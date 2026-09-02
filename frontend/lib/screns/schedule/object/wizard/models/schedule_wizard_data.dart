import 'package:flutter/material.dart';

import '../../../../../helper/class_colors.dart';

/// Данные мастера расстановки графика — набросок, ещё без сети.
///
/// Формы классов повторяют ответ ручки `GET /planned-to/preview/`
/// (`backend/src/schemas/schedule_plan.py`): `position` — месяц **цикла**
/// программы, `month` — месяц календаря, связывает их якорь. Повторяем
/// нарочно: когда мастер поедет на живые данные, разбор ответа ляжет прямо
/// в эти поля, и переверстывать шаги не придётся.
///
/// Своей логики здесь нет и быть не должно: что во что раскладывается,
/// считает бэкенд, а мастер это показывает.

/// Одна позиция программы обслуживания модели.
class WizardProgramItem {
  const WizardProgramItem({
    required this.position,
    required this.typeActName,
  });

  /// 1..12 — месяц цикла, а не календаря.
  final int position;

  /// «ТО 1», «ТО 6». Пусто у позиции, для которой вид ТО не выбран.
  final String typeActName;
}

/// Чем помечена клетка предпросмотра.
///
/// Три пометки, а не пять статусов ленты графиков: в предпросмотре ещё
/// нечего выполнять, речь только о том, что ляжет в базу. Поэтому и рисуем
/// клетки своим виджетом, а не `MonthStrip` — общий виджет пришлось бы
/// учить двум несовместимым словарям.
enum WizardCellMark {
  /// ТО добавится этим графиком.
  toAdd,

  /// Месяц уже занят актом — расстановка его не тронет.
  occupied,

  /// У модели нет шаблона чек-листа на этот вид ТО. Пока такая клетка есть,
  /// график не утверждается.
  templateMissing,
}

extension WizardCellMarkView on WizardCellMark {
  /// Заливка клетки. Цвета только из палитры проекта.
  ///
  /// Лента намеренно тихая: серое и белое. Громкий цвет на ней ровно один —
  /// янтарный «нет шаблона», и потому его видно. Пока «добавится» было
  /// зелёным, оно занимало почти весь год и глушило и предупреждение, и
  /// пометку старта цикла.
  Color get fill {
    switch (this) {
      case WizardCellMark.toAdd:
        return ColorApp.myColorGrayShadow;
      case WizardCellMark.occupied:
        return ColorApp.myColorWhite;
      case WizardCellMark.templateMissing:
        return ColorApp.myColorYellowLight;
    }
  }

  Color get border {
    switch (this) {
      case WizardCellMark.templateMissing:
        return ColorApp.myColorYellow;
      default:
        return ColorApp.myColorGrayBorder;
    }
  }

  /// Цвет текста внутри клетки. Заливки все светлые, поэтому текст тёмный;
  /// у занятого месяца он приглушён — этот месяц расстановка не тронет, и
  /// читать его наравне с остальными незачем.
  Color get foreground {
    switch (this) {
      case WizardCellMark.occupied:
        return ColorApp.myColorGrayText;
      case WizardCellMark.toAdd:
      case WizardCellMark.templateMissing:
        return ColorApp.myColorBlack;
    }
  }

  /// Словами — для легенды и тултипа.
  String get title {
    switch (this) {
      case WizardCellMark.toAdd:
        return 'добавится';
      case WizardCellMark.occupied:
        return 'уже занято, не тронем';
      case WizardCellMark.templateMissing:
        return 'нет шаблона';
    }
  }
}

/// Один месяц заготовки графика.
class WizardPreviewCell {
  const WizardPreviewCell({
    required this.month,
    required this.position,
    required this.typeActName,
    this.occupied = false,
    this.templateMissing = false,
  });

  /// 1..12, месяц календаря.
  final int month;

  /// 1..12, позиция программы, пришедшаяся на этот месяц.
  final int position;

  final String typeActName;

  final bool occupied;
  final bool templateMissing;

  /// Занятый месяц расстановка не трогает — значит, отсутствие шаблона на
  /// него уже не влияет, и красным он не помечается. Иначе график нельзя
  /// было бы утвердить из-за клетки, которой создание всё равно не касается.
  WizardCellMark get mark {
    if (occupied) return WizardCellMark.occupied;
    if (templateMissing) return WizardCellMark.templateMissing;
    return WizardCellMark.toAdd;
  }
}

/// Всё, чем питается мастер.
class ScheduleWizardData {
  const ScheduleWizardData({
    required this.year,
    required this.modelName,
    required this.program,
    required this.cells,
    this.knownAnchor,
  });

  final int year;

  /// Модель оборудования — чья это программа. Правка программы касается всех
  /// объектов модели, и человек должен видеть, о какой речь.
  final String modelName;

  /// Двенадцать позиций программы, по порядку.
  final List<WizardProgramItem> program;

  /// Двенадцать клеток года, январь..декабрь.
  final List<WizardPreviewCell> cells;

  /// Месяц начала цикла, восстановленный ручкой по уже расставленному году:
  /// сначала по самому запрошенному, потом по прошлому.
  ///
  /// Не `null` — шаг «Точка отсчёта» пропускается: цикл продолжается сам, и
  /// спрашивать человека не о чем. `null` — месяц выбирает он.
  final int? knownAnchor;

  bool get hasKnownAnchor => knownAnchor != null;

  /// Пока есть хоть одна клетка «нет шаблона», утверждать нельзя: по такому
  /// ТО механику нечего показать, и акт не создастся.
  bool get hasMissingTemplate =>
      cells.any((WizardPreviewCell cell) => cell.mark == WizardCellMark.templateMissing);

  /// Ни одной клетки «добавится»: год уже расставлен целиком.
  ///
  /// Утверждать такое нечего — создание вернуло бы двенадцать `skipped` и
  /// закрыло мастер, как будто что-то произошло. Кнопку в этом случае гасим.
  bool get hasNothingToAdd =>
      cells.every((WizardPreviewCell cell) => cell.mark != WizardCellMark.toAdd);
}
