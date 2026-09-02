import 'models/schedule_wizard_data.dart';

/// Расклады мастера без сети — пока внешний вид не утверждён.
///
/// Три исхода предпросмотра, ради которых мастер и затевался: чистый год,
/// год с занятыми месяцами и год, который нельзя утвердить из-за
/// недостающего шаблона. Их видно на фикстуре все три, не поднимая базу.
enum WizardFixture {
  /// Всё раскладывается, «Утвердить» доступна.
  ok,

  /// Два месяца уже заняты актами — расстановка их не тронет.
  withOccupied,

  /// У модели нет шаблона на ТО 6: «Утвердить» гаснет.
  withMissingTemplate,
}

extension WizardFixtureTitle on WizardFixture {
  /// Подпись для переключателя в точке входа `lib/dev`.
  String get title {
    switch (this) {
      case WizardFixture.ok:
        return 'Чистый год';
      case WizardFixture.withOccupied:
        return 'Есть занятые месяцы';
      case WizardFixture.withMissingTemplate:
        return 'Нет шаблона на ТО 6';
    }
  }
}

/// Программа обслуживания модели — та же, что в фикстуре экрана объекта
/// (`fixture_schedule_object_repository.dart`) и в примере плана:
/// `ТО1, ТО1, ТО3, ТО1, ТО1, ТО6, ТО1, ТО1, ТО3, ТО1, ТО1, ТО12`.
///
/// Одна и та же программа в двух фикстурах не случайность: экран объекта и
/// мастер показывают один и тот же объект, и расходиться им нельзя — иначе
/// на показе видно два разных графика подряд.
const List<int> _program = <int>[1, 1, 3, 1, 1, 6, 1, 1, 3, 1, 1, 12];

/// Месяц, с которого идёт цикл в раскладах фикстуры. Март — чтобы позиция и
/// месяц календаря заведомо не совпадали: на якоре в январе перепутать их
/// нельзя, а значит и проверить вёрстку тоже.
const int _anchorMonth = 3;

/// Собрать расклад мастера.
///
/// [withPreviousYear] — есть ли у объекта график за прошлый год. Есть —
/// якорь восстановлен, шаг «Точка отсчёта» пропускается.
ScheduleWizardData buildWizardFixture(
  WizardFixture fixture, {
  bool withPreviousYear = false,
  int? year,
  int anchorMonth = _anchorMonth,
}) {
  final int targetYear = year ?? DateTime.now().year + 1;

  // Месяцы, занятые актами. Только в раскладе `withOccupied`: в остальных
  // год чистый, и клетки «уже занято» показывать неоткуда.
  final Set<int> occupied = fixture == WizardFixture.withOccupied
      ? <int>{4, 5}
      : <int>{};

  // Нет шаблона — у вида ТО, а не у месяца: шаблон чек-листа заводится на
  // модель и вид работы. ТО 6 в программе один, но помечаем именно по виду,
  // как это делает ручка предпросмотра.
  final int? missingTypeAct =
      fixture == WizardFixture.withMissingTemplate ? 6 : null;

  final List<WizardPreviewCell> cells = <WizardPreviewCell>[];
  for (int month = 1; month <= 12; month++) {
    // Позиция цикла для месяца календаря: на якорь приходится первая.
    final int position = (month - anchorMonth + 12) % 12 + 1;
    final int typeAct = _program[position - 1];
    cells.add(WizardPreviewCell(
      month: month,
      position: position,
      typeActName: 'ТО $typeAct',
      occupied: occupied.contains(month),
      templateMissing: typeAct == missingTypeAct,
    ));
  }

  return ScheduleWizardData(
    year: targetYear,
    modelName: 'LIFT A388509',
    program: <WizardProgramItem>[
      for (int position = 1; position <= 12; position++)
        WizardProgramItem(
          position: position,
          typeActName: 'ТО ${_program[position - 1]}',
        ),
    ],
    cells: cells,
    previousYearAnchor: withPreviousYear ? anchorMonth : null,
  );
}
