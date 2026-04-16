import 'dart:convert';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker_web/image_picker_web.dart';
import 'package:intl/intl.dart';
import '../../../helper/class_colors.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../../../screns/employee/view/employees_screen.dart';
import '../../../screns/home_page/home_page.dart';
import '../../user_page_foreman.dart';
import '../employees_screen_foreman.dart';
import 'employees_archive_screen_foreman.dart';

/// Окно выбранного сотрудника Архив

class OpenViewEmployeeArchiveForeman extends StatefulWidget {
  const OpenViewEmployeeArchiveForeman({Key? key}) : super(key: key);

  @override
  State<OpenViewEmployeeArchiveForeman> createState() => _OpenViewEmployeeArchiveForemanState();
}


class _OpenViewEmployeeArchiveForemanState extends State<OpenViewEmployeeArchiveForeman> {
  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final viewEmployeeListArchived = listSelectedEmployeeForemanArchive;
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
                                      getListEmployeeForeman();
                                      IntTest.indexScreensForeman = 22;
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

                        ///Text
                        Text('Сотрудник в архиве',
                            style: TextStyle(
                                fontSize: size.width > 350 ? 25.0 : 18.0,
                                fontWeight: size.width > 350
                                    ? FontWeight.w700
                                    : FontWeight.w500)),
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
                                  style: TextStyle(fontWeight: FontWeight.w600)),
                                const SizedBox(height: 20.0),
                                Stack(
                                    children: [
                                      Container(
                                        height: 250,
                                        width: 250,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(5.0),
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
                                            CircleAvatar(
                                              radius: 70.0,
                                              backgroundImage: const AssetImage('assets/user.png'),
                                              foregroundImage: NetworkImage('http://${viewEmployeeListArchived['photo']}'),
                                              backgroundColor: ColorApp.myColorGray,
                                            ),
                                            const SizedBox(height: 10.0),
                                            Center(
                                              child: Text('${viewEmployeeListArchived['name']}',
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
                                                            color: Colors.grey
                                                                .shade400))),
                                                const SizedBox(width: 10.0),

                                                /// Заморозить
                                                // const IconButton(
                                                //     onPressed: null,
                                                //     icon: Icon(
                                                //         Icons.ac_unit_outlined,
                                                //         color: ColorApp.myColorAvatar)),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      /// Разморозить
                                      // Positioned(
                                      //   left: 30.0,
                                      //   right: 30.0,
                                      //   bottom: 20.0,
                                      //   child: ElevatedButton(
                                      //       style: ElevatedButton.styleFrom(
                                      //           backgroundColor: ColorApp.myColorBlue),
                                      //       onPressed: () async {
                                      //         await defrostingEmployeeForeman(IntTest.pressHover);
                                      //         await getListEmployeeForeman();
                                      //         IntTest.indexScreensForeman = 5;
                                      //         myStream.add(IntTest.indexScreensForeman);
                                      //         setState(() {});
                                      //       },
                                      //       child: const Text(
                                      //           'Разморозить')),
                                      // ),
                                      /// ===========
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
                                      color: Colors.grey[400],
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
                                              if (viewEmployeeListArchived['division_id'] != null)
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
                                                            '${viewEmployeeListArchived['division_id']['title']}',
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
                                              if (viewEmployeeListArchived['role_id'] != null)
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
                                                            '${viewEmployeeListArchived['role_id']['name']}',
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
                                              if (viewEmployeeListArchived['date_of_employment'] != null)
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
                                                            'Дата приема на работу'),
                                                        const SizedBox(
                                                            height: 10.0),
                                                        Text(
                                                            DateFormat(
                                                                'dd -MM-yyyy').format(
                                                                DateTime.fromMillisecondsSinceEpoch(
                                                                    viewEmployeeListArchived['date_of_employment'] * 1000)),
                                                            style: const TextStyle(
                                                                fontSize: 16.0,
                                                                fontWeight: FontWeight.w600)),
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
                                              if (viewEmployeeListArchived['company_id'] != null)
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
                                                            '${viewEmployeeListArchived['company_id']['name']}',
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
                                              if (viewEmployeeListArchived['role_id'] !=
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
                                                            '${viewEmployeeListArchived['role_id']['name']}',
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
                                              if (viewEmployeeListArchived[
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
                                                                viewEmployeeListArchived['birthday'] *
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
                                      color: Colors.grey[400],
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
                                            viewEmployeeListArchived['role_id'] == null
                                                ? const Text('')
                                                : Text(
                                              '${viewEmployeeListArchived['name']}',
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
                                            viewEmployeeListArchived['contact_phone'] == null
                                                ? const Text('')
                                                : Text(
                                              '+7${viewEmployeeListArchived['contact_phone']}',
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
                                            viewEmployeeListArchived['email'] == null
                                                ? const Text('')
                                                : Text('${viewEmployeeListArchived['email']}',
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
                                          color: Colors.grey[400],
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
                                                onTap: null,
                                                child: viewEmployeeListArchived['identity_card'] == null
                                                    ? const DottedBorder(
                                                  // radius: const Radius.circular(20.0),
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
                                                    : Image.network('http://${viewEmployeeListArchived['identity_card']}'),
                                              ),
                                            ),
                                            const SizedBox(width: 20.0),

                                            /// ЦОК
                                            Expanded(
                                              child: GestureDetector(
                                                onTap: null,
                                                child: viewEmployeeListArchived['qualification_file'] == null
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
                                                        'http://${viewEmployeeListArchived['qualification_file']}');
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
class WorksPhotoDocUdo extends StatefulWidget {
  const WorksPhotoDocUdo({Key? key}) : super(key: key);

  @override
  State<WorksPhotoDocUdo> createState() => _WorksPhotoDocUdoState();
}

class _WorksPhotoDocUdoState extends State<WorksPhotoDocUdo> {
  /// Функция изменение фото  ====================
  var imagePath;
  String basename(String path) {
    if (path.isNotEmpty) {
      String str = path.replaceAll(RegExp(r'(.png|.jpeg|.svg|.jpg)'), '');
      return str;
    }
    return 'noName';
  }
  Future openGalleryDocUser() async {
    if (kIsWeb) {
      MediaInfo? imageFile = (await ImagePickerWeb.getImageInfo);
      if (imageFile != null) {
        imagePath = imageFile;
        print(imagePath);
        requestHttp(imageFile);
      }
    }
  }
  requestHttp(MediaInfo imageFile) async {
    Map<String, String> headers = {
      "Accept": "application/json",
      "Authorization": "Bearer ${IntTest.token}"
    }; // ignore this headers if there is no authentication
    var uri = Uri.parse(
        "http://${IntTest.myIp}/api/v1/cp/admin/universal-user/${IntTest.pressHover}/identity-card/");
    http.MultipartRequest request = http.MultipartRequest("PUT", uri);
    http.MultipartFile multipartFile = http.MultipartFile.fromBytes(
        'file', imageFile.data!,
        contentType: MediaType('image', 'jpeg'),
        filename: basename(imageFile.fileName ?? ''));
    request.files.add(multipartFile);
    request.headers.addAll(headers);
    var response = await request.send();
    response.stream.transform(utf8.decoder).listen((value) {
      Map listTestPhoto = jsonDecode(value);
      listSelectedEmployee['data']['identity_card'] =
      listTestPhoto['data']['photo'];
      getListEmployeesInfo(IntTest.pressHover);
      myStream.add(IntTest.indexScreens);
    });
  }
  /// ============================================

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        width: 500,
        height: 500,
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                    onPressed: () async {
                      await openGalleryDocUser();
                      myStream.add(IntTest.indexScreens);
                      Navigator.pop(context);
                      setState(() {});
                    },
                    icon:
                    const Icon(Icons.create_outlined, color: Colors.green)),
                const Spacer(),
                IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon:
                    const Icon(Icons.close_outlined, color: Colors.green)),
              ],
            ),
            listSelectedEmployee['data']['identity_card'] == null
                ? IconButton(
                onPressed: () async {
                  await openGalleryDocUser();
                  myStream.add(IntTest.indexScreens);
                  // await getListEmployeesInfo(IntTest.pressHover);
                  // ignore: use_build_context_synchronously
                  Navigator.pop(context);
                  setState(() {});
                },
                icon: const Icon(
                  Icons.photo_camera_outlined,
                  color: Colors.green,
                  size: 40.0,
                ))
                : Image.network('http://${listSelectedEmployee['data']['identity_card']}'),
          ],
        ));
  }
}

/// ==============================================================

/// Просмотр и изменение фото ЦОК ==========================
class WorksPhotoDoc extends StatefulWidget {
  const WorksPhotoDoc({Key? key}) : super(key: key);

  @override
  State<WorksPhotoDoc> createState() => _WorksPhotoDocState();
}

class _WorksPhotoDocState extends State<WorksPhotoDoc> {
  /// Функция изменение фото ЦОК ================
  var imagePathDoc;
  String basenameDoc(String path) {
    if (path.isNotEmpty) {
      String str = path.replaceAll(RegExp(r'(.png|.jpeg|.svg|.jpg)'), '');
      return str;
    }
    return 'noName';
  }
  Future openGalleryDocUser() async {
    if (kIsWeb) {
      MediaInfo? imageFile = (await ImagePickerWeb.getImageInfo);
      if (imageFile != null) {
        imagePathDoc = imageFile;
        print(imagePathDoc);
        requestHttpDoc(imageFile);
      }
    }
  }
  requestHttpDoc(MediaInfo imageFile) async {
    Map<String, String> headers = {
      "Accept": "application/json",
      "Authorization": "Bearer ${IntTest.token}"
    }; // ignore this headers if there is no authentication
    var uri = Uri.parse(
        "http://${IntTest.myIp}/api/v1/cp/admin/universal-user/${IntTest.pressHover}/qualification-file/");
    http.MultipartRequest request = http.MultipartRequest("PUT", uri);
    http.MultipartFile multipartFile = http.MultipartFile.fromBytes(
        'file', imageFile.data!,
        contentType: MediaType('image', 'jpeg'),
        filename: basenameDoc(imageFile.fileName ?? ''));
    request.files.add(multipartFile);
    request.headers.addAll(headers);
    var response = await request.send();
    response.stream.transform(utf8.decoder).listen((value) {
      Map listTestPhoto = jsonDecode(value);
      listSelectedEmployee['data']['qualification_file'] =
      listTestPhoto['data']['photo'];
      getListEmployeesInfo(IntTest.pressHover);
      myStreamPhotoDoc.add(IntTest.indexScreens);
      myStream.add(IntTest.indexScreens);
      setState(() {});
    });
  }
  /// ===========================================

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        height: 500,
        width: 500,
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                    onPressed: () async {
                      await openGalleryDocUser();
                      Navigator.pop(context);
                      setState(() {});
                    },
                    icon:
                    const Icon(Icons.create_outlined, color: Colors.green)),
                const Spacer(),
                IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon:
                    const Icon(Icons.close_outlined, color: Colors.green)),
              ],
            ),
            Image.network(
                fit: BoxFit.cover,
                'http://${listSelectedEmployee['data']['qualification_file']}'),
          ],
        ));
  }
}

/// ========================================================
