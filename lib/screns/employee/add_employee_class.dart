import 'dart:convert';
import 'package:els/bloc/employee_bloc/employee_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import '../../helper/class_colors.dart';

///Класс Сотрудники

///Получение данных одного сотрудника ======
getListEmployeesInfo(int userId) async {
  /// Список сотрудников
  Map listSelectedEmployee = {};

  await Future(() async {
    final res = await http.get(
        Uri.parse("http://${IntTest.myIp}/api/v1/cp/universal-user/$userId/"),
        headers: {
          "Content-Type": "application/json; charset=utf-8",
          'Authorization': 'Bearer ${IntTest.token}',
        });
    var vova = jsonDecode(utf8.decode(res.bodyBytes));
    listSelectedEmployee = vova;
    print('Данные выбраного сотрудника ${listSelectedEmployee['data']['name']}');
  });
}
/// ========================================

class CartInfoPeople extends StatefulWidget {
  const CartInfoPeople({
    Key? key,
  }) : super(key: key);

  @override
  State<CartInfoPeople> createState() => _CartInfoPeopleState();
}

class _CartInfoPeopleState extends State<CartInfoPeople> {

  int isHover = -1;
  int pressHover = -1;

  bool isSortTest = false;

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return BlocBuilder<EmployeeBloc, EmployeeState>(builder: (context, state) {
      return Column(
        children: [
          IconButton(onPressed: (){
            setState(() {
              isSortTest =! isSortTest;
            });
            print(isSortTest);
          }, icon: const Icon(Icons.sort_by_alpha)),
          if (state is EmployeeGetUserState)
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.6,
              child: ListView.builder(
                controller: ScrollController(),
                itemCount: state.listGetEmployee.length,
                itemBuilder: (context, index){

                  return InkWell(
                    onTap: () async {
                      pressHover = index;
                      getListEmployeesInfo(index);
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
                                          foregroundImage: NetworkImage(
                                            'http://${state.listGetEmployee[index]['photo']}',
                                          ),
                                          backgroundImage: const AssetImage('assets/user.png'),
                                          // child: Text('${state.listGetEmployee[index]['name'][0]}',style: const TextStyle(color: ColorApp.myColorWhite,fontWeight: FontWeight.w600,fontSize: 20.0)),
                                        ),
                                      ),
                                      Expanded(
                                        child: Text( state.listGetEmployee[index]['name'],),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              ///Участок
                              if (size.width > 550) Expanded(
                                  child: Row(
                                    children: [
                                      const SizedBox(width: 40.0),
                                      Text(
                                          state.listGetEmployee[index]['role_id']['id'].toString(),
                                          style: TextStyle(
                                              fontSize:
                                              size.width > 450 ? 14 : 12)),
                                    ],
                                  )),
                              ///Номер телефона
                              if (size.width > 1050) Expanded(
                                  child: Text(state.listGetEmployee[index]['contact_phone'])),
                              ///Должность
                              if (size.width > 600) Expanded(
                                  child: Text(state.listGetEmployee[index]['role_id']['name'])),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                } ,
              ),
            ),
        ],
      );
    });
  }
}

