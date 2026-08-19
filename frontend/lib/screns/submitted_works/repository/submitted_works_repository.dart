import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../helper/api_client.dart';
import '../../../helper/api_config.dart';
import '../models/submitted_work.dart';
import '../unreviewed_counter.dart';

/// Ошибка, которую можно показать человеку.
///
/// Наружу отдаём короткий текст без кодов и стектрейсов: сообщение уходит
/// прямо на экран.
class SubmittedWorksException implements Exception {
  const SubmittedWorksException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Лента сданных работ и отметка «проверил».
///
/// Запросы идут через [Api], а не через `http` напрямую: заголовок с токеном,
/// обновление пары токенов и повтор после `401` живут там.
class SubmittedWorksRepository {
  const SubmittedWorksRepository({this.timeout = const Duration(seconds: 20)});

  final Duration timeout;

  /// Страница ленты. `page` бэкенд режет по 30 строк; без параметра выдача
  /// была бы полной, а её на большом участке качать незачем.
  Future<SubmittedWorksPage> fetch({
    int page = 1,
    bool onlyUnreviewed = false,
  }) async {
    final Uri uri = Uri.parse('${ApiConfig.base}/work/submitted').replace(
      queryParameters: <String, String>{
        'page': '$page',
        if (onlyUnreviewed) 'only_unreviewed': 'true',
      },
    );

    final http.Response response = await _get(uri);
    final Map<String, dynamic> body = _decode(response);
    return SubmittedWorksPage.fromJson(body, page);
  }

  /// Счётчик непросмотренного. Отдельной ручкой, а не длиной ленты: кнопке
  /// меню нужно число, а не тридцать карточек.
  Future<int> unreviewedCount() async {
    final Uri uri = Uri.parse('${ApiConfig.base}/work/submitted/unreviewed-count');
    final int count = _count(_decode(await _get(uri)));
    unreviewedWorksCount.value = count;
    return count;
  }

  /// Отметить работу проверенной. Возвращает счётчик после отметки — его же
  /// кладёт в [unreviewedWorksCount], чтобы кнопка меню обновилась сразу.
  Future<int> markReviewed({
    required WorkKind kind,
    required int workId,
  }) async {
    final Uri uri = Uri.parse(
      '${ApiConfig.base}/work/${kindPathSegment(kind)}/$workId/reviewed/',
    );

    http.Response response;
    try {
      response = await Api.post(
        uri,
        headers: <String, String>{'Accept': 'application/json'},
      ).timeout(timeout);
    } catch (_) {
      throw const SubmittedWorksException('Не удалось связаться с сервером');
    }

    if (response.statusCode == 404) {
      // Работу успели заархивировать или откатить в работу, пока лента
      // висела открытой. Для того, кто смотрит ленту, её там просто нет.
      throw const SubmittedWorksException('Этой работы больше нет в ленте');
    }
    _check(response);

    final int count = _count(_decode(response));
    unreviewedWorksCount.value = count;
    return count;
  }

  Future<http.Response> _get(Uri uri) async {
    try {
      return await Api.get(
        uri,
        headers: <String, String>{'Accept': 'application/json'},
      ).timeout(timeout);
    } catch (_) {
      // Обрыв сети, таймаут и CORS попадают сюда вместе: различать их для
      // человека смысла нет, действие одно — повторить.
      throw const SubmittedWorksException('Не удалось связаться с сервером');
    }
  }

  void _check(http.Response response) {
    if (response.statusCode == 401 || response.statusCode == 403) {
      throw const SubmittedWorksException('Недостаточно прав или истёк вход');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SubmittedWorksException(
        'Сервер ответил ошибкой ${response.statusCode}',
      );
    }
  }

  Map<String, dynamic> _decode(http.Response response) {
    _check(response);
    try {
      final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map) {
        throw const SubmittedWorksException('Сервер вернул неожиданный ответ');
      }
      return decoded.cast<String, dynamic>();
    } on SubmittedWorksException {
      rethrow;
    } catch (_) {
      throw const SubmittedWorksException('Не удалось прочитать ответ сервера');
    }
  }

  int _count(Map<String, dynamic> body) {
    final dynamic data = body['data'];
    final dynamic count = data is Map ? data['count'] : null;
    if (count is num) return count.toInt();
    throw const SubmittedWorksException('Сервер вернул неожиданный ответ');
  }
}
