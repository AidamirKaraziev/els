import '../models/defect_row.dart';
import '../models/object_works.dart';
import '../models/works_report.dart';
import 'works_report_repository.dart';

/// Раздел «Отчёты» в памяти — подстава для тестов экрана и для точки входа
/// `dev/report_preview.dart`.
///
/// Живёт в `lib/`, а не в `test/`, по той же причине, что и фикстура
/// графиков: макет показывают в браузере без сервера. В прод-сборку не
/// попадает — `main.dart` на неё не ссылается.
///
/// Данные подобраны так, чтобы были видны все случаи блока дефектных актов:
/// объект без актов, объект с тремя, объект с семнадцатью; месяцы с актами и
/// без; текущий месяц (сентябрь 2026) без актов — тогда плитка сводки
/// серая. Отчёт собирается через `fromJson`, а не конструкторами:
/// так фикстура повторяет форму ответа сервера и её видно глазами.
class FixtureWorksReportRepository extends WorksReportRepository {
  const FixtureWorksReportRepository({
    this.delay = const Duration(milliseconds: 350),
  });

  /// Задержка нужна: без неё не видно загрузки, и экран нельзя проверить
  /// глазами. Тесты задают ноль — тогда таймер не ставится вовсе: под
  /// `testWidgets` время подставное, и даже нулевой таймер без прокрутки
  /// не сработает — тест бы повис на первом же `await`.
  final Duration delay;

  Future<void> _wait() async {
    if (delay > Duration.zero) await Future<void>.delayed(delay);
  }

  static const int _year = 2026;

  @override
  Future<WorksReport> fetch({
    required ReportFilters filters,
    int limit = 25,
    int offset = 0,
  }) async {
    await _wait();
    final List<int> months = _monthsOf(filters);
    // Страница отбора: три «живых» объекта идут первыми, дальше — наполнение,
    // чтобы листание по 25/50/100 было видно глазами.
    final List<Map<String, dynamic>> items = _allObjects
        .skip(offset)
        .take(limit)
        .map((_FixtureObject object) => object.toRow(months))
        .toList(growable: false);

    final int defects = _objects.fold<int>(
      0,
      (int sum, _FixtureObject object) => sum + object.defectsIn(months),
    );
    final int breakdowns = _objects.fold<int>(
      0,
      (int sum, _FixtureObject object) => sum + object.breakdownsIn(months),
    );

    return WorksReport.fromJson(<String, dynamic>{
      'period': _period(filters, months),
      'summary': <String, dynamic>{
        'objects_total': _allObjects.length,
        'objects_without_breakdowns': _allObjects
            .where((_FixtureObject object) => object.breakdownsIn(months) == 0)
            .length,
        'maintenance_planned': months.length * _allObjects.length,
        'maintenance_completed': months.length * _allObjects.length - 2,
        'maintenance_late': 1,
        'maintenance_overdue': 2,
        'completion_percent': 92.0,
        'counts': <String, dynamic>{
          'breakdowns': breakdowns,
          'client_requests': 4,
          'other_requests': 1,
          'defects': defects,
        },
        'avg_reaction_hours': 1.5,
        'reacted_count': breakdowns,
      },
      'months': months
          .map((int month) => <String, dynamic>{
                'year': _year,
                'month': month,
                'maintenance_planned': _allObjects.length,
                'maintenance_completed': _allObjects.length,
                'counts': <String, dynamic>{
                  'breakdowns': month.isEven ? 1 : 0,
                  'defects': _objects.fold<int>(
                    0,
                    (int sum, _FixtureObject object) =>
                        sum + object.defectsIn(<int>[month]),
                  ),
                },
              })
          .toList(growable: false),
      'total_objects': _allObjects.length,
      'items': items,
    });
  }

  @override
  Future<ObjectWorksReport> fetchObjectWorks({
    required int objectId,
    required ReportFilters filters,
  }) async {
    await _wait();
    final List<int> months = _monthsOf(filters);
    final _FixtureObject object = _allObjects.firstWhere(
      (_FixtureObject candidate) => candidate.id == objectId,
      orElse: () => _objects.first,
    );

    return ObjectWorksReport.fromJson(<String, dynamic>{
      'object': object.toRow(months),
      'period': _period(filters, months),
      'maintenance': months
          .map((int month) => <String, dynamic>{
                'act_id': objectId * 100 + month,
                'year': _year,
                'month': month,
                'status': 'done',
                'started_at': '$_year-${_two(month)}-03T09:00:00',
                'finished_at': '$_year-${_two(month)}-03T11:30:00',
                'foreman': 'Сергеев П. А.',
                'mechanic': object.mechanic,
                'steps': <Map<String, dynamic>>[
                  <String, dynamic>{'title': 'Осмотр шахты', 'done': true},
                  <String, dynamic>{'title': 'Проверка ловителей', 'done': true},
                ],
                'defects': object.defectsJson(month),
              })
          .toList(growable: false),
      'requests': <Map<String, dynamic>>[
        if (object.breakdownsIn(months) > 0)
          <String, dynamic>{
            'kind': 'breakdown',
            'order_id': objectId * 10,
            'created_at': '$_year-${_two(months.first)}-14T08:12:00',
            'accepted_at': '$_year-${_two(months.first)}-14T09:40:00',
            'done_at': '$_year-${_two(months.first)}-14T12:05:00',
            'reaction_hours': 1.5,
            'category': 'Остановка кабины',
            'reason': 'застряла кабина между этажами',
            'status': 'done',
            'executor': object.mechanic,
            'photo_count': 2,
          },
      ],
      'defects': object.defectsJson(null, months: months),
    });
  }

  /// Акты всего отбора за период — то, что откроется с плитки сводки.
  ///
  /// Собирается из тех же актов, что лежат в шторках объектов, — как и на
  /// сервере, где список и число плитки считает один запрос.
  @override
  Future<List<ReportDefectRow>> fetchDefects({
    required ReportFilters filters,
  }) async {
    await _wait();
    final List<int> months = _monthsOf(filters);
    return _objects
        .expand((_FixtureObject object) => object
            .defectsJson(null, months: months)
            .map((Map<String, dynamic> raw) => ReportDefectRow.fromJson(
                  <String, dynamic>{
                    ...raw,
                    'object_id': object.id,
                    'object_name': object.name,
                    'address': object.address,
                  },
                )))
        .toList(growable: false);
  }

  @override
  Future<String> exportUrl({
    required ReportFilters filters,
    required String format,
    bool withPhotos = false,
    List<int>? objectIds,
  }) async {
    return 'about:blank';
  }

  static List<int> _monthsOf(ReportFilters filters) {
    if (filters.dateFrom.year > _year || filters.dateTo.year < _year) {
      return const <int>[];
    }
    final int from = filters.dateFrom.year < _year ? 1 : filters.dateFrom.month;
    final int to = filters.dateTo.year > _year ? 12 : filters.dateTo.month;
    return List<int>.generate(to - from + 1, (int index) => from + index);
  }

  static Map<String, dynamic> _period(ReportFilters filters, List<int> months) {
    return <String, dynamic>{
      'date_from': ReportFilters.dateLabel(filters.dateFrom),
      'date_to': ReportFilters.dateLabel(filters.dateTo),
      'month_from': <String, dynamic>{
        'year': _year,
        'month': months.isEmpty ? filters.dateFrom.month : months.first,
      },
      'month_to': <String, dynamic>{
        'year': _year,
        'month': months.isEmpty ? filters.dateTo.month : months.last,
      },
      'months_count': months.length,
    };
  }

  static String _two(int value) => value.toString().padLeft(2, '0');
}

/// Объект фикстуры: акты заданы списком «месяц → названия».
class _FixtureObject {
  const _FixtureObject({
    required this.id,
    required this.name,
    required this.address,
    required this.mechanic,
    required this.defects,
    this.breakdownMonths = const <int>[],
  });

  final int id;
  final String name;
  final String address;
  final String mechanic;
  final Map<int, List<String>> defects;
  final List<int> breakdownMonths;

  int defectsIn(List<int> months) => months.fold<int>(
        0,
        (int sum, int month) => sum + (defects[month]?.length ?? 0),
      );

  int breakdownsIn(List<int> months) =>
      breakdownMonths.where(months.contains).length;

  Map<String, dynamic> toRow(List<int> months) => <String, dynamic>{
        'object_id': id,
        'object_name': name,
        'address': address,
        'responsible_mechanic': mechanic,
        'division': 'Участок №2',
        'maintenance_planned': months.length,
        'maintenance_completed': months.length,
        'maintenance_late': 0,
        'maintenance_overdue': 0,
        'counts': <String, dynamic>{
          'breakdowns': breakdownsIn(months),
          'defects': defectsIn(months),
        },
        'months': months
            .map((int month) => <String, dynamic>{
                  'year': FixtureWorksReportRepository._year,
                  'month': month,
                  'maintenance': 'done',
                  'counts': <String, dynamic>{
                    'breakdowns': breakdownMonths.contains(month) ? 1 : 0,
                    'defects': defects[month]?.length ?? 0,
                  },
                  'works_total': (defects[month]?.length ?? 0) +
                      (breakdownMonths.contains(month) ? 1 : 0),
                })
            .toList(growable: false),
      };

  /// Акты за месяц, а при `month == null` — за все [months].
  List<Map<String, dynamic>> defectsJson(int? month, {List<int>? months}) {
    final List<int> wanted = month != null ? <int>[month] : months ?? <int>[];
    final List<Map<String, dynamic>> out = <Map<String, dynamic>>[];
    for (final int item in wanted) {
      final List<String> titles = defects[item] ?? const <String>[];
      for (int index = 0; index < titles.length; index++) {
        out.add(<String, dynamic>{
          'defect_id': id * 1000 + item * 10 + index,
          'title': titles[index],
          'description': index.isEven ? 'Выявлено при плановом ТО' : null,
          'month': item,
          'status': index == 0 ? 'open' : 'done',
          'responsible': mechanic,
          'created_at': '${FixtureWorksReportRepository._year}-'
              '${item.toString().padLeft(2, '0')}-05T10:00:00',
          'photo_count': index,
        });
      }
    }
    return out;
  }
}

/// Весь отбор фикстуры: три объекта с актами и наполнение до 62 штук —
/// столько, чтобы на странице по 25 было три страницы, по 50 — две,
/// по 100 — одна.
final List<_FixtureObject> _allObjects = <_FixtureObject>[
  ..._objects,
  for (int index = 1; index <= 59; index++)
    _FixtureObject(
      id: 100 + index,
      name: 'Лифт ${index.toString().padLeft(2, '0')}',
      address: 'ул. Строителей, ${index * 2}',
      mechanic: 'Петров П. П.',
      defects: const <int, List<String>>{},
    ),
];

const List<_FixtureObject> _objects = <_FixtureObject>[
  _FixtureObject(
    id: 44,
    name: 'Эскалатор 2а «Лакоста»',
    address: 'ул. Ленина, 12',
    mechanic: 'Иванов И. И.',
    defects: <int, List<String>>{
      2: <String>['Износ поручня', 'Люфт гребёнки', 'Шум редуктора'],
    },
    breakdownMonths: <int>[2, 6],
  ),
  _FixtureObject(
    id: 45,
    name: 'Лифт 7, подъезд 3',
    address: 'пр. Мира, 101',
    mechanic: 'Петров П. П.',
    defects: <int, List<String>>{},
  ),
  _FixtureObject(
    id: 46,
    name: 'Лифт грузовой 2000 кг',
    address: 'Индустриальная, 8к2',
    mechanic: 'Сидоров С. С.',
    defects: <int, List<String>>{
      1: <String>['Течь масла', 'Обрыв троса ограничителя'],
      3: <String>['Дверь шахты не запирается'],
      4: <String>['Износ вкладышей', 'Трещина рамы', 'Люфт башмаков'],
      5: <String>['Потёртость канатов', 'Гул двигателя'],
      7: <String>['Скрип дверей кабины', 'Перекос кабины', 'Шум редуктора'],
      // Сентября нет нарочно: «Месяц» на сегодняшней дате показывает
      // серую плитку.
      10: <String>['Обрыв кнопки вызова', 'Не горит табло'],
      11: <String>['Течь масла', 'Люфт гребёнки'],
    },
    breakdownMonths: <int>[4],
  ),
];
