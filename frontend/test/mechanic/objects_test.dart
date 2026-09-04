/// Свои объекты: список собирается из работ, а не с сервера.
///
/// Проверяется правило: один объект — одна строка, сколько бы работ по нему
/// ни было, и адрес не теряется из-за того, что первой пришла работа, где
/// его не прислали.
library;

import 'package:els/mechanic/data/objects.dart';
import 'package:els/mechanic/data/tasks.dart';
import 'package:flutter_test/flutter_test.dart';

MechanicTask _order(Map<String, dynamic> object) {
  return MechanicTask(
    kind: TaskKind.order,
    id: 1,
    title: 'Заявка',
    section: TaskSection.now,
    rank: 1,
    order: 0,
    raw: <String, dynamic>{'object_id': object},
  );
}

MechanicTask _maintenance(Map<String, dynamic> object) {
  return MechanicTask(
    kind: TaskKind.maintenance,
    id: 2,
    title: 'ТО',
    section: TaskSection.maintenance,
    rank: 1,
    order: 0,
    raw: <String, dynamic>{'object': object},
  );
}

void main() {
  test('объект берётся и из заявки, и из планового ТО', () {
    final List<MechanicObject> objects = objectsFromTasks(<MechanicTask>[
      _order(<String, dynamic>{
        'id': 7,
        'name': 'Лифт 12',
        'address': 'улица Ленина 45',
        'factory_model_id': <String, dynamic>{
          'type_object_id': <String, dynamic>{'name': 'Лифт'},
        },
      }),
      _maintenance(<String, dynamic>{'id': 9, 'name': 'Эскалатор 3'}),
    ]);

    expect(objects.length, 2);
    expect(objects.first.name, 'Лифт 12');
    expect(objects.first.address, 'улица Ленина 45');
    expect(objects.first.badge, 'Лифт');
    expect(objects.last.name, 'Эскалатор 3');
  });

  test('один объект в нескольких работах остаётся одной строкой', () {
    final List<MechanicObject> objects = objectsFromTasks(<MechanicTask>[
      _order(<String, dynamic>{'id': 7, 'name': 'Лифт 12'}),
      _maintenance(<String, dynamic>{'id': 7, 'name': 'Лифт 12'}),
      _order(<String, dynamic>{'id': 7, 'name': 'Лифт 12'}),
    ]);

    expect(objects.length, 1);
  });

  test('адрес добирается из следующей работы, если в первой его не было', () {
    final List<MechanicObject> objects = objectsFromTasks(<MechanicTask>[
      _maintenance(<String, dynamic>{'id': 7, 'name': 'Лифт 12'}),
      _order(<String, dynamic>{
        'id': 7,
        'name': 'Лифт 12',
        'address': 'улица Ленина 45',
      }),
    ]);

    expect(objects.single.address, 'улица Ленина 45');
  });

  test('объект без номера в список не попадает', () {
    expect(
      objectsFromTasks(<MechanicTask>[
        _order(<String, dynamic>{'name': 'Лифт без id'}),
      ]),
      isEmpty,
    );
  });

  test('порядок — по названию, а не по свежести работы', () {
    final List<MechanicObject> objects = objectsFromTasks(<MechanicTask>[
      _order(<String, dynamic>{'id': 2, 'name': 'Лифт 12'}),
      _order(<String, dynamic>{'id': 1, 'name': 'Травалатор 1'}),
      _order(<String, dynamic>{'id': 3, 'name': 'Аварийный подъёмник'}),
    ]);

    expect(objects.map((MechanicObject o) => o.id).toList(), <int>[3, 2, 1]);
  });
}
