// ignore_for_file: use_build_context_synchronously
import 'dart:convert';
import 'package:els/helper/api_config.dart';
import 'package:flutter/material.dart';
import '../../../helper/button/my_button.dart';
import '../../../helper/class_colors.dart';
import 'package:http/http.dart' as http;
import '../../../screns/home_page/home_page.dart';
import '../companies_screen_foreman.dart';
import 'package:els/helper/api_client.dart';

/// Создание компании Прорабом

/// Компании =====================
getCompanyObjectList() async {
  final url = '${ApiConfig.base}/all-company/?page=1';
  final res = await Api.get(Uri.parse(url), headers: {
    "Content-Type": "application/json; charset=utf-8",
    'Accept': 'application/json',
  });
  var response = jsonDecode(utf8.decode(res.bodyBytes));
  getCompanyList = response['data'];
  myStream.add(IntTest.indexScreens);
  // print('получение из Обьектов $getCompanyList');
}
String? getCompanyTitle;
List getCompanyList = [];
/// ==============================


/// Добавить компанию ==============================================
class AddCompanyForeman extends StatefulWidget {
  const AddCompanyForeman({
    Key? key,
  }) : super(key: key);

  @override
  State<AddCompanyForeman> createState() => _AddCompanyForemanState();
}
class _AddCompanyForemanState extends State<AddCompanyForeman> {

  /// Создание Компании ============
  createCompanyForeman() async {
    var response = await Api.post(
      Uri.parse("${ApiConfig.base}/company/"),
      headers: {
        "Content-Type": "application/json; charset=utf-8",
      },
      body: json.encode(
        {
          "name": companyName.text,
          "director_name": director.text,
          "cont_phone": phoneNumber.text,
          "cont_address": legalAddress.text,
          "email": email.text,
          "site": site.text,
          "location_id": 1
        },
      ),
    );
    var listAddCompany = jsonDecode(utf8.decode(response.bodyBytes));
    print(listAddCompany);
    // getCompanyForeman.add(listAddCompany['data']);
  }
  /// ==============================

  /// Наимнование компании
  TextEditingController companyName = TextEditingController();

  /// Директор
  TextEditingController director = TextEditingController();

  /// Номер телефона
  TextEditingController phoneNumber = TextEditingController();

  /// Юридический адрес
  TextEditingController legalAddress = TextEditingController();

  /// Электронный адрес
  TextEditingController email = TextEditingController();

  /// Сайт
  TextEditingController site = TextEditingController();


  final regNameComp = GlobalKey<FormState>();
  final nameDir = GlobalKey<FormState>();
  final keyPhoneNumberComp = GlobalKey<FormState>();
  final legAddress = GlobalKey<FormState>();
  final emailComp = GlobalKey<FormState>();
  final siteComp = GlobalKey<FormState>();

  bool fff = false;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 890.0,
      // height: 750.0,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Текст и кнопка закрыть
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Создание компании',
                      style:
                      TextStyle(fontSize: 25.0, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 5.0),
                    Text(
                      'Заполните все поля, чтобы добавить новую компанию в систему',
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
            const SizedBox(height: 30.0),
            /// Наимнование компании Директор
            Row(
              children: [
                /// Наимнование компании
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Наимнование компании',style: TextStyle(fontSize: 15.0,fontWeight: FontWeight.bold,color: ColorApp.myColorGrayText),),
                      const SizedBox(height: 10.0),
                      Form(
                        key: regNameComp,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        child: TextFormField(
                          validator: (value) {
                            if (value!.isEmpty) {
                              return 'Заполните название';
                            } else {
                               null;
                            }
                          },
                          cursorColor: ColorApp.myColorGray,
                          controller: companyName,
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
                ),
                const SizedBox(width: 20.0),
                /// Директор
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Директор',style: TextStyle(fontSize: 15.0,fontWeight: FontWeight.bold,color: ColorApp.myColorGrayText),),
                      const SizedBox(height: 10.0),
                      Form(
                        key: nameDir,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        child: TextFormField(
                          validator: (value) {
                            if (value!.isEmpty) {
                              return 'Заполните название';
                            } else {
                              return null;
                            }
                          },
                          cursorColor: ColorApp.myColorGray,
                          controller: director,
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
                ),
              ],
            ),
            const SizedBox(height: 30.0),
            /// Телефон Юридический адрес
            Row(
              children: [
                /// Телефон
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Телефон',style: TextStyle(fontSize: 15.0,fontWeight: FontWeight.bold,color: ColorApp.myColorGrayText),),
                      const SizedBox(height: 10.0),
                      Form(
                        key: keyPhoneNumberComp,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        child: TextFormField(
                          maxLength: 10,
                          cursorColor: ColorApp.myColorGray,
                          controller: phoneNumber,
                          decoration: const InputDecoration(
                              prefixIcon: Padding(
                                padding: EdgeInsets.only(left: 10.0, top: 11.0),
                                child: Text('+7'),
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
                                !RegExp(r'^[+]*[(]{0,1}[0-9]{1,4}[)]{0,1}[-\s\./0-9]+$')
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
                ),
                const SizedBox(width: 20.0),
                /// Юридический адрес
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Юридический адрес',style: TextStyle(fontSize: 15.0,fontWeight: FontWeight.bold,color: ColorApp.myColorGrayText),),
                      const SizedBox(height: 10.0),
                      Form(
                        key: legAddress,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        child: TextFormField(
                          validator: (value) {
                            if (value!.isEmpty) {
                              return 'Заполните название';
                            } else {
                              return null;
                            }
                          },
                          cursorColor: ColorApp.myColorGray,
                          controller: legalAddress,
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
                ),
              ],
            ),
            const SizedBox(height: 30.0),
            /// Электронный адрес Сайт
            Row(
              children: [
                /// Электронный адрес
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Электронный адрес',style: TextStyle(fontSize: 15.0,fontWeight: FontWeight.bold,color: ColorApp.myColorGrayText),),
                      const SizedBox(height: 10.0),
                      Form(
                        key: emailComp,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        child: TextFormField(
                          validator: (value) {
                            if (value!.isEmpty) {
                              return 'Заполните название';
                            } else {
                              return null;
                            }
                          },
                          cursorColor: ColorApp.myColorGray,
                          controller: email,
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
                ),
                const SizedBox(width: 20.0),
                /// Сайт
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Сайт',style: TextStyle(fontSize: 15.0,fontWeight: FontWeight.bold,color: ColorApp.myColorGrayText),),
                      const SizedBox(height: 10.0),
                      Form(
                        key: siteComp,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        child: TextFormField(
                          validator: (value) {
                            if (value!.isEmpty) {
                              return 'Заполните название';
                            } else {
                              return null;
                            }
                          },
                          cursorColor: ColorApp.myColorGray,
                          controller: site,
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
                ),
              ],
            ),
            const SizedBox(height: 30.0),
            /// Кнопка Сохранить
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                MainButtonApp(
                  textButton: 'Сохранить',
                  press: () async {
                    if(
                    companyName.text.isNotEmpty
                        && director.text.isNotEmpty
                        && phoneNumber.text.isNotEmpty
                        && legalAddress.text.isNotEmpty
                        && email.text.isNotEmpty
                        && site.text.isNotEmpty) {
                      await createCompanyForeman();
                      await getCompanyObjectList();
                      myStream.add(IntTest.indexScreens);
                      setState(() {});
                      Navigator.pop(context);
                      /* here is your action code if it's empty*/
                    }
                    regNameComp.currentState!.validate();
                    nameDir.currentState!.validate();
                    keyPhoneNumberComp.currentState!.validate();
                    legAddress.currentState!.validate();
                    emailComp.currentState!.validate();
                    siteComp.currentState!.validate();


                  })
              ],
            ),
          ],
        ),
      ),
    );
  }
}
/// ================================================================