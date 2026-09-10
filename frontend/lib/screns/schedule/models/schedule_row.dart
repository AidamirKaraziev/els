import 'month_cell.dart';

/// Строка раздела «Графики»: объект и его годовая лента ТО.
///
/// Собирается на сервере целиком — вместе с посчитанным состоянием каждой
/// клетки. Раскладывать двенадцать колонок `january_to_id … december_to_id`
/// на клиенте нельзя: состояние «просрочено» зависит от того, кончился ли
/// плановый месяц, и считать это в браузере по локальным часам — значит
/// получать разную картину на разных машинах.
class ScheduleRow {
  const ScheduleRow({
    required this.objectId,
    required this.name,
    required this.year,
    required this.cells,
    this.factoryNumber,
    this.address,
    this.division,
    this.foreman,
    this.typeName,
    this.defectsCount,
  });

  final int objectId;
  final String name;

  /// Год ленты. Держим в строке, а не только в фильтре: ответ может прийти
  /// после того, как человек переключил год, и подпись не должна врать.
  final int year;

  /// Ровно двенадцать клеток, январь..декабрь. Недостающие месяцы заполняются
  /// [MonthCell.empty] при разборе — виджету не приходится проверять длину.
  final List<MonthCell> cells;

  final String? factoryNumber;
  final String? address;
  final String? division;
  final String? foreman;
  final String? typeName;

  /// Сколько дефектных актов у объекта за [year]. `null` — сервер числа не
  /// прислал, и значок в строке не рисуется вовсе; ноль — значок серый.
  /// Считает сервер вместе с лентой: клиенту для этого пришлось бы ходить за
  /// актами каждой строки отдельно.
  final int? defectsCount;

  String get nameLabel => name.trim().isEmpty ? 'Без названия' : name.trim();
  String get factoryNumberLabel => factoryNumber ?? '—';
  String get addressLabel => address ?? 'Адрес не указан';
  String get divisionLabel => division ?? 'Без участка';
  String get foremanLabel => foreman ?? 'Прораб не назначен';
  String get typeLabel => typeName ?? 'Тип не указан';

  /// График на год не заводили вовсе — все двенадцать клеток пустые.
  ///
  /// Это не то же самое, что «ничего не выполнено»: винить объект не в чем,
  /// плана ему просто не поставили.
  bool get hasNoSchedule =>
      cells.every((MonthCell cell) => cell.status == MonthStatus.none);

  factory ScheduleRow.fromJson(Map<String, dynamic> json) {
    return ScheduleRow(
      objectId: _asInt(json['object_id']) ?? 0,
      name: _asString(json['name']) ?? '',
      year: _asInt(json['year']) ?? 0,
      cells: _cells(json['cells']),
      factoryNumber: _asString(json['factory_number']),
      address: _asString(json['address']),
      division: _asString(json['division']),
      foreman: _asString(json['foreman']),
      typeName: _asString(json['type_name']),
      defectsCount: _asInt(json['defects_count']),
    );
  }
}

/// Двенадцать клеток по номеру месяца.
///
/// Сервер вправе прислать только занятые месяцы; недостающие дорисовываем
/// пустыми здесь, один раз, чтобы лента не разбиралась с дырами.
List<MonthCell> _cells(dynamic value) {
  final Map<int, MonthCell> byMonth = <int, MonthCell>{};

  if (value is List) {
    for (final dynamic item in value) {
      if (item is! Map) continue;
      final MonthCell cell = MonthCell.fromJson(item.cast<String, dynamic>());
      if (cell.month >= 1 && cell.month <= 12) byMonth[cell.month] = cell;
    }
  }

  return List<MonthCell>.generate(
    12,
    (int index) => byMonth[index + 1] ?? MonthCell.empty(index + 1),
    growable: false,
  );
}

int? _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

String? _asString(dynamic value) {
  if (value is String && value.trim().isNotEmpty) return value.trim();
  return null;
}
