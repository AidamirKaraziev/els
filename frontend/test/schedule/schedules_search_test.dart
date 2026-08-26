/// Поиск: пауза перед запросом и сложение с фильтрами.
///
/// На старом экране поиска не было вовсе — `_runScheduleFilter` фильтровал
/// список, который никогда не заполнялся, и любой ввод очищал таблицу. Здесь
/// проверяем два обещания нового: запрос уходит один раз после паузы, и он
/// ищет **внутри** выбранных фильтров, а не вместо них.
library;

import 'package:els/screns/schedule/bloc/schedules_bloc.dart';
import 'package:els/screns/schedule/models/schedule_filters.dart';
import 'package:els/screns/schedule/models/schedule_row.dart';
import 'fixture_schedules_repository.dart';
import 'package:els/screns/schedule/repository/schedules_repository.dart';
import 'package:els/screns/schedule/widgets/schedule_filters_bar.dart';
import 'package:els/screns/schedule/widgets/schedule_search_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<List<String>> _pumpField(WidgetTester tester) async {
  final List<String> sent = <String>[];

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ScheduleSearchField(
          text: '',
          onSearch: sent.add,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  await tester.tap(find.byTooltip('Поиск'));
  await tester.pumpAndSettle();

  return sent;
}

void main() {
  testWidgets('на восемь букв уходит один запрос, а не восемь',
      (WidgetTester tester) async {
    final List<String> sent = await _pumpField(tester);

    await tester.enterText(find.byType(TextField), 'Кар');
    await tester.pump(const Duration(milliseconds: 100));
    await tester.enterText(find.byType(TextField), 'Карнавал');
    await tester.pump(const Duration(milliseconds: 100));

    // Пауза ещё не вышла — на сервер не ушло ничего.
    expect(sent, isEmpty);

    await tester.pump(ScheduleSearchField.debounce);
    expect(sent, <String>['Карнавал']);
  });

  testWidgets('крестик очищает поиск и отменяет отложенный запрос',
      (WidgetTester tester) async {
    final List<String> sent = await _pumpField(tester);

    await tester.enterText(find.byType(TextField), 'Карн');
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.byTooltip('Закрыть поиск'));
    await tester.pumpAndSettle();

    // Ни набранного слова, ни пустого запроса: искать было нечего — сбрасывать
    // тоже нечего.
    expect(sent, isEmpty);
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('поиск складывается с уже выбранным фильтром',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1440.0, 900.0);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    ScheduleFilters? last;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ScheduleFiltersBar(
            filters: const ScheduleFilters(
              year: 2026,
              division: FilterOption(id: 1, title: 'Участок № 1'),
            ),
            options: const ScheduleFilterOptions(
              divisions: <FilterOption>[
                FilterOption(id: 1, title: 'Участок № 1'),
              ],
            ),
            onChanged: (ScheduleFilters next) => last = next,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Поиск'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Карнавал');
    await tester.pump(ScheduleSearchField.debounce);

    expect(last!.search, 'Карнавал');
    // Участок остался: ищем внутри выбранного фильтра, а не вместо него.
    expect(last!.division, const FilterOption(id: 1, title: 'Участок № 1'));
  });

  testWidgets('фикстура сужает выдачу по паре «фильтр и поиск»',
      (WidgetTester tester) async {
    final SchedulesBloc bloc = SchedulesBloc(
      repository: FixtureSchedulesRepository(
        delay: Duration.zero,
        objectCount: 40,
      ),
    );
    addTearDown(bloc.close);

    bloc.add(SchedulesRequested(
      filters: ScheduleFilters(year: DateTime.now().year),
    ));
    await tester.pumpAndSettle();
    final int all = (bloc.state as SchedulesLoaded).rows.length;

    bloc.add(SchedulesRequested(
      filters: ScheduleFilters(
        year: DateTime.now().year,
        search: 'Карнавал',
        division: const FilterOption(id: 1, title: 'Участок № 1'),
      ),
    ));
    await tester.pumpAndSettle();
    final List<ScheduleRow> narrowed = (bloc.state as SchedulesLoaded).rows;

    expect(narrowed.length, lessThan(all));
    expect(narrowed, isNotEmpty);
    for (final ScheduleRow row in narrowed) {
      expect(row.name, contains('Карнавал'));
      expect(row.division, 'Участок № 1');
    }
  });
}
