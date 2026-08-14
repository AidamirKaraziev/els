import 'package:flutter/material.dart';

import '../../../helper/class_colors.dart';
import '../models/works_report.dart';

/// Ячейка месяца: полоска статуса ТО, под ней точки по числу работ.
///
/// Вариант, выбранный заказчиком: «чтобы сразу, бросив один взгляд, было
/// видно, что в месяц не только сделали плановое ТО, но и ещё доп. работы».
///
/// Полоска всегда на одной высоте, поэтому строка читается как лента графика,
/// а строки таблицы не разъезжаются. Вариант со стопкой сегментов, где высота
/// показывает объём, отклонён именно из-за этого.
///
/// Цвета — из макета, кадр «Окно с графиками»: зелёный, жёлтый, красный.
class MonthCellTile extends StatelessWidget {
  const MonthCellTile({
    Key? key,
    required this.cell,
    required this.onTap,
  }) : super(key: key);

  final MonthCell cell;
  final VoidCallback? onTap;

  /// Больше четырёх точек в ряд не помещается, а считать их глазами всё равно
  /// никто не станет: дальше показываем «+N».
  static const int _maxDots = 4;

  @override
  Widget build(BuildContext context) {
    final List<Widget> dots = <Widget>[];
    void addDots(int count, Color color) {
      for (int i = 0; i < count && dots.length < _maxDots; i++) {
        dots.add(_Dot(color: color));
      }
    }

    // Порядок важен: авария заметнее прочего, поэтому идёт первой и точно
    // попадёт в видимые четыре.
    addDots(cell.counts.breakdowns, ColorApp.myColorRed);
    addDots(cell.counts.clientRequests, ColorApp.myColorBlue);
    addDots(cell.counts.otherRequests, ColorApp.myColorGray);
    addDots(cell.counts.defects, ColorApp.myColorYellow);

    final int hidden = cell.counts.total - dots.length;

    return Tooltip(
      message: _tooltip(),
      waitDuration: const Duration(milliseconds: 400),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4.0),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2.0, vertical: 4.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                height: 8.0,
                decoration: BoxDecoration(
                  color: maintenanceColor(cell.maintenance),
                  borderRadius: BorderRadius.circular(2.0),
                  border: cell.maintenance == MaintenanceStatus.none
                      ? Border.all(color: ColorApp.myColorGrayBorder)
                      : null,
                ),
              ),
              const SizedBox(height: 3.0),
              SizedBox(
                height: 12.0,
                child: dots.isEmpty
                    ? const SizedBox.shrink()
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          ...dots,
                          if (hidden > 0)
                            Padding(
                              padding: const EdgeInsets.only(left: 2.0),
                              child: Text(
                                '+$hidden',
                                style: const TextStyle(
                                  fontSize: 9.0,
                                  color: ColorApp.myColorGrayText,
                                ),
                              ),
                            ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Что было в месяце — словами. Точки показывают, что работы были, а
  /// подсказка отвечает, какие именно, не заставляя проваливаться внутрь.
  String _tooltip() {
    final List<String> parts = <String>[maintenanceLabel(cell.maintenance)];
    if (cell.counts.breakdowns > 0) {
      parts.add('аварийных выездов: ${cell.counts.breakdowns}');
    }
    if (cell.counts.clientRequests > 0) {
      parts.add('заявок от заказчика: ${cell.counts.clientRequests}');
    }
    if (cell.counts.otherRequests > 0) {
      parts.add('прочих работ: ${cell.counts.otherRequests}');
    }
    if (cell.counts.defects > 0) {
      parts.add('дефектных ведомостей: ${cell.counts.defects}');
    }
    return parts.join('\n');
  }
}

class _Dot extends StatelessWidget {
  const _Dot({Key? key, required this.color}) : super(key: key);

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 5.0,
      height: 5.0,
      margin: const EdgeInsets.symmetric(horizontal: 1.0),
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

/// Легенда под матрицей. Без неё цвета и точки — ребус.
class MonthCellLegend extends StatelessWidget {
  const MonthCellLegend({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Wrap(
      spacing: 16.0,
      runSpacing: 6.0,
      children: <Widget>[
        _LegendBar(color: ColorApp.myColorGreen, label: 'ТО в срок'),
        _LegendBar(color: ColorApp.myColorYellow, label: 'ТО с опозданием'),
        _LegendBar(color: ColorApp.myColorRed, label: 'ТО просрочено'),
        _LegendBar(color: ColorApp.myColorGrayBorder, label: 'месяц идёт'),
        _LegendDot(color: ColorApp.myColorRed, label: 'авария'),
        _LegendDot(color: ColorApp.myColorBlue, label: 'заявка заказчика'),
        _LegendDot(color: ColorApp.myColorGray, label: 'прочая работа'),
        _LegendDot(color: ColorApp.myColorYellow, label: 'дефектная ведомость'),
      ],
    );
  }
}

class _LegendBar extends StatelessWidget {
  const _LegendBar({Key? key, required this.color, required this.label})
      : super(key: key);

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 14.0,
          height: 8.0,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2.0),
          ),
        ),
        const SizedBox(width: 6.0),
        Text(label, style: const TextStyle(fontSize: 12.0)),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({Key? key, required this.color, required this.label})
      : super(key: key);

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 6.0,
          height: 6.0,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6.0),
        Text(label, style: const TextStyle(fontSize: 12.0)),
      ],
    );
  }
}
