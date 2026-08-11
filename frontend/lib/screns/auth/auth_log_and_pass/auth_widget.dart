import 'package:flutter/material.dart';

import '../../../helper/class_colors.dart';

/// Виджеты Аутификации

/// Выпадающее Окно ==============================
class DropdownWindow extends StatelessWidget {
  const DropdownWindow({
    Key? key,
    required Size size,
  })  : _size = size,
        super(key: key);

  final Size _size;

  @override
  Widget build(BuildContext context) {

    TextEditingController passwordRecovery = TextEditingController();


    return TextButton(
      onPressed: () {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.0),
            ),
            content: SizedBox(
              height: 220,
              // width: 500,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Spacer(),
                      IconButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.close))
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Восстановление доступа',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 30.0),
                      Text(
                        'Введите свои учетные данные, и вам на почту придет\nинструкция по восстановлению доступа в систему',
                        style:
                            TextStyle(fontSize: _size.width > 540.0 ? 14 : 10),
                      ),
                      const SizedBox(height: 40.0),
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 40.0,
                              child: TextField(
                                controller: passwordRecovery,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  labelText: 'Логин',
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10.0),
                          InkWell(
                            onTap: () {},
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                  color: ColorApp.myColorGreen,
                                  borderRadius: BorderRadius.circular(10.0)),
                              child: const Icon(
                                Icons.telegram,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
      child: const Text(
        'Вы можете восстановить доступ',
        style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w300,
            color: ColorApp.myColorRed),
      ),
    );
  }
}
/// ==============================================