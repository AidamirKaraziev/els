/// Разбор ответов экрана графика объекта.
///
/// Экранные тесты держатся за фикстуру и проверяют вёрстку. Здесь наоборот:
/// вёрстки нет, есть готовый ответ сервера и вопрос, что репозиторий из него
/// достанет — и по какому адресу вообще сходит.
library;

import 'dart:convert';

import 'package:els/screns/schedule/models/month_cell.dart';
import 'package:els/screns/schedule/object/models/schedule_object_card.dart';
import 'package:els/screns/schedule/object/repository/api_schedule_object_repository.dart';
import 'package:els/screns/schedule/repository/schedules_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

http.Response _json(Object body, {int status = 200}) =>
    http.Response.bytes(utf8.encode(jsonEncode(body)), status);

/// Репозиторий с ответом на каждый путь: ключ — кусок адреса.
ApiScheduleObjectRepository _repository(
  Map<String, http.Response> answers, {
  List<Uri>? seen,
  http.Response? post,
  List<String>? posted,
}) {
  return ApiScheduleObjectRepository(
    send: (Uri uri) async {
      seen?.add(uri);
      for (final MapEntry<String, http.Response> answer in answers.entries) {
        if (uri.path.contains(answer.key)) return answer.value;
      }
      return _json(<String, dynamic>{'detail': 'нет такого пути'}, status: 404);
    },
    sendPost: (Uri uri, String body) async {
      seen?.add(uri);
      posted?.add(body);
      return post ?? _json(<String, dynamic>{'data': <String, dynamic>{}});
    },
  );
}

void main() {
  group('лента года', () {
    test('идёт в /schedules/rows за одним объектом', () async {
      final List<Uri> seen = <Uri>[];
      final ApiScheduleObjectRepository repository = _repository(
        <String, http.Response>{
          '/schedules/rows': _json(<String, dynamic>{
            'data': <dynamic>[
              <String, dynamic>{
                'object_id': 7,
                'cells': <dynamic>[
                  <String, dynamic>{
                    'month': 3,
                    'status': 'late',
                    'to_name': 'ТО 6',
                    'act_id': 12,
                  },
                ],
              },
            ],
          }),
        },
        seen: seen,
      );

      final List<MonthCell> cells = await repository.fetchYear(7, 2026);

      expect(seen.single.queryParameters['object_id'], '7');
      expect(seen.single.queryParameters['year'], '2026');
      // Клеток всегда двенадцать, даже когда сервер прислал одну.
      expect(cells, hasLength(12));
      expect(cells[2].status, MonthStatus.late);
      expect(cells[2].toName, 'ТО 6');
      expect(cells[2].actId, 12);
      expect(cells[0].status, MonthStatus.none);
    });

    test('объекта в выдаче нет — год пустой, а не ошибка', () async {
      final ApiScheduleObjectRepository repository = _repository(
        <String, http.Response>{
          '/schedules/rows': _json(<String, dynamic>{'data': <dynamic>[]}),
        },
      );

      final List<MonthCell> cells = await repository.fetchYear(7, 2026);

      expect(cells, hasLength(12));
      expect(
        cells.every((MonthCell cell) => cell.status == MonthStatus.none),
        isTrue,
      );
    });

    test('обрыв связи — один текст без кодов', () async {
      final ApiScheduleObjectRepository repository =
          ApiScheduleObjectRepository(send: (Uri uri) async => throw Exception('обрыв'));

      expect(
        () => repository.fetchYear(7, 2026),
        throwsA(isA<SchedulesException>().having(
          (SchedulesException error) => error.message,
          'message',
          'Не удалось связаться с сервером',
        )),
      );
    });
  });

  group('карточка объекта', () {
    test('вложенные поля разбираются, организация берётся отдельно', () async {
      final List<Uri> seen = <Uri>[];
      final ApiScheduleObjectRepository repository = _repository(
        <String, http.Response>{
          '/organization/': _json(<String, dynamic>{
            'data': <String, dynamic>{'id': 4, 'name': 'ООО «КПЭК»'},
          }),
          '/object/': _json(<String, dynamic>{
            'data': <String, dynamic>{
              'id': 7,
              'organization_id': 4,
              'division_id': <String, dynamic>{'title': 'Северная/Тургенева'},
              'address': 'г. Краснодар, ул. Северная, 356',
              'factory_model_id': <String, dynamic>{
                'model': 'LIFT A388509',
                'type_object_id': <String, dynamic>{'name': 'Лифт'},
              },
              'factory_number': '2383',
              'registration_number': '2384',
              'company_id': <String, dynamic>{'name': 'ООО "Гармония"'},
              'contact_person_id': <String, dynamic>{
                'name': 'П.С. Василенко',
                'phone': '+7 (918) 456-78-90',
              },
              'contract_id': <String, dynamic>{'title': 'Договор №2123'},
              'geo': '45.03,38.97',
              'foreman_id': <String, dynamic>{'name': 'Н.В. Гоголевский'},
              'mechanic_id': <String, dynamic>{'name': 'Л.А. Терешков'},
            },
          }),
        },
        seen: seen,
      );

      final ScheduleObjectCard card = await repository.fetchCard(7);

      expect(card.organization, 'ООО «КПЭК»');
      expect(card.division, 'Северная/Тургенева');
      expect(card.type, 'Лифт');
      expect(card.model, 'LIFT A388509');
      expect(card.contactPhone, '+7 (918) 456-78-90');
      expect(card.contract, 'Договор №2123');
      expect(card.geo?.latitude, closeTo(45.03, 0.001));
      expect(card.foreman?.fullName, 'Н.В. Гоголевский');
      expect(card.mechanic?.title, 'Механик');
      // Два запроса: объект и название организации.
      expect(seen, hasLength(2));
    });

    test('организация не ответила — прочерк, а не ошибка экрана', () async {
      final ApiScheduleObjectRepository repository = _repository(
        <String, http.Response>{
          '/organization/': _json(<String, dynamic>{'detail': 'нет'}, status: 500),
          '/object/': _json(<String, dynamic>{
            'data': <String, dynamic>{'id': 7, 'organization_id': 4, 'address': 'Адрес'},
          }),
        },
      );

      final ScheduleObjectCard card = await repository.fetchCard(7);

      expect(card.organization, isNull);
      expect(card.address, 'Адрес');
    });
  });

  group('создание графика', () {
    test('шлёт объект и год', () async {
      final List<String> posted = <String>[];
      final ApiScheduleObjectRepository repository =
          _repository(<String, http.Response>{}, posted: posted);

      await repository.generateYear(7, 2027);

      expect(jsonDecode(posted.single), <String, dynamic>{
        'object_id': 7,
        'year': 2027,
      });
    });

    test('422 доносит объяснение сервера до человека', () async {
      final ApiScheduleObjectRepository repository = _repository(
        <String, http.Response>{},
        post: _json(
          <String, dynamic>{'detail': 'Нет шаблона чек-листа на ТО 6'},
          status: 422,
        ),
      );

      expect(
        () => repository.generateYear(7, 2027),
        throwsA(isA<SchedulesException>().having(
          (SchedulesException error) => error.message,
          'message',
          'Нет шаблона чек-листа на ТО 6',
        )),
      );
    });

    test('403 говорит про права, а не про код ответа', () async {
      final ApiScheduleObjectRepository repository = _repository(
        <String, http.Response>{},
        post: _json(<String, dynamic>{'detail': 'Forbidden'}, status: 403),
      );

      expect(
        () => repository.generateYear(7, 2027),
        throwsA(isA<SchedulesException>().having(
          (SchedulesException error) => error.message,
          'message',
          'Недостаточно прав или истёк вход',
        )),
      );
    });
  });
}
