import 'package:flutter/material.dart';

import '../../helper/class_colors.dart';
import '../../helper/session.dart';
import '../user/user_contact.dart';

/// Временный экран для ролей, у которых своего экрана ещё нет.
///
/// Сейчас это механик и инженер-наладчик. Отдельные экраны для них делаются
/// отдельной работой; до тех пор показывать им админский набор нельзя —
/// половина кнопок там ответит `403`, потому что по матрице прав эти роли
/// не заводят людей, не создают объекты и не правят справочники.
///
/// Экран существует ради одного: человек должен понимать, что он вошёл, и
/// уметь выйти. Раньше роли 3 и 4 не попадали никуда — веток для них в
/// заставке не было, и приложение навсегда зависало на анимации.
class RoleStubScreen extends StatelessWidget {
  const RoleStubScreen({Key? key, required this.roleId}) : super(key: key);

  final int roleId;

  @override
  Widget build(BuildContext context) {
    final String roleName = Roles.names[roleId] ?? 'Роль не определена';
    final String userName = userProfile.isNotEmpty
        ? '${userProfile[0]['name'] ?? ''}'
        : '';

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Единая лифтовая служба',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20.0,
                    fontWeight: FontWeight.w700,
                    color: ColorApp.myColorGreenAuth,
                  ),
                ),
                const SizedBox(height: 30.0),
                if (userName.isNotEmpty)
                  Text(
                    userName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                const SizedBox(height: 8.0),
                Text(
                  roleName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: ColorApp.myColorGray),
                ),
                const SizedBox(height: 30.0),
                const Icon(
                  Icons.engineering_outlined,
                  size: 56.0,
                  color: ColorApp.myColorGreenAuth,
                ),
                const SizedBox(height: 20.0),
                const Text(
                  'Раздел для вашей роли ещё готовится',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10.0),
                const Text(
                  'Вход выполнен. Рабочие экраны появятся в следующем '
                  'обновлении — сообщим, когда будут готовы.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: ColorApp.myColorGray),
                ),
                const SizedBox(height: 30.0),
                TextButton.icon(
                  onPressed: () => signOut(),
                  icon: const Icon(Icons.logout, color: ColorApp.myColorGray),
                  label: const Text(
                    'Выйти',
                    style: TextStyle(color: ColorApp.myColorGray),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
