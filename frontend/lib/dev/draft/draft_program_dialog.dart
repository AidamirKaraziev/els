import 'package:flutter/material.dart';

import '../../helper/class_colors.dart';
import 'draft_program_data.dart';

/// Окно «Программа модели» — набросок на утверждение.
///
/// Открывается со страницы предпросмотра: программу либо создают с нуля,
/// либо правят. Своей логики нет — ни `/suggestion`, ни `PUT`: окно
/// возвращает исправленную программу вызвавшему, а тот держит её в памяти.
///
/// Кадра в Figma на это окно нет, рисовали сами — в стиле принятых блоков
/// экрана объекта: та же палитра, те же скругления 8, тот же зелёный на
/// главном действии.
Future<DraftProgram?> showDraftProgramDialog(
  BuildContext context, {
  DraftProgram? program,
  required String modelName,
  required List<String> typeActs,
  required void Function(String) onTypeActAdded,
}) {
  return showDialog<DraftProgram>(
    context: context,
    builder: (BuildContext context) => _DraftProgramDialog(
      program: program,
      modelName: modelName,
      typeActs: typeActs,
      onTypeActAdded: onTypeActAdded,
    ),
  );
}

class _DraftProgramDialog extends StatefulWidget {
  const _DraftProgramDialog({
    Key? key,
    this.program,
    required this.modelName,
    required this.typeActs,
    required this.onTypeActAdded,
  }) : super(key: key);

  /// `null` — программы у модели ещё нет, окно открыто на создание.
  final DraftProgram? program;

  /// Марка и модель лифта из объекта — начало названия, правке не подлежит.
  final String modelName;

  final List<String> typeActs;

  /// Новый вид ТО заводится в справочник, а не только в эту программу:
  /// список общий на всё приложение.
  final void Function(String) onTypeActAdded;

  @override
  State<_DraftProgramDialog> createState() => _DraftProgramDialogState();
}

class _DraftProgramDialogState extends State<_DraftProgramDialog> {
  late final bool _isNew = widget.program == null;

  /// Копия программы: «Отмена» должна возвращать всё как было, а править
  /// оригинал и откатывать назад — это хранить две версии вместо одной.
  late final DraftProgram _draft = widget.program?.copy() ??
      DraftProgram(
        modelName: widget.modelName,
        positions: List<String>.filled(12, ''),
      );

  late final TextEditingController _note =
      TextEditingController(text: _draft.note);

  /// Справочник видов ТО в этом окне. Своя копия нужна потому, что заводят
  /// вид не закрывая окна: страница за спиной пересобирает свой список, но
  /// открытое окно об этом не узнаёт — и новый вид не появился бы в выборе
  /// позиции до перезакрытия.
  late List<String> _typeActs = List<String>.of(widget.typeActs);

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  void _reorder(int oldIndex, int newIndex) {
    setState(() {
      final String moved = _draft.positions.removeAt(oldIndex);
      _draft.positions.insert(newIndex, moved);
    });
  }

  Future<void> _addTypeAct() async {
    final String? name = await showDialog<String>(
      context: context,
      builder: (BuildContext context) =>
          _NewTypeActDialog(typeActs: _typeActs),
    );
    if (name == null || name.isEmpty) return;
    widget.onTypeActAdded(name);
    setState(() => _typeActs = <String>[..._typeActs, name]);
  }

  void _save() {
    _draft.note = _note.text.trim();
    Navigator.of(context).pop(_draft);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: ColorApp.myColorWhite,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      insetPadding: const EdgeInsets.all(24.0),
      child: ConstrainedBox(
        // Двенадцать позиций в две колонки на широком экране и в одну на
        // узком; выше 640 окно не растёт — дальше список прокручивается.
        constraints: const BoxConstraints(maxWidth: 640.0, maxHeight: 720.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _Header(isNew: _isNew),
            const Divider(height: 1.0, color: ColorApp.myColorGrayBorder),
            Flexible(
              // Прокручивается сам список позиций, а поля и примечание едут
              // его шапкой и подвалом. Обёртка списка в отдельную прокрутку
              // глушила бы колесо мыши над позициями — а это большая часть
              // окна, и над ней колесо не должно быть мёртвым.
              child: ReorderableListView.builder(
                padding: const EdgeInsets.all(20.0),
                buildDefaultDragHandles: false,
                header: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const _FieldLabel('Название программы'),
                    const SizedBox(height: 6.0),
                    _NameField(
                      modelName: _draft.modelName,
                      controller: _note,
                    ),
                    const SizedBox(height: 20.0),
                    const _FieldLabel('Цикл обслуживания'),
                    const SizedBox(height: 4.0),
                    const Text(
                      'Двенадцать позиций подряд. Позицию можно перетащить '
                      'за ручку слева — так меняется порядок видов ТО внутри '
                      'цикла. На какой месяц придётся первая позиция, '
                      'решается уже в предпросмотре.',
                      style: TextStyle(
                        fontSize: 13.0,
                        color: ColorApp.myColorGray,
                      ),
                    ),
                    const SizedBox(height: 12.0),
                  ],
                ),
                footer: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const SizedBox(height: 4.0),
                    TextButton.icon(
                      onPressed: _addTypeAct,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        foregroundColor: ColorApp.myColorGreenAuth,
                        minimumSize: const Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      icon: const Icon(Icons.add, size: 18.0),
                      label: const Text('Добавить вид ТО'),
                    ),
                    const SizedBox(height: 20.0),
                    const _ModelWideNote(),
                  ],
                ),
                itemCount: _draft.positions.length,
                onReorderItem: _reorder,
                itemBuilder: (BuildContext context, int index) {
                  return _PositionRow(
                    key: ValueKey<int>(index),
                    index: index,
                    value: _draft.positions[index],
                    typeActs: _typeActs,
                    onChanged: (String value) =>
                        setState(() => _draft.positions[index] = value),
                  );
                },
              ),
            ),
            const Divider(height: 1.0, color: ColorApp.myColorGrayBorder),
            _Bottom(
              canSave: !_draft.hasEmptyPosition,
              disabledReason: _draft.hasEmptyPosition
                  ? 'У каждой позиции цикла должен быть выбран вид ТО'
                  : null,
              onCancel: () => Navigator.of(context).pop(),
              onSave: _save,
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({Key? key, required this.isNew}) : super(key: key);

  final bool isNew;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20.0, 20.0, 12.0, 16.0),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              isNew ? 'Создание программы модели' : 'Программа модели',
              style: const TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close, size: 20.0),
            color: ColorApp.myColorGray,
            splashRadius: 20.0,
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text, {Key? key}) : super(key: key);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 15.0, fontWeight: FontWeight.w600),
    );
  }
}

/// Название программы: марка с моделью из объекта плюс свободное дополнение.
///
/// Марка и модель не правятся — они и есть ответ на вопрос «чья это
/// программа». Дописать к ним можно что угодно: «после капремонта»,
/// «подъезды 3–4». Пустое дополнение — название остаётся одной маркой.
class _NameField extends StatelessWidget {
  const _NameField({
    Key? key,
    required this.modelName,
    required this.controller,
  }) : super(key: key);

  final String modelName;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: ColorApp.myColorGrayBorder),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12.0,
                  vertical: 12.0,
                ),
                decoration: const BoxDecoration(
                  color: ColorApp.myColorGrayShadow,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(7.0),
                    bottomLeft: Radius.circular(7.0),
                  ),
                ),
                child: Text(
                  modelName,
                  style: const TextStyle(
                    fontSize: 14.0,
                    fontWeight: FontWeight.w600,
                    color: ColorApp.myColorBlack,
                  ),
                ),
              ),
              const Text(
                ' — ',
                style: TextStyle(fontSize: 14.0, color: ColorApp.myColorGrayText),
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  style: const TextStyle(fontSize: 14.0),
                  decoration: const InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    hintText: 'дополнение, если нужно',
                    hintStyle: TextStyle(
                      fontSize: 14.0,
                      color: ColorApp.myColorGrayText,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 4.0,
                      vertical: 12.0,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6.0),
        const Text(
          'Марка и модель подтянуты из объекта и не правятся — дописать можно '
          'что угодно после них.',
          style: TextStyle(fontSize: 12.0, color: ColorApp.myColorGray),
        ),
      ],
    );
  }
}

class _PositionRow extends StatelessWidget {
  const _PositionRow({
    Key? key,
    required this.index,
    required this.value,
    required this.typeActs,
    required this.onChanged,
  }) : super(key: key);

  final int index;
  final String value;
  final List<String> typeActs;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final bool empty = value.isEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: <Widget>[
          ReorderableDragStartListener(
            index: index,
            child: const MouseRegion(
              cursor: SystemMouseCursors.grab,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.0),
                child: Icon(
                  Icons.drag_indicator,
                  size: 20.0,
                  color: ColorApp.myColorGrayText,
                ),
              ),
            ),
          ),
          // Номер позиции, а не месяц: цикл не обязан начинаться с января, и
          // подписывать позицию месяцем здесь значило бы врать.
          SizedBox(
            width: 32.0,
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                fontSize: 13.0,
                color: ColorApp.myColorGrayText,
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 40.0,
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              decoration: BoxDecoration(
                color: ColorApp.myColorWhite,
                border: Border.all(
                  color: empty
                      ? ColorApp.myColorRed
                      : ColorApp.myColorGrayBorder,
                ),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: empty ? null : value,
                  isExpanded: true,
                  hint: const Text(
                    'вид ТО не выбран',
                    style: TextStyle(fontSize: 14.0, color: ColorApp.myColorRed),
                  ),
                  icon: const Icon(Icons.expand_more, size: 20.0),
                  style: const TextStyle(
                    fontSize: 14.0,
                    color: ColorApp.myColorBlack,
                  ),
                  items: <DropdownMenuItem<String>>[
                    for (final String name in typeActs)
                      DropdownMenuItem<String>(
                        value: name,
                        child: Text(name),
                      ),
                  ],
                  onChanged: (String? name) {
                    if (name != null) onChanged(name);
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Программа принадлежит модели, а не лифту. Сказать это надо в окне правки,
/// а не где-то рядом: человек открыл его с графика одного объекта и по
/// умолчанию думает, что правит именно этот объект.
class _ModelWideNote extends StatelessWidget {
  const _ModelWideNote({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: ColorApp.myColorYellowLight,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: ColorApp.myColorYellow),
      ),
      child: const Text(
        'Программа принадлежит модели: правка касается всех объектов этой '
        'модели, а не только текущего.',
        style: TextStyle(fontSize: 13.0, color: ColorApp.myColorBlack),
      ),
    );
  }
}

class _Bottom extends StatelessWidget {
  const _Bottom({
    Key? key,
    required this.canSave,
    this.disabledReason,
    required this.onCancel,
    required this.onSave,
  }) : super(key: key);

  final bool canSave;
  final String? disabledReason;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    Widget primary = ElevatedButton(
      onPressed: canSave ? onSave : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: ColorApp.myColorGreenAuth,
        foregroundColor: ColorApp.myColorWhite,
        elevation: 0.0,
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 14.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
      child: const Text('Сохранить'),
    );
    if (!canSave && disabledReason != null) {
      primary = Tooltip(message: disabledReason!, child: primary);
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: <Widget>[
          TextButton(
            onPressed: onCancel,
            style: TextButton.styleFrom(
              foregroundColor: ColorApp.myColorGray,
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 14.0,
              ),
            ),
            child: const Text('Отмена'),
          ),
          const Spacer(),
          primary,
        ],
      ),
    );
  }
}

/// Окно «Новый вид ТО» — набросок на утверждение.
///
/// Маленькое окно поверх окна программы: одно поле — название. Перечень
/// работ чек-листа и копия шаблона другого вида сюда не встают: вид ТО
/// заводят посреди правки программы, и длинная форма здесь сбивает с того,
/// зачем окно открыли. Чек-лист — отдельным экраном справочника.
///
/// Логики нет: окно возвращает название вызвавшему, а тот дописывает его в
/// справочник, живущий в памяти страницы.
class _NewTypeActDialog extends StatefulWidget {
  const _NewTypeActDialog({Key? key, required this.typeActs}) : super(key: key);

  /// Уже заведённые виды ТО — нужны, чтобы окно само сказало про дубль.
  /// Молча проглоченное повторное имя выглядит как сломанная кнопка.
  final List<String> typeActs;

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

  /// Регистр и крайние пробелы не различаем: «то 4» и «ТО 4» — один вид,
  /// и справочник с обоими сразу читается как ошибка ввода.
  bool get _isDuplicate => widget.typeActs.any(
        (String name) => name.toLowerCase() == _value.toLowerCase(),
      );

  bool get _canAdd => _value.isNotEmpty && !_isDuplicate;

  void _add() {
    if (!_canAdd) return;
    Navigator.of(context).pop(_value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: ColorApp.myColorWhite,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      title: const Text(
        'Новый вид ТО',
        style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.w700),
      ),
      content: SizedBox(
        // Окно узкое: поле одно, и растягивать его на ширину окна программы
        // значило бы обещать глазу форму, которой здесь нет.
        width: 380.0,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const _FieldLabel('Название'),
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
                  borderSide: BorderSide(
                    color: _isDuplicate
                        ? ColorApp.myColorRed
                        : ColorApp.myColorGrayBorder,
                  ),
                ),
                // Дубль набирают, не выходя из поля, поэтому красной должна
                // быть и рамка в фокусе — иначе подсветки не видно вовсе.
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
                'Такой вид ТО уже есть — выберите его в позиции цикла.',
                style: TextStyle(fontSize: 12.0, color: ColorApp.myColorRed),
              ),
            ],
            const SizedBox(height: 16.0),
            const _SharedBookNote(),
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

/// Вид ТО живёт в общем справочнике, а не внутри этой программы. Сказать это
/// надо здесь же: окно открыто из правки одной программы, и без подписи
/// человек ждёт, что новый вид дальше этой программы не уйдёт.
class _SharedBookNote extends StatelessWidget {
  const _SharedBookNote({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: ColorApp.myColorYellowLight,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: ColorApp.myColorYellow),
      ),
      child: const Text(
        'Вид ТО заводится в общий справочник: он станет доступен всем '
        'программам, а не только этой. В позицию цикла его нужно выбрать '
        'отдельно.',
        style: TextStyle(fontSize: 13.0, color: ColorApp.myColorBlack),
      ),
    );
  }
}
