import '../models/new_work_draft.dart';
import '../models/work_employee.dart';
import '../models/work_item.dart';
import 'fixture_works_repository.dart';

/// Справочники для формы «Новая работа» без сервера: объекты — те же, что в
/// строках [FixtureWorksRepository], категории — как в `init_db.py`,
/// сотрудники — из ленты плюс офис и заказчики, чтобы группы в выборе
/// исполнителя были все.
class FixtureNewWork {
  const FixtureNewWork._();

  static const List<NewWorkCategory> categories = <NewWorkCategory>[
    NewWorkCategory(
      id: 1,
      code: 'AA',
      name: 'Застревание пассажира. Опасность',
      countsAsBreakdown: true,
    ),
    NewWorkCategory(
      id: 2,
      code: 'А',
      name: 'Остановка лифта, подъемника, эскалатора, траволатора',
      countsAsBreakdown: true,
    ),
    NewWorkCategory(
      id: 3,
      code: 'В',
      name: 'Ухудшение рабочих характеристик, требуется наладка',
      countsAsBreakdown: true,
    ),
    NewWorkCategory(
      id: 4,
      code: 'Н',
      name: 'Незначительные проблемы',
      countsAsBreakdown: true,
    ),
    NewWorkCategory(
      id: 5,
      code: 'Д',
      name: 'Заказчик или другие',
      countsAsBreakdown: true,
    ),
    NewWorkCategory(
      id: 9,
      code: 'С',
      name: 'Сбой без остановки',
      countsAsBreakdown: true,
    ),
    // Заявки: то, что прораб и админ заводят руками. ТО в списке нет — оно
    // идёт из графиков; «Ложный вызов» — итог выезда, его ставит механик.
    // Коды Р…ДР и «Другое» — новые, на бэке появятся сидом в S02.
    NewWorkCategory(
      id: 11,
      code: 'Р',
      name: 'Ремонт по заявке',
      countsAsBreakdown: false,
    ),
    NewWorkCategory(
      id: 12,
      code: 'НЛ',
      name: 'Наладка и регулировка',
      countsAsBreakdown: false,
    ),
    NewWorkCategory(
      id: 13,
      code: 'ЗЧ',
      name: 'Замена запчастей',
      countsAsBreakdown: false,
    ),
    NewWorkCategory(
      id: 14,
      code: 'О',
      name: 'Осмотр по обращению',
      countsAsBreakdown: false,
    ),
    NewWorkCategory(
      id: 15,
      code: 'ПР',
      name: 'Предписание надзора',
      countsAsBreakdown: false,
    ),
    NewWorkCategory(
      id: 16,
      code: 'М',
      name: 'Модернизация',
      countsAsBreakdown: false,
    ),
    NewWorkCategory(
      id: 17,
      code: 'УБ',
      name: 'Приямок и машинное помещение',
      countsAsBreakdown: false,
    ),
    NewWorkCategory(
      id: 18,
      code: 'ДОК',
      name: 'Документы и организационное',
      countsAsBreakdown: false,
    ),
    NewWorkCategory(
      id: 7,
      code: 'ПТО',
      name: 'Периодическое техническое освидетельствование',
      countsAsBreakdown: false,
    ),
    NewWorkCategory(
      id: 8,
      code: 'КР',
      name: 'Капитальный ремонт',
      countsAsBreakdown: false,
    ),
    NewWorkCategory(
      id: 19,
      code: 'ДР',
      name: 'Другое',
      countsAsBreakdown: false,
    ),
  ];

  static const List<NewWorkObject> objects = <NewWorkObject>[
    NewWorkObject(
      id: 1,
      name: 'ТЦ Карнавал 3 этаж 1',
      address: 'ул. Ленина, 12',
      type: 'Лифт с МП',
      factoryNumber: '4471',
      registrationNumber: 'ЛФ-01-2231',
      sectionId: 1,
      section: 'Центр',
      mechanicId: 11,
      mechanic: 'Иванов А. С.',
      foreman: 'Морозов П. Е.',
      contactName: 'Администрация ТЦ',
      contactPhone: '+7 812 300-10-10',
    ),
    NewWorkObject(
      id: 2,
      name: 'ТЦ Карнавал 3 этаж 2',
      address: 'ул. Ленина, 12',
      type: 'Лифт с МП',
      factoryNumber: '4472',
      registrationNumber: 'ЛФ-01-2232',
      sectionId: 1,
      section: 'Центр',
      mechanicId: 11,
      mechanic: 'Иванов А. С.',
      foreman: 'Морозов П. Е.',
      contactName: 'Администрация ТЦ',
      contactPhone: '+7 812 300-10-10',
    ),
    NewWorkObject(
      id: 3,
      name: 'ЖК Речной, подъезд 1',
      address: 'наб. Обводного канала, 5',
      type: 'Лифт без МП',
      factoryNumber: '8810',
      sectionId: 2,
      section: 'Север',
      mechanicId: 12,
      mechanic: 'Петров В. И.',
      foreman: 'Морозов П. Е.',
      contactName: 'УК «Речная»',
      contactPhone: '+7 812 555-20-20',
    ),
    NewWorkObject(
      id: 4,
      name: 'ЖК Речной, подъезд 2',
      address: 'наб. Обводного канала, 5',
      type: 'Лифт без МП',
      factoryNumber: '8811',
      sectionId: 2,
      section: 'Север',
      mechanicId: 12,
      mechanic: 'Петров В. И.',
      foreman: 'Морозов П. Е.',
      contactName: 'УК «Речная»',
      contactPhone: '+7 812 555-20-20',
    ),
    NewWorkObject(
      id: 5,
      name: 'БЦ Атлант',
      address: 'пр. Мира, 44',
      type: 'Эскалатор',
      factoryNumber: 'ES-2019-77',
      sectionId: 1,
      section: 'Центр',
      mechanicId: 13,
      mechanic: 'Сидоров К. П.',
      foreman: 'Морозов П. Е.',
    ),
    NewWorkObject(
      id: 6,
      name: 'ЖК Северный, к. 1',
      address: 'ул. Полярная, 8',
      type: 'Лифт без МП',
      factoryNumber: '9021',
      sectionId: 2,
      section: 'Север',
      mechanicId: 12,
      mechanic: 'Петров В. И.',
    ),
    NewWorkObject(
      id: 7,
      name: 'ЖК Северный, к. 3',
      address: 'ул. Полярная, 8',
      type: 'Лифт без МП',
      factoryNumber: '9023',
      sectionId: 2,
      section: 'Север',
      // Механик не закреплён: форма должна оставить исполнителя пустым.
    ),
    NewWorkObject(
      id: 8,
      name: 'Школа № 17',
      address: 'ул. Школьная, 3',
      type: 'Лифт без МП',
      factoryNumber: '3305',
      sectionId: 3,
      section: 'Юг',
      mechanicId: 14,
      mechanic: 'Кузнецов Д. М.',
      contactName: 'Завхоз',
      contactPhone: '+7 812 777-30-30',
    ),
    NewWorkObject(
      id: 9,
      name: 'Поликлиника № 4',
      address: 'ул. Больничная, 1',
      type: 'Лифт с МП',
      factoryNumber: '5150',
      sectionId: 3,
      section: 'Юг',
      mechanicId: 14,
      mechanic: 'Кузнецов Д. М.',
    ),
    NewWorkObject(
      id: 10,
      name: 'Гостиница Волна',
      address: 'ул. Морская, 20',
      type: 'Лифт с МП',
      factoryNumber: '6001',
      sectionId: 3,
      section: 'Юг',
      mechanicId: 14,
      mechanic: 'Кузнецов Д. М.',
    ),
    NewWorkObject(
      id: 11,
      name: 'Дом 9 по Садовой',
      address: 'ул. Садовая, 9',
      type: 'Лифт без МП',
      factoryNumber: '2210',
      sectionId: 1,
      section: 'Центр',
      mechanicId: 11,
      mechanic: 'Иванов А. С.',
    ),
    NewWorkObject(
      id: 12,
      name: 'Старый склад',
      address: 'ул. Заводская, 2',
      type: 'Траволатор',
      factoryNumber: 'TR-0042',
      sectionId: 3,
      section: 'Юг',
    ),
  ];

  /// Люди ленты плюс те, кого в ленте нет: офис без участка и заказчики.
  static const List<WorkEmployee> extraEmployees = <WorkEmployee>[
    WorkEmployee(
      id: 21,
      name: 'Морозов П. Е.',
      specialty: 'Прораб',
      sectionId: 1,
      section: 'Центр',
    ),
    WorkEmployee(id: 22, name: 'Белова Е. А.', specialty: 'Администратор'),
    WorkEmployee(id: 31, name: 'УК «Речная»', specialty: 'Клиент'),
    WorkEmployee(id: 32, name: 'Администрация ТЦ', specialty: 'Клиент'),
  ];

  static List<WorkEmployee> get employees => <WorkEmployee>[
    ...FixtureWorksRepository.employees,
    ...extraEmployees,
  ];

  /// Открытые работы по объекту — из строк ленты, по адресу и названию.
  static Map<int, List<NewWorkOpenItem>> openWorks() {
    final Map<int, List<NewWorkOpenItem>> out = <int, List<NewWorkOpenItem>>{};
    for (final WorkItem i in FixtureWorksRepository.items) {
      if (i.status.isClosed) continue;
      for (final NewWorkObject o in objects) {
        if (o.name != i.objectName) continue;
        out
            .putIfAbsent(o.id, () => <NewWorkOpenItem>[])
            .add(
              NewWorkOpenItem(
                kind: i.kind,
                status: i.status,
                title: i.taskText ?? i.actTitle ?? i.kind.title,
                performer: i.performer,
              ),
            );
      }
    }
    return out;
  }

  static NewWorkContext context({required String author}) => NewWorkContext(
    objects: objects,
    categories: categories,
    employees: employees,
    author: author,
    mySections: FixtureWorksRepository.mySections,
    openWorks: openWorks(),
  );
}
