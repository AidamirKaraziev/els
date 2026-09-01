import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../helper/api_client.dart';
import '../../../../helper/api_config.dart';
import '../../models/month_cell.dart';
import '../../repository/schedules_repository.dart';
import '../models/schedule_object_card.dart';
import '../models/schedule_responsible.dart';
import 'schedule_object_repository.dart';

/// Тот же интерфейс, что у фикстуры, но поверх боевых ручек.
///
/// Запросы идут через [Api]: заголовок с токеном, обновление пары токенов и
/// повтор после `401` живут там, и второго такого места в проекте быть не
/// должно.
///
/// **Лента берётся из `/schedules/rows`, а не из `/planned-to/by-object/`.**
/// Состояние клетки — «выполнено», «выполнено поздно», «просрочено» — считает
/// сервер: `overdue` отличается от `pending` только тем, кончился ли плановый
/// месяц, и по часам браузера эта граница едет. Ручка графика отдаёт сырые
/// акты, и разбирать их здесь значило бы завести вторую арифметику состояний.
class ApiScheduleObjectRepository implements ScheduleObjectRepository {
  ApiScheduleObjectRepository({
    this.timeout = const Duration(seconds: 20),
    Future<http.Response> Function(Uri uri)? send,
    Future<http.Response> Function(Uri uri, String body)? sendPost,
  })  : _send = send ?? _getViaApi,
        _sendPost = sendPost ?? _postViaApi;

  final Duration timeout;

  /// Как уходят запросы. Подменяются только в тестах: разбор ответа — это
  /// половина смысла класса, а проверить его иначе, чем подставив готовый
  /// ответ, нельзя.
  final Future<http.Response> Function(Uri uri) _send;
  final Future<http.Response> Function(Uri uri, String body) _sendPost;

  static Future<http.Response> _getViaApi(Uri uri) =>
      Api.get(uri, headers: <String, String>{'Accept': 'application/json'});

  static Future<http.Response> _postViaApi(Uri uri, String body) => Api.post(
        uri,
        headers: <String, String>{
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: body,
      );

  @override
  Future<ScheduleObjectCard> fetchCard(int objectId) async {
    final Map<String, dynamic> body =
        await _request('/object/$objectId/', const <String, String>{});

    final dynamic data = body['data'];
    if (data is! Map) {
      throw const SchedulesException('Сервер вернул неожиданный ответ');
    }
    final Map<String, dynamic> object = data.cast<String, dynamic>();

    return ScheduleObjectCard(
      id: _asInt(object['id']) ?? objectId,
      // Организация у объекта — голый `id`, названия в ответе нет. Ходим за
      // ним отдельно и молча: не ответило — в строке прочерк, а весь экран
      // из-за названия организации падать не должен.
      organization: await _organizationName(object['organization_id']),
      division: _asString(_nested(object['division_id'], 'title')),
      address: _asString(object['address']),
      type: _asString(
        _nested(_nested(object['factory_model_id'], 'type_object_id'), 'name'),
      ),
      model: _asString(_nested(object['factory_model_id'], 'model')),
      registrationNumber: _asString(object['registration_number']),
      factoryNumber: _asString(object['factory_number']),
      company: _asString(_nested(object['company_id'], 'name')),
      contactPerson: _asString(_nested(object['contact_person_id'], 'name')),
      contactPhone: _asString(_nested(object['contact_person_id'], 'phone')),
      contract: _asString(_nested(object['contract_id'], 'title')),
      geo: ScheduleGeoPoint.tryParse(_asString(object['geo'])),
      foreman: _responsible('Прораб', object['foreman_id']),
      mechanic: _responsible('Механик', object['mechanic_id']),
    );
  }

  @override
  Future<List<MonthCell>> fetchYear(int objectId, int year) async {
    final Map<String, dynamic> body = await _request(
      '/schedules/rows',
      <String, String>{'object_id': '$objectId', 'year': '$year'},
    );

    final dynamic data = body['data'];
    if (data is! List) {
      throw const SchedulesException('Сервер вернул неожиданный ответ');
    }
    if (data.isEmpty) {
      // Объекта в выдаче нет — например, он вне области видимости. Лента
      // пустая, а не сломанная: спорить об этом на экране графика не о чем.
      return _emptyYear();
    }

    final dynamic first = data.first;
    if (first is! Map) {
      throw const SchedulesException('Сервер вернул неожиданный ответ');
    }
    return _cells(first.cast<String, dynamic>()['cells']);
  }

  @override
  Future<void> generateYear(int objectId, int year) async {
    final Uri uri = Uri.parse('${ApiConfig.base}/planned-to/generate/');
    final String body = jsonEncode(<String, dynamic>{
      'object_id': objectId,
      'year': year,
      // `anchor_month` не шлём: сервер подбирает его по прошлому году, а не
      // подобрал — отвечает 422 и просит назвать месяц. Мастер с выбором
      // месяца — отдельная задача.
    });

    http.Response response;
    try {
      response = await _sendPost(uri, body).timeout(timeout);
    } catch (_) {
      throw const SchedulesException('Не удалось связаться с сервером');
    }

    if (response.statusCode == 200 || response.statusCode == 201) {
      return;
    }
    throw SchedulesException(_errorText(response));
  }

  /// Название организации по её `id`. Неудача — не ошибка экрана.
  Future<String?> _organizationName(dynamic organizationId) async {
    final int? id = _asInt(organizationId);
    if (id == null) return null;
    try {
      final Map<String, dynamic> body =
          await _request('/organization/$id/', const <String, String>{});
      final dynamic data = body['data'];
      return data is Map ? _asString(data['name']) : null;
    } catch (_) {
      return null;
    }
  }

  ScheduleResponsible? _responsible(String title, dynamic value) {
    final String? name = _asString(_nested(value, 'name'));
    if (name == null) return null;
    return ScheduleResponsible(
      title: title,
      fullName: name,
      photo: _asString(_nested(value, 'photo')),
    );
  }

  List<MonthCell> _cells(dynamic value) {
    if (value is! List) return _emptyYear();

    final Map<int, MonthCell> byMonth = <int, MonthCell>{};
    for (final dynamic item in value) {
      if (item is! Map) continue;
      final MonthCell cell = MonthCell.fromJson(item.cast<String, dynamic>());
      byMonth[cell.month] = cell;
    }

    // Двенадцать клеток всегда: недостающий месяц — пустой. Виджету не
    // приходится проверять длину, а лента не разъезжается.
    return <MonthCell>[
      for (int month = 1; month <= 12; month++)
        byMonth[month] ?? MonthCell.empty(month),
    ];
  }

  List<MonthCell> _emptyYear() =>
      <MonthCell>[for (int month = 1; month <= 12; month++) MonthCell.empty(month)];

  /// Запрос и разбор конверта. Ошибки — одним текстом без кодов и стектрейсов:
  /// он уходит прямо в плашку на экране.
  Future<Map<String, dynamic>> _request(
    String path,
    Map<String, String> query,
  ) async {
    final Uri uri = Uri.parse('${ApiConfig.base}$path')
        .replace(queryParameters: query.isEmpty ? null : query);

    http.Response response;
    try {
      response = await _send(uri).timeout(timeout);
    } catch (_) {
      // Обрыв сети, таймаут и CORS попадают сюда вместе: различать их для
      // человека смысла нет, действие одно — повторить.
      throw const SchedulesException('Не удалось связаться с сервером');
    }

    if (response.statusCode != 200) {
      throw SchedulesException(_errorText(response));
    }

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
  /// У 422 сервер объясняет причину словами — «нет шаблона чек-листа на
  /// ТО 6», «месяц начала цикла подобрать не удалось», — и как раз это
  /// человеку и нужно: по такому тексту он знает, что чинить.
  String _errorText(http.Response response) {
    if (response.statusCode == 401 || response.statusCode == 403) {
      return 'Недостаточно прав или истёк вход';
    }

    final String? detail = _detail(response);
    if (detail != null) return detail;

    return 'Сервер ответил ошибкой ${response.statusCode}';
  }

  String? _detail(http.Response response) {
    try {
      final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map) return null;
      final dynamic detail = decoded['detail'] ?? decoded['message'];
      if (detail is String && detail.trim().isNotEmpty) return detail.trim();
      // FastAPI умеет отдавать список ошибок валидации; человеку хватит
      // первой — вторая про то же тело запроса.
      if (detail is List && detail.isNotEmpty) {
        final dynamic first = detail.first;
        if (first is Map && first['msg'] is String) return first['msg'] as String;
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}

dynamic _nested(dynamic value, String key) =>
    value is Map ? value[key] : null;

int? _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

String? _asString(dynamic value) {
  if (value is String && value.trim().isNotEmpty) return value.trim();
  return null;
}
