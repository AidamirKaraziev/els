/// Размеры и приёмы оболочки механика — одним местом на все её экраны.
///
/// Числа сняты с кадров страницы «Механик | Мобильная версия» файла «КПЭК»
/// (375×667): «Список заявок» `1826:155`, «Объекты` `1826:210`,
/// «Уведомления» `1826:270`, «Личный кабинет» `1826:283`. Держим их здесь, а
/// не в каждом экране, потому что экраны потока заявок и ТО делаются
/// следующими этапами и обязаны совпасть с этими по отступам и кеглю.
///
/// Цвета берём из общей палитры `helper/class_colors.dart`: макетные
/// `#BADE89`, `#9B9A9A`, `#F5F6F6`, `#85B544` уже лежат там под именами
/// приложения. Заводить второй набор тех же цветов — верный способ получить
/// два слегка разных зелёных.
library;

import 'package:flutter/material.dart';

import '../helper/class_colors.dart';

class MechanicLayout {
  /// Поля экрана. В макете заголовок и карточки стоят на 16, строки
  /// профиля — на 18; разница в два пикселя ничего не значит, берём 16.
  static const double screenPadding = 16.0;

  /// Высота нижней навигации из макета.
  static const double navBarHeight = 49.0;

  /// Заголовок экрана: «Заявки», «Объекты», «Личный кабинет».
  static const TextStyle screenTitle = TextStyle(
    fontSize: 34.0,
    fontWeight: FontWeight.w700,
    color: ColorApp.myColorBlack,
  );

  /// Подпись раздела внутри экрана: «Плановые ТО», «Мои объекты».
  static const TextStyle sectionTitle = TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.w500,
    color: ColorApp.myColorBlack,
  );

  /// Серая подпись группы строк: «Контакты», «Информация», «Документы».
  static const TextStyle groupLabel = TextStyle(
    fontSize: 12.0,
    fontWeight: FontWeight.w500,
    color: Color(0xff8E8E93),
  );

  /// Название в карточке списка.
  static const TextStyle cardTitle = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.w700,
    color: ColorApp.myColorBlack,
  );

  /// Вторая строка карточки: срок, адрес.
  static const TextStyle cardSubtitle = TextStyle(
    fontSize: 12.0,
    fontWeight: FontWeight.w300,
    color: ColorApp.myColorGrayText,
  );

  /// Подпись строки в профиле.
  static const TextStyle rowLabel = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.w300,
    color: ColorApp.myColorBlack,
  );

  /// Значение строки в профиле.
  static const TextStyle rowValue = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.w300,
    color: Color(0xff1C1C1E),
  );

  /// Разделитель строк.
  static const Color divider = Color(0xffEBEBEB);

  /// Карточка списка: белая, скругление 5, высота 85 — так во всех кадрах.
  static const double cardRadius = 5.0;
  static const double cardHeight = 85.0;
  static const double cardGap = 16.0;
}
