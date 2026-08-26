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

/// Год, где каждое из пяти состояний встречается хотя бы раз.
///
/// Месяцы 1..5 идут по порядку состояний, остальные — пустые: так в одном
/// прогоне видно и все заливки, и то, что пустой месяц ведёт себя иначе.
List<MonthCell> _mixedCells() {
  const List<MonthStatus> first = <MonthStatus>[
    MonthStatus.done,
    MonthStatus.late,
    MonthStatus.overdue,
    MonthStatus.pending,
    MonthStatus.none,
  ];
  return <MonthCell>[
    for (int month = 1; month <= 12; month++)
      if (month <= first.length)
        MonthCell(
          month: month,
          status: first[month - 1],
          toName: first[month - 1] == MonthStatus.none ? null : 'ТО $month',
          // У пустого месяца работы за клеткой нет — иначе он стал бы
          // кликабельным, а открывать там нечего.
          actId: first[month - 1] == MonthStatus.none ? null : month,
        )
      else
        MonthCell.empty(month),
  ];
}

Future<void> _pumpCells(
  WidgetTester tester,
  double width,
  List<MonthCell> cells,
  ValueChanged<MonthCell> onCellTap,
) async {
  tester.view.physicalSize = const Size(1600.0, 400.0);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: width,
            child: MonthStrip(cells: cells, onCellTap: onCellTap),
          ),
        ),
      ),
    ),
  );
}

/// Заливка клетки за месяцем [month] — из `Container` внутри тултипа.
Color? _fillOf(WidgetTester tester, int month) {
  final Container box = tester.widget<Container>(
    find
        .descendant(
          of: find.byType(Tooltip).at(month - 1),
          matching: find.byType(Container),
        )
        .first,
  );
  return (box.decoration! as BoxDecoration).color;
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

  testWidgets('каждое состояние красится своим цветом',
      (WidgetTester tester) async {
    await _pumpCells(tester, 700, _mixedCells(), (MonthCell _) {});

    expect(_fillOf(tester, 1), MonthStatus.done.fill);
    expect(_fillOf(tester, 2), MonthStatus.late.fill);
    expect(_fillOf(tester, 3), MonthStatus.overdue.fill);
    expect(_fillOf(tester, 4), MonthStatus.pending.fill);
    // Пустой месяц заливки не имеет: он не должен весить столько же, сколько
    // назначенное и несделанное ТО.
    expect(_fillOf(tester, 5), isNull);

    // Четыре занятых состояния — четыре разных цвета, а не один на всех.
    expect(
      <Color?>{
        _fillOf(tester, 1),
        _fillOf(tester, 2),
        _fillOf(tester, 3),
        _fillOf(tester, 4),
      }.length,
      4,
    );
  });

  testWidgets('клик по клетке отдаёт её работу', (WidgetTester tester) async {
    final List<MonthCell> tapped = <MonthCell>[];
    await _pumpCells(tester, 700, _mixedCells(), tapped.add);

    await tester.tap(find.byType(Tooltip).at(2));
    await tester.pumpAndSettle();

    expect(tapped, hasLength(1));
    // Именно `actId`, а не номер месяца: карточку открывает работа за клеткой.
    expect(tapped.single.actId, 3);
    expect(tapped.single.month, 3);
  });

  testWidgets('пустой месяц не кликается', (WidgetTester tester) async {
    final List<MonthCell> tapped = <MonthCell>[];
    await _pumpCells(tester, 700, _mixedCells(), tapped.add);

    // Пятая клетка — `none`, за ней ничего нет.
    await tester.tap(find.byType(Tooltip).at(4));
    await tester.pumpAndSettle();

    expect(tapped, isEmpty);
    // И отклика на нажатие тоже нет — `InkWell` над пустым месяцем не строится.
    expect(
      find.descendant(
        of: find.byType(Tooltip).at(4),
        matching: find.byType(InkWell),
      ),
      findsNothing,
    );
  });
}
