part of 'work_details_bloc.dart';

@immutable
abstract class WorkDetailsState {
  const WorkDetailsState();
}

class WorkDetailsLoading extends WorkDetailsState {
  const WorkDetailsLoading();
}

/// Подробности приехали — чьи бы они ни были.
///
/// Общий предок у ТО и заявки не ради экономии строк: звонок в карточке один
/// на оба вида, и разговор про исполнителя должен вестись в одном месте.
/// Разное — ниже: у ТО чек-лист и времена, у заявки задание и категория.
abstract class WorkCardReady extends WorkDetailsState {
  const WorkCardReady({
    required this.loadedAt,
    this.performer,
    this.performerFailed = false,
  });

  /// Пусто — либо исполнителя в работе нет, либо справочник не ответил. Что
  /// именно, говорит [performerFailed]: молчащий справочник и незаполненное
  /// поле чинятся по-разному, и одинаковой подписью их смешивать нельзя.
  final Performer? performer;

  final bool performerFailed;

  /// Когда карточка забрала эти данные. От него считается «Обновлено»:
  /// метки правки в ответе акта нет, и про свежесть карточка может честно
  /// сказать только это.
  final DateTime loadedAt;
}

/// ТО: чек-лист с отметками, снимки шагов, времена.
class WorkDetailsReady extends WorkCardReady {
  const WorkDetailsReady({
    required this.details,
    required this.photos,
    required DateTime loadedAt,
    Performer? performer,
    bool performerFailed = false,
  }) : super(
          loadedAt: loadedAt,
          performer: performer,
          performerFailed: performerFailed,
        );

  final WorkDetails details;
  final WorkPhotos photos;
}

/// Заявка: задание, категория, время заведения, снимки.
///
/// [performerFailed] здесь не бывает при первой загрузке: исполнитель
/// приезжает внутри самой заявки, и «телефон не загрузился» сказать не о чем.
class OrderReady extends WorkCardReady {
  const OrderReady({
    required this.order,
    required this.photos,
    required DateTime loadedAt,
    Performer? performer,
    bool performerFailed = false,
  }) : super(
          loadedAt: loadedAt,
          performer: performer,
          performerFailed: performerFailed,
        );

  final OrderDetails order;
  final OrderPhotos photos;
}

/// Подробности не загрузились. Шапка карточки при этом остаётся живой: всё,
/// что в ней есть, приехало со строкой списка и серверу не нужно.
class WorkDetailsFailure extends WorkDetailsState {
  const WorkDetailsFailure({required this.message});

  final String message;
}
