import 'package:flutter/material.dart';
import 'package:els/helper/api_config.dart';
import 'package:gap/gap.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import '../../../helper/button/my_button.dart';
import '../../../helper/class_colors.dart';
import 'package:http/http.dart' as http;

import 'add_object.dart';

/// Создание договора

var myS = '';

class AddContract extends StatefulWidget {
   const AddContract({Key? key}) : super(key: key);

  @override
  State<AddContract> createState() => _AddContractState();
}

class _AddContractState extends State<AddContract> {



  /// Добавление нового договора ===
  addingContactPerson() async {
    var response = await http.post(
      Uri.parse("${ApiConfig.base}/contract/"),
      headers: {
        "Content-Type": "application/json; charset=utf-8",
        'Authorization': 'Bearer ${IntTest.token}',
      },
      body: json.encode({
        "company_id": getCompanyForContractTitle,
        "title": nameContract.text,
        "validity_period": durationInSeconds,
        "type_contract_id": getViewContractTitle,
        "cost_type_id": getPriceTypesContractTitle,
        }
      ),
    );
    var listAddContract = jsonDecode(utf8.decode(response.bodyBytes));
    print('Добавление договора ++++$listAddContract+++++++');
    // listSelectedContactPersonCompany.add(listAddContract['data']);
  }
  /// ==============================

  /// Договор =====================
  getViewContract() async {
    final url = '${ApiConfig.base}/contracts/?page=1';
    final res = await http.get(Uri.parse(url), headers: {
      "Content-Type": "application/json; charset=utf-8",
      'Accept': 'application/json',
      'Authorization': 'Bearer ${IntTest.token}',
    });
    var response = jsonDecode(utf8.decode(res.bodyBytes));
    getViewContractList = response['data'];
    setState((){});
    // print('получение Вида договора ${getViewContractList}');
  }
  String? getViewContractTitle;
  List getViewContractList = [];
  /// ==============================

  /// Компании =======================
  getCompanyForContract() async {
    final url = '${ApiConfig.base}/all-company/?page=1';
    final res = await http.get(Uri.parse(url), headers: {
      "Content-Type": "application/json; charset=utf-8",
      'Accept': 'application/json',
      'Authorization': 'Bearer ${IntTest.token}',
    });
    var response = jsonDecode(utf8.decode(res.bodyBytes));
    getCompanyForContractList = response['data'];
    print('получение компаний для договора ${getCompanyForContractList}');
    setState((){});
  }
  String? getCompanyForContractTitle;
  List getCompanyForContractList = [];
  /// ================================

  /// Типы цен =======================
  getPriceTypesContract() async {
    final url = '${ApiConfig.base}/cost-types/?page=1';
    final res = await http.get(Uri.parse(url), headers: {
      "Content-Type": "application/json; charset=utf-8",
      'Accept': 'application/json',
      'Authorization': 'Bearer ${IntTest.token}',
    });
    var response = jsonDecode(utf8.decode(res.bodyBytes));
    getPriceTypesContractList = response['data'];
    // print('получение типы цен ${getPriceTypesContractList}');
    setState((){});
  }
  String? getPriceTypesContractTitle;
  List getPriceTypesContractList = [];
  /// ================================

  DateRangePickerController myCalendarContract = DateRangePickerController();
  /// ==============================================================
  var myDataCalendar = DateFormat('dd/MM/yyyy').format(DateTime.now());
  /// ==============================================================

  /// ФИО
  TextEditingController nameContract = TextEditingController();



  final nameContractPro = GlobalKey<FormState>();

  late int durationInSeconds;


  @override
  void initState() {
    getViewContract();
    getCompanyForContract();
    getPriceTypesContract();
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 500.0,
      height: 550.0,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Добавление договора, иконка закрыть
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Добавление договора',
                      style:
                      TextStyle(fontSize: 25.0, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 5.0),
                    Text(
                      'Заполните все поля, чтобы добавить новый договор',
                      style: TextStyle(color: Colors.grey.shade400),
                    ),
                  ],
                ),
                IconButton(
                    onPressed: () {
                      print(IntTest.pressHover);
                      Navigator.pop(context);
                    },
                    icon: const Icon(
                      Icons.close,
                      color: ColorApp.myColorGreenAuth,
                    ))
              ],
            ),
            const Gap(30.0),
            /// Название
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Название',style: TextStyle(fontSize: 15.0,fontWeight: FontWeight.bold,color: ColorApp.myColorGrayText),),
                const SizedBox(height: 10.0),
                Form(
                  key: nameContractPro,
                  child: TextFormField(
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Заполните название';
                      } else {
                        null;
                      }
                    },
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
                ),
              ],
            ),
            const Gap(20.0),
            /// Компания
            SizedBox(
              height: 50.0,
              child: DropdownButtonFormField(
                value: getCompanyForContractTitle,
                hint: const Text('Компания'),
                onChanged: (newValue1) async {
                  setState(() {
                    getCompanyForContractTitle = newValue1 as String?;
                    getCompanyForContractTitle!.indexOf(newValue1!);
                  });
                },
                items: getCompanyForContractList.map((jobTitleList) {
                  return DropdownMenuItem(
                    value: jobTitleList['id'].toString(),
                    child: SizedBox(
                      width: 200.0,
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
                decoration: const InputDecoration(
                    border: OutlineInputBorder()),
              ),
            ),
            const Gap(20.0),
            /// Тип Договора
            SizedBox(
              height: 50.0,
              child: DropdownButtonFormField(
                value: getViewContractTitle,
                hint: const Text('Тип Договора'),
                onChanged: (newValue1) async {
                  setState(() {
                    getViewContractTitle = newValue1 as String?;
                    getViewContractTitle!.indexOf(newValue1!);
                  });
                },
                items: getViewContractList.map((jobTitleList) {
                  return DropdownMenuItem(
                    value: jobTitleList['id'].toString(),
                    child: SizedBox(
                      width: 200.0,
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
                decoration: const InputDecoration(
                    border: OutlineInputBorder()),
              ),
            ),
            const Gap(20.0),
            /// Тип оплаты
            SizedBox(
              height: 50.0,
              child: DropdownButtonFormField(
                value: getPriceTypesContractTitle,
                hint: const Text('Тип оплаты'),
                onChanged: (newValue1) async {
                  setState(() {
                    getPriceTypesContractTitle = newValue1 as String?;
                    getPriceTypesContractTitle!.indexOf(newValue1!);
                  });
                },
                items: getPriceTypesContractList.map((jobTitleList) {
                  return DropdownMenuItem(
                    value: jobTitleList['id'].toString(),
                    child: SizedBox(
                      width: 200.0,
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
                decoration: const InputDecoration(
                    border: OutlineInputBorder()),
              ),
            ),
            const Gap(20.0),
            /// Период действия договора
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Период действия договора',
                  style: TextStyle(
                      fontSize: 15.0,
                      fontWeight: FontWeight.bold,
                      color: ColorApp.myColorGrayText),
                ),
                const SizedBox(height: 10.0),
                InkWell(
                    onTap: () async {
                      showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              content: SizedBox(
                                width: 270,
                                height: 350,
                                child: Column(
                                  children: [
                                    SfDateRangePicker(
                                      monthCellStyle: DateRangePickerMonthCellStyle(
                                        todayCellDecoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(50),
                                            border: Border.all(color: ColorApp.myColorGreenAuth)),
                                        todayTextStyle: const TextStyle(color: ColorApp.myColorGreenAuth),
                                      ),
                                      headerStyle: const DateRangePickerHeaderStyle(
                                        textAlign: TextAlign.center,
                                      ),
                                      controller: myCalendarContract,
                                      monthViewSettings: const DateRangePickerMonthViewSettings(firstDayOfWeek: 1),
                                      selectionMode: DateRangePickerSelectionMode.range,
                                      rangeSelectionColor: ColorApp.myColorGreenLine,
                                      startRangeSelectionColor: ColorApp.myColorGreen,
                                      endRangeSelectionColor: ColorApp.myColorGreen,
                                    ),
                                    ///Кнопки Отмена и Выбрать
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                                      children: [
                                        /// Отмена
                                        Expanded(
                                          child: OutlinedButton(
                                              style: OutlinedButton.styleFrom(
                                                padding: const EdgeInsets.symmetric(
                                                    horizontal: 20.0,
                                                    vertical: 10.0),
                                                side: const BorderSide(
                                                    color: ColorApp.myColorGreenAuth,
                                                    width: 1.0),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                  BorderRadius.circular(20.0),
                                                ),
                                              ),
                                              onPressed: () {
                                                myCalendarContract.selectedRanges = null;
                                                Navigator.pop(context);
                                              },
                                              child: const Text('Отмена',
                                                  style: TextStyle(
                                                      fontSize: 10.0,
                                                      color:
                                                      ColorApp.myColorGreenAuth))),
                                        ),
                                        const SizedBox(width: 10.0),
                                        /// Выбрать
                                        Expanded(
                                          child: OutlinedButton(
                                              style: OutlinedButton.styleFrom(
                                                padding: const EdgeInsets.symmetric(
                                                    horizontal: 20.0,
                                                    vertical: 10.0),
                                                side: const BorderSide(
                                                    color: ColorApp.myColorGreenAuth,
                                                    width: 1.0),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                  BorderRadius.circular(20.0),
                                                ),
                                              ),
                                              onPressed: () {
                                              //  myS = getViewContractTitle!;
                                                myS = '${myCalendarContract.selectedRange!.startDate?.day}-${myCalendarContract.selectedRange!.startDate?.month}-${myCalendarContract.selectedRange!.startDate?.year} ${myCalendarContract.selectedRange!.endDate?.day}-${myCalendarContract.selectedRange!.endDate?.month}-${myCalendarContract.selectedRange!.endDate?.year}';
                                                 // myCalendarContract = myS as DateRangePickerController;
                                                // print(myS);


                                                  // Даты в формате "dd-MM-yyyy"
                                                  String date1 = "${myCalendarContract.selectedRange!.startDate?.day}-${myCalendarContract.selectedRange!.startDate?.month}-${myCalendarContract.selectedRange!.startDate?.year}";
                                                  String date2 = "${myCalendarContract.selectedRange!.endDate?.day}-${myCalendarContract.selectedRange!.endDate?.month}-${myCalendarContract.selectedRange!.endDate?.year}";

                                                  // Парсим даты
                                                  DateTime dateTime1 = DateFormat("d-M-yyyy").parse(date1);
                                                  DateTime dateTime2 = DateFormat("d-M-yyyy").parse(date2);

                                                  // Получаем Unix timestamp в секундах
                                                  int seconds1 = dateTime1.millisecondsSinceEpoch ~/ 1000;
                                                  int seconds2 = dateTime2.millisecondsSinceEpoch ~/ 1000;

                                                  // print("$date1 в секундах: $seconds1"); // 27-7-2025 → 1753574400
                                                  // print("$date2 в секундах: $seconds2"); // 31-7-2025 → 1754006400

                                                durationInSeconds  =  seconds1! - seconds2!;
                                                print('Длительность периода: $durationInSeconds секунд');

                                                 Navigator.pop(context);
                                              },
                                              child: const Text('Выбрать',
                                                  style: TextStyle(
                                                      fontSize: 10.0,
                                                      color: ColorApp.myColorGreenAuth))),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          });
                    },
                    child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        height: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5.0),
                          border: Border.all(width: 1.0,color: Colors.grey),
                        ),
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('${myDataCalendar}',style: const TextStyle(color: Colors.grey,fontSize: 16.0),),
                              const Icon(Icons.calendar_month_outlined,color: Colors.grey)]))),
              ],
            ),
            const Gap(30.0),
            /// Кнопка Сохранить
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                MainButtonApp(textButton: 'Сохранить', press: () async {
                  if(
                  nameContract.text.isNotEmpty
                  ){
                    await addingContactPerson();
                    await getViewContract();
                    await getTreatyObjectList();
                    Navigator.pop(context);
                    setState(() {});
                  }else{

                  }
                  nameContractPro.currentState!.validate();
                },),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
