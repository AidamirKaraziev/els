import 'package:flutter/material.dart';

import '../../../helper/calendar/month_picker.dart'
    show kMonthsNominative, kMonthsShort;
import '../../../helper/class_colors.dart';
import '../models/month_cell.dart';

/// Годовая лента: двенадцать клеток месяцев в ряд.
///
/// Клетки **сжимаются под доступную ширину**, а не уезжают в горизонтальный
/// скролл. Лента внутри строки списка — не отдельный экран: если она едет вбок
/// сама по себе, человек листает её у каждого объекта по отдельности и теряет
/// то единственное, ради чего лента и нужна, — сравнение объектов глазами по
/// вертикали.
class MonthStrip extends StatelessWidget {
  const MonthStrip({
    Key? key,
    required this.cells,
    required this.onCellTap,
    this.showMonthLabels = false,
    this.onCellMoved,
  }) : super(key: key);

  final List<MonthCell> cells;
  final ValueChanged<MonthCell> onCellTap;

  /// Перенести ТО на другой месяц: `(что тащили, куда положили)`.
  ///
  /// Не задан — лента не перетаскивается вовсе, и раздел «Графики» остаётся
  /// таким, каким был: там строк много, и случайное перетаскивание в чужой
  /// строке — худшее, что может случиться с плановым графиком.
  ///
  /// Тащить можно только **незакрытое** ТО: назначенное и просроченное.
  /// Выполненную работу перенести нельзя — она сделана в свой месяц, и
  /// подпись под ней перестала бы соответствовать акту. Класть можно только
  /// на **пустой** месяц: на занятый значило бы затереть чужой акт молча.
  final void Function(MonthCell cell, int toMonth)? onCellMoved;

  /// Можно ли утащить эту клетку.
  static bool canDrag(MonthCell cell) =>
      cell.actId != null &&
      (cell.status == MonthStatus.pending || cell.status == MonthStatus.overdue);

  /// Можно ли положить сюда.
  static bool canDrop(MonthCell cell) => cell.status == MonthStatus.none;

  /// Подписывать ли месяцы под клетками.
  ///
  /// В ленте объектов — нет: там двенадцать одинаковых колонок у всех строк
  /// сразу, и подпись, повторённая у каждого объекта, только шумит. На экране
  /// одного объекта лента единственная, и без подписи месяц приходится
  /// пересчитывать пальцем. По умолчанию выключено — раздел «Графики»
  /// остаётся таким, каким был.
  final bool showMonthLabels;

  /// Зазор между клетками — как в макете (кадр `83:312`: шаг 18 при клетке 15).
  static const double _gap = 3;

  /// Клетка макета. Уже её не жмём: 12 квадратов по 15 плюс зазоры дают ровно
  /// 213 px — ширину ленты в кадре.
  static const double _minCell = 15;

  /// Шире смысла нет: клетка перестаёт читаться как клетка и превращается в
  /// кнопку.
  static const double _maxCell = 44;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double gaps = _gap * (cells.length - 1);
        final double available = constraints.maxWidth - gaps;

        // Ширина может прийти бесконечной, если ленту положат в неограниченный
        // `Row`. `clamp` это переживает: получится максимальная клетка.
        //
        // Снизу не подпираем: клетка мельче макетной читается плохо, но
        // обрезанная лента врёт — показывает десять месяцев из двенадцати и
        // молчит об этом. Уж лучше мелко, чем неправда.
        final double raw = available / cells.length;
        final double width = raw.isFinite ? raw.clamp(1, _maxCell).toDouble() : _maxCell;

        // На узкой клетке высота равна ширине — это квадрат макета. На широкой
        // высота упирается в 22: пилюля, а не плитка.
        final double height = width < _minCell ? width : width.clamp(_minCell, 22).toDouble();

        final List<Widget> children = <Widget>[];
        for (int i = 0; i < cells.length; i++) {
          if (i > 0) children.add(const SizedBox(width: _gap));
          children.add(_MonthPill(
            cell: cells[i],
            width: width,
            height: height,
            onTap: onCellTap,
            onMoved: onCellMoved,
            // Подпись «Янв» кеглем 9 требует места: на макетной клетке в
            // 15 px она превратилась бы в обрезок буквы. Клетка при этом не
            // растягивается — лучше лента без подписей, чем лента, которая
            // из-за подписей поехала.
            monthLabel: showMonthLabels && width >= 24
                ? kMonthsShort[cells[i].month - 1]
                : null,
          ));
        }

        return Row(
          mainAxisSize: MainAxisSize.min,
          // Клетки равняются по верху: с подписями месяцев столбики разной
          // высоты, и по центру лента поехала бы вверх-вниз.
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        );
      },
    );
  }
}

class _MonthPill extends StatelessWidget {
  const _MonthPill({
    Key? key,
    required this.cell,
    required this.width,
    required this.height,
    required this.onTap,
    this.monthLabel,
    this.onMoved,
  }) : super(key: key);

  final MonthCell cell;
  final double width;
  final double height;
  final ValueChanged<MonthCell> onTap;

  /// Перенос ТО на другой месяц. `null` — лента неподвижна.
  final void Function(MonthCell cell, int toMonth)? onMoved;

  /// «Янв» под клеткой. `null` — подписи нет.
  final String? monthLabel;

  /// Подпись выбирается по тому, что реально влезло.
  ///
  /// План требует в клетке вид работы («ТО 1»), макет рисует клетку пустой —
  /// и на ширине макета «ТО 12» кеглем 10 туда не помещается ни при какой
  /// вёрстке. Поэтому не выбираем между планом и кадром, а показываем то,
  /// что влезает: полную подпись на широкой ленте, номер месяца на средней,
  /// ничего — на макетной. Всё остальное всегда есть в тултипе.
  String get _label {
    if (width >= 30) return cell.label;
    // Номер месяца в клетке нужен, только пока месяц не подписан снизу: с
    // подписью «Янв» цифра 1 над ней — то же самое, сказанное дважды.
    if (width >= 16 && monthLabel == null) return cell.shortLabel;
    return '';
  }

  /// «Март · ТО 1 · выполнено». Месяц обязателен: без него на ленте без
  /// подписей нельзя понять, о каком месяце речь.
  String get _tooltip {
    final String month = kMonthsNominative[cell.month - 1];
    final String kind = cell.label;
    return <String>[
      month,
      if (kind.isNotEmpty) kind,
      cell.status.title,
    ].join(' · ');
  }

  /// Обернуть клетку в перетаскивание, если лента это позволяет.
  ///
  /// Клетка бывает и источником, и целью — но никогда одновременно: тащат
  /// занятую, кладут в пустую.
  ///
  /// [interactive] — клетка со своим нажатием, [plain] — она же без него: в
  /// «летящей» копии и в следе на месте источника нажатие лишнее.
  Widget _movable(Widget interactive, Widget plain) {
    final void Function(MonthCell cell, int toMonth)? moved = onMoved;
    if (moved == null) return interactive;

    if (MonthStrip.canDrag(cell)) {
      return MouseRegion(
        // Курсор-рука: иначе по клетке не видно, что её можно взять, и
        // человек либо не пробует вовсе, либо тянет ту, которая не двигается.
        cursor: SystemMouseCursors.grab,
        child: Draggable<MonthCell>(
          data: cell,
          // Лента лежит в вертикальной прокрутке экрана. Без этого мышиный
          // жест достаётся прокрутке — клетка «не берётся» вовсе. Горизонталь
          // отдаём переносу, вертикаль оставляем прокрутке: лента узкая, и
          // тащить месяц вверх-вниз всё равно некуда.
          affinity: Axis.horizontal,
          // Курсор держит клетку за середину: иначе она уезжает из-под пальца
          // и целиться в соседний месяц приходится на глаз.
          dragAnchorStrategy: pointerDragAnchorStrategy,
          feedback: Transform.translate(
            offset: Offset(-width / 2, -height / 2),
            child: Material(
              color: Colors.transparent,
              elevation: 6.0,
              child: Opacity(opacity: 0.9, child: plain),
            ),
          ),
          // На месте, откуда тащат, остаётся контур: так видно, что месяц
          // освободится, и куда вернуть, если передумали.
          childWhenDragging: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              border: Border.all(color: ColorApp.myColorGrayBorder, width: 1),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          child: interactive,
        ),
      );
    }

    if (!MonthStrip.canDrop(cell)) return interactive;

    return DragTarget<MonthCell>(
      // Сам себе не цель: месяц, из которого тащат, занят — но проверить
      // стоит и здесь, чтобы «перенос» на то же место не слал запрос.
      onWillAcceptWithDetails: (DragTargetDetails<MonthCell> details) =>
          details.data.month != cell.month,
      onAcceptWithDetails: (DragTargetDetails<MonthCell> details) =>
          moved(details.data, cell.month),
      builder:
          (BuildContext context, List<MonthCell?> candidates, List<dynamic> rejected) {
            if (candidates.isEmpty) return interactive;
            // Под курсором цель зеленеет: пустая клетка иначе почти не отличима
            // от соседних, и попадание не подтверждается ничем.
            return Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                color: ColorApp.myColorGreen.withValues(alpha: 0.35),
                border: Border.all(color: ColorApp.myColorGreen, width: 1),
                borderRadius: BorderRadius.circular(2),
              ),
            );
          },
    );
  }

  @override
  Widget build(BuildContext context) {
    final String label = _label;

    final Widget content = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: cell.status.fill,
        border: Border.all(color: cell.status.border, width: 1),
        borderRadius: BorderRadius.circular(2),
      ),
      alignment: Alignment.center,
      child: label.isEmpty
          ? null
          : Text(
              label,
              style: TextStyle(
                color: cell.status.foreground,
                fontSize: width >= 30 ? 10 : 9,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              textAlign: TextAlign.center,
            ),
    );

    final Widget pill = Tooltip(
      message: _tooltip,
      // Пустой месяц открывать нечего — он и не кликается. `InkWell` поверх
      // него дал бы отклик на нажатие, за которым ничего не происходит.
      child: _movable(
        cell.isTappable
            ? Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => onTap(cell),
                  borderRadius: BorderRadius.circular(2),
                  child: content,
                ),
              )
            : content,
        content,
      ),
    );

    final String? month = monthLabel;
    if (month == null) {
      return pill;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        pill,
        const SizedBox(height: 4),
        SizedBox(
          width: width,
          child: Text(
            month,
            style: const TextStyle(fontSize: 9, color: ColorApp.myColorGrayText),
            maxLines: 1,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}
