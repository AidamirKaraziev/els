part of 'schedule_object_bloc.dart';

@immutable
abstract class ScheduleObjectEvent {
  const ScheduleObjectEvent();
}

/// Загрузить карточку объекта.
///
/// Годится и первому открытию экрана, и повтору после ошибки: запрос один и
/// тот же, и разводить их по двум событиям значило бы дважды писать один путь.
class ScheduleObjectRequested extends ScheduleObjectEvent {
  const ScheduleObjectRequested();
}
