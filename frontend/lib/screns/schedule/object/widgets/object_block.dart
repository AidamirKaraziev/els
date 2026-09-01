import 'package:flutter/material.dart';

import '../../../../helper/class_colors.dart';

/// Заголовок блока и его содержимое.
///
/// Общий на три блока кадра: у «Информации», «Местоположения» и
/// «Ответственных» одинаковый заголовок 16/w600 и один отступ до карточки.
class ObjectBlock extends StatelessWidget {
  const ObjectBlock({Key? key, required this.title, required this.child})
      : super(key: key);

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16.0),
        child,
      ],
    );
  }
}

/// Белая карточка с мягкой тенью — общий фон блоков на кадре.
///
/// Тень подрядчика (`Colors.grey`, `blurRadius: 5`, без смещения) на кадре
/// выглядит грязной каймой по всем четырём сторонам; здесь она приглушена и
/// сдвинута вниз, как на макете.
BoxDecoration objectCardDecoration() => BoxDecoration(
      borderRadius: BorderRadius.circular(10.0),
      color: ColorApp.myColorWhite,
      boxShadow: <BoxShadow>[
        BoxShadow(
          color: Colors.grey.withValues(alpha: 0.25),
          blurRadius: 12.0,
          offset: const Offset(0, 4),
        ),
      ],
    );
