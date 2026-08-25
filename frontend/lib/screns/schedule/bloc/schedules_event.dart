part of 'schedules_bloc.dart';

@immutable
abstract class SchedulesEvent {
  const SchedulesEvent();
}

/// Перезапросить ленту с новым отбором.
///
/// Одно событие и на фильтры, и на поиск, и на смену года: они складываются в
/// один [ScheduleFilters], и отдельные события развели бы по блоку три пути к
/// одному и тому же запросу. Список всегда сбрасывается на первую страницу —
/// иначе после сужения отбора человек остался бы на пятой странице пустоты.
class SchedulesRequested extends SchedulesEvent {
  const SchedulesRequested({
    required this.filters,
  });

  final ScheduleFilters filters;
}

/// Значения выпадающих фильтров: участки, типы, названия, заводские номера.
///
/// Отдельно от строк и один раз за жизнь экрана: список участков не должен
/// зависеть от того, какая страница объектов сейчас загружена.
class SchedulesFilterOptionsRequested extends SchedulesEvent {
  const SchedulesFilterOptionsRequested();
}

class SchedulesNextPageRequested extends SchedulesEvent {
  const SchedulesNextPageRequested();
}
