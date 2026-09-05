/// Размеры и стили экранов дефектов прораба — одним местом на оба экрана.
///
/// Кадра в макете нет, поэтому числа взяты не с потолка, а с соседей:
/// отступ `ColorApp.kPadding` и белая карточка со скруглением 5 — из карточки
/// объекта прораба (`object_foreman/object_page_foreman.dart`), кегли и
/// разделитель — из оболочки механика (`mechanic/mechanic_theme.dart`), где
/// они сняты с кадров. Появится кадр списка дефектов — править надо здесь,
/// а не в двух экранах.
///
/// Цвета берём из общей палитры `helper/class_colors.dart`. Заводить второй
/// набор тех же зелёных — верный способ получить два слегка разных.
library;

import 'package:flutter/material.dart';

import '../../helper/class_colors.dart';
import 'defect_entry.dart';

class DefectsLayout {
  /// Поле экрана. У прораба всё стоит на 20 — берём его, а не механиковские 16.
  static const double screenPadding = ColorApp.kPadding;

  static const double cardRadius = 5.0;
  static const double cardGap = 12.0;

  static const Color divider = Color(0xffEBEBEB);

  static const TextStyle screenTitle = TextStyle(
    fontSize: 24.0,
    fontWeight: FontWeight.w700,
    color: ColorApp.myColorBlack,
  );

  static const TextStyle cardTitle = TextStyle(
    fontSize: 15.0,
    fontWeight: FontWeight.w600,
    color: ColorApp.myColorBlack,
  );

  static const TextStyle cardSubtitle = TextStyle(
    fontSize: 12.0,
    fontWeight: FontWeight.w300,
    color: ColorApp.myColorGrayText,
  );

  /// Подпись поля в карточке: «Вид ТО», «Кто нашёл».
  static const TextStyle rowLabel = TextStyle(
    fontSize: 12.0,
    fontWeight: FontWeight.w300,
    color: ColorApp.myColorGrayText,
  );

  /// Значение поля в карточке.
  static const TextStyle rowValue = TextStyle(
    fontSize: 15.0,
    fontWeight: FontWeight.w600,
    color: ColorApp.myColorBlack,
  );

  /// Год в переключателе.
  static const TextStyle yearValue = TextStyle(
    fontSize: 17.0,
    fontWeight: FontWeight.w600,
    color: ColorApp.myColorBlack,
  );
}

/// Цвета пилюли состояния.
///
/// Состояний четыре, и различать их надо с одного взгляда на список: зелёным
/// помечено то, что доведено до конца, серым — то, что только заведено.
class DefectStateColors {
  static Color background(DefectState state) {
    switch (state) {
      case DefectState.created:
        return ColorApp.myColorGrayBorder;
      case DefectState.reviewed:
        return const Color(0xffFDF0DC);
      case DefectState.issued:
        return const Color(0xffE6EDFD);
      case DefectState.fixed:
        return ColorApp.myColorGreenLine;
      case DefectState.unknown:
        return ColorApp.myColorGrayBorder;
    }
  }

  static Color text(DefectState state) {
    switch (state) {
      case DefectState.created:
        return ColorApp.myColorGray;
      case DefectState.reviewed:
        return const Color(0xffB07D2B);
      case DefectState.issued:
        return const Color(0xff4B6BB8);
      case DefectState.fixed:
        return ColorApp.myColorGreenAuth;
      case DefectState.unknown:
        return ColorApp.myColorGray;
    }
  }
}

/// Пилюля состояния — одна на список и на карточку.
class DefectStatePill extends StatelessWidget {
  const DefectStatePill({Key? key, required this.state}) : super(key: key);

  final DefectState state;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
      decoration: BoxDecoration(
        color: DefectStateColors.background(state),
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Text(
        state.label,
        style: TextStyle(
          fontSize: 12.0,
          fontWeight: FontWeight.w600,
          color: DefectStateColors.text(state),
        ),
      ),
    );
  }
}
