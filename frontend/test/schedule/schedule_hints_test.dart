/// Значки «?» на экране графика объекта.
///
/// Проверяем не текст подсказки, а то, что значок вообще доходит до пальца:
/// на прежнем экране подсказок не было именно потому, что ставить их было
/// некуда, и молчаливо неработающий значок здесь — худший из исходов.
library;

import 'package:els/helper/hints/hint_icon.dart';
import 'package:els/helper/hints/hints.dart';
import 'package:els/screns/schedule/models/schedule_role.dart';
import 'package:els/screns/schedule/object/repository/fixture_schedule_object_repository.dart';
import 'package:els/screns/schedule/object/view/schedule_object_screen.dart';
import 'package:els/screns/schedule/object/wizard/repository/fixture_maintenance_program_repository.dart';
import 'package:els/screns/schedule/object/wizard/repository/fixture_schedule_wizard_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const int _filledYear = 2026;

Future<void> _pump(WidgetTester tester, {required Size size}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      home: ScheduleObjectScreen(
        objectId: 1,
        repository: FixtureScheduleObjectRepository(filledYear: _filledYear),
        wizardRepository: (String modelName) =>
            const FixtureScheduleWizardRepository(delay: Duration.zero),
        programRepository: FixtureMaintenanceProgramRepository(
          delay: Duration.zero,
        ),
        role: ScheduleRole.admin,
        initialYear: _filledYear,
        objectName: 'График',
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('значок у «Плановые ТО» открывает подсказку', (tester) async {
    await _pump(tester, size: const Size(1600.0, 1400.0));

    final Finder icon = find.byWidgetPredicate(
      (Widget w) => w is HintIcon && w.id == HintIds.scheduleMonthCreatesAct,
    );
    expect(icon, findsOneWidget);

    await tester.tap(icon);
    await tester.pumpAndSettle();

    expect(find.text(hints[HintIds.scheduleMonthCreatesAct]!.title),
        findsOneWidget);
  });

  testWidgets('на узком окне значок работает и в столбце', (tester) async {
    // Ниже 620 px подпись ленты уходит из строки в столбец и уезжает за
    // нижний край — значок должен работать и там, после прокрутки.
    await _pump(tester, size: const Size(900.0, 1400.0));

    final Finder icon = find.byWidgetPredicate(
      (Widget w) => w is HintIcon && w.id == HintIds.scheduleMonthCreatesAct,
    );
    await tester.ensureVisible(icon);
    await tester.pumpAndSettle();
    await tester.tap(icon);
    await tester.pumpAndSettle();

    expect(find.text(hints[HintIds.scheduleMonthCreatesAct]!.title),
        findsOneWidget);
  });
}
