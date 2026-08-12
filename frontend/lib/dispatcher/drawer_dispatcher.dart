import 'package:els/dispatcher/task_screen_dispatcher/application_screen.dart';
import 'package:flutter/material.dart';

import '../foreman/task_foreman/task_screen_foreman.dart';
import '../helper/button/side_menu_button.dart';
import '../helper/class_colors.dart';
import '../helper/session.dart';
import '../screns/home_page/home_page.dart';

/// MyDrawer ==============================================

class DrawerDispatcher extends StatefulWidget {
  const DrawerDispatcher({Key? key}) : super(key: key);

  @override
  State<DrawerDispatcher> createState() => _DrawerDispatcherState();
}

class _DrawerDispatcherState extends State<DrawerDispatcher> {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 30.0),
              /// Единая лифтовая служба
              const Text(
                'Единая лифтовая служба',
                style: TextStyle(
                  fontSize: 19.0,
                  fontWeight: FontWeight.w700,
                  color: ColorApp.myColorGreenAuth,
                ),
              ),
              const SizedBox(height: 30.0),

              /// Заявки
              Stack(
                children: [
                  MenuButton(
                    myIcons: Icons.list_alt,
                    title: 'Мои Заявки',
                    press: () async {
                      getListApplication();
                      IntTest.indexScreensDispatcher = 0;
                      IntTest.myTitle = 'Мои Заявки';
                      setState(() {});
                      myStream.add(IntTest.indexScreensDispatcher);
                    },
                    colorButton: IntTest.indexScreensDispatcher == 0
                        ? ColorApp.myColorGreenLine
                        : Colors.transparent,
                  ),
                  // if (numberApplications != 0)
                  //   Positioned(
                  //       right: 8.0,
                  //       top: 8.0,
                  //       child: AlertsWidget(
                  //         alertsNumber: numberApplications,
                  //         myColor: ColorApp.myColorRed,
                  //       )),
                ],
              ),

              /// Выполненные Заявки
              Stack(
                children: [
                  MenuButton(
                    myIcons: Icons.check_box_outlined,
                    title: 'Выполненые Заявки',
                    press: () async {
                      getListApplication();
                      IntTest.indexScreensDispatcher = 2;
                      IntTest.myTitle = 'Выполненые Заявки';
                      setState(() {});
                      myStream.add(IntTest.indexScreensDispatcher);
                    },
                    colorButton: IntTest.indexScreensDispatcher == 2
                        ? ColorApp.myColorGreenLine
                        : Colors.transparent,
                  ),
                  // if (numberApplications != 0)
                  //   Positioned(
                  //       right: 8.0,
                  //       top: 8.0,
                  //       child: AlertsWidget(
                  //         alertsNumber: numberApplications,
                  //         myColor: ColorApp.myColorRed,
                  //       )),
                ],
              ),

              /// Мой профиль
              MenuButton(
                myIcons: Icons.person_outline,
                title: 'Мой профиль',
                press: () async {
                  getListTaskForeman();
                  IntTest.indexScreensDispatcher = 4;
                  IntTest.myTitle = 'Мой профиль';
                  setState(() {});
                  myStream.add(IntTest.indexScreensDispatcher);
                },
                colorButton: IntTest.indexScreensDispatcher == 4
                    ? ColorApp.myColorGreenLine
                    : Colors.transparent,
              ),

              /// Выход
              MenuButton(
                myIcons: Icons.logout,
                title: 'Выйти',
                press: () => signOut(),
                colorButton: Colors.transparent,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
/// ========================================================