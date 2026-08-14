import 'package:flutter/material.dart';

import '../class_colors.dart';
import 'hint_settings.dart';

/// Переключатель «Показывать подсказки» в профиле.
///
/// Нужен ровно для одного: вернуть карточку «С чего начать», закрытую по
/// ошибке. Без него крестик — необратимое действие, а необратимых действий в
/// интерфейсе быть не должно.
///
/// Включение возвращает все скрытые карточки разом: человек, который жмёт
/// «показывать», хочет их увидеть, а не узнать, что когда-то закрыл навсегда.
class HintsSwitch extends StatelessWidget {
  const HintsSwitch({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: HintSettings.instance,
      builder: (BuildContext context, _) {
        final bool enabled = HintSettings.instance.enabled;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
          decoration: BoxDecoration(
            color: ColorApp.myColorWhite,
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: enabled,
            activeColor: ColorApp.myColorGreenAuth,
            onChanged: (bool value) => HintSettings.instance.setEnabled(value),
            title: const Text(
              'Показывать подсказки',
              style: TextStyle(fontSize: 15.0, fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              enabled
                  ? 'Значки «?» рядом с непонятными местами и карточка '
                      '«С чего начать» на главной'
                  : 'Подсказки скрыты. Включите, чтобы вернуть их все',
              style: const TextStyle(
                fontSize: 12.0,
                color: ColorApp.myColorGrayText,
              ),
            ),
          ),
        );
      },
    );
  }
}
