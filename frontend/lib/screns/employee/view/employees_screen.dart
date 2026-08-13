import 'dart:convert';
import 'package:els/helper/api_config.dart';
import 'package:els/screns/employee/widgets/topButton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../dispatcher/task_screen_dispatcher/application_screen_completed.dart';
import '../../../helper/class_colors.dart';
import '../../../helper/header/header.dart';
import '../../../helper/my_drawer/my_drawer.dart';
import '../../../helper/my_user.dart';
import '../../home_page/home_page.dart';
import 'package:http/http.dart' as http;
import '../bloc/employee_bloc.dart';
import '../widgets/add_employee.dart';
import 'employees_archive_screen.dart';
import 'package:els/helper/api_client.dart';
import 'package:els/helper/api_image.dart';

///Сотрудники

/// Список сотрудников
Map listSelectedEmployee = {};
Map listSelectedEmployeeArchived = {};
List getEmployee = [];
List dataEmployee = [];
List dataDeleteUserEmployee = [];
List listArchivedEmployees = [];

int newScreensEmployee = 1;


final employeeScrollController = ScrollController();

var myColorButtonEmployee;



/// Получение списка сотрудников ===
getListEmployee() async{
  final res = await Api.get(
      Uri.parse('${ApiConfig.base}/cp/all-employee/?page=$newScreensEmployee'),
      headers: {
        "Content-Type": "application/json; charset=utf-8",
        'Accept': 'application/json',
      });
  Map vova = jsonDecode(utf8.decode(res.bodyBytes));
  dataEmployee = vova['data'];
  dataEmployee.removeWhere((key) => key['role_id']['id'] == 1);


  print(dataEmployee[0]['role_id']['id']);
  myStream.add(IntTest.indexScreens);
}
/// ================================

///Получение данных одного сотрудника ======
getListEmployeesInfo(int userId) async {
  await Future(() async {
    final res = await Api.get(
        Uri.parse("${ApiConfig.base}/cp/universal-user/$userId/"),
        headers: {
          "Content-Type": "application/json; charset=utf-8",
        });
    var vova = jsonDecode(utf8.decode(res.bodyBytes));
    listSelectedEmployee = vova;
    print(listSelectedEmployee['data']['id']);

  });
}
/// ========================================


///Сотрудники ==================================================
class EmployeesScreen extends StatefulWidget {
  const EmployeesScreen({
    Key? key,
  }) : super(key: key);


  @override
  State<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends State<EmployeesScreen> {

  int isHover = -1;
  int pressHover = -1;
  bool isSortTest = false;

  /// Функция поиска по имени ========================
  void _runEmployeeFilter(String enteredKeyword) {
    List result = [];
    if(enteredKeyword.isEmpty){
      result = getEmployee;
    }else{
      result = getEmployee
          .where((user) => myColorButtonEmployee == 1
          ? user['name'].toLowerCase().contains(enteredKeyword.toLowerCase()) : myColorButtonEmployee == 2
          ? user['division_id']['title'].toLowerCase().contains(enteredKeyword.toLowerCase()) : myColorButtonEmployee == 3
          ? user['contact_phone'].toLowerCase().contains(enteredKeyword.toLowerCase())
          : user['role_id']['name'].toLowerCase().contains(enteredKeyword.toLowerCase()))
          .toList();
    }
    setState(() {
      print(result);
      dataEmployee = result;
    });
  } //<<<<<<<<<
  /// ================================================

  final ScrollController _controller = ScrollController();

  @override
  void initState() {
    myColorButtonEmployee = 1;
    EmployeeBloc().add(EmployeeGetUserEvent());
    dataEmployee = getEmployee;
    getListEmployee();
    // _controller.addListener(_loadMore);
    // TODO: implement initState
    super.initState();
  }

  @override
  void dispose() {
    newScreensEmployee = 1;
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
                      /// Текст
                      Text('Сотрудники',
                          style: TextStyle(
                              fontSize: size.width > 350
                                  ? 25.0
                                  : 18.0,
                              fontWeight: size.width > 350
                                  ? FontWeight.w700
                                  : FontWeight.w500)),
                      const SizedBox(width: 10.0),
                      ///Добавить Сотрудника
                      IconButton(
                          onPressed: () async {
                            setState(() {
                              showDialog(
                                  context: context,
                                  builder: (context) =>
                                  const AlertDialog(
                                    content: AddEmployee(),
                                  )).then((value) => setState((){}));
                            });
                          },
                          icon: const Icon(
                              Icons.add_box_rounded,
                              size: 25.0,
                              color: ColorApp
                                  .myColorGreenAuth)),

                      /// Список архивированных Сотрудников
                      if (size.width > 500)
                        IconButton(
                            onPressed: () async {
                              await getListEmployeeArchived();
                              IntTest.indexScreens = 15;
                              myStream.add(IntTest.indexScreens);
                            },
                            icon: const Icon(
                                Icons.archive_outlined,
                                size: 25.0,
                                color: ColorApp.myColorGray)),

                      ///Поиск
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
                                      color: ColorApp.myColorGray)),
                          ],
                        ),
                      if (openListSearch)
                        Row(
                          children: [
                            const SizedBox(width: 10),
                            SizedBox(
                              width:
                              MediaQuery.of(context).size.width * 0.3,
                              height: 40.0,
                              child: Form(
                                child: TextField(
                                  onChanged: (value) => _runEmployeeFilter(value),
                                  cursorColor: ColorApp.myColorGray,
                                  decoration:
                                  InputDecoration(
                                      contentPadding:
                                      const EdgeInsets.all(0.0),
                                      prefixIcon: IconButton(
                                          onPressed: () {},
                                          icon: const Icon(Icons.search)),
                                      suffixIcon: IconButton(
                                          onPressed: () {
                                            setState(() {
                                              dataEmployee = getEmployee;
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
                                      labelText: myColorButtonEmployee == 1
                                          ? 'Поиск по имени' : myColorButtonEmployee == 2
                                          ? 'Поиск по участку' : myColorButtonEmployee == 3
                                          ? 'Поиск по телефону' : 'Поиск по должности',
                                      labelStyle: const TextStyle(color: ColorApp.myColorGray)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      const Spacer(),

                      /// Переключение страницы
                      Row(
                        children: [
                          IconButton(onPressed: (){
                            if(newScreensEmployee > 1) {
                              --newScreensEmployee;
                            }
                            getListEmployee();
                            myStream.add(IntTest.indexScreens);
                          }, icon: const Icon(Icons.arrow_circle_left_outlined, color: Color(0xffBADE89))),
                          const SizedBox(width: 10.0),
                          Text('$newScreensEmployee'),
                          const SizedBox(width: 10.0),
                          IconButton(onPressed: (){
                            if(dataEmployee.isNotEmpty) {
                              newScreensEmployee++;
                            }
                            getListEmployee();
                            myStream.add(IntTest.indexScreens);
                          }, icon: const Icon(Icons.arrow_circle_right_outlined, color: Color(0xffBADE89))),
                        ],
                      ),
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
                        ///ФИО
                        Expanded(
                            child: Row(
                              children: [
                                TopButtonWidget(
                                  text: 'ФИО',
                                  press: () {
                                    myColorButtonEmployee = 1;
                                    setState(() {});
                                  },
                                  pressIcon: () {},
                                  colorButton: myColorButtonEmployee == 1 ? ColorApp.myColorGreen : ColorApp.myColorWhite,
                                  colorText: myColorButtonEmployee == 1 ? Colors.white :  ColorApp.myColorBlack,
                                ),
                              ],
                            )),
                        ///Участок
                        if (size.width > 550) Expanded(
                          child: Row(
                            children: [
                              TopButtonWidget(
                                text: 'Участок',
                                press: () {
                                  myColorButtonEmployee = 2;
                                  setState(() {
                                  });
                                },
                                pressIcon: () {},
                                colorButton: myColorButtonEmployee == 2 ? ColorApp.myColorGreen : ColorApp.myColorWhite,
                                colorText: myColorButtonEmployee == 2 ? Colors.white :  ColorApp.myColorBlack,
                              ),
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
                                  myColorButtonEmployee = 3;
                                  setState(() {});
                                },
                                pressIcon: () {},
                                colorButton: myColorButtonEmployee == 3 ? ColorApp.myColorGreen : ColorApp.myColorWhite,
                                colorText: myColorButtonEmployee == 3 ? Colors.white :  ColorApp.myColorBlack,
                              ),
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
                                  myColorButtonEmployee = 4;
                                  setState(() {});
                                },
                                pressIcon: () {},
                                colorButton: myColorButtonEmployee == 4 ? ColorApp.myColorGreen : ColorApp.myColorWhite,
                                colorText: myColorButtonEmployee == 4 ? Colors.white :  ColorApp.myColorBlack,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                /// Основной
                BlocBuilder<EmployeeBloc, EmployeeState>(
                  builder: (context, state) {
                    return Expanded(
                  child: ListView.builder(
                    controller: _controller,
                    itemCount: dataEmployee.length,
                    itemBuilder: (context, index) {
                      // dataEmployee.sort((a, b) => a['name'].compareTo(b['name']));
                      final employee = dataEmployee[index];
                      return employee['is_active'] == false ? Container() : Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Card(
                          key: ValueKey(dataEmployee[index]),
                          child:  InkWell(
                            onTap: () async {
                              IntTest.indexUserList = index;
                              IntTest.pressHover = employee['id'];
                              await getListEmployeesInfo(IntTest.pressHover);
                              myStream.add(IntTest.indexScreens);
                              print('нажал');
                              IntTest.indexScreens = 11;
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
                                  borderRadius: BorderRadius.circular(5.0),
                                  color: isHover == index
                                      ? Colors.grey.shade50
                                      : ColorApp.myColorWhite,
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
                                                ? ColorApp.myColorWhite
                                                : ColorApp.myColorGrayShadow,
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
                                                      // newPhotoSelectEmployee != '' ? apiImage(newPhotoSelectEmployee) :
                                                      apiImage(dataEmployee[index]['photo']),
                                                      backgroundImage: const AssetImage('assets/user.png'),
                                                    );
                                                  },
                                                ),
                                              ),
                                              Expanded(
                                                  child:
                                                  getEmployee[index]['name'] == null
                                                      ? const Text('')
                                                      : Text(employee['name'],
                                                      style: TextStyle(fontSize: size.width > 450 ? 14 : 12))),
                                            ],
                                          ),
                                        ),
                                      ),
                                      ///Участок
                                      if (size.width > 550) Expanded(
                                          child: Row(
                                            children: [
                                              const SizedBox(width: 20.0),
                                              employee['division_id'] == null
                                                  ? const Text('')
                                                  : Text(employee['division_id']['title'].toString(),
                                                  style: TextStyle(fontSize: size.width > 450 ? 14 : 12)),
                                            ],
                                          )),
                                      ///Номер телефона
                                      if (size.width > 1050) Expanded(
                                          child: employee['contact_phone'] != null
                                              ? Text('+7${employee['contact_phone']}')
                                              : const Text('')),
                                      ///Должность
                                      if (size.width > 600) Expanded(
                                          child: Text(employee['role_id']['name'])
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
  },
),
                const SizedBox(height: 20.0),
              ],
            ),
          ),
        );
      },
    );

  }

}
///=============================================================