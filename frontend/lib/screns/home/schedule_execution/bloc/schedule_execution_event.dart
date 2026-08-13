part of 'schedule_execution_bloc.dart';

@immutable
abstract class ScheduleExecutionEvent {
  const ScheduleExecutionEvent();
}

/// Запросить отчёт за месяц. День внутри [month] не используется.
///
/// Фильтры по участку, организации и компании ручка принимает, но карточка на
/// главной их не задаёт: они пригодятся экрану подробностей, когда он появится.
class ScheduleExecutionRequested extends ScheduleExecutionEvent {
  const ScheduleExecutionRequested({
    required this.month,
    this.divisionId,
    this.organizationId,
    this.companyId,
  });

  final DateTime month;
  final int? divisionId;
  final int? organizationId;
  final int? companyId;
}
