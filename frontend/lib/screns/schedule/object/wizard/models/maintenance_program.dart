/// Программа обслуживания модели: двенадцать позиций «месяц цикла → вид ТО».
///
/// Формы классов повторяют ручку `/maintenance-program/by-model/{id}/`
/// (`backend/src/schemas/maintenance_program.py`): `position` — месяц
/// **цикла**, а не календаря, и правится программа целиком — частичной
/// правки у ручки нет по смыслу.
///
/// Своей логики здесь нет: что во что раскладывается по календарю, считает
/// бэкенд, а мастер это показывает.

/// Длина цикла — год, одно ТО в месяц. Столько же ждёт `PUT`.
const int kProgramLength = 12;

/// Вид ТО из справочника `types_acts`.
class TypeAct {
  const TypeAct({required this.id, required this.name});

  /// `null` — вид заведён только в этом окне и в справочнике его ещё нет:
  /// ручки на создание вида ТО у нас пока нет. С такой позицией программу
  /// не сохранить, и окно об этом говорит.
  final int? id;

  final String name;
}

/// Одна позиция программы.
class MaintenanceProgramItem {
  const MaintenanceProgramItem({
    required this.position,
    this.typeActId,
    this.typeActName = '',
  });

  /// 1..12 — месяц цикла.
  final int position;

  /// `null` — вид ТО на позиции не выбран: программу с такой позицией
  /// сохранить нельзя.
  final int? typeActId;

  final String typeActName;

  MaintenanceProgramItem copyWith({int? typeActId, String? typeActName}) {
    return MaintenanceProgramItem(
      position: position,
      typeActId: typeActId ?? this.typeActId,
      typeActName: typeActName ?? this.typeActName,
    );
  }
}

/// Программа модели целиком.
class MaintenanceProgram {
  const MaintenanceProgram({
    required this.modelId,
    required this.items,
    this.name,
  });

  /// Пустая программа на двенадцать позиций — то, с чего начинается создание.
  factory MaintenanceProgram.empty(int modelId) {
    return MaintenanceProgram(
      modelId: modelId,
      items: <MaintenanceProgramItem>[
        for (int position = 1; position <= kProgramLength; position++)
          MaintenanceProgramItem(position: position),
      ],
    );
  }

  final int modelId;

  /// Название программы. Марку с моделью подставляет мастер: у ручки поле
  /// свободное, и хранить в нём только дописанное человеком нельзя — тогда
  /// программа в базе оказалась бы без имени модели.
  final String? name;

  /// Двенадцать позиций по порядку.
  final List<MaintenanceProgramItem> items;

  bool get hasEmptyPosition =>
      items.any((MaintenanceProgramItem item) => item.typeActId == null);

  MaintenanceProgram copyWith({
    String? name,
    List<MaintenanceProgramItem>? items,
  }) {
    return MaintenanceProgram(
      modelId: modelId,
      name: name ?? this.name,
      items: items ?? this.items,
    );
  }
}
