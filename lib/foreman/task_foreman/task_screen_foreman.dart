import 'dart:async';
import 'dart:convert';
import 'package:els/foreman/task_foreman/task_widget_foreman/add_task_foreman.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../helper/class_colors.dart';
import '../../../helper/header/header.dart';
import 'package:http/http.dart' as http;
import '../../screns/companies/view/companies_screen.dart';
import '../../screns/employee/widgets/topButton.dart';
import '../../screns/home_page/home_page.dart';
import '../drawer_foreman.dart';
import '../user_page_foreman.dart';

///Задачи Прораба

bool addWorks = false;
bool addWorksTwo = false;

var myPhoto;

Map listSelectedTaskIdForeman = {};
List photoSelectedTaskIdForeman = [];

List getTaskForeman = [];
List dataListTaskForeman = [];

class TaskScreenForeman extends StatefulWidget {
  const TaskScreenForeman({Key? key}) : super(key: key);

  @override
  State<TaskScreenForeman> createState() => _TaskScreenForemanState();
}

/// Список всех задач ==========
getListTaskForeman() async {
  final res = await http
      .get(Uri.parse('http://${IntTest.myIp}/api/v1/order/all'), headers: {
    "Content-Type": "application/json; charset=utf-8",
    'Accept': 'application/json',
    'Authorization': 'Bearer ${IntTest.token}',
  });
  var vova = jsonDecode(utf8.decode(res.bodyBytes));
  getTaskForeman = vova['data'];
  myStream.add(IntTest.indexScreensForeman);

}
/// ============================

///Получение данных выбраной задачи ==========
getListTaskInfoForeman(int userId) async {
  await Future(() async {
    final res = await http.get(
        Uri.parse("http://${IntTest.myIp}/api/v1/order/$userId/"),
        headers: {
          "Content-Type": "application/json; charset=utf-8",
          'Authorization': 'Bearer ${IntTest.token}',
        });
    var vova = jsonDecode(utf8.decode(res.bodyBytes));
    listSelectedTaskIdForeman = vova;
    getPhotoSelectedTaskInfoForeman(listSelectedTaskIdForeman['data']['id']);
  });
}
/// ==========================================

///Получение фото выбраной задачи =====================
getPhotoSelectedTaskInfoForeman(int taskId) async {
  await Future(() async {
    final res = await http.get(
        Uri.parse("http://${IntTest.myIp}/api/v1/order-photo/$taskId?page=1"),
        headers: {
          "Content-Type": "application/json; charset=utf-8",
          'Authorization': 'Bearer ${IntTest.token}',
        });
    var vova = jsonDecode(utf8.decode(res.bodyBytes));
    photoSelectedTaskIdForeman = vova['data'];
    myStream.add(IntTest.indexScreens);
  });
}
/// ===================================================

bool openListSearch = false;

class _TaskScreenForemanState extends State<TaskScreenForeman> {

  Timer? _timer;

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 3), (Timer timer) {
      getListTaskForeman();
    });
  }

  /// Функция поиска по задаче ==========================
  void _runTaskForemanFilter(String enteredKeyword) {
    List result = [];
    if (enteredKeyword.isEmpty) {
      result = getTaskForeman;
    } else {
      result = getTaskForeman
          .where((user) => user['object_id']['name']
              .toLowerCase()
              .contains(enteredKeyword.toLowerCase()))
          .toList();
    }
    setState(() {
      dataListTaskForeman = result;
    });
  }
  /// ===================================================

  /// ФИО
  TextEditingController fio = TextEditingController();

  bool completedTask = false;

  @override
  void initState() {
    getListTaskForeman();
    dataListTaskForeman = getTaskForeman;
    _startTimer();

    // TODO: implement initState
    super.initState();
  }

  @override
  void dispose() {
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
          drawer: const DrawerForeman(),
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
                      const SizedBox(width: 5.0),
                      ///Добавить Задачу
                      if (completedTask != true)
                        IconButton(
                            onPressed: () async {
                              setState(() {
                                showDialog(
                                    context: context,
                                    builder: (context) => const AlertDialog(
                                          content: AddTaskForeman(),
                                        )).then((value) => setState(() {}));
                              });
                            },
                            icon: const Icon(Icons.add_box_rounded,
                                size: 25.0, color: ColorApp.myColorGreenAuth)),
                      /// Список выполненых задач
                      IconButton(
                          onPressed: () {
                            IntTest.indexScreensForeman = 16;
                            myStream.add(IntTest.indexScreensForeman);
                            setState(() {});
                          },
                          icon: Icon(Icons.check_box_outlined,
                              color:  Colors.grey.shade600)),

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
                                  onChanged: (value) => _runTaskForemanFilter(value),
                                  cursorColor: ColorApp.myColorGray,
                                  decoration: InputDecoration(
                                      contentPadding: const EdgeInsets.all(0.0),
                                      prefixIcon: IconButton(
                                          onPressed: () {},
                                          icon: const Icon(Icons.search)),
                                      suffixIcon: IconButton(
                                          onPressed: () {
                                            setState(() {
                                              dataListTaskForeman = getTaskForeman;
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
                                // myColorButton = 1;
                                setState(() {});
                              },
                              pressIcon: () {},
                              colorButton: ColorApp.myColorWhite,
                              colorText: ColorApp.myColorBlack,
                            ),
                            // const SizedBox(width: 5.0),
                            // Container(
                            //     width: 27,
                            //     height: 27,
                            //     decoration: BoxDecoration(
                            //       border: Border.all(
                            //           color: ColorApp.myColorGreen, width: 1.0),
                            //       borderRadius: BorderRadius.circular(4.0),
                            //     ),
                            //     child: const Icon(Icons.arrow_drop_down_sharp)),
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
                                    // myColorButton = 2;
                                    setState(() {});
                                  },
                                  pressIcon: () {},
                                  colorButton: ColorApp.myColorWhite,
                                  colorText: ColorApp.myColorBlack,
                                ),
                                // const SizedBox(width: 5.0),
                                // Container(
                                //     width: 27,
                                //     height: 27,
                                //     decoration: BoxDecoration(
                                //       border: Border.all(
                                //           color: ColorApp.myColorGreen, width: 1.0),
                                //       borderRadius: BorderRadius.circular(4.0),
                                //     ),
                                //     child: const Icon(Icons.arrow_drop_down_sharp)),
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
                                    // myColorButton = 3;
                                    setState(() {});
                                  },
                                  pressIcon: () {},
                                  colorButton: ColorApp.myColorWhite,
                                  colorText: ColorApp.myColorBlack,
                                ),
                                // const SizedBox(width: 5.0),
                                // Container(
                                //     width: 27,
                                //     height: 27,
                                //     decoration: BoxDecoration(
                                //       border: Border.all(
                                //           color: ColorApp.myColorGreen, width: 1.0),
                                //       borderRadius: BorderRadius.circular(4.0),
                                //     ),
                                //     child: const Icon(Icons.arrow_drop_down_sharp)),
                              ],
                            ),
                          ),

                        ///Автор
                        if (size.width > 930)
                          Expanded(
                            child: Row(
                              children: [
                                TopButtonWidget(
                                  text: 'Автор',
                                  press: () {
                                    // myColorButton = 4;
                                    // setState(() {});
                                  },
                                  pressIcon: () {},
                                  colorButton: ColorApp.myColorWhite,
                                  colorText: ColorApp.myColorBlack,
                                ),
                                // const SizedBox(width: 5.0),
                                // Container(
                                //     width: 27,
                                //     height: 27,
                                //     decoration: BoxDecoration(
                                //       border: Border.all(
                                //           color: ColorApp.myColorGreen, width: 1.0),
                                //       borderRadius: BorderRadius.circular(4.0),
                                //     ),
                                //     child: const Icon(Icons.arrow_drop_down_sharp)),
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
                                    // myColorButton = 5;
                                    // setState(() {});
                                  },
                                  pressIcon: () {},
                                  colorButton: ColorApp.myColorWhite,
                                  colorText: ColorApp.myColorBlack,
                                ),
                                // const SizedBox(width: 5.0),
                                // Container(
                                //     width: 27,
                                //     height: 27,
                                //     decoration: BoxDecoration(
                                //       border: Border.all(
                                //           color: ColorApp.myColorGreen, width: 1.0),
                                //       borderRadius: BorderRadius.circular(4.0),
                                //     ),
                                //     child: const Icon(Icons.arrow_drop_down_sharp)),
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
                                  },
                                pressIcon: () {},
                                colorButton: ColorApp.myColorWhite,
                                colorText: ColorApp.myColorBlack,
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
                             itemCount: getTaskForeman.length,
                             itemBuilder: (context, index) {
                               final myListTask = getTaskForeman[index];
                               return myListTask['status_id']['id'] == 4 ? Container() :  Padding(
                                 padding: const EdgeInsets.symmetric(horizontal: 20.0),
                                 child:  Card(
                                   // key: ValueKey(myListTask['id']),
                                   child:  InkWell(
                                     onTap: () async {
                                       IntTest.indexTaskList = index;
                                       IntTest.pressHover = myListTask['id'];
                                       await getListTaskInfoForeman(IntTest.pressHover);
                                       // await getPhotoSelectedTaskInfoForeman(IntTest.pressHover);
                                       myStream.add(IntTest.indexScreensForeman);
                                       IntTest.indexScreensForeman = 15;
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
                                               myListTask['object_id']['name'] == null
                                                   ? const Expanded(child: Text(''))
                                                   : Expanded(child: Text('${myListTask['object_id']['name']}' ?? '')),

                                               ///Дата заявки
                                               if (size.width > 550)
                                                 Expanded(
                                                     child: Row(
                                                   mainAxisAlignment: MainAxisAlignment.center,
                                                   children: [
                                                     Text(DateFormat('dd -MM-yyyy').format(DateTime.fromMillisecondsSinceEpoch(myListTask['created_at'] * 1000))),],
                                                 )),

                                               /// Коментарий
                                               if (size.width > 1000)
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
                                               if (size.width > 930)
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
                                               myListTask['executor_id'] == null
                                                   ? const Expanded(
                                                       child: Text(''))
                                                   : Expanded(
                                                       child: Container(
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
                                                               '${myListTask['executor_id']['name']}'))),

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
