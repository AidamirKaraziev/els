part of 'breakdowns_bloc.dart';

@immutable
abstract class BreakdownsEvent {
  const BreakdownsEvent();
}

/// Запросить отчёт за месяц. День внутри [month] не используется.
class BreakdownsRequested extends BreakdownsEvent {
  const BreakdownsRequested({required this.month, this.limit = 5});

  final DateTime month;
  final int limit;
}
