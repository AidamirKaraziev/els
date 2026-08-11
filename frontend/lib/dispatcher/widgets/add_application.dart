import 'dart:convert';
import 'package:els/helper/api_config.dart';
import 'package:flutter/material.dart';
import '../../../helper/button/my_button.dart';
import 'package:http/http.dart' as http;
import '../../../helper/class_colors.dart';
import '../../screns/home_page/home_page.dart';
import '../../screns/task/view/task_screen.dart';
import '../../screns/user/user_contact.dart';
import '../task_screen_dispatcher/application_screen.dart';

/// Окно добавление Заявки





class AddApplication extends StatefulWidget {
  const AddApplication({Key? key}) : super(key: key);

  @override
  State<AddApplication> createState() => _AddApplicationState();
}

class _AddApplicationState extends State<AddApplication> {

  /// Создание Заявки ==============
  createNewApplication() async {
    var response = await http.post(
      Uri.parse("${ApiConfig.base}/order/"),
      headers: {
        "Content-Type": "application/json; charset=utf-8",
        'Authorization': 'Bearer ${IntTest.token}',
      },
      body: json.encode({
        "object_id": objectTitleApplication, //идентификатор объекта
        "creator_id": userProfile[0]['id'], //id создателя
        "fault_category_id": faultCategoryTitleApplication,//faultCategoryTitle, //id категории неисправности
        "task_text": commentApplication.text,//коментарии к задаче
        "executor_id": mechanicTitleApplication, //id исполнителя
        "created_at": newDateBirthProfile.millisecondsSinceEpoch/1000 //дата создания
      },
      ),
    );
    var listAddTask = jsonDecode(utf8.decode(response.bodyBytes));
    print('Добавление Заявки  ++++$listAddTask+++++++');
    getApplication.add(listAddTask['data']);
    getListApplication();
    myStream.add(IntTest.indexScreens);
  }
  /// ==============================

  /// Объект =============================
  getListObjectApplication() async {
    final url = '${ApiConfig.base}/all-objects/';
    final res = await http.get(Uri.parse(url), headers: {
      "Content-Type": "application/json; charset=utf-8",
      'Accept': 'application/json',
      'Authorization': 'Bearer ${IntTest.token}',
    });
    var response = jsonDecode(utf8.decode(res.bodyBytes));
    objectListApplication = response['data'];
    setState(() {});
  }
  String? objectTitleApplication;
  List objectListApplication = [];
  /// ====================================

  /// Механик ============================
  getListMechanicApplication() async {
    final url = '${ApiConfig.base}/universal-user/sort-by-role/3/';
    final res = await http.get(Uri.parse(url), headers: {
      "Content-Type": "application/json; charset=utf-8",
      'Accept': 'application/json',
      'Authorization': 'Bearer ${IntTest.token}',
    });
    var response = jsonDecode(utf8.decode(res.bodyBytes));
    mechanicListApplication = response['data'];
    setState(() {});
  }
  String? mechanicTitleApplication;
  List mechanicListApplication = [];
  /// ====================================

  /// Категория неисправности ============
  faultCategoryApplication() async {
    final url = '${ApiConfig.base}/fault-category/all?page=1';
    final res = await http.get(Uri.parse(url), headers: {
      "Content-Type": "application/json; charset=utf-8",
      'Accept': 'application/json',
      'Authorization': 'Bearer ${IntTest.token}',
    });
    var response = jsonDecode(utf8.decode(res.bodyBytes));
    faultCategoryListApplication = response['data'];
    setState(() {});
  }
  String? faultCategoryTitleApplication;
  List faultCategoryListApplication = [];
  /// ====================================

  List searchApplicationTest = [];


  /// Функция поиска по имени =================================
  // void _runObjectFilterApplication(String enteredKeyword) {
  //   List result = [];
  //   if (enteredKeyword.isEmpty) {
  //     result = organizationList;
  //   } else {
  //     result = organizationList
  //         .where((user) =>
  //         user['name'].toLowerCase().contains(enteredKeyword.toLowerCase()))
  //         .toList();
  //   }
  //   setState(() {
  //     searchApplicationTest = result;
  //   });
  //   print(searchApplicationTest);
  // }
  /// =========================================================

  /// Коментарий к задаче
  TextEditingController commentApplication = TextEditingController();


  /// Дата задачи
  DateTime newDateBirthProfile = DateTime.now();




  /// Причины неисправности =============
  // causeOfMalfunction() async {
  //   final url = '${ApiConfig.base}/reason-fault/all?page=1';
  //   final res = await http.get(Uri.parse(url), headers: {
  //     "Content-Type": "application/json; charset=utf-8",
  //     'Accept': 'application/json',
  //     'Authorization': 'Bearer ${IntTest.token}',
  //   });
  //   var response = jsonDecode(utf8.decode(res.bodyBytes));
  //   setState(() {
  //     causeOfMalList = response['data'];
  //   });
  //   print(causeOfMalList);
  // }
  // String? causeOfMalTitle;
  // List causeOfMalList = [];
  /// ====================================

  DateTime dateCreationTasks = DateTime.now();

  DateTime dateBirth = DateTime.now();

  @override
  void initState() {
    getListObjectApplication();
    getListMechanicApplication();
    faultCategoryApplication();
    dataListTask = getTask; /// проверить
    // TODO: implement initState
    super.initState();
  }

  bool colorTest = false;

  // final regCommentApplication = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return SizedBox(
      width: 800.0,
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
                      'Создание заявки',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: size.width > 570.0 ? 22.0 : 18.0),
                    ),
                    Text(
                      'Заполните все поля, чтобы добавить новую заявку в систему',
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
            const SizedBox(height: 20.0),
            ///Дата задачи и Время заявки
            // Row(
            //   children: [
            //     ///Дата заявки
            //     SizedBox(
            //       height: 80,
            //       width: 200.0,
            //       child: Column(
            //         crossAxisAlignment: CrossAxisAlignment.start,
            //         children: [
            //           const Text(
            //             'Дата заявки',
            //             style: TextStyle(
            //                 fontSize: 15.0,
            //                 fontWeight: FontWeight.bold,
            //                 color: ColorApp.myColorGrayText),
            //           ),
            //           const SizedBox(height: 10.0),
            //           InkWell(
            //               onTap: () async {
            //                 final DateTime? dateTime = await showDatePicker(
            //                     context: context,
            //                     initialDate: dateCreationTasks,
            //                     firstDate: DateTime(2000),
            //                     lastDate: DateTime(3000));
            //                 if (dateTime != null) {
            //                   dateCreationTasks = dateTime;
            //                   setState(() {});
            //                 }
            //               },
            //               child: Container(
            //                   padding: const EdgeInsets.symmetric(
            //                       horizontal: 10.0),
            //                   height: 50,
            //                   decoration: BoxDecoration(
            //                     borderRadius: BorderRadius.circular(5.0),
            //                     border: Border.all(
            //                         width: 1.0, color: Colors.grey),
            //                   ),
            //                   child: Row(
            //                       mainAxisAlignment:
            //                       MainAxisAlignment.spaceBetween,
            //                       children: [
            //                         Text(
            //                           '${dateCreationTasks.day} - ${dateCreationTasks.month} - ${dateCreationTasks.year}',
            //                           style: const TextStyle(
            //                               color: Colors.grey,
            //                               fontSize: 16.0),
            //                         ),
            //                         const Icon(
            //                             Icons.calendar_month_outlined,
            //                             color: ColorApp.myColorGreenAuth)
            //                       ]))),
            //         ],
            //       ),
            //     ),
            //     const SizedBox(width: 10.0),
            //     /// Сотрудник который создал заявку
            //     Column(
            //       crossAxisAlignment: CrossAxisAlignment.start,
            //       children: [
            //         const Text(
            //           'Дата заявки',
            //           style: TextStyle(
            //               fontSize: 15.0,
            //               fontWeight: FontWeight.bold,
            //               color: ColorApp.myColorGrayText),
            //         ),
            //         const SizedBox(height: 10.0),
            //         SizedBox(
            //           height: 50.0,
            //           child: DropdownButtonFormField(
            //             value: allEmployeeTitle,
            //             hint: const Text('Сотрудники'),
            //             onChanged: (newValue1) async {
            //               setState(() {
            //                 allEmployeeTitle = newValue1 as String?;
            //                 allEmployeeTitle!.indexOf(newValue1!);
            //               });
            //             },
            //             items: listAllEmployee.map((jobTitleList) {
            //               return DropdownMenuItem(
            //                 value: jobTitleList['id'].toString(),
            //                 child: SizedBox(
            //                   width: 200,
            //                   child: Row(
            //                     children: [
            //                       Expanded(
            //                         child: Text(jobTitleList['name'],
            //                             overflow: TextOverflow.ellipsis),
            //                       ),
            //                     ],
            //                   ),
            //                 ),
            //               );
            //             }).toList(),
            //             decoration: const InputDecoration(border: OutlineInputBorder()),
            //           ),
            //         ),
            //       ],
            //     ),
            //   ],
            // ),
            const SizedBox(height: 10.0),
            /// Обьект
            // Row(
            //   children: [
            //     SizedBox(
            //       height: 40.0,
            //       width: MediaQuery.of(context).size.width * 0.55,
            //       child: Form(
            //         child: TextField(
            //           onChanged: (value) => _runObjectFilterApplication(value),
            //           cursorColor: ColorApp.myColorGray,
            //           decoration: InputDecoration(
            //               contentPadding:
            //               const EdgeInsets.all(8.0),
            //               suffixIcon: IconButton(
            //                   onPressed: () {
            //                     setState(() {
            //                       searchApplicationTest = organizationList;
            //                     });
            //
            //                     setState(() {});
            //                   },
            //                   icon: const Icon(Icons.close)),
            //               border: const OutlineInputBorder(),
            //               focusedBorder:
            //               const OutlineInputBorder(
            //                   borderSide: BorderSide(color: ColorApp.myColorGreenAuth)),
            //               labelText: 'Поиск по названию',
            //               labelStyle: const TextStyle(
            //                   color: ColorApp.myColorGray)),
            //         ),
            //       ),
            //     ),
            //   ],
            // ),

            ///
            SizedBox(
              height: 60.0,
              child: DropdownButtonFormField(
                value: objectTitleApplication,
                hint: const Text('Объект'),
                onChanged: (newValue1) async {
                  setState(() {
                    objectTitleApplication = newValue1 as String?;
                    objectTitleApplication!.indexOf(newValue1!);
                  });
                },
                items: objectListApplication.map((organizationTitleList) {
                  return DropdownMenuItem(
                    value: organizationTitleList['id'].toString(),
                    child: Text('${organizationTitleList['name']}'),
                  );
                }).toList(),
                decoration: const InputDecoration(
                    border: OutlineInputBorder()),
              ),
            ),
            // Container(
            //   height: 200,
            //     child: SearchAndSelectPage()),
            const SizedBox(height: 10.0),
            ///  Механик
            SizedBox(
              height: 60.0,
              child: DropdownButtonFormField(
                value: mechanicTitleApplication,
                hint: const Text('Механик'),
                onChanged: (newValue1) async {
                  setState(() {
                    mechanicTitleApplication = newValue1 as String?;
                    mechanicTitleApplication!.indexOf(newValue1!);
                  });
                },
                items: mechanicListApplication.map((jobTitleList) {
                  return DropdownMenuItem(
                    value: jobTitleList['id'].toString(),
                    child: Text(jobTitleList['name'],
                        overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
                decoration: const InputDecoration(
                    border: OutlineInputBorder()),
              ),
            ),
            const SizedBox(height: 10.0),
            /// Категория неисправности
            SizedBox(
              height: 60.0,
              child: DropdownButtonFormField(
                value: faultCategoryTitleApplication,
                hint: const Text('Причина неисправности'),
                onChanged: (newValue1) async {
                  setState(() {
                    faultCategoryTitleApplication = newValue1 as String?;
                    faultCategoryTitleApplication!.indexOf(newValue1!);
                  });
                },
                items: faultCategoryListApplication.map((causeOfMalTitleList) {
                  return DropdownMenuItem(
                    value: causeOfMalTitleList['id'].toString(),
                    child: Text(causeOfMalTitleList['name']),
                  );
                }).toList(),
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
            ),
            const SizedBox(height: 10.0),
            ///Комментарий
            Form(
              // key: regCommentApplication,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: TextFormField(
                minLines: 1,
                maxLines: 5,
                // validator: (value) {
                //   if (value!.isEmpty) {
                //     return 'Напишите комментарий';
                //   } else {
                //     return null;
                //   }
                // },
                cursorColor: ColorApp.myColorGray,
                controller: commentApplication,
                decoration: const InputDecoration(

                    border: OutlineInputBorder(),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: ColorApp.myColorGreenAuth),
                    ),
                    labelText: 'Комментарий',
                    labelStyle: TextStyle(color: ColorApp.myColorGray)),
              ),
            ),
            const SizedBox(height: 30.0),
            /// Кнопка Добавить
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: objectTitleApplication != null && mechanicTitleApplication != null && faultCategoryTitleApplication != null  ? ColorApp.myColorGreenAuth : Colors.grey ,
                      padding: const EdgeInsets.symmetric(vertical: 20.0)),
                  onPressed: objectTitleApplication != null && mechanicTitleApplication != null && faultCategoryTitleApplication != null  ?  () async {
                    // regCommentApplication.currentState!.validate();
                    await createNewApplication();
                    myStream.add(IntTest.indexScreens);
                    Navigator.pop(context);
                    setState(() {});
                  } : (){print('gecnj');},
                  child: Text(
                    objectTitleApplication != null && mechanicTitleApplication != null && faultCategoryTitleApplication != null  ?  'Сохранить' : 'Заполните все поля',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class SearchPage extends StatefulWidget {
  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  Map _results = {};
  bool _loading = false;

  // Функция поиска
  Future<void> _search(String query) async {
    if (query.isEmpty) {
      setState(() {
        _results = {};
      });
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.base}/all-objects/'),
          headers: {
            "Content-Type": "application/json; charset=utf-8",
            'Accept': 'application/json',
            'Authorization': 'Bearer ${IntTest.token}',
          });

      if (response.statusCode == 200) {
        setState(() {
          _results = jsonDecode(utf8.decode(response.bodyBytes));
        });
      }
    } catch (e) {
      print('Ошибка: $e');
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Поле поиска
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Введите имя...',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                _search(value);
              },
            ),
            const SizedBox(height: 10),

            // Результаты
            if (_loading)
              const CircularProgressIndicator()
            else
              Expanded(
                child: ListView.builder(
                  itemCount: _results.length,
                  itemBuilder: (context, index) {
                    final user = _results['data'][index];
                    return ListTile(
                      title: Text(user['name']),
                      onTap: (){
                        _searchController.text = user['name'];
                        print(user['name']);
                        setState(() {});
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class SearchAndSelectPage extends StatefulWidget {
  @override
  _SearchAndSelectPageState createState() => _SearchAndSelectPageState();
}

class _SearchAndSelectPageState extends State<SearchAndSelectPage> {
  final TextEditingController _searchController = TextEditingController();
  Map _results = {};
  bool _loading = false;
  dynamic _selectedItem;
  bool _showDropdown = false;

  // Поиск через бэкенд
  Future<void> _search(String query) async {
    if (query.isEmpty) {
      setState(() {
        _results = {};
        _showDropdown = false;
      });
      return;
    }

    setState(() {
      _loading = true;
      _showDropdown = true;
    });

    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.base}/all-objects/'),
      );

      if (response.statusCode == 200) {
        List<dynamic> allUsers = json.decode(response.body);
        setState(() {
          _results['data'] = allUsers
              .where((user) =>
          user['name'].toLowerCase().contains(query.toLowerCase()) ||
              user['email'].toLowerCase().contains(query.toLowerCase()))
              .toList();
        });
      }
    } catch (e) {
      print('Ошибка: $e');
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  ///Выбор элемента
  void _selectItem(dynamic item) {
    setState(() {
      _selectedItem = item;
      _searchController.text = item['name'];
      _showDropdown = false;
      _results = {};
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Поле поиска с выпадающим списком
          Stack(
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Начните вводить имя...',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _selectedItem != null
                      ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      setState(() {
                        _selectedItem = null;
                        _searchController.clear();
                        _results = {};
                      });
                    },
                  )
                      : null,
                ),
                onChanged: _search,
                onTap: () {
                  if (_searchController.text.isNotEmpty) {
                    setState(() {
                      _showDropdown = true;
                    });
                  }
                },
              ),

              // Выпадающий список результатов
              if (_showDropdown && _results.isNotEmpty)
                Positioned(
                  top: 60,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 5,
                        ),
                      ],
                    ),
                    child: _loading
                        ? const Center(child: CircularProgressIndicator())
                        : ListView.builder(
                      itemCount: _results.length,
                      itemBuilder: (context, index) {
                        final item = _results['data'][index];
                        return ListTile(
                          title: Text(item['name']),
                          onTap: () => _selectItem(item),
                        );
                      },
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 20),

          // Информация о выбранном элементе
          if (_selectedItem != null)
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Выбран:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text('Имя: ${_selectedItem['name']}'),
                    // Text('Email: ${_selectedItem['email']}'),
                    // Text('Телефон: ${_selectedItem['phone']}'),
                    // Text('Город: ${_selectedItem['address']['city']}'),
                  ],
                ),
              ),
            ),

          // Подсказка
          if (_selectedItem == null && _searchController.text.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.search, size: 50, color: Colors.grey),
                    SizedBox(height: 10),
                    Text('Начните вводить имя для поиска'),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}