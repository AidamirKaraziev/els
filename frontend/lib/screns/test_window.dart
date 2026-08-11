import 'dart:convert';
import 'package:els/helper/api_config.dart';
import 'package:els/screns/schedule/schedule_page.dart';
import 'package:els/screns/schedule/schedule_screen.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../helper/class_colors.dart';
import '../helper/header/header.dart';
import '../helper/my_user.dart';
import 'companies/view/companies_screen.dart';
import 'companies/widgets/AddObjectSelectedCompany.dart';
import 'home_page/home_page.dart';

/// Окно списки объекта

Map listSelectedCompanySchedule = {};

class TestWindow extends StatefulWidget {
  const TestWindow({Key? key}) : super(key: key);

  @override
  State<TestWindow> createState() => _TestWindowState();
}

class _TestWindowState extends State<TestWindow> {


  ///Получение данных объекта одной компании =============
  getListCompanyInfoObjectSchedule(int userId) async {
    await Future(() async {
      final res = await http.get(
          Uri.parse("${ApiConfig.base}/object/$userId/"),
          headers: {
            "Content-Type": "application/json; charset=utf-8",
            'Authorization': 'Bearer ${IntTest.token}',
          });
      var vova = jsonDecode(utf8.decode(res.bodyBytes));
      listSelectedCompanySchedule = vova;
      // print('Объект выбраной компании ${listSelectedCompanySchedule['data']}');
    });
  }
  /// ====================================================

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return  Scaffold(
      body: Column(
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
                // if (size.width <= 1350)
                //   Row(
                //     children: [
                //       IconButton(
                //           onPressed: () {
                //             myOpenDrawer.currentState!.openDrawer();
                //             setState(() {});
                //           },
                //           icon: Icon(Icons.menu,
                //               size: size.width > 350 ? 25.0 : 20)),
                //       const SizedBox(width: 10.0),
                //     ],
                //   ),
                /// Кнопка Назад Обьекты
                Row(
                  children: [
                    Container(
                      width: 32.0,
                      height: 32.0,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5.0),
                        border: Border.all(
                            color: ColorApp.myColorGrayBorder, width: 1),
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
                              IntTest.indexScreens = 1;
                              openListCompanySchedule = false;
                              myStream.add(IntTest.indexScreens);
                            });
                          },
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Colors.black,
                            size: 13.0,
                          )),
                    ),
                    const SizedBox(width: 30.0),
                  ],
                ),
                /// Текст
                Text('Объекты компании',
                    style: TextStyle(
                        fontSize: size.width > 350 ? 25.0 : 18.0,
                        fontWeight: size.width > 350
                            ? FontWeight.w700
                            : FontWeight.w500)),

                ///Добавить Сотрудника
                // IconButton(
                //     onPressed: () async {
                //       setState(() {
                //         showDialog(
                //             context: context,
                //             builder: (context) => const AlertDialog(
                //               // content: AddEmployee(),
                //             )).then((value) => setState(() {}));
                //       });
                //     },
                //     icon: const Icon(Icons.add_box_rounded,
                //         size: 25.0, color: ColorApp.myColorGreenAuth)),
                // if (size.width > 500)
                //   Row(
                //     children: [
                //       if (openListSearch == false)
                //         IconButton(
                //             onPressed: () {
                //               openListSearch = true;
                //               setState(() {});
                //               // myStream.add(IntTest.indexScreens);
                //             },
                //             icon: const Icon(Icons.search,
                //                 size: 25.0, color: ColorApp.myColorGray)),
                //     ],
                //   ),
                /// Поиск
                // if (openListSearch)
                //   Row(
                //     children: [
                //       const SizedBox(width: 10),
                //       SizedBox(
                //         width: MediaQuery.of(context).size.width * 0.3,
                //         height: 40.0,
                //         child: Form(
                //           child: TextField(
                //             // onChanged: (value) => _runEmployeeFilter(value),
                //             cursorColor: ColorApp.myColorGray,
                //             decoration: InputDecoration(
                //                 contentPadding: const EdgeInsets.all(0.0),
                //                 prefixIcon: IconButton(
                //                     onPressed: () {},
                //                     icon: const Icon(Icons.search)),
                //                 suffixIcon: IconButton(
                //                     onPressed: () {
                //                       setState(() {
                //                         // dataEmployee = getEmployee;
                //                       });
                //                       openListSearch = false;
                //                       // myStream.add(IntTest.indexScreens);
                //                     },
                //                     icon: const Icon(Icons.close)),
                //                 border: const OutlineInputBorder(),
                //                 focusedBorder: const OutlineInputBorder(
                //                   borderSide: BorderSide(
                //                       color: ColorApp.myColorGreenAuth),
                //                 ),
                //                 labelText: 'Поиск',
                //                 labelStyle: const TextStyle(
                //                     color: ColorApp.myColorGray)),
                //           ),
                //         ),
                //       ),
                //     ],
                //   ),
                const Spacer(),

                ///Колокольчик
                if (size.width > 400)
                  Badge(
                    alignment: const AlignmentDirectional(21, 4),
                    backgroundColor: ColorApp.myColorRed,
                    isLabelVisible: IntTest.badgeCount > 0 ? true : false,
                    label: IntTest.badgeCount < 1
                        ? const SizedBox.shrink()
                        : Text(IntTest.badgeCount.toString(),
                        style: const TextStyle(
                            fontSize: 12.0,
                            color: ColorApp.myColorWhite,
                            fontWeight: FontWeight.w500)),
                    child: IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.notifications_none_outlined,
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
          testListSSSS.isNotEmpty
              ? Expanded(child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: ListView.builder(
                itemExtent: 70.0,
                itemCount: testListSSSS.length,
                itemBuilder: (context, index) {
                  final listAddSelectedObjectCompany = testListSSSS['data'][index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 5.0),
                    child: Card(
                      key: ValueKey(testListSSSS['data'][index]),
                      child: InkWell(
                        onTap: () async {
                          IntTest.pressHover = testListSSSS['data'][index]['id'];
                          // print(IntTest.pressHover);
                          await getListCompanyInfoObjectSchedule(IntTest.pressHover);
                          // setState(() {
                          //   showDialog(
                          //       context: context,
                          //       builder: (context) => const AlertDialog(content: SchedulePage(),
                          //       ));
                          // });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 10.0),
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: Colors.grey, width: 1),
                            borderRadius:
                            BorderRadius.circular(5.0),
                          ),

                          child: Row(
                            mainAxisAlignment:
                            MainAxisAlignment
                                .spaceBetween,
                            children: [
                              const SizedBox(width: 10.0),
                              /// Название
                              Expanded(
                                  child: Text(listAddSelectedObjectCompany['name'] == null ? '':  '${listAddSelectedObjectCompany['name']}',
                                      style: const TextStyle(
                                          fontSize: 12.0,
                                          fontWeight:
                                          FontWeight
                                              .w600))),
                              const SizedBox(width: 10.0),
                              /// Адрес
                              Expanded(
                                  child: Text(listAddSelectedObjectCompany['address'] == null ? '':
                                  '${listAddSelectedObjectCompany['address']}',
                                      style: const TextStyle(
                                          fontSize: 12.0,
                                          fontWeight: FontWeight.w600))),
                              const SizedBox(width: 10.0),
                              /// Прораб
                              Expanded(
                                  child: Text(listAddSelectedObjectCompany['foreman_id']['name'] == null ? '':
                                  '${listAddSelectedObjectCompany['foreman_id']['name']}',
                                      style: const TextStyle(
                                          fontSize: 12.0,
                                          fontWeight: FontWeight.w600))),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }
          ),
              ))
              : const Center(child: Text('Список пустой')),
        ],
      ),
    );
  }
}
