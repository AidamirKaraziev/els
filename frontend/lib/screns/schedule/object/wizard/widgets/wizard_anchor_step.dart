import 'package:flutter/material.dart';

import '../../../../../helper/calendar/month_picker.dart' show kMonthsNominative;
import '../../../../../helper/class_colors.dart';
import '../../widgets/object_block.dart';
import '../models/schedule_wizard_data.dart';

/// Шаг 2 — «Точка отсчёта»: месяц, на который приходится первая позиция
/// программы.
///
/// Показывается, только когда якорь неоткуда взять: графика за прошлый год
/// нет либо он не ложится на программу однозначно. Есть прошлый год — шаг
/// пропускается целиком, и мастер об этом говорит на первом шаге.
///
/// Выбирать за человека нельзя: якорь сдвигает весь год, и молчаливый выбор
/// выглядел бы как «система сама так решила». Тем же рассуждением живёт 422
/// в ручке предпросмотра (`_anchor_required` в `schedule_plan.py`).
class WizardAnchorStep extends StatelessWidget {
  const WizardAnchorStep({
    Key? key,
    required this.data,
    required this.anchorMonth,
    required this.onChanged,
  }) : super(key: key);

  final ScheduleWizardData data;

  /// Выбранный месяц, 1..12.
  final int anchorMonth;

  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final String firstTypeAct =
        data.program.isEmpty ? '' : data.program.first.typeActName;

    return ObjectBlock(
      title: 'Точка отсчёта',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16.0),
        decoration: objectCardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Начало цикла не удалось определить по графику за '
              '${data.year - 1} год: его либо нет, либо он не ложится на '
              'программу однозначно. Месяц выбирается вручную.',
              style: const TextStyle(fontSize: 13.0, color: ColorApp.myColorGray),
            ),
            const SizedBox(height: 16.0),
            const Text(
              'С какого месяца начинается цикл',
              style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12.0),
            _MonthGrid(selected: anchorMonth, onChanged: onChanged),
            const SizedBox(height: 16.0),
            Text(
              'Первая позиция программы'
              '${firstTypeAct.isEmpty ? '' : ' — $firstTypeAct'} придётся на '
              '${kMonthsNominative[anchorMonth - 1].toLowerCase()} '
              '${data.year} года.',
              style: const TextStyle(fontSize: 13.0, color: ColorApp.myColorBlack),
            ),
          ],
        ),
      ),
    );
  }
}

/// Двенадцать месяцев плитками. Выбор одним нажатием, без выпадающего списка:
/// вариантов ровно двенадцать, и все они помещаются на экран.
class _MonthGrid extends StatelessWidget {
  const _MonthGrid({Key? key, required this.selected, required this.onChanged})
      : super(key: key);

  final int selected;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: <Widget>[
        for (int month = 1; month <= 12; month++)
          _MonthChip(
            month: month,
            isSelected: month == selected,
            onTap: () => onChanged(month),
          ),
      ],
    );
  }
}

class _MonthChip extends StatelessWidget {
  const _MonthChip({
    Key? key,
    required this.month,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  final int month;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final String name = kMonthsNominative[month - 1];
    return Material(
      color: isSelected ? ColorApp.myColorGreenAuth : ColorApp.myColorWhite,
      borderRadius: BorderRadius.circular(8.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8.0),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(
              color: isSelected
                  ? ColorApp.myColorGreenAuth
                  : ColorApp.myColorGrayBorder,
            ),
          ),
          child: Text(
            name,
            style: TextStyle(
              fontSize: 13.0,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color:
                  isSelected ? ColorApp.myColorWhite : ColorApp.myColorBlack,
            ),
          ),
        ),
      ),
    );
  }
}
