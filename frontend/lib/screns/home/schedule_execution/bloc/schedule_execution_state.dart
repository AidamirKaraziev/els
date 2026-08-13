part of 'schedule_execution_bloc.dart';

@immutable
abstract class ScheduleExecutionState {
  const ScheduleExecutionState();

  /// Месяц, к которому относится состояние. Заголовок карточки берёт его
  /// отсюда, поэтому подпись и данные не расходятся даже во время загрузки.
  DateTime? get month => null;
}

class ScheduleExecutionInitial extends ScheduleExecutionState {
  const ScheduleExecutionInitial();
}

class ScheduleExecutionLoading extends ScheduleExecutionState {
  const ScheduleExecutionLoading({required DateTime month}) : _month = month;

  final DateTime _month;

  @override
  DateTime get month => _month;
}

class ScheduleExecutionLoaded extends ScheduleExecutionState {
  const ScheduleExecutionLoaded({required DateTime month, required this.report})
      : _month = month;

  final DateTime _month;
  final ScheduleExecutionReport report;

  @override
  DateTime get month => _month;
}

class ScheduleExecutionFailure extends ScheduleExecutionState {
  const ScheduleExecutionFailure({
    required DateTime month,
    required this.message,
  }) : _month = month;

  final DateTime _month;
  final String message;

  @override
  DateTime get month => _month;
}
