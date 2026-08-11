import 'package:flutter/material.dart';
import '../../screns/companies/widgets/add_companies.dart';
import '../../screns/employee/widgets/add_employee.dart';
import '../../screns/home_page/home_page.dart';
import '../../screns/object/widgets/add_object.dart';
import '../../screns/object/widgets/editing_object.dart';
import '../class_colors.dart';
import '../my_drawer/my_drawer.dart';
import '../my_user.dart';

///Header

class MyHeader extends StatefulWidget {
  const MyHeader({Key? key}) : super(key: key);

  @override
  State<MyHeader> createState() => _MyHeaderState();
}

final GlobalKey<ScaffoldState> myOpenDrawer = GlobalKey<ScaffoldState>();

class _MyHeaderState extends State<MyHeader> {
  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return Scaffold(
      key: myOpenDrawer,
      drawer: const MyDrawer(),
      backgroundColor: Colors.white,
      body: Padding(
        padding: EdgeInsets.symmetric(
            horizontal: size.width > 600 ? 20.0 : 10.0),
        child: Row(
          children: [
            ///Иконка меню
            if (size.width <= 1350)
              Row(
                children: [
                  IconButton(onPressed: (){
                    myOpenDrawer.currentState!.openDrawer();
                    setState(() {});
                  }, icon: Icon(Icons.menu,size: size.width > 350 ? 25.0 : 20)),
                  const SizedBox(width: 10.0),
                ],
              ),
            ///Text
            Text(IntTest.myTitle,
                style:  TextStyle(
                    fontSize: size.width > 350 ? 25.0 : 18.0,
                    fontWeight: size.width > 350 ?  FontWeight.w700 : FontWeight.w500)),
            ///Иконки Обьекты
            if ( IntTest.indexScreens == 3)
              Row(
                children: [
                  const SizedBox(width: 10.0),
                  ///Добавить Обьект
                  IconButton(
                      onPressed: () {
                        setState(() {
                          showDialog(
                              context: context,
                              builder: (context) => const AlertDialog(
                                content:  AddObject(),
                              ));
                        });
                      },
                      icon: const Icon(
                          Icons.add_box_rounded,
                          size: 25.0,
                          color: ColorApp
                              .myColorGreenAuth)),
                  ///Поиск Обьекта
                  IconButton(
                      onPressed: () {
                        setState(() {
                          showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                content:  EditingObject(),
                              ));
                        });
                      },
                      icon: const Icon(Icons.search,
                          size: 25.0,
                          color:
                          ColorApp.myColorGray)),
                ],
              ),
            ///Иконки Компании
            if (IntTest.indexScreens == 4)
              Row(
                children: [
                  const SizedBox(width: 10.0),
                  ///Добавить Компанию
                  IconButton(
                      onPressed: () {
                        setState(() {
                          showDialog(
                              context: context,
                              builder: (context) =>  const AlertDialog(
                                content: AddCompany(),
                              ));
                        });
                      },
                      icon: const Icon(
                          Icons.add_box_rounded,
                          size: 25.0,
                          color: ColorApp
                              .myColorGreenAuth)),
                ],
              ),
            ///Иконки Сотрудники
            if (IntTest.indexScreens == 6)
              Row(
                children: [
                  const SizedBox(width: 10.0),
                  ///Добавить Сотрудника
                  IconButton(
                      onPressed: () {
                        setState(() {
                          showDialog(
                              context: context,
                              builder: (context) =>  const AlertDialog(
                                content:  AddEmployee(),
                              ));
                        });
                      },
                      icon: const Icon(
                          Icons.add_box_rounded,
                          size: 25.0,
                          color: ColorApp
                              .myColorGreenAuth)),
                  ///Архивировать Сотрудника
                  if(size.width > 500)
                    IconButton(
                        onPressed: () {},
                        icon: const Icon(
                            Icons.archive_outlined,
                            size: 25.0,
                            color:
                            ColorApp.myColorGray)),
                  ///Поиск Сотрудника
                  if(size.width > 500)
                    IconButton(
                        onPressed: () {},
                        icon: const Icon(Icons.search,
                            size: 25.0,
                            color:
                            ColorApp.myColorGray)),
                ],
              ),

            const Spacer(),
            ///Колокольчик
            if(size.width > 400)
            // Badge(
            //   position:
            //   const BadgePosition(top: 0, end: 0),
            //   badgeContent: const Text('9',
            //       style: TextStyle(
            //           color: ColorApp.myColorWhite,
            //           fontWeight: FontWeight.w500)),
            //   toAnimate: false,
            //   badgeColor: ColorApp.myColorRed,
            //   child: IconButton(
            //     onPressed: () {},
            //     icon: const Icon(
            //         Icons.notifications_none_outlined,
            //         size: 25.0),
            //   ),
            // ),

              SizedBox( width:size.width > 500 ? 40.0 : 10.0),
            ///Аватар Юзера
            StreamBuilder(
              stream: myStream.stream,
              builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                return const MyUser();
              },
            ),
          ],
        ),
      ),
    );
  }
}