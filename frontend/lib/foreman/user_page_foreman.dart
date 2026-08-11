import 'package:dotted_border/dotted_border.dart';
import 'package:els/helper/api_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../../../helper/class_colors.dart';
import 'package:http/http.dart' as http;
import '../../screns/home_page/home_page.dart';
import '../screns/user/user_contact.dart';

import 'employee_foreman/employee_widget_foreman/editing_employee_foreman.dart';


/// Окно User

class OpenViewUserForeman extends StatefulWidget {
  const OpenViewUserForeman({Key? key}) : super(key: key);

  @override
  State<OpenViewUserForeman> createState() => _OpenViewUserForemanState();
}

/// Замозморозка сотрудника ===================
// freezingEmployeeForeman(int userId) async {
//   await Future(() async {
//     final res = await http.get(
//         Uri.parse("${ApiConfig.base}/cp/admin/$userId/archive/"),
//         headers: {
//           "Content-Type": "application/json; charset=utf-8",
//           'Authorization': 'Bearer ${IntTest.token}',
//         });
//     var vova = jsonDecode(utf8.decode(res.bodyBytes));
//     listSelectedEmployeeForeman = vova;
//     print(listSelectedEmployeeForeman);
//   });
// }
/// ===========================================

/// Разморозка сотрудника =======================
// defrostingEmployeeForeman(int userId) async {
//   await Future(() async {
//     final res = await http.get(
//         Uri.parse("${ApiConfig.base}/cp/admin/$userId/unzip/"),
//         headers: {
//           "Content-Type": "application/json; charset=utf-8",
//           'Authorization': 'Bearer ${IntTest.token}',
//         });
//     var vova = jsonDecode(utf8.decode(res.bodyBytes));
//     listSelectedEmployeeForeman = vova;
//     print(listSelectedEmployeeForeman);
//   });
// }
/// =============================================


/// Функция изменение фото ====================
// var imagePath;
// String basename(String path) {
//   if (path.isNotEmpty) {
//     String str = path.replaceAll(RegExp(r'(.png|.jpeg|.svg|.jpg)'), '');
//     return str;
//   }
//   return 'noName';
// }
// Future openGallery() async {
//   if (kIsWeb) {
//     MediaInfo? imageFile = (await ImagePickerWeb.getImageInfo);
//     if (imageFile != null) {
//       imagePath = imageFile;
//       print(imagePath);
//       requestHttp(imageFile);
//     }
//   }
// }
// requestHttp(MediaInfo imageFile) async {
//   Map<String, String> headers = {
//     "Accept": "application/json",
//     "Authorization": "Bearer ${IntTest.token}"
//   }; // ignore this headers if there is no authentication
//   var uri = Uri.parse(
//       "${ApiConfig.base}/cp/admin/universal-user/${IntTest.pressHover}/photo/");
//   http.MultipartRequest request = http.MultipartRequest("PUT", uri);
//   http.MultipartFile multipartFile = http.MultipartFile.fromBytes(
//       'file', imageFile.data!,
//       contentType: MediaType('image', 'jpeg'),
//       filename: basename(imageFile.fileName ?? ''));
//   request.files.add(multipartFile);
//   request.headers.addAll(headers);
//   var response = await request.send();
//   response.stream.transform(utf8.decoder).listen((value) {
//     Map listTestPhoto = jsonDecode(value);
//     listSelectedEmployeeForeman['data']['photo'] = listTestPhoto['data']['photo'];
//     dataEmployeeForeman[IntTest.indexUserList]['photo'] = listTestPhoto['data']['photo'];
//   });
//   myStream.add(IntTest.indexScreens);
// }
/// ============================================

class _OpenViewUserForemanState extends State<OpenViewUserForeman> {

  /// Функция изменение фото Док Уд  ===============
  // var imagePath;
  // String basename(String path) {
  //   if (path.isNotEmpty) {
  //     String str = path.replaceAll(RegExp(r'(.png|.jpeg|.svg|.jpg)'), '');
  //     return str;
  //   }
  //   return 'noName';
  // }
  // Future openGalleryDocUserCertificate() async {
  //   if (kIsWeb) {
  //     MediaInfo? imageFile = (await ImagePickerWeb.getImageInfo);
  //     if (imageFile != null) {
  //       imagePath = imageFile;
  //       print(imagePath);
  //       requestHttp(imageFile);
  //     }
  //   }
  // }
  // requestHttp(MediaInfo imageFile) async {
  //   Map<String, String> headers = {
  //     "Accept": "application/json",
  //     "Authorization": "Bearer ${IntTest.token}"
  //   }; // ignore this headers if there is no authentication
  //   var uri = Uri.parse(
  //       "${ApiConfig.base}/cp/admin/universal-user/${IntTest.pressHover}/identity-card/");
  //   http.MultipartRequest request = http.MultipartRequest("PUT", uri);
  //   http.MultipartFile multipartFile = http.MultipartFile.fromBytes(
  //       'file', imageFile.data!,
  //       contentType: MediaType('image', 'jpeg'),
  //       filename: basename(imageFile.fileName ?? ''));
  //   request.files.add(multipartFile);
  //   request.headers.addAll(headers);
  //   var response = await request.send();
  //   response.stream.transform(utf8.decoder).listen((value) {
  //     Map listTestPhoto = jsonDecode(value);
  //     listSelectedEmployeeForeman['data']['identity_card'] = listTestPhoto['data']['identity_card'];
  //     getListEmployeesInfoForeman(IntTest.pressHover);
  //     myStream.add(IntTest.indexScreens);
  //   });
  // }
  // /// ==============================================
  //
  // /// Функция изменение фото ЦОК ======================
  // var imagePathDoc;
  // String basenameDoc(String path) {
  //   if (path.isNotEmpty) {
  //     String str = path.replaceAll(RegExp(r'(.png|.jpeg|.svg|.jpg)'), '');
  //     return str;
  //   }
  //   return 'noName';
  // }
  // Future openGalleryDocUserQualifications() async {
  //   if (kIsWeb) {
  //     MediaInfo? imageFile = (await ImagePickerWeb.getImageInfo);
  //     if (imageFile != null) {
  //       imagePathDoc = imageFile;
  //       print(imagePathDoc);
  //       requestHttpDoc(imageFile);
  //     }
  //   }
  // }
  // requestHttpDoc(MediaInfo imageFile) async {
  //   Map<String, String> headers = {
  //     "Accept": "application/json",
  //     "Authorization": "Bearer ${IntTest.token}"
  //   }; // ignore this headers if there is no authentication
  //   var uri = Uri.parse(
  //       "${ApiConfig.base}/cp/admin/universal-user/${IntTest.pressHover}/qualification-file/");
  //   http.MultipartRequest request = http.MultipartRequest("PUT", uri);
  //   http.MultipartFile multipartFile = http.MultipartFile.fromBytes(
  //       'file', imageFile.data!,
  //       contentType: MediaType('image', 'jpeg'),
  //       filename: basenameDoc(imageFile.fileName ?? ''));
  //   request.files.add(multipartFile);
  //   request.headers.addAll(headers);
  //   var response = await request.send();
  //   response.stream.transform(utf8.decoder).listen((value) {
  //     Map listTestPhoto = jsonDecode(value);
  //     listSelectedEmployeeForeman['data']['qualification_file'] = listTestPhoto['data']['qualification_file'];
  //     getListEmployeesInfoForeman(IntTest.pressHover);
  //     myStream.add(IntTest.indexScreens);
  //     // setState(() {});
  //   });
  // }
  /// =================================================

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final viewEmployeeList = userProfile[0];
    return StreamBuilder(
      stream: myStream.stream,
      builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
        return Scaffold(
          backgroundColor: ColorApp.myColorGrayShadow,
          body: SingleChildScrollView(
            child: Container(
              color: ColorApp.myColorTransparent,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ///Header =====
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: ColorApp.kPadding),
                    color: Colors.white,
                    height: 70,
                    width: double.infinity,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        /// Кнопка Назад Сотрудники
                        // Row(
                        //   children: [
                        //     Container(
                        //       width: 32.0,
                        //       height: 32.0,
                        //       decoration: BoxDecoration(
                        //         borderRadius: BorderRadius.circular(5.0),
                        //         border: Border.all(
                        //             color: ColorApp.myColorGrayBorder,
                        //             width: 1),
                        //         color: Colors.white,
                        //         boxShadow: const [
                        //           BoxShadow(
                        //             color: ColorApp.myColorAvatar,
                        //             blurRadius: 5,
                        //           ),
                        //         ],
                        //       ),
                        //       child: IconButton(
                        //           onPressed: () async {
                        //            // await getListEmployee();
                        //             IntTest.indexScreensForeman = 5;
                        //             myStream.add(IntTest.indexScreensForeman);
                        //             setState(() {});
                        //           },
                        //           icon: const Icon(
                        //             Icons.arrow_back_ios_new_rounded,
                        //             color: Colors.black,
                        //             size: 13.0,
                        //           )),
                        //     ),
                        //     const SizedBox(width: 30.0),
                        //   ],
                        // ),

                        ///Text
                        Text('Мой Профиль',
                            style: TextStyle(
                                fontSize: size.width > 350 ? 25.0 : 18.0,
                                fontWeight: size.width > 350
                                    ? FontWeight.w700
                                    : FontWeight.w500)),

                        /// Кнопки Изменить Удалить
                        Row(
                          children: [
                            const SizedBox(width: 10.0),

                            /// Изменить
                            IconButton(
                                onPressed: () {
                                  setState(() {
                                    showDialog(
                                        context: context,
                                        builder: (context) => const AlertDialog(
                                            content: EditingEmployeeForeman()));
                                  });
                                },
                                icon: const Icon(Icons.edit_outlined,
                                    color: ColorApp.myColorGreenAuth)),
                            const SizedBox(width: 10.0),

                            /// Удалить
                            // IconButton(
                            //     onPressed: () {
                            //       setState(() {
                            //         showDialog(
                            //             context: context,
                            //             builder: (context) => AlertDialog(
                            //                     content: SizedBox(
                            //                   width: 200.0,
                            //                   height: 60.0,
                            //                   child: Column(
                            //                     mainAxisAlignment:
                            //                         MainAxisAlignment.center,
                            //                     children: [
                            //                       const Text('Удалить сотрудника?'),
                            //                       const Spacer(),
                            //                       Row(
                            //                           mainAxisAlignment:
                            //                               MainAxisAlignment
                            //                                   .center,
                            //                           children: [
                            //                             Expanded(
                            //                                 child:
                            //                                     ElevatedButton(
                            //                                         onPressed:
                            //                                             () async {
                            //                                           await deleteEmployeeForeman(IntTest.pressHover);
                            //                                           getEmployeeForeman.removeWhere((item) =>
                            //                                           item["id"] == IntTest.pressHover);
                            //                                           IntTest.indexScreensForeman = 5;
                            //                                           myStream.add(IntTest.indexScreensForeman);
                            //                                           Navigator.pop(context);
                            //                                         },
                            //                                         style: ElevatedButton.styleFrom(
                            //                                             primary:
                            //                                                 ColorApp
                            //                                                     .myColorRed),
                            //                                         child: const Text(
                            //                                             'Да',
                            //                                             style: TextStyle(
                            //                                                 fontSize: 16.0,
                            //                                                 fontWeight: FontWeight.bold)))),
                            //                             const SizedBox(width: 20.0),
                            //                             Expanded(
                            //                                 child:
                            //                                     ElevatedButton(
                            //                                         onPressed:
                            //                                             () {
                            //                                           Navigator.pop(
                            //                                               context);
                            //                                         },
                            //                                         style: ElevatedButton.styleFrom(
                            //                                             primary:
                            //                                                 ColorApp
                            //                                                     .myColorGreenAuth),
                            //                                         child: const Text(
                            //                                             'Нет',
                            //                                             style: TextStyle(
                            //                                                 fontSize:
                            //                                                     16.0,
                            //                                                 fontWeight:
                            //                                                     FontWeight.bold)))),
                            //                           ]),
                            //                       const Spacer(),
                            //                     ],
                            //                   ),
                            //                 )));
                            //       });
                            //     },
                            //     icon: const Icon(Icons.delete_outline_outlined,
                            //         color: ColorApp.myColorRed)),
                          ],
                        ),
                        const Spacer(),

                        ///Колокольчик
                        if (size.width > 400)
                          Badge(
                            alignment: const AlignmentDirectional(21, 4),
                            backgroundColor: ColorApp.myColorRed,
                            isLabelVisible:
                                IntTest.badgeCount > 0 ? true : false,
                            label: IntTest.badgeCount < 1
                                ? const SizedBox.shrink()
                                : Text(IntTest.badgeCount.toString(),
                                    style: const TextStyle(
                                        fontSize: 12.0,
                                        color: ColorApp.myColorWhite,
                                        fontWeight: FontWeight.w500)),
                            child: IconButton(
                              onPressed: () {},
                              icon: const Icon(
                                  Icons.notifications_none_outlined,
                                  size: 25.0),
                            ),
                          ),
                        SizedBox(width: size.width > 500 ? 40.0 : 10.0),

                        ///Аватар Юзера
                        const MyUserForeman(),
                      ],
                    ),
                  ),

                  /// ===========
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        /// Photo & Info
                        Row(
                          children: [
                            /// Профиль Фото Имя
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                /// Текст Профиль
                                const Text(
                                  'Профиль',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 20.0),
                                if (viewEmployeeList['is_actual'] == true)
                                  Container(
                                    height: 250,
                                    width: 250,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(5.0),
                                      color:
                                          viewEmployeeList['is_actual'] == true
                                              ? ColorApp.myColorWhite
                                              : Colors.grey[300],
                                      boxShadow: const [
                                        BoxShadow(
                                          color: ColorApp.myColorAvatar,
                                          blurRadius: 5,
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        // if(state is UserGetState)
                                        Badge(
                                            smallSize: 30.0,
                                            largeSize: 50.0,
                                            alignment:
                                                const AlignmentDirectional(
                                                    100, 90),
                                            backgroundColor:
                                                ColorApp.myColorGreen,
                                            label: IconButton(
                                                onPressed: () async {
                                                  // openGallery();
                                                },
                                                icon: const Icon(
                                                  Icons.camera_alt_outlined,
                                                  color: ColorApp.myColorWhite,
                                                )),
                                            child: CircleAvatar(
                                                radius: 70.0,
                                                backgroundImage: const AssetImage('assets/user.png'),
                                                foregroundImage: NetworkImage('http://${viewEmployeeList['photo']}'))),
                                        const SizedBox(height: 10.0),
                                        /// Имя сотрудника
                                        Center(
                                          child: Text(viewEmployeeList['name'].toString(),
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                  fontSize: 16.0,
                                                  fontWeight: FontWeight.w600)),
                                        ),
                                        const SizedBox(height: 10.0),

                                        ///Кнопка Редактировать и Заморозить
                                        const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            /// Редактировать
                                            // OutlinedButton(
                                            //     style: OutlinedButton.styleFrom(
                                            //       padding: const EdgeInsets
                                            //               .symmetric(
                                            //           horizontal: 20.0,
                                            //           vertical: 10.0),
                                            //       side: BorderSide(
                                            //           color:
                                            //               Colors.grey.shade400,
                                            //           width: 1.0),
                                            //       shape: RoundedRectangleBorder(
                                            //         borderRadius:
                                            //             BorderRadius.circular(
                                            //                 20.0),
                                            //       ),
                                            //     ),
                                            //     onPressed: () {
                                            //       setState(() {
                                            //         showDialog(
                                            //             context: context,
                                            //             builder: (context) =>
                                            //                 const AlertDialog(
                                            //                     content:
                                            //                         EditingEmployeeForeman()));
                                            //       });
                                            //       // await defrostingEmployee(IntTest.pressHover);
                                            //       // myStream.add(IntTest.indexScreens);
                                            //     },
                                            //     child: Text('Редактировать',
                                            //         style: TextStyle(
                                            //             fontSize: 10.0,
                                            //             color: Colors
                                            //                 .grey.shade400))),
                                            SizedBox(width: 10.0),

                                            /// Заморозить
                                            // IconButton(
                                            //     onPressed: () async {
                                            //       await showDialog(
                                            //           context: context,
                                            //           builder: (context) =>
                                            //               const AlertDialog(
                                            //                   content: EmployeeAccountFreezeForeman()));
                                            //       setState(() {});
                                            //     },
                                            //     icon: const Icon(
                                            //         Icons.ac_unit_outlined,
                                            //         color: ColorApp
                                            //             .myColorAvatar)),
                                          ],
                                        ),
                                      ],
                                    ),
                                  )
                                else
                                  Stack(
                                    children: [
                                      Container(
                                        height: 250,
                                        width: 250,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(5.0),
                                          color: Colors.grey[400],
                                          boxShadow: const [
                                            BoxShadow(
                                              color: ColorApp.myColorAvatar,
                                              blurRadius: 5,
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.center,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Badge(
                                                smallSize: 30.0,
                                                largeSize: 50.0,
                                                alignment: const AlignmentDirectional(100, 90),
                                                backgroundColor: ColorApp.myColorGray,
                                                label: const IconButton(
                                                    onPressed: null,
                                                    icon: Icon(Icons.camera_alt_outlined,
                                                      color: ColorApp.myColorGrayShadow,
                                                    )),
                                                child: CircleAvatar(
                                                  radius: 70.0,
                                                  backgroundImage: const AssetImage('assets/user.png'),
                                                  foregroundImage: NetworkImage('http://${viewEmployeeList['photo']}'),
                                                  backgroundColor: ColorApp.myColorGray,
                                                )),
                                            const SizedBox(height: 10.0),
                                            Center(
                                              child: Text(
                                                  viewEmployeeList['name'],
                                                  textAlign: TextAlign.center,
                                                  style: const TextStyle(
                                                      fontSize: 16.0,
                                                      fontWeight:
                                                          FontWeight.w600)),
                                            ),
                                            const SizedBox(height: 10.0),

                                            ///Кнопка Редактировать и Заморозить
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                /// Редактировать
                                                OutlinedButton(
                                                    style: OutlinedButton
                                                        .styleFrom(
                                                      padding: const EdgeInsets
                                                              .symmetric(
                                                          horizontal: 20.0,
                                                          vertical: 10.0),
                                                      side: BorderSide(
                                                          color: Colors
                                                              .grey.shade400,
                                                          width: 1.0),
                                                      shape:
                                                          RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(20.0),
                                                      ),
                                                    ),
                                                    onPressed: () async {},
                                                    child: Text('Редактировать',
                                                        style: TextStyle(
                                                            fontSize: 10.0,
                                                            color: Colors.grey.shade400))),
                                                const SizedBox(width: 10.0),

                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Positioned(
                                      //   left: 30.0,
                                      //   right: 30.0,
                                      //   bottom: 20.0,
                                      //   child: ElevatedButton(
                                      //       style: ElevatedButton.styleFrom(
                                      //           backgroundColor:
                                      //               ColorApp.myColorBlue),
                                      //       onPressed: () async {
                                      //         /// ========================================================
                                      //         await defrostingEmployeeForeman(IntTest.pressHover);
                                      //         myStream.add(IntTest.indexScreensForeman);
                                      //         setState(() {});
                                      //         /// ========================================================
                                      //       },
                                      //       child: const Text('Аккаунт заморожен')),
                                      // )
                                    ],
                                  ),
                              ],
                            ),
                            const SizedBox(width: 20),

                            /// Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Информация',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 20.0),
                                  Container(
                                    padding: const EdgeInsets.all(20.0),
                                    height: 250,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(5.0),
                                      color:
                                          viewEmployeeList['is_actual'] == true
                                              ? ColorApp.myColorWhite
                                              : Colors.grey[400],
                                      boxShadow: const [
                                        BoxShadow(
                                          color: ColorApp.myColorAvatar,
                                          blurRadius: 5,
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        /// Участок, Должность, Дата приема на работу
                                        Expanded(
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.start,
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              ///Участок
                                              if (viewEmployeeList['division_id'] != null)
                                                Row(
                                                  children: [
                                                    const Icon(Icons.location_on_outlined),
                                                    const SizedBox(width: 20.0),
                                                    Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        const Text('Участок'),
                                                        const SizedBox(
                                                            height: 10.0),
                                                        Text(
                                                            '${viewEmployeeList['division_id']['title']}',
                                                            style: const TextStyle(
                                                                fontSize: 16.0,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600)),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              const SizedBox(height: 20.0),

                                              ///Должность
                                              if (viewEmployeeList['role_id'] != null)
                                                Row(
                                                  children: [
                                                    const Icon(Icons
                                                        .person_outline_outlined),
                                                    const SizedBox(width: 20.0),
                                                    Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        const Text('Должность'),
                                                        const SizedBox(
                                                            height: 10.0),
                                                        Text(
                                                            '${viewEmployeeList['role_id']['name']}',
                                                            style: const TextStyle(
                                                                fontSize: 16.0,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600)),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              const SizedBox(height: 20.0),

                                              ///Дата приема на работу
                                              if (viewEmployeeList['date_of_employment'] != null)
                                                Row(
                                                  children: [
                                                    const Icon(Icons
                                                        .calendar_month_outlined),
                                                    const SizedBox(width: 20.0),
                                                    Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment.start,
                                                      children: [
                                                        const Text(
                                                            'Дата приема на работу'),
                                                        const SizedBox(height: 10.0),
                                                        Text(DateFormat('dd -MM-yyyy').format(DateTime.fromMillisecondsSinceEpoch(viewEmployeeList['date_of_employment'] * 1000)),
                                                            style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.w600)),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 20),

                                        /// Компания, Должность, Дата рождения
                                        Expanded(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              ///Компания
                                              if (viewEmployeeList[
                                                      'company_id'] !=
                                                  null)
                                                Row(
                                                  children: [
                                                    const Icon(Icons.domain),
                                                    const SizedBox(width: 20.0),
                                                    Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        const Text('Компания'),
                                                        const SizedBox(
                                                            height: 10.0),
                                                        Text(
                                                            '${viewEmployeeList['company_id']['name']}',
                                                            style: const TextStyle(
                                                                fontSize: 16.0,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600)),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              const SizedBox(height: 20.0),

                                              ///Должность
                                              if (viewEmployeeList['role_id'] !=
                                                  null)
                                                Row(
                                                  children: [
                                                    const Icon(Icons
                                                        .person_outline_outlined),
                                                    const SizedBox(width: 20.0),
                                                    Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        const Text('Должность'),
                                                        const SizedBox(
                                                            height: 10.0),
                                                        Text(
                                                            '${viewEmployeeList['role_id']['name']}',
                                                            style: const TextStyle(
                                                                fontSize: 16.0,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600)),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              const SizedBox(height: 20.0),

                                              ///Дата рождения
                                              if (viewEmployeeList[
                                                      'birthday'] !=
                                                  null)
                                                Row(
                                                  children: [
                                                    const Icon(Icons
                                                        .calendar_month_outlined),
                                                    const SizedBox(width: 20.0),
                                                    Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        const Text(
                                                            'Дата рождения'),
                                                        const SizedBox(
                                                            height: 10.0),
                                                        Text(
                                                            DateFormat(
                                                                    'dd -MM-yyyy')
                                                                .format(DateTime
                                                                    .fromMillisecondsSinceEpoch(
                                                                        viewEmployeeList['birthday'] *
                                                                            1000)),
                                                            style: const TextStyle(
                                                                fontSize: 16.0,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w600)),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        /// Contact Документы
                        Row(
                          children: [
                            /// Контакты
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Контакты',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 20.0),
                                  Container(
                                    padding: const EdgeInsets.all(20.0),
                                    width: double.infinity,
                                    height: 250,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(5.0),
                                      color:
                                          viewEmployeeList['is_actual'] == true
                                              ? ColorApp.myColorWhite
                                              : Colors.grey[400],
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Colors.grey,
                                          blurRadius: 5,
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceAround,
                                      children: [
                                        ///ФИО
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text('ФИО'),
                                            const SizedBox(height: 10.0),
                                            viewEmployeeList['role_id'] == null
                                                ? const Text('')
                                                : Text(
                                                    '${viewEmployeeList['name']}',
                                                    style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w600),
                                                  ),
                                          ],
                                        ),

                                        ///Номер телефона
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text('Номер телефона'),
                                            const SizedBox(height: 10.0),
                                            viewEmployeeList['contact_phone'] == null
                                                ? const Text('')
                                                : Text(
                                                    '+7${viewEmployeeList['contact_phone']}',
                                                    style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w600),
                                                  ),
                                          ],
                                        ),

                                        ///Эл. почта
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text('Эл. почта'),
                                            const SizedBox(height: 10.0),
                                            viewEmployeeList['email'] == null
                                                ? const Text('')
                                                : Text(
                                                    '${viewEmployeeList['email']}',
                                                    style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w600),
                                                  ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 20),

                            /// Документы
                            StreamBuilder(
                              stream: myStreamPhotoDoc.stream,
                              builder: (BuildContext context, AsyncSnapshot<dynamic>snapshot) {
                                return   Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                          'Документы',
                                          style: TextStyle(fontWeight: FontWeight.w600)),
                                      const SizedBox(height: 20.0),
                                      Container(
                                        padding: const EdgeInsets.all(20.0),
                                        width: double.infinity,
                                        height: 250,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(5.0),
                                          color: viewEmployeeList['is_actual'] == true
                                              ? ColorApp.myColorWhite
                                              : Colors.grey[400],
                                          boxShadow: const [
                                            BoxShadow(
                                              color: Colors.grey,
                                              blurRadius: 5,
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          children: [
                                            /// Удостоверение
                                            Expanded(
                                              child: GestureDetector(
                                                onTap: viewEmployeeList['is_actual'] == false ?  null : () async {

                                                  // await openGalleryDocUserCertificate();
                                                  setState(() {});
                                                  myStream.add(IntTest.indexScreens);
                                                  // setState(() {
                                                  //   showDialog(
                                                  //       context: context,
                                                  //       builder: (context) =>
                                                  //           const AlertDialog(content: WorksPhotoDocUdo()));
                                                  // });
                                                },
                                                child: viewEmployeeList['identity_card'] == null
                                                    ? const DottedBorder(
                                                  // radius: Radius.circular(20.0),
                                                  // color: ColorApp.myColorGray,
                                                  child: Padding(
                                                    padding: EdgeInsets.all(8.0),
                                                    child: Column(
                                                      // crossAxisAlignment: CrossAxisAlignment.center,
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      children: [
                                                        Icon(Icons.backup, color: ColorApp.myColorGrayText, size: 30.0),
                                                        SizedBox(height: 10.0),
                                                        Row(
                                                          mainAxisAlignment: MainAxisAlignment.center,
                                                          children: [
                                                            Text('Добавить фото\nудостоверения',
                                                                style: TextStyle(
                                                                    fontSize:
                                                                    16.0,
                                                                    color: ColorApp
                                                                        .myColorGrayText)),
                                                          ],
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                )
                                                    : Image.network('http://${viewEmployeeList['identity_card']}'),
                                              ),
                                            ),
                                            const SizedBox(width: 20.0),

                                            /// ЦОК
                                            Expanded(
                                              child: GestureDetector(
                                                onTap: viewEmployeeList['is_actual'] == false ?  null :  () async {
                                                  // await openGalleryDocUserQualifications();
                                                  myStream.add(IntTest.indexScreens);
                                                  setState(() {});
                                                  // setState(() {
                                                  //   showDialog(
                                                  //       context: context,
                                                  //       builder: (context) =>
                                                  //           const AlertDialog(
                                                  //             content:
                                                  //                 WorksPhotoDoc(),
                                                  //           ));
                                                  // });
                                                },
                                                child: viewEmployeeList['qualification_file'] == null
                                                    ? const DottedBorder(
                                                  // radius: Radius.circular(20.0),
                                                  // color: ColorApp.myColorGray,
                                                  child: Center(
                                                    child: Padding(padding: EdgeInsets.all(8.0),
                                                      child: Column(
                                                        mainAxisAlignment: MainAxisAlignment.center,
                                                        children: [
                                                          Icon(Icons.backup, color: ColorApp.myColorGrayText,size: 30.0),
                                                          SizedBox(height: 10.0),
                                                          Text(
                                                            'Добавить фото\nЦОК',
                                                            textAlign: TextAlign.center,
                                                            style: TextStyle(
                                                                fontSize: 16.0,
                                                                color: ColorApp.myColorGrayText),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                )
                                                    : StreamBuilder(
                                                  stream:
                                                  myStreamPhotoDoc.stream,
                                                  builder: (BuildContext
                                                  context,
                                                      AsyncSnapshot<dynamic>
                                                      snapshot) {
                                                    return Image.network(
                                                        'http://${viewEmployeeList['qualification_file']}');
                                                  },
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Просмотр и изменение фото Удостоверение ======================
// class WorksPhotoDocUdoForeman extends StatefulWidget {
//   const WorksPhotoDocUdoForeman({Key? key}) : super(key: key);
//
//   @override
//   State<WorksPhotoDocUdoForeman> createState() => _WorksPhotoDocUdoForemanState();
// }
//
// class _WorksPhotoDocUdoForemanState extends State<WorksPhotoDocUdoForeman> {
//   /// Функция изменение фото  ====================
//   var imagePath;
//   String basename(String path) {
//     if (path.isNotEmpty) {
//       String str = path.replaceAll(RegExp(r'(.png|.jpeg|.svg|.jpg)'), '');
//       return str;
//     }
//     return 'noName';
//   }
//   Future openGalleryDocUser() async {
//     if (kIsWeb) {
//       MediaInfo? imageFile = (await ImagePickerWeb.getImageInfo);
//       if (imageFile != null) {
//         imagePath = imageFile;
//         print(imagePath);
//         requestHttp(imageFile);
//       }
//     }
//   }
//   requestHttp(MediaInfo imageFile) async {
//     Map<String, String> headers = {
//       "Accept": "application/json",
//       "Authorization": "Bearer ${IntTest.token}"
//     }; // ignore this headers if there is no authentication
//     var uri = Uri.parse(
//         "${ApiConfig.base}/cp/admin/universal-user/${IntTest.pressHover}/identity-card/");
//     http.MultipartRequest request = http.MultipartRequest("PUT", uri);
//     http.MultipartFile multipartFile = http.MultipartFile.fromBytes(
//         'file', imageFile.data!,
//         contentType: MediaType('image', 'jpeg'),
//         filename: basename(imageFile.fileName ?? ''));
//     request.files.add(multipartFile);
//     request.headers.addAll(headers);
//     var response = await request.send();
//     response.stream.transform(utf8.decoder).listen((value) {
//       Map listTestPhoto = jsonDecode(value);
//       listSelectedEmployeeForeman['data']['identity_card'] =
//           listTestPhoto['data']['photo'];
//       getListEmployeesInfoForeman(IntTest.pressHover);
//       myStream.add(IntTest.indexScreens);
//     });
//   }
//   /// ============================================
//
//   @override
//   Widget build(BuildContext context) {
//     return SizedBox(
//         width: 500,
//         height: 500,
//         child: Column(
//           children: [
//             Row(
//               children: [
//                 IconButton(
//                     onPressed: () async {
//                       await openGalleryDocUser();
//                       myStream.add(IntTest.indexScreens);
//                       Navigator.pop(context);
//                       setState(() {});
//                     },
//                     icon:
//                         const Icon(Icons.create_outlined, color: Colors.green)),
//                 const Spacer(),
//                 IconButton(
//                     onPressed: () {
//                       Navigator.pop(context);
//                     },
//                     icon:
//                         const Icon(Icons.close_outlined, color: Colors.green)),
//               ],
//             ),
//             listSelectedEmployeeForeman['data']['identity_card'] == null
//                 ? IconButton(
//                     onPressed: () async {
//                       await openGalleryDocUser();
//                       myStream.add(IntTest.indexScreens);
//                       // await getListEmployeesInfo(IntTest.pressHover);
//                       // ignore: use_build_context_synchronously
//                       Navigator.pop(context);
//                       setState(() {});
//                     },
//                     icon: const Icon(
//                       Icons.photo_camera_outlined,
//                       color: Colors.green,
//                       size: 40.0,
//                     ))
//                 : Image.network('http://${listSelectedEmployeeForeman['data']['identity_card']}'),
//           ],
//         ));
//   }
// }
/// ==============================================================

/// Просмотр и изменение фото ЦОК ==========================
// class WorksPhotoDocForeman extends StatefulWidget {
//   const WorksPhotoDocForeman({Key? key}) : super(key: key);
//
//   @override
//   State<WorksPhotoDocForeman> createState() => _WorksPhotoDocForemanState();
// }
//
// class _WorksPhotoDocForemanState extends State<WorksPhotoDocForeman> {
//   /// Функция изменение фото ЦОК ================
//   var imagePathDoc;
//   String basenameDoc(String path) {
//     if (path.isNotEmpty) {
//       String str = path.replaceAll(RegExp(r'(.png|.jpeg|.svg|.jpg)'), '');
//       return str;
//     }
//     return 'noName';
//   }
//   Future openGalleryDocUser() async {
//     if (kIsWeb) {
//       MediaInfo? imageFile = (await ImagePickerWeb.getImageInfo);
//       if (imageFile != null) {
//         imagePathDoc = imageFile;
//         print(imagePathDoc);
//         requestHttpDoc(imageFile);
//       }
//     }
//   }
//   requestHttpDoc(MediaInfo imageFile) async {
//     Map<String, String> headers = {
//       "Accept": "application/json",
//       "Authorization": "Bearer ${IntTest.token}"
//     }; // ignore this headers if there is no authentication
//     var uri = Uri.parse(
//         "${ApiConfig.base}/cp/admin/universal-user/${IntTest.pressHover}/qualification-file/");
//     http.MultipartRequest request = http.MultipartRequest("PUT", uri);
//     http.MultipartFile multipartFile = http.MultipartFile.fromBytes(
//         'file', imageFile.data!,
//         contentType: MediaType('image', 'jpeg'),
//         filename: basenameDoc(imageFile.fileName ?? ''));
//     request.files.add(multipartFile);
//     request.headers.addAll(headers);
//     var response = await request.send();
//     response.stream.transform(utf8.decoder).listen((value) {
//       Map listTestPhoto = jsonDecode(value);
//       listSelectedEmployeeForeman['data']['qualification_file'] =
//           listTestPhoto['data']['photo'];
//       getListEmployeesInfoForeman(IntTest.pressHover);
//       myStreamPhotoDoc.add(IntTest.indexScreens);
//       myStream.add(IntTest.indexScreens);
//       setState(() {});
//     });
//   }
//   /// ===========================================
//
//   @override
//   Widget build(BuildContext context) {
//     return SizedBox(
//         height: 500,
//         width: 500,
//         child: Column(
//           children: [
//             Row(
//               children: [
//                 IconButton(
//                     onPressed: () async {
//                       await openGalleryDocUser();
//                       Navigator.pop(context);
//                       setState(() {});
//                     },
//                     icon:
//                         const Icon(Icons.create_outlined, color: Colors.green)),
//                 const Spacer(),
//                 IconButton(
//                     onPressed: () {
//                       Navigator.pop(context);
//                     },
//                     icon:
//                         const Icon(Icons.close_outlined, color: Colors.green)),
//               ],
//             ),
//             Image.network(
//                 fit: BoxFit.cover,
//                 'http://${listSelectedEmployeeForeman['data']['qualification_file']}'),
//           ],
//         ));
//   }
// }
/// ========================================================


/// Иконка с фото ==========================================
class MyUserForeman extends StatefulWidget {
  const MyUserForeman({Key? key}) : super(key: key);

  @override
  State<MyUserForeman> createState() => _MyUserForemanState();
}
class _MyUserForemanState extends State<MyUserForeman> {
  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return CircularPercentIndicator(
      radius: size.width > 350 ? 33.0 : 23.0,
      lineWidth: 5.0,
      percent: 0.7,
      progressColor: ColorApp.myColorGreenAuth,
      backgroundColor: ColorApp.myColorAvatar,
      center: GestureDetector(
          onTap: () async {
            IntTest.indexScreensForeman = 24;
            myStream.add(IntTest.indexScreensForeman);
            setState(() {});
          },
          child: StreamBuilder(
            stream: myStream.stream,
            builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
              return CircleAvatar(
                radius: size.width > 350 ? 29.0 : 20.0,
                backgroundColor: Colors.transparent,
                backgroundImage: const AssetImage('assets/user.png'),
                foregroundImage:  NetworkImage('http://${userProfile[0]['photo']}'),
              );
            },
          )

      ),
    );
  }
}
/// ========================================================