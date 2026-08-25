import 'package:els/screns/object/view/object_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../bloc/company_bloc/company_bloc.dart';
import '../../screns/companies/view/companies_screen.dart';
import '../../screns/employee/bloc/employee_bloc.dart';
import '../../screns/employee/view/employees_screen.dart';
import '../../screns/home_page/home_page.dart';
import '../../screns/object/bloc/object_bloc.dart';
import '../../screns/schedule/schedule_screen.dart';
import '../../screns/task/bloc_task/task_bloc.dart';
import '../../screns/task/view/task_screen.dart';
import '../button/side_menu_button.dart';
import '../class_colors.dart';
import '../session.dart';

/// MyDrawer =====================================
class MyDrawer extends StatefulWidget {
  const MyDrawer({Key? key}) : super(key: key);

  @override
  State<MyDrawer> createState() => _MyDrawerState();
}

class _MyDrawerState extends State<MyDrawer> {

  final _url = 'https://tochkalift.ru/';

  void _launchURL() async =>
      await canLaunch(_url) ? await launch(_url) : throw 'Could not launch $_url';


  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
          stream: myStream.stream,
          builder: (context, ind) => Drawer(
            backgroundColor: Colors.white,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 30.0),
                    const Text(
                      'Единая лифтовая служба',
                      style: TextStyle(
                        fontSize: 19.0,
                        fontWeight: FontWeight.w700,
                        color: ColorApp.myColorGreenAuth,
                      ),
                    ),
                    const SizedBox(height: 30.0),

                    ///Главная
                    MenuButton(
                      myIcons: Icons.home_outlined,
                      title: 'Главная',
                      press: () {
                        IntTest.indexScreens = 0;
                        IntTest.myTitle = 'Главная';
                        myStream.add(IntTest.indexScreens);
                        setState(() {});
                      },
                      colorButton: IntTest.indexScreens == 0
                          ? ColorApp.myColorGreenLine
                          : Colors.transparent,
                    ),

                    ///График
                    MenuButton(
                      myIcons: Icons.calendar_today,
                      title: 'График',
                      press: () async {
                        await getScheduleFun();
                        dataSchedule = getScheduleList;
                        IntTest.indexScreens = 1;
                        IntTest.myTitle = 'График';
                        myStream.add(IntTest.indexScreens);
                        setState(() {});
                      },
                      colorButton: IntTest.indexScreens == 1
                          ? ColorApp.myColorGreenLine
                          : Colors.transparent,
                    ),

                    ///Задачи
                    BlocBuilder<TaskBloc, TaskState>(
                      builder: (context, state) {
                        return Stack(
                          children: [
                            MenuButton(
                              myIcons: Icons.list_alt,
                              title: 'Задачи',
                              press: () async {
                                TaskBloc().add(TaskGetEvent());
                                IntTest.indexScreens = 2;
                                IntTest.myTitle = 'Задачи';
                                setState(() {});
                                myStream.add(IntTest.indexScreens);
                              },
                              colorButton: IntTest.indexScreens == 2
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
                        );
                      },
                    ),

                    /// Выполненые Задачи
                    BlocBuilder<TaskBloc, TaskState>(
                      builder: (context, state) {
                        return Stack(
                          children: [
                            MenuButton(
                              myIcons: Icons.check_box_outlined,
                              title: 'Выполненые Задачи',
                              press: () async {
                                IntTest.indexScreens = 21;
                                myStream.add(IntTest.indexScreens);
                                setState(() {});
                              },
                              colorButton: IntTest.indexScreens == 21
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
                        );
                      },
                    ),

                    ///Обьекты
                    BlocBuilder<MyObjectBloc, MyObjectState>(
                      builder: (context, state) {
                        return Stack(
                          children: [
                            MenuButton(
                              myIcons: Icons.radio_button_checked_outlined,
                              title: 'Обьекты',
                              press: () {
                                getListObjectArchive();
                                getAllListOfObjects();
                                // MyObjectBloc().add(ObjectGetEvent());
                                // getObject = state.modelObjectList;
                                IntTest.indexScreens = 3;
                                IntTest.myTitle = 'Обьекты';
                                myStream.add(IntTest.indexScreens);
                                setState(() {});
                              },
                              colorButton: IntTest.indexScreens == 3
                                  ? ColorApp.myColorGreenLine
                                  : Colors.transparent,
                            ),
                            if(getAllObject.isNotEmpty)
                              for(var i = 0; i < getAllObject.length; i++)
                                if(getAllObject[i]['foreman_id'] ? ['is_active'] == false || getAllObject[i]['foreman_id'] == null || getAllObject[i]['mechanic_id'] ? ['is_active'] == false || getAllObject[i]['mechanic_id'] == null)
                                  Positioned(
                                      right: 8.0,
                                      top: 8.0,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(5.0),
                                          color: Colors.red[300],
                                        ),
                                        width: 25,
                                        height: 25,
                                        child: const Center(
                                            child: Text(
                                              '!',
                                              style:
                                              TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                                            )),
                                      )),

                          ],
                        );
                      },
                    ),

                    ///Компании
                    BlocBuilder<CompanyBloc, CompanyState>(
                      builder: (context, state) {
                        return MenuButton(
                          myIcons: Icons.domain,
                          title: 'Компании',
                          press: () async {
                            CompanyBloc().add(CompanyGetUserEvent());
                            if (state is CompanyGetState) {
                              getCompany = state.listGetCompany;
                            }
                            IntTest.indexScreens = 4;
                            IntTest.myTitle = 'Компании';
                            myStream.add(IntTest.indexScreens);
                            if (state is CompanyGetState) {
                              dataCompany = state.listGetCompany;
                            }
                            setState(() {});
                          },
                          colorButton: IntTest.indexScreens == 4
                              ? ColorApp.myColorGreenLine
                              : Colors.transparent,
                        );
                      },
                    ),

                    ///Отчеты
                    Stack(
                      children: [
                        // Бейджа у отчётов нет намеренно: здесь была
                        // константа `numberReports = 3`, которая ничего
                        // не считала.
                        MenuButton(
                          myIcons: Icons.bar_chart_outlined,
                          title: 'Отчеты',
                          press: () {
                            IntTest.indexScreens = 5;
                            IntTest.myTitle = 'Отчеты';
                            myStream.add(IntTest.indexScreens);
                            setState(() {});
                          },
                          colorButton: IntTest.indexScreens == 5
                              ? ColorApp.myColorGreenLine
                              : Colors.transparent,
                        ),
                      ],
                    ),

                    ///Сотрудники
                    BlocBuilder<EmployeeBloc, EmployeeState>(
                      builder: (context, state) {
                        return MenuButton(
                          myIcons: Icons.people_outlined,
                          title: 'Сотрудники',
                          press: () async {
                            IntTest.indexScreens = 6;
                            EmployeeBloc().add(EmployeeGetUserEvent());
                            dataEmployee = getEmployee;
                            myStream.add(IntTest.indexScreens);
                            setState(() {});
                          },
                          colorButton: IntTest.indexScreens == 6
                              ? ColorApp.myColorGreenLine
                              : Colors.transparent,
                        );
                      },
                    ),

                    ///Задачи
                    // Stack(
                    //   children: [
                    //     MenuButton(
                    //       myIcons: Icons.task_outlined,
                    //       title: 'Задачи',
                    //       press: () {
                    //         IntTest.indexScreens = 7;
                    //         IntTest.myTitle = 'Задачи';
                    //         setState(() {});
                    //       },
                    //       colorButton: IntTest.indexScreens == 7
                    //           ? ColorApp.myColorGreenLine
                    //           : Colors.transparent,
                    //     ),
                    //     if (numberTask != 0)
                    //       Positioned(
                    //           right: 8.0,
                    //           top: 8.0,
                    //           child: AlertsWidget(
                    //             alertsNumber: numberTask,
                    //             myColor: ColorApp.myColorGreen,
                    //           )),
                    //   ],
                    // ),
                    // const SizedBox(height: 10.0),

                    ///Охрана труда
                    // Stack(
                    //   children: [
                    //     MenuButton(
                    //       myIcons: Icons.engineering_outlined,
                    //       title: 'Охрана труда',
                    //       press: () {
                    //         IntTest.indexScreens = 8;
                    //         IntTest.myTitle = 'Охрана труда';
                    //         setState(() {});
                    //       },
                    //       colorButton: IntTest.indexScreens == 8
                    //           ? ColorApp.myColorGreenLine
                    //           : Colors.transparent,
                    //     ),
                    //     if (numberLaborProtection != 0)
                    //       Positioned(
                    //           right: 8.0,
                    //           top: 8.0,
                    //           child: AlertsWidget(
                    //             alertsNumber: numberLaborProtection,
                    //             myColor: ColorApp.myColorGreen,
                    //           )),
                    //   ],
                    // ),
                    // const SizedBox(height: 10.0),

                    ///Магазины
                    // MenuButton(
                    //   myIcons: Icons.storefront_outlined,
                    //   title: 'Магазины',
                    //   press: () async {
                    //     IntTest.indexScreens = 24;
                    //     IntTest.myTitle = 'Магазины';
                    //     _launchURL();
                    //     setState(() {});
                    //   },
                    //   colorButton: IntTest.indexScreens == 24
                    //       ? ColorApp.myColorGreenLine
                    //       : Colors.transparent,
                    // ),
                    const SizedBox(height: 10.0),

                    ///Выход
                    MenuButton(
                      myIcons: Icons.logout,
                      title: 'Выйти',
                      press: () => signOut(),
                      colorButton: Colors.transparent,
                    ),
                    const SizedBox(height: 10.0),
                  ],
                ),
              ),
            ),
          ));


  }
}
/// ==============================================