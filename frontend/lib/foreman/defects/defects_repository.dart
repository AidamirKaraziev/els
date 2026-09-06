/// Запросы за дефектными актами объекта.
///
/// Идут через `helper/api_client.dart`, а не голым `http`: клиент сам
/// подставляет `Authorization`, обновляет протухший access и повторяет
/// запрос. Экранам прораба, унаследованным от подрядчика, токен подставлялся
/// руками из `IntTest.token` в каждом месте — повторять это здесь незачем.
library;

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../helper/api_client.dart';
import '../../helper/api_config.dart';
import 'defect_entry.dart';

/// Путь файла в том виде, в каком его ждёт `POST /files/link`.
///
/// Бэкенд отдаёт `pdf_file` адресом (`host:port/api/v1/static/defective_act/…`,
/// см. `getters/static_url.py`), а ручка ссылки принимает путь относительно
/// каталога загрузок и по нему же считает владельца файла
/// (`core/files.parse_owner`). Отправить туда полный адрес значит получить
/// «такого файла нет»: разбор увидит `host:port` вместо сущности.
String staticPathOf(String raw) {
  const String marker = '/api/v1/static/';
  final int at = raw.indexOf(marker);
  if (at >= 0) return raw.substring(at + marker.length);
  // Уже относительный путь: так приходит от сервера без запроса и так удобнее
  // в тестах. Ведущий слэш ручка срезает сама, но лишним не будет.
  return raw.startsWith('/') ? raw.substring(1) : raw;
}

class DefectsRepository {
  const DefectsRepository();

  /// Лента объекта за год. Год обязателен — ручка без него не отвечает.
  Future<List<DefectEntry>> byObjectAndYear({
    required int objectId,
    required int year,
  }) async {
    final Uri url = Uri.parse(
      '${ApiConfig.base}/defective-act/by-object/$objectId/?year=$year',
    );
    final http.Response response = await Api.get(url);
    final List<dynamic> rows = _list(response);
    return rows
        .whereType<Map<dynamic, dynamic>>()
        .map((Map<dynamic, dynamic> row) =>
            DefectEntry.fromJson(Map<String, dynamic>.from(row)))
        .toList();
  }

  /// Дефекты, заведённые на одной работе по ТО, — для блока в её карточке.
  ///
  /// Отдельной ручкой, а не выборкой из ленты объекта: карточка работы не
  /// знает ни года ленты, ни объекта, а тянуть все акты объекта ради двух
  /// строк — лишний трафик.
  Future<List<DefectEntry>> byActFact(int actFactId) async {
    final Uri url = Uri.parse(
      '${ApiConfig.base}/defective-act/by-act-fact/$actFactId/',
    );
    final http.Response response = await Api.get(url);
    final List<dynamic> rows = _list(response);
    return rows
        .whereType<Map<dynamic, dynamic>>()
        .map((Map<dynamic, dynamic> row) =>
            DefectEntry.fromJson(Map<String, dynamic>.from(row)))
        .toList();
  }

  /// Сколько дефектных актов у объекта за год — для значка-счётчика.
  ///
  /// Отдельной ручкой, а не длиной ленты: считает она ровно тот же запрос
  /// (`kind = internal`, год создания), но не тащит через сеть акты со
  /// снимками ради одного числа.
  Future<int> countByObjectAndYear({
    required int objectId,
    required int year,
  }) async {
    final Uri url = Uri.parse(
      '${ApiConfig.base}/defective-act/by-object/$objectId/count/?year=$year',
    );
    final http.Response response = await Api.get(url);
    final Object? data = _data(response);
    if (data is! int) throw const FormatException('Ответ без числа');
    return data;
  }

  /// Полный акт: описание и снимки, которых в строке списка нет.
  Future<DefectEntry> byId(int id) async {
    final Uri url = Uri.parse('${ApiConfig.base}/defective-act/$id/');
    final http.Response response = await Api.get(url);
    return DefectEntry.fromJson(_single(response));
  }

  /// Оформить акт клиенту. Возвращается **потомок**, а не первоисточник:
  /// сервер заводит отдельную запись, а родителю только меняет состояние.
  ///
  /// Повторный вызов заводит ещё один клиентский акт — так и задумано: акт
  /// мог уйти клиенту дважды, с разным набором фото.
  Future<DefectEntry> issueToClient(int id, Map<String, dynamic> body) async {
    final Uri url = Uri.parse(
      '${ApiConfig.base}/defective-act/$id/issue-to-client/',
    );
    final http.Response response = await Api.post(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=utf-8',
        'Accept': 'application/json',
      },
      body: jsonEncode(body),
    );
    return DefectEntry.fromJson(_single(response));
  }

  /// Собрать PDF. Отдельным запросом, а не побочным действием выпуска: файл
  /// пересобирается и для внутреннего акта, и для клиентского.
  Future<DefectEntry> generatePdf(int id) async {
    final Uri url = Uri.parse('${ApiConfig.base}/defective-act/$id/pdf/');
    final http.Response response = await Api.post(url);
    return DefectEntry.fromJson(_single(response));
  }

  /// Короткоживущая ссылка на файл — её можно открыть в новой вкладке.
  ///
  /// Прямо к `/api/v1/static/…` обратиться нельзя: статике нужен заголовок
  /// `Authorization`, а новая вкладка его не отправит. Тот же приём, что у
  /// выгрузки топа поломок (`screns/home/top_breakdowns`).
  Future<String> downloadLink(String pdfPath) async {
    final Uri url = Uri.parse('${ApiConfig.base}/files/link');
    final http.Response response = await Api.post(
      url,
      headers: <String, String>{
        'Content-Type': 'application/json; charset=utf-8',
        'Accept': 'application/json',
      },
      body: jsonEncode(<String, String>{'path': staticPathOf(pdfPath)}),
    );
    final Map<String, dynamic> data = _single(response);
    final Object? link = data['url'];
    if (link == null) throw const FormatException('Ответ без ссылки');
    return link.toString();
  }

  List<dynamic> _list(http.Response response) {
    final Object? data = _data(response);
    if (data is! List) return const <dynamic>[];
    return data;
  }

  Map<String, dynamic> _single(http.Response response) {
    final Object? data = _data(response);
    if (data is! Map) {
      throw const FormatException('Ответ без записи акта');
    }
    return Map<String, dynamic>.from(data);
  }

  /// Тело ответа у этого API всегда обёрнуто: `{message, errors, data}`.
  /// Ошибку разбираем через `ApiError`, чтобы на экран попал текст бэкенда,
  /// а не «Exception: 403».
  Object? _data(http.Response response) {
    if (response.statusCode != 200) {
      throw Exception(ApiError.messageOf(response));
    }
    final Object? body = jsonDecode(utf8.decode(response.bodyBytes));
    if (body is! Map) {
      throw const FormatException('Ответ не разобран');
    }
    return body['data'];
  }
}
