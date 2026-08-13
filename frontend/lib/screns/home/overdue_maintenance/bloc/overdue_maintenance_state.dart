part of 'overdue_maintenance_bloc.dart';

@immutable
abstract class OverdueMaintenanceState {
  const OverdueMaintenanceState();

  /// Отчёт, который сейчас есть на руках. У загрузки это предыдущая
  /// страница: при листании шапка со счётчиком и стрелками не должна
  /// мигать и прыгать, пока идёт запрос.
  OverdueMaintenanceReport? get report => null;

  /// Сколько строк пропущено от начала выдачи. Нужен и списку, и подписи
  /// «6–10 из 23».
  int get offset => 0;
}

class OverdueMaintenanceInitial extends OverdueMaintenanceState {
  const OverdueMaintenanceInitial();
}

class OverdueMaintenanceLoading extends OverdueMaintenanceState {
  const OverdueMaintenanceLoading({
    OverdueMaintenanceReport? previous,
    int offset = 0,
  })  : _previous = previous,
        _offset = offset;

  final OverdueMaintenanceReport? _previous;
  final int _offset;

  @override
  OverdueMaintenanceReport? get report => _previous;

  @override
  int get offset => _offset;
}

class OverdueMaintenanceLoaded extends OverdueMaintenanceState {
  const OverdueMaintenanceLoaded({
    required OverdueMaintenanceReport report,
    int offset = 0,
  })  : _report = report,
        _offset = offset;

  final OverdueMaintenanceReport _report;
  final int _offset;

  @override
  OverdueMaintenanceReport get report => _report;

  @override
  int get offset => _offset;
}

class OverdueMaintenanceFailure extends OverdueMaintenanceState {
  const OverdueMaintenanceFailure({required this.message});

  final String message;
}
