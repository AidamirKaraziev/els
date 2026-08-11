import 'dart:convert';
import 'package:els/helper/api_config.dart';
import 'package:els/foreman/object_foreman/object_screen_foreman.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../helper/class_colors.dart';
import '../../helper/header/header.dart';
import '../../screns/employee/widgets/topButton.dart';
import '../../screns/home_page/home_page.dart';
import '../../screns/user/user_contact.dart';
import '../drawer_foreman.dart';
import '../user_page_foreman.dart';

///Графики

Map listSelectedScheduleForeman = {};
List dataScheduleListForeman = [];
List getScheduleListForeman = [];

/// Данные выбраного графика прораба
getListScheduleForeman() async {
  final res = await http.get(
      Uri.parse('${ApiConfig.base}/object/by-foreman/?foreman_id=${userProfile[0]['id']}&page=1'),
      headers: {
        "Content-Type": "application/json; charset=utf-8",
        'Accept': 'application/json',
        'Authorization': 'Bearer ${IntTest.token}',
      });
  var vova = jsonDecode(utf8.decode(res.bodyBytes));
  getScheduleListForeman = vova['data'];
  myStream.add(IntTest.indexScreens);
}
/// ================================

/// Данные выбраного графика прораба =============
getListScheduleInfoForeman(int userId) async {
  await Future(() async {
    final res = await http.get(
        Uri.parse("${ApiConfig.base}/object/$userId/"),
        headers: {
          "Content-Type": "application/json; charset=utf-8",
          'Authorization': 'Bearer ${IntTest.token}',
        });
    var vova = jsonDecode(utf8.decode(res.bodyBytes));
    listSelectedScheduleForeman = vova;
    print(listSelectedObjectForeman);
  });
}
/// ==============================================

bool openListCompanySchedule = false;
bool openListPlotSchedule = false;

class ScheduleScreenForeman extends StatefulWidget {
  const ScheduleScreenForeman({
    Key? key,
  }) : super(key: key);

  @override
  State<ScheduleScreenForeman> createState() => _ScheduleScreenForemanState();
}

class _ScheduleScreenForemanState extends State<ScheduleScreenForeman> {
  bool openListSearch = false;

  @override
  void initState() {
    getListScheduleForeman();
    dataScheduleListForeman = getScheduleListForeman;
    // TODO: implement initState
    super.initState();
  }

  /// Функция поиска по имени ========================
  void _runScheduleFilter(String enteredKeyword) {
    List result = [];
    if (enteredKeyword.isEmpty) {
      result = getScheduleListForeman;
    } else {
      result = getScheduleListForeman
          .where((user) =>
          user['name'].toLowerCase().contains(enteredKeyword.toLowerCase()))
          .toList();
    }
    setState(() {
      dataScheduleListForeman = result;
    });
    print('Сработала функция');
  }
  /// ================================================

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return StreamBuilder(
      stream: myStream.stream,
      builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
        return Scaffold(
          key: myOpenDrawer,
          drawer: const DrawerForeman(),
          body: Container(
            color: ColorApp.myColorTransparent,
            child: Column(
              children: [
                /// Header
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

                      /// Текст
                      Text('Графики',
                          style: TextStyle(
                              fontSize: size.width > 350 ? 25.0 : 18.0,
                              fontWeight: size.width > 350
                                  ? FontWeight.w700
                                  : FontWeight.w500)),
                      const SizedBox(width: 10.0),
                      if (size.width > 500)
                        Row(
                          children: [
                            if (openListSearch == false)

                              IconButton(
                                  onPressed: () {
                                    openListSearch = true;
                                    setState(() {});
                                    myStream.add(IntTest.indexScreens);
                                  },
                                  icon: const Icon(Icons.search,
                                      size: 25.0, color: ColorApp.myColorGray)),
                          ],
                        ),
                      if (openListSearch)
                        Row(
                          children: [
                            const SizedBox(width: 10),
                            SizedBox(
                              width: MediaQuery.of(context).size.width * 0.3,
                              height: 40.0,
                              child: Form(
                                child: TextField(
                                  onChanged: (value) => _runScheduleFilter(value),
                                  cursorColor: ColorApp.myColorGray,
                                  decoration: InputDecoration(
                                      contentPadding: const EdgeInsets.all(0.0),
                                      prefixIcon: IconButton(
                                          onPressed: () {},
                                          icon: const Icon(Icons.search)),
                                      suffixIcon: IconButton(
                                          onPressed: () {
                                            setState(() {
                                              dataScheduleListForeman = getScheduleListForeman;
                                            });
                                            openListSearch = false;
                                            // myStream.add(IntTest.indexScreens);
                                          },
                                          icon: const Icon(Icons.close)),
                                      border: const OutlineInputBorder(),
                                      focusedBorder: const OutlineInputBorder(
                                        borderSide: BorderSide(
                                            color: ColorApp.myColorGreenAuth),
                                      ),
                                      labelText: 'Поиск',
                                      labelStyle: const TextStyle(
                                          color: ColorApp.myColorGray)),
                                ),
                              ),
                            ),
                          ],
                        ),
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
                      const MyUserForeman(),
                    ],
                  ),
                ),

                /// Top Bar
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    height: 50,
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
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ///Название
                        if (size.width >= 1150) Expanded(
                            flex: 2,
                            child: Row(
                              children: [
                                TopButtonWidget(
                                  text: 'Название',
                                  press: () {
                                    // myColorButtonObject = 1;
                                    // setState(() {});
                                  },
                                  pressIcon: () {},
                                  colorButton: ColorApp.myColorWhite,
                                  colorText: ColorApp.myColorBlack,
                                ),
                                // const SizedBox(width: 5.0),
                                // Container(
                                //     width: 27.5,
                                //     height: 27.5,
                                //     decoration: BoxDecoration(
                                //       border:
                                //       Border.all(color: ColorApp.myColorGreen, width: 1.0),
                                //       borderRadius: BorderRadius.circular(3.0),
                                //     ),
                                //     child: const Icon(Icons.arrow_drop_down_sharp)),
                              ],
                            )),
                        ///Заводской номер
                        if (size.width > 900)  SizedBox(
                          width: 150,
                          child: Row(
                            children: [
                              TopButtonWidget(
                                text: 'Заводской номер',
                                press: () {
                                  // myColorButtonObject = 2;
                                  // setState(() {});
                                },
                                pressIcon: () {},
                                colorButton: ColorApp.myColorWhite,
                                colorText: ColorApp.myColorBlack,
                              ),
                              // const SizedBox(width: 5.0),
                              // Container(
                              //     width: 27.5,
                              //     height: 27.5,
                              //     decoration: BoxDecoration(
                              //       border:
                              //       Border.all(color: ColorApp.myColorGreen, width: 1.0),
                              //       borderRadius: BorderRadius.circular(3.0),
                              //     ),
                              //     child: const Icon(Icons.arrow_drop_down_sharp)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10.0),
                        ///Компания
                        // if (size.width >= 1150) Expanded(
                        //     flex: 3,
                        //     child: Row(
                        //       children: [
                        //         TopButtonWidget(
                        //           text: 'Компания',
                        //           press: () {
                        //             // myColorButtonObject = 3;
                        //             // setState(() {});
                        //           },
                        //           pressIcon: () {},
                        //           colorButton: ColorApp.myColorWhite,
                        //           colorText: ColorApp.myColorBlack,
                        //         ),
                        //         // const SizedBox(width: 5.0),
                        //         // Container(
                        //         //     width: 27.5,
                        //         //     height: 27.5,
                        //         //     decoration: BoxDecoration(
                        //         //       border:
                        //         //       Border.all(color: ColorApp.myColorGreen, width: 1.0),
                        //         //       borderRadius: BorderRadius.circular(3.0),
                        //         //     ),
                        //         //     child: const Icon(Icons.arrow_drop_down_sharp)),
                        //       ],
                        //     )),
                        ///Адресс
                        // Expanded(
                        //     flex: 3,
                        //     child: Row(
                        //       children: [
                        //         TopButtonWidget(
                        //           text: 'Адресс',
                        //           press: () {
                        //             // myColorButtonObject = 4;
                        //             // setState(() {});
                        //           },
                        //           pressIcon: () {},
                        //           colorButton: ColorApp.myColorWhite,
                        //           colorText: ColorApp.myColorBlack,
                        //         ),
                        //         // const SizedBox(width: 5.0),
                        //         // Container(
                        //         //     width: 27.5,
                        //         //     height: 27.5,
                        //         //     decoration: BoxDecoration(
                        //         //       border:
                        //         //       Border.all(color: ColorApp.myColorGreen, width: 1.0),
                        //         //       borderRadius: BorderRadius.circular(3.0),
                        //         //     ),
                        //         //     child: const Icon(Icons.arrow_drop_down_sharp)),
                        //       ],
                        //     )),
                        ///Участок
                        if (size.width > 750) Expanded(
                            flex: 2,
                            child: Row(
                              children: [
                                TopButtonWidget(
                                  text: 'Участок',
                                  press: () {
                                    // myColorButtonObject = 5;
                                    // setState(() {});
                                  },
                                  pressIcon: () {},
                                  colorButton: ColorApp.myColorWhite,
                                  colorText: ColorApp.myColorBlack,
                                ),
                                // const SizedBox(width: 5.0),
                                // Container(
                                //     width: 27.5,
                                //     height: 27.5,
                                //     decoration: BoxDecoration(
                                //       border:
                                //       Border.all(color: ColorApp.myColorGreen, width: 1.0),
                                //       borderRadius: BorderRadius.circular(3.0),
                                //     ),
                                //     child: const Icon(Icons.arrow_drop_down_sharp)),
                              ],
                            )),
                        const SizedBox(width: 10.0),
                        ///Тип
                        if (size.width > 500)  SizedBox(
                          width: 150.0,
                          child: Row(
                            children: [
                              TopButtonWidget(text: 'Тип',
                                press: () {
                                  // myColorButtonObject = 6;
                                  // setState(() {});
                                },
                                pressIcon: () {},
                                colorButton: ColorApp.myColorWhite,
                                colorText: ColorApp.myColorBlack,
                              ),
                              // const SizedBox(width: 5.0),
                              // Container(
                              //     width: 27.5,
                              //     height: 27.5,
                              //     decoration: BoxDecoration(
                              //       border:
                              //       Border.all(color: ColorApp.myColorGreen, width: 1.0),
                              //       borderRadius: BorderRadius.circular(3.0),
                              //     ),
                              //     child: const Icon(Icons.arrow_drop_down_sharp)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10.0),
                        /// Графики
                        Expanded(
                            flex: 3,
                            child: Row(
                              children: [
                                TopButtonWidget(text: 'Графики',
                                  press: () {
                                    // myColorButtonObject = 6;
                                    // setState(() {});
                                  },
                                  pressIcon: () {},
                                  colorButton: ColorApp.myColorWhite,
                                  colorText: ColorApp.myColorBlack,
                                ),
                                // const SizedBox(width: 5.0),
                                // Container(
                                //     width: 27.5,
                                //     height: 27.5,
                                //     decoration: BoxDecoration(
                                //       border:
                                //       Border.all(color: ColorApp.myColorGreen, width: 1.0),
                                //       borderRadius: BorderRadius.circular(3.0),
                                //     ),
                                //     child: const Icon(Icons.arrow_drop_down_sharp)),
                              ],
                            )),
                      ],
                    ),
                  ),
                ),

                /// Body
                Expanded(
                  child: ListView.builder(
                      itemCount: dataScheduleListForeman.length,
                      itemBuilder: (context, index) {
                        final dataObjectScreen = dataScheduleListForeman[index];
                        return dataObjectScreen['is_actual'] == false
                            ? Container()
                            :  Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child: Card(
                            key: ValueKey(dataObjectScreen['id']),
                            child: GestureDetector(
                              onTap: () async {
                                IntTest.indexObjectList = index;
                                IntTest.pressHover = dataObjectScreen['id'];
                                await getListScheduleInfoForeman(IntTest.pressHover);
                                myStream.add(IntTest.indexScreensForeman);
                                IntTest.indexScreensForeman = 14;
                                setState(() {});
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(5.0),
                                    color: ColorApp.myColorWhite),
                                child: Padding(padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      ///Название
                                      if (size.width > 1150)
                                        Expanded(
                                          flex: 2,
                                          child: Column(
                                            crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                            children: [
                                              Text(dataObjectScreen['name'] ?? '',
                                                  style: const TextStyle(
                                                      fontWeight: FontWeight.w400)),
                                            ],
                                          ),
                                        ),
                                      const SizedBox(width: 10.0),

                                      ///Заводской номер
                                      if (size.width > 900)
                                        SizedBox(
                                          width: 150,
                                          child: Column(
                                            crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                  '${dataObjectScreen['factory_number']}' ??
                                                      '',
                                                  style: const TextStyle(
                                                      fontWeight: FontWeight.w400)),
                                            ],
                                          ),
                                        ),
                                      const SizedBox(width: 10.0),

                                      ///Компания
                                      // if (size.width > 500)
                                      //   Expanded(
                                      //     flex: 3,
                                      //     child: Row(
                                      //       children: [
                                      //         CircleAvatar(
                                      //             foregroundImage:  NetworkImage(dataObjectScreen['company_id'] == null ? '' : 'http://${dataObjectScreen['company_id']['photo'].toString()}'),
                                      //             backgroundImage: const AssetImage('assets/comp.jpeg')),
                                      //         const SizedBox(width: 10.0),
                                      //         dataObjectScreen['company_id'] == null ? Text('') :
                                      //         Text('${dataObjectScreen['company_id']['name'] ?? ''}',
                                      //             style: const TextStyle(fontWeight: FontWeight.w400)),
                                      //       ],
                                      //     ),
                                      //   ),
                                      // const SizedBox(width: 10.0),

                                      ///Адрес
                                      // Expanded(
                                      //   flex: 3,
                                      //   child: Column(
                                      //     crossAxisAlignment:
                                      //     CrossAxisAlignment
                                      //         .start,
                                      //     children: [
                                      //       Text(dataObjectScreen['address'] ?? '',
                                      //           style: const TextStyle(
                                      //               fontWeight:
                                      //               FontWeight
                                      //                   .w400)),
                                      //     ],
                                      //   ),
                                      // ),
                                      // const SizedBox(width: 10.0),

                                      ///Участок
                                      if (size.width > 750)
                                        Expanded(
                                            flex: 2,
                                            child: dataObjectScreen['division_id'] != null
                                                ? Text(dataObjectScreen['division_id']['title'])
                                                : const Text('')),
                                      const SizedBox(width: 10.0),

                                      ///Тип
                                      if (size.width > 500)
                                        Container(
                                          width: 150.0,
                                          padding: const EdgeInsets.all(10.0),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(10),
                                            color: ColorApp.myColorGreen,
                                          ),
                                          child: Center(
                                              child: Text(
                                                dataObjectScreen['factory_model_id']['type_object_id']['name'] ?? '',
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.w500,
                                                    color: ColorApp.myColorWhite),
                                              )),
                                        ),

                                      ///Графики
                                      const SizedBox(width: 10.0),
                                      Expanded(
                                        flex: 3,
                                        child: Row(
                                          children: [
                                            Container(
                                              height: 20.0,
                                              width: 20.0,
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(5.0),
                                                color: ColorApp.myColorGreen,
                                              ),
                                            ),
                                            const SizedBox(width: 5.0),
                                            Container(
                                              height: 20.0,
                                              width: 20.0,
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(5.0),
                                                color: ColorApp.myColorGreen,
                                              ),
                                            ),
                                            const SizedBox(width: 5.0),
                                            Container(
                                              height: 20.0,
                                              width: 20.0,
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(5.0),
                                                color: ColorApp.myColorGreen,
                                              ),
                                            ),
                                            const SizedBox(width: 5.0),
                                            Container(
                                              height: 20.0,
                                              width: 20.0,
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(5.0),
                                                color: ColorApp.myColorGreen,
                                              ),
                                            ),
                                            const SizedBox(width: 5.0),
                                            Container(
                                              height: 20.0,
                                              width: 20.0,
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(5.0),
                                                color: ColorApp.myColorGreen,
                                              ),
                                            ),
                                            const SizedBox(width: 5.0),
                                            Container(
                                              height: 20.0,
                                              width: 20.0,
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(5.0),
                                                color: ColorApp.myColorGreen,
                                              ),
                                            ),
                                            const SizedBox(width: 5.0),
                                            Container(
                                              height: 20.0,
                                              width: 20.0,
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(5.0),
                                                color: ColorApp.myColorGreen,
                                              ),
                                            ),
                                            const SizedBox(width: 5.0),
                                            Container(
                                              height: 20.0,
                                              width: 20.0,
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(5.0),
                                                color: ColorApp.myColorGreen,
                                              ),
                                            ),
                                            const SizedBox(width: 5.0),
                                            Container(
                                              height: 20.0,
                                              width: 20.0,
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(5.0),
                                                color: ColorApp.myColorGreen,
                                              ),
                                            ),
                                            const SizedBox(width: 5.0),
                                            Container(
                                              height: 20.0,
                                              width: 20.0,
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(5.0),
                                                color: ColorApp.myColorGreen,
                                              ),
                                            ),
                                            const SizedBox(width: 5.0),
                                            Container(
                                              height: 20.0,
                                              width: 20.0,
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(5.0),
                                                color: ColorApp.myColorGreen,
                                              ),
                                            ),
                                            const SizedBox(width: 5.0),
                                            Container(
                                              height: 20.0,
                                              width: 20.0,
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(5.0),
                                                color: ColorApp.myColorGreen,
                                              ),
                                            ),
                                            const SizedBox(width: 5.0),
                                          ],
                                        ),
                                      ),
                                    ],
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
