import 'package:flutter/material.dart';
import '../home/overdue_maintenance/overdue_maintenance.dart';
import '../home/schedule_execution/schedule_execution.dart';
import '../home/top_breakdowns/top_breakdowns.dart';

///Главная

class DesktopVersion extends StatelessWidget {
  const DesktopVersion({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: const [
          ///Топ поломок
          TopBreakdowns(),
          SizedBox(height: 20.0),

          ///Выполнение графика
          ScheduleExecution(),
          SizedBox(height: 20.0),

          ///Просроченные ТО
          OverdueMaintenance(),
        ],
      ),
    );
  }
}
