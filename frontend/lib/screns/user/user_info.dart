import 'package:els/screns/user/user_contact.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../helper/class_colors.dart';
import '../home_page/home_page.dart';

/// Блок User Info

class UserInfo extends StatelessWidget {
  const UserInfo({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: myStream.stream,
      builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Информация',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 20.0),
            Container(
              padding: const EdgeInsets.all(20.0),
              height: 250,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5.0),
                color: ColorApp.myColorWhite,
                boxShadow: const [
                  BoxShadow(
                    color: Colors.grey,
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
                        if (userProfile[0]['division_id'] != null)
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
                                      '${userProfile[0]['division_id']['title']}',
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
                        if (userProfile[0]['role_id'] != null)
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
                                      '${userProfile[0]['role_id']['name']}',
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
                        if (userProfile[0]['date_of_employment'] != null)
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
                                              userProfile[0]['date_of_employment'] * 1000)),
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
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ///Компания
                        if (userProfile[0]['company_id'] != null)
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
                                      '${userProfile[0]['company_id']['name']}',
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
                        if (userProfile[0]['role_id'] != null)
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
                                      '${userProfile[0]['role_id']['name']}',
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
                        if (userProfile[0]['birthday'] != null)
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
                                          userProfile[0]['birthday'] *
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
              // Row(
              //   children: [
              //     /// Участок , Должность, Компания
              //     Column(
              //       children: [
              //         ///Участок
              //         Row(
              //           children: [
              //             const Icon(Icons.location_on_outlined),
              //             const SizedBox(width: 20.0),
              //             Column(
              //               crossAxisAlignment: CrossAxisAlignment.start,
              //               children: [
              //                 const Text('Участок'),
              //                 const SizedBox(height: 10.0),
              //                 Text('Участок № ${userProfile[0]['company_id']}',
              //                     style: const TextStyle(
              //                         fontSize: 16.0,
              //                         fontWeight: FontWeight.w600)),
              //               ],
              //             ),
              //           ],
              //         ),
              //
              //         ///Должность
              //         Row(
              //           children: [
              //             const Icon(Icons.person_outline_outlined),
              //             const SizedBox(width: 20.0),
              //             Column(
              //               crossAxisAlignment: CrossAxisAlignment.start,
              //               children: [
              //                 const Text('Должность'),
              //                 const SizedBox(height: 10.0),
              //                 Text('${userProfile[0]['role_id']['name']}',
              //                     style: const TextStyle(
              //                         fontSize: 16.0,
              //                         fontWeight: FontWeight.w600)),
              //               ],
              //             ),
              //           ],
              //         ),
              //
              //         ///Компания
              //         Row(
              //           children: [
              //             const Icon(Icons.domain),
              //             const SizedBox(width: 20.0),
              //             Column(
              //               crossAxisAlignment: CrossAxisAlignment.start,
              //               children: [
              //                 const Text('Компания'),
              //                 const SizedBox(height: 10.0),
              //                 Text(userProfile[0]['company_id'],
              //                     style: const TextStyle(
              //                         fontSize: 16.0,
              //                         fontWeight: FontWeight.w600)),
              //               ],
              //             ),
              //           ],
              //         ),
              //       ],
              //     ),
              //
              //     /// Дата рождения, Дата приема на работу, Компания
              //     Column(
              //       children: [
              //         /// Дата рождения
              //         Row(
              //           children: [
              //             const Icon(Icons.location_on_outlined),
              //             const SizedBox(width: 20.0),
              //             Column(
              //               crossAxisAlignment: CrossAxisAlignment.start,
              //               children: [
              //                 const Text('Дата рождения'),
              //                 const SizedBox(height: 10.0),
              //                 Text('Участок № ${userProfile[0]['birthday']}',
              //                     style: const TextStyle(
              //                         fontSize: 16.0,
              //                         fontWeight: FontWeight.w600)),
              //               ],
              //             ),
              //           ],
              //         ),
              //
              //         /// Дата приема на работу
              //         Row(
              //           children: [
              //             const Icon(Icons.person_outline_outlined),
              //             const SizedBox(width: 20.0),
              //             Column(
              //               crossAxisAlignment: CrossAxisAlignment.start,
              //               children: [
              //                 const Text('Должность'),
              //                 const SizedBox(height: 10.0),
              //                 Text('${userProfile[0]['date_of_employment']}',
              //                     style: const TextStyle(
              //                         fontSize: 16.0,
              //                         fontWeight: FontWeight.w600)),
              //               ],
              //             ),
              //           ],
              //         ),
              //
              //         /// Компания
              //         Row(
              //           children: [
              //             const Icon(Icons.domain),
              //             const SizedBox(width: 20.0),
              //             Column(
              //               crossAxisAlignment: CrossAxisAlignment.start,
              //               children: [
              //                 const Text('Компания'),
              //                 const SizedBox(height: 10.0),
              //                 Text(userProfile[0]['company_id'],
              //                     style: const TextStyle(
              //                         fontSize: 16.0,
              //                         fontWeight: FontWeight.w600)),
              //               ],
              //             ),
              //           ],
              //         ),
              //       ],
              //     ),
              //   ],
              // ),
            ),
          ],
        );
      },
    );
  }
}
