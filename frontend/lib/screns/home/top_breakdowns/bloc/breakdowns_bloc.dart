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

  DateTime get month => _lastMonth ?? DateTime.now();

  Future<void> _onRequested(
    BreakdownsRequested event,
    Emitter<BreakdownsState> emit,
  ) async {
    _lastMonth = event.month;
    emit(BreakdownsLoading(month: event.month));

    try {
      final BreakdownsReport report = await _repository.fetch(
        year: event.month.year,
        month: event.month.month,
        limit: event.limit,
      );

      // Пока ждали ответ, человек мог переключить месяц. Показывать данные
      // за апрель под заголовком «Май» нельзя.
      if (_lastMonth != event.month) return;

      emit(BreakdownsLoaded(month: event.month, report: report));
    } on BreakdownsException catch (error) {
      if (_lastMonth != event.month) return;
      emit(BreakdownsFailure(month: event.month, message: error.message));
    }
  }
}
