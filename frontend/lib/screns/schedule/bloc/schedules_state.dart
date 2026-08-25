part of 'schedules_bloc.dart';

@immutable
abstract class SchedulesState {
  const SchedulesState({
    required this.filters,
    this.options = ScheduleFilterOptions.empty,
  });

  /// Текущий отбор. Живёт во всех состояниях, включая загрузку и ошибку:
  /// фильтр применяется сразу при выборе, и панель, собранная только по
  /// «загружено», на каждом выборе моргала бы и теряла выбранные значения.
  final ScheduleFilters filters;

  /// Значения выпадающих списков. Грузятся один раз и не зависят от того,
  /// какая страница объектов сейчас на экране.
  final ScheduleFilterOptions options;
}

class SchedulesInitial extends SchedulesState {
  const SchedulesInitial({
    required ScheduleFilters filters,
    ScheduleFilterOptions options = ScheduleFilterOptions.empty,
  }) : super(filters: filters, options: options);
}

class SchedulesLoading extends SchedulesState {
  const SchedulesLoading({
    required ScheduleFilters filters,
    ScheduleFilterOptions options = ScheduleFilterOptions.empty,
  }) : super(filters: filters, options: options);
}

class SchedulesLoaded extends SchedulesState {
  const SchedulesLoaded({
    required ScheduleFilters filters,
    ScheduleFilterOptions options = ScheduleFilterOptions.empty,
    required this.rows,
    required this.page,
    required this.hasNext,
    this.isLoadingMore = false,
  }) : super(filters: filters, options: options);

  final List<ScheduleRow> rows;
  final int page;
  final bool hasNext;
  final bool isLoadingMore;

  SchedulesLoaded copyWith({
    ScheduleFilters? filters,
    ScheduleFilterOptions? options,
    List<ScheduleRow>? rows,
    int? page,
    bool? hasNext,
    bool? isLoadingMore,
  }) {
    return SchedulesLoaded(
      filters: filters ?? this.filters,
      options: options ?? this.options,
      rows: rows ?? this.rows,
      page: page ?? this.page,
      hasNext: hasNext ?? this.hasNext,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

class SchedulesFailure extends SchedulesState {
  const SchedulesFailure({
    required ScheduleFilters filters,
    ScheduleFilterOptions options = ScheduleFilterOptions.empty,
    required this.message,
  }) : super(filters: filters, options: options);

  final String message;
}
