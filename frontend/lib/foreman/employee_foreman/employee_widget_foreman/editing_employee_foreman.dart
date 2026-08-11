import 'dart:convert';
import 'package:els/helper/api_config.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:els/foreman/employee_foreman/employees_screen_foreman.dart';
import 'package:els/helper/button/my_button.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../../../helper/class_colors.dart';
import 'package:flutter/foundation.dart';
import 'package:http_parser/http_parser.dart';
import '../../../screns/home_page/home_page.dart';

/// Изменение сотрудника

class EditingEmployeeForeman extends StatefulWidget {
  const EditingEmployeeForeman({
    Key? key,
  }) : super(key: key);

  @override
  State<EditingEmployeeForeman> createState() => _EditingEmployeeForemanState();
}

class _EditingEmployeeForemanState extends State<EditingEmployeeForeman> {
  /// Получение Должность для изменения ==
  // getEditingEmployeeJobTitle() async {
  //   final url = '${ApiConfig.base}/roles/?page=1';
  //   final res = await http.get(Uri.parse(url), headers: {
  //     "Content-Type": "application/json; charset=utf-8",
  //     'Accept': 'application/json',
  //     'Authorization': 'Bearer ${IntTest.token}',
  //   });
  //   var response = jsonDecode(utf8.decode(res.bodyBytes));
  //   setState(() {
  //     editingJobTitleList = response['data'];
  //   });
  //   // print('Получение Должность для изменения $editingJobTitleList ====================');
  // }
  // String? editingMyJobTitle;
  // List editingJobTitleList = [];
  /// ====================================

  /// Дата рождения
  DateTime dateBirthEmployee = DateTime.fromMillisecondsSinceEpoch(listSelectedEmployeeForeman['birthday'] == null ? 1725412316 : listSelectedEmployeeForeman['birthday'] * 1000);

  /// Дата приема на работу
  DateTime employmentDate = DateTime.fromMillisecondsSinceEpoch(listSelectedEmployeeForeman['date_of_employment']  == null ? 1725412316 : listSelectedEmployeeForeman['date_of_employment'] * 1000);


  /// Изменение юзера ==============================
  editingEmployeeUserForeman(int userId) async {
    var res = await http.put(
      Uri.parse(
          "${ApiConfig.base}/cp/foreman/universal-user/$userId/"),
      headers: {
        "Content-Type": "application/json; charset=utf-8",
        'Authorization': 'Bearer ${IntTest.token}',
      },
      body: json.encode(
        {
          "name": editingEmployeeName.text,
          "contact_phone": phoneNumber.text,
          "birthday": dateBirthEmployee.millisecondsSinceEpoch / 1000,
          "location_id": 1,
          "date_of_employment": employmentDate.millisecondsSinceEpoch / 1000,
        },
      ),
    );
    var vova = jsonDecode(utf8.decode(res.bodyBytes));
    print(vova);
  }
  /// ==============================================

  /// Наимнование компании
  TextEditingController editingEmployeeName = TextEditingController(text: listSelectedEmployeeForeman['name']);

  /// Номер телефона
  TextEditingController phoneNumber = TextEditingController(text: listSelectedEmployeeForeman['contact_phone']);

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
        "${ApiConfig.base}/cp/foreman/universal-user/${IntTest.pressHover}/photo/");
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
      listSelectedEmployeeForeman['data']['photo'] = listTestPhoto['data']['photo'];
      dataEmployeeForeman[IntTest.indexUserList]['photo'] =
          listTestPhoto['data']['photo'];
      print('фотооооо${dataEmployeeForeman[IntTest.indexUserList]['photo']}');
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
                  children: [
                    const Text('Фото сотрудника',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, color: Colors.grey)),
                    const SizedBox(height: 10.0),
                    // DottedBorder(
                    //   borderType: BorderType.RRect,
                    //   radius: const Radius.circular(10.0),
                    //   color: Colors.grey.shade400,
                    //   dashPattern: const [5, 5],
                    //   padding: const EdgeInsets.all(16.0),
                    //   child: Row(
                    //     children: [
                    //       /// фото
                    //       SizedBox(
                    //           width: 100,
                    //           height: 100,
                    //           child: listSelectedEmployeeForeman['photo'] != null
                    //               ? ClipRRect(
                    //                   borderRadius: BorderRadius.circular(5.0),
                    //                   // Image border
                    //                   child: SizedBox.fromSize(
                    //                       size: const Size.fromRadius(48),
                    //                       // Image radius
                    //                       child: Image.network(
                    //                           '${ApiConfig.scheme}://${listSelectedEmployeeForeman['photo']}',
                    //                           fit: BoxFit.cover)))
                    //               : Image.asset('assets/user.png')),
                    //       const SizedBox(width: 20.0),
                    //
                    //       /// Текст Загрузите фото
                    //       const Text(
                    //         'Загрузите фото',
                    //         style: TextStyle(
                    //             fontSize: 15.0, fontWeight: FontWeight.bold),
                    //       ),
                    //       const Spacer(),
                    //
                    //       /// Кнопка Прикрепить
                    //       OutlinedButton(
                    //           style: OutlinedButton.styleFrom(
                    //               padding: const EdgeInsets.symmetric(
                    //                   horizontal: 30.0, vertical: 15.0)),
                    //           onPressed: () {
                    //             // openGallery();
                    //             // await openGalleryEditingEmployee();
                    //           },
                    //           child: const Text(
                    //             'Прикрепить',
                    //             style: TextStyle(
                    //                 fontSize: 15.0,
                    //                 fontWeight: FontWeight.bold,
                    //                 color: ColorApp.myColorBlack),
                    //           )),
                    //     ],
                    //   ),
                    // ),
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
                    MainButtonApp(
                      textButton: 'Сохранить',
                      press: () async {
                        /// Измененния имя
                        listSelectedEmployeeForeman['name'] = editingEmployeeName.text;
                        dataEmployeeForeman[IntTest.indexUserList]['name'] = editingEmployeeName.text;

                        /// Измененния телефона
                        listSelectedEmployeeForeman['contact_phone'] = phoneNumber.text;
                        dataEmployeeForeman[IntTest.indexUserList]['contact_phone'] = phoneNumber.text;

                        /// Даты приема на работу
                        listSelectedEmployeeForeman['date_of_employment'] = employmentDate.millisecondsSinceEpoch / 1000;
                        dataEmployeeForeman[IntTest.indexUserList]['date_of_employment'] = employmentDate.millisecondsSinceEpoch / 1000;

                        /// Дата рождения
                        listSelectedEmployeeForeman['birthday'] = dateBirthEmployee.millisecondsSinceEpoch / 1000;
                        dataEmployeeForeman[IntTest.indexUserList]['birthday'] = dateBirthEmployee.millisecondsSinceEpoch / 1000;

                        await editingEmployeeUserForeman(IntTest.pressHover);

                        myStream.add(IntTest.indexScreens);
                        Navigator.pop(context);
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


