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
  int stepsTotal = 52,
  int stepsDone = 0,
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
    'title': 'ТО $month',
    'steps_total': stepsTotal,
    'steps_done': stepsDone,
    'finished_at': finishedAt,
    'status_id': 1,
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

    test('ТО текущего и прошедших месяцев — сейчас, будущих — планируется', () {
      final List<MechanicTask> tasks = build(
        maintenance: <Map<String, dynamic>>[
          maintenanceRow(actId: 1, year: 2025, month: 12),
          maintenanceRow(actId: 2, year: 2026, month: 5),
          maintenanceRow(actId: 3, year: 2026, month: 6),
        ],
      );

      Map<int, TaskSection> byId = <int, TaskSection>{
        for (final MechanicTask task in tasks) task.id: task.section,
      };
      expect(byId[1], TaskSection.now, reason: 'декабрь прошлого года просрочен');
      expect(byId[2], TaskSection.now, reason: 'текущий месяц — делать сейчас');
      expect(byId[3], TaskSection.planned);
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

    test('заявки идут выше ТО, а просроченное ТО — выше свежего', () {
      final List<MechanicTask> tasks = build(
        orders: <Map<String, dynamic>>[orderRow(id: 1)],
        maintenance: <Map<String, dynamic>>[
          maintenanceRow(actId: 10, year: 2026, month: 5),
          maintenanceRow(actId: 11, year: 2025, month: 11),
        ],
      );

      expect(tasks.map((MechanicTask task) => task.id), <int>[1, 11, 10]);
    });

    test('секции идут в одном порядке: сейчас, планируется, сделано, архив', () {
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
    test('заявка: название объекта, категория с датой, тип оборудования', () {
      final MechanicTask task = build(
        orders: <Map<String, dynamic>>[
          orderRow(id: 1, code: 'AA', createdAt: DateTime(2026, 5, 12)),
        ],
      ).single;

      expect(task.title, 'Лифт № 30');
      expect(task.subtitle, 'AA · заявка от 12 мая 2026');
      expect(task.badge, 'Лифт без МП');
      expect(task.address, 'Крылатая улица 2');
    });

    test('заявка без категории обходится без разделителя', () {
      final MechanicTask task = build(
        orders: <Map<String, dynamic>>[
          orderRow(id: 1, code: '', createdAt: DateTime(2026, 5, 12)),
        ],
      ).single;

      expect(task.subtitle, 'Заявка от 12 мая 2026');
    });

    test('ТО: срок месяцем и прогресс по шагам', () {
      final MechanicTask task = build(
        maintenance: <Map<String, dynamic>>[
          maintenanceRow(actId: 1, year: 2026, month: 5, stepsDone: 3),
        ],
      ).single;

      expect(task.subtitle, 'Срок: май 2026');
      expect(task.progress, 'Сделано 3 из 52');
      expect(task.badge, 'ТО');
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
}
