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

  group('Outbox с файлом', () {
    late MemoryStore store;

    setUp(() => store = MemoryStore());

    test('байты уезжают вместе с действием и уходят из хранилища', () async {
      // Снимок сделан в машинном помещении, где связи нет: он обязан дождаться
      // сети на телефоне, а после отправки не занимать место.
      List<int>? delivered;
      final Outbox outbox = Outbox(
        userId: 7,
        store: store,
        sender: (OutboxAction action) async {
          delivered = action.bytes;
          return SendOutcome.done;
        },
      );

      await outbox.enqueue(
        title: 'фото к заявке №14',
        method: 'POST',
        path: '/order-photo/14/',
        file: <int>[1, 2, 3, 4],
        fileName: 'photo.jpg',
      );
      await outbox.flush();

      expect(delivered, <int>[1, 2, 3, 4]);
      expect(await outbox.pending(), isEmpty);
      expect(
        await store.keys('mechanic.7.outbox.file.'),
        isEmpty,
        reason: 'отправленный файл в хранилище не остаётся',
      );
    });

    test('без связи файл остаётся на телефоне и уходит со второй попытки',
        () async {
      bool online = false;
      List<int>? delivered;
      final Outbox outbox = Outbox(
        userId: 7,
        store: store,
        sender: (OutboxAction action) async {
          if (!online) return SendOutcome.retry;
          delivered = action.bytes;
          return SendOutcome.done;
        },
      );

      await outbox.enqueue(
        title: 'фото',
        method: 'POST',
        path: '/order-photo/14/',
        file: <int>[9, 9, 9],
        fileName: 'photo.jpg',
      );
      await outbox.flush();

      expect(await outbox.pending(), hasLength(1));
      expect(await store.keys('mechanic.7.outbox.file.'), hasLength(1));

      online = true;
      await outbox.flush();

      expect(delivered, <int>[9, 9, 9]);
      expect(await outbox.pending(), isEmpty);
    });

    test('потерянный файл не отправляется пустым, а уходит в отклонённые',
        () async {
      bool asked = false;
      final Outbox outbox = Outbox(
        userId: 7,
        store: store,
        sender: (OutboxAction action) async {
          asked = true;
          return SendOutcome.done;
        },
      );

      await outbox.enqueue(
        title: 'фото',
        method: 'POST',
        path: '/order-photo/14/',
        file: <int>[1],
        fileName: 'photo.jpg',
      );
      for (final String key in await store.keys('mechanic.7.outbox.file.')) {
        await store.remove(key);
      }
      await outbox.flush();

      expect(asked, isFalse, reason: 'пустой файл серверу не отправляем');
      expect(await outbox.pending(), isEmpty);
      expect((await outbox.rejected()).single.lastError, contains('не найден'));
    });

    test('выход из системы забирает и снимки', () async {
      final Outbox outbox = Outbox(
        userId: 7,
        store: store,
        sender: (OutboxAction action) async => SendOutcome.retry,
      );

      await outbox.enqueue(
        title: 'фото',
        method: 'POST',
        path: '/order-photo/14/',
        file: <int>[1, 2],
        fileName: 'photo.jpg',
      );
      await outbox.forget();

      expect(await store.keys('mechanic.7.'), isEmpty);
    });

    test('очередь с файлом переживает перезапуск приложения', () async {
      final Outbox first = Outbox(
        userId: 7,
        store: store,
        sender: (OutboxAction action) async => SendOutcome.retry,
      );
      await first.enqueue(
        title: 'фото',
        method: 'POST',
        path: '/order-photo/14/',
        file: <int>[5, 6, 7],
        fileName: 'photo.jpg',
      );
      await first.flush();

      List<int>? delivered;
      final Outbox second = Outbox(
        userId: 7,
        store: store,
        sender: (OutboxAction action) async {
          delivered = action.bytes;
          return SendOutcome.done;
        },
      );
      await second.flush();

      expect(delivered, <int>[5, 6, 7]);
    });
  });

  group('отложенный id', () {
    late MemoryStore store;

    setUp(() => store = MemoryStore());

    /// Очередь, где создание акта отвечает своим `id`, а снимок просто уходит.
    ///
    /// Так же ведёт себя настоящий отправщик: `id` он разбирает из ответа
    /// сервера и кладёт в действие, см. `mechanic_workspace.dart`.
    Outbox outboxThatCreates(int id, {required List<String> sent}) {
      return Outbox(
        userId: 7,
        store: store,
        sender: (OutboxAction action) async {
          if (action.provides != null) action.createdId = id;
          sent.add(action.target);
          return SendOutcome.done;
        },
      );
    }

    Future<void> enqueueDefectWithPhoto(Outbox outbox) async {
      final OutboxAction act = await outbox.enqueue(
        title: 'дефект',
        method: 'POST',
        path: '/defective-act/',
        body: <String, dynamic>{'act_fact_id': 3, 'title': 'течь'},
        provides: true,
      );
      await outbox.enqueue(
        title: 'фото дефекта',
        method: 'POST',
        path: '/defective-act-photo/{${act.provides}}/',
        file: <int>[1, 2, 3],
        fileName: 'defect.jpg',
      );
    }

    test('снимок уходит по адресу, который сервер выдал акту', () async {
      final List<String> sent = <String>[];
      final Outbox outbox = outboxThatCreates(42, sent: sent);

      await enqueueDefectWithPhoto(outbox);
      await outbox.flush();

      expect(sent, <String>['/defective-act/', '/defective-act-photo/42/']);
      expect(await outbox.pending(), isEmpty);
    });

    test('пока акт не ушёл, снимок ждёт и адрес не выдумывает', () async {
      // Ровно случай машинного помещения: акт стоит на временной осечке, и
      // отправить снимок некуда — `id` ещё не существует.
      bool online = false;
      final List<String> sent = <String>[];
      final Outbox outbox = Outbox(
        userId: 7,
        store: store,
        sender: (OutboxAction action) async {
          if (!online) return SendOutcome.retry;
          if (action.provides != null) action.createdId = 42;
          sent.add(action.target);
          return SendOutcome.done;
        },
      );

      await enqueueDefectWithPhoto(outbox);
      await outbox.flush();

      expect(sent, isEmpty);
      expect(await outbox.pending(), hasLength(2));

      online = true;
      await outbox.flush();

      expect(sent, <String>['/defective-act/', '/defective-act-photo/42/']);
    });

    test('снимок без своего акта уходит в отклонённые, а не в никуда',
        () async {
      // Сервер отказал по существу: акта не будет никогда. Молча выбросить
      // снимок нельзя — это работа человека, и он должен о ней услышать.
      final List<String> sent = <String>[];
      final Outbox outbox = Outbox(
        userId: 7,
        store: store,
        sender: (OutboxAction action) async {
          if (action.provides != null) return SendOutcome.rejected;
          sent.add(action.target);
          return SendOutcome.done;
        },
      );

      await enqueueDefectWithPhoto(outbox);
      await outbox.flush();

      expect(sent, isEmpty, reason: 'снимок серверу не показывали');
      expect(await outbox.pending(), isEmpty);
      expect(await outbox.rejected(), hasLength(2));
      expect(
        (await outbox.rejected()).last.lastError,
        contains('отправить некуда'),
      );
      expect(
        await store.keys('mechanic.7.outbox.file.'),
        isEmpty,
        reason: 'отклонённый снимок не занимает место на телефоне',
      );
    });

    test('ключ переживает перезапуск между актом и снимком', () async {
      // Акт ушёл, приложение закрыли, снимок остался в очереди. Ключ обязан
      // найтись: иначе перезапуск превращает снимок в осиротевший.
      final List<String> first = <String>[];
      final Outbox before = Outbox(
        userId: 7,
        store: store,
        sender: (OutboxAction action) async {
          if (action.provides == null) return SendOutcome.retry;
          action.createdId = 42;
          first.add(action.target);
          return SendOutcome.done;
        },
      );
      await enqueueDefectWithPhoto(before);
      await before.flush();

      expect(first, <String>['/defective-act/']);
      expect(await before.pending(), hasLength(1));

      final List<String> second = <String>[];
      await outboxThatCreates(0, sent: second).flush();

      expect(second, <String>['/defective-act-photo/42/']);
    });

    test('выход из системы забирает и разобранные ключи', () async {
      final Outbox outbox = outboxThatCreates(42, sent: <String>[]);
      await enqueueDefectWithPhoto(outbox);
      await outbox.flush();
      await outbox.forget();

      expect(await store.keys('mechanic.7.'), isEmpty);
    });
  });

  group('полоса очереди', () {
    late MemoryStore store;

    setUp(() => store = MemoryStore());

    test('удачная отправка сообщает о себе — иначе полоса очереди врёт',
        () async {
      // Полоса «Не отправлено: N» пересчитывалась только по таймеру в две
      // минуты: работа уходила на сервер, а человек всё это время видел, что
      // она не ушла, и жал кнопку заново.
      int changes = 0;
      bool online = false;
      final Outbox outbox = Outbox(
        userId: 7,
        store: store,
        onChanged: () => changes++,
        sender: (OutboxAction action) async =>
            online ? SendOutcome.done : SendOutcome.retry,
      );

      await outbox.enqueue(title: 'в работу', method: 'PUT', path: '/order/1/');
      await outbox.flush();
      expect(changes, 0, reason: 'без связи очередь не менялась');

      online = true;
      await outbox.flush();

      expect(changes, 1);
      expect(await outbox.pending(), isEmpty);
    });

    test('отклонённое действие тоже меняет очередь', () async {
      int changes = 0;
      final Outbox outbox = Outbox(
        userId: 7,
        store: store,
        onChanged: () => changes++,
        sender: (OutboxAction action) async => SendOutcome.rejected,
      );

      await outbox.enqueue(title: 'в работу', method: 'PUT', path: '/order/1/');
      await outbox.flush();

      expect(changes, 1);
      expect(await outbox.rejected(), hasLength(1));

      await outbox.forgetRejected();
      expect(changes, 2);
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
