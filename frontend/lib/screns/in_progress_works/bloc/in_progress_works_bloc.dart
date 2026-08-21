// `package:bloc` и `package:meta` в pubspec.yaml не объявлены — остальной код
// импортирует их транзитивно. Берём то же самое из flutter_bloc и foundation,
// которые объявлены явно.
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/in_progress_work.dart';
import '../repository/in_progress_works_repository.dart';

part 'in_progress_works_event.dart';
part 'in_progress_works_state.dart';

/// Состояние раздела «Сейчас в работе».
///
/// Проще ленты сданных: одна ручка, ни страниц, ни отбора, ни действий над
/// работой — прораб смотрит и звонит, а распоряжается работой механик.
/// Отдельный блок, а не поле в `SubmittedWorksBloc`, потому что запроса два:
/// раздел может лечь, пока лента сданных жива, и наоборот.
class InProgressWorksBloc
    extends Bloc<InProgressWorksEvent, InProgressWorksState> {
  InProgressWorksBloc({InProgressWorksRepository? repository})
      : _repository = repository ?? const InProgressWorksRepository(),
        super(const InProgressWorksInitial()) {
    on<InProgressWorksRequested>(_onRequested);
  }

  final InProgressWorksRepository _repository;

  /// Номер последнего запроса: отсекает ответы, которые уже никому не нужны.
  /// Пригодится авто-обновлению (этап 8.6), где запросы пойдут сами.
  int _requestId = 0;

  Future<void> _onRequested(
    InProgressWorksRequested event,
    Emitter<InProgressWorksState> emit,
  ) async {
    final int requestId = ++_requestId;

    // Предыдущий список отдаём в состояние загрузки: при обновлении раздел
    // не должен схлопываться и подкидывать ленту сданных вверх.
    emit(InProgressWorksLoading(previous: state.works));

    try {
      final InProgressWorks works = await _repository.fetch();
      if (requestId != _requestId) return;
      emit(InProgressWorksLoaded(works: works));
    } on InProgressWorksException catch (error) {
      if (requestId != _requestId) return;
      emit(InProgressWorksFailure(message: error.message));
    }
  }
}
