import 'package:els/foreman/companies_foreman/companies_screen_foreman.dart';
import 'package:els/foreman/schedule_foreman/schedule_page_foreman.dart';
import 'package:els/foreman/task_foreman/task_completed_foreman/task_page_completed_foreman.dart';
import 'package:els/foreman/task_foreman/task_completed_foreman/task_screen_completed_foreman.dart';
import 'package:els/foreman/task_foreman/task_page_foreman.dart';
import 'package:els/foreman/task_foreman/task_screen_foreman.dart';
import 'package:els/foreman/user_page_foreman.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/user_bloc/user_bloc.dart';
import '../helper/class_colors.dart';
import '../screns/companies/view/company_page.dart';
import '../screns/employee/view/employee_page.dart';
import '../screns/home_page/home_page.dart';
import '../screns/in_progress_works/in_progress_counts.dart';
import '../screns/in_progress_works/models/in_progress_work.dart';
import '../screns/in_progress_works/repository/in_progress_works_repository.dart';
import '../screns/report/report_screen.dart';
import '../screns/schedule/schedule_page.dart';
import '../screns/schedule/view/schedule_section.dart';
import '../screns/schedule/view/schedules_screen.dart';
import '../screns/submitted_works/repository/submitted_works_repository.dart';
import '../screns/submitted_works/view/submitted_works_screen.dart';
import '../screns/task/view/task_page.dart';
import '../screns/user/user_page.dart';
import 'companies_foreman/companies_arhive_foreman/companies_screen_archive_foreman.dart';
import 'companies_foreman/companies_arhive_foreman/company_page_archive_foreman.dart';
import 'companies_foreman/company_page_foreman.dart';
import 'drawer_foreman.dart';
import 'employee_foreman/employee_arhive_foreman/employee_archive_page_foreman.dart';
import 'employee_foreman/employee_arhive_foreman/employees_archive_screen_foreman.dart';
import 'employee_foreman/employee_page_foreman.dart';
import 'employee_foreman/employees_screen_foreman.dart';
import 'object_foreman/arhive_object_foreman/object_page_archive_foreman.dart';
import 'object_foreman/arhive_object_foreman/object_screen_archive_foreman.dart';
import 'object_foreman/object_screen_foreman.dart';
import 'object_foreman/object_page_foreman.dart';

/// Домашняя Прораб

class HomeForeman extends StatefulWidget {
  const HomeForeman({Key? key}) : super(key: key);

  @override
  State<HomeForeman> createState() => _HomeForemanState();
}

class _HomeForemanState extends State<HomeForeman> {
  ///Список Страниц
  final List<Widget> _screensForeman = [

    ///Обьекты 0
    const ObjectScreenForeman(),

    ///Графики 1
    const ScheduleSection(
      role: ScheduleRole.foreman,
      drawer: DrawerForeman(),
    ),

    ///Заявки 2
    const TaskScreenForeman(),

    ///Компании 3
    const CompaniesScreenForeman(),

    ///Отчеты 4
    const ReportScreen(drawer: DrawerForeman()),

    ///Сотрудники 5
    const EmployeesScreenForeman(),

    ///Окно Юзера 6
    const MyProfile(drawer: DrawerForeman()),

    ///Окно выбранной Компании 7
    const CompanyPage(),

    ///Окно выбранного Обьекта 8
    const ObjectPageForeman(),

    ///Окно выбранного Юзера 9
    const OpenViewEmployee(),

    ///  10
    const SchedulePage(),

    /// Окно выбранной задачи 11
    const TaskPage(),

    /// Окно архив объекты 12
    const ObjectScreenArchiveForeman(),

    /// Окно архив выбранного объекта 13
    const ObjectPageArchiveForeman(),

    /// Окно выбранного графика 14
    const SchedulePageForeman(),

    /// Окно выбранной задачи 15
    const TaskPageForeman(),

    /// Окно выполненых задачи 16
    const TaskScreenCompletedForeman(),

    /// Окно выбранной выполненой задачи 17
    const TaskPageCompletedForeman(),

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

    /// Лента сданных работ 25
    const SubmittedWorksScreen(drawer: DrawerForeman()),
  ];

  @override
  void initState() {
    getListObjectForeman();
    // Список объектов для графиков больше не тянем: новый раздел «Графики»
    // грузит себя сам, а этот вызов кормил только экран подрядчика.
    getListTaskForeman();
    getListCompanyForeman();
    getListEmployeeForeman();
    // Счётчики нужны кнопке меню, а не экрану: числа видны с любого раздела,
    // поэтому и тянем их один раз при входе в оболочку. Ошибку глотаем молча
    // — из-за неё нельзя не пустить прораба в систему.
    const SubmittedWorksRepository().unreviewedCount().catchError((_) => 0);
    _loadInProgressCounts();
    // TODO: implement initState
    super.initState();
  }

  /// Сколько работ идёт прямо сейчас — для таблеток в боковом меню.
  ///
  /// Раньше эти числа появлялись только после захода в «Сданные работы»:
  /// класть их умел лишь блок раздела. Прораб открывал бургер и видел одну
  /// серую таблетку, хотя работы шли.
  ///
  /// Пишем только в пустое значение: если прораб успел открыть раздел раньше,
  /// чем вернулся этот запрос, свежие числа из блока затирать нечем.
  Future<void> _loadInProgressCounts() async {
    try {
      final InProgressWorks works =
          await const InProgressWorksRepository().fetch();
      if (inProgressCounts.value != InProgressCounts.none) return;
      inProgressCounts.value =
          InProgressCounts(total: works.total, problems: works.problems);
    } catch (_) {
      // Пустое меню без чисел лучше, чем не пустить прораба в систему.
    }
  }

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
                        child: DrawerForeman(),
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
                              child: _screensForeman[IntTest.indexScreensForeman],
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
