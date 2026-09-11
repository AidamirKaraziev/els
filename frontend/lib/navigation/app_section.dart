import 'package:flutter/material.dart';

import '../helper/session.dart';

/// Разделы приложения — единственное место, где задан состав и порядок
/// пунктов бургера.
///
/// Раньше у админа и прораба было два разных drawer'а, и в каждом пункты
/// перечислялись руками со своими номерами экранов. Порядок расходился,
/// пункты пропадали при переходах. Здесь порядок — порядок `values`, а кто
/// что видит — `roles`. «Выйти» — не раздел, а действие; оно живёт в
/// `AppDrawer` отдельно, внизу.
enum AppSection {
  home('Главная', Icons.home_outlined),
  objects('Объекты', Icons.radio_button_checked_outlined),
  schedule('График', Icons.calendar_today),
  works('Работы', Icons.list_alt),
  reports('Отчёты', Icons.insert_chart_outlined),
  companies('Компании', Icons.business_outlined),
  employees('Сотрудники', Icons.people_outline);

  const AppSection(this.title, this.icon);

  final String title;
  final IconData icon;

  /// Роли, которым раздел показывается. Пока оба бургера сходятся в один,
  /// админ и прораб видят всё одинаково — таково решение E03.
  Set<int> get roles => const <int>{Roles.admin, Roles.foreman};

  /// Разделы для роли — в утверждённом порядке.
  static List<AppSection> forRole(int roleId) =>
      values.where((AppSection s) => s.roles.contains(roleId)).toList();
}
