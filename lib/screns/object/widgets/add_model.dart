import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../helper/button/my_button.dart';
import '../../../helper/class_colors.dart';
import '../../home_page/home_page.dart';
import 'add_object.dart';

/// Создания модэли по ID

var typeSelectModel; /// разобраться с

/// Тип =======================
getTypeObjectList() async {
  final url = 'http://${IntTest.myIp}/api/v1/type-object/?page=1';
  final res = await http.get(Uri.parse(url), headers: {
    "Content-Type": "application/json; charset=utf-8",
    'Accept': 'application/json',
    'Authorization': 'Bearer ${IntTest.token}',
  });
  var response = jsonDecode(utf8.decode(res.bodyBytes));
  typeObjectList = response['data'];
  // print(modelList);
}
String? typeObjectTitle;
List typeObjectList = [];
/// ===========================

/// Модэль по ID ============================
getModelObjectListId(var modelId) async {
  //api/v1/factory-model/sort-by-type-object/$modelId/?page=1
  final url = 'http://${IntTest.myIp}/api/v1/factory-model/sort-by-type-object/$modelId/?page=1';
  final res = await http.get(Uri.parse(url), headers: {
    "Content-Type": "application/json; charset=utf-8",
    'Accept': 'application/json',
    'Authorization': 'Bearer ${IntTest.token}',
  });
  var response = jsonDecode(utf8.decode(res.bodyBytes));
  modelListId = response['data'];
  print('modelMapId:${modelListId}');

}
String? modelTitleId;
List modelListId = [];
/// ==========================================

class AddModel extends StatefulWidget {
  AddModel({
    Key? key,
  }) : super(key: key);

  @override
  State<AddModel> createState() => _AddModelState();
}
class _AddModelState extends State<AddModel> {
  /// Добавление модели ======
  addingModel() async {
    var response = await http.post(
      Uri.parse("http://${IntTest.myIp}/api/v1/factory-model/"),
      headers: {
        "Content-Type": "application/json; charset=utf-8",
        'Authorization': 'Bearer ${IntTest.token}',
      },
      body: json.encode({
        "type_object_id": typeObjectTitle,
        "factory": factoryNumber.text,
        "model": modelNumber.text,
      }
      ),
    );
    var listAddModel = jsonDecode(utf8.decode(response.bodyBytes));
    modelListId.add(listAddModel['data']);
    print('Добавление модели ++++${modelListId}+++++++');
    getTypeObjectList();
  }
  /// ========================

  /// Серийный номер
  TextEditingController modelNumber = TextEditingController();

  /// Завод изготовитель
  TextEditingController factoryNumber = TextEditingController();


  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 790.0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Добавление модели, иконка закрыть
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Добавление модели',
                    style:
                    TextStyle(fontSize: 25.0, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5.0),
                  Text(
                    'Заполните все поля, чтобы добавить новую модель',
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
          const SizedBox(height: 30.0),
          Row(
            children: [
              /// Завод изготовитель
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Завод изготовитель',style: TextStyle(fontSize: 15.0,fontWeight: FontWeight.bold,color: ColorApp.myColorGrayText),),
                    const SizedBox(height: 10.0),
                    TextFormField(
                      cursorColor: ColorApp.myColorGray,
                      controller: factoryNumber,
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
              /// Имя модели
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Имя модели',style: TextStyle(fontSize: 15.0,fontWeight: FontWeight.bold,color: ColorApp.myColorGrayText),),
                    const SizedBox(height: 10.0),
                    TextFormField(
                      cursorColor: ColorApp.myColorGray,
                      controller: modelNumber,
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
          /// Кнопка Добавить
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              MainButtonApp(textButton: 'Добавить', press: () async {
                await addingModel();
                await getModelObjectListId(typeObjectTitle);
                myStream.add(IntTest.indexScreens);
                Navigator.pop(context);
                setState(() {});
              },),
            ],
          ),
        ],
      ),
    );
  }
}