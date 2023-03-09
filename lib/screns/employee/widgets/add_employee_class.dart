import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:toggle_switch/toggle_switch.dart';
import '../../../helper/class_colors.dart';
import '../../home_page/home_page.dart';
import 'package:http/http.dart' as http;

import '../bloc/employee_bloc.dart';

///Класс Сотрудники

/// Список сотрудников
Map listSelectedEmployee = {};

class CartInfoPeople extends StatefulWidget {
  CartInfoPeople({
    Key? key,
  }) : super(key: key);


  @override
  State<CartInfoPeople> createState() => _CartInfoPeopleState();
}

class _CartInfoPeopleState extends State<CartInfoPeople> {
  int isHover = -1;
  int pressHover = -1;
  bool isSortTest = false;

  ///Получение данных одного сотрудника ======
  getListEmployeesInfo(int userId) async {
    await Future(() async {
      final res = await http.get(
          Uri.parse("http://${IntTest.myIp}/api/v1/cp/universal-user/$userId/"),
          headers: {
            "Content-Type": "application/json; charset=utf-8",
            'Authorization': 'Bearer ${IntTest.token}',
          });
      var vova = jsonDecode(utf8.decode(res.bodyBytes));
      listSelectedEmployee = vova;
      print('Данные выбраного сотрудника ${listSelectedEmployee['data']}');
    });
  }

  /// ========================================

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return BlocBuilder<EmployeeBloc, EmployeeState>(builder: (context, state) {
      final getEmployee = state.listGetEmployee;
      return Column(
        children: [
          if (getEmployee.isNotEmpty)
            SizedBox(
              height: MediaQuery.of(context).size.height*0.745,
              child: ListView.builder(
                controller: ScrollController(),
                itemCount: getEmployee.length,
                itemBuilder: (context, index) {
                  return InkWell(
                    onTap: () async {
                      IntTest.pressHover = getEmployee[index]['id'];
                      await getListEmployeesInfo(IntTest.pressHover);
                      pointsMapController.add(IntTest.indexScreens);
                      IntTest.indexScreens = 12;
                      IntTest.myTitle = 'Сотрудник';
                      setState(() {});
                    },
                    onHover: (val) {
                      setState(() {
                        isHover = index;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 2.0),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5.0),
                          color: isHover == index
                              ? Colors.grey.shade50
                              : ColorApp.myColorWhite,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              ///ФИО
                              Expanded(
                                child: Container(
                                  height: 60,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    color: isHover == index
                                        ? ColorApp.myColorWhite
                                        : ColorApp.myColorGrayShadow,
                                  ),
                                  child: Row(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10.0),
                                        child: CircleAvatar(
                                          foregroundImage: NetworkImage('http://${getEmployee[index]['photo']}'),
                                          backgroundImage: const AssetImage('assets/user.png'),
                                        ),
                                      ),
                                      Expanded(
                                        child:
                                        getEmployee[index]['name'] == null
                                            ? const Text('Не заполнено')
                                            : Text(
                                            getEmployee[index]['name'],
                                            style: TextStyle(
                                                fontSize: size.width > 450
                                                    ? 14
                                                    : 12)),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              ///Участок
                              if (size.width > 550)
                                Expanded(
                                    child: Row(
                                      children: [
                                        const SizedBox(width: 20.0),
                                        getEmployee[index]['division_id'] == null
                                            ? const Text('Не заполнено')
                                            : Text(
                                            getEmployee[index]
                                            ['division_id']['title'].toString(),
                                            style: TextStyle(
                                                fontSize: size.width > 450
                                                    ? 14
                                                    : 12)),
                                      ],
                                    )),

                              ///Номер телефона
                              if (size.width > 1050)
                                Expanded(
                                    child: getEmployee[index]
                                    ['contact_phone'] !=
                                        null
                                        ? Text(getEmployee[index]
                                    ['contact_phone'])
                                        : const Text('Не заполнено')),

                              ///Должность
                              if (size.width > 600)
                                Expanded(
                                    child: Text(getEmployee[index]
                                    ['role_id']['name'])),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      );
    });
  }
}

