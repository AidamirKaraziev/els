part of 'schedules_bloc.dart';

@immutable
abstract class SchedulesState {
  const SchedulesState();
}

class SchedulesInitial extends SchedulesState {
  const SchedulesInitial();
}

class SchedulesLoading extends SchedulesState {
  const SchedulesLoading();
}

class SchedulesLoaded extends SchedulesState {
  const SchedulesLoaded({
    required this.rows,
    required this.page,
    required this.hasNext,
    this.isLoadingMore = false,
  });

  final List<ScheduleRow> rows;
  final int page;
  final bool hasNext;
  final bool isLoadingMore;

  SchedulesLoaded copyWith({
    List<ScheduleRow>? rows,
    int? page,
    bool? hasNext,
    bool? isLoadingMore,
  }) {
    return SchedulesLoaded(
      rows: rows ?? this.rows,
      page: page ?? this.page,
      hasNext: hasNext ?? this.hasNext,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

class SchedulesFailure extends SchedulesState {
  const SchedulesFailure({required this.message});

  final String message;
}
