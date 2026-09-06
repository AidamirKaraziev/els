/// Карточка дефекта: то, что карточка знает не из акта.
///
/// Сеть здесь не поднимается: `loadFull: false` — ровно тот режим, в котором
/// работают набросок и тесты.
library;

import 'package:els/foreman/defects/defect_card_screen.dart';
import 'package:els/foreman/defects/defect_entry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

DefectEntry _entry({String? objectName}) => DefectEntry(
      id: 3,
      title: 'Неисправность дверей',
      source: DefectSource.order,
      state: DefectState.created,
      objectName: objectName,
    );

Widget _app(Widget child) => MaterialApp(home: child);

void main() {
  group('объект в реквизитах', () {
    testWidgets('имя берётся из ленты, когда в акте его нет', (tester) async {
      await tester.pumpWidget(_app(DefectCardScreen(
        entry: _entry(),
        objectName: 'AAAAAAAAAAAA',
        loadFull: false,
      )));

      expect(find.text('AAAAAAAAAAAA'), findsOneWidget);
    });

    testWidgets('имя из акта важнее: оно относится к самому акту',
        (tester) async {
      await tester.pumpWidget(_app(DefectCardScreen(
        entry: _entry(objectName: 'Лифт из планового ТО'),
        objectName: 'AAAAAAAAAAAA',
        loadFull: false,
      )));

      expect(find.text('Лифт из планового ТО'), findsOneWidget);
      expect(find.text('AAAAAAAAAAAA'), findsNothing);
    });
  });
}
