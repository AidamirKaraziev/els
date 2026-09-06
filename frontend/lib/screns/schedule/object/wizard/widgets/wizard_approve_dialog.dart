import 'package:flutter/material.dart';

import '../../../../../helper/class_colors.dart';

/// Подтверждение перед созданием графика.
///
/// Мастер живёт в одном окне: человек видит ленту года целиком и утверждает
/// её одной кнопкой. Раньше между ним и записью в базу стоял второй шаг —
/// теперь не стоит ничего, и последнее движение должно спрашивать.
///
/// Расстановку окно не пересказывает намеренно: что легло по месяцам, видно
/// в ленте за ним, а второй пересказ тех же двенадцати клеток человек всё
/// равно не читает — он жмёт «Да».
///
/// Возвращает `true`, только если нажали «Да»: закрытие мимо окна и «Назад»
/// дают `false`.
Future<bool> showWizardApproveDialog(
  BuildContext context, {
  required int year,
}) async {
  final bool? approved = await showDialog<bool>(
    context: context,
    builder: (BuildContext context) => _WizardApproveDialog(year: year),
  );
  return approved ?? false;
}

class _WizardApproveDialog extends StatelessWidget {
  const _WizardApproveDialog({Key? key, required this.year}) : super(key: key);

  final int year;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: ColorApp.myColorWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      title: Text(
        'Создать график на $year год?',
        style: const TextStyle(
          fontSize: 17.0,
          fontWeight: FontWeight.w600,
          color: ColorApp.myColorBlack,
        ),
      ),
      content: const Text(
        'Сверьтесь с лентой: виды ТО должны стоять по тем месяцам, по которым '
        'вы их расставили. График создастся сразу для этого объекта.',
        style: TextStyle(fontSize: 14.0, color: ColorApp.myColorGray),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 12.0),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          style: TextButton.styleFrom(
            foregroundColor: ColorApp.myColorGray,
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
          ),
          child: const Text('Назад'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: ColorApp.myColorGreenAuth,
            foregroundColor: ColorApp.myColorWhite,
            elevation: 0.0,
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 12.0,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
          child: const Text('Да'),
        ),
      ],
    );
  }
}
