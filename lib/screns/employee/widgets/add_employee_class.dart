import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../helper/class_colors.dart';
import '../../home_page/home_page.dart';
import 'package:http/http.dart' as http;

import '../bloc/employee_bloc.dart';

///Класс Сотрудники

/// Список сотрудников
Map listSelectedEmployee = {};

bool archive = false;

List getEmployee = [];

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
      getEmployee = state.listGetEmployee;
      return Stack(
        children: [
          if (getEmployee.isNotEmpty)
          SizedBox(
            height: MediaQuery.of(context).size.height*0.745,
            child: ListView.builder(
              controller: ScrollController(),
              itemCount: getEmployee.length,
              itemBuilder: (context, index) {
                final employee = getEmployee[index];
                return InkWell(
                  onTap: () async {
                    IntTest.pressHover = employee['id'];
                    IntTest.indexUserList = index;
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
                                        foregroundImage: NetworkImage('http://${employee['photo']}'),
                                        backgroundImage: const AssetImage('assets/user.png'),
                                      ),
                                    ),
                                    Expanded(
                                      child:
                                      getEmployee[index]['name'] == null
                                          ? const Text('Не заполнено')
                                          : Text(
                                          employee['name'],
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
                                      employee['division_id'] == null
                                          ? const Text('Не заполнено')
                                          : Text(
                                          employee
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
                                  child: employee
                                  ['contact_phone'] !=
                                      null
                                      ? Text(employee
                                  ['contact_phone'])
                                      : const Text('Не заполнено')),

                            ///Должность
                            if (size.width > 600)
                              Expanded(
                                  child: Text(employee
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
          /// Архивированные сотрудники ==
          if(archive == true)
            Container(
              color: Colors.grey.shade300,
              height: 360,
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('Отмороженные сотрудники )))'),
                      const SizedBox(width: 30.0),
                      IconButton(onPressed: (){
                        archive = false;
                        print('yes this archive : $archive');
                        pointsMapController.add(IntTest.indexScreens);

                      }, icon: const Icon(Icons.expand_less,color: ColorApp.myColorGray,))
                    ],
                  ),
                  SizedBox(
                    height: 320,
                    child: ListView.builder(
                      controller: ScrollController(),
                      itemCount: getEmployee.length,
                      itemBuilder: (context, index) {
                        final employee = getEmployee[index];
                        return InkWell(
                          // onTap: () async {
                          //   IntTest.pressHover = employee['id'];
                          //   IntTest.indexUserList = index;
                          //   await getListEmployeesInfo(IntTest.pressHover);
                          //   pointsMapController.add(IntTest.indexScreens);
                          //   IntTest.indexScreens = 12;
                          //   IntTest.myTitle = 'Сотрудник';
                          //   setState(() {});
                          // },
                          onHover: (val) {
                            setState(() {
                              isHover = index;
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 5.0,left: 5.0,right: 5.0),
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
                                                foregroundImage: NetworkImage('http://${employee['photo']}'),
                                                backgroundImage: const AssetImage('assets/user.png'),
                                              ),
                                            ),
                                            Expanded(
                                              child:
                                              getEmployee[index]['name'] == null
                                                  ? const Text('Не заполнено')
                                                  : Text(
                                                  employee['name'],
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
                                              employee['division_id'] == null
                                                  ? const Text('Не заполнено')
                                                  : Text(
                                                  employee
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
                                          child: employee
                                          ['contact_phone'] !=
                                              null
                                              ? Text(employee
                                          ['contact_phone'])
                                              : const Text('Не заполнено')),

                                    ///Должность
                                    if (size.width > 600)
                                      Expanded(
                                          child: Text(employee
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
              ),
            ),
          /// =============================
        ],
      );
    });
  }
}

