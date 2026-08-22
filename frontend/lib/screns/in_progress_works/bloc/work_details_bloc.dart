// `package:bloc` и `package:meta` в pubspec.yaml не объявлены — остальной код
// импортирует их транзитивно. Берём то же самое из flutter_bloc и foundation,
// которые объявлены явно.
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../submitted_works/models/submitted_work.dart' show WorkKind;
import '../models/order_details.dart';
import '../models/work_details.dart';
import '../repository/work_details_repository.dart';

part 'work_details_event.dart';
part 'work_details_state.dart';

/// Подробности одной работы: чек-лист либо задание, снимки, кому звонить.
///
/// Один блок на оба вида работ, а не два похожих: экран у них общий, звонок
/// общий, и разъехаться они не должны. Ветка выбирается по [kind] — у ТО
/// спрашиваем акт, у заявки саму заявку.
///
/// Карточка живая: пока она открыта, работа под ней продолжается. Механик не
/// знает, что прораб на него смотрит, — он может отметить пункт, снять паузу
/// или закрыть работу в любую секунду. Такт задаёт виджет
/// (`widgets/work_card_live.dart`), блок только знает, как перечитать себя
/// молча — [WorkDetailsRefreshed].
///
/// Ушедшую из раздела работу карточка не подменяет: вместо подробностей
/// встаёт [WorkGone] с дорогой обратно к списку. Условие «работа ещё идёт»
/// здесь ровно то же, каким раздел её отбирает (`crud_in_progress_works.py`):
/// у ТО — пустой `finished_at`, у заявки — статус «В процессе».
class WorkDetailsBloc extends Bloc<WorkDetailsEvent, WorkDetailsState> {
  WorkDetailsBloc({
    required this.workId,
    this.kind = WorkKind.maintenance,
    WorkDetailsRepository? repository,
  })  : _repository = repository ?? const WorkDetailsRepository(),
        super(const WorkDetailsLoading()) {
    on<WorkDetailsRequested>(_onRequested);
    on<WorkDetailsRefreshed>(_onRefreshed);
    on<WorkPerformerRequested>(_onPerformerRequested);
  }

  /// `work_id` строки: у ТО это id фактического акта, у заявки — её
  /// собственный id.
  final int workId;

  /// Вид работы. От него зависит, за чем идти на сервер и что показывать.
  final WorkKind kind;

  final WorkDetailsRepository _repository;

  bool get _isOrder => kind != WorkKind.maintenance;

  Future<void> _onRequested(
    WorkDetailsRequested event,
    Emitter<WorkDetailsState> emit,
  ) async {
    emit(const WorkDetailsLoading());

    if (_isOrder) {
      await _loadOrder(emit);
      return;
    }
    await _loadAct(emit);
  }

  /// Такт живой карточки: перечитать то же самое, ничего не погасив.
  ///
  /// Работы под карточкой может уже не быть — тогда экран об этом и скажет.
  /// Второй раз спрашивать про неё незачем: [WorkGone] — состояние конечное,
  /// назад в работу сданное не возвращается.
  Future<void> _onRefreshed(
    WorkDetailsRefreshed event,
    Emitter<WorkDetailsState> emit,
  ) async {
    if (state is WorkGone) return;

    if (_isOrder) {
      await _loadOrder(emit, silent: true);
      return;
    }
    await _loadAct(emit, silent: true);
  }

  /// ТО: акт, снимки шагов и телефон механика — тремя запросами.
  ///
  /// `silent` — такт живой карточки: сбой такого запроса не меняет ничего,
  /// потому что менять было бы на худшее. Прежний чек-лист устарел на минуту,
  /// «Не удалось загрузить» на его месте не говорит вообще ничего.
  Future<void> _loadAct(
    Emitter<WorkDetailsState> emit, {
    bool silent = false,
  }) async {
    final WorkDetails details;
    try {
      details = await _repository.fetchDetails(workId);
    } on WorkDetailsException catch (error) {
      if (silent) return;
      emit(WorkDetailsFailure(message: error.message));
      return;
    }

    // Акт закрыт — работы в разделе больше нет. Проверка стоит и на первой
    // загрузке: список мог устареть на минуту, и открытая по нему карточка
    // обязана сказать правду сразу, а не через такт.
    if (details.isFinished) {
      emit(WorkGone.submitted);
      return;
    }

    // Снимки и телефон — не повод уронить карточку. Чек-лист и времена уже на
    // руках, а без миниатюр и кнопки «Позвонить» карточка отвечает на главный
    // вопрос. Поэтому их сбои ловим по отдельности и молча.
    final WorkPhotos photos = await _photos(silent: silent);
    final Performer? performer = await _actPerformer(details, silent: silent);

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

  /// Заявка: сама заявка и её снимки. Третьего запроса нет — исполнитель
  /// приезжает внутри заявки, с телефоном и специальностью.
  Future<void> _loadOrder(
    Emitter<WorkDetailsState> emit, {
    bool silent = false,
  }) async {
    final OrderDetails order;
    try {
      order = await _repository.fetchOrder(workId);
    } on WorkDetailsException catch (error) {
      if (silent) return;
      emit(WorkDetailsFailure(message: error.message));
      return;
    }

    // Заявка ушла из «В процессе». Сдана она или её статус просто откатили —
    // разные новости, и слова у них разные: в ленте сданных прораб найдёт
    // только первую.
    if (order.isGone) {
      emit(order.isSubmitted ? WorkGone.submitted : WorkGone.stopped);
      return;
    }

    emit(
      OrderReady(
        order: order,
        photos: await _orderPhotos(silent: silent),
        performer: order.executor,
        loadedAt: DateTime.now(),
      ),
    );
  }

  /// Перечитать телефон, не трогая всё остальное.
  ///
  /// Работа и снимки остаются те же самые: человек уходил в справочник, а не
  /// в работу. Меняется только исполнитель — и `loadedAt` вместе с ним:
  /// карточка говорит «Обновлено» про то, что на экране, а на экране теперь
  /// свежий телефон.
  Future<void> _onPerformerRequested(
    WorkPerformerRequested event,
    Emitter<WorkDetailsState> emit,
  ) async {
    final WorkDetailsState current = state;

    if (current is WorkDetailsReady) {
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
      return;
    }

    if (current is OrderReady) {
      // Заявку целиком перезапрашивать незачем: у неё меняется ровно то, за
      // чем прораб ходил в справочник, — телефон исполнителя.
      final int? userId = current.performer?.id;
      if (userId == null || userId <= 0) return;

      final Performer? performer = await _performer(userId);
      emit(
        OrderReady(
          order: current.order,
          photos: current.photos,
          performer: performer,
          performerFailed: performer == null,
          loadedAt: DateTime.now(),
        ),
      );
    }
  }

  /// Кому звонить у ТО.
  ///
  /// На такте в справочник не ходим: телефон механика не меняется оттого, что
  /// он отметил пункт, а лишний запрос в минуту — это лишний запрос в минуту.
  /// Идём заново, только если акт назвал другого механика: тогда прежний номер
  /// стал бы чужим.
  Future<Performer?> _actPerformer(
    WorkDetails details, {
    required bool silent,
  }) async {
    final WorkDetailsState current = state;
    if (silent &&
        current is WorkDetailsReady &&
        current.details.mainMechanicId == details.mainMechanicId) {
      return current.performer;
    }
    return _performer(details.mainMechanicId);
  }

  /// Снимки шагов. Упавший запрос на такте оставляет те, что уже на экране:
  /// пропавшие миниатюры прораб прочтёт как «механик их удалил», а под
  /// молчаливым чек-листом на их месте встала бы подпись «снимков не оставил»
  /// — прямое враньё от одного дрогнувшего запроса.
  Future<WorkPhotos> _photos({bool silent = false}) async {
    final WorkDetailsState current = state;
    try {
      return await _repository.fetchPhotos(workId);
    } on WorkDetailsException {
      if (silent && current is WorkDetailsReady) return current.photos;
      return WorkPhotos.empty;
    }
  }

  /// Снимки заявки — по той же причине и с той же оговоркой.
  Future<OrderPhotos> _orderPhotos({bool silent = false}) async {
    final WorkDetailsState current = state;
    try {
      return await _repository.fetchOrderPhotos(workId);
    } on WorkDetailsException {
      if (silent && current is OrderReady) return current.photos;
      return OrderPhotos.empty;
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
