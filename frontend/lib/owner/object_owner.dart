import 'dart:convert';
import 'package:els/helper/api_config.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import '../helper/class_colors.dart';
import '../helper/header/header.dart';
import '../screns/employee/widgets/topButton.dart';
import '../screns/home_page/home_page.dart';

import '../screns/user/user_contact.dart';
import 'drawer_owner.dart';
import 'package:els/helper/api_client.dart';
import 'package:els/helper/api_image.dart';


///Получение данных одного обьекта =======
List getObjectOwner = [];
List dataObjectOwner = [];
Map listSelectedObjectOwner = {};
List archiveDataObjectOwner = [];
int myColorButtonObjectOwner = 1;

/// Список обьектов прораба ======
getListObjectOwner() async {
  final res = await Api.get(
      Uri.parse('${ApiConfig.base}/object/by-foreman/?foreman_id=${userProfile[0]['id']}&page=1'),
      headers: {
        "Content-Type": "application/json; charset=utf-8",
        'Accept': 'application/json',
      });
  var vova = jsonDecode(utf8.decode(res.bodyBytes));
  getObjectOwner = vova['data'];
  dataObjectOwner = getObjectOwner;
  myStream.add(IntTest.indexScreensForeman);
}
/// ==============================

/// Данные выбраного обьекта прораба ===========
getListObjectInfoOwner(int userId) async {
  await Future(() async {
    final res = await Api.get(
        Uri.parse("${ApiConfig.base}/object/$userId/"),
        headers: {
          "Content-Type": "application/json; charset=utf-8",
        });
    var vova = jsonDecode(utf8.decode(res.bodyBytes));
    listSelectedObjectOwner = vova;
    // print(' id =>>${listSelectedObjectForeman['data']['contact_person_id']['id']} name =>> ${listSelectedObjectForeman['data']['contact_person_id']['name']}');
  });
}
/// ============================================


class ObjectScreenOwner extends StatefulWidget {
  const ObjectScreenOwner({Key? key}) : super(key: key);

  @override
  State<ObjectScreenOwner> createState() => _ObjectScreenForemanState();
}

class _ObjectScreenForemanState extends State<ObjectScreenOwner> {

  /// Функция поиска по имени ========================
  void _runObjectFilter(String enteredKeyword) {
    List result = [];
    if (enteredKeyword.isEmpty) {
      result = getObjectOwner;
    } else {
      result = getObjectOwner
          .where((user) =>
          user['name'].toLowerCase().contains(enteredKeyword.toLowerCase()))
          .toList();
    }
    setState(() {
      dataObjectOwner = result;
    });
    print('Сработала функция');
  }
  /// ================================================

  @override
  void initState() {
    // getListObjectOwner();
    // dataObjectOwner = getObjectOwner;
    // TODO: implement initState
    super.initState();
  }

  bool openListSearchOwner = false;


  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return Scaffold(
      key: myOpenDrawer,
      drawer: const DrawerOwner(),
      body: SafeArea(
        child: StreamBuilder(
            stream: myStream.stream,
            builder: (context, ind) =>  Container(
              color: ColorApp.myColorTransparent,
              child: Column(
                children: [
                  ///Header ========
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: ColorApp.kPadding),
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
                        /// Кнопка Назад
                        // if(archivedObject != false)
                        //   Row(
                        //     children: [
                        //       Container(
                        //         width: 32.0,
                        //         height: 32.0,
                        //         decoration: BoxDecoration(
                        //           borderRadius: BorderRadius.circular(5.0),
                        //           border: Border.all(
                        //               color: ColorApp.myColorGrayBorder,
                        //               width: 1),
                        //           color: Colors.white,
                        //           boxShadow: const [
                        //             BoxShadow(
                        //               color: ColorApp.myColorAvatar,
                        //               blurRadius: 5,
                        //             ),
                        //           ],
                        //         ),
                        //         child: IconButton(
                        //             onPressed: () {
                        //               setState(() {
                        //                 archivedObject =! archivedObject;
                        //                 myStream.add(IntTest.indexScreens);
                        //               });
                        //             },
                        //             icon: const Icon(
                        //               Icons.arrow_back_ios_new_rounded,
                        //               color: Colors.black,
                        //               size: 13.0,
                        //             )),
                        //       ),
                        //       const SizedBox(width: 30.0),
                        //     ],
                        //   ),
                        ///Text
                        Text('Обьекты',
                            style: TextStyle(
                                fontSize: size.width > 350 ? 25.0 : 18.0,
                                fontWeight: size.width > 350
                                    ? FontWeight.w700
                                    : FontWeight.w500)),
                        const SizedBox(width: 20.0),

                        ///Поиск Обьекта
                        Row(
                            children: [
                              if (size.width > 500)
                                Row(
                                  children: [
                                    if (openListSearchOwner == false)
                                      IconButton(
                                          onPressed: () {
                                            openListSearchOwner = true;
                                            setState(() {});
                                          },
                                          icon: const Icon(Icons.search,
                                              size: 25.0,
                                              color: ColorApp.myColorGray)),
                                  ],
                                ),
                              if (openListSearchOwner)
                                Row(
                                  children: [
                                    SizedBox(
                                      width:
                                      MediaQuery.of(context).size.width * 0.5,
                                      height: 40.0,
                                      child: Form(
                                        child: TextField(
                                          onChanged: (value) => _runObjectFilter(value),
                                          cursorColor: ColorApp.myColorGray,
                                          decoration: InputDecoration(
                                              contentPadding:
                                              const EdgeInsets.all(0.0),
                                              prefixIcon: IconButton(
                                                  onPressed: () {
                                                    dataObjectOwner = getObjectOwner;
                                                  },
                                                  icon: const Icon(Icons.search)),
                                              suffixIcon: IconButton(
                                                  onPressed: () {
                                                    setState(() {
                                                      dataObjectOwner = getObjectOwner;
                                                    });
                                                    openListSearchOwner = false;
                                                    setState(() {});
                                                  },
                                                  icon: const Icon(Icons.close)),
                                              border: const OutlineInputBorder(),
                                              focusedBorder:
                                              const OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                      color: ColorApp
                                                          .myColorGreenAuth)),
                                              labelText: myColorButtonObjectOwner == 1
                                                  ? 'Поиск по названию' : myColorButtonObjectOwner == 2
                                                  ? 'Поиск по заводскому номеру' : myColorButtonObjectOwner == 3
                                                  ? 'Поиск по компании' : myColorButtonObjectOwner == 4
                                                  ? 'Поиск по адресу' : myColorButtonObjectOwner == 5
                                                  ? 'Поиск по участку' : 'Поиск по типу',
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

                        ///Аватар Юзера
                        // const MyUserOwner(),
                      ],
                    ),
                  ),

                  Expanded(
                    child: Column(
                      children: [
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
                                Expanded(
                                    flex: 3,
                                    child: Row(
                                      children: [
                                        TopButtonWidget(
                                          text: 'Название',
                                          press: () {
                                            myColorButtonObjectOwner = 1;
                                            myStream.add(IntTest.indexScreens);
                                            setState(() {});
                                          },
                                          pressIcon: () {},
                                          colorButton: myColorButtonObjectOwner == 1 ? ColorApp.myColorGreen : ColorApp.myColorWhite,
                                          colorText: myColorButtonObjectOwner == 1 ? Colors.white :  ColorApp.myColorBlack,
                                        ),
                                      ],
                                    )),
                                ///Заводской номер
                                if (size.width > 1150)  Expanded(
                                    flex: 3,
                                    child: Row(
                                      children: [
                                        TopButtonWidget(
                                          text: 'Заводской номер',
                                          press: () {
                                            myColorButtonObjectOwner = 2;
                                            myStream.add(IntTest.indexScreens);
                                            setState(() {});
                                          },
                                          pressIcon: () {},
                                          colorButton: myColorButtonObjectOwner == 2 ? ColorApp.myColorGreen : ColorApp.myColorWhite,
                                          colorText: myColorButtonObjectOwner == 2 ? Colors.white :  ColorApp.myColorBlack,
                                        ),
                                      ],
                                    )),
                                ///Компания
                                if (size.width >= 990) Expanded(
                                    flex: 3,
                                    child: Row(
                                      children: [
                                        TopButtonWidget(
                                          text: 'Компания',
                                          press: () {
                                            myColorButtonObjectOwner = 3;
                                            myStream.add(IntTest.indexScreens);
                                            setState(() {});
                                          },
                                          pressIcon: () {},
                                          colorButton: myColorButtonObjectOwner == 3 ? ColorApp.myColorGreen : ColorApp.myColorWhite,
                                          colorText: myColorButtonObjectOwner == 3 ? Colors.white :  ColorApp.myColorBlack,
                                        ),
                                      ],
                                    )),
                                ///Адресс
                                if (size.width > 650)
                                  Expanded(
                                      flex: 3,
                                      child: Row(
                                        children: [
                                          TopButtonWidget(
                                            text: 'Адресс',
                                            press: () {
                                              myColorButtonObjectOwner = 4;
                                              myStream.add(IntTest.indexScreens);
                                              setState(() {});
                                            },
                                            pressIcon: () {},
                                            colorButton: myColorButtonObjectOwner == 4 ? ColorApp.myColorGreen : ColorApp.myColorWhite,
                                            colorText: myColorButtonObjectOwner == 4 ? Colors.white :  ColorApp.myColorBlack,
                                          ),
                                        ],
                                      )),
                                ///Участок
                                if (size.width > 850) Expanded(
                                    flex: 3,
                                    child: Row(
                                      children: [
                                        TopButtonWidget(
                                          text: 'Участок',
                                          press: () {
                                            myColorButtonObjectOwner = 5;
                                            myStream.add(IntTest.indexScreens);
                                            setState(() {});
                                          },
                                          pressIcon: () {},
                                          colorButton: myColorButtonObjectOwner == 5 ? ColorApp.myColorGreen : ColorApp.myColorWhite,
                                          colorText: myColorButtonObjectOwner == 5 ? Colors.white :  ColorApp.myColorBlack,
                                        ),
                                      ],
                                    )),
                                ///Тип
                                if (size.width > 450)  Expanded(
                                    flex: 2,
                                    child: Row(
                                      children: [
                                        TopButtonWidget(text: 'Тип',
                                          press: () {
                                            myColorButtonObjectOwner = 6;
                                            myStream.add(IntTest.indexScreens);
                                            setState(() {});
                                          },
                                          pressIcon: () {},
                                          colorButton: myColorButtonObjectOwner == 6 ? ColorApp.myColorGreen : ColorApp.myColorWhite,
                                          colorText: myColorButtonObjectOwner == 6 ? Colors.white :  ColorApp.myColorBlack,
                                        ),
                                      ],
                                    )),
                              ],
                            ),
                          ),
                        ),
                        Expanded(
                            child:ListView.builder(
                                itemCount: dataObjectOwner.length,
                                itemBuilder: (context, index) {
                                  final dataObjectScreen = dataObjectOwner[index];
                                  return dataObjectScreen['is_actual'] == false
                                      ? Container()
                                      : Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                                    child: Card(
                                      // key: ValueKey(dataObjectScreen['id']),
                                      child: GestureDetector(
                                        onTap: () async {
                                          IntTest.indexObjectList = index;
                                          IntTest.pressHover = dataObjectScreen['id'];
                                          await getListObjectInfoOwner(IntTest.pressHover);
                                          myStream.add(IntTest.indexScreensForeman);
                                          IntTest.indexScreensForeman = 8;
                                          setState(() {});
                                        },
                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(5.0),
                                            color: ColorApp.myColorWhite,
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                ///Название
                                                if (size.width > 1150)
                                                  Expanded(
                                                    flex: 3,
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(dataObjectScreen['name'] ?? '',
                                                            style: const TextStyle(
                                                                fontWeight:
                                                                FontWeight
                                                                    .w400)),
                                                      ],
                                                    ),
                                                  ),
                                                const SizedBox(width: 10.0),

                                                ///Заводской номер
                                                if (size.width > 900)
                                                  Expanded(
                                                    flex: 3,
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text('${dataObjectScreen['factory_number']}' ?? '',
                                                            style: const TextStyle(fontWeight: FontWeight.w400)),
                                                      ],
                                                    ),
                                                  ),
                                                const SizedBox(width: 10.0),

                                                ///Компания
                                                if (size.width > 500)
                                                  Expanded(
                                                    flex: 3,
                                                    child: Row(
                                                      children: [
                                                        CircleAvatar(
                                                            foregroundImage:  apiImage(dataObjectScreen['company_id']['photo'].toString()),
                                                            backgroundImage: const AssetImage('assets/comp.jpeg')),
                                                        const SizedBox(width: 10.0),
                                                        dataObjectScreen['company_id'] == null ? const Text('') :
                                                        Expanded(
                                                          child: Text('${dataObjectScreen['company_id']['name'] ?? ''}',
                                                              style: const TextStyle(fontWeight: FontWeight.w400)),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                const SizedBox(width: 10.0),

                                                ///Адрес
                                                Expanded(
                                                  flex: 3,
                                                  child: Column(
                                                    crossAxisAlignment:
                                                    CrossAxisAlignment
                                                        .start,
                                                    children: [
                                                      Text(dataObjectScreen['address'] ?? '',
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
                                                  Expanded(
                                                      flex: 3,
                                                      child: dataObjectScreen['division_id'] != null ? Text('${dataObjectScreen['division_id']['title']}') : const Text('')),
                                                const SizedBox(width: 10.0),

                                                ///Тип
                                                if (size.width > 500)
                                                  Expanded(
                                                    flex: 2,
                                                    child: Container(
                                                      padding:
                                                      const EdgeInsets.all(
                                                          10.0),
                                                      decoration: BoxDecoration(
                                                        borderRadius:
                                                        BorderRadius
                                                            .circular(10),
                                                        color: ColorApp
                                                            .myColorGreen,
                                                      ),
                                                      child: Center(
                                                          child: Text(dataObjectScreen['factory_model_id']['type_object_id']['name'] ?? '',
                                                            style: const TextStyle(
                                                                fontWeight:
                                                                FontWeight.w500,
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
                                    ),
                                  );
                                })),
                        const SizedBox(height: 20.0),
                      ],
                    ),
                  ),
                ],
              ),
            )),
      ),
    );
  }
}