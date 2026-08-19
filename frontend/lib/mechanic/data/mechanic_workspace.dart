/// Рабочее место механика: локальная база, очередь и синхронизация вместе.
///
/// Экранам нужен один вход, а не три объекта с одинаковым `userId`. Здесь же
/// живёт фоновая отправка: очередь и синхронизация запускаются по таймеру и
/// при возвращении в приложение.
///
/// Всё привязано к вошедшему: телефон в бригаде бывает общим, и данные
/// предыдущего человека новому показывать нельзя.
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../helper/api_client.dart';
import '../../helper/api_config.dart';
import 'local_store.dart';
import 'mechanic_sync.dart';
import 'notifications.dart';
import 'outbox.dart';
import 'tasks.dart';

class MechanicWorkspace {
  MechanicWorkspace._(this.userId, {KeyValueStore store = const PreferencesStore()})
      : localStore = LocalStore(userId: userId, store: store) {
    outbox = Outbox(userId: userId, sender: _send, store: store);
    journal = NotificationJournal(store: localStore);
    sync = MechanicSync(store: localStore, journal: journal);
  }

  final int userId;
  final LocalStore localStore;
  late final Outbox outbox;
  late final MechanicSync sync;
  late final NotificationJournal journal;

  /// Как часто телефон сам пробует догнать сервер и отдать сделанное.
  ///
  /// Две минуты, а не три секунды, как у подрядчика: список механика
  /// обновляется от силы несколько раз за смену, а батарея на объекте одна.
  static const Duration _period = Duration(minutes: 2);

  static MechanicWorkspace? _current;
  Timer? _timer;

  /// Состояние для интерфейса: сколько неотправленного и когда последний раз
  /// удалось синхронизироваться.
  final ValueNotifier<WorkspaceStatus> status =
      ValueNotifier<WorkspaceStatus>(const WorkspaceStatus());

  /// Рабочее место вошедшего. Смена человека закрывает прежнее.
  static MechanicWorkspace of(int userId) {
    final MechanicWorkspace? existing = _current;
    if (existing != null && existing.userId == userId) return existing;
    existing?._stop();
    final MechanicWorkspace fresh = MechanicWorkspace._(userId);
    _current = fresh;
    return fresh;
  }

  static MechanicWorkspace? get current => _current;

  /// Запускает фоновую работу. Зовётся оболочкой при открытии.
  void start() {
    _timer ??= Timer.periodic(_period, (_) => refresh());
    unawaited(refresh());
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
  }

  /// Отдать сделанное и забрать изменения — именно в таком порядке.
  ///
  /// Сначала очередь: иначе синхронизация принесёт запись в прежнем
  /// состоянии и затрёт ею то, что человек уже отметил на телефоне.
  Future<void> refresh() async {
    await outbox.flush();
    final SyncResult result = await sync.pullAll();
    final List<OutboxAction> waiting = await outbox.pending();
    final List<OutboxAction> denied = await outbox.rejected();

    // Отказ по существу человек должен увидеть даже если не смотрел на полосу
    // состояния: это его работа, которая не ушла. Повторно записать событие
    // нельзя — журнал отбрасывает уже известные ключи.
    await journal.add(<MechanicEvent>[
      for (final OutboxAction action in denied)
        rejectedEvent(
          actionId: action.id,
          actionTitle: action.title,
          error: action.lastError,
          nowMs: DateTime.now().millisecondsSinceEpoch,
        ),
    ]);

    status.value = WorkspaceStatus(
      pending: waiting.length,
      rejected: denied.length,
      unread: await journal.unread(),
      lastSyncAt: result.ok ? DateTime.now() : status.value.lastSyncAt,
      lastError: result.ok ? null : result.error,
    );
  }

  /// Ставит в очередь смену статуса заявки.
  ///
  /// Здесь же запоминается, что правку сделал я: та же отметка приедет
  /// обратно синхронизацией, и без этого телефон сообщил бы мне о моём же
  /// действии как о чужом изменении.
  Future<void> sendOrderStatus({
    required int orderId,
    required int statusId,
    required String title,
    String? commentary,
  }) async {
    await journal.rememberMyChange(changeKey(TaskKind.order, orderId, statusId));
    await outbox.enqueue(
      title: title,
      method: 'PUT',
      path: '/order/$orderId/',
      body: <String, dynamic>{
        'status_id': statusId,
        if (commentary != null && commentary.trim().isNotEmpty)
          'commentary': commentary.trim(),
      },
    );
    await _markLocally(orderId, statusId, commentary);
    await _publishQueue();
  }

  /// Отмечает заявку в локальной базе сразу, не дожидаясь сервера.
  ///
  /// Без этого механик в подвале нажимает «В работу» и не видит никакого
  /// отклика до следующего выхода на связь — то есть считает, что кнопка не
  /// сработала, и жмёт ещё раз. Синхронизация потом перезапишет строку
  /// серверной версией.
  Future<void> _markLocally(int orderId, int statusId, String? commentary) async {
    final List<Map<String, dynamic>> rows =
        await localStore.read(LocalCollection.orders);
    for (final Map<String, dynamic> row in rows) {
      if (asInt(row['id']) != orderId) continue;
      row['status_id'] = <String, dynamic>{
        'id': statusId,
        'name': orderStatusName(statusId),
      };
      if (commentary != null && commentary.trim().isNotEmpty) {
        row['commentary'] = commentary.trim();
      }
    }
    await localStore.write(LocalCollection.orders, rows);
  }

  /// Ставит фотографию в очередь. Снимок уже сжат — это делает `image_picker`
  /// на входе, см. экран заявки.
  Future<void> attachOrderPhoto({
    required int orderId,
    required List<int> bytes,
    required String fileName,
  }) async {
    await outbox.enqueue(
      title: 'Фото к заявке №$orderId',
      method: 'POST',
      path: '/order-photo/$orderId/',
      file: bytes,
      fileName: fileName,
    );
    await _publishQueue();
  }

  /// Сколько снимков этой заявки ещё не ушло на сервер.
  Future<int> queuedPhotos(int orderId) async {
    final List<OutboxAction> waiting = await outbox.pending();
    return waiting
        .where((OutboxAction action) =>
            action.fileKey != null && action.path == '/order-photo/$orderId/')
        .length;
  }

  /// Обновляет счётчики очереди в интерфейсе, не дожидаясь синхронизации.
  Future<void> _publishQueue() async {
    final List<OutboxAction> waiting = await outbox.pending();
    final List<OutboxAction> denied = await outbox.rejected();
    status.value = WorkspaceStatus(
      pending: waiting.length,
      rejected: denied.length,
      unread: await journal.unread(),
      lastSyncAt: status.value.lastSyncAt,
      lastError: status.value.lastError,
    );
  }

  /// Гасит счётчик уведомлений — человек открыл вкладку и всё увидел.
  Future<void> markNotificationsRead() async {
    await journal.markAllRead();
    await _publishQueue();
  }

  /// Забывает всё про человека — при выходе из системы.
  Future<void> forget() async {
    _stop();
    await outbox.forget();
    await localStore.forget();
    status.value = const WorkspaceStatus();
    if (identical(_current, this)) _current = null;
  }

  /// Отправка одного действия очереди.
  ///
  /// Путь хранится без хоста, поэтому адрес собирается здесь и всегда из
  /// текущей настройки — см. `helper/api_config.dart`.
  Future<SendOutcome> _send(OutboxAction action) async {
    final Uri url = Uri.parse('${ApiConfig.base}${action.path}');

    final List<int>? bytes = action.bytes;
    if (bytes != null) return _sendFile(action, url, bytes);

    final Map<String, String> headers = <String, String>{
      'Content-Type': 'application/json',
    };
    final String body = jsonEncode(action.body);

    http.Response response;
    switch (action.method.toUpperCase()) {
      case 'POST':
        response = await Api.post(url, headers: headers, body: body);
        break;
      case 'PUT':
        response = await Api.put(url, headers: headers, body: body);
        break;
      default:
        // Такого действия мы не заводили. Повторять бессмысленно.
        action.lastError = 'Неизвестный метод ${action.method}';
        return SendOutcome.rejected;
    }

    if (response.statusCode >= 400) {
      action.lastError = ApiError.messageOf(response);
    }
    return outcomeForStatus(response.statusCode);
  }

  /// Отправка действия с файлом — фотографии к заявке.
  ///
  /// Тело такого запроса поток, и повторить его после `401` нельзя, поэтому
  /// токен обновляется до отправки: этим занимается `Api.multipart`.
  /// Расширение в имени файла обязательно — бэкенд берёт его из `filename` и
  /// с ним сохраняет снимок на диск.
  Future<SendOutcome> _sendFile(
    OutboxAction action,
    Uri url,
    List<int> bytes,
  ) async {
    try {
      final http.MultipartRequest request = await Api.multipart(
        action.method.toUpperCase(),
        url,
      );
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: action.fileName ?? 'photo.jpg',
        ),
      );
      final http.Response response = await http.Response.fromStream(
        await request.send(),
      );
      if (response.statusCode >= 400) {
        action.lastError = ApiError.messageOf(response);
      }
      return outcomeForStatus(response.statusCode);
    } catch (error) {
      // Связь оборвалась на середине потока. Файл остаётся в очереди.
      action.lastError = '$error';
      return SendOutcome.retry;
    }
  }
}

/// То, что оболочка показывает про связь и неотправленное.
class WorkspaceStatus {
  const WorkspaceStatus({
    this.pending = 0,
    this.rejected = 0,
    this.unread = 0,
    this.lastSyncAt,
    this.lastError,
  });

  final int pending;
  final int rejected;

  /// Непрочитанных уведомлений — красная точка на вкладке из макета.
  final int unread;

  final DateTime? lastSyncAt;
  final String? lastError;
}
