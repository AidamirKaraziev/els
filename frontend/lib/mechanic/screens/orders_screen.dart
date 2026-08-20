/// Первая вкладка механика — кадр «Список заявок» `1826:155`.
///
/// Что в кадре и что здесь. Кадр называется «Список заявок», но нарисованы в
/// нём **плановые ТО**: заголовок «Заявки», под ним раздел «Плановые ТО» с
/// листалкой по дням и карточки объектов со сроком. Потока заявки диспетчера —
/// статусов, кнопок, фотографий — в макете нет ни на одном из четырнадцати
/// кадров. Поэтому экран собран так: приёмы оформления взяты из кадра
/// (заголовок 34, разделы 16, белые карточки 343×85 со скруглением 5, зелёный
/// значок в углу, шеврон справа, фон `#F5F6F6`), а состав — из работы
/// механика.
///
/// Разделов четыре, и делятся они **по виду работы**, а не по сроку:
///
/// * **Сейчас** — открытые заявки диспетчера. Аварии сверху.
/// * **Плановые ТО** — всё несданное по графику: просроченное первым и с
///   пометкой, потом текущий месяц, потом будущие.
/// * **Выполнено** — закрытые заявки и сданные ТО. Свёрнуто: это память, а не
///   работа.
/// * **Архив** — снятые задачи, серым и свёрнутым. Молча убрать задачу с
///   экрана нельзя: механик решит, что приложение её потеряло.
///
/// Раньше деление было по сроку — «сейчас» и «планируется», — и заявка с ТО
/// лежали вперемешку. Механик ищет глазами не «что в этом месяце», а «что у
/// меня по заявкам» и «что по графику», поэтому вид работы стал главным.
/// Чтобы срочное не потерялось внутри своей секции, в шапке стоит сводка
/// («1 авария», «2 просрочено»), а на карточке — цветная пометка.
///
/// Листалки по дням из кадра здесь нет намеренно: у заявки в базе нет срока
/// вовсе, а у ТО срок — месяц, дня в графике не существует
/// (`план ТО - заполненная ячейка месяца, а не отдельный признак`). Листалка
/// по дням показывала бы пустые дни и прятала просроченное.
///
/// Кружок слева в кадре — фотография объекта. Ни `GET /order/for-me`, ни
/// `GET /act-fact/for-me` фотографии объекта не отдают (в первом объект
/// приезжает целиком, и поля `photo` в нём нет), поэтому вместо неё значок по
/// виду работы.
library;

import 'package:flutter/material.dart';

import '../../helper/class_colors.dart';
import '../data/local_store.dart';
import '../data/mechanic_workspace.dart';
import '../data/tasks.dart';
import '../mechanic_theme.dart';
import 'order_screen.dart';

class MechanicOrdersScreen extends StatefulWidget {
  const MechanicOrdersScreen({Key? key}) : super(key: key);

  @override
  State<MechanicOrdersScreen> createState() => _MechanicOrdersScreenState();
}

class _MechanicOrdersScreenState extends State<MechanicOrdersScreen> {
  List<MechanicTask> _tasks = <MechanicTask>[];
  bool _loaded = false;

  /// Свёрнутые разделы. Сделанное и архив закрыты: механику нужен короткий
  /// список работы, а не всё, что было.
  final Set<TaskSection> _folded = <TaskSection>{
    TaskSection.done,
    TaskSection.archive,
  };

  @override
  void initState() {
    super.initState();
    _reload();
    MechanicWorkspace.current?.status.addListener(_reload);
  }

  @override
  void dispose() {
    MechanicWorkspace.current?.status.removeListener(_reload);
    super.dispose();
  }

  /// Перечитывает локальную базу.
  ///
  /// Зовётся и на изменение состояния рабочего места: синхронизация принесла
  /// правки, очередь отправила отметку — список обязан это показать.
  Future<void> _reload() async {
    final MechanicWorkspace? workspace = MechanicWorkspace.current;
    if (workspace == null) {
      if (mounted) setState(() => _loaded = true);
      return;
    }

    final List<Map<String, dynamic>> orders =
        await workspace.localStore.read(LocalCollection.orders);
    final List<Map<String, dynamic>> maintenance =
        await workspace.localStore.read(LocalCollection.maintenance);
    if (!mounted) return;

    setState(() {
      _tasks = buildTaskList(
        orders: orders,
        maintenance: maintenance,
        userId: workspace.userId,
        now: DateTime.now(),
      );
      _loaded = true;
    });
  }

  Future<void> _refresh() async {
    await MechanicWorkspace.current?.refresh();
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> body = <Widget>[
      const Padding(
        padding: EdgeInsets.fromLTRB(
          MechanicLayout.screenPadding,
          24.0,
          MechanicLayout.screenPadding,
          16.0,
        ),
        child: Text('Заявки', style: MechanicLayout.screenTitle),
      ),
    ];

    for (final TaskSection section in TaskSection.values) {
      final List<MechanicTask> tasks = tasksOf(_tasks, section);
      if (tasks.isEmpty) continue;
      body.add(
        _SectionHeader(
          title: _sectionTitle(section),
          count: tasks.length,
          note: _sectionNote(section, tasks),
          alarming: section == TaskSection.now,
          folded: _folded.contains(section),
          foldable: section == TaskSection.done || section == TaskSection.archive,
          onTap: () => setState(() {
            if (!_folded.remove(section)) _folded.add(section);
          }),
        ),
      );
      if (_folded.contains(section)) continue;
      for (final MechanicTask task in tasks) {
        body.add(
          _TaskCard(
            task: task,
            dimmed: section == TaskSection.archive,
            onTap: () => _open(task),
          ),
        );
      }
    }

    if (_loaded && _tasks.isEmpty) body.add(const _Empty());

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24.0),
        physics: const AlwaysScrollableScrollPhysics(),
        children: body,
      ),
    );
  }

  void _open(MechanicTask task) {
    if (task.kind == TaskKind.maintenance) {
      // Поток ТО — следующий этап. Молчаливая кнопка хуже честного ответа.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Экран ТО с чек-листом появится следующим обновлением'),
        ),
      );
      return;
    }

    Navigator.of(context)
        .push(
          MaterialPageRoute<void>(
            builder: (BuildContext context) => MechanicOrderScreen(task: task),
          ),
        )
        .then((_) => _reload());
  }

  String _sectionTitle(TaskSection section) {
    switch (section) {
      case TaskSection.now:
        return 'Сейчас';
      case TaskSection.maintenance:
        return 'Плановые ТО';
      case TaskSection.done:
        return 'Выполнено';
      case TaskSection.archive:
        return 'Архив';
    }
  }

  /// Короткая сводка справа в шапке секции: сколько там горящего.
  ///
  /// Нужна ровно потому, что секции теперь делятся по виду работы: авария
  /// лежит среди заявок, просроченное ТО — среди плановых, и по одному
  /// заголовку не видно, есть ли там что-то срочное.
  static String? _sectionNote(TaskSection section, List<MechanicTask> tasks) {
    switch (section) {
      case TaskSection.now:
        final int urgent = tasks.where((MechanicTask t) => t.urgent).length;
        return urgent == 0 ? null : _plural(urgent, 'авария', 'аварии', 'аварий');
      case TaskSection.maintenance:
        final int overdue = tasks.where((MechanicTask t) => t.overdue).length;
        return overdue == 0 ? null : '$overdue просрочено';
      case TaskSection.done:
      case TaskSection.archive:
        return null;
    }
  }

  static String _plural(int count, String one, String few, String many) {
    final int mod100 = count % 100;
    final int mod10 = count % 10;
    if (mod100 >= 11 && mod100 <= 14) return '$count $many';
    if (mod10 == 1) return '$count $one';
    if (mod10 >= 2 && mod10 <= 4) return '$count $few';
    return '$count $many';
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.count,
    required this.folded,
    required this.foldable,
    required this.onTap,
    this.note,
    this.alarming = false,
  });

  final String title;
  final int count;

  /// Сводка по срочному внутри секции: «1 авария», «2 просрочено».
  final String? note;

  /// Красным сводка горит только у аварий; просроченное ТО — жёлтым: срок
  /// вышел, но лифт стоит не обязательно.
  final bool alarming;

  final bool folded;
  final bool foldable;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Widget row = Padding(
      padding: const EdgeInsets.fromLTRB(
        MechanicLayout.screenPadding,
        8.0,
        MechanicLayout.screenPadding,
        12.0,
      ),
      child: Row(
        children: <Widget>[
          Text(title, style: MechanicLayout.sectionTitle),
          const SizedBox(width: 8.0),
          Text('$count', style: MechanicLayout.cardSubtitle),
          const Spacer(),
          if (note != null)
            _Pill(
              text: note!,
              tone: alarming ? _Tone.alarm : _Tone.warning,
            ),
          if (foldable)
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Icon(
                folded ? Icons.expand_more : Icons.expand_less,
                size: 20.0,
                color: ColorApp.myColorGrayText,
              ),
            ),
        ],
      ),
    );

    if (!foldable) return row;
    return InkWell(onTap: onTap, child: row);
  }
}

/// Карточка работы — белая, 343×85 со скруглением 5, как во всех кадрах.
class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.task,
    required this.onTap,
    this.dimmed = false,
  });

  final MechanicTask task;

  /// Снятая задача показывается серой: смотреть можно, делать нечего.
  final bool dimmed;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color ink = dimmed ? ColorApp.myColorGrayText : ColorApp.myColorBlack;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        MechanicLayout.screenPadding,
        0.0,
        MechanicLayout.screenPadding,
        MechanicLayout.cardGap,
      ),
      child: Material(
        color: dimmed ? ColorApp.myColorGrayShadow : ColorApp.myColorWhite,
        borderRadius: BorderRadius.circular(MechanicLayout.cardRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(MechanicLayout.cardRadius),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: MechanicLayout.cardHeight),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  _Mark(task: task, dimmed: dimmed),
                  const SizedBox(width: 13.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          task.title,
                          style: MechanicLayout.cardTitle.copyWith(color: ink),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 5.0),
                        Text(
                          task.subtitle,
                          style: MechanicLayout.cardSubtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (_note(task) != null) ...<Widget>[
                          const SizedBox(height: 6.0),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: _Pill(
                              text: _note(task)!,
                              tone: _noteTone(task),
                              dimmed: dimmed,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      if (task.badge != null)
                        _Badge(text: task.badge!, dimmed: dimmed),
                      if (task.watchingOnly)
                        const Padding(
                          padding: EdgeInsets.only(top: 6.0),
                          child: _Badge(text: 'наблюдаю', muted: true),
                        ),
                    ],
                  ),
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
      ),
    );
  }

  /// Пометка на карточке: у заявки — состояние, у ТО — срок и сколько шагов
  /// пройдено. В кадре её нет, но в кадре нет и работы по заявке.
  static String? _note(MechanicTask task) {
    if (task.kind == TaskKind.maintenance) {
      final String? progress = task.progress;
      if (task.overdue) {
        return progress == null ? 'Срок вышел' : 'Срок вышел · $progress';
      }
      if (task.thisMonth) {
        return progress == null ? 'Этот месяц' : 'Этот месяц · $progress';
      }
      return progress;
    }
    switch (task.statusId) {
      case OrderStatus.accepted:
        return 'Принята';
      case OrderStatus.inProgress:
        return 'В работе';
      case OrderStatus.done:
        return 'Выполнена';
      case OrderStatus.problem:
        return 'Проблема';
      default:
        return null;
    }
  }

  static _Tone _noteTone(MechanicTask task) {
    if (task.kind == TaskKind.maintenance) {
      if (task.overdue) return _Tone.warning;
      return task.thisMonth ? _Tone.good : _Tone.neutral;
    }
    switch (task.statusId) {
      case OrderStatus.problem:
        return _Tone.alarm;
      case OrderStatus.done:
        return _Tone.good;
      case OrderStatus.inProgress:
        return _Tone.good;
      default:
        return _Tone.neutral;
    }
  }
}

/// Тон пометки. Цвета берём из общей палитры, а не заводим свои.
enum _Tone { neutral, good, warning, alarm }

/// Цвет текста и подложки под тон. Подложка — тот же цвет, разбавленный
/// белым: держать в палитре по второму, светлому оттенку каждого цвета
/// значит заводить пары, которые рано или поздно разъедутся.
class _ToneColors {
  const _ToneColors(this.ink, this.background);

  final Color ink;
  final Color background;

  static _ToneColors of(_Tone tone, {bool dimmed = false}) {
    if (dimmed) {
      return const _ToneColors(
        ColorApp.myColorGrayText,
        ColorApp.myColorGrayShadow,
      );
    }
    switch (tone) {
      case _Tone.good:
        return _ToneColors(
          ColorApp.myColorGreenAuth,
          ColorApp.myColorGreenAuth.withOpacity(0.12),
        );
      case _Tone.warning:
        return _ToneColors(
          ColorApp.myColorYellow,
          ColorApp.myColorYellow.withOpacity(0.14),
        );
      case _Tone.alarm:
        return _ToneColors(
          ColorApp.myColorRed,
          ColorApp.myColorRed.withOpacity(0.14),
        );
      case _Tone.neutral:
        return const _ToneColors(
          ColorApp.myColorGray,
          ColorApp.myColorGrayShadow,
        );
    }
  }
}

/// Пометка словами: состояние заявки, срок ТО, сводка в шапке секции.
///
/// Раньше это была третья строка карточки серым по белому — её приходилось
/// вычитывать. Цвет и подложка отвечают на вопрос «горит или нет» до чтения.
class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.tone, this.dimmed = false});

  final String text;
  final _Tone tone;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final _ToneColors colors = _ToneColors.of(tone, dimmed: dimmed);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 11.0,
          fontWeight: FontWeight.w500,
          color: colors.ink,
        ),
      ),
    );
  }
}

/// Значок слева. В кадре здесь фотография объекта, но списки её не отдают,
/// поэтому значок говорит, что это за работа и насколько она горит: авария —
/// красный треугольник, просроченное ТО — жёлтый календарь, остальное —
/// спокойный зелёный.
class _Mark extends StatelessWidget {
  const _Mark({required this.task, required this.dimmed});

  final MechanicTask task;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final _ToneColors colors = _ToneColors.of(_toneOf(task), dimmed: dimmed);
    return Container(
      width: 45.0,
      height: 45.0,
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(MechanicLayout.cardRadius),
      ),
      child: Icon(_iconOf(task), size: 22.0, color: colors.ink),
    );
  }

  static _Tone _toneOf(MechanicTask task) {
    if (task.kind == TaskKind.maintenance) {
      return task.overdue ? _Tone.warning : _Tone.good;
    }
    if (task.urgent) return _Tone.alarm;
    return task.closed ? _Tone.neutral : _Tone.good;
  }

  static IconData _iconOf(MechanicTask task) {
    if (task.kind == TaskKind.maintenance) {
      return task.overdue ? Icons.event_busy_outlined : Icons.event_available_outlined;
    }
    return task.urgent ? Icons.warning_amber_rounded : Icons.build_outlined;
  }
}

/// Значок в углу карточки: тип оборудования, «ТО», «наблюдаю».
///
/// В кадре он 35×14 с текстом в 7 пунктов. Семь пунктов — это на грани
/// читаемости даже для молодых глаз, а механик смотрит в телефон в машинном
/// помещении; поэтому здесь 9 и высота по тексту. Это расхождение с макетом
/// сделано сознательно.
class _Badge extends StatelessWidget {
  const _Badge({required this.text, this.dimmed = false, this.muted = false});

  final String text;
  final bool dimmed;

  /// Серый вариант — для пометки «наблюдаю».
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final Color background = dimmed
        ? ColorApp.myColorGrayBorder
        : (muted ? ColorApp.myColorGrayText : ColorApp.myColorGreen);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7.0, vertical: 2.0),
      constraints: const BoxConstraints(maxWidth: 96.0),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(2.0),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 9.0,
          fontWeight: FontWeight.w500,
          color: ColorApp.myColorWhite,
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(32.0, 64.0, 32.0, 32.0),
      child: Column(
        children: <Widget>[
          Icon(Icons.check_circle_outline, size: 48.0, color: ColorApp.myColorGreen),
          SizedBox(height: 16.0),
          Text(
            'Работы на вас пока нет.\nПотяните список вниз, чтобы проверить связь.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14.0, color: ColorApp.myColorGray),
          ),
        ],
      ),
    );
  }
}
