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
import 'data/mechanic_workspace.dart';
import 'mechanic_theme.dart';
import 'screens/notifications_screen.dart';
import 'screens/objects_screen.dart';
import 'screens/orders_screen.dart';
import 'screens/profile_screen.dart';

class MechanicShell extends StatefulWidget {
  const MechanicShell({Key? key}) : super(key: key);

  @override
  State<MechanicShell> createState() => _MechanicShellState();
}

class _MechanicShellState extends State<MechanicShell>
    with WidgetsBindingObserver {
  /// Номер вкладки личного кабинета в панели внизу.
  static const int _profileTab = 3;

  int _tab = 0;

  /// Вкладка, с которой ушли в личный кабинет: стрелка «назад» там возвращает
  /// именно на неё, а не на первую. Панель вкладок никуда не девается, но
  /// возврат одним нажатием привычнее, чем поиск нужной вкладки глазами.
  int _tabBeforeProfile = 0;
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

  /// Переключение вкладки. Открытая вкладка уведомлений гасит счётчик:
  /// человек её открыл — значит, увидел.
  void _pick(int index) {
    if (index == _profileTab && _tab != _profileTab) _tabBeforeProfile = _tab;
    setState(() => _tab = index);
    if (index == 2) _workspace?.markNotificationsRead();
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
                children: <Widget>[
                  const MechanicOrdersScreen(),
                  const MechanicObjectsScreen(),
                  const MechanicNotificationsScreen(),
                  MechanicProfileScreen(onBack: () => _pick(_tabBeforeProfile)),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _workspace == null
          ? _NavBar(current: _tab, onPick: _pick)
          : ValueListenableBuilder<WorkspaceStatus>(
              valueListenable: _workspace!.status,
              builder: (BuildContext context, WorkspaceStatus status, _) {
                return _NavBar(
                  current: _tab,
                  unread: status.unread,
                  onPick: _pick,
                );
              },
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
  const _NavBar({
    required this.current,
    required this.onPick,
    this.unread = 0,
  });

  final int current;

  /// Непрочитанные уведомления — красная точка над колокольчиком. В макете она
  /// есть (`1826:270`), и это единственный признак, по которому механик поймёт,
  /// что появилось что-то новое: push мы пока не шлём.
  final int unread;

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
                    child: Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: <Widget>[
                        Icon(
                          _icons[index],
                          size: 22.0,
                          color: active
                              ? ColorApp.myColorGreen
                              : ColorApp.myColorGrayText,
                        ),
                        if (index == 2 && unread > 0)
                          Positioned(
                            top: 2.0,
                            right: 6.0,
                            child: Container(
                              width: 8.0,
                              height: 8.0,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: ColorApp.myColorRed,
                              ),
                            ),
                          ),
                      ],
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
