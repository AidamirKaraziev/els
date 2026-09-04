/// Объекты механика — те, что видны из его же работ.
///
/// Отдельной ручки «мои объекты» у механика нет: `/object/by-mechanic/`
/// живёт в админ-панели, требует `OBJECT_READ` и чужой `mechanic_id`
/// (`backend/src/api/api_v1/endpoints/object.py`), и в машинном помещении
/// без связи бесполезна. Зато объект приходит внутри каждой заявки и
/// каждого планового ТО, а те уже лежат в локальной базе — значит, список
/// собирается из них, работает оффлайн и не стоит ни одного запроса.
///
/// Плата за это честная и её надо знать: **объект, на котором у механика
/// сейчас нет ни работ, ни заявок, в список не попадёт.** Дефект на таком
/// заводится не отсюда, а с заявки, которую по нему заведут.
library;

import 'tasks.dart';

/// Объект глазами механика: столько, сколько нужно, чтобы его узнать.
class MechanicObject {
  const MechanicObject({
    required this.id,
    required this.name,
    this.address,
    this.badge,
  });

  final int id;
  final String name;
  final String? address;

  /// Тип объекта — «Лифт», «Эскалатор». Тем же значком объект помечен в
  /// списке заявок.
  final String? badge;
}

/// Собирает объекты из работ, схлопывая дубли.
///
/// Один объект приходит и заявкой, и плановым ТО, и не по разу — в списке он
/// должен быть один. Побеждает первое встреченное описание, а недостающий
/// адрес добирается из следующих: у заявки объект приходит подробнее, чем у
/// ТО, и терять адрес из-за порядка работ незачем.
///
/// Порядок — по названию: список читают глазами, ища знакомый дом, а не
/// свежую работу.
List<MechanicObject> objectsFromTasks(List<MechanicTask> tasks) {
  final Map<int, MechanicObject> found = <int, MechanicObject>{};

  for (final MechanicTask task in tasks) {
    final Map<String, dynamic> row = task.kind == TaskKind.order
        ? asMap(task.raw['object_id'])
        : asMap(task.raw['object']);

    final int? id = asInt(row['id']);
    if (id == null) continue;

    final String? address = asString(row['address']);
    final MechanicObject? seen = found[id];
    if (seen == null) {
      found[id] = MechanicObject(
        id: id,
        name: asString(row['name']) ?? 'Объект №$id',
        address: address,
        badge: objectTypeName(row),
      );
      continue;
    }
    if (seen.address == null && address != null) {
      found[id] = MechanicObject(
        id: seen.id,
        name: seen.name,
        address: address,
        badge: seen.badge,
      );
    }
  }

  final List<MechanicObject> objects = found.values.toList();
  objects.sort((MechanicObject a, MechanicObject b) => a.name.compareTo(b.name));
  return objects;
}
