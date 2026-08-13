import 'dart:convert';
import 'package:els/helper/api_config.dart';
import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../../helper/button/my_button.dart';
import '../../../helper/class_colors.dart';
import 'package:http/http.dart' as http;
import '../../object/widgets/add_contact_person_object.dart';
import '../view/companies_screen.dart';
import '../view/company_page.dart';
import 'package:els/helper/api_client.dart';



class AddContactPerson extends StatefulWidget {
  AddContactPerson({
    Key? key,
  }) : super(key: key);

  @override
  State<AddContactPerson> createState() => _AddContactPersonState();
}

class _AddContactPersonState extends State<AddContactPerson> {

  /// Добавление контактного лица ==
  addingContactPerson() async {
    var response = await Api.post(
      Uri.parse("${ApiConfig.base}/contact-person/"),
      headers: {
        "Content-Type": "application/json; charset=utf-8",
      },
      body: json.encode({
        "name": newNameContactPerson.text,
        "company_id": listSelectedCompany['data']['id'],
        "phone": newPhoneNumberContactPerson.text,
        "email": newEmailContactPerson.text,
        "address": newAddressContactPerson.text,
      },
      ),
    );
    var listAddContactPerson = jsonDecode(utf8.decode(response.bodyBytes));
    print('Добавление контактного лица ++++$listAddContactPerson+++++++');
    listSelectedContactPersonCompany.add(listAddContactPerson['data']);
    await getContactPersonCompany();
  }
  /// ==============================

  /// ФИО
  TextEditingController newNameContactPerson = TextEditingController();

  /// Адрес
  TextEditingController newAddressContactPerson  = TextEditingController();

  /// Номер телефона
  TextEditingController newPhoneNumberContactPerson = TextEditingController();

  /// Электронный адрес
  TextEditingController newEmailContactPerson = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final keyFio = GlobalKey<FormState>();
    final keyAddress = GlobalKey<FormState>();
    final keyEmail = GlobalKey<FormState>();
    final keyPhoneNumber = GlobalKey<FormState>();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        /// Добавление контакного лица, иконка закрыть
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Добавление контакного лица',
                  style:
                  TextStyle(fontSize: 25.0, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5.0),
                Text(
                  'Заполните все поля, чтобы добавить новое контактное лицо для компании',
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
        const Gap(40.0),
        /// ФИО
        Form(
          autovalidateMode: AutovalidateMode.onUserInteraction,
          key: keyFio,
          child: TextFormField(
            cursorColor: ColorApp.myColorGray,
            controller: newNameContactPerson,
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
        const Gap(25.0),
        /// Адрес
        Form(
          autovalidateMode: AutovalidateMode.onUserInteraction,
          key: keyAddress,
          child: TextFormField(
            cursorColor: ColorApp.myColorGray,
            controller: newAddressContactPerson,
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
        const Gap(25.0),
        /// Номер телефона
        Form(
          autovalidateMode: AutovalidateMode.onUserInteraction,
          key: keyPhoneNumber,
          child: TextFormField(
            maxLength: 10,
            cursorColor: ColorApp.myColorGray,
            controller: newPhoneNumberContactPerson,
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
            controller: newEmailContactPerson,
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
        const Gap(50.0),
        /// Кнопка Сохранить
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MainButtonApp(textButton: 'Сохранить', press: () async {
              keyFio.currentState!.validate();
              keyAddress.currentState!.validate();
              keyPhoneNumber.currentState!.validate();
              keyEmail.currentState!.validate();
              if(keyFio.currentState!.validate() &&
                  keyPhoneNumber.currentState!.validate() &&
                  keyEmail.currentState!.validate() &&
                  keyAddress.currentState!.validate()){
                await addingContactPerson();
                await getContactPersonCompany();
                await getContactPersonSelectedCompanyList();
                Navigator.pop(context);
                setState(() {});
              }

            },),
          ],
        ),
      ],
    );
  }
}