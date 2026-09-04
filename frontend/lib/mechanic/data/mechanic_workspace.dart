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
import '../../helper/image_picking.dart';
import 'acts.dart';
import 'local_store.dart';
import 'mechanic_sync.dart';
import 'notifications.dart';
import 'outbox.dart';
import 'tasks.dart';

class MechanicWorkspace {
  MechanicWorkspace._(this.userId, {KeyValueStore store = const PreferencesStore()})
      : localStore = LocalStore(userId: userId, store: store) {
    outbox = Outbox(
      userId: userId,
      sender: _send,
      store: store,
      onChanged: () => unawaited(_publishQueue()),
    );
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

  /// Чек-лист акта: сначала с сервера, при отказе — то, что лежит на телефоне.
  ///
  /// Порядок именно такой, а не «сначала кэш»: регламент правит прораб, и
  /// механик, открывший ТО на связи, должен увидеть свежий список пунктов.
  /// Без связи открывается сохранённый — иначе в подвале чек-лист вообще
  /// нельзя было бы посмотреть.
  Future<ActDetails?> loadAct(int actId) async {
    final Map<String, dynamic>? fresh = await _fetchAct(actId);
    if (fresh != null) {
      await _rememberAct(fresh);
      return actFromRow(fresh);
    }

    final List<Map<String, dynamic>> rows =
        await localStore.read(LocalCollection.acts);
    for (final Map<String, dynamic> row in rows) {
      if (asInt(row['id']) == actId) return actFromRow(row);
    }
    return null;
  }

  Future<Map<String, dynamic>?> _fetchAct(int actId) async {
    final Uri url = Uri.parse('${ApiConfig.base}/act-fact/$actId/');
    http.Response response;
    try {
      response = await Api.get(url);
    } catch (_) {
      return null;
    }
    if (response.statusCode != 200) return null;

    try {
      final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));
      final dynamic data = decoded is Map ? decoded['data'] : null;
      if (data is! Map) return null;
      return data.cast<String, dynamic>();
    } on FormatException {
      return null;
    }
  }

  /// Ставит в очередь правку чек-листа: отметку пункта, комментарий, начало
  /// работы и закрытие акта — всё это один и тот же `PUT`.
  ///
  /// Чек-лист уходит целиком: отдельной ручки «отметить пункт» на бэкенде
  /// нет, и это не упущение — пункт со своим номером считается тем же самым,
  /// а без номера новым.
  Future<void> sendActChecklist({
    required ActDetails act,
    required String title,
    bool start = false,
    bool finish = false,
    String? commentary,
  }) async {
    final int nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    await journal.rememberMyChange(
      changeKey(
        TaskKind.maintenance,
        act.id,
        finish ? 'closed' : act.doneCount,
      ),
    );

    // Начало и закрытие двигают ещё и статус: без него прораб видит только
    // даты и не отличает идущую работу от вставшей. Пауза при этом снимается
    // явным пустым `paused_at` — бэкенд отличает «не прислали» от «сбрось».
    final int? statusId = finish
        ? OrderStatus.done
        : start
            ? OrderStatus.inProgress
            : null;

    await outbox.enqueue(
      title: title,
      method: 'PUT',
      path: '/act-fact/${act.id}/',
      body: <String, dynamic>{
        'checklist': act.checklistBody(),
        if (start) 'started_at': nowSeconds,
        if (finish) 'finished_at': nowSeconds,
        if (statusId != null) ...<String, dynamic>{
          'status_id': statusId,
          'paused_at': null,
        },
        if (commentary != null && commentary.trim().isNotEmpty)
          'commentary': commentary.trim(),
      },
    );

    await _rememberAct(act.toRow());
    await _markActLocally(
      act,
      startedAt: start ? nowSeconds : null,
      finishedAt: finish ? nowSeconds : null,
      statusId: statusId,
      clearPause: statusId != null,
      commentary: commentary,
    );
    await _publishQueue();
  }

  /// Ставит в очередь смену состояния работы по ТО: пауза, проблема,
  /// возвращение к работе.
  ///
  /// Отдельно от [sendActChecklist], хотя ручка та же: чек-лист здесь не
  /// нужен и слать его незачем — он весит сотни килобайт, а меняется одно
  /// число. Пауза одним нажатием и без вопросов: её жмут, когда уже приехал
  /// аварийный вызов.
  Future<void> sendActState({
    required int actId,
    required int statusId,
    required String title,
    bool paused = false,
    String? commentary,
  }) async {
    final int nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    await outbox.enqueue(
      title: title,
      method: 'PUT',
      path: '/act-fact/$actId/',
      body: <String, dynamic>{
        'status_id': statusId,
        'paused_at': paused ? nowSeconds : null,
        if (commentary != null && commentary.trim().isNotEmpty)
          'commentary': commentary.trim(),
      },
    );

    await _markMaintenanceState(
      actId,
      statusId: statusId,
      pausedAt: paused ? nowSeconds : null,
      commentary: commentary,
    );
    await _publishQueue();
  }

  /// Кладёт чек-лист в локальную базу, чтобы карточка открывалась без связи.
  Future<void> _rememberAct(Map<String, dynamic> row) async {
    final int? id = asInt(row['id']);
    if (id == null) return;

    final List<Map<String, dynamic>> rows =
        await localStore.read(LocalCollection.acts);
    rows.removeWhere((Map<String, dynamic> stored) => asInt(stored['id']) == id);
    rows.add(row);
    await localStore.write(LocalCollection.acts, rows);
  }

  /// Отмечает ход работы в строке списка ТО, не дожидаясь сервера.
  ///
  /// То же, зачем это делается у заявки: без отклика человек считает, что
  /// кнопка не сработала. Синхронизация потом перезапишет строку серверной
  /// версией — `steps_done` она считает сама.
  Future<void> _markActLocally(
    ActDetails act, {
    int? startedAt,
    int? finishedAt,
    int? statusId,
    bool clearPause = false,
    String? commentary,
  }) async {
    final List<Map<String, dynamic>> rows =
        await localStore.read(LocalCollection.maintenance);
    for (final Map<String, dynamic> row in rows) {
      if (asInt(row['act_id']) != act.id) continue;
      row['steps_done'] = act.doneCount;
      row['steps_total'] = act.total;
      if (startedAt != null) row['started_at'] = startedAt;
      if (finishedAt != null) row['finished_at'] = finishedAt;
      if (statusId != null) row['status_id'] = statusId;
      if (clearPause) row['paused_at'] = null;
      if (commentary != null && commentary.trim().isNotEmpty) {
        row['commentary'] = commentary.trim();
      }
    }
    await localStore.write(LocalCollection.maintenance, rows);
  }

  /// Отмечает состояние работы в строке списка ТО, не дожидаясь сервера.
  ///
  /// `status_id` у ТО — число, а не карта, как у заявки: так его отдаёт
  /// список `/act-fact/for-me`, и записать сюда карту значило бы сломать
  /// разбор своих же строк.
  Future<void> _markMaintenanceState(
    int actId, {
    required int statusId,
    int? pausedAt,
    String? commentary,
  }) async {
    final List<Map<String, dynamic>> rows =
        await localStore.read(LocalCollection.maintenance);
    for (final Map<String, dynamic> row in rows) {
      if (asInt(row['act_id']) != actId) continue;
      row['status_id'] = statusId;
      row['paused_at'] = pausedAt;
      if (commentary != null && commentary.trim().isNotEmpty) {
        row['commentary'] = commentary.trim();
      }
    }
    await localStore.write(LocalCollection.maintenance, rows);
  }

  /// Ставит в очередь фотографию шага. Снимок уже сжат — этим занимается
  /// `image_picker` на входе, как и у заявки.
  Future<void> attachStepPhoto({
    required int actId,
    required int stepId,
    required List<int> bytes,
    required String fileName,
  }) async {
    await outbox.enqueue(
      title: 'Фото к шагу $stepId, ТО №$actId',
      method: 'POST',
      path: '/act-fact/$actId/step/$stepId/photo/',
      file: bytes,
      fileName: fileName,
    );
    await _publishQueue();
  }

  /// Ставит в очередь дефект, найденный в работе по ТО, и снимки к нему.
  ///
  /// Два запроса, а не один: адрес снимка — `/defective-act-photo/{id}/`, и
  /// `id` придумывает сервер в ответ на создание акта. Механик находит дефект
  /// в машинном помещении, где связи нет, поэтому оба уходят в очередь, а
  /// адрес снимка остаётся шаблоном с ключом до тех пор, пока акт не уйдёт —
  /// см. `outbox.dart`.
  ///
  /// Работу это не двигает: дефект пишется по ходу ТО и закрытию не мешает.
  Future<void> sendDefect({
    required int actId,
    required String title,
    String? description,
    List<PickedImage> photos = const <PickedImage>[],
  }) async {
    final OutboxAction act = await outbox.enqueue(
      title: 'Дефект по ТО №$actId — $title',
      method: 'POST',
      path: '/defective-act/',
      body: <String, dynamic>{
        'act_fact_id': actId,
        'title': title,
        if (description != null && description.trim().isNotEmpty)
          'description': description.trim(),
      },
      provides: true,
    );

    for (final PickedImage photo in photos) {
      final List<int>? bytes = photo.data;
      if (bytes == null) continue;
      await outbox.enqueue(
        title: 'Фото дефекта «$title»',
        method: 'POST',
        path: '/defective-act-photo/{${act.provides}}/',
        file: bytes,
        fileName: photo.fileName ?? 'defect.jpg',
      );
    }

    await _publishQueue();
  }

  /// Сколько снимков этого шага ещё не ушло на сервер.
  Future<int> queuedStepPhotos(int actId, int stepId) async {
    final Map<int, int> counts = await queuedStepPhotoCounts(actId);
    return counts[stepId] ?? 0;
  }

  /// Сколько снимков ждёт связи по каждому шагу акта.
  ///
  /// Считается за один проход по очереди: экран шагов спрашивает это разом за
  /// весь список, а не по пункту — очередь лежит в одном ключе хранилища, и
  /// восемь отдельных чтений означали бы восемь разборов одного и того же
  /// JSON.
  Future<Map<int, int>> queuedStepPhotoCounts(int actId) async {
    final RegExp shape = RegExp(r'^/act-fact/(\d+)/step/(\d+)/photo/$');
    final Map<int, int> counts = <int, int>{};

    for (final OutboxAction action in await outbox.pending()) {
      if (action.fileKey == null) continue;
      final RegExpMatch? match = shape.firstMatch(action.path);
      if (match == null) continue;
      if (int.tryParse(match.group(1)!) != actId) continue;
      final int? stepId = int.tryParse(match.group(2)!);
      if (stepId == null) continue;
      counts[stepId] = (counts[stepId] ?? 0) + 1;
    }
    return counts;
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
    final Uri url = Uri.parse('${ApiConfig.base}${action.target}');

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
    final SendOutcome outcome = outcomeForStatus(response.statusCode);

    // Действие обещало ключ — значит, `id` созданной записи ждут следующие в
    // очереди. Не разобрали — ключа не будет, и ждущий его снимок очередь
    // отклонит: это честнее, чем отправить снимок в никуда.
    if (outcome == SendOutcome.done && action.provides != null) {
      action.createdId = _createdIdOf(response);
    }
    return outcome;
  }

  /// `id` созданной записи из ответа. Формат общий для всех ручек:
  /// `{"data": {"id": 12, …}}`.
  int? _createdIdOf(http.Response response) {
    try {
      final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));
      final dynamic data = decoded is Map ? decoded['data'] : null;
      return data is Map ? asInt(data['id']) : null;
    } on FormatException {
      return null;
    }
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
