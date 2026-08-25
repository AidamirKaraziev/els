import 'package:els/screns/user/user_contact.dart';
import 'package:els/screns/user/user_doc.dart';
import 'package:els/screns/user/user_info.dart';
import 'package:els/screns/user/user_profile.dart';
import 'package:els/screns/user/widgets/editing_profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/user_bloc/user_bloc.dart';
import '../../helper/class_colors.dart';
import '../../helper/header/header.dart';
import '../../helper/hints/hints_switch.dart';
import '../../helper/my_drawer/my_drawer.dart';
import '../../helper/my_user.dart';
import '../../helper/sign_out_button.dart';
import '../home_page/home_page.dart';

///Мой профиль

class MyProfile extends StatefulWidget {
  const MyProfile({
    Key? key,
    this.drawer = const MyDrawer(),
  }) : super(key: key);

  /// Боковое меню экрана. Профиль общий для всех ролей, а меню у них разные:
  /// прошитый здесь `MyDrawer` показывал прорабу бургер админа.
  final Widget drawer;

  @override
  State<MyProfile> createState() => _MyProfileState();
}

class _MyProfileState extends State<MyProfile> {
  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return  Scaffold(
      key: myOpenDrawer,
      drawer: widget.drawer,
      body: Container(
        color: ColorApp.myColorTransparent,
        child: SingleChildScrollView(
          child: Column(
            children: [
              ///Header ========
              StreamBuilder(
                stream: myStream.stream,
                builder: (context, ind) => Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: ColorApp.kPadding),
                  color: Colors.white,
                  height: 70,
                  width: double.infinity,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      ///Назад — на раздел, с которого зашли
                      ProfileBackButton(
                        onBack: () => setState(() {}),
                        size: size.width > 350 ? 25.0 : 20,
                      ),
                      const SizedBox(width: 4.0),

                      ///Иконка меню
                      if (size.width <= 1350)
                        Row(
                          children: [
                            IconButton(
                                onPressed: () {
                                  myOpenDrawer.currentState!.openDrawer();
                                  setState(() {});
                                },
                                icon: Icon(Icons.menu,
                                    size: size.width > 350 ? 25.0 : 20)),
                            const SizedBox(width: 10.0),
                          ],
                        ),

                      /// Текст
                      Text('Личный профиль',
                          style: TextStyle(
                              fontSize: size.width > 350 ? 25.0 : 18.0,
                              fontWeight: size.width > 350
                                  ? FontWeight.w700
                                  : FontWeight.w500)),
                      const SizedBox(width: 10.0),

                      /// изменить Профиль User
                      if (size.width > 500)
                        IconButton(
                            onPressed: () async {
                              setState(() {
                                showDialog(
                                    context: context,
                                    builder: (context) => const AlertDialog(
                                      content: EditingProfile(),
                                    )).then((value) => setState(() {}));
                              });
                            },
                            icon: const Icon(Icons.edit_outlined,
                                size: 25.0,
                                color: ColorApp.myColorGreenAuth)),
                      const Spacer(),

                      ///Колокольчик
                      if (size.width > 400)
                        Badge(
                          alignment: const AlignmentDirectional(21, 4),
                          backgroundColor: ColorApp.myColorRed,
                          isLabelVisible:
                          IntTest.badgeCount > 0 ? true : false,
                          label: IntTest.badgeCount < 1
                              ? const SizedBox.shrink()
                              : Text(IntTest.badgeCount.toString(),
                              style: const TextStyle(
                                  fontSize: 12.0,
                                  color: ColorApp.myColorWhite,
                                  fontWeight: FontWeight.w500)),
                          child: IconButton(
                            onPressed: () {},
                            icon: const Icon(
                                Icons.notifications_none_outlined,
                                size: 25.0),
                          ),
                        ),
                      SizedBox(width: size.width > 500 ? 40.0 : 10.0),

                      ///Аватар Юзера
                      const MyUser(),
                    ],
                  ),
                ),
              ),
              /// ==============
              if (size.width > 600)
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Row(
                        children: const [
                          UserProfile(),
                          SizedBox(width: 20.0),
                          Expanded(child: UserInfo()),
                        ],
                      ),
                      const SizedBox(height: 20.0),
                      Row(
                        children: const [
                          Expanded(child: UserContact()),
                          SizedBox(width: 20.0),
                          Expanded(child: UserDoc()),
                        ],
                      ),
                      const SizedBox(height: 20.0),
                      const HintsSwitch(),
                      const SizedBox(height: 24.0),
                      const SignOutButton(),
                    ],
                  ),
                )
              else Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    UserProfile(),
                    SizedBox(height: 20.0),
                    UserInfo(),
                    SizedBox(height: 20.0),
                    UserContact(),
                    SizedBox(height: 20.0),
                    UserDoc(),
                    SizedBox(height: 24.0),
                    SignOutButton(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
