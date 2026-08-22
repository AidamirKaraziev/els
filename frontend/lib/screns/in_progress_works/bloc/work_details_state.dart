part of 'work_details_bloc.dart';

@immutable
abstract class WorkDetailsState {
  const WorkDetailsState();
}

class WorkDetailsLoading extends WorkDetailsState {
  const WorkDetailsLoading();
}

class WorkDetailsReady extends WorkDetailsState {
  const WorkDetailsReady({
    required this.details,
    required this.photos,
    required this.loadedAt,
    this.performer,
    this.performerFailed = false,
  });

  final WorkDetails details;
  final WorkPhotos photos;

  /// Пусто — либо механика в акте нет, либо справочник не ответил. Что именно,
  /// говорит [performerFailed]: молчащий справочник и незаполненное поле
  /// чинятся по-разному, и одинаковой подписью их смешивать нельзя.
  final Performer? performer;

  final bool performerFailed;

  /// Когда карточка забрала эти данные. От него считается «Обновлено»:
  /// метки правки в ответе акта нет, и про свежесть карточка может честно
  /// сказать только это.
  final DateTime loadedAt;
}

/// Подробности не загрузились. Шапка карточки при этом остаётся живой: всё,
/// что в ней есть, приехало со строкой списка и серверу не нужно.
class WorkDetailsFailure extends WorkDetailsState {
  const WorkDetailsFailure({required this.message});

  final String message;
}
