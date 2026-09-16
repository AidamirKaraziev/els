import 'dart:async';
import 'package:els/screns/schedule/bloc/schedules_bloc.dart';
import 'package:els/foreman/companies_foreman/companies_screen_foreman.dart';
import 'package:els/foreman/user_page_foreman.dart';
import 'package:flutter/material.dart';
import '../helper/class_colors.dart';
import '../navigation/app_router.dart';
import '../navigation/app_section.dart';
import '../navigation/section_index.dart';
import '../navigation/shell_drawer.dart';
import '../screns/home/home_screen.dart';
import '../screns/companies/view/company_page.dart';
import '../screns/employee/view/employee_page.dart';
import '../screns/home_page/home_page.dart';
import '../screns/report/report_screen.dart';
import '../screns/schedule/view/schedule_section.dart';
import '../screns/schedule/view/route_schedule_object_opener.dart';
import '../screns/schedule/view/schedules_screen.dart';
import '../screns/submitted_works/repository/submitted_works_repository.dart';
import '../screns/works/repository/api_works_repository.dart';
import '../screns/works/view/works_screen.dart';
import '../screns/user/user_page.dart';
import 'companies_foreman/companies_arhive_foreman/companies_screen_archive_foreman.dart';
import 'companies_foreman/companies_arhive_foreman/company_page_archive_foreman.dart';
import 'companies_foreman/company_page_foreman.dart';
import 'employee_foreman/employee_arhive_foreman/employee_archive_page_foreman.dart';
import 'employee_foreman/employee_arhive_foreman/employees_archive_screen_foreman.dart';
import 'employee_foreman/employee_page_foreman.dart';
import 'employee_foreman/employees_screen_foreman.dart';
import 'object_foreman/arhive_object_foreman/object_page_archive_foreman.dart';
import 'object_foreman/arhive_object_foreman/object_screen_archive_foreman.dart';
import 'object_foreman/object_screen_foreman.dart';
import 'object_foreman/object_page_foreman.dart';

/// Домашняя Прораб — оболочка прораба.
///
/// Раздел выбирается маршрутом ([appRouter]), экран внутри раздела — по
/// индексу подрядчика (`IntTest.indexScreensForeman` + `myStream`), пока
/// детальные экраны не переведены (S08). Таблица — [SectionIndex.foreman].

class HomeForeman extends StatefulWidget {
  const HomeForeman({Key? key}) : super(key: key);

  @override
  State<HomeForeman> createState() => _HomeForemanState();
}

class _HomeForemanState extends State<HomeForeman> {
  static const SectionIndex _index = SectionIndex.foreman;

  StreamSubscription<dynamic>? _screens$;
  int _handledTap = appRouter.tapSerial;

  /// Маршрут сменился. Тап по бургеру всегда ведёт к корневому экрану
  /// раздела; адрес из браузера — только если раздел другой (см. `HomePage`).
  void _onRoute() {
    if (!mounted) return;
    final AppSection section = appRouter.section;
    final bool tapped = appRouter.tapSerial != _handledTap;
    _handledTap = appRouter.tapSerial;
    if (!tapped && _index.sectionOf(IntTest.indexScreensForeman) == section) {
      return;
    }
    _enter(section);
  }

  /// Открыть раздел с корневого экрана — то, что делали пункты `DrawerForeman`.
  void _enter(AppSection section) {
    switch (section) {
      case AppSection.objects:
        getListObjectForeman();
        break;
      case AppSection.works:
        // Число могло устареть, пока прораб сидел в другом разделе: механик
        // закрывает заявки не спрашивая.
        const SubmittedWorksRepository().unreviewedCount().catchError((_) => 0);
        break;
      case AppSection.companies:
        getListCompanyForeman();
        break;
      case AppSection.employees:
        getListEmployeeForeman();
        break;
      default:
        break;
    }
    _show(_index.rootOf(section), title: section.title);
  }

  /// Показать экран по индексу — тем же путём, каким ходят экраны подрядчика.
  void _show(int index, {String? title}) {
    if (title != null) IntTest.myTitle = title;
    IntTest.indexScreensForeman = index;
    myStream.add(index);
  }

  /// Блок ленты «Графиков». Живёт у оболочки по той же причине, что и у
  /// админа (`home_page.dart`): разделы стоят в дереве одной позицией, и уход
  /// в «Заявки» уносит раздел вместе с его блоком. Прораб, вернувшийся в
  /// «Графики», должен увидеть тот же год и тот же отбор, что оставил.
  SchedulesBloc? _scheduleBloc;

  @override
  void dispose() {
    _screens$?.cancel();
    appRouter.removeListener(_onRoute);
    _scheduleBloc?.close();
    super.dispose();
  }

  /// Экран по индексу оболочки.
  Widget _screenAt(int index) {
    if (index != 1) return _screensForeman[index];

    _scheduleBloc ??= SchedulesBloc();
    return ScheduleSection(
      role: ScheduleRole.foreman,
      bloc: _scheduleBloc,
      // Клик в строку открывает тот же экран «График объекта», что и у
      // админа, — маршрутом поверх оболочки, но глазами прораба.
      opener: const RouteScheduleObjectOpener.foreman(),
    );
  }

  ///Список Страниц
  final List<Widget> _screensForeman = [

    ///Обьекты 0
    const ObjectScreenForeman(),

    ///Графики 1 — заглушка: раздел строится в `_scheduleSection`.
    const SizedBox.shrink(),

    ///Работы 2 — единая лента заявок и актов
    WorksScreen(
      repository: ApiWorksRepository(),
      drawer: const ShellDrawer(),
      canCreateWork: true,
    ),

    ///Компании 3
    const CompaniesScreenForeman(),

    ///Отчеты 4
    const ReportScreen(),

    ///Сотрудники 5
    const EmployeesScreenForeman(),

    ///Окно Юзера 6
    const MyProfile(),

    ///Окно выбранной Компании 7
    const CompanyPage(),

    ///Окно выбранного Обьекта 8
    const ObjectPageForeman(),

    ///Окно выбранного Юзера 9
    const OpenViewEmployee(),

    ///  10 — экран графика подрядчика снят, слот держит нумерацию
    const SizedBox.shrink(),

    /// Окно выбранной задачи 11 — экран снят, слот держит нумерацию
    const SizedBox.shrink(),

    /// Окно архив объекты 12
    const ObjectScreenArchiveForeman(),

    /// Окно архив выбранного объекта 13
    const ObjectPageArchiveForeman(),

    /// Окно выбранного графика 14 — экран подрядчика снят, слот держит нумерацию
    const SizedBox.shrink(),

    /// Окно выбранной задачи 15 — экран снят, слот держит нумерацию
    const SizedBox.shrink(),

    /// Окно выполненых задачи 16 — экран снят, слот держит нумерацию
    const SizedBox.shrink(),

    /// Окно выбранной выполненой задачи 17 — экран снят, слот держит нумерацию
    const SizedBox.shrink(),

    /// Окно выбранной компании 18
    const CompanyPageForeman(),

    /// Окно архив компаний 19
    const CompaniesScreenArchiveForeman(),

    /// Окно архив выбранной компании 20
    const CompanyPageArchiveForeman(),

    /// Окно выбранного сотрудника 21
    const OpenViewEmployeeForeman(),

    /// Окно архив сотрудники 22
    const EmployeesArchiveScreenForeman(),

    /// Окно выбранного сотрудника архив 23
    const OpenViewEmployeeArchiveForeman(),

    /// Окно User 24
    const OpenViewUserForeman(),

    /// Лента сданных работ 25 — экран снят, слот держит нумерацию
    const SizedBox.shrink(),

    /// Главная 26 — до S06 админский экран как есть: у прораба своей нет
    const HomeScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _screens$ = myStream.stream.listen((_) {
      if (!mounted) return;
      final AppSection? owner = _index.sectionOf(IntTest.indexScreensForeman);
      if (owner != null) appRouter.showSection(owner);
      setState(() {});
    });
    appRouter.addListener(_onRoute);
    _enter(appRouter.section);

    getListObjectForeman();
    // Список объектов для графиков больше не тянем: новый раздел «Графики»
    // грузит себя сам, а этот вызов кормил только экран подрядчика.
    getListCompanyForeman();
    getListEmployeeForeman();
    // Таблетка у «Работ» видна с любого раздела — число берём при входе, не
    // дожидаясь, пока прораб откроет ленту. Ошибку глотаем: из-за неё нельзя
    // не пустить в систему.
    const SubmittedWorksRepository().unreviewedCount().catchError((_) => 0);
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return Scaffold(
      body: Row(
        children: <Widget>[
          ///Боковое меню
          if (size.width > 1350)
            const Expanded(flex: 2, child: ShellDrawer()),

          /// Body
          Expanded(flex: 8, child: _screenAt(IntTest.indexScreensForeman)),
        ],
      ),
    );
  }
}
