import 'work_employee.dart';
import 'work_item.dart';

/// Вид работы, который человек выбирает первым в форме «Новая работа».
///
/// На бэке вида нет — он вычисляется из категории заявки
/// (`backend/src/services/work_kind.py`): категория с флагом поломки даёт
/// «Аварию», остальные — «Заявку». Выбор вида в форме сужает список
/// категорий, чтобы бейдж в ленте совпал с тем, что человек нажал.
enum NewWorkKind { breakdown, request }

extension NewWorkKindLabel on NewWorkKind {
  String get title => this == NewWorkKind.breakdown ? 'Авария' : 'Заявка';

  /// Пояснение под кнопкой: что именно попадёт в эту ветку.
  String get hint => this == NewWorkKind.breakdown
      ? 'Застревание, остановка, поломка'
      : 'Плановая или прочая работа';

  WorkKind get feedKind =>
      this == NewWorkKind.breakdown ? WorkKind.breakdown : WorkKind.request;
}

/// Категория заявки из справочника `fault_category`: код, полное имя и
/// флаг поломки — по нему категория попадает под «Аварию» или «Заявку».
class NewWorkCategory {
  const NewWorkCategory({
    required this.id,
    required this.code,
    required this.name,
    required this.countsAsBreakdown,
  });

  final int id;
  final String code;
  final String name;
  final bool countsAsBreakdown;

  NewWorkKind get kind =>
      countsAsBreakdown ? NewWorkKind.breakdown : NewWorkKind.request;
}

/// Объект для выбора: всё, по чему его ищут, и всё, что показывает
/// карточка после выбора. Закреплённый механик подставляется исполнителем.
class NewWorkObject {
  const NewWorkObject({
    required this.id,
    required this.name,
    required this.address,
    this.type,
    this.factoryNumber,
    this.registrationNumber,
    this.sectionId,
    this.section,
    this.mechanicId,
    this.mechanic,
    this.foreman,
    this.contactName,
    this.contactPhone,
  });

  final int id;
  final String name;
  final String address;
  final String? type;
  final String? factoryNumber;
  final String? registrationNumber;
  final int? sectionId;
  final String? section;
  final int? mechanicId;
  final String? mechanic;
  final String? foreman;
  final String? contactName;
  final String? contactPhone;

  /// Ищет по любому куску: адрес, название, номера, участок, механик.
  /// Несколько слов — все должны найтись, в любом порядке.
  bool matches(String query) {
    final String q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    final String hay = <String?>[
      name,
      address,
      type,
      factoryNumber,
      registrationNumber,
      section,
      mechanic,
      foreman,
    ].whereType<String>().join(' ').toLowerCase();
    return q.split(RegExp(r'\s+')).every(hay.contains);
  }
}

/// Открытая работа по выбранному объекту — чтобы не завести дубль.
class NewWorkOpenItem {
  const NewWorkOpenItem({
    required this.kind,
    required this.status,
    required this.title,
    this.performer,
  });

  final WorkKind kind;
  final WorkStatus status;
  final String title;
  final String? performer;
}

/// Всё, что форме нужно показать, но что она не меняет: справочники, автор
/// и «свои» участки прораба. Собирается снаружи — на фикстуре или из ручек.
class NewWorkContext {
  const NewWorkContext({
    required this.objects,
    required this.categories,
    required this.employees,
    required this.author,
    this.mySections = const <int>{},
    this.openWorks = const <int, List<NewWorkOpenItem>>{},
  });

  final List<NewWorkObject> objects;
  final List<NewWorkCategory> categories;

  /// Все активные пользователи, включая клиентов: задача бывает и на
  /// заказчика — оплатить, дать доступ.
  final List<WorkEmployee> employees;

  /// Кто заводит работу — строка «Создаст: …» внизу формы.
  final String author;

  /// Участки прораба: его группа раскрыта первой.
  final Set<int> mySections;

  /// Что уже висит по объекту, по id объекта.
  final Map<int, List<NewWorkOpenItem>> openWorks;

  List<NewWorkCategory> categoriesFor(NewWorkKind kind) =>
      categories.where((NewWorkCategory c) => c.kind == kind).toList();

  WorkEmployee? employeeById(int? id) {
    if (id == null) return null;
    for (final WorkEmployee e in employees) {
      if (e.id == id) return e;
    }
    return null;
  }
}

/// Что человек заполнил. Идёт в `POST /order/` как есть: `creator_id` и
/// `created_at` сервер ставит сам.
class NewWorkDraft {
  const NewWorkDraft({
    required this.kind,
    required this.object,
    required this.category,
    this.executor,
    this.description = '',
    this.photoName,
  });

  final NewWorkKind kind;
  final NewWorkObject object;
  final NewWorkCategory category;

  /// Пусто — работа ляжет в ленту «Новой» без исполнителя, назначат из строки.
  final WorkEmployee? executor;
  final String description;

  /// Имя выбранного файла; сам файл — в S02.
  final String? photoName;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'object_id': object.id,
    'fault_category_id': category.id,
    'executor_id': executor?.id,
    'task_text': description.isEmpty ? null : description,
  };
}

/// Ошибка создания словами — печатается в форме, форма остаётся открытой.
class NewWorkException implements Exception {
  const NewWorkException(this.message);

  final String message;

  @override
  String toString() => message;
}
