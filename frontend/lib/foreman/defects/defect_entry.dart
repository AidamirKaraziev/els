/// Дефектный акт глазами прораба — ровно то, что показывают список и карточка.
///
/// Ответ ручки для экрана слишком широк: `planned_to_id` разворачивается в
/// полный объект вместе с участком, моделью, компанией и всеми двенадцатью
/// месяцами плана — несколько килобайт на строку списка, из которых нужен
/// один год. Поэтому экран работает не с картой из JSON, а с этим значением:
/// что нужно показать, видно по полям, а не по тому, куда дотянулся `[]`.
///
/// Разбор здесь же, а не в репозитории, по той же причине, по какой он лежит
/// рядом с `DefectLink` у механика: у разбора есть свои случаи (акт без
/// работы, работа без шаблона, снимок без пути), и проверять их надо тестом,
/// не поднимая сети.
library;

import '../../helper/api_config.dart';

/// Откуда дефект заведён. Четыре точки входа механика — четыре случая.
///
/// Считается по привязкам, а не приходит с сервера: сервер хранит ссылки, а
/// «пункт чек-листа» отличается от «работы по ТО» только тем, что рядом с
/// `act_fact_id` заполнен `checklist_step_id`.
enum DefectSource {
  /// Дефект на пункте чек-листа: работа плюс номер пункта.
  checklistStep,

  /// Дефект по работе целиком, без привязки к пункту.
  work,

  /// Дефект по аварийной заявке.
  order,

  /// Дефект заведён прямо с объекта — работы и заявки нет.
  object,
}

extension DefectSourceLabel on DefectSource {
  String get label {
    switch (this) {
      case DefectSource.checklistStep:
        return 'Пункт чек-листа';
      case DefectSource.work:
        return 'Работа по ТО';
      case DefectSource.order:
        return 'Заявка';
      case DefectSource.object:
        return 'Объект';
    }
  }
}

/// Состояние акта: `created` / `reviewed` / `issued` / `fixed`.
///
/// Пятый случай — `unknown` — не выдумка на будущее, а защита: состояние
/// приходит строкой, и незнакомое значение должно показаться как есть, а не
/// уронить список.
enum DefectState { created, reviewed, issued, fixed, unknown }

extension DefectStateLabel on DefectState {
  String get label {
    switch (this) {
      case DefectState.created:
        return 'Заведён';
      case DefectState.reviewed:
        return 'Просмотрен';
      case DefectState.issued:
        return 'Выдан клиенту';
      case DefectState.fixed:
        return 'Устранён';
      case DefectState.unknown:
        return 'Неизвестно';
    }
  }
}

DefectState _stateFrom(Object? raw) {
  switch (raw?.toString()) {
    case 'created':
      return DefectState.created;
    case 'reviewed':
      return DefectState.reviewed;
    case 'issued':
      return DefectState.issued;
    case 'fixed':
      return DefectState.fixed;
    default:
      return DefectState.unknown;
  }
}

/// Один снимок дефекта.
class DefectPhoto {
  const DefectPhoto({required this.id, required this.url});

  final int id;

  /// Готовый адрес со схемой. Бэкенд отдаёт путь без неё
  /// (`host:port/api/v1/static/…`, см. `backend/src/getters/static_url.py`),
  /// и дописывает её `ApiConfig`. Грузить такой адрес надо через
  /// `helper/api_image.dart`: статика требует токена.
  final String url;

  static DefectPhoto? fromJson(Map<String, dynamic> json) {
    final Object? id = json['id'];
    final Object? photo = json['photo'];
    // Снимок без пути показывать нечем: у записи в базе есть строка, а файла
    // за ней нет. Молча пропускаем — битая картинка в галерее хуже, чем
    // галерея на одну карточку короче.
    if (id is! int || photo == null || photo.toString().isEmpty) return null;
    return DefectPhoto(id: id, url: '${ApiConfig.scheme}://$photo');
  }
}

/// Дефектный акт в том виде, в каком его показывают экраны прораба.
class DefectEntry {
  const DefectEntry({
    required this.id,
    required this.title,
    required this.source,
    required this.state,
    this.description,
    this.createdAt,
    this.month,
    this.year,
    this.typeActName,
    this.authorName,
    this.objectName,
    this.photos = const <DefectPhoto>[],
  });

  final int id;
  final String title;
  final String? description;

  final DefectSource source;
  final DefectState state;

  /// День, когда дефект заведён.
  ///
  /// Именно день, а не момент: `to_timestamp` на бэкенде ловит `datetime`
  /// первой же веткой `isinstance(d, date)` и время суток отбрасывает
  /// (`backend/src/utils/time_stamp.py`). Показывать часы значило бы
  /// показывать полночь у всех подряд.
  final DateTime? createdAt;

  /// Месяц планового ТО. Пуст у трёх точек входа из четырёх.
  final int? month;

  /// Год плана. Не путать с годом ленты: лента режется по дате создания.
  final String? year;

  /// Вид ТО той работы, на которой дефект замечен. Пуст у дефекта по заявке
  /// и у заведённого прямо с объекта — работы там нет вовсе.
  final String? typeActName;

  /// Кто нашёл.
  final String? authorName;

  final String? objectName;

  final List<DefectPhoto> photos;

  static const List<String> _months = <String>[
    'январь',
    'февраль',
    'март',
    'апрель',
    'май',
    'июнь',
    'июль',
    'август',
    'сентябрь',
    'октябрь',
    'ноябрь',
    'декабрь',
  ];

  /// Название месяца планового ТО, если он известен.
  String? get monthName {
    final int? value = month;
    if (value == null || value < 1 || value > 12) return null;
    return _months[value - 1];
  }

  static DefectEntry fromJson(Map<String, dynamic> json) {
    final Object? plannedTo = json['planned_to_id'];
    final Object? typeAct = json['type_act'];
    final Object? author = json['created_by_user_id'];

    return DefectEntry(
      id: json['id'] as int,
      title: (json['title'] ?? '').toString(),
      description: _text(json['description']),
      source: _sourceFrom(json),
      state: _stateFrom(json['state']),
      createdAt: _dateFrom(json['created_at']),
      month: json['month'] is int ? json['month'] as int : null,
      year: plannedTo is Map ? _text(plannedTo['year']) : null,
      typeActName: typeAct is Map ? _text(typeAct['name']) : null,
      authorName: author is Map ? _text(author['name']) : null,
      objectName: plannedTo is Map && plannedTo['object_id'] is Map
          ? _text((plannedTo['object_id'] as Map)['name'])
          : null,
      photos: _photosFrom(json['photos']),
    );
  }

  static DefectSource _sourceFrom(Map<String, dynamic> json) {
    if (json['act_fact_id'] != null) {
      return json['checklist_step_id'] != null
          ? DefectSource.checklistStep
          : DefectSource.work;
    }
    if (json['order_id'] != null) return DefectSource.order;
    return DefectSource.object;
  }

  /// Метка времени приходит в **секундах**, а `DateTime` ждёт миллисекунды.
  static DateTime? _dateFrom(Object? raw) {
    if (raw is! int) return null;
    return DateTime.fromMillisecondsSinceEpoch(raw * 1000);
  }

  static List<DefectPhoto> _photosFrom(Object? raw) {
    if (raw is! List) return const <DefectPhoto>[];
    final List<DefectPhoto> photos = <DefectPhoto>[];
    for (final Object? item in raw) {
      if (item is! Map) continue;
      final DefectPhoto? photo =
          DefectPhoto.fromJson(Map<String, dynamic>.from(item));
      if (photo != null) photos.add(photo);
    }
    return photos;
  }

  /// Пустая строка — то же самое, что отсутствие поля: экран рисует прочерк,
  /// а не пустое место, по которому не понять, потерялось значение или его нет.
  static String? _text(Object? raw) {
    if (raw == null) return null;
    final String value = raw.toString().trim();
    return value.isEmpty ? null : value;
  }
}
