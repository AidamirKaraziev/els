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
import 'outbox.dart';

class MechanicWorkspace {
  MechanicWorkspace._(this.userId, {KeyValueStore store = const PreferencesStore()})
      : localStore = LocalStore(userId: userId, store: store) {
    outbox = Outbox(userId: userId, sender: _send, store: store);
    sync = MechanicSync(store: localStore);
  }

  final int userId;
  final LocalStore localStore;
  late final Outbox outbox;
  late final MechanicSync sync;

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

    status.value = WorkspaceStatus(
      pending: waiting.length,
      rejected: denied.length,
      lastSyncAt: result.ok ? DateTime.now() : status.value.lastSyncAt,
      lastError: result.ok ? null : result.error,
    );
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
}

/// То, что оболочка показывает про связь и неотправленное.
class WorkspaceStatus {
  const WorkspaceStatus({
    this.pending = 0,
    this.rejected = 0,
    this.lastSyncAt,
    this.lastError,
  });

  final int pending;
  final int rejected;
  final DateTime? lastSyncAt;
  final String? lastError;
}
