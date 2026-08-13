import 'package:flutter/material.dart';
import '../../helper/class_colors.dart';
import '../../helper/header/header.dart';
import '../../helper/my_drawer/my_drawer.dart';
import '../../helper/my_user.dart';
import '../employee/view/employees_screen.dart';
import '../home_page/home_page.dart';
import '../responsive_screens/responsive.dart';
import 'best_employee.dart';
import 'overdue_maintenance.dart';
import 'schedule_execution/schedule_execution.dart';
import 'top_breakdowns/top_breakdowns.dart';

///Главная

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    Key? key,
  }) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  @override
  void initState() {
    getListEmployee();
    myStream.add(IntTest.indexScreens);
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return Scaffold(
      key: myOpenDrawer,
      drawer: const MyDrawer(),
      body: Container(
        color: ColorApp.myColorTransparent,
        child: !Responsive.isMobile(context)
            ? Column(
          children: [
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
                  Text('Главная',
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
            const Expanded(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    ///Топ поломок
                    Expanded(
                      child: Column(
                        children: [
                          Expanded(child: TopBreakdowns()),
                          SizedBox(height: 20.0),
                          ///Просроченные ТО
                          Expanded(child: OverdueMaintenance()),
                        ],
                      ),
                    ),
                    SizedBox(width: 20.0),
                    ///Правый блок
                    Expanded(
                      child: Column(
                        children: [
                          /// Выполнение графика
                          Expanded(flex: 4, child: ScheduleExecution()),
                          // SizedBox(height: 20.0),
                          /// Лучший сотрудник
                          // Expanded(
                          //   flex: 3,
                          //   child: BestEmployee(),
                          // ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        )
            : SingleChildScrollView(
          child: Column(
            children: [
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
                    const Text('Главная',style: TextStyle(color: Colors.black,fontSize: 20.0,fontWeight: FontWeight.w600),),

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
              const TopBreakdowns(),
              const SizedBox(height: 10.0),
              const ScheduleExecution(),
              const SizedBox(height: 10.0),
              const OverdueMaintenance(),
              // const SizedBox(height: 10.0),
              // StreamBuilder(
              //   stream: myStream.stream,
              //   builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
              //     return const BestEmployee();
              //   },
              // ),
            ],
          ),
        ),
      ),
    );

  }
}
