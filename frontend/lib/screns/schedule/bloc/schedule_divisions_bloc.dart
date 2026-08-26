import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/schedule_division.dart';
import '../repository/fixture_schedules_repository.dart';
import '../repository/schedules_repository.dart';

part 'schedule_divisions_event.dart';
part 'schedule_divisions_state.dart';

/// Первое окно «Графиков» у админа: участки с процентом выполнения.
///
/// Отдельный блок, а не поля в [SchedulesBloc]: экраны живут порознь — участки
/// загружаются один раз, а лента объектов под ними листается, фильтруется и
/// перезапрашивается. Общее состояние означало бы, что догрузка страницы
/// объектов способна погасить список участков.
class ScheduleDivisionsBloc
    extends Bloc<ScheduleDivisionsEvent, ScheduleDivisionsState> {
  ScheduleDivisionsBloc({SchedulesRepository? repository, int? year})
      : this._(
          repository ?? FixtureSchedulesRepository(),
          year ?? DateTime.now().year,
        );

  ScheduleDivisionsBloc._(this._repository, int year)
      : super(ScheduleDivisionsInitial(year: year)) {
    on<ScheduleDivisionsRequested>(_onRequested);
  }

  final SchedulesRepository _repository;

  /// Порядковый номер запроса. Год переключают стрелками, и два быстрых нажатия
  /// подряд легко приходят с ответами в обратном порядке — тогда на экране
  /// оказался бы позапрошлый год.
  int _requestId = 0;

  Future<void> _onRequested(
    ScheduleDivisionsRequested event,
    Emitter<ScheduleDivisionsState> emit,
  ) async {
    final int requestId = ++_requestId;
    emit(ScheduleDivisionsLoading(year: event.year));

    try {
      final List<ScheduleDivision> divisions =
          await _repository.fetchDivisions(year: event.year);

      if (requestId != _requestId) return;

      emit(ScheduleDivisionsLoaded(year: event.year, divisions: divisions));
    } on SchedulesException catch (error) {
      if (requestId != _requestId) return;
      emit(ScheduleDivisionsFailure(year: event.year, message: error.message));
    }
  }
}
