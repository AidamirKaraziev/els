/// Мастер расстановки графика: проверяем вид и шаги, а не расстановку.
///
/// Заготовку мастер берёт у репозитория — здесь фикстурного, — а в базу
/// по-прежнему ничего не пишет: `generate` подключается следующей работой.
/// Поэтому и проверяем то, что уже есть, — что кнопка ведёт в мастер, а не
/// раскладывает год сразу; что шаги листаются туда и обратно; что «Утвердить»
/// гаснет на исходе «нет шаблона»; что шаг «Точка отсчёта» отпадает, когда
/// цикл продолжается с прошлого года, — и как выделена клетка старта цикла.
library;

import 'package:els/helper/class_colors.dart';
import 'package:els/screns/schedule/models/schedule_role.dart';
import 'package:els/screns/schedule/object/repository/fixture_schedule_object_repository.dart';
import 'package:els/screns/schedule/object/view/schedule_object_screen.dart';
import 'package:els/screns/schedule/object/wizard/fixture_schedule_wizard_data.dart';
import 'package:els/screns/schedule/object/wizard/models/schedule_wizard_data.dart';
import 'package:els/screns/schedule/object/wizard/repository/fixture_schedule_wizard_repository.dart';
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
        repository: FixtureScheduleWizardRepository(
          fixture: fixture,
          withPreviousYear: withPreviousYear,
          delay: Duration.zero,
        ),
        objectId: 1,
        year: _emptyYear,
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
          wizardRepository: (String modelName) =>
              const FixtureScheduleWizardRepository(delay: Duration.zero),
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

  // ------------------------------------------------ вид клетки старта цикла
  //
  // Отдельно от раскладов фикстуры: она ведёт цикл с марта и первую позицию
  // никуда не двигает, а столкновение «старт + нет шаблона» на ней вообще не
  // воспроизводится — позиция 1 всегда ТО 1, у которого шаблон есть. Поэтому
  // клетки здесь собраны руками.

  testWidgets('первая позиция цикла помечена тегом «СТАРТ»',
      (WidgetTester tester) async {
    await _pumpPreview(tester, _handmade());

    expect(find.text('СТАРТ'), findsOneWidget);

    // Тег стоит на клетке позиции 1, а она пришлась на март — не на январь:
    // иначе тест прошёл бы и на ленте, которая просто метит первый месяц.
    final BoxDecoration march = _cellDecoration(tester, 'Март');
    expect(march.color, ColorApp.myColorBlack);
    expect(_cellDecoration(tester, 'Январь').color, isNot(ColorApp.myColorBlack));
  });

  testWidgets('старт на клетке «нет шаблона» остаётся янтарным',
      (WidgetTester tester) async {
    // Предупреждение важнее старта: из-за него график не утверждается, и
    // тёмная заливка его бы съела. Старт помечается рамкой и тегом.
    await _pumpPreview(tester, _handmade(missingAtStart: true));

    final BoxDecoration march = _cellDecoration(tester, 'Март');
    expect(march.color, ColorApp.myColorYellowLight);

    final BorderSide side = (march.border! as Border).top;
    expect(side.color, ColorApp.myColorBlack);
    expect(side.width, 2.0);

    expect(find.text('СТАРТ'), findsOneWidget);
  });
}

/// Заготовка с циклом, начинающимся в марте, — собранная руками.
///
/// [missingAtStart] помечает первую позицию цикла как «нет шаблона»: ровно то
/// столкновение двух акцентов, ради которого в клетке заведена тёмная рамка.
ScheduleWizardData _handmade({bool missingAtStart = false}) {
  const int anchor = 3;
  return ScheduleWizardData(
    year: _emptyYear,
    modelName: 'LIFT A388509',
    program: const <WizardProgramItem>[
      WizardProgramItem(position: 1, typeActName: 'ТО 1'),
    ],
    cells: <WizardPreviewCell>[
      for (int month = 1; month <= 12; month++)
        WizardPreviewCell(
          month: month,
          position: (month - anchor + 12) % 12 + 1,
          typeActName: 'ТО 1',
          templateMissing: missingAtStart && month == anchor,
        ),
    ],
  );
}

Future<void> _pumpPreview(WidgetTester tester, ScheduleWizardData data) async {
  tester.view.physicalSize = const Size(1600.0, 1400.0);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: WizardPreviewStep(data: data, anchorMonth: 3),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Оформление клетки месяца.
///
/// Ищем по тултипу: он единственный, что называет месяц целиком, — в самой
/// клетке стоит сокращение, и «Мар» нашлось бы и в соседнем тексте.
BoxDecoration _cellDecoration(WidgetTester tester, String month) {
  final Finder cell = find.descendant(
    of: find.byTooltip(_tooltipOf(tester, month)),
    matching: find.byType(Container),
  );
  final Container box = tester.widget<Container>(cell.first);
  return box.decoration! as BoxDecoration;
}

/// Полный текст тултипа клетки: месяц, вид ТО, пометка и, у старта, «старт
/// цикла». Собирать его в тесте руками значило бы повторять формат виджета.
String _tooltipOf(WidgetTester tester, String month) {
  final Iterable<Tooltip> tooltips = tester.widgetList<Tooltip>(
    find.byType(Tooltip),
  );
  return tooltips
      .map((Tooltip tooltip) => tooltip.message ?? '')
      .firstWhere((String message) => message.startsWith('$month ·'));
}
