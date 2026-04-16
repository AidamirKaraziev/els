import 'package:els/screns/employee/widgets/topButton.dart';
import 'package:flutter/material.dart';

import '../../../helper/class_colors.dart';
import '../../home_page/home_page.dart';

int myColorButtonObject = 1;

class TopWidgetObject extends StatefulWidget {
  const TopWidgetObject({Key? key}) : super(key: key);

  @override
  State<TopWidgetObject> createState() => _TopWidgetObjectState();
}

class _TopWidgetObjectState extends State<TopWidgetObject> {

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
          ///Название
          Expanded(
              flex: 3,
              child: Row(
                children: [
                  TopButtonWidget(
                    text: 'Название',
                    press: () {
                      myColorButtonObject = 1;
                      myStream.add(IntTest.indexScreens);
                      setState(() {});
                    },
                    pressIcon: () {},
                    colorButton: myColorButtonObject == 1 ? ColorApp.myColorGreen : ColorApp.myColorWhite,
                    colorText: myColorButtonObject == 1 ? Colors.white :  ColorApp.myColorBlack,
                  ),
                  // const SizedBox(width: 5.0),
                  // Container(
                  //     width: 27.5,
                  //     height: 27.5,
                  //     decoration: BoxDecoration(
                  //       border:
                  //       Border.all(color: ColorApp.myColorGreen, width: 1.0),
                  //       borderRadius: BorderRadius.circular(3.0),
                  //     ),
                  //     child: const Icon(Icons.arrow_drop_down_sharp)),
                ],
              )),
          ///Заводской номер
          if (size.width > 1150)  Expanded(
              flex: 3,
              child: Row(
                children: [
                  TopButtonWidget(
                    text: 'Заводской номер',
                    press: () {
                      myColorButtonObject = 2;
                      myStream.add(IntTest.indexScreens);
                      setState(() {});
                    },
                    pressIcon: () {},
                    colorButton: myColorButtonObject == 2 ? ColorApp.myColorGreen : ColorApp.myColorWhite,
                    colorText: myColorButtonObject == 2 ? Colors.white :  ColorApp.myColorBlack,
                  ),
                  // const SizedBox(width: 5.0),
                  // Container(
                  //     width: 27.5,
                  //     height: 27.5,
                  //     decoration: BoxDecoration(
                  //       border:
                  //       Border.all(color: ColorApp.myColorGreen, width: 1.0),
                  //       borderRadius: BorderRadius.circular(3.0),
                  //     ),
                  //     child: const Icon(Icons.arrow_drop_down_sharp)),
                ],
              )),
          ///Компания
          if (size.width >= 990) Expanded(
              flex: 3,
              child: Row(
                children: [
                  TopButtonWidget(
                    text: 'Компания',
                    press: () {
                      myColorButtonObject = 3;
                      myStream.add(IntTest.indexScreens);
                      setState(() {});
                    },
                    pressIcon: () {},
                    colorButton: myColorButtonObject == 3 ? ColorApp.myColorGreen : ColorApp.myColorWhite,
                    colorText: myColorButtonObject == 3 ? Colors.white :  ColorApp.myColorBlack,
                  ),
                  // const SizedBox(width: 5.0),
                  // Container(
                  //     width: 27.5,
                  //     height: 27.5,
                  //     decoration: BoxDecoration(
                  //       border:
                  //       Border.all(color: ColorApp.myColorGreen, width: 1.0),
                  //       borderRadius: BorderRadius.circular(3.0),
                  //     ),
                  //     child: const Icon(Icons.arrow_drop_down_sharp)),
                ],
              )),
          ///Адресс
          if (size.width > 650)
          Expanded(
              flex: 3,
              child: Row(
                children: [
                  TopButtonWidget(
                    text: 'Адресс',
                    press: () {
                      myColorButtonObject = 4;
                      myStream.add(IntTest.indexScreens);
                      setState(() {});
                    },
                    pressIcon: () {},
                    colorButton: myColorButtonObject == 4 ? ColorApp.myColorGreen : ColorApp.myColorWhite,
                    colorText: myColorButtonObject == 4 ? Colors.white :  ColorApp.myColorBlack,
                  ),
                  // const SizedBox(width: 5.0),
                  // Container(
                  //     width: 27.5,
                  //     height: 27.5,
                  //     decoration: BoxDecoration(
                  //       border:
                  //       Border.all(color: ColorApp.myColorGreen, width: 1.0),
                  //       borderRadius: BorderRadius.circular(3.0),
                  //     ),
                  //     child: const Icon(Icons.arrow_drop_down_sharp)),
                ],
              )),
          ///Участок
          if (size.width > 850) Expanded(
              flex: 3,
              child: Row(
            children: [
              TopButtonWidget(
                  text: 'Участок',
                  press: () {
                    myColorButtonObject = 5;
                    myStream.add(IntTest.indexScreens);
                    setState(() {});
                  },
                  pressIcon: () {},
                colorButton: myColorButtonObject == 5 ? ColorApp.myColorGreen : ColorApp.myColorWhite,
                colorText: myColorButtonObject == 5 ? Colors.white :  ColorApp.myColorBlack,
                ),
              // const SizedBox(width: 5.0),
              // Container(
              //     width: 27.5,
              //     height: 27.5,
              //     decoration: BoxDecoration(
              //       border:
              //       Border.all(color: ColorApp.myColorGreen, width: 1.0),
              //       borderRadius: BorderRadius.circular(3.0),
              //     ),
              //     child: const Icon(Icons.arrow_drop_down_sharp)),
            ],
          )),
          ///Тип
          if (size.width > 450)  Expanded(
            flex: 2,
              child: Row(
            children: [
              TopButtonWidget(text: 'Тип',
                press: () {
                  myColorButtonObject = 6;
                  myStream.add(IntTest.indexScreens);
                  setState(() {});
                },
                pressIcon: () {},
                colorButton: myColorButtonObject == 6 ? ColorApp.myColorGreen : ColorApp.myColorWhite,
                colorText: myColorButtonObject == 6 ? Colors.white :  ColorApp.myColorBlack,
              ),
              // const SizedBox(width: 5.0),
              // Container(
              //     width: 27.5,
              //     height: 27.5,
              //     decoration: BoxDecoration(
              //       border:
              //       Border.all(color: ColorApp.myColorGreen, width: 1.0),
              //       borderRadius: BorderRadius.circular(3.0),
              //     ),
              //     child: const Icon(Icons.arrow_drop_down_sharp)),
            ],
          )),
        ],
      ),
    );
  }
}
