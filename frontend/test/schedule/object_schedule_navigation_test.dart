/// Переходы из графика объекта: клетка ведёт в работу, плашка — в сотрудника.
///
/// Проверяем не содержимое целевых экранов — оно грузится из сети и в тесте
/// его нет, — а сам переход: маршрут кладётся поверх, «назад» возвращает в тот
/// же год ленты, а неподходящая клетка и человек без id молчат.
library;

import 'package:els/screns/schedule/models/schedule_role.dart';
import 'package:els/screns/schedule/object/models/schedule_object_card.dart';
import 'package:els/screns/schedule/object/models/schedule_responsible.dart';
import 'package:els/screns/schedule/object/repository/fixture_schedule_object_repository.dart';
import 'package:els/screns/schedule/object/view/schedule_object_screen.dart';
import 'package:els/screns/schedule/object/widgets/object_responsibles_card.dart';
import 'package:els/screns/schedule/view/schedule_work_card_screen.dart';
import 'package:els/screns/schedule/widgets/month_strip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Год, на который фикстура кладёт заполненную ленту.
const int _filledYear = 2026;

/// Клетки ленты в порядке месяцев — по тултипам внутри самой ленты.
Finder _cells() => find.descendant(
      of: find.byType(MonthStrip),
      matching: find.byType(Tooltip),
    );

Future<void> _pumpScreen(
  WidgetTester tester, {
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
        role: ScheduleRole.admin,
        initialYear: initialYear,
        objectName: 'ТЦ Карнавал 3 этаж 1',
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Плашка ответственного с заданным человеком, отдельно от экрана.
Future<List<ScheduleResponsible>> _pumpResponsibles(
  WidgetTester tester, {
  required ScheduleResponsible foreman,
}) async {
  final List<ScheduleResponsible> opened = <ScheduleResponsible>[];
  tester.view.physicalSize = const Size(1600.0, 900.0);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ObjectResponsiblesCard(
          card: ScheduleObjectCard(id: 1, foreman: foreman),
          onOpen: opened.add,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return opened;
}

void main() {
  group('переходы из графика объекта', () {
    testWidgets('клик по заполненной клетке открывает карточку работы',
        (WidgetTester tester) async {
      await _pumpScreen(tester);

      // Первая клетка заполненного года — у фикстуры за ней стоит акт.
      await tester.tap(_cells().first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(ScheduleWorkCardScreen), findsOneWidget);
      // Шапка карточки — название объекта, а не безымянная «Работа»: человек
      // должен видеть, чью работу открыл.
      expect(
        find.descendant(
          of: find.byType(ScheduleWorkCardScreen),
          matching: find.text('ТЦ Карнавал 3 этаж 1'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('«назад» возвращает в тот же год ленты',
        (WidgetTester tester) async {
      // Открываем на пустом годе и переключаемся на заполненный: так год в
      // блоке отличается от того, с которым экран создали, и видно, что
      // возврат приводит именно туда, откуда ушли, а не на умолчание.
      await _pumpScreen(tester, initialYear: _filledYear - 1);
      await tester.tap(find.byTooltip('Следующий год'));
      await tester.pumpAndSettle();

      await tester.tap(_cells().first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(ScheduleWorkCardScreen), findsOneWidget);

      final NavigatorState navigator = tester.state(find.byType(Navigator));
      navigator.pop();
      await tester.pumpAndSettle();

      expect(find.byType(ScheduleWorkCardScreen), findsNothing);
      // Год остался тот, на который переключились вручную.
      expect(find.text('$_filledYear'), findsOneWidget);
    });

    testWidgets('плашка с id нажимается и отдаёт человека',
        (WidgetTester tester) async {
      final List<ScheduleResponsible> opened = await _pumpResponsibles(
        tester,
        foreman: const ScheduleResponsible(
          title: 'Прораб',
          fullName: 'Н.В. Гоголевский',
          id: 12,
        ),
      );

      await tester.tap(find.text('Н.В. Гоголевский'));
      await tester.pumpAndSettle();

      expect(opened, hasLength(1));
      expect(opened.single.id, 12);
    });

    testWidgets('плашка без id не нажимается', (WidgetTester tester) async {
      final List<ScheduleResponsible> opened = await _pumpResponsibles(
        tester,
        foreman: const ScheduleResponsible(
          title: 'Прораб',
          fullName: 'Н.В. Гоголевский',
        ),
      );

      expect(find.byType(InkWell), findsNothing);

      await tester.tap(find.text('Н.В. Гоголевский'));
      await tester.pumpAndSettle();

      expect(opened, isEmpty);
    });
  });
}
