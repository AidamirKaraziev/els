import 'dart:convert';
import 'package:els/helper/api_config.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import '../../../helper/button/my_button.dart';
import '../../../helper/class_colors.dart';
import 'package:http/http.dart' as http;
import '../../home_page/home_page.dart';
import '../view/companies_screen.dart';
import '../view/company_page.dart';
import 'package:els/helper/api_client.dart';

/// Добавление акаунта

class AddAccounts extends StatefulWidget {
  AddAccounts({
    Key? key,
  }) : super(key: key);

  @override
  State<AddAccounts> createState() => _AddAccountsState();
}

class _AddAccountsState extends State<AddAccounts> {

  /// Добавление акаунта ==========
  addingContactPerson() async {
    var response = await Api.post(
      Uri.parse("${ApiConfig.base}/cp/admin/create-client/"),
      headers: {
        "Content-Type": "application/json; charset=utf-8",
      },
      body: json.encode({
        "name": nameAccountUser.text,
        "email": emailAccount.text,
        "password": passwordAccount.text,
        "contact_phone": phoneNumberAccount.text,
        "birthday": dateBirthAccount.millisecondsSinceEpoch/1000,
        "location_id": 1,
        "role_id": 6,
        "company_id": listSelectedCompany['data']['id'],
      },
      ),
    );
    var listAddAccount = jsonDecode(utf8.decode(response.bodyBytes));
    print('Добавление акаунта ++++$listAddAccount+++++++');
    listSelectedAccountCompany.add(listAddAccount['data']);
    getAccountCompany(listSelectedCompany['data']['id']);
    myStream.add(IntTest.indexScreens);
  }
  /// =============================


  /// ФИО
  TextEditingController nameAccountUser = TextEditingController();

  /// Пароль
  TextEditingController passwordAccount = TextEditingController();

  /// Номер телефона
  TextEditingController phoneNumberAccount = TextEditingController();

  /// Электронный адрес
  TextEditingController emailAccount = TextEditingController();

  DateTime dateBirthAccount = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final keyFio = GlobalKey<FormState>();
    final keyEmail = GlobalKey<FormState>();
    final keyPhoneNumber = GlobalKey<FormState>();
    final keyPasswordNewEmployee = GlobalKey<FormState>();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        /// Текст Кнопка закрыть
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// Добавление акаунта
                const Text(
                  'Добавление акаунта',
                  style:
                  TextStyle(fontSize: 25.0, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5.0),
                /// Заполните все поля, чтобы добавить новой акаунт компании
                Text(
                  'Заполните все поля, чтобы добавить новой акаунт компании',
                  style: TextStyle(color: Colors.grey.shade400),
                ),
              ],
            ),
            /// Кнопка закрыть
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
        const SizedBox(height: 40.0),
        /// Текст Добавить Фото
        // const Text(
        //   'Добавить Фото',
        //   style: TextStyle(fontWeight: FontWeight.w700, color: Colors.grey),
        // ),
        // const SizedBox(height: 10.0),
        /// Кнопка Загрузите фото
        // DottedBorder(
        //   borderType: BorderType.RRect,
        //   radius: const Radius.circular(10.0),
        //   color: Colors.grey.shade400,
        //   dashPattern: const [5, 5],
        //   padding: const EdgeInsets.all(16.0),
        //   child: Row(
        //     children: [
        //       Container(
        //         decoration: BoxDecoration(
        //             color: ColorApp.myColorGreenWhite,
        //             borderRadius: BorderRadius.circular(5.0)),
        //         width: 80.0,
        //         height: 80.0,
        //         child: const Icon(
        //           Icons.photo_outlined,
        //           size: 22,
        //           color: ColorApp.myColorWhite,
        //         ),
        //       ),
        //       const SizedBox(width: 20.0),
        //       const Text(
        //         'Загрузите фото',
        //         style: TextStyle(fontSize: 15.0, fontWeight: FontWeight.bold),
        //       ),
        //       const Spacer(),
        //       OutlinedButton(
        //           style: OutlinedButton.styleFrom(
        //               padding: const EdgeInsets.symmetric(
        //                   horizontal: 30.0, vertical: 15.0)),
        //           onPressed: () {},
        //           child: const Text(
        //             'Прикрепить',
        //             style: TextStyle(
        //                 fontSize: 15.0,
        //                 fontWeight: FontWeight.bold,
        //                 color: ColorApp.myColorBlack),
        //           )),
        //     ],
        //   ),
        // ),
        // const SizedBox(height: 30.0),
        /// ФИО
        Form(
          autovalidateMode: AutovalidateMode.onUserInteraction,
          key: keyFio,
          child: TextFormField(
            cursorColor: ColorApp.myColorGray,
            controller: nameAccountUser,
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
        const SizedBox(height: 20.0),
        /// Дата рождения
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Дата рождения',
              style: TextStyle(
                  fontSize: 15.0,
                  fontWeight: FontWeight.bold,
                  color: ColorApp.myColorGrayText),
            ),
            const SizedBox(height: 10.0),
            InkWell(
                onTap: () async {
                  final DateTime? dateTime =
                  await showDatePicker(
                      context: context,
                      initialDate: dateBirthAccount,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(3000));
                  if (dateTime != null) {
                    dateBirthAccount = dateTime;
                    setState(() {});
                  }
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
                          Text('${dateBirthAccount.day} - ${dateBirthAccount.month} - ${dateBirthAccount.year}',style: const TextStyle(color: Colors.grey,fontSize: 16.0),),
                          const Icon(Icons.calendar_month_outlined,color: Colors.grey)]))),
          ],
        ),
        // TextFormField(
        //   cursorColor: ColorApp.myColorGray,
        //   decoration: InputDecoration(
        //       hintText: '${dateBirthAccount.day} - ${dateBirthAccount.month} - ${dateBirthAccount.year}',
        //       suffixIcon: IconButton(onPressed: () async {
        //         final DateTime ? dateTime = await showDatePicker(context: context,
        //             initialDate: dateBirthAccount,
        //             firstDate: DateTime(1900),
        //             lastDate: DateTime(3000));
        //         if(dateTime != null){
        //           setState(() {
        //             dateBirthAccount = dateTime;
        //             print(dateBirthAccount.millisecondsSinceEpoch/1000);
        //           });
        //         }
        //       },  icon: const Icon(Icons.calendar_month_outlined)),
        //       border: const OutlineInputBorder(),
        //       focusedBorder: const OutlineInputBorder(
        //         borderSide:
        //         BorderSide(color: ColorApp.myColorGreenAuth),
        //       ),
        //       // labelText: 'Документ',
        //       labelStyle: const TextStyle(color: ColorApp.myColorGray)),
        // ),
        const SizedBox(height: 20.0),
        /// Номер телефона
        Form(
          key: keyPhoneNumber,
          child: TextFormField(
            maxLength: 10,
            cursorColor: ColorApp.myColorGray,
            controller: phoneNumberAccount,
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
        const SizedBox(height: 10.0),
        /// Электронный адрес
        Form(
          key: keyEmail,
          child: TextFormField(
            cursorColor: ColorApp.myColorGray,
            controller: emailAccount,
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
        const SizedBox(height: 20.0),
        /// Пароль
        Form(
          key: keyPasswordNewEmployee,
          child: TextFormField(
            cursorColor: ColorApp.myColorGray,
            controller: passwordAccount,
            decoration: const InputDecoration(
              // suffixIcon: IconButton(onPressed: (){},icon: const Icon(Icons.calendar_month_outlined),),
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: ColorApp.myColorGreenAuth),
                ),
                labelText: 'Придумайте пароль',
                labelStyle: TextStyle(color: ColorApp.myColorGray)),
            validator: (value) {
              if (value!.length < 4) {
                return 'Минимум 4 символа';
              } else {
                return null;
              }
            },
          ),
        ),
        const SizedBox(height: 50.0),
        /// Кнопка Сохранить
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MainButtonApp(textButton: 'Сохранить', press: () async {
              keyFio.currentState!.validate();
              keyPhoneNumber.currentState!.validate();
              keyEmail.currentState!.validate();
              keyPasswordNewEmployee.currentState!.validate();
              if(keyFio.currentState!.validate() &&
                  keyPhoneNumber.currentState!.validate() &&
                  keyEmail.currentState!.validate() &&
                  keyPasswordNewEmployee.currentState!.validate()){
                await addingContactPerson();
                Navigator.pop(context);
                myStream.add(IntTest.indexScreens);
              }
            },),
          ],
        ),
      ],
    );
  }
}
class ViewAccount extends StatelessWidget {
  const ViewAccount({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
        height: 300,
        child: Column(
          children: [],
        ));
  }
}



