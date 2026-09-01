part of 'schedule_object_bloc.dart';

@immutable
abstract class ScheduleObjectState {
  const ScheduleObjectState();
}

class ScheduleObjectInitial extends ScheduleObjectState {
  const ScheduleObjectInitial();
}

class ScheduleObjectLoading extends ScheduleObjectState {
  const ScheduleObjectLoading();
}

class ScheduleObjectLoaded extends ScheduleObjectState {
  const ScheduleObjectLoaded(this.card);

  final ScheduleObjectCard card;
}

/// Карточку загрузить не удалось.
///
/// Текст показываем прямо человеку, поэтому он приходит уже готовым из
/// репозитория — без кодов ответа и стектрейсов.
class ScheduleObjectFailure extends ScheduleObjectState {
  const ScheduleObjectFailure(this.message);

  final String message;
}
