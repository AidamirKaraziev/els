import 'dart:convert';
import 'package:els/helper/api_config.dart';
import 'package:http_parser/http_parser.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:els/helper/button/my_button.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:els/helper/image_picking.dart';
import '../../../bloc/company_bloc/company_bloc.dart';
import '../../../helper/class_colors.dart';
import 'package:http/http.dart' as http;

import '../../home_page/home_page.dart';
import '../view/companies_screen.dart';
import 'package:els/helper/api_client.dart';
import 'package:els/helper/api_image.dart';



/// Редактировании компании ==================================

class EditingCompany extends StatefulWidget {
  const EditingCompany({
    Key? key,
  }) : super(key: key);

  @override
  State<EditingCompany> createState() => _EditingCompanyState();
}

class _EditingCompanyState extends State<EditingCompany> {



  /// Функция изменение фото ====================
  var imagePath;
  String basename(String path) {
    if (path.isNotEmpty) {
      String str = path.replaceAll(RegExp(r'(.png|.jpeg|.svg|.jpg)'), '');
      return str;
    }
    return 'noName';
  }
  Future openGalleryAndCompany() async {
    if (kIsWeb) {
      PickedImage? imageFile = (await pickImageFromGallery());
      if (imageFile != null) {
        imagePath = imageFile;
        print(imagePath);
        requestHttp(imageFile);
      }
    }
  }
  requestHttp(PickedImage imageFile) async {
    Map<String, String> headers = {
      "Accept": "application/json",
    }; // ignore this headers if there is no authentication
    var uri = Uri.parse("${ApiConfig.base}/company/${IntTest.pressHover}/photo/");
    http.MultipartRequest request = await Api.multipart("PUT", uri);
    http.MultipartFile multipartFile = http.MultipartFile.fromBytes(
        'file', imageFile.data!,
        contentType: MediaType('image', 'jpeg'),
        filename: basename(imageFile.fileName ?? ''));
    request.files.add(multipartFile);
    request.headers.addAll(headers);
    var response = await Api.sendMultipart(request);
    response.stream.transform(utf8.decoder).listen((value) {
      Map listTestPhoto = jsonDecode(value);
      listSelectedCompany['data']['photo'] = listTestPhoto['data']['photo'];
      dataCompany[IntTest.indexCompanyList]['photo'] = listTestPhoto['data']['photo'];
    });
    myStream.add(IntTest.indexScreens);
  }
  /// ============================================

  /// Функция редактировании компании ==
  editingCompany(int userId) async {
    var response = await Api.put(
      Uri.parse("${ApiConfig.base}/company/$userId/"),
      headers: {
        "Content-Type": "application/json; charset=utf-8",
      },
      body: json.encode(
        {
          "name": newNameCompany.text,
          "director_name": newNameDirectorCompany.text,
          "cont_phone": newPhoneNumberCompany.text,
          "cont_address": newAddressCompany.text,
          "email": newEmailCompany.text,
          "site": newSiteCompany.text,
          "location_id": 1,
        },
      ),
    );
  }
  /// ==================================

  /// Text Controller New Company =========================================================================================

  /// Редактировании компании
  TextEditingController newNameCompany = TextEditingController(text: listSelectedCompany['data']['name']);

  /// Директор
  TextEditingController newNameDirectorCompany = TextEditingController(text: listSelectedCompany['data']['director_name']);

  /// Номер телефона
  TextEditingController newPhoneNumberCompany = TextEditingController(text: listSelectedCompany['data']['cont_phone']);

  /// Юридический адрес
  TextEditingController newAddressCompany = TextEditingController(text: listSelectedCompany['data']['cont_address']);

  /// Электронный адрес
  TextEditingController newEmailCompany = TextEditingController(text: listSelectedCompany['data']['email']);

  /// Сайт
  TextEditingController newSiteCompany = TextEditingController(text: listSelectedCompany['data']['site']);

  /// ==========================================================================================================================

  @override
  void initState() {
    print('>>>>>>>>>>> Editing >>>>>${listSelectedCompany['data']}');
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: myStream.stream,
      builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
        return SizedBox(
          width: 890.0,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// Текст и кнопка закрвыть
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
                /// текст Логотип компании
                const Text(
                  'Логотип компании',
                  style: TextStyle(fontWeight: FontWeight.w700, color: Colors.grey),
                ),
                const SizedBox(height: 10.0),
                /// Загрузите логотип
                DottedBorder(
                  // borderType: BorderType.RRect,
                  // radius: const Radius.circular(10.0),
                  // color: Colors.grey.shade400,
                  // dashPattern: const [5, 5],
                  // padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      dataCompany[IntTest.indexCompanyList]['photo'] == null
                          ? Container(
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
                      )
                          : CircleAvatar(
                        radius: 30.0,
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage: const AssetImage('assets/comp.jpeg'),
                        foregroundImage: apiImage(listSelectedCompany['data']['photo']),
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
                          onPressed: () {
                            openGalleryAndCompany();
                          },
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
                /// Наимнование компании, Директор
                Row(
                  children: [
                    /// Наимнование компании
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Наимнование компании',style: TextStyle(fontSize: 15.0,fontWeight: FontWeight.bold,color: ColorApp.myColorGrayText),),
                          const SizedBox(height: 10.0),
                          TextFormField(
                            cursorColor: ColorApp.myColorGray,
                            controller: newNameCompany,
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
                    /// Директор
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Директор',style: TextStyle(fontSize: 15.0,fontWeight: FontWeight.bold,color: ColorApp.myColorGrayText),),
                          const SizedBox(height: 10.0),
                          TextFormField(
                            cursorColor: ColorApp.myColorGray,
                            controller: newNameDirectorCompany,
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
                /// Номер телефона, Юридический адрес
                Row(
                  children: [
                    /// Номер телефона
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
                              controller: newPhoneNumberCompany,
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
                          TextFormField(
                            cursorColor: ColorApp.myColorGray,
                            controller: newAddressCompany,
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
                /// Электронный адрес, Сайт
                Row(
                  children: [
                    /// Электронный адрес
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Электронный адрес',style: TextStyle(fontSize: 15.0,fontWeight: FontWeight.bold,color: ColorApp.myColorGrayText),),
                          const SizedBox(height: 10.0),
                          TextFormField(
                            cursorColor: ColorApp.myColorGray,
                            controller: newEmailCompany,
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
                    /// Сайт
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Сайт',style: TextStyle(fontSize: 15.0,fontWeight: FontWeight.bold,color: ColorApp.myColorGrayText),),
                          const SizedBox(height: 10.0),
                          TextFormField(
                            cursorColor: ColorApp.myColorGray,
                            controller: newSiteCompany,
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
                /// Кнопка Сохранить
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    MainButtonApp(textButton: 'Сохранить', press: () async {
                      await editingCompany(IntTest.pressHover);
                      CompanyBloc().add(CompanyGetUserEvent());
                      /// Новое имя компании
                      listSelectedCompany['data']['name'] = newNameCompany.text;
                      getCompany[IntTest.indexCompanyList]['name'] = newNameCompany.text;
                      /// Новое имя директора
                      listSelectedCompany['data']['director_name'] = newNameDirectorCompany.text;
                      getCompany[IntTest.indexCompanyList]['director_name'] = newNameDirectorCompany.text;
                      /// Новый телефон компании
                      listSelectedCompany['data']['cont_phone'] = newPhoneNumberCompany.text;
                      getCompany[IntTest.indexCompanyList]['cont_phone'] = newPhoneNumberCompany.text;
                      /// Новый адрес компании
                      listSelectedCompany['data']['cont_address'] = newAddressCompany.text;
                      getCompany[IntTest.indexCompanyList]['cont_address'] = newAddressCompany.text;
                      /// Новый електронный адрес компании
                      listSelectedCompany['data']['email'] = newEmailCompany.text;
                      getCompany[IntTest.indexCompanyList]['email'] = newEmailCompany.text;
                      /// Новый сайт компании
                      listSelectedCompany['data']['site'] = newSiteCompany.text;
                      getCompany[IntTest.indexCompanyList]['site'] = newSiteCompany.text;
                      myStream.add(IntTest.indexScreens);
                      Navigator.pop(context);
                    },),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

  }
}
/// ==========================================================