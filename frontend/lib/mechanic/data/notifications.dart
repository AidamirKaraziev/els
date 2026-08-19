/// Уведомления механика — считаются на телефоне, бэкенд о них не знает.
///
/// Таблицы уведомлений на сервере нет, и заводить её ради вкладки со списком
/// незачем: всё, о чём нужно сказать, видно из разницы между тем, что лежало
/// на телефоне, и тем, что приехало синхронизацией. Push — отдельный этап, и
/// вот для него сервер понадобится.
///
/// О чём сообщаем:
///
/// * **Новая задача.** Записи не было, и она появилась. Заявку отдают обоим —
///   исполнителю и механику объекта, — поэтому уведомление получают тоже оба.
/// * **Статус сменил кто-то другой.** По задаче, которую ведут двое, важно
///   знать, что второй уже начал. Свои же отметки в уведомления не попадают:
///   человек их только что сделал руками, напоминать ему о них — шум.
/// * **Задачу сняли.** Приезжает как `is_actual: false`. Молча убрать её с
///   экрана нельзя: механик решит, что приложение потеряло работу.
/// * **Сервер отклонил моё действие.** Раньше это было видно только полосой
///   состояния, которая исчезает при следующем обновлении.
///
/// Порядок в журнале — свежее сверху. Прочитанность одна на весь список:
/// человек заходит на вкладку и видит всё, счётчик гаснет.
library;

import 'local_store.dart';
import 'tasks.dart';

/// О чём уведомление.
enum MechanicEventKind {
  /// На меня поставили задачу.
  assigned,

  /// Статус или прогресс сменил кто-то другой.
  statusChanged,

  /// Задачу удалили.
  removed,

  /// Сервер отказал по существу — повторять бессмысленно.
  rejected,
}

/// Одна запись журнала.
class MechanicEvent {
  const MechanicEvent({
    required this.id,
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.at,
    this.read = false,
    this.taskKind,
    this.taskId,
  });

  /// Ключ записи. Собран из события, а не из счётчика: одно и то же событие,
  /// пришедшее дважды (повторная синхронизация той же правки), не должно
  /// удваивать список.
  final String id;

  final MechanicEventKind kind;

  /// Первая строка: «Новая заявка».
  final String title;

  /// Вторая строка: объект и подробность.
  final String subtitle;

  /// Когда, в миллисекундах эпохи.
  final int at;

  final bool read;

  /// Куда ведёт тап, если событие про конкретную работу.
  final TaskKind? taskKind;
  final int? taskId;

  MechanicEvent asRead() => MechanicEvent(
        id: id,
        kind: kind,
        title: title,
        subtitle: subtitle,
        at: at,
        read: true,
        taskKind: taskKind,
        taskId: taskId,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'kind': kind.name,
        'title': title,
        'subtitle': subtitle,
        'at': at,
        'read': read,
        if (taskKind != null) 'task_kind': taskKind!.name,
        if (taskId != null) 'task_id': taskId,
      };

  static MechanicEvent? fromJson(Map<String, dynamic> row) {
    final Object? id = row['id'];
    final Object? kind = row['kind'];
    if (id is! String || kind is! String) return null;
    return MechanicEvent(
      id: id,
      kind: MechanicEventKind.values.firstWhere(
        (MechanicEventKind value) => value.name == kind,
        orElse: () => MechanicEventKind.statusChanged,
      ),
      title: asString(row['title']) ?? 'Изменение',
      subtitle: asString(row['subtitle']) ?? '',
      at: asInt(row['at']) ?? 0,
      read: row['read'] == true,
      taskKind: TaskKind.values
          .where((TaskKind value) => value.name == row['task_kind'])
          .firstOrNull,
      taskId: asInt(row['task_id']),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

/// Журнал уведомлений одного человека.
///
/// Живёт в той же локальной базе, поэтому выход из системы забывает его вместе
/// со всем остальным: телефон в бригаде бывает общим.
class NotificationJournal {
  NotificationJournal({required this.store, this.keep = 50});

  final LocalStore store;

  /// Сколько записей храним. Журнал — это «что случилось, пока меня не было»,
  /// а не история за годы.
  final int keep;

  Future<List<MechanicEvent>> all() async {
    final List<Map<String, dynamic>> rows =
        await store.read(LocalCollection.events);
    final List<MechanicEvent> events = <MechanicEvent>[];
    for (final Map<String, dynamic> row in rows) {
      final MechanicEvent? event = MechanicEvent.fromJson(row);
      if (event != null) events.add(event);
    }
    events.sort((MechanicEvent a, MechanicEvent b) => b.at.compareTo(a.at));
    return events;
  }

  Future<int> unread() async {
    final List<MechanicEvent> events = await all();
    return events.where((MechanicEvent event) => !event.read).length;
  }

  /// Дописывает новые события, не задваивая уже записанные.
  Future<void> add(List<MechanicEvent> fresh) async {
    if (fresh.isEmpty) return;

    final List<MechanicEvent> events = await all();
    final Set<String> known = <String>{
      for (final MechanicEvent event in events) event.id,
    };
    final List<MechanicEvent> merged = <MechanicEvent>[
      for (final MechanicEvent event in fresh)
        if (!known.contains(event.id)) event,
      ...events,
    ];
    merged.sort((MechanicEvent a, MechanicEvent b) => b.at.compareTo(a.at));

    await store.write(
      LocalCollection.events,
      <Map<String, dynamic>>[
        for (final MechanicEvent event in merged.take(keep)) event.toJson(),
      ],
    );
  }

  Future<void> markAllRead() async {
    final List<MechanicEvent> events = await all();
    if (events.every((MechanicEvent event) => event.read)) return;
    await store.write(
      LocalCollection.events,
      <Map<String, dynamic>>[
        for (final MechanicEvent event in events) event.asRead().toJson(),
      ],
    );
  }

  /// Запоминает, что правку сделал я сам, — чтобы синхронизация не сообщила
  /// мне о ней как о чужой. Ключ тот же, что считает [changeKey].
  Future<void> rememberMyChange(String key) async {
    final List<Map<String, dynamic>> rows =
        await store.read(LocalCollection.myChanges);
    if (rows.any((Map<String, dynamic> row) => row['key'] == key)) return;
    await store.write(
      LocalCollection.myChanges,
      <Map<String, dynamic>>[
        ...rows.take(keep),
        <String, dynamic>{'key': key},
      ],
    );
  }

  Future<Set<String>> myChanges() async {
    final List<Map<String, dynamic>> rows =
        await store.read(LocalCollection.myChanges);
    return <String>{
      for (final Map<String, dynamic> row in rows)
        if (row['key'] is String) row['key'] as String,
    };
  }

  /// Убирает отметки о своих правках, которые уже приехали с сервера.
  Future<void> forgetMyChanges(Set<String> applied) async {
    if (applied.isEmpty) return;
    final List<Map<String, dynamic>> rows =
        await store.read(LocalCollection.myChanges);
    await store.write(
      LocalCollection.myChanges,
      <Map<String, dynamic>>[
        for (final Map<String, dynamic> row in rows)
          if (!applied.contains(row['key'])) row,
      ],
    );
  }
}

/// Ключ «эту правку сделал я»: вид работы, запись и новое состояние.
String changeKey(TaskKind kind, int id, Object? state) =>
    '${kind.name}:$id:$state';

/// События из разницы между тем, что лежало, и тем, что приехало.
///
/// Считается до слияния: после него прежнего состояния уже не узнать.
List<MechanicEvent> eventsFromSync({
  required List<Map<String, dynamic>> stored,
  required List<Map<String, dynamic>> incoming,
  required TaskKind kind,
  required int nowMs,
  Set<String> myChanges = const <String>{},
  Set<String>? matchedMyChanges,
}) {
  final String idField = kind == TaskKind.order ? 'id' : 'act_id';
  final Map<Object, Map<String, dynamic>> before =
      <Object, Map<String, dynamic>>{
    for (final Map<String, dynamic> row in stored)
      if (row[idField] != null) row[idField] as Object: row,
  };

  final List<MechanicEvent> events = <MechanicEvent>[];

  for (final Map<String, dynamic> row in incoming) {
    final int? id = asInt(row[idField]);
    if (id == null) continue;
    final Map<String, dynamic>? was = before[id];
    final int mark = asInt(row['updated_at']) ?? nowMs ~/ 1000;
    final String object = _objectName(row, kind);

    if (row['is_actual'] == false) {
      // О снятии говорим только если задача у человека была: иначе это правка
      // записи, которую он никогда не видел.
      if (was == null || was['is_actual'] == false) continue;
      events.add(
        MechanicEvent(
          id: 'removed:${kind.name}:$id:$mark',
          kind: MechanicEventKind.removed,
          title: kind == TaskKind.order ? 'Заявку сняли' : 'ТО сняли',
          subtitle: object,
          at: mark * 1000,
          taskKind: kind,
          taskId: id,
        ),
      );
      continue;
    }

    if (was == null) {
      events.add(
        MechanicEvent(
          id: 'assigned:${kind.name}:$id',
          kind: MechanicEventKind.assigned,
          title: kind == TaskKind.order ? 'Новая заявка' : 'Новое ТО',
          subtitle: _assignedSubtitle(row, kind, object),
          at: mark * 1000,
          taskKind: kind,
          taskId: id,
        ),
      );
      continue;
    }

    final Object? state = _stateOf(row, kind);
    if (state == _stateOf(was, kind)) continue;

    final String mine = changeKey(kind, id, state);
    if (myChanges.contains(mine)) {
      // Это приехала моя же отметка. Сообщать о ней нечего.
      matchedMyChanges?.add(mine);
      continue;
    }

    events.add(
      MechanicEvent(
        id: 'state:${kind.name}:$id:$state:$mark',
        kind: MechanicEventKind.statusChanged,
        title: kind == TaskKind.order ? 'Заявка изменилась' : 'ТО изменилось',
        subtitle: '$object · ${_stateText(row, kind)}',
        at: mark * 1000,
        taskKind: kind,
        taskId: id,
      ),
    );
  }

  return events;
}

/// Событие «сервер отказал» из отклонённого действия очереди.
MechanicEvent rejectedEvent({
  required String actionId,
  required String actionTitle,
  String? error,
  required int nowMs,
}) {
  return MechanicEvent(
    id: 'rejected:$actionId',
    kind: MechanicEventKind.rejected,
    title: 'Сервер отклонил действие',
    subtitle: error == null ? actionTitle : '$actionTitle · $error',
    at: nowMs,
  );
}

/// Состояние, изменение которого стоит показать.
///
/// У заявки это статус. У ТО статуса в списке нет — там важно, сколько шагов
/// сделано и закрыто ли ТО.
Object? _stateOf(Map<String, dynamic> row, TaskKind kind) {
  if (kind == TaskKind.order) return asInt(asMap(row['status_id'])['id']);
  if (row['finished_at'] != null) return 'closed';
  return asInt(row['steps_done']) ?? 0;
}

String _stateText(Map<String, dynamic> row, TaskKind kind) {
  if (kind == TaskKind.order) {
    return asString(asMap(row['status_id'])['name']) ?? 'статус изменился';
  }
  if (row['finished_at'] != null) return 'ТО закрыто';
  final int done = asInt(row['steps_done']) ?? 0;
  final int total = asInt(row['steps_total']) ?? 0;
  return total == 0 ? 'сделано $done' : 'сделано $done из $total';
}

String _objectName(Map<String, dynamic> row, TaskKind kind) {
  final Map<String, dynamic> object =
      asMap(kind == TaskKind.order ? row['object_id'] : row['object']);
  return asString(object['name']) ?? 'Объект';
}

String _assignedSubtitle(
  Map<String, dynamic> row,
  TaskKind kind,
  String object,
) {
  if (kind == TaskKind.order) {
    final String? code = asString(asMap(row['fault_category_id'])['code']);
    return code == null ? object : '$object · $code';
  }
  final int? year = asInt(row['year']);
  final int? month = asInt(row['month']);
  if (year == null || month == null) return object;
  return '$object · срок ${monthText(year, month)}';
}
