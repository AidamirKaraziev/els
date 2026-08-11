part of 'breakdowns_bloc.dart';

@immutable
abstract class BreakdownsEvent {
  const BreakdownsEvent();
}

/// Запросить отчёт за месяц. День внутри [month] не используется.
///
/// Одним событием пользуются и карточка на главной, и экран подробностей —
/// отличаются только параметрами: карточке хватает пяти строк без фильтров,
/// экрану нужны все объекты, фильтры и сравнение с прошлым месяцем.
class BreakdownsRequested extends BreakdownsEvent {
  const BreakdownsRequested({
    required this.month,
    this.limit = 5,
    this.divisionId,
    this.organizationId,
    this.withPrevious = false,
  });

  final DateTime month;
  final int limit;
  final int? divisionId;
  final int? organizationId;

  /// Догрузить счётчики за предыдущий месяц. Стоит лишнего запроса на бэке,
  /// поэтому карточка на главной этого не просит.
  final bool withPrevious;
}
