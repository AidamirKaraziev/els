/// Разбор ответов бэкенда: конверт удачи и конверт ошибки.
///
/// Всё API отвечает одной формой — `{"data": …, "message": …}` при удаче и
/// `{"message": "Error", "errors": [{"code": 144, "message": …}],
/// "description": …}` при ошибке (`backend/src/errors.py`). Разбирать её в
/// каждом репозитории значило бы держать две копии одного знания: первая же
/// правка формы на бэкенде расходится, и один экран показывает человеку
/// причину, а соседний — «Сервер ответил ошибкой 422».
library;

import 'dart:convert';

import 'package:http/http.dart' as http;

import 'schedules_repository.dart';

/// Тело удачного ответа целиком, вместе с конвертом.
///
/// Само поле `data` не достаём: у одних ручек там объект, у других список, и
/// проверку типа всё равно делает вызывающий — ему же и сообщать, что именно
/// он ждал.
Map<String, dynamic> decodeEnvelope(http.Response response) {
  try {
    final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! Map) {
      throw const SchedulesException('Сервер вернул неожиданный ответ');
    }
    return decoded.cast<String, dynamic>();
  } on SchedulesException {
    rethrow;
  } catch (_) {
    throw const SchedulesException('Не удалось прочитать ответ сервера');
  }
}

/// Текст неудачи для человека.
///
/// У 422 сервер объясняет причину словами — «нет шаблона чек-листа на ТО 6»,
/// «укажите месяц, с которого начинается цикл», — и как раз это человеку и
/// нужно: по такому тексту он знает, что чинить.
String errorText(http.Response response) {
  if (response.statusCode == 401 || response.statusCode == 403) {
    return 'Недостаточно прав или истёк вход';
  }

  final String? explained = _explanation(response);
  if (explained != null) return explained;

  return 'Сервер ответил ошибкой ${response.statusCode}';
}

/// Номер ошибки из конверта — тот самый `num`, с которым её завели на бэкенде.
///
/// Нужен там, где по коду различается ветка работы, а не только текст: 144 —
/// «якорь цикла не восстановился», и мастер расстановки отвечает на неё
/// вопросом человеку, а не плашкой с ошибкой.
int? errorCode(http.Response response) {
  final Map<String, dynamic>? first = _firstError(response);
  final dynamic code = first?['code'];
  return asInt(code);
}

/// Причина словами: сперва конверт ошибок, потом привычные FastAPI-формы.
///
/// Порядок не случаен. `message` верхнего уровня в конверте ошибки — всегда
/// литерал «Error», и читать его первым значит показать человеку это слово
/// вместо объяснения.
String? _explanation(http.Response response) {
  final Map<String, dynamic>? first = _firstError(response);
  final String? fromErrors = asString(first?['message']);
  if (fromErrors != null) return fromErrors;

  final Map<String, dynamic>? body = _tryDecode(response);
  if (body == null) return null;

  final String? description = asString(body['description']);
  if (description != null) return description;

  final dynamic detail = body['detail'];
  if (detail is String) return asString(detail);
  // FastAPI умеет отдавать список ошибок валидации; человеку хватит первой —
  // вторая про то же тело запроса.
  if (detail is List && detail.isNotEmpty) {
    final dynamic item = detail.first;
    if (item is Map) return asString(item['msg']);
  }
  return null;
}

Map<String, dynamic>? _firstError(http.Response response) {
  final Map<String, dynamic>? body = _tryDecode(response);
  final dynamic errors = body?['errors'];
  if (errors is! List || errors.isEmpty) return null;
  final dynamic first = errors.first;
  return first is Map ? first.cast<String, dynamic>() : null;
}

/// Разбор тела там, где нечитаемое тело — не повод для новой ошибки: текст
/// неудачи и так найдётся по коду ответа.
Map<String, dynamic>? _tryDecode(http.Response response) {
  try {
    final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));
    return decoded is Map ? decoded.cast<String, dynamic>() : null;
  } catch (_) {
    return null;
  }
}

/// Вложенное поле, если родитель вообще объект.
dynamic nested(dynamic value, String key) => value is Map ? value[key] : null;

int? asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

/// Строка без пустых: пустое поле в ответе и отсутствующее — для экрана одно
/// и то же, и различать их прочерком в каждом виджете незачем.
String? asString(dynamic value) {
  if (value is String && value.trim().isNotEmpty) return value.trim();
  return null;
}
