import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/schedule_filters.dart';
import '../models/schedule_row.dart';
import '../repository/api_schedules_repository.dart';
import '../repository/schedules_repository.dart';

part 'schedules_event.dart';
part 'schedules_state.dart';

class SchedulesBloc extends Bloc<SchedulesEvent, SchedulesState> {
  SchedulesBloc({SchedulesRepository? repository, ScheduleFilters? filters})
      : this._(
          repository ?? ApiSchedulesRepository(),
          filters ?? ScheduleFilters.currentYear(),
        );

  SchedulesBloc._(this._repository, ScheduleFilters filters)
      : _filters = filters,
        super(SchedulesInitial(filters: filters)) {
    on<SchedulesRequested>(_onRequested);
    on<SchedulesFilterOptionsRequested>(_onFilterOptionsRequested);
    on<SchedulesNextPageRequested>(_onNextPageRequested);
  }

  final SchedulesRepository _repository;
  int _requestId = 0;

  /// Отбор и значения выпадающих держим полями, а не выковыриваем из
  /// состояния: догрузка страницы и приход значений происходят в отрыве от
  /// того, что сейчас на экране, а спрашивать у экрана «с чем ты был» — верный
  /// способ подгрузить вторую страницу под уже сменившийся фильтр.
  ScheduleFilters _filters;
  ScheduleFilterOptions _options = ScheduleFilterOptions.empty;

  Future<void> _onRequested(
    SchedulesRequested event,
    Emitter<SchedulesState> emit,
  ) async {
    _filters = event.filters;
    final int requestId = ++_requestId;
    emit(SchedulesLoading(filters: _filters, options: _options));

    try {
      final page = await _repository.fetchRows(
        filters: event.filters,
        page: 1,
      );

      if (requestId != _requestId) return;

      emit(SchedulesLoaded(
        filters: _filters,
        options: _options,
        rows: page.items,
        page: page.page,
        hasNext: page.hasNext,
        isLoadingMore: false,
      ));
    } on SchedulesException catch (error) {
      if (requestId != _requestId) return;
      emit(SchedulesFailure(
        filters: _filters,
        options: _options,
        message: error.message,
      ));
    }
  }

  /// Значения выпадающих приходят отдельно от строк и могут не прийти вовсе.
  ///
  /// Неудача здесь экран не ломает: без значений фильтров человек всё равно
  /// видит ленту, а плашка «не удалось» вместо списка объектов была бы обменом
  /// нужного на второстепенное.
  Future<void> _onFilterOptionsRequested(
    SchedulesFilterOptionsRequested event,
    Emitter<SchedulesState> emit,
  ) async {
    try {
      _options = await _repository.fetchFilterOptions();
    } on SchedulesException {
      return;
    }

    emit(_withOptions(state));
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
        filters: _filters,
        page: nextPage,
      );

      if (requestId != _requestId) return;

      emit(SchedulesLoaded(
        filters: _filters,
        options: _options,
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

  /// Тот же экран, но со значениями фильтров.
  ///
  /// Пересобираем состояние того же вида, а не подменяем его на «загружено»:
  /// значения могут прийти в любой момент, и подмена стёрла бы с экрана и
  /// спиннер, и текст ошибки.
  SchedulesState _withOptions(SchedulesState state) {
    if (state is SchedulesLoaded) {
      return state.copyWith(options: _options);
    }
    if (state is SchedulesFailure) {
      return SchedulesFailure(
        filters: state.filters,
        options: _options,
        message: state.message,
      );
    }
    if (state is SchedulesLoading) {
      return SchedulesLoading(filters: state.filters, options: _options);
    }
    return SchedulesInitial(filters: state.filters, options: _options);
  }
}
