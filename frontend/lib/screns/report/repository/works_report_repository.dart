import 'dart:convert';

import 'package:els/helper/api_client.dart';
import 'package:http/http.dart' as http;

import '../../../helper/api_config.dart';
import '../models/object_works.dart';
import '../models/works_report.dart';

/// Ошибка, которую экран может показать человеку.
///
/// Наружу отдаём короткий текст без кодов и стектрейсов: сообщение уходит
/// прямо в интерфейс.
class WorksReportException implements Exception {
  const WorksReportException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Отбор объектов отчёта.
///
/// Отдельным типом, а не пятью параметрами в каждом вызове: тот же набор
/// уходит и в запрос отчёта, и в ссылку на выгрузку, и разъехаться они не
/// должны — иначе человек скачает файл не по тому отбору, что видит.
class ReportFilters {
  const ReportFilters({
    required this.dateFrom,
    required this.dateTo,
    this.divisionId,
    this.organizationId,
    this.companyId,
    this.objectId,
  });

  final DateTime dateFrom;
  final DateTime dateTo;
  final int? divisionId;
  final int? organizationId;
  final int? companyId;
  final int? objectId;

  ReportFilters copyWith({
    DateTime? dateFrom,
    DateTime? dateTo,
    int? divisionId,
    int? organizationId,
    int? companyId,
    int? objectId,
    bool clearDivision = false,
    bool clearOrganization = false,
    bool clearCompany = false,
    bool clearObject = false,
  }) {
    return ReportFilters(
      dateFrom: dateFrom ?? this.dateFrom,
      dateTo: dateTo ?? this.dateTo,
      divisionId: clearDivision ? null : divisionId ?? this.divisionId,
      organizationId:
          clearOrganization ? null : organizationId ?? this.organizationId,
      companyId: clearCompany ? null : companyId ?? this.companyId,
      objectId: clearObject ? null : objectId ?? this.objectId,
    );
  }

  static String _date(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';

  Map<String, String> toQuery() => <String, String>{
        'date_from': _date(dateFrom),
        'date_to': _date(dateTo),
        if (divisionId != null) 'division_id': '$divisionId',
        if (organizationId != null) 'organization_id': '$organizationId',
        if (companyId != null) 'company_id': '$companyId',
        if (objectId != null) 'object_id': '$objectId',
      };
}

class WorksReportRepository {
  const WorksReportRepository({this.timeout = const Duration(seconds: 30)});

  /// Тридцать секунд, а не двадцать как у виджетов главной: отчёт за год по
  /// сотне лифтов считается заметно дольше карточки.
  final Duration timeout;

  Future<WorksReport> fetch({
    required ReportFilters filters,
    int limit = 25,
    int offset = 0,
  }) async {
    final Map<String, String> query = <String, String>{
      ...filters.toQuery(),
      'limit': '$limit',
      if (offset > 0) 'offset': '$offset',
    };

    final Uri uri = Uri.parse('${ApiConfig.base}/reports/works')
        .replace(queryParameters: query);

    final http.Response response = await _get(uri);
    return WorksReport.fromJson(_decode(response));
  }

  /// Все работы одного объекта за период — уровни 2 и 3.
  ///
  /// Отдельным запросом, а не в общем отчёте: на сотне лифтов за год
  /// чек-листы всех актов — это мегабайты, которые экран покажет только по
  /// клику на строку.
  Future<ObjectWorksReport> fetchObjectWorks({
    required int objectId,
    required ReportFilters filters,
  }) async {
    final Uri uri = Uri.parse('${ApiConfig.base}/reports/object/$objectId/works')
        .replace(queryParameters: filters.toQuery());

    final http.Response response = await _get(uri);
    return ObjectWorksReport.fromJson(_decode(response));
  }

  /// Адрес выгрузки, который можно открыть в новой вкладке.
  ///
  /// Прямо к ручке выгрузки обратиться нельзя: ей нужен заголовок
  /// `Authorization`, а новая вкладка его не отправит. Поэтому сервер
  /// подписывает короткоживущую ссылку, а ключ выгрузки берётся из закрытого
  /// списка на бэкенде — подставить свой адрес клиент не может.
  Future<String> exportUrl({
    required ReportFilters filters,
    required String format,
    bool withPhotos = false,
  }) async {
    final Uri uri = Uri.parse('${ApiConfig.base}/files/export-link');

    http.Response response;
    try {
      response = await Api.post(
        uri,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=utf-8',
          'Accept': 'application/json',
        },
        body: jsonEncode(<String, dynamic>{
          'export': 'works',
          'params': <String, String>{
            ...filters.toQuery(),
            'format': format,
            if (withPhotos) 'with_photos': 'true',
          },
        }),
      ).timeout(timeout);
    } catch (_) {
      throw const WorksReportException('Не удалось связаться с сервером');
    }

    final Map<String, dynamic> data = _decode(response);
    final Object? url = data['url'];
    if (url is! String || url.isEmpty) {
      throw const WorksReportException('Сервер не вернул ссылку на файл');
    }

    // Бэкенд отдаёт адрес **без схемы** — `els23.ru/api/v1/…`, ровно как
    // ссылки на фото и сканы. Схему дописывает клиент: на вебе берётся схема
    // открытой страницы, см. `ApiConfig.scheme` и `helper/api_image.dart`.
    //
    // Без этого браузер считает адрес относительным и приклеивает его к
    // текущему пути: получается `https://els23.ru/els23.ru/api/v1/…`, и
    // скачивание молча не работает.
    if (url.contains('://')) return url;
    return '${ApiConfig.scheme}://$url';
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
      throw const WorksReportException('Не удалось связаться с сервером');
    }
  }

  Map<String, dynamic> _decode(http.Response response) {
    if (response.statusCode == 401 || response.statusCode == 403) {
      throw const WorksReportException('Недостаточно прав или истёк вход');
    }
    if (response.statusCode == 404) {
      throw const WorksReportException('Объект не найден');
    }
    if (response.statusCode != 200) {
      throw WorksReportException(
        'Сервер ответил ошибкой ${response.statusCode}',
      );
    }

    try {
      final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));
      final dynamic data = decoded is Map ? decoded['data'] : null;
      if (data is! Map) {
        throw const WorksReportException('Сервер вернул неожиданный ответ');
      }
      return data.cast<String, dynamic>();
    } on WorksReportException {
      rethrow;
    } catch (_) {
      throw const WorksReportException('Не удалось прочитать ответ сервера');
    }
  }
}
