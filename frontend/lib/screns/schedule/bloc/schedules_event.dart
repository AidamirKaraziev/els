part of 'schedules_bloc.dart';

@immutable
abstract class SchedulesEvent {
  const SchedulesEvent();
}

class SchedulesRequested extends SchedulesEvent {
  const SchedulesRequested({
    required this.filters,
  });

  final ScheduleFilters filters;
}

class SchedulesNextPageRequested extends SchedulesEvent {
  const SchedulesNextPageRequested();
}
