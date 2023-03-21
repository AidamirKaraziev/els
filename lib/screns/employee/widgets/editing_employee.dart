import 'dart:convert';
import 'package:dotted_border/dotted_border.dart';
import 'package:els/helper/button/my_button.dart';
import 'package:els/helper/class_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import '../../home_page/home_page.dart';
import '../bloc/employee_bloc.dart';
import 'add_employee_class.dart';

/// Изменение сотрудника

class EditingEmployee extends StatefulWidget {
  const EditingEmployee({
    Key? key,
  }) : super(key: key);

  @override
  State<EditingEmployee> createState() => _EditingEmployeeState();
}

class _EditingEmployeeState extends State<EditingEmployee> {

  /// Получение Должность для изменения ==
  getEditingEmployeeJobTitle() async {
    final url = 'http://${IntTest.myIp}/api/v1/roles/?page=1';
    final res = await http.get(Uri.parse(url), headers: {
      "Content-Type": "application/json; charset=utf-8",
      'Accept': 'application/json',
      'Authorization': 'Bearer ${IntTest.token}',
    });
    var response = jsonDecode(utf8.decode(res.bodyBytes));
    setState(() {
      editingJobTitleList = response['data'];
    });
    print(editingJobTitleList);
  }

  String? editingMyJobTitle;
  List editingJobTitleList = [];

  /// ====================================

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getEditingEmployeeJobTitle();
    print('Сработал Инит Стате');
  }

  /// Изменение юзера =======================
  editingEmployeeUser(int userId) async {
    var response = await http.put(
      Uri.parse("http://185.119.58.63/api/v1/cp/admin/universal-user/$userId/"),
      headers: {
        "Content-Type": "application/json; charset=utf-8",
        'Authorization': 'Bearer ${IntTest.token}',
      },
      body: json.encode(
        {
          "name": editingEmployeeName.text,
          "contact_phone": phoneNumber.text,
          "birthday": 1678041841,
          "location_id": 1,
          "date_of_employment": 1678041841
        },
      ),
    );
  }

  /// =======================================

  /// Наимнование компании
  TextEditingController editingEmployeeName = TextEditingController(text: listSelectedEmployee['data']['name']);

  /// Дата приема на работу
  TextEditingController dateOfEmployment = TextEditingController();

  /// Номер телефона
  TextEditingController phoneNumber = TextEditingController(text: listSelectedEmployee['data']['contact_phone']);

  /// день рождения
  TextEditingController birthday = TextEditingController();



  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Редактировании сотрудника',
                      style:
                      TextStyle(fontSize: 25.0, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 5.0),
                    Text(
                      'Здесь вы можете отредактировать необходимые поля',
                      style: TextStyle(color: Colors.grey.shade400),
                    ),
                  ],
                ),
                IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(
                      Icons.close,
                      color: ColorApp.myColorGreenAuth,
                    ))
              ],
            ),
            const SizedBox(height: 30.0),
            const Text(
              'Фото сотрудника',
              style: TextStyle(fontWeight: FontWeight.w700, color: Colors.grey),
            ),
            const SizedBox(height: 10.0),
            DottedBorder(
              borderType: BorderType.RRect,
              radius: const Radius.circular(10.0),
              color: Colors.grey.shade400,
              dashPattern: const [5, 5],
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                        color: ColorApp.myColorGreenWhite,
                        borderRadius: BorderRadius.circular(5.0)),
                    width: 80.0,
                    height: 80.0,
                    child: const Icon(
                      Icons.photo_outlined,
                      size: 22,
                      color: ColorApp.myColorWhite,
                    ),
                  ),
                  const SizedBox(width: 20.0),
                  const Text(
                    'Загрузите фото',
                    style: TextStyle(
                        fontSize: 15.0, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  OutlinedButton(
                      style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 30.0, vertical: 15.0)),
                      onPressed: () {},
                      child: const Text(
                        'Прикрепить',
                        style: TextStyle(
                            fontSize: 15.0,
                            fontWeight: FontWeight.bold,
                            color: ColorApp.myColorBlack),
                      )),
                ],
              ),
            ),
            const SizedBox(height: 20.0),

            /// Новое имя сотрудника
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Новое имя сотрудника', style: TextStyle(
                    fontSize: 15.0,
                    fontWeight: FontWeight.bold,
                    color: ColorApp.myColorGrayText),),
                const SizedBox(height: 10.0),
                TextFormField(
                  cursorColor: ColorApp.myColorGray,
                  controller: editingEmployeeName,
                  decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: ColorApp.myColorGreenAuth)),
                      labelStyle: TextStyle(color: ColorApp.myColorGray))),
              ],
            ),
            const SizedBox(height: 10.0),

            /// Номер телефона
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Номер телефона', style: TextStyle(fontSize: 15.0,
                    fontWeight: FontWeight.bold,
                    color: ColorApp.myColorGrayText),),
                const SizedBox(height: 10.0),
                Form(
                  // key: keyPhoneNumber,
                  child: TextFormField(
                    maxLength: 10,
                    cursorColor: ColorApp.myColorGray,
                    controller: phoneNumber,
                    decoration: const InputDecoration(
                        prefixIcon: Padding(
                          padding: EdgeInsets.only(left: 10.0, top: 11.0),
                          child: Text('+7', style: TextStyle(color: ColorApp
                              .myColorGray),),
                        ),
                        border: OutlineInputBorder(),
                        focusedBorder: OutlineInputBorder(
                          borderSide:
                          BorderSide(color: ColorApp.myColorGreenAuth),
                        ),
                        labelText: 'Номер телефона',
                        labelStyle: TextStyle(color: ColorApp.myColorGray)),
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value!.isEmpty ||
                          !RegExp(
                              r'^[+]*[(]{0,1}[0-9]{1,4}[)]{0,1}[-\s\./0-9]+$')
                              .hasMatch(value)) {
                        return 'Некорректный номер телефона';
                      } else {
                        return null;
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5.0),

            /// Должность
            SizedBox(
              height: 50.0,
              child: DropdownButtonFormField(
                value: editingMyJobTitle,
                hint: const Text('Должность'),
                onChanged: (newValue1) async {
                  print('нажал');
                  setState(() {
                    editingMyJobTitle = newValue1 as String?;
                  });
                },
                items: editingJobTitleList.map((jobTitle) {
                  return DropdownMenuItem(
                    value: jobTitle['id'],
                    child: Text(jobTitle['name']),
                  );
                }).toList(),
                decoration: const InputDecoration(
                    border: OutlineInputBorder()),
              ),
            ),
            const SizedBox(height: 10.0),

            /// Дата приема на работу и день рождения
            Row(
              children: [
                /// Дата приема на работу
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Дата приема на работу', style: TextStyle(
                          fontSize: 15.0,
                          fontWeight: FontWeight.bold,
                          color: ColorApp.myColorGrayText),),
                      const SizedBox(height: 10.0),
                      TextFormField(
                        cursorColor: ColorApp.myColorGray,
                        controller: dateOfEmployment,
                        decoration: const InputDecoration(
                            prefixIcon: Icon(
                                Icons.calendar_month_outlined, color: ColorApp
                                .myColorGreenAuth),
                            border: OutlineInputBorder(),
                            focusedBorder: OutlineInputBorder(
                              borderSide:
                              BorderSide(color: ColorApp.myColorGreenAuth),
                            ),
                            // labelText: 'Документ',
                            labelStyle: TextStyle(color: ColorApp.myColorGray)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20.0),

                /// день рождения
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('день рождения', style: TextStyle(
                          fontSize: 15.0,
                          fontWeight: FontWeight.bold,
                          color: ColorApp.myColorGrayText),),
                      const SizedBox(height: 10.0),
                      TextFormField(
                        cursorColor: ColorApp.myColorGray,
                        controller: birthday,
                        decoration: const InputDecoration(
                            prefixIcon: Icon(
                                Icons.calendar_month_outlined, color: ColorApp
                                .myColorGreenAuth),
                            border: OutlineInputBorder(),
                            focusedBorder: OutlineInputBorder(
                              borderSide:
                              BorderSide(color: ColorApp.myColorGreenAuth),
                            ),
                            // labelText: 'Документ',
                            labelStyle: TextStyle(color: ColorApp.myColorGray)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20.0),

            /// Кнопка Сохранить
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                BlocBuilder<EmployeeBloc, EmployeeState>(
                  builder: (context, state) {
                    return MainButtonApp(
                      textButton: 'Сохранить', press: () async {
                      await editingEmployeeUser(IntTest.pressHover);
                      /// Измененния имя
                      listSelectedEmployee['data']['name'] = editingEmployeeName.text;
                      getEmployee[IntTest.indexUserList]['name'] = editingEmployeeName.text;
                      /// Измененния телефона
                      listSelectedEmployee['data']['contact_phone'] = phoneNumber.text;
                      getEmployee[IntTest.indexUserList]['contact_phone'] = phoneNumber.text;
                      /// Измененния должности
                      pointsMapController.add(IntTest.indexScreens);
                      Navigator.pop(context);
                    },);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}