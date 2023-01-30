import 'package:flutter/material.dart';
import '../../helper/class_colors.dart';
import 'auth_log_and_pass/log_and_pass.dart';

///Аутификация

class Auth extends StatefulWidget {
  const Auth({Key? key}) : super(key: key);

  @override
  State<Auth> createState() => _AuthState();
}

class _AuthState extends State<Auth> {

  var singleCheck = true;

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return Scaffold(
      body: SingleChildScrollView(
        child: Row(
          children: [
            ///Логин пароль
            Expanded(
              flex: 5,
                child: Column(
                  children: [
                    const LogAndPass(),
                    Text('© 2022 Единая лифтовая компания. Все права защищены',
                        style: TextStyle(fontSize: 12, color: Colors.grey[350])),
                  ],
                )),
            ///Инфо и картинка
            if (size.width > 1070)
              Expanded(
                flex: 6,
                child: Padding(
                  padding: const EdgeInsets.only(top: 30.0),
                  child: Container(
                    height: MediaQuery.of(context).size.height,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20.0),
                    decoration: BoxDecoration(
                      border:
                          Border.all(color: ColorApp.myColorGreenLine, width: 1),
                      gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: [0.5, 2],
                          colors: [
                            ColorApp.myColorTransparent,
                            ColorApp.myColorWhite,
                          ]),
                      borderRadius:
                          const BorderRadius.only(topLeft: Radius.circular(50.0)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        SizedBox(
                          width: 500,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Вся информация у вас под рукой:',
                                  style: TextStyle(fontSize: 20)),
                              const SizedBox(height: 40.0),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Checkbox(
                                            activeColor: ColorApp.myColorGreenAuth,
                                            value: singleCheck,
                                            onChanged: (newValue) {},
                                          ),
                                          const Text('Контроль заявок'),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Checkbox(
                                            activeColor: ColorApp.myColorGreenAuth,
                                            value: singleCheck,
                                            onChanged: (newValue) {},
                                          ),
                                          const Text('Ведение отчетности'),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Checkbox(
                                            activeColor: ColorApp.myColorGreenAuth,
                                            value: singleCheck,
                                            onChanged: (newValue) {},
                                          ),
                                          const Text('Выполнение плановых ТО'),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Checkbox(
                                            activeColor: ColorApp.myColorGreenAuth,
                                            value: singleCheck,
                                            onChanged: (newValue) {},
                                          ),
                                          const Text('Подробная статистика'),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Image.asset(
                          'assets/1.png',
                          width: 400,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}





