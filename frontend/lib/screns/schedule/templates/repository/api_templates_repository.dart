import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../helper/api_client.dart';
import '../../../../helper/api_config.dart';
import '../../repository/api_envelope.dart';
import '../../repository/schedules_repository.dart';
import '../models/checklist_template.dart';
import 'templates_repository.dart';

/// Тот же интерфейс, что у фикстуры, но поверх боевых ручек.
///
/// Запросы идут через [Api]: заголовок с токеном, обновление пары токенов и
/// повтор после `401` живут там, и второго такого места в проекте быть не
/// должно.
///
/// Вид ТО у модели на сервере — строка `acts_bases`, даже без шагов.
/// Экран же различает «шаблон есть» и «нет шаблона» по шагам, и
/// `TemplateTypeAct.templateId` заполнен только у первых. Поэтому id строк
/// репозиторий помнит сам — в [_rows], по паре модель × вид — и по нему
/// решает, слать `PUT` или `POST`, куда бить `DELETE` и `restore`.
class ApiTemplatesRepository implements TemplatesRepository {
  ApiTemplatesRepository({
    this.timeout = const Duration(seconds: 20),
    Future<http.Response> Function(Uri uri)? send,
    Future<http.Response> Function(Uri uri, String body)? sendPost,
    Future<http.Response> Function(Uri uri, String body)? sendPut,
    Future<http.Response> Function(Uri uri)? sendDelete,
  })  : _send = send ?? _getViaApi,
        _sendPost = sendPost ?? _postViaApi,
        _sendPut = sendPut ?? _putViaApi,
        _sendDelete = sendDelete ?? _deleteViaApi;

  final Duration timeout;

  /// Как уходят запросы. Подменяются только в тестах: разбор ответа — это
  /// половина смысла класса, а проверить его иначе, чем подставив готовый
  /// ответ, нельзя.
  final Future<http.Response> Function(Uri uri) _send;
  final Future<http.Response> Function(Uri uri, String body) _sendPost;
  final Future<http.Response> Function(Uri uri, String body) _sendPut;
  final Future<http.Response> Function(Uri uri) _sendDelete;

  static const Map<String, String> _jsonHeaders = <String, String>{
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };

  static Future<http.Response> _getViaApi(Uri uri) =>
      Api.get(uri, headers: <String, String>{'Accept': 'application/json'});

  static Future<http.Response> _postViaApi(Uri uri, String body) =>
      Api.post(uri, headers: _jsonHeaders, body: body);

  static Future<http.Response> _putViaApi(Uri uri, String body) =>
      Api.put(uri, headers: _jsonHeaders, body: body);

  static Future<http.Response> _deleteViaApi(Uri uri) =>
      Api.delete(uri, headers: <String, String>{'Accept': 'application/json'});

  /// Последний загруженный список — для «Скопировать из…» и для id строк.
  List<ModelTemplates>? _loaded;

  /// `acts_bases.id` по паре модель × вид ТО из последней загрузки.
  final Map<String, int> _rows = <String, int>{};

  /// Пары, чья строка мягко удалена. `PUT` по такой строке шагов не оживит:
  /// предпросмотр графика считает шаблоном только строку без `deleted_at`.
  final Set<String> _deletedRows = <String>{};

  static String _key(int modelId, int typeActId) => '$modelId:$typeActId';

  @override
  Future<List<ModelTemplates>> loadAll() async {
    final List<TemplateModel> models = await _models();
    _rows.clear();
    _deletedRows.clear();

    final List<ModelTemplates> result = <ModelTemplates>[
      for (final TemplateModel model in models)
        ModelTemplates(model: model, types: await _typeActs(model.id)),
    ];
    _loaded = result;
    return result;
  }

  /// Все модели справочника — ручка отдаёт по 30 на страницу.
  Future<List<TemplateModel>> _models() async {
    final List<TemplateModel> models = <TemplateModel>[];
    for (int page = 1;; page++) {
      final Map<String, dynamic> body = await _get(
        '/all-factory-model/',
        <String, String>{'page': '$page'},
      );
      final dynamic data = body['data'];
      if (data is! List) {
        throw const SchedulesException('Сервер вернул неожиданный ответ');
      }
      for (final dynamic item in data) {
        final int? id = asInt(nested(item, 'id'));
        if (id == null) continue;
        models.add(TemplateModel(id: id, name: _modelName(item, id)));
      }
      if (!_hasNext(body)) return models;
    }
  }

  /// Имя модели — завод и модель вместе: в справочнике «модель» одна и та
  /// же у разных заводов встречается.
  static String _modelName(dynamic item, int id) {
    final String? factory = asString(nested(item, 'factory'));
    final String? model = asString(nested(item, 'model'));
    final List<String> parts = <String>[
      if (factory != null) factory,
      if (model != null && model != factory) model,
    ];
    return parts.isEmpty ? 'Модель #$id' : parts.join(' ');
  }

  /// Виды ТО модели в порядке сервера: живые, потом убранные — так рисует
  /// экран, и сортировать второй раз ему незачем.
  Future<List<TemplateTypeAct>> _typeActs(int modelId) async {
    final Map<String, dynamic> body = await _get(
      '/acts-bases/by-model/$modelId/',
      const <String, String>{},
    );
    final dynamic data = body['data'];
    if (data is! List) {
      throw const SchedulesException('Сервер вернул неожиданный ответ');
    }

    final List<TemplateTypeAct> live = <TemplateTypeAct>[];
    final List<TemplateTypeAct> deleted = <TemplateTypeAct>[];
    for (final dynamic item in data) {
      final int? typeActId = asInt(nested(nested(item, 'type_act'), 'id'));
      final int? rowId = asInt(nested(item, 'template_id'));
      if (typeActId == null || rowId == null) continue;
      _rows[_key(modelId, typeActId)] = rowId;

      final List<String> steps = _steps(nested(item, 'steps'));
      final TemplateTypeAct typeAct = TemplateTypeAct(
        typeActId: typeActId,
        typeActName:
            asString(nested(nested(item, 'type_act'), 'name')) ?? 'ТО #$typeActId',
        templateId: steps.isEmpty ? null : rowId,
        steps: steps,
        deleted: asString(nested(item, 'deleted_at')) != null,
      );
      if (typeAct.deleted) _deletedRows.add(_key(modelId, typeActId));
      (typeAct.deleted ? deleted : live).add(typeAct);
    }
    return <TemplateTypeAct>[...live, ...deleted];
  }

  static List<String> _steps(dynamic value) {
    if (value is! List) return const <String>[];
    return List<String>.unmodifiable(<String>[
      for (final dynamic step in value)
        if (asString(step) != null) asString(step)!,
    ]);
  }

  @override
  Future<void> save({
    required int modelId,
    required int typeActId,
    required List<String> steps,
  }) async {
    final int? rowId = await _rowId(modelId, typeActId);
    if (rowId != null) {
      // Строка есть, но удалена — сначала вернуть: из мастера графика шаблон
      // заводят на клетку «нет шаблона», и удалённая пара — одна из её причин.
      if (_deletedRows.remove(_key(modelId, typeActId))) {
        await _post('/act-base/$rowId/restore/', const <String, dynamic>{});
      }
      await _put('/act-base/$rowId/', <String, dynamic>{'steps': steps});
      return;
    }
    await _post('/act-base/', <String, dynamic>{
      'factory_model_id': modelId,
      'type_act_id': typeActId,
      'steps': steps,
    });
  }

  /// Вид ТО у модели — два шага: вид в справочнике `types_acts` и пустая
  /// строка `acts_bases` для пары. Имя в справочнике уже есть — берём его:
  /// «ТО 12» у ЩЛЗ-400 отсутствовать может, но в справочнике оно одно.
  @override
  Future<void> addTypeAct({required int modelId, required String name}) async {
    final int typeActId =
        await _findTypeAct(name) ?? await _createTypeAct(name);
    await _post('/act-base/', <String, dynamic>{
      'factory_model_id': modelId,
      'type_act_id': typeActId,
      'steps': const <String>[],
    });
  }

  Future<int?> _findTypeAct(String name) async {
    final String wanted = _fold(name);
    for (int page = 1;; page++) {
      final Map<String, dynamic> body = await _get(
        '/type-acts/',
        <String, String>{'page': '$page'},
      );
      final dynamic data = body['data'];
      if (data is! List) {
        throw const SchedulesException('Сервер вернул неожиданный ответ');
      }
      for (final dynamic item in data) {
        final String? found = asString(nested(item, 'name'));
        if (found != null && _fold(found) == wanted) {
          return asInt(nested(item, 'id'));
        }
      }
      if (!_hasNext(body)) return null;
    }
  }

  static String _fold(String name) =>
      name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  Future<int> _createTypeAct(String name) async {
    final Map<String, dynamic> body =
        await _post('/type-acts/', <String, dynamic>{'name': name});
    final int? id = asInt(nested(body['data'], 'id'));
    if (id == null) {
      throw const SchedulesException('Сервер вернул неожиданный ответ');
    }
    return id;
  }

  @override
  Future<void> removeTypeAct({
    required int modelId,
    required int typeActId,
    bool force = false,
  }) async {
    final int rowId = await _requireRowId(modelId, typeActId);
    final Uri uri = Uri.parse('${ApiConfig.base}/act-base/$rowId/')
        .replace(queryParameters: force ? <String, String>{'force': 'true'} : null);

    http.Response response;
    try {
      response = await _sendDelete(uri).timeout(timeout);
    } catch (_) {
      throw const SchedulesException('Не удалось связаться с сервером');
    }
    if (response.statusCode == 200) {
      _deletedRows.add(_key(modelId, typeActId));
      return;
    }
    if (response.statusCode == 409 && errorCode(response) == 1213) {
      throw TemplateInUseException(errorText(response));
    }
    throw SchedulesException(errorText(response));
  }

  @override
  Future<void> restoreTypeAct({
    required int modelId,
    required int typeActId,
  }) async {
    final int rowId = await _requireRowId(modelId, typeActId);
    await _post('/act-base/$rowId/restore/', const <String, dynamic>{});
    _deletedRows.remove(_key(modelId, typeActId));
  }

  /// Чужие шаблоны — из последней загрузки: экран её уже сделал, а гонять
  /// десятки запросов заново ради диалога «Скопировать из…» незачем.
  @override
  Future<List<TemplateSource>> sources() async {
    final List<ModelTemplates> all = _loaded ?? await loadAll();
    return <TemplateSource>[
      for (final ModelTemplates item in all)
        for (final TemplateTypeAct t in item.active)
          if (t.hasTemplate)
            TemplateSource(
              modelName: item.model.name,
              typeActName: t.typeActName,
              steps: t.steps,
            ),
    ];
  }

  Future<int?> _rowId(int modelId, int typeActId) async {
    if (_loaded == null) await loadAll();
    return _rows[_key(modelId, typeActId)];
  }

  Future<int> _requireRowId(int modelId, int typeActId) async {
    final int? rowId = await _rowId(modelId, typeActId);
    if (rowId == null) {
      throw const SchedulesException('Вид ТО у этой модели не найден');
    }
    return rowId;
  }

  bool _hasNext(Map<String, dynamic> body) {
    final dynamic paginator = nested(body['meta'], 'paginator');
    return nested(paginator, 'has_next') == true;
  }

  Future<Map<String, dynamic>> _get(
    String path,
    Map<String, String> query,
  ) {
    final Uri uri = Uri.parse('${ApiConfig.base}$path')
        .replace(queryParameters: query.isEmpty ? null : query);
    return _request(() => _send(uri));
  }

  Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body) {
    final Uri uri = Uri.parse('${ApiConfig.base}$path');
    return _request(() => _sendPost(uri, jsonEncode(body)));
  }

  Future<Map<String, dynamic>> _put(String path, Map<String, dynamic> body) {
    final Uri uri = Uri.parse('${ApiConfig.base}$path');
    return _request(() => _sendPut(uri, jsonEncode(body)));
  }

  /// Запрос и разбор конверта. Ошибки — одним текстом без кодов и стектрейсов:
  /// он уходит прямо в плашку на экране.
  Future<Map<String, dynamic>> _request(
    Future<http.Response> Function() send,
  ) async {
    http.Response response;
    try {
      response = await send().timeout(timeout);
    } catch (_) {
      // Обрыв сети, таймаут и CORS попадают сюда вместе: различать их для
      // человека смысла нет, действие одно — повторить.
      throw const SchedulesException('Не удалось связаться с сервером');
    }

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw SchedulesException(errorText(response));
    }

    return decodeEnvelope(response);
  }
}
