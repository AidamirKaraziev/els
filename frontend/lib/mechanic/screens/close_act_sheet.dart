/// Лист подтверждения «Завершить работу»: что именно уйдёт прорабу.
///
/// Отдельным файлом, потому что зовётся с двух экранов: из чек-листа, когда
/// механик дошёл до конца списка, и с карточки ТО, где кнопка «Завершить
/// работу» появляется при всех отмеченных пунктах. Это одно и то же действие,
/// и спрашивать о нём двумя разными листами значило бы показать человеку два
/// разных обещания про одну работу.
///
/// **Слово «акт» человеку не показываем.** Акт — это запись в базе; механик
/// же завершает работу, и кнопка называется так, как он сам её назвал бы.
/// В коде сущность по-прежнему акт: `finished_at`, `act-fact`, имя файла.
///
/// **Завершить работу можно и с неотмеченными пунктами.** Бэкенд этого не
/// запрещает, и мы не запрещаем: механик приехал, часть работ не сделал, и
/// заставлять его врать в чек-листе ради завершения хуже, чем показать прорабу
/// «5 из 8». Поэтому лист перечисляет, чего не хватает, а не блокирует кнопку.
library;

import 'package:flutter/material.dart';

import '../../helper/class_colors.dart';
import '../data/acts.dart';
import '../data/tasks.dart';
import '../mechanic_theme.dart';

/// Ответ листа: механик подтвердил завершение и что он к нему написал.
class CloseActChoice {
  const CloseActChoice({this.commentary});

  /// Комментарий ко всей работе — пустой, если механику нечего добавить.
  final String? commentary;
}

/// Показывает лист и возвращает выбор человека. `null` — передумал.
Future<CloseActChoice?> showCloseActSheet(
  BuildContext context, {
  required MechanicTask task,
  required ActDetails act,
  required int queuedPhotos,
  String cancelLabel = 'Вернуться к пунктам',
}) {
  return showModalBottomSheet<CloseActChoice>(
    context: context,
    isScrollControlled: true,
    backgroundColor: ColorApp.myColorWhite,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(12.0)),
    ),
    builder: (BuildContext context) => _CloseSheet(
      task: task,
      act: act,
      queuedPhotos: queuedPhotos,
      cancelLabel: cancelLabel,
    ),
  );
}

class _CloseSheet extends StatefulWidget {
  const _CloseSheet({
    required this.task,
    required this.act,
    required this.queuedPhotos,
    required this.cancelLabel,
  });

  final MechanicTask task;
  final ActDetails act;
  final int queuedPhotos;

  /// Куда человек вернётся, отказавшись: из чек-листа — к пунктам, с карточки
  /// — никуда. Обещать «вернуться к пунктам» там, где пунктов на экране нет,
  /// значит соврать в мелочи.
  final String cancelLabel;

  @override
  State<_CloseSheet> createState() => _CloseSheetState();
}

class _CloseSheetState extends State<_CloseSheet> {
  final TextEditingController _commentary = TextEditingController();

  @override
  void dispose() {
    _commentary.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ActDetails act = widget.act;
    final List<String> missing = act.steps
        .where((ActStep step) => !step.done)
        .map((ActStep step) => step.title.toLowerCase())
        .toList();

    // Лист прокручивается: неотмеченных пунктов бывает восемь, и их
    // перечисление на маленьком экране лист не вмещает. Отступ снизу — под
    // клавиатуру: поле комментария она иначе закрывает целиком.
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20.0,
          12.0,
          20.0,
          20.0 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Center(
              child: Container(
                width: 36.0,
                height: 4.0,
                decoration: BoxDecoration(
                  color: ColorApp.myColorGrayBorder,
                  borderRadius: BorderRadius.circular(2.0),
                ),
              ),
            ),
            const SizedBox(height: 14.0),
            Text(
              act.title == null ? 'Завершить работу?' : 'Завершить ${act.title}?',
              style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10.0),
            Text(
              missing.isEmpty
                  ? 'Все пункты отмечены. После этого работа уйдёт прорабу '
                      'в ленту сданных.'
                  : 'Не отмечено: ${missing.join(', ')}. После этого работа '
                      'уйдёт прорабу в ленту сданных.',
              style: const TextStyle(
                fontSize: 14.0,
                fontWeight: FontWeight.w300,
                color: Color(0xff1C1C1E),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14.0),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 14.0,
                vertical: 12.0,
              ),
              decoration: BoxDecoration(
                color: ColorApp.myColorTransparent,
                borderRadius: BorderRadius.circular(MechanicLayout.cardRadius),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _SheetLine(label: 'Объект', value: widget.task.title),
                  _SheetLine(
                    label: 'Пройдено пунктов',
                    value: progressText(act.doneCount, act.total),
                  ),
                  _SheetLine(
                    label: 'Снимков в очереди',
                    value: widget.queuedPhotos == 0
                        ? 'нет'
                        : '${widget.queuedPhotos}',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14.0),
            // Комментарий ко всей работе, а не к пункту: «менял ролики, нужен
            // повторный выезд». Необязательный — заставлять писать после
            // каждого ТО значит получить в базе тридцать строк «ок».
            TextField(
              controller: _commentary,
              minLines: 2,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              style: const TextStyle(fontSize: 14.0),
              decoration: InputDecoration(
                labelText: 'Комментарий к работе',
                hintText: 'Необязательно',
                labelStyle: const TextStyle(
                  fontSize: 14.0,
                  color: ColorApp.myColorGray,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(MechanicLayout.cardRadius),
                ),
              ),
            ),
            const SizedBox(height: 14.0),
            SizedBox(
              height: 48.0,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(
                  CloseActChoice(commentary: _commentary.text),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorApp.myColorGreenAuth,
                  foregroundColor: ColorApp.myColorWhite,
                  elevation: 0.0,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(MechanicLayout.cardRadius),
                  ),
                ),
                child: const Text(
                  'Завершить работу',
                  style: TextStyle(fontSize: 15.0),
                ),
              ),
            ),
            SizedBox(
              height: 48.0,
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  foregroundColor: ColorApp.myColorGray,
                ),
                child: Text(
                  widget.cancelLabel,
                  style: const TextStyle(fontSize: 15.0),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SheetLine extends StatelessWidget {
  const _SheetLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 130.0,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13.0,
                fontWeight: FontWeight.w300,
                color: ColorApp.myColorGray,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13.0, color: Color(0xff1C1C1E)),
            ),
          ),
        ],
      ),
    );
  }
}
