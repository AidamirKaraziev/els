import 'package:dotted_border/dotted_border.dart';
import 'package:els/helper/button/my_button.dart';
import 'package:els/helper/class_colors.dart';
import 'package:flutter/material.dart';



class EditingCompany extends StatefulWidget {
  const EditingCompany({
    Key? key,
  }) : super(key: key);

  @override
  State<EditingCompany> createState() => _EditingCompanyState();
}

class _EditingCompanyState extends State<EditingCompany> {

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
                      'Редактировании компании',
                      style:
                      TextStyle(fontSize: 25.0, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 5.0),
                    Text(
                      'Здесь вы можете отредактировать необходимые поля',
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
              'Логотип компании',
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
                    'Загрузите логотип',
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Наимнование компании',style: TextStyle(fontSize: 15.0,fontWeight: FontWeight.bold,color: ColorApp.myColorGrayText),),
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
                      const Text('Директор',style: TextStyle(fontSize: 15.0,fontWeight: FontWeight.bold,color: ColorApp.myColorGrayText),),
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
                      const Text('Номер телефона',style: TextStyle(fontSize: 15.0,fontWeight: FontWeight.bold,color: ColorApp.myColorGrayText),),
                      const SizedBox(height: 10.0),
                      Form(
                        // key: keyPhoneNumber,
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Юридический адрес',style: TextStyle(fontSize: 15.0,fontWeight: FontWeight.bold,color: ColorApp.myColorGrayText),),
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
                const SizedBox(width: 20.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Сайт',style: TextStyle(fontSize: 15.0,fontWeight: FontWeight.bold,color: ColorApp.myColorGrayText),),
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