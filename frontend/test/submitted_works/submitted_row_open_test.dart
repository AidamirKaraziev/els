/// Вход в карточку из строки ленты.
///
/// Строка целиком открывает работу, а кнопка «Проверил» — нет: у неё своё
/// действие, и нажатие туда не значит «покажи подробнее». Проверенная строка
/// открывается так же: карточку читают и после отметки.
library;

import 'package:els/screns/submitted_works/models/submitted_work.dart';
import 'package:els/screns/submitted_works/widgets/submitted_work_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

SubmittedWork _work({bool reviewed = false}) {
  return SubmittedWork(
    kind: WorkKind.maintenance,
    workId: 12,
    outcome: WorkOutcome.done,
    objectId: 3,
    objectName: 'Лифт 12, подъезд 1',
    objectAddress: 'пр. Ленина, 48',
    performer: 'Сафин Р.',
    closedAt: DateTime(2026, 8, 21, 17, 40),
    reviewedAt: reviewed ? DateTime(2026, 8, 22, 10, 15) : null,
    reviewer: reviewed ? 'Петров А.' : null,
  );
}

Future<void> _pump(
  WidgetTester tester, {
  required VoidCallback onOpen,
  required VoidCallback onReview,
  bool reviewed = false,
}) async {
  tester.view.physicalSize = const Size(400.0, 900.0);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SubmittedWorkRow(
          work: _work(reviewed: reviewed),
          onReview: onReview,
          onOpen: onOpen,
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('тык по строке открывает карточку', (WidgetTester tester) async {
    int opened = 0;
    int reviewed = 0;
    await _pump(
      tester,
      onOpen: () => opened++,
      onReview: () => reviewed++,
    );

    await tester.tap(find.text('Лифт 12, подъезд 1'));
    await tester.pumpAndSettle();

    expect(opened, 1);
    expect(reviewed, 0);
  });

  testWidgets('«Проверил» в строке карточку не открывает',
      (WidgetTester tester) async {
    int opened = 0;
    int reviewed = 0;
    await _pump(
      tester,
      onOpen: () => opened++,
      onReview: () => reviewed++,
    );

    await tester.tap(find.text('Проверил'));
    await tester.pumpAndSettle();

    expect(reviewed, 1);
    expect(opened, 0);
  });

  testWidgets('проверенная строка тоже открывается',
      (WidgetTester tester) async {
    int opened = 0;
    await _pump(
      tester,
      reviewed: true,
      onOpen: () => opened++,
      onReview: () {},
    );

    await tester.tap(find.text('Лифт 12, подъезд 1'));
    await tester.pumpAndSettle();

    expect(opened, 1);
  });
}
