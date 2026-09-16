import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../foreman/defects/defects_repository.dart';
import '../../../helper/class_colors.dart';
import '../../../navigation/shell_drawer.dart';
import '../../in_progress_works/repository/work_details_repository.dart';
import '../../schedule/view/schedule_section.dart' show scheduleShowsLeading;
import '../bloc/works_bloc.dart';
import '../models/new_work_draft.dart';
import '../models/work_counts.dart';
import '../models/work_employee.dart';
import '../models/work_filters.dart';
import '../models/work_item.dart';
import '../models/work_section.dart';
import '../repository/works_repository.dart';
import '../widgets/work_filter_chips.dart';
import '../widgets/work_group_header.dart';
import '../widgets/work_row_tile.dart';
import 'new_work_dialog.dart';
import 'work_item_card_screen.dart';

/// Экран «Работы»: заявки и акты ТО одной лентой.
///
/// Вид собран по образцу графиков E01 — серый фон, белая шапка, белая
/// карточка фильтров, белая карточка списка с разделителями. Своего кадра в
/// Figma нет.
///
/// Состояние — в [WorksBloc]: отбор, страницы и опрос перемен. Экран держит
/// только то, что относится к экрану: такт опроса и такт таймеров строк.
class WorksScreen extends StatelessWidget {
  const WorksScreen({
    Key? key,
    required this.repository,
    this.drawer = const ShellDrawer(),
    this.onOpen,
    this.detailsRepository,
    this.defectsRepository,
    this.tick = const Duration(seconds: 30),
    this.poll = const Duration(seconds: 15),
    this.canCreateWork = false,
  }) : super(key: key);

  final WorksRepository repository;

  /// Кнопка «Новая работа» в шапке. Включается там, где лента смонтирована
  /// у роли с правом `order:create` — у админа и прораба; у механика кнопки
  /// нет, ему заводить работы нечем. Справочники и создание идут через
  /// [repository], после успеха лента перечитывается.
  final bool canCreateWork;

  /// Боковое меню. У прораба лента — корень раздела, и на узкой ширине это
  /// единственный путь из «Работ» куда-то ещё.
  final Widget drawer;

  /// Клик по строке. Пусто — открывается карточка работы
  /// (`WorkItemCardScreen`); своя обработка — для тестов и превью.
  final ValueChanged<WorkItem>? onOpen;

  /// Откуда карточка работы берёт подробности и дефекты. Пусто — живые
  /// ручки; подменяются на фикстуре и в тестах.
  final WorkDetailsRepository? detailsRepository;
  final DefectsRepository? defectsRepository;

  /// Как часто перерисовывать таймеры строк. Один таймер на ленту, а не в
  /// каждой строке. `null` — не тикать: так экран собирается в тесте, где
  /// периодический таймер не даёт `pumpAndSettle` закончиться.
  final Duration? tick;

  /// Как часто спрашивать перемены. Пятнадцать секунд: механик взял задачу —
  /// прораб видит это раньше, чем успеет ему позвонить. `null` — не
  /// опрашивать (тесты и превью на фикстуре).
  final Duration? poll;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<WorksBloc>(
      create: (_) =>
          WorksBloc(repository: repository)..add(const WorksRequested()),
      child: _WorksBody(
        repository: repository,
        drawer: drawer,
        onOpen: onOpen,
        detailsRepository: detailsRepository,
        defectsRepository: defectsRepository,
        tick: tick,
        poll: poll,
        canCreateWork: canCreateWork,
      ),
    );
  }
}

class _WorksBody extends StatefulWidget {
  const _WorksBody({
    Key? key,
    required this.repository,
    required this.drawer,
    required this.onOpen,
    required this.detailsRepository,
    required this.defectsRepository,
    required this.tick,
    required this.poll,
    required this.canCreateWork,
  }) : super(key: key);

  /// Тот же, что у блока: форме «Новая работа» нужны справочники и создание.
  final WorksRepository repository;
  final Widget drawer;
  final ValueChanged<WorkItem>? onOpen;
  final WorkDetailsRepository? detailsRepository;
  final DefectsRepository? defectsRepository;
  final Duration? tick;
  final Duration? poll;
  final bool canCreateWork;

  @override
  State<_WorksBody> createState() => _WorksBodyState();
}

class _WorksBodyState extends State<_WorksBody> with WidgetsBindingObserver {
  Timer? _ticker;
  Timer? _poller;
  DateTime _now = DateTime.now();

  /// Справочники формы грузятся — кнопка «Новая работа» крутится и второй
  /// клик не открывает вторую форму.
  bool _loadingNewWork = false;

  /// «Новая работа»: справочники с сервера, форма, создание через
  /// репозиторий. Ошибка загрузки — snackbar; ошибка создания — строкой в
  /// форме, форма остаётся с введённым.
  Future<void> _newWork(BuildContext context) async {
    if (_loadingNewWork) return;
    final WorksBloc bloc = context.read<WorksBloc>();
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    setState(() => _loadingNewWork = true);
    NewWorkContext data;
    try {
      data = await widget.repository.newWorkContext();
    } on WorksException catch (e) {
      if (mounted) setState(() => _loadingNewWork = false);
      messenger.showSnackBar(
        SnackBar(
          content: Text(e.message),
          behavior: SnackBarBehavior.floating,
          width: 360,
        ),
      );
      return;
    }
    if (!context.mounted) return;
    setState(() => _loadingNewWork = false);
    await showNewWorkDialog(
      context,
      data: data,
      onCreate: (NewWorkDraft draft) async {
        int id;
        try {
          id = await widget.repository.createWork(draft);
        } on WorksException catch (e) {
          throw NewWorkException(e.message);
        }
        bloc.add(const WorksRequested());
        messenger.showSnackBar(
          SnackBar(
            content: Text('Работа №$id создана'),
            behavior: SnackBarBehavior.floating,
            width: 360,
          ),
        );
      },
    );
  }

  /// Когда опрашивали в последний раз — чтобы возврат из фона не спрашивал
  /// чаще такта: браузер дёргает видимость вкладки и на смену окна, и на
  /// снимок, и каждый раз слать запрос — значит опрашивать не по такту, а
  /// по чиху окна.
  DateTime _lastSync = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final Duration? tick = widget.tick;
    if (tick != null) {
      _ticker = Timer.periodic(
        tick,
        (_) => setState(() => _now = DateTime.now()),
      );
    }
    _startPolling();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _poller?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Приложение свернули — опрос замолкает: запросы в фоне тратят батарею и
  /// трафик, а увидеть их результат некому. Вернулись — спрашиваем сразу,
  /// если спали дольше такта: за это время лента устарела сильнее, чем на
  /// такт, и ждать его незачем.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      final Duration? poll = widget.poll;
      if (poll != null && DateTime.now().difference(_lastSync) >= poll) {
        _sync();
      }
      _startPolling();
    } else {
      _poller?.cancel();
      _poller = null;
    }
  }

  /// Такт, если он не идёт. Живой не перезапускаем: «вернулись» браузер
  /// шлёт и без ухода, и перезапуск такта на каждый — значит никогда не
  /// дождаться его конца.
  void _startPolling() {
    final Duration? poll = widget.poll;
    if (poll == null || _poller != null) return;
    _poller = Timer.periodic(poll, (_) => _sync());
  }

  void _sync() {
    if (!mounted) return;
    _lastSync = DateTime.now();
    context.read<WorksBloc>().add(const WorksSynced());
  }

  WorksBloc get _bloc => context.read<WorksBloc>();

  void _onFiltersChanged(WorkFilters filters) =>
      _bloc.add(WorksRequested(filters: filters));

  Future<void> _assign(WorkItem item) async {
    final WorksFeed? feed = _bloc.state.feed;
    final WorkEmployee? who = await showDialog<WorkEmployee>(
      context: context,
      builder: (BuildContext context) => _AssignDialog(
        item: item,
        employees: feed?.employees ?? const <WorkEmployee>[],
        mySections: feed?.mySections ?? const <int>{},
      ),
    );
    if (who == null || !mounted) return;
    _bloc.add(WorkAssigned(item, who));
  }

  /// Звонок исполнителю через набор номера. Телефона нет — так и говорим,
  /// а не притворяемся звонком.
  Future<void> _call(WorkItem item) async {
    final String? phone = item.performerPhone;
    if (phone == null) {
      _say('У ${item.performer ?? 'исполнителя'} нет телефона в карточке');
      return;
    }
    final Uri uri = Uri(scheme: 'tel', path: phone.replaceAll(' ', ''));
    if (!await launchUrl(uri)) {
      _say('Не удалось набрать $phone');
    }
  }

  void _review(WorkItem item) => _bloc.add(WorkReviewed(item));

  /// Карточка работы поверх ленты. Отметка «Проверил» из карточки идёт в тот
  /// же блок, что и кнопка в строке: лента под карточкой перечитывает строку
  /// сама, и по возвращении прораб видит её уже отмеченной.
  void _open(WorkItem item) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => WorkItemCardScreen(
          item: item,
          onReview: item.status.isClosed ? () => _review(item) : null,
          repository: widget.detailsRepository,
          defectsRepository: widget.defectsRepository,
        ),
      ),
    );
  }

  void _say(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(text), duration: const Duration(seconds: 2)),
      );
  }

  /// Лента с заголовками блоков при порядке «сначала требуют внимания».
  ///
  /// Заголовки — обычные элементы списка, а не `SliverList` с шапками: их
  /// два, и лента одна. Разделитель перед заголовком не рисуется — у него
  /// свой серый фон, и линия над ним читалась бы как двойная.
  Widget _list(WorksState state) {
    final WorksFeed feed = state.feed!;
    final bool grouped =
        state.filters.sort == WorkSort.attention && feed.items.isNotEmpty;
    // Не больше, чем строк на руках: число с ручки — по всему отбору, а
    // страница могла кончиться раньше блока.
    final int urgent = feed.attentionCount.clamp(0, feed.items.length);
    final int rest = feed.items.length - urgent;

    final List<Widget> rows = <Widget>[];
    for (int i = 0; i < feed.items.length; i++) {
      if (grouped && i == 0) {
        rows.add(
          urgent > 0
              ? WorkGroupHeader(
                  title: 'Требуют внимания',
                  count: urgent,
                  urgent: true,
                )
              : WorkGroupHeader(title: 'Остальные', count: rest),
        );
      } else if (grouped && i == urgent) {
        rows.add(WorkGroupHeader(title: 'Остальные', count: rest));
      } else if (i > 0) {
        rows.add(
          const Divider(
            height: 1,
            thickness: 1,
            color: ColorApp.myColorGrayBorder,
          ),
        );
      }
      final WorkItem item = feed.items[i];
      rows.add(
        WorkRowTile(
          item: item,
          now: _now,
          onTap: () => (widget.onOpen ?? _open)(item),
          onAssign: () => _assign(item),
          onCall: () => _call(item),
          onReview: () => _review(item),
        ),
      );
    }
    if (feed.nextCursor != null) {
      rows.add(
        _MoreRow(
          loading: state.loadingMore,
          onPressed: () => _bloc.add(const WorksMoreRequested()),
        ),
      );
    }

    return ListView.builder(
      itemCount: rows.length,
      itemBuilder: (BuildContext context, int index) => rows[index],
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<WorksBloc, WorksState>(
      listenWhen: (WorksState a, WorksState b) =>
          a.messageSerial != b.messageSerial,
      listener: (BuildContext context, WorksState state) {
        if (state.message != null) _say(state.message!);
      },
      builder: (BuildContext context, WorksState state) => Scaffold(
        backgroundColor: ColorApp.myColorGrayShadow,
        drawer: widget.drawer,
        appBar: AppBar(
          automaticallyImplyLeading: scheduleShowsLeading(context),
          title: const Text('Работы'),
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: ColorApp.myColorBlack,
          actions: <Widget>[
            if (widget.canCreateWork)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: _NewWorkButton(
                  loading: _loadingNewWork,
                  onPressed: () => _newWork(context),
                ),
              ),
          ],
        ),
        body: Column(
          children: <Widget>[
            // Панель рисуется во всех состояниях, включая загрузку: чипс
            // применяется сразу, и пропадай панель на время запроса — нажать
            // второй было бы не по чему.
            WorkFilterChips(
              filters: state.filters,
              counts: state.feed?.counts ?? WorkCounts.empty,
              sections: state.feed?.sections ?? const <WorkSection>[],
              employees: state.feed?.employees ?? const <WorkEmployee>[],
              onChanged: _onFiltersChanged,
            ),
            Expanded(child: _body(state)),
          ],
        ),
      ),
    );
  }

  Widget _body(WorksState state) {
    final WorksFeed? feed = state.feed;

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(state.error!, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => _bloc.add(const WorksRequested()),
              child: const Text('Повторить'),
            ),
          ],
        ),
      );
    }

    if (feed == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (feed.items.isEmpty && !state.loading) {
      return _EmptyView(
        filters: state.filters,
        onReset: () => _onFiltersChanged(state.filters.cleared()),
      );
    }

    // Лента остаётся на месте, пока едет новый отбор: заслонка поверх, а не
    // спиннер вместо списка — иначе каждый чипс мигал бы пустым экраном.
    return Stack(
      children: <Widget>[
        Container(
          margin: const EdgeInsets.all(16),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: ColorApp.myColorWhite,
            borderRadius: BorderRadius.circular(5),
          ),
          child: _list(state),
        ),
        if (state.loading) ...<Widget>[
          const ModalBarrier(dismissible: false, color: Colors.black12),
          const Center(child: CircularProgressIndicator()),
        ],
      ],
    );
  }
}

/// «Показать ещё» в хвосте ленты, пока у ручки есть курсор. Кнопка, а не
/// подгрузка по скроллу: лента живая, и строки под пальцем и так двигаются.
/// «Новая работа» в шапке: на широком экране — с подписью, на узком —
/// одна иконка, чтобы не тесниться с заголовком и бургером.
class _NewWorkButton extends StatelessWidget {
  const _NewWorkButton({
    Key? key,
    required this.onPressed,
    this.loading = false,
  }) : super(key: key);

  final VoidCallback onPressed;

  /// Справочники формы ещё грузятся — вместо плюса крутилка.
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final bool narrow = MediaQuery.sizeOf(context).width < 600;
    final Widget icon = loading
        ? const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : Icon(narrow ? Icons.add_circle_outline : Icons.add, size: 18);
    if (narrow) {
      return IconButton(
        tooltip: 'Новая работа',
        icon: icon,
        color: ColorApp.myColorGreenAuth,
        onPressed: loading ? null : onPressed,
      );
    }
    return TextButton.icon(
      onPressed: loading ? null : onPressed,
      style: TextButton.styleFrom(
        foregroundColor: ColorApp.myColorGreenAuth,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      icon: icon,
      label: const Text('Новая работа'),
    );
  }
}

class _MoreRow extends StatelessWidget {
  const _MoreRow({Key? key, required this.loading, required this.onPressed})
    : super(key: key);

  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: ColorApp.myColorGrayBorder)),
      ),
      child: loading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : TextButton(
              onPressed: onPressed,
              child: const Text(
                'Показать ещё',
                style: TextStyle(
                  fontSize: 13,
                  color: ColorApp.myColorGreenAuth,
                ),
              ),
            ),
    );
  }
}

/// «Кого назначить»: сотрудники с должностью и участком. Сначала «мои
/// механики» — с участков прораба, потом остальные: своих он назначает по
/// десять раз на дню, чужих — когда свои заняты. Одно нажатие — выбор,
/// без «ОК».
class _AssignDialog extends StatelessWidget {
  const _AssignDialog({
    Key? key,
    required this.item,
    required this.employees,
    required this.mySections,
  }) : super(key: key);

  final WorkItem item;
  final List<WorkEmployee> employees;
  final Set<int> mySections;

  @override
  Widget build(BuildContext context) {
    final List<WorkEmployee> mine = employees
        .where((WorkEmployee e) => mySections.contains(e.sectionId))
        .toList();
    final List<WorkEmployee> others = employees
        .where((WorkEmployee e) => !mySections.contains(e.sectionId))
        .toList();

    return SimpleDialog(
      title: Text(
        '${item.number} · ${item.objectName}',
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
      titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 4),
      contentPadding: const EdgeInsets.fromLTRB(0, 4, 0, 12),
      children: <Widget>[
        if (mine.isNotEmpty) ...<Widget>[
          _AssignGroup(title: 'Мои механики', count: mine.length),
          for (final WorkEmployee e in mine) _AssignOption(employee: e),
        ],
        if (others.isNotEmpty) ...<Widget>[
          _AssignGroup(
            title: mine.isEmpty ? 'Сотрудники' : 'Остальные',
            count: others.length,
          ),
          for (final WorkEmployee e in others) _AssignOption(employee: e),
        ],
      ],
    );
  }
}

class _AssignGroup extends StatelessWidget {
  const _AssignGroup({Key? key, required this.title, required this.count})
    : super(key: key);

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 4),
      child: Text(
        '${title.toUpperCase()} · $count',
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: ColorApp.myColorGrayText,
        ),
      ),
    );
  }
}

/// Строка сотрудника: значок должности, имя, под ним должность; участок —
/// справа, серым: он нужен, чтобы не послать человека через весь город.
class _AssignOption extends StatelessWidget {
  const _AssignOption({Key? key, required this.employee}) : super(key: key);

  final WorkEmployee employee;

  @override
  Widget build(BuildContext context) {
    return SimpleDialogOption(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      onPressed: () => Navigator.of(context).pop(employee),
      child: Row(
        children: <Widget>[
          Tooltip(
            message: employee.specialty,
            child: Icon(employee.icon, size: 18, color: ColorApp.myColorGray),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(employee.name, style: const TextStyle(fontSize: 14)),
                Text(
                  employee.specialty,
                  style: const TextStyle(
                    fontSize: 11,
                    color: ColorApp.myColorGrayText,
                  ),
                ),
              ],
            ),
          ),
          if (employee.section != null) ...<Widget>[
            const SizedBox(width: 16),
            const Icon(
              Icons.place_outlined,
              size: 14,
              color: ColorApp.myColorGray,
            ),
            const SizedBox(width: 4),
            Text(
              employee.section!,
              style: const TextStyle(fontSize: 12, color: ColorApp.myColorGray),
            ),
          ],
        ],
      ),
    );
  }
}

/// Пустая выдача: «работ нет» и «под отбор не подошло» — разные случаи, и
/// путать их нельзя: во втором виноват отбор, который человек сам сузил.
class _EmptyView extends StatelessWidget {
  const _EmptyView({Key? key, required this.filters, required this.onReset})
    : super(key: key);

  final WorkFilters filters;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final bool filtered = !filters.isEmpty;
    final String text;
    if (filters.archived && filters.activeCount == 1) {
      text = 'В архиве пусто';
    } else if (filtered) {
      text = 'Под отбор не подошла ни одна работа';
    } else {
      text = 'Работ пока нет';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              filtered ? Icons.search_off : Icons.inbox_outlined,
              size: 48,
              color: ColorApp.myColorGrayBorder,
            ),
            const SizedBox(height: 16),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: ColorApp.myColorGrayText,
              ),
            ),
            if (filtered) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                'Стоит условий: ${filters.activeCount}',
                style: const TextStyle(
                  fontSize: 12,
                  color: ColorApp.myColorGrayText,
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: onReset,
                child: const Text(
                  'Сбросить всё',
                  style: TextStyle(
                    fontSize: 13,
                    color: ColorApp.myColorGreenAuth,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
