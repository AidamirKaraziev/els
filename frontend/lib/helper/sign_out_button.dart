import 'package:flutter/material.dart';

import 'class_colors.dart';
import 'session.dart';

/// Кнопка выхода из аккаунта на экране профиля.
///
/// Одна на три экрана: профиль у админа, прораба и диспетчера — три копии
/// одного и того же, унаследованные от подрядчика. Заводить в каждой свою
/// кнопку значит обречь их разъехаться.
///
/// Стоит внизу, под данными: выход — редкое и завершающее действие, ему незачем
/// спорить за внимание с профилем. Вид тот же, что у кнопки в профиле механика
/// (`mechanic/screens/profile_screen.dart`), сделанной по макету: аккаунт
/// должен выглядеть одинаково во всех ролях.
///
/// Подтверждения нет намеренно: сессия восстанавливается входом, а
/// несохранённых правок экран профиля не держит.
class SignOutButton extends StatelessWidget {
  const SignOutButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50.0,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          // Не `myColorGreen` (#BADE89): белый текст на нём почти не виден.
          // `myColorGreenAuth` — рабочий зелёный действий приложения.
          backgroundColor: ColorApp.myColorGreenAuth,
          elevation: 0.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
        ),
        onPressed: () => signOut(),
        child: const Text(
          'Выйти',
          style: TextStyle(
            fontSize: 18.0,
            fontWeight: FontWeight.w500,
            color: ColorApp.myColorWhite,
          ),
        ),
      ),
    );
  }
}

/// Стрелка «назад» в шапке профиля.
///
/// Возвращает на раздел, с которого сюда пришли: истории переходов в
/// оболочках подрядчика нет, её держит `session.dart`.
class ProfileBackButton extends StatelessWidget {
  const ProfileBackButton({Key? key, required this.onBack, this.size = 25.0})
      : super(key: key);

  /// Перерисовать оболочку после возврата — состояние живёт в родителе.
  final VoidCallback onBack;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {
        leaveProfile();
        onBack();
      },
      tooltip: 'Назад',
      icon: Icon(Icons.arrow_back, size: size),
    );
  }
}
