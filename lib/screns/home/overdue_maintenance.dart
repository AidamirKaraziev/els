import 'package:flutter/material.dart';
import '../../helper/calendar/calendar.dart';
import '../../helper/class_colors.dart';
import '../responsive_screens/responsive.dart';

/// Просроченные ТО ==================================
class OverdueMaintenance extends StatelessWidget {
  const OverdueMaintenance({
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
                    'Просроченные ТО',
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
                    'Объект',
                    style: TextStyle(color: Colors.black),
                  ),
                  Text(
                    'Ответственный',
                    style: TextStyle(color: Colors.black),
                  ),
                  Text(
                    'Клиент',
                    style: TextStyle(color: Colors.black),
                  ),
                  Text(
                    'Назначенная дата',
                    style: TextStyle(color: Colors.black),
                  ),
                ],
              ),
              Divider(color: Colors.grey.shade300, thickness: 1),
              const SizedBox(height: 10.0),
              Expanded(
                child: ListView.builder(
                  itemCount: 5,
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.only(bottom: 10.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                      height: 40,
                      decoration: BoxDecoration(
                        color: ColorApp.myColorRed,
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Text('№13'),
                          Text('В.Р. Никифоров'),
                          Text('УК “Престиж”'),
                          Text('09.10.2022'),
                        ],
                      ),
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
                      'Просроченные ТО',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: size.width > 430 ? 20 : 15),
                    ),
                    /// Календарь
                    const MyDataCalendar(),
                  ],
                ),
                const SizedBox(height: 10.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Объект',
                      style: TextStyle(color: Colors.black),
                    ),
                    if(size.width > 430)
                    const Text(
                      'Ответственный',
                      style: TextStyle(color: Colors.black),
                    ),
                    const Text(
                      'Клиент',
                      style: TextStyle(color: Colors.black),
                    ),
                    const Text(
                      'Назначенная дата',
                      style: TextStyle(color: Colors.black),
                    ),
                  ],
                ),
                Divider(color: Colors.grey.shade300, thickness: 1),
                const SizedBox(height: 10.0),
                SizedBox(
                  height: MediaQuery.of(context).size.height*0.3,
                  child: ListView.builder(
                    itemCount: 5,
                    itemBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        height: 40,
                        decoration: BoxDecoration(
                          color: ColorApp.myColorRed,
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('№13'),
                            if(size.width > 430)
                            const Text('В.Р. Никифоров'),
                            const Text('УК “Престиж”'),
                            const Text('09.10.2022'),
                          ],
                        ),
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
/// ==================================================
