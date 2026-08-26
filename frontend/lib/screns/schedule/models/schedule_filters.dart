import 'package:flutter/foundation.dart';

/// Фильтр «Графики» — состояние годовой ленты объекта.
///
/// Отвечает на вопрос «где болит»: показать объекты, у которых в выбранном
/// году есть просрочка, есть выполненное с опозданием, есть незакрытое, либо
/// наоборот — всё сделано.
enum ScheduleState {
  hasOverdue,
  hasLate,
  hasPending,
  allDone,
}

extension ScheduleStateView on ScheduleState {
  String get title {
    switch (this) {
      case ScheduleState.hasOverdue:
        return 'Есть просроченные';
      case ScheduleState.hasLate:
        return 'Есть выполненные не вовремя';
      case ScheduleState.hasPending:
        return 'Есть незакрытые';
      case ScheduleState.allDone:
        return 'Всё выполнено';
    }
  }

  /// Значение для query-параметра `schedule_state`.
  String get query {
    switch (this) {
      case ScheduleState.hasOverdue:
        return 'has_overdue';
      case ScheduleState.hasLate:
        return 'has_late';
      case ScheduleState.hasPending:
        return 'has_pending';
      case ScheduleState.allDone:
        return 'all_done';
    }
  }
}

/// Значение выпадающего фильтра: то, что видит человек, и то, что уходит на
/// сервер.
@immutable
class FilterOption {
  const FilterOption({required this.id, required this.title});

  final int id;
  final String title;

  @override
  bool operator ==(Object other) =>
      other is FilterOption && other.id == id && other.title == title;

  @override
  int get hashCode => Object.hash(id, title);
}

/// Пункт «Без участка» в фильтре участков.
///
/// Объекты, которым участок не проставлен. Значением `division_id` это не
/// выразить: пусто там означает «не фильтруем», и такие объекты иначе не
/// отобрать вовсе — поэтому на сервер уходит отдельный `without_division`.
///
/// Отрицательный `id` взят намеренно: настоящие id участков положительные,
/// и пункт спокойно живёт в одном списке с ними — панели фильтров не нужно
/// знать, что он особенный.
const FilterOption kWithoutDivision =
    FilterOption(id: -1, title: 'Без участка');

/// Набор условий, которыми сужен список.
///
/// Поиск и фильтры **складываются**: ищем внутри выбранных фильтров, а не
/// вместо них. Поэтому это один объект, а не два независимых состояния — иначе
/// в блоке появилась бы развилка «что сейчас главнее», которой в поведении нет.
@immutable
class ScheduleFilters {
  const ScheduleFilters({
    required this.year,
    this.search = '',
    this.division,
    this.typeObject,
    this.name,
    this.factoryNumber,
    this.state,
  });

  ScheduleFilters.currentYear() : this(year: DateTime.now().year);

  final int year;

  /// Свободный текст из лупы. Ищется на сервере по названию, заводскому
  /// номеру, адресу, участку, типу оборудования и виду ТО — иначе поиск нашёл
  /// бы только то, что уже подгружено на экран.
  final String search;

  final FilterOption? division;
  final FilterOption? typeObject;
  final FilterOption? name;
  final FilterOption? factoryNumber;
  final ScheduleState? state;

  bool get isEmpty =>
      search.trim().isEmpty &&
      division == null &&
      typeObject == null &&
      name == null &&
      factoryNumber == null &&
      state == null;

  /// Сколько условий стоит — для подписи «Сбросить всё».
  int get activeCount => <bool>[
        search.trim().isNotEmpty,
        division != null,
        typeObject != null,
        name != null,
        factoryNumber != null,
        state != null,
      ].where((bool active) => active).length;

  /// Копия с изменёнными полями.
  ///
  /// Сброс одного фильтра — отдельные флаги `clear*`, потому что `null` в
  /// именованном параметре здесь означает «не трогай», а не «убери».
  ScheduleFilters copyWith({
    int? year,
    String? search,
    FilterOption? division,
    FilterOption? typeObject,
    FilterOption? name,
    FilterOption? factoryNumber,
    ScheduleState? state,
    bool clearDivision = false,
    bool clearTypeObject = false,
    bool clearName = false,
    bool clearFactoryNumber = false,
    bool clearState = false,
  }) {
    return ScheduleFilters(
      year: year ?? this.year,
      search: search ?? this.search,
      division: clearDivision ? null : (division ?? this.division),
      typeObject: clearTypeObject ? null : (typeObject ?? this.typeObject),
      name: clearName ? null : (name ?? this.name),
      factoryNumber:
          clearFactoryNumber ? null : (factoryNumber ?? this.factoryNumber),
      state: clearState ? null : (state ?? this.state),
    );
  }

  /// Всё убрать, год оставить: год — это не фильтр, а то, на что смотрим.
  ScheduleFilters cleared() => ScheduleFilters(year: year);

  Map<String, String> toQuery() {
    final String text = search.trim();
    return <String, String>{
      'year': '$year',
      if (text.isNotEmpty) 'search': text,
      if (division == kWithoutDivision)
        'without_division': 'true'
      else if (division != null)
        'division_id': '${division!.id}',
      if (typeObject != null) 'type_object_id': '${typeObject!.id}',
      if (name != null) 'name': name!.title,
      if (factoryNumber != null) 'factory_number': factoryNumber!.title,
      if (state != null) 'schedule_state': state!.query,
    };
  }

  @override
  bool operator ==(Object other) =>
      other is ScheduleFilters &&
      other.year == year &&
      other.search == search &&
      other.division == division &&
      other.typeObject == typeObject &&
      other.name == name &&
      other.factoryNumber == factoryNumber &&
      other.state == state;

  @override
  int get hashCode => Object.hash(
        year,
        search,
        division,
        typeObject,
        name,
        factoryNumber,
        state,
      );
}
