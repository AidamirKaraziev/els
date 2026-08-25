import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/schedule_filters.dart';
import '../models/schedule_row.dart';
import '../repository/fixture_schedules_repository.dart';
import '../repository/schedules_repository.dart';

part 'schedules_event.dart';
part 'schedules_state.dart';

class SchedulesBloc extends Bloc<SchedulesEvent, SchedulesState> {
  SchedulesBloc({SchedulesRepository? repository})
      : _repository = repository ?? FixtureSchedulesRepository(),
        super(const SchedulesInitial()) {
    on<SchedulesRequested>(_onRequested);
    on<SchedulesNextPageRequested>(_onNextPageRequested);
  }

  final SchedulesRepository _repository;
  int _requestId = 0;
  ScheduleFilters _lastFilters = ScheduleFilters.currentYear();

  Future<void> _onRequested(
    SchedulesRequested event,
    Emitter<SchedulesState> emit,
  ) async {
    _lastFilters = event.filters;
    final int requestId = ++_requestId;
    emit(const SchedulesLoading());

    try {
      final page = await _repository.fetchRows(
        filters: event.filters,
        page: 1,
      );

      if (requestId != _requestId) return;

      emit(SchedulesLoaded(
        rows: page.items,
        page: page.page,
        hasNext: page.hasNext,
        isLoadingMore: false,
      ));
    } on SchedulesException catch (error) {
      if (requestId != _requestId) return;
      emit(SchedulesFailure(message: error.message));
    }
  }

  Future<void> _onNextPageRequested(
    SchedulesNextPageRequested event,
    Emitter<SchedulesState> emit,
  ) async {
    final state = this.state;
    if (state is! SchedulesLoaded) return;

    final int requestId = ++_requestId;
    final int nextPage = state.page + 1;

    emit(state.copyWith(isLoadingMore: true));

    try {
      final page = await _repository.fetchRows(
        filters: _lastFilters,
        page: nextPage,
      );

      if (requestId != _requestId) return;

      emit(SchedulesLoaded(
        rows: <ScheduleRow>[...state.rows, ...page.items],
        page: page.page,
        hasNext: page.hasNext,
        isLoadingMore: false,
      ));
    } on SchedulesException {
      if (requestId != _requestId) return;
      emit(state.copyWith(isLoadingMore: false));
    }
  }
}
