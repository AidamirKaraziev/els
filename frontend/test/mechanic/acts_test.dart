/// Чек-лист акта: разбор ответа и сборка тела для `PUT /act-fact/{id}/`.
///
/// Проверяется то, на чём держится поток ТО: номер шага должен пережить
/// отправку. Пункт, ушедший без номера, считается на бэкенде новым — снимки
/// старого к нему не перейдут, а в акте появится дубль пункта. Ошибка здесь
/// не видна на экране и вылезает у прораба через месяц.
library;

import 'package:els/mechanic/data/acts.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> actRow({
  String? title = 'ТО-1',
  List<Map<String, dynamic>>? steps,
}) {
  return <String, dynamic>{
    'id': 2481,
    'checklist': <String, dynamic>{
      'title': title,
      'steps': steps ??
          <Map<String, dynamic>>[
            <String, dynamic>{
              'id': 1,
              'title': 'Осмотр машинного помещения',
              'done': true,
              'comment': 'Пыльно, убрал',
            },
            <String, dynamic>{
              'id': 2,
              'title': 'Проверка тормоза лебёдки',
              'done': false,
              'comment': null,
            },
          ],
    },
  };
}

void main() {
  group('разбор ответа', () {
    test('пункты приходят с номерами, отметками и комментарием', () {
      final ActDetails act = actFromRow(actRow());

      expect(act.id, 2481);
      expect(act.title, 'ТО-1');
      expect(act.total, 2);
      expect(act.doneCount, 1);
      expect(act.steps.first.id, 1);
      expect(act.steps.first.done, isTrue);
      expect(act.steps.first.comment, 'Пыльно, убрал');
      expect(act.steps.last.comment, isNull);
    });

    test('пустой чек-лист — это «регламент не заполнен», а не сбой', () {
      final ActDetails act = actFromRow(
        actRow(title: null, steps: <Map<String, dynamic>>[]),
      );

      expect(act.empty, isTrue);
      expect(act.title, isNull);
      expect(act.doneCount, 0);
    });

    test('пункт без названия пропускается, остальные остаются', () {
      final ActDetails act = actFromRow(
        actRow(
          steps: <Map<String, dynamic>>[
            <String, dynamic>{'id': 1, 'title': '   ', 'done': true},
            <String, dynamic>{'id': 2, 'title': 'Канаты', 'done': false},
          ],
        ),
      );

      expect(act.total, 1);
      expect(act.steps.single.title, 'Канаты');
    });

    test('чек-лист без поля steps не роняет экран', () {
      final ActDetails act = actFromRow(<String, dynamic>{
        'id': 7,
        'checklist': <String, dynamic>{'title': 'ТО-2'},
      });

      expect(act.empty, isTrue);
      expect(act.id, 7);
    });
  });

  group('тело для отправки', () {
    test('номер шага сохраняется — иначе бэкенд заведёт пункт заново', () {
      final ActDetails act = actFromRow(actRow());
      final Map<String, dynamic> body = act.checklistBody();

      final List<dynamic> steps = body['steps'] as List<dynamic>;
      expect(body['title'], 'ТО-1');
      expect(steps.length, 2);
      expect((steps.first as Map<String, dynamic>)['id'], 1);
      expect((steps.last as Map<String, dynamic>)['id'], 2);
    });

    test('пустой комментарий не уходит на сервер', () {
      const ActStep step = ActStep(id: 3, title: 'Кабина', comment: '   ');

      expect(step.toBody().containsKey('comment'), isFalse);
    });

    test('комментарий уходит обрезанным по краям', () {
      const ActStep step = ActStep(id: 3, title: 'Кабина', comment: '  скол  ');

      expect(step.toBody()['comment'], 'скол');
    });

    test('пункт без номера уходит без ключа id', () {
      const ActStep step = ActStep(id: null, title: 'Новый пункт');

      expect(step.toBody().containsKey('id'), isFalse);
    });
  });

  group('правка пункта', () {
    test('меняется только отмеченный пункт, порядок сохраняется', () {
      final ActDetails act = actFromRow(actRow());
      final ActDetails next =
          act.withStepAt(1, act.steps[1].copyWith(done: true));

      expect(next.doneCount, 2);
      expect(next.steps[0].title, 'Осмотр машинного помещения');
      expect(next.steps[1].title, 'Проверка тормоза лебёдки');
      expect(next.steps[1].id, 2, reason: 'номер шага не должен потеряться');
      // Исходный акт не тронут: экран шагов держит его в состоянии и
      // подменяет целиком.
      expect(act.doneCount, 1);
    });

    test('номер за пределами списка ничего не ломает', () {
      final ActDetails act = actFromRow(actRow());

      expect(act.withStepAt(9, act.steps.first).doneCount, 1);
      expect(act.withStepAt(-1, act.steps.first).total, 2);
    });

    test('строка для локальной базы читается тем же разбором', () {
      final ActDetails act = actFromRow(actRow());
      final ActDetails again = actFromRow(act.toRow());

      expect(again.id, act.id);
      expect(again.title, act.title);
      expect(again.total, act.total);
      expect(again.doneCount, act.doneCount);
      expect(again.steps.first.comment, 'Пыльно, убрал');
    });
  });

  test('подпись прогресса', () {
    expect(progressText(5, 8), '5 из 8');
  });
}
