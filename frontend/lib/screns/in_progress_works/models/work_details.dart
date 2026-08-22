/// Подробности текущей работы — то, чего нет в строке раздела.
///
/// Строка отвечает на вопрос «за чем идти», карточка — «что там». Всё для
/// неё уже лежит на сервере, новых ручек этап не заводит:
///
/// * `GET /act-fact/{id}/` — чек-лист с отметками и комментариями механика,
///   времена, id механика ([WorkDetails]);
/// * `GET /act-fact/{id}/photos/` — снимки шагов ([WorkPhotos]);
/// * `GET /cp/universal-user/{id}/` — кому звонить ([Performer]).
///
/// Отдельно от `ActDetails` механика (`mechanic/data/acts.dart`) намеренно:
/// та живёт офлайн-слоем телефона, умеет отправлять чек-лист обратно и не
/// несёт ни паузы, ни механика, ни снимков. Прорабу же нужно только читать.
library;

/// Сколько пунктов чек-листа видно до обрыва.
///
/// Шесть — из макета: столько помещается на телефоне, не превращая карточку в
/// свиток. Остальные прячутся за «и ещё N» и разворачиваются по нажатию.
const int kVisibleSteps = 6;

/// Пункт регламента глазами прораба.
class ChecklistStep {
  const ChecklistStep({
    required this.id,
    required this.title,
    required this.done,
    this.comment,
  });

  /// Номер шага внутри акта. На него ссылается фотография — по нему снимки и
  /// раскладываются по пунктам.
  final int? id;

  final String title;
  final bool done;

  /// Что механик приписал к пункту. Живёт внутри своего пункта, а не общей
  /// кучей внизу: «износ выше нормы» без названия шага ничего не значит.
  final String? comment;

  static ChecklistStep? fromJson(Map<String, dynamic> json) {
    final String? title = _trimmed(_asString(json['title']));
    if (title == null) return null;
    return ChecklistStep(
      id: _asInt(json['id']),
      title: title,
      done: json['done'] == true,
      comment: _trimmed(_asString(json['comment'])),
    );
  }
}

/// Чек-лист акта целиком.
class WorkChecklist {
  const WorkChecklist({this.title, this.steps = const <ChecklistStep>[]});

  /// Название регламента из графика: «ТО-1». Может отсутствовать.
  final String? title;

  final List<ChecklistStep> steps;

  int get total => steps.length;

  int get doneCount => steps.where((ChecklistStep step) => step.done).length;

  /// Пустой чек-лист означает «регламент не заполнен», а не «ничего не
  /// сделано». Карточка обязана сказать это словами, а не нулём.
  bool get isEmpty => steps.isEmpty;

  /// «4 из 12» — подпись блока.
  String get progressLabel => '$doneCount из $total';

  /// Порядок показа: сначала отмеченные в порядке регламента, потом
  /// неотмеченные.
  ///
  /// Прораб открывает карточку, чтобы понять, что уже сделано, — сделанное и
  /// стоит первым. Внутри каждой группы порядок регламента сохраняется:
  /// пункты идут так, как их проходит механик.
  List<ChecklistStep> get ordered => <ChecklistStep>[
        ...steps.where((ChecklistStep step) => step.done),
        ...steps.where((ChecklistStep step) => !step.done),
      ];

  /// Что видно до разворота.
  List<ChecklistStep> visible({bool expanded = false}) {
    final List<ChecklistStep> all = ordered;
    if (expanded || all.length <= kVisibleSteps) return all;
    return all.sublist(0, kVisibleSteps);
  }

  /// Сколько пунктов спрятано за «и ещё N». Ноль — видно все.
  int get hiddenCount =>
      total > kVisibleSteps ? total - kVisibleSteps : 0;

  /// «…и ещё 6 пунктов».
  String get hiddenLabel => '…и ещё $hiddenCount ${_stepsWord(hiddenCount)}';

  static WorkChecklist fromJson(dynamic value) {
    if (value is! Map) return const WorkChecklist();
    final Map<String, dynamic> json = value.cast<String, dynamic>();
    return WorkChecklist(
      title: _trimmed(_asString(json['title'])),
      steps: _asMapList(json['steps'])
          .map(ChecklistStep.fromJson)
          .whereType<ChecklistStep>()
          .toList(growable: false),
    );
  }
}

/// Ответ `GET /act-fact/{id}/`.
///
/// Времена здесь приходят строкой ISO, а не секундами эпохи, как в ленте
/// раздела. Разбираем их, но в шапке карточки всё равно показываем то, что
/// уже пришло со строкой: два представления одного времени рано или поздно
/// разойдутся, и человек увидит разное в списке и в карточке.
class WorkDetails {
  const WorkDetails({
    required this.id,
    this.checklist = const WorkChecklist(),
    this.startedAt,
    this.pausedAt,
    this.commentary,
    this.mainMechanicId,
  });

  final int id;
  final WorkChecklist checklist;

  final DateTime? startedAt;

  /// Когда работа встала. Пусто — работа не на паузе.
  final DateTime? pausedAt;

  /// Комментарий ко всей работе: почему остановился или что не вышло.
  final String? commentary;

  /// Кому звонить. По нему карточка идёт за телефоном механика.
  final int? mainMechanicId;

  factory WorkDetails.fromJson(Map<String, dynamic> json) {
    final dynamic data = json['data'];
    final Map<String, dynamic> act =
        data is Map ? data.cast<String, dynamic>() : json;

    return WorkDetails(
      id: _asInt(act['id']) ?? 0,
      checklist: WorkChecklist.fromJson(act['checklist']),
      startedAt: _asMoment(act['started_at']),
      pausedAt: _asMoment(act['paused_at']),
      commentary: _trimmed(_asString(act['commentary'])),
      mainMechanicId: _asInt(act['main_mechanic_id']),
    );
  }
}

/// Снимки шагов, разложенные по пунктам.
///
/// Ручка отдаёт их одним списком на весь акт: снимков у ТО единицы, и тянуть
/// их по одному запросу на пункт значило бы двенадцать запросов вместо одного.
class WorkPhotos {
  const WorkPhotos(this.byStep);

  final Map<int, List<String>> byStep;

  static const WorkPhotos empty = WorkPhotos(<int, List<String>>{});

  /// Снимки одного пункта. Пункт без номера сфотографировать нельзя — у него
  /// их и не бывает.
  List<String> of(ChecklistStep step) {
    final int? id = step.id;
    if (id == null) return const <String>[];
    return byStep[id] ?? const <String>[];
  }

  factory WorkPhotos.fromJson(Map<String, dynamic> json) {
    final Map<int, List<String>> byStep = <int, List<String>>{};

    for (final Map<String, dynamic> row in _asMapList(json['data'])) {
      final int? stepId = _asInt(row['step_id']);
      final String? photo = _trimmed(_asString(row['photo']));
      if (stepId == null || photo == null) continue;
      byStep.putIfAbsent(stepId, () => <String>[]).add(photo);
    }

    return WorkPhotos(byStep);
  }
}

/// Кто ведёт работу — из справочника сотрудников.
///
/// Строка раздела знает исполнителя только по имени: телефона в ответе
/// текущих работ нет и быть не должно — раздел про состояние работ, а не про
/// справочник. Карточка идёт за номером отдельно, по `main_mechanic_id` акта.
class Performer {
  const Performer({
    required this.id,
    this.name,
    this.specialty,
    this.phone,
  });

  final int id;
  final String? name;

  /// Специальность из справочника: «Механик».
  final String? specialty;

  /// `contact_phone` как он лежит в справочнике — поле необязательное.
  final String? phone;

  /// Есть ли кому звонить.
  bool get hasPhone => callUri != null;

  /// Что подставить в `tel:`.
  ///
  /// В справочнике номер лежит по-разному: где-то с `+7`, где-то с восьмёркой,
  /// где-то десятью цифрами — старые экраны дописывали `+7` прямо в строку
  /// вывода. Нормализуем здесь, чтобы звонок уходил одинаково отовсюду.
  String? get callUri {
    final String? digits = _digits(phone);
    if (digits == null) return null;
    if (phone!.trim().startsWith('+')) return '+$digits';
    if (digits.length == 11 && digits.startsWith('8')) {
      return '+7${digits.substring(1)}';
    }
    if (digits.length == 11 && digits.startsWith('7')) return '+$digits';
    if (digits.length == 10) return '+7$digits';
    // Короткий или странный номер оставляем как есть: набрать его человек
    // всё равно сможет, а выдумывать за справочник код страны — нет.
    return digits;
  }

  /// «+7 999 000-00-00». Непривычной длины номер показываем как записан:
  /// подгонять его под маску значило бы соврать о том, что в справочнике.
  String? get phoneLabel {
    final String? uri = callUri;
    if (uri == null) return null;
    if (!uri.startsWith('+7') || uri.length != 12) return uri;
    return '+7 ${uri.substring(2, 5)} ${uri.substring(5, 8)}-'
        '${uri.substring(8, 10)}-${uri.substring(10)}';
  }

  factory Performer.fromJson(Map<String, dynamic> json) {
    final dynamic data = json['data'];
    final Map<String, dynamic> user =
        data is Map ? data.cast<String, dynamic>() : json;
    final dynamic specialty = user['working_specialty_id'];

    return Performer(
      id: _asInt(user['id']) ?? 0,
      name: _trimmed(_asString(user['name'])),
      specialty: specialty is Map
          ? _trimmed(_asString(specialty.cast<String, dynamic>()['title']))
          : null,
      phone: _trimmed(_asString(user['contact_phone'])),
    );
  }
}

/// «21.08.2026, 08:15» — как времена подписаны в макете.
String? stampLabel(DateTime? at) {
  if (at == null) return null;
  return '${_two(at.day)}.${_two(at.month)}.${at.year}, '
      '${_two(at.hour)}:${_two(at.minute)}';
}

/// Возраст того, что на экране: «только что», «минуту назад», «2 часа назад».
///
/// В ответе акта метки правки нет, и сказать, когда механик последний раз
/// что-то отметил, карточка не может. Честно она может сказать только одно —
/// когда сама эти данные забрала.
String agoLabel(DateTime loadedAt, {DateTime? now}) {
  final Duration passed = (now ?? DateTime.now()).difference(loadedAt);
  if (passed.isNegative || passed.inMinutes < 1) return 'только что';

  final int minutes = passed.inMinutes;
  if (minutes < 60) {
    if (minutes == 1) return 'минуту назад';
    return '$minutes ${_minutesWord(minutes)} назад';
  }

  final int hours = passed.inHours;
  if (hours == 1) return 'час назад';
  return '$hours ${_hoursWord(hours)} назад';
}

String _stepsWord(int count) => _plural(count, 'пункт', 'пункта', 'пунктов');

String _minutesWord(int count) =>
    _plural(count, 'минуту', 'минуты', 'минут');

String _hoursWord(int count) => _plural(count, 'час', 'часа', 'часов');

String _plural(int count, String one, String few, String many) {
  final int hundreds = count % 100;
  final int tens = count % 10;
  if (hundreds >= 11 && hundreds <= 14) return many;
  if (tens == 1) return one;
  if (tens >= 2 && tens <= 4) return few;
  return many;
}

String _two(int value) => value.toString().padLeft(2, '0');

/// Только цифры номера. `null` — цифр нет вовсе, то есть номера нет.
String? _digits(String? phone) {
  if (phone == null) return null;
  final String digits = phone.replaceAll(RegExp(r'\D'), '');
  return digits.isEmpty ? null : digits;
}

/// Есть ли у строки времени часовой пояс: «Z» или смещение вида «+03:00».
final RegExp _zoned = RegExp(r'(Z|[+-]\d{2}:?\d{2})$');

/// Время из ответа акта: строка ISO. Секунды эпохи тоже принимаем — на случай,
/// если поле однажды приведут к форме соседних ручек.
///
/// **Строка без пояса — это UTC.** Бэкенд хранит времена наивным `datetime` в
/// UTC и отдаёт их как `2026-08-21T15:14:00`, без «Z»; `DateTime.tryParse`
/// такую строку читает как местное время, и карточка показывала «начал 15:14»
/// там, где строка списка говорит «начал 18:14». Список прав: он получает то
/// же время секундами эпохи, то есть уже с поясом. Дописываем «Z» сами и
/// переводим в местное — иначе одно и то же время расходится на экране на
/// величину часового пояса.
DateTime? _asMoment(dynamic value) {
  if (value is String) {
    final String text = value.trim();
    if (text.isEmpty) return null;
    final DateTime? parsed =
        DateTime.tryParse(_zoned.hasMatch(text) ? text : '${text}Z');
    return parsed?.toLocal();
  }
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

String? _trimmed(String? value) {
  final String? text = value?.trim();
  return text == null || text.isEmpty ? null : text;
}

List<Map<String, dynamic>> _asMapList(dynamic value) {
  if (value is! List) return const <Map<String, dynamic>>[];
  return value
      .whereType<Map>()
      .map((Map item) => item.cast<String, dynamic>())
      .toList(growable: false);
}
