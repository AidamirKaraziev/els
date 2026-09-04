import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../helper/api_client.dart';
import '../../../helper/api_config.dart';
import '../models/schedule_filters.dart';
import '../models/schedule_row.dart';
import 'schedules_repository.dart';

/// Тот же интерфейс, что у фикстуры, но поверх двух боевых ручек.
///
/// Запросы идут через [Api]: заголовок с токеном, обновление пары токенов и
/// повтор после `401` живут там, и второго такого места в проекте быть не
/// должно. `dio` в разделе не заводим — весь проект ходит через [Api].
class ApiSchedulesRepository implements SchedulesRepository {
  ApiSchedulesRepository({
    this.timeout = const Duration(seconds: 20),
    Future<http.Response> Function(Uri uri)? send,
  }) : _send = send ?? _viaApi;

  final Duration timeout;

  /// Как уходит запрос. Подменяется только в тестах: разбор ответа — это
  /// половина смысла этого класса, а проверить его иначе, чем подставив
  /// готовый ответ, нельзя.
  final Future<http.Response> Function(Uri uri) _send;

  static Future<http.Response> _viaApi(Uri uri) =>
      Api.get(uri, headers: <String, String>{'Accept': 'application/json'});

  @override
  Future<SchedulePage> fetchRows({
    required ScheduleFilters filters,
    required int page,
  }) async {
    final Map<String, dynamic> body = await _fetch(
      '/schedules/rows',
      <String, String>{...filters.toQuery(), 'page': '$page'},
    );

    final dynamic data = body['data'];
    if (data is! List) {
      throw const SchedulesException('Сервер вернул неожиданный ответ');
    }

    return SchedulePage(
      items: <ScheduleRow>[
        for (final dynamic item in data)
          if (item is Map) ScheduleRow.fromJson(item.cast<String, dynamic>()),
      ],
      page: page,
      // Именно отсюда, а не из «список непуст»: на признаке «непуст» старый
      // экран уезжал за последнюю страницу и показывал пустоту.
      hasNext: _hasNext(body),
    );
  }

  @override
  Future<ScheduleRow?> fetchRow({
    required int objectId,
    required int year,
  }) async {
    final Map<String, dynamic> body = await _fetch(
      '/schedules/rows',
      <String, String>{'object_id': '$objectId', 'year': '$year'},
    );

    final dynamic data = body['data'];
    if (data is! List) {
      throw const SchedulesException('Сервер вернул неожиданный ответ');
    }
    // Пусто — объекта в выдаче нет; отбор экрана сюда не уходит, значит дело
    // не в фильтре, а в области видимости. Строку оставляем прежней.
    if (data.isEmpty) return null;

    final dynamic first = data.first;
    if (first is! Map) {
      throw const SchedulesException('Сервер вернул неожиданный ответ');
    }
    return ScheduleRow.fromJson(first.cast<String, dynamic>());
  }

  @override
  Future<ScheduleFilterOptions> fetchFilterOptions() async {
    final Map<String, dynamic> body =
        await _fetch('/schedules/filters', const <String, String>{});

    final dynamic data = body['data'];
    if (data is! Map) {
      throw const SchedulesException('Сервер вернул неожиданный ответ');
    }

    return ScheduleFilterOptions(
      divisions: _options(data['divisions']),
      types: _options(data['types']),
      names: _options(data['names']),
      factoryNumbers: _options(data['factory_numbers']),
    );
  }

  /// Запрос и разбор конверта. Ошибки — одним текстом без кодов и стектрейсов:
  /// он уходит прямо в плашку на экране.
  Future<Map<String, dynamic>> _fetch(String path, Map<String, String> query) async {
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

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw const SchedulesException('Недостаточно прав или истёк вход');
    }
    if (response.statusCode != 200) {
      throw SchedulesException('Сервер ответил ошибкой ${response.statusCode}');
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

  /// `meta.paginator.has_next`. Нет метаданных — считаем, что догружать нечего:
  /// лишняя страница вхолостую лучше, чем бесконечный скролл в пустоту.
  bool _hasNext(Map<String, dynamic> body) {
    final dynamic meta = body['meta'];
    if (meta is! Map) return false;
    final dynamic paginator = meta['paginator'];
    if (paginator is! Map) return false;
    return paginator['has_next'] == true;
  }

  List<FilterOption> _options(dynamic value) {
    if (value is! List) return const <FilterOption>[];

    return <FilterOption>[
      for (final dynamic item in value)
        if (item is Map && item['title'] is String)
          FilterOption(
            id: item['id'] is int ? item['id'] as int : 0,
            title: item['title'] as String,
          ),
    ];
  }
}
