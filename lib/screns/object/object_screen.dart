import 'package:els/helper/class_colors.dart';
import 'package:els/screns/object/object_widgets/top_widget.dart';
import 'package:flutter/material.dart';
import '../../helper/my_map/my_map.dart';

///ОБЬЕКТЫ

class ObjectScreen extends StatefulWidget {
  const ObjectScreen({Key? key}) : super(key: key);

  @override
  State<ObjectScreen> createState() => _ObjectScreenState();
}

bool test = true;

class _ObjectScreenState extends State<ObjectScreen> {
  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return Scaffold(
      body: SafeArea(
        child: Container(
          color: ColorApp.myColorTransparent,
          child: Column(
            children: [
              ///Кнопки Список Карта
              Padding(
                padding: const EdgeInsets.only(top: 20.0, right: 20.0),
                child: Row(
                  children: [
                    const Spacer(),

                    ///Кнопка Список
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        onPrimary: test == true ? Colors.white : Colors.black,
                        primary: test == true
                            ? const Color(0xffBADE89)
                            : Colors.white,
                      ),
                      onPressed: () {
                        test = true;
                        print(test);
                        setState(() {});
                      },
                      child: const Text('Список'),
                    ),

                    ///Кнопка Карта
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        onPrimary: test == false ? Colors.white : Colors.black,
                        primary: test == false
                            ? ColorApp.myColorGreen
                            : Colors.white,
                      ),
                      onPressed: () {
                        test = false;
                        print(test);
                        setState(() {});
                      },
                      child: const Text('Карта'),
                    ),
                  ],
                ),
              ),
              test == true
                  ? Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          const TopWidgetObject(),
                          const SizedBox(height: 20.0),
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.65,
                            child: ListView.builder(
                                controller: ScrollController(),
                                itemCount: 10,
                                itemBuilder: (context, index) =>
                                    GestureDetector(
                                      onTap: () {},
                                      child: Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 10.0),
                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(5.0),
                                            color: ColorApp.myColorWhite,
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 20.0,vertical: 10.0),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                              children: [
                                                ///Компания
                                                if (size.width > 1150)
                                                  Expanded(
                                                    child: Container(
                                                      height: 60,
                                                      // padding: const EdgeInsets.all(10.0),
                                                      decoration: BoxDecoration(
                                                        borderRadius:
                                                        BorderRadius
                                                            .circular(10),
                                                        color: ColorApp
                                                            .myColorGrayShadow,
                                                      ),
                                                      child: Row(
                                                        children: const [
                                                          Padding(
                                                            padding: EdgeInsets
                                                                .symmetric(
                                                                horizontal:
                                                                10.0),
                                                            child: CircleAvatar(
                                                              foregroundImage:
                                                              NetworkImage(
                                                                'http:',
                                                              ),
                                                              backgroundImage:
                                                              AssetImage(
                                                                  'assets/user.png'),
                                                              // child: Text('${state.listGetEmployee[index]['name'][0]}',style: const TextStyle(color: ColorApp.myColorWhite,fontWeight: FontWeight.w600,fontSize: 20.0)),
                                                            ),
                                                          ),
                                                          Expanded(
                                                            child: Text('name'),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                const SizedBox(width: 10.0),
                                                ///Организация
                                                if (size.width > 900)
                                                  Expanded(
                                                    child: Container(
                                                      height: 60,
                                                      // padding: const EdgeInsets.all(10.0),
                                                      decoration: BoxDecoration(
                                                        borderRadius:
                                                        BorderRadius
                                                            .circular(10),
                                                        color: ColorApp
                                                            .myColorGrayShadow,
                                                      ),
                                                      child: Row(
                                                        children: const [
                                                          Padding(
                                                            padding: EdgeInsets
                                                                .symmetric(
                                                                horizontal:
                                                                10.0),
                                                            child: CircleAvatar(
                                                              foregroundImage:
                                                              NetworkImage(
                                                                'http',
                                                              ),
                                                              backgroundImage:
                                                              AssetImage(
                                                                  'assets/user.png'),
                                                              // child: Text('${state.listGetEmployee[index]['name'][0]}',style: const TextStyle(color: ColorApp.myColorWhite,fontWeight: FontWeight.w600,fontSize: 20.0)),
                                                            ),
                                                          ),
                                                          Expanded(
                                                            child: Text('name'),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                const SizedBox(width: 10.0),
                                                ///Адрес
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: const [
                                                      Text('Краснодар',
                                                          style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600)),
                                                      Text(
                                                          'ул. Калинина, 12, подъезд 2'),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(width: 10.0),
                                                ///Участок
                                                if (size.width > 750)
                                                  const Expanded(
                                                      child: Text(
                                                          'ООО “Гармония”')),
                                                const SizedBox(width: 10.0),
                                                ///Прораб
                                                if (size.width > 500)
                                                  Expanded(
                                                    child: Container(
                                                      height: 60,
                                                      // padding: const EdgeInsets.all(10.0),
                                                      decoration: BoxDecoration(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(10),
                                                        color: ColorApp
                                                            .myColorGrayShadow,
                                                      ),
                                                      child: Row(
                                                        children: const [
                                                          Padding(
                                                            padding: EdgeInsets
                                                                .symmetric(
                                                                    horizontal:
                                                                        10.0),
                                                            child: CircleAvatar(
                                                              foregroundImage:
                                                                  NetworkImage(
                                                                'http://' ']}',
                                                              ),
                                                              backgroundImage:
                                                                  AssetImage(
                                                                      'assets/user.png'),
                                                              // child: Text('${state.listGetEmployee[index]['name'][0]}',style: const TextStyle(color: ColorApp.myColorWhite,fontWeight: FontWeight.w600,fontSize: 20.0)),
                                                            ),
                                                          ),
                                                          Expanded(
                                                            child: Text('name'),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                const SizedBox(width: 10.0),
                                                ///Прораб
                                                if (size.width > 500)
                                                  Expanded(
                                                    child: Container(
                                                      padding: const EdgeInsets.all(10.0),
                                                      decoration: BoxDecoration(
                                                        borderRadius:
                                                        BorderRadius
                                                            .circular(10),
                                                        color: ColorApp.myColorGreen,
                                                      ),
                                                      child: Center(child: Text('name',style: TextStyle(fontWeight: FontWeight.w500,color: ColorApp.myColorWhite),)),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    )),
                          ),
                        ],
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width,
                        height: MediaQuery.of(context).size.height * 0.7,
                        child: MyMap(),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
