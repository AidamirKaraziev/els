/// Раздел «Сейчас в работе»: какие строки открываются, а какие нет.
///
/// Карточка есть пока только у ТО. У заявки нет чек-листа, зато есть задание и
/// категория — её карточка приезжает этапом 9.2, и до тех пор строка заявки
/// нажатием никуда не ведёт.
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
  testWidgets('строка ТО открывается, строка заявки — нет',
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
    expect(rows[1].onTap, isNull);
  });
}
