import 'dart:convert';

import 'package:els/helper/api_client.dart';
import 'package:http/http.dart' as http;

import '../../../../helper/api_config.dart';
import '../models/schedule_execution_report.dart';

/// Ошибка, которую карточка может показать человеку.
///
/// Наружу отдаём короткий текст без кодов и стектрейсов: сообщение уходит
/// прямо в виджет на главной.
class ScheduleExecutionException implements Exception {
  const ScheduleExecutionException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ScheduleExecutionRepository {
  const ScheduleExecutionRepository({this.timeout = const Duration(seconds: 20)});

  final Duration timeout;

  /// Выполнение графика ТО за месяц по участкам.
  ///
  /// Ручка новая; старая `/planned-to/schedule-execution-stats/` жива, но
  /// помечена устаревшей: она теряла ТО, закрытое в следующем месяце.
  Future<ScheduleExecutionReport> fetch({
    required int year,
    required int month,
    int? divisionId,
    int? organizationId,
    int? companyId,
  }) async {
    final Map<String, String> query = <String, String>{
      'year': '$year',
      'month': '$month',
      if (divisionId != null) 'division_id': '$divisionId',
      if (organizationId != null) 'organization_id': '$organizationId',
      if (companyId != null) 'company_id': '$companyId',
    };

    final Uri uri = Uri.parse('${ApiConfig.base}/statistics/schedule-execution')
        .replace(queryParameters: query);

    http.Response response;
    try {
      response = await Api.get(
        uri,
        headers: <String, String>{'Accept': 'application/json'},
      ).timeout(timeout);
    } catch (_) {
      // Обрыв сети, таймаут и CORS попадают сюда вместе: различать их для
      // человека смысла нет, действие одно — повторить.
      throw const ScheduleExecutionException('Не удалось связаться с сервером');
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw const ScheduleExecutionException('Недостаточно прав или истёк вход');
    }
    if (response.statusCode != 200) {
      throw ScheduleExecutionException(
        'Сервер ответил ошибкой ${response.statusCode}',
      );
    }

    try {
      final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));
      final dynamic data = decoded is Map ? decoded['data'] : null;
      if (data is! Map) {
        throw const ScheduleExecutionException('Сервер вернул неожиданный ответ');
      }
      return ScheduleExecutionReport.fromJson(data.cast<String, dynamic>());
    } on ScheduleExecutionException {
      rethrow;
    } catch (_) {
      throw const ScheduleExecutionException('Не удалось прочитать ответ сервера');
    }
  }
}
