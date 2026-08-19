// `package:bloc` и `package:meta` в pubspec.yaml не объявлены — остальной код
// импортирует их транзитивно. Берём то же самое из flutter_bloc и foundation,
// которые объявлены явно.
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/submitted_work.dart';
import '../repository/submitted_works_repository.dart';

part 'submitted_works_event.dart';
part 'submitted_works_state.dart';

/// Состояние ленты сданных работ.
///
/// Отметка «проверил» устроена в два шага: строка чинится на месте сразу, а
/// следом страница перезапрашивается. Первое нужно, чтобы кнопка отвечала без
/// задержки; второе — чтобы в строке оказались настоящие «кто и когда» с
/// сервера, а при включённом отборе «только непросмотренные» строка ушла из
/// списка. Держать это одним локальным изменением нельзя: имени проверившего
/// у клиента нет, а выдумывать его в ленте — врать.
class SubmittedWorksBloc
    extends Bloc<SubmittedWorksEvent, SubmittedWorksState> {
  SubmittedWorksBloc({SubmittedWorksRepository? repository})
      : _repository = repository ?? const SubmittedWorksRepository(),
        super(const SubmittedWorksInitial()) {
    on<SubmittedWorksRequested>(_onRequested);
    on<SubmittedWorkReviewed>(_onReviewed);
  }

  final SubmittedWorksRepository _repository;

  /// Номер последнего запроса: отсекает ответы, которые уже никому не нужны.
  /// Человек пролистнул две страницы подряд, а ответ на первую пришёл после
  /// второй и перезаписал бы её.
  int _requestId = 0;

  Future<void> _onRequested(
    SubmittedWorksRequested event,
    Emitter<SubmittedWorksState> emit,
  ) async {
    final bool onlyUnreviewed = event.onlyUnreviewed ?? state.onlyUnreviewed;
    final int requestId = ++_requestId;

    // Предыдущую страницу отдаём в состояние загрузки: при листании шапка со
    // стрелками не должна мигать между запросами.
    emit(SubmittedWorksLoading(
      previous: state.page,
      onlyUnreviewed: onlyUnreviewed,
    ));

    try {
      SubmittedWorksPage page = await _repository.fetch(
        page: event.page,
        onlyUnreviewed: onlyUnreviewed,
      );

      // Страница за концом выдачи: работ стало меньше, пока человек листал —
      // или он отметил последнюю на странице при включённом отборе. Пустой
      // список на пятой странице выглядел бы как «лента кончилась».
      if (page.isEmpty && event.page > 1) {
        page = await _repository.fetch(page: 1, onlyUnreviewed: onlyUnreviewed);
      }

      if (requestId != _requestId) return;
      emit(SubmittedWorksLoaded(page: page, onlyUnreviewed: onlyUnreviewed));
    } on SubmittedWorksException catch (error) {
      if (requestId != _requestId) return;
      emit(SubmittedWorksFailure(
        message: error.message,
        onlyUnreviewed: onlyUnreviewed,
      ));
    }
  }

  Future<void> _onReviewed(
    SubmittedWorkReviewed event,
    Emitter<SubmittedWorksState> emit,
  ) async {
    final SubmittedWorksPage? current = state.page;
    if (current == null) return;

    try {
      await _repository.markReviewed(
        kind: event.work.kind,
        workId: event.work.workId,
      );
    } on SubmittedWorksException catch (error) {
      emit(SubmittedWorksActionFailed(
        message: error.message,
        page: current,
        onlyUnreviewed: state.onlyUnreviewed,
      ));
      // Работа могла уехать из ленты вовсе — показываем то, что на сервере.
      add(SubmittedWorksRequested(page: current.page));
      return;
    }

    // Строку чиним на месте, чтобы кнопка ответила сразу, и тут же идём за
    // настоящими «кто и когда».
    emit(SubmittedWorksLoading(
      previous: _patched(current, event.work),
      onlyUnreviewed: state.onlyUnreviewed,
    ));
    add(SubmittedWorksRequested(page: current.page));
  }

  SubmittedWorksPage _patched(SubmittedWorksPage page, SubmittedWork marked) {
    return SubmittedWorksPage(
      items: page.items
          .map((SubmittedWork item) =>
              item.kind == marked.kind && item.workId == marked.workId
                  ? item.markedReviewed(by: null)
                  : item)
          .toList(growable: false),
      page: page.page,
      pageCount: page.pageCount,
      hasPrev: page.hasPrev,
      hasNext: page.hasNext,
    );
  }
}
