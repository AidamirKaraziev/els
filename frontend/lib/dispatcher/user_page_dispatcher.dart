import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../../../helper/class_colors.dart';
import 'package:http/http.dart' as http;
import '../../screns/home_page/home_page.dart';
import '../screns/user/user_contact.dart';
import 'package:els/helper/api_config.dart';
import 'package:els/helper/api_image.dart';

/// Окно User

class OpenViewUserDispatcher extends StatefulWidget {
  const OpenViewUserDispatcher({Key? key}) : super(key: key);

  @override
  State<OpenViewUserDispatcher> createState() => _OpenViewUserDispatcherState();
}

class _OpenViewUserDispatcherState extends State<OpenViewUserDispatcher> {

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
                        /// Кнопка Назад
                        if (size.width <= 1350)
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
                                      IntTest.indexScreensDispatcher = 0;
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
                        Text('Мой Профиль',
                            style: TextStyle(
                                fontSize: size.width > 350 ? 25.0 : 18.0,
                                fontWeight: size.width > 350
                                    ? FontWeight.w700
                                    : FontWeight.w500)),

                        /// Кнопки Изменить Удалить
                        // Row(
                        //   children: [
                        //     const SizedBox(width: 10.0),
                        //
                        //     /// Изменить
                        //     IconButton(
                        //         onPressed: () {
                        //           setState(() {
                        //             showDialog(
                        //                 context: context,
                        //                 builder: (context) => const AlertDialog(
                        //                     content: EditingEmployeeForeman()));
                        //           });
                        //         },
                        //         icon: const Icon(Icons.edit_outlined,
                        //             color: ColorApp.myColorGreenAuth)),
                        //     const SizedBox(width: 10.0),
                        //
                        //     /// Удалить
                        //     // IconButton(
                        //     //     onPressed: () {
                        //     //       setState(() {
                        //     //         showDialog(
                        //     //             context: context,
                        //     //             builder: (context) => AlertDialog(
                        //     //                     content: SizedBox(
                        //     //                   width: 200.0,
                        //     //                   height: 60.0,
                        //     //                   child: Column(
                        //     //                     mainAxisAlignment:
                        //     //                         MainAxisAlignment.center,
                        //     //                     children: [
                        //     //                       const Text('Удалить сотрудника?'),
                        //     //                       const Spacer(),
                        //     //                       Row(
                        //     //                           mainAxisAlignment:
                        //     //                               MainAxisAlignment
                        //     //                                   .center,
                        //     //                           children: [
                        //     //                             Expanded(
                        //     //                                 child:
                        //     //                                     ElevatedButton(
                        //     //                                         onPressed:
                        //     //                                             () async {
                        //     //                                           await deleteEmployeeForeman(IntTest.pressHover);
                        //     //                                           getEmployeeForeman.removeWhere((item) =>
                        //     //                                           item["id"] == IntTest.pressHover);
                        //     //                                           IntTest.indexScreensForeman = 5;
                        //     //                                           myStream.add(IntTest.indexScreensForeman);
                        //     //                                           Navigator.pop(context);
                        //     //                                         },
                        //     //                                         style: ElevatedButton.styleFrom(
                        //     //                                             primary:
                        //     //                                                 ColorApp
                        //     //                                                     .myColorRed),
                        //     //                                         child: const Text(
                        //     //                                             'Да',
                        //     //                                             style: TextStyle(
                        //     //                                                 fontSize: 16.0,
                        //     //                                                 fontWeight: FontWeight.bold)))),
                        //     //                             const SizedBox(width: 20.0),
                        //     //                             Expanded(
                        //     //                                 child:
                        //     //                                     ElevatedButton(
                        //     //                                         onPressed:
                        //     //                                             () {
                        //     //                                           Navigator.pop(
                        //     //                                               context);
                        //     //                                         },
                        //     //                                         style: ElevatedButton.styleFrom(
                        //     //                                             primary:
                        //     //                                                 ColorApp
                        //     //                                                     .myColorGreenAuth),
                        //     //                                         child: const Text(
                        //     //                                             'Нет',
                        //     //                                             style: TextStyle(
                        //     //                                                 fontSize:
                        //     //                                                     16.0,
                        //     //                                                 fontWeight:
                        //     //                                                     FontWeight.bold)))),
                        //     //                           ]),
                        //     //                       const Spacer(),
                        //     //                     ],
                        //     //                   ),
                        //     //                 )));
                        //     //       });
                        //     //     },
                        //     //     icon: const Icon(Icons.delete_outline_outlined,
                        //     //         color: ColorApp.myColorRed)),
                        //   ],
                        // ),
                        const Spacer(),

                        ///Колокольчик
                        // if (size.width > 400)
                        //   Badge(
                        //     alignment: const AlignmentDirectional(21, 4),
                        //     backgroundColor: ColorApp.myColorRed,
                        //     isLabelVisible:
                        //         IntTest.badgeCount > 0 ? true : false,
                        //     label: IntTest.badgeCount < 1
                        //         ? const SizedBox.shrink()
                        //         : Text(IntTest.badgeCount.toString(),
                        //             style: const TextStyle(
                        //                 fontSize: 12.0,
                        //                 color: ColorApp.myColorWhite,
                        //                 fontWeight: FontWeight.w500)),
                        //     child: IconButton(
                        //       onPressed: () {},
                        //       icon: const Icon(
                        //           Icons.notifications_none_outlined,
                        //           size: 25.0),
                        //     ),
                        //   ),
                        // SizedBox(width: size.width > 500 ? 40.0 : 10.0),

                        ///Аватар Юзера
                        const MyUserDispatcher(),
                      ],
                    ),
                  ),

                  /// ===========
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        /// Профиль Фото Имя и Контакты
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
                                  Container(
                                    height: 250,
                                    width: 250,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(5.0),
                                      color: ColorApp.myColorWhite,
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
                                        CircleAvatar(
                                            radius: 70.0,
                                            backgroundImage: const AssetImage('assets/user.png'),
                                            foregroundImage: apiImage(viewEmployeeList['photo'])),
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
                                        // Row(
                                        //   mainAxisAlignment:
                                        //       MainAxisAlignment.center,
                                        //   children: [
                                        //     /// Редактировать
                                        //     // OutlinedButton(
                                        //     //     style: OutlinedButton.styleFrom(
                                        //     //       padding: const EdgeInsets
                                        //     //               .symmetric(
                                        //     //           horizontal: 20.0,
                                        //     //           vertical: 10.0),
                                        //     //       side: BorderSide(
                                        //     //           color:
                                        //     //               Colors.grey.shade400,
                                        //     //           width: 1.0),
                                        //     //       shape: RoundedRectangleBorder(
                                        //     //         borderRadius:
                                        //     //             BorderRadius.circular(
                                        //     //                 20.0),
                                        //     //       ),
                                        //     //     ),
                                        //     //     onPressed: () {
                                        //     //       setState(() {
                                        //     //         showDialog(
                                        //     //             context: context,
                                        //     //             builder: (context) =>
                                        //     //                 const AlertDialog(
                                        //     //                     content:
                                        //     //                         EditingEmployeeForeman()));
                                        //     //       });
                                        //     //       // await defrostingEmployee(IntTest.pressHover);
                                        //     //       // myStream.add(IntTest.indexScreens);
                                        //     //     },
                                        //     //     child: Text('Редактировать',
                                        //     //         style: TextStyle(
                                        //     //             fontSize: 10.0,
                                        //     //             color: Colors
                                        //     //                 .grey.shade400))),
                                        //     const SizedBox(width: 10.0),
                                        //
                                        //     /// Заморозить
                                        //     // IconButton(
                                        //     //     onPressed: () async {
                                        //     //       await showDialog(
                                        //     //           context: context,
                                        //     //           builder: (context) =>
                                        //     //               const AlertDialog(
                                        //     //                   content: EmployeeAccountFreezeForeman()));
                                        //     //       setState(() {});
                                        //     //     },
                                        //     //     icon: const Icon(
                                        //     //         Icons.ac_unit_outlined,
                                        //     //         color: ColorApp
                                        //     //             .myColorAvatar)),
                                        //   ],
                                        // ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(width: 20),
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
                                      viewEmployeeList['is_active'] == true
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
                          ],
                        ),
                        const SizedBox(height: 20),

                        /// Информация
                        Column(
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
                                viewEmployeeList['is_active'] == true
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
                        const SizedBox(height: 20),

                        /// Документы
                        StreamBuilder(
                          stream: myStreamPhotoDoc.stream,
                          builder: (BuildContext context, AsyncSnapshot<dynamic>snapshot) {
                            return   Column(
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
                                    color: viewEmployeeList['is_active'] == true
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
                                          onTap: viewEmployeeList['is_active'] == false ?  null : () async {
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

                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Icon(Icons.backup, color: ColorApp.myColorGrayText, size: 30.0),
                                                  SizedBox(height: 10.0),
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    children: [
                                                      Text('Нет фото\nудостоверения',
                                                          textAlign: TextAlign.center,
                                                          style: TextStyle(
                                                              fontSize: 16.0,
                                                              color: ColorApp.myColorGrayText)),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                            ),
                                          )
                                              : apiImageWidget(viewEmployeeList['identity_card']),
                                        ),
                                      ),
                                      const SizedBox(width: 20.0),

                                      /// ЦОК
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: viewEmployeeList['is_active'] == false ?  null :  () async {
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
                                                      'Нет фото\nЦОК',
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
                                              return apiImageWidget(viewEmployeeList['qualification_file']);
                                            },
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
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

/// Иконка с фото ==========================================
class MyUserDispatcher extends StatefulWidget {
  const MyUserDispatcher({Key? key}) : super(key: key);

  @override
  State<MyUserDispatcher> createState() => _MyUserDispatcherState();
}
class _MyUserDispatcherState extends State<MyUserDispatcher> {
  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return CircularPercentIndicator(
      radius: 23.0,
      lineWidth: 5.0,
      percent: 0.7,
      progressColor: ColorApp.myColorGreenAuth,
      backgroundColor: ColorApp.myColorAvatar,
      center: GestureDetector(
          onTap: () async {
            IntTest.indexScreensDispatcher = 4;
            myStream.add(IntTest.indexScreensDispatcher);
            setState(() {});
          },
          child: StreamBuilder(
            stream: myStream.stream,
            builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
              return CircleAvatar(
                radius: 20.0,
                backgroundColor: Colors.transparent,
                backgroundImage: const AssetImage('assets/user.png'),
                foregroundImage:  apiImage(userProfile[0]['photo']),
              );
            },
          )

      ),
    );
  }
}
/// ========================================================