import 'dart:convert';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import '../../../helper/button/my_button.dart';
import '../../../helper/class_colors.dart';
import 'package:http/http.dart' as http;

import '../screns/home_page/home_page.dart';
import '../screns/object/widgets/add_object.dart';


/// Организация ========================
getOrganizationObjectList() async {
  final url = 'http://${IntTest.myIp}/api/v1/all-organization/?page=1';
  final res = await http.get(Uri.parse(url), headers: {
    "Content-Type": "application/json; charset=utf-8",
    'Accept': 'application/json',
    'Authorization': 'Bearer ${IntTest.token}',
  });
  var response = jsonDecode(utf8.decode(res.bodyBytes));
  organizationList = response['data'];
  // print(organizationList);
}
String? organizationTitle;
List organizationList = [];
/// ====================================

/// Добавить организацию ================================
class AddOrganization extends StatefulWidget {
  AddOrganization({
    Key? key,
  }) : super(key: key);

  @override
  State<AddOrganization> createState() => _AddOrganizationState();
}
class _AddOrganizationState extends State<AddOrganization> {

  /// Создание организации =======
  createOrganization() async {
    var response = await http.post(
      Uri.parse("http://${IntTest.myIp}/api/v1/organization/"),
      headers: {
        "Content-Type": "application/json; charset=utf-8",
        'Authorization': 'Bearer ${IntTest.token}',
      },
      body: json.encode(
        {
        "title": organizationName.text,
        "director_id": 1,
        "phone_office": organizationPhoneNumber.text,
        "phone_dispatcher": phoneNumberDispatcher.text,
        "phone_accountant": phoneNumberAccountant.text,
        "email": organizationEmail.text,
        "site": organizationSite.text,
        "address": organizationAddress.text,
        },
      ),
    );
    var listAddOrganization = jsonDecode(utf8.decode(response.bodyBytes));
    organizationList.add(listAddOrganization['data']);
    getOrganizationObjectList();

    myStream.add(IntTest.indexScreens);
  }
  /// ============================



  /// Наимнование организации
  TextEditingController organizationName = TextEditingController();

  /// Директор
  TextEditingController director = TextEditingController();

  /// адрес организации
  TextEditingController organizationAddress = TextEditingController();

  /// Номер телефона организации
  TextEditingController organizationPhoneNumber = TextEditingController();

  /// Номер телефона бухгалтера
  TextEditingController phoneNumberAccountant = TextEditingController();

  /// Номер телефона диспетчера
  TextEditingController phoneNumberDispatcher = TextEditingController();


  /// Электронный адрес организации
  TextEditingController organizationEmail = TextEditingController();

  /// Сайт организации
  TextEditingController organizationSite = TextEditingController();


  final nameOrg = GlobalKey<FormState>();
  final nameDir = GlobalKey<FormState>();
  final addressOrg = GlobalKey<FormState>();
  final keyPhoneNumberOrg = GlobalKey<FormState>();
  final keyPhoneNumberBuh = GlobalKey<FormState>();
  final keyPhoneNumberDis = GlobalKey<FormState>();
  final nameSite = GlobalKey<FormState>();
  final nameEmail = GlobalKey<FormState>();


  @override
  Widget build(BuildContext context) {
    print(organizationList);
    return SizedBox(
      width: 890.0,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            /// Текст и кнопка закрыть
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Создание организации',
                      style:
                      TextStyle(fontSize: 25.0, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 5.0),
                    Text(
                      'Заполните все поля, чтобы добавить новую организации в систему',
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
            /// Наимнование организации и Директор
            Row(
              children: [
                /// Наимнование организации
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Наимнование организации',style: TextStyle(fontSize: 15.0,fontWeight: FontWeight.bold,color: ColorApp.myColorGrayText),),
                      const SizedBox(height: 10.0),
                      Form(
                        key: nameOrg,
                        child: TextFormField(
                          validator: (value) {
                            if (value!.isEmpty) {
                              return 'Поле не заполнено';
                            } else {
                              return null;
                            }
                          },
                          cursorColor: ColorApp.myColorGray,
                          controller: organizationName,
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
                        child: TextFormField(
                          validator: (value) {
                            if (value!.isEmpty) {
                              return 'Поле не заполнено';
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
            const SizedBox(height: 20.0),
            /// Номер телефона и Адрес организации
            Row(
              children: [
                /// Адрес организации
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Адрес организации',style: TextStyle(fontSize: 15.0,fontWeight: FontWeight.bold,color: ColorApp.myColorGrayText),),
                      const SizedBox(height: 10.0),
                      Form(
                        key: addressOrg,
                        child: TextFormField(
                          validator: (value) {
                            if (value!.isEmpty) {
                              return 'Поле не заполнено';
                            } else {
                              return null;
                            }
                          },
                          cursorColor: ColorApp.myColorGray,
                          controller: organizationAddress,
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
            const SizedBox(height: 20.0),
            /// Номер телефона бухгалтер и Номер телефона диспетчера
            Row(
              children: [
                /// Номер телефона организации
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Номер телефона организации',style: TextStyle(fontSize: 15.0,fontWeight: FontWeight.bold,color: ColorApp.myColorGrayText),),
                      const SizedBox(height: 10.0),
                      Form(
                        key: keyPhoneNumberOrg,
                        child: TextFormField(
                          maxLength: 10,
                          cursorColor: ColorApp.myColorGray,
                          controller: organizationPhoneNumber,
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
                /// Номер телефона бухгалтер
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Номер телефона бухгалтер',style: TextStyle(fontSize: 15.0,fontWeight: FontWeight.bold,color: ColorApp.myColorGrayText),),
                      const SizedBox(height: 10.0),
                      Form(
                        key: keyPhoneNumberBuh,
                        child: TextFormField(
                          maxLength: 10,
                          cursorColor: ColorApp.myColorGray,
                          controller: phoneNumberAccountant,
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
                /// Номер телефона диспетчера
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Номер телефона диспетчера',style: TextStyle(fontSize: 15.0,fontWeight: FontWeight.bold,color: ColorApp.myColorGrayText),),
                      const SizedBox(height: 10.0),
                      Form(
                        key: keyPhoneNumberDis,
                        child: TextFormField(
                          maxLength: 10,
                          cursorColor: ColorApp.myColorGray,
                          controller: phoneNumberDispatcher,
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
              ],
            ),
            const SizedBox(height: 20.0),
            /// Электронный адрес организации и Сайт
            Row(
              children: [
                /// Электронный адрес организации
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Электронный адрес',style: TextStyle(fontSize: 15.0,fontWeight: FontWeight.bold,color: ColorApp.myColorGrayText),),
                      const SizedBox(height: 10.0),
                      Form(
                        key: nameEmail,
                        child: TextFormField(
                          validator: (value) {
                            if (value!.isEmpty) {
                              return 'Поле не заполнено';
                            } else {
                              return null;
                            }
                          },
                          cursorColor: ColorApp.myColorGray,
                          controller: organizationEmail,
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
                /// Сайт организации
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Сайт',style: TextStyle(fontSize: 15.0,fontWeight: FontWeight.bold,color: ColorApp.myColorGrayText),),
                      const SizedBox(height: 10.0),
                      Form(
                        key: nameSite,
                        child: TextFormField(
                          validator: (value) {
                            if (value!.isEmpty) {
                              return 'Поле не заполнено';
                            } else {
                              return null;
                            }
                          },
                          cursorColor: ColorApp.myColorGray,
                          controller: organizationSite,
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
            /// Кнопка сохранить
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                MainButtonApp(textButton: 'Сохранить', press: () async {
                  nameOrg.currentState!.validate();
                  nameDir.currentState!.validate();
                  addressOrg.currentState!.validate();
                  nameEmail.currentState!.validate();
                  nameSite.currentState!.validate();
                  if(

                       organizationName.text.isNotEmpty
                      || director.text.isNotEmpty
                      || organizationAddress.text.isNotEmpty
                      || organizationPhoneNumber.text.isNotEmpty
                      || phoneNumberAccountant.text.isNotEmpty
                      || phoneNumberDispatcher.text.isNotEmpty
                      || organizationEmail.text.isNotEmpty
                      || organizationSite.text.isNotEmpty
                  ){
                    await createOrganization();
                    await getOrganizationObjectList();
                    myStream.add(IntTest.indexScreens);
                    setState(() {});
                    Navigator.pop(context);
                    print('jnhf,jnfk');
                  }


                },),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
/// ==================================================