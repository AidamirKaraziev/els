// `package:bloc` и `package:meta` в pubspec.yaml не объявлены — остальной код
// импортирует их транзитивно. Берём то же самое из flutter_bloc и foundation,
// которые объявлены явно.
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/top_employees_report.dart';
import '../repository/top_employees_repository.dart';

part 'top_employees_event.dart';
part 'top_employees_state.dart';

/// Состояние карточки «Топ сотрудников».
///
/// В отличие от соседей, у карточки три переключателя: месяц, «лучшие или
/// худшие» и — у админа — «механики или прорабы». Все три хранятся в
/// состоянии, а не в виджете: после ответа сервера шапка должна показывать то
/// же, что показывает список.
class TopEmployeesBloc extends Bloc<TopEmployeesEvent, TopEmployeesState> {
  TopEmployeesBloc({TopEmployeesRepository? repository})
      : _repository = repository ?? const TopEmployeesRepository(),
        super(const TopEmployeesInitial()) {
    on<TopEmployeesRequested>(_onRequested);
  }

  final TopEmployeesRepository _repository;

  /// Номер последнего запроса: отсекает ответы, которые уже никому не нужны.
  /// Человек успел переключить месяц и порядок, а ответ на первый запрос
  /// пришёл последним и перезаписал бы список.
  int _requestId = 0;

  Future<void> _onRequested(
    TopEmployeesRequested event,
    Emitter<TopEmployeesState> emit,
  ) async {
    final int requestId = ++_requestId;
    final DateTime month = event.month;

    // Предыдущий отчёт отдаём в состояние загрузки: при переключении
    // «лучшие/худшие» шапка и переключатели не должны мигать.
    emit(TopEmployeesLoading(
      previous: state.report,
      month: month,
      kind: event.kind,
      order: event.order,
      offset: event.offset,
    ));

    try {
      TopEmployeesReport report = await _repository.fetch(
        year: month.year,
        month: month.month,
        kind: event.kind,
        order: event.order,
        limit: event.limit,
        offset: event.offset,
      );
      int offset = event.offset;

      // Страница за концом выдачи: сотрудников стало меньше, пока человек
      // листал. Пустой список при ненулевом счётчике выглядел бы как «людей
      // нет», поэтому молча возвращаемся на первую страницу.
      if (report.items.isEmpty && offset > 0 && report.totalCount > 0) {
        report = await _repository.fetch(
          year: month.year,
          month: month.month,
          kind: event.kind,
          order: event.order,
          limit: event.limit,
        );
        offset = 0;
      }

      if (requestId != _requestId) return;

      emit(TopEmployeesLoaded(
        report: report,
        month: month,
        kind: event.kind,
        order: event.order,
        offset: offset,
      ));
    } on TopEmployeesException catch (error) {
      if (requestId != _requestId) return;
      emit(TopEmployeesFailure(
        message: error.message,
        month: month,
        kind: event.kind,
        order: event.order,
      ));
    }
  }
}
