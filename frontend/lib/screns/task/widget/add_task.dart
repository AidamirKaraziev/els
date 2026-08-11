import 'dart:convert';
import 'package:els/helper/api_config.dart';
import 'package:flutter/material.dart';
import '../../../helper/button/my_button.dart';
import 'package:http/http.dart' as http;
import '../../../helper/class_colors.dart';
import '../../home_page/home_page.dart';
import '../../user/user_contact.dart';
import '../bloc_task/task_bloc.dart';
import '../view/task_screen.dart';

/// Окно добавление задачи

class AddTask extends StatefulWidget {
  const AddTask({Key? key}) : super(key: key);

  @override
  State<AddTask> createState() => _AddTaskState();
}

class _AddTaskState extends State<AddTask> {
  /// Создание задачи ========
  createNewTask() async {
    var response = await http.post(
      Uri.parse("${ApiConfig.base}/order/"),
      headers: {
        "Content-Type": "application/json; charset=utf-8",
        'Authorization': 'Bearer ${IntTest.token}',
      },
      body: json.encode({
        "object_id": objectTitleTask, //идентификатор объекта
        "creator_id": userProfile[0]['id'], //id создателя
        "fault_category_id": 1,//faultCategoryTitle, //id категории неисправности
        "task_text": commentTask.text,//коментарии к задаче
        "executor_id": allEmployeeTitleTask, //id исполнителя
        "created_at": newDateBirthProfile.millisecondsSinceEpoch/1000 //дата создания
        /// data.millisecondsSinceEpoch/1000, отправлять в секундах
        /// DateTime.fromMillisecondsSinceEpoch(1666349129*1000) полученая дата из милисекунд
      },
      ),
    );
    var listAddTask = jsonDecode(utf8.decode(response.bodyBytes));
    print('Добавление задачи ++++$listAddTask+++++++');
    dataListTask.add(listAddTask['data']);
    TaskBloc().add(TaskGetEvent());
    myStream.add(IntTest.indexScreens);
  }
  /// =======================

  /// Коментарий к задаче
  TextEditingController commentTask = TextEditingController();

  TimeOfDay myTimeOfDay = TimeOfDay.now();

  /// Дата задачи
  DateTime newDateBirthProfile = DateTime.now();


  void _showTimePiker() {
    showTimePicker(context: context, initialTime: TimeOfDay.now())
        .then((value) {
      setState(() {
        myTimeOfDay = value!;
      });
    });
  }

  /// Участок ===================
  // getPlotTaskList() async {
  //   final url = '${ApiConfig.base}/divisions/?page=1';
  //   final res = await http.get(Uri.parse(url), headers: {
  //     "Content-Type": "application/json; charset=utf-8",
  //     'Accept': 'application/json',
  //     'Authorization': 'Bearer ${IntTest.token}',
  //   });
  //   var response = jsonDecode(utf8.decode(res.bodyBytes));
  //   setState(() {
  //     plotList = response['data'];
  //   });
  //   // print(plotList);
  // }
  // String? myPlotTitle;
  // List plotList = [];
  /// ===========================

  /// Объект ====================
  getListObjectTask() async {
    final url = '${ApiConfig.base}/all-objects/';
    final res = await http.get(Uri.parse(url), headers: {
      "Content-Type": "application/json; charset=utf-8",
      'Accept': 'application/json',
      'Authorization': 'Bearer ${IntTest.token}',
    });
    var response = jsonDecode(utf8.decode(res.bodyBytes));
    setState(() {
      objectListTask = response['data'];
    });
  }
  String? objectTitleTask;
  List objectListTask = [];
  /// ===========================

  /// Механик =====================
  // getListEmployeeTask() async {
  //   final url = '${ApiConfig.base}/cp/all-employee/?page=1';
  //   final res = await http.get(Uri.parse(url), headers: {
  //     "Content-Type": "application/json; charset=utf-8",
  //     'Accept': 'application/json',
  //     'Authorization': 'Bearer ${IntTest.token}',
  //   });
  //   var response = jsonDecode(utf8.decode(res.bodyBytes));
  //   setState(() {
  //     employeeListTask = response['data'];
  //   });
  //   // print(mechanicList);
  // }
  // String? employeeTitleTask;
  // List employeeListTask = [];
  /// =============================

  /// Категория неисправности ===
  faultCategoryTask() async {
    final url = '${ApiConfig.base}/fault-category/all?page=1';
    final res = await http.get(Uri.parse(url), headers: {
      "Content-Type": "application/json; charset=utf-8",
      'Accept': 'application/json',
      'Authorization': 'Bearer ${IntTest.token}',
    });
    var response = jsonDecode(utf8.decode(res.bodyBytes));
    setState(() {
      faultCategoryListTask = response['data'];
    });
    // print(faultCategoryList);
  }
  String? faultCategoryTitleTask;
  List faultCategoryListTask = [];
  /// ===========================


  /// Все сотрудники ===========
  allEmployee() async {
    final url = '${ApiConfig.base}/cp/all-employee/?page=1';
    final res = await http.get(Uri.parse(url), headers: {
      "Content-Type": "application/json; charset=utf-8",
      'Accept': 'application/json',
      'Authorization': 'Bearer ${IntTest.token}',
    });
    var response = jsonDecode(utf8.decode(res.bodyBytes));
    setState(() {
      listAllEmployeeTask = response['data'];
    });
  }
  String? allEmployeeTitleTask;
  List listAllEmployeeTask = [];
  /// ==========================

  DateTime dateCreationTasks = DateTime.now();

  DateTime dateBirth = DateTime.now();

  @override
  void initState() {
    getListObjectTask();
    allEmployee();
    faultCategoryTask();

    // dataListTask = listTask;
    // TODO: implement initState
    super.initState();
  }

  final regCommentTask = GlobalKey<FormState>();

  bool colorTest = false;

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return SizedBox(
      width: 500.0,
      child: SingleChildScrollView(
        child: Column(
          children: [
            /// Текст и кнопка назад
            Row(
              children: [
                /// Текст
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Создание задачи',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: size.width > 570.0 ? 22.0 : 18.0),
                    ),
                    Text(
                      'Заполните все поля, чтобы добавить новую задачу в систему',
                      style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: size.width > 570.0 ? 14.0 : 8.0),
                    ),
                  ],
                ),
                const Spacer(),
                /// кнопка назад
                IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(
                      Icons.close,
                      color: ColorApp.myColorGreenAuth,
                    )),
              ],
            ),
            SizedBox(height: size.width > 570.0 ? 40.0 : 20.0),
            ///Дата задачи
            SizedBox(
              height: 80,
              child: Row(
                children: [
                  ///Дата задачи
                  Expanded(
                    child: Column(
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
                                  initialDate: dateCreationTasks,
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(3000));
                              if (dateTime != null) {
                                dateCreationTasks = dateTime;
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
                                        '${dateCreationTasks.day} - ${dateCreationTasks.month} - ${dateCreationTasks.year}',
                                        style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 16.0),
                                      ),
                                      const Icon(
                                          Icons.calendar_month_outlined,
                                          color: ColorApp.myColorGreenAuth)
                                    ]))),
                      ],
                    ),
                  ),
                  // const SizedBox(width: 10.0),
                  /// Дата выполнения
                  // Expanded(
                  //   child: Column(
                  //     crossAxisAlignment: CrossAxisAlignment.start,
                  //     children: [
                  //       const Text(
                  //         'Дата выполнения',
                  //         style: TextStyle(
                  //             fontSize: 15.0,
                  //             fontWeight: FontWeight.bold,
                  //             color: ColorApp.myColorGrayText),
                  //       ),
                  //       const SizedBox(height: 10.0),
                  //       InkWell(
                  //           onTap: () async {
                  //             final DateTime? dateTime = await showDatePicker(
                  //                 context: context,
                  //                 initialDate: dateCreationTasks,
                  //                 firstDate: DateTime(2000),
                  //                 lastDate: DateTime(3000));
                  //             if (dateTime != null) {
                  //               dateCreationTasks = dateTime;
                  //               setState(() {});
                  //             }
                  //           },
                  //           child: Container(
                  //               padding: const EdgeInsets.symmetric(
                  //                   horizontal: 10.0),
                  //               height: 50,
                  //               decoration: BoxDecoration(
                  //                 borderRadius: BorderRadius.circular(5.0),
                  //                 border: Border.all(
                  //                     width: 1.0, color: Colors.grey),
                  //               ),
                  //               child: Row(
                  //                   mainAxisAlignment:
                  //                   MainAxisAlignment.spaceBetween,
                  //                   children: [
                  //                     Text(
                  //                       '${dateCreationTasks.day} - ${dateCreationTasks.month} - ${dateCreationTasks.year}',
                  //                       style: const TextStyle(
                  //                           color: Colors.grey,
                  //                           fontSize: 16.0),
                  //                     ),
                  //                     const Icon(
                  //                         Icons.calendar_month_outlined,
                  //                         color: ColorApp.myColorGreenAuth)
                  //                   ]))),
                  //     ],
                  //   ),
                  // ),
                ],
              ),
            ),
            SizedBox(height: size.width > 570.0 ? 20.0 : 10.0),
            /// Обьект
            SizedBox(
              height: 50.0,
              child: DropdownButtonFormField(
                value: objectTitleTask,
                hint: const Text('Объект'),
                onChanged: (newValue1) async {
                  setState(() {
                    objectTitleTask = newValue1 as String?;
                    objectTitleTask!.indexOf(newValue1!);
                  });
                },
                items: objectListTask.map((organizationTitleList) {
                  return DropdownMenuItem(
                    value: organizationTitleList['id'].toString(),
                    child: Text('${organizationTitleList['name']}'),
                  );
                }).toList(),
                decoration: const InputDecoration(
                    border: OutlineInputBorder()),
              ),
            ),
            SizedBox(height: size.width > 570.0 ? 20.0 : 10.0),
            /// Все сотрудники для задач
            SizedBox(
              height: 50.0,
              child: DropdownButtonFormField(
                value: allEmployeeTitleTask,
                hint: const Text('Сотрудники'),
                onChanged: (newValue1) async {
                  setState(() {
                    allEmployeeTitleTask = newValue1 as String?;
                    allEmployeeTitleTask!.indexOf(newValue1!);
                  });
                },
                items: listAllEmployeeTask.map((jobTitleList) {
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
            SizedBox(height: size.width > 570.0 ? 20.0 : 10.0),
            ///Комментарий
            Form(
              key: regCommentTask,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: TextFormField(
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Напишите задачу';
                  } else {
                    return null;
                  }
                },
                cursorColor: ColorApp.myColorGray,
                controller: commentTask,
                decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: ColorApp.myColorGreenAuth),
                    ),
                    labelText: 'Комментарий',
                    labelStyle: TextStyle(color: ColorApp.myColorGray)),
              ),
            ),
            SizedBox(height: size.width > 570.0 ? 20.0 : 10.0),
            /// Кнопка Сохранить
            MainButtonApp(
              textButton:  allEmployeeTitleTask != null && objectTitleTask != null ?  'Сохранить' : 'Заполните все поля',
              press: allEmployeeTitleTask != null && objectTitleTask != null ? () async {
                regCommentTask.currentState!.validate();
                if(commentTask.text.isNotEmpty) {
                  await createNewTask();
                  await getListTask();
                  myStream.add(IntTest.indexScreens);
                  Navigator.pop(context);
                }
                setState(() {});
              } : (){print('gecnj');},
            ),
            SizedBox(height: size.width > 570.0 ? 20.0 : 10.0),
            /// Причина неисправности Фотография
            // Row(
            //   children: [
            //     /// Причина неисправности
            //     // Expanded(
            //     //   child: SizedBox(
            //     //     height: 50.0,
            //     //     child: DropdownButtonFormField(
            //     //       value: causeOfMalTitle,
            //     //       hint: const Text('Причина неисправности'),
            //     //       onChanged: (newValue1) async {
            //     //         setState(() {
            //     //           print(causeOfMalTitle);
            //     //           causeOfMalTitle = newValue1 as String?;
            //     //           causeOfMalTitle!.indexOf(newValue1!);
            //     //         });
            //     //       },
            //     //       items: causeOfMalList.map((causeOfMalTitleList) {
            //     //         return DropdownMenuItem(
            //     //           value: causeOfMalTitleList['id'].toString(),
            //     //           child: Text(causeOfMalTitleList['name']),
            //     //         );
            //     //       }).toList(),
            //     //       decoration: const InputDecoration(border: OutlineInputBorder()),
            //     //     ),
            //     //   ),
            //     // ),
            //     // const SizedBox(width: 10.0),
            //     ///Фотография
            //     // Expanded(
            //     //   child: GestureDetector(
            //     //     onTap: () async {
            //     //       final imageClassification =
            //     //       await ImagePickerWeb.getImageAsBytes();
            //     //     },
            //     //     child: DottedBorder(
            //     //       color: ColorApp.myColorGray,
            //     //       child:  SizedBox(
            //     //         height: 44.0,
            //     //         child: Center(
            //     //           child: Padding(
            //     //             padding: const EdgeInsets.symmetric(horizontal: 10.0),
            //     //             child: Row(
            //     //               children: [
            //     //                 Text('Фотография',style: TextStyle(color: Colors.grey.shade600)),
            //     //                 Spacer(),
            //     //                 Icon(Icons.backup_outlined,
            //     //                     color: ColorApp.myColorGray),
            //     //               ],
            //     //             ),
            //     //           ),
            //     //         ),
            //     //       ),
            //     //     ),
            //     //   ),
            //     // ),
            //   ],
            // ),
            // SizedBox(height: size.width > 570.0 ? 20.0 : 10.0),
          ],
        ),
      ),
    );
  }
}