/// Работа механика одним списком: заявки и плановые ТО вместе.
///
/// Экран не должен решать, что из чего состоит, и тем более считать это в
/// `build`. Здесь строки локальной базы — как их отдал бэкенд — превращаются в
/// [MechanicTask] с уже посчитанной секцией и порядком, а экран остаётся
/// вёрсткой. Заодно это то место, которое проверяется тестами без телефона и
/// без сети.
///
/// Правила, из которых сделан список:
///
/// * **Четыре секции: сейчас, планируется, сделано, архив.** Механику нужно
///   понимать, что делать сегодня и что его ждёт; сданное он хочет видеть, но
///   отдельно, а удалённое — серым и убранным с глаз.
/// * **Срок у заявки и у ТО разный.** У заявки срока в базе нет вовсе, только
///   дата создания: заявку делают сразу, поэтому она всегда «сейчас». У ТО
///   срок — плановый месяц; дня в графике нет
///   (`план ТО - заполненная ячейка месяца, а не отдельный признак`), поэтому
///   ТО текущего и прошедших месяцев — «сейчас», а будущих — «планируется».
/// * **Аварии сверху.** Порог реакции на застревание — полчаса, на прочее
///   сутки. Список, где авария лежит под просроченным ТО позапрошлого года,
///   работать мешает.
/// * **Заявку ведут двое.** Исполнитель и механик, отвечающий за лифт;
///   `GET /order/for-me` отдаёт её обоим. Если я не исполнитель, я наблюдаю:
///   отмечать за него нельзя, и сервер это тоже не даст —
///   `POST /order-photo/{id}/` проверяет исполнителя.
library;

import '../../helper/calendar/month_picker.dart';

/// Что это за работа. Разные ручки, разные экраны, разные действия.
enum TaskKind {
  /// Заявка диспетчера — `GET /order/for-me`.
  order,

  /// Плановое ТО — `GET /act-fact/for-me`.
  maintenance,
}

/// Куда работа попадает на экране. Порядок объявления — порядок на экране.
enum TaskSection {
  /// Делать сейчас: открытые заявки и ТО, чей плановый месяц уже наступил.
  now,

  /// Планируется: ТО будущих месяцев.
  planned,

  /// Сделано: заявка «Выполнено» или «Проблема», ТО с датой закрытия.
  done,

  /// Архив: запись удалили. Показывается серым и в свёрнутом виде.
  archive,
}

/// Статусы заявки из справочника `statuses` — те же числа, что на бэкенде.
class OrderStatus {
  static const int created = 1;
  static const int accepted = 2;
  static const int inProgress = 3;
  static const int done = 4;
  static const int problem = 5;
}

/// Название статуса заявки словами.
///
/// Справочник `statuses` приезжает вместе с заявкой, но отметка, поставленная
/// без связи, приходит от нас самих — и подписать её тоже должны мы.
String orderStatusName(int? statusId) {
  switch (statusId) {
    case OrderStatus.created:
      return 'Создано';
    case OrderStatus.accepted:
      return 'Принято';
    case OrderStatus.inProgress:
      return 'В процессе';
    case OrderStatus.done:
      return 'Выполнено';
    case OrderStatus.problem:
      return 'Проблема';
    default:
      return 'Без статуса';
  }
}

/// Внутри секции «сейчас» работы идут тремя группами: сначала аварии, потом
/// остальные заявки, потом ТО. В прочих секциях группа одна, и порядок задаёт
/// только время.
class _Rank {
  static const int urgentOrder = 0;
  static const int order = 1;
  static const int maintenance = 2;
  static const int single = 0;
}

/// Одна работа в списке механика.
class MechanicTask {
  const MechanicTask({
    required this.kind,
    required this.id,
    required this.title,
    required this.subtitle,
    required this.section,
    required this.rank,
    required this.order,
    required this.raw,
    this.badge,
    this.address,
    this.statusId,
    this.urgent = false,
    this.watchingOnly = false,
    this.progress,
  });

  final TaskKind kind;

  /// `id` заявки или `act_id` ТО.
  final int id;

  /// Первая строка карточки — название объекта.
  final String title;

  /// Вторая строка: срок у ТО, дата и категория у заявки.
  final String subtitle;

  /// Адрес объекта.
  final String? address;

  /// Зелёный значок в углу карточки: тип оборудования у заявки, «ТО» у ТО.
  final String? badge;

  final TaskSection section;

  /// Группа внутри секции — см. [_Rank].
  final int rank;

  /// Порядок внутри группы. Меньше — выше.
  final int order;

  /// Статус заявки. У ТО статуса в списке нет — там прогресс по шагам.
  final int? statusId;

  /// Авария: категория поломки помечена `counts_as_breakdown`.
  final bool urgent;

  /// Я не исполнитель, а механик объекта: смотреть можно, отмечать нельзя.
  final bool watchingOnly;

  /// «Сделано N из M» у ТО.
  final String? progress;

  /// Строка из локальной базы целиком — карточке нужны подробности.
  final Map<String, dynamic> raw;

  /// Закрытая заявка: делать больше нечего.
  bool get closed =>
      statusId == OrderStatus.done || statusId == OrderStatus.problem;
}

/// Собирает список работ из двух коллекций локальной базы.
///
/// `userId` нужен, чтобы отличить свою заявку от заявки на моём объекте.
/// `now` передаётся снаружи: тесты не должны зависеть от календаря машины.
List<MechanicTask> buildTaskList({
  required List<Map<String, dynamic>> orders,
  required List<Map<String, dynamic>> maintenance,
  required int userId,
  required DateTime now,
}) {
  final List<MechanicTask> tasks = <MechanicTask>[];

  for (final Map<String, dynamic> row in orders) {
    final MechanicTask? task = taskFromOrder(row, userId: userId);
    if (task != null) tasks.add(task);
  }
  for (final Map<String, dynamic> row in maintenance) {
    final MechanicTask? task = taskFromMaintenance(row, now: now);
    if (task != null) tasks.add(task);
  }

  tasks.sort((MechanicTask a, MechanicTask b) {
    if (a.section != b.section) {
      return a.section.index.compareTo(b.section.index);
    }
    if (a.rank != b.rank) return a.rank.compareTo(b.rank);
    return a.order.compareTo(b.order);
  });
  return tasks;
}

/// Работы одной секции, в готовом порядке.
List<MechanicTask> tasksOf(List<MechanicTask> all, TaskSection section) {
  return all.where((MechanicTask task) => task.section == section).toList();
}

/// Заявка из строки `GET /order/for-me`.
MechanicTask? taskFromOrder(Map<String, dynamic> row, {required int userId}) {
  final int? id = asInt(row['id']);
  if (id == null) return null;

  final Map<String, dynamic> object = asMap(row['object_id']);
  final Map<String, dynamic> category = asMap(row['fault_category_id']);
  final int? statusId = asInt(asMap(row['status_id'])['id']);
  final bool urgent = category['counts_as_breakdown'] == true;
  final int createdAt = asInt(row['created_at']) ?? 0;
  final bool closed =
      statusId == OrderStatus.done || statusId == OrderStatus.problem;

  final TaskSection section;
  if (row['is_actual'] == false) {
    section = TaskSection.archive;
  } else if (closed) {
    section = TaskSection.done;
  } else {
    // Заявка всегда «сейчас»: срока у неё нет, её делают сразу.
    section = TaskSection.now;
  }

  final int rank;
  if (section != TaskSection.now) {
    rank = _Rank.single;
  } else {
    rank = urgent ? _Rank.urgentOrder : _Rank.order;
  }

  final int when = section == TaskSection.done
      ? (asInt(row['done_at']) ?? asInt(row['updated_at']) ?? createdAt)
      : (section == TaskSection.archive
          ? (asInt(row['updated_at']) ?? createdAt)
          : createdAt);

  final String code = asString(category['code']) ?? '';
  final String day = dayText(createdAt);

  return MechanicTask(
    kind: TaskKind.order,
    id: id,
    title: asString(object['name']) ?? 'Объект №${asInt(object['id']) ?? 0}',
    address: asString(object['address']),
    subtitle: code.isEmpty ? 'Заявка от $day' : '$code · заявка от $day',
    badge: _typeOfObject(object),
    section: section,
    rank: rank,
    // Свежее сверху.
    order: -when,
    statusId: statusId,
    urgent: urgent,
    watchingOnly: asInt(asMap(row['executor_id'])['id']) != userId,
    raw: row,
  );
}

/// Плановое ТО из строки `GET /act-fact/for-me`.
MechanicTask? taskFromMaintenance(
  Map<String, dynamic> row, {
  required DateTime now,
}) {
  final int? id = asInt(row['act_id']);
  if (id == null) return null;

  final Map<String, dynamic> object = asMap(row['object']);
  final int year = asInt(row['year']) ?? now.year;
  final int month = asInt(row['month']) ?? now.month;
  final int plan = year * 12 + month;
  final int current = now.year * 12 + now.month;

  final TaskSection section;
  if (row['is_actual'] == false) {
    section = TaskSection.archive;
  } else if (row['finished_at'] != null) {
    section = TaskSection.done;
  } else if (plan > current) {
    section = TaskSection.planned;
  } else {
    section = TaskSection.now;
  }

  final int order;
  if (section == TaskSection.done) {
    order = -(asInt(row['finished_at']) ?? 0);
  } else if (section == TaskSection.archive) {
    order = -(asInt(row['updated_at']) ?? 0);
  } else {
    // Просроченное — выше: чем раньше плановый месяц, тем меньше ключ.
    order = plan;
  }

  final int? total = asInt(row['steps_total']);
  final int? doneSteps = asInt(row['steps_done']);

  return MechanicTask(
    kind: TaskKind.maintenance,
    id: id,
    title: asString(object['name']) ?? 'Объект №${asInt(object['id']) ?? 0}',
    address: asString(object['address']),
    subtitle: 'Срок: ${monthText(year, month)}',
    badge: 'ТО',
    section: section,
    rank: section == TaskSection.now ? _Rank.maintenance : _Rank.single,
    order: order,
    progress: total == null || total == 0
        ? null
        : 'Сделано ${doneSteps ?? 0} из $total',
    raw: row,
  );
}

/// Тип оборудования из объекта заявки — то, что в макете стоит зелёным
/// значком в углу карточки: «Лифт», «Травалатор».
String? _typeOfObject(Map<String, dynamic> object) {
  final Map<String, dynamic> model = asMap(object['factory_model_id']);
  return asString(asMap(model['type_object_id'])['name']);
}

/// «12 мая 2026» из секунд эпохи.
///
/// Время местное, а не UTC: даты заявок бэкенд отдаёт полуночью по UTC, и в
/// нашем поясе (+3) день совпадает, а метки правок читаются так, как их видит
/// человек с часами в руках.
String dayText(int seconds) {
  if (seconds <= 0) return 'неизвестной даты';
  final DateTime at = DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
  return '${at.day} ${kMonthsGenitive[at.month - 1]} ${at.year}';
}

/// «май 2026» — у ТО в графике есть только месяц.
String monthText(int year, int month) {
  if (month < 1 || month > 12) return '$year';
  return '${kMonthsNominative[month - 1].toLowerCase()} $year';
}

/// Разбор присланного: бэкенд отдаёт вложенные объекты, но любое поле может
/// приехать `null`, и падать из-за этого списком нельзя.
Map<String, dynamic> asMap(Object? value) {
  if (value is Map) return value.cast<String, dynamic>();
  return <String, dynamic>{};
}

int? asInt(Object? value) {
  if (value is int) return value;
  if (value is String) return int.tryParse(value);
  return null;
}

String? asString(Object? value) {
  if (value is String && value.trim().isNotEmpty) return value.trim();
  return null;
}
