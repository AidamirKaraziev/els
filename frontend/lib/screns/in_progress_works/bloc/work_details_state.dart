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

/// Работы под карточкой больше нет: её сдали, пока карточка была открыта.
///
/// Отдельное состояние, а не [WorkDetailsFailure]: у сбоя есть «Повторить» и
/// живая шапка со строкой списка, здесь ни того, ни другого. Повторять нечего,
/// а шапка соврала бы пилюлей «Идёт · 41 мин» — ради этого края этап и заведён.
class WorkGone extends WorkDetailsState {
  const WorkGone({required this.title, required this.text});

  final String title;
  final String text;

  /// Работу закрыли: ТО с проставленным `finished_at`, заявка в статусе
  /// «Выполнено» или «Проблема». Обе уходят в ленту сданных работ, и прорабу
  /// есть куда за ними пойти.
  static const WorkGone submitted = WorkGone(
    title: 'Работу сдали',
    text: 'Механик закрыл её, пока карточка была открыта. Она ушла в ленту '
        'сданных работ.',
  );

  /// Обратный поворот: работу, открытую из ленты сданных, вернули в работу.
  /// Акту сбросили `finished_at`, заявке — статус. В ленте сданных её больше
  /// нет, а карточка с чек-листом говорила бы, что работа кончена.
  static const WorkGone returned = WorkGone(
    title: 'Работа снова в работе',
    text: 'Её открыли заново, пока карточка была открыта. Из ленты сданных '
        'она ушла.',
  );

  /// Заявка ушла из раздела, но не сдана: статус вернули в «Создано» или
  /// «Принято». В ленте сданных её не будет, и обещать её там нельзя.
  static const WorkGone stopped = WorkGone(
    title: 'Работа больше не идёт',
    text: 'Её статус изменился, пока карточка была открыта. В разделе текущих '
        'работ её больше нет.',
  );
}

/// Подробности не загрузились. Шапка карточки при этом остаётся живой: всё,
/// что в ней есть, приехало со строкой списка и серверу не нужно.
class WorkDetailsFailure extends WorkDetailsState {
  const WorkDetailsFailure({required this.message});

  final String message;
}
