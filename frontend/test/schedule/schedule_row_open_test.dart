/// Что строка отдаёт наверх по клику в клетку.
///
/// Раньше наверх уходила одна клетка, и объект на месте клика терялся: экран
/// открывал карточку работы с пустым `objectName`, а в шапке стояло безликое
/// «Работа». Поэтому проверяем именно пару «строка и клетка».
///
/// Пустой месяц не открывает ничего: за ним нет работы, и отклик на нажатие,
/// за которым ничего не происходит, — это обещание, которого экран не держит.
library;

import 'package:els/screns/schedule/models/month_cell.dart';
import 'package:els/screns/schedule/models/schedule_row.dart';
import 'package:els/screns/schedule/widgets/schedule_row_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

ScheduleRow _row() {
  return ScheduleRow(
    objectId: 7,
    name: 'ТЦ Карнавал 3 этаж 1',
    year: 2026,
    factoryNumber: 'B7NS 3400',
    address: 'г. Краснодар, ул. Северная, 356',
    foreman: 'Н.В. Гоголевский',
    typeName: 'Лифт без МП',
    cells: <MonthCell>[
      const MonthCell(
        month: 1,
        status: MonthStatus.done,
        toName: 'ТО 1',
        actId: 101,
      ),
      MonthCell.empty(2),
      for (int month = 3; month <= 12; month++)
        MonthCell(
          month: month,
          status: MonthStatus.pending,
          toName: 'ТО 1',
          actId: 100 + month,
        ),
    ],
  );
}

Future<List<Object?>> _pump(
  WidgetTester tester, {
  required void Function(ScheduleRow, MonthCell) onCellTap,
  double width = 400,
}) async {
  tester.view.physicalSize = Size(width, 900.0);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ScheduleRowTile(row: _row(), onCellTap: onCellTap),
      ),
    ),
  );

  return const <Object?>[];
}

void main() {
  testWidgets('клик по занятой клетке отдаёт наверх и строку, и клетку',
      (WidgetTester tester) async {
    ScheduleRow? gotRow;
    MonthCell? gotCell;

    await _pump(tester, onCellTap: (ScheduleRow row, MonthCell cell) {
      gotRow = row;
      gotCell = cell;
    });

    await tester.tap(find.byTooltip('Январь · ТО 1 · выполнено'));
    await tester.pump();

    // Именно объект, а не только номер акта: из него берётся шапка карточки.
    expect(gotRow?.objectId, 7);
    expect(gotRow?.nameLabel, 'ТЦ Карнавал 3 этаж 1');
    expect(gotCell?.actId, 101);
  });

  testWidgets('клик по пустому месяцу не открывает ничего',
      (WidgetTester tester) async {
    int taps = 0;

    await _pump(tester, onCellTap: (ScheduleRow _, MonthCell __) => taps++);

    await tester.tap(find.byTooltip('Февраль · ТО не назначено'));
    await tester.pump();

    expect(taps, 0);
  });

  testWidgets('в тултипе есть и месяц, и вид работы, и состояние',
      (WidgetTester tester) async {
    await _pump(tester, onCellTap: (ScheduleRow _, MonthCell __) {});

    // Без месяца лента без подписей не читается вовсе: клетки одинаковые.
    expect(find.byTooltip('Январь · ТО 1 · выполнено'), findsOneWidget);
    expect(find.byTooltip('Март · ТО 1 · назначено'), findsOneWidget);
  });
}
