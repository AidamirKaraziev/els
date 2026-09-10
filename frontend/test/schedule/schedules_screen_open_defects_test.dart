/// Тап по значку дефектных актов в ленте открывает их список за год ленты.
///
/// Именно список, а не экран графика объекта: у значка своё обещание, и
/// клик по нему в строку не проваливается. Год уходит явно — список без
/// него открылся бы на текущем, и число на значке разошлось бы со списком.
library;

import 'package:els/foreman/defects/defects_badge.dart';
import 'package:els/foreman/defects/defects_screen.dart';
import 'package:els/screns/schedule/bloc/schedules_bloc.dart';
import 'package:els/screns/schedule/models/schedule_row.dart';
import 'package:els/screns/schedule/repository/fixture_schedules_repository.dart';
import 'package:els/screns/schedule/view/schedules_screen.dart';
import 'package:els/screns/schedule/widgets/schedule_row_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

Future<SchedulesBloc> _pump(WidgetTester tester) async {
  tester.view.physicalSize = const Size(400.0, 900.0);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final SchedulesBloc bloc = SchedulesBloc(
    repository: FixtureSchedulesRepository(
      delay: Duration.zero,
      objectCount: 3,
    ),
  );
  addTearDown(bloc.close);

  await tester.pumpWidget(
    MaterialApp(
      home: BlocProvider<SchedulesBloc>.value(
        value: bloc,
        child: const SchedulesScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();

  return bloc;
}

void main() {
  testWidgets('тап по значку открывает список актов объекта за год ленты', (
    WidgetTester tester,
  ) async {
    final SchedulesBloc bloc = await _pump(tester);
    final ScheduleRow row = (bloc.state as SchedulesLoaded).rows.first;

    await tester.tap(
      find.descendant(
        of: find.byType(ScheduleRowTile).first,
        matching: find.byType(DefectsBadge),
      ),
    );
    await tester.pumpAndSettle();

    final DefectsScreen screen = tester.widget<DefectsScreen>(
      find.byType(DefectsScreen),
    );
    expect(screen.objectId, row.objectId);
    expect(screen.initialYear, row.year);
    expect(screen.objectName, row.nameLabel);
  });
}
