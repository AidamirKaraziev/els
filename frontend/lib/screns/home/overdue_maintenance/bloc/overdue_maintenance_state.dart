part of 'overdue_maintenance_bloc.dart';

@immutable
abstract class OverdueMaintenanceState {
  const OverdueMaintenanceState();
}

class OverdueMaintenanceInitial extends OverdueMaintenanceState {
  const OverdueMaintenanceInitial();
}

class OverdueMaintenanceLoading extends OverdueMaintenanceState {
  const OverdueMaintenanceLoading();
}

class OverdueMaintenanceLoaded extends OverdueMaintenanceState {
  const OverdueMaintenanceLoaded({required this.report});

  final OverdueMaintenanceReport report;
}

class OverdueMaintenanceFailure extends OverdueMaintenanceState {
  const OverdueMaintenanceFailure({required this.message});

  final String message;
}
