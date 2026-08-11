import 'dart:convert';
import 'dart:html';
import 'dart:typed_data';
import 'package:email_validator/email_validator.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../helper/button/my_button.dart';
import 'package:http/http.dart' as http;
import '../../../helper/class_colors.dart';
import '../../home_page/home_page.dart';
import '../../object/widgets/add_plot.dart';
import '../bloc/employee_bloc.dart';
import '../view/employees_screen.dart';

/// Окно добавление сотрудника



bool myBoolTest = false;

/// Прораб =======================
getForemanObjectList() async {
  final url =
      'http://${IntTest.myIp}/api/v1/universal-user/sort-by-role/2/?page=1';
  final res = await http.get(Uri.parse(url), headers: {
    "Content-Type": "application/json; charset=utf-8",
    'Accept': 'application/json',
    'Authorization': 'Bearer ${IntTest.token}',
  });
  var response = jsonDecode(utf8.decode(res.bodyBytes));
  foremanList = response['data'];
  myStream.add(IntTest.indexScreens);
  // print(organizationList);
}
String? foremanTitle;
List foremanList = [];
/// ==============================


/// Механик ========================
getMechanicObjectList() async {
  final url =
      'http://${IntTest.myIp}/api/v1/universal-user/sort-by-role/3/?page=1';
  final res = await http.get(Uri.parse(url), headers: {
    "Content-Type": "application/json; charset=utf-8",
    'Accept': 'application/json',
    'Authorization': 'Bearer ${IntTest.token}',
  });
  var response = jsonDecode(utf8.decode(res.bodyBytes));
  mechanicList = response['data'];
  myStream.add(IntTest.indexScreens);
  // print(mechanicList);
}
String? mechanicTitle;
List mechanicList = [];
/// ================================

class AddEmployee extends StatefulWidget {
  const AddEmployee({Key? key}) : super(key: key);

  @override
  State<AddEmployee> createState() => _AddEmployeeState();
}

class _AddEmployeeState extends State<AddEmployee> {
  /// Создание юзера ======
  createUser() async {
    var response = await http.post(
      Uri.parse("http://${IntTest.myIp}/$myLink/"),
      headers: {
        "Content-Type": "application/json; charset=utf-8",
        'Authorization': 'Bearer ${IntTest.token}',
      },
      body: json.encode(
        {
          "name": fio.text,
          "email": email.text,
          "password": newUserPassword.text,
          "contact_phone": numberPhone.text,
          "birthday": dateBirth.millisecondsSinceEpoch / 1000,
          "location_id": 1,
          "role_id": myJobTitle,
          // "working_specialty_id": 2,
          "division_id": myPlotTitle,
          "date_of_employment": employmentDate.millisecondsSinceEpoch / 1000,

          /// DateTime.now().millisecondsSinceEpoch/1000, отправлять в секундах
          /// DateTime.fromMillisecondsSinceEpoch(1666349129*1000) полученая дата из милисекунд
        },
      ),
    );
    var listAddEmployee = jsonDecode(utf8.decode(response.bodyBytes));
    print(listAddEmployee['data']);
    getEmployee.add(listAddEmployee['data']);
    getListEmployee();
    EmployeeBloc().add(EmployeeGetUserEvent());
    myStream.add(IntTest.indexScreens);
  }
  late String myLink;
  /// =====================

  /// ФИО
  TextEditingController fio = TextEditingController();

  /// Номер телефона
  TextEditingController numberPhone = TextEditingController();

  /// Электронная почта
  TextEditingController email = TextEditingController();

  /// Пароль юсера
  TextEditingController passwordUser = TextEditingController();

  /// Документ Удостоверение
  TextEditingController document = TextEditingController();

  /// Документ ЦОК
  TextEditingController classification = TextEditingController();

  /// Пароль нового юзера
  TextEditingController newUserPassword = TextEditingController();

  /// Включение камеры
  bool imageAvailable = false;

  /// Данные камеры
  late Uint8List imageFile;

  /// Доступ в систему
  var accessToSystem = true;

  /// Права суперпользователя
  var superuserRights = true;




  /// Должность ===================
  getEmployeeJobTitle() async {
    final url = 'http://${IntTest.myIp}/api/v1/roles/?page=1';
    final res = await http.get(Uri.parse(url), headers: {
      "Content-Type": "application/json; charset=utf-8",
      'Accept': 'application/json',
      'Authorization': 'Bearer ${IntTest.token}',
    });
    var response = jsonDecode(utf8.decode(res.bodyBytes));
    setState(() {
      jobTitleList = response['data'];
    });
    print(jobTitleList);
  }
  String? myJobTitle;
  List jobTitleList = [];

  /// =============================

  DateTime employmentDate = DateTime.now();

  DateTime dateBirth = DateTime.now();

  @override
  void initState() {
    myPlotTitle = null;
    // TODO: implement initState
    super.initState();
    getEmployeeJobTitle();
    getPlot();
  }

  @override
  Widget build(BuildContext context) {
    final keyFio = GlobalKey<FormState>();
    final keyEmail = GlobalKey<FormState>();
    final keyPhoneNumber = GlobalKey<FormState>();
    final keyPasswordNewEmployee = GlobalKey<FormState>();
    final Size size = MediaQuery.of(context).size;

    return StreamBuilder(
        stream: myStream.stream,
        builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
          return SizedBox(
            width: size.width > 570.0 ? 500.0 : 320.0,
            height: MediaQuery.of(context).size.height * 0.98,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  /// Текст кнопка закрыть
                  Row(
                    children: [
                      /// Текст
                      Text(
                        'Добавление сотрудника',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: size.width > 570.0 ? 25.0 : 16.0),
                      ),
                      const Spacer(),
                      /// кнопка закрыть
                      IconButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          icon: const Icon(
                            Icons.close,
                            color: ColorApp.myColorGreenAuth,
                          )),
                    ],
                  ),
                  SizedBox(height: size.width > 570.0 ? 20.0 : 10.0),

                  ///ФИО
                  Form(
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    key: keyFio,
                    child: TextFormField(
                      cursorColor: ColorApp.myColorGray,
                      controller: fio,
                      decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: ColorApp.myColorGreenAuth),
                          ),
                          labelText: 'ФИО',
                          labelStyle: TextStyle(color: ColorApp.myColorGray)),
                      validator: (value) {
                        if (value!.isEmpty ||
                            !RegExp(r'^[а-я А-Я]+$').hasMatch(value)) {
                          return 'Некоректное Имя';
                        } else {
                          return null;
                        }
                      },
                    ),
                  ),
                  SizedBox(height: size.width > 570.0 ? 20.0 : 10.0),

                  ///Номер телефона
                  Form(
                    key: keyPhoneNumber,
                    child: TextFormField(
                      maxLength: 10,
                      cursorColor: ColorApp.myColorGray,
                      controller: numberPhone,
                      decoration: const InputDecoration(
                          prefixIcon: Padding(
                            padding: EdgeInsets.only(left: 10.0, top: 11.0),
                            child: Text('+7'),
                          ),
                          border: OutlineInputBorder(),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: ColorApp.myColorGreenAuth),
                          ),
                          labelText: 'Номер телефона',
                          labelStyle: TextStyle(color: ColorApp.myColorGray)),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value!.length > 10 ||
                            !RegExp(r'^[+]*[(]{0,1}[0-9]{1,4}[)]{0,1}[-\s\./0-9]+$')
                                .hasMatch(value)) {
                          return 'Некорректный номер телефона';
                        } else {
                          return null;
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 10.0),

                  ///Электронная почта
                  Form(
                    key: keyEmail,
                    child: TextFormField(
                      cursorColor: ColorApp.myColorGray,
                      controller: email,
                      decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: ColorApp.myColorGreenAuth),
                          ),
                          labelText: 'Электронная почта',
                          labelStyle: TextStyle(color: ColorApp.myColorGray)),
                      keyboardType: TextInputType.emailAddress,
                      validator: (email) =>
                      email != null && !EmailValidator.validate(email)
                          ? 'Не корректный email'
                          : null,
                    ),
                  ),
                  SizedBox(height: size.width > 570.0 ? 20.0 : 10.0),
                  ///Дата приема на работу и Дата рождения
                  Row(
                    children: [
                      ///Дата приема на работу
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Дата приема на работу',
                              style: TextStyle(
                                  fontSize: 15.0,
                                  fontWeight: FontWeight.bold,
                                  color: ColorApp.myColorGrayText),
                            ),
                            const SizedBox(height: 10.0),
                            InkWell(
                                onTap: () async {
                                  final DateTime? dateTime =
                                  await showDatePicker(
                                      context: context,
                                      initialDate: employmentDate,
                                      firstDate: DateTime(2000),
                                      lastDate: DateTime(3000));
                                  if (dateTime != null) {
                                    employmentDate = dateTime;
                                    setState(() {});
                                    employmentDate = DateTime.utc(dateTime.year, dateTime.month, dateTime.day, dateTime.hour, dateTime.minute); // указываем UTC часовой пояс
                                    int unixTime = employmentDate.toUtc().millisecondsSinceEpoch ~/ 1000; // переводим в Unix time с учетом UTC часового пояса
                                    employmentDate = unixTime as DateTime;
                                  }
                                },
                                child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                                    height: 50,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(5.0),
                                      border: Border.all(width: 1.0,color: Colors.grey),
                                    ),
                                    child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('${employmentDate.day} - ${employmentDate.month} - ${employmentDate.year}',style: const TextStyle(color: Colors.grey,fontSize: 16.0),),
                                          const Icon(Icons.calendar_month_outlined,color: Colors.grey)]))),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10.0),

                      ///Дата рождения
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Дата рождения',
                              style: TextStyle(
                                  fontSize: 15.0,
                                  fontWeight: FontWeight.bold,
                                  color: ColorApp.myColorGrayText),
                            ),
                            const SizedBox(height: 10.0),
                            InkWell(
                                onTap: () async {
                                  final DateTime? dateTime =
                                  await showDatePicker(
                                      context: context,
                                      initialDate: dateBirth,
                                      firstDate: DateTime(1900),
                                      lastDate: DateTime(3000));
                                  if (dateTime != null) {
                                    dateBirth = dateTime;
                                    setState(() {});
                                    dateBirth = DateTime.utc(dateTime.year, dateTime.month, dateTime.day, dateTime.hour, dateTime.minute); // указываем UTC часовой пояс
                                    int unixTime = dateBirth.toUtc().millisecondsSinceEpoch ~/ 1000; // переводим в Unix time с учетом UTC часового пояса
                                    dateBirth = unixTime as DateTime;
                                  }
                                },
                                child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                                    height: 50,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(5.0),
                                      border: Border.all(width: 1.0,color: Colors.grey),
                                    ),
                                    child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('${dateBirth.day} - ${dateBirth.month} - ${dateBirth.year}',style: const TextStyle(color: Colors.grey,fontSize: 16.0),),
                                          const Icon(Icons.calendar_month_outlined,color: Colors.grey)]))),
                          ],
                        ),
                      ),
                    ],
                  ),

                  /// Divider
                  Column(
                    children: const [
                      SizedBox(height: 20.0),
                      Divider(color: ColorApp.myColorGray),
                      SizedBox(height: 20.0),
                    ],
                  ),
                  if (size.width < 570.0) const SizedBox(height: 10.0),
                  /// Участок Должность
                  Row(
                    children: [
                      /// Участок
                      Expanded(
                        child: SizedBox(
                          height: 50.0,
                          child: DropdownButtonFormField(
                            isExpanded: true,
                            value: myPlotTitle,
                            hint: const Text('Участок'),
                            onChanged: (newValue1) async {
                              setState(() {
                                myPlotTitle = newValue1 as String?;
                                myPlotTitle!.indexOf(newValue1!);
                                print(myPlotTitle);
                              });
                            },
                            items: plotList.map((jobTitleList) {
                              return DropdownMenuItem(
                                value: jobTitleList['id'].toString(),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text('${jobTitleList['title']}',
                                          overflow: TextOverflow.ellipsis),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            decoration: InputDecoration(
                                prefixIcon: IconButton(
                                    onPressed: () async {
                                      setState(() {
                                        showDialog(
                                            context: context,
                                            builder: (context) =>
                                                AlertDialog(
                                                  content: AddPlot(),
                                                )).then((value) => setState((){}));
                                      });
                                    },
                                    icon: const Icon(
                                        Icons.add_box_rounded,
                                        size: 20.0,
                                        color: ColorApp.myColorGreenAuth)),
                                border: const OutlineInputBorder()),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10.0),
                      /// Должность
                      Expanded(
                        child: SizedBox(
                          height: 50.0,
                          child: DropdownButtonFormField(
                            // icon: const Icon(Icons.add),
                            value: myJobTitle,
                            hint: const Text('Должность'),
                            onChanged: (newValue1) async {
                              setState(() {
                                myJobTitle = newValue1 as String?;
                                myJobTitle!.indexOf(newValue1!);
                                if(myJobTitle == '1'){
                                  myLink = 'api/v1/cp/admin/create-admin';
                                  print(myLink);
                                }
                                else if(myJobTitle == '6') {
                                  myLink = 'api/v1/cp/admin/create-client';
                                  print(myLink);
                                }else{
                                  myLink = 'api/v1/cp/admin/create-employee';
                                  print(myLink);
                                }
                              });
                              print(myJobTitle);
                              print(myLink);
                            },
                            items: jobTitleList.map((jobTitle) {
                              return DropdownMenuItem(
                                value: jobTitle['id'].toString(),
                                child: Text(jobTitle['name']),
                              );
                            }).toList(),
                            decoration:  const InputDecoration(
                                border: OutlineInputBorder()),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (size.width > 570.0)
                  /// Divider
                    Column(
                      children: const [
                        SizedBox(height: 20.0),
                        Divider(color: ColorApp.myColorGray),
                        SizedBox(height: 20.0),
                      ],
                    ),
                  // if (size.width < 570.0) const SizedBox(height: 10.0),

                  /// Добавить Фото Документа
                  // Row(
                  //   children: [
                  //     /// Документ
                  //     Expanded(
                  //       child: TextFormField(
                  //         cursorColor: ColorApp.myColorGray,
                  //         controller: document,
                  //         decoration: const InputDecoration(
                  //             border: OutlineInputBorder(),
                  //             focusedBorder: OutlineInputBorder(
                  //               borderSide:
                  //               BorderSide(color: ColorApp.myColorGreenAuth),
                  //             ),
                  //             labelText: 'Документ',
                  //             labelStyle: TextStyle(color: ColorApp.myColorGray)),
                  //       ),
                  //     ),
                  //     const SizedBox(width: 10.0),
                  //     Expanded(
                  //       child: InkWell(
                  //         onTap: () async {
                  //           final imageDocument = await ImagePickerWeb();
                  //         },
                  //         child: DottedBorder(
                  //           color: ColorApp.myColorGray,
                  //           child: const SizedBox(
                  //             height: 44.0,
                  //             child: Center(
                  //               child: Icon(Icons.backup_outlined,
                  //                   color: ColorApp.myColorGray),
                  //             ),
                  //           ),
                  //         ),
                  //       ),
                  //     ),
                  //   ],
                  // ),
                  // SizedBox(height: size.width > 570.0 ? 20.0 : 10.0),

                  /// Добавить ЦОК
                  // Row(
                  //   children: [
                  //     Expanded(
                  //       child: TextFormField(
                  //         cursorColor: ColorApp.myColorGray,
                  //         controller: classification,
                  //         decoration: const InputDecoration(
                  //             border: OutlineInputBorder(),
                  //             focusedBorder: OutlineInputBorder(
                  //               borderSide:
                  //               BorderSide(color: ColorApp.myColorGreenAuth),
                  //             ),
                  //             labelText: 'ЦОК',
                  //             labelStyle: TextStyle(color: ColorApp.myColorGray)),
                  //       ),
                  //     ),
                  //     const SizedBox(width: 10.0),
                  //     Expanded(
                  //       child: InkWell(
                  //         onTap: () async {
                  //           final imageClassification =
                  //           await ImagePickerWeb.getImageInfo;
                  //         },
                  //         child: DottedBorder(
                  //           color: ColorApp.myColorGray,
                  //           child: const SizedBox(
                  //             height: 44.0,
                  //             child: Center(
                  //               child: Icon(Icons.backup_outlined,
                  //                   color: ColorApp.myColorGray),
                  //             ),
                  //           ),
                  //         ),
                  //       ),
                  //     ),
                  //   ],
                  // ),
                  // SizedBox(height: size.width > 570.0 ? 20.0 : 10.0),
                  /// Пароль нового юзера
                  Form(
                    key: keyPasswordNewEmployee,
                    child: TextFormField(
                      cursorColor: ColorApp.myColorGray,
                      controller: newUserPassword,
                      decoration: const InputDecoration(
                        // suffixIcon: IconButton(onPressed: (){},icon: const Icon(Icons.calendar_month_outlined),),
                          border: OutlineInputBorder(),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: ColorApp.myColorGreenAuth),
                          ),
                          labelText: 'Придумайте пароль',
                          labelStyle: TextStyle(color: ColorApp.myColorGray)),
                      validator: (value) {
                        if (value!.length < 4) {
                          return 'Минимум 4 символа';
                        } else {
                          return null;
                        }
                      },
                    ),
                  ),
                  SizedBox(height: size.width > 570.0 ? 20.0 : 10.0),
                  /// Кнопка Сохранить
                  MainButtonApp(
                    textButton: 'Сохранить',
                    press: () async {
                      keyFio.currentState!.validate();
                      keyPhoneNumber.currentState!.validate();
                      keyEmail.currentState!.validate();
                      keyPasswordNewEmployee.currentState!.validate();
                      if (keyFio.currentState!.validate() &&
                          keyPhoneNumber.currentState!.validate() &&
                          keyEmail.currentState!.validate() &&
                          keyPasswordNewEmployee.currentState!.validate()) {
                        await createUser();
                        await getMechanicObjectList();
                        await getForemanObjectList();
                        myStream.add(IntTest.indexScreens);
                        Navigator.pop(context);
                        setState(() {});
                      }
                    },
                  ),
                ],
              ),
            ),
          );});

  }
}

