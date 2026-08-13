part of 'overdue_maintenance_bloc.dart';

@immutable
abstract class OverdueMaintenanceEvent {
  const OverdueMaintenanceEvent();
}

/// Запросить долги. Периода у события нет: просрочка — состояние на сегодня.
///
/// Фильтры по участку, организации и компании ручка принимает, но карточка на
/// главной их не задаёт: они пригодятся экрану подробностей, когда он
/// появится.
class OverdueMaintenanceRequested extends OverdueMaintenanceEvent {
  const OverdueMaintenanceRequested({
    this.limit = 5,
    this.offset = 0,
    this.divisionId,
    this.organizationId,
    this.companyId,
  });

  /// Сколько строк показать. Счётчик в шапке считает по всей выдаче, поэтому
  /// обрезка списка не искажает цифру.
  final int limit;

  /// Сколько строк пропустить — страница списка.
  final int offset;

  final int? divisionId;
  final int? organizationId;
  final int? companyId;
}
