import 'package:flutter/material.dart';

import '../../../../helper/class_colors.dart';
import '../../../../helper/session.dart';

/// Модели ответа `GET /api/v1/statistics/top-employees`.
///
/// Разбираются в типы, а не носятся как `Map<String, dynamic>`: половина
/// полей законно приходит `null` — сотрудник без участка, метрика, которую в
/// этом месяце не из чего было посчитать, балл, которого нет вовсе.

/// Кого ранжируем. Прорабов может смотреть только админ.
enum EmployeeKind { mechanic, foreman }

extension EmployeeKindQuery on EmployeeKind {
  String get value => this == EmployeeKind.foreman ? 'foreman' : 'mechanic';

  String get label => this == EmployeeKind.foreman ? 'Прорабы' : 'Механики';
}

/// Порядок выдачи: лучшие сверху или худшие.
enum EmployeeOrder { best, worst }

extension EmployeeOrderQuery on EmployeeOrder {
  String get value => this == EmployeeOrder.worst ? 'worst' : 'best';

  String get label => this == EmployeeOrder.worst ? 'Худшие' : 'Лучшие';
}

/// Строка рейтинга.
class EmployeeScoreItem {
  const EmployeeScoreItem({
    required this.userId,
    required this.name,
    required this.roleId,
    required this.division,
    required this.score,
    required this.isProvisional,
    required this.worksCount,
    required this.ordersClosed,
    required this.maintenanceTotal,
    required this.maintenanceOnTime,
    required this.objectsCount,
    required this.breakdownsOnObjects,
    required this.repeatCount,
    required this.avgReactionHours,
  });

  final int userId;
  final String? name;
  final int? roleId;
  final String? division;

  /// 0–100. `null` — считать было не из чего: ни работ, ни закреплённых
  /// лифтов за месяц.
  final double? score;

  /// Работ меньше порога: цифре верить рано, и в вершину списка строка не
  /// попадает.
  final bool isProvisional;

  final int worksCount;
  final int ordersClosed;
  final int maintenanceTotal;
  final int maintenanceOnTime;
  final int objectsCount;
  final int breakdownsOnObjects;
  final int repeatCount;
  final double? avgReactionHours;

  String get nameLabel =>
      name?.trim().isNotEmpty == true ? name!.trim() : 'Сотрудник $userId';

  String get divisionLabel =>
      division?.trim().isNotEmpty == true ? division!.trim() : '—';

  String get roleLabel => Roles.names[roleId ?? 0] ?? '—';

  /// «87» или «—». Дробную часть не показываем: разговор о человеке не
  /// становится точнее от десятой доли балла.
  String get scoreLabel => score == null ? '—' : score!.round().toString();

  /// Чем занят человек — второй строкой под фамилией. Собирается из того,
  /// что в этом месяце вообще было: «4 заявки · 2 ТО».
  String get workLabel {
    final List<String> parts = <String>[];
    if (ordersClosed > 0) {
      final String word = _plural(ordersClosed, 'заявка', 'заявки', 'заявок');
      parts.add('$ordersClosed $word');
    }
    if (maintenanceTotal > 0) {
      parts.add('$maintenanceOnTime из $maintenanceTotal ТО в срок');
    }
    if (parts.isEmpty) {
      return 'Работ за месяц нет';
    }
    return parts.join(' · ');
  }

  /// Цвет бейджа с баллом. Три ступени, все из палитры приложения: зелёный —
  /// норма, жёлтый — есть о чём поговорить, красный — разбор.
  Color get color {
    if (score == null || isProvisional) return ColorApp.myColorGrayText;
    if (score! >= 75) return ColorApp.myColorGreenAuth;
    if (score! >= 50) return ColorApp.myColorYellow;
    return ColorApp.myColorRed;
  }

  factory EmployeeScoreItem.fromJson(Map<String, dynamic> json) {
    return EmployeeScoreItem(
      userId: _asInt(json['user_id']) ?? 0,
      name: _asString(json['name']),
      roleId: _asInt(json['role_id']),
      division: _asString(json['division']),
      score: _asDouble(json['score']),
      isProvisional: json['is_provisional'] == true,
      worksCount: _asInt(json['works_count']) ?? 0,
      ordersClosed: _asInt(json['orders_closed']) ?? 0,
      maintenanceTotal: _asInt(json['maintenance_total']) ?? 0,
      maintenanceOnTime: _asInt(json['maintenance_on_time']) ?? 0,
      objectsCount: _asInt(json['objects_count']) ?? 0,
      breakdownsOnObjects: _asInt(json['breakdowns_on_objects']) ?? 0,
      repeatCount: _asInt(json['repeat_count']) ?? 0,
      avgReactionHours: _asDouble(json['avg_reaction_hours']),
    );
  }
}

/// Рейтинг сотрудников за месяц.
class TopEmployeesReport {
  const TopEmployeesReport({
    required this.year,
    required this.month,
    required this.totalCount,
    required this.rankedCount,
    required this.minWorks,
    required this.items,
  });

  final int year;
  final int month;

  /// По всей выборке, а не по обрезанному `limit` списку.
  final int totalCount;

  /// Сколько из них с полноценным баллом. Пустая карточка при ненулевом
  /// `totalCount` означает «людей видно, работ за месяц нет» — это разные
  /// новости, и подпись под списком должна их различать.
  final int rankedCount;

  /// Порог активности, который применил сервер. Нужен подписи «мало данных».
  final int minWorks;

  final List<EmployeeScoreItem> items;

  bool get isEmpty => items.isEmpty;

  factory TopEmployeesReport.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> period = _asMap(json['period']);
    return TopEmployeesReport(
      year: _asInt(period['year']) ?? 0,
      month: _asInt(period['month']) ?? 0,
      totalCount: _asInt(json['total_count']) ?? 0,
      rankedCount: _asInt(json['ranked_count']) ?? 0,
      minWorks: _asInt(json['min_works']) ?? 0,
      items: _asList(json['items'])
          .map(EmployeeScoreItem.fromJson)
          .toList(growable: false),
    );
  }
}

String _plural(int count, String one, String few, String many) {
  final int mod100 = count % 100;
  if (mod100 >= 11 && mod100 <= 14) return many;
  switch (count % 10) {
    case 1:
      return one;
    case 2:
    case 3:
    case 4:
      return few;
    default:
      return many;
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
