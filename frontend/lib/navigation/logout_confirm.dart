import 'package:flutter/material.dart';

import '../helper/class_colors.dart';

/// Спросить, точно ли выходить. `true` — выходим.
///
/// Раньше «Выйти» разлогинивал с первого тапа: пункт стоит последним, и
/// промахнуться по нему с «Сотрудников» было легко.
Future<bool> confirmLogout(BuildContext context) async {
  final bool? answer = await showDialog<bool>(
    context: context,
    builder: (BuildContext context) => AlertDialog(
      backgroundColor: ColorApp.myColorWhite,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      title: const Text(
        'Выйти из приложения?',
        style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.w700),
      ),
      content: const Text(
        'Для входа снова понадобятся логин и пароль.',
        style: TextStyle(fontSize: 14.0, color: ColorApp.myColorGray),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 12.0),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          style: TextButton.styleFrom(foregroundColor: ColorApp.myColorGray),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: ColorApp.myColorGreenAuth,
            foregroundColor: ColorApp.myColorWhite,
            elevation: 0.0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.0),
            ),
          ),
          child: const Text('Выйти'),
        ),
      ],
    ),
  );
  return answer ?? false;
}
