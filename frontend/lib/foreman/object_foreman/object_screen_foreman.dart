import 'dart:convert';
import 'package:els/helper/api_config.dart';
import 'package:els/foreman/object_foreman/widgets_object_foreman/add_object_foreman.dart';
import 'package:els/main.dart';
import 'package:els/screns/object/widgets/top_widget.dart';
import 'package:flutter/material.dart';
import '../../../helper/class_colors.dart';
import '../../../helper/header/header.dart';
import '../../../helper/my_map/my_map.dart';
import '../../../helper/my_user.dart';
import 'package:http/http.dart' as http;
import '../../screns/home_page/home_page.dart';
import '../../screns/user/user_contact.dart';
import '../drawer_foreman.dart';
import '../user_page_foreman.dart';
import 'package:els/helper/api_client.dart';
import 'package:els/helper/api_image.dart';

///ОБЬЕКТЫ

///Получение данных одного обьекта =======
List getObjectForeman = [];
List dataObjectForeman = [];
Map listSelectedObjectForeman = {};
List archiveDataObjectForeman = [];

/// Список обьектов прораба ======
getListObjectForeman() async {
  final res = await Api.get(
      Uri.parse('${ApiConfig.base}/object/by-foreman/?foreman_id=${userProfile[0]['id']}&page=1'),
      headers: {
        "Content-Type": "application/json; charset=utf-8",
        'Accept': 'application/json',
      });
  var vova = jsonDecode(utf8.decode(res.bodyBytes));
  getObjectForeman = vova['data'];
  dataObjectForeman = getObjectForeman;
  myStream.add(IntTest.indexScreensForeman);
}
/// ==============================

/// Данные выбраного обьекта прораба ===========
getListObjectInfoForeman(int userId) async {
  await Future(() async {
    final res = await Api.get(
        Uri.parse("${ApiConfig.base}/object/$userId/"),
        headers: {
          "Content-Type": "application/json; charset=utf-8",
        });
    var vova = jsonDecode(utf8.decode(res.bodyBytes));
    listSelectedObjectForeman = vova;
    // print(' id =>>${listSelectedObjectForeman['data']['contact_person_id']['id']} name =>> ${listSelectedObjectForeman['data']['contact_person_id']['name']}');
  });
}
/// ============================================

class ObjectScreenForeman extends StatefulWidget {
  const ObjectScreenForeman({Key? key}) : super(key: key);

  @override
  State<ObjectScreenForeman> createState() => _ObjectScreenForemanState();
}

class _ObjectScreenForemanState extends State<ObjectScreenForeman> {

  /// Функция поиска по имени ========================
  void _runObjectFilter(String enteredKeyword) {
    List result = [];
    if (enteredKeyword.isEmpty) {
      result = getObjectForeman;
    } else {
      result = getObjectForeman
          .where((user) =>
          user['name'].toLowerCase().contains(enteredKeyword.toLowerCase()))
          .toList();
    }
    setState(() {
      dataObjectForeman = result;
    });
    print('Сработала функция');
  }
  /// ================================================

  @override
  void initState() {
    getListObjectForeman();
    dataObjectForeman = getObjectForeman;
    // TODO: implement initState
    super.initState();
  }

  bool openListSearchObject = false;
  bool test = true;
  bool archivedObject = false;

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return Scaffold(
      key: myOpenDrawer,
      drawer: const DrawerForeman(),
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
                        if(archivedObject != false)
                          Row(
                            children: [
                              Container(
                                width: 32.0,
                                height: 32.0,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(5.0),
                                  border: Border.all(
                                      color: ColorApp.myColorGrayBorder,
                                      width: 1),
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
                                        archivedObject =! archivedObject;
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
                        ///Text
                        Text('Обьекты',
                            style: TextStyle(
                                fontSize: size.width > 350 ? 25.0 : 18.0,
                                fontWeight: size.width > 350
                                    ? FontWeight.w700
                                    : FontWeight.w500)),
                        const SizedBox(width: 10.0),

                        ///Добавить Обьект
                        IconButton(
                            onPressed: () {
                              setState(() {
                                showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      content: AddObjectForeman(),
                                    ));
                              });
                            },
                            icon: const Icon(Icons.add_box_rounded,
                                size: 25.0,
                                color: ColorApp.myColorGreenAuth)),

                        /// Кнопка архив
                        if (test == true)
                          IconButton(
                              onPressed: () {
                                IntTest.indexScreensForeman = 12;
                                myStream.add(IntTest.indexScreens);
                                setState(() {});
                              },
                              icon: Icon(
                                  Icons.archive_outlined,
                                  size: 25.0,
                                  color: archivedObject == true ? ColorApp.myColorGreenAuth : ColorApp.myColorGray)),

                        ///Поиск Обьекта
                        if(test == true)
                          Row(
                            children: [
                              if (size.width > 500)
                                Row(
                                  children: [
                                    if (openListSearchObject == false)
                                      IconButton(
                                          onPressed: () {
                                            openListSearchObject = true;
                                            setState(() {});
                                          },
                                          icon: const Icon(Icons.search,
                                              size: 25.0,
                                              color: ColorApp.myColorGray)),
                                  ],
                                ),
                              if (openListSearchObject)
                                Row(
                                  children: [
                                    SizedBox(
                                      width:
                                      MediaQuery.of(context).size.width * 0.3,
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
                                                    dataObjectForeman = getObjectForeman;
                                                  },
                                                  icon: const Icon(Icons.search)),
                                              suffixIcon: IconButton(
                                                  onPressed: () {
                                                    setState(() {
                                                      dataObjectForeman = getObjectForeman;
                                                    });
                                                    openListSearchObject = false;
                                                    setState(() {});
                                                  },
                                                  icon: const Icon(Icons.close)),
                                              border: const OutlineInputBorder(),
                                              focusedBorder:
                                              const OutlineInputBorder(
                                                  borderSide: BorderSide(
                                                      color: ColorApp
                                                          .myColorGreenAuth)),
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
                  /// ==============
                  ///Кнопки Список Карта
                  Padding(
                    padding: const EdgeInsets.only(top: 20.0, right: 20.0),
                    child: Row(
                      children: [
                        const Spacer(),
                        ///Кнопка Список
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            foregroundColor: test == true ? Colors.white : Colors.black, backgroundColor: test == true
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
                            foregroundColor: test == false ? Colors.white : Colors.black, backgroundColor: test == false
                                ? ColorApp.myColorGreen
                                : Colors.white,
                          ),
                          onPressed: () async {
                            const MyApp();
                            /// MyObjectBloc().add(ObjectGetEvent());
                            test = false;
                            setState(() {});
                          },
                          child: const Text('Карта'),
                        ),
                      ],
                    ),
                  ),
                  test == true
                  /// Окно список
                      ? Expanded(
                    child: Column(
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(20.0),
                          child: TopWidgetObject(),
                        ),
                        Expanded(
                            child:ListView.builder(
                                itemCount: dataObjectForeman.length,
                                itemBuilder: (context, index) {
                                  final dataObjectScreen = dataObjectForeman[index];
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
                                          await getListObjectInfoForeman(IntTest.pressHover);
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
                  )
                  /// Окно карта
                      : const Expanded(child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: MyMap(),
                  )),
                ],
              ),
            )),
      ),
    );
  }
}
