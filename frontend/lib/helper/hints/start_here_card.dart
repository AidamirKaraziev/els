import 'package:flutter/material.dart';

import '../class_colors.dart';
import '../session.dart';
import 'hint_settings.dart';
import 'hints.dart';

/// Карточка «С чего начать» на главной.
///
/// То, что реально снимает растерянность первого входа: значки «?» помогают
/// тому, кто уже понял, о чём спросить, а новичок не знает, чего он не знает.
///
/// Закрывается крестиком навсегда и не показывается снова. Вернуть её можно
/// переключателем «Показывать подсказки» в профиле — закрыть случайно и
/// остаться без объяснений человек не должен.
///
/// Не модальное окно при входе: такие закрывают не читая.
class StartHereCard extends StatelessWidget {
  const StartHereCard({Key? key, this.roleId}) : super(key: key);

  /// Роль, для которой берётся текст. По умолчанию — вошедшего.
  final int? roleId;

  /// Идентификатор скрытия свой у каждой роли: человек, сменивший роль,
  /// увидит новый текст, а не пустоту от прошлого закрытия.
  String _dismissId(int role) => 'start_here.$role';

  @override
  Widget build(BuildContext context) {
    final int role = roleId ?? idUserTest;
    final StartHereContent? content = startHereFor(role);
    if (content == null) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: HintSettings.instance,
      builder: (BuildContext context, _) {
        if (!HintSettings.instance.shows(_dismissId(role))) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 16.0),
          padding: const EdgeInsets.fromLTRB(16.0, 14.0, 8.0, 14.0),
          decoration: BoxDecoration(
            color: ColorApp.myColorGreenLine,
            borderRadius: BorderRadius.circular(10.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  const Icon(
                    Icons.lightbulb_outline,
                    size: 18.0,
                    color: ColorApp.myColorGreenAuth,
                  ),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: Text(
                      content.title,
                      style: const TextStyle(
                        fontSize: 15.0,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Больше не показывать',
                    onPressed: () =>
                        HintSettings.instance.dismiss(_dismissId(role)),
                    icon: const Icon(Icons.close, size: 18.0),
                    splashRadius: 18.0,
                  ),
                ],
              ),
              const SizedBox(height: 4.0),
              ...content.steps.map(
                (String step) => Padding(
                  padding: const EdgeInsets.only(right: 8.0, bottom: 6.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Padding(
                        padding: EdgeInsets.only(top: 6.0, right: 8.0),
                        child: Icon(
                          Icons.circle,
                          size: 5.0,
                          color: ColorApp.myColorGreenAuth,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          step,
                          style: const TextStyle(fontSize: 13.0, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
