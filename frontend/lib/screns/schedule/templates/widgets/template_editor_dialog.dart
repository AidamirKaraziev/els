import 'package:flutter/material.dart';

import '../../../../helper/class_colors.dart';
import '../models/checklist_template.dart';
import '../repository/templates_repository.dart';

/// Окно «Шаблон ТО»: плоский список шагов чек-листа для пары модель × вид.
///
/// Открывается строкой вида ТО на экране «Шаблоны ТО» — шаблон либо создают
/// с нуля, либо правят. Шаги — строки без вложенности; порядок меняется
/// перетаскиванием за ручку, шаг убирается крестиком. «Скопировать из…»
/// подставляет шаги чужого шаблона вместо текущих.
///
/// Сохраняет не окно, а экран: окно возвращает список шагов, экран зовёт
/// репозиторий и перечитывает список. Так окно ничего не знает о том, куда
/// уходит результат, и одинаково живёт на фикстуре и на живом API.
///
/// Кадра в Figma на это окно нет, рисовали сами — в стиле окна программы
/// модели: та же палитра, те же скругления, тот же зелёный на главном
/// действии.
Future<List<String>?> showTemplateEditorDialog(
  BuildContext context, {
  required TemplatesRepository repository,
  required TemplateModel model,
  required TemplateTypeAct typeAct,
}) {
  return showDialog<List<String>>(
    context: context,
    builder: (BuildContext context) => _TemplateEditorDialog(
      repository: repository,
      model: model,
      typeAct: typeAct,
    ),
  );
}

class _TemplateEditorDialog extends StatefulWidget {
  const _TemplateEditorDialog({
    Key? key,
    required this.repository,
    required this.model,
    required this.typeAct,
  }) : super(key: key);

  final TemplatesRepository repository;
  final TemplateModel model;
  final TemplateTypeAct typeAct;

  @override
  State<_TemplateEditorDialog> createState() => _TemplateEditorDialogState();
}

class _TemplateEditorDialogState extends State<_TemplateEditorDialog> {
  /// Контроллеры по одному на шаг; ключ строки — сам контроллер, чтобы при
  /// перетаскивании текст ехал вместе со строкой, а не оставался на месте.
  final List<TextEditingController> _steps = <TextEditingController>[];

  @override
  void initState() {
    super.initState();
    for (final String step in widget.typeAct.steps) {
      _steps.add(TextEditingController(text: step));
    }
    // Новый шаблон открывается с одной пустой строкой: пустой список не
    // подсказывает, что здесь вообще надо делать.
    if (_steps.isEmpty) _steps.add(TextEditingController());
    for (final TextEditingController c in _steps) {
      c.addListener(_onChanged);
    }
  }

  @override
  void dispose() {
    for (final TextEditingController c in _steps) {
      c.dispose();
    }
    super.dispose();
  }

  void _onChanged() => setState(() {});

  bool get _hasEmpty =>
      _steps.any((TextEditingController c) => c.text.trim().isEmpty);

  bool get _canSave => _steps.isNotEmpty && !_hasEmpty;

  String? get _disabledReason {
    if (_steps.isEmpty) return 'Добавьте хотя бы один шаг';
    if (_hasEmpty) return 'Есть пустой шаг — заполните или уберите его';
    return null;
  }

  void _add() {
    final TextEditingController c = TextEditingController()
      ..addListener(_onChanged);
    setState(() => _steps.add(c));
  }

  /// Убрать контроллер после кадра: поле ещё стоит в дереве и на своём
  /// снятии отписывается от контроллера — отпущенный раньше, он на этом
  /// падает.
  void _disposeLater(Iterable<TextEditingController> controllers) {
    final List<TextEditingController> gone = controllers.toList();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final TextEditingController c in gone) {
        c.dispose();
      }
    });
  }

  void _remove(int index) {
    final TextEditingController c = _steps[index];
    setState(() => _steps.removeAt(index));
    _disposeLater(<TextEditingController>[c]);
  }

  void _reorder(int oldIndex, int newIndex) {
    setState(() {
      final TextEditingController c = _steps.removeAt(oldIndex);
      _steps.insert(newIndex, c);
    });
  }

  Future<void> _copyFrom() async {
    final List<TemplateSource> all = await widget.repository.sources();
    if (!mounted) return;
    // Свой шаблон копировать в самого себя незачем.
    final List<TemplateSource> sources = all
        .where(
          (TemplateSource s) =>
              s.modelName != widget.model.name ||
              s.typeActName != widget.typeAct.typeActName,
        )
        .toList();

    final TemplateSource? picked = await showDialog<TemplateSource>(
      context: context,
      builder: (BuildContext context) => _CopySourceDialog(sources: sources),
    );
    if (picked == null || !mounted) return;

    final int filled =
        _steps.where((TextEditingController c) => c.text.trim().isNotEmpty).length;
    if (filled > 0) {
      final bool? ok = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
          title: const Text('Заменить шаги?'),
          content: Text(
            'Текущие шаги ($filled) будут заменены шагами шаблона '
            '«${picked.modelName} · ${picked.typeActName}».',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: TextButton.styleFrom(foregroundColor: ColorApp.myColorGray),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: ColorApp.myColorGreenAuth,
              ),
              child: const Text('Заменить'),
            ),
          ],
        ),
      );
      if (ok != true || !mounted) return;
    }

    _disposeLater(_steps);
    setState(() {
      _steps
        ..clear()
        ..addAll(
          picked.steps.map(
            (String s) => TextEditingController(text: s)..addListener(_onChanged),
          ),
        );
    });
  }

  void _save() {
    Navigator.of(context).pop(
      <String>[for (final TextEditingController c in _steps) c.text.trim()],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: ColorApp.myColorWhite,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      insetPadding: const EdgeInsets.all(24.0),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640.0, maxHeight: 720.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _Header(
              isNew: !widget.typeAct.hasTemplate,
              typeActName: widget.typeAct.typeActName,
              modelName: widget.model.name,
            ),
            const Divider(height: 1.0, color: ColorApp.myColorGrayBorder),
            Flexible(child: _content()),
            const Divider(height: 1.0, color: ColorApp.myColorGrayBorder),
            _Bottom(
              canSave: _canSave,
              disabledReason: _disabledReason,
              onCancel: () => Navigator.of(context).pop(),
              onSave: _save,
            ),
          ],
        ),
      ),
    );
  }

  Widget _content() {
    // Прокручивается сам список шагов, а подпись и кнопки едут его шапкой и
    // подвалом — колесо мыши над шагами не должно быть мёртвым. `shrinkWrap`:
    // новый шаблон с одной строкой не должен растягивать окно до потолка.
    return ReorderableListView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.all(20.0),
      buildDefaultDragHandles: false,
      header: const Padding(
        padding: EdgeInsets.only(bottom: 12.0),
        child: Text(
          'Шаги чек-листа по порядку, без подпунктов. Порядок меняется '
          'перетаскиванием за ручку слева; механик увидит шаги в акте '
          'именно так.',
          style: TextStyle(fontSize: 13.0, color: ColorApp.myColorGray),
        ),
      ),
      footer: Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: Wrap(
          spacing: 16.0,
          runSpacing: 8.0,
          children: <Widget>[
            _FooterAction(
              icon: Icons.add,
              label: 'Добавить шаг',
              onPressed: _add,
            ),
            _FooterAction(
              icon: Icons.content_copy_outlined,
              label: 'Скопировать из…',
              onPressed: _copyFrom,
            ),
          ],
        ),
      ),
      itemCount: _steps.length,
      onReorderItem: _reorder,
      itemBuilder: (BuildContext context, int index) {
        return _StepRow(
          key: ObjectKey(_steps[index]),
          index: index,
          controller: _steps[index],
          onRemove: () => _remove(index),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    Key? key,
    required this.isNew,
    required this.typeActName,
    required this.modelName,
  }) : super(key: key);

  final bool isNew;
  final String typeActName;
  final String modelName;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20.0, 20.0, 12.0, 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  isNew ? 'Новый шаблон $typeActName' : 'Шаблон $typeActName',
                  style: const TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4.0),
                Text(
                  modelName,
                  style: const TextStyle(
                    fontSize: 14.0,
                    color: ColorApp.myColorGray,
                  ),
                ),
              ],
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

/// Одна строка шага: номер, ручка перетаскивания, поле, крестик.
class _StepRow extends StatelessWidget {
  const _StepRow({
    Key? key,
    required this.index,
    required this.controller,
    required this.onRemove,
  }) : super(key: key);

  final int index;
  final TextEditingController controller;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final bool empty = controller.text.trim().isEmpty;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 28.0,
            child: Text(
              '${index + 1}.',
              style: const TextStyle(
                fontSize: 14.0,
                color: ColorApp.myColorGrayText,
              ),
            ),
          ),
          ReorderableDragStartListener(
            index: index,
            child: const MouseRegion(
              cursor: SystemMouseCursors.grab,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
                child: Icon(
                  Icons.drag_handle,
                  size: 20.0,
                  color: ColorApp.myColorGrayText,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8.0),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: ColorApp.myColorWhite,
                border: Border.all(
                  color: empty ? ColorApp.myColorRed : ColorApp.myColorGrayBorder,
                ),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: TextField(
                controller: controller,
                style: const TextStyle(
                  fontSize: 14.0,
                  color: ColorApp.myColorBlack,
                ),
                decoration: const InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  hintText: 'Что проверить',
                  hintStyle: TextStyle(color: ColorApp.myColorGrayText),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12.0,
                    vertical: 12.0,
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(Icons.close, size: 18.0),
            color: ColorApp.myColorGrayText,
            splashRadius: 18.0,
            tooltip: 'Убрать шаг',
          ),
        ],
      ),
    );
  }
}

class _FooterAction extends StatelessWidget {
  const _FooterAction({
    Key? key,
    required this.icon,
    required this.label,
    required this.onPressed,
  }) : super(key: key);

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero,
        foregroundColor: ColorApp.myColorGreenAuth,
        minimumSize: const Size(0, 0),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      icon: Icon(icon, size: 18.0),
      label: Text(label),
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

/// Окно «Скопировать из…»: чужие шаблоны списком, один клик — выбор.
class _CopySourceDialog extends StatelessWidget {
  const _CopySourceDialog({Key? key, required this.sources}) : super(key: key);

  final List<TemplateSource> sources;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: ColorApp.myColorWhite,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      insetPadding: const EdgeInsets.all(24.0),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420.0, maxHeight: 560.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(20.0, 20.0, 12.0, 12.0),
              child: Row(
                children: <Widget>[
                  const Expanded(
                    child: Text(
                      'Скопировать шаги из',
                      style: TextStyle(
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
            ),
            const Divider(height: 1.0, color: ColorApp.myColorGrayBorder),
            Flexible(
              child: sources.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text(
                        'Других шаблонов пока нет',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14.0,
                          color: ColorApp.myColorGray,
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: sources.length,
                      separatorBuilder: (_, __) => const Divider(
                        height: 1.0,
                        color: ColorApp.myColorGrayBorder,
                      ),
                      itemBuilder: (BuildContext context, int index) {
                        final TemplateSource s = sources[index];
                        return ListTile(
                          onTap: () => Navigator.of(context).pop(s),
                          title: Text(
                            '${s.modelName} · ${s.typeActName}',
                            style: const TextStyle(
                              fontSize: 14.0,
                              color: ColorApp.myColorBlack,
                            ),
                          ),
                          subtitle: Text(
                            stepsLabel(s.steps.length),
                            style: const TextStyle(
                              fontSize: 13.0,
                              color: ColorApp.myColorGray,
                            ),
                          ),
                          trailing: const Icon(
                            Icons.chevron_right,
                            color: ColorApp.myColorGrayText,
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// «1 шаг», «3 шага», «12 шагов» — нужно и списку шаблонов.
String stepsLabel(int n) {
  final int mod10 = n % 10;
  final int mod100 = n % 100;
  if (mod10 == 1 && mod100 != 11) return '$n шаг';
  if (mod10 >= 2 && mod10 <= 4 && (mod100 < 12 || mod100 > 14)) {
    return '$n шага';
  }
  return '$n шагов';
}
