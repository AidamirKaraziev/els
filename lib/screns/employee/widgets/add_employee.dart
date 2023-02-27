import 'dart:convert';
import 'dart:typed_data';
import 'package:dotted_border/dotted_border.dart';
import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:image_picker_web/image_picker_web.dart';
import '../../../helper/button/my_button.dart';
import '../../../helper/class_colors.dart';
import 'package:http/http.dart' as http;

import '../../home_page/home_page.dart';

/// Окно добавление сотрудника

class AddEmployee extends StatefulWidget {
  const AddEmployee({Key? key}) : super(key: key);

  @override
  State<AddEmployee> createState() => _AddEmployeeState();
}

class _AddEmployeeState extends State<AddEmployee> {
  /// Создание юзера ======
  createUser() async {
    var response = await http.post(
      Uri.parse("http://185.119.58.63/api/v1/cp/admin/create-employee/"),
      headers: {
        "Content-Type": "application/json; charset=utf-8",
        'Authorization': 'Bearer ${IntTest.token}',
      },
      body: json.encode(
        {
          "name": fio.text,
          "email": email.text,
          "password": "2",
          "contact_phone": numberPhone.text,
          "birthday": 1666349129,
          "location_id": 1,
          "role_id": 4,
          "working_specialty_id": 1,
          "division_id": 1,
          "date_of_employment": 1676707997
        },
      ),
    );
  }

  /// =====================

  /// очистка данных
  dataCleaningFunction() {
    fio.clear();
    numberPhone.clear();
    email.clear();
    dateBirth.clear();
    document.clear();
    classification.clear();
  }

  /// ФИО
  TextEditingController fio = TextEditingController();

  /// Номер телефона
  TextEditingController numberPhone = TextEditingController();

  /// Электронная почта
  TextEditingController email = TextEditingController();

  /// Дата рождения
  TextEditingController dateBirth = TextEditingController();

  /// Документ Удостоверение
  TextEditingController document = TextEditingController();

  /// Документ ЦОК
  TextEditingController classification = TextEditingController();

  /// Включение камеры
  bool imageAvailable = false;

  /// Данные камеры
  late Uint8List imageFile;

  /// Доступ в систему
  var accessToSystem = true;

  /// Права суперпользователя
  var superuserRights = true;

  /// Участок =========
  getPlot() async {
    final url = 'http://${IntTest.myIp}/api/v1/divisions/?page=1';
    final res = await http.get(Uri.parse(url), headers: {
      "Content-Type": "application/json; charset=utf-8",
      'Accept': 'application/json',
      'Authorization': 'Bearer ${IntTest.token}',
    });
    var response = jsonDecode(utf8.decode(res.bodyBytes));
    setState(() {
      plotList = response['data'];
    });
    print(plotList);
  }

  String? myPlotTitle;
  List plotList = [];

  /// =================

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

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getEmployeeJobTitle();
    getPlot();
    print('Сработал Инит Стате');
  }

  @override
  Widget build(BuildContext context) {
    final keyFio = GlobalKey<FormState>();
    final keyEmail = GlobalKey<FormState>();
    final keyPhoneNumber = GlobalKey<FormState>();
    final Size size = MediaQuery.of(context).size;

    return SizedBox(
      width: size.width > 570.0 ? 500.0 : 320.0,
      height: MediaQuery.of(context).size.height * 0.98,
      child: SingleChildScrollView(
        child: Column(
          children: [
            /// Текст и Фото
            Row(
              children: [
                Text(
                  'Добавление сотрудника',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: size.width > 570.0 ? 25.0 : 18.0),
                ),
                const Spacer(),

                /// Добавить Фото
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(50),
                      border: Border.all(color: ColorApp.myColorGray)),
                  child: imageAvailable
                      ? Image.memory(imageFile)
                      : IconButton(
                          onPressed: () async {
                            final image =
                                await ImagePickerWeb.getImageAsBytes();
                            setState(() {
                              imageFile = image!;
                              imageAvailable = true;
                            });
                          },
                          icon: const Icon(
                            Icons.add_a_photo_outlined,
                            color: ColorApp.myColorGray,
                            size: 20,
                          )),
                ),
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
                  if (value!.isEmpty ||
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

            /// Divider
            Column(
              children: const [
                SizedBox(height: 20.0),
                Divider(color: ColorApp.myColorGray),
                SizedBox(height: 20.0),
              ],
            ),
            if (size.width < 570.0) const SizedBox(height: 10.0),
            size.width > 570.0

                /// Участок & Должность
                ? Row(
                    children: [
                      /// Участок
                      Expanded(
                        child: SizedBox(
                          height: 50.0,
                          child: DropdownButtonFormField(
                            value: myPlotTitle,
                            hint: const Text('Участок'),
                            onChanged: (newValue1) async {
                              print('нажал');
                              setState(() {
                                myPlotTitle = newValue1 as String?;
                              });
                            },
                            items: plotList.map((jobTitleList) {
                              return DropdownMenuItem(
                                value: jobTitleList['id'],
                                child: Text(jobTitleList['title']),
                              );
                            }).toList(),
                            decoration: const InputDecoration(
                                border: OutlineInputBorder()),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10.0),

                      /// Должность
                      Expanded(
                        child: SizedBox(
                          height: 50.0,
                          child: DropdownButtonFormField(
                            value: myJobTitle,
                            hint: const Text('Должность'),
                            onChanged: (newValue1) async {
                              print('нажал');
                              setState(() {
                                myJobTitle = newValue1 as String?;
                              });
                            },
                            items: jobTitleList.map((jobTitle) {
                              return DropdownMenuItem(
                                value: jobTitle['id'],
                                child: Text(jobTitle['name']),
                              );
                            }).toList(),
                            decoration: const InputDecoration(
                                border: OutlineInputBorder()),
                          ),
                        ),
                      ),
                    ],
                  )

                /// Участок & Должность
                : Column(
                    children: [
                      /// Участок
                      SizedBox(
                        height: 50.0,
                        child: DropdownButtonFormField(
                          value: myPlotTitle,
                          hint: const Text('Участок'),
                          onChanged: (newValue1) async {
                            print('нажал');
                            setState(() {
                              myPlotTitle = newValue1 as String?;
                            });
                          },
                          items: plotList.map((jobTitleList) {
                            return DropdownMenuItem(
                              value: jobTitleList['id'],
                              child: Text(jobTitleList['title']),
                            );
                          }).toList(),
                          decoration: const InputDecoration(
                              border: OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(height: 10.0),

                      /// Должность
                      SizedBox(
                        height: 50.0,
                        child: DropdownButtonFormField(
                          value: myJobTitle,
                          hint: const Text('Должность'),
                          onChanged: (newValue1) async {
                            print('нажал');
                            setState(() {
                              myJobTitle = newValue1 as String?;
                            });
                          },
                          items: jobTitleList.map((jobTitle) {
                            return DropdownMenuItem(
                              value: jobTitle['id'],
                              child: Text(jobTitle['name']),
                            );
                          }).toList(),
                          decoration: const InputDecoration(
                              border: OutlineInputBorder()),
                        ),
                      ),
                    ],
                  ),
            SizedBox(height: size.width > 570.0 ? 20.0 : 10.0),

            /// Checkbox
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                /// Checkbox Доступ в систему
                Row(
                  children: [
                    Checkbox(
                      activeColor: ColorApp.myColorGreenAuth,
                      value: accessToSystem,
                      onChanged: (newValue) {
                        setState(() {
                          accessToSystem = !accessToSystem;
                          setState(() {});
                        });
                      },
                    ),
                    Text(
                      'Доступ в систему',
                      style: TextStyle(
                          color: ColorApp.myColorGray,
                          fontSize: size.width > 570.0 ? 14 : 9),
                    ),
                  ],
                ),

                /// Checkbox Права суперпользователя
                Row(
                  children: [
                    Checkbox(
                      activeColor: ColorApp.myColorGreenAuth,
                      value: superuserRights,
                      onChanged: (newValue) {
                        setState(() {
                          superuserRights = !superuserRights;
                          setState(() {});
                        });
                      },
                    ),
                    Text('Права суперпользователя',
                        style: TextStyle(
                            color: ColorApp.myColorGray,
                            fontSize: size.width > 570.0 ? 14 : 9)),
                  ],
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
            if (size.width < 570.0) const SizedBox(height: 10.0),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    cursorColor: ColorApp.myColorGray,
                    controller: document,
                    decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: ColorApp.myColorGreenAuth),
                        ),
                        labelText: 'Документ',
                        labelStyle: TextStyle(color: ColorApp.myColorGray)),
                  ),
                ),
                const SizedBox(width: 10.0),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final imageDocument =
                          await ImagePickerWeb.getImageAsBytes();
                    },
                    child: DottedBorder(
                      color: ColorApp.myColorGray,
                      child: const SizedBox(
                        height: 44.0,
                        child: Center(
                          child: Icon(Icons.backup_outlined,
                              color: ColorApp.myColorGray),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: size.width > 570.0 ? 20.0 : 10.0),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    cursorColor: ColorApp.myColorGray,
                    controller: classification,
                    decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: ColorApp.myColorGreenAuth),
                        ),
                        labelText: 'ЦОК',
                        labelStyle: TextStyle(color: ColorApp.myColorGray)),
                  ),
                ),
                const SizedBox(width: 10.0),
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      final imageClassification =
                          await ImagePickerWeb.getImageAsBytes();
                    },
                    child: DottedBorder(
                      color: ColorApp.myColorGray,
                      child: const SizedBox(
                        height: 44.0,
                        child: Center(
                          child: Icon(Icons.backup_outlined,
                              color: ColorApp.myColorGray),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: size.width > 570.0 ? 20.0 : 10.0),

            /// Кнопка Сохранить
            MainButtonApp(
              textButton: 'Сохранить',
              press: () async {
                await createUser();
                // employeeBloc.add(EmployeeGetUserEvent());
                pointsMapController.add(IntTest.indexScreens);
                Navigator.pop(context);
                setState(() {});
                // keyEmail.currentState!.validate();
                // keyPhoneNumber.currentState!.validate();
                // keyFio.currentState!.validate();
              },
            ),
          ],
        ),
      ),
    );
  }
}
