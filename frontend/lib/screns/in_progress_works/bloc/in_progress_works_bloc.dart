// `package:bloc` и `package:meta` в pubspec.yaml не объявлены — остальной код
// импортирует их транзитивно. Берём то же самое из flutter_bloc и foundation,
// которые объявлены явно.
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../in_progress_counts.dart';
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
  /// При опросе раз в минуту такое случается само — ответ на медленный запрос
  /// может прийти после ответа на следующий и откатить список назад.
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
      // Числа для бокового меню кладём здесь, а не в репозитории: решает, чей
      // ответ считать настоящим, именно блок — устаревший не должен менять
      // меню, как не меняет список.
      inProgressCounts.value =
          InProgressCounts(total: works.total, problems: works.problems);
      emit(InProgressWorksLoaded(works: works));
    } on InProgressWorksException catch (error) {
      if (requestId != _requestId) return;
      // Список с прошлого удачного запроса отдаём дальше: неудачный такт
      // опроса должен добавлять на экран пометку, а не убирать с него работы.
      emit(
        InProgressWorksFailure(message: error.message, previous: state.works),
      );
    }
  }
}
