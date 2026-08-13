// `package:bloc` и `package:meta` в pubspec.yaml не объявлены — остальной код
// импортирует их транзитивно. Берём то же самое из flutter_bloc и foundation,
// которые объявлены явно.
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/schedule_execution_report.dart';
import '../repository/schedule_execution_repository.dart';

part 'schedule_execution_event.dart';
part 'schedule_execution_state.dart';

/// Состояние карточки «Выполнение графика».
///
/// Как и у топа поломок, различает загрузку, ошибку и пустой месяц: пустой
/// месяц здесь означает «график на этот месяц не заполнен», и путать его с
/// лежащим бэкендом нельзя — выводы у человека будут противоположные.
class ScheduleExecutionBloc
    extends Bloc<ScheduleExecutionEvent, ScheduleExecutionState> {
  ScheduleExecutionBloc({ScheduleExecutionRepository? repository})
      : _repository = repository ?? const ScheduleExecutionRepository(),
        super(const ScheduleExecutionInitial()) {
    on<ScheduleExecutionRequested>(_onRequested);
  }

  final ScheduleExecutionRepository _repository;

  DateTime? _lastMonth;

  /// Номер последнего запроса: отсекает ответы, которые уже никому не нужны.
  /// Человек переключил месяц, а старый ответ пришёл после нового и перезаписал
  /// бы его.
  int _requestId = 0;

  DateTime get month => _lastMonth ?? DateTime.now();

  Future<void> _onRequested(
    ScheduleExecutionRequested event,
    Emitter<ScheduleExecutionState> emit,
  ) async {
    _lastMonth = event.month;
    final int requestId = ++_requestId;
    emit(ScheduleExecutionLoading(month: event.month));

    try {
      final ScheduleExecutionReport report = await _repository.fetch(
        year: event.month.year,
        month: event.month.month,
        divisionId: event.divisionId,
        organizationId: event.organizationId,
        companyId: event.companyId,
      );

      if (requestId != _requestId) return;

      emit(ScheduleExecutionLoaded(month: event.month, report: report));
    } on ScheduleExecutionException catch (error) {
      if (requestId != _requestId) return;
      emit(ScheduleExecutionFailure(month: event.month, message: error.message));
    }
  }
}
