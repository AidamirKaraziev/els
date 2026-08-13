import 'dart:async';
import 'package:els/helper/api_config.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../../foreman/task_foreman/task_screen_foreman.dart';
import '../../helper/class_colors.dart';
import '../../screns/companies/view/companies_screen.dart';
import '../../screns/employee/widgets/add_employee.dart';
import '../../screns/employee/widgets/topButton.dart';
import '../../screns/home_page/home_page.dart';
import '../../widgets_create/organization_greate.dart';
import '../user_page_dispatcher.dart';
import '../widgets/add_application.dart';
import 'package:els/helper/api_client.dart';
import 'package:els/helper/empty_list.dart';

/// Домашняя диспетчера

/// Список созданых заявок ===
getListApplication() async {
  final res = await Api.get(Uri.parse('${ApiConfig.base}/order/my'), headers: {
    "Content-Type": "application/json; charset=utf-8",
    'Accept': 'application/json',
  });
  var madeApplication = jsonDecode(utf8.decode(res.bodyBytes));
  getApplication = madeApplication['data'];
  dataApplication = getApplication;
  myStream.add(IntTest.indexScreens);
}

List getApplication = [];

List dataApplication = [];
/// ==========================

///Получение данных выбраной задачи ==========
getListApplicationInfo(int userId) async {
  await Future(() async {
    final res = await Api.get(
        Uri.parse("${ApiConfig.base}/order/$userId/"),
        headers: {
          "Content-Type": "application/json; charset=utf-8",
        });
    var vova = jsonDecode(utf8.decode(res.bodyBytes));
    listSelectedApplicationId = vova;
    getPhotoSelectedTaskInfoForeman(listSelectedApplicationId['data']['id']);
  });
}
/// ==========================================

Map listSelectedApplicationId = {};

int myColorButtonApplication = 1;

class ApplicationScreen extends StatefulWidget {
  const ApplicationScreen({Key? key}) : super(key: key);

  @override
  State<ApplicationScreen> createState() => _ApplicationScreenState();
}

class _ApplicationScreenState extends State<ApplicationScreen> {


  /// Функция поиска по заявке ==========================
  void _runApplicationFilter(String enteredKeyword) {
    List result = [];
    if (enteredKeyword.isEmpty) {
      result = getApplication;
    } else {
      result = getApplication
          .where((user) => myColorButtonApplication == 1
          ? user['object_id']['name'].toLowerCase().contains(enteredKeyword.toLowerCase())
          : myColorButtonApplication == 2
          ? user['created_at'].toLowerCase().contains(enteredKeyword.toLowerCase())
          : myColorButtonApplication == 3
          ? user['task_text'].toLowerCase().contains(enteredKeyword.toLowerCase())
          : myColorButtonApplication == 4
          ? user['creator_id']['name'].toLowerCase().contains(enteredKeyword.toLowerCase())
          : myColorButtonApplication == 5
          ? user['executor_id']['name'].toLowerCase().contains(enteredKeyword.toLowerCase())
          : user['status_id']['name'].toLowerCase().contains(enteredKeyword.toLowerCase()))
          .toList();
    }
    setState(() {
      dataApplication = result;
    });
  }
  /// ===================================================


  Timer? _timer;

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 3), (Timer timer) {
      getListApplication();
    });
  }


  /// ФИО
  TextEditingController fio = TextEditingController();

  bool completedTask = false;
  bool openListSearch = false;

  @override
  void initState() {
    // _startTimer();
    getListApplication();


    // TODO: implement initState
    super.initState();
  }

  @override
  void dispose() {
    myColorButtonApplication = 1;
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {



    final Size size = MediaQuery.of(context).size;
    return StreamBuilder(
      stream: myStream.stream,
      builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
        return Scaffold(
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
                    /// Текст Мои заявки
                    const Text('Мои заявки',
                        style: TextStyle(
                            fontSize: 20.0,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(width: 10.0),
                    ///Добавить Заявку
                    if (completedTask != true)
                      IconButton(
                          onPressed: () async {
                            setState(() {
                              showDialog(
                                  context: context,
                                  builder: (context) => const AlertDialog(
                                        content: AddApplication(),
                                      )).then((value) => setState(() {}));
                            });
                          },
                          icon: const Icon(Icons.add_box_rounded,
                              size: 25.0, color: ColorApp.myColorGreenAuth)),
                    // const SizedBox(width: 10.0),

                    /// Обновить страницу
                    IconButton(
                        onPressed: () async {
                          getListApplication();
                        },
                        icon: const Icon(Icons.change_circle_outlined,
                            size: 25.0, color: ColorApp.myColorGreenAuth)),
                    // const SizedBox(width: 10.0),

                    ///Поиск задачи
                    if (size.width > 500)
                      Row(
                        children: [
                          if (openListSearch == false)
                            IconButton(
                                onPressed: () {
                                  openListSearch = true;
                                  setState(() {});
                                  // myStream.add(IntTest.indexScreens);
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
                            width: MediaQuery.of(context).size.width * 0.4,
                            height: 40.0,
                            child: Form(
                              child: TextField(
                                onChanged: (value) => _runApplicationFilter(value),
                                cursorColor: ColorApp.myColorGray,
                                decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.all(0.0),
                                    prefixIcon: IconButton(
                                        onPressed: () {},
                                        icon: const Icon(Icons.search)),
                                    suffixIcon: IconButton(
                                        onPressed: () {
                                          setState(() {
                                            dataApplication = getApplication;
                                          });
                                          openListSearch = false;
                                          myStream.add(IntTest.indexScreens);
                                        },
                                        icon: const Icon(Icons.close)),
                                    border: const OutlineInputBorder(),
                                    focusedBorder: const OutlineInputBorder(
                                      borderSide: BorderSide(
                                          color: ColorApp.myColorGreenAuth),
                                    ),
                                    labelText: myColorButtonApplication == 1
                                        ? 'Поиск по названию' : myColorButtonApplication == 2
                                        ? 'Поиск по дате заявки' : myColorButtonApplication == 3
                                        ? 'Поиск по коментарию' : myColorButtonApplication == 4
                                        ? 'Поиск по автору' : myColorButtonApplication == 5
                                        ? 'Поиск по исполнителю' : 'Поиск по статусу',
                                    labelStyle: const TextStyle(
                                        color: ColorApp.myColorGray)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                      ),

                    const Spacer(),

                    /// Кнопка выполненых задач
                    if (size.width <= 1350)
                    Row(
                      children: [
                        ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor: ColorApp.myColorGreen,
                                padding: const EdgeInsets.symmetric(vertical: 5.0,horizontal: 10)),
                            onPressed: (){

                            getListApplication();
                            IntTest.indexScreensDispatcher = 2;
                            IntTest.myTitle = 'Выполненые Заявки';
                            setState(() {});
                            myStream.add(IntTest.indexScreensDispatcher);
                          }, child: const Text('Выполненные', style: TextStyle(color: Colors.white,  fontSize: 14.0, fontWeight: FontWeight.w700))),
                      ],
                    ),
                    const SizedBox(width: 20.0),

                    ///Колокольчик
                    // if (size.width > 400)
                    //   Badge(
                    //     alignment: const AlignmentDirectional(21, 4),
                    //     backgroundColor: ColorApp.myColorRed,
                    //     isLabelVisible: IntTest.badgeCount > 0 ? true : false,
                    //     label: IntTest.badgeCount < 1
                    //         ? const SizedBox.shrink()
                    //         : Text(IntTest.badgeCount.toString(),
                    //             style: const TextStyle(
                    //                 fontSize: 12.0,
                    //                 color: ColorApp.myColorWhite,
                    //                 fontWeight: FontWeight.w500)),
                    //     child: IconButton(
                    //       onPressed: () {},
                    //       icon: const Icon(Icons.notifications_none_outlined,
                    //           size: 25.0),
                    //     ),
                    //   ),
                    // const SizedBox(width: 20.0),

                    ///Аватар Юзера
                    const MyUserDispatcher(),
                  ],
                ),
              ),

              /// Top Bar =====
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5.0),
                    color: ColorApp.myColorWhite,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade400,
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ///Обьект
                      Expanded(
                          child: Row(
                            children: [
                              TopButtonWidget(
                                text: 'Обьект',
                                press: () {
                                  myColorButtonApplication = 1;
                                  setState(() {});
                                },
                                pressIcon: () {},
                                colorButton: myColorButtonApplication == 1 ? ColorApp.myColorGreen : ColorApp.myColorWhite,
                                colorText: myColorButtonApplication == 1 ? Colors.white :  ColorApp.myColorBlack,
                              ),
                            ],
                          )),

                      ///Дата заявки
                      if (size.width > 550)
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TopButtonWidget(
                                text: 'Дата заявки',
                                press: () {
                                  // myColorButtonApplication = 2;
                                  setState(() {});
                                },
                                pressIcon: () {},
                                colorButton: myColorButtonApplication == 2 ? ColorApp.myColorGreen : ColorApp.myColorWhite,
                                colorText: myColorButtonApplication == 2 ? Colors.white :  ColorApp.myColorBlack,
                              ),
                            ],
                          ),
                        ),

                      /// Коментарий
                        Expanded(
                          child: Row(
                            // mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TopButtonWidget(
                                text: 'Коментарий',
                                press: () {
                                  myColorButtonApplication = 3;
                                  setState(() {});
                                },
                                pressIcon: () {},
                                colorButton: myColorButtonApplication == 3 ? ColorApp.myColorGreen : ColorApp.myColorWhite,
                                colorText: myColorButtonApplication == 3 ? Colors.white :  ColorApp.myColorBlack,
                              ),
                            ],
                          ),
                        ),

                      ///Автор
                      if (size.width > 1150)
                        Expanded(
                          child: Row(
                            children: [
                              TopButtonWidget(
                                text: 'Автор',
                                press: () {
                                  myColorButtonApplication = 4;
                                  setState(() {});
                                },
                                pressIcon: () {},
                                colorButton: myColorButtonApplication == 4 ? ColorApp.myColorGreen : ColorApp.myColorWhite,
                                colorText: myColorButtonApplication == 4 ? Colors.white :  ColorApp.myColorBlack,
                              ),
                            ],
                          ),
                        ),

                      ///Исполнитель
                      if (size.width > 1000)
                      Expanded(
                          child: Row(
                            children: [
                              TopButtonWidget(
                                text: 'Исполнитель',
                                press: () {
                                  myColorButtonApplication = 5;
                                  setState(() {});
                                },
                                pressIcon: () {},
                                colorButton: myColorButtonApplication == 5 ? ColorApp.myColorGreen : ColorApp.myColorWhite,
                                colorText: myColorButtonApplication == 5 ? Colors.white :  ColorApp.myColorBlack,
                              ),
                            ],
                          ),
                        ),

                      ///Статус
                      // if (size.width > 600)
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TopButtonWidget(
                              text: 'Статус',
                              press: () {
                                myColorButtonApplication = 6;
                                setState(() {});
                              },
                              pressIcon: () {},
                              colorButton: myColorButtonApplication == 6 ? ColorApp.myColorGreen : ColorApp.myColorWhite,
                              colorText: myColorButtonApplication == 6 ? Colors.white :  ColorApp.myColorBlack,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              /// Body ====
              Expanded(
                  child: dataApplication.every((t) => t['status_id']?['id'] == 4)
                      ? const EmptyList(
                          title: 'Заявок нет',
                          hint: 'Здесь появятся заявки, которые вы создали.',
                          icon: Icons.list_alt,
                        )
                      : ListView.builder(
                    // controller: employeeScrollController,
                    itemCount: dataApplication.length,
                    itemBuilder: (context, index) {
                      final myListTask = dataApplication[index];
                      return myListTask['status_id']['id'] == 4 ? Container() :  Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child:  Card(
                          // key: ValueKey(myListTask['id']),
                          child:  InkWell(
                            onTap: () async {
                              IntTest.indexTaskList = index;
                              IntTest.pressHover = myListTask['id'];
                              await getListApplicationInfo(IntTest.pressHover);
                              await getPhotoSelectedTaskInfoForeman(IntTest.pressHover);
                              myStream.add(IntTest.indexScreensDispatcher);
                              IntTest.indexScreensDispatcher = 1;
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
                                      ///Название
                                      Expanded(child: myListTask['object_id']['name'] == null ? const Text('') : Text('${myListTask['object_id']['name']}' ?? '')),

                                      ///Дата заявки
                                      if (size.width > 550)
                                        Expanded(
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Text(DateFormat('dd -MM-yyyy').format(DateTime.fromMillisecondsSinceEpoch(myListTask['created_at'] * 1000))),],
                                            )),

                                      /// Коментарий
                                        Expanded(
                                            child: Row(
                                              mainAxisAlignment:
                                              MainAxisAlignment
                                                  .center,
                                              children: [
                                                Container(
                                                    width: 170,
                                                    padding:
                                                    const EdgeInsets
                                                        .symmetric(
                                                        horizontal:
                                                        10.0,
                                                        vertical:
                                                        10.0),
                                                    decoration: BoxDecoration(
                                                        borderRadius:
                                                        BorderRadius
                                                            .circular(
                                                            5.0),
                                                        color: ColorApp
                                                            .myColorGrayShadow),
                                                    child: Text(
                                                      '${myListTask['task_text']}',
                                                      overflow:
                                                      TextOverflow
                                                          .ellipsis,
                                                    )),
                                              ],
                                            )),
                                      const SizedBox(width: 10.0),

                                      ///Автор
                                      if (size.width > 1150)
                                        Expanded(
                                            child: Container(
                                                padding:
                                                const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
                                                decoration: BoxDecoration(
                                                    borderRadius: BorderRadius.circular(5.0),
                                                    color: ColorApp.myColorGrayShadow),
                                                child: Text('${myListTask['creator_id']['name']}' ?? ''))),
                                      const SizedBox(width: 10.0),

                                      ///Исполнитель
                                      if (size.width > 1000)
                                      Expanded(
                                          child: Container(
                                              padding:
                                              const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
                                              decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.circular(5.0),
                                                  color: ColorApp.myColorGrayShadow),
                                              child: myListTask['executor_id'] == null ? const Text('') : Text('${myListTask['executor_id']['name']}'))),

                                      ///Дата исполнения
                                      // if (size.width > 550)
                                      //   Expanded(
                                      //       child: Row(
                                      //         mainAxisAlignment: MainAxisAlignment.center,
                                      //         children: [
                                      //           Text('до ${DateFormat('dd -MM-yyyy').format(DateTime.fromMillisecondsSinceEpoch(myListTask['created_at']*1000))}'),
                                      //         ],
                                      //       )),
                                      // myListTask['in_progress_at']
                                      /// Статус
                                      Expanded(
                                          child: myListTask['status_id'] == null ? Container() :
                                          Row(
                                            mainAxisAlignment:
                                            MainAxisAlignment.center,
                                            children: [
                                              ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                    foregroundColor: Colors.white, backgroundColor: myListTask['status_id']['id'] == 3 ? Colors.yellow[400] :  myListTask['status_id']['id'] == 4 ? Colors.green[400] : myListTask['status_id']['id'] == 5 ? Colors.red[400] :  Colors.grey),
                                                onPressed: () {
                                                  setState(() {});
                                                },
                                                child: Text(
                                                    '${myListTask['status_id']['name']}',
                                                    style: const TextStyle(
                                                        fontSize:
                                                        10.0)),
                                              ),
                                            ],
                                          )),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  )),
            ],
          ),
        );
      },
    );
  }
}
