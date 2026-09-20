/// Разбор ответов экрана «Шаблоны ТО» и адреса, куда он бьёт.
///
/// Вёрстку экрана проверяют тесты на фикстуре. Здесь — готовые ответы
/// сервера и вопрос, что репозиторий из них достанет и какой запрос уйдёт:
/// `PUT` или `POST`, с `force` или без, повторно ли заводится вид ТО,
/// который в справочнике уже есть.
library;

import 'dart:convert';

import 'package:els/screns/schedule/repository/schedules_repository.dart';
import 'package:els/screns/schedule/templates/models/checklist_template.dart';
import 'package:els/screns/schedule/templates/repository/api_templates_repository.dart';
import 'package:els/screns/schedule/templates/repository/templates_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

/// Один увиденный запрос: метод, путь с параметрами, тело.
class _Seen {
  const _Seen(this.method, this.uri, [this.body]);

  final String method;
  final Uri uri;
  final String? body;

  String get path => uri.path.replaceFirst(RegExp(r'^.*/api/v1'), '');

  @override
  String toString() => '$method $path${uri.hasQuery ? '?${uri.query}' : ''}';
}

typedef _Answer = http.Response Function(_Seen request);

http.Response _ok(Object data, {Map<String, dynamic>? meta}) =>
    http.Response.bytes(
      utf8.encode(jsonEncode(<String, dynamic>{
        'data': data,
        'message': 'OK',
        if (meta != null) 'meta': meta,
      })),
      200,
    );

http.Response _error(int status, int code, String message) =>
    http.Response.bytes(
      utf8.encode(jsonEncode(<String, dynamic>{
        'message': 'Error',
        'errors': <Map<String, dynamic>>[
          <String, dynamic>{'code': code, 'message': message},
        ],
      })),
      status,
    );

ApiTemplatesRepository _repository(_Answer answer, List<_Seen> seen) {
  Future<http.Response> reply(_Seen request) async {
    seen.add(request);
    return answer(request);
  }

  return ApiTemplatesRepository(
    send: (Uri uri) => reply(_Seen('GET', uri)),
    sendPost: (Uri uri, String body) => reply(_Seen('POST', uri, body)),
    sendPut: (Uri uri, String body) => reply(_Seen('PUT', uri, body)),
    sendDelete: (Uri uri) => reply(_Seen('DELETE', uri)),
  );
}

Map<String, dynamic> _model(int id, String factory, String model) =>
    <String, dynamic>{'id': id, 'factory': factory, 'model': model};

Map<String, dynamic> _pair(
  int typeActId,
  String name,
  int templateId, {
  List<String> steps = const <String>[],
  String? deletedAt,
}) =>
    <String, dynamic>{
      'type_act': <String, dynamic>{'id': typeActId, 'name': name},
      'template_id': templateId,
      'steps': steps,
      'steps_count': steps.length,
      'has_template': steps.isNotEmpty,
      'deleted_at': deletedAt,
    };

Map<String, dynamic> _paginator({required bool hasNext}) => <String, dynamic>{
      'paginator': <String, dynamic>{'page': 1, 'has_next': hasNext},
    };

/// Справочник из одной модели с тремя видами: ТО 1 с шаблоном, ТО 3 без,
/// ТО 6 убран. Ответ на всё остальное — пустой успех.
http.Response _catalogue(_Seen request) {
  if (request.path == '/all-factory-model/') {
    return _ok(<Object>[_model(7, 'ЩЛЗ', '400')],
        meta: _paginator(hasNext: false));
  }
  if (request.path == '/acts-bases/by-model/7/') {
    return _ok(<Object>[
      _pair(1, 'ТО 1', 71, steps: <String>['Осмотр', 'Смазка']),
      _pair(3, 'ТО 6', 73, deletedAt: '2026-09-20T10:00:00'),
      _pair(2, 'ТО 3', 72),
    ]);
  }
  return _ok(<String, dynamic>{'id': 1});
}

void main() {
  group('loadAll', () {
    test('модели по страницам, виды с шагами, убранные — в конец', () async {
      int modelPage = 0;
      final List<_Seen> seen = <_Seen>[];
      final ApiTemplatesRepository repository = _repository((_Seen r) {
        if (r.path == '/all-factory-model/') {
          modelPage++;
          return _ok(
            <Object>[
              if (modelPage == 1) _model(7, 'ЩЛЗ', '400'),
              if (modelPage == 2) _model(8, 'OTIS', 'OTIS'),
            ],
            meta: _paginator(hasNext: modelPage == 1),
          );
        }
        if (r.path == '/acts-bases/by-model/8/') return _ok(<Object>[]);
        return _catalogue(r);
      }, seen);

      final List<ModelTemplates> all = await repository.loadAll();

      expect(all.map((ModelTemplates m) => m.model.name), <String>['ЩЛЗ 400', 'OTIS']);
      expect(seen.map((_Seen s) => '$s'), <String>[
        'GET /all-factory-model/?page=1',
        'GET /all-factory-model/?page=2',
        'GET /acts-bases/by-model/7/',
        'GET /acts-bases/by-model/8/',
      ]);

      final List<TemplateTypeAct> types = all.first.types;
      expect(types.map((TemplateTypeAct t) => t.typeActName), <String>['ТО 1', 'ТО 3', 'ТО 6']);
      expect(types[0].hasTemplate, isTrue);
      expect(types[0].templateId, 71);
      expect(types[0].steps, <String>['Осмотр', 'Смазка']);
      expect(types[1].hasTemplate, isFalse);
      expect(types[1].deleted, isFalse);
      expect(types[2].deleted, isTrue);
      expect(all.first.withTemplate, 1);
    });

    test('ошибка сервера — текст из конверта', () async {
      final ApiTemplatesRepository repository = _repository(
        (_Seen r) => _error(422, 1, 'Не хватает прав на справочник'),
        <_Seen>[],
      );
      expect(
        repository.loadAll(),
        throwsA(isA<SchedulesException>().having(
          (SchedulesException e) => e.message,
          'message',
          'Не хватает прав на справочник',
        )),
      );
    });
  });

  group('save', () {
    test('у пары уже есть строка — PUT с шагами, даже если шаблон был пуст',
        () async {
      final List<_Seen> seen = <_Seen>[];
      final ApiTemplatesRepository repository = _repository(_catalogue, seen);
      await repository.loadAll();
      seen.clear();

      await repository.save(modelId: 7, typeActId: 2, steps: <String>['Шаг']);

      expect(seen.map((_Seen s) => '$s'), <String>['PUT /act-base/72/']);
      expect(jsonDecode(seen.single.body!), <String, dynamic>{
        'steps': <String>['Шаг'],
      });
    });

    test('строки нет — POST с моделью и видом', () async {
      final List<_Seen> seen = <_Seen>[];
      final ApiTemplatesRepository repository = _repository(_catalogue, seen);
      await repository.loadAll();
      seen.clear();

      await repository.save(modelId: 7, typeActId: 9, steps: <String>['Шаг']);

      expect(seen.map((_Seen s) => '$s'), <String>['POST /act-base/']);
      expect(jsonDecode(seen.single.body!), <String, dynamic>{
        'factory_model_id': 7,
        'type_act_id': 9,
        'steps': <String>['Шаг'],
      });
    });
  });

  group('addTypeAct', () {
    test('имя есть в справочнике — вид не заводится второй раз', () async {
      final List<_Seen> seen = <_Seen>[];
      final ApiTemplatesRepository repository = _repository((_Seen r) {
        if (r.path == '/type-acts/') {
          return _ok(<Object>[
            <String, dynamic>{'id': 4, 'name': 'ТО 12'},
          ], meta: _paginator(hasNext: false));
        }
        return _catalogue(r);
      }, seen);

      await repository.addTypeAct(modelId: 7, name: ' то 12 ');

      expect(seen.map((_Seen s) => '$s'), <String>[
        'GET /type-acts/?page=1',
        'POST /act-base/',
      ]);
      expect(jsonDecode(seen.last.body!), <String, dynamic>{
        'factory_model_id': 7,
        'type_act_id': 4,
        'steps': <String>[],
      });
    });

    test('имени нет — POST /type-acts/, потом пустая строка у модели', () async {
      final List<_Seen> seen = <_Seen>[];
      final ApiTemplatesRepository repository = _repository((_Seen r) {
        if (r.path == '/type-acts/' && r.method == 'GET') {
          return _ok(<Object>[], meta: _paginator(hasNext: false));
        }
        if (r.path == '/type-acts/' && r.method == 'POST') {
          return _ok(<String, dynamic>{'id': 11, 'name': 'ТО 24'});
        }
        return _catalogue(r);
      }, seen);

      await repository.addTypeAct(modelId: 7, name: 'ТО 24');

      expect(seen.map((_Seen s) => '$s'), <String>[
        'GET /type-acts/?page=1',
        'POST /type-acts/',
        'POST /act-base/',
      ]);
      expect(jsonDecode(seen[1].body!), <String, dynamic>{'name': 'ТО 24'});
      expect(jsonDecode(seen[2].body!)['type_act_id'], 11);
    });
  });

  group('removeTypeAct', () {
    test('DELETE по строке пары; стоят ТО — отдельная ошибка с текстом', () async {
      final List<_Seen> seen = <_Seen>[];
      final ApiTemplatesRepository repository = _repository((_Seen r) {
        if (r.method == 'DELETE' && r.uri.queryParameters['force'] != 'true') {
          return _error(409, 1213, 'По шаблону стоят 3 ТО');
        }
        return _catalogue(r);
      }, seen);
      await repository.loadAll();
      seen.clear();

      await expectLater(
        repository.removeTypeAct(modelId: 7, typeActId: 1),
        throwsA(isA<TemplateInUseException>().having(
          (TemplateInUseException e) => e.message,
          'message',
          'По шаблону стоят 3 ТО',
        )),
      );
      await repository.removeTypeAct(modelId: 7, typeActId: 1, force: true);

      expect(seen.map((_Seen s) => '$s'), <String>[
        'DELETE /act-base/71/',
        'DELETE /act-base/71/?force=true',
      ]);
    });

    test('другой отказ — обычная ошибка', () async {
      final ApiTemplatesRepository repository = _repository((_Seen r) {
        if (r.method == 'DELETE') return _error(403, 1, 'Нет прав');
        return _catalogue(r);
      }, <_Seen>[]);

      expect(
        repository.removeTypeAct(modelId: 7, typeActId: 1),
        throwsA(isA<SchedulesException>().having(
          (SchedulesException e) => e is TemplateInUseException,
          'in use',
          isFalse,
        )),
      );
    });
  });

  test('restoreTypeAct бьёт в restore строки пары', () async {
    final List<_Seen> seen = <_Seen>[];
    final ApiTemplatesRepository repository = _repository(_catalogue, seen);
    await repository.loadAll();
    seen.clear();

    await repository.restoreTypeAct(modelId: 7, typeActId: 3);

    expect(seen.map((_Seen s) => '$s'), <String>['POST /act-base/73/restore/']);
  });

  test('sources — только живые с шаблоном, из последней загрузки', () async {
    final List<_Seen> seen = <_Seen>[];
    final ApiTemplatesRepository repository = _repository(_catalogue, seen);
    await repository.loadAll();
    seen.clear();

    final List<TemplateSource> sources = await repository.sources();

    expect(seen, isEmpty);
    expect(sources.map((TemplateSource s) => '${s.modelName} · ${s.typeActName}'),
        <String>['ЩЛЗ 400 · ТО 1']);
  });
}
