import 'package:flutter/material.dart';

import '../../helper/class_colors.dart';
import '../employee/widgets/topButton.dart';

///Вверхние кнопки в Компании


class TopButtonCompanies extends StatefulWidget {
  const TopButtonCompanies({Key? key}) : super(key: key);

  @override
  State<TopButtonCompanies> createState() => _TopButtonCompaniesState();
}

class _TopButtonCompaniesState extends State<TopButtonCompanies> {
  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
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
          ///Название компании
          Expanded(
              child: TopButtonWidget(
                text: 'Название компании',
                press: () {
                  myColorButton = 1;
                  setState(() {});
                },
                pressIcon: () {},
                colorButton: myColorButton == 1 ? ColorApp.myColorGreen : ColorApp.myColorWhite,
                colorText: myColorButton == 1 ? ColorApp.myColorWhite : ColorApp.myColorBlack,
              )),
          const SizedBox(width: 30),
          ///Имя Директора
          if (size.width > 500) Expanded(
            child: TopButtonWidget(
              text: 'Директор',
              press: () {
                myColorButton = 2;
                setState(() {});
              },
              pressIcon: () {},
              colorButton: myColorButton == 2 ? ColorApp.myColorGreen : ColorApp.myColorWhite,
              colorText: myColorButton == 2 ? ColorApp.myColorWhite : ColorApp.myColorBlack,
            ),
          ),
          ///Номер телефона
          if (size.width > 1150) const Expanded(child: Text('Номер телефона')),
          ///Тип договора
          if (size.width > 800) Expanded(
            child: TopButtonWidget(
              text: 'Тип договора',
              press: () {
                myColorButton = 3;
                setState(() {});
              },
              pressIcon: () {},
              colorButton: myColorButton == 3 ? ColorApp.myColorGreen : ColorApp.myColorWhite,
              colorText: myColorButton == 3 ? ColorApp.myColorWhite : ColorApp.myColorBlack,
            ),
          ),
        ],
      ),
    );
  }
}