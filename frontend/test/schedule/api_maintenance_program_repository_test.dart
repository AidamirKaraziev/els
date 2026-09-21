/// Ручка `/type-acts/` глазами окна программы: какой запрос уходит на
/// «Добавить вид ТО» и что окно получает назад.
///
/// Остальное у репозитория — `GET` программы и `PUT` целиком — проверено на
/// живом стеке; сюда положено то, что появилось в S05 и без сети иначе
/// не увидеть: 409 «имя занято» должен дойти до окна текстом сервера.
library;

import 'dart:convert';

import 'package:els/screns/schedule/object/wizard/models/maintenance_program.dart';
import 'package:els/screns/schedule/object/wizard/repository/api_maintenance_program_repository.dart';
import 'package:els/screns/schedule/object/wizard/repository/maintenance_program_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

http.Response _json(Object body, {int status = 200}) =>
    http.Response.bytes(utf8.encode(jsonEncode(body)), status);

void main() {
  test('createTypeAct — POST /type-acts/ с именем, назад вид с id', () async {
    final List<String> seen = <String>[];
    final ApiMaintenanceProgramRepository repository =
        ApiMaintenanceProgramRepository(
      send: (Uri uri) async => fail('GET не ожидался'),
      sendPut: (Uri uri, String body) async => fail('PUT не ожидался'),
      sendPost: (Uri uri, String body) async {
        seen.add('POST ${uri.path} $body');
        return _json(<String, dynamic>{
          'data': <String, dynamic>{'id': 14, 'name': 'ТО 4'},
          'message': 'OK',
        }, status: 201);
      },
    );

    final TypeAct act = await repository.createTypeAct('ТО 4');

    expect(act.id, 14);
    expect(act.name, 'ТО 4');
    expect(seen, <String>['POST /api/v1/type-acts/ {"name":"ТО 4"}']);
  });

  test('имя занято — исключение с текстом сервера', () async {
    final ApiMaintenanceProgramRepository repository =
        ApiMaintenanceProgramRepository(
      send: (Uri uri) async => fail('GET не ожидался'),
      sendPut: (Uri uri, String body) async => fail('PUT не ожидался'),
      sendPost: (Uri uri, String body) async => _json(
        <String, dynamic>{
          'message': 'Error',
          'errors': <Map<String, dynamic>>[
            <String, dynamic>{'code': 1209, 'message': 'Вид ТО «ТО 4» уже есть'},
          ],
        },
        status: 409,
      ),
    );

    await expectLater(
      repository.createTypeAct('ТО 4'),
      throwsA(isA<MaintenanceProgramException>().having(
        (MaintenanceProgramException e) => e.message,
        'message',
        'Вид ТО «ТО 4» уже есть',
      )),
    );
  });
}
