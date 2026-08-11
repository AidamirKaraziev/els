import 'dart:convert';
import 'package:els/helper/api_config.dart';
import 'package:flutter/foundation.dart';
import 'package:gap/gap.dart';
import 'package:els/screns/object/widgets/editing_object.dart';
import 'package:els/screns/object/widgets/object_accountFreeze.dart';
import 'package:flutter/material.dart';
import 'package:els/helper/image_picking.dart';
import '../../../helper/act.dart';
import '../../../helper/class_colors.dart';
import '../../../helper/my_map/my_map.dart';
import '../../../helper/my_user.dart';
import '../../home_page/home_page.dart';
import '../bloc/object_bloc.dart';
import 'object_screen.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

/// Окно выбранного обьекта

class ObjectPage extends StatefulWidget {
  const ObjectPage({Key? key}) : super(key: key);

  @override
  State<ObjectPage> createState() => _ObjectPageState();
}

/// Замозморозка Обьекта =============
freezingObject(int userId) async {
  await Future(() async {
    final res = await http.get(
        Uri.parse("${ApiConfig.base}/object/$userId/archive/"),
        headers: {
          "Content-Type": "application/json; charset=utf-8",
          'Authorization': 'Bearer ${IntTest.token}',
        });
    var vova = jsonDecode(utf8.decode(res.bodyBytes));
    listSelectedObject = vova;
  });
}
/// ==================================

/// Разморозка Обьекта =================
defrostingObject(int userId) async {
  await Future(() async {
    final res = await http.get(
        Uri.parse("${ApiConfig.base}/object/$userId/unzip/"),
        headers: {
          "Content-Type": "application/json; charset=utf-8",
          'Authorization': 'Bearer ${IntTest.token}',
        });
    var vova = jsonDecode(utf8.decode(res.bodyBytes));
    listSelectedObject = vova;
  });
}
/// ====================================


class _ObjectPageState extends State<ObjectPage> {

  /// Функция изменение фото Письмо о назначении =====
  var imagePathLetterOfAppointment;
  String basename(String path) {
    if (path.isNotEmpty) {
      String str = path.replaceAll(RegExp(r'(.png|.jpeg|.svg|.jpg)'), '');
      return str;
    }
    return 'noName';
  }
  Future openGalleryDocOfDestination() async {
    if (kIsWeb) {
      PickedImage? imageFile = (await pickImageFromGallery());
      if (imageFile != null) {
        imagePathLetterOfAppointment = imageFile;
        requestHttp(imageFile);
      }
    }
  }
  requestHttp(PickedImage imageFile) async {
    Map<String, String> headers = {
      "Accept": "application/json",
      "Authorization": "Bearer ${IntTest.token}"
    }; // ignore this headers if there is no authentication
    var uri = Uri.parse("${ApiConfig.base}/object/${IntTest.pressHover}/letter_of_appointment/");
    http.MultipartRequest request = http.MultipartRequest("PUT", uri);
    http.MultipartFile multipartFile = http.MultipartFile.fromBytes(
        'file', imageFile.data!,
        contentType: MediaType('image', 'jpeg'),
        filename: basename(imageFile.fileName ?? ''));
    request.files.add(multipartFile);
    request.headers.addAll(headers);
    var response = await request.send();
    response.stream.transform(utf8.decoder).listen((value) {
      Map listTestPhoto = jsonDecode(value);
      // listSelectedObject['data']['letter_of_appointment'] = listTestPhoto['data']['identity_card'];
      getListObjectInfo(IntTest.pressHover);
      MyObjectBloc().add(ObjectGetEvent());
      myStream.add(IntTest.indexScreens);
    });
  }
  /// =================================================


  /// Функция изменение фото Акт Приемки Оборудования ==
  var imagePathAPO;
  String basenameAPO(String path) {
    if (path.isNotEmpty) {
      String str = path.replaceAll(RegExp(r'(.png|.jpeg|.svg|.jpg)'), '');
      return str;
    }
    return 'noName';
  }
  Future openGalleryDocAPO() async {
    if (kIsWeb) {
      PickedImage? imageFile = (await pickImageFromGallery());
      if (imageFile != null) {
        imagePathAPO = imageFile;
        requestHttpAPO(imageFile);
      }
    }
  }
  requestHttpAPO(PickedImage imageFile) async {
    Map<String, String> headers = {
      "Accept": "application/json",
      "Authorization": "Bearer ${IntTest.token}"
    }; // ignore this headers if there is no authentication
    var uri = Uri.parse("${ApiConfig.base}/object/${IntTest.pressHover}/act_pto/");
    http.MultipartRequest request = http.MultipartRequest("PUT", uri);
    http.MultipartFile multipartFile = http.MultipartFile.fromBytes(
        'file', imageFile.data!,
        contentType: MediaType('image', 'jpeg'),
        filename: basenameAPO(imageFile.fileName ?? ''));
    request.files.add(multipartFile);
    request.headers.addAll(headers);
    var response = await request.send();
    response.stream.transform(utf8.decoder).listen((value) {
      Map listTestPhoto = jsonDecode(value);
      getListObjectInfo(IntTest.pressHover);
      MyObjectBloc().add(ObjectGetEvent());
      myStream.add(IntTest.indexScreens);
    });
  }
  /// ===================================================


  /// Механик ==============
  getMechanic() async {
    final url =
        '${ApiConfig.base}/universal-user/sort-by-role/3/';
    final res = await http.get(Uri.parse(url), headers: {
      "Content-Type": "application/json; charset=utf-8",
      'Accept': 'application/json',
      'Authorization': 'Bearer ${IntTest.token}',
    });
    var response = jsonDecode(utf8.decode(res.bodyBytes));
    getMechanicList = response['data'];
    myStream.add(IntTest.indexScreens);
    // print(mechanicList);
  }
  String? getMechanicTitle;
  List getMechanicList = [];
  /// ======================

  /// Прораб ==============
  getForeman() async {
    final url =
        '${ApiConfig.base}/universal-user/sort-by-role/2/';
    final res = await http.get(Uri.parse(url), headers: {
      "Content-Type": "application/json; charset=utf-8",
      'Accept': 'application/json',
      'Authorization': 'Bearer ${IntTest.token}',
    });
    var response = jsonDecode(utf8.decode(res.bodyBytes));
    // print(response['data'][0]['is_actual']);
    getForemanList = response['data'];
    myStream.add(IntTest.indexScreens);
    // print(mechanicList);
  }
  String? getForemanTitle;
  List getForemanList = [];
  /// =====================

  /// Функция изменение мех заморож ===========
  editingObjectMechanic(int userId) async {
    var response = await http.put(
      Uri.parse("${ApiConfig.base}/object/$userId/"),
      headers: {
        "Content-Type": "application/json; charset=utf-8",
        'Authorization': 'Bearer ${IntTest.token}',
      },
      body: json.encode(
        {
          // "foreman_id": foremanTitle,
          "mechanic_id": getMechanicTitle
        },
      ),
    );
    var vova = jsonDecode(utf8.decode(response.bodyBytes));
    MyObjectBloc().add(ObjectGetEvent());
  }
  /// =========================================

  /// Функция изменение прораба заморож =======
  editingObjectForeman(int userId) async {
    var response = await http.put(
      Uri.parse("${ApiConfig.base}/object/$userId/"),
      headers: {
        "Content-Type": "application/json; charset=utf-8",
        'Authorization': 'Bearer ${IntTest.token}',
      },
      body: json.encode(
        {
          "foreman_id": getForemanTitle,
          // "mechanic_id": getMechanicTitle
        },
      ),
    );
    var vova = jsonDecode(utf8.decode(response.bodyBytes));
    MyObjectBloc().add(ObjectGetEvent());
  }
  /// =========================================


  @override
  void initState() {
    getMechanic();
    getForeman();
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final viewObjectPage = listSelectedObject['data'];
    return StreamBuilder(
        stream: myStream.stream,
        builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
          return Scaffold(
              backgroundColor: ColorApp.myColorTransparent,
              body: SingleChildScrollView(
                child: Container(
                  color: ColorApp.myColorTransparent,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ///Header =====
                      Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: ColorApp.kPadding),
                          color: Colors.white,
                          height: 70,
                          width: double.infinity,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              /// Кнопка Назад Обьекты
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
                                            myStream.add(IntTest.indexScreens);
                                          });
                                        },
                                        icon: const Icon(
                                          Icons.arrow_back_ios_new_rounded,
                                          color: Colors.black,
                                          size: 13.0,
                                        )),
                                  ),
                                  const SizedBox(width: 30.0),
                                ],
                              ),

                              ///Text
                              Text(
                                  viewObjectPage['is_actual'] == true
                                      ? 'Обьект'
                                      : 'Обьект заморожен',
                                  style: TextStyle(
                                      fontSize: size.width > 350 ? 25.0 : 18.0,
                                      fontWeight: size.width > 350
                                          ? FontWeight.w700
                                          : FontWeight.w500)),
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
                          )),

                      /// Body ======
                      Padding(
                        padding: const EdgeInsets.all(ColorApp.kPadding),
                        child: Column(
                          children: [
                            ///Левый Блок, Правый Блок
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ///Левый Блок
                                if (size.width > 1150)
                                Expanded(
                                  flex: 3,
                                  child: Column(
                                    children: [
                                      if (size.width > 1150) const SizedBox(height: 10.0),
                                      viewObjectPage['is_actual'] == false
                                          ? Column(
                                              crossAxisAlignment: CrossAxisAlignment.stretch,
                                              children: [
                                                const Gap(10.0),
                                                ElevatedButton(
                                                    style: ElevatedButton.styleFrom(backgroundColor: ColorApp.myColorBlue),
                                                    onPressed: () async {
                                                      await defrostingObject(IntTest.pressHover);

                                                      /// ======================================================
                                                      if (listSelectedObject['data']['is_actual'] == true) {
                                                        archiveDataObject.removeAt(IntTest.indexObjectList);
                                                        dataObject.add(listSelectedObject['data']);
                                                      }
                                                      myStream.add(IntTest.indexScreens);
                                                      setState(() {});

                                                      /// ======================================================
                                                    },
                                                    child: const Text('Разморозить объект')),
                                                const Gap(2.0),
                                              ],
                                            )
                                          ///кнопки
                                          :
                                      Row(
                                              children: [
                                                const Text(
                                                  'Информация',
                                                  style: TextStyle(
                                                      fontSize: 16,
                                                      fontWeight:
                                                          FontWeight.w600),
                                                ),
                                                Row(
                                                  children: [
                                                    const Gap(10.0),

                                                    /// Изменить

                                                    if(viewObjectPage['foreman_id'] ? ['is_actual'] != false && viewObjectPage['foreman_id'] != null && viewObjectPage['mechanic_id'] ? ['is_actual'] != false && viewObjectPage['mechanic_id'] != null)
                                                    IconButton(
                                                        onPressed: () {
                                                          setState(() {
                                                            showDialog(
                                                                context:
                                                                    context,
                                                                builder:
                                                                    (context) =>
                                                                        AlertDialog(
                                                                          content:
                                                                              EditingObject(),
                                                                        ));
                                                          });
                                                        },
                                                        icon: const Icon(
                                                            Icons
                                                                .edit_outlined,
                                                            color: ColorApp
                                                                .myColorGray)),

                                                    /// Заморозить
                                                    IconButton(
                                                        onPressed: () {
                                                          setState(() async {
                                                            await showDialog(
                                                                context:
                                                                    context,
                                                                builder:
                                                                    (context) =>
                                                                        const AlertDialog(
                                                                          content:
                                                                              ObjectAccountFreeze(),
                                                                        ));
                                                            setState(() {});
                                                          });
                                                        },
                                                        icon: const Icon(
                                                            Icons
                                                                .ac_unit_outlined,
                                                            color: ColorApp
                                                                .myColorGray)),
                                                  ],
                                                ),
                                              ],
                                            ),
                                      const Gap(10.0),
                                      Container(
                                        padding: const EdgeInsets.all(20.0),
                                        height: 790,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(5.0),
                                          color:
                                              viewObjectPage['is_actual'] == true
                                                  ? ColorApp.myColorWhite
                                                  : Colors.grey[300],
                                          boxShadow: const [
                                            BoxShadow(
                                              color: Colors.grey,
                                              blurRadius: 5,
                                            ),
                                          ],
                                        ),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            /// Организация
                                            IconAndText(
                                                icon: Icons.domain,
                                                title: 'Название',
                                                subtitle:
                                                    '${viewObjectPage['name']}' ??
                                                        ''),

                                            /// Участок
                                            IconAndText(
                                                icon: Icons.signpost_outlined,
                                                title: 'Участок',
                                                subtitle: '${viewObjectPage['division_id']['title']}' ?? ''),

                                            /// Адрес
                                            IconAndText(
                                                icon: Icons
                                                    .location_on_outlined,
                                                title: 'Адрес',
                                                subtitle:
                                                    '${viewObjectPage['address']}' ??
                                                        ''),

                                            /// Тип
                                            IconAndText(
                                                icon:
                                                    Icons.looks_one_outlined,
                                                title: 'Тип',
                                                subtitle:
                                                    '${viewObjectPage['factory_model_id']['type_object_id']['name']}' ??
                                                        ''),

                                            /// Модель
                                            IconAndText(
                                                icon: Icons.elevator_outlined,
                                                title: 'Модель',
                                                subtitle:
                                                    '${viewObjectPage['factory_model_id']['model']}' ??
                                                        ''),

                                            /// Регистрационный номер
                                            IconAndText(
                                                icon: Icons.filter_1_outlined,
                                                title:
                                                    'Регистрационный номер',
                                                subtitle:
                                                    '${viewObjectPage['registration_number']}' ??
                                                        ''),

                                            /// Заводской номер
                                            IconAndText(
                                                icon: Icons.filter_1_outlined,
                                                title: 'Заводской номер',
                                                subtitle:
                                                    '${viewObjectPage['factory_number']}' ??
                                                        ''),

                                            /// Компания
                                            if (viewObjectPage['company_id'] != null)
                                              IconAndText(
                                                  icon: Icons.domain,
                                                  title: 'Компания',
                                                  subtitle:
                                                      '${viewObjectPage['company_id']['name']}' ??
                                                          ''),

                                            /// Контактное лицо
                                            if (viewObjectPage['contact_person_id'] != null)
                                              IconAndText(icon: Icons.person_outline,
                                                  title: 'Контактное лицо',
                                                  subtitle: '${viewObjectPage['contact_person_id']['name']}' ?? ''),

                                            /// Телефон
                                            if (viewObjectPage['contact_person_id'] != null)
                                            IconAndText(icon: Icons.phone_outlined,
                                                title: 'Телефон',
                                                subtitle: '+7${viewObjectPage['contact_person_id']['phone']}' ?? ''),

                                            /// Договор переделать
                                             IconAndText(
                                                icon: Icons
                                                    .insert_drive_file_outlined,
                                                title: 'Договор',
                                                subtitle: '${listSelectedObject['data']['contract_id']['title']}'),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(width: 20.0),

                                ///Правый Блок
                                Expanded(
                                  flex: 7,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const SizedBox(height: 22.0),

                                      ///Местоположение
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Местоположение',
                                            style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600),
                                          ),
                                          const SizedBox(height: 20.0),
                                          Container(
                                            height: 250,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(5.0),
                                              color: ColorApp.myColorWhite,
                                              boxShadow: const [
                                                BoxShadow(
                                                  color: Colors.grey,
                                                  blurRadius: 5,
                                                ),
                                              ],
                                            ),
                                            child: viewObjectPage['geo'] ==
                                                    'string'
                                                ? Container(
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius
                                                              .circular(5.0),
                                                      color: ColorApp
                                                          .myColorWhite,
                                                      boxShadow: const [
                                                        BoxShadow(
                                                          color: Colors.grey,
                                                          blurRadius: 5,
                                                        ),
                                                      ],
                                                    ),
                                                    child: const Center(
                                                        child: Text(
                                                            'Нет данных')),
                                                  )
                                                : const MyMapObject(),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 20.0),

                                      /// Информация
                                      if (size.width < 1150)
                                       Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Информация',
                                            style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600),
                                          ),
                                          const SizedBox(height: 20.0),
                                          size.width > 580
                                              ? Container(
                                            height: size.width > 840 ? 250.0 : 260,
                                            padding: const EdgeInsets.all(20.0),
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
                                            child: size.width > 840
                                            ? Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [

                                                /// Организация
                                                Column(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    /// Организация
                                                    IconAndText(
                                                        icon: Icons.domain,
                                                        title: 'Название',
                                                        subtitle:
                                                        '${viewObjectPage['name']}' ??
                                                            ''),

                                                    /// Участок
                                                    IconAndText(
                                                        icon: Icons.signpost_outlined,
                                                        title: 'Участок',
                                                        subtitle: '${viewObjectPage['division_id']['title']}' ?? ''),

                                                    /// Адрес
                                                    IconAndText(
                                                        icon: Icons
                                                            .location_on_outlined,
                                                        title: 'Адрес',
                                                        subtitle:
                                                        '${viewObjectPage['address']}' ??
                                                            ''),

                                                    /// Тип
                                                    IconAndText(
                                                        icon:
                                                        Icons.looks_one_outlined,
                                                        title: 'Тип',
                                                        subtitle:
                                                        '${viewObjectPage['factory_model_id']['type_object_id']['name']}' ??
                                                            ''),

                                                  ],
                                                ),

                                                /// Регистрационный номер
                                                Column(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    /// Модель
                                                    IconAndText(
                                                        icon: Icons.elevator_outlined,
                                                        title: 'Модель',
                                                        subtitle:
                                                        '${viewObjectPage['factory_model_id']['model']}' ??
                                                            ''),

                                                    /// Регистрационный номер
                                                    IconAndText(
                                                        icon: Icons.filter_1_outlined,
                                                        title:
                                                        'Регистрационный номер',
                                                        subtitle:
                                                        '${viewObjectPage['registration_number']}' ??
                                                            ''),

                                                    /// Заводской номер
                                                    IconAndText(
                                                        icon: Icons.filter_1_outlined,
                                                        title: 'Заводской номер',
                                                        subtitle:
                                                        '${viewObjectPage['factory_number']}' ??
                                                            ''),

                                                    /// Компания
                                                    if (viewObjectPage['company_id'] != null)
                                                      IconAndText(
                                                          icon: Icons.domain,
                                                          title: 'Компания',
                                                          subtitle:
                                                          '${viewObjectPage['company_id']['name']}' ??
                                                              ''),
                                                  ],
                                                ),

                                                /// Регистрационный номер
                                                Column(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [

                                                    /// Контактное лицо
                                                    if (viewObjectPage['contact_person_id'] != null)
                                                      IconAndText(icon: Icons.person_outline,
                                                          title: 'Контактное лицо',
                                                          subtitle: '${viewObjectPage['contact_person_id']['name']}' ?? ''),

                                                    /// Телефон
                                                    if (viewObjectPage['contact_person_id'] != null)
                                                      IconAndText(icon: Icons.phone_outlined,
                                                          title: 'Телефон',
                                                          subtitle: '+7${viewObjectPage['contact_person_id']['phone']}' ?? ''),

                                                    /// Договор переделать
                                                    IconAndText(
                                                        icon: Icons
                                                            .insert_drive_file_outlined,
                                                        title: 'Договор',
                                                        subtitle: '${listSelectedObject['data']['contract_id']['title']}'),
                                                  ],
                                                ),
                                              ],
                                            )
                                            : Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [

                                                /// Организация
                                                Column(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    /// Организация
                                                    IconAndText(
                                                        icon: Icons.domain,
                                                        title: 'Название',
                                                        subtitle:
                                                        '${viewObjectPage['name']}' ??
                                                            ''),

                                                    /// Участок
                                                    IconAndText(
                                                        icon: Icons.signpost_outlined,
                                                        title: 'Участок',
                                                        subtitle: '${viewObjectPage['division_id']['title']}' ?? ''),

                                                    /// Адрес
                                                    IconAndText(
                                                        icon: Icons
                                                            .location_on_outlined,
                                                        title: 'Адрес',
                                                        subtitle:
                                                        '${viewObjectPage['address']}' ??
                                                            ''),

                                                    /// Тип
                                                    IconAndText(
                                                        icon:
                                                        Icons.looks_one_outlined,
                                                        title: 'Тип',
                                                        subtitle:
                                                        '${viewObjectPage['factory_model_id']['type_object_id']['name']}' ??
                                                            ''),

                                                    /// Модель
                                                    IconAndText(
                                                        icon: Icons.elevator_outlined,
                                                        title: 'Модель',
                                                        subtitle:
                                                        '${viewObjectPage['factory_model_id']['model']}' ??
                                                            ''),

                                                    /// Регистрационный номер
                                                    IconAndText(
                                                        icon: Icons.filter_1_outlined,
                                                        title:
                                                        'Регистрационный номер',
                                                        subtitle:
                                                        '${viewObjectPage['registration_number']}' ??
                                                            ''),

                                                  ],
                                                ),

                                                /// Регистрационный номер
                                                Column(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [

                                                    /// Заводской номер
                                                    IconAndText(
                                                        icon: Icons.filter_1_outlined,
                                                        title: 'Заводской номер',
                                                        subtitle:
                                                        '${viewObjectPage['factory_number']}' ??
                                                            ''),

                                                    /// Компания
                                                    if (viewObjectPage['company_id'] != null)
                                                      IconAndText(
                                                          icon: Icons.domain,
                                                          title: 'Компания',
                                                          subtitle:
                                                          '${viewObjectPage['company_id']['name']}' ??
                                                              ''),

                                                    /// Контактное лицо
                                                    if (viewObjectPage['contact_person_id'] != null)
                                                      IconAndText(icon: Icons.person_outline,
                                                          title: 'Контактное лицо',
                                                          subtitle: '${viewObjectPage['contact_person_id']['name']}' ?? ''),

                                                    /// Телефон
                                                    if (viewObjectPage['contact_person_id'] != null)
                                                      IconAndText(icon: Icons.phone_outlined,
                                                          title: 'Телефон',
                                                          subtitle: '+7${viewObjectPage['contact_person_id']['phone']}' ?? ''),

                                                    /// Договор переделать
                                                    IconAndText(
                                                        icon: Icons
                                                            .insert_drive_file_outlined,
                                                        title: 'Договор',
                                                        subtitle: '${listSelectedObject['data']['contract_id']['title']}'),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          )
                                              : Container(
                                            padding: const EdgeInsets.all(20.0),
                                            height: 790,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                              BorderRadius.circular(5.0),
                                              color:
                                              viewObjectPage['is_actual'] == true
                                                  ? ColorApp.myColorWhite
                                                  : Colors.grey[300],
                                              boxShadow: const [
                                                BoxShadow(
                                                  color: Colors.grey,
                                                  blurRadius: 5,
                                                ),
                                              ],
                                            ),
                                            child: Column(
                                              mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                              children: [
                                                /// Организация
                                                IconAndText(
                                                    icon: Icons.domain,
                                                    title: 'Название',
                                                    subtitle:
                                                    '${viewObjectPage['name']}' ??
                                                        ''),

                                                /// Участок
                                                IconAndText(
                                                    icon: Icons.signpost_outlined,
                                                    title: 'Участок',
                                                    subtitle: '${viewObjectPage['division_id']['title']}' ?? ''),

                                                /// Адрес
                                                IconAndText(
                                                    icon: Icons
                                                        .location_on_outlined,
                                                    title: 'Адрес',
                                                    subtitle:
                                                    '${viewObjectPage['address']}' ??
                                                        ''),

                                                /// Тип
                                                IconAndText(
                                                    icon:
                                                    Icons.looks_one_outlined,
                                                    title: 'Тип',
                                                    subtitle:
                                                    '${viewObjectPage['factory_model_id']['type_object_id']['name']}' ??
                                                        ''),

                                                /// Модель
                                                IconAndText(
                                                    icon: Icons.elevator_outlined,
                                                    title: 'Модель',
                                                    subtitle:
                                                    '${viewObjectPage['factory_model_id']['model']}' ??
                                                        ''),

                                                /// Регистрационный номер
                                                IconAndText(
                                                    icon: Icons.filter_1_outlined,
                                                    title:
                                                    'Регистрационный номер',
                                                    subtitle:
                                                    '${viewObjectPage['registration_number']}' ??
                                                        ''),

                                                /// Заводской номер
                                                IconAndText(
                                                    icon: Icons.filter_1_outlined,
                                                    title: 'Заводской номер',
                                                    subtitle:
                                                    '${viewObjectPage['factory_number']}' ??
                                                        ''),

                                                /// Компания
                                                if (viewObjectPage['company_id'] != null)
                                                  IconAndText(
                                                      icon: Icons.domain,
                                                      title: 'Компания',
                                                      subtitle:
                                                      '${viewObjectPage['company_id']['name']}' ??
                                                          ''),

                                                /// Контактное лицо
                                                if (viewObjectPage['contact_person_id'] != null)
                                                  IconAndText(icon: Icons.person_outline,
                                                      title: 'Контактное лицо',
                                                      subtitle: '${viewObjectPage['contact_person_id']['name']}' ?? ''),

                                                /// Телефон
                                                if (viewObjectPage['contact_person_id'] != null)
                                                  IconAndText(icon: Icons.phone_outlined,
                                                      title: 'Телефон',
                                                      subtitle: '+7${viewObjectPage['contact_person_id']['phone']}' ?? ''),

                                                /// Договор переделать
                                                IconAndText(
                                                    icon: Icons
                                                        .insert_drive_file_outlined,
                                                    title: 'Договор',
                                                    subtitle: '${listSelectedObject['data']['contract_id']['title']}'),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),

                                      ///Ответственные
                                      Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                                'Ответственные',
                                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                                            const SizedBox(height: 20.0),
                                             Row(
                                              children: [

                                                ///Прораб
                                                listSelectedObject['data']['foreman_id'] == null
                                                    ? Expanded(child: InkWell(
                                                  onTap: (){
                                                    setState(() {
                                                      showDialog(
                                                          context: context,
                                                          builder: (context) => AlertDialog(
                                                            content: Column(
                                                              mainAxisSize: MainAxisSize.min,
                                                              children: [
                                                                SizedBox(
                                                                  height: 50.0,
                                                                  child: DropdownButtonFormField(
                                                                    value: getForemanTitle,
                                                                    hint: const Text('Прораб'),
                                                                    onChanged: (newValue1) async {
                                                                      setState(() {
                                                                        getForemanTitle = newValue1 as String?;
                                                                        getForemanTitle!.indexOf(newValue1!);
                                                                      });
                                                                    },
                                                                    validator: (newValue1) {
                                                                      if (newValue1 == null) {
                                                                        return 'Заполните поля';
                                                                      }
                                                                    },
                                                                    items: getForemanList.map((jobTitleList) {
                                                                      print(jobTitleList);
                                                                      return DropdownMenuItem(
                                                                        value: jobTitleList['id'].toString(),
                                                                        child: SizedBox(
                                                                          width: 170.0,
                                                                          child: Row(
                                                                            children: [
                                                                              Expanded(
                                                                                child: Text(jobTitleList['name'],
                                                                                    overflow: TextOverflow.ellipsis),
                                                                              ),
                                                                            ],
                                                                          ),
                                                                        ),
                                                                      );
                                                                    }).toList(),
                                                                    decoration: const InputDecoration(
                                                                        border: OutlineInputBorder()),
                                                                  ),
                                                                ),
                                                                const SizedBox(height: 10.0),
                                                                Column(
                                                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                                                  children: [
                                                                    ElevatedButton(onPressed: () async {
                                                                      await editingObjectForeman(IntTest.pressHover);
                                                                      await getListObjectInfo(IntTest.pressHover);
                                                                      myStream.add(IntTest.indexScreens);
                                                                      setState(() {});
                                                                      Navigator.pop(context);
                                                                    }, child: const Text('КНОПКА')),
                                                                  ],
                                                                ),
                                                              ],
                                                            ),
                                                          ));
                                                    });
                                                  },
                                                  child: Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                                                      height: 70,
                                                      decoration: BoxDecoration(
                                                        borderRadius: BorderRadius.circular(5.0),
                                                        color: Colors.red[300],
                                                        boxShadow: const [
                                                          BoxShadow(
                                                            color: Colors.grey,
                                                            blurRadius: 5,
                                                          ),
                                                        ],
                                                      ),
                                                      child: const Center(
                                                          child: Text('Назначить прораба',style: TextStyle(
                                                              fontSize: 16,
                                                              fontWeight: FontWeight.w600,
                                                              color: ColorApp.myColorWhite)))),
                                                ))
                                                    : Expanded(
                                                  child: Row(
                                                      children: [
                                                        listSelectedObject['data']['foreman_id']['is_actual'] == false
                                                            ? Expanded(child: InkWell(
                                                          onTap: (){
                                                            setState(() {
                                                              showDialog(
                                                                  context: context,
                                                                  builder: (context) => AlertDialog(
                                                                    content: Column(
                                                                      mainAxisSize: MainAxisSize.min,
                                                                      children: [
                                                                        SizedBox(
                                                                          height: 50.0,
                                                                          child: DropdownButtonFormField(
                                                                            value: getForemanTitle,
                                                                            hint: const Text('Прораб'),
                                                                            onChanged: (newValue1) async {
                                                                              setState(() {
                                                                                getForemanTitle = newValue1 as String?;
                                                                                getForemanTitle!.indexOf(newValue1!);
                                                                              });
                                                                            },
                                                                            validator: (newValue1) {
                                                                              if (newValue1 == null) {
                                                                                return 'Заполните поля';
                                                                              }
                                                                            },
                                                                            items: getForemanList.map((jobTitleList) {
                                                                              return DropdownMenuItem(
                                                                                value: jobTitleList['id'].toString(),
                                                                                child: SizedBox(
                                                                                  width: 170.0,
                                                                                  child: Row(
                                                                                    children: [
                                                                                      Expanded(
                                                                                        child: Text(jobTitleList['name'],
                                                                                            overflow: TextOverflow.ellipsis),
                                                                                      ),
                                                                                    ],
                                                                                  ),
                                                                                ),
                                                                              );
                                                                            }).toList(),
                                                                            decoration: const InputDecoration(
                                                                                border: OutlineInputBorder()),
                                                                          ),
                                                                        ),
                                                                        const SizedBox(height: 10.0),
                                                                        Column(
                                                                          crossAxisAlignment: CrossAxisAlignment.stretch,
                                                                          children: [
                                                                            ElevatedButton(onPressed: () async {
                                                                              await editingObjectForeman(IntTest.pressHover);
                                                                              await getListObjectInfo(IntTest.pressHover);
                                                                              myStream.add(IntTest.indexScreens);
                                                                              setState(() {});
                                                                              Navigator.pop(context);
                                                                            }, child: const Text('КНОПКА')),
                                                                          ],
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ));
                                                            });
                                                          },
                                                          child: Container(
                                                              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                                                              height: 70,
                                                              decoration: BoxDecoration(
                                                                borderRadius: BorderRadius.circular(5.0),
                                                                color: Colors.blue[200],
                                                                boxShadow: const [
                                                                  BoxShadow(
                                                                    color: Colors.grey,
                                                                    blurRadius: 5,
                                                                  ),
                                                                ],
                                                              ),
                                                              child: const Center(
                                                                  child: Text('Назначить прораба',style: TextStyle(
                                                                      fontSize: 16,
                                                                      fontWeight: FontWeight.w600,
                                                                      color: ColorApp.myColorWhite)))),
                                                        ))
                                                            : Expanded(
                                                          child: Container(
                                                            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                                                            height: 70,
                                                            decoration: BoxDecoration(
                                                              borderRadius:
                                                              BorderRadius
                                                                  .circular(5.0),
                                                              color: ColorApp
                                                                  .myColorGreenWhite,
                                                              boxShadow: const [
                                                                BoxShadow(
                                                                  color: Colors.grey,
                                                                  blurRadius: 5,
                                                                ),
                                                              ],
                                                            ),
                                                            child: Row(
                                                              children: [
                                                                const Expanded(
                                                                  child: Text(
                                                                    'Прораб',
                                                                    style: TextStyle(
                                                                        fontSize: 16,
                                                                        fontWeight:
                                                                        FontWeight
                                                                            .w600,
                                                                        color: ColorApp
                                                                            .myColorWhite),
                                                                  ),
                                                                ),
                                                                Expanded(
                                                                  child: Container(
                                                                    height: 60,
                                                                    // padding: const EdgeInsets.all(10.0),
                                                                    decoration:
                                                                    BoxDecoration(
                                                                      borderRadius:
                                                                      BorderRadius
                                                                          .circular(
                                                                          10),
                                                                      color: ColorApp
                                                                          .myColorGrayShadow,
                                                                    ),
                                                                    child: viewObjectPage['foreman_id'] == null
                                                                        ? const Expanded(
                                                                        child: Text(''))
                                                                        :  Row(
                                                                      children: [
                                                                        Padding(
                                                                            padding: const EdgeInsets
                                                                                .symmetric(
                                                                                horizontal:
                                                                                10.0),
                                                                            child: CircleAvatar(
                                                                                backgroundImage: const NetworkImage('assets/user.png'),
                                                                                foregroundImage: NetworkImage('${ApiConfig.scheme}://${viewObjectPage['foreman_id']['photo']}'))),
                                                                        Expanded(
                                                                            child: Text(
                                                                                '${viewObjectPage['foreman_id']['name']}',
                                                                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                  ),
                                                ),
                                                const SizedBox(width: 20.0),

                                                /// Механик
                                                listSelectedObject['data']['mechanic_id'] == null
                                                    ? Expanded(child: InkWell(
                                                  onTap: (){
                                                    setState(() {
                                                      showDialog(
                                                          context: context,
                                                          builder: (context) => AlertDialog(
                                                            content: Column(
                                                              mainAxisSize: MainAxisSize.min,
                                                              children: [
                                                                SizedBox(
                                                                  height: 50.0,
                                                                  child: DropdownButtonFormField(
                                                                    value: getMechanicTitle,
                                                                    hint: const Text('Механик'),
                                                                    onChanged: (newValue1) async {
                                                                      setState(() {
                                                                        getMechanicTitle = newValue1 as String?;
                                                                        getMechanicTitle!.indexOf(newValue1!);
                                                                      });
                                                                    },
                                                                    validator: (newValue1) {
                                                                      if (newValue1 == null) {
                                                                        return 'Заполните поля';
                                                                      }
                                                                    },
                                                                    items: getMechanicList.map((jobTitleList) {
                                                                      print(getMechanicList);
                                                                      return DropdownMenuItem(
                                                                        value: jobTitleList['id'].toString(),
                                                                        child: SizedBox(
                                                                          width: 170.0,
                                                                          child: Row(
                                                                            children: [
                                                                              Expanded(
                                                                                child: Text(jobTitleList['name']),
                                                                              ),
                                                                            ],
                                                                          ),
                                                                        ),
                                                                      );
                                                                    }).toList(),
                                                                    decoration: const InputDecoration(
                                                                        border: OutlineInputBorder()),
                                                                  ),
                                                                ),
                                                                const SizedBox(height: 10.0),
                                                                Column(
                                                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                                                  children: [
                                                                    ElevatedButton(onPressed: () async {
                                                                      await editingObjectMechanic(IntTest.pressHover);
                                                                      await getListObjectInfo(IntTest.pressHover);
                                                                      MyObjectBloc().add(ObjectGetEvent());
                                                                      myStream.add(IntTest.indexScreens);
                                                                      setState(() {});
                                                                      Navigator.pop(context);
                                                                    }, child: const Text('КНОПКА')),
                                                                  ],
                                                                ),
                                                              ],
                                                            ),
                                                          ));
                                                    });
                                                  },
                                                  child: Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                                                      height: 70,
                                                      decoration: BoxDecoration(
                                                        borderRadius: BorderRadius.circular(5.0),
                                                        color: Colors.red[300],
                                                        boxShadow: const [
                                                          BoxShadow(
                                                            color: Colors.grey,
                                                            blurRadius: 5,
                                                          ),
                                                        ],
                                                      ),
                                                      child: const Center(
                                                          child: Text('Назначить механика',style: TextStyle(
                                                              fontSize: 16,
                                                              fontWeight: FontWeight.w600,
                                                              color: ColorApp.myColorWhite)))),
                                                ))
                                                    : Expanded(
                                                      child: Row(
                                                        children: [
                                                          listSelectedObject['data']['mechanic_id']['is_actual'] == false
                                                              ? Expanded(child: InkWell(
                                                            onTap: (){
                                                              setState(() {
                                                                showDialog(
                                                                    context: context,
                                                                    builder: (context) => AlertDialog(
                                                                      content: Column(
                                                                        mainAxisSize: MainAxisSize.min,
                                                                        children: [
                                                                          SizedBox(
                                                                            height: 50.0,
                                                                            child: DropdownButtonFormField(
                                                                              value: getMechanicTitle,
                                                                              hint: const Text('Механик'),
                                                                              onChanged: (newValue1) async {
                                                                                setState(() {
                                                                                  getMechanicTitle = newValue1 as String?;
                                                                                  getMechanicTitle!.indexOf(newValue1!);
                                                                                });
                                                                              },
                                                                              validator: (newValue1) {
                                                                                if (newValue1 == null) {
                                                                                  return 'Заполните поля';
                                                                                }
                                                                              },
                                                                              items: getMechanicList.map((jobTitleList) {
                                                                                return DropdownMenuItem(
                                                                                  value: jobTitleList['id'].toString(),
                                                                                  child: SizedBox(
                                                                                    width: 170.0,
                                                                                    child: Row(
                                                                                      children: [
                                                                                        Expanded(
                                                                                          child: Text(jobTitleList['name'],
                                                                                              overflow: TextOverflow.ellipsis),
                                                                                        ),
                                                                                      ],
                                                                                    ),
                                                                                  ),
                                                                                );
                                                                              }).toList(),
                                                                              decoration: const InputDecoration(
                                                                                  border: OutlineInputBorder()),
                                                                            ),
                                                                          ),
                                                                          const SizedBox(height: 10.0),
                                                                          Column(
                                                                            crossAxisAlignment: CrossAxisAlignment.stretch,
                                                                            children: [
                                                                              ElevatedButton(onPressed: () async {
                                                                                await editingObjectMechanic(IntTest.pressHover);
                                                                                await getListObjectInfo(IntTest.pressHover);
                                                                                myStream.add(IntTest.indexScreens);
                                                                                setState(() {});
                                                                                Navigator.pop(context);
                                                                              }, child: const Text('КНОПКА')),
                                                                            ],
                                                                          ),
                                                                        ],
                                                                      ),
                                                                    ));
                                                              });
                                                            },
                                                            child: Container(
                                                                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                                                                height: 70,
                                                                decoration: BoxDecoration(
                                                                  borderRadius: BorderRadius.circular(5.0),
                                                                  color: Colors.blue[200],
                                                                  boxShadow: const [
                                                                    BoxShadow(
                                                                      color: Colors.grey,
                                                                      blurRadius: 5,
                                                                    ),
                                                                  ],
                                                                ),
                                                                child: const Center(
                                                                    child: Text('Назначить механика',style: TextStyle(
                                                                        fontSize: 16,
                                                                        fontWeight: FontWeight.w600,
                                                                        color: ColorApp.myColorWhite)))),
                                                          ))
                                                              : Expanded(
                                                            child: Container(
                                                              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                                                              height: 70,
                                                              decoration: BoxDecoration(
                                                                borderRadius:
                                                                BorderRadius.circular(5.0),
                                                                color: ColorApp.myColorGreenWhite,
                                                                boxShadow: const [
                                                                  BoxShadow(
                                                                    color: Colors.grey,
                                                                    blurRadius: 5,
                                                                  ),
                                                                ],
                                                              ),
                                                              child: Row(
                                                                children: [
                                                                  const Expanded(
                                                                    child: Text(
                                                                      'Механик',
                                                                      style: TextStyle(
                                                                          fontSize: 16,
                                                                          fontWeight: FontWeight.w600,
                                                                          color: ColorApp.myColorWhite),
                                                                    ),
                                                                  ),
                                                                  Expanded(
                                                                    child: Container(
                                                                      height: 60,
                                                                      // padding: const EdgeInsets.all(10.0),
                                                                      decoration: BoxDecoration(
                                                                        borderRadius: BorderRadius.circular(10),
                                                                        color: ColorApp.myColorGrayShadow,
                                                                      ),
                                                                      child: viewObjectPage['mechanic_id'] == null
                                                                          ? const Expanded(child: Text(''))
                                                                          :  Row(
                                                                        children: [
                                                                          Padding(
                                                                              padding: const EdgeInsets
                                                                                  .symmetric(
                                                                                  horizontal:
                                                                                  10.0),
                                                                              child: CircleAvatar(
                                                                                  backgroundImage: const NetworkImage('assets/user.png'),
                                                                                  foregroundImage: NetworkImage('${ApiConfig.scheme}://${viewObjectPage['mechanic_id']['photo']}'))),
                                                                          Expanded(child:
                                                                          Text('${viewObjectPage['mechanic_id']['name']}',
                                                                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
                                                                        ],
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                            ),
                                                          ),

                                                        ]),
                                                    ),
                                              ]),
                                          ]),
                                      const SizedBox(height: 20.0),

                                      ///Об объекте
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Об объекте',
                                            style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600),
                                          ),
                                          const SizedBox(height: 20.0),
                                          size.width > 580
                                              ? Container(
                                            padding: const EdgeInsets.all(20.0),
                                            height: 180,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(5.0),
                                              color: viewObjectPage[
                                                          'is_actual'] ==
                                                      true
                                                  ? ColorApp.myColorWhite
                                                  : Colors.grey[300],
                                              boxShadow: const [
                                                BoxShadow(
                                                  color: Colors.grey,
                                                  blurRadius: 5,
                                                ),
                                              ],
                                            ),
                                            child: size.width > 840
                                            ? Column(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                /// Высота подъема, Количество остановок, Грузоподъемность
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    /// Высота подъема
                                                    Expanded(
                                                        child: IconAndText(
                                                            icon:
                                                                Icons.height,
                                                            title:
                                                                'Высота подъема',
                                                            subtitle: viewObjectPage[
                                                                        'lifting_heights']
                                                                    .toString() ??
                                                                '')),

                                                    /// Количество остановок
                                                    Expanded(
                                                        child: IconAndText(
                                                            icon: Icons
                                                                .elevator_outlined,
                                                            title:
                                                                'Количество остановок',
                                                            subtitle: viewObjectPage[
                                                                        'number_of_stops']
                                                                    .toString() ??
                                                                '')),

                                                    /// Грузоподъемность
                                                    Expanded(
                                                        child: IconAndText(
                                                            icon: Icons
                                                                .scale_outlined,
                                                            title:
                                                                'Грузоподъемность',
                                                            subtitle: viewObjectPage[
                                                                        'load_capacity']
                                                                    .toString() ??
                                                                '')),
                                                  ],
                                                ),

                                                /// Ширина, Стоимость ТО с НДС, Стоимость ТО без НДС
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    /// Ширина
                                                    // Expanded(
                                                    //     child: IconAndText(
                                                    //         icon: Icons
                                                    //             .sync_alt_rounded,
                                                    //         title: 'Ширина',
                                                    //         subtitle: viewObjectPage['width'].toString() ?? '')),

                                                    /// Стоимость ТО с НДС
                                                    Expanded(
                                                        child: IconAndText(
                                                            icon: Icons
                                                                .currency_ruble_outlined,
                                                            title:
                                                                'Стоимость ТО с НДС',
                                                            subtitle: viewObjectPage[
                                                                        'cost_nds']
                                                                    .toString() ??
                                                                '')),

                                                    /// Стоимость ТО без НДС
                                                    Expanded(
                                                        child: IconAndText(
                                                            icon: Icons
                                                                .currency_ruble_outlined,
                                                            title:
                                                                'Стоимость ТО без НДС',
                                                            subtitle: viewObjectPage[
                                                                        'cost_no_nds']
                                                                    .toString() ??
                                                                '')),

                                                    /// Для красоты
                                                    Expanded(
                                                        child: Container()),
                                                  ],
                                                ),
                                              ],
                                            )
                                            : Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                /// Высота подъема, Количество остановок, Грузоподъемность
                                                Column(
                                                  mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                                  children: [
                                                    /// Высота подъема
                                                    IconAndText(
                                                        icon:
                                                        Icons.height,
                                                        title:
                                                        'Высота подъема',
                                                        subtitle: viewObjectPage[
                                                        'lifting_heights']
                                                            .toString() ??
                                                            ''),

                                                    /// Количество остановок
                                                    IconAndText(
                                                        icon: Icons
                                                            .elevator_outlined,
                                                        title:
                                                        'Количество остановок',
                                                        subtitle: viewObjectPage[
                                                        'number_of_stops']
                                                            .toString() ??
                                                            ''),

                                                    /// Грузоподъемность
                                                    IconAndText(
                                                        icon: Icons
                                                            .scale_outlined,
                                                        title:
                                                        'Грузоподъемность',
                                                        subtitle: viewObjectPage[
                                                        'load_capacity']
                                                            .toString() ??
                                                            ''),
                                                  ],
                                                ),

                                                /// Ширина, Стоимость ТО с НДС, Стоимость ТО без НДС
                                                Column(
                                                  mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                                  children: [
                                                    /// Стоимость ТО с НДС
                                                    IconAndText(
                                                        icon: Icons
                                                            .currency_ruble_outlined,
                                                        title:
                                                        'Стоимость ТО с НДС',
                                                        subtitle: viewObjectPage[
                                                        'cost_nds']
                                                            .toString() ??
                                                            ''),

                                                    /// Стоимость ТО без НДС
                                                    IconAndText(
                                                        icon: Icons
                                                            .currency_ruble_outlined,
                                                        title:
                                                        'Стоимость ТО без НДС',
                                                        subtitle: viewObjectPage[
                                                        'cost_no_nds']
                                                            .toString() ??
                                                            ''),

                                                    /// Для красоты
                                                    Container(),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          )
                                              : Container(
                                            padding: const EdgeInsets.all(20.0),
                                            height: 300,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                              BorderRadius.circular(5.0),
                                              color: viewObjectPage[
                                              'is_actual'] ==
                                                  true
                                                  ? ColorApp.myColorWhite
                                                  : Colors.grey[300],
                                              boxShadow: const [
                                                BoxShadow(
                                                  color: Colors.grey,
                                                  blurRadius: 5,
                                                ),
                                              ],
                                            ),
                                            child: Column(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                /// Высота подъема, Количество остановок, Грузоподъемность
                                                IconAndText(
                                                    icon:
                                                    Icons.height,
                                                    title:
                                                    'Высота подъема',
                                                    subtitle: viewObjectPage[
                                                    'lifting_heights']
                                                        .toString() ??
                                                        ''),

                                                /// Количество остановок
                                                IconAndText(
                                                    icon: Icons
                                                        .elevator_outlined,
                                                    title:
                                                    'Количество остановок',
                                                    subtitle: viewObjectPage[
                                                    'number_of_stops']
                                                        .toString() ??
                                                        ''),

                                                /// Грузоподъемность
                                                IconAndText(
                                                    icon: Icons
                                                        .scale_outlined,
                                                    title:
                                                    'Грузоподъемность',
                                                    subtitle: viewObjectPage[
                                                    'load_capacity']
                                                        .toString() ??
                                                        ''),

                                                /// Ширина, Стоимость ТО с НДС, Стоимость ТО без НДС
                                                IconAndText(
                                                    icon: Icons
                                                        .currency_ruble_outlined,
                                                    title:
                                                    'Стоимость ТО с НДС',
                                                    subtitle: viewObjectPage[
                                                    'cost_nds']
                                                        .toString() ??
                                                        ''),

                                                /// Стоимость ТО без НДС
                                                IconAndText(
                                                    icon: Icons
                                                        .currency_ruble_outlined,
                                                    title:
                                                    'Стоимость ТО без НДС',
                                                    subtitle: viewObjectPage[
                                                    'cost_no_nds']
                                                        .toString() ??
                                                        ''),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 20.0),

                                      ///Инспекции
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          /// Инспекции
                                          const Text(
                                            'Инспекции',
                                            style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600),
                                          ),
                                          const SizedBox(height: 20.0),
                                          Container(
                                            padding: const EdgeInsets.all(20.0),
                                            height: size.width > 580 ? 115.0 : 130.0,
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(5.0),
                                              color: viewObjectPage['is_actual'] == true
                                                  ? ColorApp.myColorWhite
                                                  : Colors.grey[300],
                                              boxShadow: const [
                                                BoxShadow(
                                                  color: Colors.grey,
                                                  blurRadius: 5,
                                                ),
                                              ],
                                            ),
                                            child: size.width > 580
                                                ? Row(
                                              crossAxisAlignment: CrossAxisAlignment.center,
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                /// Дата полного ТО
                                                // SizedBox(
                                                //     height: 40,
                                                //     child: IconAndText(
                                                //         icon: Icons.calendar_month_outlined,
                                                //         title: 'Дата полного ТО',
                                                //         subtitle: '${DateFormat('dd -MM-yyyy').format(DateTime.fromMillisecondsSinceEpoch(viewObjectPage['date_inspection'] * 1000))}',
                                                //         // '${viewObjectPage['date_inspection']}')
                                                // )),
                                                /// DateFormat('dd -MM-yyyy').format(DateTime.fromMillisecondsSinceEpoch(viewObjectPage['date_inspection'] * 1000))
                                                /// Дата планового ТО
                                                SizedBox(
                                                    height: 40,
                                                    child: IconAndText(
                                                        icon: Icons.calendar_month_outlined,
                                                        title: 'Дата планового ТО',
                                                        subtitle:
                                                        '${viewObjectPage['planned_inspection']}'
                                                    )),

                                                /// Период ТО
                                                SizedBox(
                                                    height: 40,
                                                    child: IconAndText(
                                                        icon: Icons.calendar_month_outlined,
                                                        title: 'Период ТО',
                                                        subtitle: '${viewObjectPage['period_inspection']}')),
                                              ],
                                            )
                                                : Column(
                                              crossAxisAlignment: CrossAxisAlignment.center,
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                SizedBox(
                                                    height: 40,
                                                    child: IconAndText(
                                                        icon: Icons.calendar_month_outlined,
                                                        title: 'Дата планового ТО',
                                                        subtitle:
                                                        '${viewObjectPage['planned_inspection']}'
                                                    )),

                                                /// Период ТО
                                                SizedBox(
                                                    height: 40,
                                                    child: IconAndText(
                                                        icon: Icons.calendar_month_outlined,
                                                        title: 'Период ТО',
                                                        subtitle: '${viewObjectPage['period_inspection']}')),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20.0),

                            ///Документы
                            if(size.width > 840)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Документы',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 10.0),
                                  Container(
                                    padding: const EdgeInsets.all(20.0),
                                    // height: 250,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(5.0),
                                      color: viewObjectPage['is_actual'] == true
                                          ? ColorApp.myColorWhite
                                          : Colors.grey[300],
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Colors.grey,
                                          blurRadius: 5,
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [

                                        /// Письмо о назначении
                                        Row(
                                          children: [
                                            const Expanded(
                                              flex: 2,
                                              child: Column(
                                                crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                                children: [
                                                  Text('Документ',
                                                      style: TextStyle(
                                                          fontWeight:
                                                          FontWeight.w300,
                                                          fontSize: 12)),
                                                  SizedBox(height: 5.0),
                                                  Text('Письмо о назначении',
                                                      style: TextStyle(
                                                          fontWeight:
                                                          FontWeight.w600,
                                                          fontSize: 15)),
                                                ],
                                              ),
                                            ),
                                            Expanded(
                                              flex: 8,
                                              child: Container(
                                                padding:
                                                const EdgeInsets.symmetric(horizontal: 10.0),
                                                height: 50.0,
                                                decoration: BoxDecoration(
                                                    borderRadius: BorderRadius.circular(5.0),
                                                    border: Border.all(width: 1, color: ColorApp.myColorAvatar)),
                                                child: Row(
                                                  children: [
                                                    listSelectedObject['data']['letter_of_appointment'] == null ?
                                                    InkWell(
                                                      onTap: () async {
                                                        // openGalleryDocOfDestination();
                                                        // await getListObjectInfo(IntTest.pressHover);
                                                        // // MyObjectBloc().add(ObjectGetEvent());
                                                        // myStream.add(IntTest.indexScreens);
                                                        // setState(() {
                                                        //   showDialog(
                                                        //       context: context,
                                                        //       builder: (context) =>
                                                        //           AlertDialog(
                                                        //             content: Stack(children: [
                                                        //               Image.network('${ApiConfig.scheme}://${listSelectedObject['data']['letter_of_appointment']}',fit: BoxFit.cover),
                                                        //               Positioned(
                                                        //                   top: 0,
                                                        //                   right: 0,
                                                        //                   child: IconButton(onPressed: (){Navigator.pop(context);},icon: const Icon(Icons.close,color: Colors.red))),
                                                        //
                                                        //             ]),
                                                        //           ));
                                                        // });
                                                        ///
                                                        setState(() {
                                                          showDialog(
                                                              context: context,
                                                              builder: (context) =>
                                                                  const AlertDialog(
                                                                    content:
                                                                        AcceptanceCertificate(),
                                                                  )).then(
                                                              (value) =>
                                                                  setState(
                                                                      () {}));
                                                        });
                                                        ///
                                                      },
                                                      child: Container(
                                                        width: 30.0,
                                                        height: 30.0,
                                                        decoration: BoxDecoration(
                                                          borderRadius:
                                                          BorderRadius
                                                              .circular(
                                                              5.0),
                                                          color: ColorApp
                                                              .myColorGreen,
                                                        ),
                                                        child: const Icon(
                                                          Icons.add_a_photo_outlined,
                                                          color: ColorApp.myColorWhite,
                                                        ),
                                                      ),
                                                    ) : const Icon(Icons.picture_as_pdf_outlined, color: ColorApp.myColorGreen),
                                                    const SizedBox(width: 10.0),
                                                    Text(
                                                      listSelectedObject['data']['letter_of_appointment'] != null ? 'doc28338_ndc.pdf' : 'Добавте фото',
                                                      style: const TextStyle(
                                                          fontSize: 16,
                                                          fontWeight:
                                                          FontWeight.w600),
                                                    ),
                                                    const Spacer(),
                                                    /// Развернуть Изменить
                                                    if( listSelectedObject['data']['letter_of_appointment'] != null)
                                                      Row(
                                                        children: [
                                                          /// Развернуть
                                                          InkWell(
                                                            onTap: () async {
                                                              setState(() {
                                                                showDialog(
                                                                    context: context,
                                                                    builder: (context) =>
                                                                        AlertDialog(
                                                                          content: Stack(children: [
                                                                            Image.network('${ApiConfig.scheme}://${listSelectedObject['data']['letter_of_appointment']}',fit: BoxFit.cover),
                                                                            Positioned(
                                                                                top: 0,
                                                                                right: 0,
                                                                                child: IconButton(onPressed: (){Navigator.pop(context);},icon: const Icon(Icons.close,color: Colors.red))),

                                                                          ]),
                                                                        ));
                                                              });
                                                              // setState(() {
                                                              //   showDialog(
                                                              //       context: context,
                                                              //       builder: (context) =>
                                                              //           const AlertDialog(
                                                              //             content:
                                                              //                 AcceptanceCertificate(),
                                                              //           )).then(
                                                              //       (value) =>
                                                              //           setState(
                                                              //               () {}));
                                                              // });
                                                            },
                                                            child: Container(
                                                              width: 30.0,
                                                              height: 30.0,
                                                              decoration:
                                                              BoxDecoration(
                                                                borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                    5.0),
                                                                color: ColorApp
                                                                    .myColorGreen,
                                                              ),
                                                              child: const Icon(
                                                                Icons
                                                                    .open_in_full_outlined,
                                                                color: ColorApp
                                                                    .myColorWhite,
                                                              ),
                                                            ),
                                                          ),
                                                          const SizedBox(width: 10.0),
                                                          /// Изменить
                                                          InkWell(
                                                            onTap: () async {
                                                              openGalleryDocOfDestination();
                                                              await getListObjectInfo(IntTest.pressHover);
                                                              myStream.add(IntTest.indexScreens);
                                                              setState(() {});
                                                            },

                                                            child: Container(
                                                              width: 30.0,
                                                              height: 30.0,
                                                              decoration: BoxDecoration(
                                                                borderRadius: BorderRadius.circular(5.0),
                                                                color: ColorApp.myColorGreen,
                                                              ),
                                                              child: const Icon(
                                                                Icons.edit_outlined,
                                                                color: ColorApp.myColorWhite,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      )

                                                    // const SizedBox(width: 10.0),
                                                    // Container(
                                                    //   width: 30.0,
                                                    //   height: 30.0,
                                                    //   decoration: BoxDecoration(
                                                    //     borderRadius:
                                                    //         BorderRadius
                                                    //             .circular(5.0),
                                                    //     color:
                                                    //         ColorApp.myColorRed,
                                                    //   ),
                                                    //   child: const Icon(
                                                    //     Icons.delete_outline,
                                                    //     color: ColorApp
                                                    //         .myColorWhite,
                                                    //   ),
                                                    // ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),


                                        const SizedBox(height: 20.0),
                                        /// Сертификат
                                        // Row(
                                        //   children: [
                                        //     Expanded(
                                        //       flex: 2,
                                        //       child: Column(
                                        //         crossAxisAlignment:
                                        //             CrossAxisAlignment.start,
                                        //         children: const [
                                        //           Text('Документ',
                                        //               style: TextStyle(
                                        //                   fontWeight:
                                        //                       FontWeight.w300,
                                        //                   fontSize: 12)),
                                        //           SizedBox(height: 5.0),
                                        //           Text('Сертификат',
                                        //               style: TextStyle(
                                        //                   fontWeight:
                                        //                       FontWeight.w600,
                                        //                   fontSize: 15)),
                                        //         ],
                                        //       ),
                                        //     ),
                                        //     Expanded(
                                        //       flex: 8,
                                        //       child: Container(
                                        //         padding:
                                        //             const EdgeInsets.symmetric(
                                        //                 horizontal: 10.0),
                                        //         height: 50.0,
                                        //         decoration: BoxDecoration(
                                        //             borderRadius:
                                        //                 BorderRadius.circular(
                                        //                     5.0),
                                        //             border: Border.all(
                                        //                 width: 1,
                                        //                 color: ColorApp
                                        //                     .myColorAvatar)),
                                        //         child: Row(
                                        //           children: [
                                        //             const Icon(
                                        //                 Icons
                                        //                     .picture_as_pdf_outlined,
                                        //                 color: ColorApp
                                        //                     .myColorGreen),
                                        //             const SizedBox(width: 10.0),
                                        //             const Text(
                                        //               'doc28338_ndc.pdf',
                                        //               style: TextStyle(
                                        //                   fontSize: 16,
                                        //                   fontWeight:
                                        //                       FontWeight.w600),
                                        //             ),
                                        //             const Spacer(),
                                        //             InkWell(
                                        //               onTap: () {
                                        //                 setState(() {
                                        //                   showDialog(
                                        //                       context: context,
                                        //                       builder: (context) =>
                                        //                           const AlertDialog(
                                        //                             content:
                                        //                                 LetterOfAppointment(),
                                        //                           )).then(
                                        //                       (value) =>
                                        //                           setState(
                                        //                               () {}));
                                        //                 });
                                        //               },
                                        //               child: Container(
                                        //                 width: 30.0,
                                        //                 height: 30.0,
                                        //                 decoration:
                                        //                     BoxDecoration(
                                        //                   borderRadius:
                                        //                       BorderRadius
                                        //                           .circular(
                                        //                               5.0),
                                        //                   color: ColorApp
                                        //                       .myColorGreen,
                                        //                 ),
                                        //                 child: const Icon(
                                        //                   Icons
                                        //                       .open_in_full_outlined,
                                        //                   color: ColorApp
                                        //                       .myColorWhite,
                                        //                 ),
                                        //               ),
                                        //             ),
                                        //             const SizedBox(width: 10.0),
                                        //             Container(
                                        //               width: 30.0,
                                        //               height: 30.0,
                                        //               decoration: BoxDecoration(
                                        //                 borderRadius:
                                        //                     BorderRadius
                                        //                         .circular(5.0),
                                        //                 color: ColorApp
                                        //                     .myColorGreen,
                                        //               ),
                                        //               child: const Icon(
                                        //                 Icons
                                        //                     .download_for_offline_outlined,
                                        //                 color: ColorApp
                                        //                     .myColorWhite,
                                        //               ),
                                        //             ),
                                        //             const SizedBox(width: 10.0),
                                        //             Container(
                                        //               width: 30.0,
                                        //               height: 30.0,
                                        //               decoration: BoxDecoration(
                                        //                 borderRadius:
                                        //                     BorderRadius
                                        //                         .circular(5.0),
                                        //                 color:
                                        //                     ColorApp.myColorRed,
                                        //               ),
                                        //               child: const Icon(
                                        //                 Icons.delete_outline,
                                        //                 color: ColorApp
                                        //                     .myColorWhite,
                                        //               ),
                                        //             ),
                                        //           ],
                                        //         ),
                                        //       ),
                                        //     ),
                                        //   ],
                                        // ),

                                        /// Акт
                                        Row(
                                          children: [
                                            const Expanded(
                                              flex: 2,
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text('Документ',
                                                      style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.w300,
                                                          fontSize: 12)),
                                                  SizedBox(height: 5.0),
                                                  Text('Акт',
                                                      style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          fontSize: 15)),
                                                ],
                                              ),
                                            ),
                                            Expanded(
                                              flex: 8,
                                              child: Container(
                                                padding:
                                                const EdgeInsets.symmetric(horizontal: 10.0),
                                                height: 50.0,
                                                decoration: BoxDecoration(
                                                    borderRadius: BorderRadius.circular(5.0),
                                                    border: Border.all(width: 1, color: ColorApp.myColorAvatar)),
                                                child: Row(
                                                  children: [
                                                    listSelectedObject['data']['act_pto'] == null ?
                                                    InkWell(
                                                      onTap: () async {
                                                        // openGalleryDocAPO();
                                                        // await getListObjectInfo(IntTest.pressHover);
                                                        // // MyObjectBloc().add(ObjectGetEvent());
                                                        // myStream.add(IntTest.indexScreens);
                                                        // setState(() {
                                                        //   showDialog(
                                                        //       context: context,
                                                        //       builder: (context) =>
                                                        //           AlertDialog(
                                                        //             content: Stack(children: [
                                                        //               Image.network('${ApiConfig.scheme}://${listSelectedObject['data']['letter_of_appointment']}',fit: BoxFit.cover),
                                                        //               Positioned(
                                                        //                   top: 0,
                                                        //                   right: 0,
                                                        //                   child: IconButton(onPressed: (){Navigator.pop(context);},icon: const Icon(Icons.close,color: Colors.red))),
                                                        //
                                                        //             ]),
                                                        //           ));
                                                        // });
                                                        ///
                                                        setState(() {
                                                          showDialog(
                                                              context: context,
                                                              builder: (context) =>
                                                                  const AlertDialog(
                                                                    content:
                                                                        AcceptanceCertificate(),
                                                                  )).then(
                                                              (value) =>
                                                                  setState(
                                                                      () {}));
                                                        });
                                                        ///
                                                      },
                                                      child: Container(
                                                        width: 30.0,
                                                        height: 30.0,
                                                        decoration: BoxDecoration(
                                                          borderRadius:
                                                          BorderRadius
                                                              .circular(
                                                              5.0),
                                                          color: ColorApp
                                                              .myColorGreen,
                                                        ),
                                                        child: const Icon(
                                                          Icons.add_a_photo_outlined,
                                                          color: ColorApp.myColorWhite,
                                                        ),
                                                      ),
                                                    ) : const Icon(Icons.picture_as_pdf_outlined, color: ColorApp.myColorGreen),
                                                    const SizedBox(width: 10.0),
                                                    Text(
                                                      listSelectedObject['data']['letter_of_appointment'] != null ? 'doc28338_ndc.pdf' : 'Добавте фото',
                                                      style: const TextStyle(
                                                          fontSize: 16,
                                                          fontWeight:
                                                          FontWeight.w600),
                                                    ),
                                                    const Spacer(),
                                                    /// Развернуть Изменить
                                                    if( listSelectedObject['data']['act_pto'] != null)
                                                      Row(
                                                        children: [
                                                          /// Развернуть
                                                          InkWell(
                                                            onTap: () async {
                                                              setState(() {
                                                                showDialog(
                                                                    context: context,
                                                                    builder: (context) =>
                                                                        AlertDialog(
                                                                          content: Stack(children: [
                                                                            Image.network('${ApiConfig.scheme}://${listSelectedObject['data']['act_pto']}',fit: BoxFit.cover),
                                                                            Positioned(
                                                                                top: 0,
                                                                                right: 0,
                                                                                child: IconButton(onPressed: (){Navigator.pop(context);},icon: const Icon(Icons.close,color: Colors.red))),

                                                                          ]),
                                                                        ));
                                                              });

                                                            },
                                                            child: Container(
                                                              width: 30.0,
                                                              height: 30.0,
                                                              decoration:
                                                              BoxDecoration(
                                                                borderRadius: BorderRadius.circular(5.0),
                                                                color: ColorApp.myColorGreen),
                                                              child: const Icon(Icons.open_in_full_outlined, color: ColorApp.myColorWhite),
                                                            ),
                                                          ),
                                                          const SizedBox(width: 10.0),
                                                          /// Изменить
                                                          InkWell(
                                                            onTap: () async {
                                                              openGalleryDocAPO();
                                                              await getListObjectInfo(IntTest.pressHover);
                                                              myStream.add(IntTest.indexScreens);
                                                              setState(() {});
                                                            },

                                                            child: Container(
                                                              width: 30.0,
                                                              height: 30.0,
                                                              decoration: BoxDecoration(
                                                                borderRadius: BorderRadius.circular(5.0),
                                                                color: ColorApp.myColorGreen,
                                                              ),
                                                              child: const Icon(
                                                                Icons.edit_outlined,
                                                                color: ColorApp.myColorWhite,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      )

                                                    // const SizedBox(width: 10.0),
                                                    // Container(
                                                    //   width: 30.0,
                                                    //   height: 30.0,
                                                    //   decoration: BoxDecoration(
                                                    //     borderRadius:
                                                    //         BorderRadius
                                                    //             .circular(5.0),
                                                    //     color:
                                                    //         ColorApp.myColorRed,
                                                    //   ),
                                                    //   child: const Icon(
                                                    //     Icons.delete_outline,
                                                    //     color: ColorApp
                                                    //         .myColorWhite,
                                                    //   ),
                                                    // ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                      /// ===========
                    ],
                  ),
                ),
              ));
        });
  }
}

class IconAndText extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const IconAndText({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          // Icons.add_chart_outlined,
          size: 25.0,
          color: ColorApp.myColorGreen,
        ),
        const SizedBox(width: 30.0),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style:
                    const TextStyle(fontWeight: FontWeight.w300, fontSize: 12)),
            const SizedBox(height: 5.0),
            SizedBox(
              width: 180.0,
              child: Text(subtitle,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 15)),
            ),
          ],
        )
      ],
    );
  }
}
