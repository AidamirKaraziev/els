import 'package:els/dispatcher/user_page_dispatcher.dart';
import 'package:els/foreman/task_foreman/task_screen_foreman.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../helper/class_colors.dart';
import '../../../../helper/header/header.dart';
import '../../../../helper/my_drawer/my_drawer.dart';
import '../../../screns/companies/view/companies_screen.dart';
import '../../../screns/employee/widgets/topButton.dart';
import '../../../screns/home_page/home_page.dart';
import 'application_screen.dart';

///Задачи Архив

bool addWorks = false;
bool addWorksTwo = false;

int completedApplication = 1;

class ApplicationScreenCompleted extends StatefulWidget {
  const ApplicationScreenCompleted({Key? key}) : super(key: key);

  @override
  State<ApplicationScreenCompleted> createState() => _ApplicationScreenCompletedState();
}

bool openListSearch = false;

class _ApplicationScreenCompletedState extends State<ApplicationScreenCompleted> {

  /// Функция поиска по задаче ===================================
  void _runApplicationCompletedFilter(String enteredKeyword) {
    List result = [];
    if (enteredKeyword.isEmpty) {
      result = getApplication;
    } else {
      result = getApplication
          .where((user) => completedApplication == 1
          ? user['object_id']['name'].toLowerCase().contains(enteredKeyword.toLowerCase())
          : completedApplication == 2
          ? user['created_at'].toLowerCase().contains(enteredKeyword.toLowerCase())
          : completedApplication == 3
          ? user['task_text'].toLowerCase().contains(enteredKeyword.toLowerCase())
          : completedApplication == 4
          ? user['creator_id']['name'].toLowerCase().contains(enteredKeyword.toLowerCase())
          : completedApplication == 5
          ? user['executor_id']['name'].toLowerCase().contains(enteredKeyword.toLowerCase())
          : user['status_id']['name'].toLowerCase().contains(enteredKeyword.toLowerCase()))
          .toList();
    }
    setState(() {
      dataApplication = result;
    });
  }
  /// ============================================================

  /// ФИО
  TextEditingController fio = TextEditingController();

  bool completedTask = false;

  @override
  void initState() {
    getListApplication();
    // TODO: implement initState
    super.initState();
  }

  @override
  void dispose() {
    completedApplication = 1;
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
                      /// Кнопка Назад
                      if (size.width <= 1350)
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
                                    IntTest.indexScreensDispatcher = 0;
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
                      const Text('Выполненные заявки',
                          style: TextStyle(
                              fontSize: 20.0,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(width: 5.0),
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
                              width: MediaQuery.of(context).size.width * 0.35,
                              height: 40.0,
                              child: Form(
                                child: TextField(
                                  onChanged: (value) => _runApplicationCompletedFilter(value),
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
                                      labelText: completedApplication == 1
                                          ? 'Поиск по названию' : completedApplication == 2
                                          ? 'Поиск по дате заявки' : completedApplication == 3
                                          ? 'Поиск по коментарию' : completedApplication == 4
                                          ? 'Поиск по автору' : completedApplication == 5
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
                      // SizedBox(width: size.width > 500 ? 40.0 : 10.0),

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
                                    completedApplication = 1;
                                    setState(() {});
                                  },
                                  pressIcon: () {},
                                  colorButton: completedApplication == 1 ? ColorApp.myColorGreen : ColorApp.myColorWhite,
                                  colorText: completedApplication == 1 ? Colors.white :  ColorApp.myColorBlack,
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
                                    // completedApplication = 2;
                                    setState(() {});
                                  },
                                  pressIcon: () {},
                                  colorButton: completedApplication == 2 ? ColorApp.myColorGreen : ColorApp.myColorWhite,
                                  colorText: completedApplication == 2 ? Colors.white :  ColorApp.myColorBlack,
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
                                    completedApplication = 3;
                                    setState(() {});
                                  },
                                  pressIcon: () {},
                                  colorButton: completedApplication == 3 ? ColorApp.myColorGreen : ColorApp.myColorWhite,
                                  colorText: completedApplication == 3 ? Colors.white :  ColorApp.myColorBlack,
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
                                    completedApplication = 4;
                                    setState(() {});
                                  },
                                  pressIcon: () {},
                                  colorButton: completedApplication == 4 ? ColorApp.myColorGreen : ColorApp.myColorWhite,
                                  colorText: completedApplication == 4 ? Colors.white :  ColorApp.myColorBlack,
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
                                    completedApplication = 5;
                                    setState(() {});
                                  },
                                  pressIcon: () {},
                                  colorButton: completedApplication == 5 ? ColorApp.myColorGreen : ColorApp.myColorWhite,
                                  colorText: completedApplication == 5 ? Colors.white :  ColorApp.myColorBlack,
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
                                  completedApplication = 6;
                                  setState(() {});
                                },
                                pressIcon: () {},
                                colorButton: completedApplication == 6 ? ColorApp.myColorGreen : ColorApp.myColorWhite,
                                colorText: completedApplication == 6 ? Colors.white :  ColorApp.myColorBlack,
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
                                itemCount: dataApplication.length,
                                itemBuilder: (context, index) {
                                  final myListTask = dataApplication[index];
                                  return myListTask['status_id']['id'] != 4 ? Container() :  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                                    child: Card(
                                      // key: ValueKey(myListTask['id']),
                                      child: InkWell(
                                        onTap: () async {
                                          IntTest.indexTaskList = index;
                                          IntTest.pressHover = myListTask['id'];
                                          await getListTaskInfoForeman(IntTest.pressHover);
                                          myStream.add(IntTest.indexScreensDispatcher);
                                          IntTest.indexScreensDispatcher = 3;
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
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                ///Название
                                                if(myListTask['object_id'] != null)
                                                Expanded(
                                                    child: Text('${myListTask['object_id']['name']}')),

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

                                                  Expanded(
                                                      child: Row(
                                                    mainAxisAlignment: MainAxisAlignment.center,
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

                                                ///Проверка
                                                Expanded(child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    ElevatedButton(
                                                      style: ElevatedButton.styleFrom(
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
