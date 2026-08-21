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
///
/// Секции делят работу **по виду**, а не по сроку: механик ищет глазами «что
/// у меня по заявкам» и «что по графику», а не «что в этом месяце». Срок
/// внутри секции показывает порядок и метка: просроченное ТО стоит первым и
/// подписано, а не уезжает в другой раздел.
enum TaskSection {
  /// Заявки диспетчера, которые ещё делать. Аварии сверху.
  now,

  /// Плановые ТО, которые ещё не сданы: просроченные, этого месяца, будущие.
  maintenance,

  /// Выполнено: заявка «Выполнено» или «Проблема», ТО с датой закрытия.
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

/// Состояние работы по ТО — тот же справочник `statuses`, что и у заявки.
///
/// «Приостановлено» отдельным номером в справочнике нет и заводить его мы не
/// стали: пауза — это «Принято» при уже начатой работе, и отличает её от
/// невзятого ТО заполненный `started_at`. Разбирает это [maintenanceState].
enum MaintenanceState {
  /// Механик за ТО ещё не брался.
  notStarted,

  /// Работа идёт прямо сейчас.
  inWork,

  /// Механик начал и приостановил: аварийный вызов, нет запчасти.
  paused,

  /// Работа встала, и прораб должен разобраться почему.
  problem,

  /// Работа завершена, акт закрыт.
  done,
}

/// Состояние работы по строке списка ТО.
///
/// Порядок проверок важен: закрытый акт остаётся закрытым, каким бы ни был
/// статус, а неначатое ТО не бывает ни на паузе, ни в проблеме — статус у
/// таких строк по умолчанию «Создано», и читать его как состояние работы
/// значило бы придумать работу там, где её не было.
MaintenanceState maintenanceState(Map<String, dynamic> row) {
  if (row['finished_at'] != null) return MaintenanceState.done;
  if (row['started_at'] == null) return MaintenanceState.notStarted;

  switch (asInt(row['status_id'])) {
    case OrderStatus.problem:
      return MaintenanceState.problem;
    case OrderStatus.accepted:
      return MaintenanceState.paused;
    default:
      return MaintenanceState.inWork;
  }
}

/// Что делает главная — единственная зелёная — кнопка карточки ТО.
enum ActAction {
  /// Механик берётся за работу впервые.
  start,

  /// Работа идёт, кнопка просто открывает чек-лист.
  open,

  /// Возвращение к приостановленной или вставшей работе.
  resume,

  /// Все пункты отмечены, остаётся закрыть акт.
  close,

  /// Работа завершена — нажимать нечего.
  none,
}

/// Кнопки карточки ТО в этом состоянии работы.
///
/// Отдельно от экрана, потому что это правило, а не вёрстка: именно оно
/// решает, увидит ли механик «Завершить работу» вместо «Продолжить ТО» и
/// можно ли из этого состояния приостановиться.
class ActControls {
  const ActControls({
    required this.main,
    required this.canPause,
    required this.canReportProblem,
  });

  final ActAction main;

  /// Приостановить можно только идущую работу: приостановленная уже стоит, а
  /// за неначатую механик ещё не брался.
  final bool canPause;

  /// Сообщить о проблеме можно из любой начатой работы. До начала — нет:
  /// проблема мешает делать, а делать ещё не начинали.
  final bool canReportProblem;

  /// Подпись главной кнопки.
  String get mainLabel {
    switch (main) {
      case ActAction.start:
        return 'Начать ТО';
      case ActAction.close:
        return 'Завершить работу';
      case ActAction.open:
      case ActAction.resume:
        return 'Продолжить ТО';
      case ActAction.none:
        return '';
    }
  }
}

/// Разбирает состояние работы в набор кнопок.
ActControls actControls(MaintenanceState state, {required bool allDone}) {
  switch (state) {
    case MaintenanceState.notStarted:
      return const ActControls(
        main: ActAction.start,
        canPause: false,
        canReportProblem: false,
      );
    case MaintenanceState.inWork:
      return ActControls(
        main: allDone ? ActAction.close : ActAction.open,
        canPause: true,
        canReportProblem: true,
      );
    case MaintenanceState.paused:
      return const ActControls(
        main: ActAction.resume,
        canPause: false,
        canReportProblem: true,
      );
    case MaintenanceState.problem:
      return const ActControls(
        main: ActAction.resume,
        canPause: false,
        canReportProblem: false,
      );
    case MaintenanceState.done:
      return const ActControls(
        main: ActAction.none,
        canPause: false,
        canReportProblem: false,
      );
  }
}

/// Состояние работы словами — одинаково в списке и в карточке ТО.
String maintenanceStateName(MaintenanceState state) {
  switch (state) {
    case MaintenanceState.notStarted:
      return 'Не начато';
    case MaintenanceState.inWork:
      return 'В работе';
    case MaintenanceState.paused:
      return 'Приостановлено';
    case MaintenanceState.problem:
      return 'Проблема';
    case MaintenanceState.done:
      return 'Завершено';
  }
}

/// Группы внутри секции. В заявках сверху аварии, в ТО — взятое в работу,
/// потом просроченное и текущий месяц; в прочих секциях группа одна, и
/// порядок задаёт только время.
class _Rank {
  static const int urgentOrder = 0;
  static const int order = 1;
  static const int startedMaintenance = 0;
  static const int overdueMaintenance = 1;
  static const int currentMaintenance = 2;
  static const int futureMaintenance = 3;
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
    this.overdue = false,
    this.thisMonth = false,
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

  /// ТО, чей плановый месяц уже прошёл. Раньше такое ТО уезжало в секцию
  /// «сейчас» и там терялось среди заявок; теперь оно стоит первым в своей
  /// секции и подписано словами.
  final bool overdue;

  /// ТО текущего месяца: срок ещё не вышел, но делать его уже пора.
  final bool thisMonth;

  /// Строка из локальной базы целиком — карточке нужны подробности.
  final Map<String, dynamic> raw;

  /// Закрытая заявка: делать больше нечего.
  ///
  /// Только заявка: у ТО те же номера статусов значат другое — «Проблема»
  /// означает вставшую работу, которую ещё доделывать, а закрытость ТО видна
  /// по `finished_at`.
  bool get closed =>
      kind == TaskKind.order &&
      (statusId == OrderStatus.done || statusId == OrderStatus.problem);
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

  final bool overdue = plan < current;
  final bool thisMonth = plan == current;

  final TaskSection section;
  if (row['is_actual'] == false) {
    section = TaskSection.archive;
  } else if (row['finished_at'] != null) {
    section = TaskSection.done;
  } else {
    // Несданное ТО любого месяца — в свою секцию: просроченное сверху.
    section = TaskSection.maintenance;
  }

  final MaintenanceState state = maintenanceState(row);
  final bool started = state != MaintenanceState.notStarted &&
      state != MaintenanceState.done;

  final int order;
  if (section == TaskSection.done) {
    order = -(asInt(row['finished_at']) ?? 0);
  } else if (section == TaskSection.archive) {
    order = -(asInt(row['updated_at']) ?? 0);
  } else if (started) {
    // За что взялись последним, то и сверху: механик вернулся с аварийного
    // вызова и ищет ту работу, которую бросил, а не самую старую из начатых.
    order = -(asInt(row['started_at']) ?? 0);
  } else {
    // Чем раньше плановый месяц, тем выше строка.
    order = plan;
  }

  final int rank;
  if (section != TaskSection.maintenance) {
    rank = _Rank.single;
  } else if (started) {
    // Взятое в работу — включая приостановленное — стоит выше просроченного:
    // недоделанная своя работа важнее чужого срока.
    rank = _Rank.startedMaintenance;
  } else if (overdue) {
    rank = _Rank.overdueMaintenance;
  } else if (thisMonth) {
    rank = _Rank.currentMaintenance;
  } else {
    rank = _Rank.futureMaintenance;
  }

  final int? total = asInt(row['steps_total']);
  final int? doneSteps = asInt(row['steps_done']);

  return MechanicTask(
    kind: TaskKind.maintenance,
    id: id,
    title: asString(object['name']) ?? 'Объект №${asInt(object['id']) ?? 0}',
    address: asString(object['address']),
    // Взятое в работу подписано состоянием, а не сроком: оно стоит первым в
    // списке, и человек должен видеть, почему именно оно там, — особенно
    // приостановленное, которое иначе не отличить от идущего.
    subtitle: started
        ? maintenanceStateName(state)
        : 'Срок: ${monthText(year, month)}',
    badge: 'ТО',
    section: section,
    rank: rank,
    order: order,
    // Статус ТО карточке нужен, чтобы открыться в правильном состоянии без
    // связи: в списке он ни на что не влияет, там прогресс по шагам.
    statusId: asInt(row['status_id']),
    progress: total == null || total == 0
        ? null
        : 'Сделано ${doneSteps ?? 0} из $total',
    overdue: overdue && section == TaskSection.maintenance,
    thisMonth: thisMonth && section == TaskSection.maintenance,
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

/// «21 августа, 15:20» — там, где час важен не меньше дня.
///
/// Пауза бывает на полчаса, и «работа стоит с 21 августа» на такое не
/// отвечает: механик отошёл после обеда и вернулся к вечеру, и разницу видно
/// только по часам.
String dayTimeText(int seconds) {
  if (seconds <= 0) return 'неизвестного времени';
  final DateTime at = DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
  final String minute = at.minute.toString().padLeft(2, '0');
  return '${at.day} ${kMonthsGenitive[at.month - 1]}, ${at.hour}:$minute';
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
