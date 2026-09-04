import 'dart:typed_data';

import 'package:els/helper/image_picking.dart';
import 'package:els/mechanic/screens/defect_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Лист «Дефект»: что механик может записать и чего лист ему не позволит.
///
/// Проверяется правило, а не вёрстка: обязателен только заголовок, описание
/// и снимки — по желанию.
void main() {
  testWidgets('без заголовка записать нельзя', (WidgetTester tester) async {
    await _open(tester);

    expect(_sendEnabled(tester), isFalse, reason: 'заголовка ещё нет');

    await tester.enterText(_field(tester, 'Что не так'), 'Течёт редуктор');
    await tester.pump();

    expect(_sendEnabled(tester), isTrue);
  });

  testWidgets('одни пробелы заголовком не считаются',
      (WidgetTester tester) async {
    await _open(tester);

    await tester.enterText(_field(tester, 'Что не так'), '   ');
    await tester.pump();

    expect(_sendEnabled(tester), isFalse);
  });

  testWidgets('лист отдаёт заголовок, описание и снимки',
      (WidgetTester tester) async {
    final List<DefectDraft?> answers = <DefectDraft?>[];
    await _open(tester, answers: answers);

    await tester.enterText(_field(tester, 'Что не так'), '  Течёт редуктор  ');
    await tester.enterText(_field(tester, 'Подробности'), 'Со среды, на подъёме');
    await tester.pump();

    await tester.tap(find.text('Добавить снимок'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Выбрать из галереи'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Записать дефект'));
    await tester.pumpAndSettle();

    final DefectDraft? draft = answers.single;
    expect(draft, isNotNull);
    expect(draft!.title, 'Течёт редуктор', reason: 'края обрезаются');
    expect(draft.description, 'Со среды, на подъёме');
    expect(draft.photos, hasLength(1));
  });

  testWidgets('пустое описание уходит как ничего, а не пустой строкой',
      (WidgetTester tester) async {
    final List<DefectDraft?> answers = <DefectDraft?>[];
    await _open(tester, answers: answers);

    await tester.enterText(_field(tester, 'Что не так'), 'Скрипит дверь');
    await tester.pump();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Записать дефект'));
    await tester.pumpAndSettle();

    expect(answers.single?.description, isNull);
  });

  testWidgets('снимок можно убрать до отправки', (WidgetTester tester) async {
    final List<DefectDraft?> answers = <DefectDraft?>[];
    await _open(tester, answers: answers);

    await tester.enterText(_field(tester, 'Что не так'), 'Скрипит дверь');
    await tester.tap(find.text('Добавить снимок'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Снять сейчас'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Записать дефект'));
    await tester.pumpAndSettle();

    expect(answers.single?.photos, isEmpty);
  });

  testWidgets('отказ ничего не записывает', (WidgetTester tester) async {
    final List<DefectDraft?> answers = <DefectDraft?>[];
    await _open(tester, answers: answers);

    await tester.tap(find.widgetWithText(TextButton, 'Не сейчас'));
    await tester.pumpAndSettle();

    expect(answers.single, isNull);
  });
}

/// Открывает лист и складывает его ответ в [answers].
Future<void> _open(
  WidgetTester tester, {
  List<DefectDraft?>? answers,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (BuildContext context) => TextButton(
            onPressed: () async {
              final DefectDraft? draft = await showDefectSheet(
                context,
                pickPhoto: _photo,
              );
              answers?.add(draft);
            },
            child: const Text('открыть'),
          ),
        ),
      ),
    ),
  );

  await tester.tap(find.text('открыть'));
  await tester.pumpAndSettle();
}

/// Подставной выбор снимка: камеры в тесте нет.
Future<PickedImage?> _photo({required bool fromCamera}) async {
  return PickedImage(fileName: 'shot.png', data: _square);
}

/// Валидный PNG 8×8 — `Image.memory` разбирает именно его, а не любые байты.
final Uint8List _square = Uint8List.fromList(<int>[
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, //
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x08, 0x00, 0x00, 0x00, 0x08,
  0x08, 0x02, 0x00, 0x00, 0x00, 0x4B, 0x6D, 0x29, 0xDC, 0x00, 0x00, 0x00,
  0x11, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x98, 0x3D, 0x6B, 0x16,
  0x56, 0xC4, 0x30, 0xB4, 0x24, 0x00, 0x3A, 0xAB, 0x73, 0xC1, 0x0A, 0xC4,
  0x5F, 0x93, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42,
  0x60, 0x82,
]);

Finder _field(WidgetTester tester, String label) {
  return find.widgetWithText(TextField, label);
}

bool _sendEnabled(WidgetTester tester) {
  final ElevatedButton button = tester.widget<ElevatedButton>(
    find.widgetWithText(ElevatedButton, 'Записать дефект'),
  );
  return button.onPressed != null;
}
