import 'dart:convert';
import 'package:els/helper/api_config.dart';
import 'package:els/screns/companies/widgets/company_account_freeze.dart';
import 'package:flutter/material.dart';
import '../../../helper/class_colors.dart';
import '../../../helper/my_user.dart';
import '../../home_page/home_page.dart';
import '../widgets/AddAccount.dart';
import '../widgets/AddObjectSelectedCompany.dart';
import '../widgets/ContactFaces.dart';
import '../widgets/editing_company.dart';
import 'package:http/http.dart' as http;
import 'companies_screen.dart';
import 'companies_screen_archive.dart';

/// Окно выбранной компании

bool addObjectSelectedCompany = false;

/// получить список контактных лиц компании ==
getContactPersonCompany() async {
  await Future(() async {
    final res = await http.get(
        Uri.parse("${ApiConfig.base}/contact-person/sort-by-company/${IntTest.pressHover}/?page=1"),
        headers: {
          "Content-Type": "application/json; charset=utf-8",
          'Authorization': 'Bearer ${IntTest.token}',
        });
    var vova = jsonDecode(utf8.decode(res.bodyBytes));
    listSelectedContactPersonCompany = vova['data'];
    // print('контактные лица компании : $listSelectedContactPersonCompany');
    myStream.add(IntTest.indexScreens);
  });
}
/// ==========================================

/// получить список акаунтов компании ==========
getAccountCompany(int numberCompany) async {
  await Future(() async {
    final res = await http.get(
        Uri.parse("${ApiConfig.base}/company/clients/${IntTest.pressHover}"),
        headers: {
          "Content-Type": "application/json; charset=utf-8",
          'Authorization': 'Bearer ${IntTest.token}',
        });
    var vova = jsonDecode(utf8.decode(res.bodyBytes));
    listSelectedAccountCompany = vova['data'];
    print('список акаунтов компании : $listSelectedAccountCompany');
    myStream.add(IntTest.indexScreens);
  });
}
/// ============================================

/// получить список обьектов компании =============
getListObjectCompany(int numberCompany) async {
  await Future(() async {
    final res = await http.get(
        Uri.parse("${ApiConfig.base}/object/sort-by-company/$numberCompany/?page=1"),
        headers: {
          "Content-Type": "application/json; charset=utf-8",
          'Authorization': 'Bearer ${IntTest.token}',
        });
    var vova = jsonDecode(utf8.decode(res.bodyBytes));
    listSelectedObjectCompany = vova['data'];
    print('список обьектов компании : ${listSelectedObjectCompany.length}');
    myStream.add(IntTest.indexScreens);
  });
}
/// ===============================================

/// Замозморозка компании =============
freezingCompany(int userId) async {
  await Future(() async {
    final res = await http.get(
        Uri.parse("${ApiConfig.base}/company/$userId/archive/"),
        headers: {
          "Content-Type": "application/json; charset=utf-8",
          'Authorization': 'Bearer ${IntTest.token}',
        });
    var vova = jsonDecode(utf8.decode(res.bodyBytes));
    listSelectedCompany = vova;
  });
}
/// ===================================

/// Разморозка компании =================
defrostingCompany(int userId) async {
  await Future(() async {
    final res = await http.get(
        Uri.parse("${ApiConfig.base}/company/$userId/unzip/"),
        headers: {
          "Content-Type": "application/json; charset=utf-8",
          'Authorization': 'Bearer ${IntTest.token}',
        });
    // var vova = jsonDecode(utf8.decode(res.bodyBytes));
    // listSelectedCompany = vova;
  });
  getCompanyArchive();
}
/// =====================================

class CompanyPage extends StatefulWidget {
  const CompanyPage({Key? key}) : super(key: key);

  @override
  State<CompanyPage> createState() => _CompanyPageState();
}


class _CompanyPageState extends State<CompanyPage> {

  @override
  void initState() {
    getContactPersonCompany();
    getAccountCompany(IntTest.pressHover);
    getListObjectCompany(IntTest.pressHover);
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final viewCompanyList = listSelectedCompany['data'];
    return StreamBuilder(
      stream: myStream.stream,
      builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
        return Scaffold(
          backgroundColor: ColorApp.myColorTransparent,
          body: SingleChildScrollView(
            child: Container(
              color: ColorApp.myColorTransparent,
              child: Column(
                children: [
                  ///Header =====
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal:ColorApp.kPadding),
                    color: Colors.white,
                    height: 70,
                    width: double.infinity,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        /// Кнопка Назад
                          Row(
                            children: [
                              Container(
                                width: 32.0,
                                height: 32.0,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(5.0),
                                  border: Border.all(color: ColorApp.myColorGrayBorder,width: 1),
                                  color: Colors.white,
                                  boxShadow: const [
                                    BoxShadow(
                                      color: ColorApp.myColorAvatar,
                                      blurRadius: 5,
                                    ),
                                  ],
                                ),
                                child: IconButton(
                                    onPressed: () {
                                      setState(() {
                                        IntTest.indexScreens = 4;
                                        myStream.add(IntTest.indexScreens);
                                      });
                                    },
                                    icon: const Icon(
                                      Icons.arrow_back_ios_new_rounded,
                                      color: Colors.black,size: 13.0,
                                    )),
                              ),
                              const SizedBox(width: 30.0),
                            ],
                          ),
                        ///Text
                        Text('Компания',
                            style: TextStyle(
                                fontSize: size.width > 350
                                    ? 25.0
                                    : 18.0,
                                fontWeight: size.width > 350
                                    ? FontWeight.w700
                                    : FontWeight.w500)),
                        const Spacer(),
                        ///Колокольчик
                        if (size.width > 400)
                          Badge(
                            alignment:
                            const AlignmentDirectional(21, 4),
                            backgroundColor: ColorApp.myColorRed,
                            isLabelVisible: IntTest.badgeCount > 0
                                ? true
                                : false,
                            label: IntTest.badgeCount < 1
                                ? const SizedBox.shrink()
                                : Text(
                                IntTest.badgeCount.toString(),
                                style: const TextStyle(
                                    fontSize: 12.0,
                                    color:
                                    ColorApp.myColorWhite,
                                    fontWeight:
                                    FontWeight.w500)),
                            child: IconButton(
                              onPressed: () {},
                              icon: const Icon(
                                  Icons
                                      .notifications_none_outlined,
                                  size: 25.0),
                            ),
                          ),
                        SizedBox(width: size.width > 500 ? 40.0 : 10.0),
                        ///Аватар Юзера
                        const MyUser(),
                      ],
                    ),
                  ),
                  /// ===========
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        ///кнопки
                        Row(
                          children: [
                            /// Информация
                            const Text(
                              'Информация',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(width: 10.0),

                            /// Изменить
                            if (listSelectedCompany['data']['is_actual'] == true)
                            IconButton(
                                onPressed: () {
                                  setState(() {
                                    showDialog(
                                        context: context,
                                        builder: (context) => const AlertDialog(
                                          content: EditingCompany(),
                                        ));
                                  });
                                },
                                icon: const Icon(Icons.edit_outlined,
                                    color: ColorApp.myColorGray)),

                            /// Заморозить
                            if (listSelectedCompany['data']['is_actual'] == true)
                            IconButton(
                                onPressed: () {
                                  setState(() async {
                                    await showDialog(
                                        context: context,
                                        builder: (context) => const AlertDialog(
                                          content: CompanyAccountFreeze(),
                                        ));
                                  });
                                },
                                icon: const Icon(Icons.ac_unit_outlined,
                                    color: ColorApp.myColorGray)),
                          ],
                        ),
                        const SizedBox(height: 20.0),
                        Column(
                          children: [
                            /// Лого и Инфа
                            Row(
                              children: [
                                /// Лого
                                if (listSelectedCompany['data']['is_actual'] == true)
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(5.0),
                                      color: ColorApp.myColorWhite,
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Colors.grey,
                                          blurRadius: 5,
                                        ),
                                      ],
                                    ),
                                    height: 250,
                                    width: 250,
                                    child: Padding(
                                      padding: const EdgeInsets.all(50.0),
                                      child: CircleAvatar(
                                        radius: 230.0,
                                        backgroundColor: Colors.grey.shade200,
                                        backgroundImage: const AssetImage('assets/comp.jpeg'),
                                        foregroundImage: NetworkImage(
                                            'http://${viewCompanyList['photo']}'),
                                      ),
                                    ),
                                  )
                                else
                                  Stack(
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(5.0),
                                          color: Colors.grey[400],
                                          boxShadow: const [
                                            BoxShadow(
                                              color: Colors.grey,
                                              blurRadius: 5,
                                            ),
                                          ],
                                        ),
                                        height: 250,
                                        width: 250,
                                        child: Padding(
                                          padding: const EdgeInsets.all(50.0),
                                          child: CircleAvatar(
                                            backgroundColor: Colors.grey.shade200,
                                            backgroundImage: const AssetImage('assets/comp.jpeg'),
                                            foregroundImage: NetworkImage(
                                                'http://${viewCompanyList['photo']}'),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 10.0),
                                      /// Кнопка Разморозить
                                      Positioned(
                                        left: 30.0,
                                        right: 30.0,
                                        bottom: 20.0,
                                        child: ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                                backgroundColor: ColorApp.myColorBlue),
                                            onPressed: () async {
                                              await defrostingCompany(IntTest.pressHover);
                                              listSelectedCompany['data']['is_actual'] = true;
                                              myStream.add(IntTest.indexScreens);
                                              setState(() {});
                                            },
                                            child: const Text('Разморозить')),
                                      )
                                    ],
                                  ),
                                const SizedBox(width: 20.0),

                                /// Инфа
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(5.0),
                                      color: listSelectedCompany['data']['is_actual'] == true ? ColorApp.myColorWhite : Colors.grey[400],
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Colors.grey,
                                          blurRadius: 5,
                                        ),
                                      ],
                                    ),
                                    height: size.width > 600 ? 250 : null,
                                    child: Padding(
                                      padding: const EdgeInsets.all(30.0),
                                      child: Row(
                                        children: [
                                          /// Название Адрес Директор
                                          Expanded(
                                            child: Column(
                                              mainAxisAlignment:
                                              MainAxisAlignment
                                                  .spaceAround,
                                              children: [
                                                /// Название
                                                Row(
                                                  children: [
                                                    const Icon(Icons.business,
                                                        color: ColorApp
                                                            .myColorGreenWhite),
                                                    const SizedBox(
                                                        width: 20.0),
                                                    Column(
                                                      crossAxisAlignment:
                                                      CrossAxisAlignment
                                                          .start,
                                                      children: [
                                                        const Text('Название',
                                                            style: TextStyle(
                                                                fontSize:
                                                                12)),
                                                        Text(
                                                            '${viewCompanyList['name']}',
                                                            style: const TextStyle(
                                                                fontSize: 15,
                                                                fontWeight:
                                                                FontWeight
                                                                    .w600)),
                                                      ],
                                                    ),
                                                  ],
                                                ),

                                                /// Адрес
                                                Row(
                                                  children: [
                                                    const Icon(
                                                        Icons
                                                            .location_on_outlined,
                                                        color: ColorApp
                                                            .myColorGreenWhite),
                                                    const SizedBox(
                                                        width: 20.0),
                                                    Column(
                                                      crossAxisAlignment:
                                                      CrossAxisAlignment
                                                          .start,
                                                      children: [
                                                        const Text('Адрес',
                                                            style: TextStyle(
                                                                fontSize:
                                                                12)),
                                                        Text(
                                                            '${viewCompanyList['cont_address']}',
                                                            style: const TextStyle(
                                                                fontSize: 15,
                                                                fontWeight:
                                                                FontWeight
                                                                    .w600)),
                                                      ],
                                                    ),
                                                  ],
                                                ),

                                                /// Директор
                                                Row(
                                                  children: [
                                                    const Icon(
                                                        Icons.person_outline,
                                                        color: ColorApp
                                                            .myColorGreenWhite),
                                                    const SizedBox(
                                                        width: 20.0),
                                                    Column(
                                                      crossAxisAlignment:
                                                      CrossAxisAlignment
                                                          .start,
                                                      children: [
                                                        const Text('Директор',
                                                            style: TextStyle(
                                                                fontSize:
                                                                12)),
                                                        Text(
                                                            '${viewCompanyList['director_name']}',
                                                            style: const TextStyle(
                                                                fontSize: 15,
                                                                fontWeight:
                                                                FontWeight
                                                                    .w600)),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),

                                          /// Сайт Телефон Эл.почта
                                          Expanded(
                                            child: Column(
                                              mainAxisAlignment:
                                              MainAxisAlignment
                                                  .spaceAround,
                                              children: [
                                                ///Сайт
                                                Row(
                                                  children: [
                                                    const Icon(Icons.language,
                                                        color: ColorApp
                                                            .myColorGreenWhite),
                                                    const SizedBox(
                                                        width: 20.0),
                                                    Column(
                                                      crossAxisAlignment:
                                                      CrossAxisAlignment
                                                          .start,
                                                      children: [
                                                        const Text('Сайт',
                                                            style: TextStyle(
                                                                fontSize:
                                                                12)),
                                                        Text(
                                                            '${viewCompanyList['site']}',
                                                            style: const TextStyle(
                                                                fontSize: 15,
                                                                fontWeight:
                                                                FontWeight
                                                                    .w600)),
                                                      ],
                                                    ),
                                                  ],
                                                ),

                                                ///Телефон
                                                Row(
                                                  children: [
                                                    const Icon(
                                                        Icons.phone_outlined,
                                                        color: ColorApp
                                                            .myColorGreenWhite),
                                                    const SizedBox(
                                                        width: 20.0),
                                                    Column(
                                                      crossAxisAlignment:
                                                      CrossAxisAlignment
                                                          .start,
                                                      children: [
                                                        const Text('Телефон',
                                                            style: TextStyle(
                                                                fontSize:
                                                                12)),
                                                        Text(
                                                            '+7${viewCompanyList['cont_phone']}',
                                                            style: const TextStyle(
                                                                fontSize: 15,
                                                                fontWeight:
                                                                FontWeight
                                                                    .w600)),
                                                      ],
                                                    ),
                                                  ],
                                                ),

                                                ///Эл.почта
                                                Row(
                                                  children: [
                                                    const Icon(
                                                        Icons.email_outlined,
                                                        color: ColorApp
                                                            .myColorGreenWhite),
                                                    const SizedBox(
                                                        width: 20.0),
                                                    Column(
                                                      crossAxisAlignment:
                                                      CrossAxisAlignment
                                                          .start,
                                                      children: [
                                                        const Text('Эл.почта',
                                                            style: TextStyle(
                                                                fontSize:
                                                                12)),
                                                        Text(
                                                            '${viewCompanyList['email']}',
                                                            style: const TextStyle(
                                                                fontSize: 15,
                                                                fontWeight:
                                                                FontWeight
                                                                    .w600)),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20.0),
                            /// Аккаунты Объекты Контактные лица
                            Row(
                              children: const [
                                /// Аккаунты
                                Expanded(
                                  flex: 3,
                                  child: DisplayAccountCompany(),
                                ),
                                SizedBox(width: 20.0),

                                ///Объекты
                                Expanded(
                                  flex: 3,
                                  child:
                                  AddObjectSelectedCompany(),
                                ),
                                SizedBox(width: 20.0),

                                ///Контактные лица
                                Expanded(
                                  flex: 2,
                                  child: ContactFaces(),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}