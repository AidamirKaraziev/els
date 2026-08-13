import 'package:flutter/material.dart';

import '../../../../helper/calendar/month_picker.dart';
import '../../../../helper/class_colors.dart';

/// Модели ответа `GET /api/v1/statistics/overdue-maintenance`.
///
/// Разбираются в типы, а не носятся как `Map<String, dynamic>`: половина
/// полей законно приходит `null` — объект без адреса, без клиента, без
/// закреплённого механика.

/// Одно просроченное ТО: объект и плановый месяц.
///
/// Объект с тремя пропущенными месяцами придёт тремя элементами — иначе не
/// видно, за какие именно месяцы долг.
class OverdueMaintenanceItem {
  const OverdueMaintenanceItem({
    required this.actId,
    required this.objectId,
    required this.objectName,
    required this.registrationNumber,
    required this.factoryNumber,
    required this.address,
    required this.client,
    required this.division,
    required this.responsibleMechanic,
    required this.year,
    required this.month,
    required this.monthsOverdue,
  });

  final int actId;
  final int objectId;
  final String? objectName;
  final String? registrationNumber;
  final String? factoryNumber;
  final String? address;
  final String? client;
  final String? division;
  final String? responsibleMechanic;

  /// Плановый месяц, а не дата закрытия: точной даты ТО в базе нет вообще,
  /// график хранит только месяц.
  final int year;
  final int month;

  /// На сколько месяцев просрочено. Всегда не меньше единицы: текущий месяц
  /// в выдачу не попадает.
  final int monthsOverdue;

  /// Чем подписать объект. Название заполнено не всегда, и «Объект 42» лучше
  /// пустой ячейки: по нему хотя бы понятно, что спрашивать.
  String get objectLabel {
    for (final String? candidate in <String?>[
      objectName,
      registrationNumber,
      factoryNumber,
    ]) {
      if (candidate?.trim().isNotEmpty == true) return candidate!.trim();
    }
    return 'Объект $objectId';
  }

  String get clientLabel =>
      client?.trim().isNotEmpty == true ? client!.trim() : '—';

  String get responsibleLabel => responsibleMechanic?.trim().isNotEmpty == true
      ? responsibleMechanic!.trim()
      : '—';

  /// «Мар 2026». Короткая форма: колонка узкая, а год нужен — долг может
  /// тянуться с прошлого года.
  String get plannedLabel {
    if (month < 1 || month > 12) return '$year';
    return '${kMonthsShort[month - 1]} $year';
  }

  /// «5 мес.» — точная мера долга под датой.
  String get overdueLabel => '$monthsOverdue мес.';

  /// Цвет строки. Два уровня, оба из палитры приложения: свежий долг —
  /// жёлтый, всё остальное — красный. Точную величину несёт подпись
  /// [overdueLabel], изобретать под неё оттенки не нужно.
  Color get color =>
      monthsOverdue <= 1 ? ColorApp.myColorYellow : ColorApp.myColorRed;

  factory OverdueMaintenanceItem.fromJson(Map<String, dynamic> json) {
    return OverdueMaintenanceItem(
      actId: _asInt(json['act_id']) ?? 0,
      objectId: _asInt(json['object_id']) ?? 0,
      objectName: _asString(json['object_name']),
      registrationNumber: _asString(json['registration_number']),
      factoryNumber: _asString(json['factory_number']),
      address: _asString(json['address']),
      client: _asString(json['client']),
      division: _asString(json['division']),
      responsibleMechanic: _asString(json['responsible_mechanic']),
      year: _asInt(json['year']) ?? 0,
      month: _asInt(json['month']) ?? 0,
      monthsOverdue: _asInt(json['months_overdue']) ?? 1,
    );
  }
}

/// Просроченные ТО на сегодня.
class OverdueMaintenanceReport {
  const OverdueMaintenanceReport({
    required this.year,
    required this.month,
    required this.totalCount,
    required this.objectsAffected,
    required this.items,
  });

  /// Месяц, от которого бэкенд отсчитывал просрочку. Виджет его не рисует,
  /// но без него `monthsOverdue` нечем проверить при разборе жалоб.
  final int year;
  final int month;

  /// По всей выдаче, а не по обрезанному `limit` списку.
  final int totalCount;
  final int objectsAffected;

  final List<OverdueMaintenanceItem> items;

  /// Пусто — значит долгов нет. Это хорошая новость, а не ошибка и не
  /// незаполненный график: график мог быть заполнен и весь закрыт вовремя.
  bool get isEmpty => items.isEmpty;

  /// Список обрезан: показываем не всё, что просрочено.
  bool get hasMore => totalCount > items.length;

  factory OverdueMaintenanceReport.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> generatedFor = _asMap(json['generated_for']);
    return OverdueMaintenanceReport(
      year: _asInt(generatedFor['year']) ?? 0,
      month: _asInt(generatedFor['month']) ?? 0,
      totalCount: _asInt(json['total_count']) ?? 0,
      objectsAffected: _asInt(json['objects_affected']) ?? 0,
      items: _asList(json['items'])
          .map(OverdueMaintenanceItem.fromJson)
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
