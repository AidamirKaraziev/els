import 'package:flutter/material.dart';

import '../../../helper/class_colors.dart';

/// Модели ответа `GET /api/v1/reports/works`.
///
/// Разбираются в типы, а не носятся как `Map<String, dynamic>`: половина
/// полей законно приходит `null` — объект без адреса, без клиента, без
/// закреплённого механика.

/// Состояние планового ТО за месяц.
///
/// Пять значений, а не два. `pending` и `overdue` различаются только тем,
/// кончился ли плановый месяц: незакрытое ТО за текущий месяц — работа
/// впереди, а за прошедший — долг. Смешивать их нельзя, иначе первого числа
/// каждого месяца экран показывал бы всплеск просрочки на ровном месте.
enum MaintenanceStatus { none, done, late, pending, overdue }

/// Разбор статуса ТО из строки ответа.
///
/// Общая, а не приватная: тем же статусом описано ТО и в матрице, и в
/// раскрытой строке объекта. Два разбора однажды разъехались бы.
MaintenanceStatus maintenanceStatusFrom(dynamic raw) {
  switch (raw) {
    case 'done':
      return MaintenanceStatus.done;
    case 'late':
      return MaintenanceStatus.late;
    case 'pending':
      return MaintenanceStatus.pending;
    case 'overdue':
      return MaintenanceStatus.overdue;
    default:
      return MaintenanceStatus.none;
  }
}

/// Цвет ячейки месяца.
///
/// Взят из макета: в кадре «Окно с графиками» строка объекта — это двенадцать
/// квадратов в зелёном, жёлтом и красном. Свой набор цветов означал бы, что
/// один и тот же факт выглядит в системе по-разному.
Color maintenanceColor(MaintenanceStatus status) {
  switch (status) {
    case MaintenanceStatus.done:
      return ColorApp.myColorGreen;
    case MaintenanceStatus.late:
      return ColorApp.myColorYellow;
    case MaintenanceStatus.overdue:
      return ColorApp.myColorRed;
    case MaintenanceStatus.pending:
      return ColorApp.myColorGrayBorder;
    case MaintenanceStatus.none:
      return Colors.transparent;
  }
}

String maintenanceLabel(MaintenanceStatus status) {
  switch (status) {
    case MaintenanceStatus.done:
      return 'ТО выполнено в срок';
    case MaintenanceStatus.late:
      return 'ТО выполнено с опозданием';
    case MaintenanceStatus.overdue:
      return 'ТО просрочено';
    case MaintenanceStatus.pending:
      return 'ТО не выполнено, месяц идёт';
    case MaintenanceStatus.none:
      return 'ТО не планировалось';
  }
}

int _int(dynamic value) => value is num ? value.toInt() : 0;

double? _double(dynamic value) => value is num ? value.toDouble() : null;

String? _string(dynamic value) {
  if (value is! String) return null;
  final String trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

DateTime? _dateTime(dynamic value) =>
    value is String ? DateTime.tryParse(value) : null;

/// Сколько работ каждого вида. Плановое ТО сюда не входит: у него состояние,
/// а не количество.
class WorkCounts {
  const WorkCounts({
    this.breakdowns = 0,
    this.clientRequests = 0,
    this.otherRequests = 0,
    this.defects = 0,
  });

  factory WorkCounts.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const WorkCounts();
    return WorkCounts(
      breakdowns: _int(json['breakdowns']),
      clientRequests: _int(json['client_requests']),
      otherRequests: _int(json['other_requests']),
      defects: _int(json['defects']),
    );
  }

  final int breakdowns;
  final int clientRequests;
  final int otherRequests;
  final int defects;

  int get total => breakdowns + clientRequests + otherRequests + defects;
}

/// Год и месяц — граница периода в терминах плана ТО.
class ReportMonth {
  const ReportMonth({required this.year, required this.month});

  factory ReportMonth.fromJson(Map<String, dynamic> json) => ReportMonth(
        year: _int(json['year']),
        month: _int(json['month']),
      );

  final int year;
  final int month;
}

/// Период отчёта: как его попросили и как он считался на самом деле.
///
/// Даты и месяцы расходятся намеренно: у ячейки графика нет дня, поэтому ТО
/// попадает в отчёт, если его плановый месяц пересекается с периодом. Экран
/// обязан сказать об этом словами, иначе лишнее ТО выглядит ошибкой счёта.
class ReportPeriod {
  const ReportPeriod({
    required this.dateFrom,
    required this.dateTo,
    required this.monthFrom,
    required this.monthTo,
    required this.monthsCount,
  });

  factory ReportPeriod.fromJson(Map<String, dynamic> json) => ReportPeriod(
        dateFrom: DateTime.tryParse('${json['date_from']}') ?? DateTime.now(),
        dateTo: DateTime.tryParse('${json['date_to']}') ?? DateTime.now(),
        monthFrom: ReportMonth.fromJson(
          (json['month_from'] as Map?)?.cast<String, dynamic>() ??
              <String, dynamic>{},
        ),
        monthTo: ReportMonth.fromJson(
          (json['month_to'] as Map?)?.cast<String, dynamic>() ??
              <String, dynamic>{},
        ),
        monthsCount: _int(json['months_count']),
      );

  final DateTime dateFrom;
  final DateTime dateTo;
  final ReportMonth monthFrom;
  final ReportMonth monthTo;
  final int monthsCount;

  /// Захватил ли отчёт больше месяцев, чем просили датами.
  ///
  /// Если да — под фильтрами появляется пояснение. Без него человек увидит
  /// ТО за март в отчёте «с 15 марта» и решит, что мы ошиблись.
  bool get widerThanAsked =>
      dateFrom.day != 1 || dateTo.day != _lastDayOf(dateTo);

  static int _lastDayOf(DateTime date) =>
      DateTime(date.year, date.month + 1, 0).day;
}

/// Один месяц одного объекта — ячейка матрицы.
class MonthCell {
  const MonthCell({
    required this.year,
    required this.month,
    required this.maintenance,
    required this.maintenanceFinishedAt,
    required this.counts,
    required this.worksTotal,
  });

  factory MonthCell.fromJson(Map<String, dynamic> json) => MonthCell(
        year: _int(json['year']),
        month: _int(json['month']),
        maintenance: maintenanceStatusFrom(json['maintenance']),
        maintenanceFinishedAt: _dateTime(json['maintenance_finished_at']),
        counts: WorkCounts.fromJson(
          (json['counts'] as Map?)?.cast<String, dynamic>(),
        ),
        worksTotal: _int(json['works_total']),
      );

  final int year;
  final int month;
  final MaintenanceStatus maintenance;
  final DateTime? maintenanceFinishedAt;
  final WorkCounts counts;
  final int worksTotal;

  bool get isEmpty =>
      maintenance == MaintenanceStatus.none && counts.total == 0;
}

/// Объект (лифт) в отчёте: карточка слева, ячейки месяцев справа.
class ReportObjectRow {
  const ReportObjectRow({
    required this.objectId,
    required this.objectName,
    required this.registrationNumber,
    required this.factoryNumber,
    required this.address,
    required this.client,
    required this.division,
    required this.factoryModel,
    required this.responsibleMechanic,
    required this.responsibleForeman,
    required this.maintenancePlanned,
    required this.maintenanceCompleted,
    required this.maintenanceLate,
    required this.maintenanceOverdue,
    required this.counts,
    required this.months,
  });

  factory ReportObjectRow.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawMonths =
        json['months'] is List ? json['months'] as List<dynamic> : <dynamic>[];
    return ReportObjectRow(
      objectId: _int(json['object_id']),
      objectName: _string(json['object_name']),
      registrationNumber: _string(json['registration_number']),
      factoryNumber: _string(json['factory_number']),
      address: _string(json['address']),
      client: _string(json['client']),
      division: _string(json['division']),
      factoryModel: _string(json['factory_model']),
      responsibleMechanic: _string(json['responsible_mechanic']),
      responsibleForeman: _string(json['responsible_foreman']),
      maintenancePlanned: _int(json['maintenance_planned']),
      maintenanceCompleted: _int(json['maintenance_completed']),
      maintenanceLate: _int(json['maintenance_late']),
      maintenanceOverdue: _int(json['maintenance_overdue']),
      counts: WorkCounts.fromJson(
        (json['counts'] as Map?)?.cast<String, dynamic>(),
      ),
      months: rawMonths
          .whereType<Map>()
          .map((Map raw) => MonthCell.fromJson(raw.cast<String, dynamic>()))
          .toList(growable: false),
    );
  }

  final int objectId;
  final String? objectName;
  final String? registrationNumber;
  final String? factoryNumber;
  final String? address;
  final String? client;
  final String? division;
  final String? factoryModel;
  final String? responsibleMechanic;
  final String? responsibleForeman;

  final int maintenancePlanned;
  final int maintenanceCompleted;
  final int maintenanceLate;
  final int maintenanceOverdue;
  final WorkCounts counts;
  final List<MonthCell> months;

  /// Чем подписать объект. Название заполнено не всегда, и «Объект 42» лучше
  /// пустой ячейки: по нему хотя бы понятно, что спрашивать.
  String get objectLabel {
    for (final String? candidate in <String?>[
      objectName,
      registrationNumber,
      factoryNumber,
    ]) {
      if (candidate?.isNotEmpty == true) return candidate!;
    }
    return 'Объект $objectId';
  }

  String get addressLabel => address ?? '—';

  /// «11 из 12» — короткая сводка по ТО для строки.
  String get maintenanceSummary =>
      maintenancePlanned == 0 ? '—' : '$maintenanceCompleted из $maintenancePlanned';
}

/// Столбик помесячной полосы: свод по всем объектам отбора.
class MonthTotals {
  const MonthTotals({
    required this.year,
    required this.month,
    required this.maintenancePlanned,
    required this.maintenanceCompleted,
    required this.counts,
  });

  factory MonthTotals.fromJson(Map<String, dynamic> json) => MonthTotals(
        year: _int(json['year']),
        month: _int(json['month']),
        maintenancePlanned: _int(json['maintenance_planned']),
        maintenanceCompleted: _int(json['maintenance_completed']),
        counts: WorkCounts.fromJson(
          (json['counts'] as Map?)?.cast<String, dynamic>(),
        ),
      );

  final int year;
  final int month;
  final int maintenancePlanned;
  final int maintenanceCompleted;
  final WorkCounts counts;
}

/// Краткая сводка за период — верх экрана.
class ReportSummary {
  const ReportSummary({
    required this.objectsTotal,
    required this.objectsWithoutBreakdowns,
    required this.maintenancePlanned,
    required this.maintenanceCompleted,
    required this.maintenanceLate,
    required this.maintenanceOverdue,
    required this.completionPercent,
    required this.counts,
    required this.avgReactionHours,
    required this.reactedCount,
  });

  factory ReportSummary.fromJson(Map<String, dynamic> json) => ReportSummary(
        objectsTotal: _int(json['objects_total']),
        objectsWithoutBreakdowns: _int(json['objects_without_breakdowns']),
        maintenancePlanned: _int(json['maintenance_planned']),
        maintenanceCompleted: _int(json['maintenance_completed']),
        maintenanceLate: _int(json['maintenance_late']),
        maintenanceOverdue: _int(json['maintenance_overdue']),
        completionPercent: _double(json['completion_percent']) ?? 0,
        counts: WorkCounts.fromJson(
          (json['counts'] as Map?)?.cast<String, dynamic>(),
        ),
        avgReactionHours: _double(json['avg_reaction_hours']),
        reactedCount: _int(json['reacted_count']),
      );

  final int objectsTotal;
  final int objectsWithoutBreakdowns;
  final int maintenancePlanned;
  final int maintenanceCompleted;
  final int maintenanceLate;
  final int maintenanceOverdue;
  final double completionPercent;
  final WorkCounts counts;
  final double? avgReactionHours;
  final int reactedCount;

  /// Время реакции без числа заявок — бессмысленная цифра: «2 ч» по одной
  /// заявке из сорока и «2 ч» по сорока выглядят одинаково.
  String get reactionLabel {
    if (avgReactionHours == null || reactedCount == 0) return '—';
    return '$avgReactionHours ч';
  }
}

/// Отчёт о работах на объектах за период.
class WorksReport {
  const WorksReport({
    required this.period,
    required this.summary,
    required this.months,
    required this.totalObjects,
    required this.items,
  });

  factory WorksReport.fromJson(Map<String, dynamic> json) {
    final List<dynamic> rawMonths =
        json['months'] is List ? json['months'] as List<dynamic> : <dynamic>[];
    final List<dynamic> rawItems =
        json['items'] is List ? json['items'] as List<dynamic> : <dynamic>[];

    return WorksReport(
      period: ReportPeriod.fromJson(
        (json['period'] as Map?)?.cast<String, dynamic>() ??
            <String, dynamic>{},
      ),
      summary: ReportSummary.fromJson(
        (json['summary'] as Map?)?.cast<String, dynamic>() ??
            <String, dynamic>{},
      ),
      months: rawMonths
          .whereType<Map>()
          .map((Map raw) => MonthTotals.fromJson(raw.cast<String, dynamic>()))
          .toList(growable: false),
      totalObjects: _int(json['total_objects']),
      items: rawItems
          .whereType<Map>()
          .map((Map raw) =>
              ReportObjectRow.fromJson(raw.cast<String, dynamic>()))
          .toList(growable: false),
    );
  }

  final ReportPeriod period;
  final ReportSummary summary;
  final List<MonthTotals> months;
  final int totalObjects;
  final List<ReportObjectRow> items;

  bool get isEmpty => items.isEmpty;
}

/// Короткие имена месяцев для шапки матрицы.
const List<String> monthShortNames = <String>[
  'Янв',
  'Фев',
  'Мар',
  'Апр',
  'Май',
  'Июн',
  'Июл',
  'Авг',
  'Сен',
  'Окт',
  'Ноя',
  'Дек',
];

const List<String> monthFullNames = <String>[
  'январь',
  'февраль',
  'март',
  'апрель',
  'май',
  'июнь',
  'июль',
  'август',
  'сентябрь',
  'октябрь',
  'ноябрь',
  'декабрь',
];
