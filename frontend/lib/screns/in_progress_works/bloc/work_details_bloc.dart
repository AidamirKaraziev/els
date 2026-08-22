// `package:bloc` и `package:meta` в pubspec.yaml не объявлены — остальной код
// импортирует их транзитивно. Берём то же самое из flutter_bloc и foundation,
// которые объявлены явно.
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/work_details.dart';
import '../repository/work_details_repository.dart';

part 'work_details_event.dart';
part 'work_details_state.dart';

/// Подробности одной работы: чек-лист, снимки, кому звонить.
///
/// Опроса нет намеренно: раздел перечитывает себя раз в минуту потому, что
/// прораб держит его открытым весь день, а карточку открывают, чтобы прочесть
/// и закрыть. Живая карточка — край этапа 9.3, там же и разговор о том, что
/// делать, если работу сдали при открытой карточке.
class WorkDetailsBloc extends Bloc<WorkDetailsEvent, WorkDetailsState> {
  WorkDetailsBloc({required this.actId, WorkDetailsRepository? repository})
      : _repository = repository ?? const WorkDetailsRepository(),
        super(const WorkDetailsLoading()) {
    on<WorkDetailsRequested>(_onRequested);
    on<WorkPerformerRequested>(_onPerformerRequested);
  }

  /// `work_id` строки: у ТО это id фактического акта.
  final int actId;

  final WorkDetailsRepository _repository;

  Future<void> _onRequested(
    WorkDetailsRequested event,
    Emitter<WorkDetailsState> emit,
  ) async {
    emit(const WorkDetailsLoading());

    final WorkDetails details;
    try {
      details = await _repository.fetchDetails(actId);
    } on WorkDetailsException catch (error) {
      emit(WorkDetailsFailure(message: error.message));
      return;
    }

    // Снимки и телефон — не повод уронить карточку. Чек-лист и времена уже на
    // руках, а без миниатюр и кнопки «Позвонить» карточка отвечает на главный
    // вопрос. Поэтому их сбои ловим по отдельности и молча.
    final WorkPhotos photos = await _photos();
    final Performer? performer = await _performer(details.mainMechanicId);

    emit(
      WorkDetailsReady(
        details: details,
        photos: photos,
        performer: performer,
        // Сбой телефона и «механик не назван» — разные вещи: в первом случае
        // карточка говорит, что номер не загрузился, во втором — что механика
        // в акте нет.
        performerFailed: details.mainMechanicId != null && performer == null,
        loadedAt: DateTime.now(),
      ),
    );
  }

  /// Перечитать телефон, не трогая всё остальное.
  ///
  /// Акт и снимки остаются те же самые: человек уходил в справочник, а не в
  /// работу. Меняется только исполнитель — и `loadedAt` вместе с ним: карточка
  /// говорит «Обновлено» про то, что на экране, а на экране теперь свежий
  /// телефон.
  Future<void> _onPerformerRequested(
    WorkPerformerRequested event,
    Emitter<WorkDetailsState> emit,
  ) async {
    final WorkDetailsState current = state;
    if (current is! WorkDetailsReady) return;

    final int? userId = current.details.mainMechanicId;
    if (userId == null) return;

    final Performer? performer = await _performer(userId);

    emit(
      WorkDetailsReady(
        details: current.details,
        photos: current.photos,
        performer: performer,
        performerFailed: performer == null,
        loadedAt: DateTime.now(),
      ),
    );
  }

  Future<WorkPhotos> _photos() async {
    try {
      return await _repository.fetchPhotos(actId);
    } on WorkDetailsException {
      return WorkPhotos.empty;
    }
  }

  Future<Performer?> _performer(int? userId) async {
    if (userId == null) return null;
    try {
      return await _repository.fetchPerformer(userId);
    } on WorkDetailsException {
      return null;
    }
  }
}
