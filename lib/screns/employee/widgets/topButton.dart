import 'package:flutter/material.dart';

import '../../../helper/class_colors.dart';

///Вверхние кнопки в Сотрудники


class TopButton extends StatefulWidget {
  const TopButton({Key? key}) : super(key: key);

  @override
  State<TopButton> createState() => _TopButtonState();
}

var myColorButton = 2;

class _TopButtonState extends State<TopButton> {
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
          ///ФИО
          Expanded(
            child: TopButtonWidget(
              text: 'ФИО',
              press: () {
                myColorButton = 1;
                setState(() {});
              },
              pressIcon: () {},
              colorButton: myColorButton == 1 ? ColorApp.myColorGreen : ColorApp.myColorWhite,
              colorText: myColorButton == 1 ? ColorApp.myColorWhite : ColorApp.myColorBlack,
            )),
          ///Участок
          if (size.width > 550) Expanded(
            child: TopButtonWidget(
              text: 'Участок',
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
          if (size.width > 1050) const Expanded(child: Text('Номер телефона')),
          ///Должность
          if (size.width > 600) Expanded(
            child: TopButtonWidget(
              text: 'Должность',
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


///Кнопка
class TopButtonWidget extends StatelessWidget {
  final String text;
  final VoidCallback press;
  final VoidCallback pressIcon;
  final Color colorButton;
  final Color colorText;

  const TopButtonWidget({
    Key? key,
    required this.text,
    required this.press,
    required this.pressIcon,
    required this.colorButton, required this.colorText,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            primary: ColorApp.myColorGreenLine,
              backgroundColor: colorButton,
              side: const BorderSide(color: ColorApp.myColorGreen)),
          onPressed: press,
          child: Text(
            text,
            style: TextStyle(color: colorText, ),
          ),
        ),
        const SizedBox(width: 5.0),
        InkWell(
          onTap: pressIcon,
          child: Container(
              width: 27,
              height: 27,
              decoration: BoxDecoration(
                border: Border.all(color: ColorApp.myColorGreen, width: 1.0),
                borderRadius: BorderRadius.circular(4.0),
              ),
              child: const Icon(Icons.arrow_drop_down_sharp)),
        ),
      ],
    );
  }
}
