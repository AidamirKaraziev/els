/// Раздел «Сейчас в работе»: строки открываются — все.
///
/// Карточка одна на оба вида: у ТО за строкой чек-лист, у заявки — задание и
/// категория. Строка, которая подсвечивается нажатием и никуда не ведёт, —
/// худшее из состояний, и раздел его больше не показывает.
library;

import 'package:els/screns/in_progress_works/bloc/in_progress_works_bloc.dart';
import 'package:els/screns/in_progress_works/models/in_progress_work.dart';
import 'package:els/screns/in_progress_works/widgets/in_progress_section.dart';
import 'package:els/screns/in_progress_works/widgets/in_progress_work_row.dart';
import 'package:els/screns/submitted_works/models/submitted_work.dart'
    show WorkKind;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

InProgressWork _work(WorkKind kind, int id) {
  return InProgressWork(
    kind: kind,
    workId: id,
    state: WorkState.running,
    objectName: 'Лифт $id',
    performer: 'Ковалёв А.',
    startedAt: DateTime.now().subtract(const Duration(minutes: 40)),
  );
}

void main() {
  testWidgets('открывается и строка ТО, и строка заявки',
      (WidgetTester tester) async {
    final InProgressWorks works = InProgressWorks(
      items: <InProgressWork>[
        _work(WorkKind.maintenance, 12),
        _work(WorkKind.breakdown, 34),
      ],
      total: 2,
      problems: 0,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: InProgressSection(
              state: InProgressWorksLoaded(works: works),
            ),
          ),
        ),
      ),
    );

    final List<InProgressWorkRow> rows = tester
        .widgetList<InProgressWorkRow>(find.byType(InProgressWorkRow))
        .toList();

    expect(rows.length, 2);
    expect(rows[0].work.kind, WorkKind.maintenance);
    expect(rows[0].onTap, isNotNull);
    expect(rows[1].work.kind, WorkKind.breakdown);
    expect(rows[1].onTap, isNotNull);
  });
}
