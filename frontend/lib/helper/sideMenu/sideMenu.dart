import 'package:els/helper/button/side_menu_button.dart';
import 'package:flutter/material.dart';

import '../class_colors.dart';



class MyDrawer extends StatefulWidget {
  const MyDrawer({Key? key}) : super(key: key);

  @override
  State<MyDrawer> createState() => _MyDrawerState();
}

class _MyDrawerState extends State<MyDrawer> {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 30.0),
              const Text(
                'Единая лифтовая служба',
                style: TextStyle(
                  fontSize: 20.0,
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
                  setState(() {});
                },
                colorButton: IntTest.indexScreens == 0
                    ? ColorApp.myColorGreenLine
                    : Colors.transparent,
              ),
              const SizedBox(height: 10.0),

              ///График
              MenuButton(
                myIcons: Icons.calendar_today,
                title: 'График',
                press: () {
                  IntTest.indexScreens = 1;
                  IntTest.myTitle = 'График';
                  setState(() {});
                },
                colorButton: IntTest.indexScreens == 1
                    ? ColorApp.myColorGreenLine
                    : Colors.transparent,
              ),
              const SizedBox(height: 10.0),

              ///Заявки
              Stack(
                children: [
                  MenuButton(
                    myIcons: Icons.list_alt,
                    title: 'Заявки',
                    press: () {
                      IntTest.indexScreens = 2;
                      IntTest.myTitle = 'Заявки';
                      setState(() {});
                    },
                    colorButton: IntTest.indexScreens == 2
                        ? ColorApp.myColorGreenLine
                        : Colors.transparent,
                  ),
                  if (numberApplications != 0)
                    Positioned(
                        right: 8.0,
                        top: 8.0,
                        child: AlertsWidget(
                          alertsNumber: numberApplications,
                          myColor: ColorApp.myColorRed,
                        )),
                ],
              ),
              const SizedBox(height: 10.0),

              ///Обьекты
              MenuButton(
                myIcons: Icons.radio_button_checked_outlined,
                title: 'Обьекты',
                press: () {
                  IntTest.indexScreens = 3;
                  IntTest.myTitle = 'Обьекты';
                  setState(() {});
                },
                colorButton: IntTest.indexScreens == 3
                    ? ColorApp.myColorGreenLine
                    : Colors.transparent,
              ),
              const SizedBox(height: 10.0),

              ///Компании
              MenuButton(
                myIcons: Icons.domain,
                title: 'Компании',
                press: () async {
                  // companyBloc.add(CompanyGetUserEvent());
                  IntTest.indexScreens = 4;
                  IntTest.myTitle = 'Компании';
                  setState(() {});
                },
                colorButton:  IntTest.indexScreens == 4
                    ? ColorApp.myColorGreenLine
                    : Colors.transparent,
              ),
              const SizedBox(height: 10.0),

              ///Отчеты
              // Бейджа у отчётов нет намеренно: здесь была константа
              // `numberReports = 3`, которая ничего не считала.
              MenuButton(
                myIcons: Icons.bar_chart_outlined,
                title: 'Отчеты',
                press: () {
                  IntTest.indexScreens = 5;
                  IntTest.myTitle = 'Отчеты';
                  setState(() {});
                },
                colorButton: IntTest.indexScreens == 5
                    ? ColorApp.myColorGreenLine
                    : Colors.transparent,
              ),
              const SizedBox(height: 10.0),

              ///Сотрудники
              MenuButton(
                myIcons: Icons.people_outlined,
                title: 'Сотрудники',
                press: () async {
                  // employeeBloc.add(EmployeeGetUserEvent());
                  IntTest.indexScreens = 6;
                  IntTest.myTitle = 'Сотрудники';
                  setState(() {});
                },
                colorButton:  IntTest.indexScreens == 6
                    ? ColorApp.myColorGreenLine
                    : Colors.transparent,
              ),
              const SizedBox(height: 10.0),

              ///Задачи
              Stack(
                children: [
                  MenuButton(
                    myIcons: Icons.task_outlined,
                    title: 'Задачи',
                    press: () {
                      IntTest.indexScreens = 7;
                      IntTest.myTitle = 'Задачи';
                      setState(() {});
                    },
                    colorButton:  IntTest.indexScreens == 7
                        ? ColorApp.myColorGreenLine
                        : Colors.transparent,
                  ),
                  if (numberTask != 0)
                    Positioned(
                        right: 8.0,
                        top: 8.0,
                        child: AlertsWidget(
                          alertsNumber: numberTask,
                          myColor: ColorApp.myColorGreen,
                        )),
                ],
              ),
              const SizedBox(height: 10.0),

              ///Охрана труда
              Stack(
                children: [
                  MenuButton(
                    myIcons: Icons.engineering_outlined,
                    title: 'Охрана труда',
                    press: () {
                      IntTest.indexScreens = 8;
                      IntTest.myTitle = 'Охрана труда';
                      setState(() {});
                    },
                    colorButton:  IntTest.indexScreens == 8
                        ? ColorApp.myColorGreenLine
                        : Colors.transparent,
                  ),
                  if (numberLaborProtection != 0)
                    Positioned(
                        right: 8.0,
                        top: 8.0,
                        child: AlertsWidget(
                          alertsNumber: numberLaborProtection,
                          myColor: ColorApp.myColorGreen,
                        )),
                ],
              ),
              const SizedBox(height: 10.0),

              ///Окно компании
              MenuButton(
                myIcons: Icons.store_outlined,
                title: 'Просмотр компании',
                press: () async {
                  IntTest.indexScreens = 10;
                  IntTest.myTitle = 'компании';
                  setState(() {});
                },
                colorButton:  IntTest.indexScreens == 10
                    ? ColorApp.myColorGreenLine
                    : Colors.transparent,
              ),
              const SizedBox(height: 10.0),

              ///Окно Обьекта
              MenuButton(
                myIcons: Icons.emoji_objects_outlined,
                title: 'Просмотр Обьекта',
                press: () async {
                  IntTest.indexScreens = 11;
                  IntTest.myTitle = 'Просмотр Обьекта';
                  setState(() {});
                },
                colorButton:  IntTest.indexScreens == 11
                    ? ColorApp.myColorGreenLine
                    : Colors.transparent,
              ),
            ],
          ),
        ),
      ),
    );
  }
}


