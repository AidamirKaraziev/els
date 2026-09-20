import 'package:flutter/material.dart';

import '../../../../helper/class_colors.dart';

/// Окно «Новый вид ТО» с экрана шаблонов: одно поле — название.
///
/// Вид ТО заводится у одной модели: «ТО 4» появится у неё строкой
/// «нет шаблона», у других моделей — нет. Шаблон окно не создаёт:
/// чек-лист заводят следующим кликом по строке.
///
/// Возвращает название; у модели его записывает экран. Дубль и пустое
/// окно не отдаёт — человек видит подсказку, а не сломанную кнопку.
Future<String?> showNewTypeActDialog(
  BuildContext context, {
  required String modelName,
  required List<String> existing,
}) {
  return showDialog<String>(
    context: context,
    builder: (BuildContext context) =>
        _NewTypeActDialog(modelName: modelName, existing: existing),
  );
}

class _NewTypeActDialog extends StatefulWidget {
  const _NewTypeActDialog({
    Key? key,
    required this.modelName,
    required this.existing,
  }) : super(key: key);

  /// Модель, у которой заводим вид — видна в заголовке.
  final String modelName;

  /// Виды ТО, уже заведённые у этой модели — окно само говорит про дубль.
  final List<String> existing;

  @override
  State<_NewTypeActDialog> createState() => _NewTypeActDialogState();
}

class _NewTypeActDialogState extends State<_NewTypeActDialog> {
  final TextEditingController _name = TextEditingController();

  @override
  void initState() {
    super.initState();
    _name.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  String get _value => _name.text.trim();

  /// Регистр и крайние пробелы не различаем: «то 4» и «ТО 4» — один вид.
  bool get _isDuplicate => widget.existing.any(
        (String name) => name.toLowerCase() == _value.toLowerCase(),
      );

  bool get _canAdd => _value.isNotEmpty && !_isDuplicate;

  void _add() {
    if (!_canAdd) return;
    Navigator.of(context).pop(_value);
  }

  @override
  Widget build(BuildContext context) {
    final Color border =
        _isDuplicate ? ColorApp.myColorRed : ColorApp.myColorGrayBorder;
    return AlertDialog(
      backgroundColor: ColorApp.myColorWhite,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Новый вид ТО',
            style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2.0),
          Text(
            widget.modelName,
            style: const TextStyle(
              fontSize: 13.0,
              fontWeight: FontWeight.w400,
              color: ColorApp.myColorGray,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 380.0,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'Название',
              style: TextStyle(fontSize: 13.0, color: ColorApp.myColorGray),
            ),
            const SizedBox(height: 6.0),
            TextField(
              controller: _name,
              autofocus: true,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _add(),
              style: const TextStyle(fontSize: 14.0),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Например, ТО 4',
                hintStyle: const TextStyle(
                  fontSize: 14.0,
                  color: ColorApp.myColorGrayText,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 12.0,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide(color: border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide(
                    color: _isDuplicate
                        ? ColorApp.myColorRed
                        : ColorApp.myColorGreenAuth,
                    width: 2.0,
                  ),
                ),
              ),
            ),
            if (_isDuplicate) ...<Widget>[
              const SizedBox(height: 6.0),
              const Text(
                'Такой вид ТО у этой модели уже есть.',
                style: TextStyle(fontSize: 12.0, color: ColorApp.myColorRed),
              ),
            ],
            const SizedBox(height: 16.0),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: ColorApp.myColorYellowLight,
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: ColorApp.myColorYellow),
              ),
              child: Text(
                'Вид ТО появится только у модели «${widget.modelName}» '
                'строкой «нет шаблона». Чек-лист заводится следующим '
                'кликом по строке.',
                style: const TextStyle(
                  fontSize: 13.0,
                  color: ColorApp.myColorBlack,
                ),
              ),
            ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 12.0),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(foregroundColor: ColorApp.myColorGray),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: _canAdd ? _add : null,
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
          child: const Text('Добавить'),
        ),
      ],
    );
  }
}
