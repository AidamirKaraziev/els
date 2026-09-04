/// Карточка заявки и работа по ней.
///
/// Своего кадра у этого экрана нет: в макете механика четырнадцать кадров, и
/// поток заявки — статусы, фотографии, комментарий — не нарисован ни в одном.
/// Поэтому экран собран из приёмов соседних кадров (белые карточки со
/// скруглением 5 на фоне `#F5F6F6`, заголовки 16, подписи 12 серым), а состав
/// взят из потока, который заказчик уже принял на вебе и который был у
/// подрядчика в мобильном приложении.
///
/// Решения, которые стоит знать:
///
/// * **Статус не меняется от того, что карточку открыли.** У подрядчика тап по
///   заявке молча переводил её в «Принято». Заявку теперь видят двое —
///   исполнитель и механик объекта, — и открывать чужую работу, меняя ей
///   статус, нельзя. Каждый переход — отдельная кнопка.
/// * **Всё уходит через очередь.** Кнопка срабатывает мгновенно и без связи;
///   отметка ложится в локальную базу сразу, чтобы человек видел отклик, а не
///   жал второй раз.
/// * **Наблюдателю кнопок не видно.** Если я механик объекта, но не
///   исполнитель, сервер всё равно откажет: `POST /order-photo/{id}/` проверяет
///   исполнителя. Кнопка, которая заведомо получит отказ, хуже отсутствующей.
/// * **Фотографии показываются только те, что ещё в очереди.** Снимки,
///   уже принятые сервером, лежат в `GET /order-photo/{order_id}` и требуют
///   связи; галерея заявки — отдельная работа, здесь её нет.
library;

import 'package:flutter/material.dart';

import '../../helper/class_colors.dart';
import '../../helper/image_picking.dart';
import '../data/defect_link.dart';
import '../data/mechanic_workspace.dart';
import '../data/tasks.dart';
import '../mechanic_theme.dart';
import 'defect_sheet.dart';
import 'quiet_button.dart';

/// Сколько снимков разрешаем приложить к одной заявке за раз.
///
/// Пять — как в потоке подрядчика. Ограничение не про сервер, а про телефон:
/// снимки ждут связи в его хранилище.
const int _photoLimit = 5;

class MechanicOrderScreen extends StatefulWidget {
  const MechanicOrderScreen({Key? key, required this.task}) : super(key: key);

  final MechanicTask task;

  @override
  State<MechanicOrderScreen> createState() => _MechanicOrderScreenState();
}

class _MechanicOrderScreenState extends State<MechanicOrderScreen> {
  final TextEditingController _comment = TextEditingController();

  late int? _statusId = widget.task.statusId;
  int _queuedPhotos = 0;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _comment.text = asString(widget.task.raw['commentary']) ?? '';
    _countPhotos();
  }

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _countPhotos() async {
    final int count =
        await MechanicWorkspace.current?.queuedPhotos(widget.task.id) ?? 0;
    if (mounted) setState(() => _queuedPhotos = count);
  }

  @override
  Widget build(BuildContext context) {
    final MechanicTask task = widget.task;
    final Map<String, dynamic> raw = task.raw;

    return Scaffold(
      backgroundColor: ColorApp.myColorTransparent,
      appBar: AppBar(
        backgroundColor: ColorApp.myColorWhite,
        foregroundColor: ColorApp.myColorBlack,
        elevation: 0.0,
        title: Text('Заявка №${task.id}', style: MechanicLayout.sectionTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          MechanicLayout.screenPadding,
          16.0,
          MechanicLayout.screenPadding,
          32.0,
        ),
        children: <Widget>[
          if (task.watchingOnly) const _WatchingNote(),
          _Card(
            children: <Widget>[
              Text(task.title, style: MechanicLayout.screenTitle.copyWith(fontSize: 20.0)),
              if (task.address != null) ...<Widget>[
                const SizedBox(height: 6.0),
                Text(task.address!, style: MechanicLayout.cardSubtitle),
              ],
              const SizedBox(height: 12.0),
              _Line(label: 'Состояние', value: orderStatusName(_statusId)),
              _Line(
                label: 'Категория',
                value: asString(asMap(raw['fault_category_id'])['name']) ?? '—',
              ),
              _Line(label: 'Заведена', value: dayText(asInt(raw['created_at']) ?? 0)),
              _Line(
                label: 'Кто завёл',
                value: asString(asMap(raw['creator_id'])['name']) ?? '—',
              ),
              _Line(
                label: 'Исполнитель',
                value: asString(asMap(raw['executor_id'])['name']) ?? '—',
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          _Card(
            children: <Widget>[
              const Text('Что нужно сделать', style: MechanicLayout.sectionTitle),
              const SizedBox(height: 8.0),
              Text(
                asString(raw['task_text']) ?? 'Описание не заполнено',
                style: MechanicLayout.rowValue,
              ),
            ],
          ),
          if (!task.watchingOnly) ...<Widget>[
            const SizedBox(height: 16.0),
            _Card(
              children: <Widget>[
                const Text('Комментарий', style: MechanicLayout.sectionTitle),
                const SizedBox(height: 8.0),
                TextField(
                  controller: _comment,
                  maxLines: 3,
                  style: MechanicLayout.rowValue,
                  decoration: const InputDecoration(
                    hintText: 'Что сделано, что мешает закрыть',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 16.0),
                _Photos(
                  queued: _queuedPhotos,
                  onAdd: _busy ? null : _addPhoto,
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            ..._actions(task),
          ],
          // Дефект — вне блока исполнителя намеренно. Кнопки статуса
          // наблюдателю не показываем: сервер откажет, `POST /order-photo/`
          // проверяет исполнителя. Дефект такой проверки не делает —
          // `_resolve_object` смотрит только на видимость заявки, — и
          // механик объекта, приехавший не по своей заявке, обязан иметь
          // возможность записать то, что увидел.
          if (_statusId != OrderStatus.done &&
              _statusId != OrderStatus.problem) ...<Widget>[
            const SizedBox(height: 8.0),
            Align(
              alignment: Alignment.centerLeft,
              child: MechanicQuietButton(
                icon: mechanicDefectIcon,
                label: 'Дефект по заявке',
                ink: ColorApp.myColorGray,
                onTap: _reportDefect,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Дефект по заявке: статус её не двигает и `_busy` не занимает — заявка
  /// остаётся ровно в том состоянии, в каком была.
  Future<void> _reportDefect() async {
    final DefectDraft? draft = await showDefectSheet(context);
    if (draft == null || !mounted) return;

    await MechanicWorkspace.current?.sendDefect(
      link: DefectLink.order(widget.task.id),
      title: draft.title,
      description: draft.description,
      photos: draft.photos,
    );
    if (!mounted) return;
    _say('Дефект «${draft.title}» записан.');
  }

  /// Кнопки перехода — ровно те, что имеют смысл в текущем состоянии.
  List<Widget> _actions(MechanicTask task) {
    final int? status = _statusId;
    if (status == OrderStatus.done || status == OrderStatus.problem) {
      return <Widget>[
        const _Done(),
      ];
    }

    return <Widget>[
      if (status == null || status == OrderStatus.created)
        _Button(
          label: 'Принять заявку',
          onTap: _busy ? null : () => _move(OrderStatus.accepted, 'принял'),
        ),
      if (status == null ||
          status == OrderStatus.created ||
          status == OrderStatus.accepted)
        _Button(
          label: 'В работу',
          onTap: _busy ? null : () => _move(OrderStatus.inProgress, 'в работу'),
        ),
      if (status == OrderStatus.inProgress) ...<Widget>[
        _Button(
          label: 'Выполнил',
          onTap: _busy ? null : () => _move(OrderStatus.done, 'выполнил'),
        ),
        _Button(
          label: 'Проблема',
          tone: _Tone.warning,
          onTap: _busy ? null : () => _move(OrderStatus.problem, 'проблема'),
        ),
      ],
    ];
  }

  Future<void> _move(int statusId, String what) async {
    final MechanicWorkspace? workspace = MechanicWorkspace.current;
    if (workspace == null) return;

    setState(() => _busy = true);
    await workspace.sendOrderStatus(
      orderId: widget.task.id,
      statusId: statusId,
      title: 'Заявка №${widget.task.id} — $what',
      commentary: _comment.text,
    );
    if (!mounted) return;
    setState(() {
      _statusId = statusId;
      _busy = false;
    });
    _say('Отметка сохранена. Уйдёт на сервер, как появится связь.');
  }

  Future<void> _addPhoto() async {
    if (_queuedPhotos >= _photoLimit) {
      _say('Больше $_photoLimit снимков за раз телефон в очереди не держит.');
      return;
    }

    final bool? fromCamera = await showModalBottomSheet<bool>(
      context: context,
      builder: (BuildContext context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Снять сейчас'),
              onTap: () => Navigator.of(context).pop(true),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Выбрать из галереи'),
              onTap: () => Navigator.of(context).pop(false),
            ),
          ],
        ),
      ),
    );
    if (fromCamera == null) return;

    setState(() => _busy = true);
    try {
      final PickedImage? shot = await pickWorkPhoto(fromCamera: fromCamera);
      final List<int>? bytes = shot?.data;
      if (bytes == null) return;

      await MechanicWorkspace.current?.attachOrderPhoto(
        orderId: widget.task.id,
        bytes: bytes,
        fileName: shot?.fileName ?? 'photo.jpg',
      );
      await _countPhotos();
      _say('Снимок в очереди. Уйдёт вместе с остальным.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _say(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }
}

class _WatchingNote extends StatelessWidget {
  const _WatchingNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: ColorApp.myColorGreenLine,
        borderRadius: BorderRadius.circular(MechanicLayout.cardRadius),
      ),
      child: const Row(
        children: <Widget>[
          Icon(Icons.visibility_outlined, size: 18.0, color: ColorApp.myColorGray),
          SizedBox(width: 8.0),
          Expanded(
            child: Text(
              'Вы отвечаете за этот лифт, но работает по заявке другой механик. '
              'Отмечать за него нельзя.',
              style: TextStyle(fontSize: 12.0, color: ColorApp.myColorGray),
            ),
          ),
        ],
      ),
    );
  }
}

class _Photos extends StatelessWidget {
  const _Photos({required this.queued, required this.onAdd});

  final int queued;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            queued == 0
                ? 'Фотографии не приложены'
                : 'В очереди снимков: $queued',
            style: MechanicLayout.cardSubtitle,
          ),
        ),
        TextButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add_a_photo_outlined, size: 18.0),
          label: const Text('Добавить'),
          style: TextButton.styleFrom(foregroundColor: ColorApp.myColorGreenAuth),
        ),
      ],
    );
  }
}

enum _Tone { normal, warning }

class _Button extends StatelessWidget {
  const _Button({required this.label, required this.onTap, this.tone = _Tone.normal});

  final String label;
  final VoidCallback? onTap;
  final _Tone tone;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: SizedBox(
        height: 48.0,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: tone == _Tone.warning
                ? ColorApp.myColorYellow
                : ColorApp.myColorGreenAuth,
            foregroundColor: ColorApp.myColorWhite,
            elevation: 0.0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(MechanicLayout.cardRadius),
            ),
          ),
          child: Text(label, style: const TextStyle(fontSize: 15.0)),
        ),
      ),
    );
  }
}

class _Done extends StatelessWidget {
  const _Done();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: <Widget>[
          Icon(Icons.check_circle_outline, color: ColorApp.myColorGreenAuth),
          SizedBox(width: 8.0),
          Expanded(
            child: Text(
              'Работа сдана. Прораб увидит её в ленте сданных работ.',
              style: TextStyle(fontSize: 13.0, color: ColorApp.myColorGray),
            ),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: ColorApp.myColorWhite,
        borderRadius: BorderRadius.circular(MechanicLayout.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value});

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
            width: 110.0,
            child: Text(label, style: MechanicLayout.rowLabel),
          ),
          Expanded(child: Text(value, style: MechanicLayout.rowValue)),
        ],
      ),
    );
  }
}
