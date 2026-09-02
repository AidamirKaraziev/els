/// Строка срока ближайшего ТО под лентой экрана объекта.
///
/// Проверяем правило, а не картинку: показывается месяц самого раннего
/// **незакрытого** ТО года, и роль на него не влияет.
library;

import 'package:els/screns/schedule/models/schedule_role.dart';
import 'package:els/screns/schedule/object/repository/fixture_schedule_object_repository.dart';
import 'package:els/screns/schedule/object/view/schedule_object_screen.dart';
import 'package:els/screns/schedule/object/widgets/object_schedule_card.dart';
import 'package:els/screns/schedule/object/wizard/repository/fixture_maintenance_program_repository.dart';
import 'package:els/screns/schedule/object/wizard/repository/fixture_schedule_wizard_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Год, на который фикстура кладёт заполненную ленту. Берём заданный, а не
/// «текущий»: тест не должен ломаться первого января.
const int _filledYear = 2026;

Future<void> _pump(
  WidgetTester tester, {
  ScheduleRole role = ScheduleRole.admin,
  int initialYear = _filledYear,
}) async {
  tester.view.physicalSize = const Size(1600.0, 1400.0);
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
        role: role,
        initialYear: initialYear,
        objectName: 'График',
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('показан месяц самого раннего просроченного',
      (WidgetTester tester) async {
    await _pump(tester);

    // В фикстуре просрочен май, а назначенные — сентябрь и дальше: долг
    // делать раньше, чем то, что только назначено.
    expect(find.text('ТО 1 · 1 – 31 мая'), findsOneWidget);
  });

  testWidgets('года без графика строку не показывают',
      (WidgetTester tester) async {
    await _pump(tester, initialYear: _filledYear + 1);

    expect(find.textContaining(' – '), findsNothing);
    expect(find.textContaining('График на'), findsOneWidget);
  });

  testWidgets('прораб и админ видят строку одинаково',
      (WidgetTester tester) async {
    await _pump(tester, role: ScheduleRole.foreman);

    expect(find.text('ТО 1 · 1 – 31 мая'), findsOneWidget);
    expect(find.byType(ObjectScheduleCard), findsOneWidget);
  });
}
