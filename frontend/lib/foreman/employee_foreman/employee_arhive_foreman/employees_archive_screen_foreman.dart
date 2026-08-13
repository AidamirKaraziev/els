import 'dart:convert';
import 'package:els/helper/api_config.dart';
import 'package:els/screns/employee/widgets/topButton.dart';
import 'package:flutter/material.dart';
import '../../../helper/class_colors.dart';
import '../../../helper/header/header.dart';
import '../../../helper/my_drawer/my_drawer.dart';
import 'package:http/http.dart' as http;
import '../../../screns/home_page/home_page.dart';
import '../../user_page_foreman.dart';
import '../employees_screen_foreman.dart';
import 'package:els/helper/api_client.dart';

/// Сотрудники Архив

final employeeScrollController = ScrollController();
int pageEmployee = 1;
late int testId;

Map listSelectedEmployeeForemanArchive = {};

///Получение данных одного сотрудника архив =============
getListEmployeesInfoForemanArchive(int userId) async {
  await Future(() async {
    final res = await Api.get(
        Uri.parse("${ApiConfig.base}/cp/universal-user/$userId/"),
        headers: {
          "Content-Type": "application/json; charset=utf-8",
        });
    var vova = jsonDecode(utf8.decode(res.bodyBytes));
    listSelectedEmployeeForemanArchive = vova['data'];
    print(listSelectedEmployeeForeman);
  });
}
/// =====================================================


///Сотрудники ================================================================
class EmployeesArchiveScreenForeman extends StatefulWidget {
  const EmployeesArchiveScreenForeman({
    Key? key,
  }) : super(key: key);


  @override
  State<EmployeesArchiveScreenForeman> createState() => _EmployeesArchiveScreenForemanState();
}

class _EmployeesArchiveScreenForemanState extends State<EmployeesArchiveScreenForeman> {

  int isHover = -1;
  int pressHover = -1;
  bool isSortTest = false;
  bool archivedEmployees = false;


  /// Функция поиска по имени ========================
  void _runEmployeeFilter(String enteredKeyword) {
    List result = [];
    if(enteredKeyword.isEmpty){
      result = getEmployeeForeman;
    }else{
      result = getEmployeeForeman.where((user) => user['name'].toLowerCase().contains(enteredKeyword.toLowerCase())).toList();
    }
    setState(() {
      dataEmployeeForeman = result;
    });
  }
  /// ================================================

  @override
  void initState() {
    getListEmployeeForeman();
    dataEmployeeForeman = getEmployeeForeman;
    setState(() {});
    // TODO: implement initState
    super.initState();
  }

  bool openListSearch = false;

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
                ///Header ========
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(width: 0.3, color: Colors.grey.shade200),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal:ColorApp.kPadding),
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
                                    size: size.width > 350
                                        ? 25.0
                                        : 20)),
                            const SizedBox(width: 10.0),
                          ],
                        ),
                      /// Кнопка Назад
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
                                onPressed: () async {
                                  await getListEmployeeForeman();
                                  IntTest.indexScreensForeman = 5;
                                  myStream.add(IntTest.indexScreensForeman);
                                },
                                icon: const Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  color: Colors.black,
                                  size: 13.0,
                                )),
                          ),
                          const SizedBox(width: 17.0),
                        ],
                      ),
                      /// Текст
                      Text('Сотрудники архив',
                          style: TextStyle(
                              fontSize: size.width > 350
                                  ? 25.0
                                  : 18.0,
                              fontWeight: size.width > 350
                                  ? FontWeight.w700
                                  : FontWeight.w500)),
                      const SizedBox(width: 10.0),
                      /// Список архивированных Сотрудников
                      if (size.width > 500)
                        IconButton(
                            onPressed: () async {
                              await getListEmployeeForeman();
                              IntTest.indexScreensForeman = 5;
                              myStream.add(IntTest.indexScreensForeman);
                              setState(() {});
                            },
                            icon: const Icon(
                                Icons.archive_outlined,
                                size: 25.0,
                                color: ColorApp.myColorGreenAuth)),

                      ///Поиск Компании
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
                                  icon: const Icon(
                                      Icons.search,
                                      size: 25.0,
                                      color: ColorApp
                                          .myColorGray)),
                          ],
                        ),
                      if (openListSearch)
                        Row(
                          children: [
                            const SizedBox(width: 10),
                            SizedBox(
                              width:
                              MediaQuery.of(context)
                                  .size
                                  .width *
                                  0.3,
                              height: 40.0,
                              child: Form(
                                child: TextField(
                                  onChanged: (value) => _runEmployeeFilter(value),
                                  cursorColor: ColorApp
                                      .myColorGray,
                                  decoration:
                                  InputDecoration(
                                      contentPadding:
                                      const EdgeInsets.all(0.0),
                                      prefixIcon: IconButton(
                                          onPressed: () {},
                                          icon: const Icon(Icons.search)),
                                      suffixIcon:
                                      IconButton(
                                          onPressed: () {
                                            setState(() {
                                              dataEmployeeForeman = getEmployeeForeman;
                                            });
                                            openListSearch = false;
                                            // myStream.add(IntTest.indexScreens);
                                          },
                                          icon: const Icon(Icons.close)),
                                      border:
                                      const OutlineInputBorder(),
                                      focusedBorder:
                                      const OutlineInputBorder(
                                          borderSide:
                                          BorderSide(color: ColorApp.myColorGreenAuth)),
                                      labelText: 'Поиск',
                                      labelStyle: const TextStyle(color: ColorApp.myColorGray)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      const Spacer(),
                      ///Колокольчик
                      if (size.width > 400)
                        Badge(
                          alignment:
                          const AlignmentDirectional(21, 4),
                          backgroundColor: ColorApp.myColorRed,
                          isLabelVisible: IntTest.badgeCount > 0
                              ? true
                              : false,
                          label: IntTest.badgeCount < 1
                              ? const SizedBox.shrink()
                              : Text(
                              IntTest.badgeCount.toString(),
                              style: const TextStyle(
                                  fontSize: 12.0,
                                  color:
                                  ColorApp.myColorWhite,
                                  fontWeight:
                                  FontWeight.w500)),
                          child: IconButton(
                            onPressed: () {},
                            icon: const Icon(
                                Icons
                                    .notifications_none_outlined,
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
                        ///ФИО
                        Expanded(
                            child: Row(
                              children: [
                                TopButtonWidget(
                                  text: 'ФИО',
                                  press: () {
                                    myColorButton = 1;
                                    setState(() {});
                                  },
                                  pressIcon: () {},
                                  colorButton: ColorApp.myColorWhite,
                                  colorText:  ColorApp.myColorBlack,
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
                        ///Участок
                        if (size.width > 550) Expanded(
                          child: Row(
                            children: [
                              TopButtonWidget(
                                text: 'Участок',
                                press: () {
                                  myColorButton = 2;
                                  setState(() {
                                    print(getEmployeeForeman[0]['division_id']['id']);
                                  });
                                },
                                pressIcon: () {},
                                colorButton: ColorApp.myColorWhite,
                                colorText:  ColorApp.myColorBlack,
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
                        ///Номер телефона
                        if (size.width > 1050)  Expanded(
                          child: Row(
                            children: [
                              TopButtonWidget(
                                text: 'Номер телефона',
                                press: () {
                                  myColorButton = 3;
                                  setState(() {});
                                },
                                pressIcon: () {},
                                colorButton: ColorApp.myColorWhite,
                                colorText:  ColorApp.myColorBlack,
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
                        // Expanded(child: Text('Номер телефона'))
                        ///Должность
                        if (size.width > 600)Expanded(
                          child: Row(
                            children: [
                              TopButtonWidget(
                                text: 'Должность',
                                press: () {
                                  myColorButton = 3;
                                  print(getEmployeeForeman[0]['role_id']['id']);
                                  setState(() {});
                                },
                                pressIcon: () {},
                                colorButton: ColorApp.myColorWhite,
                                colorText:  ColorApp.myColorBlack,
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
                      ],
                    ),
                  ),
                ),
                /// =============
                Expanded(
                  child: ListView.builder(
                    controller: employeeScrollController,
                    itemCount: dataEmployeeForeman.length,
                    itemBuilder: (context, index) {
                      final employeeArchived = dataEmployeeForeman[index];
                      return  employeeArchived['is_actual'] != false
                          ? Container()
                          : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child: Card(
                          key: ValueKey(employeeArchived[index]),
                          child: InkWell(
                            onTap: () async {
                              IntTest.indexUserList = index;
                              IntTest.pressHover = employeeArchived['id'];
                              await getListEmployeesInfoForemanArchive(employeeArchived['id']);
                              myStream.add(IntTest.indexScreensForeman);
                              IntTest.indexScreensForeman = 23;
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
                                  color: Colors.grey.shade300
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    ///ФИО
                                    Expanded(
                                      child: Container(
                                        height: 60,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(10),
                                          color: isHover == index
                                              ? Colors.grey.shade200
                                              : Colors.grey.shade300,
                                        ),
                                        child: Row(
                                          children: [
                                            Padding(
                                              padding: const EdgeInsets.symmetric(horizontal: 10.0),
                                              child: StreamBuilder(
                                                stream: myStream.stream,
                                                builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                                                  return CircleAvatar(
                                                    foregroundImage:
                                                    // newPhotoSelectEmployee != '' ? NetworkImage('${ApiConfig.scheme}://$newPhotoSelectEmployee') :
                                                    NetworkImage('${ApiConfig.scheme}://${employeeArchived['photo']}'),
                                                    backgroundImage: const AssetImage('assets/user.png'),
                                                  );
                                                },
                                              ),
                                            ),
                                            Expanded(
                                              child:
                                              employeeArchived['name'] == null
                                                  ? const Text('')
                                                  : Text(employeeArchived['name'],
                                                  style: TextStyle(
                                                      fontSize: size.width > 450 ? 14 : 12)),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    ///Участок
                                    if (size.width > 550) Expanded(child: Row(
                                      children: [
                                        const SizedBox(width: 20.0),
                                        employeeArchived['division_id'] == null
                                            ? const Text('')
                                            : Text(employeeArchived['division_id']['title'].toString(),
                                            style: TextStyle(fontSize: size.width > 450 ? 14 : 12)),
                                      ],
                                    )),
                                    ///Номер телефона
                                    if (size.width > 1050) Expanded(
                                        child: employeeArchived['contact_phone'] != null
                                            ? Text(employeeArchived['contact_phone'])
                                            : const Text('')),
                                    ///Должность
                                    Expanded(
                                        child: employeeArchived['role_id'] != null
                                            ? Text(employeeArchived['role_id']['name'])
                                            : const Text('')),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20.0),
              ],
            ),
          ),
        );
      },
    );

  }
  /// Функция запроса на новую страницу
  // void _scrollListener (){
  //   if(employeeScrollController.position.pixels == employeeScrollController.position.maxScrollExtent){
  //     pageEmployee = pageEmployee + 1;
  //     print(pageEmployee);
  //     EmployeeBloc().add(EmployeeGetUserEvent());
  //     // getEmployee = listSelectedEmployee['data'];
  //     setState(() {});
  //   }else{
  //     // print('НЕЕЕЕЕ Сработал СкроллКонроллер');
  //   }
  // }
}
///===========================================================================