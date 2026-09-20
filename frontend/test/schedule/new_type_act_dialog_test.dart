/// Диалог «Новый вид ТО»: Return в поле — то же, что «Добавить».
///
/// Руками в браузере это не проверить: инструмент Enter до Flutter web не
/// доносит. Тест закрывает вопрос из передачи S03.
library;

import 'package:els/screns/schedule/templates/widgets/new_type_act_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Return отдаёт имя, дубль — нет', (WidgetTester tester) async {
    String? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (BuildContext context) => TextButton(
            onPressed: () async {
              result = await showNewTypeActDialog(
                context,
                modelName: 'ЩЛЗ-400',
                existing: <String>['ТО 1'],
              );
            },
            child: const Text('открыть'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('открыть'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'ТО 1');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(result, isNull);
    expect(find.byType(TextField), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'ТО 4');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(result, 'ТО 4');
    expect(find.byType(TextField), findsNothing);
  });
}
