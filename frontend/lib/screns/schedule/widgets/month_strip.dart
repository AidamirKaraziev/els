import 'package:flutter/material.dart';

import '../../../helper/calendar/month_picker.dart' show kMonthsNominative;
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
  }) : super(key: key);

  final List<MonthCell> cells;
  final ValueChanged<MonthCell> onCellTap;

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
          ));
        }

        return Row(
          mainAxisSize: MainAxisSize.min,
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
  }) : super(key: key);

  final MonthCell cell;
  final double width;
  final double height;
  final ValueChanged<MonthCell> onTap;

  /// Подпись выбирается по тому, что реально влезло.
  ///
  /// План требует в клетке вид работы («ТО 1»), макет рисует клетку пустой —
  /// и на ширине макета «ТО 12» кеглем 10 туда не помещается ни при какой
  /// вёрстке. Поэтому не выбираем между планом и кадром, а показываем то,
  /// что влезает: полную подпись на широкой ленте, номер месяца на средней,
  /// ничего — на макетной. Всё остальное всегда есть в тултипе.
  String get _label {
    if (width >= 30) return cell.label;
    if (width >= 16) return cell.shortLabel;
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

    return Tooltip(
      message: _tooltip,
      // Пустой месяц открывать нечего — он и не кликается. `InkWell` поверх
      // него дал бы отклик на нажатие, за которым ничего не происходит.
      child: cell.isTappable
          ? Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onTap(cell),
                borderRadius: BorderRadius.circular(2),
                child: content,
              ),
            )
          : content,
    );
  }
}
