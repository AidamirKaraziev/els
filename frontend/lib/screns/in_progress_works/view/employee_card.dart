/// Переход из карточки работы в карточку сотрудника — «Добавить номер».
///
/// Оболочки подрядчика держат открытый раздел глобальной переменной на роль и
/// перерисовываются по `myStream` — та же беда, что описана у перехода в
/// профиль в `helper/session.dart`. Истории переходов в них нет, поэтому
/// переключить раздел значило бы увести человека без возврата: прораб пришёл
/// вписать номер, а вернулся бы в список сотрудников.
///
/// Поэтому карточку сотрудника открываем **маршрутом** поверх карточки
/// работы, а её кнопке «назад» объясняем, что снимать надо маршрут, а не
/// менять индекс, — см. [goBackFromSection]. Раздел оболочки при этом не
/// двигается вовсе: под маршрутами всё это время лежит лента сданных работ.
///
/// Карточка сотрудника у админа и у прораба — два разных экрана подрядчика с
/// разными загрузчиками. Ролям, у которых такого экрана нет, ссылка не
/// показывается: жёлтая пометка «Номер не указан» остаётся, вести ей некуда.
library;

import 'package:flutter/material.dart';

import '../../../foreman/employee_foreman/employee_page_foreman.dart';
import '../../../foreman/employee_foreman/employees_screen_foreman.dart'
    show getListEmployeesInfoForeman;
import '../../../helper/class_colors.dart';
import '../../../helper/session.dart';
import '../../employee/view/employee_page.dart';
import '../../employee/view/employees_screen.dart' show getListEmployeesInfo;

/// Есть ли у этой роли карточка сотрудника, в которую можно увести.
bool get canOpenEmployeeCard =>
    idUserTest == Roles.admin || idUserTest == Roles.foreman;

/// Открыть карточку сотрудника поверх карточки работы.
///
/// Ждёт, пока человек оттуда вернётся: карточке работы после этого надо
/// перечитать телефон — за ним прораб туда и ходил.
///
/// Сначала грузим человека в глобальную переменную, из которой читает экран
/// подрядчика, и только потом открываем маршрут: сделай наоборот — экран
/// нарисуется по данным прошлого сотрудника.
Future<void> openEmployeeCard(BuildContext context, int userId) async {
  if (!canOpenEmployeeCard) return;

  final bool foreman = idUserTest == Roles.foreman;
  IntTest.pressHover = userId;
  if (foreman) {
    await getListEmployeesInfoForeman(userId);
  } else {
    await getListEmployeesInfo(userId);
  }

  if (!context.mounted) return;
  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (BuildContext context) => foreman
          ? const OpenViewEmployeeForeman()
          : const OpenViewEmployee(),
    ),
  );
}
