/// Карточка планового ТО — кадр «Информация о ТО» `1826:296`.
///
/// Что здесь есть сверх кадра и почему:
///
/// * **Предпросмотр регламента.** В кадре пункты появляются только после
///   начала работ. Механик же решает «браться ли сейчас» именно по составу
///   регламента, поэтому первые пункты и их число видны сразу, до нажатия
///   «Начать ТО»: список открывается на просмотр, отметки в нём недоступны.
/// * **Состояние работы словами.** У работы пять состояний — не начато, в
///   работе, приостановлено, проблема, завершено, — и они меняют единственную
///   зелёную кнопку экрана. В кадре кнопка одна и всегда одинаковая.
/// * **Пауза и проблема тихими действиями под кнопкой.** Механик приходит
///   сюда работать, а не выбирать из трёх равноправных кнопок; приостановить
///   работу и сообщить о проблеме нужно редко, и в макете их нет вовсе.
///
/// Даты берутся из строки списка ТО (`task.raw`), а не из ответа акта: в
/// списке они числом, в акте строкой ISO, и два представления одного времени
/// рано или поздно разъедутся — см. `data/acts.dart`.
library;

import 'package:flutter/material.dart';

import '../../helper/class_colors.dart';
import '../data/acts.dart';
import '../data/local_store.dart';
import '../data/mechanic_workspace.dart';
import '../data/tasks.dart';
import '../mechanic_theme.dart';
import 'act_info_screen.dart';
import 'act_steps_screen.dart';
import 'close_act_sheet.dart';
import 'defect_sheet.dart';

/// Сколько пунктов показываем в предпросмотре.
///
/// Три: этого хватает, чтобы понять, о чём регламент, и карточка при этом
/// целиком помещается на экран телефона без прокрутки.
const int _previewLimit = 3;

class MechanicActScreen extends StatefulWidget {
  const MechanicActScreen({Key? key, required this.task}) : super(key: key);

  final MechanicTask task;

  @override
  State<MechanicActScreen> createState() => _MechanicActScreenState();
}

class _MechanicActScreenState extends State<MechanicActScreen> {
  ActDetails? _act;
  bool _loading = true;
  bool _busy = false;

  /// Отметки о ходе работы. Держим их в состоянии экрана, потому что отметка
  /// уходит в очередь и в локальную базу, а строка списка, с которой экран
  /// открыли, остаётся прежней до следующего перечитывания.
  late int? _startedAt = asInt(widget.task.raw['started_at']);
  late int? _finishedAt = asInt(widget.task.raw['finished_at']);
  late int? _statusId = asInt(widget.task.raw['status_id']);
  late int? _pausedAt = asInt(widget.task.raw['paused_at']);
  late String? _commentary = asString(widget.task.raw['commentary']);

  /// Состояние работы считает [maintenanceState] — то же, что и для списка.
  /// Второй разбор тех же полей рано или поздно разошёлся бы с первым, и
  /// карточка говорила бы одно, а строка списка другое.
  MaintenanceState get _state => maintenanceState(<String, dynamic>{
        'started_at': _startedAt,
        'finished_at': _finishedAt,
        'status_id': _statusId,
      });

  bool get _started => _state != MaintenanceState.notStarted && !_closed;

  bool get _closed => _finishedAt != null;

  /// Отмечать пункты можно, только пока работа идёт: приостановленное ТО
  /// потому и приостановлено, что механик занят другим. Посмотреть регламент
  /// при этом можно всегда.
  bool get _editable => _state == MaintenanceState.inWork;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final ActDetails? act =
        await MechanicWorkspace.current?.loadAct(widget.task.id);
    if (!mounted) return;
    setState(() {
      _act = act;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final MechanicTask task = widget.task;

    return Scaffold(
      backgroundColor: ColorApp.myColorTransparent,
      appBar: AppBar(
        backgroundColor: ColorApp.myColorWhite,
        foregroundColor: ColorApp.myColorBlack,
        elevation: 0.0,
        title: const Text('Плановое ТО', style: MechanicLayout.sectionTitle),
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
                task.title,
                style: MechanicLayout.screenTitle.copyWith(fontSize: 20.0),
              ),
              if (task.address != null) ...<Widget>[
                const SizedBox(height: 6.0),
                Text(task.address!, style: MechanicLayout.cardSubtitle),
              ],
              const SizedBox(height: 12.0),
              _Line(label: 'Состояние', value: _stateText()),
              _Line(label: 'Срок', value: _dueText()),
              _Line(label: 'Регламент', value: _ruleText()),
              _Line(label: 'Начато', value: _startText()),
            ],
          ),
          const SizedBox(height: 16.0),
          _Rules(
            act: _act,
            loading: _loading,
            onOpen: _act == null ? null : () => _openSteps(view: !_editable),
          ),
          const SizedBox(height: 16.0),
          _InfoRow(onTap: () => _openInfo(task)),
          const SizedBox(height: 16.0),
          ..._actions(),
        ],
      ),
    );
  }

  List<Widget> _actions() {
    if (_closed) return <Widget>[const _Done()];
    if (_loading) return <Widget>[];

    final ActDetails? act = _act;
    if (act == null) {
      return <Widget>[
        const _Note(
          'Регламент ещё не загружен. Откройте это ТО хотя бы раз на связи — '
          'дальше он будет открываться и без неё.',
        ),
      ];
    }
    if (act.empty) {
      return <Widget>[
        const _Note(
          'В акте нет ни одного пункта. Регламент вносит прораб — до этого '
          'отмечать нечего.',
        ),
      ];
    }

    // Одна зелёная кнопка в любом состоянии, тихие действия под ней. Три
    // равноправные кнопки на этом экране означали бы, что механик каждый раз
    // выбирает из трёх, — а он в девяти случаях из десяти просто идёт
    // работать. Какие кнопки положены в этом состоянии, решает [actControls].
    final ActControls controls = actControls(
      _state,
      allDone: act.doneCount == act.total,
    );

    return <Widget>[
      if (_state == MaintenanceState.paused || _state == MaintenanceState.problem)
        _StatePlate(
          state: _state,
          progress: progressText(act.doneCount, act.total),
          pausedAt: _pausedAt,
          commentary: _commentary,
        ),
      _Button(
        label: controls.mainLabel,
        onTap: _busy ? null : () => _mainAction(controls.main),
      ),
      if (controls.canPause ||
          controls.canReportProblem ||
          controls.canReportDefect)
        _QuietActions(
          controls: controls,
          onPause: _busy ? null : _pause,
          onProblem: _busy ? null : _reportProblem,
          onDefect: _busy ? null : _reportDefect,
        ),
      const _Note(
        'Отметка ложится в телефон сразу и уходит на сервер, как появится связь.',
      ),
    ];
  }

  Future<void> _mainAction(ActAction action) {
    return action == ActAction.close ? _close() : _start();
  }

  /// «Начать ТО» и «Продолжить ТО» — одна кнопка и один путь: работа после неё
  /// идёт, и экран шагов открыт на отметки.
  ///
  /// Повторное открытие уже начатого ТО время начала не сдвигает: `started_at`
  /// отвечает на вопрос «когда механик взялся», и переписывать его при каждом
  /// заходе значит потерять этот ответ. Возобновление после паузы двигает
  /// только статус.
  Future<void> _start() async {
    final ActDetails? act = _act;
    if (act == null) return;

    if (!_started) {
      setState(() => _busy = true);
      await MechanicWorkspace.current?.sendActChecklist(
        act: act,
        title: 'ТО №${act.id} — начато',
        start: true,
      );
      if (!mounted) return;
      setState(() {
        _startedAt = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        _statusId = OrderStatus.inProgress;
        _pausedAt = null;
        _busy = false;
      });
    } else if (!_editable) {
      await _sendState(
        statusId: OrderStatus.inProgress,
        title: 'ТО №${act.id} — работа продолжена',
      );
      if (!mounted) return;
    }

    await _openSteps(view: false);
  }

  /// Пауза — одно нажатие и без вопросов: её жмут, когда уже приехал
  /// аварийный вызов, а не когда есть время заполнять форму. Отметки остаются
  /// на месте, вернуться можно той же кнопкой «Продолжить ТО».
  Future<void> _pause() async {
    final ActDetails? act = _act;
    if (act == null) return;

    await _sendState(
      statusId: OrderStatus.accepted,
      title: 'ТО №${act.id} — приостановлено',
      paused: true,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Работа приостановлена.')),
    );
  }

  /// «Проблема» — единственное состояние, которое спрашивает причину: прорабу
  /// мало знать, что работа встала, ему разбираться почему.
  Future<void> _reportProblem() async {
    final ActDetails? act = _act;
    if (act == null) return;

    final String? reason = await _showProblemSheet(context);
    if (reason == null || !mounted) return;

    await _sendState(
      statusId: OrderStatus.problem,
      title: 'ТО №${act.id} — проблема',
      commentary: reason,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Прораб увидит проблему в своём списке.')),
    );
  }

  /// «Дефект» — единственное тихое действие, которое не трогает состояние
  /// работы: механик записывает найденное и идёт дальше по чек-листу. Прораб
  /// увидит дефект отдельной записью, а не сменой статуса ТО.
  Future<void> _reportDefect() async {
    final ActDetails? act = _act;
    if (act == null) return;

    final DefectDraft? draft = await showDefectSheet(context);
    if (draft == null || !mounted) return;

    // Логика отправки — следующим шагом этапа; сейчас лист утверждается
    // внешним видом.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Дефект «${draft.title}» записан.')),
    );
  }

  Future<void> _sendState({
    required int statusId,
    required String title,
    bool paused = false,
    String? commentary,
  }) async {
    final ActDetails? act = _act;
    if (act == null) return;

    setState(() => _busy = true);
    await MechanicWorkspace.current?.sendActState(
      actId: act.id,
      statusId: statusId,
      title: title,
      paused: paused,
      commentary: commentary,
    );
    if (!mounted) return;
    setState(() {
      _statusId = statusId;
      _pausedAt = paused ? DateTime.now().millisecondsSinceEpoch ~/ 1000 : null;
      if (commentary != null && commentary.trim().isNotEmpty) {
        _commentary = commentary.trim();
      }
      _busy = false;
    });
  }

  /// Завершение работы с карточки — то же действие, что кнопка внизу
  /// чек-листа, и лист подтверждения у них общий.
  Future<void> _close() async {
    final ActDetails? act = _act;
    if (act == null) return;

    final Map<int, int> counts =
        await MechanicWorkspace.current?.queuedStepPhotoCounts(act.id) ??
            <int, int>{};
    final int queued =
        counts.values.fold<int>(0, (int sum, int count) => sum + count);
    if (!mounted) return;

    final CloseActChoice? choice = await showCloseActSheet(
      context,
      task: widget.task,
      act: act,
      queuedPhotos: queued,
      cancelLabel: 'Не сейчас',
    );
    if (choice == null || !mounted) return;

    setState(() => _busy = true);
    await MechanicWorkspace.current?.sendActChecklist(
      act: act,
      title: 'ТО №${act.id} — работа завершена',
      finish: true,
      commentary: choice.commentary,
    );
    if (!mounted) return;
    setState(() {
      _finishedAt = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      _statusId = OrderStatus.done;
      _pausedAt = null;
      _busy = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Работа завершена. Уйдёт на сервер, как появится связь.'),
      ),
    );
  }

  Future<void> _openSteps({required bool view}) async {
    final ActDetails? act = _act;
    if (act == null) return;

    final ActDetails? changed = await Navigator.of(context).push<ActDetails>(
      MaterialPageRoute<ActDetails>(
        builder: (BuildContext context) => MechanicActStepsScreen(
          task: widget.task,
          act: act,
          viewOnly: view || _closed,
        ),
      ),
    );
    if (!mounted || changed == null) return;
    setState(() => _act = changed);
    await _reloadMarks();
  }

  /// Перечитывает отметки о ходе работы из локальной базы: закрытие акта
  /// происходит на экране шагов, а показывает его эта карточка.
  Future<void> _reloadMarks() async {
    final MechanicWorkspace? workspace = MechanicWorkspace.current;
    if (workspace == null) return;

    final List<Map<String, dynamic>> rows =
        await workspace.localStore.read(LocalCollection.maintenance);
    for (final Map<String, dynamic> row in rows) {
      if (asInt(row['act_id']) != widget.task.id) continue;
      if (!mounted) return;
      setState(() {
        _startedAt = asInt(row['started_at']);
        _finishedAt = asInt(row['finished_at']);
        _statusId = asInt(row['status_id']);
        _pausedAt = asInt(row['paused_at']);
        _commentary = asString(row['commentary']);
      });
      return;
    }
  }

  void _openInfo(MechanicTask task) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => MechanicActInfoScreen(
          task: task,
          act: _act,
          startedAt: _startedAt,
          finishedAt: _finishedAt,
        ),
      ),
    );
  }

  String _stateText() => maintenanceStateName(_state);

  String _dueText() {
    final int? year = asInt(widget.task.raw['year']);
    final int? month = asInt(widget.task.raw['month']);
    if (year == null || month == null) return '—';
    final String text = monthText(year, month);
    return '${text[0].toUpperCase()}${text.substring(1)}';
  }

  String _ruleText() {
    final ActDetails? act = _act;
    if (act == null) return _loading ? 'Загружается…' : '—';
    final String name = act.title ?? 'Без названия';
    return act.empty ? '$name, пунктов нет' : '$name, ${act.total} п.';
  }

  String _startText() {
    final int? at = _startedAt;
    return at == null ? '—' : dayText(at);
  }
}

/// Предпросмотр регламента: первые пункты и сколько их всего.
///
/// Отметить пункт отсюда нельзя, и это видно по виду — квадратики серые, без
/// заливки. Смотреть регламент можно, не начиная работу; отмечать — только на
/// экране шагов, и только после начала.
class _Rules extends StatelessWidget {
  const _Rules({required this.act, required this.loading, required this.onOpen});

  final ActDetails? act;
  final bool loading;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final ActDetails? act = this.act;

    if (act == null) {
      return _Card(
        children: <Widget>[
          const Text('Регламент', style: MechanicLayout.sectionTitle),
          const SizedBox(height: 8.0),
          Text(
            loading ? 'Загружается…' : 'Не загружен',
            style: MechanicLayout.cardSubtitle,
          ),
        ],
      );
    }

    final List<ActStep> shown = act.steps.take(_previewLimit).toList();
    final int rest = act.total - shown.length;

    return Material(
      color: ColorApp.myColorWhite,
      borderRadius: BorderRadius.circular(MechanicLayout.cardRadius),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(MechanicLayout.cardRadius),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      act.title == null ? 'Регламент' : 'Регламент ${act.title}',
                      style: MechanicLayout.sectionTitle,
                    ),
                  ),
                  Text(
                    act.empty ? 'пунктов нет' : '${act.total} п.',
                    style: MechanicLayout.cardSubtitle,
                  ),
                ],
              ),
              if (act.empty) ...<Widget>[
                const SizedBox(height: 8.0),
                const Text(
                  'Пункты в акт вносит прораб.',
                  style: MechanicLayout.cardSubtitle,
                ),
              ] else ...<Widget>[
                const SizedBox(height: 8.0),
                for (final ActStep step in shown)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        _Box(done: step.done),
                        const SizedBox(width: 10.0),
                        Expanded(
                          child: Text(
                            step.title,
                            style: const TextStyle(
                              fontSize: 13.0,
                              fontWeight: FontWeight.w300,
                              color: Color(0xff1C1C1E),
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 6.0),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          rest > 0 ? 'Ещё ${_plural(rest)}' : 'Открыть регламент',
                          style: const TextStyle(
                            fontSize: 13.0,
                            fontWeight: FontWeight.w300,
                            color: ColorApp.myColorGray,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        size: 20.0,
                        color: Color(0xff717E95),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static String _plural(int count) {
    final int mod100 = count % 100;
    final int mod10 = count % 10;
    if (mod100 >= 11 && mod100 <= 14) return '$count пунктов';
    if (mod10 == 1) return '$count пункт';
    if (mod10 >= 2 && mod10 <= 4) return '$count пункта';
    return '$count пунктов';
  }
}

/// Квадратик пункта. Отмеченный зелёный, остальные серые контуром.
class _Box extends StatelessWidget {
  const _Box({required this.done});

  final bool done;

  /// Квадратик предпросмотра меньше, чем на экране шагов: здесь его не
  /// нажимают, и он не должен спорить с текстом пункта.
  static const double size = 18.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      margin: const EdgeInsets.only(top: 2.0),
      decoration: BoxDecoration(
        color: done ? ColorApp.myColorGreenAuth : ColorApp.myColorWhite,
        border: done
            ? null
            : Border.all(color: ColorApp.myColorGrayBorder, width: 1.5),
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: done
          ? const Icon(
              Icons.check,
              size: size - 5.0,
              color: ColorApp.myColorWhite,
            )
          : null,
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ColorApp.myColorWhite,
      borderRadius: BorderRadius.circular(MechanicLayout.cardRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(MechanicLayout.cardRadius),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 18.0),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text('Подробнее о ТО', style: MechanicLayout.rowLabel),
              ),
              Icon(Icons.chevron_right, size: 22.0, color: Color(0xff717E95)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Плашка вставшей работы: почему она стоит и сколько успели сделать.
///
/// Стоит над кнопкой, а не в строке «Состояние»: строка отвечает на вопрос
/// «что с этим ТО», а плашка — на вопрос «почему я вижу здесь „Продолжить“,
/// хотя ничего не делаю». Прогресс в ней тот же, что в списке.
class _StatePlate extends StatelessWidget {
  const _StatePlate({
    required this.state,
    required this.progress,
    this.pausedAt,
    this.commentary,
  });

  final MaintenanceState state;
  final String progress;
  final int? pausedAt;
  final String? commentary;

  @override
  Widget build(BuildContext context) {
    final bool problem = state == MaintenanceState.problem;
    final Color ink = problem ? ColorApp.myColorRed : ColorApp.myColorYellow;
    final int? at = pausedAt;

    final String text = problem
        ? (commentary?.trim().isNotEmpty == true
            ? '${commentary!.trim()}. Отмечено $progress.'
            : 'Прораб разбирается. Отмечено $progress.')
        : at == null
            ? 'Отмечено $progress. Работа ждёт вас.'
            : 'Отмечено $progress. Работа стоит с ${dayTimeText(at)}.';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12.0),
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: ink.withOpacity(0.12),
        borderRadius: BorderRadius.circular(MechanicLayout.cardRadius),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            problem ? Icons.error_outline : Icons.pause_circle_outline,
            size: 18.0,
            color: ink,
          ),
          const SizedBox(width: 8.0),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13.0,
                height: 1.4,
                color: Color(0xff1C1C1E),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Пауза и проблема — строкой под зелёной кнопкой.
///
/// Тихие, потому что редкие: сделать их равноправными кнопками значит каждый
/// раз предлагать механику выбор из трёх, хотя обычно он просто идёт работать.
class _QuietActions extends StatelessWidget {
  const _QuietActions({
    required this.controls,
    required this.onPause,
    required this.onProblem,
    required this.onDefect,
  });

  /// Какие действия положены в этом состоянии. Занятость экрана — отдельно:
  /// на время отправки кнопка гаснет, но не исчезает, иначе строка под
  /// кнопкой прыгает на каждое нажатие.
  final ActControls controls;

  final VoidCallback? onPause;
  final VoidCallback? onProblem;
  final VoidCallback? onDefect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: <Widget>[
          if (controls.canPause)
            Expanded(
              child: _QuietButton(
                icon: Icons.pause_circle_outline,
                label: 'Приостановить',
                ink: ColorApp.myColorGray,
                onTap: onPause,
              ),
            ),
          if (controls.canReportProblem)
            Expanded(
              child: _QuietButton(
                icon: Icons.error_outline,
                label: 'Проблема',
                ink: ColorApp.myColorRed,
                onTap: onProblem,
              ),
            ),
          if (controls.canReportDefect)
            Expanded(
              child: _QuietButton(
                icon: Icons.report_gmailerrorred_outlined,
                label: 'Дефект',
                ink: ColorApp.myColorGray,
                onTap: onDefect,
              ),
            ),
        ],
      ),
    );
  }
}

class _QuietButton extends StatelessWidget {
  const _QuietButton({
    required this.icon,
    required this.label,
    required this.ink,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color ink;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40.0,
      child: TextButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18.0),
        // Кнопок в строке бывает три, и «Приостановить» на экране 375 точек
        // в треть строки не влезает. Уменьшить подпись честнее, чем оборвать
        // её многоточием: «Приостанови…» человек читать не должен.
        label: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(label, style: const TextStyle(fontSize: 14.0)),
        ),
        style: TextButton.styleFrom(
          foregroundColor: ink,
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
        ),
      ),
    );
  }
}

/// Лист «Проблема»: причина и ничего лишнего.
///
/// Причина обязательна — в этом вся разница между проблемой и паузой. Статус
/// «стоит» прораб и так увидит, а вот что именно случилось, кроме механика,
/// сказать некому.
Future<String?> _showProblemSheet(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: ColorApp.myColorWhite,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(12.0)),
    ),
    builder: (BuildContext context) => const _ProblemSheet(),
  );
}

class _ProblemSheet extends StatefulWidget {
  const _ProblemSheet();

  @override
  State<_ProblemSheet> createState() => _ProblemSheetState();
}

class _ProblemSheetState extends State<_ProblemSheet> {
  final TextEditingController _reason = TextEditingController();
  bool _empty = true;

  @override
  void initState() {
    super.initState();
    _reason.addListener(() {
      final bool empty = _reason.text.trim().isEmpty;
      if (empty != _empty) setState(() => _empty = empty);
    });
  }

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            const Text(
              'Что мешает доделать?',
              style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10.0),
            const Text(
              'Работа встанет, а прораб увидит причину у себя. Отметки '
              'останутся на месте.',
              style: TextStyle(
                fontSize: 14.0,
                fontWeight: FontWeight.w300,
                color: Color(0xff1C1C1E),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14.0),
            TextField(
              controller: _reason,
              autofocus: true,
              minLines: 2,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              style: const TextStyle(fontSize: 14.0),
              decoration: InputDecoration(
                hintText: 'Например: нет запчасти на складе',
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
                onPressed: _empty
                    ? null
                    : () => Navigator.of(context).pop(_reason.text.trim()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorApp.myColorRed,
                  foregroundColor: ColorApp.myColorWhite,
                  elevation: 0.0,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(MechanicLayout.cardRadius),
                  ),
                ),
                child: const Text(
                  'Сообщить о проблеме',
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
                child: const Text('Отмена', style: TextStyle(fontSize: 15.0)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Button extends StatelessWidget {
  const _Button({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: SizedBox(
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
              'Работа завершена. Прораб увидит её в ленте сданных.',
              style: TextStyle(fontSize: 13.0, color: ColorApp.myColorGray),
            ),
          ),
        ],
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
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
