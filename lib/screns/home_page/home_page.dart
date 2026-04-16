import 'dart:async';
import 'package:els/screns/companies/view/companies_screen.dart';
import 'package:els/screns/companies/view/company_page.dart';
import 'package:els/screns/home/home_screen.dart';
import 'package:els/screns/object/view/object_screen.dart';
import 'package:els/screns/report/report_screen.dart';
import 'package:els/screns/schedule/schedule_screen.dart';
import 'package:els/screns/task/view/task_screen.dart';
import 'package:els/screns/user/user_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../helper/class_colors.dart';
import '../../helper/my_drawer/my_drawer.dart';
import '../../my_test_screen.dart';
import '../companies/view/companies_screen_archive.dart';
import '../companies/view/company_page_archive.dart';
import '../employee/view/employee_archive_page.dart';
import '../employee/view/employees_archive_screen.dart';
import '../employee/view/employees_screen.dart';
import '../employee/view/employee_page.dart';
import '../../bloc/user_bloc/user_bloc.dart';
import '../object/view/object_page.dart';
import '../object/view/object_page_archive.dart';
import '../object/view/object_screen_archive.dart';
import '../schedule/schedule_page.dart';
import '../task/view/archive/task_page_archive.dart';
import '../task/view/archive/task_screen_archive.dart';
import '../task/view/task_page.dart';
import '../test_window.dart';

///Главная User

///Это временно ====================================================
StreamController myStream = StreamController.broadcast();
/// ================================================================

///Это временно ====================================================
StreamController myStreamListPlanetTO = StreamController.broadcast();
/// ================================================================

///Это временно ====================================================
StreamController myStreamTask = StreamController.broadcast();
/// ================================================================

///Это временно ====================================================
StreamController myStreamProfile = StreamController.broadcast();
/// ================================================================

///Это временно ====================================================
StreamController myStreamPhotoDoc = StreamController.broadcast();
/// ================================================================

class HomePage extends StatefulWidget {
  const HomePage({
    Key? key,
  }) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  ///Список Страниц
  final List<Widget> _screens = [
    ///Главная 0
    const HomeScreen(),

    ///Графики 1
    const ScheduleScreen(),

    ///Заявки 2
    const TaskScreen(),

    ///Обьекты 3
    const ObjectScreen(),

    ///Компании 4
    const CompaniesScreen(),

    ///Отчеты 5
    const ReportScreen(),

    ///Сотрудники 6
     const EmployeesScreen(),

    ///Задачи 7
    const TaskScreen(), ///

    ///Охрана Труда 8
    // const WorksScreen(),

    ///Окно Юзера 9
    const MyProfile(),

    ///Окно выбранной Компании 10
    const CompanyPage(),

    ///Окно выбранного Обьекта 11
    const ObjectPage(),

    ///Окно выбранного Юзера 12
    const OpenViewEmployee(),

    ///  13
    const SchedulePage(),
    /// Окно выбранной задачи 14
    const TaskPage(),
    ///Окно Test 15
    const TestWindow(),
    ///Окно Архив сотрудники 16
     EmployeesArchiveScreen(),
    ///Окно Архив выбранного сотрудника 17
    const OpenViewEmployeeArchive(),
    ///Окно Архив Компании 18
    const CompaniesScreenArchive(),
    ///Окно Архив выбранной компании 19
    const CompanyPageArchive(),
    ///Окно Архив списка объектов 20
    const ObjectScreenArchive(),
    ///Окно Архив выбранного объекта 21
    const ObjectPageArchive(),
    ///Окно Архив Задач 22
    const TaskScreenArchive(),
    ///Окно Архив выбранной задачи 23
    const TaskPageArchive(),
  ];

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return BlocBuilder<UserBloc, UserState>(
      builder: (context, state) {
        return Scaffold(
          body: Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    ///Боковое меню
                    if (size.width > 1350)
                      const Expanded(
                        flex: 2,
                        child: MyDrawer(),
                      ),
                    /// Body
                    Expanded(
                      flex: 8,
                      child: Column(
                        children: [
                          /// Body
                          StreamBuilder(
                            stream: myStream.stream,
                            builder: (context, ind) => Expanded(
                              flex: 9,
                              child: _screens[IntTest.indexScreens],
                            ),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
