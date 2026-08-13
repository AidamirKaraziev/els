import 'dart:convert';
import 'package:els/helper/api_config.dart';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../helper/button/my_button.dart';
import '../../../helper/class_colors.dart';
import '../../employee/widgets/add_employee.dart';
import '../../employee/widgets/editing_employee.dart';
import '../../home_page/home_page.dart';
import 'add_object.dart';
import 'package:els/helper/api_client.dart';


/// Участок =========
getPlot() async {
  final url = '${ApiConfig.base}/divisions/?page=1';
  final res = await Api.get(Uri.parse(url), headers: {
    "Content-Type": "application/json; charset=utf-8",
    'Accept': 'application/json',
  });
  var response = jsonDecode(utf8.decode(res.bodyBytes));

  plotList = response['data'];

}
String? myPlotTitle;
List plotList = [];
/// =================

class AddPlot extends StatefulWidget {
  AddPlot({
    Key? key,
  }) : super(key: key);

  @override
  State<AddPlot> createState() => _AddPlotState();
}

class _AddPlotState extends State<AddPlot> {

  // /// Участок ===================
  // getPlotObjectList() async {
  //   final url = '${ApiConfig.base}/divisions/?page=1';
  //   final res = await Api.get(Uri.parse(url), headers: {
  //     "Content-Type": "application/json; charset=utf-8",
  //     'Accept': 'application/json',
  //     'Authorization': 'Bearer ${IntTest.token}',
  //   });
  //   var response = jsonDecode(utf8.decode(res.bodyBytes));
  //   plotList = response['data'];
  //   print('Участок${response['data']['title']}');
  //   myStreamProfile.add(IntTest.indexScreens);
  //   setState(() {});
  // }
  // String? myPlotTitle;
  // /// ===========================




  /// Создать новый участок ==
  createNewPlot() async {
    var response = await Api.post(
      Uri.parse("${ApiConfig.base}/divisions/"),
      headers: {
        "Content-Type": "application/json; charset=utf-8",
      },
      body: json.encode({
        "title": newNamePlot.text,
      }
      ),
    );
    var listAddPlot = jsonDecode(utf8.decode(response.bodyBytes));
    print('новый участок ==${listAddPlot}==');
    plotList.add(listAddPlot['data']);
    // getPlotObjectList();
    getPlot();
    myStreamProfile.add(IntTest.indexScreens);
  }
  /// ========================


  /// Серийный номер
  TextEditingController newNamePlot = TextEditingController();
  final regNamePlot = GlobalKey<FormState>();


  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 500.0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// Создать новый участок, иконка закрыть
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Создать новый участок',
                    style:
                    TextStyle(fontSize: 25.0, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 5.0),
                  Text(
                    'Заполните поле, чтобы создать новый участок',
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
          /// Новый участок,
          Row(
            children: [
              /// Новый участок
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Новый участок',style: TextStyle(fontSize: 15.0,fontWeight: FontWeight.bold,color: ColorApp.myColorGrayText),),
                    const SizedBox(height: 10.0),
                    Form(
                      key: regNamePlot,
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
                        controller: newNamePlot,
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
          /// Кнопка Добавить
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              MainButtonApp(textButton: 'Добавить', press: () async {
                if(newNamePlot.text.isNotEmpty){
                  await createNewPlot();
                  await getPlot();
                  // await getPlotEmployee();

                  myStreamProfile.add(IntTest.indexScreens);
                  Navigator.pop(context);
                }
                regNamePlot.currentState!.validate();
                setState(() {});
              },),
            ],
          ),
        ],
      ),
    );
  }
}