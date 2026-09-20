import 'package:flutter/material.dart';

import '../../../../helper/class_colors.dart';
import '../models/checklist_template.dart';
import '../repository/templates_repository.dart';
import '../widgets/new_type_act_dialog.dart';
import '../widgets/template_editor_dialog.dart';

/// Экран «Шаблоны ТО»: модели лифтов и виды ТО, у каждой пары — есть
/// шаблон чек-листа или нет.
///
/// Открывается кнопкой из шапки «Графиков» маршрутом поверх ленты. Список
/// один на все модели — их в справочнике десятки, не тысячи, и отдельный
/// выбор модели перед списком добавлял бы клик, ничего не показывая.
///
/// Кадра в Figma нет, рисовали сами — в стиле ленты «Графиков»: серый фон,
/// одна белая карточка, строки разделены линией.
class TemplatesScreen extends StatefulWidget {
  const TemplatesScreen({Key? key, required this.repository}) : super(key: key);

  final TemplatesRepository repository;

  @override
  State<TemplatesScreen> createState() => _TemplatesScreenState();
}

class _TemplatesScreenState extends State<TemplatesScreen> {
  late Future<List<ModelTemplates>> _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = widget.repository.loadAll();
  }

  Future<void> _edit(TemplateModel model, TemplateTypeAct typeAct) async {
    final List<String>? steps = await showTemplateEditorDialog(
      context,
      repository: widget.repository,
      model: model,
      typeAct: typeAct,
    );
    if (steps == null || !mounted) return;
    await _run(() => widget.repository.save(
          modelId: model.id,
          typeActId: typeAct.typeActId,
          steps: steps,
        ));
  }

  /// Действие на сервере и перечитывание списка следом. Не вышло —
  /// плашка с причиной словами, список остаётся прежним: человек видит,
  /// что ничего не изменилось, и может повторить.
  Future<void> _run(Future<void> Function() action) async {
    try {
      await action();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
      return;
    }
    if (!mounted) return;
    setState(_load);
  }

  /// Новый вид ТО — у одной модели, потом список перечитывается: у неё
  /// появляется строка «нет шаблона», у остальных ничего не меняется.
  Future<void> _addTypeAct(ModelTemplates item) async {
    final String? name = await showNewTypeActDialog(
      context,
      modelName: item.model.name,
      existing: <String>[for (final TemplateTypeAct t in item.types) t.typeActName],
    );
    if (name == null || !mounted) return;
    await _run(
      () => widget.repository.addTypeAct(modelId: item.model.id, name: name),
    );
  }

  /// Убрать вид у модели — мягко: строка уходит вниз зачёркнутой, шаблон
  /// цел, вернуть можно в один клик. Шаблон уже заведён — спрашиваем, чтобы
  /// не задеть случайно. Пустой вид уходит без вопроса.
  Future<void> _removeTypeAct(TemplateModel model, TemplateTypeAct typeAct) async {
    if (typeAct.steps.isNotEmpty) {
      final bool? ok = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
          title: const Text('Удалить вид ТО?'),
          content: Text(
            'У модели «${model.name}» вид «${typeAct.typeActName}» перестанет '
            'попадать в новые графики. Шаблон '
            '(${stepsLabel(typeAct.steps.length)}) и акты по нему '
            'сохранятся, вид можно будет вернуть.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: TextButton.styleFrom(foregroundColor: ColorApp.myColorGray),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: ColorApp.myColorRed),
              child: const Text('Удалить'),
            ),
          ],
        ),
      );
      if (ok != true || !mounted) return;
    }
    await _run(() => _remove(model, typeAct));
  }

  /// Сервер отказал: по шаблону стоят ещё не начатые ТО. Это не ошибка, а
  /// вопрос — убрать всё равно или оставить. «Да» — тот же запрос с `force`.
  Future<void> _remove(TemplateModel model, TemplateTypeAct typeAct) async {
    try {
      await widget.repository.removeTypeAct(
        modelId: model.id,
        typeActId: typeAct.typeActId,
      );
    } on TemplateInUseException catch (e) {
      if (!mounted) return;
      final bool? ok = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
          title: const Text('По шаблону стоят ТО'),
          content: Text(
            '${e.message}. Акты уже созданы со своим снимком шагов и '
            'останутся; в новые графики вид попадать не будет.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: TextButton.styleFrom(foregroundColor: ColorApp.myColorGray),
              child: const Text('Оставить'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: ColorApp.myColorRed),
              child: const Text('Удалить всё равно'),
            ),
          ],
        ),
      );
      if (ok != true) return;
      await widget.repository.removeTypeAct(
        modelId: model.id,
        typeActId: typeAct.typeActId,
        force: true,
      );
    }
  }

  Future<void> _restoreTypeAct(
    TemplateModel model,
    TemplateTypeAct typeAct,
  ) async {
    await _run(() => widget.repository.restoreTypeAct(
          modelId: model.id,
          typeActId: typeAct.typeActId,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorApp.myColorGrayShadow,
      appBar: AppBar(
        title: const Text('Шаблоны ТО'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: ColorApp.myColorBlack,
      ),
      body: FutureBuilder<List<ModelTemplates>>(
        future: _future,
        builder: (
          BuildContext context,
          AsyncSnapshot<List<ModelTemplates>> snapshot,
        ) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    'Не удалось загрузить шаблоны: ${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14.0),
                  ),
                  const SizedBox(height: 12.0),
                  TextButton(
                    onPressed: () => setState(_load),
                    style: TextButton.styleFrom(
                      foregroundColor: ColorApp.myColorGreenAuth,
                    ),
                    child: const Text('Повторить'),
                  ),
                ],
              ),
            );
          }
          final List<ModelTemplates>? models = snapshot.data;
          if (models == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return _List(
            models: models,
            onTap: _edit,
            onAdd: _addTypeAct,
            onRemove: _removeTypeAct,
            onRestore: _restoreTypeAct,
          );
        },
      ),
    );
  }
}

class _List extends StatelessWidget {
  const _List({
    Key? key,
    required this.models,
    required this.onTap,
    required this.onAdd,
    required this.onRemove,
    required this.onRestore,
  }) : super(key: key);

  final List<ModelTemplates> models;
  final void Function(TemplateModel, TemplateTypeAct) onTap;
  final void Function(ModelTemplates) onAdd;
  final void Function(TemplateModel, TemplateTypeAct) onRemove;
  final void Function(TemplateModel, TemplateTypeAct) onRestore;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        // На широком экране карточка не растягивается на весь монитор: строка
        // «ТО 3 · 8 шагов» на полторы тысячи пикселей читается плохо.
        constraints: const BoxConstraints(maxWidth: 960.0),
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: <Widget>[
            const Padding(
              padding: EdgeInsets.only(bottom: 12.0),
              child: Text(
                'Чек-лист, который механик видит в акте, зависит от модели '
                'лифта и вида ТО. Вид без шаблона в график встанет, но акт '
                'по нему будет пустым.',
                style: TextStyle(fontSize: 13.0, color: ColorApp.myColorGray),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: ColorApp.myColorWhite,
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Column(
                children: <Widget>[
                  for (int i = 0; i < models.length; i++) ...<Widget>[
                    if (i > 0)
                      const Divider(
                        height: 1.0,
                        thickness: 1.0,
                        color: ColorApp.myColorGrayBorder,
                      ),
                    _ModelBlock(
                      item: models[i],
                      onTap: onTap,
                      onAdd: onAdd,
                      onRemove: onRemove,
                      onRestore: onRestore,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Модель и её виды ТО; внизу — «+ Вид ТО» для этой модели.
class _ModelBlock extends StatelessWidget {
  const _ModelBlock({
    Key? key,
    required this.item,
    required this.onTap,
    required this.onAdd,
    required this.onRemove,
    required this.onRestore,
  }) : super(key: key);

  final ModelTemplates item;
  final void Function(TemplateModel, TemplateTypeAct) onTap;
  final void Function(ModelTemplates) onAdd;
  final void Function(TemplateModel, TemplateTypeAct) onRemove;
  final void Function(TemplateModel, TemplateTypeAct) onRestore;

  @override
  Widget build(BuildContext context) {
    final int total = item.active.length;
    final int missing = total - item.withTemplate;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 8.0),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  item.model.name,
                  style: const TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.w700,
                    color: ColorApp.myColorBlack,
                  ),
                ),
              ),
              Text(
                // У модели без видов «все шаблоны есть» звучало бы как
                // готовность, а это как раз пустота.
                total == 0
                    ? 'видов ТО нет'
                    : missing == 0
                        ? 'все шаблоны есть'
                        : '${item.withTemplate} из $total с шаблоном',
                style: TextStyle(
                  fontSize: 13.0,
                  color: missing == 0 && total > 0
                      ? ColorApp.myColorGreenAuth
                      : ColorApp.myColorGray,
                ),
              ),
            ],
          ),
        ),
        for (final TemplateTypeAct t in item.types)
          if (t.deleted)
            _DeletedTypeActRow(
              typeAct: t,
              onRestore: () => onRestore(item.model, t),
            )
          else
            _TypeActRow(
              typeAct: t,
              onTap: () => onTap(item.model, t),
              onRemove: () => onRemove(item.model, t),
            ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12.0, 0.0, 12.0, 8.0),
          child: TextButton.icon(
            onPressed: () => onAdd(item),
            style: TextButton.styleFrom(
              foregroundColor: ColorApp.myColorGreenAuth,
            ),
            icon: const Icon(Icons.add, size: 20.0),
            label: const Text('Вид ТО'),
          ),
        ),
      ],
    );
  }
}

/// Строка вида ТО: имя, число шагов или «нет шаблона», удаление и
/// действие справа.
class _TypeActRow extends StatelessWidget {
  const _TypeActRow({
    Key? key,
    required this.typeAct,
    required this.onTap,
    required this.onRemove,
  }) : super(key: key);

  final TemplateTypeAct typeAct;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final bool has = typeAct.hasTemplate;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: _rowPadding,
        child: Row(
          children: <Widget>[
            Icon(
              has ? Icons.checklist_rounded : Icons.remove_circle_outline,
              size: 20.0,
              color: has ? ColorApp.myColorGreenAuth : ColorApp.myColorRed,
            ),
            const SizedBox(width: 12.0),
            SizedBox(
              width: 72.0,
              child: Text(
                typeAct.typeActName,
                style: const TextStyle(
                  fontSize: 14.0,
                  color: ColorApp.myColorBlack,
                ),
              ),
            ),
            Expanded(
              child: Text(
                has ? stepsLabel(typeAct.steps.length) : 'нет шаблона',
                style: TextStyle(
                  fontSize: 13.0,
                  color: has ? ColorApp.myColorGray : ColorApp.myColorRed,
                ),
              ),
            ),
            IconButton(
              onPressed: onRemove,
              tooltip: 'Удалить вид ТО',
              splashRadius: 20.0,
              icon: const Icon(
                Icons.delete_outline,
                size: 20.0,
                color: ColorApp.myColorGrayText,
              ),
            ),
            Text(
              has ? 'Изменить' : 'Создать',
              style: TextStyle(
                fontSize: 13.0,
                fontWeight: FontWeight.w500,
                color: has ? ColorApp.myColorGray : ColorApp.myColorGreenAuth,
              ),
            ),
            const SizedBox(width: 4.0),
            const Icon(
              Icons.chevron_right,
              size: 20.0,
              color: ColorApp.myColorGrayText,
            ),
          ],
        ),
      ),
    );
  }
}

const EdgeInsets _rowPadding = EdgeInsets.fromLTRB(20.0, 4.0, 20.0, 4.0);

/// Убранный вид ТО: внизу блока, имя зачёркнуто красным, остальное
/// светло-серое — видно, что это старое. Справа «Вернуть».
class _DeletedTypeActRow extends StatelessWidget {
  const _DeletedTypeActRow({
    Key? key,
    required this.typeAct,
    required this.onRestore,
  }) : super(key: key);

  final TemplateTypeAct typeAct;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    const Color muted = ColorApp.myColorGrayText;
    return InkWell(
      onTap: onRestore,
      child: Padding(
        // Корзины здесь нет, а её 48px задают высоту живой строки —
        // добираем отступом, чтобы строки не прыгали.
        padding: const EdgeInsets.fromLTRB(20.0, 18.0, 20.0, 18.0),
        child: Row(
          children: <Widget>[
            const Icon(Icons.history, size: 20.0, color: muted),
            const SizedBox(width: 12.0),
            SizedBox(
              width: 72.0,
              child: Text(
                typeAct.typeActName,
                style: const TextStyle(
                  fontSize: 14.0,
                  color: muted,
                  decoration: TextDecoration.lineThrough,
                  decorationColor: ColorApp.myColorRed,
                  decorationThickness: 2.0,
                ),
              ),
            ),
            Expanded(
              child: Text(
                typeAct.hasTemplate
                    ? 'удалён · ${stepsLabel(typeAct.steps.length)}'
                    : 'удалён',
                style: const TextStyle(fontSize: 13.0, color: muted),
              ),
            ),
            // Место под корзину живой строки — «Вернуть» стоит в одну
            // колонку с «Изменить», а не прыгает вправо.
            const SizedBox(width: 48.0),
            const Text(
              'Вернуть',
              style: TextStyle(
                fontSize: 13.0,
                fontWeight: FontWeight.w500,
                color: ColorApp.myColorGreenAuth,
              ),
            ),
            const SizedBox(width: 4.0),
            const Icon(Icons.restore, size: 20.0, color: ColorApp.myColorGreenAuth),
          ],
        ),
      ),
    );
  }
}
