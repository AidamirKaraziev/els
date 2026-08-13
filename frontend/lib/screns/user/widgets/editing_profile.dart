import 'dart:convert';
import 'package:els/helper/api_config.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:dotted_border/dotted_border.dart';
import 'package:els/helper/button/my_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:els/helper/image_picking.dart';
import '../../../bloc/user_bloc/user_bloc.dart';
import '../../../helper/class_colors.dart';
import '../../employee/bloc/employee_bloc.dart';
import '../../employee/view/employees_screen.dart';
import '../../home_page/home_page.dart';
import '../user_contact.dart';
import 'package:http_parser/http_parser.dart';
import 'package:els/helper/api_client.dart';

/// Изменение сотрудника

class EditingProfile extends StatefulWidget {
  const EditingProfile({
    Key? key,
  }) : super(key: key);

  @override
  State<EditingProfile> createState() => _EditingProfileState();
}

class _EditingProfileState extends State<EditingProfile> {

  @override
  void initState() {

    // TODO: implement initState
    super.initState();
  }


  /// Изменение юзера =======================
  editingProfile() async {
    var response = await Api.put(
      Uri.parse("${ApiConfig.base}/cp/universal-user/me/"),
      headers: {
        "Content-Type": "application/json; charset=utf-8",
      },
      body: json.encode(
        {
          "name": editingProfileName.text,
          "contact_phone": phoneProfileNumber.text,
          "birthday": newDateBirthProfile.millisecondsSinceEpoch/1000,
          "location_id": 1,
          "date_of_employment": newEmploymentDateProfile.millisecondsSinceEpoch/1000,
        },
      ),
    );
  }
  /// =======================================

  /// Функция изменение фото ====================
  var imagePath;
  String basename(String path) {
    if (path.isNotEmpty) {
      String str = path.replaceAll(RegExp(r'(.png|.jpeg|.svg|.jpg)'), '');
      return str;
    }
    return 'noName';
  }
  Future openGallery() async {
    if (kIsWeb) {
      PickedImage? imageFile = (await pickImageFromGallery());
      if (imageFile != null) {
        imagePath = imageFile;
        // print(imagePath);
        requestHttp(imageFile);
      }
    }
  }
  requestHttp(PickedImage imageFile) async {
    Map<String, String> headers = {
      "Accept": "application/json",
    }; // ignore this headers if there is no authentication
    var uri = Uri.parse(
        "${ApiConfig.base}/cp/universal-user/me/photo/");
    http.MultipartRequest request = await Api.multipart("PUT", uri);
    http.MultipartFile multipartFile = http.MultipartFile.fromBytes(
        'file', imageFile.data!,
        contentType: MediaType('image', 'jpeg'),
        filename: basename(imageFile.fileName ?? ''));
    request.files.add(multipartFile);
    request.headers.addAll(headers);
    var response = await Api.sendMultipart(request);
    response.stream.transform(utf8.decoder).listen((value) {
      Map listTestPhoto = jsonDecode(value);
      userProfile[0]['photo'] = listTestPhoto['data']['photo'];
      dataEmployee[IntTest.indexUserList]['photo'] = listTestPhoto['data']['photo'];
      UserBloc().add(UserGetEvent());
    });
    myStream.add(IntTest.indexScreens);
  }
  /// ============================================

  /// Новое имя профиля
  TextEditingController editingProfileName = TextEditingController(text: userProfile[0]['name']);

  /// Номер телефона
  TextEditingController phoneProfileNumber = TextEditingController(text: userProfile[0]['contact_phone']);

  /// день рождения
  DateTime newDateBirthProfile = DateTime.fromMillisecondsSinceEpoch(userProfile[0]['birthday'] == null ? 1725412316 : userProfile[0]['birthday'] * 1000);
  /// Дата приема на работу
  DateTime newEmploymentDateProfile = DateTime.fromMillisecondsSinceEpoch(userProfile[0]['date_of_employment']  == null ? 1725412316 : userProfile[0]['date_of_employment'] * 1000);


  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Редактировании профиля иконка закрыть
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                /// Текст Редактировании профиля
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Редактирование профиля',
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
                /// иконка закрыть
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
            /// Фото профиля
            const Text(
              'Фото сотрудника',
              style: TextStyle(fontWeight: FontWeight.w700, color: Colors.grey),
            ),
            const SizedBox(height: 10.0),
            DottedBorder(
              // borderType: BorderType.RRect,
              // radius: const Radius.circular(10.0),
              // color: Colors.grey.shade400,
              // dashPattern: const [5, 5],
              // padding: const EdgeInsets.all(16.0),
              child: StreamBuilder(
                  stream: myStream.stream,
                  builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                    return Row(
                      children: [
                        userProfile[0]['photo'] == null ?
                        Image.asset('assets/user.png') :
                        SizedBox(
                          height: 100.0,
                          width: 100.0,
                          child: Image.network(
                              '${ApiConfig.scheme}://${userProfile[0]['photo']}'),
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
                            onPressed: () async {
                              await openGallery();
                              myStream.add(IntTest.indexScreens);
                            },
                            child: const Text(
                              'Прикрепить',
                              style: TextStyle(
                                  fontSize: 15.0,
                                  fontWeight: FontWeight.bold,
                                  color: ColorApp.myColorBlack),
                            )),
                      ],
                    );
                  }),

            ),
            const SizedBox(height: 20.0),

            /// Новое имя профиля
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
                    controller: editingProfileName,
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
                    controller: phoneProfileNumber,
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

            /// Дата приема на работу и день рождения
            // Row(
            //   children: [
            //     ///Дата приема на работу
            //     Expanded(
            //       child: Column(
            //         crossAxisAlignment: CrossAxisAlignment.start,
            //         children: [
            //           const Text(
            //             'Дата приема на работу',
            //             style: TextStyle(
            //                 fontSize: 15.0,
            //                 fontWeight: FontWeight.bold,
            //                 color: ColorApp.myColorGrayText),
            //           ),
            //           const SizedBox(height: 10.0),
            //           InkWell(
            //               onTap: () async {
            //                 final DateTime? dateTime =
            //                 await showDatePicker(
            //                     context: context,
            //                     initialDate: newEmploymentDateProfile,
            //                     firstDate: DateTime(2000),
            //                     lastDate: DateTime(3000));
            //                 if (dateTime != null) {
            //                   newEmploymentDateProfile = dateTime;
            //                   setState(() {});
            //                 }
            //               },
            //               child: Container(
            //                   padding: const EdgeInsets.symmetric(horizontal: 10.0),
            //                   height: 50,
            //                   decoration: BoxDecoration(
            //                     borderRadius: BorderRadius.circular(5.0),
            //                     border: Border.all(width: 1.0,color: Colors.grey),
            //                   ),
            //                   child: Row(
            //                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //                       children: [
            //                         Text('${newEmploymentDateProfile.day} - ${newEmploymentDateProfile.month} - ${newEmploymentDateProfile.year}',style: const TextStyle(color: Colors.grey,fontSize: 16.0),),
            //                         const Icon(Icons.calendar_month_outlined,color: Colors.grey)]))),
            //         ],
            //       ),
            //     ),
            //     const SizedBox(width: 10.0),
            //     ///Дата рождения
            //     Expanded(
            //       child: Column(
            //         crossAxisAlignment: CrossAxisAlignment.start,
            //         children: [
            //           const Text(
            //             'Дата рождения',
            //             style: TextStyle(
            //                 fontSize: 15.0,
            //                 fontWeight: FontWeight.bold,
            //                 color: ColorApp.myColorGrayText),
            //           ),
            //           const SizedBox(height: 10.0),
            //           InkWell(
            //               onTap: () async {
            //                 final DateTime? dateTime =
            //                 await showDatePicker(
            //                     context: context,
            //                     initialDate: newDateBirthProfile,
            //                     firstDate: DateTime(1900),
            //                     lastDate: DateTime(3000));
            //                 if (dateTime != null) {
            //                   newDateBirthProfile = dateTime;
            //                   setState(() {});
            //                 }
            //               },
            //               child: Container(
            //                   padding: const EdgeInsets.symmetric(horizontal: 10.0),
            //                   height: 50,
            //                   decoration: BoxDecoration(
            //                     borderRadius: BorderRadius.circular(5.0),
            //                     border: Border.all(width: 1.0,color: Colors.grey),
            //                   ),
            //                   child: Row(
            //                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //                       children: [
            //                         Text('${newDateBirthProfile.day} - ${newDateBirthProfile.month} - ${newDateBirthProfile.year}',style: const TextStyle(color: Colors.grey,fontSize: 16.0),),
            //                         const Icon(Icons.calendar_month_outlined,color: Colors.grey)]))),
            //         ],
            //       ),
            //     ),
            //   ],
            // ),
            // const SizedBox(height: 20.0),

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
                                initialDate: newEmploymentDateProfile,
                                firstDate: DateTime(2000),
                                lastDate: DateTime(3000));
                            if (dateTime != null) {
                              newEmploymentDateProfile = dateTime;
                              setState(() {});
                              newEmploymentDateProfile = DateTime.utc(
                                  dateTime.year,
                                  dateTime.month,
                                  dateTime.day,
                                  dateTime.hour,
                                  dateTime.minute); // указываем UTC часовой пояс
                              int unixTime = newEmploymentDateProfile
                                  .toUtc()
                                  .millisecondsSinceEpoch ~/
                                  1000; // переводим в Unix time с учетом UTC часового пояса
                              newEmploymentDateProfile = unixTime as DateTime;
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
                                      '${newEmploymentDateProfile.day} - ${newEmploymentDateProfile.month} - ${newEmploymentDateProfile.year}',
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
                const SizedBox(width: 20.0),
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
                                initialDate: newDateBirthProfile,
                                firstDate: DateTime(1900),
                                lastDate: DateTime(3000));
                            if (dateTime != null) {
                              newDateBirthProfile = dateTime;
                              setState(() {});
                              newDateBirthProfile = DateTime.utc(dateTime.year, dateTime.month, dateTime.day, dateTime.hour, dateTime.minute); // указываем UTC часовой пояс
                              int unixTime = newDateBirthProfile.toUtc().millisecondsSinceEpoch ~/ 1000; // переводим в Unix time с учетом UTC часового пояса
                              newDateBirthProfile = unixTime as DateTime;
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
                                      '${newDateBirthProfile.day} - ${newDateBirthProfile.month} - ${newDateBirthProfile.year}',
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
            /// Кнопка Сохранить
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 30.0),
                MainButtonApp(
                  textButton: 'Сохранить', press: () async {
                  /// Измененния имя
                  userProfile[0]['name'] = editingProfileName.text;
                  /// Измененния телефона
                  userProfile[0]['contact_phone'] = phoneProfileNumber.text;
                  /// Новая дата рождения
                  userProfile[0]['birthday'] = newDateBirthProfile.millisecondsSinceEpoch/1000;
                  /// Новая дата приема на работу
                  userProfile[0]['date_of_employment'] = newEmploymentDateProfile.millisecondsSinceEpoch/1000;
                  await editingProfile();
                  myStream.add(IntTest.indexScreens);
                  Navigator.pop(context);
                  setState(() {});
                }
                ,),
              ],
            ),
          ],
        ),
      ),
    );
  }
}