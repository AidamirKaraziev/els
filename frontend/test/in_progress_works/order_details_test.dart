/// Разбор ответа заявки.
///
/// Проверяется то, чем карточка заявки отличается от карточки ТО: категория
/// собирается из кода и полного имени, пустое задание остаётся пустым (слова
/// вместо него говорит экран), время заведения приходит секундами эпохи, а
/// исполнитель лежит внутри самой заявки — с телефоном.
library;

import 'package:els/screns/in_progress_works/models/order_details.dart';
import 'package:els/screns/in_progress_works/models/work_details.dart';
import 'package:flutter_test/flutter_test.dart';

int _seconds(DateTime at) => at.millisecondsSinceEpoch ~/ 1000;

Map<String, dynamic> _order({
  Object? task = 'Не открываются двери на четвёртом этаже',
  Object? category = const <String, dynamic>{
    'id': 1,
    'name': 'AA (Застревание пассажира. Опасность)',
    'code': 'AA',
  },
  Object? reason,
  Object? createdAt,
  Object? executor,
}) {
  return <String, dynamic>{
    'data': <String, dynamic>{
      'id': 34,
      'task_text': task,
      'fault_category_id': category,
      'reason_fault_id': reason,
      'created_at': createdAt,
      'executor_id': executor,
    },
  };
}

void main() {
  group('задание', () {
    test('приходит как записал диспетчер', () {
      final OrderDetails order = OrderDetails.fromJson(_order());

      expect(order.id, 34);
      expect(order.taskLabel, 'Не открываются двери на четвёртом этаже');
    });

    // Заявку заводят по звонку, и текст пишут не всегда. Пустая строка и
    // пробелы — то же самое, что отсутствие поля: сказать словами, что
    // задания нет, должен экран, а не модель.
    test('пустое поле остаётся пустым', () {
      expect(OrderDetails.fromJson(_order(task: null)).taskLabel, isNull);
      expect(OrderDetails.fromJson(_order(task: '   ')).taskLabel, isNull);
    });
  });

  group('категория', () {
    test('код и слова, а не код дважды', () {
      final OrderDetails order = OrderDetails.fromJson(_order());

      // В базе полное имя начинается с кода: показать их подряд значило бы
      // «AA · AA (Застревание…)».
      expect(order.categoryLabel, 'AA · Застревание пассажира. Опасность');
    });

    test('имя непривычного вида показывается как записано', () {
      final OrderDetails order = OrderDetails.fromJson(
        _order(
          category: const <String, dynamic>{
            'name': 'Плановая замена',
            'code': 'ПЗ',
          },
        ),
      );

      expect(order.categoryLabel, 'Плановая замена');
    });

    test('без имени остаётся код, без обоих — слова', () {
      expect(
        OrderDetails.fromJson(
          _order(category: const <String, dynamic>{'code': 'AA'}),
        ).categoryLabel,
        'AA',
      );
      expect(
        OrderDetails.fromJson(_order(category: null)).categoryLabel,
        'Категория не указана',
      );
    });
  });

  group('причина неисправности', () {
    test('заполненная — строкой', () {
      final OrderDetails order = OrderDetails.fromJson(
        _order(
          reason: const <String, dynamic>{'id': 3, 'name': 'Не сработал УБ'},
        ),
      );

      expect(order.reasonLabel, 'Не сработал УБ');
    });

    // У идущей заявки причину обычно ещё не поставили: её заполняют, когда
    // разобрались.
    test('незаполненная — пусто', () {
      expect(OrderDetails.fromJson(_order()).reasonLabel, isNull);
    });
  });

  group('время заведения', () {
    // Время суток бэкенд теряет: `created_at` заявки всегда приезжает
    // полночью. Показываем день — часы были бы выдумкой.
    test('секунды эпохи становятся днём без часов', () {
      final DateTime created = DateTime(2026, 8, 21, 9, 40);
      final OrderDetails order =
          OrderDetails.fromJson(_order(createdAt: _seconds(created)));

      expect(order.createdAt, created);
      expect(order.createdLabel, '21.08.2026');
    });

    test('пустое поле — пустая подпись', () {
      expect(OrderDetails.fromJson(_order()).createdLabel, isNull);
      expect(OrderDetails.fromJson(_order(createdAt: 0)).createdLabel, isNull);
    });
  });

  group('исполнитель', () {
    test('приезжает внутри заявки, с телефоном и специальностью', () {
      final OrderDetails order = OrderDetails.fromJson(
        _order(
          executor: const <String, dynamic>{
            'id': 7,
            'name': 'Титов И.',
            'contact_phone': '89990000000',
            'working_specialty_id': <String, dynamic>{'title': 'Механик'},
          },
        ),
      );

      final Performer? executor = order.executor;
      expect(executor?.id, 7);
      expect(executor?.name, 'Титов И.');
      expect(executor?.specialty, 'Механик');
      expect(executor?.callUri, '+79990000000');
    });

    test('заявка без исполнителя — не сбой', () {
      expect(OrderDetails.fromJson(_order()).executor, isNull);
    });
  });

  group('снимки', () {
    test('плоским списком: пунктов у заявки нет', () {
      final OrderPhotos photos = OrderPhotos.fromJson(<String, dynamic>{
        'data': <Map<String, dynamic>>[
          <String, dynamic>{'id': 1, 'order_id': 34, 'photo': 'host/a.jpg'},
          <String, dynamic>{'id': 2, 'order_id': 34, 'photo': 'host/b.jpg'},
        ],
      });

      expect(photos.items, <String>['host/a.jpg', 'host/b.jpg']);
    });

    test('строки без файла пропускаются, а не рисуются пустыми рамками', () {
      final OrderPhotos photos = OrderPhotos.fromJson(<String, dynamic>{
        'data': <Map<String, dynamic>>[
          <String, dynamic>{'id': 1, 'photo': null},
          <String, dynamic>{'id': 2, 'photo': '  '},
        ],
      });

      expect(photos.isEmpty, isTrue);
    });

    test('ответ без списка — пусто, а не падение', () {
      expect(
        OrderPhotos.fromJson(<String, dynamic>{}).isEmpty,
        isTrue,
      );
    });
  });
}
