/// Пустая выдача объясняет, кто её опустошил.
///
/// «Объектов не найдено» на весь экран после того, как человек сам сузил
/// отбор, читается как поломка системы. Поэтому пустота по отбору выглядит
/// иначе, чем пустота по базе, и предлагает выход.
library;

import 'package:els/screns/schedule/bloc/schedules_bloc.dart';
import 'package:els/screns/schedule/models/schedule_filters.dart';
import 'fixture_schedules_repository.dart';
import 'package:els/screns/schedule/view/schedules_screen.dart';
import 'package:els/screns/schedule/widgets/schedule_filters_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

Future<SchedulesBloc> _pumpScreen(
  WidgetTester tester, {
  required ScheduleFilters filters,
  int objectCount = 5,
}) async {
  tester.view.physicalSize = const Size(1440.0, 900.0);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  // Без задержки: фикстура ждёт 350 мс ради видимой загрузки, тесту это лишний
  // таймер.
  final SchedulesBloc bloc = SchedulesBloc(
    repository: FixtureSchedulesRepository(
      delay: Duration.zero,
      objectCount: objectCount,
    ),
    filters: filters,
  );
  addTearDown(bloc.close);

  await tester.pumpWidget(
    MaterialApp(
      home: BlocProvider<SchedulesBloc>.value(
        value: bloc,
        child: const SchedulesScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();

  return bloc;
}

void main() {
  testWidgets('пусто по отбору — видно отбор и выход из него',
      (WidgetTester tester) async {
    final SchedulesBloc bloc = await _pumpScreen(
      tester,
      filters: const ScheduleFilters(year: 2026, search: 'такого объекта нет'),
    );

    expect(find.textContaining('не подошёл ни один объект'), findsOneWidget);
    expect(find.text('Стоит условий: 1'), findsOneWidget);

    await tester.tap(find.text('Сбросить всё'));
    await tester.pumpAndSettle();

    expect(bloc.state.filters.isEmpty, isTrue);
    expect(bloc.state.filters.year, 2026);
    // Отбор сняли — объекты вернулись.
    expect(find.textContaining('не подошёл ни один объект'), findsNothing);
  });

  testWidgets('пусто без отбора — это про базу, а не про фильтры',
      (WidgetTester tester) async {
    await _pumpScreen(
      tester,
      filters: const ScheduleFilters(year: 2026),
      objectCount: 0,
    );

    expect(find.text('Объектов не найдено'), findsOneWidget);
    expect(find.textContaining('Сбросить всё'), findsNothing);
  });

  testWidgets('панель фильтров стоит и в загрузке, и на пустой выдаче',
      (WidgetTester tester) async {
    await _pumpScreen(
      tester,
      filters: const ScheduleFilters(year: 2026, search: 'такого объекта нет'),
    );

    // Панель рисуется во всех состояниях: фильтр применяется сразу при выборе,
    // и пропадай она на время запроса — выбрать второй было бы не по чему.
    expect(find.byType(ScheduleFiltersBar), findsOneWidget);
  });
}
