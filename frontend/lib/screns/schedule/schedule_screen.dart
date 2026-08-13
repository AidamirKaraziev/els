import 'dart:convert';
import 'package:els/helper/api_config.dart';
import 'package:els/screns/schedule/schedule_page.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../helper/class_colors.dart';
import '../../helper/header/header.dart';
import '../../helper/my_drawer/my_drawer.dart';
import '../../helper/my_user.dart';
import '../employee/widgets/topButton.dart';
import '../home_page/home_page.dart';
import '../object/view/object_screen.dart';
import 'package:els/helper/api_client.dart';

///Графики

Map testListSSSS = {};
List dataSchedule = [];
List getScheduleList = [];
List getTOScheduleList = [];

int myColorButtonSchedule = 1;
int newScreensSchedule = 1;

getScheduleFun() async {
  final res = await Api.get(
      Uri.parse('${ApiConfig.base}/all-objects/?page=$newScreensSchedule'),
      headers: {
        "Content-Type": "application/json; charset=utf-8",
        'Accept': 'application/json',
      });
  var getObjectListBlock = jsonDecode(utf8.decode(res.bodyBytes));
  dataSchedule = getObjectListBlock['data'];
  // print('${dataSchedule}');
  myStream.add(IntTest.indexScreens);
}

bool openListCompanySchedule = false;
bool openListPlotSchedule = false;

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({
    Key? key,
  }) : super(key: key);

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {

  bool openListSearch = false;

  final ScrollController _controllerSchedule = ScrollController();

  @override
  void initState() {
    getScheduleFun();
    dataSchedule = getScheduleList;
    // _controllerSchedule.addListener(_loadMore);
    // TODO: implement initState
    super.initState();
  }

  @override
  void dispose() {
    newScreensSchedule = 1;
    super.dispose();
  }

  /// Функция поиска по имени ========================
  void _runScheduleFilter(String enteredKeyword) {
    List result = [];
    if (enteredKeyword.isEmpty) {
      result = getScheduleList;
    } else {
      result = getScheduleList
          .where((user) => myColorButtonSchedule == 1
          ? user['name'].toLowerCase().contains(enteredKeyword.toLowerCase())
          : myColorButtonSchedule == 2
          ? user['factory_number'].toLowerCase().contains(enteredKeyword.toLowerCase())
          : myColorButtonSchedule == 3
          ? user['division_id']['title'].toLowerCase().contains(enteredKeyword.toLowerCase())
          : user['factory_model_id']['type_object_id']['name'].toLowerCase().contains(enteredKeyword.toLowerCase()))
          .toList();
    }
    setState(() {
      dataSchedule = result;
    });
    print('Сработала функция');
  }
  /// ================================================

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return StreamBuilder(
      stream: myStream.stream,
      builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
        return Scaffold(
          key: myOpenDrawer,
          drawer: const MyDrawer(),
          body: Container(
            color: ColorApp.myColorTransparent,
            child: Column(
              children: [
                ///Header =====
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: ColorApp.kPadding),
                  color: Colors.white,
                  height: 70,
                  width: double.infinity,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      ///Иконка меню
                      if (size.width <= 1350)
                        Row(
                          children: [
                            IconButton(
                                onPressed: () {
                                  myOpenDrawer.currentState!.openDrawer();
                                  setState(() {});
                                },
                                icon: Icon(Icons.menu,
                                    size: size.width > 350 ? 25.0 : 20)),
                            const SizedBox(width: 10.0),
                          ],
                        ),

                      /// Текст
                      Text('Графики',
                          style: TextStyle(
                              fontSize: size.width > 350 ? 25.0 : 18.0,
                              fontWeight: size.width > 350
                                  ? FontWeight.w700
                                  : FontWeight.w500)),
                      const SizedBox(width: 10.0),
                      if (size.width > 500)
                        Row(
                          children: [
                            if (openListSearch == false)
                              IconButton(
                                  onPressed: () {
                                    openListSearch = true;
                                    setState(() {});
                                    myStream.add(IntTest.indexScreens);
                                  },
                                  icon: const Icon(Icons.search,
                                      size: 25.0, color: ColorApp.myColorGray)),
                          ],
                        ),
                      if (openListSearch)
                        Row(
                          children: [
                            const SizedBox(width: 10),
                            SizedBox(
                              width: MediaQuery.of(context).size.width * 0.3,
                              height: 40.0,
                              child: Form(
                                child: TextField(
                                  onChanged: (value) => _runScheduleFilter(value),
                                  cursorColor: ColorApp.myColorGray,
                                  decoration: InputDecoration(
                                      contentPadding: const EdgeInsets.all(0.0),
                                      prefixIcon: IconButton(
                                          onPressed: () {},
                                          icon: const Icon(Icons.search)),
                                      suffixIcon: IconButton(
                                          onPressed: () {
                                            setState(() {
                                              dataSchedule = getScheduleList;
                                            });
                                            openListSearch = false;
                                            // myStream.add(IntTest.indexScreens);
                                          },
                                          icon: const Icon(Icons.close)),
                                      border: const OutlineInputBorder(),
                                      focusedBorder: const OutlineInputBorder(
                                        borderSide: BorderSide(
                                            color: ColorApp.myColorGreenAuth),
                                      ),
                                      labelText: myColorButtonSchedule == 1
                                          ? 'Поиск по названию' : myColorButtonSchedule == 2
                                          ? 'Поиск по заводскому номеру' : myColorButtonSchedule == 3
                                          ? 'Поиск по участку' : 'Поиск по типу',
                                      labelStyle: const TextStyle(
                                          color: ColorApp.myColorGray)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      const Spacer(),
                      /// Переключение страницы
                      Row(
                        children: [
                          IconButton(onPressed: (){
                            if(newScreensSchedule > 1) {
                              --newScreensSchedule;
                            }
                            getScheduleFun();
                            myStream.add(IntTest.indexScreens);
                            setState(() {});
                          }, icon: const Icon(Icons.arrow_circle_left_outlined, color: Color(0xffBADE89))),
                          const SizedBox(width: 10.0),
                          Text('$newScreensSchedule'),
                          const SizedBox(width: 10.0),
                          IconButton(onPressed: (){
                            if(dataSchedule.isNotEmpty) {
                              newScreensSchedule++;
                            }
                            getScheduleFun();
                            myStream.add(IntTest.indexScreens);
                            setState(() {});
                          }, icon: const Icon(Icons.arrow_circle_right_outlined, color: Color(0xffBADE89))),
                        ],
                      ),
                      ///Колокольчик
                      if (size.width > 400)
                        Badge(
                          alignment: const AlignmentDirectional(21, 4),
                          backgroundColor: ColorApp.myColorRed,
                          isLabelVisible: IntTest.badgeCount > 0 ? true : false,
                          label: IntTest.badgeCount < 1
                              ? const SizedBox.shrink()
                              : Text(IntTest.badgeCount.toString(),
                              style: const TextStyle(
                                  fontSize: 12.0,
                                  color: ColorApp.myColorWhite,
                                  fontWeight: FontWeight.w500)),
                          child: IconButton(
                            onPressed: () {},
                            icon: const Icon(Icons.notifications_none_outlined,
                                size: 25.0),
                          ),
                        ),
                      SizedBox(width: size.width > 500 ? 40.0 : 10.0),

                      ///Аватар Юзера
                      const MyUser(),
                    ],
                  ),
                ),

                /// Top bar
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Container(
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
                            flex: 2,
                            child: Row(
                              children: [
                                TopButtonWidget(
                                  text: 'Название',
                                  press: () {
                                    myColorButtonSchedule = 1;
                                    setState(() {});
                                  },
                                  pressIcon: () {},
                                  colorButton: myColorButtonSchedule == 1 ? ColorApp.myColorGreen : ColorApp.myColorWhite,
                                  colorText: myColorButtonSchedule == 1 ? Colors.white :  ColorApp.myColorBlack,
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
                        if (size.width > 980)  SizedBox(
                          width: 170,
                          child: Row(
                            children: [
                              TopButtonWidget(
                                text: 'Заводской номер',
                                press: () {
                                  myColorButtonSchedule = 2;
                                  setState(() {});
                                },
                                pressIcon: () {},
                                colorButton: myColorButtonSchedule == 2 ? ColorApp.myColorGreen : ColorApp.myColorWhite,
                                colorText: myColorButtonSchedule == 2 ? Colors.white :  ColorApp.myColorBlack,
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
                          ),
                        ),
                        const SizedBox(width: 10.0),
                        ///Участок
                        if (size.width > 850) Expanded(
                            flex: 2,
                            child: Row(
                              children: [
                                TopButtonWidget(
                                  text: 'Участок',
                                  press: () {
                                    myColorButtonSchedule = 3;
                                    setState(() {});
                                  },
                                  pressIcon: () {},
                                  colorButton: myColorButtonSchedule == 3 ? ColorApp.myColorGreen : ColorApp.myColorWhite,
                                  colorText: myColorButtonSchedule == 3 ? Colors.white :  ColorApp.myColorBlack,
                                ),
                              ],
                            )),
                        const SizedBox(width: 10.0),
                        ///Тип
                        if (size.width > 1150)  SizedBox(
                          width: 150.0,
                          child: Row(
                            children: [
                              TopButtonWidget(text: 'Тип',
                                press: () {
                                  myColorButtonSchedule = 4;
                                  setState(() {});
                                },
                                pressIcon: () {},
                                colorButton: myColorButtonSchedule == 4 ? ColorApp.myColorGreen : ColorApp.myColorWhite,
                                colorText: myColorButtonSchedule == 4 ? Colors.white :  ColorApp.myColorBlack,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10.0),
                        /// Графики
                        if (size.width > 650)
                        Expanded(
                            flex: 3,
                            child: Row(
                              children: [
                                TopButtonWidget(text: 'Графики',
                                  press: () {
                                    // myColorButtonObject = 6;
                                    // setState(() {});
                                  },
                                  pressIcon: () {},
                                  colorButton: ColorApp.myColorWhite,
                                  colorText: ColorApp.myColorBlack,
                                ),
                              ],
                            )),
                      ],
                    ),
                  ),
                ),

                /// Body ============
                StreamBuilder(
                    stream: myStream.stream,
                    builder: (context, ind) => Expanded(
                      child: ListView.builder(
                          controller: _controllerSchedule,
                          itemCount: dataSchedule.length,
                          itemBuilder: (context, index) {
                            dataSchedule.sort((a, b) => a['name'].compareTo(b['name']));
                            final dataObjectScreen = dataSchedule[index];
                            return dataObjectScreen['is_actual'] == false
                                ? Container()
                                :  Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20.0),
                              child: Card(
                                key: ValueKey(dataObjectScreen['id']),
                                child: GestureDetector(
                                  onTap: () async {
                                    IntTest.indexObjectList = index;
                                    IntTest.pressHover = dataObjectScreen['id'];
                                    await getListObjectInfo(IntTest.pressHover);
                                    await getAllTemplateTOInIdObject(IntTest.pressHover); // Получение всех Шаблонов привязанных к обьекту
                                    await getFactActListInIdObject(IntTest.pressHover); // Получение фактических актов привязанных к обьекту
                                    await getTOScheduleIdObject(IntTest.pressHover); // Получить список плановых TO привязанных к обьекту

                                    myStream.add(IntTest.indexScreens);
                                    IntTest.indexScreens = 12;
                                    setState(() {});
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(5.0),
                                        color: ColorApp.myColorWhite),
                                    child: Padding(padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          ///Название
                                          Expanded(
                                            flex: 2,
                                            child: Column(
                                              crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                              children: [
                                                Text(dataObjectScreen['name'] ?? '',
                                                    style: const TextStyle(
                                                        fontWeight: FontWeight.w400)),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 10.0),

                                          ///Заводской номер
                                          if (size.width > 980)
                                            SizedBox(
                                              width: 170,
                                              child: Column(
                                                crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                      '${dataObjectScreen['factory_number']}' ??
                                                          '',
                                                      style: const TextStyle(
                                                          fontWeight: FontWeight.w400)),
                                                ],
                                              ),
                                            ),
                                          const SizedBox(width: 10.0),

                                          ///Участок
                                          if (size.width > 850)
                                            Expanded(
                                                flex: 2,
                                                child: dataObjectScreen['division_id'] != null
                                                    ? Text(dataObjectScreen['division_id']['title'])
                                                    : const Text('')),
                                          const SizedBox(width: 10.0),

                                          ///Тип
                                          if (size.width > 1150)
                                            Container(
                                              width: 150.0,
                                              padding: const EdgeInsets.all(10.0),
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(10),
                                                color: ColorApp.myColorGreen,
                                              ),
                                              child: Center(
                                                  child: Text(
                                                    dataObjectScreen['factory_model_id']['type_object_id']['name'] ?? '',
                                                    style: const TextStyle(
                                                        fontWeight: FontWeight.w500,
                                                        color: ColorApp.myColorWhite),
                                                  )),
                                            ),

                                          ///Графики
                                          const SizedBox(width: 10.0),
                                          if (size.width > 650)
                                            Expanded(
                                              flex: 3,
                                              child: Row(
                                                children: [
                                                  Container(
                                                    height: 20.0,
                                                    width: 20.0,
                                                    decoration: BoxDecoration(
                                                      borderRadius: BorderRadius.circular(5.0),
                                                      color: ColorApp.myColorGreen,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 5.0),
                                                  Container(
                                                    height: 20.0,
                                                    width: 20.0,
                                                    decoration: BoxDecoration(
                                                      borderRadius: BorderRadius.circular(5.0),
                                                      color: ColorApp.myColorGreen,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 5.0),
                                                  Container(
                                                    height: 20.0,
                                                    width: 20.0,
                                                    decoration: BoxDecoration(
                                                      borderRadius: BorderRadius.circular(5.0),
                                                      color: ColorApp.myColorGreen,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 5.0),
                                                  Container(
                                                    height: 20.0,
                                                    width: 20.0,
                                                    decoration: BoxDecoration(
                                                      borderRadius: BorderRadius.circular(5.0),
                                                      color: ColorApp.myColorGreen,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 5.0),
                                                  Container(
                                                    height: 20.0,
                                                    width: 20.0,
                                                    decoration: BoxDecoration(
                                                      borderRadius: BorderRadius.circular(5.0),
                                                      color: ColorApp.myColorGreen,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 5.0),
                                                  Container(
                                                    height: 20.0,
                                                    width: 20.0,
                                                    decoration: BoxDecoration(
                                                      borderRadius: BorderRadius.circular(5.0),
                                                      color: ColorApp.myColorGreen,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 5.0),
                                                  Container(
                                                    height: 20.0,
                                                    width: 20.0,
                                                    decoration: BoxDecoration(
                                                      borderRadius: BorderRadius.circular(5.0),
                                                      color: ColorApp.myColorGreen,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 5.0),
                                                  Container(
                                                    height: 20.0,
                                                    width: 20.0,
                                                    decoration: BoxDecoration(
                                                      borderRadius: BorderRadius.circular(5.0),
                                                      color: ColorApp.myColorGreen,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 5.0),
                                                  Container(
                                                    height: 20.0,
                                                    width: 20.0,
                                                    decoration: BoxDecoration(
                                                      borderRadius: BorderRadius.circular(5.0),
                                                      color: ColorApp.myColorGreen,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 5.0),
                                                  Container(
                                                    height: 20.0,
                                                    width: 20.0,
                                                    decoration: BoxDecoration(
                                                      borderRadius: BorderRadius.circular(5.0),
                                                      color: ColorApp.myColorGreen,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 5.0),
                                                  Container(
                                                    height: 20.0,
                                                    width: 20.0,
                                                    decoration: BoxDecoration(
                                                      borderRadius: BorderRadius.circular(5.0),
                                                      color: ColorApp.myColorGreen,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 5.0),
                                                  Container(
                                                    height: 20.0,
                                                    width: 20.0,
                                                    decoration: BoxDecoration(
                                                      borderRadius: BorderRadius.circular(5.0),
                                                      color: ColorApp.myColorGreen,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 5.0),
                                                ],
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                    )),

              ],
            ),
          ),
        );
      },
    );

  }
}
