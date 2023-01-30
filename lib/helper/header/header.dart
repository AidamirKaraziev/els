



import 'package:badges/badges.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

import '../../bloc/user_bloc/user_bloc.dart';
import '../../screns/companies/add_companies.dart';
import '../../screns/employee/add_employee.dart';
import '../../screns/object/object_widgets/add_object.dart';
import '../../screns/object/object_widgets/editing_object.dart';
import '../class_colors.dart';

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
    return BlocBuilder<UserBloc, UserState>(
      builder: (context, state) {
        return Padding(
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
                                builder: (context) => AlertDialog(
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
                                builder: (context) =>  AlertDialog(
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
                Badge(
                  position:
                  const BadgePosition(top: 0, end: 0),
                  badgeContent: const Text('9',
                      style: TextStyle(
                          color: ColorApp.myColorWhite,
                          fontWeight: FontWeight.w500)),
                  toAnimate: false,
                  badgeColor: ColorApp.myColorRed,
                  child: IconButton(
                    onPressed: () {},
                    icon: const Icon(
                        Icons.notifications_none_outlined,
                        size: 25.0),
                  ),
                ),

              SizedBox( width:size.width > 500 ? 40.0 : 10.0),
              ///Аватар Юзера
              if(state is UserGetState)
                CircularPercentIndicator(
                  radius: size.width > 350 ? 33.0 : 23.0,
                  lineWidth: 5.0,
                  percent: 0.7,
                  progressColor: ColorApp.myColorGreenAuth,
                  backgroundColor: ColorApp.myColorAvatar,
                  center: GestureDetector(
                    onTap: (){
                      IntTest.indexScreens = 9;
                      IntTest.myTitle = state.getUser[0]['name'];
                      setState(() {});
                    },
                    child: CircleAvatar(
                      radius: size.width > 350 ? 29.0 : 20.0,
                      backgroundColor: Colors.transparent,
                      backgroundImage: const AssetImage('assets/user.png'),
                      foregroundImage: NetworkImage('http://${state.getUser[0]['photo']}'),
                      // child: Text('${state.getUser[0]['name'][0]}',style: const TextStyle(color: ColorApp.myColorWhite,fontWeight: FontWeight.w600,fontSize: 20.0)),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}