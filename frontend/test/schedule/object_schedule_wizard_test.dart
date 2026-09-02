/// Мастер расстановки графика — набросок: проверяем вид, а не расстановку.
///
/// Логики в мастере пока нет: данные приходят фикстурой, в базу он ничего не
/// пишет. Поэтому и проверяем только то, что уже есть, — что кнопка ведёт в
/// мастер, а не раскладывает год сразу; что шаги листаются туда и обратно;
/// что «Утвердить» гаснет на исходе «нет шаблона» и что шаг «Точка отсчёта»
/// отпадает, когда цикл продолжается с прошлого года.
library;

import 'package:els/screns/schedule/models/schedule_role.dart';
import 'package:els/screns/schedule/object/repository/fixture_schedule_object_repository.dart';
import 'package:els/screns/schedule/object/view/schedule_object_screen.dart';
import 'package:els/screns/schedule/object/wizard/fixture_schedule_wizard_data.dart';
import 'package:els/screns/schedule/object/wizard/view/schedule_wizard_screen.dart';
import 'package:els/screns/schedule/object/wizard/widgets/wizard_anchor_step.dart';
import 'package:els/screns/schedule/object/wizard/widgets/wizard_preview_step.dart';
import 'package:els/screns/schedule/object/wizard/widgets/wizard_program_step.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Год, на который фикстура экрана кладёт заполненную ленту. Мастер
/// открываем на соседнем: кнопка создания есть только у пустого года.
const int _filledYear = 2026;
const int _emptyYear = 2027;

Future<void> _pumpWizard(
  WidgetTester tester, {
  WizardFixture fixture = WizardFixture.ok,
  bool withPreviousYear = false,
}) async {
  tester.view.physicalSize = const Size(1600.0, 1400.0);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      home: ScheduleWizardScreen(
        data: buildWizardFixture(
          fixture,
          withPreviousYear: withPreviousYear,
          year: _emptyYear,
        ),
        objectName: 'ТЦ Карнавал 3 этаж 1',
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, String label) async {
  await tester.tap(find.widgetWithText(ElevatedButton, label).first);
  await tester.pumpAndSettle();
}

/// Кнопка нижней панели: включена или нет.
bool _enabled(WidgetTester tester, String label) {
  final ElevatedButton button = tester.widget<ElevatedButton>(
    find.widgetWithText(ElevatedButton, label).first,
  );
  return button.onPressed != null;
}

void main() {
  testWidgets('кнопка «Создать график» открывает мастер, а не раскладывает год',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1600.0, 1400.0);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: ScheduleObjectScreen(
          objectId: 1,
          repository: FixtureScheduleObjectRepository(filledYear: _filledYear),
          role: ScheduleRole.admin,
          initialYear: _emptyYear,
          objectName: 'ТЦ Карнавал 3 этаж 1',
        ),
      ),
    );
    await tester.pumpAndSettle();

    await _tap(tester, 'Создать график на $_emptyYear');

    expect(find.byType(ScheduleWizardScreen), findsOneWidget);
    expect(find.byType(WizardProgramStep), findsOneWidget);
  });

  testWidgets('три шага листаются вперёд и назад',
      (WidgetTester tester) async {
    await _pumpWizard(tester);

    expect(find.byType(WizardProgramStep), findsOneWidget);

    await _tap(tester, 'Далее');
    expect(find.byType(WizardAnchorStep), findsOneWidget);

    await _tap(tester, 'Далее');
    expect(find.byType(WizardPreviewStep), findsOneWidget);
    // На последнем шаге «Далее» уступает место «Утвердить».
    expect(find.widgetWithText(ElevatedButton, 'Далее'), findsNothing);

    await tester.tap(find.widgetWithText(TextButton, 'Назад'));
    await tester.pumpAndSettle();
    expect(find.byType(WizardAnchorStep), findsOneWidget);
  });

  testWidgets('на первом шаге «Отмена» закрывает мастер',
      (WidgetTester tester) async {
    await _pumpWizard(tester);

    await tester.tap(find.widgetWithText(TextButton, 'Отмена'));
    await tester.pumpAndSettle();

    // Мастер был единственным маршрутом — после закрытия экрана нет.
    expect(find.byType(WizardProgramStep), findsNothing);
  });

  testWidgets('прошлогодний график убирает шаг «Точка отсчёта»',
      (WidgetTester tester) async {
    await _pumpWizard(tester, withPreviousYear: true);

    await _tap(tester, 'Далее');

    expect(find.byType(WizardAnchorStep), findsNothing);
    expect(find.byType(WizardPreviewStep), findsOneWidget);
  });

  testWidgets('предпросмотр называет месяц начала цикла',
      (WidgetTester tester) async {
    // Фикстура ведёт цикл с марта. Месяц в родительном падеже: «с марта», а
    // не «с март» — на такой строке спотыкается глаз, а не только редактор.
    await _pumpWizard(tester, withPreviousYear: true);

    await _tap(tester, 'Далее');

    expect(find.text('Цикл начинается с марта.'), findsOneWidget);
  });

  testWidgets('«нет шаблона» — «Утвердить» выключена',
      (WidgetTester tester) async {
    await _pumpWizard(
      tester,
      fixture: WizardFixture.withMissingTemplate,
      withPreviousYear: true,
    );

    await _tap(tester, 'Далее');

    expect(_enabled(tester, 'Утвердить'), isFalse);
    expect(find.textContaining('нет шаблона чек-листа'), findsOneWidget);
  });

  testWidgets('чистый год — «Утвердить» доступна и закрывает мастер',
      (WidgetTester tester) async {
    await _pumpWizard(tester, withPreviousYear: true);

    await _tap(tester, 'Далее');

    expect(_enabled(tester, 'Утвердить'), isTrue);

    await _tap(tester, 'Утвердить');
    expect(find.byType(WizardPreviewStep), findsNothing);
  });

  testWidgets('занятые месяцы утверждению не мешают',
      (WidgetTester tester) async {
    await _pumpWizard(
      tester,
      fixture: WizardFixture.withOccupied,
      withPreviousYear: true,
    );

    await _tap(tester, 'Далее');

    expect(_enabled(tester, 'Утвердить'), isTrue);
    expect(find.textContaining('уже занято'), findsWidgets);
  });
}
