import 'package:flutter/material.dart';

import '../../../helper/class_colors.dart';
import '../models/new_work_draft.dart';
import '../models/work_employee.dart';
import '../models/work_item.dart';
import '../widgets/work_kind_badge.dart';

/// Форма «Новая работа» из ленты «Работы»: админ и прораб заводят заявку,
/// не дожидаясь диспетчера.
///
/// Порядок полей — как человек думает: что случилось (вид), где (объект),
/// какая категория, кто поедет, что именно сделать. Механик объекта
/// подставляется исполнителем сам, но его можно поменять на любого —
/// включая заказчика: задача бывает и «оплатить», «дать доступ».
///
/// [onCreate] получает черновик и шлёт его на сервер; пока идёт запрос,
/// кнопки выключены. Бросил [NewWorkException] — текст печатается над
/// кнопками, форма остаётся: правки не пропадают. «Создать и ещё одну»
/// оставляет вид, объект и категорию — для серии задач по одному лифту.
Future<void> showNewWorkDialog(
  BuildContext context, {
  required NewWorkContext data,
  required Future<void> Function(NewWorkDraft draft) onCreate,
}) {
  return showDialog<void>(
    context: context,
    builder: (BuildContext context) =>
        NewWorkDialog(data: data, onCreate: onCreate),
  );
}

class NewWorkDialog extends StatefulWidget {
  const NewWorkDialog({Key? key, required this.data, required this.onCreate})
    : super(key: key);

  final NewWorkContext data;
  final Future<void> Function(NewWorkDraft draft) onCreate;

  @override
  State<NewWorkDialog> createState() => _NewWorkDialogState();
}

class _NewWorkDialogState extends State<NewWorkDialog> {
  NewWorkKind _kind = NewWorkKind.breakdown;
  NewWorkObject? _object;
  NewWorkCategory? _category;
  WorkEmployee? _executor;
  String? _photoName;
  final TextEditingController _description = TextEditingController();

  /// Идёт запрос — второй не уйдёт, пока не ответил первый.
  bool _busy = false;

  /// Что ответила ручка словами; `null` — ошибки нет.
  String? _error;

  /// Сколько уже создано этой формой — подпись «ещё одна» после первой.
  int _created = 0;

  @override
  void initState() {
    super.initState();
    _description.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  bool get _descriptionRequired => _kind == NewWorkKind.request;

  bool get _complete =>
      _object != null &&
      _category != null &&
      (!_descriptionRequired || _description.text.trim().isNotEmpty);

  /// Исполнитель — тот, кого объект держит закреплённым.
  bool get _executorIsObjectMechanic =>
      _object != null &&
      _executor != null &&
      _executor!.id == _object!.mechanicId;

  NewWorkDraft get _draft => NewWorkDraft(
    kind: _kind,
    object: _object!,
    category: _category!,
    executor: _executor,
    description: _description.text.trim(),
    photoName: _photoName,
  );

  void _pickKind(NewWorkKind kind) {
    if (kind == _kind) return;
    setState(() {
      _kind = kind;
      // Категория другого вида в этой ветке не живёт.
      if (_category != null && _category!.kind != kind) _category = null;
    });
  }

  void _pickObject(NewWorkObject? object) {
    setState(() {
      _object = object;
      // Механик объекта — исполнитель по умолчанию; руками выбранный
      // остаётся, если объект просто поменяли.
      if (object != null && (_executor == null || _executorWasAuto)) {
        _executor = widget.data.employeeById(object.mechanicId);
        _executorWasAuto = true;
      }
    });
  }

  bool _executorWasAuto = false;

  Future<void> _pickExecutor() async {
    final _ExecutorChoice? choice = await showDialog<_ExecutorChoice>(
      context: context,
      builder: (BuildContext context) => _ExecutorPicker(
        employees: widget.data.employees,
        mySections: widget.data.mySections,
        objectMechanicId: _object?.mechanicId,
        selected: _executor,
      ),
    );
    if (choice == null || !mounted) return;
    setState(() {
      _executor = choice.employee;
      _executorWasAuto = false;
    });
  }

  void _pickPhoto() {
    // Набросок: выбор файла — в S02. Тут только место в форме.
    setState(() => _photoName = _photoName == null ? 'IMG_2031.jpg' : null);
  }

  Future<void> _submit({required bool another}) async {
    if (_busy || !_complete) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.onCreate(_draft);
      if (!mounted) return;
      if (!another) {
        Navigator.of(context).pop();
        return;
      }
      setState(() {
        _created += 1;
        _description.clear();
        _photoName = null;
      });
    } on NewWorkException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool narrow = MediaQuery.sizeOf(context).width < 600.0;
    final Widget body = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Flexible(child: SingleChildScrollView(child: _form())),
        // Вне прокрутки: длинная форма не спрячет ответ ручки.
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: _ErrorLine(_error!),
          ),
      ],
    );

    if (narrow) {
      // На телефоне диалог во всю ширину: три выпадашки и карточка объекта
      // в окне 400 px не помещаются.
      return Dialog.fullscreen(
        backgroundColor: ColorApp.myColorWhite,
        child: Scaffold(
          backgroundColor: ColorApp.myColorWhite,
          appBar: AppBar(
            backgroundColor: ColorApp.myColorWhite,
            foregroundColor: ColorApp.myColorBlack,
            elevation: 0,
            title: _title(),
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 0.0),
            child: body,
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 12.0),
              child: _actions(stacked: true),
            ),
          ),
        ),
      );
    }

    return AlertDialog(
      backgroundColor: ColorApp.myColorWhite,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      titlePadding: const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 0.0),
      contentPadding: const EdgeInsets.fromLTRB(24.0, 12.0, 24.0, 0.0),
      title: _title(),
      content: SizedBox(width: 620.0, child: body),
      actionsPadding: const EdgeInsets.fromLTRB(24.0, 8.0, 24.0, 16.0),
      actions: <Widget>[_actions(stacked: false)],
    );
  }

  Widget _title() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          _created == 0 ? 'Новая работа' : 'Ещё одна работа',
          style: const TextStyle(
            fontSize: 17.0,
            fontWeight: FontWeight.w600,
            color: ColorApp.myColorBlack,
          ),
        ),
        const SizedBox(height: 4.0),
        Text(
          'Создаст: ${widget.data.author} · ${_formatNow(DateTime.now())}',
          style: const TextStyle(fontSize: 12.0, color: ColorApp.myColorGray),
        ),
      ],
    );
  }

  Widget _form() {
    final NewWorkContext data = widget.data;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const _Label('Вид работы'),
        _KindChooser(kind: _kind, onChanged: _pickKind),
        const SizedBox(height: 16.0),
        const _Label('Объект'),
        if (_object == null)
          _ObjectSearch(objects: data.objects, onPicked: _pickObject)
        else ...<Widget>[
          _ObjectCard(object: _object!, onChange: () => _pickObject(null)),
          _OpenWorks(items: data.openWorks[_object!.id] ?? const []),
        ],
        const SizedBox(height: 16.0),
        const _Label('Категория'),
        _CategoryField(
          categories: data.categoriesFor(_kind),
          value: _category,
          onChanged: (NewWorkCategory? c) => setState(() => _category = c),
        ),
        const SizedBox(height: 16.0),
        const _Label('Исполнитель', optional: true),
        _ExecutorField(
          executor: _executor,
          fromObject: _executorIsObjectMechanic,
          onTap: _pickExecutor,
          onClear: _executor == null
              ? null
              : () => setState(() {
                  _executor = null;
                  _executorWasAuto = false;
                }),
        ),
        const SizedBox(height: 16.0),
        _Label('Описание', optional: !_descriptionRequired),
        TextField(
          controller: _description,
          minLines: 2,
          maxLines: 5,
          style: _valueStyle,
          decoration: _decoration(
            hint: _kind == NewWorkKind.breakdown
                ? 'Что случилось, где, есть ли люди в кабине'
                : 'Что нужно сделать',
          ),
        ),
        const SizedBox(height: 12.0),
        _PhotoRow(name: _photoName, onTap: _pickPhoto),
        const SizedBox(height: 8.0),
      ],
    );
  }

  Widget _actions({required bool stacked}) {
    final Widget cancel = TextButton(
      onPressed: _busy ? null : () => Navigator.of(context).pop(),
      style: TextButton.styleFrom(foregroundColor: ColorApp.myColorGray),
      child: const Text('Отмена'),
    );
    final Widget another = OutlinedButton(
      onPressed: _busy || !_complete ? null : () => _submit(another: true),
      style: OutlinedButton.styleFrom(
        foregroundColor: ColorApp.myColorGreenAuth,
        side: const BorderSide(color: ColorApp.myColorGreenAuth),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      ),
      child: const Text('Создать и ещё одну'),
    );
    final Widget create = ElevatedButton.icon(
      onPressed: _busy || !_complete ? null : () => _submit(another: false),
      style: ElevatedButton.styleFrom(
        backgroundColor: ColorApp.myColorGreenAuth,
        foregroundColor: ColorApp.myColorWhite,
        disabledBackgroundColor: ColorApp.myColorGreenWhite,
        disabledForegroundColor: ColorApp.myColorWhite,
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      ),
      icon: _busy
          ? const SizedBox(
              width: 16.0,
              height: 16.0,
              child: CircularProgressIndicator(
                strokeWidth: 2.0,
                color: ColorApp.myColorWhite,
              ),
            )
          : const Icon(Icons.add, size: 18.0),
      label: Text(_busy ? 'Создаю…' : 'Создать'),
    );

    if (stacked) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          create,
          const SizedBox(height: 8.0),
          another,
          const SizedBox(height: 4.0),
          cancel,
        ],
      );
    }
    return Row(
      children: <Widget>[
        cancel,
        const Spacer(),
        another,
        const SizedBox(width: 12.0),
        create,
      ],
    );
  }
}

// --- Вид работы ------------------------------------------------------------

/// Две крупные кнопки. Красная точка у аварии — тот же цвет, что у бейджа в
/// ленте: человек сразу видит, куда ляжет работа.
class _KindChooser extends StatelessWidget {
  const _KindChooser({Key? key, required this.kind, required this.onChanged})
    : super(key: key);

  final NewWorkKind kind;
  final ValueChanged<NewWorkKind> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        for (final NewWorkKind k in NewWorkKind.values) ...<Widget>[
          if (k != NewWorkKind.values.first) const SizedBox(width: 12.0),
          Expanded(
            child: _KindButton(
              kind: k,
              selected: k == kind,
              onTap: () => onChanged(k),
            ),
          ),
        ],
      ],
    );
  }
}

class _KindButton extends StatelessWidget {
  const _KindButton({
    Key? key,
    required this.kind,
    required this.selected,
    required this.onTap,
  }) : super(key: key);

  final NewWorkKind kind;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color accent = kind.feedKind.color;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.0),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8.0),
          color: selected
              ? accent.withValues(alpha: 0.08)
              : ColorApp.myColorWhite,
          border: Border.all(
            color: selected ? accent : ColorApp.myColorAvatar,
            width: selected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 10.0,
              height: 10.0,
              decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
            ),
            const SizedBox(width: 10.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    kind.title,
                    style: TextStyle(
                      fontSize: 15.0,
                      fontWeight: FontWeight.w600,
                      color: selected
                          ? ColorApp.myColorBlack
                          : ColorApp.myColorGray,
                    ),
                  ),
                  Text(
                    kind.hint,
                    style: const TextStyle(
                      fontSize: 11.0,
                      color: ColorApp.myColorGrayText,
                    ),
                  ),
                ],
              ),
            ),
            if (selected) Icon(Icons.check_circle, size: 18.0, color: accent),
          ],
        ),
      ),
    );
  }
}

// --- Объект ------------------------------------------------------------------

/// Поиск объекта: поле и список под ним, пока объект не выбран. Ищет по
/// адресу, названию, номерам, участку и механику — по любому куску.
class _ObjectSearch extends StatefulWidget {
  const _ObjectSearch({Key? key, required this.objects, required this.onPicked})
    : super(key: key);

  final List<NewWorkObject> objects;
  final ValueChanged<NewWorkObject> onPicked;

  @override
  State<_ObjectSearch> createState() => _ObjectSearchState();
}

class _ObjectSearchState extends State<_ObjectSearch> {
  final TextEditingController _query = TextEditingController();
  final FocusNode _focus = FocusNode();

  /// Высота списка — около шести строк; дальше прокрутка внутри рамки,
  /// чтобы механик мог пролистать всю технику, не набирая запрос.
  static const double _listHeight = 6.5 * 54.0;

  @override
  void initState() {
    super.initState();
    _query.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _query.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String q = _query.text;
    final List<NewWorkObject> found = widget.objects
        .where((NewWorkObject o) => o.matches(q))
        .toList();
    // Список виден всегда, пока объект не выбран: на вебе клик по строке
    // сначала снимает фокус с поля, и список, привязанный к фокусу,
    // исчезал до того, как InkWell получал tap — выбор не срабатывал.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        TextField(
          controller: _query,
          focusNode: _focus,
          autofocus: true,
          style: _valueStyle,
          decoration: _decoration(
            hint: 'Адрес, название, зав. номер, участок…',
            prefix: const Icon(
              Icons.search,
              size: 20.0,
              color: ColorApp.myColorGray,
            ),
            suffix: q.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.clear, size: 18.0),
                    color: ColorApp.myColorGray,
                    onPressed: _query.clear,
                  ),
          ),
        ),
        Container(
          margin: const EdgeInsets.only(top: 4.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5.0),
            border: Border.all(color: ColorApp.myColorGrayBorder),
          ),
          child: found.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Text(
                    'Ничего не нашлось — проверь адрес или номер',
                    style: TextStyle(
                      fontSize: 13.0,
                      color: ColorApp.myColorGray,
                    ),
                  ),
                )
              : ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: _listHeight),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Flexible(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: found.length,
                          itemBuilder: (BuildContext context, int i) =>
                              _ObjectRow(
                                object: found[i],
                                onTap: () => widget.onPicked(found[i]),
                              ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          q.isEmpty
                              ? 'Всего ${found.length}'
                              : 'Найдено ${found.length}',
                          style: const TextStyle(
                            fontSize: 12.0,
                            color: ColorApp.myColorGrayText,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

class _ObjectRow extends StatelessWidget {
  const _ObjectRow({Key? key, required this.object, required this.onTap})
    : super(key: key);

  final NewWorkObject object;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Название — заголовком: механики ориентируются по нему, а не по адресу.
    final List<String> tail = <String>[
      if (object.address.isNotEmpty) object.address,
      if (object.type != null) object.type!,
      if (object.factoryNumber != null) 'зав. № ${object.factoryNumber}',
    ];
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(object.name, style: _valueStyle),
                  Text(
                    tail.join(' · '),
                    style: const TextStyle(
                      fontSize: 12.0,
                      color: ColorApp.myColorGray,
                    ),
                  ),
                ],
              ),
            ),
            if (object.section != null) ...<Widget>[
              const SizedBox(width: 12.0),
              const Icon(
                Icons.place_outlined,
                size: 14.0,
                color: ColorApp.myColorGray,
              ),
              const SizedBox(width: 4.0),
              Text(
                object.section!,
                style: const TextStyle(
                  fontSize: 12.0,
                  color: ColorApp.myColorGray,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Карточка выбранного объекта: всё, что пригодится, пока заводишь
/// работу, — от заводского номера до телефона контактного лица.
class _ObjectCard extends StatelessWidget {
  const _ObjectCard({Key? key, required this.object, required this.onChange})
    : super(key: key);

  final NewWorkObject object;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14.0, 12.0, 8.0, 12.0),
      decoration: BoxDecoration(
        color: ColorApp.myColorGrayShadow,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      object.name,
                      style: const TextStyle(
                        fontSize: 15.0,
                        fontWeight: FontWeight.w600,
                        color: ColorApp.myColorBlack,
                      ),
                    ),
                    Text(
                      <String>[
                        if (object.address.isNotEmpty) object.address,
                        if (object.type != null) object.type!,
                      ].join(' · '),
                      style: const TextStyle(
                        fontSize: 13.0,
                        color: ColorApp.myColorGray,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: onChange,
                style: TextButton.styleFrom(
                  foregroundColor: ColorApp.myColorGreenAuth,
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                ),
                child: const Text('Изменить'),
              ),
            ],
          ),
          const SizedBox(height: 8.0),
          Wrap(
            spacing: 20.0,
            runSpacing: 6.0,
            children: <Widget>[
              if (object.factoryNumber != null)
                _Fact('Зав. №', object.factoryNumber!),
              if (object.registrationNumber != null)
                _Fact('Рег. №', object.registrationNumber!),
              if (object.section != null) _Fact('Участок', object.section!),
              _Fact('Механик', object.mechanic ?? 'не закреплён'),
              _Fact('Прораб', object.foreman ?? 'не закреплён'),
              if (object.contactName != null)
                _Fact(
                  'Контакт',
                  object.contactPhone == null
                      ? object.contactName!
                      : '${object.contactName} · ${object.contactPhone}',
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact(this.label, this.value, {Key? key}) : super(key: key);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 12.0, color: ColorApp.myColorBlack),
        children: <InlineSpan>[
          TextSpan(
            text: '$label ',
            style: const TextStyle(color: ColorApp.myColorGrayText),
          ),
          TextSpan(text: value),
        ],
      ),
    );
  }
}

/// Что уже висит по объекту. Не мешает создать ещё — только показывает.
class _OpenWorks extends StatelessWidget {
  const _OpenWorks({Key? key, required this.items}) : super(key: key);

  final List<NewWorkOpenItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 6.0, left: 2.0),
        child: Text(
          'Открытых работ по объекту нет',
          style: TextStyle(fontSize: 12.0, color: ColorApp.myColorGrayText),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'В РАБОТЕ СЕЙЧАС · ${items.length}',
            style: const TextStyle(
              fontSize: 10.0,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: ColorApp.myColorGrayText,
            ),
          ),
          const SizedBox(height: 4.0),
          for (final NewWorkOpenItem i in items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3.0),
              child: Row(
                children: <Widget>[
                  WorkKindBadge(kind: i.kind),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: Text(
                      i.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13.0),
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  _StatusPill(i.status),
                  if (i.performer != null) ...<Widget>[
                    const SizedBox(width: 8.0),
                    Text(
                      i.performer!,
                      style: const TextStyle(
                        fontSize: 12.0,
                        color: ColorApp.myColorGray,
                      ),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill(this.status, {Key? key}) : super(key: key);

  final WorkStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Text(
        status.title,
        style: TextStyle(
          fontSize: 11.0,
          fontWeight: FontWeight.w600,
          color: status.color,
        ),
      ),
    );
  }
}

// --- Категория ---------------------------------------------------------------

class _CategoryField extends StatelessWidget {
  const _CategoryField({
    Key? key,
    required this.categories,
    required this.value,
    required this.onChanged,
  }) : super(key: key);

  final List<NewWorkCategory> categories;
  final NewWorkCategory? value;
  final ValueChanged<NewWorkCategory?> onChanged;

  @override
  Widget build(BuildContext context) {
    // Не `DropdownButtonFormField`: смена вида сбрасывает категорию, а
    // поле формы своё начальное значение не переживает.
    return InputDecorator(
      decoration: _decoration(),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<NewWorkCategory>(
          value: value,
          isExpanded: true,
          isDense: true,
          hint: const Text(
            'Выбери категорию',
            style: TextStyle(fontSize: 15.0, color: ColorApp.myColorGrayText),
          ),
          style: _valueStyle,
          items: <DropdownMenuItem<NewWorkCategory>>[
            for (final NewWorkCategory c in categories)
              DropdownMenuItem<NewWorkCategory>(
                value: c,
                child: Row(
                  children: <Widget>[
                    SizedBox(
                      width: 40.0,
                      child: Text(
                        c.code,
                        style: const TextStyle(
                          fontSize: 14.0,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        c.name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14.0),
                      ),
                    ),
                  ],
                ),
              ),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// --- Исполнитель -------------------------------------------------------------

/// Поле исполнителя: кто выбран, откуда он (участок, должность) и почему
/// подставлен — «закреплён за объектом». Пусто — работу назначат из ленты.
class _ExecutorField extends StatelessWidget {
  const _ExecutorField({
    Key? key,
    required this.executor,
    required this.fromObject,
    required this.onTap,
    this.onClear,
  }) : super(key: key);

  final WorkEmployee? executor;
  final bool fromObject;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final WorkEmployee? e = executor;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(5.0),
      child: Container(
        padding: const EdgeInsets.fromLTRB(10.0, 8.0, 4.0, 8.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5.0),
          border: Border.all(color: ColorApp.myColorAvatar),
        ),
        child: Row(
          children: <Widget>[
            Icon(
              e?.icon ?? Icons.person_add_alt_outlined,
              size: 20.0,
              color: ColorApp.myColorGray,
            ),
            const SizedBox(width: 10.0),
            Expanded(
              child: e == null
                  ? const Text(
                      'Не назначен — назначат из ленты',
                      style: TextStyle(
                        fontSize: 15.0,
                        color: ColorApp.myColorGrayText,
                      ),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(e.name, style: _valueStyle),
                        Text(
                          <String>[
                            e.specialty,
                            if (e.section != null) e.section!,
                            if (fromObject) 'закреплён за объектом',
                          ].join(' · '),
                          style: const TextStyle(
                            fontSize: 12.0,
                            color: ColorApp.myColorGray,
                          ),
                        ),
                      ],
                    ),
            ),
            if (onClear != null)
              IconButton(
                icon: const Icon(Icons.clear, size: 18.0),
                color: ColorApp.myColorGray,
                tooltip: 'Без исполнителя',
                onPressed: onClear,
              ),
            const Icon(Icons.arrow_drop_down, color: ColorApp.myColorGray),
          ],
        ),
      ),
    );
  }
}

class _ExecutorChoice {
  const _ExecutorChoice(this.employee);

  final WorkEmployee employee;
}

/// Выбор исполнителя: поиск сверху, ниже группы по участкам — свой участок
/// первым, потом остальные, заказчики в самом низу. Должность видна в
/// каждой строке: диспетчера на лифт не пошлёшь.
class _ExecutorPicker extends StatefulWidget {
  const _ExecutorPicker({
    Key? key,
    required this.employees,
    required this.mySections,
    required this.objectMechanicId,
    required this.selected,
  }) : super(key: key);

  final List<WorkEmployee> employees;
  final Set<int> mySections;
  final int? objectMechanicId;
  final WorkEmployee? selected;

  @override
  State<_ExecutorPicker> createState() => _ExecutorPickerState();
}

class _ExecutorPickerState extends State<_ExecutorPicker> {
  final TextEditingController _query = TextEditingController();

  @override
  void initState() {
    super.initState();
    _query.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  bool _isClient(WorkEmployee e) {
    final String s = e.specialty.toLowerCase();
    return s.contains('клиент') || s.contains('заказчик');
  }

  bool _matches(WorkEmployee e) {
    final String q = _query.text.trim().toLowerCase();
    if (q.isEmpty) return true;
    return '${e.name} ${e.specialty} ${e.section ?? ''}'.toLowerCase().contains(
      q,
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<WorkEmployee> all = widget.employees.where(_matches).toList();
    final List<WorkEmployee> clients = all.where(_isClient).toList();
    final List<WorkEmployee> staff = all.where((e) => !_isClient(e)).toList();

    // Группы по участку: свои первыми, без участка — «Офис».
    final Map<String, List<WorkEmployee>> groups =
        <String, List<WorkEmployee>>{};
    final List<String> order = <String>[];
    void put(String key, WorkEmployee e) {
      if (!groups.containsKey(key)) {
        groups[key] = <WorkEmployee>[];
        order.add(key);
      }
      groups[key]!.add(e);
    }

    for (final WorkEmployee e in staff) {
      if (widget.mySections.contains(e.sectionId)) {
        put(e.section ?? 'Участок', e);
      }
    }
    for (final WorkEmployee e in staff) {
      if (!widget.mySections.contains(e.sectionId) && e.section != null) {
        put(e.section!, e);
      }
    }
    for (final WorkEmployee e in staff) {
      if (!widget.mySections.contains(e.sectionId) && e.section == null) {
        put('Офис', e);
      }
    }

    return SimpleDialog(
      title: const Text(
        'Исполнитель',
        style: TextStyle(fontSize: 15.0, fontWeight: FontWeight.w700),
      ),
      titlePadding: const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 4.0),
      contentPadding: const EdgeInsets.fromLTRB(0.0, 4.0, 0.0, 12.0),
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(24.0, 4.0, 24.0, 8.0),
          child: SizedBox(
            width: 420.0,
            child: TextField(
              controller: _query,
              autofocus: true,
              style: _valueStyle,
              decoration: _decoration(
                hint: 'Имя, должность, участок',
                prefix: const Icon(
                  Icons.search,
                  size: 20.0,
                  color: ColorApp.myColorGray,
                ),
              ),
            ),
          ),
        ),
        if (all.isEmpty)
          const Padding(
            padding: EdgeInsets.fromLTRB(24.0, 8.0, 24.0, 8.0),
            child: Text(
              'Никого не нашлось',
              style: TextStyle(fontSize: 13.0, color: ColorApp.myColorGray),
            ),
          ),
        for (final String key in order) ...<Widget>[
          _PickerGroup(
            title:
                widget.mySections.isNotEmpty &&
                    groups[key]!.any(
                      (e) => widget.mySections.contains(e.sectionId),
                    )
                ? '$key · мой участок'
                : key,
            count: groups[key]!.length,
          ),
          for (final WorkEmployee e in groups[key]!) _PickerOption(e, this),
        ],
        if (clients.isNotEmpty) ...<Widget>[
          _PickerGroup(title: 'Заказчики', count: clients.length),
          for (final WorkEmployee e in clients) _PickerOption(e, this),
        ],
      ],
    );
  }
}

class _PickerGroup extends StatelessWidget {
  const _PickerGroup({Key? key, required this.title, required this.count})
    : super(key: key);

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24.0, 12.0, 24.0, 4.0),
      child: Text(
        '${title.toUpperCase()} · $count',
        style: const TextStyle(
          fontSize: 10.0,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: ColorApp.myColorGrayText,
        ),
      ),
    );
  }
}

class _PickerOption extends StatelessWidget {
  const _PickerOption(this.employee, this.picker, {Key? key}) : super(key: key);

  final WorkEmployee employee;
  final _ExecutorPickerState picker;

  @override
  Widget build(BuildContext context) {
    final bool fromObject = employee.id == picker.widget.objectMechanicId;
    final bool selected = employee.id == picker.widget.selected?.id;
    return SimpleDialogOption(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      onPressed: () => Navigator.of(context).pop(_ExecutorChoice(employee)),
      child: Row(
        children: <Widget>[
          Tooltip(
            message: employee.specialty,
            child: Icon(employee.icon, size: 18.0, color: ColorApp.myColorGray),
          ),
          const SizedBox(width: 12.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  employee.name,
                  style: TextStyle(
                    fontSize: 14.0,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
                Text(
                  fromObject
                      ? '${employee.specialty} · закреплён за объектом'
                      : employee.specialty,
                  style: TextStyle(
                    fontSize: 11.0,
                    color: fromObject
                        ? ColorApp.myColorGreenAuth
                        : ColorApp.myColorGrayText,
                  ),
                ),
              ],
            ),
          ),
          if (employee.section != null) ...<Widget>[
            const SizedBox(width: 16.0),
            const Icon(
              Icons.place_outlined,
              size: 14.0,
              color: ColorApp.myColorGray,
            ),
            const SizedBox(width: 4.0),
            Text(
              employee.section!,
              style: const TextStyle(
                fontSize: 12.0,
                color: ColorApp.myColorGray,
              ),
            ),
          ],
          if (selected) ...<Widget>[
            const SizedBox(width: 8.0),
            const Icon(
              Icons.check,
              size: 16.0,
              color: ColorApp.myColorGreenAuth,
            ),
          ],
        ],
      ),
    );
  }
}

// --- Фото и мелочи -----------------------------------------------------------

class _PhotoRow extends StatelessWidget {
  const _PhotoRow({Key? key, required this.name, required this.onTap})
    : super(key: key);

  final String? name;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (name == null) {
      return Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: onTap,
          style: TextButton.styleFrom(foregroundColor: ColorApp.myColorGray),
          icon: const Icon(Icons.add_a_photo_outlined, size: 18.0),
          label: const Text('Добавить фото'),
        ),
      );
    }
    return Align(
      alignment: Alignment.centerLeft,
      child: Chip(
        avatar: const Icon(Icons.image_outlined, size: 16.0),
        label: Text(name!, style: const TextStyle(fontSize: 12.0)),
        deleteIcon: const Icon(Icons.close, size: 14.0),
        onDeleted: onTap,
        backgroundColor: ColorApp.myColorGrayShadow,
        side: BorderSide.none,
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text, {Key? key, this.optional = false}) : super(key: key);

  final String text;
  final bool optional;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: RichText(
        text: TextSpan(
          text: text,
          style: _labelStyle,
          children: <InlineSpan>[
            if (optional)
              const TextSpan(
                text: ' · необязательно',
                style: TextStyle(color: ColorApp.myColorGrayText),
              ),
          ],
        ),
      ),
    );
  }
}

class _ErrorLine extends StatelessWidget {
  const _ErrorLine(this.text, {Key? key}) : super(key: key);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Icon(Icons.error_outline, size: 16.0, color: ColorApp.myColorRed),
        const SizedBox(width: 6.0),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13.0, color: ColorApp.myColorRed),
          ),
        ),
      ],
    );
  }
}

const TextStyle _labelStyle = TextStyle(
  fontSize: 12.0,
  fontWeight: FontWeight.w300,
  color: ColorApp.myColorGray,
);

const TextStyle _valueStyle = TextStyle(
  fontSize: 15.0,
  fontWeight: FontWeight.w500,
  color: ColorApp.myColorBlack,
);

OutlineInputBorder _border(Color color) => OutlineInputBorder(
  borderRadius: BorderRadius.circular(5.0),
  borderSide: BorderSide(color: color),
);

InputDecoration _decoration({String? hint, Widget? prefix, Widget? suffix}) =>
    InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        fontSize: 15.0,
        fontWeight: FontWeight.w400,
        color: ColorApp.myColorGrayText,
      ),
      prefixIcon: prefix,
      suffixIcon: suffix,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 10.0,
        vertical: 12.0,
      ),
      enabledBorder: _border(ColorApp.myColorAvatar),
      focusedBorder: _border(ColorApp.myColorGreenAuth),
      border: _border(ColorApp.myColorAvatar),
    );

String _formatNow(DateTime d) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(d.day)}.${two(d.month)}.${d.year} ${two(d.hour)}:${two(d.minute)}';
}
