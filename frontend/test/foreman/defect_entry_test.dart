import 'package:els/foreman/defects/defect_entry.dart';
import 'package:flutter_test/flutter_test.dart';

/// Разбор ответа `GET /defective-act/…` в то, что показывают экраны прораба.
///
/// Формы взяты с живого стека: акт по заявке — снятый с ответа ленты объекта
/// 80 (`{"order_id": 53, "type_act": null, …}`), остальные собраны по тем же
/// правилам. Ручка отдаёт заметно больше полей, чем разбирается: лишнее
/// (участок, модель, компания внутри `planned_to_id`) здесь намеренно не
/// повторяется — экрану оно не нужно, и тест не должен делать вид, что нужно.
void main() {
  group('откуда заведён', () {
    test('пункт чек-листа — это работа плюс номер пункта', () {
      final DefectEntry entry = DefectEntry.fromJson(<String, dynamic>{
        'id': 12,
        'title': 'Износ каната',
        'act_fact_id': 74,
        'checklist_step_id': 14,
      });

      expect(entry.source, DefectSource.checklistStep);
    });

    test('работа по ТО — тот же act_fact_id, но без пункта', () {
      final DefectEntry entry = DefectEntry.fromJson(<String, dynamic>{
        'id': 11,
        'title': 'Дверь шахты',
        'act_fact_id': 74,
        'checklist_step_id': null,
      });

      expect(entry.source, DefectSource.work);
    });

    test('заявка', () {
      final DefectEntry entry = DefectEntry.fromJson(<String, dynamic>{
        'id': 3,
        'title': 'Неисправность дверей',
        'order_id': 53,
      });

      expect(entry.source, DefectSource.order);
    });

    test('без работы и без заявки остаётся только объект', () {
      final DefectEntry entry = DefectEntry.fromJson(<String, dynamic>{
        'id': 7,
        'title': 'Разбит плафон',
        'object_id': 80,
      });

      expect(entry.source, DefectSource.object);
    });
  });

  group('состояние', () {
    test('четыре известных значения разбираются', () {
      DefectState stateOf(String raw) => DefectEntry.fromJson(<String, dynamic>{
            'id': 1,
            'title': 'т',
            'state': raw,
          }).state;

      expect(stateOf('created'), DefectState.created);
      expect(stateOf('reviewed'), DefectState.reviewed);
      expect(stateOf('issued'), DefectState.issued);
      expect(stateOf('fixed'), DefectState.fixed);
    });

    test('незнакомое значение не роняет разбор', () {
      final DefectEntry entry = DefectEntry.fromJson(<String, dynamic>{
        'id': 1,
        'title': 'т',
        'state': 'что-то новое',
      });

      expect(entry.state, DefectState.unknown);
      expect(entry.state.label, 'Неизвестно');
    });
  });

  group('вид ТО', () {
    test('разворачивается из вложенного объекта', () {
      final DefectEntry entry = DefectEntry.fromJson(<String, dynamic>{
        'id': 12,
        'title': 'т',
        'act_fact_id': 74,
        'type_act': <String, dynamic>{'id': 2, 'name': 'ТО-1'},
      });

      expect(entry.typeActName, 'ТО-1');
    });

    test('у акта по заявке пуст — работы по ТО там не было', () {
      final DefectEntry entry = DefectEntry.fromJson(<String, dynamic>{
        'id': 3,
        'title': 'Неисправность дверей',
        'order_id': 53,
        'type_act': null,
      });

      expect(entry.typeActName, isNull);
    });
  });

  group('дата', () {
    test('метка приходит в секундах, а не в миллисекундах', () {
      final DefectEntry entry = DefectEntry.fromJson(<String, dynamic>{
        'id': 3,
        'title': 'т',
        // 2026-09-05 00:00 по времени машины: время суток бэкенд теряет,
        // см. `backend/src/utils/time_stamp.py`.
        'created_at': DateTime(2026, 9, 5).millisecondsSinceEpoch ~/ 1000,
      });

      expect(entry.createdAt, DateTime(2026, 9, 5));
    });

    test('без метки дата пуста, а не эпоха', () {
      final DefectEntry entry = DefectEntry.fromJson(<String, dynamic>{
        'id': 3,
        'title': 'т',
        'created_at': null,
      });

      expect(entry.createdAt, isNull);
    });
  });

  group('снимки', () {
    test('путь дополняется схемой', () {
      final DefectEntry entry = DefectEntry.fromJson(<String, dynamic>{
        'id': 3,
        'title': 'т',
        'photos': <dynamic>[
          <String, dynamic>{
            'id': 6,
            'photo': 'localhost:8080/api/v1/static/'
                'defective_act/3/photo/65f36e1c.jpeg',
          },
        ],
      });

      expect(entry.photos, hasLength(1));
      expect(entry.photos.single.id, 6);
      // Схему дописывает `apiImage`, а не разбор: адрес со схемой, пропущенный
      // через него ещё раз, превращается в `http://http://…`.
      expect(
        entry.photos.single.url,
        'localhost:8080/api/v1/static/defective_act/3/photo/65f36e1c.jpeg',
      );
    });

    test('запись без файла в галерею не попадает', () {
      final DefectEntry entry = DefectEntry.fromJson(<String, dynamic>{
        'id': 3,
        'title': 'т',
        'photos': <dynamic>[
          <String, dynamic>{'id': 6, 'photo': null},
          <String, dynamic>{'id': 7, 'photo': ''},
        ],
      });

      expect(entry.photos, isEmpty);
    });

    test('поля photos может не быть вовсе', () {
      final DefectEntry entry =
          DefectEntry.fromJson(<String, dynamic>{'id': 3, 'title': 'т'});

      expect(entry.photos, isEmpty);
    });
  });

  group('прочее', () {
    test('автор и месяц берутся из ответа', () {
      final DefectEntry entry = DefectEntry.fromJson(<String, dynamic>{
        'id': 3,
        'title': 'Неисправность дверей',
        'month': 9,
        'planned_to_id': <String, dynamic>{
          'year': '2026',
          'object_id': <String, dynamic>{'name': 'Эскалатор 2а'},
        },
        'created_by_user_id': <String, dynamic>{
          'id': 2,
          'name': 'Механик для Мобилки',
        },
      });

      expect(entry.authorName, 'Механик для Мобилки');
      expect(entry.monthName, 'сентябрь');
      expect(entry.year, '2026');
      expect(entry.objectName, 'Эскалатор 2а');
    });

    test('пустая строка — то же самое, что отсутствие поля', () {
      final DefectEntry entry = DefectEntry.fromJson(<String, dynamic>{
        'id': 3,
        'title': 'т',
        'description': '   ',
      });

      expect(entry.description, isNull);
    });

    test('месяц вне 1..12 названия не получает', () {
      DefectEntry withMonth(Object? month) =>
          DefectEntry.fromJson(<String, dynamic>{
            'id': 3,
            'title': 'т',
            'month': month,
          });

      expect(withMonth(0).monthName, isNull);
      expect(withMonth(13).monthName, isNull);
      expect(withMonth(null).monthName, isNull);
      expect(withMonth(1).monthName, 'январь');
      expect(withMonth(12).monthName, 'декабрь');
    });
  });
}
