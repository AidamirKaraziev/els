import 'dart:convert';
import 'package:els/screns/companies/widgets/top_button.dart';
import 'package:flutter/material.dart';
import '../../../helper/class_colors.dart';
import '../../../helper/header/header.dart';
import '../../../helper/my_drawer/my_drawer.dart';
import 'package:http/http.dart' as http;
import '../../screns/home_page/home_page.dart';
import '../user_page_foreman.dart';

///Компании =======================================

/// Список Компаний ==========
List getCompanyForeman = [];

List dataCompanyForeman = [];

Map listSelectedCompanyForeman = {};

/// Список всех компаний
getListCompanyForeman() async {
  final res = await http.get(
      Uri.parse('http://${IntTest.myIp}/api/v1/all-company/?page=1'),
      headers: {
        "Content-Type": "application/json; charset=utf-8",
        'Accept': 'application/json',
        'Authorization': 'Bearer ${IntTest.token}',
      });
  var vova = jsonDecode(utf8.decode(res.bodyBytes));

  getCompanyForeman = vova['data'];
  myStream.add(IntTest.indexScreensForeman);
}

class CompaniesScreenForeman extends StatefulWidget {
  const CompaniesScreenForeman({
    Key? key,
  }) : super(key: key);

  @override
  State<CompaniesScreenForeman> createState() => _CompaniesScreenForemanState();
}

bool openListSearchCompany = false;


int isHover = -1;

///Получение данных одной компании ==============
getListCompanyInfoForeman(int userId) async {
  await Future(() async {
    final res = await http.get(
        Uri.parse("http://${IntTest.myIp}/api/v1/company/$userId/"),
        headers: {
          "Content-Type": "application/json; charset=utf-8",
          'Authorization': 'Bearer ${IntTest.token}',
        });
    var vova = jsonDecode(utf8.decode(res.bodyBytes));
    listSelectedCompanyForeman = vova;
  });
}
/// =============================================

class _CompaniesScreenForemanState extends State<CompaniesScreenForeman> {
  /// Функция поиска по имени =======================
  void _runCompanyFilter(String enteredKeyword) {
    List result = [];
    if (enteredKeyword.isEmpty) {
      result = getCompanyForeman;
    } else {
      result = getCompanyForeman
          .where((user) =>
              user['name'].toLowerCase().contains(enteredKeyword.toLowerCase()))
          .toList();
    }
    setState(() {
      dataCompanyForeman = result;
    });
  }
  /// ===============================================

  @override
  void initState() {
    getListCompanyForeman();
    dataCompanyForeman = getCompanyForeman;
    // TODO: implement initState
    setState(() {});
    super.initState();
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
                ///Header
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
                          // IconButton(
                          //     onPressed: () async {
                          //       setState(() {
                          //         showDialog(
                          //             context: context,
                          //             builder: (context) => const AlertDialog(
                          //               content: AddCompanyForeman(),
                          //             ))
                          //             .then((value) => setState(() {}));
                          //       });
                          //     },
                          //     icon: const Icon(Icons.add_box_rounded,
                          //         size: 25.0,
                          //         color: ColorApp.myColorGreenAuth)),
                          /// Кнопка архив
                          if (size.width > 500)
                            IconButton(
                                onPressed: () {
                                  IntTest.indexScreensForeman = 19;
                                  myStream.add(IntTest.indexScreensForeman);
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
                                  width: MediaQuery.of(context).size.width *
                                      0.3,
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
                                                  dataCompanyForeman = getCompanyForeman;
                                                });
                                                openListSearchCompany = false;
                                                setState(() {});
                                              },
                                              icon:
                                              const Icon(Icons.close)),
                                          border:
                                          const OutlineInputBorder(),
                                          focusedBorder:
                                          const OutlineInputBorder(
                                            borderSide: BorderSide(
                                                color: ColorApp
                                                    .myColorGreenAuth),
                                          ),
                                          labelText: 'Поиск',
                                          labelStyle: const TextStyle(
                                              color: ColorApp.myColorGray)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                      const Spacer(),

                      ///Колокольчик
                      if (size.width > 400)
                        Badge(
                          alignment: const AlignmentDirectional(21, 4),
                          backgroundColor: ColorApp.myColorRed,
                          isLabelVisible:
                          IntTest.badgeCount > 0 ? true : false,
                          label: IntTest.badgeCount < 1
                              ? const SizedBox.shrink()
                              : Text(IntTest.badgeCount.toString(),
                              style: const TextStyle(
                                  fontSize: 12.0,
                                  color: ColorApp.myColorWhite,
                                  fontWeight: FontWeight.w500)),
                          child: IconButton(
                            onPressed: () {},
                            icon: const Icon(
                                Icons.notifications_none_outlined,
                                size: 25.0),
                          ),
                        ),
                      SizedBox(width: size.width > 500 ? 40.0 : 10.0),

                      ///Аватар Юзера
                      const MyUserForeman(),
                    ],
                  ),
                ),
                /// Top Bar
                const Padding(
                  padding: EdgeInsets.all( 20.0),
                  child: TopButtonCompanies(),
                ),
                /// Список компаний
                Expanded(
                  child: ListView.builder(
                      itemCount: dataCompanyForeman.length,
                      itemBuilder: (context, index) {
                        final company = dataCompanyForeman[index];
                        return company['is_actual'] == false ? Container() : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child: Card(
                            // key: ValueKey(dataCompany[index]),
                            child: InkWell(
                              onTap: () async {
                                IntTest.indexCompanyList = index;
                                IntTest.pressHover = company['id'];
                                await getListCompanyInfoForeman(IntTest.pressHover);
                                IntTest.indexScreensForeman = 18;
                                myStream.add(IntTest.indexScreensForeman);
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
                                                  : ColorApp.myColorGrayShadow,
                                            ),
                                            child: Row(
                                              children: [
                                                Padding(
                                                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                                                  child: CircleAvatar(
                                                    backgroundColor: Colors.grey.shade200,
                                                    backgroundImage: const AssetImage('assets/comp.jpeg'),
                                                    foregroundImage: NetworkImage('http://${company['photo']}'),
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
                                          Expanded(child: Text(company['director_name'])),

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
