import 'dart:async';
import 'package:els/screns/companies/view/companies_screen.dart';
import 'package:els/screns/companies/view/company_page.dart';
import 'package:els/screns/home/home_screen.dart';
import 'package:els/screns/object/view/object_screen.dart';
import 'package:els/screns/report/report_screen.dart';
import 'package:els/screns/schedule/bloc/schedules_bloc.dart';
import 'package:els/screns/schedule/models/schedule_filters.dart';
import 'package:els/screns/schedule/view/schedule_section.dart';
import 'package:els/screns/schedule/view/route_schedule_object_opener.dart';
import 'package:els/screns/schedule/view/schedules_screen.dart';
import 'package:els/screns/task/view/task_screen.dart';
import 'package:els/screns/user/user_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../helper/class_colors.dart';
import '../../helper/my_drawer/my_drawer.dart';
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
import '../task/view/archive/task_page_archive.dart';
import '../task/view/archive/task_screen_archive.dart';
import '../task/view/task_page.dart';

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
  /// Блок ленты «Графиков». Живёт у оболочки, а не внутри раздела: разделы
  /// стоят в дереве одной позицией, и уход в «Заявки» выносит «Графики»
  /// оттуда целиком. Блок внутри раздела умирал бы вместе с ними, и человек,
  /// вернувшийся из другого раздела, получал бы год и отбор заново.
  SchedulesBloc? _scheduleBloc;

  /// Счётчик заходов с главной. Он же ключ раздела: два клика подряд по
  /// одному участку обязаны дать чистую ленту, а не то, что человек успел
  /// нафильтровать внутри между ними.
  int _scheduleRequests = 0;

  @override
  void dispose() {
    _scheduleBloc?.close();
    super.dispose();
  }

  /// Экран по индексу оболочки.
  ///
  /// «Графики» — единственный, кого просят открыть с готовым отбором: с
  /// главной по клику на участке. Заявка забирается один раз, поэтому вход
  /// из меню по-прежнему показывает все объекты.
  Widget _screenAt(int index) {
    if (index != 1) return _screens[index];

    final ScheduleFilters? requested = ScheduleSectionRequest.take();
    if (requested != null) {
      // Заход с главной начинает ленту с нуля: прежний отбор человек не
      // просил, он нажал на участок. Старый блок закрываем — второго
      // владельца у него нет.
      _scheduleBloc?.close();
      _scheduleBloc = SchedulesBloc(filters: requested);
      ++_scheduleRequests;
    }

    _scheduleBloc ??= SchedulesBloc();

    return ScheduleSection(
      role: ScheduleRole.admin,
      bloc: _scheduleBloc,
      // Клик в строку открывает экран «График объекта» маршрутом поверх
      // оболочки. Экран подрядчика из этого пути ушёл.
      opener: const RouteScheduleObjectOpener.admin(),
      // Ключ меняется только на заходе с главной: иначе Flutter переиспользовал
      // бы состояние прежней ленты, и новый фильтр приехал бы к старым строкам.
      key: ValueKey<int>(_scheduleRequests),
    );
  }

  ///Список Страниц
  final List<Widget> _screens = [
    ///Главная 0
    const HomeScreen(),

    ///Графики 1 — заглушка: раздел строится в `_scheduleSection`.
    const SizedBox.shrink(),

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

    ///  13 — экран графика подрядчика снят, слот держит нумерацию
    const SizedBox.shrink(),
    /// Окно выбранной задачи 14
    const TaskPage(),
    ///Окно Test 15 — экран снят, слот держит нумерацию
    const SizedBox.shrink(),
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
                              child: _screenAt(IntTest.indexScreens),
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
