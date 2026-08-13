import 'package:flutter/material.dart';

import '../../../../helper/class_colors.dart';

/// Модели ответа `GET /api/v1/statistics/schedule-execution`.
///
/// Разбираются в типы, а не носятся как `Map<String, dynamic>`: половина
/// полей законно приходит `null` (участок без названия, участок без прораба),
/// и цепочка вроде `data['division']['title']` здесь означала бы красный
/// экран вместо виджета.

/// Участок в отчёте о выполнении графика ТО.
class ScheduleExecutionDivision {
  const ScheduleExecutionDivision({
    required this.divisionId,
    required this.division,
    required this.responsible,
    required this.responsibleCount,
    required this.plannedCount,
    required this.completedCount,
    required this.completedLateCount,
    required this.completionPercent,
  });

  /// `null` — объекты, у которых участок не проставлен.
  final int? divisionId;
  final String? division;

  /// Уже собранная бэкендом строка: одно имя либо «Никифоров +2».
  final String? responsible;
  final int responsibleCount;

  final int plannedCount;
  final int completedCount;

  /// Входит в [completedCount], а не считается отдельно от него.
  final int completedLateCount;

  final double completionPercent;

  String get divisionLabel => division?.trim().isNotEmpty == true
      ? division!.trim()
      : 'Без участка';

  String get responsibleLabel => responsible?.trim().isNotEmpty == true
      ? responsible!.trim()
      : '—';

  /// Доля для полосы прогресса. Обрезается по краям: полоса с percent > 1
  /// роняет `LinearPercentIndicator` исключением, а не рисует переполнение.
  double get fraction => (completionPercent / 100).clamp(0.0, 1.0);

  /// Цвет полосы. Пороги грубые намеренно: карточка нужна, чтобы отличить
  /// «всё сделано» от «участок провалился», а не чтобы читать проценты.
  Color get color {
    if (completionPercent >= 90) return ColorApp.myColorGreen;
    if (completionPercent >= 70) return ColorApp.myColorYellow;
    return ColorApp.myColorRed;
  }

  factory ScheduleExecutionDivision.fromJson(Map<String, dynamic> json) {
    return ScheduleExecutionDivision(
      divisionId: _asInt(json['division_id']),
      division: _asString(json['division']),
      responsible: _asString(json['responsible']),
      responsibleCount: _asInt(json['responsible_count']) ?? 0,
      plannedCount: _asInt(json['planned_count']) ?? 0,
      completedCount: _asInt(json['completed_count']) ?? 0,
      completedLateCount: _asInt(json['completed_late_count']) ?? 0,
      completionPercent: _asDouble(json['completion_percent']) ?? 0,
    );
  }
}

/// Выполнение графика ТО за месяц.
class ScheduleExecutionReport {
  const ScheduleExecutionReport({
    required this.year,
    required this.month,
    required this.plannedCount,
    required this.completedCount,
    required this.completedLateCount,
    required this.completionPercent,
    required this.items,
  });

  final int year;
  final int month;
  final int plannedCount;
  final int completedCount;
  final int completedLateCount;
  final double completionPercent;
  final List<ScheduleExecutionDivision> items;

  /// Пусто — значит на этот месяц не заведено ни одного ТО. Это не ошибка и
  /// не ноль процентов: график просто не заполнен.
  bool get isEmpty => items.isEmpty;

  factory ScheduleExecutionReport.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> period = _asMap(json['period']);
    return ScheduleExecutionReport(
      year: _asInt(period['year']) ?? 0,
      month: _asInt(period['month']) ?? 0,
      plannedCount: _asInt(json['planned_count']) ?? 0,
      completedCount: _asInt(json['completed_count']) ?? 0,
      completedLateCount: _asInt(json['completed_late_count']) ?? 0,
      completionPercent: _asDouble(json['completion_percent']) ?? 0,
      items: _asList(json['items'])
          .map(ScheduleExecutionDivision.fromJson)
          .toList(growable: false),
    );
  }
}

int? _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

double? _asDouble(dynamic value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

String? _asString(dynamic value) {
  if (value is String) return value;
  return null;
}

List<Map<String, dynamic>> _asList(dynamic value) {
  if (value is! List) return const <Map<String, dynamic>>[];
  return value
      .whereType<Map>()
      .map((Map item) => item.cast<String, dynamic>())
      .toList(growable: false);
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map) return value.cast<String, dynamic>();
  return <String, dynamic>{};
}
