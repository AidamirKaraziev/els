import 'package:flutter/material.dart';

import '../../../helper/class_colors.dart';

/// Переключатель года: «‹ 2026 ›».
///
/// Стоит и в панели фильтров над лентой объектов, и в шапке списка участков.
/// Год — не условие отбора, а то, на что мы смотрим: сброс фильтров его не
/// трогает, а выбранный год едет с человеком дальше, на экран объектов.
///
/// Вынесен из панели фильтров, а не скопирован: две пилюли года в одном
/// разделе неизбежно разъехались бы по высоте и кеглю.
class ScheduleYearPicker extends StatelessWidget {
  const ScheduleYearPicker({
    Key? key,
    required this.year,
    required this.onChanged,
  }) : super(key: key);

  final int year;
  final ValueChanged<int> onChanged;

  static const double height = 24.0;
  static const double fontSize = 10.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: ColorApp.myColorWhite,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: ColorApp.myColorGreenAuth),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _YearArrow(
            icon: Icons.chevron_left,
            tooltip: 'Предыдущий год',
            onPressed: () => onChanged(year - 1),
          ),
          Text(
            '$year',
            style: const TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: ColorApp.myColorBlack,
            ),
          ),
          _YearArrow(
            icon: Icons.chevron_right,
            tooltip: 'Следующий год',
            onPressed: () => onChanged(year + 1),
          ),
        ],
      ),
    );
  }
}

/// Стрелка года.
///
/// Не `IconButton`: у того минимальная область нажатия 48 и он растянул бы
/// пилюлю вдвое против кадра. Поле нажатия при этом остаётся во всю высоту
/// пилюли, а не по размеру самой стрелки.
class _YearArrow extends StatelessWidget {
  const _YearArrow({
    Key? key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  }) : super(key: key);

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        child: SizedBox(
          width: 20,
          height: ScheduleYearPicker.height,
          child: Icon(icon, size: 14, color: ColorApp.myColorGreenAuth),
        ),
      ),
    );
  }
}
