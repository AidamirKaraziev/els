import 'dart:convert';
import 'package:els/helper/api_config.dart';
import 'package:els/helper/button/my_button.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../../helper/class_colors.dart';
import 'package:http/http.dart' as http;

import '../../../screns/home_page/home_page.dart';
import '../task_screen_foreman.dart';
import 'package:els/helper/api_client.dart';
import 'package:els/helper/session.dart';

///Редактирование Задачи

class EditingTaskForeman extends StatefulWidget {
  EditingTaskForeman({
    Key? key,
  }) : super(key: key);

  @override
  State<EditingTaskForeman> createState() => _EditingTaskForemanState();
}

class _EditingTaskForemanState extends State<EditingTaskForeman> {

  Map testTask = {};

  /// Функция Редактирование Задачи ==
  editingTaskForeman(int userId) async {
    var response = await Api.put(
      Uri.parse("${ApiConfig.base}/order/$userId/"),
      headers: {
        "Content-Type": "application/json; charset=utf-8",
      },
      body: json.encode(
        {
          "object_id": newTaskObjectTitle, // объект +
          "task_text": newCommentTask.text, // текст задания +
          "executor_id": executorTitle, // исполнитель +
          "created_at": dateTask.millisecondsSinceEpoch / 1000,  //dateTask, // создан в
          // "accepted_at": "2024-03-06", // принято в
          // "in_progress_at": "2024-03-06", // в процессе
          // "dane_at": "2024-03-06", // сделано
          "status_id": statusTitle, // статус
          "is_viewed": true // выполненно
        },
      ),
    );
    testTask = jsonDecode(utf8.decode(response.bodyBytes));
    // testTask = vova['data'];
    print('Измененная задача : ${testTask['data']['executor_id']['name']}');
  }
  /// ================================

  /// Новоя задача
  TextEditingController newCommentTask = TextEditingController(text: '${listSelectedTaskIdForeman['data']['task_text']}');

  /// Автор  ================
  getAuthorTask() async {
    final url = '${ApiConfig.base}/cp/all-employee/?page=1';
    final res = await Api.get(Uri.parse(url), headers: {
      "Content-Type": "application/json; charset=utf-8",
      'Accept': 'application/json',
    });
    var response = jsonDecode(utf8.decode(res.bodyBytes));
    setState(() {
      listAllAuthor = response['data'];
    });
    // print('Все сотрудники для задач ${listAllEmployee}');
  }
  String? allAuthorTitle;
  List listAllAuthor = [];
  /// ========================

  /// Исполнитель ========================
  getExecutorTask() async {
    final url = '${ApiConfig.base}/cp/all-employee/?page=1';
    final res = await Api.get(Uri.parse(url), headers: {
      "Content-Type": "application/json; charset=utf-8",
      'Accept': 'application/json',
    });
    var response = jsonDecode(utf8.decode(res.bodyBytes));
    setState(() {
      executorList = response['data'];
    });
    // print(mechanicList);
  }
  String? executorTitle;
  List executorList = [];
  /// ====================================

  /// Объект ============================
  getTaskObjectList() async {
    final url = '${ApiConfig.base}/all-objects/?page=1';
    final res = await Api.get(Uri.parse(url), headers: {
      "Content-Type": "application/json; charset=utf-8",
      'Accept': 'application/json',
    });
    var response = jsonDecode(utf8.decode(res.bodyBytes));
    setState(() {
      newTaskObjectList = response['data'];
    });
    // print(organizationList);
  }
  String? newTaskObjectTitle;
  List newTaskObjectList = [];
  /// ===================================

  /// Статус ========================
  getStatusTask() async {
    final url = '${ApiConfig.base}/statuses/?page=1';
    final res = await Api.get(Uri.parse(url), headers: {
      "Content-Type": "application/json; charset=utf-8",
      'Accept': 'application/json',
    });
    var response = jsonDecode(utf8.decode(res.bodyBytes));
    setState(() {
      statusList = response['data'];
    });
    // print(statusList);
  }
  String? statusTitle;
  List statusList = [];
  /// ====================================



  DateTime dateTask = DateTime.now();

  // DateTime newDateTask = DateTime.now();

  @override
  void initState() {
    getAuthorTask();
    getExecutorTask();
    getTaskObjectList();
    getStatusTask();
    // newTaskObjectTitle = listSelectedTaskId['data']['newTaskObjectTitle']['id'];
    // executorTitle = listSelectedTaskId['data']['mechanic_id']['id'];
    // allAuthorTitle = listSelectedTaskId['data']['newTaskObjectTitle']['id'];
    dateTask = DateTime.fromMillisecondsSinceEpoch(listSelectedTaskIdForeman['data']['created_at']*1000);
    newTaskObjectTitle = '${listSelectedTaskIdForeman['data']['object_id']['id']}';
    executorTitle = '${listSelectedTaskIdForeman['data']['executor_id']['id']}';
    statusTitle = '${listSelectedTaskIdForeman['data']['status_id']['id']}';
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 500.0,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ///Тест и кнопкка закрыть
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Редактирование задачи',
                      style:
                      TextStyle(fontSize: 25.0, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 5.0),
                    Text(
                      'Заполните все поля, чтобы изменить задачу',
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
            const Gap(20.0),
            /// Обьект
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Обьекты',
                  style: TextStyle(
                      fontSize: 15.0,
                      fontWeight: FontWeight.bold,
                      color: ColorApp.myColorGrayText),
                ),
                const SizedBox(height: 10.0),
                SizedBox(
                  height: 50.0,
                  child: DropdownButtonFormField(
                    value: newTaskObjectTitle,
                    hint: const Text('Объект'),
                    onChanged: (newValue1) async {
                      setState(() {
                        newTaskObjectTitle = newValue1 as String?;
                        newTaskObjectTitle!.indexOf(newValue1!);
                      });
                    },
                    items: newTaskObjectList.map((jobTitleList) {
                      return DropdownMenuItem(
                        value: jobTitleList['id'].toString(),
                        child: SizedBox(
                          width: 300,
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(jobTitleList['name'],
                                    overflow: TextOverflow.ellipsis),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                  ),
                ),
              ],
            ),
            const Gap(30.0),
            ///Новая Задача
            SizedBox(
              height: 50.0,
              child: Form(
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: TextFormField(
                  cursorColor: ColorApp.myColorGray,
                  controller: newCommentTask,
                  decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: ColorApp.myColorGreenAuth),
                      ),
                      labelText: 'Задача',
                      labelStyle: TextStyle(color: ColorApp.myColorGray)),
                ),
              ),
            ),
            const Gap(20.0),
            /// Исполнитель
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Назначенный исполнитель',
                  style: TextStyle(
                      fontSize: 15.0,
                      fontWeight: FontWeight.bold,
                      color: ColorApp.myColorGrayText),
                ),
                const SizedBox(height: 10.0),
                SizedBox(
                  height: 50.0,
                  child: DropdownButtonFormField(
                    value: executorTitle,
                    hint: Text('${listSelectedTaskIdForeman['data']['executor_id']['id']}'),
                    onChanged: (newValue1) async {
                      setState(() {
                        executorTitle = newValue1 as String?;
                        executorTitle!.indexOf(newValue1!);
                      });
                    },
                    items: executorList.map((jobTitleList) {
                      return DropdownMenuItem(
                        value: jobTitleList['id'].toString(),
                        child: SizedBox(
                          width: 300,
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(jobTitleList['name'],
                                    overflow: TextOverflow.ellipsis),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                  ),
                ),
              ],
            ),
            const Gap(20.0),
            /// Статус
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Статус',
                  style: TextStyle(
                      fontSize: 15.0,
                      fontWeight: FontWeight.bold,
                      color: ColorApp.myColorGrayText),
                ),
                const SizedBox(height: 10.0),
                SizedBox(
                  height: 50.0,
                  child: DropdownButtonFormField(
                    value: statusTitle,
                    hint: Text('${listSelectedTaskIdForeman['data']['status_id']['name']}'),
                    onChanged: (newValue1) async {
                      setState(() {
                        statusTitle = newValue1 as String?;
                        statusTitle!.indexOf(newValue1!);
                      });
                    },
                    // См. `canPickStatus`: экраны в этом коде переиспользуются
                    // между ролями, поэтому правило применяется и здесь.
                    items: statusList.where(canPickStatus).map((jobTitleList) {
                      return DropdownMenuItem(
                        value: jobTitleList['id'].toString(),
                        child: SizedBox(
                          width: 300,
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(jobTitleList['name'],
                                    overflow: TextOverflow.ellipsis),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                  ),
                ),
              ],
            ),
            const Gap(20.0),
            /// Автор задачи
            // Column(
            //   crossAxisAlignment: CrossAxisAlignment.start,
            //   children: [
            //     const Text(
            //       'Автор задачи',
            //       style: TextStyle(
            //           fontSize: 15.0,
            //           fontWeight: FontWeight.bold,
            //           color: ColorApp.myColorGrayText),
            //     ),
            //     const SizedBox(height: 10.0),
            //     SizedBox(
            //       height: 50.0,
            //       child: DropdownButtonFormField(
            //         value: allAuthorTitle,
            //         hint: Text('${listSelectedTaskId['data']['creator_id']['name']}'),
            //         onChanged: (newValue1) async {
            //           setState(() {
            //             allAuthorTitle = newValue1 as String?;
            //             allAuthorTitle!.indexOf(newValue1!);
            //           });
            //         },
            //         items: listAllAuthor.map((jobTitleList) {
            //           return DropdownMenuItem(
            //             value: jobTitleList['id'].toString(),
            //             child: SizedBox(
            //               width: 300,
            //               child: Row(
            //                 children: [
            //                   Expanded(
            //                     child: Text(jobTitleList['name'],
            //                         overflow: TextOverflow.ellipsis),
            //                   ),
            //                 ],
            //               ),
            //             ),
            //           );
            //         }).toList(),
            //         decoration: const InputDecoration(border: OutlineInputBorder()),
            //       ),
            //     ),
            //   ],
            // ),
            // const Gap(20.0),
            /// Дата задачи
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Дата задачи',
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
                          initialDate: dateTask,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(3000));
                      if (dateTime != null) {
                        dateTask = dateTime;
                        setState(() {});
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
                                '${dateTask.day} - ${dateTask.month} - ${dateTask.year}',
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
            const Gap(30.0),
            /// Дата полного ТО, Дата планового ТО, Период ТО
            // Column(
            //   children: [
            //     Row(
            //       children: [
            //         /// Дата полного ТО
            //         Expanded(
            //           child: Column(
            //             crossAxisAlignment: CrossAxisAlignment.start,
            //             children: [
            //               const Text(
            //                 'Дата полного ТО',
            //                 style: TextStyle(
            //                     fontSize: 15.0,
            //                     fontWeight: FontWeight.bold,
            //                     color: ColorApp.myColorGrayText),
            //               ),
            //               const SizedBox(height: 10.0),
            //               InkWell(
            //                   onTap: () async {
            //                     final DateTime? dateTime = await showDatePicker(
            //                         context: context,
            //                         initialDate: newDateFullTO,
            //                         firstDate: DateTime(2000),
            //                         lastDate: DateTime(3000));
            //                     if (dateTime != null) {
            //                       newDateFullTO = dateTime;
            //                       setState(() {});
            //                     }
            //                   },
            //                   child: Container(
            //                       padding: const EdgeInsets.symmetric(
            //                           horizontal: 10.0),
            //                       height: 50,
            //                       decoration: BoxDecoration(
            //                         borderRadius: BorderRadius.circular(5.0),
            //                         border: Border.all(
            //                             width: 1.0, color: Colors.grey),
            //                       ),
            //                       child: Row(
            //                           mainAxisAlignment:
            //                           MainAxisAlignment.spaceBetween,
            //                           children: [
            //                             Text(
            //                               '${newDateFullTO.day} - ${newDateFullTO.month} - ${newDateFullTO.year}',
            //                               style: const TextStyle(
            //                                   color: Colors.grey,
            //                                   fontSize: 16.0),
            //                             ),
            //                             const Icon(
            //                                 Icons.calendar_month_outlined,
            //                                 color: Colors.grey)
            //                           ]))),
            //             ],
            //           ),
            //         ),
            //         const SizedBox(width: 20.0),
            //         /// Дата планового ТО
            //         Expanded(
            //           child: Column(
            //             crossAxisAlignment: CrossAxisAlignment.start,
            //             children: [
            //               const Text(
            //                 'Дата планового ТО',
            //                 style: TextStyle(
            //                     fontSize: 15.0,
            //                     fontWeight: FontWeight.bold,
            //                     color: ColorApp.myColorGrayText),
            //               ),
            //               const SizedBox(height: 10.0),
            //               InkWell(
            //                   onTap: () async {
            //                     final DateTime? dateTime = await showDatePicker(
            //                         context: context,
            //                         initialDate: newDatePlannedTO,
            //                         firstDate: DateTime(2000),
            //                         lastDate: DateTime(3000));
            //                     if (dateTime != null) {
            //                       newDatePlannedTO = dateTime;
            //                       setState(() {});
            //                     }
            //                   },
            //                   child: Container(
            //                       padding: const EdgeInsets.symmetric(
            //                           horizontal: 10.0),
            //                       height: 50,
            //                       decoration: BoxDecoration(
            //                         borderRadius: BorderRadius.circular(5.0),
            //                         border: Border.all(
            //                             width: 1.0, color: Colors.grey),
            //                       ),
            //                       child: Row(
            //                           mainAxisAlignment:
            //                           MainAxisAlignment.spaceBetween,
            //                           children: [
            //                             Text(
            //                               '${newDatePlannedTO.day} - ${newDatePlannedTO.month} - ${newDatePlannedTO.year}',
            //                               style: const TextStyle(
            //                                   color: Colors.grey,
            //                                   fontSize: 16.0),
            //                             ),
            //                             const Icon(
            //                                 Icons.calendar_month_outlined,
            //                                 color: Colors.grey)
            //                           ]))),
            //             ],
            //           ),
            //         ),
            //       ],
            //     ),
            //     const Gap(20.0),
            //     Row(
            //       children: [
            //         /// Дата полного ТО
            //         Expanded(
            //           child: Column(
            //             crossAxisAlignment: CrossAxisAlignment.start,
            //             children: [
            //               const Text(
            //                 'Дата полного ТО',
            //                 style: TextStyle(
            //                     fontSize: 15.0,
            //                     fontWeight: FontWeight.bold,
            //                     color: ColorApp.myColorGrayText),
            //               ),
            //               const SizedBox(height: 10.0),
            //               InkWell(
            //                   onTap: () async {
            //                     final DateTime? dateTime = await showDatePicker(
            //                         context: context,
            //                         initialDate: newDateFullTO,
            //                         firstDate: DateTime(2000),
            //                         lastDate: DateTime(3000));
            //                     if (dateTime != null) {
            //                       newDateFullTO = dateTime;
            //                       setState(() {});
            //                     }
            //                   },
            //                   child: Container(
            //                       padding: const EdgeInsets.symmetric(
            //                           horizontal: 10.0),
            //                       height: 50,
            //                       decoration: BoxDecoration(
            //                         borderRadius: BorderRadius.circular(5.0),
            //                         border: Border.all(
            //                             width: 1.0, color: Colors.grey),
            //                       ),
            //                       child: Row(
            //                           mainAxisAlignment:
            //                           MainAxisAlignment.spaceBetween,
            //                           children: [
            //                             Text(
            //                               '${newDateFullTO.day} - ${newDateFullTO.month} - ${newDateFullTO.year}',
            //                               style: const TextStyle(
            //                                   color: Colors.grey,
            //                                   fontSize: 16.0),
            //                             ),
            //                             const Icon(
            //                                 Icons.calendar_month_outlined,
            //                                 color: Colors.grey)
            //                           ]))),
            //             ],
            //           ),
            //         ),
            //         const SizedBox(width: 20.0),
            //         /// Дата планового ТО
            //         Expanded(
            //           child: Column(
            //             crossAxisAlignment: CrossAxisAlignment.start,
            //             children: [
            //               const Text(
            //                 'Дата планового ТО',
            //                 style: TextStyle(
            //                     fontSize: 15.0,
            //                     fontWeight: FontWeight.bold,
            //                     color: ColorApp.myColorGrayText),
            //               ),
            //               const SizedBox(height: 10.0),
            //               InkWell(
            //                   onTap: () async {
            //                     final DateTime? dateTime = await showDatePicker(
            //                         context: context,
            //                         initialDate: newDatePlannedTO,
            //                         firstDate: DateTime(2000),
            //                         lastDate: DateTime(3000));
            //                     if (dateTime != null) {
            //                       newDatePlannedTO = dateTime;
            //                       setState(() {});
            //                     }
            //                   },
            //                   child: Container(
            //                       padding: const EdgeInsets.symmetric(
            //                           horizontal: 10.0),
            //                       height: 50,
            //                       decoration: BoxDecoration(
            //                         borderRadius: BorderRadius.circular(5.0),
            //                         border: Border.all(
            //                             width: 1.0, color: Colors.grey),
            //                       ),
            //                       child: Row(
            //                           mainAxisAlignment:
            //                           MainAxisAlignment.spaceBetween,
            //                           children: [
            //                             Text(
            //                               '${newDatePlannedTO.day} - ${newDatePlannedTO.month} - ${newDatePlannedTO.year}',
            //                               style: const TextStyle(
            //                                   color: Colors.grey,
            //                                   fontSize: 16.0),
            //                             ),
            //                             const Icon(
            //                                 Icons.calendar_month_outlined,
            //                                 color: Colors.grey)
            //                           ]))),
            //             ],
            //           ),
            //         ),
            //
            //       ],
            //     ),
            //   ],
            // ),
            // const Gap(40.0),
            /// Кнопка Сохранить
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                MainButtonApp(textButton: 'Сохранить', press: () async {
                  await editingTaskForeman(IntTest.pressHover);
                  /// Новая задача
                  listSelectedTaskIdForeman['data']['task_text'] = newCommentTask.text;
                  /// Новая дата
                  listSelectedTaskIdForeman['data']['created_at'] = dateTask.millisecondsSinceEpoch/1000;
                  /// Новый исполнитель
                  listSelectedTaskIdForeman['data']['executor_id']['name'] = testTask['data']['executor_id']['name'];
                  /// Новый статус
                  listSelectedTaskIdForeman['data']['status_id']['id'] = testTask['data']['status_id']['id'];
                  /// Новый оъект
                  listSelectedTaskIdForeman['data']['object_id']['name'] = testTask['data']['object_id']['name'];
                  await getListTaskForeman();
                  myStream.add(IntTest.indexScreens);
                  Navigator.pop(context);
                },),
              ],
            ),
          ],
        ),
      ),
    );
  }
}