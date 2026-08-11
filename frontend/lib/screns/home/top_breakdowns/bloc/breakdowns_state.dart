part of 'breakdowns_bloc.dart';

@immutable
abstract class BreakdownsState {
  const BreakdownsState();

  /// Месяц, к которому относится состояние. Заголовок карточки берёт его
  /// отсюда, поэтому подпись и данные не расходятся даже во время загрузки.
  DateTime? get month => null;
}

class BreakdownsInitial extends BreakdownsState {
  const BreakdownsInitial();
}

class BreakdownsLoading extends BreakdownsState {
  const BreakdownsLoading({required DateTime month}) : _month = month;

  final DateTime _month;

  @override
  DateTime get month => _month;
}

class BreakdownsLoaded extends BreakdownsState {
  const BreakdownsLoaded({required DateTime month, required this.report})
      : _month = month;

  final DateTime _month;
  final BreakdownsReport report;

  @override
  DateTime get month => _month;
}

class BreakdownsFailure extends BreakdownsState {
  const BreakdownsFailure({required DateTime month, required this.message})
      : _month = month;

  final DateTime _month;
  final String message;

  @override
  DateTime get month => _month;
}
