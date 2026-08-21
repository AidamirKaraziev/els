/// Список работ механика: секции, порядок и пометка «наблюдаю».
///
/// Проверяется то, что решает не вёрстка, а правило: куда попадает заявка,
/// куда ТО, что оказывается наверху и когда механик видит чужую работу.
/// Ошибка здесь означает, что человек не увидит аварию или примет чужую
/// задачу за свою.
library;

import 'package:els/mechanic/data/tasks.dart';
import 'package:flutter_test/flutter_test.dart';

/// «Сейчас» для тестов — середина мая 2026. Календарь машины ни при чём.
final DateTime today = DateTime(2026, 5, 15);

int seconds(DateTime at) => at.millisecondsSinceEpoch ~/ 1000;

Map<String, dynamic> orderRow({
  required int id,
  int executorId = 7,
  int statusId = OrderStatus.created,
  bool urgent = false,
  bool actual = true,
  DateTime? createdAt,
  String objectName = 'Лифт № 30',
  String? typeName = 'Лифт без МП',
  String code = 'ТО',
}) {
  return <String, dynamic>{
    'id': id,
    'object_id': <String, dynamic>{
      'id': 23,
      'name': objectName,
      'address': 'Крылатая улица 2',
      'factory_model_id': <String, dynamic>{
        'type_object_id': <String, dynamic>{'name': typeName},
      },
    },
    'executor_id': <String, dynamic>{'id': executorId},
    'status_id': <String, dynamic>{'id': statusId, 'name': 'Создано'},
    'fault_category_id': <String, dynamic>{
      'code': code,
      'name': 'категория',
      'counts_as_breakdown': urgent,
    },
    'task_text': 'проверить',
    'created_at': seconds(createdAt ?? DateTime(2026, 5, 10)),
    'updated_at': seconds(createdAt ?? DateTime(2026, 5, 10)),
    'is_actual': actual,
  };
}

Map<String, dynamic> maintenanceRow({
  required int actId,
  int year = 2026,
  int month = 5,
  bool actual = true,
  int? finishedAt,
  int? startedAt,
  int? pausedAt,
  int statusId = OrderStatus.created,
  int stepsTotal = 52,
  int stepsDone = 0,
  String? regulation = 'ТО-1',
}) {
  return <String, dynamic>{
    'act_id': actId,
    'object': <String, dynamic>{
      'id': 82,
      'name': 'Создаю Тест',
      'address': 'улица Стасова 182',
    },
    'year': year,
    'month': month,
    'title': regulation,
    'steps_total': stepsTotal,
    'steps_done': stepsDone,
    'finished_at': finishedAt,
    'started_at': startedAt,
    'paused_at': pausedAt,
    'status_id': statusId,
    'updated_at': seconds(DateTime(2026, 5, 1)),
    'is_actual': actual,
  };
}

List<MechanicTask> build({
  List<Map<String, dynamic>> orders = const <Map<String, dynamic>>[],
  List<Map<String, dynamic>> maintenance = const <Map<String, dynamic>>[],
  int userId = 7,
}) {
  return buildTaskList(
    orders: orders,
    maintenance: maintenance,
    userId: userId,
    now: today,
  );
}

void main() {
  group('секции', () {
    test('открытая заявка — в работе сейчас', () {
      final List<MechanicTask> tasks = build(
        orders: <Map<String, dynamic>>[orderRow(id: 1)],
      );

      expect(tasks.single.section, TaskSection.now);
    });

    test('«Выполнено» и «Проблема» уходят в сделанное', () {
      final List<MechanicTask> tasks = build(
        orders: <Map<String, dynamic>>[
          orderRow(id: 1, statusId: OrderStatus.done),
          orderRow(id: 2, statusId: OrderStatus.problem),
        ],
      );

      expect(
        tasks.map((MechanicTask task) => task.section),
        everyElement(TaskSection.done),
      );
    });

    test('удалённая задача уходит в архив, а не исчезает', () {
      final List<MechanicTask> tasks = build(
        orders: <Map<String, dynamic>>[orderRow(id: 1, actual: false)],
        maintenance: <Map<String, dynamic>>[
          maintenanceRow(actId: 9, actual: false),
        ],
      );

      expect(tasks, hasLength(2));
      expect(
        tasks.map((MechanicTask task) => task.section),
        everyElement(TaskSection.archive),
      );
    });

    test('архив сильнее закрытого статуса', () {
      // Удалённую заявку человек ищет в архиве, а не среди сданных работ.
      final List<MechanicTask> tasks = build(
        orders: <Map<String, dynamic>>[
          orderRow(id: 1, statusId: OrderStatus.done, actual: false),
        ],
      );

      expect(tasks.single.section, TaskSection.archive);
    });

    test('несданное ТО любого месяца лежит в своей секции', () {
      // Секции делятся по виду работы: заявки отдельно, график отдельно.
      // Срок внутри секции показывают порядок и пометки.
      final List<MechanicTask> tasks = build(
        maintenance: <Map<String, dynamic>>[
          maintenanceRow(actId: 1, year: 2025, month: 12),
          maintenanceRow(actId: 2, year: 2026, month: 5),
          maintenanceRow(actId: 3, year: 2026, month: 6),
        ],
      );

      expect(
        tasks.map((MechanicTask task) => task.section),
        everyElement(TaskSection.maintenance),
      );
    });

    test('заявка в секцию ТО не попадает', () {
      final List<MechanicTask> tasks = build(
        orders: <Map<String, dynamic>>[orderRow(id: 1)],
        maintenance: <Map<String, dynamic>>[maintenanceRow(actId: 9)],
      );

      final Map<int, TaskSection> byKind = <int, TaskSection>{
        for (final MechanicTask task in tasks) task.id: task.section,
      };
      expect(byKind[1], TaskSection.now);
      expect(byKind[9], TaskSection.maintenance);
    });

    test('просроченное ТО и ТО этого месяца помечены, будущее — нет', () {
      final List<MechanicTask> tasks = build(
        maintenance: <Map<String, dynamic>>[
          maintenanceRow(actId: 1, year: 2025, month: 12),
          maintenanceRow(actId: 2, year: 2026, month: 5),
          maintenanceRow(actId: 3, year: 2026, month: 6),
        ],
      );

      final Map<int, MechanicTask> byId = <int, MechanicTask>{
        for (final MechanicTask task in tasks) task.id: task,
      };
      expect(byId[1]!.overdue, isTrue, reason: 'декабрь прошлого года просрочен');
      expect(byId[1]!.thisMonth, isFalse);
      expect(byId[2]!.overdue, isFalse);
      expect(byId[2]!.thisMonth, isTrue, reason: 'текущий месяц — делать сейчас');
      expect(byId[3]!.overdue, isFalse);
      expect(byId[3]!.thisMonth, isFalse);
    });

    test('просроченное ТО стоит выше будущего', () {
      final List<MechanicTask> tasks = build(
        maintenance: <Map<String, dynamic>>[
          maintenanceRow(actId: 3, year: 2026, month: 6),
          maintenanceRow(actId: 2, year: 2026, month: 5),
          maintenanceRow(actId: 1, year: 2025, month: 12),
        ],
      );

      expect(tasks.map((MechanicTask task) => task.id), <int>[1, 2, 3]);
    });

    test('взятое в работу стоит выше просроченного', () {
      // Недоделанная своя работа важнее чужого срока: механик вернулся с
      // аварийного вызова и ищет то, что бросил.
      final List<MechanicTask> tasks = build(
        maintenance: <Map<String, dynamic>>[
          maintenanceRow(actId: 1, year: 2025, month: 12),
          maintenanceRow(
            actId: 2,
            year: 2026,
            month: 6,
            startedAt: seconds(DateTime(2026, 5, 15, 9)),
            statusId: OrderStatus.inProgress,
          ),
        ],
      );

      expect(tasks.map((MechanicTask task) => task.id), <int>[2, 1]);
    });

    test('приостановленное ТО остаётся наверху вместе с начатым', () {
      final List<MechanicTask> tasks = build(
        maintenance: <Map<String, dynamic>>[
          maintenanceRow(actId: 1, year: 2025, month: 12),
          maintenanceRow(
            actId: 2,
            year: 2026,
            month: 6,
            startedAt: seconds(DateTime(2026, 5, 15, 9)),
            pausedAt: seconds(DateTime(2026, 5, 15, 11)),
            statusId: OrderStatus.accepted,
          ),
          maintenanceRow(
            actId: 3,
            year: 2026,
            month: 6,
            startedAt: seconds(DateTime(2026, 5, 15, 14)),
            statusId: OrderStatus.inProgress,
          ),
        ],
      );

      // За что взялись последним, то и сверху.
      expect(tasks.map((MechanicTask task) => task.id), <int>[3, 2, 1]);
    });

    test('состояние начатой работы попадает в пилюлю', () {
      final List<MechanicTask> tasks = build(
        maintenance: <Map<String, dynamic>>[
          maintenanceRow(
            actId: 1,
            startedAt: seconds(DateTime(2026, 5, 15, 9)),
            pausedAt: seconds(DateTime(2026, 5, 15, 11)),
            statusId: OrderStatus.accepted,
          ),
        ],
      );

      expect(tasks.single.note, 'Приостановлено');
      expect(tasks.single.statusId, OrderStatus.accepted);
    });

    test('статус «Проблема» у ТО не значит, что делать больше нечего', () {
      // У заявки те же номера означают закрытие, и общий геттер `closed`
      // раньше не различал сущности.
      final List<MechanicTask> tasks = build(
        maintenance: <Map<String, dynamic>>[
          maintenanceRow(
            actId: 1,
            startedAt: seconds(DateTime(2026, 5, 15, 9)),
            statusId: OrderStatus.problem,
          ),
        ],
      );

      expect(tasks.single.closed, isFalse);
      expect(tasks.single.section, TaskSection.maintenance);
    });

    test('закрытый акт остаётся сданным при любом статусе', () {
      final List<MechanicTask> tasks = build(
        maintenance: <Map<String, dynamic>>[
          maintenanceRow(
            actId: 1,
            startedAt: seconds(DateTime(2026, 5, 12, 9)),
            finishedAt: seconds(DateTime(2026, 5, 12, 18)),
            statusId: OrderStatus.problem,
          ),
        ],
      );

      expect(tasks.single.section, TaskSection.done);
    });

    test('сданное ТО пометок о сроке не носит', () {
      // Иначе в «Выполнено» половина строк была бы с жёлтым «срок вышел».
      final List<MechanicTask> tasks = build(
        maintenance: <Map<String, dynamic>>[
          maintenanceRow(
            actId: 1,
            year: 2025,
            month: 12,
            finishedAt: seconds(DateTime(2026, 5, 12)),
          ),
        ],
      );

      expect(tasks.single.section, TaskSection.done);
      expect(tasks.single.overdue, isFalse);
      expect(tasks.single.thisMonth, isFalse);
    });

    test('закрытое ТО считается сделанным по дате закрытия, а не по месяцу', () {
      // Так же, как на бэкенде: выполнение считается по `finished_at`.
      final List<MechanicTask> tasks = build(
        maintenance: <Map<String, dynamic>>[
          maintenanceRow(
            actId: 1,
            year: 2026,
            month: 9,
            finishedAt: seconds(DateTime(2026, 5, 12)),
          ),
        ],
      );

      expect(tasks.single.section, TaskSection.done);
    });
  });

  group('порядок', () {
    test('авария стоит выше обычной заявки, даже более свежей', () {
      final List<MechanicTask> tasks = build(
        orders: <Map<String, dynamic>>[
          orderRow(id: 1, createdAt: DateTime(2026, 5, 14)),
          orderRow(id: 2, urgent: true, createdAt: DateTime(2026, 5, 2)),
        ],
      );

      expect(tasks.map((MechanicTask task) => task.id), <int>[2, 1]);
    });

    test('среди равных свежее сверху', () {
      final List<MechanicTask> tasks = build(
        orders: <Map<String, dynamic>>[
          orderRow(id: 1, createdAt: DateTime(2026, 5, 2)),
          orderRow(id: 2, createdAt: DateTime(2026, 5, 9)),
        ],
      );

      expect(tasks.map((MechanicTask task) => task.id), <int>[2, 1]);
    });

    test('заявки идут выше ТО, а просроченное ТО — выше будущего', () {
      final List<MechanicTask> tasks = build(
        orders: <Map<String, dynamic>>[orderRow(id: 1)],
        maintenance: <Map<String, dynamic>>[
          maintenanceRow(actId: 10, year: 2026, month: 5),
          maintenanceRow(actId: 11, year: 2025, month: 11),
        ],
      );

      expect(tasks.map((MechanicTask task) => task.id), <int>[1, 11, 10]);
    });

    test('секции идут в одном порядке: сейчас, ТО, выполнено, архив', () {
      final List<MechanicTask> tasks = build(
        orders: <Map<String, dynamic>>[
          orderRow(id: 1, actual: false),
          orderRow(id: 2, statusId: OrderStatus.done),
          orderRow(id: 3),
        ],
        maintenance: <Map<String, dynamic>>[
          maintenanceRow(actId: 4, year: 2026, month: 8),
        ],
      );

      expect(tasks.map((MechanicTask task) => task.id), <int>[3, 4, 2, 1]);
    });
  });

  group('наблюдаю', () {
    test('чужая заявка на моём объекте помечена', () {
      // Список отдаёт её и исполнителю, и механику объекта. Отмечать за
      // другого нельзя — сервер тоже не даст.
      final List<MechanicTask> tasks = build(
        orders: <Map<String, dynamic>>[orderRow(id: 1, executorId: 99)],
      );

      expect(tasks.single.watchingOnly, isTrue);
    });

    test('своя заявка не помечена', () {
      final List<MechanicTask> tasks = build(
        orders: <Map<String, dynamic>>[orderRow(id: 1, executorId: 7)],
      );

      expect(tasks.single.watchingOnly, isFalse);
    });
  });

  group('карточка', () {
    test('заявка: объект, адрес, код с датой и тип оборудования', () {
      final MechanicTask task = build(
        orders: <Map<String, dynamic>>[
          orderRow(
            id: 1,
            code: 'AA',
            statusId: OrderStatus.inProgress,
            createdAt: DateTime(2026, 5, 12),
          ),
        ],
      ).single;

      expect(task.title, 'Лифт № 30');
      expect(task.address, 'Крылатая улица 2');
      expect(task.note, 'В работе');
      expect(task.meta, 'AA · от 12 мая');
      expect(task.badge, 'Лифт без МП');
    });

    test('заявка без категории обходится без разделителя', () {
      final MechanicTask task = build(
        orders: <Map<String, dynamic>>[
          orderRow(id: 1, code: '', createdAt: DateTime(2026, 5, 12)),
        ],
      ).single;

      expect(task.meta, 'от 12 мая');
    });

    test('заявка не этого года подписана годом', () {
      final MechanicTask task = build(
        orders: <Map<String, dynamic>>[
          orderRow(id: 1, code: 'AA', createdAt: DateTime(2025, 12, 3)),
        ],
      ).single;

      expect(task.meta, 'AA · от 3 декабря 2025');
    });

    test('заведённая, но не принятая заявка обходится без пилюли', () {
      final MechanicTask task = build(
        orders: <Map<String, dynamic>>[
          orderRow(id: 1, statusId: OrderStatus.created),
        ],
      ).single;

      expect(task.note, isNull);
    });

    test('ТО: регламент в значке, срок и прогресс в хвосте', () {
      final MechanicTask task = build(
        maintenance: <Map<String, dynamic>>[
          maintenanceRow(actId: 1, year: 2026, month: 5, stepsDone: 3),
        ],
      ).single;

      expect(task.badge, 'ТО-1');
      expect(task.address, 'улица Стасова 182');
      expect(task.note, 'Этот месяц');
      expect(task.meta, 'до 31 мая · 3 из 52');
    });

    test('ТО без названия регламента остаётся с общим значком', () {
      // Поле необязательное: чек-лист могли завести без названия.
      final MechanicTask task = build(
        maintenance: <Map<String, dynamic>>[
          maintenanceRow(actId: 1, regulation: '  '),
        ],
      ).single;

      expect(task.badge, 'ТО');
    });

    test('спокойное будущее ТО обходится без пилюли', () {
      final MechanicTask task = build(
        maintenance: <Map<String, dynamic>>[
          maintenanceRow(actId: 1, year: 2026, month: 9),
        ],
      ).single;

      expect(task.note, isNull);
      expect(task.meta, 'до 30 сентября · 0 из 52');
    });

    test('просроченное ТО прошлого года подписано годом', () {
      final MechanicTask task = build(
        maintenance: <Map<String, dynamic>>[
          maintenanceRow(actId: 1, year: 2025, month: 12),
        ],
      ).single;

      expect(task.note, 'Срок вышел');
      expect(task.meta, 'до 31 декабря 2025 · 0 из 52');
    });

    test('ТО без пунктов показывает один срок', () {
      final MechanicTask task = build(
        maintenance: <Map<String, dynamic>>[
          maintenanceRow(actId: 1, stepsTotal: 0),
        ],
      ).single;

      expect(task.meta, 'до 31 мая');
    });

    test('открытая авария считает время ожидания', () {
      // В лифте может стоять человек: строка показывает, сколько он там уже.
      final DateTime at = DateTime(2026, 5, 15, 9);
      final MechanicTask task = build(
        orders: <Map<String, dynamic>>[
          orderRow(
            id: 1,
            urgent: true,
            statusId: OrderStatus.accepted,
            createdAt: at,
          ),
        ],
      ).single;

      expect(task.waitingSince, seconds(at));
    });

    test('обычная заявка времени не считает', () {
      final MechanicTask task = build(
        orders: <Map<String, dynamic>>[
          orderRow(id: 1, statusId: OrderStatus.accepted),
        ],
      ).single;

      expect(task.waitingSince, isNull);
    });

    test('закрытая авария времени не считает', () {
      final MechanicTask task = build(
        orders: <Map<String, dynamic>>[
          orderRow(id: 1, urgent: true, statusId: OrderStatus.done),
        ],
      ).single;

      expect(task.waitingSince, isNull);
    });

    test('строка без идентификатора не роняет список', () {
      final List<MechanicTask> tasks = build(
        orders: <Map<String, dynamic>>[
          <String, dynamic>{'task_text': 'мусор'},
          orderRow(id: 1),
        ],
      );

      expect(tasks, hasLength(1));
    });

    test('пустой объект не оставляет карточку без названия', () {
      final List<MechanicTask> tasks = build(
        orders: <Map<String, dynamic>>[
          <String, dynamic>{'id': 5, 'object_id': null},
        ],
      );

      expect(tasks.single.title, 'Объект №0');
      expect(tasks.single.badge, isNull);
    });
  });

  group('сроки и время словами', () {
    test('срок ТО — последний день планового месяца', () {
      expect(deadlineText(2026, 2, now: today), 'до 28 февраля');
      expect(deadlineText(2024, 2, now: today), 'до 29 февраля 2024');
    });

    test('пустой год в графике не выдаёт выдуманный срок', () {
      // Год в графике строковый и набит руками: нечисловой приезжает нулём.
      expect(deadlineText(0, 5, now: today), 'срок не задан');
      expect(deadlineText(2026, 0, now: today), 'срок не задан');
    });

    test('сколько человек уже ждёт', () {
      String waited(Duration ago) =>
          waitedText(seconds(today.subtract(ago)), now: today);

      expect(waited(const Duration(seconds: 30)), 'только что');
      expect(waited(const Duration(minutes: 14)), '14 мин');
      expect(waited(const Duration(hours: 2, minutes: 40)), '2 ч 40 мин');
      expect(waited(const Duration(hours: 3)), '3 ч');
      expect(waited(const Duration(hours: 26)), '1 дн 2 ч');
      expect(waited(const Duration(days: 2)), '2 дн');
    });

    test('часы телефона впереди серверных — не отрицательное время', () {
      expect(
        waitedText(seconds(today.add(const Duration(minutes: 5))), now: today),
        'только что',
      );
    });
  });
}
