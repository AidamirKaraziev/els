/// Экран открывает карточку работы с названием объекта в шапке.
///
/// Проверяем стык, который раньше был порван: строка знает объект, а экран
/// передавал в карточку пустой `objectName`, и в шапке стояло «Работа».
///
/// Маршрут перехватываем наблюдателем и **не строим**: карточка внутри создаёт
/// `WorkDetailsBloc` и лезет в сеть, а нас интересует ровно то, с чем её
/// открыли. Конструктор виджета побочных действий не имеет — блок появляется
/// только в `build`.
library;

import 'package:els/screns/schedule/bloc/schedules_bloc.dart';
import 'package:els/screns/schedule/models/month_cell.dart';
import 'package:els/screns/schedule/models/schedule_row.dart';
import 'fixture_schedules_repository.dart';
import 'package:els/screns/schedule/view/schedule_work_card_screen.dart';
import 'package:els/screns/schedule/view/schedules_screen.dart';
import 'package:els/screns/schedule/widgets/schedule_row_tile.dart';
import 'package:els/helper/calendar/month_picker.dart' show kMonthsNominative;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _RouteSpy extends NavigatorObserver {
  Route<dynamic>? pushed;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushed = route;
    super.didPush(route, previousRoute);
  }
}

String _tooltipOf(MonthCell cell) {
  return <String>[
    kMonthsNominative[cell.month - 1],
    if (cell.label.isNotEmpty) cell.label,
    cell.status.title,
  ].join(' · ');
}

void main() {
  testWidgets('в шапку карточки уходит название объекта, а не пустая строка',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(400.0, 900.0);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final _RouteSpy spy = _RouteSpy();
    // Без задержки: фикстура ждёт 350 мс, чтобы человек увидел загрузку, а
    // тесту это лишний таймер.
    final SchedulesBloc bloc = SchedulesBloc(
      repository: FixtureSchedulesRepository(
        delay: Duration.zero,
        objectCount: 3,
      ),
    );
    addTearDown(bloc.close);

    await tester.pumpWidget(
      MaterialApp(
        navigatorObservers: <NavigatorObserver>[spy],
        home: BlocProvider<SchedulesBloc>.value(
          value: bloc,
          child: const SchedulesScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final SchedulesState state = bloc.state;
    expect(state, isA<SchedulesLoaded>());
    final ScheduleRow row = (state as SchedulesLoaded).rows.first;
    final MonthCell cell =
        row.cells.firstWhere((MonthCell c) => c.isTappable);

    // Тултип одной клетки повторяется в других строках — берём ту, что в
    // первой: именно её объект мы сверяем.
    await tester.tap(find.descendant(
      of: find.byType(ScheduleRowTile).first,
      matching: find.byTooltip(_tooltipOf(cell)),
    ));
    // Намеренно без `pump`: кадр построил бы карточку и увёл тест в сеть.

    final Route<dynamic>? pushed = spy.pushed;
    expect(pushed, isA<MaterialPageRoute<void>>());

    final Widget opened = (pushed! as MaterialPageRoute<void>)
        .builder(tester.element(find.byType(SchedulesScreen)));

    expect(opened, isA<ScheduleWorkCardScreen>());
    final ScheduleWorkCardScreen card = opened as ScheduleWorkCardScreen;
    expect(card.workId, cell.actId);
    expect(card.objectName, row.nameLabel);
    expect(card.objectName, isNotEmpty);
  });
}
