import 'package:flutter/material.dart';

import 'class_colors.dart';

/// Пустой список — это нормальное состояние, а не сбой загрузки.
///
/// После того как выдача стала резаться по области видимости, пустые списки
/// перестали быть редкостью: механик видит только свои назначения, клиент —
/// только лифты своей компании, прораб без участка не видит ничего. Раньше на
/// пустом ответе экран показывал просто серое поле, и человек читал это как
/// «не загрузилось» — и шёл жаловаться, что данные пропали.
class EmptyList extends StatelessWidget {
  const EmptyList({
    Key? key,
    required this.title,
    this.hint,
    this.icon = Icons.inbox_outlined,
  }) : super(key: key);

  /// Что именно пусто — «Объектов нет», «Заявок нет».
  final String title;

  /// Почему пусто и что с этим делать. Необязательно, но чаще всего нужно:
  /// без объяснения человек считает пустой экран поломкой.
  final String? hint;

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48.0, color: ColorApp.myColorAvatar),
            const SizedBox(height: 16.0),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.w600,
                color: ColorApp.myColorGray,
              ),
            ),
            if (hint != null) ...[
              const SizedBox(height: 8.0),
              SizedBox(
                width: 360.0,
                child: Text(
                  hint!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: ColorApp.myColorGrayText),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
