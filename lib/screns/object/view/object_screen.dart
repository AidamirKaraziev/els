import 'dart:convert';
import 'package:els/helper/class_colors.dart';
import 'package:els/main.dart';
import 'package:els/screns/object/widgets/top_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../helper/my_map/my_map.dart';
import '../../home_page/home_page.dart';
import 'package:http/http.dart' as http;

import '../bloc/object_bloc.dart';

///ОБЬЕКТЫ


///Получение данных одного обьекта =======
Map listSelectedObject = {};
getListObjectInfo(int userId) async {
  await Future(() async {
    final res = await http.get(
        Uri.parse("http://${IntTest.myIp}/api/v1/object/$userId/"),
        headers: {
          "Content-Type": "application/json; charset=utf-8",
          'Authorization': 'Bearer ${IntTest.token}',
        });
    var vova = jsonDecode(utf8.decode(res.bodyBytes));
    listSelectedObject = vova;
    print('Данные выбраного обьекта ${listSelectedObject['data']}');
  });
}
/// ======================================

class ObjectScreen extends StatefulWidget {
  const ObjectScreen({Key? key}) : super(key: key);

  @override
  State<ObjectScreen> createState() => _ObjectScreenState();
}

bool test = true;

class _ObjectScreenState extends State<ObjectScreen> {
  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return Scaffold(
      body: SafeArea(
        child: Container(
          color: ColorApp.myColorTransparent,
          child: Column(
            children: [
              ///Кнопки Список Карта
              Padding(
                padding: const EdgeInsets.only(top: 20.0, right: 20.0),
                child: Row(
                  children: [
                    const Spacer(),

                    ///Кнопка Список
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        onPrimary: test == true ? Colors.white : Colors.black,
                        primary: test == true
                            ? const Color(0xffBADE89)
                            : Colors.white,
                      ),
                      onPressed: () {
                        test = true;
                        print(test);
                        setState(() {});
                      },
                      child: const Text('Список'),
                    ),

                    ///Кнопка Карта
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        onPrimary: test == false ? Colors.white : Colors.black,
                        primary: test == false
                            ? ColorApp.myColorGreen
                            : Colors.white,
                      ),
                      onPressed: () async {
                        const MyApp();
                        MyObjectBloc().add(ObjectGetEvent());
                        test = false;
                        setState(() {});
                      },
                      child: const Text('Карта'),
                    ),
                  ],
                ),
              ),
              test == true
                  ? Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          const TopWidgetObject(),
                          const SizedBox(height: 20.0),
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.65,
                            child: BlocBuilder<MyObjectBloc, MyObjectState>(
                              builder: (context, state) {
                                final listObject = state.modelObjectList;
                                return ListView.builder(
                                    controller: ScrollController(),
                                    itemCount: listObject.length,
                                    itemBuilder: (context, index) =>
                                        GestureDetector(
                                          onTap: () {
                                            IntTest.pressHover = listObject[index]['id'];
                                            getListObjectInfo(IntTest.pressHover);
                                            pointsMapController.add(IntTest.indexScreens);
                                            IntTest.indexScreens = 11;
                                            print(IntTest.pressHover);
                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: 10.0),
                                            child: Container(
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(5.0),
                                                color: ColorApp.myColorWhite,
                                              ),
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 20.0,
                                                        vertical: 10.0),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    ///Компания
                                                    if (size.width > 1150)
                                                      Expanded(
                                                        child: Container(
                                                          height: 60,
                                                          decoration: BoxDecoration(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          10),
                                                              color: ColorApp
                                                                  .myColorGrayShadow),
                                                          child: Row(
                                                            children: [
                                                              const Padding(
                                                                padding: EdgeInsets
                                                                    .symmetric(
                                                                        horizontal:
                                                                            10.0),
                                                                child:
                                                                    CircleAvatar(
                                                                  foregroundImage:
                                                                      NetworkImage(
                                                                          'http:'),
                                                                  backgroundImage:
                                                                      AssetImage(
                                                                          'assets/user.png'),
                                                                ),
                                                              ),
                                                              Expanded(
                                                                child: Text(listObject[index]['company_id']['name']),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    const SizedBox(width: 10.0),

                                                    ///Организация
                                                    if (size.width > 900)
                                                      Expanded(
                                                        child: Container(
                                                          height: 60,
                                                          // padding: const EdgeInsets.all(10.0),
                                                          decoration:
                                                              BoxDecoration(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        10),
                                                            color: ColorApp
                                                                .myColorGrayShadow,
                                                          ),
                                                          child: Row(
                                                            children: [
                                                              Padding(
                                                                padding: const EdgeInsets
                                                                    .symmetric(
                                                                        horizontal:
                                                                            10.0),
                                                                child:
                                                                    CircleAvatar(
                                                                  foregroundImage:
                                                                      NetworkImage(
                                                                    'http//${listObject[index]['photo']}',
                                                                  ),
                                                                  backgroundImage:
                                                                      const AssetImage(
                                                                          'assets/user.png'),
                                                                  // child: Text('${state.listGetEmployee[index]['name'][0]}',style: const TextStyle(color: ColorApp.myColorWhite,fontWeight: FontWeight.w600,fontSize: 20.0)),
                                                                ),
                                                              ),
                                                              Expanded(
                                                                child: Text(
                                                                    listObject[index]['organization_id']['title']),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    const SizedBox(width: 10.0),

                                                    ///Адрес
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(listObject[index]['address'],
                                                              style: const TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w400)),
                                                        ],
                                                      ),
                                                    ),
                                                    const SizedBox(width: 10.0),

                                                    ///Участок
                                                    if (size.width > 750)
                                                      const Expanded(
                                                          child: Text(
                                                              'ООО “Гармония”')),
                                                    const SizedBox(width: 10.0),

                                                    ///Прораб
                                                    if (size.width > 500)
                                                      Expanded(
                                                        child: Container(
                                                          height: 60,
                                                          // padding: const EdgeInsets.all(10.0),
                                                          decoration:
                                                              BoxDecoration(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        10),
                                                            color: ColorApp
                                                                .myColorGrayShadow,
                                                          ),
                                                          child: Row(
                                                            children: [
                                                              const Padding(
                                                                padding: EdgeInsets
                                                                    .symmetric(
                                                                        horizontal:
                                                                            10.0),
                                                                child:
                                                                    CircleAvatar(
                                                                  foregroundImage:
                                                                      NetworkImage(
                                                                          'http://'
                                                                          ']}'),
                                                                  backgroundImage:
                                                                      AssetImage(
                                                                          'assets/user.png'),
                                                                  // child: Text('${state.listGetEmployee[index]['name'][0]}',style: const TextStyle(color: ColorApp.myColorWhite,fontWeight: FontWeight.w600,fontSize: 20.0)),
                                                                ),
                                                              ),
                                                              const Expanded(
                                                                child: Text(
                                                                    'text'),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    const SizedBox(width: 10.0),

                                                    ///Тип
                                                    if (size.width > 500)
                                                      Expanded(
                                                        child: Container(
                                                          padding:
                                                              const EdgeInsets
                                                                  .all(10.0),
                                                          decoration:
                                                              BoxDecoration(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        10),
                                                            color: ColorApp
                                                                .myColorGreen,
                                                          ),
                                                          child: const Center(
                                                              child: Text(
                                                            'Type',
                                                            style: TextStyle(
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                                color: ColorApp
                                                                    .myColorWhite),
                                                          )),
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ));
                              },
                            ),
                          ),
                        ],
                      ),
                    )

                  /// Окно карта ===
                  : Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width,
                        height: MediaQuery.of(context).size.height * 0.7,
                        child: const MyMap(),
                      ),
                    ),

              /// ===============
            ],
          ),
        ),
      ),
    );
  }
}
