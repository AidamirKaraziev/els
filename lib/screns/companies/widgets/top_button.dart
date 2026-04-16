import 'package:flutter/material.dart';
import '../../../foreman/companies_foreman/companies_arhive_foreman/companies_screen_archive_foreman.dart';
import '../../../helper/class_colors.dart';
import '../../employee/widgets/topButton.dart';
import '../../home_page/home_page.dart';

///Вверхние кнопки в Компании

var myColorButtonCompany = 1;

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
                  setState(() {
                    myStream.add(IntTest.indexScreens);
                    print(openListSearchCompany);
                    myColorButtonCompany = 1;
                  });
                },
                pressIcon: () {},
                colorButton: myColorButtonCompany == 1 ? ColorApp.myColorGreen : ColorApp.myColorWhite,
                colorText: myColorButtonCompany == 1 ? ColorApp.myColorWhite :  ColorApp.myColorBlack,
              )),
          const SizedBox(width: 30),
          ///Имя Директора
          if (size.width > 500) Expanded(
            child: TopButtonWidget(
              text: 'Директор',
              press: () {
                myStream.add(IntTest.indexScreens);
                myColorButtonCompany = 2;
                setState(() {});
              },
              pressIcon: () {},
              colorButton: myColorButtonCompany == 2 ? ColorApp.myColorGreen : ColorApp.myColorWhite,
              colorText: myColorButtonCompany == 2 ? ColorApp.myColorWhite :  ColorApp.myColorBlack,
            ),
          ),
          ///Номер телефона
          if (size.width > 1150)  Expanded(child: TopButtonWidget(
            text: 'Номер телефона',
            press: () {
              openListSearchCompany = false;
              myStream.add(IntTest.indexScreens);
              myColorButtonCompany = 3;
              setState(() {});
            },
            pressIcon: () {},
            colorButton: myColorButtonCompany == 3 ? ColorApp.myColorGreen : ColorApp.myColorWhite,
            colorText: myColorButtonCompany == 3 ? ColorApp.myColorWhite :  ColorApp.myColorBlack,
          )),
          ///Тип договора
          if (size.width > 800) Expanded(
            child: TopButtonWidget(
              text: 'Эл.почта',
              press: () {
                myStream.add(IntTest.indexScreens);
                myColorButtonCompany = 4;
                setState(() {});
              },
              pressIcon: () {},
              colorButton: myColorButtonCompany == 4 ? ColorApp.myColorGreen : ColorApp.myColorWhite,
              colorText: myColorButtonCompany == 4 ? ColorApp.myColorWhite :  ColorApp.myColorBlack,
            ),
          ),
        ],
      ),
    );
  }
}