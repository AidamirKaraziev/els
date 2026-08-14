import 'dart:convert';

import 'package:els/helper/api_client.dart';
import 'package:http/http.dart' as http;

import '../../../../helper/api_config.dart';
import '../models/top_employees_report.dart';

/// Ошибка, которую карточка может показать человеку.
///
/// Наружу отдаём короткий текст без кодов и стектрейсов: сообщение уходит
/// прямо в виджет на главной.
class TopEmployeesException implements Exception {
  const TopEmployeesException(this.message);

  final String message;

  @override
  String toString() => message;
}

class TopEmployeesRepository {
  const TopEmployeesRepository({
    this.timeout = const Duration(seconds: 20),
  });

  final Duration timeout;

  /// Рейтинг сотрудников за месяц.
  ///
  /// `minWorks` не передаём: порог активности — договорённость, а не выбор
  /// человека у экрана, и живёт он умолчанием ручки. Здесь он появится, если
  /// когда-нибудь станет настройкой.
  Future<TopEmployeesReport> fetch({
    required int year,
    required int month,
    EmployeeKind kind = EmployeeKind.mechanic,
    EmployeeOrder order = EmployeeOrder.best,
    int limit = 5,
    int offset = 0,
    int? divisionId,
    int? organizationId,
    int? companyId,
  }) async {
    final Map<String, String> query = <String, String>{
      'year': '$year',
      'month': '$month',
      'kind': kind.value,
      'order': order.value,
      'limit': '$limit',
      if (offset > 0) 'offset': '$offset',
      if (divisionId != null) 'division_id': '$divisionId',
      if (organizationId != null) 'organization_id': '$organizationId',
      if (companyId != null) 'company_id': '$companyId',
    };

    final Uri uri = Uri.parse('${ApiConfig.base}/statistics/top-employees')
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
      throw const TopEmployeesException('Не удалось связаться с сервером');
    }

    if (response.statusCode == 403) {
      // Отдельно от 401: рейтинг людей открыт админу и прорабу, и «нет прав»
      // здесь — обычное состояние, а не сломанная сессия.
      throw const TopEmployeesException('Рейтинг сотрудников вам не доступен');
    }
    if (response.statusCode == 401) {
      throw const TopEmployeesException('Истёк вход в систему');
    }
    if (response.statusCode != 200) {
      throw TopEmployeesException(
        'Сервер ответил ошибкой ${response.statusCode}',
      );
    }

    try {
      final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));
      final dynamic data = decoded is Map ? decoded['data'] : null;
      if (data is! Map) {
        throw const TopEmployeesException('Сервер вернул неожиданный ответ');
      }
      return TopEmployeesReport.fromJson(data.cast<String, dynamic>());
    } on TopEmployeesException {
      rethrow;
    } catch (_) {
      throw const TopEmployeesException('Не удалось прочитать ответ сервера');
    }
  }
}
