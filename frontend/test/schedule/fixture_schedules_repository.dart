import 'package:els/screns/schedule/models/month_cell.dart';
import 'package:els/screns/schedule/models/schedule_filters.dart';
import 'package:els/screns/schedule/models/schedule_row.dart';
import 'package:els/screns/schedule/repository/schedules_repository.dart';

/// Раздел «Графики» в памяти — подстава для тестов экрана.
///
/// Живёт в `test/`, а не в `lib/`: боевой раздел ходит в сеть через
/// `ApiSchedulesRepository`, и второй реализации в самом приложении быть не
/// должно — с ней экран однажды собрался бы с выдуманными данными.
///
/// Повторяет поведение ручек: страницы по тридцать строк, фильтры и поиск
/// складываются, состояние клеток разное. Тесты экрана держатся за неё
/// сознательно — они проверяют вёрстку и переходы, а не разбор ответа
/// сервера; разбор проверяет `api_schedules_repository_test.dart`.
class FixtureSchedulesRepository implements SchedulesRepository {
  FixtureSchedulesRepository({
    this.delay = const Duration(milliseconds: 350),
    int objectCount = 87,
  }) : _rows = _generate(objectCount);

  /// Задержка нужна: без неё не видно ни загрузки, ни догрузки по скроллу, и
  /// экран нельзя проверить глазами.
  final Duration delay;

  final List<ScheduleRow> _rows;

  static const int _pageSize = 30;

  @override
  Future<SchedulePage> fetchRows({
    required ScheduleFilters filters,
    required int page,
  }) async {
    await Future<void>.delayed(delay);

    final List<ScheduleRow> matched = _rows
        .map((ScheduleRow row) => _withYear(row, filters.year))
        .where((ScheduleRow row) => _matches(row, filters))
        .toList(growable: false);

    final int from = (page - 1) * _pageSize;
    if (from >= matched.length) {
      return SchedulePage(items: const <ScheduleRow>[], page: page, hasNext: false);
    }
    final int to = (from + _pageSize).clamp(0, matched.length);

    return SchedulePage(
      items: matched.sublist(from, to),
      page: page,
      hasNext: to < matched.length,
    );
  }

  @override
  Future<ScheduleFilterOptions> fetchFilterOptions() async {
    await Future<void>.delayed(delay);

    return ScheduleFilterOptions(
      divisions: _options(_divisions),
      types: _options(_types),
      names: _options(
        _rows.map((ScheduleRow row) => row.name).toSet().toList(growable: false)
          ..sort(),
      ),
      factoryNumbers: _options(
        _rows
            .map((ScheduleRow row) => row.factoryNumberLabel)
            .toSet()
            .toList(growable: false)
          ..sort(),
      ),
    );
  }

  /// Фильтры и поиск складываются — то же правило, что будет на сервере.
  bool _matches(ScheduleRow row, ScheduleFilters filters) {
    if (filters.division == kWithoutDivision) {
      if (row.division != null) return false;
    } else if (filters.division != null &&
        row.division != filters.division!.title) {
      return false;
    }
    if (filters.typeObject != null && row.typeName != filters.typeObject!.title) {
      return false;
    }
    if (filters.name != null && row.name != filters.name!.title) return false;
    if (filters.factoryNumber != null &&
        row.factoryNumberLabel != filters.factoryNumber!.title) {
      return false;
    }
    if (filters.state != null && !_matchesState(row, filters.state!)) {
      return false;
    }

    final String text = filters.search.trim().toLowerCase();
    if (text.isEmpty) return true;

    // Тот же набор полей, что будет искать `ilike` на сервере, включая вид ТО:
    // «ТО 6» должно находить объект, у которого шестимесячное ТО стоит в марте.
    final Iterable<String> haystack = <String?>[
      row.name,
      row.factoryNumber,
      row.address,
      row.division,
      row.typeName,
      ...row.cells.map((MonthCell cell) => cell.toName),
    ].whereType<String>();

    return haystack.any((String value) => value.toLowerCase().contains(text));
  }

  bool _matchesState(ScheduleRow row, ScheduleState state) {
    final Set<MonthStatus> statuses =
        row.cells.map((MonthCell cell) => cell.status).toSet();

    switch (state) {
      case ScheduleState.hasOverdue:
        return statuses.contains(MonthStatus.overdue);
      case ScheduleState.hasLate:
        return statuses.contains(MonthStatus.late);
      case ScheduleState.hasPending:
        return statuses.contains(MonthStatus.pending);
      case ScheduleState.allDone:
        // «Всё выполнено» — про назначенное. Объект без графика сюда не
        // попадает: хвалить его не за что.
        return !row.hasNoSchedule &&
            statuses.every((MonthStatus status) =>
                status == MonthStatus.done ||
                status == MonthStatus.late ||
                status == MonthStatus.none);
    }
  }

  ScheduleRow _withYear(ScheduleRow row, int year) {
    if (row.year == year) return row;

    // Прошлый год закрыт целиком, будущий ещё не начинался: так видно, что
    // переключатель года действительно меняет ленту.
    final int now = DateTime.now().year;
    final MonthStatus fill = year < now ? MonthStatus.done : MonthStatus.pending;

    return ScheduleRow(
      objectId: row.objectId,
      name: row.name,
      year: year,
      factoryNumber: row.factoryNumber,
      address: row.address,
      division: row.division,
      foreman: row.foreman,
      typeName: row.typeName,
      cells: row.cells
          .map((MonthCell cell) => cell.status == MonthStatus.none
              ? cell
              : MonthCell(
                  month: cell.month,
                  status: fill,
                  toName: cell.toName,
                  actId: cell.actId,
                ))
          .toList(growable: false),
    );
  }

  static List<FilterOption> _options(List<String> values) {
    return List<FilterOption>.generate(
      values.length,
      (int index) => FilterOption(id: index + 1, title: values[index]),
      growable: false,
    );
  }
}

const List<String> _divisions = <String>[
  'Участок № 1',
  'Участок № 2',
  'Северная/Тургенева',
  'Московская/40 лет Победы',
  'Северная/Красная',
];

const List<String> _types = <String>[
  'Лифт без МП',
  'Лифт с МП',
  'Эскалатор',
  'Траволатор',
  'Грузовой лифт',
];

const List<String> _foremen = <String>[
  'Н.В. Гоголевский',
  'В.Р. Никифоров',
  'П.С. Василенко',
];

const List<String> _addresses = <String>[
  'г. Краснодар, ул. Северная, 356',
  'г. Краснодар, ул. Тургенева, 231',
  'г. Краснодар, ул. Московская, 26',
];

/// Раскладка видов ТО по месяцам: ежемесячное ТО 1, раз в квартал ТО 3,
/// полугодовое ТО 6, годовое ТО 12. Так же, как их набивают руками в графике.
String _toName(int month) {
  if (month == 12) return 'ТО 12';
  if (month % 6 == 0) return 'ТО 6';
  if (month % 3 == 0) return 'ТО 3';
  return 'ТО 1';
}

List<ScheduleRow> _generate(int count) {
  final int year = DateTime.now().year;
  final int currentMonth = DateTime.now().month;

  return List<ScheduleRow>.generate(count, (int index) {
    // Каждый десятый объект — без графика: пустая лента должна быть видна на
    // экране, а не только в теории.
    final bool noSchedule = index % 10 == 9;

    final List<MonthCell> cells = List<MonthCell>.generate(12, (int i) {
      final int month = i + 1;
      if (noSchedule) return MonthCell.empty(month);

      // Отдельные месяцы намеренно оставлены незанятыми: у объекта не обязан
      // быть заполнен весь год.
      if ((index + month) % 13 == 0) return MonthCell.empty(month);

      final MonthStatus status = _status(index, month, currentMonth);

      return MonthCell(
        month: month,
        status: status,
        toName: _toName(month),
        // У пустого месяца работы нет, у остальных — свой номер акта.
        actId: index * 12 + month,
      );
    }, growable: false);

    return ScheduleRow(
      objectId: index + 1,
      name: _name(index),
      year: year,
      factoryNumber: 'B7NS ${3400 + index}',
      address: _addresses[index % _addresses.length],
      division: _divisions[index % _divisions.length],
      foreman: _foremen[index % _foremen.length],
      typeName: _types[index % _types.length],
      cells: cells,
    );
  }, growable: false);
}

/// Состояние клетки в фикстуре.
///
/// Будущее — всегда «назначено»: показывать просрочку за не наступивший месяц
/// нельзя, и заглушка не должна учить экран неправде.
MonthStatus _status(int index, int month, int currentMonth) {
  if (month > currentMonth) return MonthStatus.pending;
  if (month == currentMonth) return MonthStatus.pending;

  switch ((index + month) % 7) {
    case 0:
      return MonthStatus.overdue;
    case 1:
    case 2:
      return MonthStatus.late;
    default:
      return MonthStatus.done;
  }
}

String _name(int index) {
  const List<String> names = <String>[
    'ТЦ Карнавал 3 этаж',
    'Красный дом на Северной',
    'Спортмастер',
    'Воздух.верх',
    'Лифт №',
  ];
  return '${names[index % names.length]} ${index + 1}';
}
