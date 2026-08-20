/// Карточка планового ТО — кадр «Информация о ТО» `1826:296`.
///
/// Что здесь есть сверх кадра и почему:
///
/// * **Предпросмотр регламента.** В кадре пункты появляются только после
///   начала работ. Механик же решает «браться ли сейчас» именно по составу
///   регламента, поэтому первые пункты и их число видны сразу, до нажатия
///   «Начать ТО»: список открывается на просмотр, отметки в нём недоступны.
/// * **Состояние работы словами.** У акта три состояния — не начато, в
///   работе, сдано, — и они меняют единственную кнопку экрана. В кадре кнопка
///   одна и всегда одинаковая.
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

  bool get _started => _startedAt != null;

  bool get _closed => _finishedAt != null;

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
            onOpen: _act == null ? null : () => _openSteps(view: !_started),
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

    return <Widget>[
      _Button(
        label: _started ? 'Продолжить ТО' : 'Начать ТО',
        onTap: _busy ? null : _start,
      ),
      const _Note(
        'Отметка ложится в телефон сразу и уходит на сервер, как появится связь.',
      ),
    ];
  }

  /// «Начать ТО» — это отметка времени начала, а не переход по статусу.
  ///
  /// Повторное открытие уже начатого ТО время начала не сдвигает: `started_at`
  /// отвечает на вопрос «когда механик взялся», и переписывать его при каждом
  /// заходе значит потерять этот ответ.
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
        _busy = false;
      });
    }

    await _openSteps(view: false);
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

  String _stateText() {
    if (_closed) return 'Сдано';
    if (_started) return 'В работе';
    return 'Не начато';
  }

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
              'Акт закрыт. Прораб увидит работу в ленте сданных.',
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
