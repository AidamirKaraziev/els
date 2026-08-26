/// Лента объектов догружается сама и знает, где кончилась.
///
/// Фикстура отдаёт страницы по тридцать строк. Без слушателя прокрутки человек
/// видел первые тридцать объектов из восьмидесяти семи и считал, что это все.
library;

import 'package:els/screns/schedule/bloc/schedules_bloc.dart';
import 'package:els/screns/schedule/models/schedule_division.dart';
import 'package:els/screns/schedule/models/schedule_filters.dart';
import 'package:els/screns/schedule/repository/fixture_schedules_repository.dart';
import 'package:els/screns/schedule/repository/schedules_repository.dart';
import 'package:els/screns/schedule/view/schedules_screen.dart';
import 'package:els/screns/schedule/widgets/schedule_row_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

/// Фикстура, которая считает запросы страниц.
///
/// Нужна ровно для одного утверждения: на последней странице прокрутка вниз не
/// должна дёргать репозиторий снова.
class _CountingRepository implements SchedulesRepository {
  _CountingRepository({int objectCount = 87})
      : _inner = FixtureSchedulesRepository(
          delay: Duration.zero,
          objectCount: objectCount,
        );

  final FixtureSchedulesRepository _inner;
  final List<int> requestedPages = <int>[];

  @override
  Future<SchedulePage> fetchRows({
    required ScheduleFilters filters,
    required int page,
  }) {
    requestedPages.add(page);
    return _inner.fetchRows(filters: filters, page: page);
  }

  @override
  Future<List<ScheduleDivision>> fetchDivisions({
    required int year,
  }) =>
      _inner.fetchDivisions(year: year);

  @override
  Future<ScheduleFilterOptions> fetchFilterOptions() =>
      _inner.fetchFilterOptions();
}

Future<_CountingRepository> _pumpScreen(
  WidgetTester tester, {
  int objectCount = 87,
}) async {
  tester.view.physicalSize = const Size(1440.0, 900.0);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final _CountingRepository repository =
      _CountingRepository(objectCount: objectCount);

  final SchedulesBloc bloc = SchedulesBloc(
    repository: repository,
    filters: ScheduleFilters(year: DateTime.now().year),
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

  return repository;
}

/// Прокрутить ленту до самого низа.
Future<void> _scrollToBottom(WidgetTester tester) async {
  final Finder list = find.byType(Scrollable).last;
  await tester.drag(list, const Offset(0, -100000));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('прокрутка до конца догружает следующую страницу',
      (WidgetTester tester) async {
    final _CountingRepository repository = await _pumpScreen(tester);

    expect(repository.requestedPages, <int>[1]);

    await _scrollToBottom(tester);

    expect(repository.requestedPages, contains(2));
  });

  testWidgets('на последней странице внизу написано, что объекты кончились',
      (WidgetTester tester) async {
    // Сорок объектов — это ровно две страницы: первая полная, вторая короткая.
    await _pumpScreen(tester, objectCount: 40);

    expect(find.text('Это все объекты'), findsNothing);

    await _scrollToBottom(tester);
    await _scrollToBottom(tester);

    expect(find.text('Это все объекты'), findsOneWidget);
  });

  testWidgets('на первой и единственной странице отбивки нет',
      (WidgetTester tester) async {
    await _pumpScreen(tester, objectCount: 5);

    await _scrollToBottom(tester);

    // Под списком из пяти объектов «Это все объекты» звучало бы как отчёт о
    // проделанной работе там, где листать было нечего.
    expect(find.text('Это все объекты'), findsNothing);
    expect(find.byType(ScheduleRowTile), findsNWidgets(5));
  });

  testWidgets('дойдя до конца, лента перестаёт просить страницы',
      (WidgetTester tester) async {
    final _CountingRepository repository = await _pumpScreen(
      tester,
      objectCount: 40,
    );

    await _scrollToBottom(tester);
    await _scrollToBottom(tester);

    final int afterEnd = repository.requestedPages.length;

    await _scrollToBottom(tester);
    await _scrollToBottom(tester);

    expect(repository.requestedPages.length, afterEnd);
  });
}
