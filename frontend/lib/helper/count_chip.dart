import 'package:flutter/material.dart';

import 'class_colors.dart';

/// Тон таблетки с числом.
///
/// Три состояния одной лестницы: спокойное дело, работа в ходу, работа
/// встала. Цвет здесь не украшение — по нему числа различают, не читая.
enum CountTone {
  /// Спокойное: непросмотренные сданные работы. Это долг по проверке, а не
  /// событие, и кричать ему не о чем.
  neutral,

  /// Работа идёт.
  running,

  /// Работа встала с проблемой.
  problem,
}

/// Таблетка с числом у пункта меню.
///
/// Светлая подложка, цветные буквы — набор общий с пилюлями состояния в
/// разделе «Сейчас в работе», чтобы меню и список говорили одно и то же.
///
/// Подложки заметно плотнее, чем у пилюль в списке: таблетки стоят на белом
/// меню и на зелёной подсветке открытого пункта, и на подсветке светлая
/// зелёная подложка исчезала совсем.
///
/// Ширина заведомо больше высоты: рядом могут стоять числа другой природы, и
/// таблетка должна читаться таблеткой даже на одной цифре.
class CountChip extends StatelessWidget {
  const CountChip({Key? key, required this.count, required this.tone})
      : super(key: key);

  final int count;
  final CountTone tone;

  @override
  Widget build(BuildContext context) {
    final _ChipColors colors = _ChipColors.of(tone);

    return Container(
      height: 24.0,
      constraints: const BoxConstraints(minWidth: 32.0),
      padding: const EdgeInsets.symmetric(horizontal: 9.0),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(999.0),
      ),
      alignment: Alignment.center,
      child: Text(
        _label(count),
        style: TextStyle(
          fontSize: 12.0,
          fontWeight: FontWeight.bold,
          color: colors.ink,
          // Цифры одной ширины: числа меняются сами, и строка меню не должна
          // от этого дёргаться.
          fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

class _ChipColors {
  const _ChipColors(this.background, this.ink);

  final Color background;
  final Color ink;

  static _ChipColors of(CountTone tone) {
    switch (tone) {
      case CountTone.neutral:
        return const _ChipColors(Color(0xffE7E9E9), ColorApp.myColorGray);
      case CountTone.running:
        // На тон глубже, чем `myColorGreenLine`: тем же цветом подсвечен
        // открытый пункт меню, и на нём таблетка пропадала.
        return const _ChipColors(Color(0xffD3E9B4), Color(0xff41691A));
      case CountTone.problem:
        return const _ChipColors(Color(0xffF3CFCE), Color(0xff9C3835));
    }
  }
}

/// «99+» вместо сотен. Порог недостижимый, но строка меню не должна
/// разъезжаться, если он всё-таки случится.
String _label(int count) => count > 99 ? '99+' : '$count';
