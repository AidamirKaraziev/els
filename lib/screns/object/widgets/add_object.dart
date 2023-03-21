import 'package:els/helper/button/my_button.dart';
import 'package:flutter/material.dart';
import '../../../helper/class_colors.dart';

///Создание объекта

class AddObject extends StatefulWidget {
  AddObject({
    Key? key,
  }) : super(key: key);

  @override
  State<AddObject> createState() => _AddObjectState();
}

class _AddObjectState extends State<AddObject> {

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

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 890.0,
      // height: 750.0,
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
                      'Создание объекта',
                      style:
                      TextStyle(fontSize: 25.0, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 5.0),
                    Text(
                      'Заполните все поля, чтобы добавить новый объект в систему',
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
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Организация',style: TextStyle(fontSize: 15.0,fontWeight: FontWeight.bold,color: ColorApp.myColorGrayText),),
                      const SizedBox(height: 10.0),
                      TextFormField(
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
                    ],
                  ),
                ),
                const SizedBox(width: 20.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Участок',style: TextStyle(fontSize: 15.0,fontWeight: FontWeight.bold,color: ColorApp.myColorGrayText),),
                      const SizedBox(height: 10.0),
                      TextFormField(
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
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30.0),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Адрес',style: TextStyle(fontSize: 15.0,fontWeight: FontWeight.bold,color: ColorApp.myColorGrayText),),
                      const SizedBox(height: 10.0),
                      TextFormField(
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
                    ],
                  ),
                ),
                const SizedBox(width: 20.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Модель',style: TextStyle(fontSize: 15.0,fontWeight: FontWeight.bold,color: ColorApp.myColorGrayText),),
                      const SizedBox(height: 10.0),
                      TextFormField(
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
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30.0),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Компания',style: TextStyle(fontSize: 15.0,fontWeight: FontWeight.bold,color: ColorApp.myColorGrayText),),
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
                const SizedBox(width: 10.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Контактное лицо',style: TextStyle(fontSize: 15.0,fontWeight: FontWeight.bold,color: ColorApp.myColorGrayText),),
                      const SizedBox(height: 10.0),
                      TextFormField(
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
                    ],
                  ),
                ),
                const SizedBox(width: 10.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Договор',style: TextStyle(fontSize: 15.0,fontWeight: FontWeight.bold,color: ColorApp.myColorGrayText),),
                      const SizedBox(height: 10.0),
                      TextFormField(
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
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30.0),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Регистрационный номер',style: TextStyle(fontSize: 15.0,fontWeight: FontWeight.bold,color: ColorApp.myColorGrayText),),
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
                const SizedBox(width: 10.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Заводской номер',style: TextStyle(fontSize: 15.0,fontWeight: FontWeight.bold,color: ColorApp.myColorGrayText),),
                      const SizedBox(height: 10.0),
                      TextFormField(
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
                    ],
                  ),
                ),
                const SizedBox(width: 10.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Высота подъема',style: TextStyle(fontSize: 15.0,fontWeight: FontWeight.bold,color: ColorApp.myColorGrayText),),
                      const SizedBox(height: 10.0),
                      TextFormField(
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
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30.0),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Количество остановок',style: TextStyle(fontSize: 15.0,fontWeight: FontWeight.bold,color: ColorApp.myColorGrayText),),
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
                const SizedBox(width: 10.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Грузоподъемность',style: TextStyle(fontSize: 15.0,fontWeight: FontWeight.bold,color: ColorApp.myColorGrayText),),
                      const SizedBox(height: 10.0),
                      TextFormField(
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
                    ],
                  ),
                ),
                const SizedBox(width: 10.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Ширина',style: TextStyle(fontSize: 15.0,fontWeight: FontWeight.bold,color: ColorApp.myColorGrayText),),
                      const SizedBox(height: 10.0),
                      TextFormField(
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




