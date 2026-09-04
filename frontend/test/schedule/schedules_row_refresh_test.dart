/// Закрыли ТО — в ленте раздела обновляется одна строка, а не вся лента.
///
/// До этого лента умела ровно одно обновление — `SchedulesRequested`, а оно
/// сбрасывает постраничную загрузку к первой странице: человек, закрывший ТО
/// после пяти прокруток, вернулся бы в начало списка. Клетку при этом считает
/// сервер — «выполнено с опозданием» отличается от «выполнено» тем, кончился
/// ли плановый месяц, и по часам браузера эта граница едет.
library;

import 'package:els/screns/schedule/bloc/schedules_bloc.dart';
import 'package:els/screns/schedule/models/month_cell.dart';
import 'package:els/screns/schedule/models/schedule_filters.dart';
import 'package:els/screns/schedule/models/schedule_row.dart';
import 'package:els/screns/schedule/repository/schedules_repository.dart';
import 'package:els/screns/schedule/view/schedule_work_card_screen.dart';
import 'package:els/screns/schedule/view/schedules_screen.dart';
import 'package:els/screns/schedule/widgets/schedule_row_tile.dart';
import 'package:els/helper/calendar/month_picker.dart' show kMonthsNominative;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixture_schedules_repository.dart';

const int _pageSize = 2;

/// Лента из шести объектов страницами по два — так видно, что обновление
/// строки не сбрасывает уже догруженные страницы.
class _PagedRepository implements SchedulesRepository {
  _PagedRepository({this.fresh, this.fails = false});

  /// Что ответить на запрос одной строки. `null` — объекта в выдаче нет.
  final ScheduleRow? fresh;

  /// Ручка одной строки отвечает ошибкой.
  final bool fails;

  final List<int> requestedPages = <int>[];
  final List<int> requestedRows = <int>[];

  @override
  Future<SchedulePage> fetchRows({
    required ScheduleFilters filters,
    required int page,
  }) async {
    requestedPages.add(page);
    final int from = (page - 1) * _pageSize;
    return SchedulePage(
      items: <ScheduleRow>[
        for (int i = from; i < from + _pageSize && i < 6; i++)
          _row(objectId: 100 + i, year: filters.year),
      ],
      page: page,
      hasNext: from + _pageSize < 6,
    );
  }

  @override
  Future<ScheduleRow?> fetchRow({
    required int objectId,
    required int year,
  }) async {
    requestedRows.add(objectId);
    if (fails) throw const SchedulesException('Сервер ответил ошибкой 500');
    return fresh;
  }

  @override
  Future<ScheduleFilterOptions> fetchFilterOptions() async =>
      ScheduleFilterOptions.empty;
}

ScheduleRow _row({
  required int objectId,
  required int year,
  MonthStatus march = MonthStatus.pending,
}) {
  return ScheduleRow(
    objectId: objectId,
    name: 'Объект $objectId',
    year: year,
    cells: <MonthCell>[
      for (int month = 1; month <= 12; month++)
        month == 3
            ? MonthCell(month: 3, status: march, toName: 'ТО 1', actId: 900)
            : MonthCell.empty(month),
    ],
  );
}

/// Лента, догруженная до второй страницы.
Future<SchedulesBloc> _loadedTwoPages(_PagedRepository repository) async {
  final SchedulesBloc bloc = SchedulesBloc(
    repository: repository,
    filters: const ScheduleFilters(year: 2027),
  );
  bloc.add(const SchedulesRequested(filters: ScheduleFilters(year: 2027)));
  await bloc.stream.firstWhere((SchedulesState s) => s is SchedulesLoaded);
  bloc.add(const SchedulesNextPageRequested());
  await bloc.stream.firstWhere(
    (SchedulesState s) => s is SchedulesLoaded && s.page == 2,
  );
  return bloc;
}

void main() {
  test('обновляется одна строка, страницы и отбор остаются', () async {
    final _PagedRepository repository = _PagedRepository(
      fresh: _row(objectId: 101, year: 2027, march: MonthStatus.late),
    );
    final SchedulesBloc bloc = await _loadedTwoPages(repository);
    addTearDown(bloc.close);

    bloc.add(const SchedulesRowRefreshed(101));
    await bloc.stream.firstWhere(
      (SchedulesState s) =>
          s is SchedulesLoaded && s.rows[1].cells[2].status == MonthStatus.late,
    );

    final SchedulesLoaded state = bloc.state as SchedulesLoaded;
    // Страницы на месте: четыре строки, вторая страница, есть что догружать.
    expect(state.rows.length, 4);
    expect(state.page, 2);
    expect(state.hasNext, isTrue);
    expect(state.filters.year, 2027);
    // Соседние строки не тронуты.
    expect(state.rows[0].cells[2].status, MonthStatus.pending);
    expect(state.rows[2].cells[2].status, MonthStatus.pending);
    // Ленту заново не просили — только одну строку.
    expect(repository.requestedPages, <int>[1, 2]);
    expect(repository.requestedRows, <int>[101]);
  });

  test('объекта нет в выдаче — лента остаётся прежней', () async {
    final _PagedRepository repository = _PagedRepository(fresh: null);
    final SchedulesBloc bloc = await _loadedTwoPages(repository);
    addTearDown(bloc.close);

    final SchedulesState before = bloc.state;
    bloc.add(const SchedulesRowRefreshed(101));
    // Ждём, пока запрос уйдёт и ответ разберётся: нового состояния быть не
    // должно, и сверять нечего, кроме того, что оно не сменилось.
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(repository.requestedRows, <int>[101]);
    expect(identical(bloc.state, before), isTrue);
  });

  test('ручка ответила ошибкой — лента остаётся прежней', () async {
    final _PagedRepository repository = _PagedRepository(fails: true);
    final SchedulesBloc bloc = await _loadedTwoPages(repository);
    addTearDown(bloc.close);

    final SchedulesState before = bloc.state;
    bloc.add(const SchedulesRowRefreshed(101));
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(identical(bloc.state, before), isTrue);
  });

  test('строки нет в списке — в сеть не ходим', () async {
    final _PagedRepository repository = _PagedRepository(fresh: null);
    final SchedulesBloc bloc = await _loadedTwoPages(repository);
    addTearDown(bloc.close);

    bloc.add(const SchedulesRowRefreshed(999));
    await Future<void>.delayed(Duration.zero);

    expect(repository.requestedRows, isEmpty);
  });

  testWidgets('закрытие ТО из карточки перечитывает строку этого объекта',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(400.0, 900.0);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final _RouteSpy spy = _RouteSpy();
    final _RowSpyRepository repository = _RowSpyRepository();
    final SchedulesBloc bloc = SchedulesBloc(repository: repository);
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

    final ScheduleRow row = (bloc.state as SchedulesLoaded).rows.first;
    final MonthCell cell = row.cells.firstWhere((MonthCell c) => c.isTappable);

    await tester.tap(find.descendant(
      of: find.byType(ScheduleRowTile).first,
      matching: find.byTooltip(_tooltipOf(cell)),
    ));
    // Намеренно без `pump`: кадр построил бы карточку и увёл тест в сеть.

    final Widget opened = (spy.pushed! as MaterialPageRoute<void>)
        .builder(tester.element(find.byType(SchedulesScreen)));
    final ScheduleWorkCardScreen card = opened as ScheduleWorkCardScreen;

    // Кнопка «Завершить ТО» зовёт ровно это — карточку не строим.
    expect(card.onToFinished, isNotNull);
    card.onToFinished!();
    await tester.pumpAndSettle();

    expect(repository.requestedRows, <int>[row.objectId]);
  });
}

/// Фикстура, которая помнит, какие строки у неё перечитывали.
class _RowSpyRepository implements SchedulesRepository {
  _RowSpyRepository()
      : _inner = FixtureSchedulesRepository(
          delay: Duration.zero,
          objectCount: 3,
        );

  final FixtureSchedulesRepository _inner;
  final List<int> requestedRows = <int>[];

  @override
  Future<SchedulePage> fetchRows({
    required ScheduleFilters filters,
    required int page,
  }) =>
      _inner.fetchRows(filters: filters, page: page);

  @override
  Future<ScheduleRow?> fetchRow({
    required int objectId,
    required int year,
  }) {
    requestedRows.add(objectId);
    return _inner.fetchRow(objectId: objectId, year: year);
  }

  @override
  Future<ScheduleFilterOptions> fetchFilterOptions() =>
      _inner.fetchFilterOptions();
}

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
