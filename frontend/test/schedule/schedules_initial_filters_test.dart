/// С каким отбором открывается раздел «Графики».
///
/// Обычный вход — из меню, и тогда лента показывает всё. Но с главной, из
/// карточки «Выполнение графика», в раздел приходят с готовым участком, и
/// заявка на такой заход живёт в статике: между карточкой и разделом стоит
/// оболочка подрядчика, передать значение по-другому нельзя. Статика опасна
/// ровно одним — заявка, забытая до следующего захода, показала бы человеку
/// вчерашний фильтр вместо всех объектов. Про это здесь и тесты.
library;

import 'package:els/screns/schedule/models/schedule_filters.dart';
import 'package:els/screns/schedule/models/schedule_row.dart';
import 'package:els/screns/schedule/repository/schedules_repository.dart';
import 'package:els/screns/schedule/view/schedule_section.dart';
import 'package:els/screns/schedule/view/schedules_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:els/screns/schedule/repository/fixture_schedules_repository.dart';

/// Фикстура, которая запоминает, с чем её попросили ленту.
class _SpyRepository implements SchedulesRepository {
  _SpyRepository()
      : _inner = FixtureSchedulesRepository(delay: Duration.zero);

  final FixtureSchedulesRepository _inner;
  final List<ScheduleFilters> asked = <ScheduleFilters>[];

  @override
  Future<SchedulePage> fetchRows({
    required ScheduleFilters filters,
    required int page,
  }) {
    asked.add(filters);
    return _inner.fetchRows(filters: filters, page: page);
  }

  @override
  Future<ScheduleRow?> fetchRow({
    required int objectId,
    required int year,
  }) =>
      _inner.fetchRow(objectId: objectId, year: year);

  @override
  Future<ScheduleFilterOptions> fetchFilterOptions() =>
      _inner.fetchFilterOptions();
}

Future<_SpyRepository> _pump(
  WidgetTester tester, {
  ScheduleFilters? initialFilters,
}) async {
  tester.view.physicalSize = const Size(1440.0, 900.0);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final _SpyRepository repository = _SpyRepository();

  await tester.pumpWidget(
    MaterialApp(
      home: ScheduleSection(
        role: ScheduleRole.admin,
        repository: repository,
        initialFilters: initialFilters,
      ),
    ),
  );
  await tester.pumpAndSettle();

  return repository;
}

void main() {
  setUp(ScheduleSectionRequest.take);

  testWidgets('без заявки лента просит все объекты за текущий год',
      (WidgetTester tester) async {
    final _SpyRepository repository = await _pump(tester);

    expect(repository.asked.first.isEmpty, isTrue);
    expect(repository.asked.first.year, DateTime.now().year);
  });

  testWidgets('заданный отбор уезжает в первый же запрос ленты',
      (WidgetTester tester) async {
    const ScheduleFilters wanted = ScheduleFilters(
      year: 2025,
      division: FilterOption(id: 4, title: 'Участок № 1'),
    );

    final _SpyRepository repository =
        await _pump(tester, initialFilters: wanted);

    // Именно первым запросом, а не вторым после перерисовки: иначе человек
    // успел бы увидеть чужие строки.
    expect(repository.asked.first, wanted);
    expect(find.byType(SchedulesScreen), findsOneWidget);
  });

  test('заявка забирается один раз', () {
    const ScheduleFilters filters = ScheduleFilters(year: 2025);

    ScheduleSectionRequest.put(filters);

    expect(ScheduleSectionRequest.take(), filters);
    // Второй заход в раздел — уже из меню, и он обязан показать всё.
    expect(ScheduleSectionRequest.take(), isNull);
  });
}
