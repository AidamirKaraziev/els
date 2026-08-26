part of 'schedule_divisions_bloc.dart';

@immutable
abstract class ScheduleDivisionsEvent {
  const ScheduleDivisionsEvent();
}

/// Запросить участки за год.
///
/// Год приходит событием, а не берётся из состояния: смена года — это и есть
/// единственная причина перезапроса на этом экране.
class ScheduleDivisionsRequested extends ScheduleDivisionsEvent {
  const ScheduleDivisionsRequested({required this.year});

  final int year;
}
