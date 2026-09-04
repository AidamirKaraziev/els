/// Один пункт регламента: отметка, комментарий и фотографии.
///
/// Своего кадра у экрана нет — в «Этапах ТО» пункт живёт строкой в списке.
/// Комментарий и снимки в строку не помещаются, поэтому пункт открывается
/// отдельно, приёмами карточки заявки: белые карточки со скруглением 5 на
/// фоне `#F5F6F6`, поле комментария в рамке, снимки плитками.
///
/// Что важно знать:
///
/// * **Фотография привязана к номеру шага**, а не к его тексту:
///   `POST /act-fact/{id}/step/{step_id}/photo/`. Пункт без номера сфотографировать
///   нельзя — снимку некуда сослаться, и кнопка в таком пункте не появляется.
///   Такой пункт бывает только у акта, который прораб ещё не сохранил.
/// * **Показываем только снимки из очереди.** Принятые сервером лежат в
///   `GET /act-fact/{id}/photos/` и требуют связи; галерея шага — отдельная
///   работа, здесь её нет. То же решение, что в карточке заявки.
/// * **Комментарий и отметка уходят одним `PUT`** — это одна и та же правка
///   чек-листа, и разделять их значило бы слать два запроса на одно действие.
library;

import 'package:flutter/material.dart';

import '../../helper/class_colors.dart';
import '../../helper/image_picking.dart';
import '../data/acts.dart';
import '../data/defect_link.dart';
import '../data/mechanic_workspace.dart';
import '../mechanic_theme.dart';
import 'defect_sheet.dart';
import 'quiet_button.dart';

/// Сколько снимков разрешаем приложить к одному шагу за раз. Пять — как в
/// карточке заявки: ограничение не про сервер, а про телефон, снимки ждут
/// связи в его хранилище.
const int _photoLimit = 5;

class MechanicActStepScreen extends StatefulWidget {
  const MechanicActStepScreen({
    Key? key,
    required this.act,
    required this.index,
    this.readOnly = false,
  }) : super(key: key);

  final ActDetails act;

  /// Номер пункта в списке — не `id` шага: список и есть порядок.
  final int index;

  final bool readOnly;

  @override
  State<MechanicActStepScreen> createState() => _MechanicActStepScreenState();
}

class _MechanicActStepScreenState extends State<MechanicActStepScreen> {
  final TextEditingController _comment = TextEditingController();

  late ActDetails _act = widget.act;
  late bool _done = _step.done;
  int _queued = 0;
  bool _busy = false;

  ActStep get _step => _act.steps[widget.index];

  @override
  void initState() {
    super.initState();
    _comment.text = _step.comment ?? '';
    _countPhotos();
  }

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _countPhotos() async {
    final int? stepId = _step.id;
    if (stepId == null) return;
    final int count =
        await MechanicWorkspace.current?.queuedStepPhotos(_act.id, stepId) ?? 0;
    if (mounted) setState(() => _queued = count);
  }

  @override
  Widget build(BuildContext context) {
    final int number = widget.index + 1;

    return Scaffold(
      backgroundColor: ColorApp.myColorTransparent,
      appBar: AppBar(
        backgroundColor: ColorApp.myColorWhite,
        foregroundColor: ColorApp.myColorBlack,
        elevation: 0.0,
        title: Text(
          'Шаг $number из ${_act.total}',
          style: MechanicLayout.sectionTitle,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          MechanicLayout.screenPadding,
          16.0,
          MechanicLayout.screenPadding,
          32.0,
        ),
        children: <Widget>[
          _Card(
            children: <Widget>[
              Text(
                _step.title,
                style: MechanicLayout.sectionTitle.copyWith(height: 1.4),
              ),
              const SizedBox(height: 12.0),
              const Divider(height: 1.0, color: MechanicLayout.divider),
              InkWell(
                onTap: widget.readOnly || _busy
                    ? null
                    : () => setState(() => _done = !_done),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: Row(
                    children: <Widget>[
                      _Box(done: _done),
                      const SizedBox(width: 12.0),
                      const Expanded(
                        child: Text(
                          'Пункт выполнен',
                          style: MechanicLayout.rowValue,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          _Card(
            children: <Widget>[
              const Text('Комментарий', style: MechanicLayout.sectionTitle),
              const SizedBox(height: 8.0),
              TextField(
                controller: _comment,
                maxLines: 3,
                readOnly: widget.readOnly,
                style: MechanicLayout.rowValue,
                decoration: const InputDecoration(
                  hintText: 'Что сделано, что мешает закрыть',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16.0),
          _Photos(
            queued: _queued,
            stepId: _step.id,
            onAdd: widget.readOnly || _busy ? null : _addPhoto,
          ),
          const SizedBox(height: 16.0),
          // Дефект тут привязывается к самому пункту, а не только к ТО:
          // «трос изношен» на пункте про тросы прораб поймёт без пересказа.
          // Пункт без номера привязать не к чему — там же, где нельзя
          // сфотографировать, нельзя и записать дефект.
          if (!widget.readOnly && _step.id != null)
            Align(
              alignment: Alignment.centerLeft,
              child: MechanicQuietButton(
                icon: mechanicDefectIcon,
                label: 'Дефект по пункту',
                ink: ColorApp.myColorGray,
                onTap: _reportDefect,
              ),
            ),
          const SizedBox(height: 8.0),
          if (!widget.readOnly)
            _Button(label: 'Сохранить и вернуться', onTap: _busy ? null : _save),
        ],
      ),
    );
  }

  /// Дефект на этом пункте: тихое действие, как в карточке ТО.
  ///
  /// Ни отметки, ни комментария, ни `_busy` — чек-лист не двигается. Механик
  /// записал найденное и вернулся к пункту в том же виде, в каком его
  /// оставил: несохранённый комментарий в поле остаётся на месте.
  Future<void> _reportDefect() async {
    final int? stepId = _step.id;
    if (stepId == null) return;

    final DefectDraft? draft = await showDefectSheet(context);
    if (draft == null || !mounted) return;

    await MechanicWorkspace.current?.sendDefect(
      link: DefectLink.act(_act.id, stepId: stepId),
      title: draft.title,
      description: draft.description,
      photos: draft.photos,
    );
    if (!mounted) return;
    _say('Дефект «${draft.title}» записан.');
  }

  /// Сохраняет отметку и комментарий одной правкой чек-листа.
  Future<void> _save() async {
    final String text = _comment.text.trim();
    final ActDetails next = _act.withStepAt(
      widget.index,
      ActStep(
        id: _step.id,
        title: _step.title,
        done: _done,
        comment: text.isEmpty ? null : text,
      ),
    );

    setState(() {
      _act = next;
      _busy = true;
    });

    await MechanicWorkspace.current?.sendActChecklist(
      act: next,
      title: 'ТО №${next.id} — ${progressText(next.doneCount, next.total)}',
    );
    if (!mounted) return;
    setState(() => _busy = false);
    Navigator.of(context).pop(next);
  }

  Future<void> _addPhoto() async {
    final int? stepId = _step.id;
    if (stepId == null) return;

    if (_queued >= _photoLimit) {
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

      await MechanicWorkspace.current?.attachStepPhoto(
        actId: _act.id,
        stepId: stepId,
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

class _Photos extends StatelessWidget {
  const _Photos({required this.queued, required this.stepId, required this.onAdd});

  final int queued;
  final int? stepId;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    if (stepId == null) {
      return const _Card(
        children: <Widget>[
          Text('Фотографии', style: MechanicLayout.sectionTitle),
          SizedBox(height: 8.0),
          Text(
            'У этого пункта нет номера — снимку не к чему привязаться. '
            'Номер появится, когда прораб сохранит регламент.',
            style: MechanicLayout.cardSubtitle,
          ),
        ],
      );
    }

    return _Card(
      children: <Widget>[
        Row(
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
              style: TextButton.styleFrom(
                foregroundColor: ColorApp.myColorGreenAuth,
              ),
            ),
          ],
        ),
        if (queued > 0) ...<Widget>[
          const SizedBox(height: 12.0),
          Wrap(
            spacing: 10.0,
            runSpacing: 10.0,
            children: <Widget>[
              for (int index = 0; index < queued; index++) const _Waiting(),
            ],
          ),
        ],
        const SizedBox(height: 12.0),
        const Text(
          'Снимок сжимается на входе и ждёт связи в очереди.',
          style: TextStyle(fontSize: 12.0, color: ColorApp.myColorGray),
        ),
      ],
    );
  }
}

/// Плитка снимка, который ещё не ушёл.
///
/// Сам снимок не показываем: он лежит в очереди в base64, и держать его в
/// памяти экрана ради предпросмотра — это мегабайты на пустом месте.
class _Waiting extends StatelessWidget {
  const _Waiting();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96.0,
      height: 72.0,
      padding: const EdgeInsets.all(6.0),
      alignment: Alignment.bottomLeft,
      decoration: BoxDecoration(
        color: ColorApp.myColorGrayBorder,
        borderRadius: BorderRadius.circular(MechanicLayout.cardRadius),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
        decoration: BoxDecoration(
          color: ColorApp.myColorYellow,
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: const Text(
          'ждёт связи',
          style: TextStyle(
            fontSize: 9.0,
            fontWeight: FontWeight.w500,
            color: ColorApp.myColorWhite,
          ),
        ),
      ),
    );
  }
}

class _Box extends StatelessWidget {
  const _Box({required this.done});

  final bool done;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24.0,
      height: 24.0,
      decoration: BoxDecoration(
        color: done ? ColorApp.myColorGreenAuth : ColorApp.myColorWhite,
        border: done
            ? null
            : Border.all(color: ColorApp.myColorGrayBorder, width: 2.0),
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: done
          ? const Icon(Icons.check, size: 16.0, color: ColorApp.myColorWhite)
          : null,
    );
  }
}

class _Button extends StatelessWidget {
  const _Button({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48.0,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorApp.myColorGreenAuth,
          foregroundColor: ColorApp.myColorWhite,
          elevation: 0.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MechanicLayout.cardRadius),
          ),
        ),
        child: Text(label, style: const TextStyle(fontSize: 15.0)),
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
