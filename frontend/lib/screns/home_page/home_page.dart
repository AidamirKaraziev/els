import 'dart:async';
import 'package:els/screns/companies/view/companies_screen.dart';
import 'package:els/screns/companies/view/company_page.dart';
import 'package:els/screns/home/home_screen.dart';
import 'package:els/screns/object/view/object_screen.dart';
import 'package:els/screns/report/report_screen.dart';
import 'package:els/screns/schedule/bloc/schedules_bloc.dart';
import 'package:els/screns/schedule/models/schedule_filters.dart';
import 'package:els/screns/schedule/templates/repository/api_templates_repository.dart';
import 'package:els/screns/schedule/view/schedule_section.dart';
import 'package:els/screns/schedule/view/route_schedule_object_opener.dart';
import 'package:els/screns/schedule/view/schedules_screen.dart';
import 'package:els/screns/user/user_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/company_bloc/company_bloc.dart';
import '../../helper/class_colors.dart';
import '../../navigation/app_router.dart';
import '../../navigation/app_section.dart';
import '../../navigation/section_index.dart';
import '../../navigation/shell_drawer.dart';
import '../companies/view/companies_screen_archive.dart';
import '../companies/view/company_page_archive.dart';
import '../employee/view/employee_archive_page.dart';
import '../employee/view/employees_archive_screen.dart';
import '../employee/view/employees_screen.dart';
import '../employee/view/employee_page.dart';
import '../object/view/object_page.dart';
import '../object/view/object_page_archive.dart';
import '../object/view/object_screen_archive.dart';
import '../submitted_works/repository/submitted_works_repository.dart';
import '../works/repository/api_works_repository.dart';
import '../works/view/works_screen.dart';

///Главная User — оболочка админа.
///
/// Раздел выбирается маршрутом ([appRouter]), экран внутри раздела — по
/// индексу подрядчика (`IntTest.indexScreens` + `myStream`), пока детальные
/// экраны не переведены (S08). Таблица соответствия — [SectionIndex.admin].

///Это временно ====================================================
StreamController myStream = StreamController.broadcast();
/// ================================================================

///Это временно ====================================================
StreamController myStreamListPlanetTO = StreamController.broadcast();
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
  static const SectionIndex _index = SectionIndex.admin;

  StreamSubscription<dynamic>? _screens$;

  @override
  void initState() {
    super.initState();
    // Внутренний переход (карточка объекта, архив) приходит по потоку:
    // перерисовываемся и сообщаем маршрутизатору раздел, чтобы адрес и
    // подсветка в бургере не отставали. Профиль — ничейный: раздел не трогаем.
    _screens$ = myStream.stream.listen((_) {
      if (!mounted) return;
      final AppSection? owner = _index.sectionOf(IntTest.indexScreens);
      if (owner != null) appRouter.showSection(owner);
      setState(() {});
    });
    appRouter.addListener(_onRoute);
    _enter(appRouter.section);
    // Таблетка у «Работ» видна с любого раздела — число берём при входе, не
    // дожидаясь, пока человек откроет ленту. Ошибку глотаем: из-за неё нельзя
    // не пустить в систему.
    const SubmittedWorksRepository().unreviewedCount().catchError((_) => 0);
  }

  @override
  void dispose() {
    _screens$?.cancel();
    appRouter.removeListener(_onRoute);
    _scheduleBloc?.close();
    super.dispose();
  }

  int _handledTap = appRouter.tapSerial;

  /// Маршрут сменился. Тап по бургеру всегда ведёт к корневому экрану
  /// раздела — так из карточки возвращаются к списку. Адрес из браузера
  /// («назад», набранный руками) меняет экран, только если раздел другой:
  /// свой раздел маршрутизатор узнаёт от нас же и перерисовки не стоит.
  void _onRoute() {
    if (!mounted) return;
    final AppSection section = appRouter.section;
    final bool tapped = appRouter.tapSerial != _handledTap;
    _handledTap = appRouter.tapSerial;
    if (!tapped && _index.sectionOf(IntTest.indexScreens) == section) return;
    _enter(section);
  }

  /// Открыть раздел с корневого экрана — то, что делали пункты `MyDrawer`.
  void _enter(AppSection section) {
    switch (section) {
      case AppSection.objects:
        getListObjectArchive();
        getAllListOfObjects();
        break;
      case AppSection.works:
        // Число могло устареть, пока сидели в другом разделе: механик
        // закрывает заявки не спрашивая.
        const SubmittedWorksRepository().unreviewedCount().catchError((_) => 0);
        break;
      case AppSection.companies:
        final CompanyState state = context.read<CompanyBloc>().state;
        if (state is CompanyGetState) {
          getCompany = state.listGetCompany;
          dataCompany = state.listGetCompany;
        }
        break;
      default:
        break;
    }
    _show(_index.rootOf(section), title: section.title);
  }

  /// Показать экран по индексу — тем же путём, каким ходят экраны подрядчика.
  void _show(int index, {String? title}) {
    if (title != null) IntTest.myTitle = title;
    IntTest.indexScreens = index;
    myStream.add(index);
  }

  /// Блок ленты «Графиков». Живёт у оболочки, а не внутри раздела: разделы
  /// стоят в дереве одной позицией, и уход в «Заявки» выносит «Графики»
  /// оттуда целиком. Блок внутри раздела умирал бы вместе с ними, и человек,
  /// вернувшийся из другого раздела, получал бы год и отбор заново.
  SchedulesBloc? _scheduleBloc;

  /// Счётчик заходов с главной. Он же ключ раздела: два клика подряд по
  /// одному участку обязаны дать чистую ленту, а не то, что человек успел
  /// нафильтровать внутри между ними.
  int _scheduleRequests = 0;

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
      // Кнопка «Шаблоны ТО» в шапке: без репозитория раздел её не рисует.
      templatesRepository: ApiTemplatesRepository(),
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

    ///Работы 2 — единая лента заявок и актов
    WorksScreen(
      repository: ApiWorksRepository(),
      drawer: const ShellDrawer(),
      canCreateWork: true,
    ),

    ///Обьекты 3
    const ObjectScreen(),

    ///Компании 4
    const CompaniesScreen(),

    ///Отчеты 5
    const ReportScreen(),

    ///Сотрудники 6
     const EmployeesScreen(),

    ///Задачи 7 — экран снят, слот держит нумерацию
    const SizedBox.shrink(),

    ///Охрана Труда — снят, слота нет: дальше номера идут без пропуска
    // const WorksScreen(),

    ///Окно Юзера 8
    const MyProfile(),

    ///Окно выбранной Компании 9
    const CompanyPage(),

    ///Окно выбранного Обьекта 10
    const ObjectPage(),

    ///Окно выбранного Юзера 11
    const OpenViewEmployee(),

    ///  12 — экран графика подрядчика снят, слот держит нумерацию
    const SizedBox.shrink(),
    /// Окно выбранной задачи 13 — экран снят, слот держит нумерацию
    const SizedBox.shrink(),
    ///Окно Test 14 — экран снят, слот держит нумерацию
    const SizedBox.shrink(),
    ///Окно Архив сотрудники 15
     EmployeesArchiveScreen(),
    ///Окно Архив выбранного сотрудника 16
    const OpenViewEmployeeArchive(),
    ///Окно Архив Компании 17
    const CompaniesScreenArchive(),
    ///Окно Архив выбранной компании 18
    const CompanyPageArchive(),
    ///Окно Архив списка объектов 19
    const ObjectScreenArchive(),
    ///Окно Архив выбранного объекта 20
    const ObjectPageArchive(),
    ///Окно Архив Задач 21 — экран снят, слот держит нумерацию
    const SizedBox.shrink(),
    ///Окно Архив выбранной задачи 22 — экран снят, слот держит нумерацию
    const SizedBox.shrink(),
  ];

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
          Expanded(flex: 8, child: _screenAt(IntTest.indexScreens)),
        ],
      ),
    );
  }
}
