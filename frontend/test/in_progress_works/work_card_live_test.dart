/// Карточка работы сама по себе, без человека: она перечитывает работу раз в
/// минуту и переживает то, что механик делает у себя в телефоне.
///
/// Проверяется край этапа 9.3: работу сдали при открытой карточке, запрос
/// упал на такте, чек-лист был развёрнут руками. Всё это молча ломается при
/// первой же правке рядом, а видно становится только на живом объекте.
library;

import 'package:els/bloc/user_bloc/user_bloc.dart';
import 'package:els/screns/in_progress_works/models/in_progress_work.dart';
import 'package:els/screns/in_progress_works/models/work_details.dart';
import 'package:els/screns/in_progress_works/repository/work_details_repository.dart';
import 'package:els/screns/in_progress_works/view/work_card_screen.dart';
import 'package:els/screns/submitted_works/models/submitted_work.dart'
    show WorkKind;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

/// Репозиторий, который считает запросы, умеет падать по команде и умеет
/// закрыть работу между тактами — как это делает механик в своём телефоне.
class _Repository extends WorkDetailsRepository {
  _Repository();

  /// Пунктов в регламенте. Их дюжина — столько же, сколько в карточке ТО:
  /// шесть видно сразу, остальные за «и ещё 6 пунктов».
  static const int steps = 12;

  int calls = 0;
  int performerCalls = 0;

  bool fails = false;
  bool photosFail = false;
  int done = 4;
  DateTime? finishedAt;

  /// Снимок у первого пункта. Пусто — механик ещё не фотографировал.
  WorkPhotos photos = WorkPhotos.empty;

  @override
  Future<WorkDetails> fetchDetails(int actId) async {
    calls++;
    if (fails) throw const WorkDetailsException('Не удалось загрузить');

    return WorkDetails(
      id: actId,
      mainMechanicId: 7,
      startedAt: DateTime(2026, 8, 21, 8, 15),
      finishedAt: finishedAt,
      checklist: WorkChecklist(
        title: 'ТО-2',
        steps: List<ChecklistStep>.generate(
          steps,
          (int i) => ChecklistStep(
            id: i + 1,
            title: 'Пункт ${i + 1}',
            done: i < done,
          ),
        ),
      ),
    );
  }

  @override
  Future<WorkPhotos> fetchPhotos(int actId) async {
    if (photosFail) throw const WorkDetailsException('Не удалось загрузить');
    return photos;
  }

  @override
  Future<Performer> fetchPerformer(int userId) async {
    performerCalls++;
    return Performer(id: userId, name: 'Сафин Р.', phone: '9990000000');
  }
}

InProgressWork _work() {
  return InProgressWork(
    kind: WorkKind.maintenance,
    workId: 12,
    state: WorkState.running,
    objectId: 3,
    objectName: 'Лифт 12, подъезд 1',
    objectAddress: 'пр. Ленина, 48',
    performer: 'Сафин Р.',
    since: DateTime.now().subtract(const Duration(minutes: 40)),
    startedAt: DateTime.now().subtract(const Duration(minutes: 40)),
    title: 'ТО-2',
    progress: const WorkProgress(done: 4, total: 12),
  );
}

/// Карточка с первым ответом на руках.
Future<void> _open(WidgetTester tester, _Repository repository) async {
  tester.view.physicalSize = const Size(400.0, 900.0);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    BlocProvider<UserBloc>(
      create: (_) => UserBloc(),
      child: MaterialApp(
        home: WorkCardScreen(work: _work(), repository: repository),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Прошёл такт — и карточка успела разобрать ответ.
Future<void> _tick(WidgetTester tester) async {
  await tester.pump(const Duration(minutes: 1));
  await tester.pumpAndSettle();
}

/// Снять дерево, чтобы таймер карточки не пережил тест.
Future<void> _close(WidgetTester tester) => tester.pumpWidget(const SizedBox());

void main() {
  testWidgets('карточка перечитывает работу раз в минуту',
      (WidgetTester tester) async {
    final _Repository repository = _Repository();

    await _open(tester, repository);
    expect(repository.calls, 1);

    await _tick(tester);
    expect(repository.calls, 2);

    await _tick(tester);
    expect(repository.calls, 3);

    await _close(tester);
  });

  // Механик отметил пункт — прораб видит это, ничего не нажимая.
  testWidgets('отметки догоняют механика сами',
      (WidgetTester tester) async {
    final _Repository repository = _Repository();

    await _open(tester, repository);
    expect(find.text('Чек-лист · 4 из 12'), findsOneWidget);

    repository.done = 5;
    await _tick(tester);

    expect(find.text('Чек-лист · 5 из 12'), findsOneWidget);

    await _close(tester);
  });

  // Телефон механика не меняется оттого, что он отметил пункт: в справочник
  // карточка сходила один раз, на первой загрузке.
  testWidgets('в справочник карточка на такте не ходит',
      (WidgetTester tester) async {
    final _Repository repository = _Repository();

    await _open(tester, repository);
    expect(repository.performerCalls, 1);

    await _tick(tester);
    await _tick(tester);

    expect(repository.calls, 3);
    expect(repository.performerCalls, 1);

    await _close(tester);
  });

  testWidgets('свёрнутое приложение карточку не опрашивает',
      (WidgetTester tester) async {
    final _Repository repository = _Repository();

    await _open(tester, repository);
    expect(repository.calls, 1);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump(const Duration(minutes: 5));
    await tester.pump();
    expect(repository.calls, 1);

    // Вернулись к экрану — карточка перечитывается сразу, не дожидаясь такта:
    // за время сна она устарела сильнее, чем на минуту.
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(repository.calls, 2);

    await _close(tester);
  });

  // Ради этого этап и заведён: механик закрыл работу, пока прораб её читал.
  testWidgets('работу сдали на такте — карточка перестаёт быть карточкой',
      (WidgetTester tester) async {
    final _Repository repository = _Repository();

    await _open(tester, repository);
    expect(find.text('Чек-лист · 4 из 12'), findsOneWidget);

    repository.finishedAt = DateTime(2026, 8, 21, 11, 40);
    await _tick(tester);

    expect(find.text('Работу сдали'), findsOneWidget);
    expect(find.text('К списку'), findsOneWidget);
    expect(find.textContaining('Чек-лист'), findsNothing);
    expect(repository.calls, 2);

    // Такт погашен: сданная работа обратно в работу не возвращается, и
    // спрашивать про неё каждую минуту незачем.
    await _tick(tester);
    await _tick(tester);
    expect(repository.calls, 2);

    await _close(tester);
  });

  // Упавший такт — не новость для прораба: то, что он читает, никуда не
  // делось, а «Не удалось загрузить» на месте чек-листа не говорит ничего.
  testWidgets('сбой на такте не гасит карточку',
      (WidgetTester tester) async {
    final _Repository repository = _Repository();

    await _open(tester, repository);
    expect(find.text('Чек-лист · 4 из 12'), findsOneWidget);

    repository.fails = true;
    await _tick(tester);

    expect(find.text('Чек-лист · 4 из 12'), findsOneWidget);
    expect(find.text('Не удалось загрузить'), findsNothing);
    expect(find.text('Повторить'), findsNothing);

    // Сервер ответил снова — карточка догоняет его следующим тактом, без
    // единого нажатия.
    repository.fails = false;
    repository.done = 6;
    await _tick(tester);

    expect(find.text('Чек-лист · 6 из 12'), findsOneWidget);

    await _close(tester);
  });

  // Снимки на такте отваливаются отдельно от акта — и пропасть с экрана не
  // должны: под молчаливым чек-листом на их месте встала бы подпись «снимков
  // механик не оставил», то есть прямое враньё от одного дрогнувшего запроса.
  testWidgets('упавшие снимки не стирают то, что уже на экране',
      (WidgetTester tester) async {
    final _Repository repository = _Repository();
    repository.photos = const WorkPhotos(<int, List<String>>{
      1: <String>['host/a.jpg'],
    });

    await _open(tester, repository);
    expect(find.byType(Image), findsOneWidget);

    repository.photosFail = true;
    await _tick(tester);

    expect(find.byType(Image), findsOneWidget);
    expect(
      find.text('Снимков и комментариев механик не оставил.'),
      findsNothing,
    );

    await _close(tester);

    // Сам файл в тесте не качается: биндинг отвечает на любой запрос кодом 400.
    expect(tester.takeException(), isNotNull);
  });

  // Чек-лист разворачивают руками, и такт не вправе схлопнуть его обратно.
  testWidgets('развёрнутый чек-лист переживает такт',
      (WidgetTester tester) async {
    final _Repository repository = _Repository();

    await _open(tester, repository);
    expect(find.text('Пункт 12'), findsNothing);

    await tester.tap(find.text('…и ещё 6 пунктов'));
    await tester.pumpAndSettle();
    expect(find.text('Пункт 12'), findsOneWidget);

    await _tick(tester);
    expect(find.text('Пункт 12'), findsOneWidget);

    await _close(tester);
  });
}
