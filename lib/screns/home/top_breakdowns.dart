import 'package:flutter/material.dart';
import '../../helper/calendar/calendar.dart';
import '../../helper/class_colors.dart';
import '../responsive_screens/responsive.dart';

/// Топ поломок ============================================

class TopBreakdowns extends StatefulWidget {
  const TopBreakdowns({Key? key}) : super(key: key);

  @override
  State<TopBreakdowns> createState() => _TopBreakdownsState();
}

class _TopBreakdownsState extends State<TopBreakdowns> {

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
                      'Топ поломок',
                      style:
                          TextStyle(fontWeight: FontWeight.w700, fontSize: 21),
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
                      'Номер',
                      style: TextStyle(color: Colors.black),
                    ),
                    Text(
                      'Клиент',
                      style: TextStyle(color: Colors.black),
                    ),
                    Text(
                      'Ответственный',
                      style: TextStyle(color: Colors.black),
                    ),
                    Text(
                      'За месяц',
                      style: TextStyle(color: Colors.black),
                    ),
                  ],
                ),
                Divider(color: Colors.grey.shade300, thickness: 1),
                const SizedBox(height: 20.0),
                Expanded(
                  child: ListView.builder(
                    itemCount: 5,
                    itemBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 40,
                              decoration: BoxDecoration(
                                color: ColorApp.myColorTransparent,
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: const [
                                    Text('№12'),
                                    Text('УК “Престиж”'),
                                    Text('В.Р. Никифоров'),
                                    SizedBox(
                                      width: 30.0,
                                    )
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10.0),
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10.0),
                                color: ColorApp.myColorRed),
                            child: const Center(
                                child: Text(
                              '4',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 16),
                            )),
                          ),
                        ],
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
                        'Топ поломок',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: size.width > 430 ? 20 : 15),
                      ),
                      /// Календарь
                      const MyDataCalendar(),
                      // IconButton(onPressed: (){}, icon: const Icon(Icons.calendar_today)),
                    ],
                  ),
                  const SizedBox(height: 10.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Номер',
                        style: TextStyle(color: Colors.black),
                      ),
                      const Text(
                        'Клиент',
                        style: TextStyle(color: Colors.black),
                      ),
                      if (size.width > 430)
                        const Text(
                          'Ответственный',
                          style: TextStyle(color: Colors.black),
                        ),
                      const Text(
                        'За месяц',
                        style: TextStyle(color: Colors.black),
                      ),
                    ],
                  ),
                  Divider(color: Colors.grey.shade300, thickness: 1),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.3,
                    child: ListView.builder(
                      itemCount: 5,
                      itemBuilder: (context, index) => Padding(
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 40,
                                decoration: BoxDecoration(
                                  color: ColorApp.myColorTransparent,
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10.0),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('№12'),
                                      const Text('УК “Престиж”'),
                                      if (size.width > 430)
                                        const Text('В.Р. Никифоров'),
                                      const SizedBox(
                                        width: 30.0,
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10.0),
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10.0),
                                  color: ColorApp.myColorRed),
                              child: const Center(
                                  child: Text(
                                '4',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 16),
                              )),
                            ),
                          ],
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

/// ========================================================
