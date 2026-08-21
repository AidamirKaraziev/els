import 'package:flutter/material.dart';

/// Оттенки состояния текущей работы: пилюля в строке раздела и таблетки чисел
/// в боковом меню красятся одним набором.
///
/// Светлая подложка, цветные буквы — так пилюля не спорит с бейджем вида
/// работы и видно, что это разные вещи.
///
/// В `class_colors.dart` из них есть только зелёная подложка
/// ([ColorApp.myColorGreenLine]); остальные живут здесь, а не в общем файле:
/// он достался от подрядчика, и своими цветами мы его не разбавляем, пока они
/// нужны одному разделу.
const Color pauseBackground = Color(0xffFBEFC7);
const Color pauseText = Color(0xff8A6A00);
const Color problemBackground = Color(0xffF7DCDB);
const Color problemText = Color(0xffB03F3B);
const Color runningText = Color(0xff4C7A1F);
