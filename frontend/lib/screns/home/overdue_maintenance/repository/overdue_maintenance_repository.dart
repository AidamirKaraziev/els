import 'dart:convert';

import 'package:els/helper/api_client.dart';
import 'package:http/http.dart' as http;

import '../../../../helper/api_config.dart';
import '../models/overdue_maintenance_report.dart';

/// Ошибка, которую карточка может показать человеку.
///
/// Наружу отдаём короткий текст без кодов и стектрейсов: сообщение уходит
/// прямо в виджет на главной.
class OverdueMaintenanceException implements Exception {
  const OverdueMaintenanceException(this.message);

  final String message;

  @override
  String toString() => message;
}

class OverdueMaintenanceRepository {
  const OverdueMaintenanceRepository({
    this.timeout = const Duration(seconds: 20),
  });

  final Duration timeout;

  /// Просроченные ТО на сегодня.
  ///
  /// Месяца в параметрах нет намеренно: просрочка — состояние на сегодня, а
  /// не срез периода, и текущий месяц ручка берёт из своих часов.
  Future<OverdueMaintenanceReport> fetch({
    int limit = 5,
    int offset = 0,
    int? divisionId,
    int? organizationId,
    int? companyId,
  }) async {
    final Map<String, String> query = <String, String>{
      'limit': '$limit',
      if (offset > 0) 'offset': '$offset',
      if (divisionId != null) 'division_id': '$divisionId',
      if (organizationId != null) 'organization_id': '$organizationId',
      if (companyId != null) 'company_id': '$companyId',
    };

    final Uri uri = Uri.parse('${ApiConfig.base}/statistics/overdue-maintenance')
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
      throw const OverdueMaintenanceException('Не удалось связаться с сервером');
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw const OverdueMaintenanceException(
        'Недостаточно прав или истёк вход',
      );
    }
    if (response.statusCode != 200) {
      throw OverdueMaintenanceException(
        'Сервер ответил ошибкой ${response.statusCode}',
      );
    }

    try {
      final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));
      final dynamic data = decoded is Map ? decoded['data'] : null;
      if (data is! Map) {
        throw const OverdueMaintenanceException(
          'Сервер вернул неожиданный ответ',
        );
      }
      return OverdueMaintenanceReport.fromJson(data.cast<String, dynamic>());
    } on OverdueMaintenanceException {
      rethrow;
    } catch (_) {
      throw const OverdueMaintenanceException(
        'Не удалось прочитать ответ сервера',
      );
    }
  }
}
