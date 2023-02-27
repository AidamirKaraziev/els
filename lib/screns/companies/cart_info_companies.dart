import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/company_bloc/company_bloc.dart';
import '../../helper/class_colors.dart';
import '../home_page/home_page.dart';
import 'package:http/http.dart' as http;

/// Карточка Компаний

/// Список Компаний ==========
Map listSelectedCompany = {};
/// ==========================

class CartInfoCompanies extends StatefulWidget {
  const CartInfoCompanies({
    Key? key,
  }) : super(key: key);

  @override
  State<CartInfoCompanies> createState() => _CartInfoCompaniesState();
}

class _CartInfoCompaniesState extends State<CartInfoCompanies> {
  int isHover = -1;

  ///Получение данных одной компании ======
  getListCompanyInfo(int userId) async {
    await Future(() async {
      final res = await http.get(
          Uri.parse("http://${IntTest.myIp}/api/v1/company/$userId/"),
          headers: {
            "Content-Type": "application/json; charset=utf-8",
            'Authorization': 'Bearer ${IntTest.token}',
          });
      var vova = jsonDecode(utf8.decode(res.bodyBytes));
      listSelectedCompany = vova;
      print('Данные выбраной компании ${listSelectedCompany['data']}');
    });
  }

  /// ========================================

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return BlocBuilder<CompanyBloc, CompanyState>(
  builder: (context, state) {
    return Column(
      children: [
        if (state is CompanyGetState)
          SizedBox(
            height: MediaQuery.of(context).size.height*0.7,
            child: ListView.builder(
              itemCount: state.listGetCompany.length,
              itemBuilder: (context, index) => InkWell(
                onTap: () async {
                  IntTest.pressHover = state.listGetCompany[index]['id'];
                  await getListCompanyInfo(IntTest.pressHover);
                  pointsMapController.add(IntTest.indexScreens);
                  IntTest.indexScreens = 10;
                  print('Открыть Блок');
                  setState(() {

                  });
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
                          ///Название компании
                          Expanded(
                            child: Container(
                              height: 60,
                              // padding: const EdgeInsets.all(10.0),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: isHover == index
                                    ? ColorApp.myColorWhite
                                    : ColorApp.myColorGrayShadow,
                              ),
                              child: Row(
                                children: [
                                  Padding(padding: const EdgeInsets.symmetric(horizontal: 10.0),
                                    child: CircleAvatar(
                                      backgroundImage: const NetworkImage('assets/cat.jpeg'),
                                      foregroundImage: NetworkImage('http://${state.listGetCompany[index]['photo']}'),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      state.listGetCompany[index]['name'],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 30),
                          ///Имя Директора
                          if (size.width > 500) Expanded(
                              child: Text(state.listGetCompany[index]['director_name'])),
                          ///Номер телефона
                          if (size.width > 1150) Expanded(
                              child: Text(state.listGetCompany[index]['cont_phone'],
                                  style: TextStyle(
                                      fontSize: size.width > 450 ? 14 : 12))),
                          ///Тип договора
                          if (size.width > 800) Expanded(child: Text(state.listGetCompany[index]['email'])),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  },
);
  }
}