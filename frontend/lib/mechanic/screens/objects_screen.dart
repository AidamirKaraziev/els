/// Свои объекты — вкладка «Объекты» оболочки механика.
///
/// Кадр в макете есть (`1826:210`), но выгружен не был, и вёрстка собрана из
/// приёмов соседних экранов: карточка списка заявок один в один — белая,
/// скругление 5, значок 45×45 слева, название и адрес двумя строками. Когда
/// кадр появится, сверять надо этот файл.
///
/// Зачем экран нужен сейчас: это четвёртая точка входа дефекта. Механик
/// приехал на объект не по своей заявке и не по ТО — записать найденное ему
/// больше неоткуда. Список объектов сам по себе тоже полезен, но карточки
/// объекта с историей здесь нет: она отдельная работа.
///
/// Откуда берутся объекты и чего в списке не будет — см. `data/objects.dart`.
library;

import 'package:flutter/material.dart';

import '../../helper/class_colors.dart';
import '../data/defect_link.dart';
import '../data/local_store.dart';
import '../data/mechanic_workspace.dart';
import '../data/objects.dart';
import '../data/tasks.dart';
import '../mechanic_theme.dart';
import 'defect_sheet.dart';
import 'quiet_button.dart';

class MechanicObjectsScreen extends StatefulWidget {
  const MechanicObjectsScreen({Key? key, this.objects, this.onBack})
      : super(key: key);

  /// Готовый список — для набросков и тестов. В приложении не задаётся:
  /// экран читает локальную базу сам.
  final List<MechanicObject>? objects;

  /// Стрелка «назад» появляется, только когда экран открыт поверх другого —
  /// с экрана заявок. На своей вкладке возвращаться некуда.
  final VoidCallback? onBack;

  @override
  State<MechanicObjectsScreen> createState() => _MechanicObjectsScreenState();
}

class _MechanicObjectsScreenState extends State<MechanicObjectsScreen> {
  List<MechanicObject> _objects = <MechanicObject>[];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    if (widget.objects != null) {
      _objects = widget.objects!;
      _loaded = true;
      return;
    }
    _reload();
    MechanicWorkspace.current?.status.addListener(_reload);
  }

  @override
  void dispose() {
    if (widget.objects == null) {
      MechanicWorkspace.current?.status.removeListener(_reload);
    }
    super.dispose();
  }

  /// Перечитывает объекты из тех же работ, что показывает список заявок.
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
      _objects = objectsFromTasks(
        buildTaskList(
          orders: orders,
          maintenance: maintenance,
          userId: workspace.userId,
          now: DateTime.now(),
        ),
      );
      _loaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorApp.myColorTransparent,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _refresh,
          child: ListView(
            padding: const EdgeInsets.only(bottom: 32.0),
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  MechanicLayout.screenPadding,
                  24.0,
                  MechanicLayout.screenPadding,
                  16.0,
                ),
                child: Row(
                  children: <Widget>[
                    if (widget.onBack != null) ...<Widget>[
                      InkWell(
                        onTap: widget.onBack,
                        child: const Padding(
                          padding: EdgeInsets.all(4.0),
                          child: Icon(Icons.arrow_back, size: 24.0),
                        ),
                      ),
                      const SizedBox(width: 8.0),
                    ],
                    const Text('Объекты', style: MechanicLayout.screenTitle),
                  ],
                ),
              ),
              if (!_loaded)
                const Padding(
                  padding: EdgeInsets.only(top: 64.0),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_objects.isEmpty)
                const _Empty()
              else
                ..._objects.map(
                  (MechanicObject object) => _ObjectCard(
                    object: object,
                    onDefect: () => _reportDefect(object),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _refresh() async {
    if (widget.objects != null) return;
    await MechanicWorkspace.current?.refresh();
    await _reload();
  }

  /// Дефект на объекте — без работы и без заявки: одна привязка `object_id`.
  Future<void> _reportDefect(MechanicObject object) async {
    final DefectDraft? draft = await showDefectSheet(context);
    if (draft == null || !mounted) return;

    await MechanicWorkspace.current?.sendDefect(
      link: DefectLink.object(object.id),
      title: draft.title,
      description: draft.description,
      photos: draft.photos,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Дефект «${draft.title}» записан.')),
    );
  }
}

/// Карточка объекта: приёмы карточки заявки, но без пилюли состояния —
/// состояния у объекта нет.
class _ObjectCard extends StatelessWidget {
  const _ObjectCard({required this.object, required this.onDefect});

  final MechanicObject object;
  final VoidCallback onDefect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        MechanicLayout.screenPadding,
        0.0,
        MechanicLayout.screenPadding,
        MechanicLayout.cardGap,
      ),
      child: Material(
        color: ColorApp.myColorWhite,
        borderRadius: BorderRadius.circular(MechanicLayout.cardRadius),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 14.0, 16.0, 6.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    width: 45.0,
                    height: 45.0,
                    decoration: BoxDecoration(
                      color: ColorApp.myColorGreenLine,
                      borderRadius:
                          BorderRadius.circular(MechanicLayout.cardRadius),
                    ),
                    child: const Icon(
                      Icons.apartment_outlined,
                      size: 22.0,
                      color: ColorApp.myColorGreenAuth,
                    ),
                  ),
                  const SizedBox(width: 13.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          object.name,
                          style: MechanicLayout.cardTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (object.address != null) ...<Widget>[
                          const SizedBox(height: 5.0),
                          Text(
                            object.address!,
                            style: MechanicLayout.cardSubtitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        if (object.badge != null) ...<Widget>[
                          const SizedBox(height: 6.0),
                          Text(
                            object.badge!,
                            style: MechanicLayout.cardSubtitle,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 17.0, color: MechanicLayout.divider),
              Align(
                alignment: Alignment.centerLeft,
                child: MechanicQuietButton(
                  icon: mechanicDefectIcon,
                  label: 'Дефект',
                  ink: ColorApp.myColorGray,
                  onTap: onDefect,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Пустой список объясняется словами: «объектов нет» механик прочитал бы как
/// поломку, а дело обычно в том, что работы по ним ещё не назначены.
class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(32.0, 64.0, 32.0, 32.0),
      child: Column(
        children: <Widget>[
          Icon(Icons.apartment_outlined, size: 48.0, color: ColorApp.myColorGray),
          SizedBox(height: 16.0),
          Text(
            'Объекты появятся вместе с работой по ним — заявкой или плановым '
            'ТО. Потяните список вниз, чтобы проверить связь.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14.0, color: ColorApp.myColorGray),
          ),
        ],
      ),
    );
  }
}
