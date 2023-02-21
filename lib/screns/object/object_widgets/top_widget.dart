import 'package:els/screns/employee/widgets/topButton.dart';
import 'package:flutter/material.dart';

import '../../../helper/class_colors.dart';

class TopWidgetObject extends StatefulWidget {
  const TopWidgetObject({Key? key}) : super(key: key);

  @override
  State<TopWidgetObject> createState() => _TopWidgetObjectState();
}

class _TopWidgetObjectState extends State<TopWidgetObject> {

  int myColorButtonObject = 1;

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5.0),
        color: ColorApp.myColorWhite,
        boxShadow: const [
          BoxShadow(
            color: Colors.grey,
            blurRadius: 5,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ///Компания
          if (size.width >= 1150) Expanded(
              child: TopButtonWidget(
                text: 'Компания',
                press: () {
                  myColorButtonObject = 5;
                  setState(() {});
                },
                pressIcon: () {},
                colorButton: myColorButtonObject == 5 ? ColorApp.myColorGreen : ColorApp.myColorWhite,
                colorText: myColorButtonObject == 5 ? ColorApp.myColorWhite : ColorApp.myColorBlack,
              )),
          ///Организация
          if (size.width > 900)  Expanded(
              child: TopButtonWidget(
                text: 'Организация',
                press: () {
                  myColorButtonObject = 3;
                  setState(() {});
                },
                pressIcon: () {},
                colorButton: myColorButtonObject == 3 ? ColorApp.myColorGreen : ColorApp.myColorWhite,
                colorText: myColorButtonObject == 3 ? ColorApp.myColorWhite : ColorApp.myColorBlack,
              )),
          ///Адресс
          Expanded(
              child: TopButtonWidget(
                text: 'Адресс',
                press: () {
                  myColorButtonObject = 1;
                  setState(() {});
                },
                pressIcon: () {},
                colorButton: myColorButtonObject == 1 ? ColorApp.myColorGreen : ColorApp.myColorWhite,
                colorText: myColorButtonObject == 1 ? ColorApp.myColorWhite : ColorApp.myColorBlack,
              )),
          ///Участок
          if (size.width > 750) Expanded(child: TopButtonWidget(
              text: 'Участок',
              press: () {
                myColorButtonObject = 2;
                setState(() {});
              },
              pressIcon: () {},
              colorButton: myColorButtonObject == 2 ? ColorApp.myColorGreen : ColorApp.myColorWhite,
              colorText: myColorButtonObject == 2 ? ColorApp.myColorWhite : ColorApp.myColorBlack,
            )),
          ///Прораб
          if (size.width > 500) Expanded(child: TopButtonWidget(text: 'Прораб',
              press: () {
                myColorButtonObject = 4;
                setState(() {});
              },
              pressIcon: () {},
              colorButton: myColorButtonObject == 4 ? ColorApp.myColorGreen : ColorApp.myColorWhite,
              colorText: myColorButtonObject == 4 ? ColorApp.myColorWhite : ColorApp.myColorBlack,
            )),
          ///Тип
          if (size.width > 500)  Expanded(child: TopButtonWidget(text: 'Тип',
            press: () {
              myColorButtonObject = 4;
              setState(() {});
            },
            pressIcon: () {},
            colorButton: myColorButtonObject == 4 ? ColorApp.myColorGreen : ColorApp.myColorWhite,
            colorText: myColorButtonObject == 4 ? ColorApp.myColorWhite : ColorApp.myColorBlack,
          )),
        ],
      ),
    );
  }
}
