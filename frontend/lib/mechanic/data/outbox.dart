/// Очередь исходящих действий механика.
///
/// В лифтовом помещении связи нет. Механик отмечает «в работу», проходит
/// чек-лист, закрывает ТО — и всё это должно уйти на сервер, когда телефон
/// снова увидит сеть, а не потеряться вместе с экраном.
///
/// Правила, из которых сделана очередь:
///
/// * **Порядок сохраняется, и очередь встаёт на первой временной ошибке.**
///   «В работу» обязано уйти раньше «выполнил»: бэкенд по смене статуса
///   проставляет `in_progress_at` и `done_at`, и переставленные местами
///   действия дадут заявку, закрытую раньше, чем начатую.
/// * **Адрес хранится путём, без хоста.** Origin приезжает из `--dart-define`
///   или из адреса страницы и между запусками меняется (офис, объект,
///   боевой домен). Сохранённая целиком ссылка ушла бы завтра не туда.
/// * **Отказ отказу рознь.** Нет сети, `429` или `5xx` — повторяем. `403`
///   или `422` повторять бессмысленно: сервер уже сказал «нет», и повтор
///   через час скажет то же самое. Такое действие уходит в «отклонённые» и
///   показывается человеку — молча выбросить его нельзя, это его работа.
/// * **`401` не считается отказом.** Токен обновляет клиент API сам; для
///   очереди это просто «сейчас не вышло».
library;

import 'dart:async';
import 'dart:convert';

import 'local_store.dart';

/// Одно отложенное действие.
class OutboxAction {
  OutboxAction({
    required this.id,
    required this.title,
    required this.method,
    required this.path,
    required this.body,
    required this.createdAt,
    this.attempts = 0,
    this.lastError,
  });

  /// Идентификатор внутри очереди: время создания плюс счётчик. Нужен, чтобы
  /// убрать из очереди именно это действие, а не «похожее».
  final String id;

  /// Что человек увидит в списке неотправленного: «Заявка №14 — в работу».
  final String title;

  final String method;

  /// Путь после `/api/v1`, с ведущим слэшем: `/order/14/`.
  final String path;

  final Map<String, dynamic> body;

  /// Когда действие сделано на телефоне, миллисекунды эпохи.
  final int createdAt;

  int attempts;

  String? lastError;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'title': title,
        'method': method,
        'path': path,
        'body': body,
        'created_at': createdAt,
        'attempts': attempts,
        'last_error': lastError,
      };

  static OutboxAction? fromJson(Map<String, dynamic> row) {
    final dynamic id = row['id'];
    final dynamic method = row['method'];
    final dynamic path = row['path'];
    if (id is! String || method is! String || path is! String) return null;
    return OutboxAction(
      id: id,
      title: row['title'] is String ? row['title'] as String : path,
      method: method,
      path: path,
      body: row['body'] is Map
          ? (row['body'] as Map<dynamic, dynamic>).cast<String, dynamic>()
          : <String, dynamic>{},
      createdAt: row['created_at'] is int ? row['created_at'] as int : 0,
      attempts: row['attempts'] is int ? row['attempts'] as int : 0,
      lastError: row['last_error'] is String ? row['last_error'] as String : null,
    );
  }
}

/// Чем закончилась попытка отправки.
enum SendOutcome {
  /// Сервер принял. Действие уходит из очереди.
  done,

  /// Сейчас не вышло: нет сети, `429`, `5xx`, протухший токен. Пробуем позже.
  retry,

  /// Сервер отказал по существу. Повторять нечего, человеку надо сказать.
  rejected,
}

/// Отправщик одного действия. Отдельным типом, чтобы очередь не зависела ни
/// от `http`, ни от адреса бэкенда и проверялась тестами без сети.
typedef ActionSender = Future<SendOutcome> Function(OutboxAction action);

/// Очередь исходящих действий одного человека.
class Outbox {
  Outbox({
    required this.userId,
    required ActionSender sender,
    KeyValueStore store = const PreferencesStore(),
    DateTime Function() now = DateTime.now,
  })  : _sender = sender,
        _store = store,
        _now = now;

  final int userId;
  final ActionSender _sender;
  final KeyValueStore _store;
  final DateTime Function() _now;

  static const String _prefix = 'mechanic';

  String get _queueKey => '$_prefix.$userId.outbox';

  String get _rejectedKey => '$_prefix.$userId.outbox.rejected';

  /// Идёт ли отправка прямо сейчас. Две параллельные отправки послали бы одно
  /// действие дважды — а «выполнил» дважды означает две записи в истории.
  Future<void>? _flushing;

  int _counter = 0;

  /// Ставит действие в очередь и пробует отправить сразу.
  ///
  /// Ждать отправки экран не должен: смысл очереди в том, что кнопка
  /// срабатывает мгновенно и без сети.
  Future<OutboxAction> enqueue({
    required String title,
    required String method,
    required String path,
    Map<String, dynamic> body = const <String, dynamic>{},
  }) async {
    final DateTime moment = _now();
    final OutboxAction action = OutboxAction(
      id: '${moment.microsecondsSinceEpoch}-${_counter++}',
      title: title,
      method: method,
      path: path,
      body: body,
      createdAt: moment.millisecondsSinceEpoch,
    );

    final List<OutboxAction> queue = await pending();
    queue.add(action);
    await _save(_queueKey, queue);

    unawaited(flush());
    return action;
  }

  /// Что ещё не ушло.
  Future<List<OutboxAction>> pending() => _load(_queueKey);

  /// Что сервер отклонил и о чём надо сказать человеку.
  Future<List<OutboxAction>> rejected() => _load(_rejectedKey);

  /// Убирает отклонённое из показа — человек его увидел.
  Future<void> forgetRejected() => _store.remove(_rejectedKey);

  /// Отправляет очередь по порядку, до первой временной осечки.
  ///
  /// Возвращает число ушедших действий. Повторный вызов во время отправки
  /// ждёт текущую, а не запускает вторую.
  Future<int> flush() async {
    final Future<void>? running = _flushing;
    if (running != null) {
      await running;
      return 0;
    }

    final Completer<void> gate = Completer<void>();
    _flushing = gate.future;
    try {
      return await _flush();
    } finally {
      _flushing = null;
      gate.complete();
    }
  }

  Future<int> _flush() async {
    List<OutboxAction> queue = await pending();
    if (queue.isEmpty) return 0;

    int sent = 0;
    while (queue.isNotEmpty) {
      final OutboxAction action = queue.first;

      SendOutcome outcome;
      try {
        outcome = await _sender(action);
      } catch (error) {
        // Сеть отвалилась прямо во время отправки. Это ровно тот случай,
        // ради которого очередь и заведена.
        outcome = SendOutcome.retry;
        action.lastError = '$error';
      }

      if (outcome == SendOutcome.retry) {
        action.attempts += 1;
        await _save(_queueKey, queue);
        break;
      }

      queue.removeAt(0);
      if (outcome == SendOutcome.rejected) {
        final List<OutboxAction> denied = await rejected();
        denied.add(action);
        await _save(_rejectedKey, denied);
      } else {
        sent += 1;
      }
      await _save(_queueKey, queue);
    }

    return sent;
  }

  /// Забывает очередь этого человека — при выходе из системы.
  Future<void> forget() async {
    await _store.remove(_queueKey);
    await _store.remove(_rejectedKey);
  }

  Future<List<OutboxAction>> _load(String key) async {
    final String? raw = await _store.read(key);
    if (raw == null || raw.isEmpty) return <OutboxAction>[];
    try {
      final dynamic decoded = jsonDecode(raw);
      if (decoded is! List) return <OutboxAction>[];
      return decoded
          .whereType<Map<dynamic, dynamic>>()
          .map((Map<dynamic, dynamic> row) =>
              OutboxAction.fromJson(row.cast<String, dynamic>()))
          .whereType<OutboxAction>()
          .toList();
    } on FormatException {
      return <OutboxAction>[];
    }
  }

  Future<void> _save(String key, List<OutboxAction> actions) {
    return _store.write(
      key,
      jsonEncode(actions.map((OutboxAction a) => a.toJson()).toList()),
    );
  }
}

/// Как понимать ответ сервера.
///
/// Вынесено отдельно от отправщика, потому что это правило одно на все
/// действия и его нужно проверять тестами, а не глазами.
SendOutcome outcomeForStatus(int statusCode) {
  if (statusCode >= 200 && statusCode < 300) return SendOutcome.done;

  // Токен протух — обновление уже сделал клиент API, а нам достаточно
  // повторить. Ждать перевхода не нужно: если сессии нет совсем, человека
  // уведут на экран входа, а очередь дождётся следующего.
  if (statusCode == 401) return SendOutcome.retry;

  // Таймаут, «слишком часто» и любые пятисотые — сервер жив, но сейчас не
  // может. Это временное по определению.
  if (statusCode == 408 || statusCode == 429 || statusCode >= 500) {
    return SendOutcome.retry;
  }

  return SendOutcome.rejected;
}
