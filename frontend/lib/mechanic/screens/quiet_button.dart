/// Тихая кнопка: действие, которое ничего не двигает.
///
/// «Приостановить», «Проблема», «Дефект» — в карточке ТО они стоят строкой
/// под главной кнопкой и намеренно выглядят слабее её: главное действие
/// экрана одно, остальные его не перебивают.
///
/// Живёт отдельным файлом, потому что дефект записывается уже из четырёх
/// мест — карточки ТО, пункта чек-листа, заявки и объекта, — и четыре
/// одинаковые приватные копии кнопки разошлись бы на первой же правке.
library;

import 'package:flutter/material.dart';

class MechanicQuietButton extends StatelessWidget {
  const MechanicQuietButton({
    Key? key,
    required this.icon,
    required this.label,
    required this.ink,
    required this.onTap,
  }) : super(key: key);

  final IconData icon;
  final String label;
  final Color ink;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40.0,
      child: TextButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18.0),
        // Кнопок в строке бывает три, и «Приостановить» на экране 375 точек
        // в треть строки не влезает. Уменьшить подпись честнее, чем оборвать
        // её многоточием: «Приостанови…» человек читать не должен.
        label: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(label, style: const TextStyle(fontSize: 14.0)),
        ),
        style: TextButton.styleFrom(
          foregroundColor: ink,
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
        ),
      ),
    );
  }
}

/// Иконка дефекта — одна на все четыре точки входа: механик узнаёт кнопку в
/// заявке по тому, как она выглядела в карточке ТО.
const IconData mechanicDefectIcon = Icons.report_gmailerrorred_outlined;
