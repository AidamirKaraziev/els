import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../helper/class_colors.dart';
import '../../../helper/header/header.dart';
import '../../../helper/my_drawer/my_drawer.dart';
import '../../../helper/my_user.dart';
import '../../companies/view/companies_screen.dart';
import '../../employee/widgets/topButton.dart';
import '../../home_page/home_page.dart';
import '../widget/add_task.dart';
import 'package:http/http.dart' as http;

///Задачи

bool addWorks = false;
bool addWorksTwo = false;

Map listSelectedTaskId = {};
List photoSelectedTaskId = [];
String onePhotoSelectedTaskId = '';

int myColorButtonTask = 1;

int newScreensTask = 1;

List getTask = [];
List dataListTask = [];

class TaskScreen extends StatefulWidget {
  const TaskScreen({Key? key}) : super(key: key);

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

/// Список всех задач ===
getListTask() async {
  final res = await http
      .get(Uri.parse('http://${IntTest.myIp}/api/v1/order/all'), headers: {
    "Content-Type": "application/json; charset=utf-8",
    'Accept': 'application/json',
    'Authorization': 'Bearer ${IntTest.token}',
  });
  var getEmployeeMap = jsonDecode(utf8.decode(res.bodyBytes));
  getTask = getEmployeeMap['data'];
  dataListTask = getTask;
  // print('==========================================================');
  // print(dataListTask);
  // print('==========================================================');
  myStream.add(IntTest.indexScreens);
}
/// =====================

///Получение данных выбраной задачи ====
getListTaskInfo(int userId) async {
  await Future(() async {
    final res = await http.get(
        Uri.parse("http://${IntTest.myIp}/api/v1/order/$userId/"),
        headers: {
          "Content-Type": "application/json; charset=utf-8",
          'Authorization': 'Bearer ${IntTest.token}',
        });
    var vova = jsonDecode(utf8.decode(res.bodyBytes));
    listSelectedTaskId = vova;
    getPhotoSelectedTaskInfo(listSelectedTaskId['data']['id']);
  });
}
/// ====================================

///Получение фото выбраной задачи ==============
getPhotoSelectedTaskInfo(int taskId) async {
  await Future(() async {
    final res = await http.get(
        Uri.parse("http://${IntTest.myIp}/api/v1/order-photo/$taskId?page=1"),
        headers: {
          "Content-Type": "application/json; charset=utf-8",
          'Authorization': 'Bearer ${IntTest.token}',
        });
     var vova = jsonDecode(utf8.decode(res.bodyBytes));
    photoSelectedTaskId = vova['data'];
    print('pfoto');
  });
}
/// ============================================

///Получение одного фото выбраной задачи ===
getPhotoTaskSelected(int userId) async {
  await Future(() async {
    final res = await http.get(
        Uri.parse("http://${IntTest.myIp}/api/v1/order-photo/$userId/"),
        headers: {
          "Content-Type": "application/json; charset=utf-8",
          'Authorization': 'Bearer ${IntTest.token}',
        });
    var vova = jsonDecode(utf8.decode(res.bodyBytes));
    onePhotoSelectedTaskId = vova['data']['photo'];
  });
}
/// ========================================

bool openListSearch = false;

class _TaskScreenState extends State<TaskScreen> {

  Timer? _timer;

  // void _startTimer() {
  //   _timer = Timer.periodic(const Duration(seconds: 10), (Timer timer) {
  //     getListTask();
  //
  //   });
  // }

  /// Функция поиска по задаче =======================
  void _runTaskFilter(String enteredKeyword) {
    List result = [];
    if (enteredKeyword.isEmpty) {
      result = getTask;
    } else {
      result = getTask
          .where((user) => myColorButtonTask == 1
          ? user['object_id']['name'].toLowerCase().contains(enteredKeyword.toLowerCase())
          : myColorButtonTask == 2
          ? user['created_at'].toLowerCase().contains(enteredKeyword.toLowerCase())
          : myColorButtonTask == 3
          ? user['task_text'].toLowerCase().contains(enteredKeyword.toLowerCase())
          : myColorButtonTask == 4
          ? user['creator_id']['name'].toLowerCase().contains(enteredKeyword.toLowerCase())
          : myColorButtonTask == 5
          ? user['executor_id']['name'].toLowerCase().contains(enteredKeyword.toLowerCase())
          : user['status_id']['name'].toLowerCase().contains(enteredKeyword.toLowerCase()))
          .toList();
    }
    setState(() {
      dataListTask = result;
    });
  }
  /// ================================================

  /// ФИО
  TextEditingController fio = TextEditingController();

  bool completedTask = false;

  @override
  void initState() {
    myColorButtonTask = 1;
    getListTask();
    // _startTimer();
    // TODO: implement initState
    super.initState();
  }

  @override
  void dispose() {
    openListSearch = false;
    // newScreensTask = 1;
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
          key: myOpenDrawer,
          drawer: const MyDrawer(),
          body: Container(
            color: ColorApp.myColorTransparent,
            child: Column(
              children: [
                ///Header =====
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: ColorApp.kPadding),
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
                      if(completedTask == true)
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
                                      completedTask =! completedTask;
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
                      Text('Задачи',
                          style: TextStyle(
                              fontSize: size.width > 350 ? 25.0 : 18.0,
                              fontWeight: size.width > 350
                                  ? FontWeight.w700
                                  : FontWeight.w500)),

                      ///Добавить Задачу
                        if (completedTask != true && size.width > 900)
                        IconButton(
                            onPressed: () async {
                              setState(() {
                                showDialog(
                                    context: context,
                                    builder: (context) => const AlertDialog(
                                      content: AddTask(),
                                    )).then((value) => setState(() {}));
                              });
                            },
                            icon: const Icon(Icons.add_box_rounded,
                                size: 25.0, color: ColorApp.myColorGreenAuth)),
                      const SizedBox(height: 20.0),
                      /// Список выполненых задач
                      // if (size.width > 900)
                      // TextButton(onPressed: (){
                      //   IntTest.indexScreens = 22;
                      //   myStream.add(IntTest.indexScreens);
                      //   setState(() {});
                      // }, child: const Text('Список выполненых задач', style: TextStyle(color: Colors.grey,  fontSize: 18.0, fontWeight: FontWeight.w700))),

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
                              width: MediaQuery.of(context).size.width * 0.3,
                              height: 40.0,
                              child: Form(
                                child: TextField(
                                  onChanged: (value) => _runTaskFilter(value),
                                  cursorColor: ColorApp.myColorGray,
                                  decoration: InputDecoration(
                                      contentPadding: const EdgeInsets.all(0.0),
                                      prefixIcon: IconButton(
                                          onPressed: () {},
                                          icon: const Icon(Icons.search)),
                                      suffixIcon: IconButton(
                                          onPressed: () {
                                            setState(() {
                                              dataListTask = getTask;

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
                                      labelText: myColorButtonTask == 1
                                          ? 'Поиск по названию' : myColorButtonTask == 2
                                          ? 'Поиск по дате заявки' : myColorButtonTask == 3
                                          ? 'Поиск по коментарию' : myColorButtonTask == 4
                                          ? 'Поиск по автору' : myColorButtonTask == 5
                                          ? 'Поиск по исполнителю' : 'Поиск по статусу',
                                      labelStyle: const TextStyle(
                                          color: ColorApp.myColorGray)),
                                ),
                              ),
                            ),
                          ],
                        ),

                      const Spacer(),

                      /// Переключение страницы
                      // Row(
                      //   children: [
                      //     IconButton(onPressed: (){
                      //       if(newScreensTask > 1) {
                      //         --newScreensTask;
                      //       }
                      //       getListTask();
                      //       myStream.add(IntTest.indexScreens);
                      //       setState(() {});
                      //     }, icon: const Icon(Icons.arrow_circle_left_outlined, color: Color(0xffBADE89))),
                      //     const SizedBox(width: 10.0),
                      //     Text('$newScreensTask'),
                      //     const SizedBox(width: 10.0),
                      //     IconButton(onPressed: (){
                      //       if(dataListTask.isNotEmpty) {
                      //         newScreensTask++;
                      //       }
                      //       getListTask();
                      //       myStream.add(IntTest.indexScreens);
                      //       setState(() {});
                      //     }, icon: const Icon(Icons.arrow_circle_right_outlined, color: Color(0xffBADE89))),
                      //   ],
                      // ),

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
                                    myColorButtonTask = 1;
                                    setState(() {});
                                  },
                                  pressIcon: () {},
                                  colorButton: myColorButtonTask == 1 ? ColorApp.myColorGreen : ColorApp.myColorWhite,
                                  colorText: myColorButtonTask == 1 ? Colors.white :  ColorApp.myColorBlack,
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
                                    // myColorButtonTask = 2;
                                    setState(() {});
                                  },
                                  pressIcon: () {},
                                  colorButton: myColorButtonTask == 2 ? ColorApp.myColorGreen : ColorApp.myColorWhite,
                                  colorText: myColorButtonTask == 2 ? Colors.white :  ColorApp.myColorBlack,
                                ),
                              ],
                            ),
                          ),

                        /// Задача
                        if (size.width > 1000)
                          Expanded(
                            child: Row(
                              // mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                TopButtonWidget(
                                  text: 'Задача',
                                  press: () {
                                    myColorButtonTask = 3;
                                    setState(() {});
                                  },
                                  pressIcon: () {},
                                  colorButton: myColorButtonTask == 3 ? ColorApp.myColorGreen : ColorApp.myColorWhite,
                                  colorText: myColorButtonTask == 3 ? Colors.white :  ColorApp.myColorBlack,
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
                                    myColorButtonTask = 4;
                                    setState(() {});
                                  },
                                  pressIcon: () {},
                                  colorButton: myColorButtonTask == 4 ? ColorApp.myColorGreen : ColorApp.myColorWhite,
                                  colorText: myColorButtonTask == 4 ? Colors.white :  ColorApp.myColorBlack,
                                ),
                              ],
                            ),
                          ),

                        ///Исполнитель
                        if (size.width > 750)
                          Expanded(
                            child: Row(
                              children: [
                                TopButtonWidget(
                                  text: 'Исполнитель',
                                  press: () {
                                    myColorButtonTask = 5;
                                    setState(() {});
                                  },
                                  pressIcon: () {},
                                  colorButton: myColorButtonTask == 5 ? ColorApp.myColorGreen : ColorApp.myColorWhite,
                                  colorText: myColorButtonTask == 5 ? Colors.white :  ColorApp.myColorBlack,
                                ),
                              ],
                            ),
                          ),

                        ///Дата исполнения
                        // if (size.width > 550)
                        //   Expanded(
                        //     child: Row(
                        //       mainAxisAlignment: MainAxisAlignment.center,
                        //       children: [
                        //         TopButtonWidget(
                        //           text: 'Дата исполнения',
                        //           press: () {
                        //             myColorButton = 6;
                        //             setState(() {});
                        //           },
                        //           pressIcon: () {},
                        //           colorButton: myColorButton == 6
                        //               ? ColorApp.myColorGreen
                        //               : ColorApp.myColorWhite,
                        //           colorText: myColorButton == 6
                        //               ? ColorApp.myColorWhite
                        //               : ColorApp.myColorBlack,
                        //         ),
                        //         const SizedBox(width: 5.0),
                        //         Container(
                        //             width: 27,
                        //             height: 27,
                        //             decoration: BoxDecoration(
                        //               border: Border.all(
                        //                   color: ColorApp.myColorGreen, width: 1.0),
                        //               borderRadius: BorderRadius.circular(4.0),
                        //             ),
                        //             child: const Icon(Icons.arrow_drop_down_sharp)),
                        //       ],
                        //     ),
                        //   ),

                        ///Статус
                        // if (size.width > 600)
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TopButtonWidget(
                                text: 'Статус',
                                press: () {
                                  myColorButtonTask = 6;
                                  setState(() {});
                                },
                                pressIcon: () {},
                                colorButton: myColorButtonTask == 6 ? ColorApp.myColorGreen : ColorApp.myColorWhite,
                                colorText: myColorButtonTask == 6 ? Colors.white :  ColorApp.myColorBlack,
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
                    child: ListView.builder(
                      // controller: employeeScrollController,
                      itemCount: dataListTask.length,
                      itemBuilder: (context, index) {
                        dataListTask.sort((a, b) => b['creator_id']['role_id']['id'].compareTo(a['creator_id']['role_id']['id']));
                        final myListTask = dataListTask[index];
                        return myListTask['status_id']['id'] == 4 ? Container() : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child:  Card(
                            // key: ValueKey(myListTask['id']),
                            child:  InkWell(
                              onTap: () async {
                                IntTest.indexTaskList = index;
                                IntTest.pressHover = myListTask['id'];
                                print(myListTask['creator_id']);
                                print(myListTask['creator_id']['role_id']['id']);
                                await getListTaskInfo(IntTest.pressHover);
                                await getPhotoSelectedTaskInfo(IntTest.pressHover);
                                myStream.add(IntTest.indexScreens);
                                IntTest.indexScreens = 13;
                                setState(() {});
                              },
                              onHover: (val) {
                                setState(() {
                                  isHover = index;
                                });
                              },
                              child: Container(
                                decoration: BoxDecoration(

                                  border: Border.all(color: myListTask['creator_id'] ? ['role_id'] ? ['id'] == 5 ? Colors.red : Colors.white, width: 1.5),
                                  borderRadius: BorderRadius.circular(5.0),
                                  color:
                                  // isHover == index
                                  //     ? Colors.grey.shade50
                                  //    :
                                  myListTask['creator_id'] ? ['role_id'] ? ['id'] == 5 ? Colors.orange[200] : ColorApp.myColorWhite,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      ///Название
                                      myListTask['object_id'] == null
                                          ? const Expanded(child: Text(''))
                                          : Expanded(child: Text('${myListTask['object_id']['name']}' ?? '')),

                                      ///Дата заявки
                                      if (size.width > 550)
                                        Expanded(
                                            child: Row(
                                              mainAxisAlignment:
                                              MainAxisAlignment
                                                  .center,
                                              children: [
                                                Text(DateFormat('dd -MM-yyyy').format(DateTime.fromMillisecondsSinceEpoch(myListTask['created_at'] * 1000))),],
                                            )),

                                      /// Коментарий
                                      if (size.width > 1000)
                                        Expanded(
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Container(
                                                    width: 170,
                                                    padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
                                                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(5.0),
                                                        color: myListTask['creator_id'] ? ['role_id'] ? ['id'] == 5 ? Colors.orange[200] : ColorApp.myColorGrayShadow),
                                                    child: Text('${myListTask['task_text']}', overflow: TextOverflow.ellipsis)),
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
                                                    color: myListTask['creator_id'] ? ['role_id'] ? ['id'] == 5 ? Colors.orange[200] : ColorApp.myColorGrayShadow),
                                                child: Text(myListTask['creator_id'] ? ['role_id'] ? ['id'] == 5 ? 'Заявка' : '${myListTask['creator_id'] ? ['name']}' ?? ''))),
                                      const SizedBox(width: 10.0),

                                      ///Исполнитель
                                      if (size.width > 750)
                                        Expanded(
                                            child: Container(
                                                padding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 10.0,
                                                    vertical: 10.0),
                                                decoration: BoxDecoration(
                                                    borderRadius: BorderRadius.circular(5.0),
                                                    color:  myListTask['executor_id']?['is_actual'] == false ? Colors.blue[300] : myListTask['creator_id'] ? ['role_id'] ? ['id'] == 5 ? Colors.orange[200] : ColorApp.myColorGrayShadow),
                                                child:  myListTask['executor_id'] == null
                                                    ? const Center(child: Text('Удален',style: TextStyle(color: Colors.red,fontWeight: FontWeight.bold),))
                                                    : Text('${myListTask['executor_id']['name']}', style: TextStyle(color: myListTask['executor_id']['is_actual'] == false ? Colors.white : Colors.black),))),

                                      /// Статус
                                      Expanded(
                                          child: myListTask['status_id'] == null ? Container() :
                                          Row(
                                            mainAxisAlignment:
                                            MainAxisAlignment.center,
                                            children: [
                                              ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                    shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(5.0)),
                                                    foregroundColor: Colors.white, backgroundColor: myListTask['status_id']['id'] == 3 ? Colors.yellow[400] :  myListTask['status_id']['id'] == 4 ? Colors.green[400] : myListTask['status_id']['id'] == 5 ? Colors.red[400] :  Colors.grey),
                                                onPressed: () {
                                                  addWorks = true;
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
                        );
                      },
                    )),
              ],
            ),
          ),
        );
      },
    );
  }
}
