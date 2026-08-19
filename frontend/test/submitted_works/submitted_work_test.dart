/// Разбор ленты сданных работ.
///
/// Проверяется то, что ломается молча: у строки почти каждое поле законно
/// приходит `null` — заявка без объекта, ТО без задания, работа без
/// исполнителя, — и экран обязан это пережить, а не показать пустоту вместо
/// сданной работы.
library;

import 'package:els/screns/submitted_works/models/submitted_work.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _row({
  String kind = 'breakdown',
  int workId = 12,
  Object? outcome = 'done',
  Object? object = const <String, dynamic>{
    'id': 3,
    'name': 'Лифт 12',
    'address': 'ул. Сданная, 4',
  },
  Object? taskText = 'Не закрывается дверь',
  Object? performer = 'Механик Петров',
  Object? closedAt = 1786000000,
  Object? reviewedAt,
  Object? reviewer,
}) {
  return <String, dynamic>{
    'kind': kind,
    'work_id': workId,
    'outcome': outcome,
    'object': object,
    'task_text': taskText,
    'performer': performer,
    'closed_at': closedAt,
    'reviewed_at': reviewedAt,
    'reviewer': reviewer,
  };
}

Map<String, dynamic> _feed(
  List<Map<String, dynamic>> rows, {
  Object? paginator = const <String, dynamic>{
    'page': 2,
    'total': 5,
    'has_prev': true,
    'has_next': true,
  },
}) {
  return <String, dynamic>{
    'data': rows,
    'meta': <String, dynamic>{'paginator': paginator},
  };
}

void main() {
  group('SubmittedWork', () {
    test('строка ленты разбирается целиком', () {
      final SubmittedWork work = SubmittedWork.fromJson(_row());

      expect(work.kind, WorkKind.breakdown);
      expect(work.workId, 12);
      expect(work.objectLabel, 'Лифт 12');
      expect(work.addressLabel, 'ул. Сданная, 4');
      expect(work.taskLabel, 'Не закрывается дверь');
      expect(work.performerLabel, 'Механик Петров');
      expect(work.isReviewed, isFalse);
      expect(work.isProblem, isFalse);
    });

    test('«Проблема» видна отдельно от вида работы', () {
      final SubmittedWork work =
          SubmittedWork.fromJson(_row(outcome: 'problem'));

      // Авария, которую не смогли устранить, остаётся аварией.
      expect(work.kind, WorkKind.breakdown);
      expect(work.isProblem, isTrue);
    });

    test('строка без исхода считается удавшейся работой', () {
      // Поле необязательное: старый бэкенд его не отдаёт вовсе.
      expect(SubmittedWork.fromJson(_row(outcome: null)).isProblem, isFalse);
    });

    test('заявка без объекта не роняет строку', () {
      final SubmittedWork work = SubmittedWork.fromJson(_row(object: null));

      expect(work.objectLabel, 'Объект не указан');
      expect(work.addressLabel, isNull);
    });

    test('объект без названия подписан своим id', () {
      final SubmittedWork work = SubmittedWork.fromJson(
        _row(object: <String, dynamic>{'id': 42}),
      );

      // «Объект 42» лучше пустой строки: по нему хотя бы понятно, что
      // спрашивать.
      expect(work.objectLabel, 'Объект 42');
    });

    test('незнакомый вид работы показывается, а не прячется', () {
      final SubmittedWork work = SubmittedWork.fromJson(_row(kind: 'что-то'));

      expect(work.kind, WorkKind.request);
      expect(work.kindLabel, 'Заявка');
    });

    test('ТО без задания не выдумывает себе текст', () {
      final SubmittedWork work = SubmittedWork.fromJson(
        _row(kind: 'maintenance', taskText: null),
      );

      expect(work.kind, WorkKind.maintenance);
      expect(work.taskLabel, isNull);
    });

    test('дата сдачи несёт время суток', () {
      final SubmittedWork work = SubmittedWork.fromJson(
        _row(
          closedAt: DateTime(2026, 8, 11, 9, 30).millisecondsSinceEpoch ~/ 1000,
        ),
      );

      // За день на объекте бывает несколько выходов, и без часов их не
      // различить.
      expect(work.closedLabel, '11.08.2026, 09:30');
    });

    test('пустая дата не превращается в 1970 год', () {
      final SubmittedWork work = SubmittedWork.fromJson(_row(closedAt: null));

      expect(work.closedAt, isNull);
      expect(work.closedLabel, '—');
    });

    test('отметка подписана тем, кто её поставил', () {
      final SubmittedWork work = SubmittedWork.fromJson(
        _row(
          reviewedAt:
              DateTime(2026, 8, 12, 10, 15).millisecondsSinceEpoch ~/ 1000,
          reviewer: 'Прораб Сидоров',
        ),
      );

      expect(work.isReviewed, isTrue);
      expect(work.reviewedLabel, 'Проверил Прораб Сидоров, 12.08.2026, 10:15');
    });

    test('отметка без имени всё равно читается', () {
      final SubmittedWork work =
          SubmittedWork.fromJson(_row()).markedReviewed(
        by: null,
        at: DateTime(2026, 8, 12, 10, 15),
      );

      expect(work.reviewedLabel, 'Проверено 12.08.2026, 10:15');
      // Остальное у копии на месте — иначе строка мигнёт пустотой.
      expect(work.objectLabel, 'Лифт 12');
      expect(work.workId, 12);
    });

    test('вид работы даёт адрес для отметки', () {
      expect(kindPathSegment(WorkKind.clientRequest), 'client_request');
      expect(kindPathSegment(WorkKind.maintenance), 'maintenance');
    });
  });

  group('SubmittedWorksPage', () {
    test('страница разбирается вместе со стрелками', () {
      final SubmittedWorksPage page =
          SubmittedWorksPage.fromJson(_feed(<Map<String, dynamic>>[_row()]), 2);

      expect(page.items, hasLength(1));
      expect(page.page, 2);
      expect(page.pageCount, 5);
      expect(page.hasPrev, isTrue);
      expect(page.hasNext, isTrue);
    });

    test('выдача без паджинатора — одна страница без стрелок', () {
      // Ручка отдаёт `paginator: null`, если параметр страницы не передали.
      final SubmittedWorksPage page = SubmittedWorksPage.fromJson(
        _feed(<Map<String, dynamic>>[_row()], paginator: null),
        1,
      );

      expect(page.page, 1);
      expect(page.pageCount, 1);
      expect(page.hasPrev, isFalse);
      expect(page.hasNext, isFalse);
    });

    test('пустая лента — это не ошибка', () {
      final SubmittedWorksPage page =
          SubmittedWorksPage.fromJson(_feed(const <Map<String, dynamic>>[]), 1);

      expect(page.isEmpty, isTrue);
    });
  });
}
