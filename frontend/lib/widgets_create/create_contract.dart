/// createContract

import 'dart:convert';
import 'package:els/helper/api_config.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import '../../../helper/button/my_button.dart';
import '../../../helper/class_colors.dart';
import 'package:http/http.dart' as http;

import '../screns/employee/widgets/add_employee.dart';
import '../screns/home_page/home_page.dart';
import '../screns/object/widgets/add_object.dart';
import 'package:els/helper/api_client.dart';

/// Создания договора

class CreateContract extends StatefulWidget {
  CreateContract({
    Key? key,
  }) : super(key: key);

  @override
  State<CreateContract> createState() => _CreateContractState();
}

class _CreateContractState extends State<CreateContract> {
  /// Добавление договора ==========
  createContract() async {
    var response = await Api.post(
      Uri.parse("${ApiConfig.base}/contract/"),
      headers: {
        "Content-Type": "application/json; charset=utf-8",
      },
      body: json.encode(
        {

          "company_id": getCompanyTitle,
          "title": nameContract.text,
          "validity_period": dateBirthAccount.millisecondsSinceEpoch / 1000,
          "type_contract_id":  typeContractTitle ,
          "cost_type_id": ndsTitle,

        },
      ),
    );
    var listAddContract = jsonDecode(utf8.decode(response.bodyBytes));
    print('Сработало');
    print('Добавление договора ++++$listAddContract+++++++');
    // getTreatyList.add(listAddContract['data']);
    myStream.add(IntTest.indexScreens);
  }

  /// =============================

  /// Название
  TextEditingController nameContract = TextEditingController();

  /// Пароль
  TextEditingController contractPrice = TextEditingController();

  DateTime dateBirthAccount = DateTime.now();

  /// Компании =====================
  getCompanyObjectList() async {
    final url = '${ApiConfig.base}/all-company/?page=1';
    final res = await Api.get(Uri.parse(url), headers: {
      "Content-Type": "application/json; charset=utf-8",
      'Accept': 'application/json',
    });
    var response = jsonDecode(utf8.decode(res.bodyBytes));
    setState(() {
      getCompanyList = response['data'];
      myStream.add(IntTest.indexScreens);
    });
    // print('получение из Обьектов $getCompanyList');
  }
  String? getCompanyTitle;
  List getCompanyList = [];
  /// ==============================

  /// Список НДС ==================
  getContractNDSList() async {
    final url = '${ApiConfig.base}/cost-types/?page=1';
    final res = await Api.get(Uri.parse(url), headers: {
      "Content-Type": "application/json; charset=utf-8",
      'Accept': 'application/json',
    });
    var response = jsonDecode(utf8.decode(res.bodyBytes));
    ndsList = response['data'];
    print(' НДС : ${ndsList}');
  }
  String? ndsTitle;
  List ndsList = [];
  /// =============================

  /// Список тип договора =========
  getTypeContractList() async {
    final url = '${ApiConfig.base}/contracts/?page=1';
    final res = await Api.get(Uri.parse(url), headers: {
      "Content-Type": "application/json; charset=utf-8",
      'Accept': 'application/json',
    });
    var response = jsonDecode(utf8.decode(res.bodyBytes));
    typeContractList = response['data'];
    print(' Тип договора: ${typeContractList}');
  }
  String? typeContractTitle;
  List typeContractList = [];
  /// =============================

  @override
  void initState() {
    getCompanyObjectList();
    getContractNDSList();
    getTypeContractList();
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: myStream.stream,
      builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
        return SingleChildScrollView(
          child: SizedBox(
            width: 400.0,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// Текст Договор кнопка назад
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      /// Добавление договора
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Добавление договора',
                            style: TextStyle(
                                fontSize: 18.0, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 5.0),
                          Text(
                            'Заполните все поля, чтобы добавить новый договор',
                            style: TextStyle(
                                color: Colors.grey.shade400, fontSize: 14.0),
                          ),
                        ],
                      ),

                      /// кнопка назад
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

                  /// Название
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Название',
                        style: TextStyle(
                            fontSize: 15.0,
                            fontWeight: FontWeight.bold,
                            color: ColorApp.myColorGrayText),
                      ),
                      const SizedBox(height: 10.0),
                      TextFormField(
                        cursorColor: ColorApp.myColorGray,
                        controller: nameContract,
                        decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            focusedBorder: OutlineInputBorder(
                              borderSide:
                              BorderSide(color: ColorApp.myColorGreenAuth),
                            ),
                            // labelText: 'Документ',
                            labelStyle: TextStyle(color: ColorApp.myColorGray)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20.0),

                  /// Компании
                  SizedBox(
                    height: 50.0,
                    child: DropdownButtonFormField(
                      value: getCompanyTitle,
                      hint: const Text('Компания'),
                      onChanged: (newValue1) async {
                        setState(() {
                          getCompanyTitle = newValue1 as String?;
                          getCompanyTitle!.indexOf(newValue1!);
                        });
                      },
                      items: getCompanyList.map((jobTitleList) {
                        return DropdownMenuItem(
                          value: jobTitleList['id'].toString(),
                          child: SizedBox(
                            width: 130.0,
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
                      decoration: InputDecoration(
                          prefixIcon: IconButton(
                              onPressed: () async {
                                setState(() {
                                  showDialog(
                                      context: context,
                                      builder: (context) => const AlertDialog(
                                        content: AddEmployee(),
                                      )).then((value) => setState(() {}));
                                });
                              },
                              icon: const Icon(Icons.add_box_rounded,
                                  size: 20.0, color: ColorApp.myColorGreenAuth)),
                          border: const OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(height: 20.0),

                  /// Тип оплаты
                  SizedBox(
                    height: 50.0,
                    child: DropdownButtonFormField(
                      value: ndsTitle,
                      hint: const Text('Тип оплаты'),
                      onChanged: (newValue1) async {
                        setState(() {
                          ndsTitle = newValue1 as String?;
                          ndsTitle!.indexOf(newValue1!);
                          print(ndsTitle);
                        });
                      },
                      items: ndsList.map((jobTitleList) {
                        return DropdownMenuItem(
                          value: jobTitleList['id'].toString(),
                          child: Text(jobTitleList['name']),
                        );
                      }).toList(),
                      decoration: const InputDecoration(
                          border: OutlineInputBorder()),
                    ),

                  ),
                  const SizedBox(height: 20.0),

                  /// Тип договора
                  SizedBox(
                    height: 50.0,
                    child: DropdownButtonFormField(
                      value: typeContractTitle,
                      hint: const Text('Тип договора'),
                      onChanged: (newValue1) async {
                        setState(() {
                          typeContractTitle = newValue1 as String?;
                          typeContractTitle!.indexOf(newValue1!);
                          print(typeContractTitle);
                        });
                      },
                      items: typeContractList.map((jobTitleList) {
                        return DropdownMenuItem(
                          value: jobTitleList['id'].toString(),
                          child: Text(jobTitleList['name']),
                        );
                      }).toList(),
                      decoration: const InputDecoration(
                          border: OutlineInputBorder()),
                    ),

                  ),
                  const SizedBox(height: 20.0),

                  /// Дата оканчания
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Дата оканчания',
                        style: const TextStyle(
                            fontSize: 15.0,
                            fontWeight: FontWeight.bold,
                            color: ColorApp.myColorGrayText),
                      ),
                      const SizedBox(height: 10.0),
                      InkWell(
                        onTap: () async {
                          final DateTime? dateTime = await showDatePicker(
                              context: context,
                              initialDate: dateBirthAccount,
                              firstDate: DateTime(1900),
                              lastDate: DateTime(3000));
                          if (dateTime != null) {
                            setState(() {
                              dateBirthAccount = dateTime;
                              print(dateBirthAccount.millisecondsSinceEpoch / 1000);
                            });
                          }
                        },
                        child: Container(
                          height: 50.0,
                          decoration: BoxDecoration(
                            border: Border.all(width: 1.3, color: Colors.grey),
                            borderRadius: BorderRadius.circular(5.0),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10.0),
                            child: Row(
                              children: [
                                Text(
                                  '${dateBirthAccount.day} - ${dateBirthAccount.month} - ${dateBirthAccount.year}',
                                  style: const TextStyle(color: Colors.grey),
                                ),
                                const Spacer(),
                                const Icon(Icons.calendar_month_outlined, color: Colors.grey),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20.0),

                  /// Кнопка сохранить
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      MainButtonApp(
                        textButton: 'Сохранить',
                        press: () async {
                          getContractNDSList();
                          await createContract();
                          await getCompanyObjectList();
                          Navigator.pop(context);
                          myStream.add(IntTest.indexScreens);
                          setState(() {});
                        },
                      ),
                    ],
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

