/// Чек-лист ТО — кадры «Этапы ТО 1–3» (`1826:392`, `1826:445`, `1848:505`).
///
/// Решения, которые стоит знать:
///
/// * **Отметка пункта отправляет чек-лист целиком.** Отдельной ручки «отметь
///   шаг» на бэкенде нет и не должно быть: пункт со своим номером считается
///   тем же самым, без номера — новым, поэтому список всегда уходит одним
///   куском (`PUT /act-fact/{id}/`). Всё через очередь: без связи отметка
///   ложится в телефон сразу.
/// * **Завершить работу можно и с неотмеченными пунктами.** Бэкенд этого не
///   запрещает — `finished_at` пишется независимо от чек-листа, — и запрещать
///   на телефоне мы не стали: механик приехал, часть работ не сделал, и
///   заставлять его врать в чек-листе ради завершения хуже, чем показать
///   прорабу «5 из 8». Но спрашиваем подтверждение и пишем в нём, чего не
///   хватает.
/// * **Просмотр без начала работы.** С карточки сюда можно зайти до нажатия
///   «Начать ТО» — тогда экран открыт на чтение: квадратики серые, нижней
///   панели нет. Это ответ на вопрос «а что там делать надо», который механик
///   задаёт до того, как берётся.
library;

import 'package:flutter/material.dart';

import '../../helper/class_colors.dart';
import '../data/acts.dart';
import '../data/mechanic_workspace.dart';
import '../data/tasks.dart';
import '../mechanic_theme.dart';
import 'act_step_screen.dart';
import 'close_act_sheet.dart';

class MechanicActStepsScreen extends StatefulWidget {
  const MechanicActStepsScreen({
    Key? key,
    required this.task,
    required this.act,
    this.viewOnly = false,
  }) : super(key: key);

  final MechanicTask task;
  final ActDetails act;

  /// Только смотреть: работа ещё не начата или акт уже закрыт.
  final bool viewOnly;

  @override
  State<MechanicActStepsScreen> createState() => _MechanicActStepsScreenState();
}

class _MechanicActStepsScreenState extends State<MechanicActStepsScreen> {
  late ActDetails _act = widget.act;
  Map<int, int> _photos = <int, int>{};
  bool _busy = false;
  bool _closed = false;

  @override
  void initState() {
    super.initState();
    _countPhotos();
  }

  Future<void> _countPhotos() async {
    final Map<int, int> counts =
        await MechanicWorkspace.current?.queuedStepPhotoCounts(widget.act.id) ??
            <int, int>{};
    if (mounted) setState(() => _photos = counts);
  }

  bool get _readOnly => widget.viewOnly || _closed;

  @override
  Widget build(BuildContext context) {
    final int left = _act.total - _act.doneCount;

    return Scaffold(
      backgroundColor: ColorApp.myColorTransparent,
      appBar: AppBar(
        backgroundColor: ColorApp.myColorWhite,
        foregroundColor: ColorApp.myColorBlack,
        elevation: 0.0,
        title: Text(
          _act.title == null ? 'Регламент' : 'Регламент ${_act.title}',
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
          _Progress(act: _act, subtitle: _subtitle(left)),
          const SizedBox(height: 16.0),
          _Steps(
            act: _act,
            photos: _photos,
            readOnly: _readOnly,
            onToggle: _busy ? null : _toggle,
            onOpen: _open,
          ),
          if (_readOnly) ...<Widget>[
            const SizedBox(height: 16.0),
            _Note(
              _closed
                  ? 'Работа завершена. Прораб увидит её в ленте сданных.'
                  : 'Это просмотр. Чтобы отмечать пункты, начните ТО в карточке.',
            ),
          ],
        ],
      ),
      bottomNavigationBar: _readOnly || _act.empty
          ? null
          : _Bottom(
              left: left,
              onClose: _busy ? null : _confirmClose,
            ),
    );
  }

  String _subtitle(int left) {
    if (_act.empty) return 'В акте нет ни одного пункта.';
    if (left == 0) return 'Все пункты отмечены.';
    return 'Осталось $left из ${_act.total}.';
  }

  /// Отметка пункта: сразу в состояние экрана, потом в очередь.
  Future<void> _toggle(int index) async {
    final ActStep step = _act.steps[index];
    final ActDetails next =
        _act.withStepAt(index, step.copyWith(done: !step.done));

    setState(() {
      _act = next;
      _busy = true;
    });

    await MechanicWorkspace.current?.sendActChecklist(
      act: next,
      title: 'ТО №${next.id} — ${progressText(next.doneCount, next.total)}',
    );
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _open(int index) async {
    final ActDetails? changed = await Navigator.of(context).push<ActDetails>(
      MaterialPageRoute<ActDetails>(
        builder: (BuildContext context) => MechanicActStepScreen(
          act: _act,
          index: index,
          readOnly: _readOnly,
        ),
      ),
    );
    if (!mounted) return;
    if (changed != null) setState(() => _act = changed);
    await _countPhotos();
  }

  /// Подтверждение — кадра в макете нет, лист собран из приёмов соседних.
  /// Спрашиваем всегда: снять завершение с телефона нечем.
  ///
  /// Тот же лист показывает карточка ТО по кнопке «Завершить работу»: это одно
  /// и то же действие, и живёт оно в `close_act_sheet.dart`.
  Future<void> _confirmClose() async {
    final int queued =
        _photos.values.fold<int>(0, (int sum, int count) => sum + count);

    final CloseActChoice? choice = await showCloseActSheet(
      context,
      task: widget.task,
      act: _act,
      queuedPhotos: queued,
    );
    if (choice == null || !mounted) return;

    setState(() => _busy = true);
    await MechanicWorkspace.current?.sendActChecklist(
      act: _act,
      title: 'ТО №${_act.id} — работа завершена',
      finish: true,
      commentary: choice.commentary,
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _closed = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Работа завершена. Уйдёт на сервер, как появится связь.'),
      ),
    );
    Navigator.of(context).pop(_act);
  }
}

class _Progress extends StatelessWidget {
  const _Progress({required this.act, required this.subtitle});

  final ActDetails act;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final double part = act.total == 0 ? 0.0 : act.doneCount / act.total;

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
        children: <Widget>[
          Text(
            act.empty
                ? 'Регламент не заполнен'
                : 'Пройдено ${progressText(act.doneCount, act.total)}',
            style: MechanicLayout.sectionTitle,
          ),
          const SizedBox(height: 8.0),
          ClipRRect(
            borderRadius: BorderRadius.circular(3.0),
            child: LinearProgressIndicator(
              value: part,
              minHeight: 6.0,
              backgroundColor: ColorApp.myColorGrayBorder,
              valueColor: const AlwaysStoppedAnimation<Color>(
                ColorApp.myColorGreenAuth,
              ),
            ),
          ),
          const SizedBox(height: 8.0),
          Text(subtitle, style: MechanicLayout.cardSubtitle),
        ],
      ),
    );
  }
}

class _Steps extends StatelessWidget {
  const _Steps({
    required this.act,
    required this.photos,
    required this.readOnly,
    required this.onToggle,
    required this.onOpen,
  });

  final ActDetails act;

  /// Сколько снимков шага ждёт связи, по номеру шага.
  final Map<int, int> photos;

  final bool readOnly;
  final ValueChanged<int>? onToggle;
  final ValueChanged<int> onOpen;

  @override
  Widget build(BuildContext context) {
    if (act.empty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: ColorApp.myColorWhite,
          borderRadius: BorderRadius.circular(MechanicLayout.cardRadius),
        ),
        child: const Text(
          'Пункты в акт вносит прораб. Пока их нет, отмечать нечего.',
          style: MechanicLayout.cardSubtitle,
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: ColorApp.myColorWhite,
        borderRadius: BorderRadius.circular(MechanicLayout.cardRadius),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: <Widget>[
          for (int index = 0; index < act.steps.length; index++)
            _StepRow(
              step: act.steps[index],
              queuedPhotos: photos[act.steps[index].id] ?? 0,
              last: index == act.steps.length - 1,
              readOnly: readOnly,
              onToggle: onToggle == null ? null : () => onToggle!(index),
              onOpen: () => onOpen(index),
            ),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({
    required this.step,
    required this.queuedPhotos,
    required this.last,
    required this.readOnly,
    required this.onToggle,
    required this.onOpen,
  });

  final ActStep step;
  final int queuedPhotos;
  final bool last;
  final bool readOnly;
  final VoidCallback? onToggle;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final List<Widget> marks = <Widget>[
      if (step.comment != null) const _Pill('Комментарий'),
      if (queuedPhotos > 0) _Pill('$queuedPhotos ждёт связи', warning: true),
    ];

    return DecoratedBox(
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(bottom: BorderSide(color: MechanicLayout.divider)),
      ),
      child: InkWell(
        onTap: onOpen,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                // Отдельная зона нажатия у квадратика: отметить пункт — самое
                // частое действие, и ради него открывать экран шага незачем.
                InkWell(
                  onTap: readOnly ? null : onToggle,
                  borderRadius: BorderRadius.circular(4.0),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: _Box(done: step.done, muted: readOnly),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(step.title, style: MechanicLayout.rowValue),
                      if (marks.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 6.0),
                        Wrap(spacing: 6.0, runSpacing: 6.0, children: marks),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8.0),
                const Icon(
                  Icons.chevron_right,
                  size: 22.0,
                  color: Color(0xff717E95),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Box extends StatelessWidget {
  const _Box({required this.done, this.muted = false});

  final bool done;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final Color fill = muted ? ColorApp.myColorGreen : ColorApp.myColorGreenAuth;

    return Container(
      width: 24.0,
      height: 24.0,
      decoration: BoxDecoration(
        color: done ? fill : ColorApp.myColorWhite,
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

class _Pill extends StatelessWidget {
  const _Pill(this.text, {this.warning = false});

  final String text;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
      decoration: BoxDecoration(
        color: warning
            ? ColorApp.myColorYellow.withOpacity(0.14)
            : ColorApp.myColorGrayShadow,
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11.0,
          fontWeight: FontWeight.w500,
          color: warning ? ColorApp.myColorYellow : ColorApp.myColorGray,
        ),
      ),
    );
  }
}

/// Нижняя панель: чего не хватает и кнопка закрытия.
class _Bottom extends StatelessWidget {
  const _Bottom({required this.left, required this.onClose});

  final int left;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: ColorApp.myColorWhite,
      padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 16.0),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (left > 0) ...<Widget>[
              Row(
                children: <Widget>[
                  _Pill('$left не отмечено', warning: true),
                  const SizedBox(width: 8.0),
                  const Expanded(
                    child: Text(
                      'спросим подтверждение',
                      style: MechanicLayout.cardSubtitle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10.0),
            ],
            SizedBox(
              height: 48.0,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onClose,
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
          ],
        ),
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Padding(
          padding: EdgeInsets.only(top: 1.0),
          child: Icon(
            Icons.info_outline,
            size: 18.0,
            color: ColorApp.myColorGray,
          ),
        ),
        const SizedBox(width: 8.0),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 12.0, color: ColorApp.myColorGray),
          ),
        ),
      ],
    );
  }
}
