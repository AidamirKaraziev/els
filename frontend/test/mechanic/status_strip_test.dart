/// Полоса состояния и плашка «вышла версия».
///
/// Проверяются тексты, которые механик читает в шапке: офлайн против ошибки
/// сервера, счётчики очереди, когда полосы нет вовсе, и что «Открыть» и
/// «Обновить» ведут куда обещают.
library;

import 'package:els/app_download/app_release.dart';
import 'package:els/mechanic/data/mechanic_workspace.dart';
import 'package:els/mechanic/status_strip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('текст полосы', () {
    test('всё хорошо — полосы нет', () {
      expect(statusStripText(const WorkspaceStatus()), isNull);
    });

    test('офлайн с очередью', () {
      expect(
        statusStripText(const WorkspaceStatus(offline: true, pending: 3)),
        'Офлайн · ждут отправки: 3',
      );
    });

    test('офлайн без очереди', () {
      expect(
        statusStripText(const WorkspaceStatus(offline: true)),
        'Офлайн · всё отправлено',
      );
    });

    test('сеть есть, очередь уходит', () {
      expect(
        statusStripText(const WorkspaceStatus(pending: 2)),
        'Отправляем: 2',
      );
    });

    test('ошибка сервера — её текст, без слова «офлайн»', () {
      expect(
        statusStripText(
          const WorkspaceStatus(lastError: 'Сервер не отдал данные', pending: 1),
        ),
        'Сервер не отдал данные · Отправляем: 1',
      );
    });

    test('отклонённые видны и офлайн, и онлайн', () {
      expect(
        statusStripText(const WorkspaceStatus(offline: true, rejected: 1)),
        'Офлайн · всё отправлено · Отклонено сервером: 1',
      );
      expect(
        statusStripText(const WorkspaceStatus(rejected: 2)),
        'Отклонено сервером: 2',
      );
    });
  });

  group('виджеты', () {
    Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
          MaterialApp(home: Scaffold(body: Column(children: <Widget>[child]))),
        );

    testWidgets('«Открыть» есть только при очереди', (WidgetTester tester) async {
      int opened = 0;
      await pump(
        tester,
        MechanicStatusStrip(
          status: const WorkspaceStatus(offline: true, pending: 1),
          onOpenQueue: () => opened++,
        ),
      );
      expect(find.text('Открыть'), findsOneWidget);
      await tester.tap(find.text('Открыть'));
      expect(opened, 1);

      await pump(
        tester,
        MechanicStatusStrip(
          status: const WorkspaceStatus(offline: true),
          onOpenQueue: () => opened++,
        ),
      );
      expect(find.text('Открыть'), findsNothing);
      await tester.tap(find.text('Офлайн · всё отправлено'));
      expect(opened, 1, reason: 'без очереди открывать нечего');
    });

    testWidgets('плашка обновления: версия, «Обновить», крестик',
        (WidgetTester tester) async {
      int opened = 0;
      int dismissed = 0;
      await pump(
        tester,
        MechanicUpdateBanner(
          release: const AppRelease(
            versionName: '1.0.3',
            versionCode: 4,
            size: 1,
          ),
          onOpen: () => opened++,
          onDismiss: () => dismissed++,
        ),
      );
      expect(find.text('Вышла версия 1.0.3'), findsOneWidget);
      await tester.tap(find.text('Обновить'));
      await tester.tap(find.byIcon(Icons.close));
      expect(opened, 1);
      expect(dismissed, 1);
    });
  });
}
