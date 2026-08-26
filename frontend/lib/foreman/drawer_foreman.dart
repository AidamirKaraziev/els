import 'package:els/foreman/task_foreman/task_screen_foreman.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../screns/home_page/home_page.dart';
import '../helper/button/side_menu_button.dart';
import '../helper/class_colors.dart';
import '../helper/session.dart';
import '../screns/in_progress_works/widgets/work_counts_chips.dart';
import '../screns/submitted_works/repository/submitted_works_repository.dart';
import 'companies_foreman/companies_screen_foreman.dart';
import 'employee_foreman/employees_screen_foreman.dart';
import 'object_foreman/object_screen_foreman.dart';

/// MyDrawer ==============================================
class DrawerForeman extends StatefulWidget {
  const DrawerForeman({Key? key}) : super(key: key);

  @override
  State<DrawerForeman> createState() => _DrawerForemanState();
}

class _DrawerForemanState extends State<DrawerForeman> {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 30.0),
              /// Единая лифтовая служба
              const Text(
                'Единая лифтовая служба',
                style: TextStyle(
                  fontSize: 19.0,
                  fontWeight: FontWeight.w700,
                  color: ColorApp.myColorGreenAuth,
                ),
              ),
              const SizedBox(height: 30.0),

              ///Обьекты
              MenuButton(
                myIcons: Icons.radio_button_checked_outlined,
                title: 'Обьекты',
                press: () async {
                  await getListObjectForeman();

                  IntTest.indexScreensForeman = 0;
                  IntTest.myTitle = 'Обьекты';
                  myStream.add(IntTest.indexScreensForeman);
                  setState(() {});
                },
                colorButton: IntTest.indexScreensForeman == 0
                    ? ColorApp.myColorGreenLine
                    : Colors.transparent,
              ),

              ///График
              MenuButton(
                myIcons: Icons.calendar_today,
                title: 'График',
                press: () {
                  IntTest.indexScreensForeman = 1;
                  IntTest.myTitle = 'График';
                  myStream.add(IntTest.indexScreensForeman);
                  setState(() {});
                },
                colorButton: IntTest.indexScreensForeman == 1
                    ? ColorApp.myColorGreenLine
                    : Colors.transparent,
              ),

              ///Задачи
              Stack(
                children: [
                  MenuButton(
                    myIcons: Icons.list_alt,
                    title: 'Задачи',
                    press: () async {
                      getListTaskForeman();
                      IntTest.indexScreensForeman = 2;
                      IntTest.myTitle = 'Задачи';
                      setState(() {});
                      myStream.add(IntTest.indexScreensForeman);
                    },
                    colorButton: IntTest.indexScreensForeman == 2
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
              ),

              ///Компании
              MenuButton(
                myIcons: Icons.domain,
                title: 'Компании',
                press: () async {
                  await getListCompanyForeman();
                  myStream.add(IntTest.indexScreensForeman);
                  IntTest.indexScreensForeman = 3;
                  IntTest.myTitle = 'Компании';
                  setState(() {});
                },
                colorButton: IntTest.indexScreensForeman == 3
                    ? ColorApp.myColorGreenLine
                    : Colors.transparent,
              ),

              ///Отчеты
              // Бейджа у отчётов нет намеренно: подрядчик рисовал здесь
              // константу `numberReports = 3`, которая ничего не считала и
              // никогда не менялась. Считать тут пока нечего — раздел
              // показывает историю за период, а не входящие события.
              MenuButton(
                myIcons: Icons.bar_chart_outlined,
                title: 'Отчеты',
                press: () {
                  IntTest.indexScreensForeman = 4;
                  IntTest.myTitle = 'Отчеты';
                  myStream.add(IntTest.indexScreensForeman);
                  setState(() {});
                },
                colorButton: IntTest.indexScreensForeman == 4
                    ? ColorApp.myColorGreenLine
                    : Colors.transparent,
              ),

              ///Сданные работы
              MenuButton(
                myIcons: Icons.fact_check_outlined,
                title: 'Сданные работы',
                press: () {
                  // Число могло устареть, пока прораб сидел в другом
                  // разделе: механик закрывает заявки не спрашивая.
                  const SubmittedWorksRepository()
                      .unreviewedCount()
                      .catchError((_) => 0);
                  IntTest.indexScreensForeman = 25;
                  IntTest.myTitle = 'Сданные работы';
                  myStream.add(IntTest.indexScreensForeman);
                  setState(() {});
                },
                colorButton: IntTest.indexScreensForeman == 25
                    ? ColorApp.myColorGreenLine
                    : Colors.transparent,
                // Числа живут в `ValueNotifier`, а не в глобальной `var`, как
                // было у подрядчика с `numberReports`: то было зашито
                // константой и никогда не менялось, а эти обновляет сам экран
                // сданных работ — лента после отметки, раздел текущих работ
                // после опроса. Первое значение кладёт оболочка `HomeForeman`
                // при входе, чтобы числа были видны сразу.
                trailing: const WorkCountsChips(),
              ),

              ///Сотрудники
              MenuButton(
                myIcons: Icons.people_outlined,
                title: 'Сотрудники',
                press: () async {
                  IntTest.indexScreensForeman = 5;
                  await getListEmployeeForeman();
                  myStream.add(IntTest.indexScreensForeman);
                  setState(() {});
                },
                colorButton: IntTest.indexScreensForeman == 5
                    ? ColorApp.myColorGreenLine
                    : Colors.transparent,
              ),

              /// Выход
              MenuButton(
                myIcons: Icons.logout,
                title: 'Выйти',
                press: () => signOut(),
                colorButton: Colors.transparent,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
/// ========================================================