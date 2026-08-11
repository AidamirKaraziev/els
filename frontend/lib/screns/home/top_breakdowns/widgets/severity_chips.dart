import 'package:flutter/material.dart';

import '../../../../helper/class_colors.dart';
import '../models/breakdowns_report.dart';

/// Свод по категориям тяжести: «AA · 3   А · 12   В · 7».
///
/// Строкой чипов, а не диаграммой: карточка на главной невысокая, а на
/// телефоне доли в полосе превращаются в нечитаемые полоски. Чипы переносятся
/// на вторую строку и остаются читаемыми на любой ширине.
class SeverityChips extends StatelessWidget {
  const SeverityChips({
    Key? key,
    required this.items,
    this.compact = false,
  }) : super(key: key);

  final List<SeverityCount> items;

  /// На телефоне чипы мельче и без долей в процентах.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 6.0,
      runSpacing: 6.0,
      children: items
          .map((SeverityCount item) => _Chip(item: item, compact: compact))
          .toList(growable: false),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({Key? key, required this.item, required this.compact})
      : super(key: key);

  final SeverityCount item;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final Color color = item.color;

    return Tooltip(
      // Код «AA» ничего не говорит новому человеку — полное название есть
      // только здесь, в карточку оно не помещается.
      message: item.name ?? item.label,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 6.0 : 8.0,
          vertical: compact ? 2.0 : 4.0,
        ),
        decoration: BoxDecoration(
          color: color.withOpacity(0.14),
          borderRadius: BorderRadius.circular(20.0),
          border: Border.all(color: color.withOpacity(0.45)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6.0,
              height: 6.0,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 5.0),
            Text(
              '${item.label} · ${item.count}',
              style: TextStyle(
                fontSize: compact ? 11.0 : 12.5,
                fontWeight: FontWeight.w600,
                color: ColorApp.myColorBlack,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
