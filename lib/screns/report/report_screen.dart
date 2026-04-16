import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import '../../helper/class_colors.dart';
import '../../helper/header/header.dart';
import '../../helper/my_drawer/my_drawer.dart';
import '../../helper/my_user.dart';

///Отчеты

class ReportScreen extends StatefulWidget {
  const ReportScreen({Key? key}) : super(key: key);
  @override
  State<ReportScreen> createState() => _ReportScreenState();
}


class _ReportScreenState extends State<ReportScreen> {
  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return Scaffold(
      key: myOpenDrawer,
      drawer: const MyDrawer(),
      body: Container(
        color: ColorApp.myColorTransparent,
        child: Column(
          children:  [
            ///Header =====
            Container(
              padding: const EdgeInsets.symmetric(horizontal:ColorApp.kPadding),
              color: Colors.white,
              height: 70,
              width: double.infinity,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
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
                                size: size.width > 350
                                    ? 25.0
                                    : 20)),
                        const SizedBox(width: 10.0),
                      ],
                    ),
                  /// Текст
                  Text('Отчеты',
                      style: TextStyle(
                          fontSize: size.width > 350
                              ? 25.0
                              : 18.0,
                          fontWeight: size.width > 350
                              ? FontWeight.w700
                              : FontWeight.w500)),
                  const Spacer(),
                  ///Колокольчик
                  if (size.width > 400)
                    Badge(
                      alignment:
                      const AlignmentDirectional(21, 4),
                      backgroundColor: ColorApp.myColorRed,
                      isLabelVisible: IntTest.badgeCount > 0
                          ? true
                          : false,
                      label: IntTest.badgeCount < 1
                          ? const SizedBox.shrink()
                          : Text(
                          IntTest.badgeCount.toString(),
                          style: const TextStyle(
                              fontSize: 12.0,
                              color:
                              ColorApp.myColorWhite,
                              fontWeight:
                              FontWeight.w500)),
                      child: IconButton(
                        onPressed: () {},
                        icon: const Icon(
                            Icons
                                .notifications_none_outlined,
                            size: 25.0),
                      ),
                    ),
                  SizedBox(width: size.width > 500 ? 40.0 : 10.0),
                  ///Аватар Юзера
                  const MyUser(),
                ],
              ),
            ),
            /// ===========
            const Spacer(),
            Center(child: Lottie.asset('assets/Animation - 1718366497487.json')),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

