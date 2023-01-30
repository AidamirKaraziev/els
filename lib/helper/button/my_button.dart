import 'package:flutter/material.dart';

import '../class_colors.dart';



/// Главная кнопка ==============================
class MainButtonApp extends StatelessWidget {
  const MainButtonApp({Key? key, required this.textButton, required this.press}) : super(key: key);

  final String textButton;
  final VoidCallback press;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
              primary: ColorApp.myColorGreenAuth,
              padding: const EdgeInsets.symmetric(vertical: 20.0)),
          onPressed: press,
          child: Text(
            textButton,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
/// =============================================