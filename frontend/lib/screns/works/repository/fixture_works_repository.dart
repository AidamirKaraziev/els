import '../models/work_counts.dart';
import '../models/work_employee.dart';
import '../models/work_filters.dart';
import '../models/work_item.dart';
import '../models/work_order.dart';
import '../models/work_section.dart';
import 'works_repository.dart';

/// Лента «Работы» в памяти — для тестов экрана и точки `dev/works_preview.dart`.
///
/// Лежит в `lib/`, а не в `test/`, по той же причине, что и фикстура
/// графиков: набросок показывают в браузере без сервера. В прод-сборку не
/// попадает — из `main.dart` на неё ссылок нет.
///
/// Даты отсчитаны от «сейчас», а не зашиты: таймеры в строках живые, и
/// фикстура на прошлую неделю показывала бы «ждёт 6 д» у каждой новой.
/// Набор собран так, чтобы в нём был каждый статус и каждый вид, паузы,
/// затянувшиеся стадии, дефекты и комментарии, заявки без исполнителя и
/// четыре строки в архиве: на одном экране должно быть видно всё, что
/// умеет рисовать лента.
class FixtureWorksRepository implements WorksRepository {
  FixtureWorksRepository({this.delay = const Duration(milliseconds: 350)})
    : _items = List<WorkItem>.of(items);

  /// Без задержки не видно загрузки, и экран нельзя проверить глазами.
  final Duration delay;

  static final List<WorkItem> items = _build(DateTime.now());

  /// Участки с id, как на бэке: отбор идёт по числу, выпадашка — по слову.
  static const List<WorkSection> sections = <WorkSection>[
    WorkSection(id: 1, title: 'Центр'),
    WorkSection(id: 2, title: 'Север'),
    WorkSection(id: 3, title: 'Юг'),
  ];

  /// Участки прораба из превью. Два из трёх — чтобы чипс «Мои участки»
  /// что-то убирал.
  static const Set<int> mySections = <int>{1, 2};

  /// Кого можно назначить. Есть и не-механики: диалог должен показать, что
  /// должность видна, а не только имя.
  static const List<WorkEmployee> employees = <WorkEmployee>[
    WorkEmployee(
      id: 11,
      name: 'Иванов А. С.',
      specialty: 'Механик',
      sectionId: 1,
      section: 'Центр',
      phone: '+7 900 100-00-11',
    ),
    WorkEmployee(
      id: 12,
      name: 'Петров В. И.',
      specialty: 'Механик',
      sectionId: 2,
      section: 'Север',
      phone: '+7 900 100-00-12',
    ),
    WorkEmployee(
      id: 13,
      name: 'Сидоров К. П.',
      specialty: 'Инженер-наладчик',
      sectionId: 1,
      section: 'Центр',
      phone: '+7 900 100-00-13',
    ),
    WorkEmployee(
      id: 14,
      name: 'Кузнецов Д. М.',
      specialty: 'Механик',
      sectionId: 3,
      section: 'Юг',
      phone: '+7 900 100-00-14',
    ),
    WorkEmployee(
      id: 15,
      name: 'Орлова Н. В.',
      specialty: 'Диспетчер',
      sectionId: 3,
      section: 'Юг',
    ),
  ];

  /// Своя копия: «назначить» и «проверил» меняют строки, а [items] читают
  /// тесты как эталон.
  final List<WorkItem> _items;

  /// Когда строку трогали здесь — под [changes]: «проверил» дат стадий не
  /// меняет, а перемена это всё равно.
  final Map<String, DateTime> _touchedAt = <String, DateTime>{};

  /// Новая строка сверху — для превью формы «Новая работа»: созданное
  /// должно появиться в ленте, иначе набросок не показывает результат.
  void add(WorkItem item) {
    _items.insert(0, item);
    _touchedAt[item.key] = DateTime.now();
  }

  @override
  Future<WorksFeed> fetch(
    WorkFilters filters, {
    String? cursor,
    int? limit,
  }) async {
    await Future<void>.delayed(delay);
    final DateTime now = DateTime.now();

    final WorkOrder order = WorkOrder.arrange(
      _items.where(
        (WorkItem i) => filters.matches(i, now: now, mySections: mySections),
      ),
      filters.sort,
      now,
    );

    return WorksFeed(
      items: limit == null ? order.items : order.items.take(limit).toList(),
      counts: WorkCounts.count(
        _items,
        filters,
        now: now,
        mySections: mySections,
      ),
      attentionCount: order.attentionCount,
      sections: sections,
      employees: employees,
      mySections: mySections,
    );
  }

  @override
  Future<List<WorkItem>> changes(WorkFilters filters, DateTime since) async {
    await Future<void>.delayed(delay);
    final DateTime now = DateTime.now();
    final WorkFilters wide = filters.wide();
    return _items
        .where(
          (WorkItem i) => (_touchedAt[i.key] ?? i.updatedAt).isAfter(since),
        )
        .where(
          (WorkItem i) =>
              !i.isActual || wide.matches(i, now: now, mySections: mySections),
        )
        .toList();
  }

  @override
  Future<WorkItem> assign(WorkItem item, WorkEmployee who) async {
    await Future<void>.delayed(delay);
    return _replace(
      item.copyWith(
        performerId: who.id,
        performer: who.name,
        performerPhone: who.phone,
        status: item.status == WorkStatus.fresh
            ? WorkStatus.accepted
            : item.status,
        acceptedAt: item.status == WorkStatus.fresh ? DateTime.now() : null,
        reviewed: false,
      ),
    );
  }

  @override
  Future<WorkItem> review(WorkItem item) async {
    await Future<void>.delayed(delay);
    return _replace(item.copyWith(reviewed: true));
  }

  @override
  Future<int> unreviewedCount() async {
    await Future<void>.delayed(delay);
    return _items
        .where((WorkItem i) => i.status == WorkStatus.submitted && !i.reviewed)
        .length;
  }

  WorkItem _replace(WorkItem fresh) {
    final int at = _items.indexWhere((WorkItem i) => i.key == fresh.key);
    if (at >= 0) _items[at] = fresh;
    _touchedAt[fresh.key] = DateTime.now();
    return fresh;
  }

  /// Участок — по улице: в фикстуре объектов девять, и таблицы хватает.
  static WorkSection _sectionOf(String? address) {
    final String a = address ?? '';
    if (a.contains('Ленина') || a.contains('Мира') || a.contains('Морская')) {
      return sections[0];
    }
    if (a.contains('Полярная') || a.contains('Обводного')) return sections[1];
    return sections[2];
  }

  static List<WorkItem> _build(DateTime now) {
    DateTime ago(double hours) =>
        now.subtract(Duration(minutes: (hours * 60).round()));

    return _raw(ago).map((WorkItem i) {
      final WorkSection section = _sectionOf(i.objectAddress);
      final WorkEmployee? who = i.performer == null
          ? null
          : employees.firstWhere((WorkEmployee e) => e.name == i.performer);
      return i.copyWith(
        sectionId: section.id,
        section: section.title,
        performerId: who?.id,
        performerPhone: who?.phone,
      );
    }).toList();
  }

  static List<WorkItem> _raw(DateTime Function(double hours) ago) {
    return <WorkItem>[
      // Новые: заявки, которые никто не взял. Первая ждёт дольше двух часов.
      WorkItem(
        id: 1042,
        kind: WorkKind.breakdown,
        status: WorkStatus.fresh,
        objectName: 'ТЦ Карнавал 3 этаж 1',
        objectType: 'Лифт с МП',
        objectAddress: 'ул. Ленина, 12',
        taskText: 'Лифт стоит между этажами, пассажиров нет',
        createdAt: ago(2.6),
        hasDefect: true,
      ),
      WorkItem(
        id: 1041,
        kind: WorkKind.clientRequest,
        status: WorkStatus.fresh,
        objectName: 'ЖК Речной, подъезд 2',
        objectType: 'Лифт без МП',
        objectAddress: 'наб. Обводного канала, 5',
        taskText: 'Скрипит дверь кабины',
        createdAt: ago(0.4),
      ),
      WorkItem(
        id: 1039,
        kind: WorkKind.request,
        status: WorkStatus.fresh,
        objectName: 'БЦ Атлант',
        objectType: 'Эскалатор',
        objectAddress: 'пр. Мира, 44',
        taskText: 'Заменить лампу в кабине',
        createdAt: ago(1.2),
      ),
      // Принятые: назначены, не начаты.
      WorkItem(
        id: 1038,
        kind: WorkKind.breakdown,
        status: WorkStatus.accepted,
        objectName: 'ЖК Северный, к. 3',
        objectType: 'Лифт без МП',
        objectAddress: 'ул. Полярная, 8',
        taskText: 'Не открываются двери на 7 этаже',
        performer: 'Иванов А. С.',
        createdAt: ago(1.5),
        acceptedAt: ago(0.7),
      ),
      WorkItem(
        id: 7712,
        kind: WorkKind.maintenance,
        actTitle: 'ТО-3',
        status: WorkStatus.accepted,
        objectName: 'Школа № 17',
        objectType: 'Лифт без МП',
        objectAddress: 'ул. Школьная, 3',
        performer: 'Петров В. И.',
        createdAt: ago(30),
        acceptedAt: ago(5.5),
      ),
      WorkItem(
        id: 1035,
        kind: WorkKind.defect,
        status: WorkStatus.accepted,
        objectName: 'БЦ Атлант',
        objectType: 'Эскалатор',
        objectAddress: 'пр. Мира, 44',
        taskText: 'Износ канатов, требуется замена',
        performer: 'Сидоров К. П.',
        createdAt: ago(26),
        acceptedAt: ago(24),
        hasDefect: true,
      ),
      // В работе, в том числе на паузе.
      WorkItem(
        id: 7715,
        kind: WorkKind.maintenance,
        actTitle: 'ТО-1',
        status: WorkStatus.running,
        objectName: 'ТЦ Карнавал 3 этаж 2',
        objectType: 'Лифт с МП',
        objectAddress: 'ул. Ленина, 12',
        performer: 'Иванов А. С.',
        createdAt: ago(48),
        acceptedAt: ago(3),
        startedAt: ago(0.9),
        hasDefect: true,
      ),
      WorkItem(
        id: 1037,
        kind: WorkKind.breakdown,
        status: WorkStatus.running,
        objectName: 'Поликлиника № 4',
        objectType: 'Лифт с МП',
        objectAddress: 'ул. Больничная, 1',
        taskText: 'Лифт не вызывается с 1 этажа',
        performer: 'Кузнецов Д. М.',
        createdAt: ago(10),
        acceptedAt: ago(9.5),
        startedAt: ago(9),
        comment: 'Нужна плата вызывной панели, заказал на складе',
        hasDefect: true,
      ),
      WorkItem(
        id: 7709,
        kind: WorkKind.maintenance,
        actTitle: 'ТО-6',
        status: WorkStatus.running,
        objectName: 'ЖК Речной, подъезд 1',
        objectType: 'Лифт без МП',
        objectAddress: 'наб. Обводного канала, 5',
        performer: 'Петров В. И.',
        createdAt: ago(72),
        acceptedAt: ago(6),
        startedAt: ago(4),
        pausedAt: ago(1.4),
        comment: 'Уехал на аварию в Поликлинику № 4',
      ),
      WorkItem(
        id: 1033,
        kind: WorkKind.clientRequest,
        status: WorkStatus.running,
        objectName: 'Гостиница Волна',
        objectType: 'Лифт с МП',
        objectAddress: 'ул. Морская, 20',
        taskText: 'Гудит при движении вниз',
        performer: 'Сидоров К. П.',
        createdAt: ago(8),
        acceptedAt: ago(7),
        startedAt: ago(6),
        pausedAt: ago(0.5),
        hasDefect: true,
      ),
      WorkItem(
        id: 1031,
        kind: WorkKind.request,
        status: WorkStatus.running,
        objectName: 'Дом 9 по Садовой',
        objectType: 'Лифт без МП',
        objectAddress: 'ул. Садовая, 9',
        taskText: 'Проверить освещение шахты',
        performer: 'Кузнецов Д. М.',
        createdAt: ago(9.5),
        acceptedAt: ago(9.2),
        startedAt: ago(2.2),
        hasDefect: true,
        comment: 'Нашёл трещину в кронштейне, завёл дефектный акт',
      ),
      // Сданные.
      WorkItem(
        id: 7690,
        kind: WorkKind.maintenance,
        actTitle: 'ТО-12',
        status: WorkStatus.submitted,
        objectName: 'Школа № 17',
        objectType: 'Лифт без МП',
        objectAddress: 'ул. Школьная, 3',
        performer: 'Петров В. И.',
        createdAt: ago(200),
        acceptedAt: ago(36),
        startedAt: ago(34),
        closedAt: ago(30),
        hasDefect: true,
      ),
      WorkItem(
        id: 1028,
        kind: WorkKind.breakdown,
        status: WorkStatus.submitted,
        objectName: 'ТЦ Карнавал 3 этаж 1',
        objectType: 'Лифт с МП',
        objectAddress: 'ул. Ленина, 12',
        taskText: 'Застряли пассажиры',
        performer: 'Иванов А. С.',
        createdAt: ago(41),
        acceptedAt: ago(40.8),
        startedAt: ago(40.5),
        closedAt: ago(40),
        comment: 'Освободил за 20 минут, вызвал из-за сбоя частотника',
      ),
      WorkItem(
        id: 1024,
        kind: WorkKind.clientRequest,
        status: WorkStatus.submitted,
        objectName: 'БЦ Атлант',
        objectType: 'Эскалатор',
        objectAddress: 'пр. Мира, 44',
        taskText: 'Кнопка 5 этажа западает',
        performer: 'Сидоров К. П.',
        createdAt: ago(60),
        acceptedAt: ago(52),
        startedAt: ago(51),
        closedAt: ago(50),
      ),
      WorkItem(
        id: 7688,
        kind: WorkKind.maintenance,
        actTitle: 'ТО-1',
        status: WorkStatus.submitted,
        objectName: 'Поликлиника № 4',
        objectType: 'Лифт с МП',
        objectAddress: 'ул. Больничная, 1',
        performer: 'Кузнецов Д. М.',
        createdAt: ago(300),
        acceptedAt: ago(75),
        startedAt: ago(72),
        closedAt: ago(70),
      ),
      WorkItem(
        id: 1019,
        kind: WorkKind.defect,
        status: WorkStatus.submitted,
        objectName: 'Гостиница Волна',
        objectType: 'Лифт с МП',
        objectAddress: 'ул. Морская, 20',
        taskText: 'Люфт направляющих, регулировка',
        performer: 'Иванов А. С.',
        createdAt: ago(120),
        acceptedAt: ago(100),
        startedAt: ago(96),
        closedAt: ago(90),
        hasDefect: true,
      ),
      WorkItem(
        id: 1015,
        kind: WorkKind.request,
        status: WorkStatus.submitted,
        objectName: 'Дом 9 по Садовой',
        objectType: 'Лифт без МП',
        objectAddress: 'ул. Садовая, 9',
        taskText: 'Смазать направляющие',
        performer: 'Петров В. И.',
        createdAt: ago(130),
        acceptedAt: ago(125),
        startedAt: ago(122),
        closedAt: ago(120),
      ),
      // Проблемы.
      WorkItem(
        id: 1036,
        kind: WorkKind.breakdown,
        status: WorkStatus.problem,
        objectName: 'ЖК Северный, к. 1',
        objectType: 'Лифт без МП',
        objectAddress: 'ул. Полярная, 8',
        taskText: 'Обрыв в цепи безопасности',
        performer: 'Кузнецов Д. М.',
        createdAt: ago(12),
        acceptedAt: ago(11),
        startedAt: ago(10),
        closedAt: ago(8),
        comment: 'Нет запчасти, лифт остановлен до поставки',
      ),
      WorkItem(
        id: 1025,
        kind: WorkKind.clientRequest,
        status: WorkStatus.problem,
        objectName: 'Гостиница Волна',
        objectType: 'Лифт с МП',
        objectAddress: 'ул. Морская, 20',
        taskText: 'Нет доступа в машинное помещение',
        performer: 'Сидоров К. П.',
        createdAt: ago(47),
        acceptedAt: ago(46),
        startedAt: ago(45.5),
        closedAt: ago(45),
        comment: 'Администратор не дал ключ',
        hasDefect: true,
      ),
      // Архив: мягко удалённое.
      WorkItem(
        id: 1040,
        kind: WorkKind.request,
        status: WorkStatus.fresh,
        objectName: 'Дом 9 по Садовой',
        objectType: 'Лифт без МП',
        objectAddress: 'ул. Садовая, 9',
        taskText: 'Дубль заявки, создана по ошибке',
        createdAt: ago(15),
        isActual: false,
      ),
      WorkItem(
        id: 902,
        kind: WorkKind.breakdown,
        status: WorkStatus.submitted,
        objectName: 'Старый склад',
        objectType: 'Траволатор',
        objectAddress: 'ул. Заводская, 2',
        taskText: 'Объект снят с обслуживания',
        performer: 'Иванов А. С.',
        createdAt: ago(410),
        startedAt: ago(403),
        closedAt: ago(400),
        isActual: false,
      ),
      WorkItem(
        id: 7100,
        kind: WorkKind.maintenance,
        actTitle: 'ТО-3',
        status: WorkStatus.submitted,
        objectName: 'Старый склад',
        objectType: 'Траволатор',
        objectAddress: 'ул. Заводская, 2',
        performer: 'Петров В. И.',
        createdAt: ago(1000),
        startedAt: ago(903),
        closedAt: ago(900),
        isActual: false,
      ),
      WorkItem(
        id: 880,
        kind: WorkKind.defect,
        status: WorkStatus.problem,
        objectName: 'Старый склад',
        objectType: 'Траволатор',
        objectAddress: 'ул. Заводская, 2',
        taskText: 'Дефектный акт не подтверждён',
        performer: 'Сидоров К. П.',
        createdAt: ago(1210),
        startedAt: ago(1205),
        closedAt: ago(1200),
        hasDefect: true,
        isActual: false,
      ),
    ];
  }
}
