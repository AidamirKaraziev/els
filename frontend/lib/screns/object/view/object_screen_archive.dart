import 'package:els/screns/object/widgets/top_widget.dart';
import 'package:flutter/material.dart';
import '../../../helper/class_colors.dart';
import '../../../helper/header/header.dart';
import '../../../helper/my_drawer/my_drawer.dart';
import '../../../helper/my_user.dart';
import '../../home_page/home_page.dart';
import 'package:http/http.dart' as http;
import 'object_screen.dart';
import 'package:els/helper/api_config.dart';
import 'package:els/helper/api_image.dart';

///ОБЬЕКТЫ Архив

class ObjectScreenArchive extends StatefulWidget {
  const ObjectScreenArchive({Key? key}) : super(key: key);

  @override
  State<ObjectScreenArchive> createState() => _ObjectScreenArchiveState();
}

class _ObjectScreenArchiveState extends State<ObjectScreenArchive> {

  /// Функция поиска по имени ========================
  void _runObjectFilter(String enteredKeyword) {
    List result = [];
    if (enteredKeyword.isEmpty) {
      result = getObject;
    } else {
      result = getObject
          .where((user) =>
          user['name'].toLowerCase().contains(enteredKeyword.toLowerCase()))
          .toList();
    }
    setState(() {
      dataObject = result;
    });
    print('Сработала функция');
  }
  /// ================================================

  @override
  void initState() {
    getListObjectArchive();
    // dataObject = getObject;
    setState(() {});
    // TODO: implement initState
    super.initState();
  }

  bool openListSearchObject = false;
  bool test = true;
  bool archivedObject = false;

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return Scaffold(
      key: myOpenDrawer,
      drawer: const MyDrawer(),
      body: SafeArea(
        child: Container(
          color: ColorApp.myColorTransparent,
          child: Column(
            children: [
              ///Header ========
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: ColorApp.kPadding),
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
                    /// Кнопка Назад
                      Row(
                        children: [
                          Container(
                            width: 32.0,
                            height: 32.0,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(5.0),
                              border: Border.all(
                                  color: ColorApp.myColorGrayBorder,
                                  width: 1),
                              color: Colors.white,
                              boxShadow: const [
                                BoxShadow(
                                  color: ColorApp.myColorAvatar,
                                  blurRadius: 5,
                                ),
                              ],
                            ),
                            child: IconButton(
                                onPressed: () {
                                  setState(() {
                                    IntTest.indexScreens = 3;
                                    archivedObject =! archivedObject;
                                    myStream.add(IntTest.indexScreens);
                                  });
                                },
                                icon: const Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  color: Colors.black,
                                  size: 13.0,
                                )),
                          ),
                          const SizedBox(width: 18.0),
                        ],
                      ),
                    ///Text
                    Text('Объекты Архив',
                        style: TextStyle(
                            fontSize: size.width > 350 ? 25.0 : 18.0,
                            fontWeight: size.width > 350
                                ? FontWeight.w700
                                : FontWeight.w500)),
                    const SizedBox(width: 10.0),

                    /// Кнопка архив
                    if (test == true)
                      IconButton(
                          onPressed: () {
                            IntTest.indexScreens = 3;
                            myStream.add(IntTest.indexScreens);
                            setState(() {});
                          },
                          icon: const Icon(
                              Icons.archive_outlined,
                              size: 25.0,
                              color: ColorApp.myColorGreenAuth)),

                    ///Поиск Обьекта
                    if(test == true)
                    Row(
                      children: [
                        if (size.width > 500)
                          Row(
                            children: [
                              if (openListSearchObject == false)
                                IconButton(
                                    onPressed: () {
                                      openListSearchObject = true;
                                      setState(() {});
                                    },
                                    icon: const Icon(Icons.search,
                                        size: 25.0,
                                        color: ColorApp.myColorGray)),
                            ],
                          ),
                        if (openListSearchObject)
                          Row(
                            children: [
                              SizedBox(
                                width:
                                MediaQuery.of(context).size.width * 0.3,
                                height: 40.0,
                                child: Form(
                                  child: TextField(
                                    onChanged: (value) => _runObjectFilter(value),
                                    cursorColor: ColorApp.myColorGray,
                                    decoration: InputDecoration(
                                        contentPadding:
                                        const EdgeInsets.all(0.0),
                                        prefixIcon: IconButton(
                                            onPressed: () {},
                                            icon: const Icon(Icons.search)),
                                        suffixIcon: IconButton(
                                            onPressed: () {
                                              setState(() {
                                                dataObject = getObject;
                                              });
                                              openListSearchObject = false;
                                              setState(() {});
                                            },
                                            icon: const Icon(Icons.close)),
                                        border: const OutlineInputBorder(),
                                        focusedBorder:
                                        const OutlineInputBorder(
                                            borderSide: BorderSide(
                                                color: ColorApp
                                                    .myColorGreenAuth)),
                                        labelText: 'Поиск',
                                        labelStyle: const TextStyle(
                                            color: ColorApp.myColorGray)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    const Spacer(),
                    ///Колокольчик
                    if (size.width > 400)
                      Badge(
                        alignment: const AlignmentDirectional(21, 4),
                        backgroundColor: ColorApp.myColorRed,
                        isLabelVisible:
                        IntTest.badgeCount > 0 ? true : false,
                        label: IntTest.badgeCount < 1
                            ? const SizedBox.shrink()
                            : Text(IntTest.badgeCount.toString(),
                            style: const TextStyle(
                                fontSize: 12.0,
                                color: ColorApp.myColorWhite,
                                fontWeight: FontWeight.w500)),
                        child: IconButton(
                          onPressed: () {},
                          icon: const Icon(
                              Icons.notifications_none_outlined,
                              size: 25.0),
                        ),
                      ),
                    SizedBox(width: size.width > 500 ? 40.0 : 10.0),

                    ///Аватар Юзера
                    const MyUser(),
                  ],
                ),
              ),
              /// Окно список объектов архив
              StreamBuilder(
                  stream: myStream.stream,
                  builder: (context, ind) => Expanded(
                    child: Column(
                      children: [
                        const Padding(
                          padding: EdgeInsets.all(20.0),
                          child: TopWidgetObject()),
                        Expanded(
                            child: ListView.builder(
                                itemCount: dataObject.length,
                                itemBuilder: (context, index) {
                                  final dataObjectScreen = dataObject[index];
                                  return dataObjectScreen['is_actual'] != false
                                      ? Container()
                                      : Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20.0),
                                      child: Card(
                                      child: GestureDetector(
                                        onTap: () async {
                                          IntTest.indexObjectList = index;
                                          IntTest.pressHover = dataObjectScreen['id'];
                                          await getListObjectInfo(IntTest.pressHover);
                                          myStream.add(IntTest.indexScreens);
                                          IntTest.indexScreens = 20;
                                          setState(() {});
                                        },
                                        child: Container(
                                          decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(5.0),
                                              color: Colors.grey.shade300
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                ///Название
                                                if (size.width > 1150)
                                                  Expanded(
                                                    flex: 3,
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text(dataObjectScreen['name'] ?? '',
                                                            style: const TextStyle(
                                                                fontWeight:
                                                                FontWeight
                                                                    .w400)),
                                                      ],
                                                    ),
                                                  ),
                                                const SizedBox(width: 10.0),

                                                ///Заводской номер
                                                if (size.width > 900)
                                                  Expanded(
                                                    flex: 3,
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Text('${dataObjectScreen['factory_number']}' ?? '',
                                                            style: const TextStyle(fontWeight: FontWeight.w400)),
                                                      ],
                                                    ),
                                                  ),
                                                const SizedBox(width: 10.0),

                                                ///Компания
                                                if (size.width > 500)
                                                  Expanded(
                                                    flex: 3,
                                                    child: Row(
                                                      children: [
                                                        CircleAvatar(
                                                            foregroundImage:  apiImage(dataObjectScreen['company_id']['photo'].toString()),
                                                            backgroundImage: const AssetImage('assets/comp.jpeg')),
                                                        const SizedBox(width: 10.0),
                                                        dataObjectScreen['company_id'] == null ? const Text('') :
                                                        Expanded(
                                                          child: Text('${dataObjectScreen['company_id']['name'] ?? ''}',
                                                              style: const TextStyle(fontWeight: FontWeight.w400)),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                const SizedBox(width: 10.0),

                                                ///Адрес
                                                Expanded(
                                                  flex: 3,
                                                  child: Column(
                                                    crossAxisAlignment:
                                                    CrossAxisAlignment
                                                        .start,
                                                    children: [
                                                      Text(dataObjectScreen['address'] ?? '',
                                                          style: const TextStyle(
                                                              fontWeight:
                                                              FontWeight
                                                                  .w400)),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(width: 10.0),

                                                ///Участок
                                                if (size.width > 750)
                                                  Expanded(
                                                      flex: 3,
                                                      child: Text(dataObjectScreen['division_id']['title'] ?? '')),
                                                const SizedBox(width: 10.0),

                                                ///Тип
                                                if (size.width > 500)
                                                  Expanded(
                                                    flex: 2,
                                                    child: Container(
                                                      padding:
                                                      const EdgeInsets.all(
                                                          10.0),
                                                      decoration: BoxDecoration(
                                                        borderRadius:
                                                        BorderRadius
                                                            .circular(10),
                                                        color: ColorApp
                                                            .myColorGreen,
                                                      ),
                                                      child: Center(
                                                          child: Text(dataObjectScreen['factory_model_id']['type_object_id']['name'] ?? '',
                                                            style: const TextStyle(
                                                                fontWeight:
                                                                FontWeight.w500,
                                                                color: ColorApp
                                                                    .myColorWhite),
                                                          )),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                })),

                        const SizedBox(height: 20.0),
                      ],
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
