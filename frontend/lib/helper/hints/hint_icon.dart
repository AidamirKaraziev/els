import 'package:flutter/material.dart';

import '../class_colors.dart';
import 'hint_settings.dart';
import 'hints.dart';

/// Значок «?» с пояснением по клику.
///
/// Ненавязчив по устройству: подсказка всегда на экране, но свёрнута в
/// кружок и раскрывается только тем, кто нажал. Ни одного пикселя чужого
/// содержимого он не перекрывает и ничего не блокирует.
///
/// Почему не всплывающая подсказка по наведению: на планшетах наведения нет,
/// а именно там открывают приложение прорабы и механики. На этом фронте на
/// hover уже завязано 64 файла, и это известная проблема.
///
/// Почему не пошаговый тур: каждый шаг привязан к конкретному виджету и
/// разъезжается при первой правке вёрстки, а вёрстка здесь чужая и меняется.
class HintIcon extends StatelessWidget {
  const HintIcon({Key? key, required this.id, this.size = 16.0})
      : super(key: key);

  /// Идентификатор из `HintIds`. Текст лежит в реестре `hints`.
  final String id;
  final double size;

  @override
  Widget build(BuildContext context) {
    final Hint? hint = hints[id];
    if (hint == null) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: HintSettings.instance,
      builder: (BuildContext context, _) {
        // Выключенные подсказки прячут и значки: человек, который снял
        // галочку в профиле, просил именно этого.
        if (!HintSettings.instance.enabled) return const SizedBox.shrink();

        return Padding(
          padding: const EdgeInsets.only(left: 6.0),
          child: InkWell(
            onTap: () => _show(context, hint),
            borderRadius: BorderRadius.circular(size),
            child: Icon(
              Icons.help_outline,
              size: size,
              color: ColorApp.myColorGrayText,
            ),
          ),
        );
      },
    );
  }

  void _show(BuildContext context, Hint hint) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        title: Text(hint.title, style: const TextStyle(fontSize: 17.0)),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420.0),
          child: Text(
            hint.body,
            style: const TextStyle(fontSize: 14.0, height: 1.45),
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Понятно'),
          ),
        ],
      ),
    );
  }
}
