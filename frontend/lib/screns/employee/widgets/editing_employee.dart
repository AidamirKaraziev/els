// ignore_for_file: must_be_immutable

import 'dart:convert';
import 'package:dotted_border/dotted_border.dart';
import 'package:els/helper/button/my_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../../../helper/class_colors.dart';
import '../../home_page/home_page.dart';
import '../../object/widgets/add_plot.dart';
import '../../user/user_profile.dart';
import '../bloc/employee_bloc.dart';
import '../view/employee_page.dart';
import '../view/employees_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:http_parser/http_parser.dart';

/// Изменение сотрудника

/// Участок =================
getPlotEmployee() async {
  final url = 'http://${IntTest.myIp}/api/v1/divisions/?page=1';
  final res = await http.get(Uri.parse(url), headers: {
    "Content-Type": "application/json; charset=utf-8",
    'Accept': 'application/json',
    'Authorization': 'Bearer ${IntTest.token}',
  });
  var response = jsonDecode(utf8.decode(res.bodyBytes));

  plotListEmployee = response['data'];


  // print(plotListEmployee);

}
String? myPlotTitleEmployee;
List plotListEmployee = [];
/// =========================

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
    // print('Получение Должность для изменения $editingJobTitleList ====================');
  }
  String? editingMyJobTitle;
  List editingJobTitleList = [];
  /// ====================================


  /// Дата рождения
  DateTime dateBirthEmployee = DateTime.fromMillisecondsSinceEpoch(listSelectedEmployee['data']['birthday'] == null ? 1725412316 : listSelectedEmployee['data']['birthday'] * 1000);

  /// Дата приема на работу
  DateTime employmentDate = DateTime.fromMillisecondsSinceEpoch(listSelectedEmployee['data']['date_of_employment']  == null ? 1725412316 : listSelectedEmployee['data']['date_of_employment'] * 1000);



  /// Изменение юзера =======================
  editingEmployeeUser(int userId) async {
    var response = await http.put(
      Uri.parse(
          "http://${IntTest.myIp}/api/v1/cp/admin/universal-user/$userId/"),
      headers: {
        "Content-Type": "application/json; charset=utf-8",
        'Authorization': 'Bearer ${IntTest.token}',
      },
      body: json.encode(
        {
          "name": editingEmployeeName.text,
          "contact_phone": phoneNumber.text,
          "birthday": dateBirthEmployee.millisecondsSinceEpoch / 1000,
          // "location_id": myPlotTitleEmployee,
          "date_of_employment": employmentDate.millisecondsSinceEpoch / 1000,
        },
      ),
    );
  }
  /// =======================================


  Map newPlotUser = {};


  /// Изменение юзера ===========================
  editingPlotEmployeeUser(int userId) async {
    var response = await http.put(
      Uri.parse(
          "http://${IntTest.myIp}/api/v1/cp/admin/$userId/division/"),
      headers: {
        "Content-Type": "application/json; charset=utf-8",
        'Authorization': 'Bearer ${IntTest.token}',
      },
      body: json.encode(
        {
          "division_id": myPlotTitleEmployee
        },
      ),
    );
    var newPlotUser = jsonDecode(utf8.decode(response.bodyBytes));

    listSelectedEmployee['data']['division_id']['title'] = newPlotUser['data']['division_id']['title'];


    // print(newPlotUser['data']['division_id']['title']);
    // await getListEmployeesInfo(IntTest.pressHover);
    // myStream.add(IntTest.indexScreens);
  }




  /// ===========================================

  /// Наимнование компании
  TextEditingController editingEmployeeName = TextEditingController(text: listSelectedEmployee['data']['name']);

  /// Новый участок


  /// Номер телефона
  TextEditingController phoneNumber = TextEditingController(text: listSelectedEmployee['data']['contact_phone']);

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getPlotEmployee();
    getEditingEmployeeJobTitle();

    if(listSelectedEmployee['data']['division_id'] != null) {
      myPlotTitleEmployee = '${listSelectedEmployee['data']['division_id']['id']}';
    }

  }


  /// Функция изменение фото в изменениях ======
  var imagePath;
  String basename(String path) {
    if (path.isNotEmpty) {
      String str = path.replaceAll(RegExp(r'(.png|.jpeg|.svg|.jpg)'), '');
      return str;
    }
    return 'noName';
  }
  requestHttp(XFile imageFile) async {
    Map<String, String> headers = {
      "Accept": "application/json",
      "Authorization": "Bearer ${IntTest.token}"
    };
    var uri = Uri.parse(
        "http://${IntTest.myIp}/api/v1/cp/admin/universal-user/${IntTest.pressHover}/photo/");
    http.MultipartRequest request = http.MultipartRequest("PUT", uri);
    http.MultipartFile multipartFile = http.MultipartFile.fromBytes(
        'file', await imageFile.readAsBytes(),
        contentType: MediaType('image', 'jpeg'),
        filename: basename(imageFile.name));

    request.files.add(multipartFile);
    request.headers.addAll(headers);

    var response = await request.send();
    print(response.statusCode);
    myStream.add(IntTest.indexScreens);

    response.stream.transform(utf8.decoder).listen((value) {
      Map listTestPhoto = jsonDecode(value);
      print(listTestPhoto);
      listSelectedEmployee['data']['photo'] = listTestPhoto['data']['photo'];
      dataEmployee[IntTest.indexUserList]['photo'] =
          listTestPhoto['data']['photo'];
      print('фотооооо${dataEmployee[IntTest.indexUserList]['photo']}');
    });
  }
  Future openGalleryEditingEmployee() async {
    final ImagePicker picker = ImagePicker();
    if (kIsWeb) {
      final XFile? xfile = await picker.pickImage(source: ImageSource.gallery);
      if (xfile != null) {
        imagePath = xfile.path;
        print(imagePath);
        requestHttp(xfile);
      }
    }
  }
  /// ===========================================

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: myStream.stream,
      builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
        return SizedBox(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// Редактировании сотрудника иконка закрыть
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Редактировании сотрудника',
                          style: TextStyle(
                              fontSize: 25.0, fontWeight: FontWeight.bold),
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

                /// Фото сотрудника
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Фото сотрудника',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, color: Colors.grey)),
                    const SizedBox(height: 10.0),
                    DottedBorder(
                      // borderType: BorderType.RRect,
                      // radius: const Radius.circular(10.0),
                      // color: Colors.grey.shade400,
                      // dashPattern: const [5, 5],
                      // padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          /// фото
                          SizedBox(
                              width: 100,
                              height: 100,
                              child: listSelectedEmployee['data']['photo'] != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(5.0),
                                      // Image border
                                      child: SizedBox.fromSize(
                                          size: const Size.fromRadius(48),
                                          // Image radius
                                          child: Image.network(
                                              'http://${listSelectedEmployee['data']['photo']}',
                                              fit: BoxFit.cover)))
                                  : Image.asset('assets/user.png')),
                          const SizedBox(width: 20.0),

                          /// Текст Загрузите фото
                          const Text(
                            'Загрузите фото',
                            style: TextStyle(
                                fontSize: 15.0, fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),

                          /// Кнопка Прикрепить
                          OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 30.0, vertical: 15.0)),
                              onPressed: ()  {
                                openGallery();
                                // await openGalleryEditingEmployee();
                              },
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
                  ],
                ),
                const SizedBox(height: 20.0),

                /// Новое имя сотрудника
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Новое имя сотрудника',
                      style: TextStyle(
                          fontSize: 15.0,
                          fontWeight: FontWeight.bold,
                          color: ColorApp.myColorGrayText),
                    ),
                    const SizedBox(height: 10.0),
                    TextFormField(
                        cursorColor: ColorApp.myColorGray,
                        controller: editingEmployeeName,
                        decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: ColorApp.myColorGreenAuth)),
                            labelStyle:
                                TextStyle(color: ColorApp.myColorGray))),
                  ],
                ),
                const SizedBox(height: 10.0),

                /// Участок
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Участок',style: TextStyle(
                        fontSize: 15.0,
                        fontWeight: FontWeight.bold,
                        color: ColorApp.myColorGrayText)),
                    const SizedBox(height: 5.0),
                    SizedBox(
                      height: 50.0,
                      child: DropdownButtonFormField(
                        value: myPlotTitleEmployee,
                        hint: const Text('Участок'),
                        onChanged: (newValue1) async {
                          setState(() {
                            myPlotTitleEmployee = newValue1 as String?;
                            myPlotTitleEmployee!.indexOf(newValue1!);
                          });
                        },
                        items: plotListEmployee.map((jobTitleList) {
                          return DropdownMenuItem(
                            value: jobTitleList['id'].toString(),
                            child: SizedBox(
                              width: 160.0,
                              child: Row(
                                children: [
                                  Expanded(
                                      child: Text('${jobTitleList['title']}',
                                          overflow: TextOverflow.ellipsis)),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                        decoration: InputDecoration(
                            prefixIcon: IconButton(
                                onPressed: () async {
                                  setState(() {
                                    showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          content: AddPlot(),
                                        ))
                                        .then((value) => setState(() {}));
                                  });
                                },
                                icon: const Icon(Icons.add_box_rounded,
                                    size: 20.0,
                                    color: ColorApp.myColorGreenAuth)),
                            border: const OutlineInputBorder()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10.0),

                /// Номер телефона
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Номер телефона',
                      style: TextStyle(
                          fontSize: 15.0,
                          fontWeight: FontWeight.bold,
                          color: ColorApp.myColorGrayText),
                    ),
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
                              child: Text(
                                '+7',
                                style: TextStyle(color: ColorApp.myColorGray),
                              ),
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
                              !RegExp(r'^[+]*[(]{0,1}[0-9]{1,4}[)]{0,1}[-\s\./0-9]+$')
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

                /// Дата приема на работу и день рождения
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
                                final DateTime? dateTime = await showDatePicker(
                                    context: context,
                                    initialDate: employmentDate,
                                    firstDate: DateTime(2000),
                                    lastDate: DateTime(3000));
                                if (dateTime != null) {
                                  employmentDate = dateTime;
                                  setState(() {});
                                  employmentDate = DateTime.utc(
                                      dateTime.year,
                                      dateTime.month,
                                      dateTime.day,
                                      dateTime.hour,
                                      dateTime.minute); // указываем UTC часовой пояс
                                  int unixTime = employmentDate
                                          .toUtc()
                                          .millisecondsSinceEpoch ~/
                                      1000; // переводим в Unix time с учетом UTC часового пояса
                                  employmentDate = unixTime as DateTime;
                                }
                              },
                              child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10.0),
                                  height: 50,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(5.0),
                                    border: Border.all(
                                        width: 1.0, color: Colors.grey),
                                  ),
                                  child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '${employmentDate.day} - ${employmentDate.month} - ${employmentDate.year}',
                                          style: const TextStyle(
                                              color: Colors.grey,
                                              fontSize: 16.0),
                                        ),
                                        const Icon(
                                            Icons.calendar_month_outlined,
                                            color: Colors.grey)
                                      ]))),
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
                                final DateTime? dateTime = await showDatePicker(
                                    context: context,
                                    initialDate: dateBirthEmployee,
                                    firstDate: DateTime(1900),
                                    lastDate: DateTime(3000));
                                if (dateTime != null) {
                                  dateBirthEmployee = dateTime;
                                  setState(() {});
                                  dateBirthEmployee = DateTime.utc(dateTime.year, dateTime.month, dateTime.day, dateTime.hour, dateTime.minute); // указываем UTC часовой пояс
                                  int unixTime = dateBirthEmployee.toUtc().millisecondsSinceEpoch ~/ 1000; // переводим в Unix time с учетом UTC часового пояса
                                  dateBirthEmployee = unixTime as DateTime;
                                }
                              },
                              child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10.0),
                                  height: 50,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(5.0),
                                    border: Border.all(
                                        width: 1.0, color: Colors.grey),
                                  ),
                                  child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '${dateBirthEmployee.day} - ${dateBirthEmployee.month} - ${dateBirthEmployee.year}',
                                          style: const TextStyle(
                                              color: Colors.grey,
                                              fontSize: 16.0),
                                        ),
                                        const Icon(
                                            Icons.calendar_month_outlined,
                                            color: Colors.grey)
                                      ]))),
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
                          textButton: 'Сохранить',
                          press: () async {
                            /// Измененния имя
                            listSelectedEmployee['data']['name'] = editingEmployeeName.text;
                            dataEmployee[IntTest.indexUserList]['name'] = editingEmployeeName.text;

                            /// Измененния телефона
                            listSelectedEmployee['data']['contact_phone'] = phoneNumber.text;
                            dataEmployee[IntTest.indexUserList]['contact_phone'] = phoneNumber.text;

                            /// Даты приема на работу
                            listSelectedEmployee['data']['date_of_employment'] = employmentDate.millisecondsSinceEpoch / 1000;
                            dataEmployee[IntTest.indexUserList]['date_of_employment'] = employmentDate.millisecondsSinceEpoch / 1000;

                            /// Дата рождения
                            listSelectedEmployee['data']['birthday'] = dateBirthEmployee.millisecondsSinceEpoch / 1000;
                            dataEmployee[IntTest.indexUserList]['birthday'] = dateBirthEmployee.millisecondsSinceEpoch / 1000;


                            await editingEmployeeUser(IntTest.pressHover);
                            editingPlotEmployeeUser(listSelectedEmployee['data']['id']);
                            myStream.add(IntTest.indexScreens);
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}


