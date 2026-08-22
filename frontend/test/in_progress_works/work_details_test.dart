/// Подробности работы: чек-лист, снимки, кому звонить.
///
/// Проверяется то, что ломается молча: порядок и обрыв чек-листа, разница
/// между «регламент не заполнен» и «ни одного пункта не отмечено», привязка
/// снимков к пунктам по номеру шага и разнобой в записи телефонов.
library;

import 'package:els/screns/in_progress_works/models/work_details.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _step(int id, String title, {bool done = false,
    String? comment}) {
  return <String, dynamic>{
    'id': id,
    'title': title,
    'done': done,
    'comment': comment,
  };
}

Map<String, dynamic> _act({
  List<Map<String, dynamic>>? steps,
  Object? startedAt = '2026-08-21T08:15:00',
  Object? pausedAt,
  Object? mechanicId = 7,
}) {
  return <String, dynamic>{
    'data': <String, dynamic>{
      'id': 12,
      'checklist': <String, dynamic>{
        'title': 'ТО-1',
        'steps': steps ?? <Map<String, dynamic>>[],
      },
      'started_at': startedAt,
      'paused_at': pausedAt,
      'commentary': 'Уехал на аварийный вызов',
      'main_mechanic_id': mechanicId,
    },
  };
}

List<Map<String, dynamic>> _twelveSteps() {
  return <Map<String, dynamic>>[
    _step(1, 'Осмотр машинного помещения', done: true),
    _step(2, 'Проверка тормозного устройства',
        done: true, comment: 'Колодки в норме'),
    _step(3, 'Проверка дверей шахты'),
    _step(4, 'Проверка ограничителя скорости', done: true),
    _step(5, 'Смазка направляющих'),
    _step(6, 'Осмотр канатов', done: true, comment: 'Износ выше нормы'),
    _step(7, 'Проверка привода дверей кабины'),
    _step(8, 'Проверка освещения'),
    _step(9, 'Проверка связи'),
    _step(10, 'Проверка ловителей'),
    _step(11, 'Проверка буферов'),
    _step(12, 'Уборка приямка'),
  ];
}

void main() {
  group('чек-лист', () {
    test('отмеченные идут первыми, внутри — порядок регламента', () {
      final WorkChecklist checklist =
          WorkDetails.fromJson(_act(steps: _twelveSteps())).checklist;

      expect(
        checklist.ordered.take(4).map((ChecklistStep s) => s.id).toList(),
        <int>[1, 2, 4, 6],
      );
      expect(
        checklist.ordered.skip(4).take(3).map((ChecklistStep s) => s.id)
            .toList(),
        <int>[3, 5, 7],
      );
    });

    test('видно шесть пунктов, остальные — за «и ещё N»', () {
      final WorkChecklist checklist =
          WorkDetails.fromJson(_act(steps: _twelveSteps())).checklist;

      expect(checklist.visible().length, 6);
      expect(checklist.hiddenCount, 6);
      expect(checklist.hiddenLabel, '…и ещё 6 пунктов');
      expect(checklist.visible(expanded: true).length, 12);
    });

    test('короткий чек-лист не обрывается', () {
      final WorkChecklist checklist = WorkDetails.fromJson(
        _act(steps: _twelveSteps().take(4).toList()),
      ).checklist;

      expect(checklist.visible().length, 4);
      expect(checklist.hiddenCount, 0);
    });

    test('«4 из 12» считается по отметкам', () {
      final WorkChecklist checklist =
          WorkDetails.fromJson(_act(steps: _twelveSteps())).checklist;

      expect(checklist.progressLabel, '4 из 12');
    });

    // «Регламент не заполнен» и «ни один пункт не отмечен» — разные вещи, и
    // карточка обязана говорить их разными словами.
    test('пустой чек-лист — это не ноль отмеченных', () {
      final WorkChecklist checklist = WorkDetails.fromJson(_act()).checklist;

      expect(checklist.isEmpty, isTrue);
      expect(checklist.total, 0);
    });

    test('пункт без названия отбрасывается, а не рисуется пустой строкой', () {
      final WorkChecklist checklist = WorkDetails.fromJson(
        _act(steps: <Map<String, dynamic>>[
          _step(1, 'Осмотр машинного помещения'),
          <String, dynamic>{'id': 2, 'done': true},
        ]),
      ).checklist;

      expect(checklist.total, 1);
    });
  });

  group('акт', () {
    // Бэкенд отдаёт времена акта наивной строкой, а хранит их в UTC. Прочти
    // её как местное — и карточка разойдётся со строкой списка ровно на
    // часовой пояс: там то же время приходит секундами эпохи.
    test('строка без пояса читается как UTC', () {
      final WorkDetails details = WorkDetails.fromJson(
        _act(pausedAt: '2026-08-21T09:05:00'),
      );

      expect(details.startedAt, DateTime.utc(2026, 8, 21, 8, 15).toLocal());
      expect(details.pausedAt, DateTime.utc(2026, 8, 21, 9, 5).toLocal());
    });

    test('строка с поясом не сдвигается второй раз', () {
      expect(
        WorkDetails.fromJson(_act(startedAt: '2026-08-21T08:15:00Z')).startedAt,
        DateTime.utc(2026, 8, 21, 8, 15).toLocal(),
      );
      expect(
        WorkDetails.fromJson(_act(startedAt: '2026-08-21T11:15:00+03:00'))
            .startedAt,
        DateTime.utc(2026, 8, 21, 8, 15).toLocal(),
      );
    });

    test('подпись времени — как в макете', () {
      expect(stampLabel(DateTime(2026, 8, 21, 8, 15)), '21.08.2026, 08:15');
    });

    test('пустая пауза остаётся пустой — работа не встала', () {
      expect(WorkDetails.fromJson(_act()).pausedAt, isNull);
      expect(stampLabel(null), isNull);
    });

    test('механик акта — тот, кому звонить', () {
      expect(WorkDetails.fromJson(_act()).mainMechanicId, 7);
      expect(WorkDetails.fromJson(_act(mechanicId: null)).mainMechanicId,
          isNull);
    });
  });

  group('снимки', () {
    // Снимок ссылается на номер шага, а не на его текст: пункты нельзя
    // переставлять после начала работ именно поэтому.
    test('раскладываются по пунктам по номеру шага', () {
      final WorkPhotos photos = WorkPhotos.fromJson(<String, dynamic>{
        'data': <Map<String, dynamic>>[
          <String, dynamic>{'id': 1, 'step_id': 2, 'photo': 'host/a.jpg'},
          <String, dynamic>{'id': 2, 'step_id': 2, 'photo': 'host/b.jpg'},
          <String, dynamic>{'id': 3, 'step_id': 6, 'photo': 'host/c.jpg'},
        ],
      });

      const ChecklistStep second =
          ChecklistStep(id: 2, title: 'Тормоз', done: true);
      const ChecklistStep third =
          ChecklistStep(id: 3, title: 'Двери', done: false);

      expect(photos.of(second), <String>['host/a.jpg', 'host/b.jpg']);
      expect(photos.of(third), isEmpty);
    });

    test('пункт без номера снимков не имеет', () {
      const ChecklistStep step =
          ChecklistStep(id: null, title: 'Новый пункт', done: false);

      expect(WorkPhotos.empty.of(step), isEmpty);
    });
  });

  group('исполнитель', () {
    Performer performer(Object? phone) {
      return Performer.fromJson(<String, dynamic>{
        'data': <String, dynamic>{
          'id': 7,
          'name': 'Сафин Р.',
          'contact_phone': phone,
          'working_specialty_id': <String, dynamic>{'title': 'Механик'},
        },
      });
    }

    // В справочнике номер лежит по-разному: старые экраны дописывали «+7» уже
    // при выводе, поэтому в поле встречается и голая десятка, и восьмёрка.
    test('десять цифр получают код страны', () {
      expect(performer('9990000000').callUri, '+79990000000');
    });

    test('восьмёрка становится семёркой', () {
      expect(performer('8 (999) 000-00-00').callUri, '+79990000000');
    });

    test('записанный с плюсом остаётся как есть', () {
      expect(performer('+7 999 000-00-00').callUri, '+79990000000');
    });

    test('номер показывается человеку разбитым', () {
      expect(performer('9990000000').phoneLabel, '+7 999 000-00-00');
    });

    test('короткий номер не подгоняется под маску', () {
      expect(performer('112').callUri, '112');
      expect(performer('112').phoneLabel, '112');
    });

    test('пустое поле — звонить некуда', () {
      expect(performer(null).hasPhone, isFalse);
      expect(performer('   ').hasPhone, isFalse);
      expect(performer('').callUri, isNull);
    });

    test('специальность приходит справочником', () {
      expect(performer('9990000000').specialty, 'Механик');
    });
  });

  group('«Обновлено»', () {
    final DateTime now = DateTime(2026, 8, 21, 12, 0);

    test('только что', () {
      expect(agoLabel(now.subtract(const Duration(seconds: 20)), now: now),
          'только что');
    });

    test('минуту назад', () {
      expect(agoLabel(now.subtract(const Duration(minutes: 1)), now: now),
          'минуту назад');
    });

    test('склонения минут', () {
      expect(agoLabel(now.subtract(const Duration(minutes: 3)), now: now),
          '3 минуты назад');
      expect(agoLabel(now.subtract(const Duration(minutes: 11)), now: now),
          '11 минут назад');
      expect(agoLabel(now.subtract(const Duration(minutes: 21)), now: now),
          '21 минуту назад');
    });

    test('часы', () {
      expect(agoLabel(now.subtract(const Duration(hours: 1)), now: now),
          'час назад');
      expect(agoLabel(now.subtract(const Duration(hours: 2)), now: now),
          '2 часа назад');
    });

    // Часы карточки могут уйти вперёд серверных: «через минуту» показывать
    // нельзя, а данные при этом на руках.
    test('время из будущего читается как «только что»', () {
      expect(agoLabel(now.add(const Duration(minutes: 5)), now: now),
          'только что');
    });
  });
}
