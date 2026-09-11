import 'package:flutter/material.dart';

import '../helper/button/side_menu_button.dart';
import '../helper/class_colors.dart';
import '../helper/session.dart';
import 'app_section.dart';

/// Один бургер на все роли.
///
/// Без состояния: какой раздел открыт, говорит оболочка через `current`,
/// а не статическая переменная, которую каждый экран перезаписывал по-своему.
/// Поэтому подсветка не «уезжает», а состав пунктов не зависит от того,
/// откуда пришли.
class AppDrawer extends StatelessWidget {
  const AppDrawer({
    Key? key,
    required this.current,
    required this.roleId,
    required this.onSelect,
    required this.onLogout,
    this.userName,
    this.trailing = const <AppSection, Widget>{},
  }) : super(key: key);

  /// Открытый раздел — подсвечен.
  final AppSection current;

  /// Роль вошедшего, `Roles.*`. Определяет, какие разделы показать.
  final int roleId;

  /// Имя вошедшего под заголовком; без него — только роль.
  final String? userName;

  final ValueChanged<AppSection> onSelect;
  final VoidCallback onLogout;

  /// Числа справа от пункта — таблетки `CountChip`. Кладёт оболочка.
  final Map<AppSection, Widget> trailing;

  @override
  Widget build(BuildContext context) {
    final String role = Roles.names[roleId] ?? '';
    final String who =
        userName == null || userName!.isEmpty ? role : '$userName · $role';

    return Drawer(
      backgroundColor: ColorApp.myColorWhite,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const SizedBox(height: 30.0),
            const Text(
              'Единая лифтовая служба',
              style: TextStyle(
                fontSize: 19.0,
                fontWeight: FontWeight.w700,
                color: ColorApp.myColorGreenAuth,
              ),
            ),
            if (who.isNotEmpty) ...<Widget>[
              const SizedBox(height: 4.0),
              Text(
                who,
                style: const TextStyle(
                  fontSize: 13.0,
                  color: ColorApp.myColorGrayText,
                ),
              ),
            ],
            const SizedBox(height: 26.0),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: <Widget>[
                  for (final AppSection section in AppSection.forRole(roleId))
                    MenuButton(
                      key: ValueKey<AppSection>(section),
                      myIcons: section.icon,
                      title: section.title,
                      press: () => onSelect(section),
                      colorButton: section == current
                          ? ColorApp.myColorGreenLine
                          : Colors.transparent,
                      trailing: trailing[section],
                    ),
                ],
              ),
            ),
            const Divider(height: 1.0, color: ColorApp.myColorGrayBorder),
            const SizedBox(height: 10.0),
            MenuButton(
              key: const ValueKey<String>('logout'),
              myIcons: Icons.logout,
              title: 'Выйти',
              press: onLogout,
              colorButton: Colors.transparent,
            ),
          ],
        ),
      ),
    );
  }
}
