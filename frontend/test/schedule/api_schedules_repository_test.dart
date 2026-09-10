/// Разбор ответов раздела «Графики».
///
/// Тесты экрана держатся за фикстуру и проверяют вёрстку. Здесь наоборот:
/// вёрстки нет, есть готовый ответ сервера и вопрос, что репозиторий из него
/// достанет. Ошибиться тут дороже всего — неверно прочитанный `has_next`
/// виден не как исключение, а как молча пропавшая половина ленты.
library;

import 'dart:convert';

import 'package:els/screns/schedule/models/schedule_filters.dart';
import 'package:els/screns/schedule/repository/api_schedules_repository.dart';
import 'package:els/screns/schedule/repository/schedules_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

/// Репозиторий с заранее заготовленным ответом. Заодно запоминает адрес:
/// половина смысла ручки — в том, какие параметры до неё доехали.
ApiSchedulesRepository _repository(
  String body, {
  int status = 200,
  List<Uri>? seen,
}) {
  return ApiSchedulesRepository(
    send: (Uri uri) async {
      seen?.add(uri);
      return http.Response.bytes(utf8.encode(body), status);
    },
  );
}

ApiSchedulesRepository _failing() {
  return ApiSchedulesRepository(
    send: (Uri uri) async => throw Exception('обрыв'),
  );
}

void main() {
  group('лента', () {
    test('строки и признак догрузки берутся из конверта', () async {
      final ApiSchedulesRepository repository = _repository(
        jsonEncode({
          'data': [
            {
              'object_id': 7,
              'name': 'Спортмастер',
              'year': 2026,
              'cells': [
                {'month': 3, 'status': 'done', 'to_name': 'ТО 6', 'act_id': 12},
              ],
            },
          ],
          'meta': {
            'paginator': {
              'page': 1,
              'total': 3,
              'has_prev': false,
              'has_next': true,
            },
          },
        }),
      );

      final SchedulePage page = await repository.fetchRows(
        filters: const ScheduleFilters(year: 2026),
        page: 1,
      );

      expect(page.items.single.objectId, 7);
      // Недостающие месяцы дорисованы: колонки не имеют права разъехаться.
      expect(page.items.single.cells.length, 12);
      expect(page.hasNext, isTrue);
    });

    test(
      'число дефектных актов читается из строки, без поля — пусто',
      () async {
        final ApiSchedulesRepository repository = _repository(
          jsonEncode({
            'data': [
              {
                'object_id': 7,
                'name': 'С актами',
                'year': 2026,
                'cells': [],
                'defects_count': 5,
              },
              {'object_id': 8, 'name': 'Без поля', 'year': 2026, 'cells': []},
            ],
          }),
        );

        final SchedulePage page = await repository.fetchRows(
          filters: const ScheduleFilters(year: 2026),
          page: 1,
        );

        expect(page.items[0].defectsCount, 5);
        // Старый сервер без поля — значка нет, а не серый «дефектов не было».
        expect(page.items[1].defectsCount, isNull);
      },
    );

    test('без метаданных догружать нечего', () async {
      // Лишняя страница вхолостую лучше, чем бесконечный скролл в пустоту.
      final ApiSchedulesRepository repository = _repository(
        jsonEncode({'data': <dynamic>[]}),
      );

      final SchedulePage page = await repository.fetchRows(
        filters: const ScheduleFilters(year: 2026),
        page: 1,
      );

      expect(page.items, isEmpty);
      expect(page.hasNext, isFalse);
    });

    test('фильтры и номер страницы уезжают на сервер', () async {
      final List<Uri> seen = <Uri>[];
      final ApiSchedulesRepository repository = _repository(
        jsonEncode({'data': <dynamic>[]}),
        seen: seen,
      );

      await repository.fetchRows(
        filters: const ScheduleFilters(
          year: 2026,
          search: 'Спортмастер',
          division: FilterOption(id: 4, title: 'Участок № 1'),
          state: ScheduleState.hasOverdue,
        ),
        page: 2,
      );

      final Map<String, String> query = seen.single.queryParameters;

      expect(seen.single.path, endsWith('/schedules/rows'));
      // Поиск и фильтр складываются: ищем внутри выбранного участка, а не
      // вместо него.
      expect(query['search'], 'Спортмастер');
      expect(query['division_id'], '4');
      expect(query['schedule_state'], 'has_overdue');
      expect(query['page'], '2');
    });

    test('«Без участка» уходит своим параметром, а не пустым id', () async {
      // `division_id` тут не годится: пусто там означает «не фильтруем».
      final List<Uri> seen = <Uri>[];
      final ApiSchedulesRepository repository = _repository(
        jsonEncode({'data': <dynamic>[]}),
        seen: seen,
      );

      await repository.fetchRows(
        filters: const ScheduleFilters(year: 2026, division: kWithoutDivision),
        page: 1,
      );

      final Map<String, String> query = seen.single.queryParameters;

      expect(query['without_division'], 'true');
      expect(query.containsKey('division_id'), isFalse);
    });
  });

  group('фильтры', () {
    test('четыре списка разбираются в значения выпадающих', () async {
      final ApiSchedulesRepository repository = _repository(
        jsonEncode({
          'data': {
            'divisions': [
              {'id': 4, 'title': 'Участок № 1'},
            ],
            'types': [
              {'id': 1, 'title': 'Лифт без МП'},
            ],
            'names': [
              {'id': 0, 'title': 'Спортмастер'},
            ],
            'factory_numbers': [
              {'id': 0, 'title': 'F-1024'},
            ],
          },
        }),
      );

      final ScheduleFilterOptions options = await repository
          .fetchFilterOptions();

      expect(
        options.divisions.single,
        const FilterOption(id: 4, title: 'Участок № 1'),
      );
      expect(options.types.single.title, 'Лифт без МП');
      expect(options.names.single.title, 'Спортмастер');
      expect(options.factoryNumbers.single.title, 'F-1024');
    });
  });

  group('ошибки', () {
    test('403 — про права, а не про код ответа', () async {
      final ApiSchedulesRepository repository = _repository('', status: 403);

      expect(
        () => repository.fetchFilterOptions(),
        throwsA(
          isA<SchedulesException>().having(
            (SchedulesException error) => error.message,
            'message',
            'Недостаточно прав или истёк вход',
          ),
        ),
      );
    });

    test('500 называет код', () async {
      final ApiSchedulesRepository repository = _repository('', status: 500);

      expect(
        () => repository.fetchRows(
          filters: const ScheduleFilters(year: 2026),
          page: 1,
        ),
        throwsA(
          isA<SchedulesException>().having(
            (SchedulesException error) => error.message,
            'message',
            'Сервер ответил ошибкой 500',
          ),
        ),
      );
    });

    test('обрыв связи — один текст на все причины', () async {
      // Обрыв, таймаут и CORS для человека одно и то же: действие одно —
      // повторить.
      expect(
        () => _failing().fetchRows(
          filters: const ScheduleFilters(year: 2026),
          page: 1,
        ),
        throwsA(
          isA<SchedulesException>().having(
            (SchedulesException error) => error.message,
            'message',
            'Не удалось связаться с сервером',
          ),
        ),
      );
    });

    test('не тот конверт — не падение с разбором', () async {
      final ApiSchedulesRepository repository = _repository('не json');

      expect(
        () => repository.fetchFilterOptions(),
        throwsA(isA<SchedulesException>()),
      );
    });
  });
}
