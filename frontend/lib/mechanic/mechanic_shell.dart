/// Оболочка механика: четыре вкладки и нижняя навигация.
///
/// Отдельная оболочка, а не общий набор экранов админки: по матрице прав
/// механик не заводит людей, не создаёт объекты и не правит справочники, и
/// половина кнопок админского меню ответила бы ему `403`. До этого экрана
/// роли 3 и 4 упирались в заглушку `RoleStubScreen`.
///
/// Вкладки и порядок — из макета «Механик | Мобильная версия»: заявки
/// (`1826:155`), объекты (`1826:210`), уведомления (`1826:270`), личный
/// кабинет (`1826:283`). Нижняя панель там белая, высотой 49, ровно четыре
/// ячейки; выбранная иконка зелёная, остальные серые.
///
/// Экран держит `IndexedStack`, а не пересоздаёт вкладку при каждом
/// переключении: механик ходит между заявками и ТО постоянно, и терять
/// прокрутку списка на каждом шаге — раздражение на весь день.
library;

import 'package:flutter/material.dart';

import '../helper/class_colors.dart';
import '../screns/user/user_contact.dart';
import 'data/local_store.dart';
import 'data/mechanic_workspace.dart';
import 'mechanic_theme.dart';
import 'screens/profile_screen.dart';
import 'screens/soon_screen.dart';

class MechanicShell extends StatefulWidget {
  const MechanicShell({Key? key}) : super(key: key);

  @override
  State<MechanicShell> createState() => _MechanicShellState();
}

class _MechanicShellState extends State<MechanicShell>
    with WidgetsBindingObserver {
  int _tab = 0;
  MechanicWorkspace? _workspace;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Профиль к этому моменту уже загружен: оболочку показывает `RootGate`
    // после `loadProfile`. Без идентификатора человека локальную базу
    // открывать нельзя — данные окажутся ничьими и достанутся следующему,
    // кто войдёт с этого телефона.
    final int userId = _currentUserId();
    if (userId != 0) {
      _workspace = MechanicWorkspace.of(userId)..start();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Вернулись в приложение — самое время отдать сделанное и забрать
    // изменения. Телефон в кармане у механика полдня лежит выключенным.
    if (state == AppLifecycleState.resumed) _workspace?.refresh();
  }

  int _currentUserId() {
    if (userProfile.isEmpty) return 0;
    final dynamic id = (userProfile[0] as Map)['id'];
    return id is int ? id : 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorApp.myColorTransparent,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: <Widget>[
            if (_workspace != null)
              ValueListenableBuilder<WorkspaceStatus>(
                valueListenable: _workspace!.status,
                builder: (BuildContext context, WorkspaceStatus status, _) {
                  return _StatusStrip(
                    status: status,
                    onRetry: () => _workspace!.refresh(),
                  );
                },
              ),
            Expanded(
              child: IndexedStack(
                index: _tab,
                children: const <Widget>[
                  MechanicSoonScreen(
                    title: 'Заявки',
                    note: 'Список заявок и работа по ним появятся следующим '
                        'обновлением. Приложение уже держит их у себя, чтобы '
                        'они открывались без связи.',
                    collection: LocalCollection.orders,
                  ),
                  MechanicSoonScreen(
                    title: 'Объекты',
                    note: 'Карточки объектов с плановыми ТО появятся следующим '
                        'обновлением.',
                    collection: LocalCollection.maintenance,
                  ),
                  MechanicSoonScreen(
                    title: 'Уведомления',
                    note: 'Список уведомлений появится вместе с экраном '
                        'заявок. Push пока не отправляем.',
                  ),
                  MechanicProfileScreen(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _NavBar(
        current: _tab,
        onPick: (int index) => setState(() => _tab = index),
      ),
    );
  }
}

/// Полоса состояния связи и очереди.
///
/// В макете её нет — там нет и офлайна. Появляется только когда есть что
/// сказать: обычный день механика она не занимает ни пикселем.
class _StatusStrip extends StatelessWidget {
  const _StatusStrip({required this.status, required this.onRetry});

  final WorkspaceStatus status;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final List<String> parts = <String>[
      if (status.lastError != null) status.lastError!,
      if (status.pending > 0) 'Не отправлено: ${status.pending}',
      if (status.rejected > 0) 'Отклонено сервером: ${status.rejected}',
    ];
    if (parts.isEmpty) return const SizedBox.shrink();

    final bool offline = status.lastError != null;
    return Material(
      color: offline ? ColorApp.myColorYellow : ColorApp.myColorGreenLine,
      child: InkWell(
        onTap: onRetry,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: <Widget>[
              Icon(
                offline ? Icons.cloud_off : Icons.cloud_upload_outlined,
                size: 16.0,
                color: ColorApp.myColorBlack,
              ),
              const SizedBox(width: 8.0),
              Expanded(
                child: Text(
                  parts.join(' · '),
                  style: const TextStyle(fontSize: 12.0),
                ),
              ),
              const Text(
                'Повторить',
                style: TextStyle(fontSize: 12.0, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavBar extends StatelessWidget {
  const _NavBar({required this.current, required this.onPick});

  final int current;
  final ValueChanged<int> onPick;

  static const List<IconData> _icons = <IconData>[
    Icons.assignment_turned_in,
    Icons.explore,
    Icons.notifications,
    Icons.person,
  ];

  static const List<String> _labels = <String>[
    'Заявки',
    'Объекты',
    'Уведомления',
    'Личный кабинет',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: ColorApp.myColorWhite,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: MechanicLayout.navBarHeight,
          child: Row(
            children: List<Widget>.generate(_icons.length, (int index) {
              final bool active = index == current;
              return Expanded(
                child: InkWell(
                  onTap: () => onPick(index),
                  child: Tooltip(
                    message: _labels[index],
                    child: Icon(
                      _icons[index],
                      size: 22.0,
                      color: active
                          ? ColorApp.myColorGreen
                          : ColorApp.myColorGrayText,
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
