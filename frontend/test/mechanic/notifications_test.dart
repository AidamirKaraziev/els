/// Уведомления механика: разница между «было» и «приехало».
///
/// Таблицы уведомлений на бэкенде нет, весь список считает телефон. Проверять
/// это глазами нельзя: чтобы увидеть событие, нужны два состояния одной
/// записи и синхронизация между ними.
library;

import 'package:els/mechanic/data/local_store.dart';
import 'package:els/mechanic/data/notifications.dart';
import 'package:els/mechanic/data/tasks.dart';
import 'package:flutter_test/flutter_test.dart';

const int mark = 1_700_000_000;

Map<String, dynamic> order({
  required int id,
  int statusId = OrderStatus.created,
  String statusName = 'Создано',
  bool actual = true,
  int updatedAt = mark,
  String object = 'Лифт № 30',
  String code = 'AA',
}) {
  return <String, dynamic>{
    'id': id,
    'object_id': <String, dynamic>{'id': 23, 'name': object},
    'status_id': <String, dynamic>{'id': statusId, 'name': statusName},
    'fault_category_id': <String, dynamic>{'code': code},
    'updated_at': updatedAt,
    'is_actual': actual,
  };
}

Map<String, dynamic> maintenance({
  required int actId,
  int stepsDone = 0,
  int stepsTotal = 52,
  int? finishedAt,
  bool actual = true,
  int updatedAt = mark,
  int year = 2026,
  int month = 5,
}) {
  return <String, dynamic>{
    'act_id': actId,
    'object': <String, dynamic>{'id': 82, 'name': 'Создаю Тест'},
    'year': year,
    'month': month,
    'steps_done': stepsDone,
    'steps_total': stepsTotal,
    'finished_at': finishedAt,
    'updated_at': updatedAt,
    'is_actual': actual,
  };
}

List<MechanicEvent> events({
  List<Map<String, dynamic>> stored = const <Map<String, dynamic>>[],
  List<Map<String, dynamic>> incoming = const <Map<String, dynamic>>[],
  TaskKind kind = TaskKind.order,
  Set<String> myChanges = const <String>{},
  Set<String>? matched,
}) {
  return eventsFromSync(
    stored: stored,
    incoming: incoming,
    kind: kind,
    nowMs: mark * 1000,
    myChanges: myChanges,
    matchedMyChanges: matched,
  );
}

void main() {
  group('события синхронизации', () {
    test('новая заявка — уведомление с объектом и категорией', () {
      final List<MechanicEvent> got = events(
        incoming: <Map<String, dynamic>>[order(id: 1)],
      );

      expect(got.single.kind, MechanicEventKind.assigned);
      expect(got.single.title, 'Новая заявка');
      expect(got.single.subtitle, 'Лифт № 30 · AA');
      expect(got.single.taskId, 1);
    });

    test('смена статуса чужой рукой — уведомление', () {
      final List<MechanicEvent> got = events(
        stored: <Map<String, dynamic>>[order(id: 1)],
        incoming: <Map<String, dynamic>>[
          order(id: 1, statusId: OrderStatus.inProgress, statusName: 'В процессе'),
        ],
      );

      expect(got.single.kind, MechanicEventKind.statusChanged);
      expect(got.single.subtitle, 'Лифт № 30 · В процессе');
    });

    test('своя отметка, приехавшая обратно, уведомления не даёт', () {
      // Человек только что нажал кнопку. Сообщать ему о его же действии —
      // шум, из-за которого перестают читать и настоящие уведомления.
      final Set<String> matched = <String>{};
      final List<MechanicEvent> got = events(
        stored: <Map<String, dynamic>>[order(id: 1)],
        incoming: <Map<String, dynamic>>[
          order(id: 1, statusId: OrderStatus.inProgress),
        ],
        myChanges: <String>{
          changeKey(TaskKind.order, 1, OrderStatus.inProgress),
        },
        matched: matched,
      );

      expect(got, isEmpty);
      expect(matched, hasLength(1), reason: 'отметку можно забыть — она отработала');
    });

    test('чужая правка после моей всё равно доходит', () {
      // Я отметил «в работу», а кто-то закрыл заявку: помнить надо только про
      // своё состояние, а не про запись целиком.
      final List<MechanicEvent> got = events(
        stored: <Map<String, dynamic>>[order(id: 1)],
        incoming: <Map<String, dynamic>>[
          order(id: 1, statusId: OrderStatus.done, statusName: 'Выполнено'),
        ],
        myChanges: <String>{
          changeKey(TaskKind.order, 1, OrderStatus.inProgress),
        },
      );

      expect(got.single.subtitle, 'Лифт № 30 · Выполнено');
    });

    test('удаление задачи, которая у меня была, сообщается', () {
      final List<MechanicEvent> got = events(
        stored: <Map<String, dynamic>>[order(id: 1)],
        incoming: <Map<String, dynamic>>[order(id: 1, actual: false)],
      );

      expect(got.single.kind, MechanicEventKind.removed);
      expect(got.single.title, 'Заявку сняли');
    });

    test('удаление записи, которой человек не видел, молчит', () {
      final List<MechanicEvent> got = events(
        incoming: <Map<String, dynamic>>[order(id: 7, actual: false)],
      );

      expect(got, isEmpty);
    });

    test('без изменений — без уведомлений', () {
      final List<MechanicEvent> got = events(
        stored: <Map<String, dynamic>>[order(id: 1)],
        incoming: <Map<String, dynamic>>[order(id: 1)],
      );

      expect(got, isEmpty);
    });

    test('у ТО событие даёт прогресс по шагам и закрытие', () {
      final List<MechanicEvent> moved = events(
        kind: TaskKind.maintenance,
        stored: <Map<String, dynamic>>[maintenance(actId: 1)],
        incoming: <Map<String, dynamic>>[maintenance(actId: 1, stepsDone: 4)],
      );
      final List<MechanicEvent> closed = events(
        kind: TaskKind.maintenance,
        stored: <Map<String, dynamic>>[maintenance(actId: 1)],
        incoming: <Map<String, dynamic>>[
          maintenance(actId: 1, finishedAt: mark),
        ],
      );

      expect(moved.single.subtitle, 'Создаю Тест · сделано 4 из 52');
      expect(closed.single.subtitle, 'Создаю Тест · ТО закрыто');
    });

    test('новое ТО сообщает срок месяцем', () {
      final List<MechanicEvent> got = events(
        kind: TaskKind.maintenance,
        incoming: <Map<String, dynamic>>[
          maintenance(actId: 1, year: 2026, month: 9),
        ],
      );

      expect(got.single.title, 'Новое ТО');
      expect(got.single.subtitle, 'Создаю Тест · срок сентябрь 2026');
    });
  });

  group('журнал', () {
    late NotificationJournal journal;

    setUp(() {
      journal = NotificationJournal(
        store: LocalStore(userId: 7, store: MemoryStore()),
        keep: 3,
      );
    });

    test('события ложатся свежими сверху и считаются непрочитанными', () async {
      await journal.add(<MechanicEvent>[
        const MechanicEvent(
          id: 'a',
          kind: MechanicEventKind.assigned,
          title: 'старое',
          subtitle: '',
          at: 1000,
        ),
        const MechanicEvent(
          id: 'b',
          kind: MechanicEventKind.assigned,
          title: 'свежее',
          subtitle: '',
          at: 2000,
        ),
      ]);

      final List<MechanicEvent> all = await journal.all();
      expect(all.map((MechanicEvent event) => event.title), <String>[
        'свежее',
        'старое',
      ]);
      expect(await journal.unread(), 2);
    });

    test('то же событие второй раз список не удваивает', () async {
      const MechanicEvent event = MechanicEvent(
        id: 'assigned:order:1',
        kind: MechanicEventKind.assigned,
        title: 'Новая заявка',
        subtitle: '',
        at: 1000,
      );

      await journal.add(<MechanicEvent>[event]);
      await journal.add(<MechanicEvent>[event]);

      expect(await journal.all(), hasLength(1));
    });

    test('журнал ограничен и хранит самое свежее', () async {
      await journal.add(<MechanicEvent>[
        for (int i = 1; i <= 5; i++)
          MechanicEvent(
            id: '$i',
            kind: MechanicEventKind.assigned,
            title: '$i',
            subtitle: '',
            at: i * 1000,
          ),
      ]);

      final List<MechanicEvent> all = await journal.all();
      expect(all.map((MechanicEvent event) => event.title), <String>['5', '4', '3']);
    });

    test('открытая вкладка гасит счётчик', () async {
      await journal.add(<MechanicEvent>[
        const MechanicEvent(
          id: 'a',
          kind: MechanicEventKind.removed,
          title: 'снята',
          subtitle: '',
          at: 1000,
        ),
      ]);

      await journal.markAllRead();

      expect(await journal.unread(), 0);
      expect(await journal.all(), hasLength(1), reason: 'список остаётся');
    });

    test('отметки о своих правках забываются после того, как отработали',
        () async {
      await journal.rememberMyChange('order:1:3');
      await journal.rememberMyChange('order:2:4');

      expect(await journal.myChanges(), <String>{'order:1:3', 'order:2:4'});

      await journal.forgetMyChanges(<String>{'order:1:3'});

      expect(await journal.myChanges(), <String>{'order:2:4'});
    });

    test('отказ сервера попадает в журнал вместе с причиной', () async {
      await journal.add(<MechanicEvent>[
        rejectedEvent(
          actionId: '17-0',
          actionTitle: 'Заявка №14 — в работу',
          error: 'Вам отказано в доступе',
          nowMs: 5000,
        ),
      ]);

      final MechanicEvent event = (await journal.all()).single;
      expect(event.kind, MechanicEventKind.rejected);
      expect(event.subtitle, 'Заявка №14 — в работу · Вам отказано в доступе');
    });

    test('данные журнала не переезжают к следующему человеку', () async {
      final MemoryStore shared = MemoryStore();
      final NotificationJournal mine = NotificationJournal(
        store: LocalStore(userId: 7, store: shared),
      );
      final NotificationJournal other = NotificationJournal(
        store: LocalStore(userId: 8, store: shared),
      );

      await mine.add(<MechanicEvent>[
        const MechanicEvent(
          id: 'a',
          kind: MechanicEventKind.assigned,
          title: 'моё',
          subtitle: '',
          at: 1000,
        ),
      ]);

      expect(await other.all(), isEmpty);
    });
  });
}
