import 'package:flutter/material.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import '../../helper/calendar/calendar.dart';
import '../../helper/class_colors.dart';
import '../responsive_screens/responsive.dart';

/// Выполнение графика ==============================
class ScheduleExecution extends StatelessWidget {
  const ScheduleExecution({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {

    final Size size = MediaQuery.of(context).size;

    return !Responsive.isMobile(context)
        ? Container(
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15.0),
            color: Colors.white,
            boxShadow: const [
              BoxShadow(
                color: Colors.grey,
                blurRadius: 5,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    'Выполнение графика',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 21),
                  ),
                  /// Календарь
                  MyDataCalendar(),
                ],
              ),
              const SizedBox(height: 10.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text(
                    'Участок',
                    style: TextStyle(color: Colors.black),
                  ),
                  Text(
                    'Ответственный',
                    style: TextStyle(color: Colors.black),
                  ),
                  Text(
                    'Выполнение',
                    style: TextStyle(color: Colors.black),
                  ),
                ],
              ),
              Divider(color: Colors.grey.shade300, thickness: 1),
              Expanded(
                child: ListView.builder(
                  itemCount: 5,
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.only(bottom: 10.0),
                    child: LinearPercentIndicator(
                      padding: const EdgeInsets.symmetric(horizontal: 0.0),
                      center: Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 10.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Text('№1'),
                            Text('В.Р. Никифоров'),
                            Text(
                              '82 %',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      barRadius: const Radius.circular(20.0),
                      // animation: true,
                      // animationDuration: 1000,
                      lineHeight: 40.0,
                      percent: 0.82,
                      progressColor: ColorApp.myColorGreen,
                      backgroundColor: ColorApp.myColorTransparent,
                    ),
                  ),
                ),
              ),
            ],
          ),
        )
        : Padding(
          padding: const EdgeInsets.all(10.0),
          child: Container(
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15.0),
              color: Colors.white,
              boxShadow: const [
                BoxShadow(
                  color: Colors.grey,
                  blurRadius: 5,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Выполнение графика',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: size.width > 430 ? 20 : 15),
                    ),
                    /// Календарь
                    const MyDataCalendar(),
                  ],
                ),
                const SizedBox(height: 10.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      'Участок',
                      style: TextStyle(color: Colors.black),
                    ),
                    Text(
                      'Ответственный',
                      style: TextStyle(color: Colors.black),
                    ),
                    Text(
                      'Выполнение',
                      style: TextStyle(color: Colors.black),
                    ),
                  ],
                ),
                Divider(color: Colors.grey.shade300, thickness: 1),
                SizedBox(
                  height: MediaQuery.of(context).size.height*0.3,
                  child: ListView.builder(
                    itemCount: 5,
                    itemBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: LinearPercentIndicator(
                        padding: const EdgeInsets.symmetric(horizontal: 0.0),
                        center: Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 10.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Text('№1'),
                              Text('В.Р. Никифоров'),
                              Text(
                                '82 %',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        barRadius: const Radius.circular(20.0),
                        // animation: true,
                        // animationDuration: 1000,
                        lineHeight: 40.0,
                        percent: 0.82,
                        progressColor: ColorApp.myColorGreen,
                        backgroundColor: ColorApp.myColorTransparent,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
  }
}
/// =================================================
