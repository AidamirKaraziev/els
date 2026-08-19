import 'package:flutter/material.dart';

import '../../../helper/class_colors.dart';

/// Модели ответа `GET /api/v1/work/submitted` — ленты сданных работ.
///
/// Разбираются в типы, а не носятся `Map<String, dynamic>`: почти каждое поле
/// строки законно приходит `null` — заявка без объекта, ТО без задания, работа
/// без исполнителя, — и экран обязан это пережить, а не упасть списком.

/// Вид работы. Значения приходят строками (`WorkKind` на бэкенде).
enum WorkKind { maintenance, breakdown, clientRequest, request, defect }

/// Чем кончился выход: сделали или не смогли.
///
/// Отдельно от вида работы: вид отвечает на «что это было», исход — на
/// «получилось ли». Авария, закрытая проблемой, остаётся аварией.
enum WorkOutcome { done, problem }

/// Одна строка ленты: что и где сдали, кто сдал и смотрел ли это прораб.
class SubmittedWork {
  const SubmittedWork({
    required this.kind,
    required this.workId,
    required this.outcome,
    this.objectId,
    this.objectName,
    this.objectAddress,
    this.taskText,
    this.performer,
    this.closedAt,
    this.reviewedAt,
    this.reviewer,
  });

  final WorkKind kind;

  /// ID акта у ТО и ID заявки у остальных видов. Вместе с [kind] — адрес
  /// работы для отметки «проверил»; поодиночке ни то, ни другое не годится.
  final int workId;

  final WorkOutcome outcome;

  final int? objectId;
  final String? objectName;
  final String? objectAddress;

  /// Что просили сделать. Только у заявок: у ТО задание — это чек-лист акта.
  final String? taskText;

  final String? performer;
  final DateTime? closedAt;

  /// Пусто — работу ещё не смотрели, она и в счётчике.
  final DateTime? reviewedAt;
  final String? reviewer;

  bool get isReviewed => reviewedAt != null;

  bool get isProblem => outcome == WorkOutcome.problem;

  /// Чем подписать объект. Название заполнено не всегда, и «Объект 42» лучше
  /// пустой ячейки: по нему хотя бы понятно, что спрашивать.
  String get objectLabel {
    final String? name = objectName?.trim();
    if (name != null && name.isNotEmpty) return name;
    if (objectId != null) return 'Объект $objectId';
    return 'Объект не указан';
  }

  /// Адрес второй строкой под названием: по «Лифт 12» непонятно, куда ехать.
  String? get addressLabel {
    final String? address = objectAddress?.trim();
    return address == null || address.isEmpty ? null : address;
  }

  String get performerLabel {
    final String? name = performer?.trim();
    return name == null || name.isEmpty ? '—' : name;
  }

  String? get taskLabel {
    final String? text = taskText?.trim();
    return text == null || text.isEmpty ? null : text;
  }

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

  /// Цвет бейджа вида работы. Красным помечается только авария — иначе
  /// «красным» становится вся лента и признак перестаёт значить что-либо.
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

  /// «11.08.2026, 09:30». Время суток нужно: за день на объекте бывает
  /// несколько выходов, и без часов их не различить.
  String get closedLabel => _dateTimeLabel(closedAt) ?? '—';

  /// Подпись под отметкой: «Проверил Иванов, 12.08.2026, 10:15».
  String? get reviewedLabel {
    final String? at = _dateTimeLabel(reviewedAt);
    if (at == null) return null;
    final String? who = reviewer?.trim();
    return who == null || who.isEmpty
        ? 'Проверено $at'
        : 'Проверил $who, $at';
  }

  factory SubmittedWork.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> object = _asMap(json['object']);
    return SubmittedWork(
      kind: _kindFromJson(json['kind']),
      workId: _asInt(json['work_id']) ?? 0,
      outcome: _outcomeFromJson(json['outcome']),
      objectId: _asInt(object['id']),
      objectName: _asString(object['name']),
      objectAddress: _asString(object['address']),
      taskText: _asString(json['task_text']),
      performer: _asString(json['performer']),
      closedAt: _asSecondsTimestamp(json['closed_at']),
      reviewedAt: _asSecondsTimestamp(json['reviewed_at']),
      reviewer: _asString(json['reviewer']),
    );
  }

  /// Копия с проставленной отметкой. Ответ на `POST .../reviewed/` несёт
  /// только новый счётчик, поэтому строку в списке чиним на месте, а не
  /// перезапрашиваем ленту целиком.
  SubmittedWork markedReviewed({required String? by, DateTime? at}) {
    return SubmittedWork(
      kind: kind,
      workId: workId,
      outcome: outcome,
      objectId: objectId,
      objectName: objectName,
      objectAddress: objectAddress,
      taskText: taskText,
      performer: performer,
      closedAt: closedAt,
      reviewedAt: at ?? DateTime.now(),
      reviewer: by,
    );
  }
}

/// Страница ленты: строки и то, что нужно стрелкам листания.
class SubmittedWorksPage {
  const SubmittedWorksPage({
    required this.items,
    required this.page,
    required this.pageCount,
    required this.hasPrev,
    required this.hasNext,
  });

  final List<SubmittedWork> items;

  final int page;

  /// Сколько страниц всего. Общего числа работ бэкенд не отдаёт — паджинатор
  /// считает страницы, — поэтому подпись у стрелок про страницы, а не про
  /// «показаны 6–10 из 23».
  final int pageCount;

  final bool hasPrev;
  final bool hasNext;

  bool get isEmpty => items.isEmpty;

  factory SubmittedWorksPage.fromJson(Map<String, dynamic> json, int page) {
    final Map<String, dynamic> paginator =
        _asMap(_asMap(json['meta'])['paginator']);
    return SubmittedWorksPage(
      items: _asList(json['data'])
          .map(SubmittedWork.fromJson)
          .toList(growable: false),
      page: _asInt(paginator['page']) ?? page,
      pageCount: _asInt(paginator['total']) ?? 1,
      hasPrev: paginator['has_prev'] == true,
      hasNext: paginator['has_next'] == true,
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
      // сдана, и прораб обязан её увидеть, даже если справочник разъехался.
      return WorkKind.request;
  }
}

/// Строку без `outcome` считаем удавшейся работой: поле необязательное и у
/// старых клиентов бэкенда его может не быть вовсе.
WorkOutcome _outcomeFromJson(dynamic value) =>
    _asString(value) == 'problem' ? WorkOutcome.problem : WorkOutcome.done;

/// Адрес работы для отметки «проверил»: `kind` в пути ручки строкой.
String kindPathSegment(WorkKind kind) {
  switch (kind) {
    case WorkKind.maintenance:
      return 'maintenance';
    case WorkKind.breakdown:
      return 'breakdown';
    case WorkKind.clientRequest:
      return 'client_request';
    case WorkKind.request:
      return 'request';
    case WorkKind.defect:
      return 'defect';
  }
}

String? _dateTimeLabel(DateTime? at) {
  if (at == null) return null;
  String two(int value) => value.toString().padLeft(2, '0');
  return '${two(at.day)}.${two(at.month)}.${at.year}, '
      '${two(at.hour)}:${two(at.minute)}';
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
