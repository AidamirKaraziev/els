import 'dart:async';

import 'package:flutter/material.dart';

import '../models/schedule_role.dart';
import '../models/schedule_row.dart';
import '../object/repository/api_schedule_object_repository.dart';
import '../object/view/schedule_object_screen.dart';
import '../object/wizard/repository/api_maintenance_program_repository.dart';
import '../object/wizard/repository/api_schedule_wizard_repository.dart';
import 'schedule_object_opener.dart';

/// Открывает экран «График объекта» маршрутом поверх оболочки.
///
/// Прежде клик уводил на экран подрядчика: оболочка держит все экраны одним
/// списком и показывает тот, чей номер лежит в `IntTest.indexScreens`, а объект
/// приезжал туда глобальной переменной. Новый экран так открывать незачем — у
/// него свой `Scaffold` со своей шапкой, все данные он берёт через репозитории,
/// и `Navigator.push` кладёт его поверх оболочки ровно так же, как сам экран
/// открывает карточку работы и карточку сотрудника. Стрелка «назад» возвращает
/// в ленту, а лента под маршрутом не пересоздаётся — отбор и год остаются.
///
/// Экраны подрядчика (12 у админа, 14 у прораба) остаются в списках оболочки:
/// из «Графиков» в них больше не заходят, но снимать их — отдельная работа.
class RouteScheduleObjectOpener extends ScheduleObjectOpener {
  const RouteScheduleObjectOpener.admin() : _role = ScheduleRole.admin;

  const RouteScheduleObjectOpener.foreman() : _role = ScheduleRole.foreman;

  /// Чьими глазами открыт экран: от роли зависит кнопка создания графика.
  final ScheduleRole _role;

  @override
  Future<void> open(
    BuildContext context,
    ScheduleRow row, {
    VoidCallback? onScheduleChanged,
  }) async {
    // Маршрут не ждём: его future завершается при закрытии экрана, а лента до
    // возврата из `open` держит индикатор.
    unawaited(
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (BuildContext context) => ScheduleObjectScreen(
            objectId: row.objectId,
            repository: ApiScheduleObjectRepository(),
            wizardRepository: (String modelName) =>
                ApiScheduleWizardRepository(modelName: modelName),
            programRepository: ApiMaintenanceProgramRepository(),
            role: _role,
            // Год берём из строки, а не текущий: человек смотрел ленту за
            // выбранный год, и график должен открыться на нём же.
            initialYear: row.year,
            // Название лента знает — шапка не ждёт загрузки карточки.
            objectName: row.nameLabel,
            // Лента под маршрутом жива: закрыли ТО или расставили график —
            // её строка перечитывается сразу, а не по возврату назад.
            onScheduleChanged: onScheduleChanged,
          ),
        ),
      ),
    );
  }
}
