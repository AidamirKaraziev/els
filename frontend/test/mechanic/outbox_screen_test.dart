/// Экран «Очередь отправки».
///
/// Проверяется то, что человек увидит без сети: что ждущие и отклонённые
/// стоят своими группами, что у отклонённых есть «Повторить» и «Убрать» и
/// что они делают, и что пустая очередь так и говорит.
library;

import 'package:els/mechanic/data/local_store.dart';
import 'package:els/mechanic/data/mechanic_workspace.dart';
import 'package:els/mechanic/data/outbox.dart';
import 'package:els/mechanic/screens/outbox_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late MemoryStore store;
  late MemoryBlobStore blobs;
  late SendOutcome outcome;

  /// Ответ сервера по адресу; без записи — общий [outcome].
  late Map<String, SendOutcome> byPath;

  setUp(() {
    store = MemoryStore();
    blobs = MemoryBlobStore();
    outcome = SendOutcome.retry;
    byPath = <String, SendOutcome>{};
  });

  MechanicWorkspace workspace() => MechanicWorkspace.forTest(
        userId: 7,
        store: store,
        blobs: blobs,
        sender: (OutboxAction action) async => byPath[action.path] ?? outcome,
      );

  Future<void> show(WidgetTester tester, MechanicWorkspace ws) async {
    await tester.pumpWidget(
      MaterialApp(home: MechanicOutboxScreen(workspace: ws)),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('ждущие и отклонённые стоят своими группами', (tester) async {
    final MechanicWorkspace ws = workspace();
    await ws.outbox.enqueue(
      title: 'Заявка №14 — в работу',
      method: 'PUT',
      path: '/order/14/',
    );
    await ws.outbox.enqueue(
      title: 'Фото к заявке №14',
      method: 'POST',
      path: '/order-photo/14/',
      file: <int>[1, 2, 3],
      fileName: 'photo.jpg',
    );
    // Статус сервер отверг, снимок — ждёт связи.
    byPath['/order/14/'] = SendOutcome.rejected;
    await ws.outbox.flush();

    await show(tester, ws);

    expect(find.text('Ждут отправки'), findsOneWidget);
    expect(find.text('Отклонено сервером'), findsOneWidget);
    expect(find.text('Фото к заявке №14'), findsOneWidget);
    expect(find.text('Заявка №14 — в работу'), findsOneWidget);
    expect(find.text('Отправить всё'), findsOneWidget);
    expect(find.text('Повторить'), findsOneWidget);
    expect(find.text('Убрать'), findsOneWidget);
    expect(find.textContaining('1 ждёт отправки'), findsOneWidget);
  });

  testWidgets('«Убрать» снимает отклонённое', (tester) async {
    outcome = SendOutcome.rejected;
    final MechanicWorkspace ws = workspace();
    await ws.outbox.enqueue(
      title: 'Заявка №14 — в работу',
      method: 'PUT',
      path: '/order/14/',
    );
    await ws.outbox.flush();
    await show(tester, ws);
    expect(find.text('Отклонено сервером'), findsOneWidget);

    await tester.tap(find.text('Убрать'));
    await tester.pumpAndSettle();

    expect(find.text('Отклонено сервером'), findsNothing);
    expect(find.text('Всё ушло на сервер'), findsOneWidget);
    expect(await ws.outbox.rejected(), isEmpty);
  });

  testWidgets('«Повторить» возвращает в очередь, и оно уходит', (tester) async {
    outcome = SendOutcome.rejected;
    final MechanicWorkspace ws = workspace();
    await ws.outbox.enqueue(
      title: 'Заявка №14 — в работу',
      method: 'PUT',
      path: '/order/14/',
    );
    await ws.outbox.flush();
    await show(tester, ws);

    outcome = SendOutcome.done;
    await tester.tap(find.text('Повторить'));
    await tester.pumpAndSettle();

    expect(await ws.outbox.rejected(), isEmpty);
    expect(await ws.outbox.pending(), isEmpty);
    expect(find.text('Всё ушло на сервер'), findsOneWidget);
  });

  testWidgets('пустая очередь так и говорит', (tester) async {
    await show(tester, workspace());
    expect(find.text('Всё отправлено'), findsOneWidget);
    expect(find.text('Всё ушло на сервер'), findsOneWidget);
    expect(find.text('Отправить всё'), findsNothing);
  });
}
