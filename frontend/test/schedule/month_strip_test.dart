/// Лента месяцев не теряет клетки при сжатии.
///
/// Ровно тот дефект, который поймали глазами: на ширине, где клетка макета уже
/// не помещается, лента обрезалась справа и показывала десять месяцев из
/// двенадцати — молча. Это хуже мелких клеток: экран врал о годе объекта.
library;

import 'package:els/screns/schedule/models/month_cell.dart';
import 'package:els/screns/schedule/widgets/month_strip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

List<MonthCell> _cells() {
  return <MonthCell>[
    for (int month = 1; month <= 12; month++)
      MonthCell(
        month: month,
        status: MonthStatus.done,
        toName: 'ТО 12',
        actId: month,
      ),
  ];
}

Future<void> _pump(WidgetTester tester, double width) async {
  tester.view.physicalSize = const Size(1600.0, 400.0);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: width,
            child: MonthStrip(
              cells: _cells(),
              onCellTap: (MonthCell _) {},
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  // 213 — ширина ленты в кадре `83:312`, 120 — заведомо теснее макета,
  // 700 — простор, где клетка упирается в потолок.
  for (final double width in <double>[120, 213, 400, 700]) {
    testWidgets('на ширине $width все двенадцать клеток на месте',
        (WidgetTester tester) async {
      await _pump(tester, width);

      expect(find.byType(Tooltip), findsNWidgets(12));
      // Перелив `Row` роняет исключение в тестах — это и есть обрезанная лента.
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('на макетной ширине подписи нет, как в кадре',
      (WidgetTester tester) async {
    await _pump(tester, 213);

    expect(find.text('ТО 12'), findsNothing);
    expect(find.text('12'), findsNothing);
  });

  testWidgets('на просторе в клетке стоит вид работы',
      (WidgetTester tester) async {
    await _pump(tester, 700);

    expect(find.text('ТО 12'), findsNWidgets(12));
  });
}
