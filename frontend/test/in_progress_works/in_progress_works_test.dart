/// Разбор раздела «Сейчас в работе».
///
/// Проверяется то, что ломается молча: числа заголовка приходят с сервера
/// отдельно от списка, и посчитай их экран сам — при обрезке он соврал бы про
/// остаток и потерял бы красную пометку.
library;

import 'package:els/screns/in_progress_works/models/in_progress_work.dart';
// Справочник видов работ общий с лентой сданных — своего у раздела нет.
import 'package:els/screns/submitted_works/models/submitted_work.dart'
    show WorkKind;
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _work({
  String kind = 'maintenance',
  int workId = 12,
  String state = 'running',
  Object? since = 1786000000,
  Object? startedAt = 1786000000,
  Object? reason,
  Object? title = 'ТО-1',
  Object? progress = const <String, dynamic>{'done': 4, 'total': 12},
  Object? taskText,
}) {
  return <String, dynamic>{
    'kind': kind,
    'work_id': workId,
    'state': state,
    'since': since,
    'started_at': startedAt,
    'reason': reason,
    'title': title,
    'progress': progress,
    'task_text': taskText,
    'performer': 'Механик Ковалёв',
    'object': const <String, dynamic>{
      'id': 3,
      'name': 'Лифт 12',
      'address': 'пр. Ленина, 48',
    },
  };
}

Map<String, dynamic> _feed({
  List<Map<String, dynamic>>? items,
  Object? total = 1,
  Object? problems = 0,
}) {
  return <String, dynamic>{
    'data': <String, dynamic>{
      'items': items ?? <Map<String, dynamic>>[_work()],
      'total': total,
      'problems': problems,
    },
  };
}

void main() {
  test('числа заголовка берутся с провода, а не из длины списка', () {
    final InProgressWorks works = InProgressWorks.fromJson(
      _feed(items: <Map<String, dynamic>>[_work(), _work(workId: 13)],
          total: 22, problems: 3),
    );

    expect(works.items.length, 2);
    expect(works.total, 22);
    expect(works.problems, 3);
    // Остаток — то, что не поместилось: раздел подписывает его «и ещё N».
    expect(works.hidden, 20);
  });

  test('без чисел в ответе раздел не падает и считает по списку', () {
    final InProgressWorks works = InProgressWorks.fromJson(<String, dynamic>{
      'data': <String, dynamic>{
        'items': <Map<String, dynamic>>[
          _work(),
          _work(workId: 13, state: 'problem', since: null),
        ],
      },
    });

    expect(works.total, 2);
    expect(works.problems, 1);
    expect(works.hidden, 0);
  });

  test('заявка приходит без чек-листа и без регламента', () {
    final InProgressWorks works = InProgressWorks.fromJson(
      _feed(
        items: <Map<String, dynamic>>[
          _work(
            kind: 'breakdown',
            title: null,
            progress: null,
            taskText: 'Не открываются двери',
          ),
        ],
      ),
    );
    final InProgressWork work = works.items.single;

    expect(work.kind, WorkKind.breakdown);
    expect(work.progress, isNull);
    expect(work.title, isNull);
    expect(work.taskText, 'Не открываются двери');
  });

  test('пустой раздел — это пустой список, а не отсутствие данных', () {
    final InProgressWorks works = InProgressWorks.fromJson(
      _feed(items: <Map<String, dynamic>>[], total: 0),
    );

    expect(works.isEmpty, isTrue);
    expect(works.total, 0);
    expect(works.hidden, 0);
  });

  test('пилюля считает время от заданного момента, а не от «сейчас»', () {
    final InProgressWork work =
        InProgressWorks.fromJson(_feed()).items.single;
    final DateTime from = work.pillSince!;

    expect(work.pillLabel(now: from.add(const Duration(minutes: 40))),
        'Идёт · 40 мин');
    expect(work.pillLabel(now: from.add(const Duration(minutes: 70))),
        'Идёт · 1 ч 10 мин');
    expect(work.pillLabel(now: from.add(const Duration(hours: 2))), 'Идёт · 2 ч');
  });

  test('заявку берут «в работу», а не «идёт»', () {
    final InProgressWork work = InProgressWorks.fromJson(
      _feed(
        items: <Map<String, dynamic>>[_work(kind: 'breakdown', title: null)],
      ),
    ).items.single;

    expect(work.pillLabel(now: work.pillSince!.add(const Duration(minutes: 25))),
        'В работе · 25 мин');
  });

  test('у проблемы времени нет — и таймеру не от чего считать', () {
    final InProgressWork work = InProgressWorks.fromJson(
      _feed(
        items: <Map<String, dynamic>>[
          _work(state: 'problem', since: null, reason: 'Нет запчасти'),
        ],
      ),
    ).items.single;

    expect(work.pillSince, isNull);
    expect(work.pillLabel(now: DateTime.now()), 'Проблема');
  });

  test('пауза считает от момента остановки', () {
    final InProgressWork work = InProgressWorks.fromJson(
      _feed(
        items: <Map<String, dynamic>>[_work(state: 'paused')],
      ),
    ).items.single;

    expect(work.pillLabel(now: work.pillSince!.add(const Duration(minutes: 70))),
        'Пауза · 1 ч 10 мин');
  });

  test('часы прораба впереди серверных — счёт не уходит в минус', () {
    final InProgressWork work =
        InProgressWorks.fromJson(_feed()).items.single;

    expect(
      work.pillLabel(now: work.pillSince!.subtract(const Duration(minutes: 5))),
      'Идёт · меньше минуты',
    );
  });
}
