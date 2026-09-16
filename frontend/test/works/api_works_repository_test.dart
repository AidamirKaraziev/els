/// Разбор ответов `GET /work/feed` и адреса, на которые уходит отбор.
///
/// Вёрстки здесь нет: есть готовый ответ сервера и вопрос, что репозиторий
/// из него достанет и какие параметры до ручки доехали. Ошибка в имени
/// параметра видна не исключением, а лентой, которую чипс не сужает.
library;

import 'dart:convert';

import 'package:els/screns/works/models/new_work_draft.dart';
import 'package:els/screns/works/models/work_attention.dart';
import 'package:els/screns/works/models/work_employee.dart';
import 'package:els/screns/works/models/work_filters.dart';
import 'package:els/screns/works/models/work_item.dart';
import 'package:els/screns/works/repository/api_works_repository.dart';
import 'package:els/screns/works/repository/works_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

ApiWorksRepository _repository(
  Object data, {
  int status = 200,
  List<Uri>? seen,
  List<Object>? bodies,
}) {
  final String body = jsonEncode(<String, Object>{'data': data});
  return ApiWorksRepository(
    send: (Uri uri) async {
      seen?.add(uri);
      return http.Response.bytes(utf8.encode(body), status);
    },
    post: (Uri uri, Object payload) async {
      seen?.add(uri);
      bodies?.add(payload);
      return http.Response.bytes(utf8.encode(body), status);
    },
  );
}

const Map<String, Object?> _row = <String, Object?>{
  'kind': 'breakdown',
  'work_id': 1042,
  'status': 'running',
  'act_title': null,
  'object': <String, Object?>{
    'id': 7,
    'name': 'ТЦ Карнавал',
    'address': 'ул. Ленина, 12',
  },
  'object_type': 'Лифт с МП',
  'task_text': 'Стоит между этажами',
  'performer_id': 11,
  'performer': 'Иванов А. С.',
  'performer_phone': '+7 900 100-00-11',
  'created_at': 1757600000,
  'accepted_at': 1757603600,
  'started_at': 1757607200,
  'paused_at': null,
  'closed_at': null,
  'updated_at': 1757607200,
  'has_defect': true,
  'comment': null,
  'is_actual': true,
  'section_id': 1,
  'section': 'Центр',
  'reviewed': false,
  'attention': 'overdue',
};

void main() {
  group('лента', () {
    test('строка, счётчики и справочники берутся из конверта', () async {
      final ApiWorksRepository repository = _repository(<String, Object?>{
        'items': <Object?>[_row],
        'counts': <String, Object?>{
          'by_status': <String, int>{'fresh': 3, 'running': 2},
          'by_kind': <String, int>{'maintenance': 4, 'client_request': 1},
          'by_attention': <String, int>{'paused_long': 1},
        },
        'attention_count': 2,
        'next_cursor': 'abc',
        'sections': <Object?>[
          <String, Object?>{'id': 1, 'title': 'Центр'},
        ],
        'employees': <Object?>[
          <String, Object?>{
            'id': 11,
            'name': 'Иванов А. С.',
            'specialty': 'Механик',
            'section_id': 1,
            'section': 'Центр',
            'phone': '+7 900',
          },
        ],
        'my_sections': <int>[1, 2],
      });

      final WorksFeed feed = await repository.fetch(const WorkFilters());

      expect(feed.items, hasLength(1));
      final WorkItem item = feed.items.single;
      expect(item.id, 1042);
      expect(item.key, 'breakdown:1042');
      expect(item.kind, WorkKind.breakdown);
      expect(item.status, WorkStatus.running);
      expect(item.objectName, 'ТЦ Карнавал');
      expect(item.objectAddress, 'ул. Ленина, 12');
      expect(item.performerId, 11);
      expect(item.performerPhone, '+7 900 100-00-11');
      expect(item.startedAt, DateTime.fromMillisecondsSinceEpoch(1757607200000));
      expect(item.pausedAt, isNull);
      expect(item.hasDefect, isTrue);
      expect(item.sectionId, 1);
      expect(item.isActual, isTrue);

      expect(feed.counts.ofStatus(WorkStatus.fresh), 3);
      expect(feed.counts.ofKind(WorkKind.clientRequest), 1);
      expect(feed.counts.ofAttention(AttentionReason.pausedLong), 1);
      expect(feed.attentionCount, 2);
      expect(feed.nextCursor, 'abc');
      expect(feed.sections.single.label, 'Центр');
      expect(feed.employees.single.sectionId, 1);
      expect(feed.mySections, <int>{1, 2});
    });

    test('отбор уходит в параметры ручки по id', () async {
      final List<Uri> seen = <Uri>[];
      final ApiWorksRepository repository = _repository(
        <String, Object?>{'items': <Object?>[]},
        seen: seen,
      );

      await repository.fetch(
        const WorkFilters(
          status: WorkStatus.accepted,
          kind: WorkKind.clientRequest,
          search: 'карнавал',
          sectionId: 3,
          performerId: 11,
          mine: true,
          attention: AttentionReason.pausedLong,
          sort: WorkSort.updated,
        ),
        cursor: 'xyz',
        limit: 1,
      );

      final Map<String, String> q = seen.single.queryParameters;
      expect(seen.single.path, endsWith('/work/feed'));
      expect(q['status'], 'accepted');
      expect(q['kind'], 'client_request');
      expect(q['search'], 'карнавал');
      expect(q['section_id'], '3');
      expect(q['performer_id'], '11');
      expect(q['mine'], 'true');
      expect(q['attention'], 'paused_long');
      expect(q['sort'], 'updated');
      expect(q['cursor'], 'xyz');
      expect(q['limit'], '1');
      expect(q.containsKey('only_archived'), isFalse);
    });

    test('пустой курсор — последняя страница', () async {
      final ApiWorksRepository repository = _repository(<String, Object?>{
        'items': <Object?>[],
        'next_cursor': null,
      });
      final WorksFeed feed = await repository.fetch(const WorkFilters());
      expect(feed.nextCursor, isNull);
    });
  });

  group('перемены', () {
    test('спрашиваются широко и с updated_since в секундах', () async {
      final List<Uri> seen = <Uri>[];
      final ApiWorksRepository repository = _repository(
        <String, Object?>{
          'items': <Object?>[
            <String, Object?>{..._row, 'is_actual': false},
          ],
        },
        seen: seen,
      );

      final List<WorkItem> changed = await repository.changes(
        const WorkFilters(
          status: WorkStatus.fresh,
          kind: WorkKind.breakdown,
          attention: AttentionReason.unassigned,
          sectionId: 3,
          archived: false,
        ),
        DateTime.fromMillisecondsSinceEpoch(1757607200000),
      );

      final Map<String, String> q = seen.single.queryParameters;
      expect(q['updated_since'], '1757607200');
      expect(q['section_id'], '3');
      expect(q['limit'], '${ApiWorksRepository.changesLimit}');
      expect(q.containsKey('status'), isFalse);
      expect(q.containsKey('kind'), isFalse);
      expect(q.containsKey('attention'), isFalse);
      expect(changed.single.isActual, isFalse);
    });
  });

  group('действия', () {
    test('назначение уходит POST-ом с performer_id и отдаёт строку', () async {
      final List<Uri> seen = <Uri>[];
      final List<Object> bodies = <Object>[];
      final ApiWorksRepository repository = _repository(
        <String, Object?>{..._row, 'status': 'accepted'},
        seen: seen,
        bodies: bodies,
      );
      final WorkItem before = WorkItem.fromJson(
        <String, dynamic>{..._row, 'status': 'fresh'},
      );

      final WorkItem after = await repository.assign(
        before,
        const WorkEmployee(id: 11, name: 'Иванов', specialty: 'Механик'),
      );

      expect(seen.single.path, endsWith('/work/breakdown/1042/assign/'));
      expect(bodies.single, <String, int>{'performer_id': 11});
      expect(after.status, WorkStatus.accepted);
    });

    test('«проверил» — по адресу review, 404 — понятным словом', () async {
      final List<Uri> seen = <Uri>[];
      final ApiWorksRepository ok = _repository(
        <String, Object?>{..._row, 'reviewed': true},
        seen: seen,
      );
      final WorkItem row = WorkItem.fromJson(Map<String, dynamic>.of(_row));
      expect((await ok.review(row)).reviewed, isTrue);
      expect(seen.single.path, endsWith('/work/breakdown/1042/review/'));

      final ApiWorksRepository gone = _repository(
        <String, Object?>{},
        status: 404,
      );
      expect(
        () => gone.review(row),
        throwsA(
          isA<WorksException>().having(
            (WorksException e) => e.message,
            'message',
            'Этой работы больше нет в ленте',
          ),
        ),
      );
    });
  });

  group('новая работа', () {
    const Map<String, Object?> context = <String, Object?>{
      'objects': <Object?>[
        <String, Object?>{
          'id': 7,
          'name': 'ТЦ Карнавал',
          'address': 'ул. Ленина, 12',
          'type': 'Лифт с МП',
          'factory_number': '4471',
          'registration_number': 'ЛФ-01-2231',
          'section_id': 1,
          'section': 'Центр',
          'mechanic_id': 11,
          'mechanic': 'Иванов А. С.',
          'foreman': 'Морозов П. Е.',
          'contact_name': 'Администрация ТЦ',
          'contact_phone': '+7 900 200-00-01',
        },
      ],
      'categories': <Object?>[
        <String, Object?>{
          'id': 1,
          'code': 'AA',
          'name': 'Застревание пассажира. Опасность',
          'counts_as_breakdown': true,
        },
        <String, Object?>{
          'id': 6,
          'code': 'ТО',
          'name': 'Плановые работы',
          'counts_as_breakdown': false,
        },
        <String, Object?>{
          'id': 11,
          'code': 'Р',
          'name': 'Ремонт по заявке',
          'counts_as_breakdown': false,
        },
      ],
      'employees': <Object?>[
        <String, Object?>{'id': 11, 'name': 'Иванов А. С.', 'specialty': 'Механик'},
        <String, Object?>{'id': 31, 'name': 'УК «Речная»', 'specialty': 'Заказчик'},
      ],
      'open_works': <String, Object?>{
        '7': <Object?>[
          <String, Object?>{
            'kind': 'breakdown',
            'status': 'running',
            'title': 'Стоит между этажами',
            'performer': 'Иванов А. С.',
          },
        ],
      },
      'my_sections': <int>[1],
      'author': 'Морозов П. Е.',
    };

    test('справочники разбираются, ТО и «Ложный вызов» в форму не идут', () async {
      final List<Uri> seen = <Uri>[];
      final NewWorkContext data = await _repository(
        context,
        seen: seen,
      ).newWorkContext();

      expect(seen.single.path, endsWith('/work/new/context'));
      expect(data.author, 'Морозов П. Е.');
      expect(data.mySections, <int>{1});

      final NewWorkObject object = data.objects.single;
      expect(object.name, 'ТЦ Карнавал');
      expect(object.mechanicId, 11);
      expect(object.contactPhone, '+7 900 200-00-01');
      expect(object.matches('карнавал 4471'), isTrue);

      expect(data.categories.map((NewWorkCategory c) => c.code), <String>[
        'AA',
        'Р',
      ]);
      expect(data.categoriesFor(NewWorkKind.request).single.name, 'Ремонт по заявке');
      expect(data.employeeById(31)!.specialty, 'Заказчик');

      final NewWorkOpenItem open = data.openWorks[7]!.single;
      expect(open.kind, WorkKind.breakdown);
      expect(open.status, WorkStatus.running);
      expect(open.title, 'Стоит между этажами');
    });

    test('создание уходит POST /order/ и отдаёт номер заявки', () async {
      final List<Uri> seen = <Uri>[];
      final List<Object> bodies = <Object>[];
      final NewWorkContext data = NewWorkContext.fromJson(context);
      final int id = await _repository(
        <String, Object?>{'id': 1105, 'task_text': 'Заменить кнопку'},
        seen: seen,
        bodies: bodies,
      ).createWork(
        NewWorkDraft(
          kind: NewWorkKind.request,
          object: data.objects.single,
          category: data.categoriesFor(NewWorkKind.request).single,
          description: 'Заменить кнопку',
        ),
      );

      expect(id, 1105);
      expect(seen.single.path, endsWith('/order/'));
      expect(bodies.single, <String, Object?>{
        'object_id': 7,
        'fault_category_id': 11,
        'executor_id': null,
        'task_text': 'Заменить кнопку',
      });
    });

    test('отказ сервера — его словами из description', () async {
      final ApiWorksRepository repository = ApiWorksRepository(
        send: (Uri uri) async => http.Response('', 200),
        post: (Uri uri, Object payload) async => http.Response.bytes(
          utf8.encode(
            jsonEncode(<String, Object?>{
              'message': 'Error',
              'description': 'Нет такого пользователя!',
            }),
          ),
          404,
        ),
      );
      final NewWorkContext data = NewWorkContext.fromJson(context);
      expect(
        () => repository.createWork(
          NewWorkDraft(
            kind: NewWorkKind.breakdown,
            object: data.objects.single,
            category: data.categoriesFor(NewWorkKind.breakdown).single,
          ),
        ),
        throwsA(
          isA<WorksException>().having(
            (WorksException e) => e.message,
            'message',
            'Нет такого пользователя!',
          ),
        ),
      );
    });
  });

  test('ошибка сервера — коротким словом, без стектрейса', () async {
    final ApiWorksRepository repository = _repository(
      <String, Object?>{},
      status: 500,
    );
    expect(
      () => repository.fetch(const WorkFilters()),
      throwsA(
        isA<WorksException>().having(
          (WorksException e) => e.message,
          'message',
          'Сервер ответил ошибкой 500',
        ),
      ),
    );
  });
}
