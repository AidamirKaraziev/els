// `package:bloc` и `package:meta` в pubspec.yaml не объявлены — остальной код
// импортирует их транзитивно. Берём то же самое из flutter_bloc и foundation,
// которые объявлены явно.
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/overdue_maintenance_report.dart';
import '../repository/overdue_maintenance_repository.dart';

part 'overdue_maintenance_event.dart';
part 'overdue_maintenance_state.dart';

/// Состояние карточки «Просроченные ТО».
///
/// Различает загрузку, ошибку и пустой ответ. Пустой ответ здесь означает
/// «долгов нет» — в отличие от выполнения графика, где пусто значит
/// «график не заполнен». Путать их нельзя: выводы у человека
/// противоположные.
class OverdueMaintenanceBloc
    extends Bloc<OverdueMaintenanceEvent, OverdueMaintenanceState> {
  OverdueMaintenanceBloc({OverdueMaintenanceRepository? repository})
      : _repository = repository ?? const OverdueMaintenanceRepository(),
        super(const OverdueMaintenanceInitial()) {
    on<OverdueMaintenanceRequested>(_onRequested);
  }

  final OverdueMaintenanceRepository _repository;

  /// Номер последнего запроса: отсекает ответы, которые уже никому не нужны.
  /// Человек пролистнул две страницы подряд, а ответ на первую пришёл после
  /// второй и перезаписал бы её.
  int _requestId = 0;

  Future<void> _onRequested(
    OverdueMaintenanceRequested event,
    Emitter<OverdueMaintenanceState> emit,
  ) async {
    final int requestId = ++_requestId;
    // Предыдущую страницу отдаём в состояние загрузки: при листании шапка со
    // счётчиком и стрелками не должна мигать между запросами.
    emit(OverdueMaintenanceLoading(
      previous: state.report,
      offset: event.offset,
    ));

    try {
      OverdueMaintenanceReport report = await _repository.fetch(
        limit: event.limit,
        offset: event.offset,
        divisionId: event.divisionId,
        organizationId: event.organizationId,
        companyId: event.companyId,
      );
      int offset = event.offset;

      // Страница за концом выдачи: долгов стало меньше, пока человек листал.
      // Пустой список при ненулевом счётчике выглядел бы как «долгов нет»,
      // поэтому молча возвращаемся на первую страницу.
      if (report.items.isEmpty && offset > 0 && report.totalCount > 0) {
        report = await _repository.fetch(
          limit: event.limit,
          divisionId: event.divisionId,
          organizationId: event.organizationId,
          companyId: event.companyId,
        );
        offset = 0;
      }

      if (requestId != _requestId) return;

      emit(OverdueMaintenanceLoaded(report: report, offset: offset));
    } on OverdueMaintenanceException catch (error) {
      if (requestId != _requestId) return;
      emit(OverdueMaintenanceFailure(message: error.message));
    }
  }
}
