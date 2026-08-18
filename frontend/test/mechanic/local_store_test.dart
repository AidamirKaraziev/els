/// Локальная база механика: слияние присланного и метка синхронизации.
///
/// Здесь проверяется договорённость с бэкендом, а не хранение как таковое:
/// `changed_since` отдаёт только изменившееся, удалённая запись приходит с
/// `is_actual: false`, а метку двигаем по `updated_at` сервера. Ошибка в
/// любом из трёх пунктов означает либо потерянные правки, либо запись,
/// которая живёт на телефоне вечно.
library;

import 'package:els/mechanic/data/local_store.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> order(int id, {int updatedAt = 100, bool? isActual}) {
  return <String, dynamic>{
    'id': id,
    'updated_at': updatedAt,
    if (isActual != null) 'is_actual': isActual,
  };
}

void main() {
  group('mergeRows', () {
    test('новая запись добавляется, изменённая заменяет прежнюю', () {
      final List<Map<String, dynamic>> merged = mergeRows(
        <Map<String, dynamic>>[order(1, updatedAt: 10), order(2, updatedAt: 10)],
        <Map<String, dynamic>>[order(2, updatedAt: 20), order(3, updatedAt: 20)],
        idField: 'id',
      );

      expect(merged.map((Map<String, dynamic> row) => row['id']), <int>[1, 2, 3]);
      expect(
        merged.firstWhere((Map<String, dynamic> row) => row['id'] == 2)['updated_at'],
        20,
      );
    });

    test('запись с is_actual=false убирается с телефона', () {
      // Это единственный способ узнать об удалении: запись, которая просто
      // перестала приходить, от «не дошла страница» не отличить.
      final List<Map<String, dynamic>> merged = mergeRows(
        <Map<String, dynamic>>[order(1), order(2)],
        <Map<String, dynamic>>[order(2, updatedAt: 30, isActual: false)],
        idField: 'id',
      );

      expect(merged.map((Map<String, dynamic> row) => row['id']), <int>[1]);
    });

    test('удаление записи, которой на телефоне не было, ничего не ломает', () {
      final List<Map<String, dynamic>> merged = mergeRows(
        <Map<String, dynamic>>[order(1)],
        <Map<String, dynamic>>[order(5, isActual: false)],
        idField: 'id',
      );

      expect(merged.map((Map<String, dynamic> row) => row['id']), <int>[1]);
    });

    test('ключ берётся из указанного поля — у ТО это act_id', () {
      final List<Map<String, dynamic>> merged = mergeRows(
        <Map<String, dynamic>>[
          <String, dynamic>{'act_id': 1, 'steps_done': 0},
        ],
        <Map<String, dynamic>>[
          <String, dynamic>{'act_id': 1, 'steps_done': 3},
        ],
        idField: 'act_id',
      );

      expect(merged, hasLength(1));
      expect(merged.first['steps_done'], 3);
    });
  });

  group('latestMark', () {
    test('метка — самая поздняя правка из присланного', () {
      expect(
        latestMark(
          <Map<String, dynamic>>[order(1, updatedAt: 10), order(2, updatedAt: 40)],
          5,
        ),
        40,
      );
    });

    test('пустой ответ метку не двигает', () {
      // «Ничего не изменилось» — это не повод сдвинуть метку на «сейчас»:
      // между запросом и ответом на сервере могла появиться правка.
      expect(latestMark(<Map<String, dynamic>>[], 5), 5);
    });

    test('метка не едет назад', () {
      expect(latestMark(<Map<String, dynamic>>[order(1, updatedAt: 3)], 10), 10);
    });
  });

  group('LocalStore', () {
    test('данные разных людей лежат врозь', () async {
      final MemoryStore shared = MemoryStore();
      final LocalStore mine = LocalStore(userId: 1, store: shared);
      final LocalStore other = LocalStore(userId: 2, store: shared);

      await mine.write(LocalCollection.orders, <Map<String, dynamic>>[order(1)]);

      expect(await other.read(LocalCollection.orders), isEmpty);
      expect(await mine.read(LocalCollection.orders), hasLength(1));
    });

    test('выход забывает всё про человека', () async {
      final MemoryStore shared = MemoryStore();
      final LocalStore store = LocalStore(userId: 1, store: shared);
      await store.write(LocalCollection.orders, <Map<String, dynamic>>[order(1)]);
      await store.setMark(LocalCollection.orders, 42);

      await store.forget();

      expect(await store.read(LocalCollection.orders), isEmpty);
      expect(await store.mark(LocalCollection.orders), isNull);
    });

    test('испорченное хранилище не роняет приложение', () async {
      final MemoryStore shared = MemoryStore();
      await shared.write('mechanic.1.orders', 'не json');
      final LocalStore store = LocalStore(userId: 1, store: shared);

      expect(await store.read(LocalCollection.orders), isEmpty);
    });
  });
}
