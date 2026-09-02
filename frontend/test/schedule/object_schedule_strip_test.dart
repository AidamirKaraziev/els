/// Лента месяцев на экране графика объекта.
///
/// Проверяем то, ради чего этап и делался: цвета состояний видны, год
/// переключается, год без графика честно говорит об этом и предлагает его
/// создать, а созданный график тут же виден на ленте.
library;

import 'package:els/screns/schedule/models/schedule_role.dart';
import 'package:els/screns/schedule/object/repository/fixture_schedule_object_repository.dart';
import 'package:els/screns/schedule/object/view/schedule_object_screen.dart';
import 'package:els/screns/schedule/object/wizard/repository/fixture_schedule_wizard_repository.dart';
import 'package:els/screns/schedule/widgets/month_strip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Год, на который фикстура кладёт заполненную ленту. Берём не «текущий», а
/// заданный: тест не должен ломаться первого января.
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
        role: role,
        initialYear: initialYear,
        objectName: 'График',
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Заливки всех клеток ленты — по `Container` внутри тултипов.
///
/// Ищем внутри самой ленты: у стрелок года тултипы тоже есть, и по общему
/// списку первой клеткой оказался бы «Предыдущий год».
List<Color?> _fills(WidgetTester tester) {
  final Finder cells = find.descendant(
    of: find.byType(MonthStrip),
    matching: find.byType(Tooltip),
  );
  return <Color?>[
    for (int i = 0; i < tester.widgetList(cells).length; i++)
      (tester
              .widget<Container>(find
                  .descendant(
                    of: cells.at(i),
                    matching: find.byType(Container),
                  )
                  .first)
              .decoration! as BoxDecoration)
          .color,
  ];
}

Future<void> _tapNextYear(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Следующий год'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('лента показывает состояния цветом', (WidgetTester tester) async {
    await _pump(tester);

    expect(find.text('Плановые ТО'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(MonthStrip),
        matching: find.byType(Tooltip),
      ),
      findsNWidgets(12),
    );

    final List<Color?> fills = _fills(tester);
    expect(fills, hasLength(12));
    // Все пять состояний фикстуры: четыре заливки и пустой месяц без неё.
    expect(fills.whereType<Color>().toSet().length, 4);
    expect(fills.where((Color? fill) => fill == null), hasLength(1));
  });

  testWidgets('месяцы подписаны', (WidgetTester tester) async {
    await _pump(tester);

    expect(find.text('Янв'), findsOneWidget);
    expect(find.text('Дек'), findsOneWidget);
  });

  testWidgets('год переключается, по умолчанию — заданный',
      (WidgetTester tester) async {
    await _pump(tester);

    expect(find.text('$_filledYear'), findsOneWidget);

    await _tapNextYear(tester);

    expect(find.text('${_filledYear + 1}'), findsOneWidget);
    expect(find.text('$_filledYear'), findsNothing);
  });

  testWidgets('год без графика: пустая лента и кнопка создания',
      (WidgetTester tester) async {
    await _pump(tester);
    await _tapNextYear(tester);

    // Клетки на месте все двенадцать — просто пустые.
    expect(_fills(tester).where((Color? fill) => fill == null), hasLength(12));
    expect(
      find.text('График на ${_filledYear + 1} год не заводили'),
      findsOneWidget,
    );
    expect(
      find.text('Создать график на ${_filledYear + 1}'),
      findsOneWidget,
    );
  });

  testWidgets('на заполненном годе кнопки создания нет',
      (WidgetTester tester) async {
    await _pump(tester);

    expect(find.textContaining('Создать график'), findsNothing);
  });

  testWidgets('кнопка расставляет график и лента перерисовывается',
      (WidgetTester tester) async {
    await _pump(tester);
    await _tapNextYear(tester);

    await tester.tap(find.text('Создать график на ${_filledYear + 1}'));
    await tester.pumpAndSettle();

    // Пустых месяцев не осталось, кнопка и подпись ушли.
    expect(_fills(tester).where((Color? fill) => fill == null), isEmpty);
    expect(find.textContaining('Создать график'), findsNothing);
    expect(find.textContaining('не заводили'), findsNothing);
  });

  testWidgets('у прораба кнопка создания тоже есть',
      (WidgetTester tester) async {
    // `planned_to:write` есть и у прораба — он и расставляет графики своих
    // участков.
    await _pump(tester, role: ScheduleRole.foreman);
    await _tapNextYear(tester);

    expect(
      find.text('Создать график на ${_filledYear + 1}'),
      findsOneWidget,
    );
  });

  testWidgets('карточка объекта при переключении года остаётся на месте',
      (WidgetTester tester) async {
    await _pump(tester);
    await _tapNextYear(tester);

    expect(find.text('г. Краснодар, ул. Северная, 356'), findsOneWidget);
    expect(find.text('Н.В. Гоголевский'), findsOneWidget);
  });
}
