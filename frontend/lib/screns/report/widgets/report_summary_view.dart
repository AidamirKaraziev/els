import 'package:flutter/material.dart';

import '../../../helper/class_colors.dart';
import '../models/works_report.dart';

/// Сводка за период плюс помесячная полоса по всему отбору.
///
/// Считается по всему отбору, а не по видимой странице: иначе цифры менялись
/// бы при листании, и человек решил бы, что данные плывут.
class ReportSummaryView extends StatelessWidget {
  const ReportSummaryView({
    Key? key,
    required this.report,
    required this.onMonthTap,
    this.onDefectsTap,
  }) : super(key: key);

  final WorksReport report;

  /// Тап по плитке актов открывает их список за тот же период и отбор.
  /// При нуле плитка не нажимается: открывать пустой список незачем.
  final VoidCallback? onDefectsTap;

  /// Клик по столбику сужает период до этого месяца — тот же отбор, что и
  /// счётчик, на который нажали.
  final void Function(int year, int month) onMonthTap;

  @override
  Widget build(BuildContext context) {
    final ReportSummary summary = report.summary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Wrap(
          spacing: 12.0,
          runSpacing: 12.0,
          children: <Widget>[
            _Tile(
              label: 'ТО выполнено',
              value: '${summary.maintenanceCompleted}',
              hint: summary.maintenancePlanned == 0
                  ? 'график не заполнен'
                  : 'из ${summary.maintenancePlanned} · '
                      '${summary.completionPercent}%',
              hintColor: summary.maintenancePlanned == 0
                  ? ColorApp.myColorGrayText
                  : ColorApp.myColorGreenAuth,
            ),
            _Tile(
              label: 'Просрочено ТО',
              value: '${summary.maintenanceOverdue}',
              hint: summary.maintenanceLate > 0
                  ? 'закрыто с опозданием: ${summary.maintenanceLate}'
                  : null,
              hintColor: ColorApp.myColorRed,
            ),
            _Tile(
              label: 'Аварийных выездов',
              value: '${summary.counts.breakdowns}',
              // Число заявок рядом со средним обязательно: «2 ч» по одной
              // заявке из сорока и «2 ч» по сорока выглядят одинаково.
              hint: summary.reactedCount > 0
                  ? 'реакция ${summary.reactionLabel} '
                      '(по ${summary.reactedCount})'
                  : null,
            ),
            _Tile(
              label: 'Заявок от заказчика',
              value: '${summary.counts.clientRequests}',
              hint: summary.counts.otherRequests > 0
                  ? 'прочих работ: ${summary.counts.otherRequests}'
                  : null,
            ),
            _Tile(
              label: 'Объектов в отчёте',
              value: '${summary.objectsTotal}',
              hint: '${summary.objectsWithoutBreakdowns} без аварий',
            ),
            // Ноль — серый, а не красный: красное число на ровном месте
            // читается как тревога. Тот же приём, что у значка в ленте
            // графиков (`DefectsBadge`).
            _Tile(
              label: 'Дефектных актов',
              value: '${summary.counts.defects}',
              valueColor: summary.counts.defects > 0
                  ? ColorApp.myColorRed
                  : ColorApp.myColorGrayText,
              hint: summary.counts.defects > 0
                  ? 'открыть список'
                  : 'за период не составлялись',
              hintColor: summary.counts.defects > 0
                  ? ColorApp.myColorBlue
                  : ColorApp.myColorGrayText,
              onTap: summary.counts.defects > 0 ? onDefectsTap : null,
            ),
          ],
        ),
        const SizedBox(height: 18.0),
        const Text(
          'По месяцам',
          style: TextStyle(fontSize: 15.0, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8.0),
        _MonthStrip(report: report, onMonthTap: onMonthTap),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    Key? key,
    required this.label,
    required this.value,
    this.hint,
    this.hintColor,
    this.valueColor,
    this.onTap,
  }) : super(key: key);

  final String label;
  final String value;
  final String? hint;
  final Color? hintColor;
  final Color? valueColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Widget tile = Container(
      width: 190.0,
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: ColorApp.myColorWhite,
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: ColorApp.myColorGrayBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            label,
            style: const TextStyle(
              fontSize: 12.0,
              color: ColorApp.myColorGrayText,
            ),
          ),
          const SizedBox(height: 4.0),
          Text(
            value,
            style: TextStyle(
              fontSize: 24.0,
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
          if (hint != null) ...<Widget>[
            const SizedBox(height: 2.0),
            Text(
              hint!,
              style: TextStyle(
                fontSize: 11.0,
                color: hintColor ?? ColorApp.myColorGrayText,
              ),
            ),
          ],
        ],
      ),
    );
    if (onTap == null) return tile;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10.0),
      child: tile,
    );
  }
}

/// Столбики по месяцам: сверху доля выполненных ТО, снизу число работ.
class _MonthStrip extends StatelessWidget {
  const _MonthStrip({Key? key, required this.report, required this.onMonthTap})
      : super(key: key);

  final WorksReport report;
  final void Function(int year, int month) onMonthTap;

  @override
  Widget build(BuildContext context) {
    if (report.months.isEmpty) return const SizedBox.shrink();

    // Высота столбика — от самого загруженного месяца, а не от абсолютного
    // числа: иначе на спокойном периоде полоса выглядела бы пустой.
    int peak = 1;
    for (final MonthTotals month in report.months) {
      final int total = month.maintenancePlanned + month.counts.total;
      if (total > peak) peak = total;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: ColorApp.myColorWhite,
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: ColorApp.myColorGrayBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: report.months
            .map((MonthTotals month) => Expanded(
                  child: _MonthBar(
                    month: month,
                    peak: peak,
                    onTap: () => onMonthTap(month.year, month.month),
                  ),
                ))
            .toList(growable: false),
      ),
    );
  }
}

class _MonthBar extends StatelessWidget {
  const _MonthBar({
    Key? key,
    required this.month,
    required this.peak,
    required this.onTap,
  }) : super(key: key);

  final MonthTotals month;
  final int peak;
  final VoidCallback onTap;

  static const double _maxHeight = 56.0;

  @override
  Widget build(BuildContext context) {
    final int works = month.counts.total;
    final double planHeight =
        month.maintenancePlanned == 0 ? 0 : _maxHeight * month.maintenancePlanned / peak;
    final double worksHeight = works == 0 ? 0 : _maxHeight * works / peak;

    final bool complete = month.maintenancePlanned > 0 &&
        month.maintenanceCompleted == month.maintenancePlanned;

    return InkWell(
      onTap: onTap,
      child: Tooltip(
        message: '${monthFullNames[month.month - 1]} ${month.year}\n'
            'ТО: ${month.maintenanceCompleted} из ${month.maintenancePlanned}\n'
            'прочих работ: $works\n'
            'дефектных актов: ${month.counts.defects}',
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 3.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  _Bar(
                    height: planHeight,
                    color: complete
                        ? ColorApp.myColorGreen
                        : ColorApp.myColorGreenWhite,
                  ),
                  const SizedBox(width: 2.0),
                  _Bar(height: worksHeight, color: ColorApp.myColorBlue),
                ],
              ),
              const SizedBox(height: 4.0),
              Text(
                monthShortNames[month.month - 1],
                style: const TextStyle(
                  fontSize: 10.0,
                  color: ColorApp.myColorGrayText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({Key? key, required this.height, required this.color})
      : super(key: key);

  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8.0,
      // Нулевой столбик всё равно рисуем полоской в один пиксель: пустое
      // место читается как «нет данных», а тут данные есть и они нулевые.
      height: height < 2.0 ? 2.0 : height,
      decoration: BoxDecoration(
        color: height < 2.0 ? ColorApp.myColorGrayBorder : color,
        borderRadius: BorderRadius.circular(2.0),
      ),
    );
  }
}
