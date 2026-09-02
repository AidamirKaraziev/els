import 'package:flutter/material.dart';

import '../../../../../helper/calendar/month_picker.dart' show kMonthsNominative;
import '../../../../../helper/class_colors.dart';
import '../../widgets/object_block.dart';
import '../models/schedule_wizard_data.dart';

/// Шаг 1 — «Программа модели».
///
/// Двенадцать позиций цикла, по которым разложится год. **Только показ**:
/// правка программы и её сохранение — отдельная задача (решено 2 сентября).
/// Поэтому здесь нет ни полей, ни кнопки «Сохранить», а предупреждение про
/// общую на всю модель программу стоит текстом: человек должен понимать, что
/// увиденное относится не к одному его лифту.
class WizardProgramStep extends StatelessWidget {
  const WizardProgramStep({Key? key, required this.data}) : super(key: key);

  final ScheduleWizardData data;

  /// Ширина, ниже которой позиции идут одной колонкой вместо двух.
  static const double _twoColumnsWidth = 560.0;

  @override
  Widget build(BuildContext context) {
    return ObjectBlock(
      title: 'Программа обслуживания модели',
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16.0),
        decoration: objectCardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              data.modelName,
              style: const TextStyle(fontSize: 15.0, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4.0),
            const Text(
              'Программа принадлежит модели: её правка касается всех объектов '
              'этой модели, а не только текущего.',
              style: TextStyle(fontSize: 13.0, color: ColorApp.myColorGray),
            ),
            const SizedBox(height: 16.0),
            _Positions(items: data.program, twoColumnsWidth: _twoColumnsWidth),
            if (data.hasKnownAnchor) ...<Widget>[
              const SizedBox(height: 16.0),
              _KnownAnchorNote(anchorMonth: data.knownAnchor!),
            ],
          ],
        ),
      ),
    );
  }
}

/// Двенадцать строк «позиция → вид ТО».
class _Positions extends StatelessWidget {
  const _Positions({
    Key? key,
    required this.items,
    required this.twoColumnsWidth,
  }) : super(key: key);

  final List<WizardProgramItem> items;
  final double twoColumnsWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool wide = constraints.maxWidth >= twoColumnsWidth;
        if (!wide) {
          return Column(
            children: <Widget>[
              for (final WizardProgramItem item in items) _Row(item: item),
            ],
          );
        }
        // Двенадцать строк в одну колонку — это экран прокрутки ради списка,
        // который целиком помещается в две.
        final int half = (items.length / 2).ceil();
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Column(
                children: <Widget>[
                  for (final WizardProgramItem item in items.take(half))
                    _Row(item: item),
                ],
              ),
            ),
            const SizedBox(width: 24.0),
            Expanded(
              child: Column(
                children: <Widget>[
                  for (final WizardProgramItem item in items.skip(half))
                    _Row(item: item),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({Key? key, required this.item}) : super(key: key);

  final WizardProgramItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: <Widget>[
          // Номер позиции, а не месяц: цикл не обязан начинаться с января, и
          // подписывать позицию месяцем здесь значило бы врать.
          SizedBox(
            width: 32.0,
            child: Text(
              '${item.position}',
              style: const TextStyle(
                fontSize: 13.0,
                color: ColorApp.myColorGrayText,
              ),
            ),
          ),
          Expanded(
            child: Text(
              item.typeActName.isEmpty ? 'вид ТО не выбран' : item.typeActName,
              style: TextStyle(
                fontSize: 14.0,
                color: item.typeActName.isEmpty
                    ? ColorApp.myColorRed
                    : ColorApp.myColorBlack,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// «Цикл уже известен» — вместо шага «Точка отсчёта».
///
/// Шаг пропускается молча только в коде; человеку сказать надо, иначе он
/// видит два шага там, где ему обещали три, и не понимает, с какого месяца
/// пойдёт цикл.
///
/// Откуда взят якорь — из прошлого года или из этого же, расставленного
/// раньше, — ручка не сообщает, и текст про год не пишем: назвать не тот
/// год хуже, чем не называть никакого.
class _KnownAnchorNote extends StatelessWidget {
  const _KnownAnchorNote({Key? key, required this.anchorMonth})
      : super(key: key);

  final int anchorMonth;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: ColorApp.myColorGreenLine,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Text(
        'У объекта уже есть график — цикл продолжается без разрыва, '
        'начало цикла: ${kMonthsNominative[anchorMonth - 1].toLowerCase()}. '
        'Точку отсчёта выбирать не нужно.',
        style: const TextStyle(fontSize: 13.0, color: ColorApp.myColorBlack),
      ),
    );
  }
}
