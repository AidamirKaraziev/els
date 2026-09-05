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

  /// Полный акт: описание и снимки, которых в строке списка нет.
  Future<DefectEntry> byId(int id) async {
    final Uri url = Uri.parse('${ApiConfig.base}/defective-act/$id/');
    final http.Response response = await Api.get(url);
    return DefectEntry.fromJson(_single(response));
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
