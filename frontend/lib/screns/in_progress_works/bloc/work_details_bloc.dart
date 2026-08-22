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
/// Опроса нет намеренно: раздел перечитывает себя раз в минуту потому, что
/// прораб держит его открытым весь день, а карточку открывают, чтобы прочесть
/// и закрыть. Живая карточка — край этапа 9.3, там же и разговор о том, что
/// делать, если работу сдали при открытой карточке.
class WorkDetailsBloc extends Bloc<WorkDetailsEvent, WorkDetailsState> {
  WorkDetailsBloc({
    required this.workId,
    this.kind = WorkKind.maintenance,
    WorkDetailsRepository? repository,
  })  : _repository = repository ?? const WorkDetailsRepository(),
        super(const WorkDetailsLoading()) {
    on<WorkDetailsRequested>(_onRequested);
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

  /// ТО: акт, снимки шагов и телефон механика — тремя запросами.
  Future<void> _loadAct(Emitter<WorkDetailsState> emit) async {
    final WorkDetails details;
    try {
      details = await _repository.fetchDetails(workId);
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

  /// Заявка: сама заявка и её снимки. Третьего запроса нет — исполнитель
  /// приезжает внутри заявки, с телефоном и специальностью.
  Future<void> _loadOrder(Emitter<WorkDetailsState> emit) async {
    final OrderDetails order;
    try {
      order = await _repository.fetchOrder(workId);
    } on WorkDetailsException catch (error) {
      emit(WorkDetailsFailure(message: error.message));
      return;
    }

    emit(
      OrderReady(
        order: order,
        photos: await _orderPhotos(),
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

  Future<WorkPhotos> _photos() async {
    try {
      return await _repository.fetchPhotos(workId);
    } on WorkDetailsException {
      return WorkPhotos.empty;
    }
  }

  Future<OrderPhotos> _orderPhotos() async {
    try {
      return await _repository.fetchOrderPhotos(workId);
    } on WorkDetailsException {
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
