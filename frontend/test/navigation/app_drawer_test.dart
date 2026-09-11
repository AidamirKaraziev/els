import 'package:els/helper/button/side_menu_button.dart';
import 'package:els/helper/class_colors.dart';
import 'package:els/helper/session.dart';
import 'package:els/navigation/app_drawer.dart';
import 'package:els/navigation/app_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const List<String> _order = <String>[
  'Главная',
  'Объекты',
  'График',
  'Работы',
  'Отчёты',
  'Компании',
  'Сотрудники',
];

Widget _drawer({
  required int roleId,
  AppSection current = AppSection.home,
  ValueChanged<AppSection>? onSelect,
  VoidCallback? onLogout,
}) {
  return MaterialApp(
    home: Scaffold(
      body: SizedBox(
        width: 320.0,
        height: 800.0,
        child: AppDrawer(
          current: current,
          roleId: roleId,
          onSelect: onSelect ?? (_) {},
          onLogout: onLogout ?? () {},
        ),
      ),
    ),
  );
}

List<String> _titles(WidgetTester tester) => tester
    .widgetList<MenuButton>(find.byType(MenuButton))
    .map((MenuButton b) => b.title)
    .toList();

void main() {
  for (final int roleId in <int>[Roles.admin, Roles.foreman]) {
    testWidgets('у роли $roleId семь разделов в утверждённом порядке и «Выйти»',
        (WidgetTester tester) async {
      await tester.pumpWidget(_drawer(roleId: roleId));
      expect(_titles(tester), <String>[..._order, 'Выйти']);
    });
  }

  testWidgets('открытый раздел подсвечен, остальные прозрачны',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      _drawer(roleId: Roles.foreman, current: AppSection.works),
    );
    for (final MenuButton b
        in tester.widgetList<MenuButton>(find.byType(MenuButton))) {
      expect(
        b.colorButton,
        b.title == 'Работы' ? ColorApp.myColorGreenLine : Colors.transparent,
        reason: b.title,
      );
    }
  });

  testWidgets('тап по пункту отдаёт раздел, «Выйти» — onLogout',
      (WidgetTester tester) async {
    AppSection? picked;
    int logouts = 0;
    await tester.pumpWidget(_drawer(
      roleId: Roles.admin,
      onSelect: (AppSection s) => picked = s,
      onLogout: () => logouts++,
    ));
    await tester.tap(find.text('Отчёты'));
    expect(picked, AppSection.reports);
    await tester.tap(find.text('Выйти'));
    expect(logouts, 1);
  });
}
