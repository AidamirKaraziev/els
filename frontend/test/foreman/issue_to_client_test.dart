/// Экран «Оформить клиенту»: что он собирает в черновик.
///
/// Сеть не поднимается. У снимков в фикстуре пустой путь: `apiImage` рисует
/// такой прозрачным пикселем из памяти и в сеть не идёт (`helper/api_image.dart`).
/// Проверяем галочки, а не картинки — как и соседний `defect_card_test.dart`,
/// который снимки просто не показывает.
library;

import 'package:els/foreman/defects/defect_entry.dart';
import 'package:els/foreman/defects/issue_to_client_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

DefectEntry _entry({
  String? description = 'Канат изношен на 8%.',
  List<DefectPhoto> photos = const <DefectPhoto>[
    DefectPhoto(id: 5, url: ''),
    DefectPhoto(id: 6, url: ''),
    DefectPhoto(id: 7, url: ''),
  ],
}) =>
    DefectEntry(
      id: 12,
      title: 'Износ тягового каната',
      description: description,
      source: DefectSource.checklistStep,
      state: DefectState.created,
      photos: photos,
    );

/// Куда экран складывает собранное. Кнопка ничего не отправляет — черновик
/// просто оседает здесь, и проверять можно его, а не запрос.
class _Sink {
  IssueDraft? draft;
}

/// Показывает экран и отдаёт место, куда ляжет черновик.
Future<_Sink> _mount(WidgetTester tester, DefectEntry entry) async {
  final _Sink sink = _Sink();
  await tester.pumpWidget(MaterialApp(
    home: IssueToClientScreen(
      entry: entry,
      onIssue: (IssueDraft draft) async => sink.draft = draft,
    ),
  ));
  return sink;
}

/// Плитка снимка находится по своему номеру: у неё ключ `ValueKey<int>`.
Future<void> _tapPhoto(WidgetTester tester, int id) async {
  await tester.tap(find.byKey(ValueKey<int>(id)));
  await tester.pump();
}

/// Кнопка лежит под сеткой снимков и в тестовое окно 800×600 не попадает —
/// до неё надо доскроллить, как доскроллил бы прораб.
Future<void> _submit(WidgetTester tester) async {
  final Finder button = find.text('Сформировать PDF');
  await tester.scrollUntilVisible(
    button,
    200.0,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.tap(button);
  await tester.pump();
}

void main() {
  group('черновик', () {
    testWidgets('по умолчанию отмечены все снимки', (tester) async {
      final _Sink sink = await _mount(tester, _entry());
      await tester.pumpAndSettle();

      expect(find.text('Выбрано 3 из 3'), findsOneWidget);

      await _submit(tester);
      expect(sink.draft!.photoIds, <int>[5, 6, 7]);
    });

    testWidgets('снятая галочка убирает снимок, порядок акта сохраняется',
        (tester) async {
      final _Sink sink = await _mount(tester, _entry());
      await tester.pumpAndSettle();

      // Средний снимок: снимаем, потом возвращаем первый — порядок в теле
      // запроса должен остаться порядком акта, а не порядком нажатий.
      await _tapPhoto(tester, 6);
      await _tapPhoto(tester, 5);
      await _tapPhoto(tester, 5);

      expect(find.text('Выбрано 2 из 3'), findsOneWidget);

      await _submit(tester);
      expect(sink.draft!.photoIds, <int>[5, 7]);
    });

    testWidgets('без единой галочки уходит пустой список, а не умолчание',
        (tester) async {
      final _Sink sink = await _mount(tester, _entry());
      await tester.pumpAndSettle();

      for (final int id in <int>[5, 6, 7]) {
        await _tapPhoto(tester, id);
      }

      expect(find.text('Выбрано 0 из 3 · уйдёт без фото'), findsOneWidget);

      await _submit(tester);
      expect(sink.draft!.photoIds, isEmpty);
      expect(sink.draft!.toBody()['photo_ids'], isEmpty);
    });

    testWidgets('пустые поля — это null, а не пустая строка', (tester) async {
      final _Sink sink = await _mount(tester, _entry());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, '   ');
      await _submit(tester);

      final IssueDraft body = sink.draft!;
      expect(body.clientTitle, isNull);
      expect(body.clientDescription, isNull);
      expect(body.toBody().containsKey('client_title'), isFalse);
      expect(body.toBody().containsKey('client_description'), isFalse);
    });

    testWidgets('написанное прорабом уходит вместо текста механика',
        (tester) async {
      final _Sink sink = await _mount(tester, _entry());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextField).first,
        'Неисправность дверей шахты',
      );
      await tester.enterText(find.byType(TextField).last, 'Требуется замена.');
      await _submit(tester);

      expect(sink.draft!.toBody(), <String, dynamic>{
        'client_title': 'Неисправность дверей шахты',
        'client_description': 'Требуется замена.',
        'photo_ids': <int>[5, 6, 7],
      });
    });
  });

  group('акт без снимков', () {
    testWidgets('вместо сетки объяснение, счётчика нет', (tester) async {
      await _mount(tester, _entry(photos: const <DefectPhoto>[]));
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Механик не приложил снимков'),
        findsOneWidget,
      );
      expect(find.textContaining('Выбрано'), findsNothing);
    });
  });

  group('акт без описания', () {
    testWidgets('подпись говорит, что подставлять нечего', (tester) async {
      await _mount(tester, _entry(description: null));
      await tester.pumpAndSettle();

      expect(
        find.text('У механика описания нет — клиенту уйдёт без него.'),
        findsOneWidget,
      );
    });
  });
}
