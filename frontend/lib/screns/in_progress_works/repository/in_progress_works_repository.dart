import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../helper/api_client.dart';
import '../../../helper/api_config.dart';
import '../models/in_progress_work.dart';

/// Ошибка, которую можно показать человеку.
///
/// Своя, а не общая с лентой сданных: сбой раздела и сбой ленты — разные
/// события на одном экране, и ловить их приходится по отдельности.
class InProgressWorksException implements Exception {
  const InProgressWorksException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Работы, которые механики ведут прямо сейчас.
///
/// Запросы идут через [Api]: заголовок с токеном, обновление пары токенов и
/// повтор после `401` живут там.
class InProgressWorksRepository {
  const InProgressWorksRepository({this.timeout = const Duration(seconds: 20)});

  final Duration timeout;

  /// Весь раздел одним запросом. Страниц у ручки нет: одновременно ведут
  /// единицы работ, и резать такой список было бы нечего.
  Future<InProgressWorks> fetch() async {
    final Uri uri = Uri.parse('${ApiConfig.base}/work/in-progress');

    http.Response response;
    try {
      response = await Api.get(
        uri,
        headers: <String, String>{'Accept': 'application/json'},
      ).timeout(timeout);
    } catch (_) {
      // Обрыв сети, таймаут и CORS попадают сюда вместе: различать их для
      // человека смысла нет, действие одно — повторить.
      throw const InProgressWorksException('Не удалось загрузить');
    }

    return InProgressWorks.fromJson(_decode(response));
  }

  void _check(http.Response response) {
    if (response.statusCode == 401 || response.statusCode == 403) {
      throw const InProgressWorksException('Недостаточно прав или истёк вход');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw InProgressWorksException(
        'Сервер ответил ошибкой ${response.statusCode}',
      );
    }
  }

  Map<String, dynamic> _decode(http.Response response) {
    _check(response);
    try {
      final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map) {
        throw const InProgressWorksException('Сервер вернул неожиданный ответ');
      }
      return decoded.cast<String, dynamic>();
    } on InProgressWorksException {
      rethrow;
    } catch (_) {
      throw const InProgressWorksException('Не удалось прочитать ответ сервера');
    }
  }
}
