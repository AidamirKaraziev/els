import 'dart:convert';
import 'package:els/helper/api_config.dart';
import 'package:els/foreman/companies_foreman/companies_screen_foreman.dart';
import 'package:els/foreman/companies_foreman/company_page_foreman.dart';
import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../../helper/button/my_button.dart';
import '../../../helper/class_colors.dart';
import 'package:http/http.dart' as http;

import '../../../screns/companies/widgets/add_companies.dart';
import '../../../screns/home_page/home_page.dart';
import '../../../screns/object/widgets/add_contact_person_object.dart';

/// Контактные лица ///

/// Список выбранного контактного лица
Map selectedContactFacesForeman = {};
/// ==================================
Map listEditingContactPersonForeman = {};


/// получить данные выбранного контактного лица ==================
getSelectContactFacesCompanyForeman(int numberCompany) async {
  await Future(() async {
    final res = await http.get(
        Uri.parse("${ApiConfig.base}/contact-person/$numberCompany"),
        headers: {
          "Content-Type": "application/json; charset=utf-8",
          'Authorization': 'Bearer ${IntTest.token}',
        });
    selectedContactFacesForeman = jsonDecode(utf8.decode(res.bodyBytes));
    print('данные выбранного контактного лица : ${selectedContactFacesForeman['data']}');
    myStream.add(IntTest.indexScreens);
  });
}
/// ==============================================================

/// Класс для отображения списка контактных лиц===========
class ContactFacesForeman extends StatefulWidget {
  const ContactFacesForeman({Key? key}) : super(key: key);

  @override
  State<ContactFacesForeman> createState() => _ContactFacesForemanState();
}
class _ContactFacesForemanState extends State<ContactFacesForeman> {

  @override
  void initState() {
    getCompanyTitle = null;
    getContactPersonCompanyForeman();
    getContactPersonSelectedCompanyList();
    setState(() {});
    myStream.add(IntTest.indexScreens);
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: myStream.stream,
      builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Текст Контактные лица, иконка добавить
            Row(
              children: const [
                /// Контактные лица
                Text(
                  'Контактные лица',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                SizedBox(width: 20.0),

                /// иконка добавить
                // IconButton(
                //     onPressed: listSelectedCompanyForeman['data']['is_actual'] == false
                //         ? null
                //         : () {
                //             setState(() {
                //               showDialog(
                //                   context: context,
                //                   builder: (context) => AlertDialog(
                //                         content: AddContactPerson(),
                //                       ));
                //             });
                //           },
                //     icon: const Icon(
                //       Icons.add_box_rounded,
                //       color: ColorApp.myColorGreenAuth,
                //     ))
              ],
            ),
            const SizedBox(height: 20.0),
            Container(
              width: double.infinity,
              height: 300,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5.0),
                color: listSelectedCompanyForeman['data']['is_actual'] == true
                    ? ColorApp.myColorWhite
                    : Colors.grey[400],
                boxShadow: const [
                  BoxShadow(
                    color: Colors.grey,
                    blurRadius: 5,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (listSelectedContactPersonCompanyForeman.isNotEmpty)
                      /// Текст Имя,Телефон
                      Row(children: const [
                        SizedBox(width: 10.0),

                        /// Текст Имя
                        Expanded(
                            child: Text('Имя',
                                style: TextStyle(
                                    fontSize: 12.0,
                                    fontWeight: FontWeight.w500,
                                    color: ColorApp.myColorGray))),

                        /// Текст Телефон
                        Expanded(
                            child: Text('Телефон',
                                style: TextStyle(
                                    fontSize: 12.0,
                                    fontWeight: FontWeight.w500,
                                    color: ColorApp.myColorGray))),

                        /// Текст Должность
                        Expanded(
                            child: Text('Должность',
                                style: TextStyle(
                                    fontSize: 12.0,
                                    fontWeight: FontWeight.w500,
                                    color: ColorApp.myColorGray))),

                      ]),
                    const SizedBox(height: 10.0),
                    listSelectedContactPersonCompanyForeman.isNotEmpty
                        ? Expanded(
                            child: ListView.builder(
                              itemCount: listSelectedContactPersonCompanyForeman.length,
                              itemBuilder: (context, index) {
                                final listTest = listSelectedContactPersonCompanyForeman[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 10.0),
                                  child: Card(
                                      // key: ValueKey(listSelectedContactPersonCompany[index]),
                                      child: InkWell(
                                          onTap: () async {
                                            await getSelectContactFacesCompanyForeman(listSelectedContactPersonCompanyForeman[index]['id']);
                                            setState(() {
                                              showDialog(
                                                  context: context,
                                                  builder: (context) =>
                                                      const AlertDialog(
                                                        content: ViewContactPersonForeman()));
                                            });
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.all(10.0),
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(5.0),
                                              border: Border.all(
                                                  color: Colors.grey, width: 1),
                                            ),
                                            child: Row(
                                              children: [
                                                CircleAvatar(
                                                  minRadius: 25.0,
                                                    foregroundImage: NetworkImage('${ApiConfig.scheme}://${listTest['photo']}'),
                                                    backgroundImage: const AssetImage('assets/user.png')
                                                ),
                                                const SizedBox(width: 20.0),
                                                Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                   Text('${listTest['name']}'),
                                                  const SizedBox(height: 3.0),
                                                   Text('+7${listTest['phone']}'),
                                                  const SizedBox(height: 3.0),
                                                   const Text('Должность'),
                                                ],),
                                              ],
                                            ),
                                          ))),
                                );
                              },
                            ),
                          )
                        : const Center(child: Text('Список пустой')),
                    // CircularProgressIndicator(color: ColorApp.myColorGreen)),

                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
/// ======================================================

/// Выподающее окно контактных лиц =================================
class ViewContactPersonForeman extends StatefulWidget {
  const ViewContactPersonForeman({Key? key}) : super(key: key);

  @override
  State<ViewContactPersonForeman> createState() => _ViewContactPersonForemanState();
}
class _ViewContactPersonForemanState extends State<ViewContactPersonForeman> {

  @override
  void initState() {
    getCompanyObjectList();
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var dataAccount = selectedContactFacesForeman['data'];
    return StreamBuilder(
      stream: myStream.stream,
      builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
        return SizedBox(
          width: 400.0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ///Кнопкка изменить Текст Кнопкка закрыть
              Row(
                children: [
                  ///Кнопкка изменить
                  // IconButton(
                  //     onPressed: () {
                  //       setState(() {
                  //         showDialog(
                  //             context: context,
                  //             builder: (context) => const AlertDialog(
                  //               content: EditingContactPersonForeman(),
                  //             ));
                  //       });
                  //     },
                  //     icon: const Icon(
                  //       Icons.create_outlined,
                  //       color: ColorApp.myColorGreenAuth,
                  //     )),
                  const Spacer(),
                  ///Текст
                  const Text(
                    'Просмотр контактного лица',
                    style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  ///Кнопкка закрыть
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
              const SizedBox(height: 30.0),
              /// Фото и данные
              Row(
                children: [
                  /// Фото
                  CircleAvatar(
                    radius: 50.0,
                    backgroundImage: const AssetImage('assets/user.png'),
                    foregroundImage: NetworkImage('${ApiConfig.scheme}://${dataAccount['photo']}'),
                  ),
                  const SizedBox(width: 50.0),
                  /// Имя Телефон Адресс
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children:  [
                      /// Имя
                      Text(
                        '${dataAccount['name']}',
                        style:
                        const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20.0),
                      /// Телефон
                      Text(
                        '${dataAccount['phone']}',
                        style:
                        const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20.0),
                      /// Адресс
                      Text(
                        '${dataAccount['address']}',
                        style:
                        const TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

  }
}
/// ================================================================

/// Изменение контактного лица ===========================================
class EditingContactPersonForeman extends StatefulWidget {
  const EditingContactPersonForeman({Key? key}) : super(key: key);

  @override
  State<EditingContactPersonForeman> createState() => _EditingContactPersonForemanState();
}
class _EditingContactPersonForemanState extends State<EditingContactPersonForeman> {

  /// ФИО
  TextEditingController editingNameContactPerson = TextEditingController(text: '${selectedContactFacesForeman['data']['name']}');

  /// Адрес
  TextEditingController editingAddressContactPerson  = TextEditingController(text: '${selectedContactFacesForeman['data']['address']}');

  /// Номер телефона
  TextEditingController editingPhoneNumberContactPerson = TextEditingController(text:'${selectedContactFacesForeman['data']['phone']}');

  /// Электронный адрес
  TextEditingController editingEmailContactPerson = TextEditingController(text:'${selectedContactFacesForeman['data']['email']}' );

  /// Изменение контактного лица ===
  editingContactPerson() async {
    var response = await http.put(
      Uri.parse("${ApiConfig.base}/contact-person/${selectedContactFacesForeman['data']['id']}/"),
      headers: {
        "Content-Type": "application/json; charset=utf-8",
        'Authorization': 'Bearer ${IntTest.token}',
      },
      body: json.encode({
      "name": editingNameContactPerson.text,
      "company_id": getCompanyTitle,
      "phone": editingPhoneNumberContactPerson.text,
      "email": editingEmailContactPerson.text,
      "address": editingAddressContactPerson.text,
      },
      ),
    );
    listEditingContactPersonForeman = jsonDecode(utf8.decode(response.bodyBytes));
    print('Измененое контактное лицо ++++$listEditingContactPersonForeman+++++++');
    // listSelectedContactPersonCompany.add(listEditingContactPerson['data']);

  }
  /// ==============================

  @override
  void initState() {
    getCompanyTitle = '${selectedContactFacesForeman['data']['company_id']['id']}';
    print(getCompanyTitle);
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final keyFio = GlobalKey<FormState>();
    final keyAddress = GlobalKey<FormState>();
    final keyEmail = GlobalKey<FormState>();
    final keyPhoneNumber = GlobalKey<FormState>();
    return SizedBox(
      width: 500.0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ///Текст Кнопкка закрыть
          Row(
            children: [
              const Spacer(),
              ///Текст
              const Text(
                'Изменение контактного лица',
                style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              ///Кнопкка закрыть
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
          /// Фото
          CircleAvatar(
            radius: 50.0,
            backgroundImage: const AssetImage('assets/user.png'),
            foregroundImage: NetworkImage('${ApiConfig.scheme}://${selectedContactFacesForeman['data']['photo']}'),
          ),
          const Gap(20.0),
          /// ФИО
          Form(
            autovalidateMode: AutovalidateMode.onUserInteraction,
            key: keyFio,
            child: TextFormField(
              cursorColor: ColorApp.myColorGray,
              controller: editingNameContactPerson,
              decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: ColorApp.myColorGreenAuth),
                  ),
                  labelText: 'ФИО',
                  labelStyle: TextStyle(color: ColorApp.myColorGray)),
              validator: (value) {
                if (value!.isEmpty ||
                    !RegExp(r'^[а-я А-Я]+$').hasMatch(value)) {
                  return 'Некоректное Имя';
                } else {
                  return null;
                }
              },
            ),
          ),
          const Gap(20.0),
          /// Адрес
          Form(
            autovalidateMode: AutovalidateMode.onUserInteraction,
            key: keyAddress,
            child: TextFormField(
              cursorColor: ColorApp.myColorGray,
              controller: editingAddressContactPerson,
              decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: ColorApp.myColorGreenAuth),
                  ),
                  labelText: 'Адрес',
                  labelStyle: TextStyle(color: ColorApp.myColorGray)),
              validator: (value) {
                if (value!.isEmpty) {
                  return 'Заполните адрес';
                } else {
                  return null;
                }
              },
            ),
          ),
          const Gap(10.0),
          /// Компания подумать как ее оставлять если юзер ее не поменял???????
          Expanded(
            child: SizedBox(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Компания'),
                  const SizedBox(height: 5.0),
                  DropdownButtonFormField(
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
                                      content: AddCompany(),
                                    ))
                                    .then((value) => setState(() {}));
                              });
                            },
                            icon: const Icon(Icons.add_box_rounded,
                                size: 20.0,
                                color: ColorApp.myColorGreenAuth)),
                        border: const OutlineInputBorder()),
                  ),
                ],
              ),
            ),
          ),
          /// Номер телефона
          Form(
            autovalidateMode: AutovalidateMode.onUserInteraction,
            key: keyPhoneNumber,
            child: TextFormField(
              maxLength: 10,
              cursorColor: ColorApp.myColorGray,
              controller: editingPhoneNumberContactPerson,
              decoration: const InputDecoration(
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(left: 10.0, top: 11.0),
                    child: Text('+7'),
                  ),
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: ColorApp.myColorGreenAuth),
                  ),
                  labelText: 'Номер телефона',
                  labelStyle: TextStyle(color: ColorApp.myColorGray)),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value!.length > 10 ||
                    !RegExp(r'^[+]*[(]{0,1}[0-9]{1,4}[)]{0,1}[-\s\./0-9]+$')
                        .hasMatch(value)) {
                  return 'Некорректный номер телефона';
                } else {
                  return null;
                }
              },
            ),
          ),
          const Gap(10.0),
          ///Электронный адрес
          Form(
            autovalidateMode: AutovalidateMode.onUserInteraction,
            key: keyEmail,
            child: TextFormField(
              cursorColor: ColorApp.myColorGray,
              controller: editingEmailContactPerson,
              decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: ColorApp.myColorGreenAuth),
                  ),
                  labelText: 'Электронная почта',
                  labelStyle: TextStyle(color: ColorApp.myColorGray)),
              keyboardType: TextInputType.emailAddress,
              validator: (email) =>
              email != null && !EmailValidator.validate(email)
                  ? 'Не корректный email'
                  : null,
            ),
          ),
          const Gap(20.0),
          /// Кнопка Сохранить
          Row(
            children: [
              Expanded(
                child: MainButtonApp(textButton: 'Сохранить', press: () async {
                  keyFio.currentState!.validate();
                  keyAddress.currentState!.validate();
                  keyPhoneNumber.currentState!.validate();
                  keyEmail.currentState!.validate();
                  if(keyFio.currentState!.validate() &&
                      keyPhoneNumber.currentState!.validate() &&
                      keyEmail.currentState!.validate() &&
                      keyAddress.currentState!.validate()){
                    selectedContactFacesForeman['data']['name'] = editingNameContactPerson.text;
                    selectedContactFacesForeman['data']['address'] = editingAddressContactPerson.text;
                    selectedContactFacesForeman['data']['phone'] = editingPhoneNumberContactPerson.text;
                    await editingContactPerson();
                    await getSelectContactFacesCompanyForeman(selectedContactFacesForeman['data']['id']);
                    await getContactPersonCompanyForeman();
                    Navigator.pop(context);
                    myStream.add(IntTest.indexScreens);
                    setState(() {});
                  }

                },),
              ),
              const SizedBox(width: 10.0),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[300],
                      padding: const EdgeInsets.symmetric(vertical: 20.0)),
                  onPressed: (){
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Назад',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
/// ======================================================================