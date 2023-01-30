import 'package:flutter/material.dart';
import '../../helper/class_colors.dart';
import '../responsive_screens/responsive.dart';
import 'overdue_maintenance.dart';
import 'schedule_execution.dart';
import 'top_breakdowns.dart';

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
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return Container(
      color: ColorApp.myColorTransparent,
      child: !Responsive.isMobile(context)
          ? Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                      children: [
                        ///Топ поломок
                        const Expanded(
                          child: TopBreakdowns(),
                        ),
                        ///Правый блок
                        Expanded(
                          child: Column(
                            children: const [
                              ///Выполнение графика
                              Expanded(flex: 4, child: ScheduleExecution()),

                              ///Просроченные ТО
                              Expanded(
                                flex: 3,
                                child: OverdueMaintenance(),
                              ),
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
                children: const [
                  TopBreakdowns(),
                  SizedBox(height: 10.0),
                  ScheduleExecution(),
                  SizedBox(height: 10.0),
                  OverdueMaintenance(),
                ],
              ),
          ),
    );
  }
}
