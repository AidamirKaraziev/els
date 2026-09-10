import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../helper/api_config.dart';
import '../models/breakdowns_report.dart';
import 'package:els/helper/api_client.dart';

/// Ошибка, которую виджет может показать человеку.
///
/// Наружу отдаём короткий текст без кодов и стектрейсов: сообщение уходит
/// прямо в карточку на главной.
class BreakdownsException implements Exception {
  const BreakdownsException(this.message);

  final String message;

  @override
  String toString() => message;
}

class BreakdownsRepository {
  const BreakdownsRepository({this.timeout = const Duration(seconds: 20)});

  final Duration timeout;

  /// Топ поломок за месяц.
  ///
  /// [limit] по умолчанию пять — столько строк помещается в карточку.
  Future<BreakdownsReport> fetch({
    required int year,
    required int month,
    int limit = 5,
    int offset = 0,
    int? divisionId,
    int? organizationId,
    int? companyId,
    bool withPrevious = false,
  }) async {
    final Map<String, String> query = <String, String>{
      'year': '$year',
      'month': '$month',
      'limit': '$limit',
      'offset': '$offset',
      if (withPrevious) 'with_previous': 'true',
      if (divisionId != null) 'division_id': '$divisionId',
      if (organizationId != null) 'organization_id': '$organizationId',
      if (companyId != null) 'company_id': '$companyId',
    };

    final Uri uri = Uri.parse('${ApiConfig.base}/statistics/breakdowns')
        .replace(queryParameters: query);

    http.Response response;
    try {
      response = await Api.get(
        uri,
        headers: <String, String>{
          'Accept': 'application/json',
        },
      ).timeout(timeout);
    } catch (_) {
      // Сюда попадают обрыв сети, таймаут и CORS. Различать их для человека
      // смысла нет: действие одно — повторить.
      throw const BreakdownsException('Не удалось связаться с сервером');
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw const BreakdownsException('Недостаточно прав или истёк вход');
    }
    if (response.statusCode != 200) {
      throw BreakdownsException('Сервер ответил ошибкой ${response.statusCode}');
    }

    try {
      final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));
      final dynamic data = decoded is Map ? decoded['data'] : null;
      if (data is! Map) {
        throw const BreakdownsException('Сервер вернул неожиданный ответ');
      }
      return BreakdownsReport.fromJson(data.cast<String, dynamic>());
    } on BreakdownsException {
      rethrow;
    } catch (_) {
      throw const BreakdownsException('Не удалось прочитать ответ сервера');
    }
  }

  /// Заявки одного объекта за месяц — то, что открывается кликом по строке.
  ///
  /// `only_breakdowns` обязателен: без него список покажет ещё и плановые ТО,
  /// и длина не сойдётся со счётчиком в строке. Человек решит, что виджет врёт.
  Future<List<BreakdownOrder>> fetchObjectOrders({
    required int objectId,
    required int year,
    required int month,
  }) async {
    final dynamic data = await _get(
      '/order/all',
      <String, String>{
        'object_id': '$objectId',
        'year': '$year',
        'month': '$month',
        'only_breakdowns': 'true',
        'page': '1',
      },
    );
    if (data is! List) return const <BreakdownOrder>[];
    return data
        .whereType<Map>()
        .map((Map row) => BreakdownOrder.fromJson(row.cast<String, dynamic>()))
        .toList(growable: false);
  }

  /// Адрес выгрузки отчёта в PDF.
  ///
  /// Файл собирает бэкенд — тем же кодом, что считает отчёт на экране, иначе
  /// цифры в отправленном заказчику файле однажды разошлись бы с виджетом.
  ///
  /// Прямо к ручке выгрузки обратиться нельзя: ей нужен заголовок
  /// `Authorization`, а новая вкладка его не отправит — придёт 403. Поэтому
  /// сервер подписывает короткоживущую ссылку, а ключ выгрузки берётся из
  /// закрытого списка на бэкенде: подставить свой адрес клиент не может.
  ///
  /// Ссылка живёт минуту. Открывать её надо сразу.
  Future<String> exportLink({
    required int year,
    required int month,
    int? divisionId,
    int? organizationId,
  }) async {
    http.Response response;
    try {
      response = await Api.post(
        Uri.parse('${ApiConfig.base}/files/export-link'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=utf-8',
          'Accept': 'application/json',
        },
        body: jsonEncode(<String, dynamic>{
          'export': 'breakdowns',
          'params': <String, String>{
            'year': '$year',
            'month': '$month',
            if (divisionId != null) 'division_id': '$divisionId',
            if (organizationId != null) 'organization_id': '$organizationId',
          },
        }),
      ).timeout(timeout);
    } catch (_) {
      throw const BreakdownsException('Не удалось связаться с сервером');
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw const BreakdownsException('Недостаточно прав или истёк вход');
    }
    if (response.statusCode != 200) {
      throw BreakdownsException(
        'Сервер ответил ошибкой ${response.statusCode}',
      );
    }

    final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));
    final dynamic data = decoded is Map ? decoded['data'] : null;
    final Object? url = data is Map ? data['url'] : null;
    if (url is! String || url.isEmpty) {
      throw const BreakdownsException('Сервер не вернул ссылку на файл');
    }

    // Адрес приходит без схемы, см. `ApiConfig.withScheme`.
    return ApiConfig.withScheme(url);
  }

  /// Справочник участков для фильтра.
  Future<List<NamedRef>> fetchDivisions() async {
    return NamedRef.listFrom(
      await _get('/divisions/', <String, String>{'page': '1'}),
      <String>['title', 'name'],
    );
  }

  /// Справочник организаций (клиентов) для фильтра.
  Future<List<NamedRef>> fetchOrganizations() async {
    return NamedRef.listFrom(
      await _get('/all-organization/', <String, String>{'page': '1'}),
      <String>['title', 'name'],
    );
  }

  /// Общая часть GET-запроса: заголовки, таймаут, разбор конверта ответа.
  Future<dynamic> _get(String path, Map<String, String> query) async {
    final Uri uri =
        Uri.parse('${ApiConfig.base}$path').replace(queryParameters: query);

    http.Response response;
    try {
      response = await Api.get(
        uri,
        headers: <String, String>{
          'Accept': 'application/json',
        },
      ).timeout(timeout);
    } catch (_) {
      throw const BreakdownsException('Не удалось связаться с сервером');
    }

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw const BreakdownsException('Недостаточно прав или истёк вход');
    }
    if (response.statusCode != 200) {
      throw BreakdownsException('Сервер ответил ошибкой ${response.statusCode}');
    }

    try {
      final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));
      return decoded is Map ? decoded['data'] : null;
    } catch (_) {
      throw const BreakdownsException('Не удалось прочитать ответ сервера');
    }
  }
}
