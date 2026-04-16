import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import '../../../../helper/class_colors.dart';
import '../../../../helper/header/header.dart';
import '../../../../helper/my_drawer/my_drawer.dart';
import '../../../../helper/my_user.dart';
import '../../../companies/view/companies_screen.dart';
import '../../../employee/widgets/topButton.dart';
import '../../../home_page/home_page.dart';
import '../../bloc_task/task_bloc.dart';
import '../task_screen.dart';

/// Задачи Архив

/// api/v1/order/all получение списка задач
/// api/v1/order/ получение задач по id
/// api/v1/order/ создать

bool addWorks = false;
bool addWorksTwo = false;

Map listSelectedTaskId = {};
Map photoSelectedTaskId = {};

List dataListTask = [];

class TaskScreenArchive extends StatefulWidget {
  const TaskScreenArchive({Key? key}) : super(key: key);

  @override
  State<TaskScreenArchive> createState() => _TaskScreenArchiveState();
}

bool openListSearch = false;

class _TaskScreenArchiveState extends State<TaskScreenArchive> {

  int completedButtonTask = 1;

  /// Функция поиска по задаче ============================
  void _runCompletedTaskFilter(String enteredKeyword) {
    List result = [];
    if (enteredKeyword.isEmpty) {
      result = getTask;
    } else {
      result = getTask
          .where((user) => completedButtonTask == 1
          ? user['object_id']['name'].toLowerCase().contains(enteredKeyword.toLowerCase())
          : completedButtonTask == 2
          ? user['created_at'].toLowerCase().contains(enteredKeyword.toLowerCase())
          : completedButtonTask == 3
          ? user['task_text'].toLowerCase().contains(enteredKeyword.toLowerCase())
          : completedButtonTask == 4
          ? user['creator_id']['name'].toLowerCase().contains(enteredKeyword.toLowerCase())
          : completedButtonTask == 5
          ? user['executor_id']['name'].toLowerCase().contains(enteredKeyword.toLowerCase())
          : user['status_id']['name'].toLowerCase().contains(enteredKeyword.toLowerCase()))
          .toList();
    }
    setState(() {
      dataListTask = result;
    });
  }
  /// =====================================================

  /// ФИО
  TextEditingController fio = TextEditingController();

  bool completedTask = false;



  @override
  void initState() {
    TaskBloc().add(TaskGetEvent());
    getListTask();
    dataListTask = getTask;
    // TODO: implement initState
    super.initState();
  }

  @override
  void dispose() {
    openListSearch = false;
    // TODO: implement dispose
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
                      // Row(
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
                      //               IntTest.indexScreens = 2;
                      //               myStream.add(IntTest.indexScreens);
                      //             },
                      //             icon: const Icon(
                      //               Icons.arrow_back_ios_new_rounded,
                      //               color: Colors.black,
                      //               size: 13.0,
                      //             )),
                      //       ),
                      //       const SizedBox(width: 18.0),
                      //     ],
                      //   ),
                      /// Текст
                      Text('Выполненые задачи',
                          style: TextStyle(
                              fontSize: size.width > 350 ? 25.0 : 18.0,
                              fontWeight: size.width > 350
                                  ? FontWeight.w700
                                  : FontWeight.w500)),
                      const SizedBox(height: 20.0),
                      /// Иконка выполненых задач
                      // IconButton(
                      //     onPressed: () {
                      //       IntTest.indexScreens = 2;
                      //       myStream.add(IntTest.indexScreens);
                      //     },
                      //     icon: const Icon(Icons.check_box_outlined,
                      //         color: Colors.green)),

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
                                  onChanged: (value) => _runCompletedTaskFilter(value),
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
                                      labelText: completedButtonTask == 1
                                          ? 'Поиск по названию' : completedButtonTask == 2
                                          ? 'Поиск по дате заявки' : completedButtonTask == 3
                                          ? 'Поиск по коментарию' : completedButtonTask == 4
                                          ? 'Поиск по автору' : completedButtonTask == 5
                                          ? 'Поиск по исполнителю' : 'Поиск по статусу',
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
                                    completedButtonTask = 1;
                                    setState(() {});
                                  },
                                  pressIcon: () {},
                                  colorButton: completedButtonTask == 1 ? ColorApp.myColorGreen : ColorApp.myColorWhite,
                                  colorText: completedButtonTask == 1 ? Colors.white :  ColorApp.myColorBlack,
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
                                  colorButton: completedButtonTask == 2 ? ColorApp.myColorGreen : ColorApp.myColorWhite,
                                  colorText: completedButtonTask == 2 ? Colors.white :  ColorApp.myColorBlack,
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
                                    completedButtonTask = 3;
                                    setState(() {});
                                  },
                                  pressIcon: () {},
                                  colorButton: completedButtonTask == 3 ? ColorApp.myColorGreen : ColorApp.myColorWhite,
                                  colorText: completedButtonTask == 3 ? Colors.white :  ColorApp.myColorBlack,
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
                                    completedButtonTask = 4;
                                    setState(() {});
                                  },
                                  pressIcon: () {},
                                  colorButton: completedButtonTask == 4 ? ColorApp.myColorGreen : ColorApp.myColorWhite,
                                  colorText: completedButtonTask == 4 ? Colors.white :  ColorApp.myColorBlack,
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
                                    completedButtonTask = 5;
                                    setState(() {});
                                  },
                                  pressIcon: () {},
                                  colorButton: completedButtonTask == 5 ? ColorApp.myColorGreen : ColorApp.myColorWhite,
                                  colorText: completedButtonTask == 5 ? Colors.white :  ColorApp.myColorBlack,
                                ),
                              ],
                            ),
                          ),

                        ///Статус
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TopButtonWidget(
                                text: 'Статус',
                                press: () {
                                  completedButtonTask = 6;
                                  setState(() {});
                                },
                                pressIcon: () {},
                                colorButton: completedButtonTask == 6 ? ColorApp.myColorGreen : ColorApp.myColorWhite,
                                colorText: completedButtonTask == 6 ? Colors.white :  ColorApp.myColorBlack,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                /// Body ====
                Expanded(child: ListView.builder(
                                // controller: employeeScrollController,
                                itemCount: dataListTask.length,
                                itemBuilder: (context, index) {
                                  final myListTask = dataListTask[index];
                                  return myListTask['status_id']['id'] != 4 ? Container() :  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                                    child: Card(
                                      // key: ValueKey(myListTask['id']),
                                      child: InkWell(
                                        onTap: () async {
                                          IntTest.indexTaskList = index;
                                          IntTest.pressHover = myListTask['id'];
                                          await getListTaskInfo(IntTest.pressHover);
                                          myStream.add(IntTest.indexScreens);
                                          IntTest.indexScreens = 22;
                                          setState(() {});
                                        },
                                        onHover: (val) {
                                          setState(() {
                                            isHover = index;
                                          });
                                        },
                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(5.0),
                                            color: Colors.green[100]),
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                ///Название
                                                Expanded(
                                                    child: Text('${myListTask['object_id']['name']}' ?? '')),

                                                ///Дата заявки
                                                if (size.width > 550)
                                                  Expanded(
                                                      child: Row(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Text(DateFormat('dd -MM-yyyy').format(DateTime.fromMillisecondsSinceEpoch(myListTask['created_at'] * 1000))),
                                                    ],
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
                                                              const EdgeInsets.symmetric(
                                                                  horizontal: 10.0,
                                                                  vertical: 10.0),
                                                          decoration: BoxDecoration(
                                                              borderRadius: BorderRadius
                                                                      .circular(5.0),
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
                                                  // myListTask['creator_id'] != null
                                                  Expanded(
                                                      child: Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
                                                          decoration: BoxDecoration(
                                                              borderRadius: BorderRadius.circular(5.0),
                                                              color: ColorApp.myColorGrayShadow),
                                                          child: Text('${myListTask['creator_id']['name']}' ?? ''))),
                                                const SizedBox(width: 10.0),

                                                ///Исполнитель
                                                myListTask['executor_id'] == null
                                                    ? const Expanded(child: Text(''))
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

                                                ///Проверка
                                                Expanded(child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    ElevatedButton(
                                                      style: ElevatedButton.styleFrom(
                                                          shape: RoundedRectangleBorder(
                                                              borderRadius: BorderRadius.circular(5.0)),
                                                          foregroundColor: Colors.white, backgroundColor: Colors.green[400]),
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
                                    ) ,
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
