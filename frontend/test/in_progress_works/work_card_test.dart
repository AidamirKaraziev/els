/// Карточка ТО глазами прораба.
///
/// Проверяется то, ради чего карточку и делали: шапка повторяет строку, на
/// которую нажали, и появляется до ответа сервера; чек-лист обрывается на
/// шестом пункте; пустой телефон назван словами, а не спрятан.
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

/// Репозиторий, который отвечает тем, что ему велели, — и не ходит в сеть.
class _FakeRepository extends WorkDetailsRepository {
  const _FakeRepository({
    this.details,
    this.photos = WorkPhotos.empty,
    this.performer,
    this.detailsError,
    this.performerError = false,
  });

  final WorkDetails? details;
  final WorkPhotos photos;
  final Performer? performer;
  final String? detailsError;
  final bool performerError;

  @override
  Future<WorkDetails> fetchDetails(int actId) async {
    final String? error = detailsError;
    if (error != null) throw WorkDetailsException(error);
    return details ?? WorkDetails(id: actId);
  }

  @override
  Future<WorkPhotos> fetchPhotos(int actId) async => photos;

  @override
  Future<Performer> fetchPerformer(int userId) async {
    if (performerError) {
      throw const WorkDetailsException('Не удалось загрузить');
    }
    return performer ?? Performer(id: userId);
  }
}

InProgressWork _work({
  WorkState state = WorkState.paused,
  String? reason = 'Уехал на аварийный вызов',
}) {
  return InProgressWork(
    kind: WorkKind.maintenance,
    workId: 12,
    state: state,
    objectId: 3,
    objectName: 'Лифт 12, подъезд 1',
    objectAddress: 'пр. Ленина, 48',
    performer: 'Сафин Р.',
    since: DateTime.now().subtract(const Duration(hours: 1, minutes: 10)),
    startedAt: DateTime.now().subtract(const Duration(hours: 3)),
    reason: reason,
    title: 'ТО-2',
    progress: const WorkProgress(done: 4, total: 12),
  );
}

WorkDetails _details({int steps = 12, int? mechanicId = 7}) {
  return WorkDetails(
    id: 12,
    mainMechanicId: mechanicId,
    startedAt: DateTime(2026, 8, 21, 8, 15),
    pausedAt: DateTime(2026, 8, 21, 9, 5),
    checklist: WorkChecklist(
      title: 'ТО-2',
      steps: List<ChecklistStep>.generate(
        steps,
        (int i) => ChecklistStep(
          id: i + 1,
          title: 'Пункт ${i + 1}',
          done: i < 4,
          comment: i == 1 ? 'Колодки в норме' : null,
        ),
      ),
    ),
  );
}

Future<void> _pump(
  WidgetTester tester, {
  required WorkDetailsRepository repository,
  InProgressWork? work,
  Size size = const Size(400.0, 900.0),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    BlocProvider<UserBloc>(
      create: (_) => UserBloc(),
      child: MaterialApp(
        home: WorkCardScreen(
          work: work ?? _work(),
          repository: repository,
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('шапка рисуется до ответа сервера', (WidgetTester tester) async {
    await _pump(tester, repository: _FakeRepository(details: _details()));

    // Первый кадр: запросы ещё в пути, а объект, адрес, пилюля и причина уже
    // на экране — они приехали со строкой списка.
    expect(find.text('Лифт 12, подъезд 1'), findsOneWidget);
    expect(find.text('пр. Ленина, 48'), findsOneWidget);
    expect(find.text('ТО'), findsOneWidget);
    expect(find.text('Уехал на аварийный вызов'), findsOneWidget);
    expect(find.textContaining('Пауза'), findsOneWidget);

    await tester.pumpAndSettle();
  });

  testWidgets('чек-лист обрывается на шестом пункте', (WidgetTester tester) async {
    await _pump(tester, repository: _FakeRepository(details: _details()));
    await tester.pumpAndSettle();

    expect(find.text('Чек-лист · 4 из 12'), findsOneWidget);
    expect(find.text('Пункт 1'), findsOneWidget);
    expect(find.text('…и ещё 6 пунктов'), findsOneWidget);
    // Седьмой по порядку показа спрятан.
    expect(find.text('Пункт 7'), findsNothing);

    await tester.tap(find.text('…и ещё 6 пунктов'));
    await tester.pumpAndSettle();

    expect(find.text('…и ещё 6 пунктов'), findsNothing);
    expect(find.text('Пункт 12'), findsOneWidget);
  });

  testWidgets('комментарий механика живёт внутри своего пункта',
      (WidgetTester tester) async {
    await _pump(tester, repository: _FakeRepository(details: _details()));
    await tester.pumpAndSettle();

    expect(find.text('Колодки в норме'), findsOneWidget);
  });

  // Снимки живут внутри своего пункта, а не общей кучей внизу: «износ выше
  // нормы» без названия шага ничего не значит.
  testWidgets('снимки встают в свой пункт', (WidgetTester tester) async {
    await _pump(
      tester,
      repository: _FakeRepository(
        details: _details(),
        photos: const WorkPhotos(<int, List<String>>{
          2: <String>['host/a.jpg'],
        }),
      ),
    );
    await tester.pumpAndSettle();

    // Миниатюра одна — ровно у того пункта, к которому снимок привязан.
    // Аватарка в шапке сейчас не рисуется: профиль в тесте не загружен.
    expect(find.byType(Image), findsOneWidget);

    // Сам файл в тесте не качается: `TestWidgetsFlutterBinding` отвечает на
    // любой запрос кодом 400. Ошибку загрузки снимаем — проверяем, что
    // миниатюра встала на место, а не что сеть работает.
    expect(tester.takeException(), isNotNull);
  });

  testWidgets('короткий чек-лист показывается целиком',
      (WidgetTester tester) async {
    await _pump(
      tester,
      repository: _FakeRepository(details: _details(steps: 5)),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('и ещё'), findsNothing);
    expect(find.text('Пункт 5'), findsOneWidget);
  });

  testWidgets('пустой чек-лист назван словами', (WidgetTester tester) async {
    await _pump(
      tester,
      repository: _FakeRepository(details: _details(steps: 0)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Чек-лист не заполнен'), findsOneWidget);
  });

  testWidgets('номер есть — есть кнопка', (WidgetTester tester) async {
    await _pump(
      tester,
      repository: _FakeRepository(
        details: _details(),
        performer: const Performer(
          id: 7,
          name: 'Сафин Р.',
          specialty: 'Механик',
          phone: '9990000000',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Позвонить'), findsOneWidget);
    expect(find.text('Номер не указан'), findsNothing);
    expect(find.text('Механик · ТО-2'), findsOneWidget);
  });

  // Неработающая кнопка хуже её отсутствия: серую «Позвонить» прораб всё
  // равно будет жать.
  testWidgets('номера нет — кнопки нет, но сказано, чего не хватает',
      (WidgetTester tester) async {
    await _pump(
      tester,
      repository: _FakeRepository(
        details: _details(),
        performer: const Performer(id: 7, name: 'Ковалёв А.', phone: null),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Позвонить'), findsNothing);
    expect(find.text('Номер не указан'), findsOneWidget);
  });

  // Молчащий справочник и незаполненное поле чинятся по-разному — и названы
  // разными словами.
  testWidgets('справочник не ответил — это не пустой номер',
      (WidgetTester tester) async {
    await _pump(
      tester,
      // Механик в акте назван — значит за телефоном карточка сходила и не
      // получила ответа. Это не то же самое, что пустое поле.
      repository: _FakeRepository(details: _details(), performerError: true),
    );
    await tester.pumpAndSettle();

    expect(find.text('Телефон не загрузился'), findsOneWidget);
    expect(find.text('Номер не указан'), findsNothing);
  });

  testWidgets('у проблемы время объявления — «не записано»',
      (WidgetTester tester) async {
    await _pump(
      tester,
      work: _work(state: WorkState.problem, reason: 'Не подходит трос'),
      repository: _FakeRepository(details: _details()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Объявил проблему'), findsOneWidget);
    expect(find.text('не записано'), findsOneWidget);
  });

  testWidgets('времена показываются как в макете', (WidgetTester tester) async {
    await _pump(tester, repository: _FakeRepository(details: _details()));
    await tester.pumpAndSettle();

    expect(find.text('21.08.2026, 08:15'), findsOneWidget);
    expect(find.text('21.08.2026, 09:05'), findsOneWidget);
    expect(find.text('только что'), findsOneWidget);
  });

  // Шапка живёт своей жизнью: всё, что в ней есть, пришло со строкой списка.
  testWidgets('подробности не загрузились — шапка остаётся',
      (WidgetTester tester) async {
    await _pump(
      tester,
      repository: const _FakeRepository(detailsError: 'Не удалось загрузить'),
    );
    await tester.pumpAndSettle();

    expect(find.text('Лифт 12, подъезд 1'), findsOneWidget);
    expect(find.text('Не удалось загрузить'), findsOneWidget);
    expect(find.text('Повторить'), findsOneWidget);
  });
}
