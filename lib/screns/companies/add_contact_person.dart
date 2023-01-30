import 'package:dotted_border/dotted_border.dart';
import 'package:els/helper/class_colors.dart';
import 'package:flutter/material.dart';

import '../../helper/button/my_button.dart';


class AddContactPerson extends StatefulWidget {
  AddContactPerson({
    Key? key,
  }) : super(key: key);

  @override
  State<AddContactPerson> createState() => _AddContactPersonState();
}

class _AddContactPersonState extends State<AddContactPerson> {

  /// ФИО
  TextEditingController nameUser = TextEditingController();

  /// Адрес
  TextEditingController address = TextEditingController();

  /// Номер телефона
  TextEditingController phoneNumber = TextEditingController();

  /// Электронный адрес
  TextEditingController email = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 890.0,
      height: 750.0,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                      Navigator.pop(context);
                    },
                    icon: const Icon(
                      Icons.close,
                      color: ColorApp.myColorGreenAuth,
                    ))
              ],
            ),
            const SizedBox(height: 30.0),
            const Text(
              'Добавить Фото',
              style: TextStyle(fontWeight: FontWeight.w700, color: Colors.grey),
            ),
            const SizedBox(height: 10.0),
            DottedBorder(
              borderType: BorderType.RRect,
              radius: const Radius.circular(10.0),
              color: Colors.grey.shade400,
              dashPattern: const [5, 5],
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                        color: ColorApp.myColorGreenWhite,
                        borderRadius: BorderRadius.circular(5.0)),
                    width: 80.0,
                    height: 80.0,
                    child: const Icon(
                      Icons.photo_outlined,
                      size: 22,
                      color: ColorApp.myColorWhite,
                    ),
                  ),
                  const SizedBox(width: 20.0),
                  const Text(
                    'Загрузите фото',
                    style: TextStyle(fontSize: 15.0, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  OutlinedButton(
                      style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 30.0, vertical: 15.0)),
                      onPressed: () {},
                      child: const Text(
                        'Прикрепить',
                        style: TextStyle(
                            fontSize: 15.0,
                            fontWeight: FontWeight.bold,
                            color: ColorApp.myColorBlack),
                      )),
                ],
              ),
            ),
            const SizedBox(height: 30.0),
            Row(
              children: [
                /// ФИО
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('ФИО',style: TextStyle(fontSize: 15.0,fontWeight: FontWeight.bold,color: ColorApp.myColorGrayText),),
                      const SizedBox(height: 10.0),
                      TextFormField(
                        cursorColor: ColorApp.myColorGray,
                        controller: nameUser,
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
                ),
                const SizedBox(width: 20.0),
                /// Адрес
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Адрес',style: TextStyle(fontSize: 15.0,fontWeight: FontWeight.bold,color: ColorApp.myColorGrayText),),
                      const SizedBox(height: 10.0),
                      TextFormField(
                        cursorColor: ColorApp.myColorGray,
                        controller: address,
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
                ),
              ],
            ),
            const SizedBox(height: 30.0),
            Row(
              children: [
                /// Номер телефона
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Номер телефона',style: TextStyle(fontSize: 15.0,fontWeight: FontWeight.bold,color: ColorApp.myColorGrayText),),
                      const SizedBox(height: 10.0),
                      TextFormField(
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
                    ],
                  ),
                ),
                const SizedBox(width: 20.0),
                /// Электронный адрес
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Электронный адрес',style: TextStyle(fontSize: 15.0,fontWeight: FontWeight.bold,color: ColorApp.myColorGrayText),),
                      const SizedBox(height: 10.0),
                      TextFormField(
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
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30.0),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                MainButtonApp(textButton: 'Сохранить', press: () { },),
              ],
            ),
          ],
        ),
      ),
    );
  }
}