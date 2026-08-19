/// Очередь исходящих действий механика.
///
/// Проверяется то, чего не видно глазами и что нельзя проверить на объекте:
/// порядок отправки, поведение при обрыве связи и разница между «сейчас не
/// вышло» и «сервер отказал». Ошибка здесь стоит дорого — это работа, которую
/// человек уже сделал.
library;

import 'dart:async';

import 'package:els/mechanic/data/local_store.dart';
import 'package:els/mechanic/data/outbox.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Outbox', () {
    late MemoryStore store;
    late List<String> sent;

    setUp(() {
      store = MemoryStore();
      sent = <String>[];
    });

    Outbox outboxThat(SendOutcome Function(OutboxAction action) decide) {
      return Outbox(
        userId: 7,
        store: store,
        sender: (OutboxAction action) async {
          final SendOutcome outcome = decide(action);
          if (outcome == SendOutcome.done) sent.add(action.path);
          return outcome;
        },
      );
    }

    test('действия уходят в том порядке, в котором их сделали', () async {
      final Outbox outbox = outboxThat((_) => SendOutcome.done);

      await outbox.enqueue(title: 'в работу', method: 'PUT', path: '/order/1/');
      await outbox.enqueue(title: 'выполнил', method: 'PUT', path: '/order/2/');
      await outbox.flush();

      expect(sent, <String>['/order/1/', '/order/2/']);
      expect(await outbox.pending(), isEmpty);
    });

    test('обрыв связи оставляет действие в очереди', () async {
      final Outbox outbox = Outbox(
        userId: 7,
        store: store,
        sender: (OutboxAction action) async => throw Exception('нет сети'),
      );

      await outbox.enqueue(title: 'в работу', method: 'PUT', path: '/order/1/');
      await outbox.flush();

      final List<OutboxAction> waiting = await outbox.pending();
      expect(waiting, hasLength(1));
      expect(waiting.first.attempts, greaterThan(0));
    });

    test('очередь встаёт на первом временном отказе и не переставляет хвост',
        () async {
      // «Выполнил» не должно уйти раньше «в работу»: бэкенд по смене статуса
      // проставляет время, и переставленные действия дадут заявку, закрытую
      // раньше, чем начатую.
      final Outbox outbox = outboxThat(
        (OutboxAction action) => action.path == '/order/1/'
            ? SendOutcome.retry
            : SendOutcome.done,
      );

      await outbox.enqueue(title: 'в работу', method: 'PUT', path: '/order/1/');
      await outbox.enqueue(title: 'выполнил', method: 'PUT', path: '/order/2/');
      await outbox.flush();

      expect(sent, isEmpty);
      expect((await outbox.pending()).length, 2);
    });

    test('действие, добавленное во время отправки, не теряется и не дублируется',
        () async {
      // Та самая гонка: `enqueue` заканчивается фоновым `flush`, и постановка
      // в очередь приходится на середину отправки. Оба правят один ключ по
      // схеме «прочитал — изменил — записал», и без замка первое действие
      // уходит дважды либо второе пропадает молча.
      final Completer<void> held = Completer<void>();
      final Outbox outbox = Outbox(
        userId: 7,
        store: store,
        sender: (OutboxAction action) async {
          if (action.path == '/order/1/') await held.future;
          sent.add(action.path);
          return SendOutcome.done;
        },
      );

      await outbox.enqueue(title: 'в работу', method: 'PUT', path: '/order/1/');
      // Отправка первого действия сейчас висит в `sender`.
      await outbox.enqueue(title: 'выполнил', method: 'PUT', path: '/order/2/');
      held.complete();

      await outbox.flush();

      expect(sent, <String>['/order/1/', '/order/2/']);
      expect(await outbox.pending(), isEmpty);
    });

    test('отказ по существу уходит из очереди, но не пропадает', () async {
      final Outbox outbox = outboxThat((_) => SendOutcome.rejected);

      await outbox.enqueue(title: 'чужая заявка', method: 'PUT', path: '/order/9/');
      await outbox.flush();

      expect(await outbox.pending(), isEmpty);
      expect(await outbox.rejected(), hasLength(1));
      expect((await outbox.rejected()).first.title, 'чужая заявка');
    });

    test('очередь переживает перезапуск приложения', () async {
      final Outbox first = outboxThat((_) => SendOutcome.retry);
      await first.enqueue(title: 'в работу', method: 'PUT', path: '/order/1/');
      await first.flush();

      // Второй объект на том же хранилище — это и есть новый запуск.
      final Outbox second = outboxThat((_) => SendOutcome.done);
      expect(await second.pending(), hasLength(1));

      await second.flush();
      expect(sent, <String>['/order/1/']);
    });

    test('очереди разных людей не смешиваются', () async {
      final Outbox mine = outboxThat((_) => SendOutcome.retry);
      await mine.enqueue(title: 'моё', method: 'PUT', path: '/order/1/');

      final Outbox other = Outbox(
        userId: 8,
        store: store,
        sender: (OutboxAction action) async => SendOutcome.done,
      );

      expect(await other.pending(), isEmpty);
    });
  });

  group('outcomeForStatus', () {
    test('успех — это 2xx', () {
      expect(outcomeForStatus(200), SendOutcome.done);
      expect(outcomeForStatus(201), SendOutcome.done);
    });

    test('протухший токен и перегрузка — повторяем', () {
      expect(outcomeForStatus(401), SendOutcome.retry);
      expect(outcomeForStatus(429), SendOutcome.retry);
      expect(outcomeForStatus(500), SendOutcome.retry);
      expect(outcomeForStatus(502), SendOutcome.retry);
    });

    test('отказ по существу не повторяем', () {
      // 403 на чужой записи и 422 на негодном теле через час ответят тем же.
      expect(outcomeForStatus(403), SendOutcome.rejected);
      expect(outcomeForStatus(404), SendOutcome.rejected);
      expect(outcomeForStatus(422), SendOutcome.rejected);
    });
  });
}
