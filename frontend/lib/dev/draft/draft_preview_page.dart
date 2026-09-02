import 'package:flutter/material.dart';

import '../../helper/calendar/month_picker.dart'
    show kMonthsGenitive, kMonthsNominative, kMonthsShort;
import '../../helper/class_colors.dart';
import '../../screns/schedule/object/widgets/object_block.dart';
import '../../screns/schedule/object/wizard/models/schedule_wizard_data.dart';
import '../../screns/schedule/object/wizard/widgets/wizard_steps_header.dart';
import 'draft_program_data.dart';
import 'draft_program_dialog.dart';

/// Набросок нового шага «Предпросмотр».
///
/// Отличий от боевого три, и ради них набросок и делается:
///
/// * шагов два, а не три — витрина «Программа модели» уходит;
/// * программа показана строкой над лентой, и оттуда же правится окном;
/// * клетки года таскаются между месяцами до «Утвердить».
///
/// Клетки, легенда и тег «СТАРТ» повторены здесь, а не взяты из боевого
/// `wizard_preview_step.dart`: там они приватные, а трогать боевой файл в
/// этой сессии нельзя. Когда набросок примут, переедет он целиком, и
/// дубль исчезнет вместе с ним.
class DraftPreviewPage extends StatefulWidget {
  const DraftPreviewPage({
    Key? key,
    required this.fixture,
    this.year = 2028,
    this.objectName = 'Объект 25',
    this.anchorMonth = 3,
  }) : super(key: key);

  final DraftFixture fixture;
  final int year;
  final String objectName;

  /// Месяц начала цикла — тот, что пришёл с шага «Точка отсчёта».
  final int anchorMonth;

  @override
  State<DraftPreviewPage> createState() => _DraftPreviewPageState();
}

class _DraftPreviewPageState extends State<DraftPreviewPage> {
  late DraftProgram? _program = buildDraftProgram(widget.fixture);
  late List<String> _typeActs = List<String>.of(kDraftTypeActs);

  /// Месяц первой позиции цикла. Меняется перетаскиванием клетки: год
  /// раскладывается от него, поэтому отдельно хранить сами клетки не нужно.
  late int _anchorMonth = widget.anchorMonth;

  late List<WizardPreviewCell> _cells = _buildCells();

  List<WizardPreviewCell> _buildCells() {
    final DraftProgram? program = _program;
    if (program == null) return const <WizardPreviewCell>[];
    return buildDraftCells(program: program, anchorMonth: _anchorMonth);
  }

  /// Перенос ТО на другой месяц — вместе со всей цепочкой года.
  ///
  /// Цикл — не двенадцать независимых клеток, а порядок: ТО 1, ТО 1, ТО 3 и
  /// так далее. Поменяй две клетки местами — и после ТО 6 идёт то, чего в
  /// программе за ним не идёт. Поэтому перетаскивание сдвигает цепочку
  /// целиком: клетка встаёт на выбранный месяц, а остальные подтягиваются за
  /// ней по кругу, не теряя хронологии. По сути это и есть выбор месяца
  /// начала цикла, только руками и по любой клетке, а не только по стартовой.
  void _moveChain(int fromMonth, int toMonth) {
    if (fromMonth == toMonth) return;
    final int position = _cells[fromMonth - 1].position;

    setState(() {
      // Месяц позиции 1 при том, что позиция `position` встала на `toMonth`.
      _anchorMonth = (toMonth - position + 12) % 12 + 1;
      _cells = _buildCells();
    });
  }

  Future<void> _editProgram() async {
    final DraftProgram? saved = await showDraftProgramDialog(
      context,
      program: _program,
      modelName: _program?.modelName ?? kDraftModelName,
      typeActs: _typeActs,
      onTypeActAdded: (String name) {
        if (!_typeActs.contains(name)) _typeActs = <String>[..._typeActs, name];
      },
    );
    if (saved == null) return;
    setState(() {
      _program = saved;
      // Программа сменилась — год раскладывается заново от того же месяца
      // начала цикла: его человек выбирал отдельно, и терять его незачем.
      _cells = _buildCells();
    });
  }

  bool get _hasMissingTemplate => _cells.any(
      (WizardPreviewCell cell) => cell.mark == WizardCellMark.templateMissing);

  bool get _canApprove => _program != null && !_hasMissingTemplate;

  String? get _disabledReason {
    if (_program == null) {
      return 'Сначала создайте программу модели — по ней раскладывается год';
    }
    if (_hasMissingTemplate) {
      return 'Сначала выберите вид ТО на отмеченных позициях программы';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorApp.myColorTransparent,
      appBar: AppBar(
        backgroundColor: ColorApp.myColorWhite,
        elevation: 0.0,
        foregroundColor: ColorApp.myColorBlack,
        title: Text(
          'График на ${widget.year}',
          style: const TextStyle(
            fontSize: 22.0,
            fontWeight: FontWeight.w700,
            color: ColorApp.myColorBlack,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(24.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 16.0, bottom: 8.0),
              child: Text(
                widget.objectName,
                style: const TextStyle(
                  fontSize: 13.0,
                  color: ColorApp.myColorGray,
                ),
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(ColorApp.kPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const WizardStepsHeader(
                    titles: <String>['Точка отсчёта', 'Предпросмотр'],
                    current: 1,
                  ),
                  const SizedBox(height: 24.0),
                  _ProgramRow(program: _program, onEdit: _editProgram),
                  const SizedBox(height: 20.0),
                  ObjectBlock(
                    title: 'Что ляжет в ${widget.year} год',
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16.0),
                      decoration: objectCardDecoration(),
                      child: _program == null
                          ? const _NoProgramNote()
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  'Цикл начинается с '
                                  '${kMonthsGenitive[_anchorMonth - 1]}. '
                                  'Перетащите любое ТО на другой месяц — '
                                  'цепочка сдвинется за ним целиком, порядок '
                                  'видов ТО не изменится.',
                                  style: const TextStyle(
                                    fontSize: 13.0,
                                    color: ColorApp.myColorGray,
                                  ),
                                ),
                                const SizedBox(height: 16.0),
                                _Cells(cells: _cells, onMoved: _moveChain),
                                const SizedBox(height: 16.0),
                                const _Legend(),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          _Bottom(
            canApprove: _canApprove,
            disabledReason: _disabledReason,
            onBack: () => Navigator.of(context).pop(),
            onApprove: () {},
          ),
        ],
      ),
    );
  }
}

/// Строка программы над лентой — то, что заменило собой целый шаг мастера.
///
/// Двумя состояниями: программа есть — название и «Изменить программу»;
/// программы нет — красный текст и «Создать программу». Второе состояние
/// важнее первого: без программы год не раскладывается вовсе, и раньше
/// человек упирался в пустой предпросмотр без единой подсказки, что делать.
class _ProgramRow extends StatelessWidget {
  const _ProgramRow({Key? key, required this.program, required this.onEdit})
      : super(key: key);

  final DraftProgram? program;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final DraftProgram? item = program;
    final bool missing = item == null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      decoration: objectCardDecoration(),
      child: Row(
        children: <Widget>[
          Icon(
            missing ? Icons.error_outline : Icons.list_alt,
            size: 20.0,
            color: missing ? ColorApp.myColorRed : ColorApp.myColorGray,
          ),
          const SizedBox(width: 12.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Программа модели',
                  style: TextStyle(
                    fontSize: 12.0,
                    color: ColorApp.myColorGrayText,
                  ),
                ),
                const SizedBox(height: 2.0),
                Text(
                  missing
                      ? 'не заведена — год расставить нельзя'
                      : (item.name.isEmpty ? 'без названия' : item.name),
                  style: TextStyle(
                    fontSize: 15.0,
                    fontWeight: FontWeight.w600,
                    color: missing
                        ? ColorApp.myColorRed
                        : ColorApp.myColorBlack,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12.0),
          TextButton(
            onPressed: onEdit,
            style: TextButton.styleFrom(
              foregroundColor: ColorApp.myColorGreenAuth,
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 10.0,
              ),
            ),
            child: Text(missing ? 'Создать программу' : 'Изменить программу'),
          ),
        ],
      ),
    );
  }
}

/// Год без программы: показывать нечего, и объяснить это надо словами.
class _NoProgramNote extends StatelessWidget {
  const _NoProgramNote({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Год раскладывается по программе модели, а её у этой модели нет. '
      'Заведите программу — и здесь появятся двенадцать месяцев с видами ТО.',
      style: TextStyle(fontSize: 13.0, color: ColorApp.myColorGray),
    );
  }
}

/// Двенадцать клеток года, каждая — источник и цель перетаскивания.
class _Cells extends StatelessWidget {
  const _Cells({Key? key, required this.cells, required this.onMoved})
      : super(key: key);

  final List<WizardPreviewCell> cells;

  /// Месяц-источник и месяц-цель.
  final void Function(int, int) onMoved;

  static const double _minCellWidth = 84.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        const double gap = 8.0;
        final double available = constraints.maxWidth;
        int columns = ((available + gap) / (_minCellWidth + gap)).floor();
        if (columns > 12) columns = 12;
        if (columns < 2) columns = 2;
        while (columns > 2 && 12 % columns != 0) {
          columns--;
        }
        final double width = (available - gap * (columns - 1)) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: <Widget>[
            for (final WizardPreviewCell cell in cells)
              SizedBox(
                width: width,
                child: _DraggableCell(cell: cell, onMoved: onMoved),
              ),
          ],
        );
      },
    );
  }
}

/// Клетка, которую можно утащить, и она же — цель для чужой.
///
/// `affinity: Axis.horizontal` — иначе на вертикальной прокрутке страницы
/// каждое движение пальцем по ленте начинало бы перетаскивание вместо
/// прокрутки.
class _DraggableCell extends StatelessWidget {
  const _DraggableCell({Key? key, required this.cell, required this.onMoved})
      : super(key: key);

  final WizardPreviewCell cell;
  final void Function(int, int) onMoved;

  @override
  Widget build(BuildContext context) {
    // Занятый месяц не двигается и не принимает: расстановка его не трогает,
    // и подменять чужой акт перетаскиванием нельзя.
    if (cell.occupied) return _Cell(cell: cell);

    return DragTarget<int>(
      onWillAcceptWithDetails: (DragTargetDetails<int> details) =>
          details.data != cell.month,
      onAcceptWithDetails: (DragTargetDetails<int> details) =>
          onMoved(details.data, cell.month),
      builder: (
        BuildContext context,
        List<int?> candidates,
        List<dynamic> rejected,
      ) {
        final bool hovered = candidates.isNotEmpty;
        return Draggable<int>(
          data: cell.month,
          affinity: Axis.horizontal,
          feedback: Material(
            color: ColorApp.myColorTransparent,
            child: Opacity(
              opacity: 0.9,
              child: SizedBox(width: 96.0, child: _Cell(cell: cell)),
            ),
          ),
          childWhenDragging: Opacity(opacity: 0.3, child: _Cell(cell: cell)),
          child: MouseRegion(
            cursor: SystemMouseCursors.grab,
            child: _Cell(cell: cell, hovered: hovered),
          ),
        );
      },
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({Key? key, required this.cell, this.hovered = false})
      : super(key: key);

  final WizardPreviewCell cell;

  /// Над клеткой висит чужая: подсвечиваем зелёной рамкой, иначе непонятно,
  /// куда именно ляжет ТО.
  final bool hovered;

  bool get _isAnchor => cell.position == 1;

  bool get _isDark => _isAnchor && cell.mark != WizardCellMark.templateMissing;

  @override
  Widget build(BuildContext context) {
    final WizardCellMark mark = cell.mark;
    final Color foreground = _isDark ? ColorApp.myColorWhite : mark.foreground;
    final Color monthColor = _isDark ? ColorApp.myColorGrayText : mark.foreground;

    return Tooltip(
      message: '${kMonthsNominative[cell.month - 1]} · ${cell.typeActName} · '
          '${mark.title}${_isAnchor ? ' · старт цикла' : ''}',
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 8.0),
        decoration: BoxDecoration(
          color: _isDark ? ColorApp.myColorBlack : mark.fill,
          border: Border.all(
            color: hovered
                ? ColorApp.myColorGreenAuth
                : (_isAnchor ? ColorApp.myColorBlack : mark.border),
            width: hovered || (_isAnchor && !_isDark) ? 2.0 : 1.0,
          ),
          borderRadius: BorderRadius.circular(6.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(
              height: _AnchorTag.height,
              child: _isAnchor ? const _AnchorTag() : null,
            ),
            const SizedBox(height: 4.0),
            Text(
              kMonthsShort[cell.month - 1],
              style: TextStyle(fontSize: 10.0, color: monthColor),
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

class _AnchorTag extends StatelessWidget {
  const _AnchorTag({Key? key}) : super(key: key);

  static const double height = 14.0;

  @override
  Widget build(BuildContext context) {
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

class _Legend extends StatelessWidget {
  const _Legend({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16.0,
      runSpacing: 8.0,
      children: <Widget>[
        for (final WizardCellMark mark in WizardCellMark.values)
          _LegendItem(fill: mark.fill, border: mark.border, title: mark.title),
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
          style: const TextStyle(fontSize: 12.0, color: ColorApp.myColorGray),
        ),
      ],
    );
  }
}

class _Bottom extends StatelessWidget {
  const _Bottom({
    Key? key,
    required this.canApprove,
    this.disabledReason,
    required this.onBack,
    required this.onApprove,
  }) : super(key: key);

  final bool canApprove;
  final String? disabledReason;
  final VoidCallback onBack;
  final VoidCallback onApprove;

  @override
  Widget build(BuildContext context) {
    Widget primary = ElevatedButton(
      onPressed: canApprove ? onApprove : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: ColorApp.myColorGreenAuth,
        foregroundColor: ColorApp.myColorWhite,
        elevation: 0.0,
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 14.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
      child: const Text('Утвердить'),
    );
    if (!canApprove && disabledReason != null) {
      primary = Tooltip(message: disabledReason!, child: primary);
    }

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: const BoxDecoration(
        color: ColorApp.myColorWhite,
        border: Border(top: BorderSide(color: ColorApp.myColorGrayBorder)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: <Widget>[
            TextButton(
              onPressed: onBack,
              style: TextButton.styleFrom(
                foregroundColor: ColorApp.myColorGray,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 14.0,
                ),
              ),
              child: const Text('Назад'),
            ),
            const Spacer(),
            primary,
          ],
        ),
      ),
    );
  }
}
