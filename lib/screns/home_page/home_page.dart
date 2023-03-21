import 'dart:async';
import 'package:els/bloc/company_bloc/company_bloc.dart';
import 'package:els/screns/applications/applications_screen.dart';
import 'package:els/screns/companies/add_companies.dart';
import 'package:els/screns/companies/companies_screen.dart';
import 'package:els/screns/companies/company_page.dart';
import 'package:els/screns/employee/widgets/add_employee.dart';
import 'package:els/screns/employee/view/employees_screen.dart';
import 'package:els/screns/home/home_screen.dart';
import 'package:els/screns/object/bloc/object_bloc.dart';
import 'package:els/screns/object/view/object_screen.dart';
import 'package:els/screns/report/report_screen.dart';
import 'package:els/screns/schedule/schedule_screen.dart';
import 'package:els/screns/task/task_screen.dart';
import 'package:els/screns/user/user_page.dart';
import 'package:els/screns/works/works_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../employee/view/open_ view_user.dart';
import '../../bloc/user_bloc/user_bloc.dart';
import '../../helper/button/side_menu_button.dart';
import '../../helper/class_colors.dart';
import '../employee/bloc/employee_bloc.dart';
import '../employee/widgets/add_employee_class.dart';
import '../employee/widgets/editing_employee.dart';
import '../my_shop/my_shop.dart';
import '../object/view/object_page.dart';
import '../object/widgets/add_object.dart';
import '../object/widgets/editing_object.dart';

///Главная User

///Это временно ====================================================
StreamController pointsMapController = StreamController.broadcast();
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
    const ApplicationsScreen(),

    ///Обьекты 3
    const ObjectScreen(),

    ///Компании 4
    const CompaniesScreen(),

    ///Отчеты 5
    const ReportScreen(),

    ///Сотрудники 6
    const EmployeesScreen(),

    ///Задачи 7
    const TaskScreen(),

    ///Охрана Труда 8
    const WorksScreen(),

    ///Окно Юзера 9
    const UserPage(),

    ///Окно выбранной Компании 10
    const CompanyPage(),

    ///Окно выбранного Обьекта 11
    const ObjectPage(),

    ///Окно выбранного Юзера 12
    const OpenViewUser(),

    ///Окно Магазины 13
    const MyShop(),
  ];

  bool openListSearch = false;

  final GlobalKey<ScaffoldState> myOpenDrawer = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final employeeBloc = EmployeeBloc();
    final companyBloc = CompanyBloc();
    // final userBloc = UserBloc();
    return BlocBuilder<UserBloc, UserState>(
      builder: (context, state) {
        return Scaffold(
          key: myOpenDrawer,
          drawer: Drawer(
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
                        MyObjectBloc().add(ObjectGetEvent());
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
                        companyBloc.add(CompanyGetUserEvent());
                        IntTest.indexScreens = 4;
                        IntTest.myTitle = 'Компании';
                        setState(() {});
                      },
                      colorButton: IntTest.indexScreens == 4
                          ? ColorApp.myColorGreenLine
                          : Colors.transparent,
                    ),
                    const SizedBox(height: 10.0),

                    ///Отчеты
                    Stack(
                      children: [
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
                        if (numberReports != 0)
                          Positioned(
                              right: 8.0,
                              top: 8.0,
                              child: AlertsWidget(
                                alertsNumber: numberReports,
                                myColor: ColorApp.myColorGreen,
                              )),
                      ],
                    ),
                    const SizedBox(height: 10.0),

                    ///Сотрудники
                    MenuButton(
                      myIcons: Icons.people_outlined,
                      title: 'Сотрудники',
                      press: () async {
                        employeeBloc.add(EmployeeGetUserEvent());
                        IntTest.indexScreens = 6;
                        IntTest.myTitle = 'Сотрудники';
                        setState(() {});
                      },
                      colorButton: IntTest.indexScreens == 6
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
                          colorButton: IntTest.indexScreens == 7
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
                          colorButton: IntTest.indexScreens == 8
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

                    ///Магазины
                    MenuButton(
                      myIcons: Icons.storefront_outlined,
                      title: 'Магазины',
                      press: () async {
                        IntTest.indexScreens = 13;
                        IntTest.myTitle = 'Магазины';
                        setState(() {});
                      },
                      colorButton: IntTest.indexScreens == 13
                          ? ColorApp.myColorGreenLine
                          : Colors.transparent,
                    ),
                    const SizedBox(height: 10.0),
                  ],
                ),
              ),
            ),
          ),
          backgroundColor: Colors.white,
          body: Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    ///Боковое меню
                    if (size.width > 1350)
                      Expanded(
                        flex: 2,
                        child: Drawer(
                          backgroundColor: Colors.white,
                          child: Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 24.0),
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
                                    myIcons:
                                        Icons.radio_button_checked_outlined,
                                    title: 'Обьекты',
                                    press: () {
                                      IntTest.indexScreens = 3;
                                      IntTest.myTitle = 'Обьекты';
                                      MyObjectBloc().add(ObjectGetEvent());
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
                                      companyBloc.add(CompanyGetUserEvent());
                                      IntTest.indexScreens = 4;
                                      IntTest.myTitle = 'Компании';
                                      setState(() {});
                                    },
                                    colorButton: IntTest.indexScreens == 4
                                        ? ColorApp.myColorGreenLine
                                        : Colors.transparent,
                                  ),
                                  const SizedBox(height: 10.0),

                                  ///Отчеты
                                  Stack(
                                    children: [
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
                                      if (numberReports != 0)
                                        Positioned(
                                            right: 8.0,
                                            top: 8.0,
                                            child: AlertsWidget(
                                              alertsNumber: numberReports,
                                              myColor: ColorApp.myColorGreen,
                                            )),
                                    ],
                                  ),
                                  const SizedBox(height: 10.0),

                                  ///Сотрудники
                                  MenuButton(
                                    myIcons: Icons.people_outlined,
                                    title: 'Сотрудники',
                                    press: () async {
                                      employeeBloc.add(EmployeeGetUserEvent());
                                      IntTest.indexScreens = 6;
                                      IntTest.myTitle = 'Сотрудники';
                                      setState(() {});
                                    },
                                    colorButton: IntTest.indexScreens == 6
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
                                        colorButton: IntTest.indexScreens == 7
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
                                        colorButton: IntTest.indexScreens == 8
                                            ? ColorApp.myColorGreenLine
                                            : Colors.transparent,
                                      ),
                                      if (numberLaborProtection != 0)
                                        Positioned(
                                            right: 8.0,
                                            top: 8.0,
                                            child: AlertsWidget(
                                              alertsNumber:
                                                  numberLaborProtection,
                                              myColor: ColorApp.myColorGreen,
                                            )),
                                    ],
                                  ),
                                  const SizedBox(height: 10.0),
                                  ///Магазины
                                  MenuButton(
                                    myIcons: Icons.storefront_outlined,
                                    title: 'Магазины',
                                    press: () async {
                                      employeeBloc.add(EmployeeGetUserEvent());
                                      IntTest.indexScreens = 13;
                                      IntTest.myTitle = 'Магазины';
                                      setState(() {});
                                    },
                                    colorButton: IntTest.indexScreens == 13
                                        ? ColorApp.myColorGreenLine
                                        : Colors.transparent,
                                  ),
                                  const SizedBox(height: 10.0),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                    /// Header Body
                    Expanded(
                      flex: 8,
                      child: Column(
                        children: [
                          /// Header
                          StreamBuilder(
                            stream: pointsMapController.stream,
                            builder: (context, ind) => Expanded(
                                flex: 1,
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal:
                                          size.width > 600 ? 20.0 : 10.0),
                                  child: Row(
                                    children: [
                                      ///Иконка меню
                                      if (size.width <= 1350)
                                        Row(
                                          children: [
                                            IconButton(
                                                onPressed: () {
                                                  myOpenDrawer.currentState!
                                                      .openDrawer();
                                                  setState(() {});
                                                },
                                                icon: Icon(Icons.menu,
                                                    size: size.width > 350
                                                        ? 25.0
                                                        : 20)),
                                            const SizedBox(width: 10.0),
                                          ],
                                        ),

                                      /// Кнопка Назад Компании ====
                                      if (IntTest.indexScreens == 10)
                                      Row(
                                        children: [
                                          Container(
                                            width: 30.0,
                                            height: 30.0,
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(5.0),
                                              border: Border.all(color: ColorApp.myColorGrayBorder,width: 1),
                                              color: Colors.white,
                                              boxShadow: const [
                                                BoxShadow(
                                                  color: ColorApp.myColorAvatar,
                                                  blurRadius: 5,
                                                ),
                                              ],
                                            ),
                                            child: IconButton(
                                                onPressed: () {
                                                  setState(() {
                                                    IntTest.indexScreens = 4;
                                                    pointsMapController.add(IntTest.indexScreens);
                                                  });
                                                },
                                                icon: const Icon(
                                                  Icons.arrow_back_ios_new_rounded,
                                                  color: Colors.black,size: 13.0,
                                                )),
                                          ),
                                          const SizedBox(width: 30.0),
                                        ],
                                      ),
                                      /// ==========================
                                      /// Кнопка Назад Обьекты ======
                                      if (IntTest.indexScreens == 11)
                                        Row(
                                          children: [
                                            Container(
                                              width: 30.0,
                                              height: 30.0,
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(5.0),
                                                border: Border.all(color: ColorApp.myColorGrayBorder,width: 1),
                                                color: Colors.white,
                                                boxShadow: const [
                                                  BoxShadow(
                                                    color: ColorApp.myColorAvatar,
                                                    blurRadius: 5,
                                                  ),
                                                ],
                                              ),
                                              child: IconButton(
                                                  onPressed: () {
                                                    setState(() {
                                                      IntTest.indexScreens = 3;
                                                      pointsMapController.add(IntTest.indexScreens);
                                                    });
                                                  },
                                                  icon: const Icon(
                                                    Icons.arrow_back_ios_new_rounded,
                                                    color: Colors.black,size: 13.0,
                                                  )),
                                            ),
                                            const SizedBox(width: 30.0),
                                          ],
                                        ),
                                      /// =============================
                                      /// Кнопка Назад Сотрудники ==
                                      if (IntTest.indexScreens == 12)
                                        Row(
                                          children: [
                                            Container(
                                              width: 30.0,
                                              height: 30.0,
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(5.0),
                                                border: Border.all(color: ColorApp.myColorGrayBorder,width: 1),
                                                color: Colors.white,
                                                boxShadow: const [
                                                  BoxShadow(
                                                    color: ColorApp.myColorAvatar,
                                                    blurRadius: 5,
                                                  ),
                                                ],
                                              ),
                                              child: IconButton(
                                                  onPressed: () {
                                                    setState(() {
                                                      IntTest.indexScreens = 6;
                                                      pointsMapController.add(IntTest.indexScreens);
                                                    });
                                                  },
                                                  icon: const Icon(
                                                    Icons.arrow_back_ios_new_rounded,
                                                    color: Colors.black,size: 13.0,
                                                  )),
                                            ),
                                            const SizedBox(width: 30.0),
                                          ],
                                        ),
                                      /// ==========================
                                      ///Text
                                      Text(IntTest.myTitle,
                                          style: TextStyle(
                                              fontSize: size.width > 350
                                                  ? 25.0
                                                  : 18.0,
                                              fontWeight: size.width > 350
                                                  ? FontWeight.w700
                                                  : FontWeight.w500)),

                                      ///Иконки Обьекты
                                      if (IntTest.indexScreens == 3)
                                        Row(
                                          children: [
                                            const SizedBox(width: 10.0),

                                            ///Добавить Обьект
                                            IconButton(
                                                onPressed: () {
                                                  setState(() {
                                                    showDialog(
                                                        context: context,
                                                        builder: (context) =>
                                                            AlertDialog(
                                                              content:
                                                                  AddObject(),
                                                            ));
                                                  });
                                                },
                                                icon: const Icon(
                                                    Icons.add_box_rounded,
                                                    size: 25.0,
                                                    color: ColorApp
                                                        .myColorGreenAuth)),

                                            ///Поиск Обьекта
                                            IconButton(
                                                onPressed: () {
                                                  setState(() {
                                                    showDialog(
                                                        context: context,
                                                        builder: (context) =>
                                                            AlertDialog(
                                                              content:
                                                                  EditingObject(),
                                                            ));
                                                  });
                                                },
                                                icon: const Icon(Icons.search,
                                                    size: 25.0,
                                                    color:
                                                        ColorApp.myColorGray)),
                                          ],
                                        ),

                                      ///Иконки Компании
                                      if (IntTest.indexScreens == 4)
                                        Row(
                                          children: [
                                            const SizedBox(width: 10.0),

                                            ///Добавить Компанию
                                            IconButton(
                                                onPressed: () {
                                                  setState(() {
                                                    showDialog(
                                                        context: context,
                                                        builder: (context) =>
                                                            AlertDialog(
                                                              content:
                                                                  AddCompany(),
                                                            ));
                                                  });
                                                },
                                                icon: const Icon(
                                                    Icons.add_box_rounded,
                                                    size: 25.0,
                                                    color: ColorApp
                                                        .myColorGreenAuth)),
                                          ],
                                        ),

                                      ///Иконки Сотрудники
                                      if (IntTest.indexScreens == 6)
                                        Row(
                                          children: [
                                            const SizedBox(width: 10.0),

                                            ///Добавить Сотрудника
                                            IconButton(
                                                onPressed: () async {
                                                  // await getEmployeeJobTitle();
                                                  // await getPlot();
                                                  setState(() {
                                                    showDialog(
                                                        context: context,
                                                        builder: (context) =>
                                                            const AlertDialog(
                                                              content:
                                                                  AddEmployee(),
                                                            ));
                                                  });
                                                },
                                                icon: const Icon(
                                                    Icons.add_box_rounded,
                                                    size: 25.0,
                                                    color: ColorApp
                                                        .myColorGreenAuth)),

                                            ///Архивировать Сотрудника
                                            if (size.width > 500)
                                              IconButton(
                                                  onPressed: () {
                                                    archive =!archive;
                                                    pointsMapController.add(IntTest.indexScreens);
                                                    print(archive);
                                                    setState(() {});
                                                  },
                                                  icon: const Icon(
                                                      Icons.archive_outlined,
                                                      size: 25.0,
                                                      color: ColorApp
                                                          .myColorGray)),

                                            ///Поиск Сотрудника
                                            if (size.width > 500)
                                              Row(
                                                children: [
                                                  if (openListSearch == false)
                                                    IconButton(
                                                        onPressed: () {
                                                          openListSearch = true;
                                                          pointsMapController
                                                              .add(IntTest
                                                                  .indexScreens);
                                                        },
                                                        icon: const Icon(
                                                            Icons.search,
                                                            size: 25.0,
                                                            color: ColorApp
                                                                .myColorGray)),
                                                ],
                                              ),
                                            if (openListSearch)
                                              Row(
                                                children: [
                                                  const SizedBox(width: 10),
                                                  SizedBox(
                                                    width:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width *
                                                            0.3,
                                                    height: 40.0,
                                                    child: Form(
                                                      child: TextFormField(
                                                        cursorColor: ColorApp
                                                            .myColorGray,
                                                        // controller: email,
                                                        decoration:
                                                            InputDecoration(
                                                                contentPadding:
                                                                    const EdgeInsets
                                                                            .all(
                                                                        0.0),
                                                                prefixIcon:
                                                                    IconButton(
                                                                  onPressed:
                                                                      () {},
                                                                  icon: const Icon(
                                                                      Icons
                                                                          .search),
                                                                ),
                                                                suffixIcon:
                                                                    IconButton(
                                                                        onPressed:
                                                                            () {
                                                                          openListSearch =
                                                                              false;
                                                                          pointsMapController
                                                                              .add(IntTest.indexScreens);
                                                                        },
                                                                        icon: const Icon(
                                                                            Icons
                                                                                .close)),
                                                                border:
                                                                    const OutlineInputBorder(),
                                                                focusedBorder:
                                                                    const OutlineInputBorder(
                                                                  borderSide:
                                                                      BorderSide(
                                                                          color:
                                                                              ColorApp.myColorGreenAuth),
                                                                ),
                                                                labelText:
                                                                    'Поиск',
                                                                labelStyle: const TextStyle(
                                                                    color: ColorApp
                                                                        .myColorGray)),
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                          ],
                                        ),

                                      ///Иконки выбранного юзера
                                      if (IntTest.indexScreens == 12)
                                        Row(
                                          children: [
                                            const SizedBox(width: 10.0),

                                            /// Изменить
                                            IconButton(
                                                onPressed: () {
                                                  setState(() {
                                                    showDialog(
                                                        context: context,
                                                        builder: (context) =>
                                                            const AlertDialog(
                                                              content:
                                                                  EditingEmployee(),
                                                            ));
                                                  });
                                                },
                                                icon: const Icon(
                                                    Icons.edit_outlined,
                                                    color: ColorApp
                                                        .myColorGreenAuth)),
                                          ],
                                        ),
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
                                      SizedBox(
                                          width:
                                              size.width > 500 ? 40.0 : 10.0),

                                      ///Аватар Юзера
                                      if (state is UserGetState)
                                        CircularPercentIndicator(
                                          radius:
                                              size.width > 350 ? 33.0 : 23.0,
                                          lineWidth: 5.0,
                                          percent: 0.7,
                                          progressColor:
                                              ColorApp.myColorGreenAuth,
                                          backgroundColor:
                                              ColorApp.myColorAvatar,
                                          center: GestureDetector(
                                            onTap: () async {
                                              IntTest.indexScreens = 9;
                                              IntTest.myTitle = 'Мой профиль';
                                              setState(() {});
                                            },
                                            child: CircleAvatar(
                                              radius: size.width > 350
                                                  ? 29.0
                                                  : 20.0,
                                              backgroundColor:
                                                  Colors.transparent,
                                              backgroundImage: const AssetImage(
                                                  'assets/user.png'),
                                              foregroundImage: NetworkImage(
                                                  'http://${state.getUser[0]['photo']}'),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                )),
                          ),

                          /// Body
                          BlocBuilder<EmployeeBloc, EmployeeState>(
                            builder: (context, state) {
                              return StreamBuilder(
                                stream: pointsMapController.stream,
                                builder: (context, ind) => Expanded(
                                  flex: 9,
                                  child: _screens[IntTest.indexScreens],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    )
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
