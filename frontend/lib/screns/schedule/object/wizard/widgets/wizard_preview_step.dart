import 'package:flutter/material.dart';

import '../../../../../helper/calendar/month_picker.dart'
    show kMonthsGenitive, kMonthsNominative, kMonthsShort;
import '../../../../../helper/class_colors.dart';
import '../../widgets/object_block.dart';
import '../models/schedule_wizard_data.dart';

/// Шаг 3 — «Предпросмотр»: двенадцать клеток года с пометками.
///
/// Ровно то, ради чего мастер и нужен: до записи в базу видно, что добавится,
/// что останется нетронутым и где не хватает шаблона. Клетки рисуются здесь,
/// а не общим `MonthStrip`: у ленты графиков пять статусов выполнения, у
/// заготовки — три пометки другого смысла, и один виджет на оба словаря
/// пришлось бы читать со справочником.
class WizardPreviewStep extends StatelessWidget {
  const WizardPreviewStep({
    Key? key,
    required this.data,
    required this.anchorMonth,
    this.onCreateTemplate,
  }) : super(key: key);

  final ScheduleWizardData data;

  /// Месяц начала цикла — тот, что применён: с прошлого года или выбранный
  /// на шаге 2.
  final int anchorMonth;

  /// Переход в создание шаблона чек-листа. Пока не подключён: экрана
  /// шаблонов у нас ещё нет, и кнопка появится вместе с ним.
  final VoidCallback? onCreateTemplate;

  @override
  Widget build(BuildContext context) {
    return ObjectBlock(
      title: 'Что ляжет в ${data.year} год',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16.0),
        decoration: objectCardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Цикл начинается с ${kMonthsGenitive[anchorMonth - 1]}.',
              style: const TextStyle(fontSize: 13.0, color: ColorApp.myColorGray),
            ),
            const SizedBox(height: 16.0),
            _Cells(cells: data.cells),
            const SizedBox(height: 16.0),
            const _Legend(),
            if (data.hasMissingTemplate) ...<Widget>[
              const SizedBox(height: 16.0),
              _MissingTemplateNote(
                names: _missingNames(data.cells),
                onCreateTemplate: onCreateTemplate,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Виды ТО без шаблона — по одному разу, а не по разу на клетку: один ТО 6
  /// в году встречается дважды, и повторять его в тексте незачем.
  static List<String> _missingNames(List<WizardPreviewCell> cells) {
    final List<String> names = <String>[];
    for (final WizardPreviewCell cell in cells) {
      if (cell.mark != WizardCellMark.templateMissing) continue;
      if (names.contains(cell.typeActName)) continue;
      names.add(cell.typeActName);
    }
    return names;
  }
}

/// Двенадцать клеток года: месяц сверху, вид ТО внутри.
///
/// В отличие от ленты на экране объекта клетки крупные: здесь их читают, а не
/// сравнивают взглядом между объектами, и вид работы должен быть виден без
/// тултипа.
class _Cells extends StatelessWidget {
  const _Cells({Key? key, required this.cells}) : super(key: key);

  final List<WizardPreviewCell> cells;

  /// Ширина клетки, при которой «ТО 12» помещается кеглем 12.
  static const double _minCellWidth = 84.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        const double gap = 8.0;
        // Сколько клеток влезает в строку: 12, 6, 4, 3 или 2. Дробное число
        // колонок дало бы последнюю строку с одной клеткой на всю ширину.
        final double available = constraints.maxWidth;
        int columns = ((available + gap) / (_minCellWidth + gap)).floor();
        if (columns > 12) columns = 12;
        if (columns < 2) columns = 2;
        // Ровные ряды: 12 делится на 2, 3, 4, 6 и 12.
        while (columns > 2 && 12 % columns != 0) {
          columns--;
        }
        final double width = (available - gap * (columns - 1)) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: <Widget>[
            for (final WizardPreviewCell cell in cells)
              SizedBox(width: width, child: _Cell(cell: cell)),
          ],
        );
      },
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({Key? key, required this.cell}) : super(key: key);

  final WizardPreviewCell cell;

  @override
  Widget build(BuildContext context) {
    final WizardCellMark mark = cell.mark;
    return Tooltip(
      message: '${kMonthsNominative[cell.month - 1]} · ${cell.typeActName} · '
          '${mark.title}',
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 8.0),
        decoration: BoxDecoration(
          color: mark.fill,
          border: Border.all(color: mark.border),
          borderRadius: BorderRadius.circular(6.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              kMonthsShort[cell.month - 1],
              style: TextStyle(
                fontSize: 10.0,
                color: mark.foreground,
              ),
            ),
            const SizedBox(height: 4.0),
            Text(
              cell.typeActName,
              style: TextStyle(
                fontSize: 13.0,
                fontWeight: FontWeight.w600,
                color: mark.foreground,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// Что означают цвета. Без легенды пометки читаются только по тултипу, а его
/// на телефоне нет вовсе.
class _Legend extends StatelessWidget {
  const _Legend({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16.0,
      runSpacing: 8.0,
      children: <Widget>[
        for (final WizardCellMark mark in WizardCellMark.values)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 12.0,
                height: 12.0,
                decoration: BoxDecoration(
                  color: mark.fill,
                  border: Border.all(color: mark.border),
                  borderRadius: BorderRadius.circular(3.0),
                ),
              ),
              const SizedBox(width: 6.0),
              Text(
                mark.title,
                style: const TextStyle(
                  fontSize: 12.0,
                  color: ColorApp.myColorGray,
                ),
              ),
            ],
          ),
      ],
    );
  }
}

/// Почему «Утвердить» не нажимается и что с этим делать.
class _MissingTemplateNote extends StatelessWidget {
  const _MissingTemplateNote({
    Key? key,
    required this.names,
    this.onCreateTemplate,
  }) : super(key: key);

  final List<String> names;
  final VoidCallback? onCreateTemplate;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: ColorApp.myColorGrayShadow,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: ColorApp.myColorRed),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'У модели нет шаблона чек-листа: ${names.join(', ')}. По такому '
            'ТО механику нечего показать, поэтому график не утверждается.',
            style: const TextStyle(fontSize: 13.0, color: ColorApp.myColorBlack),
          ),
          const SizedBox(height: 8.0),
          TextButton(
            // Экрана шаблонов ещё нет — кнопка выключена, а не ведёт в
            // пустоту. Появится он, появится и переход.
            onPressed: onCreateTemplate,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              foregroundColor: ColorApp.myColorGreenAuth,
              minimumSize: const Size(0, 0),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Создать шаблон'),
          ),
        ],
      ),
    );
  }
}
