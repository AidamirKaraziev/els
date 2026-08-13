import 'package:flutter/material.dart';

import '../../../helper/class_colors.dart';

/// Выбор года при создании графика ТО.
///
/// Раньше год был записан в кнопке строкой `'2025'`, одинаково на админском и
/// прорабском экранах. График на любой другой год из приложения создать было
/// нельзя, а статистика на главной ищет записи ровно за выбранный месяц и год —
/// и в 2026-м не находила ничего.
///
/// Возвращает год строкой (`planned_to.year` — строковая колонка) или `null`,
/// если человек закрыл диалог.
Future<String?> pickScheduleYear(BuildContext context) {
  final int current = DateTime.now().year;
  // Прошлый год нужен, чтобы дозаполнить график задним числом, следующий —
  // чтобы завести его заранее в декабре.
  final List<int> years = <int>[current - 1, current, current + 1];

  return showDialog<String>(
    context: context,
    builder: (BuildContext context) => AlertDialog(
      title: const Text('На какой год создать график?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: years
            .map(
              (int year) => ListTile(
                title: Text('$year'),
                trailing: year == current
                    ? const Text(
                        'текущий',
                        style: TextStyle(
                          fontSize: 12.0,
                          color: ColorApp.myColorGrayText,
                        ),
                      )
                    : null,
                onTap: () => Navigator.of(context).pop('$year'),
              ),
            )
            .toList(growable: false),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Отмена'),
        ),
      ],
    ),
  );
}
