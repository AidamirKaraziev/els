import 'package:els/dispatcher/task_screen_dispatcher/application_screen.dart';
import 'package:els/foreman/task_foreman/task_screen_foreman.dart';
import 'package:els/owner/object_owner.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../screns/home_page/home_page.dart';
import '../helper/button/side_menu_button.dart';
import '../helper/class_colors.dart';
import '../helper/session.dart';

/// MyDrawer собственик ========================

class DrawerOwner extends StatefulWidget {
  const DrawerOwner({Key? key}) : super(key: key);

  @override
  State<DrawerOwner> createState() => _DrawerOwnerState();
}

class _DrawerOwnerState extends State<DrawerOwner> {
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

              ///Обьекты
              MenuButton(
                myIcons: Icons.radio_button_checked_outlined,
                title: 'Мои обьекты',
                press: () async {
                  // await getListObjectOwner();

                  IntTest.indexScreensOwner = 0;
                  IntTest.myTitle = 'Обьекты';
                  myStream.add(IntTest.indexScreensOwner);
                  setState(() {});
                },
                colorButton: IntTest.indexScreensOwner == 0
                    ? ColorApp.myColorGreenLine
                    : Colors.transparent,
              ),

              /// Мой профиль
              MenuButton(
                myIcons: Icons.person_outline,
                title: 'Мой профиль',
                press: () async {
                  getListTaskForeman();
                  IntTest.indexScreensOwner = 1;
                  IntTest.myTitle = 'Мой профиль';
                  setState(() {});
                  myStream.add(IntTest.indexScreensOwner);
                },
                colorButton: IntTest.indexScreensOwner == 4
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