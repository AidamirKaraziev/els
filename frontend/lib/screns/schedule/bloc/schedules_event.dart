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

/// Перечитать одну строку ленты — ту, у которой поменялся график.
///
/// Отдельно от [SchedulesRequested] намеренно: тот сбрасывает список на первую
/// страницу, и человек, закрывший ТО после пяти прокруток, оказался бы в
/// начале ленты. Здесь же меняется ровно одна строка, а страницы, отбор и
/// прокрутка остаются на месте.
///
/// Клетки берём у сервера, а не считаем на клиенте: «выполнено с опозданием»
/// отличается от «выполнено» тем, кончился ли плановый месяц, и по часам
/// браузера эта граница едет.
class SchedulesRowRefreshed extends SchedulesEvent {
  const SchedulesRowRefreshed(this.objectId);

  final int objectId;
}
