import 'package:flutter/material.dart';

import '../../../../helper/class_colors.dart';
import '../models/breakdowns_report.dart';

/// Строка топа: объект слева, счётчик поломок справа.
///
/// Восемь полей, выбранных для отчёта, в ширину карточки на главной не влезают,
/// поэтому здесь только то, по чему лифт узнают: номер, адрес, клиент и —
/// на широком экране — механик. Модель, участок и время реакции живут на
/// экране подробностей.
class BreakdownRow extends StatelessWidget {
  const BreakdownRow({
    Key? key,
    required this.item,
    required this.maxCount,
    this.onTap,
    this.showMechanic = true,
  }) : super(key: key);

  final BreakdownObject item;

  /// Счётчик лидера — по нему красится плашка: у первой строки она насыщенная,
  /// у последней бледная. Так порядок читается без вглядывания в цифры.
  final int maxCount;

  final VoidCallback? onTap;
  final bool showMechanic;

  /// «Поломок за месяц: 4 — AA · 1, Н · 3».
  String get _severityTooltip {
    final String total = 'Поломок за месяц: ${item.breakdownCount}';
    if (item.severity.isEmpty) return total;

    final String breakdown = item.severity
        .map((SeverityCount part) => '${part.label} · ${part.count}')
        .join(', ');
    return '$total\n$breakdown';
  }

  Color get _countColor {
    if (maxCount <= 0) return ColorApp.myColorGray;
    final double ratio = item.breakdownCount / maxCount;
    if (ratio >= 0.75) return ColorApp.myColorRed;
    if (ratio >= 0.4) return ColorApp.myColorYellow;
    return ColorApp.myColorGray;
  }

  @override
  Widget build(BuildContext context) {
    final String? subtitle = item.subtitle;
    final String? client = item.client;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10.0),
        child: Row(
          children: [
            Expanded(
              child: Container(
                constraints: const BoxConstraints(minHeight: 46.0),
                decoration: BoxDecoration(
                  color: ColorApp.myColorTransparent,
                  borderRadius: BorderRadius.circular(10.0),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10.0,
                  vertical: 6.0,
                ),
                child: Row(
                  children: [
                    /// Номер и адрес
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          if (subtitle != null)
                            Text(
                              subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11.0,
                                color: ColorApp.myColorGrayText,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8.0),

                    /// Клиент
                    Expanded(
                      flex: 3,
                      child: Text(
                        client ?? '—',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: client == null
                              ? ColorApp.myColorGrayText
                              : ColorApp.myColorBlack,
                        ),
                      ),
                    ),

                    /// Ответственный механик
                    if (showMechanic) ...[
                      const SizedBox(width: 8.0),
                      Expanded(
                        flex: 3,
                        child: Text(
                          item.responsibleMechanic ?? 'Не назначен',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: item.responsibleMechanic == null
                                ? ColorApp.myColorGrayText
                                : ColorApp.myColorBlack,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10.0),

            /// Счётчик поломок. Разбивка по тяжести в строку не помещается,
            /// поэтому висит подсказкой; целиком она видна на экране
            /// подробностей.
            Tooltip(
              message: _severityTooltip,
              child: Container(
                width: 44,
                height: 46,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10.0),
                  color: _countColor,
                ),
                child: Center(
                  child: Text(
                    '${item.breakdownCount}',
                    style: const TextStyle(
                      color: ColorApp.myColorWhite,
                      fontSize: 16.0,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
