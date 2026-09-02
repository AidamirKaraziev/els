import 'package:flutter/material.dart';

import '../../../../../helper/class_colors.dart';

/// Полоса шагов мастера: номер, название, черта между ними.
///
/// Шагов может быть два или три — «Точка отсчёта» отпадает, когда цикл
/// продолжается с прошлого года. Поэтому названия приходят списком, а не
/// зашиты здесь: полоса не должна знать, из-за чего шагов стало меньше.
class WizardStepsHeader extends StatelessWidget {
  const WizardStepsHeader({
    Key? key,
    required this.titles,
    required this.current,
  }) : super(key: key);

  final List<String> titles;

  /// Индекс текущего шага в [titles], с нуля.
  final int current;

  /// Ширина, ниже которой названия шагов прячутся и остаются одни номера.
  ///
  /// «Программа модели · Точка отсчёта · Предпросмотр» в одну строку на
  /// телефоне не помещается ни при какой вёрстке, а перенос превращает
  /// полосу в абзац.
  static const double _labelsWidth = 520.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool showLabels = constraints.maxWidth >= _labelsWidth;
        final List<Widget> children = <Widget>[];
        for (int i = 0; i < titles.length; i++) {
          if (i > 0) {
            children.add(Expanded(
              child: Container(
                height: 1.0,
                margin: const EdgeInsets.symmetric(horizontal: 8.0),
                color: ColorApp.myColorGrayBorder,
              ),
            ));
          }
          children.add(_Step(
            number: i + 1,
            title: titles[i],
            showLabel: showLabels,
            isCurrent: i == current,
            isDone: i < current,
          ));
        }
        return Row(children: children);
      },
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    Key? key,
    required this.number,
    required this.title,
    required this.showLabel,
    required this.isCurrent,
    required this.isDone,
  }) : super(key: key);

  final int number;
  final String title;
  final bool showLabel;
  final bool isCurrent;
  final bool isDone;

  @override
  Widget build(BuildContext context) {
    // Пройденный шаг и текущий залиты одинаково: разделять их третьим цветом
    // значит завести три состояния там, где человеку важны два — «сюда я уже
    // дошёл» и «сюда ещё нет».
    final bool filled = isCurrent || isDone;
    final Color background =
        filled ? ColorApp.myColorGreenAuth : ColorApp.myColorGrayShadow;
    final Color foreground =
        filled ? ColorApp.myColorWhite : ColorApp.myColorGrayText;

    final Widget badge = Container(
      width: 26.0,
      height: 26.0,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        shape: BoxShape.circle,
      ),
      child: isDone
          ? Icon(Icons.check, size: 16.0, color: foreground)
          : Text(
              '$number',
              style: TextStyle(
                fontSize: 13.0,
                fontWeight: FontWeight.w600,
                color: foreground,
              ),
            ),
    );

    if (!showLabel) {
      return Tooltip(message: title, child: badge);
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        badge,
        const SizedBox(width: 8.0),
        Text(
          title,
          style: TextStyle(
            fontSize: 14.0,
            fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
            color: isCurrent ? ColorApp.myColorBlack : ColorApp.myColorGray,
          ),
        ),
      ],
    );
  }
}
