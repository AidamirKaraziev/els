import 'package:flutter/material.dart';

import '../../../../helper/class_colors.dart';

/// Модели ответа `GET /api/v1/statistics/breakdowns`.
///
/// Остальной код приложения носит ответы как `Map<String, dynamic>` и лазит
/// в них цепочками вроде `data['status_id']['name']`. Здесь так нельзя:
/// у отчёта два уровня вложенности и поля, которые законно приходят `null`
/// (время реакции, дельта, категория у незаполненной заявки). Любая такая
/// цепочка — это красный экран у заказчика вместо виджета.

/// Сколько заявок пришлось на одну категорию тяжести.
class SeverityCount {
  const SeverityCount({
    required this.categoryId,
    required this.code,
    required this.name,
    required this.count,
    required this.share,
  });

  /// `null` — заявки, у которых категория не проставлена.
  final int? categoryId;
  final String? code;
  final String? name;
  final int count;
  final double share;

  /// Что писать в чипе. У заявок без категории кода нет.
  String get label => (code == null || code!.isEmpty) ? 'Без категории' : code!;

  /// Цвет по тяжести. Коды взяты из отраслевой классификации, которую
  /// бэкенд отдаёт в поле `code`; всё незнакомое — серое, а не красное:
  /// новая категория не должна выглядеть аварией.
  Color get color {
    switch (code) {
      case 'AA':
        return ColorApp.myColorRed;
      case 'А':
        return ColorApp.myColorYellow;
      case 'В':
        return ColorApp.myColorBlue;
      default:
        return ColorApp.myColorGray;
    }
  }

  factory SeverityCount.fromJson(Map<String, dynamic> json) {
    return SeverityCount(
      categoryId: _asInt(json['category_id']),
      code: _asString(json['code']),
      name: _asString(json['name']),
      count: _asInt(json['count']) ?? 0,
      share: _asDouble(json['share']) ?? 0,
    );
  }
}

/// Объект (лифт) в топе поломок.
class BreakdownObject {
  const BreakdownObject({
    required this.objectId,
    required this.objectName,
    required this.registrationNumber,
    required this.factoryNumber,
    required this.address,
    required this.client,
    required this.division,
    required this.factoryModel,
    required this.responsibleMechanic,
    required this.breakdownCount,
    required this.severity,
    required this.avgReactionHours,
    required this.reactedCount,
    required this.avgResolutionHours,
    required this.resolvedCount,
    required this.previousCount,
    required this.delta,
  });

  final int objectId;
  final String? objectName;
  final String? registrationNumber;
  final String? factoryNumber;
  final String? address;
  final String? client;
  final String? division;
  final String? factoryModel;
  final String? responsibleMechanic;

  final int breakdownCount;
  final List<SeverityCount> severity;

  final double? avgReactionHours;
  final int reactedCount;
  final double? avgResolutionHours;
  final int resolvedCount;

  final int? previousCount;
  final int? delta;

  /// Первая строка ячейки «Номер». Название может быть пустым — тогда
  /// показываем то, чем лифт называют в документах.
  String get title {
    final String? name = _blankToNull(objectName);
    if (name != null) return name;
    final String? registration = _blankToNull(registrationNumber);
    if (registration != null) return '№ $registration';
    return 'Объект №$objectId';
  }

  /// Вторая строка, мелким. Не дублирует [title], если тот уже взял номер.
  String? get subtitle {
    final String? registration = _blankToNull(registrationNumber);
    if (_blankToNull(objectName) != null && registration != null) {
      return '№ $registration';
    }
    return _blankToNull(address);
  }

  factory BreakdownObject.fromJson(Map<String, dynamic> json) {
    return BreakdownObject(
      objectId: _asInt(json['object_id']) ?? 0,
      objectName: _asString(json['object_name']),
      registrationNumber: _asString(json['registration_number']),
      factoryNumber: _asString(json['factory_number']),
      address: _asString(json['address']),
      client: _asString(json['client']),
      division: _asString(json['division']),
      factoryModel: _asString(json['factory_model']),
      responsibleMechanic: _asString(json['responsible_mechanic']),
      breakdownCount: _asInt(json['breakdown_count']) ?? 0,
      severity: _asList(json['severity'])
          .map(SeverityCount.fromJson)
          .toList(growable: false),
      avgReactionHours: _asDouble(json['avg_reaction_hours']),
      reactedCount: _asInt(json['reacted_count']) ?? 0,
      avgResolutionHours: _asDouble(json['avg_resolution_hours']),
      resolvedCount: _asInt(json['resolved_count']) ?? 0,
      previousCount: _asInt(json['previous_count']),
      delta: _asInt(json['delta']),
    );
  }
}

/// Отчёт за месяц целиком.
class BreakdownsReport {
  const BreakdownsReport({
    required this.year,
    required this.month,
    required this.totalBreakdowns,
    required this.objectsAffected,
    required this.severitySummary,
    required this.items,
  });

  final int year;
  final int month;
  final int totalBreakdowns;
  final int objectsAffected;
  final List<SeverityCount> severitySummary;
  final List<BreakdownObject> items;

  bool get isEmpty => items.isEmpty;

  /// Сколько объектов осталось за пределами показанного списка.
  int get hiddenObjects {
    final int hidden = objectsAffected - items.length;
    return hidden > 0 ? hidden : 0;
  }

  factory BreakdownsReport.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> period = _asMap(json['period']);
    return BreakdownsReport(
      year: _asInt(period['year']) ?? 0,
      month: _asInt(period['month']) ?? 0,
      totalBreakdowns: _asInt(json['total_breakdowns']) ?? 0,
      objectsAffected: _asInt(json['objects_affected']) ?? 0,
      severitySummary: _asList(json['severity_summary'])
          .map(SeverityCount.fromJson)
          .toList(growable: false),
      items: _asList(json['items'])
          .map(BreakdownObject.fromJson)
          .toList(growable: false),
    );
  }
}

/// Элемент справочника для фильтров: участок или организация.
class NamedRef {
  const NamedRef({required this.id, required this.title});

  final int id;
  final String title;

  static List<NamedRef> listFrom(dynamic data, List<String> titleKeys) {
    final List<NamedRef> result = <NamedRef>[];
    for (final Map<String, dynamic> row in _asList(data)) {
      final int? id = _asInt(row['id']);
      if (id == null) continue;
      String? title;
      for (final String key in titleKeys) {
        title ??= _blankToNull(_asString(row[key]));
      }
      result.add(NamedRef(id: id, title: title ?? '№$id'));
    }
    return result;
  }
}

/// Заявка в разборе по объекту — то, что открывается кликом по строке.
class BreakdownOrder {
  const BreakdownOrder({
    required this.id,
    required this.taskText,
    required this.categoryName,
    required this.categoryCode,
    required this.statusName,
    required this.createdAt,
    required this.executor,
  });

  final int id;
  final String? taskText;
  final String? categoryName;
  final String? categoryCode;
  final String? statusName;
  final DateTime? createdAt;
  final String? executor;

  factory BreakdownOrder.fromJson(Map<String, dynamic> json) {
    // Вложенные справочники приходят объектами, а не идентификаторами:
    // `fault_category_id` — это {id, name, code}, а не число.
    final Map<String, dynamic> category = _asMap(json['fault_category_id']);
    final Map<String, dynamic> status = _asMap(json['status_id']);
    final Map<String, dynamic> executor = _asMap(json['executor_id']);

    return BreakdownOrder(
      id: _asInt(json['id']) ?? 0,
      taskText: _blankToNull(_asString(json['task_text'])),
      categoryName: _blankToNull(_asString(category['name'])),
      categoryCode: _blankToNull(_asString(category['code'])),
      statusName: _blankToNull(_asString(status['name'])),
      // Бэкенд отдаёт метки времени в секундах (`utils/time_stamp.py`),
      // а Dart ждёт миллисекунды.
      createdAt: _asSecondsTimestamp(json['created_at']),
      executor: _blankToNull(_asString(executor['name'])),
    );
  }
}

// ---------------------------------------------------------------------------
// Разбор JSON. Бэкенд типы соблюдает, но пустой отчёт, null в необязательных
// полях и int вместо double от json_decode — штатные случаи, а не аварии.
// ---------------------------------------------------------------------------

DateTime? _asSecondsTimestamp(dynamic value) {
  final int? seconds = _asInt(value);
  if (seconds == null) return null;
  return DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
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

String? _blankToNull(String? value) {
  if (value == null) return null;
  final String trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
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
