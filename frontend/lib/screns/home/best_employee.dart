import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/user_bloc/user_bloc.dart';
import '../../helper/calendar/calendar.dart';
import '../../helper/class_colors.dart';
import '../employee/bloc/employee_bloc.dart';
import '../employee/view/employees_screen.dart';
import '../home_page/home_page.dart';
import '../responsive_screens/responsive.dart';

/// Топ сотрудников ==================================
class BestEmployee extends StatefulWidget {
  const BestEmployee({
    Key? key,
  }) : super(key: key);

  @override
  State<BestEmployee> createState() => _BestEmployeeState();
}

class _BestEmployeeState extends State<BestEmployee> {

  @override
  void initState() {
    getListEmployee();
    EmployeeBloc().add(EmployeeGetUserEvent());
    // TODO: implement initState
    super.initState();
  }

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
                'Топ сотрудников',
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
                'Объект',
                style: TextStyle(color: Colors.black),
              ),
              Text(
                'Фамилия',
                style: TextStyle(color: Colors.black),
              ),
              Text(
                'Должность',
                style: TextStyle(color: Colors.black),
              ),
            ],
          ),
          Divider(color: Colors.grey.shade300, thickness: 1),
          const SizedBox(height: 10.0),
          Expanded(
            child: ListView.builder(
              itemCount: getEmployee.length,
              itemBuilder: (context, index) {
                final bestEmployeeList = getEmployee[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                    height: 40,
                    decoration: BoxDecoration(
                      color: ColorApp.myColorGreen,
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children:  [
                        ///Участок
                        if (size.width > 550) Expanded(
                            child: Row(
                              children: [
                                const SizedBox(width: 20.0),
                                bestEmployeeList['division_id'] == null
                                    ? const Text('')
                                    : Text(bestEmployeeList['division_id']['title'].toString(),
                                    style: TextStyle(fontSize: size.width > 450 ? 14 : 12)),
                              ],
                            )),
                        Expanded(
                            child:
                            getEmployee[index]['name'] == null
                                ? const Text('')
                                : Text(bestEmployeeList['name'],
                                style: TextStyle(fontSize: size.width > 450 ? 14 : 12))),
                        ///Должность
                        if (size.width > 600) Expanded(
                            child: Text(bestEmployeeList['role_id']['name'])
                        ),
                        // Text('09.10.2022'),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    )
        : BlocBuilder<EmployeeBloc, EmployeeState>(
  builder: (context, state) {
    return StreamBuilder(
      stream: myStream.stream,
      builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
        return Padding(
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
                      'Топ сотрудников',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: size.width > 430 ? 20 : 15),
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
                    if (size.width > 430)
                      const Text(
                        'Фамилия',
                        style: TextStyle(color: Colors.black),
                      ),
                    const Text(
                      'Должность',
                      style: TextStyle(color: Colors.black),
                    ),
                    // const Text(
                    //   'Назначенная дата',
                    //   style: TextStyle(color: Colors.black),
                    // ),
                  ],
                ),
                Divider(color: Colors.grey.shade300, thickness: 1),
                const SizedBox(height: 10.0),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.3,
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
                            if (size.width > 430)
                              const Text('В.Р. Никифоров'),
                            const Text('Механик'),
                            // const Text('09.10.2022'),
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
      },
    );
  },
);
  }
}
/// ==================================================
