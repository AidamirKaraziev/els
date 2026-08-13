import 'dart:convert';
import 'package:els/helper/api_config.dart';
import 'package:els/screns/companies/widgets/top_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../bloc/company_bloc/company_bloc.dart';
import '../../../helper/class_colors.dart';
import '../../../helper/header/header.dart';
import '../../../helper/my_drawer/my_drawer.dart';
import '../../../helper/my_user.dart';
import '../../home_page/home_page.dart';
import '../widgets/add_companies.dart';
import 'package:http/http.dart' as http;

import 'companies_screen_archive.dart';
import 'package:els/helper/api_client.dart';

///Компании =======================================

getNewCompanyList() async {
  final res = await Api.get(
      Uri.parse('${ApiConfig.base}/all-company/?page=$newScreensCompany'),
      headers: {
        "Content-Type": "application/json; charset=utf-8",
        'Accept': 'application/json',
      });
  var getCompanyBloc = jsonDecode(utf8.decode(res.bodyBytes));
  dataCompany = getCompanyBloc['data'];
  // dataCompany = getCompany;
  // print('Получение из блок список Компаний ${getCompany}');
  // print('имя Компании ${getCompany['data']['name']} ===>>>>> актуальность ${getCompany['data']['is_actual']}');
}

/// Список Компаний ==========
Map listSelectedCompany = {};
Map listSelectedCompanyArchive = {};
List listSelectedContactPersonCompany = [];
List listSelectedAccountCompany = [];
List listSelectedObjectCompany = [];

List getCompany = [];

List dataCompany = [];

int newScreensCompany = 1;

/// ==========================

class CompaniesScreen extends StatefulWidget {
  const CompaniesScreen({
    Key? key,
  }) : super(key: key);

  @override
  State<CompaniesScreen> createState() => _CompaniesScreenState();
}

bool openListSearchCompany = false;

int isHover = -1;




///Получение данных одной компании =======
getListCompanyInfo(int userId) async {
  await Future(() async {
    final res = await Api.get(
        Uri.parse("${ApiConfig.base}/company/$userId/"),
        headers: {
          "Content-Type": "application/json; charset=utf-8",
        });
    var vova = jsonDecode(utf8.decode(res.bodyBytes));
    listSelectedCompany = vova;
    print(listSelectedCompany['data']['id']);
  });
}
/// ======================================

class _CompaniesScreenState extends State<CompaniesScreen> {

  /// Функция поиска по имени =======================
  void _runCompanyFilter(String enteredKeyword) {
    List result = [];
    if (enteredKeyword.isEmpty) {
      result = getCompany;
    } else {
      result = getCompany
          .where((user) => myColorButtonCompany == 1
          ? user['name'].toLowerCase().contains(enteredKeyword.toLowerCase()) : myColorButtonCompany == 2
          ? user['director_name'].toLowerCase().contains(enteredKeyword.toLowerCase()) : myColorButtonCompany == 3
          ? user['cont_phone'].toLowerCase().contains(enteredKeyword.toLowerCase())
          : user['email'].toLowerCase().contains(enteredKeyword.toLowerCase()))
          .toList();
    }
    setState(() {
      dataCompany = result;
    });
  }
  /// ===============================================

  @override
  void initState() {
    myColorButtonCompany = 1;
    getNewCompanyList();
    getCompanyArchive();
    dataCompany = getCompany;
    // TODO: implement initState
    setState(() {});
    super.initState();
  }

  @override
  void dispose() {
    newScreensCompany = 1;
    openListSearchCompany = false;
    // TODO: implement dispose
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return StreamBuilder(
      stream: myStream.stream,
      builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
        return Scaffold(
          key: myOpenDrawer,
          drawer: const MyDrawer(),
          body: Container(
            color: ColorApp.myColorTransparent,
            child: Column(
              children: [
                ///Header =====
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: ColorApp.kPadding),
                  color: Colors.white,
                  height: 70,
                  width: double.infinity,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      ///Иконка меню
                      if (size.width <= 1350)
                        Row(
                          children: [
                            IconButton(
                                onPressed: () {
                                  myOpenDrawer.currentState!.openDrawer();
                                  setState(() {});
                                },
                                icon: Icon(Icons.menu,
                                    size: size.width > 350 ? 25.0 : 20)),
                            const SizedBox(width: 10.0),
                          ],
                        ),
                      ///Text
                      Text('Компании',
                          style: TextStyle(
                              fontSize: size.width > 350 ? 25.0 : 18.0,
                              fontWeight: size.width > 350
                                  ? FontWeight.w700
                                  : FontWeight.w500)),
                      /// Кнопки Добавить Компанию, Кнопка архив, Поиск Компании
                      Row(
                        children: [
                          const SizedBox(width: 10.0),

                          ///Добавить Компанию
                          IconButton(
                              onPressed: () async {
                                setState(() {
                                  showDialog(
                                      context: context,
                                      builder: (context) => const AlertDialog(
                                        content: AddCompany(),
                                      ))
                                      .then((value) => setState(() {}));
                                });
                              },
                              icon: const Icon(Icons.add_box_rounded,
                                  size: 25.0,
                                  color: ColorApp.myColorGreenAuth)),
                          /// Кнопка архив
                          if (size.width > 500)
                            IconButton(
                                onPressed: () {
                                  IntTest.indexScreens = 17;
                                  myStream.add(IntTest.indexScreens);
                                  setState(() {});
                                },
                                icon: const Icon(
                                    Icons.archive_outlined,
                                    size: 25.0,
                                    color:  ColorApp.myColorGray)),

                          ///Поиск Компании
                          if (size.width > 500)
                            Row(
                              children: [
                                if (openListSearchCompany == false)
                                  IconButton(
                                      onPressed: () {
                                        openListSearchCompany = true;
                                        setState(() {});
                                      },
                                      icon: const Icon(Icons.search,
                                          size: 25.0,
                                          color: ColorApp.myColorGray)),
                              ],
                            ),
                          if (openListSearchCompany)
                            Row(
                              children: [
                                const SizedBox(width: 10),
                                SizedBox(
                                  width: MediaQuery.of(context).size.width * 0.3,
                                  height: 40.0,
                                  child: Form(
                                    child: TextField(
                                      onChanged: (value) =>
                                          _runCompanyFilter(value),
                                      cursorColor: ColorApp.myColorGray,
                                      decoration: InputDecoration(
                                          contentPadding:
                                          const EdgeInsets.all(0.0),
                                          prefixIcon: IconButton(
                                              onPressed: () {},
                                              icon:
                                              const Icon(Icons.search)),
                                          suffixIcon: IconButton(
                                              onPressed: () {
                                                setState(() {
                                                  dataCompany = getCompany;
                                                  openListSearchCompany = false;
                                                });
                                              },
                                              icon:
                                              const Icon(Icons.close)),
                                          border: const OutlineInputBorder(),
                                          focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: ColorApp.myColorGreenAuth)),
                                          labelText: myColorButtonCompany == 1
                                              ? 'Поиск по имени' : myColorButtonCompany == 2
                                              ? 'Поиск по директору' : myColorButtonCompany == 3
                                              ? 'Поиск по телефону' : 'Поиск по почте',
                                          labelStyle: const TextStyle(color: ColorApp.myColorGray)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                      const Spacer(),

                      ///Колокольчик
                      // if (size.width > 400)
                      //   Badge(
                      //     alignment: const AlignmentDirectional(21, 4),
                      //     backgroundColor: ColorApp.myColorRed,
                      //     isLabelVisible:
                      //     IntTest.badgeCount > 0 ? true : false,
                      //     label: IntTest.badgeCount < 1
                      //         ? const SizedBox.shrink()
                      //         : Text(IntTest.badgeCount.toString(),
                      //         style: const TextStyle(
                      //             fontSize: 12.0,
                      //             color: ColorApp.myColorWhite,
                      //             fontWeight: FontWeight.w500)),
                      //     child: IconButton(
                      //       onPressed: () {},
                      //       icon: const Icon(
                      //           Icons.notifications_none_outlined,
                      //           size: 25.0),
                      //     ),
                      //   ),
                      // SizedBox(width: size.width > 500 ? 40.0 : 10.0),
                      // const Spacer(),
                      /// Переключение страницы
                      Row(
                        children: [
                          IconButton(onPressed: (){
                            if(newScreensCompany > 1) {
                              --newScreensCompany;
                            }
                            getNewCompanyList();
                            myStream.add(IntTest.indexScreens);
                          }, icon: const Icon(Icons.arrow_circle_left_outlined, color: Color(0xffBADE89))),
                          const SizedBox(width: 10.0),
                          Text('$newScreensCompany'),
                          const SizedBox(width: 10.0),
                          IconButton(onPressed: (){
                            if(dataCompany.isNotEmpty) {
                              newScreensCompany++;
                            }
                            getNewCompanyList();
                            myStream.add(IntTest.indexScreens);
                          }, icon: const Icon(Icons.arrow_circle_right_outlined, color: Color(0xffBADE89))),
                        ],
                      ),

                      ///Аватар Юзера
                      const MyUser(),
                    ],
                  ),
                ),

                /// Top Bar
                const Padding(
                  padding: EdgeInsets.all( 20.0),
                  child: TopButtonCompanies(),
                ),

                /// Список компаний
                StreamBuilder(
                  stream: myStream.stream,
                  builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                    return  Expanded(
                      child: ListView.builder(
                          itemCount: dataCompany.length,
                          itemBuilder: (context, index) {
                            dataCompany.sort((a, b) => a['name'].compareTo(b['name']));
                            final company = dataCompany[index];
                            return company['is_actual'] == false ? Container() : Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20.0),
                              child: Card(
                                // key: ValueKey(dataCompany[index]),
                                child: InkWell(
                                  onTap: () async {
                                    IntTest.indexCompanyList = index;
                                    IntTest.pressHover = company['id'];
                                    await getListCompanyInfo(IntTest.pressHover);
                                    myStream.add(IntTest.indexScreens);
                                    IntTest.indexScreens = 9;
                                    print(IntTest.pressHover);
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
                                        borderRadius:
                                        BorderRadius.circular(5.0),
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
                                                  borderRadius:
                                                  BorderRadius.circular(10),
                                                  color: isHover == index
                                                      ? ColorApp.myColorWhite
                                                      : ColorApp
                                                      .myColorGrayShadow,
                                                ),
                                                child: Row(
                                                  children: [
                                                    Padding(
                                                      padding: const EdgeInsets.symmetric(horizontal: 10.0),
                                                      child: CircleAvatar(
                                                        backgroundColor: Colors.grey.shade200,
                                                        backgroundImage: const AssetImage('assets/comp.jpeg'),
                                                        foregroundImage: NetworkImage('${ApiConfig.scheme}://${company['photo']}'),
                                                      ),
                                                    ),
                                                    Expanded(
                                                      child: Text(company['name']),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 30),

                                            ///Имя Директора
                                            if (size.width > 500)
                                              Expanded(
                                                  child: Text(company[
                                                  'director_name'])),

                                            ///Номер телефона
                                            if (size.width > 1150)
                                              Expanded(
                                                  child: Text('+7${company['cont_phone']}',
                                                      style: TextStyle(
                                                          fontSize:
                                                          size.width > 450
                                                              ? 14
                                                              : 12))),

                                            ///Тип договора
                                            if (size.width > 800)
                                              Expanded(
                                                  child:
                                                  Text(company['email'])),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );


  }
}

/// ===============================================
