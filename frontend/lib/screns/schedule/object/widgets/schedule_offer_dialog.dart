import 'package:flutter/material.dart';

import '../../../../helper/class_colors.dart';

/// Предложение расставить график сразу после создания объекта.
///
/// Объект заводят в одном месте, а график ему расставляют в другом — на
/// экране «График объекта» кнопкой «Создать график на N». Между двумя
/// действиями человек уходит по своим делам, и объект остаётся без графика
/// ТО, ничем об этом не напоминая. Диалог закрывает разрыв: спрашиваем сразу
/// после сохранения и ведём в тот же мастер расстановки.
///
/// Отказ ничего не ломает и потому не пугает: «Позже» просто закрывает окно,
/// график заводится из окна графика, и подпись под кнопками об этом говорит.
///
/// Кадра в Figma на диалог нет, рисовали сами — в стиле окна правки программы
/// мастера: та же палитра, скругление 12 у окна и 8 у кнопок, зелёный на
/// главном действии.
Future<bool?> showScheduleOfferDialog(
  BuildContext context, {
  required String objectName,
  required int year,
}) {
  return showDialog<bool>(
    context: context,
    builder: (BuildContext context) => ScheduleOfferDialog(
      objectName: objectName,
      year: year,
    ),
  );
}

class ScheduleOfferDialog extends StatelessWidget {
  const ScheduleOfferDialog({
    Key? key,
    required this.objectName,
    required this.year,
  }) : super(key: key);

  /// Название только что созданного объекта. Пустое — говорим «объекту» без
  /// имени: пустая пара кавычек в тексте выглядела бы ошибкой.
  final String objectName;

  /// Год, на который предлагаем график. Текущий — как и лента по умолчанию.
  final int year;

  @override
  Widget build(BuildContext context) {
    final String name = objectName.trim();

    return AlertDialog(
      backgroundColor: ColorApp.myColorWhite,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      title: const Text(
        'Расставить график ТО?',
        style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.w700),
      ),
      content: SizedBox(
        // Окно узкое: в нём один вопрос и две кнопки, и ширина формы объекта
        // обещала бы глазу продолжение, которого нет.
        width: 420.0,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 14.0,
                  height: 1.4,
                  color: ColorApp.myColorBlack,
                ),
                children: <InlineSpan>[
                  const TextSpan(text: 'Объект '),
                  if (name.isNotEmpty)
                    TextSpan(
                      text: '«$name» ',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  TextSpan(text: 'создан. Плановых ТО на $year год у него '),
                  const TextSpan(text: 'ещё нет.'),
                ],
              ),
            ),
            const SizedBox(height: 12.0),
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: ColorApp.myColorGrayShadow,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: const Text(
                'Мастер спросит программу модели и месяц начала цикла, '
                'а год расставит сам.\n'
                'Отказ ничего не ломает: график заводится позже из окна '
                'графика объекта.',
                style: TextStyle(
                  fontSize: 13.0,
                  height: 1.4,
                  color: ColorApp.myColorGray,
                ),
              ),
            ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 8.0),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          style: TextButton.styleFrom(foregroundColor: ColorApp.myColorGray),
          child: const Text('Позже'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: ElevatedButton.styleFrom(
            backgroundColor: ColorApp.myColorGreenAuth,
            foregroundColor: ColorApp.myColorWhite,
            elevation: 0.0,
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 14.0,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
          child: const Text('Расставить'),
        ),
      ],
    );
  }
}
