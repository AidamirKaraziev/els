import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// Экран заставки — то, что видно, пока приложение восстанавливает сессию.
///
/// Раньше он же и решал, куда вести человека: `Future.delayed` на две
/// секунды, а затем `if` по роли. Две секунды были ставкой на то, что ответ
/// про профиль успеет прийти, а ролей в том `if` было четыре из шести —
/// механик и инженер не попадали никуда и оставались на этой анимации
/// навсегда.
///
/// Теперь маршрут выбирает `RootGate` по фактически загруженному профилю
/// (`homeScreenForRole`), а заставка занимается только показом.
class SplashScreen extends StatelessWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const Spacer(),
          Center(child: Lottie.asset('assets/Animation - 1720525933825.json')),
          const Spacer(),
        ],
      ),
    );
  }
}
