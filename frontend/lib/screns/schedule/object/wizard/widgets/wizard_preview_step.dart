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
            ] else if (data.hasNothingToAdd) ...<Widget>[
              const SizedBox(height: 16.0),
              const _NothingToAddNote(),
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

  /// Первая позиция программы — та, с которой разворачиваются все двенадцать
  /// ТО. Считаем по [WizardPreviewCell.position], а не по совпадению с
  /// месяцем-якорем: позиция и есть смысл «первое ТО цикла», и она уже
  /// посчитана сервером.
  bool get _isAnchor => cell.position == 1;

  /// Старт на клетке без шаблона не закрашивается тёмным.
  ///
  /// Иначе один акцент съел бы другой: предупреждение важнее, из-за него
  /// график не утверждается. Заливка остаётся янтарной, а старт помечается
  /// тёмной рамкой и тем же тегом — видны оба сигнала.
  bool get _isDark =>
      _isAnchor && cell.mark != WizardCellMark.templateMissing;

  @override
  Widget build(BuildContext context) {
    final WizardCellMark mark = cell.mark;
    final Color foreground =
        _isDark ? ColorApp.myColorWhite : mark.foreground;
    final Color monthColor =
        _isDark ? ColorApp.myColorGrayText : mark.foreground;

    return Tooltip(
      message: '${kMonthsNominative[cell.month - 1]} · ${cell.typeActName} · '
          '${mark.title}${_isAnchor ? ' · старт цикла' : ''}',
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 8.0),
        decoration: BoxDecoration(
          color: _isDark ? ColorApp.myColorBlack : mark.fill,
          border: Border.all(
            color: _isAnchor ? ColorApp.myColorBlack : mark.border,
            width: _isAnchor && !_isDark ? 2.0 : 1.0,
          ),
          borderRadius: BorderRadius.circular(6.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Место под тег держат все клетки, а не только клетка старта:
            // иначе она одна становится выше соседей и ряд идёт волной.
            SizedBox(
              height: _AnchorTag.height,
              child: _isAnchor ? const _AnchorTag() : null,
            ),
            const SizedBox(height: 4.0),
            Text(
              kMonthsShort[cell.month - 1],
              style: TextStyle(
                fontSize: 10.0,
                color: monthColor,
              ),
            ),
            const SizedBox(height: 4.0),
            Text(
              cell.typeActName,
              style: TextStyle(
                fontSize: 13.0,
                fontWeight: FontWeight.w600,
                color: foreground,
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

/// Тег «СТАРТ» над месяцем. Словом, а не одним цветом: тёмная клетка сама по
/// себе читается как «ещё один статус», и без подписи её пришлось бы угадывать.
class _AnchorTag extends StatelessWidget {
  const _AnchorTag({Key? key}) : super(key: key);

  /// Высота, которую тег занимает в клетке. Ею же резервируется место в
  /// клетках без тега — см. `_Cell`.
  static const double height = 14.0;

  @override
  Widget build(BuildContext context) {
    // Row с `min` — чтобы бейдж был по ширине надписи, а не во всю клетку:
    // родитель даёт свободную ширину, и Container без этого растянулся бы.
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          decoration: BoxDecoration(
            color: ColorApp.myColorGreenAuth,
            borderRadius: BorderRadius.circular(3.0),
          ),
          child: const Text(
            'СТАРТ',
            style: TextStyle(
              fontSize: 9.0,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
              color: ColorApp.myColorWhite,
            ),
          ),
        ),
      ],
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
          _LegendItem(
            fill: mark.fill,
            border: mark.border,
            title: mark.title,
          ),
        // Старт цикла — не пометка клетки, а отдельная ось: он приходится на
        // любую из трёх. Но в легенде он обязан быть, иначе тёмная клетка
        // читается как четвёртый статус.
        const _LegendItem(
          fill: ColorApp.myColorBlack,
          border: ColorApp.myColorBlack,
          title: 'старт цикла',
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    Key? key,
    required this.fill,
    required this.border,
    required this.title,
  }) : super(key: key);

  final Color fill;
  final Color border;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 12.0,
          height: 12.0,
          decoration: BoxDecoration(
            color: fill,
            border: Border.all(color: border),
            borderRadius: BorderRadius.circular(3.0),
          ),
        ),
        const SizedBox(width: 6.0),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12.0,
            color: ColorApp.myColorGray,
          ),
        ),
      ],
    );
  }
}

/// Год уже расставлен целиком: утверждать нечего.
///
/// Плашка тихая, серая: это не ошибка и не предупреждение, а сообщение о том,
/// что работа уже сделана — скорее всего, в прошлый заход в этот же мастер.
class _NothingToAddNote extends StatelessWidget {
  const _NothingToAddNote({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: ColorApp.myColorGrayShadow,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: ColorApp.myColorGrayBorder),
      ),
      child: const Text(
        'Все месяцы этого года уже расставлены. Занятые месяцы расстановка '
        'не трогает, поэтому добавлять нечего.',
        style: TextStyle(fontSize: 13.0, color: ColorApp.myColorBlack),
      ),
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
        color: ColorApp.myColorYellowLight,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: ColorApp.myColorYellow),
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
