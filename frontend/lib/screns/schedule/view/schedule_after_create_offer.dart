import 'package:flutter/material.dart';

import '../models/schedule_role.dart';
import '../object/repository/api_schedule_object_repository.dart';
import '../object/view/schedule_object_screen.dart';
import '../object/widgets/schedule_offer_dialog.dart';
import '../object/wizard/repository/api_maintenance_program_repository.dart';
import '../object/wizard/repository/api_schedule_wizard_repository.dart';
import '../object/wizard/view/schedule_wizard_screen.dart';
import '../repository/api_envelope.dart';

/// Путь «объект создан → график расставлен», начиная с предложения.
///
/// Формы создания объекта — три копии подрядчика, и собирать в каждой из них
/// диалог, мастер и экран графика значило бы трижды повторить одно. Здесь же
/// собираются боевые репозитории — ровно как в соседнем
/// `route_schedule_object_opener.dart`, и по той же причине: место, где
/// решают «фикстура или сеть», в проекте должно быть одно на переход.
///
/// Мастера ждём, в отличие от `RouteScheduleObjectOpener`: экран графика
/// открывается только после утверждения, и без результата мастера решить
/// нечего.
Future<void> offerScheduleForNewObject(
  BuildContext context, {
  required dynamic created,
  required ScheduleRole role,
}) async {
  final int? objectId = asInt(nested(created, 'id'));
  // Без id предлагать нечего: мастеру некуда писать график. Ответ без него —
  // не наш случай (`POST /object/` отдаёт объект целиком), но форма
  // подрядчика не проверяет даже код ответа, и падать здесь нельзя.
  if (objectId == null) return;

  final String objectName = asString(nested(created, 'name')) ?? '';
  final dynamic model = nested(created, 'factory_model_id');
  final int? modelId = asInt(nested(model, 'id'));
  final String? modelName = asString(nested(model, 'model'));

  // Год текущий — тот же, с которого открывается лента по умолчанию.
  final int year = DateTime.now().year;

  final bool? wanted = await showScheduleOfferDialog(
    context,
    objectName: objectName,
    year: year,
  );
  if (wanted != true) return;
  if (!context.mounted) return;

  final bool? approved = await Navigator.of(context).push<bool>(
    MaterialPageRoute<bool>(
      builder: (BuildContext context) => ScheduleWizardScreen(
        repository: ApiScheduleWizardRepository(modelName: modelName ?? ''),
        programRepository: ApiMaintenanceProgramRepository(),
        objectId: objectId,
        year: year,
        modelId: modelId,
        modelName: modelName,
        objectName: objectName.isEmpty ? null : objectName,
      ),
    ),
  );
  // Мастер закрыли «назад» — остаёмся там, откуда пришли. Объект создан, и
  // график заводится позже из окна графика.
  if (approved != true) return;
  if (!context.mounted) return;

  await Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (BuildContext context) => ScheduleObjectScreen(
        objectId: objectId,
        repository: ApiScheduleObjectRepository(),
        wizardRepository: (String modelName) =>
            ApiScheduleWizardRepository(modelName: modelName),
        programRepository: ApiMaintenanceProgramRepository(),
        role: role,
        initialYear: year,
        objectName: objectName.isEmpty ? null : objectName,
      ),
    ),
  );
}

/// Тот же путь, но кнопкой «Сохранить» формы: сначала закрыть форму, потом
/// предложить график.
///
/// Порядок важен: формы подрядчика открыты через `showDialog`, и второе окно
/// поверх первого встало бы под ним. Навигатор берём **до** закрытия — после
/// `pop` контекст формы уже не годится ни на что.
Future<void> closeFormAndOfferSchedule(
  BuildContext context, {
  required dynamic created,
  required ScheduleRole role,
}) async {
  final NavigatorState navigator = Navigator.of(context);
  navigator.pop();
  await offerScheduleForNewObject(
    navigator.context,
    created: created,
    role: role,
  );
}
