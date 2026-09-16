import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../helper/api_client.dart';
import '../../../helper/api_config.dart';
import '../../submitted_works/repository/submitted_works_repository.dart';
import '../models/new_work_draft.dart';
import '../models/work_counts.dart';
import '../models/work_employee.dart';
import '../models/work_filters.dart';
import '../models/work_item.dart';
import '../models/work_section.dart';
import 'works_repository.dart';

/// Тот же интерфейс, что у фикстуры, но поверх `GET /work/feed` и двух
/// действий `POST /work/{kind}/{id}/assign/|review/`.
///
/// Запросы идут через [Api]: заголовок с токеном, обновление пары токенов и
/// повтор после `401` живут там, и второго такого места в проекте быть не
/// должно. `dio` в разделе не заводим — весь проект ходит через [Api].
class ApiWorksRepository implements WorksRepository {
  ApiWorksRepository({
    this.timeout = const Duration(seconds: 20),
    Future<http.Response> Function(Uri uri)? send,
    Future<http.Response> Function(Uri uri, Object body)? post,
  }) : _send = send ?? _getViaApi,
       _post = post ?? _postViaApi;

  final Duration timeout;

  /// Как уходят запросы. Подменяются только в тестах: разбор ответа — это
  /// половина смысла этого класса, и проверить его иначе, чем подставив
  /// готовый ответ, нельзя.
  final Future<http.Response> Function(Uri uri) _send;
  final Future<http.Response> Function(Uri uri, Object body) _post;

  /// Потолок ручки (`MAX_LIMIT`): перемен за такт опроса больше не бывает.
  static const int changesLimit = 100;

  static Future<http.Response> _getViaApi(Uri uri) =>
      Api.get(uri, headers: <String, String>{'Accept': 'application/json'});

  static Future<http.Response> _postViaApi(Uri uri, Object body) => Api.post(
    uri,
    headers: <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    },
    body: jsonEncode(body),
  );

  @override
  Future<WorksFeed> fetch(
    WorkFilters filters, {
    String? cursor,
    int? limit,
  }) async {
    final Map<String, dynamic> data = await _get(<String, String>{
      ...filters.toQuery(),
      if (cursor != null) 'cursor': cursor,
      if (limit != null) 'limit': '$limit',
    });

    return WorksFeed(
      items: _items(data['items']),
      counts: data['counts'] is Map
          ? WorkCounts.fromJson((data['counts'] as Map).cast<String, dynamic>())
          : WorkCounts.empty,
      attentionCount: data['attention_count'] is num
          ? (data['attention_count'] as num).toInt()
          : 0,
      nextCursor: data['next_cursor'] is String &&
              (data['next_cursor'] as String).isNotEmpty
          ? data['next_cursor'] as String
          : null,
      sections: <WorkSection>[
        for (final dynamic s in _list(data['sections']))
          if (s is Map) WorkSection.fromJson(s.cast<String, dynamic>()),
      ],
      employees: <WorkEmployee>[
        for (final dynamic e in _list(data['employees']))
          if (e is Map) WorkEmployee.fromJson(e.cast<String, dynamic>()),
      ],
      mySections: <int>{
        for (final dynamic id in _list(data['my_sections']))
          if (id is num) id.toInt(),
      },
    );
  }

  @override
  Future<List<WorkItem>> changes(WorkFilters filters, DateTime since) async {
    final Map<String, dynamic> data = await _get(<String, String>{
      ...filters.wide().toQuery(),
      'updated_since': '${since.millisecondsSinceEpoch ~/ 1000}',
      'limit': '$changesLimit',
    });
    return _items(data['items']);
  }

  @override
  Future<WorkItem> assign(WorkItem item, WorkEmployee who) =>
      _act(item, 'assign', <String, int>{'performer_id': who.id});

  @override
  Future<WorkItem> review(WorkItem item) =>
      _act(item, 'review', const <String, dynamic>{});

  /// Ручка `GET /work/submitted/unreviewed-count` уже обёрнута лентой сданных
  /// — второго клиента к ней не заводим.
  @override
  Future<int> unreviewedCount() =>
      const SubmittedWorksRepository().unreviewedCount();

  @override
  Future<NewWorkContext> newWorkContext() async {
    final Uri uri = Uri.parse('${ApiConfig.base}/work/new/context');
    http.Response response;
    try {
      response = await _send(uri).timeout(timeout);
    } catch (_) {
      throw const WorksException('Не удалось связаться с сервером');
    }
    return NewWorkContext.fromJson(_decode(response));
  }

  /// `POST /order/` — та же ручка, что у формы диспетчера; `creator_id` и
  /// `created_at` сервер ставит сам. Ответ — заявка целиком, форме нужен
  /// только номер.
  @override
  Future<int> createWork(NewWorkDraft draft) async {
    final Uri uri = Uri.parse('${ApiConfig.base}/order/');
    http.Response response;
    try {
      response = await _post(uri, draft.toJson()).timeout(timeout);
    } catch (_) {
      throw const WorksException('Не удалось связаться с сервером');
    }
    // Отказ (нет такого объекта, исполнителя) — словами бэка из `_decode`.
    final int? id = _intOf(_decode(response)['id']);
    if (id == null) {
      throw const WorksException('Сервер вернул неожиданный ответ');
    }
    return id;
  }

  Future<WorkItem> _act(WorkItem item, String action, Object body) async {
    final Uri uri = Uri.parse(
      '${ApiConfig.base}/work/${kindPathSegment(item.kind)}/${item.id}/$action/',
    );
    http.Response response;
    try {
      response = await _post(uri, body).timeout(timeout);
    } catch (_) {
      throw const WorksException('Не удалось связаться с сервером');
    }
    if (response.statusCode == 404) {
      // Работу заархивировали или она уже не в том статусе, пока лента
      // висела открытой.
      throw const WorksException('Этой работы больше нет в ленте');
    }
    return WorkItem.fromJson(_decode(response));
  }

  Future<Map<String, dynamic>> _get(Map<String, String> query) async {
    final Uri uri = Uri.parse(
      '${ApiConfig.base}/work/feed',
    ).replace(queryParameters: query);

    http.Response response;
    try {
      response = await _send(uri).timeout(timeout);
    } catch (_) {
      // Обрыв сети, таймаут и CORS попадают сюда вместе: различать их для
      // человека смысла нет, действие одно — повторить.
      throw const WorksException('Не удалось связаться с сервером');
    }
    return _decode(response);
  }

  /// Тело `SingleEntityResponse`: то, что лежит в `data`.
  Map<String, dynamic> _decode(http.Response response) {
    if (response.statusCode == 401 || response.statusCode == 403) {
      throw const WorksException('Недостаточно прав или истёк вход');
    }
    dynamic decoded;
    try {
      decoded = jsonDecode(utf8.decode(response.bodyBytes));
    } catch (_) {
      decoded = null;
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      // Бэк кладёт человеческий текст в `description` («Нет такого
      // пользователя!»); его и печатаем — форме важно, что именно не так.
      final dynamic description = decoded is Map ? decoded['description'] : null;
      throw WorksException(
        description is String && description.isNotEmpty
            ? description
            : 'Сервер ответил ошибкой ${response.statusCode}',
      );
    }
    if (decoded == null) {
      throw const WorksException('Не удалось прочитать ответ сервера');
    }
    if (decoded is! Map || decoded['data'] is! Map) {
      throw const WorksException('Сервер вернул неожиданный ответ');
    }
    return (decoded['data'] as Map).cast<String, dynamic>();
  }

  List<WorkItem> _items(dynamic raw) => <WorkItem>[
    for (final dynamic i in _list(raw))
      if (i is Map) WorkItem.fromJson(i.cast<String, dynamic>()),
  ];

  List<dynamic> _list(dynamic raw) => raw is List ? raw : const <dynamic>[];

  int? _intOf(dynamic raw) => raw is num ? raw.toInt() : null;
}
