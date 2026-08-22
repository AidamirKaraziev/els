/// Раздел «Сейчас в работе» сам по себе, без человека: время в пилюле идёт,
/// список перечитывается, сбой не стирает работы с экрана.
///
/// Проверяется то, что молча ломается при первой же правке рядом: остановка
/// опроса на свёрнутом приложении и то, что упавший запрос оставляет прежние
/// строки. Кнопки «Повторить» у раздела нет — если опрос замолчит, человеку
/// нечем будет это исправить.
library;

import 'package:els/screns/in_progress_works/bloc/in_progress_works_bloc.dart';
import 'package:els/screns/in_progress_works/models/in_progress_work.dart';
import 'package:els/screns/in_progress_works/repository/in_progress_works_repository.dart';
import 'package:els/screns/in_progress_works/widgets/in_progress_works_live.dart';
import 'package:els/screns/in_progress_works/widgets/work_parts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

/// Ответ ручки с работой, которая идёт с момента [since].
Map<String, dynamic> _feed(DateTime since) {
  final int seconds = since.millisecondsSinceEpoch ~/ 1000;

  return <String, dynamic>{
    'data': <String, dynamic>{
      'items': <Map<String, dynamic>>[
        <String, dynamic>{
          'kind': 'maintenance',
          'work_id': 12,
          'state': 'running',
          'since': seconds,
          'started_at': seconds,
          'title': 'ТО-1',
          'progress': const <String, dynamic>{'done': 4, 'total': 12},
          'performer': 'Механик Ковалёв',
          'object': const <String, dynamic>{
            'id': 3,
            'name': 'Лифт 12',
            'address': 'пр. Ленина, 48',
          },
        },
      ],
      'total': 1,
      'problems': 0,
    },
  };
}

/// Репозиторий, который считает запросы и умеет падать по команде.
class _Repository extends InProgressWorksRepository {
  _Repository({int secondsAgo = 40 * 60, DateTime? now})
      : _since = (now ?? DateTime.now()).subtract(Duration(seconds: secondsAgo));

  /// Момент начала работы считается один раз: сервер его не переписывает от
  /// запроса к запросу, и подпись пилюли должна расти, а не топтаться на
  /// месте после каждого обновления списка.
  final DateTime _since;

  int calls = 0;
  bool fails = false;

  @override
  Future<InProgressWorks> fetch() async {
    calls++;
    if (fails) throw const InProgressWorksException('Не удалось загрузить');
    return InProgressWorks.fromJson(_feed(_since));
  }
}

Widget _app(InProgressWorksBloc bloc) {
  return MaterialApp(
    home: Scaffold(
      body: BlocProvider<InProgressWorksBloc>.value(
        value: bloc,
        child: const InProgressWorksLive(),
      ),
    ),
  );
}

/// Раздел с первым ответом на руках. `pumpAndSettle` здесь нельзя: опрос
/// заводит вечный таймер, и ждать тишины пришлось бы до самого таймаута.
Future<void> _open(WidgetTester tester, InProgressWorksBloc bloc) async {
  bloc.add(const InProgressWorksRequested());
  await tester.pumpWidget(_app(bloc));
  await tester.pump();
}

/// Снять дерево, чтобы таймеры раздела не пережили тест.
Future<void> _close(WidgetTester tester) => tester.pumpWidget(const SizedBox());

void main() {
  testWidgets('пилюля пересчитывается по своему таймеру, а не по нажатию',
      (WidgetTester tester) async {
    // Часы пилюли держим в руках. Раньше тест ждал настоящую секунду на
    // работе, начатой 59 секунд назад, — и падал на загруженной машине, где
    // минута истекала раньше первой проверки.
    final DateTime start = DateTime(2026, 8, 21, 10);
    DateTime moment = start;
    workClock = () => moment;
    addTearDown(() => workClock = DateTime.now);

    // Работа началась 59 секунд назад: пока это «меньше минуты».
    final _Repository repository = _Repository(secondsAgo: 59, now: start);
    final InProgressWorksBloc bloc = InProgressWorksBloc(repository: repository);
    addTearDown(bloc.close);

    bloc.add(const InProgressWorksRequested());
    await tester.pumpWidget(_app(bloc));
    await tester.pump();

    expect(find.text('Идёт · меньше минуты'), findsOneWidget);

    // Часы ушли вперёд, а раздел не перерисовывается: чистый виджет сам себя
    // не пересчитает, и подпись остаётся прежней.
    moment = start.add(const Duration(seconds: 2));
    await tester.pump();
    expect(find.text('Идёт · меньше минуты'), findsOneWidget);

    // Минутный такт пилюли — и подпись догоняет часы.
    await tester.pump(const Duration(minutes: 1));
    expect(find.text('Идёт · 1 мин'), findsOneWidget);

    await _close(tester);
  });

  testWidgets('раздел перечитывает себя раз в минуту',
      (WidgetTester tester) async {
    final _Repository repository = _Repository();
    final InProgressWorksBloc bloc = InProgressWorksBloc(repository: repository);
    addTearDown(bloc.close);

    await _open(tester, bloc);
    expect(repository.calls, 1);

    await tester.pump(const Duration(minutes: 1));
    await tester.pump();
    expect(repository.calls, 2);

    await tester.pump(const Duration(minutes: 1));
    await tester.pump();
    expect(repository.calls, 3);

    await _close(tester);
  });

  testWidgets('свёрнутое приложение раздел не опрашивает',
      (WidgetTester tester) async {
    final _Repository repository = _Repository();
    final InProgressWorksBloc bloc = InProgressWorksBloc(repository: repository);
    addTearDown(bloc.close);

    await _open(tester, bloc);
    expect(repository.calls, 1);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump(const Duration(minutes: 5));
    await tester.pump();
    expect(repository.calls, 1);

    // Вернулись к экрану — список перечитывается сразу, не дожидаясь такта.
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(repository.calls, 2);

    await tester.pump(const Duration(minutes: 1));
    await tester.pump();
    expect(repository.calls, 3);

    await _close(tester);
  });

  testWidgets('упавший такт оставляет строки на месте, удачный — убирает пометку',
      (WidgetTester tester) async {
    final _Repository repository = _Repository();
    final InProgressWorksBloc bloc = InProgressWorksBloc(repository: repository);
    addTearDown(bloc.close);

    await _open(tester, bloc);
    expect(find.text('Лифт 12'), findsOneWidget);
    expect(find.text('Не удалось обновить'), findsNothing);

    repository.fails = true;
    await tester.pump(const Duration(minutes: 1));
    await tester.pump();

    // Работа никуда не делась — делась связь.
    expect(find.text('Лифт 12'), findsOneWidget);
    expect(find.text('Не удалось обновить'), findsOneWidget);
    // Число работ у заголовка тоже остаётся: список на экране, значит и счёт
    // при нём.
    expect(find.text('1'), findsOneWidget);

    repository.fails = false;
    await tester.pump(const Duration(minutes: 1));
    await tester.pump();

    expect(find.text('Не удалось обновить'), findsNothing);
    expect(find.text('Лифт 12'), findsOneWidget);

    await _close(tester);
  });

  testWidgets('сбой первой загрузки объясняется словами, а не пустым местом',
      (WidgetTester tester) async {
    final _Repository repository = _Repository()..fails = true;
    final InProgressWorksBloc bloc = InProgressWorksBloc(repository: repository);
    addTearDown(bloc.close);

    await _open(tester, bloc);

    expect(find.text('Не удалось загрузить'), findsOneWidget);
    expect(find.text('Не удалось обновить'), findsNothing);

    await _close(tester);
  });
}
