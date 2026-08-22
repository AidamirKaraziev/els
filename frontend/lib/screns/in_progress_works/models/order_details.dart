/// Подробности заявки — то, что видит прораб, открыв строку не-ТО.
///
/// У заявки нет чек-листа: вместо регламента она несёт задание словами
/// диспетчера, категорию неисправности и время, когда её завели. Ручки в
/// проде, этап их не заводит:
///
/// * `GET /order/{id}/` — задание, категория, времена, исполнитель;
/// * `GET /order-photo/{id}` — снимки заявки.
///
/// Отдельно от [WorkDetails] намеренно: общего у них только экран. Ответ
/// заявки устроен иначе — времена приходят секундами эпохи и без времени
/// суток, а исполнитель целиком лежит внутри самой заявки, и второй раз в
/// справочник ходить не за чем. Общим остаётся [Performer]: кому звонить, у
/// обоих видов работ решается одинаково.
library;

import 'work_details.dart' show Performer;

/// Статусы из засеянного справочника (`backend/src/core/db/init_db.py`):
/// 1 «Создано», 2 «Принято», 3 «В процессе», 4 «Выполнено», 5 «Проблема».
///
/// Раздел «Сейчас в работе» отбирает заявки ровно по [kOrderInProgress]
/// (`crud_in_progress_works.py`), а «Выполнено» и «Проблема» уводят заявку в
/// ленту сданных. Карточка обязана читать статус теми же числами: одна и та же
/// запись не может значить разное в списке и в карточке.
const int kOrderInProgress = 3;
const int kOrderDone = 4;
const int kOrderProblem = 5;

/// Ответ `GET /order/{id}/`.
class OrderDetails {
  const OrderDetails({
    required this.id,
    this.taskText,
    this.categoryName,
    this.categoryCode,
    this.reasonFault,
    this.createdAt,
    this.executor,
    this.statusId,
    this.statusName,
  });

  final int id;

  /// Что просили сделать. Поле необязательное: диспетчер заводит заявку по
  /// звонку и текст пишет не всегда.
  final String? taskText;

  /// Категория по отраслевой классификации: `name` — полное имя вида
  /// «AA (Застревание пассажира. Опасность)», `code` — «AA».
  final String? categoryName;
  final String? categoryCode;

  /// Причина неисправности из справочника. У идущей заявки обычно пуста: её
  /// заполняют, когда разобрались.
  final String? reasonFault;

  /// Когда заявку завели.
  final DateTime? createdAt;

  /// Кому звонить. Приезжает вместе с заявкой — в `executor_id` лежит
  /// сотрудник целиком, с телефоном и специальностью.
  final Performer? executor;

  /// Что с заявкой сейчас. `null` — статуса в ответе не было.
  final int? statusId;

  /// Имя статуса как в справочнике: «Выполнено». Показывать его карточка не
  /// обязана, но сказать «статус изменился» без слова нечем.
  final String? statusName;

  /// Заявка ушла из раздела текущих работ.
  ///
  /// Статуса нет вовсе — считаем, что идёт: молчащее поле не повод объявить
  /// работу сданной, а промолчать в обратную сторону дешевле, чем соврать.
  bool get isGone => statusId != null && statusId != kOrderInProgress;

  /// Заявку закрыли: «Выполнено» либо «Проблема» — оба уводят её в ленту
  /// сданных работ. Возврат в «Создано» или «Принято» — не сдача, и говорить
  /// о нём надо другими словами.
  bool get isSubmitted =>
      statusId == kOrderDone || statusId == kOrderProblem;

  /// Задание словами диспетчера либо `null`. Что сказать вместо него, решает
  /// экран: модель подписей не выдумывает.
  String? get taskLabel => _trimmed(taskText);

  /// «AA · Застревание пассажира. Опасность».
  ///
  /// В базе полное имя начинается с кода и продолжается скобкой
  /// (`backend/src/core/db/init_db.py`), и показать их подряд значило бы
  /// «AA · AA (…)». Поэтому скобку разбираем: код отдельно, слова отдельно.
  /// Имя непривычного вида показываем как записано — подгонять справочник под
  /// шаблон карточка не вправе.
  String get categoryLabel {
    final String? name = _trimmed(categoryName);
    final String? code = _trimmed(categoryCode);

    if (name == null) return code ?? 'Категория не указана';
    if (code == null) return name;

    final RegExp shape = RegExp(
      '^${RegExp.escape(code)}\\s*\\((.+)\\)\\.?\$',
      caseSensitive: false,
    );
    final RegExpMatch? match = shape.firstMatch(name);
    if (match == null) return name;

    return '$code · ${match.group(1)}';
  }

  String? get reasonLabel => _trimmed(reasonFault);

  /// «11.08.2026» — день без времени суток.
  ///
  /// В карточке ТО времена подписаны с часами и минутами, здесь их нет
  /// намеренно: `to_timestamp` на бэкенде теряет время суток
  /// (`backend/src/utils/time_stamp.py`), и `created_at` заявки всегда
  /// приезжает полночью — а после перевода в местный пояс превращается в
  /// бодрое «03:00». Показывать такое значило бы соврать о том, чего система
  /// не хранит; строка списка говорит то же самое — «заявка от 11 августа».
  String? get createdLabel {
    final DateTime? at = createdAt;
    if (at == null) return null;
    return '${_two(at.day)}.${_two(at.month)}.${at.year}';
  }

  factory OrderDetails.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> order = _unwrap(json);
    final Map<String, dynamic> category = _asMap(order['fault_category_id']);
    final Map<String, dynamic> reason = _asMap(order['reason_fault_id']);
    final dynamic executor = order['executor_id'];
    // Статус приходит объектом справочника. Голое число тоже принимаем: так
    // это поле выглядит в соседних ручках, и разбиться о форму ответа
    // карточка не должна.
    final dynamic status = order['status_id'];
    final Map<String, dynamic> statusMap = _asMap(status);

    return OrderDetails(
      id: _asInt(order['id']) ?? 0,
      taskText: _trimmed(_asString(order['task_text'])),
      categoryName: _trimmed(_asString(category['name'])),
      categoryCode: _trimmed(_asString(category['code'])),
      reasonFault: _trimmed(_asString(reason['name'])),
      createdAt: _asSecondsTimestamp(order['created_at']),
      executor: executor is Map
          ? Performer.fromJson(executor.cast<String, dynamic>())
          : null,
      statusId: status is Map ? _asInt(statusMap['id']) : _asInt(status),
      statusName: _trimmed(_asString(statusMap['name'])),
    );
  }
}

/// Снимки заявки — `GET /order-photo/{id}`.
///
/// Плоским списком, а не по пунктам, как у ТО: пунктов у заявки нет, и
/// раскладывать снимки не на что.
class OrderPhotos {
  const OrderPhotos(this.items);

  final List<String> items;

  static const OrderPhotos empty = OrderPhotos(<String>[]);

  bool get isEmpty => items.isEmpty;

  factory OrderPhotos.fromJson(Map<String, dynamic> json) {
    return OrderPhotos(
      _asMapList(json['data'])
          .map((Map<String, dynamic> row) => _trimmed(_asString(row['photo'])))
          .whereType<String>()
          .toList(growable: false),
    );
  }
}

/// Ответы бэкенда приходят завёрнутыми в `data`. Голую карту тоже принимаем:
/// так проще писать тесты и так же поступают соседние модели.
Map<String, dynamic> _unwrap(Map<String, dynamic> json) {
  final dynamic data = json['data'];
  return data is Map ? data.cast<String, dynamic>() : json;
}

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map) return value.cast<String, dynamic>();
  return <String, dynamic>{};
}

List<Map<String, dynamic>> _asMapList(dynamic value) {
  if (value is! List) return const <Map<String, dynamic>>[];
  return value
      .whereType<Map>()
      .map((Map item) => item.cast<String, dynamic>())
      .toList(growable: false);
}

/// Времена заявки приходят секундами эпохи (`to_timestamp` на бэкенде) — то
/// есть уже с поясом, в отличие от наивных строк акта.
DateTime? _asSecondsTimestamp(dynamic value) {
  final int? seconds = _asInt(value);
  if (seconds == null || seconds == 0) return null;
  return DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
}

int? _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

String? _asString(dynamic value) => value is String ? value : null;

String _two(int value) => value.toString().padLeft(2, '0');

String? _trimmed(String? value) {
  final String? text = value?.trim();
  return text == null || text.isEmpty ? null : text;
}
