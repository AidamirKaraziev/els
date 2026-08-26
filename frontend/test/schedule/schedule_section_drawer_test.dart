/// Раздел «Графики» живёт внутри оболочки приложения и обязан отдавать её меню.
///
/// Старые экраны подрядчика несли `drawer: MyDrawer()` сами: на узкой ширине
/// боковое меню открывается только из экрана. Подмени вход без этого — и
/// человек с телефона провалится в «Графики» и останется там без навигации.
library;

import 'package:els/screns/schedule/repository/fixture_schedules_repository.dart';
import 'package:els/screns/schedule/view/schedule_section.dart';
import 'package:els/screns/schedule/view/schedules_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Метка вместо настоящего меню: у админа и прораба они разные, и раздел не
/// должен знать, какое именно ему дали.
class _FakeDrawer extends StatelessWidget {
  const _FakeDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) => const Drawer(child: Text('меню'));
}

Future<void> _pump(
  WidgetTester tester,
  ScheduleRole role, {
  required double width,
}) async {
  tester.view.physicalSize = Size(width, 900.0);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      home: ScheduleSection(
        role: role,
        drawer: const _FakeDrawer(),
        repository: FixtureSchedulesRepository(delay: Duration.zero),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

AppBar _appBar(WidgetTester tester) =>
    tester.widget<AppBar>(find.byType(AppBar).first);

void main() {
  for (final ScheduleRole role in ScheduleRole.values) {
    testWidgets('у роли $role меню приложения на месте',
        (WidgetTester tester) async {
      await _pump(tester, role, width: 375);

      final Scaffold scaffold =
          tester.widget<Scaffold>(find.byType(Scaffold).first);
      expect(scaffold.drawer, isA<_FakeDrawer>());
      // И его есть чем открыть: на узкой ширине оболочка меню не рисует.
      expect(_appBar(tester).automaticallyImplyLeading, isTrue);
    });

    testWidgets('у роли $role на широком экране второго гамбургера нет',
        (WidgetTester tester) async {
      await _pump(tester, role, width: 1440);

      // Шире 1350 оболочка держит меню постоянной колонкой — кнопка в шапке
      // вела бы к тому же меню второй раз.
      expect(_appBar(tester).automaticallyImplyLeading, isFalse);
    });
  }

  testWidgets('на вложенном экране кнопка «назад» остаётся и на широком окне',
      (WidgetTester tester) async {
    await _pump(tester, ScheduleRole.admin, width: 1440);

    // Клик по участку открывает ленту поверх участков.
    await tester.tap(find.text('Участок № 1'));
    await tester.pumpAndSettle();

    expect(find.byType(SchedulesScreen), findsOneWidget);
    // Без этого уйти с ленты было бы нечем: на широком окне гамбургер скрыт,
    // а «назад» рисуется той же кнопкой шапки.
    expect(_appBar(tester).automaticallyImplyLeading, isTrue);
  });
}
