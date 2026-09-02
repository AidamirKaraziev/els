import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../../helper/api_client.dart';
import '../../../../../helper/api_config.dart';
import '../../../repository/api_envelope.dart';
import '../models/maintenance_program.dart';
import 'maintenance_program_repository.dart';

/// Тот же интерфейс, что у фикстуры, но поверх боевых ручек
/// `/maintenance-program/by-model/{factory_model_id}/` и `/type-acts/`.
///
/// Раскладку по календарю здесь не считают вовсе: программа — это цикл из
/// двенадцати позиций, а на какой месяц придётся первая, решает мастер
/// расстановки вместе с сервером.
class ApiMaintenanceProgramRepository implements MaintenanceProgramRepository {
  ApiMaintenanceProgramRepository({
    this.timeout = const Duration(seconds: 20),
    Future<http.Response> Function(Uri uri)? send,
    Future<http.Response> Function(Uri uri, String body)? sendPut,
  })  : _send = send ?? _getViaApi,
        _sendPut = sendPut ?? _putViaApi;

  final Duration timeout;

  /// Как уходят запросы. Подменяются только в тестах: разбор ответа — половина
  /// смысла класса, а проверить его иначе, чем подставив готовый ответ, нельзя.
  final Future<http.Response> Function(Uri uri) _send;
  final Future<http.Response> Function(Uri uri, String body) _sendPut;

  static Future<http.Response> _getViaApi(Uri uri) =>
      Api.get(uri, headers: <String, String>{'Accept': 'application/json'});

  static Future<http.Response> _putViaApi(Uri uri, String body) => Api.put(
        uri,
        headers: <String, String>{
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: body,
      );

  @override
  Future<MaintenanceProgram?> program(int modelId) async {
    final http.Response response =
        await _get('${ApiConfig.base}/maintenance-program/by-model/$modelId/');

    // 404 — «программы у модели нет». Это не поломка: мастер на неё открывает
    // окно создания, и превращать её в ошибку значило бы закрыть человеку
    // единственный путь дальше.
    if (response.statusCode == 404) return null;
    if (response.statusCode != 200) {
      throw MaintenanceProgramException(errorText(response));
    }

    final Map<String, dynamic> data = _object(response);
    return MaintenanceProgram(
      modelId: asInt(data['factory_model_id']) ?? modelId,
      name: asString(data['name']),
      items: _items(data['items']),
    );
  }

  @override
  Future<MaintenanceProgram> suggestion(int modelId) async {
    final http.Response response = await _get(
      '${ApiConfig.base}/maintenance-program/by-model/$modelId/suggestion/',
    );
    if (response.statusCode != 200) {
      throw MaintenanceProgramException(errorText(response));
    }

    final Map<String, dynamic> data = _object(response);
    return MaintenanceProgram(
      modelId: asInt(data['factory_model_id']) ?? modelId,
      items: _items(data['items']),
    );
  }

  @override
  Future<List<TypeAct>> typeActs() async {
    final http.Response response = await _get('${ApiConfig.base}/type-acts/');
    if (response.statusCode != 200) {
      throw MaintenanceProgramException(errorText(response));
    }

    final dynamic data = decodeEnvelope(response)['data'];
    if (data is! List) {
      throw const MaintenanceProgramException('Сервер вернул неожиданный ответ');
    }

    final List<TypeAct> acts = <TypeAct>[];
    for (final dynamic item in data) {
      if (item is! Map) continue;
      final Map<String, dynamic> act = item.cast<String, dynamic>();
      final int? id = asInt(act['id']);
      final String? name = asString(act['name']);
      if (id == null || name == null) continue;
      acts.add(TypeAct(id: id, name: name));
    }
    return acts;
  }

  @override
  Future<void> save(MaintenanceProgram program) async {
    final Uri uri = Uri.parse(
      '${ApiConfig.base}/maintenance-program/by-model/${program.modelId}/',
    );
    // Тело — всегда двенадцать позиций: ручка заменяет программу целиком, и
    // послать половину значило бы получить 422 со списком пропусков.
    final String body = jsonEncode(<String, dynamic>{
      if (program.name != null) 'name': program.name,
      'items': <Map<String, dynamic>>[
        for (final MaintenanceProgramItem item in program.items)
          <String, dynamic>{
            'position': item.position,
            'type_act_id': item.typeActId,
          },
      ],
    });

    http.Response response;
    try {
      response = await _sendPut(uri, body).timeout(timeout);
    } catch (_) {
      throw const MaintenanceProgramException('Не удалось связаться с сервером');
    }

    if (response.statusCode == 200 || response.statusCode == 201) return;
    throw MaintenanceProgramException(errorText(response));
  }

  Future<http.Response> _get(String url) async {
    try {
      return await _send(Uri.parse(url)).timeout(timeout);
    } catch (_) {
      // Обрыв сети, таймаут и CORS попадают сюда вместе: различать их для
      // человека смысла нет, действие одно — повторить.
      throw const MaintenanceProgramException('Не удалось связаться с сервером');
    }
  }

  Map<String, dynamic> _object(http.Response response) {
    final dynamic data = decodeEnvelope(response)['data'];
    if (data is! Map) {
      throw const MaintenanceProgramException('Сервер вернул неожиданный ответ');
    }
    return data.cast<String, dynamic>();
  }

  /// Двенадцать позиций по порядку.
  ///
  /// Пропущенная позиция не рвёт цикл: она приходит пустой, и окно правки
  /// показывает её красным — сохранить такую программу всё равно нельзя.
  List<MaintenanceProgramItem> _items(dynamic value) {
    if (value is! List) {
      throw const MaintenanceProgramException('Сервер вернул неожиданный ответ');
    }

    final Map<int, MaintenanceProgramItem> byPosition =
        <int, MaintenanceProgramItem>{};
    for (final dynamic item in value) {
      if (item is! Map) continue;
      final Map<String, dynamic> position = item.cast<String, dynamic>();
      final int? number = asInt(position['position']);
      if (number == null) continue;
      byPosition[number] = MaintenanceProgramItem(
        position: number,
        typeActId: asInt(position['type_act_id']),
        typeActName: asString(position['type_act_name']) ?? '',
      );
    }

    return <MaintenanceProgramItem>[
      for (int position = 1; position <= kProgramLength; position++)
        byPosition[position] ?? MaintenanceProgramItem(position: position),
    ];
  }
}
