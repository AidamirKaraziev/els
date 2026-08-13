import 'dart:convert';
import 'package:els/helper/api_config.dart';
import 'package:els/main.dart';
import 'package:els/screns/object/widgets/top_widget.dart';
import 'package:flutter/material.dart';
import '../../../helper/class_colors.dart';
import '../../../helper/header/header.dart';
import '../../../helper/my_drawer/my_drawer.dart';
import '../../../helper/my_map/my_map.dart';
import '../../../helper/my_user.dart';
import '../../home_page/home_page.dart';
import 'package:http/http.dart' as http;
import '../bloc/object_bloc.dart';
import '../widgets/add_object.dart';
import 'package:els/helper/api_client.dart';
import 'package:els/helper/api_image.dart';
import 'package:els/helper/empty_list.dart';

///ОБЬЕКТЫ

///Получение данных одного обьекта =======
Map listSelectedObject = {};
Map listSelectedObjectTOMon = {};
List getObject = [];
List getAllObject = [];
List dataObject = [];
List geolocationAllObjects = [];
List archiveDataObject = [];

int newScreensObject = 1;

//getAllListOfObjects
/// Список всех обьектов ========
///
/// Заполняет `getAllObject` — его читает карта (`helper/my_map/my_map.dart`).
/// Постраничный список для таблицы наливает `MyObjectBloc`.
///
/// Здесь НЕЛЬЗЯ вызывать `MyObjectBloc().add(ObjectGetEvent())`. Раньше вызов
/// стоял, и получалась бесконечная рекурсия: блок в конце `_getObject` зовёт
/// `getAllListOfObjects()`, а та звала блок обратно. Приложение молотило по
/// два запроса к `/all-objects/` без остановки и на каждом витке оставляло
/// незакрытый экземпляр блока. Связь оставлена односторонней: событие блока
/// обновляет оба списка, а эта функция — только свой.
getAllListOfObjects() async {
  final res = await Api.get(
      Uri.parse('${ApiConfig.base}/all-objects/'),
      headers: {
        "Content-Type": "application/json; charset=utf-8",
        'Accept': 'application/json',
      });
  var vova = jsonDecode(utf8.decode(res.bodyBytes));
  getAllObject = vova['data'];
  myStream.add(IntTest.indexScreens);
  // dataObject = getObject;
  // print(getAllObject.length);
  // print('${dataObject[0]['factory_model_id']['type_object_id']['name']}');
  // print('${dataObject[0]['factory_model_id']['type_object_id']['id']}');

}
/// =============================


/// Список обьектов архив ========
getListObjectArchive() async {
  final res = await Api.get(
      Uri.parse('${ApiConfig.base}/all-objects/?page=1'),
      headers: {
        "Content-Type": "application/json; charset=utf-8",
        'Accept': 'application/json',
      });
  var vova = jsonDecode(utf8.decode(res.bodyBytes));
  getObject = vova['data'];
  dataObject = getObject;
  //print(dataObject);
  // print('${dataObject[0]['factory_model_id']['type_object_id']['name']}');
  // print('${dataObject[0]['factory_model_id']['type_object_id']['id']}');

}
/// ==============================

/// Данные выбраного обьекта ============
getListObjectInfo(int userId) async {
  await Future(() async {
    final res = await Api.get(
        Uri.parse("${ApiConfig.base}/object/$userId/"),
        headers: {
          "Content-Type": "application/json; charset=utf-8",
        });
    var vova = jsonDecode(utf8.decode(res.bodyBytes));
    listSelectedObject = vova;
    print(listSelectedObject);
    // print(listSelectedObject['data']['letter_of_appointment']);
    // print(listSelectedObject['data']['act_pto']);
    // print(listSelectedObject['data']['name']);
    // print(listSelectedObject['data']['foreman_id']);
    // print(listSelectedObject['data']['mechanic_id']);
    // print(listSelectedObject['data']['foreman_id']['name']);
    // print(listSelectedObject['data']['mechanic_id']['id']);
    // print(listSelectedObject['data']['mechanic_id']['is_active']);
    //
    // print(listSelectedObject['data']['factory_model_id']['type_object_id']['title']);

  });
}
/// =====================================


class ObjectScreen extends StatefulWidget {
  const ObjectScreen({Key? key}) : super(key: key);

  @override
  State<ObjectScreen> createState() => _ObjectScreenState();
}

class _ObjectScreenState extends State<ObjectScreen> {

  /// Функция поиска по имени ======================
  void _runObjectFilter(String enteredKeyword) {
    List result = [];
    if (enteredKeyword.isEmpty) {
      result = getObject;
    } else {
      result = getObject
          .where((user) => myColorButtonObject == 1
          ? user['name'].toLowerCase().contains(enteredKeyword.toLowerCase())
          : myColorButtonObject == 2
          ? user['factory_number'].toLowerCase().contains(enteredKeyword.toLowerCase())
          : myColorButtonObject == 3
          ? user['company_id']['name'].toLowerCase().contains(enteredKeyword.toLowerCase())
          : myColorButtonObject == 4
          ? user['address'].toLowerCase().contains(enteredKeyword.toLowerCase())
          : myColorButtonObject == 5
          ? user['division_id']['title'].toLowerCase().contains(enteredKeyword.toLowerCase())
          : user['factory_model_id']['type_object_id']['name'].toLowerCase().contains(enteredKeyword.toLowerCase()))
          .toList();
    }
    setState(() {
      dataObject = result;
    });
  }
  /// ==============================================

  @override
  void initState() {
    myColorButtonObject = 1;
    MyObjectBloc().add(ObjectGetEvent());
    getAllListOfObjects();
    getListObjectArchive();
    // TODO: implement initState
    super.initState();
  }

  @override
  void dispose() {
    newScreensObject = 1;
    // TODO: implement dispose
    super.dispose();
  }

  bool openListSearchObject = false;
  bool test = true;
  bool archivedObject = false;

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return Scaffold(
      key: myOpenDrawer,
      drawer: const MyDrawer(),
      body: SafeArea(
        child: StreamBuilder(
            stream: myStream.stream,
            builder: (context, ind) =>  Container(
              color: ColorApp.myColorTransparent,
              child: Column(
                children: [
                  ///Header ========
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
                        if (size.width > 650)IconButton(
                            onPressed: () {
                              setState(() {
                                showDialog(
                                    context: context,
                                    builder: (context) => const AlertDialog(
                                      content: AddObject(),
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
                                IntTest.indexScreens = 19;
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
                                                  onPressed: () {},
                                                  icon: const Icon(Icons.search)),
                                              suffixIcon: IconButton(
                                                  onPressed: () {
                                                    setState(() {
                                                      dataObject = getObject;
                                                    });
                                                    openListSearchObject = false;
                                                    setState(() {});
                                                  },
                                                  icon: const Icon(Icons.close)),
                                              border: const OutlineInputBorder(),
                                              focusedBorder:
                                              const OutlineInputBorder(
                                                  borderSide: BorderSide(color: ColorApp.myColorGreenAuth)),
                                              labelText: myColorButtonObject == 1
                                                  ? 'Поиск по названию' : myColorButtonObject == 2
                                                  ? 'Поиск по заводскому номеру' : myColorButtonObject == 3
                                                  ? 'Поиск по компании' : myColorButtonObject == 4
                                                  ? 'Поиск по адресу' : myColorButtonObject == 5
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

                        /// Переключение страницы
                        if(test == true)
                          Row(
                            children: [
                              const SizedBox(width: 20.0),
                              IconButton(onPressed: (){
                                if(newScreensObject > 1) {
                                  --newScreensObject;
                                }
                                MyObjectBloc().add(ObjectGetEvent());
                                setState(() {});
                              }, icon: const Icon(Icons.arrow_circle_left_outlined, color: Color(0xffBADE89))),
                              const SizedBox(width: 10.0),
                              Text('$newScreensObject'),
                              const SizedBox(width: 10.0),
                              IconButton(onPressed: (){
                                if(dataObject.isNotEmpty)
                                newScreensObject++;
                                MyObjectBloc().add(ObjectGetEvent());
                                setState(() {});
                              }, icon: const Icon(Icons.arrow_circle_right_outlined, color: Color(0xffBADE89))),
                            ],
                          ),

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
                        const MyUser(),
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
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5.0)),
                            foregroundColor: test == true ? Colors.white : Colors.black, backgroundColor: test == true
                                ? const Color(0xffBADE89)
                                : Colors.white,
                          ),
                          onPressed: () {
                            test = true;
                            setState(() {});
                          },
                          child: const Text('Список'),
                        ),

                        ///Кнопка Карта
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5.0)),
                            foregroundColor: test == false ? Colors.white : Colors.black, backgroundColor: test == false
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
                  /// Окно список
                      ? Expanded(
                    child: Column(
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(20.0),
                          child: TopWidgetObject(),
                        ),
                        Expanded(
                            child: dataObject.every((o) => o['is_actual'] == false)
                                ? const EmptyList(
                                    title: 'Объектов нет',
                                    hint: 'Здесь показываются действующие '
                                        'объекты. Архивные — по кнопке архива '
                                        'в шапке.',
                                  )
                                : ListView.builder(
                                itemCount: dataObject.length,
                                itemBuilder: (context, index) {
                                  dataObject.sort((a, b) => a['name'].compareTo(b['name']));
                                  final  dataObjectScreen = dataObject[index];
                                  return dataObjectScreen['is_actual'] == false
                                      ? Container()
                                      : Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                                    child: Card(
                                      child: GestureDetector(
                                        onTap: () async {
                                          IntTest.indexObjectList = index;
                                          IntTest.pressHover = dataObjectScreen['id'];
                                          await getListObjectInfo(IntTest.pressHover);
                                          myStream.add(IntTest.indexScreens);
                                          IntTest.indexScreens = 10;
                                          setState(() {});
                                        },
                                        child: Container(
                                          decoration: dataObjectScreen['mechanic_id'] == null || dataObjectScreen['foreman_id'] == null
                                              ? BoxDecoration(
                                            borderRadius: BorderRadius.circular(5.0),
                                            color: Colors.red[200])
                                              : BoxDecoration(
                                              borderRadius: BorderRadius.circular(5.0),
                                              color: dataObjectScreen['mechanic_id']['is_active'] == false || dataObjectScreen['mechanic_id'] == null
                                                  || dataObjectScreen['foreman_id']['is_active'] == false
                                                  ? Colors.red[200] : ColorApp.myColorWhite),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                ///Название
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
                                                if (size.width > 1150)Expanded(
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
                                                if (size.width > 990)
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
                                                if (size.width > 650)
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
                                                if (size.width > 850)
                                                  Expanded(
                                                      flex: 3,
                                                      child: dataObjectScreen['division_id'] != null ? Text('${dataObjectScreen['division_id']['title']}') : const Text('')),
                                                const SizedBox(width: 10.0),

                                                ///Тип
                                                if (size.width > 450)
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
