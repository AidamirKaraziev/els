/// Синхронизация телефона механика с бэкендом.
///
/// Одна мысль на весь файл: **спрашиваем не «дай всё», а «что изменилось с
/// момента T»**. `GET /order/for-me` и `GET /act-fact/for-me` принимают
/// `changed_since` и отдают только правки — вместе с удалёнными, которые
/// приходят с `is_actual: false` (мягкое удаление на бэкенде сделано ровно
/// ради этого). Иначе через год работы механик качал бы сотни записей на
/// каждом выходе на связь.
///
/// Чего здесь намеренно нет:
///
/// * **`only_open` вместе с `changed_since`.** Закрытая заявка тогда просто
///   исчезнет из ответа, и телефон не узнает, что она закрылась. Отбор
///   «что мне делать сейчас» делается уже на телефоне, по локальным данным.
/// * **Опроса по таймеру каждые три секунды**, как было у подрядчика.
///   Синхронизация идёт при открытии приложения, при возврате на вкладку и
///   после отправки очереди — то есть тогда, когда данные могли устареть.
library;

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../helper/api_client.dart';
import '../../helper/api_config.dart';
import 'local_store.dart';
import 'notifications.dart';
import 'tasks.dart';

/// Чем закончилась синхронизация — это показывается человеку, поэтому
/// различаем «нет сети» и «сервер отказал».
class SyncResult {
  const SyncResult({
    required this.ok,
    required this.received,
    this.error,
  });

  final bool ok;

  /// Сколько записей приехало. Ноль при `ok` — нормально: значит ничего не
  /// менялось с прошлого раза.
  final int received;

  final String? error;
}

class MechanicSync {
  MechanicSync({required this.store, NotificationJournal? journal})
      : journal = journal ?? NotificationJournal(store: store);

  final LocalStore store;

  /// Журнал уведомлений. Синхронизация — единственное место, где видно и
  /// прежнее состояние записи, и новое, поэтому события считаются здесь.
  final NotificationJournal journal;

  /// Тянет обе коллекции. Ошибка в одной не отменяет вторую: список ТО и
  /// список заявок независимы, и уронить оба из-за одного отказа — значит
  /// оставить механика без обоих.
  Future<SyncResult> pullAll() async {
    final SyncResult orders = await pull(
      collection: LocalCollection.orders,
      path: '/order/for-me',
      kind: TaskKind.order,
    );
    final SyncResult maintenance = await pull(
      collection: LocalCollection.maintenance,
      path: '/act-fact/for-me',
      kind: TaskKind.maintenance,
    );

    return SyncResult(
      ok: orders.ok && maintenance.ok,
      received: orders.received + maintenance.received,
      error: orders.error ?? maintenance.error,
    );
  }

  /// Одна коллекция: спросить изменения, слить с локальными, сдвинуть метку.
  Future<SyncResult> pull({
    required String collection,
    required String path,
    required TaskKind kind,
  }) async {
    final String idField = kind == TaskKind.order ? 'id' : 'act_id';
    final int? mark = await store.mark(collection);
    final Uri url = Uri.parse('${ApiConfig.base}$path').replace(
      queryParameters: <String, String>{
        if (mark != null) 'changed_since': '$mark',
      },
    );

    http.Response response;
    try {
      response = await Api.get(url);
    } catch (_) {
      // Нет сети. Это не ошибка приложения: локальные данные остаются в силе,
      // а метка не двигается, и в следующий раз спросим ровно то же.
      return const SyncResult(
        ok: false,
        received: 0,
        error: 'Нет связи с сервером',
      );
    }

    if (response.statusCode != 200) {
      return SyncResult(
        ok: false,
        received: 0,
        error: ApiError.messageOf(response, fallback: 'Сервер не отдал данные'),
      );
    }

    final List<Map<String, dynamic>> incoming = _rows(response);
    final List<Map<String, dynamic>> stored = await store.read(collection);

    // Уведомления считаются до слияния: после него прежнего состояния записи
    // уже не узнать, а вся разница именно в нём.
    final Set<String> mine = <String>{};
    final List<MechanicEvent> events = eventsFromSync(
      stored: stored,
      incoming: incoming,
      kind: kind,
      nowMs: DateTime.now().millisecondsSinceEpoch,
      myChanges: await journal.myChanges(),
      matchedMyChanges: mine,
    );

    await store.write(
      collection,
      mergeRows(stored, incoming, idField: idField),
    );
    await journal.add(events);
    await journal.forgetMyChanges(mine);

    // Метку двигаем только после того, как данные легли на диск. Иначе
    // прерванная запись означала бы пропущенные навсегда правки: метка уже
    // сдвинута, а записей нет.
    final int? next = latestMark(incoming, mark);
    if (next != null && next != mark) await store.setMark(collection, next);

    return SyncResult(ok: true, received: incoming.length);
  }

  List<Map<String, dynamic>> _rows(http.Response response) {
    try {
      final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));
      final dynamic data = decoded is Map ? decoded['data'] : null;
      if (data is! List) return <Map<String, dynamic>>[];
      return data
          .whereType<Map<dynamic, dynamic>>()
          .map((Map<dynamic, dynamic> row) => row.cast<String, dynamic>())
          .toList();
    } on FormatException {
      return <Map<String, dynamic>>[];
    }
  }
}
