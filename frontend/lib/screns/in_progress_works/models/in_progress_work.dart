import 'package:flutter/material.dart';

import '../../../helper/class_colors.dart';
import '../../submitted_works/models/submitted_work.dart' show WorkKind;

/// Модели ответа `GET /api/v1/work/in-progress` — работ, которые механики
/// ведут прямо сейчас.
///
/// Отдельно от `SubmittedWork` намеренно: у сданной работы главный вопрос
/// «кто сдал и смотрел ли я это», у текущей — «что с ней происходит и почему
/// она встала». Общий у них только справочник видов работ — [WorkKind]
/// берётся у соседа, чтобы бейдж в двух лентах одного экрана не разъехался.

/// Что с работой прямо сейчас. Незакрытая работа бывает только такой:
/// механик её ведёт, приостановил или сообщил о проблеме.
enum WorkState { running, paused, problem }

/// Сколько пунктов чек-листа отмечено.
///
/// Работа без чек-листа приходит вовсе без прогресса, а не с нулями: «пунктов
/// нет» и «ни один не отмечен» — разные вещи, и строка обязана говорить их
/// разными словами.
class WorkProgress {
  const WorkProgress({required this.done, required this.total});

  final int done;
  final int total;

  /// «7 из 12».
  String get label => '$done из $total';

  static WorkProgress? fromJson(dynamic value) {
    if (value is! Map) return null;
    final Map<String, dynamic> json = value.cast<String, dynamic>();
    final int? done = _asInt(json['done']);
    final int? total = _asInt(json['total']);
    if (done == null || total == null) return null;
    return WorkProgress(done: done, total: total);
  }
}

/// Одна строка раздела: что и где делают, кто и что с работой происходит.
class InProgressWork {
  const InProgressWork({
    required this.kind,
    required this.workId,
    required this.state,
    this.objectId,
    this.objectName,
    this.objectAddress,
    this.taskText,
    this.performer,
    this.since,
    this.startedAt,
    this.reason,
    this.title,
    this.progress,
  });

  final WorkKind kind;

  /// ID акта у ТО и ID заявки у остальных видов.
  final int workId;

  final WorkState state;

  final int? objectId;
  final String? objectName;
  final String? objectAddress;

  /// Что просили сделать. Только у заявок: у ТО задание — это чек-лист акта.
  final String? taskText;

  final String? performer;

  /// С какого момента длится состояние. У паузы — момент остановки, у идущей
  /// работы — момент начала. **У проблемы пусто**: когда механик её объявил,
  /// в системе не хранится.
  final DateTime? since;

  final DateTime? startedAt;

  /// Причина словами механика. Есть у паузы и проблемы.
  final String? reason;

  /// Регламент: «ТО-1», «ТО-3». У заявок пусто.
  final String? title;

  final WorkProgress? progress;

  bool get isProblem => state == WorkState.problem;

  /// Название объекта. «Объект 42» лучше пустой ячейки: по нему хотя бы
  /// понятно, что спрашивать.
  String get objectLabel {
    final String? name = objectName?.trim();
    if (name != null && name.isNotEmpty) return name;
    if (objectId != null) return 'Объект $objectId';
    return 'Объект не указан';
  }

  /// Адрес второй строкой: по «Лифт 12» непонятно, куда ехать.
  String? get addressLabel => _trimmed(objectAddress);

  String get performerLabel => _trimmed(performer) ?? '—';

  String? get taskLabel => _trimmed(taskText);

  /// Причина ровно как её написал механик — это цитата, а не подпись системы.
  String? get reasonLabel => _trimmed(reason);

  String get kindLabel {
    switch (kind) {
      case WorkKind.maintenance:
        return 'ТО';
      case WorkKind.breakdown:
        return 'Авария';
      case WorkKind.clientRequest:
        return 'Обращение';
      case WorkKind.request:
        return 'Заявка';
      case WorkKind.defect:
        return 'Дефект';
    }
  }

  /// Цвет бейджа вида работы. Тот же, что у сданной работы: строка узнаётся
  /// так же, как соседняя ниже по экрану.
  Color get kindColor {
    switch (kind) {
      case WorkKind.breakdown:
        return ColorApp.myColorRed;
      case WorkKind.clientRequest:
        return ColorApp.myColorBlue;
      case WorkKind.maintenance:
        return ColorApp.myColorGreenAuth;
      case WorkKind.request:
      case WorkKind.defect:
        return ColorApp.myColorGray;
    }
  }

  /// Пилюля состояния: что с работой и сколько времени она в этом состоянии.
  ///
  /// «Идёт · 40 мин», «Пауза · 1 ч 10 мин», «Проблема», «В работе · 25 мин».
  /// У проблемы времени нет и быть не может — момент, когда механик её
  /// объявил, в базе не хранится, и часы по метке правки были бы выдумкой.
  String get pillLabel {
    switch (state) {
      case WorkState.problem:
        return 'Проблема';
      case WorkState.paused:
        return _withDuration('Пауза', since);
      case WorkState.running:
        // Слово зависит от вида: механик ТО «идёт» по чек-листу, а заявку
        // берут «в работу». Разница пришла из макета и из речи прораба.
        final String word =
            kind == WorkKind.maintenance ? 'Идёт' : 'В работе';
        return _withDuration(word, since ?? startedAt);
    }
  }

  /// Серый хвост строки на телефоне: «начал 09:30 · 7 из 12» у ТО и
  /// «заявка от 21 августа» у заявки. Числа для понимания, а не для тревоги —
  /// на узком экране режется первым.
  String? get tailLabel {
    if (kind == WorkKind.maintenance) {
      final String? started = _timeLabel(startedAt);
      return _joined(<String?>[
        started == null ? null : 'начал $started',
        progress?.label,
      ]);
    }
    final String? day = _dayLabel(startedAt);
    return day == null ? null : 'заявка от $day';
  }

  /// Подпись под исполнителем на широком экране: «ТО-1 · начал 09:30» у ТО,
  /// «заявка от 21 августа» у заявки.
  String? get metaLabel {
    if (kind != WorkKind.maintenance) return tailLabel;
    final String? started = _timeLabel(startedAt);
    return _joined(<String?>[
      _trimmed(title),
      started == null ? null : 'начал $started',
    ]);
  }

  /// Регламент серым рядом с именем механика на телефоне: «· ТО-1».
  String? get titleLabel => _trimmed(title);

  factory InProgressWork.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> object = _asMap(json['object']);
    return InProgressWork(
      kind: _kindFromJson(json['kind']),
      workId: _asInt(json['work_id']) ?? 0,
      state: _stateFromJson(json['state']),
      objectId: _asInt(object['id']),
      objectName: _asString(object['name']),
      objectAddress: _asString(object['address']),
      taskText: _asString(json['task_text']),
      performer: _asString(json['performer']),
      since: _asSecondsTimestamp(json['since']),
      startedAt: _asSecondsTimestamp(json['started_at']),
      reason: _asString(json['reason']),
      title: _asString(json['title']),
      progress: WorkProgress.fromJson(json['progress']),
    );
  }
}

/// Раздел целиком: строки и два числа для заголовка.
///
/// Страниц у ручки нет — одновременно ведут единицы работ, — поэтому список
/// приходит одним куском.
class InProgressWorks {
  const InProgressWorks({required this.items});

  final List<InProgressWork> items;

  bool get isEmpty => items.isEmpty;

  /// Сколько работ идёт. Ручка своего числа пока не отдаёт — оно приезжает
  /// вместе с веткой заявок (этап 8.2). Пока считаем по списку: страниц нет,
  /// и длина списка и есть всё, что идёт. Когда число появится на проводе,
  /// меняется только это место.
  int get total => items.length;

  /// Сколько из них с проблемой — красная пометка в заголовке раздела.
  int get problems =>
      items.where((InProgressWork work) => work.isProblem).length;

  factory InProgressWorks.fromJson(Map<String, dynamic> json) {
    return InProgressWorks(
      items: _asList(json['data'])
          .map(InProgressWork.fromJson)
          .toList(growable: false),
    );
  }
}

WorkKind _kindFromJson(dynamic value) {
  switch (_asString(value)) {
    case 'maintenance':
      return WorkKind.maintenance;
    case 'breakdown':
      return WorkKind.breakdown;
    case 'client_request':
      return WorkKind.clientRequest;
    case 'defect':
      return WorkKind.defect;
    default:
      // Незнакомый вид показываем как заявку, а не прячем строку: работа
      // идёт, и прораб обязан её увидеть, даже если справочник разъехался.
      return WorkKind.request;
  }
}

/// Незнакомое состояние считаем идущей работой: она в этой ленте, значит
/// её ведут. Спрятать строку хуже, чем показать её без паузы.
WorkState _stateFromJson(dynamic value) {
  switch (_asString(value)) {
    case 'paused':
      return WorkState.paused;
    case 'problem':
      return WorkState.problem;
    default:
      return WorkState.running;
  }
}

/// «Пауза · 1 ч 10 мин». Без момента отсчёта — просто слово: пилюля без
/// времени честнее пилюли с нулём.
String _withDuration(String word, DateTime? from) {
  final String? duration = _durationLabel(from);
  return duration == null ? word : '$word · $duration';
}

/// «меньше минуты» → «40 мин» → «1 ч 10 мин» → «2 ч».
///
/// Считается один раз при отрисовке: тикающая пилюля — отдельная работа
/// (этап 8.5).
String? _durationLabel(DateTime? from) {
  if (from == null) return null;
  final Duration passed = DateTime.now().difference(from);
  // Часы механика могут уйти вперёд серверных. Отрицательное «начал через
  // пять минут» показывать нельзя, а работа при этом идёт.
  if (passed.isNegative || passed.inMinutes < 1) return 'меньше минуты';

  final int hours = passed.inHours;
  final int minutes = passed.inMinutes % 60;
  if (hours == 0) return '$minutes мин';
  if (minutes == 0) return '$hours ч';
  return '$hours ч $minutes мин';
}

/// «09:30».
String? _timeLabel(DateTime? at) {
  if (at == null) return null;
  return '${_two(at.hour)}:${_two(at.minute)}';
}

/// «21 августа» — так эту дату называют вслух.
String? _dayLabel(DateTime? at) {
  if (at == null) return null;
  return '${at.day} ${_months[at.month - 1]}';
}

const List<String> _months = <String>[
  'января',
  'февраля',
  'марта',
  'апреля',
  'мая',
  'июня',
  'июля',
  'августа',
  'сентября',
  'октября',
  'ноября',
  'декабря',
];

String _two(int value) => value.toString().padLeft(2, '0');

/// Склеивает куски через « · », пропуская пустые. Без этого строка вида
/// «начал 09:30 · » вылезает у работы без чек-листа.
String? _joined(List<String?> parts) {
  final List<String> kept = parts.whereType<String>().toList(growable: false);
  return kept.isEmpty ? null : kept.join(' · ');
}

String? _trimmed(String? value) {
  final String? text = value?.trim();
  return text == null || text.isEmpty ? null : text;
}

DateTime? _asSecondsTimestamp(dynamic value) {
  final int? seconds = _asInt(value);
  if (seconds == null) return null;
  return DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
}

int? _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

String? _asString(dynamic value) => value is String ? value : null;

Map<String, dynamic> _asMap(dynamic value) {
  if (value is Map) return value.cast<String, dynamic>();
  return <String, dynamic>{};
}

List<Map<String, dynamic>> _asList(dynamic value) {
  if (value is! List) return const <Map<String, dynamic>>[];
  return value
      .whereType<Map>()
      .map((Map item) => item.cast<String, dynamic>())
      .toList(growable: false);
}
