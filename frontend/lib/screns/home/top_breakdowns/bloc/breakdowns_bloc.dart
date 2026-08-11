// `package:bloc` и `package:meta` в pubspec.yaml не объявлены — остальной код
// импортирует их транзитивно. Здесь берём то же самое из flutter_bloc и
// foundation, которые объявлены явно.
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/breakdowns_report.dart';
import '../repository/breakdowns_repository.dart';

part 'breakdowns_event.dart';
part 'breakdowns_state.dart';

/// Состояние карточки «Топ поломок».
///
/// В отличие от остальных блоков приложения, этот различает загрузку, ошибку
/// и пустой ответ. Виджеты главной сейчас молча показывают пустоту при
/// лежащем бэкенде — человек видит «поломок нет» и верит.
class BreakdownsBloc extends Bloc<BreakdownsEvent, BreakdownsState> {
  BreakdownsBloc({BreakdownsRepository? repository})
      : _repository = repository ?? const BreakdownsRepository(),
        super(const BreakdownsInitial()) {
    on<BreakdownsRequested>(_onRequested);
  }

  final BreakdownsRepository _repository;

  /// Месяц последнего запроса. Нужен, чтобы при ошибке и повторе не терять
  /// выбор человека.
  DateTime? _lastMonth;

  /// Номер последнего запроса.
  ///
  /// Отсекает ответы, которые уже никому не нужны: человек переключил месяц
  /// или фильтр, а старый ответ пришёл после нового и перезаписал бы его.
  /// Сравнивать по месяцу здесь мало — на экране подробностей меняются ещё
  /// участок и клиент, а месяц при этом остаётся прежним.
  int _requestId = 0;

  DateTime get month => _lastMonth ?? DateTime.now();

  Future<void> _onRequested(
    BreakdownsRequested event,
    Emitter<BreakdownsState> emit,
  ) async {
    _lastMonth = event.month;
    final int requestId = ++_requestId;
    emit(BreakdownsLoading(month: event.month));

    try {
      final BreakdownsReport report = await _repository.fetch(
        year: event.month.year,
        month: event.month.month,
        limit: event.limit,
        divisionId: event.divisionId,
        organizationId: event.organizationId,
        withPrevious: event.withPrevious,
      );

      if (requestId != _requestId) return;

      emit(BreakdownsLoaded(month: event.month, report: report));
    } on BreakdownsException catch (error) {
      if (requestId != _requestId) return;
      emit(BreakdownsFailure(month: event.month, message: error.message));
    }
  }
}
