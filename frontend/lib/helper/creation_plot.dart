import 'dart:convert';
import 'package:els/helper/api_config.dart';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../screns/home_page/home_page.dart';
import 'button/my_button.dart';
import 'class_colors.dart';

class CreationPlot extends StatefulWidget {
  const CreationPlot({Key? key}) : super(key: key);

  @override
  State<CreationPlot> createState() => _CreationPlotState();
}

class _CreationPlotState extends State<CreationPlot> {

  /// Создание участка ======
  createPlot() async {
    var response = await http.post(
      Uri.parse("${ApiConfig.base}/divisions/"),
      headers: {
        "Content-Type": "application/json; charset=utf-8",
        'Authorization': 'Bearer ${IntTest.token}',
      },
      body: json.encode(
        {
            "title": newPlot.text,
        },
      ),
    );
    var listAddPlot = jsonDecode(utf8.decode(response.bodyBytes));
    print(listAddPlot['data']);
    setState(() {});
  }
  /// =======================

  /// Название участка
  TextEditingController newPlot = TextEditingController();

  @override
  Widget build(BuildContext context) {



    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ///Текст и кнопкка закрыть
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Создание участка',
                  style: TextStyle(
                      fontSize: 20.0, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 5.0),
                Text(
                  'Заполните все поля, чтобы добавить новый участок в систему',
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
                )),
          ],
        ),
        const SizedBox(height: 20.0),
        TextFormField(
          cursorColor: ColorApp.myColorGray,
          controller: newPlot,
          decoration: const InputDecoration(
              labelText: 'Название участка',
              border: OutlineInputBorder(),
              focusedBorder: OutlineInputBorder(
                borderSide:
                BorderSide(color: ColorApp.myColorGreenAuth),
              ),
              // labelText: 'Документ',
              labelStyle: TextStyle(color: ColorApp.myColorGray)),
        ),
        const SizedBox(height: 20.0),
        /// Кнопка сохранить
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MainButtonApp(
              textButton: 'Создать',
              press: () async {
                await createPlot();
                myStream.add(IntTest.indexScreens);
                Navigator.pop(context);
                setState(() {});
              },
            ),
          ],
        ),
      ],
    );
  }
}
