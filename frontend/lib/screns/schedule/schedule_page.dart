import 'dart:convert';
import 'package:els/helper/api_config.dart';
import 'dart:typed_data';
import 'package:els/screns/schedule/schedule_screen.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../../helper/class_colors.dart';
import '../../../helper/my_map/my_map.dart';
import 'package:http/http.dart' as http;
import '../../TO/escalator_travelator_TO.dart';
import '../../TO/liftMO.dart';
import '../../TO/liftNotMO.dart';
import 'widgets/finish_to_button.dart';
import 'widgets/schedule_year_dialog.dart';
import '../../helper/defective_act.dart';
import '../../helper/my_user.dart';
import 'package:intl/intl.dart';
import '../home_page/home_page.dart';
import '../object/view/object_page.dart';
import '../object/view/object_screen.dart';
import 'package:els/helper/api_client.dart';
import 'package:els/helper/api_image.dart';

/// Окно выбранного Графика


/// наш мап для создания ТО
Map myGetPlanetTO = {'numberTo': '', 'stepListTO' : ''};

Map planetTO = {};

Map listTo = {};

List listToCreatePlanetTO = [];

/// test
int intMon = 0;
int intMonTOTest = 0;
String monTO = '';
bool saveTO1 = false;
bool saveTO2 = false;
bool saveTO3 = false;
bool saveTO4 = false;

int addTOMon = 0;

int intMonTOTes = 0;

///  =======================
getSampleTO(int idObject) async {
  final url = '${ApiConfig.base}/act-fact/by-object/$idObject/';
  final res = await Api.get(Uri.parse(url), headers: {
    "Content-Type": "application/json; charset=utf-8",
    'Accept': 'application/json',
  });
  var response = jsonDecode(utf8.decode(res.bodyBytes));
  sampleTOList = response['data'];
}
String? numYanSampleTO;
String? numFebSampleTO;
String? numMarSampleTO;
String? numAprSampleTO;
String? numMaySampleTO;
String? numJunSampleTO;
String? numJulSampleTO;
String? numAugSampleTO;
String? numSepSampleTO;
String? numOctSampleTO;
String? numNovSampleTO;
String? numDecSampleTO;

List sampleTOList = [];
/// ===========================

/// /// ///
List listTOJanuaryText = [];
List listTOMonTaskText = [];

List myGetListGraphics = [];
List templatesObject = [];
List listActualActsInObject = [];
/// для то времено
Map listInTO = {};
Map listIn = {};
/// Выбранный шаблон
Map listGetSelectedTemplateTO = {};
Map newListTemplateTO = {};

Map selectedActualActsInObject = {};
///
Map getSampleTOMap = {};

List<dynamic> selectedTemplateTO = [];

Map getObjectListTO = {};

/// Test Test
List<String> pairs = [];

/// Шаблоны ===========================================================================================

/// Создание шаблона ТО
createTemplateTO(int factoryModelId, int typeActId, List stepList) async {
  String encodeTemplateTO = jsonEncode(stepList);
  var response = await Api.post(
    Uri.parse("${ApiConfig.base}/act-base/"),
    headers: {
      "Content-Type": "application/json; charset=utf-8",
    },
    body: json.encode({
      "factory_model_id": factoryModelId,
      "type_act_id": typeActId,
      "step_list": encodeTemplateTO,
    }),
  );
  newListTemplateTO = jsonDecode(utf8.decode(response.bodyBytes));
  //print('${newListTemplateTO['description']}');


  // creationFactActList(newListTemplateTO['data']['id']);
}

/// Изменение шаблона ТО
correctCreateTemplateTO(int factoryModelId, int typeActId, String stepList) async {
  var response = await Api.put(
    Uri.parse("${ApiConfig.base}/act-base/"),
    headers: {
      "Content-Type": "application/json; charset=utf-8",
    },
    body: json.encode({
      "factory_model_id": factoryModelId,
      "type_act_id": typeActId,
      "step_list": stepList,
    }),
  );
  var vova = jsonDecode(utf8.decode(response.bodyBytes));
  //print(vova);
}

/// Получение всех Шаблонов
getAllTemplateTO() async {
  final url = '${ApiConfig.base}/acts-bases/?page=1';
  final res = await Api.get(Uri.parse(url), headers: {
    "Content-Type": "application/json; charset=utf-8",
    'Accept': 'application/json',
  });
  var response = jsonDecode(utf8.decode(res.bodyBytes));
  //print('Получение всех Шаблонов  >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>${response['data']}');
}

/// Получение шаблонов привязанных к обьекту
getAllTemplateTOInIdObject(int idObject) async {
  final url = '${ApiConfig.base}/act-base/by-object/$idObject/';
  final res = await Api.get(Uri.parse(url), headers: {
    "Content-Type": "application/json; charset=utf-8",
    'Accept': 'application/json',
  });
  var response = jsonDecode(utf8.decode(res.bodyBytes));
  templatesObject = response['data'];
  sampleTOList = response['data'];
  // print('шаблонов привязанных к обьекту ==> 1  ${templatesObject[0]}');
  // print('шаблонов привязанных к обьекту ==> 2 ${sampleTOList}');
}

/// Получение выбранного шаблона
getSelectedTemplateTO(int actFactId) async {
  final res = await Api.get(
      Uri.parse('${ApiConfig.base}/act-base/$actFactId/'),
      headers: {
        "Content-Type": "application/json; charset=utf-8",
        'Accept': 'application/json',
      });
  var response = jsonDecode(utf8.decode(res.bodyBytes));
  listGetSelectedTemplateTO = response['data'];
  String stringTest = listGetSelectedTemplateTO['step_list'].replaceAll("'", '"');
  selectedTemplateTO = json.decode(stringTest);
  //print(listGetSelectedTemplateTO);
}

/// ===================================================================================================



/// Фактические Акты ==================================================================================

/// Получение фактических актов привязанных к обьекту
getFactActListInIdObject(int idObject) async {
  final res = await Api.get(
      Uri.parse('${ApiConfig.base}/act-fact/by-object/$idObject/'),
      headers: {
        "Content-Type": "application/json; charset=utf-8",
        'Accept': 'application/json',
      });
  var response = jsonDecode(utf8.decode(res.bodyBytes));
  listActualActsInObject = response['data'];
  /// Возможно ошибка проверить ============

  //print('фактических актов привязанных к обьекту ==>  ${listActualActsInObject.isNotEmpty}');

  // print('++++++++++++++++++++++++++++');
  // print(listActualActsInObject);
  // print('++++++++++++++++++++++++++++');

  // if(listActualActsInObject.isNotEmpty){
  //   String stringTest = listActualActsInObject[0]['step_list_fact'].replaceAll("'", '"');
  //   selectedActualActsInObject = json.decode(stringTest);
  //   // print(selectedActualActsInObject);
  // }
  /// ======================================
}

/// Добавить один акт факт в БД. Который в последствии будет выполнять механик, заполняя данными о ходе выполнения работ.
creationFactActList(int numberActBase) async {
  var res = await Api.post(
    Uri.parse("${ApiConfig.base}/act-fact/"),
    headers: {
      "Content-Type": "application/json; charset=utf-8",
    },
    body: json.encode({
      "object_id": listSelectedObject['data']['id'],
      "act_base_id": numberActBase, // id шаблона то
      "foreman_id": listSelectedObject['data']['foreman_id']['id'],
      "main_mechanic_id": listSelectedObject['data']['mechanic_id']['id']
    }),
  );
  var response = jsonDecode(utf8.decode(res.bodyBytes));
  intMonTOTest = response['data']['id'];
  String listNewTo = json.encode(myGetPlanetTO);
  addListFactAct(response['data']['id'], listNewTo);
  print('Добавить один акт факт в БД  >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>${listNewTo}');
  await getTOScheduleIdObject(IntTest.pressHover);

}

/// Изменить акт факт
correctFactActList(int idSelected, String newListToMon) async {
  var res = await Api.put(
    Uri.parse("${ApiConfig.base}/act-fact/$idSelected/"),
    headers: {
      "Content-Type": "application/json; charset=utf-8",
    },
    body: json.encode(
      {
      "step_list_fact": newListToMon
      },
    ),
  );
  var response = jsonDecode(utf8.decode(res.bodyBytes));
  //print('Изменить акт фак  >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>${response['data']}');
}

/// Добавить список то в акт факт
addListFactAct(int idSelectedAct, String listAct) async {
  var res = await Api.put(
    Uri.parse("${ApiConfig.base}/act-fact/$idSelectedAct/"),
    headers: {
      "Content-Type": "application/json; charset=utf-8",
    },
    body: json.encode(
      {
        "step_list_fact": listAct
      },
    ),
  );
  var response = jsonDecode(utf8.decode(res.bodyBytes));
  //print('Новый список акт фак  >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>${response.runtimeType}');
}

/// Завершение ТО живёт в `widgets/finish_to_button.dart`: тем же действием
/// пользуется прорабский экран графика, а запрос и кнопка к нему в паре.
/// Прежняя `correctFactActStatus` посылала `status_id: 0` и не вызывалась
/// ниоткуда — бэкенд такой запрос всё равно молча игнорировал.

/// ===================================================================================================



/// Плановые ТО ======================================================================================

/// Получение всех ТО
getAllTOGraphics() async {
  final url = '${ApiConfig.base}/all-planned-to/?page=1';
  final res = await Api.get(Uri.parse(url), headers: {
    "Content-Type": "application/json; charset=utf-8",
    'Accept': 'application/json',
  });
  var response = jsonDecode(utf8.decode(res.bodyBytes));
}

/// Получить список плановых TO привязанных к обьекту
getTOScheduleIdObject(int idObject) async {
  final res = await Api.get(
      Uri.parse('${ApiConfig.base}/planned-to/by-object/$idObject/?page=1'),
      headers: {
        "Content-Type": "application/json; charset=utf-8",
        'Accept': 'application/json',
      });
  var getObjectListBlock = jsonDecode(utf8.decode(res.bodyBytes));
  getTOScheduleList = getObjectListBlock['data'];

  // print('список плановых TO привязанных к обьекту ==>  ${getTOScheduleList[0]}');
  // print('список плановых TO привязанных к обьекту ==>  ${getTOScheduleList[0]['id']}');




  myStream.add(IntTest.indexScreens);
}

bool checkMon(){
  for(var i = 0; i< getTOScheduleList.length; i++){
    if(getTOScheduleList[i]['january_to_id'] != null) return true;
    if(getTOScheduleList[i]['february_to_id'] != null) return true;
    if(getTOScheduleList[i]['march_to_id'] != null) return true;
    if(getTOScheduleList[i]['april_to_id'] != null) return true;
    if(getTOScheduleList[i]['may_to_id'] != null) return true;
    if(getTOScheduleList[i]['june_to_id'] != null) return true;
    if(getTOScheduleList[i]['july_to_id'] != null) return true;
    if(getTOScheduleList[i]['august_to_id'] != null) return true;
    if(getTOScheduleList[i]['september_to_id'] != null) return true;
    if(getTOScheduleList[i]['october_to_id'] != null) return true;
    if(getTOScheduleList[i]['november_to_id'] != null) return true;
    if(getTOScheduleList[i]['december_to_id'] != null) return true;
  }
  return false;
}

/// Назначение ТО Обьекту
creationTOGraphics(String year,int objectId,) async {
  var response = await Api.post(
    Uri.parse("${ApiConfig.base}/planned-to/"),
    headers: {
      "Content-Type": "application/json; charset=utf-8",
    },
    body: json.encode({
      "year": year,
      "object_id": objectId,
    }),
  );
  var vova = jsonDecode(utf8.decode(response.bodyBytes));
  planetTO = vova;
  // print(vova);
  print('${planetTO['description']}');

}

/// Изменить ТО Обьекту
changeTOGraphics(String myMonTo ,int idTO, int idTOGraphics) async {
  var response = await Api.put(
    Uri.parse("${ApiConfig.base}/planned-to/$idTOGraphics/"),
    headers: {
      "Content-Type": "application/json; charset=utf-8",
    },
    body: json.encode({
      myMonTo : idTO,
    }),
  );
  var vova = jsonDecode(utf8.decode(response.bodyBytes));
  // print(vova);
}

/// ===================================================================================================

class SchedulePage extends StatefulWidget {
  const SchedulePage({Key? key}) : super(key: key);

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

bool openTestOne = false;
bool openTestTwo = false;
bool openBoolTo1 = false;
int monthSchedule = 1;
int addTO = 0;

class _SchedulePageState extends State<SchedulePage> {

  /// ФИО
  TextEditingController fio = TextEditingController();
  final keyNameTO1 = GlobalKey<FormState>();
  final keyNumberTO = GlobalKey<FormState>();
  TextEditingController addNewNameTO = TextEditingController();
  TextEditingController addDataYearTO = TextEditingController(text: DateFormat.y('ru').format(DateTime.now()));
  TextEditingController addNumberTO = TextEditingController();

  @override
  void initState() {
    getSampleTO(IntTest.pressHover);
    myStream.add(IntTest.indexScreens);
    // TODO: implement initState
    super.initState();
  }

  @override
  void dispose() {
    addTO = 0;
    intMon = 0;
    listTOMonTaskText.clear();
    getTOScheduleList.clear();
    // TODO: implement dispose
    super.dispose();
  }

  Map listTOJanuary = {};
  Map listTOFeb = {};
  Map listTOMar = {};
  Map listTOApr = {};
  Map listTOMay = {};
  Map listTOJun = {};
  Map listTOJul = {};
  Map listTOAug = {};
  Map listTOSen = {};
  Map listTOOct = {};
  Map listTONov = {};
  Map listTODec = {};

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final viewObjectPage = listSelectedObject['data'];
    return SingleChildScrollView(
      child: Column(
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
                  /// Кнопка Назад График
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
                                IntTest.indexScreens = 1;
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
                  Text('График',
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
          /// Body
          Padding(
            padding: const EdgeInsets.all(ColorApp.kPadding),
            child: Column(
              children: [
                /// Body
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ///Левый Блок
                    Expanded(
                      flex: 3,
                      child: Column(
                        children: [
                          const SizedBox(height: 22.0),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: const [
                              Text(
                                'Информация',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight:
                                    FontWeight.w600),
                              ),
                            ],
                          ),
                          const Gap(20.0),
                          Container(
                            padding: const EdgeInsets.all(20.0),
                            height: 790,
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
                                      subtitle: '${viewObjectPage['contact_person_id']['phone']}' ?? ''),

                                /// Договор переделать <<<<<<<
                                const IconAndText(
                                    icon: Icons
                                        .insert_drive_file_outlined,
                                    title: 'Договор',
                                    subtitle:
                                    'Договор №2123 от 24.04.2022'),
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
                                child: viewObjectPage['geo'] == null
                                    ? Container(
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
                                  child: const Center(child: Text('Нет данных')),
                                ) : const MyMapScheduleObject(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20.0),

                          ///Ответственные
                          Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Ответственные',
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 20.0),
                                Row(
                                  children: [

                                    ///Прораб

                                    listSelectedObject['data']['foreman_id'] == null
                                        ? Expanded(child: Container(
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
                                            child: Text('Прораб удалён',style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: ColorApp.myColorWhite)))))
                                        : Expanded(
                                      child: listSelectedObject['data']['foreman_id']['is_active'] == false
                                          ? Container(
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
                                              child: Text('Прораб заморожен',style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  color: ColorApp.myColorWhite))))
                                          : Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                                        height: 70,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(5.0),
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
                                              child: Text('Прораб',
                                                style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight:
                                                    FontWeight.w600,
                                                    color: ColorApp
                                                        .myColorWhite),
                                              ),
                                            ),
                                            viewObjectPage['foreman_id'] == null
                                                ? const Text('')
                                                : Expanded(
                                              child: Container(
                                                height: 60,
                                                // padding: const EdgeInsets.all(10.0),
                                                decoration:
                                                BoxDecoration(
                                                  borderRadius:
                                                  BorderRadius
                                                      .circular(10),
                                                  color: ColorApp.myColorGrayShadow,
                                                ),
                                                child: Row(
                                                  children: [
                                                    Padding(padding: const EdgeInsets.symmetric(horizontal: 10.0),
                                                        child: CircleAvatar(
                                                            backgroundImage: const NetworkImage('assets/user.png'),
                                                            foregroundImage: apiImage(viewObjectPage['foreman_id']['photo']))),
                                                    viewObjectPage['foreman_id'] == null ? const Expanded(child: Text('')) :
                                                    Expanded(
                                                        child: Text('${viewObjectPage['foreman_id']['name']}',
                                                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 20.0),

                                    /// Механик

                                    listSelectedObject['data']['mechanic_id'] == null
                                        ? Expanded(child: Container(
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
                                            child: Text('Механик удалён',style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: ColorApp.myColorWhite)))))
                                        : Expanded(
                                      child: listSelectedObject['data']['mechanic_id']['is_active'] == false
                                          ? Container(
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
                                              child: Text('Механик заморожен',style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  color: ColorApp.myColorWhite))))
                                          : Container(
                                        padding:
                                        const EdgeInsets.symmetric(
                                            horizontal: 20.0,
                                            vertical: 10.0),
                                        height: 70,
                                        decoration: BoxDecoration(
                                          borderRadius:
                                          BorderRadius.circular(
                                              5.0),
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
                                                'Механик',
                                                style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight:
                                                    FontWeight.w600,
                                                    color: ColorApp
                                                        .myColorWhite),
                                              ),
                                            ),
                                            viewObjectPage['mechanic_id'] == null
                                                ? const Text('')
                                                : Expanded(
                                              child: Container(
                                                height: 60,
                                                // padding: const EdgeInsets.all(10.0),
                                                decoration:
                                                BoxDecoration(
                                                  borderRadius:
                                                  BorderRadius
                                                      .circular(10),
                                                  color: ColorApp
                                                      .myColorGrayShadow,
                                                ),
                                                child: Row(
                                                  children: [
                                                    Padding(
                                                        padding: const EdgeInsets
                                                            .symmetric(
                                                            horizontal:
                                                            10.0),
                                                        child:
                                                        CircleAvatar(
                                                            backgroundImage: const NetworkImage('assets/user.png'),
                                                            foregroundImage: apiImage(viewObjectPage['mechanic_id']['photo']))),
                                                    viewObjectPage['mechanic_id'] == null ? const Expanded(child: Text('')) :
                                                    Expanded(
                                                      child: Text('${viewObjectPage['mechanic_id']['name']}',
                                                        style: const TextStyle(
                                                            fontSize:
                                                            14,
                                                            fontWeight:
                                                            FontWeight
                                                                .w600),
                                                      ),
                                                    )
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              ]),
                          const SizedBox(height: 20.0),

                          ///Техническое обслуживание
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              /// Техническое обслуживание
                              Row(
                                children: [
                                  const Text('Техническое обслуживание',style: TextStyle(fontWeight: FontWeight.bold,fontSize: 16.0)),
                                  const SizedBox(width: 10.0),
                                  /// Дефектный Акт
                                  IconButton(onPressed: (){
                                    setState(() {
                                      showDialog(
                                          context: context,
                                          builder: (context) =>
                                              AlertDialog(
                                                  content: StreamBuilder(
                                                      stream: myStream.stream,
                                                      builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                                                        return const DefectiveAct();
                                                      })));
                                    });
                                  }, icon: const Icon(Icons.list_alt_outlined,color: Colors.orange)),
                                  const Spacer(),
                                  /// Создать Шаблон
                                  if(templatesObject.isEmpty)
                                    ElevatedButton(onPressed: (){
                                      setState(() {
                                        showDialog(
                                            context: context,
                                            builder: (context) =>
                                                AlertDialog(
                                                    content: StreamBuilder(
                                                        stream: myStream.stream,
                                                        builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                                                          return SizedBox(
                                                            width: 600.0,
                                                            height: 200.0,
                                                            child:
                                                            listSelectedObject['data']['factory_model_id']['type_object_id']['id'] == 1
                                                                ? const TOLiftNotMO() :
                                                            listSelectedObject['data']['factory_model_id']['type_object_id']['id'] == 2
                                                                ? const TOLiftMO() :
                                                            listSelectedObject['data']['factory_model_id']['type_object_id']['id'] == 3
                                                                ? const TOEscalatorTraveller() :
                                                            listSelectedObject['data']['factory_model_id']['type_object_id']['id'] == 4
                                                                ? const TOEscalatorTraveller() :
                                                            listSelectedObject['data']['factory_model_id']['type_object_id']['id'] == 5
                                                                ? const TOCargoDisabledPersonLift() : const TOCargoDisabledPersonLift(),
                                                          );})

                                                ));
                                      });
                                    }, child: const Text('Создать Шаблон')),
                                ],
                              ),
                              const SizedBox(height: 20.0),
                              /// Кнопка создать Плановые ТО
                              if(templatesObject.isNotEmpty && getTOScheduleList.isEmpty)
                                Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 20.0,vertical: 20.0),
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(5.0),
                                        color: Colors.white,
                                        boxShadow: const [
                                          BoxShadow(color: Colors.grey, blurRadius: 5)]),
                                    child: Center(child:
                                    /// Создать Плановые ТО
                                    ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                            backgroundColor: ColorApp.myColorGreenAuth),
                                        onPressed: () async {
                                          // Год спрашиваем, а не берём из кода:
                                          // здесь годами стояла строка '2025',
                                          // и график на текущий год завести
                                          // было нечем.
                                          final String? year = await pickScheduleYear(context);
                                          if (year == null) return;
                                          await creationTOGraphics(year, IntTest.pressHover);
                                          await getTOScheduleIdObject(IntTest.pressHover);
                                          myStream.add(IntTest.indexScreens);
                                          // Получить список плановых TO привязанных к обьекту
                                          // setState(() {
                                          //   showDialog(
                                          //       context: context,
                                          //       builder: (context) =>
                                          //           AlertDialog(
                                          //               content: StreamBuilder(
                                          //                   stream: myStream.stream,
                                          //                   builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                                          //                     return SizedBox(
                                          //                       width: 340.0,
                                          //                       height: 600.0,
                                          //                       child: Column(
                                          //                         crossAxisAlignment: CrossAxisAlignment.start,
                                          //                         children: [
                                          //                           Row(
                                          //                             children: [
                                          //                               const Text('Назначить  Плановые ТО',style: TextStyle(fontWeight: FontWeight.bold,fontSize: 20.0)),
                                          //                               const Spacer(),
                                          //                               /// кнопка закрыть
                                          //                               IconButton(
                                          //                                   onPressed: () {
                                          //                                     Navigator.pop(context);
                                          //                                     myStream.add(IntTest.indexScreens);
                                          //                                   },
                                          //                                   icon: const Icon(
                                          //                                     Icons.close,
                                          //                                     color: ColorApp.myColorGreenAuth,
                                          //                                   )),
                                          //                             ],
                                          //                           ),
                                          //                           const SizedBox(height: 50.0),
                                          //                           Column(
                                          //                             children: [
                                          //                               /// Братья Месяцы
                                          //                               Column(
                                          //                                 children: [
                                          //                                   /// Янв, фев, март
                                          //                                   Row(
                                          //                                     children: [
                                          //                                       // TestButtonTO(mon: 'Янв', monNumTO: '$numYanSampleTO'),
                                          //                                       /// Янв
                                          //                                       Column(
                                          //                                         crossAxisAlignment: CrossAxisAlignment.start,
                                          //                                         children: [
                                          //                                           const  Text('Янв'),
                                          //                                           SizedBox(
                                          //                                             width: 100.0,
                                          //                                             height: 50.0,
                                          //                                             child: DropdownButtonFormField(
                                          //                                               hint: const Text('№ ТО'),
                                          //                                               value: numYanSampleTO,
                                          //                                               onChanged: (newValue1) async {
                                          //                                                 numYanSampleTO = newValue1 as String?;
                                          //                                                 numYanSampleTO!.indexOf(newValue1!);
                                          //                                                 myStream.add(IntTest.indexScreens);
                                          //                                               },
                                          //                                               items: sampleTOList.map((jobTitleList) {
                                          //                                                 if(sampleTOList.isNotEmpty){
                                          //                                                   String stringTest = jobTitleList['step_list_fact'].replaceAll("'", '"');
                                          //                                                   getSampleTOMap = json.decode(stringTest);
                                          //                                                 }
                                          //                                                 return DropdownMenuItem(
                                          //                                                   value: jobTitleList['id'].toString(),
                                          //                                                   child: SizedBox(
                                          //                                                     width: 50.0,
                                          //                                                     child: Row(
                                          //                                                       children: [
                                          //                                                         Expanded(
                                          //                                                           child: Text('${getSampleTOMap['type_act_id']['name']}',
                                          //                                                               overflow: TextOverflow.ellipsis),
                                          //                                                         ),
                                          //                                                       ],
                                          //                                                     ),
                                          //                                                   ),
                                          //
                                          //                                                 );
                                          //                                               }).toList(),
                                          //                                               decoration: const InputDecoration(
                                          //                                                   border: OutlineInputBorder()),
                                          //                                             ),
                                          //                                           ),
                                          //                                         ],
                                          //                                       ),
                                          //                                       const SizedBox(width: 20.0),
                                          //                                       /// фев
                                          //                                       Column(
                                          //                                         crossAxisAlignment: CrossAxisAlignment.start,
                                          //                                         children: [
                                          //                                           const  Text('фев'),
                                          //                                           SizedBox(
                                          //                                             width: 100.0,
                                          //                                             height: 50.0,
                                          //                                             child: DropdownButtonFormField(
                                          //                                               hint: const Text('№ ТО'),
                                          //                                               value: numFebSampleTO,
                                          //                                               onChanged: (newValue1) async {
                                          //                                                 numFebSampleTO = newValue1 as String?;
                                          //                                                 numFebSampleTO!.indexOf(newValue1!);
                                          //                                                 print(numFebSampleTO);
                                          //                                                 myStream.add(IntTest.indexScreens);
                                          //                                               },
                                          //                                               items: sampleTOList.map((jobTitleList) {
                                          //                                                 if(sampleTOList.isNotEmpty){
                                          //                                                   String stringTest = jobTitleList['step_list_fact'].replaceAll("'", '"');
                                          //                                                   getSampleTOMap = json.decode(stringTest);
                                          //                                                 }
                                          //                                                 return DropdownMenuItem(
                                          //                                                   value: jobTitleList['id'].toString(),
                                          //                                                   child: SizedBox(
                                          //                                                     width: 50.0,
                                          //                                                     child: Row(
                                          //                                                       children: [
                                          //                                                         Expanded(
                                          //                                                           child: Text('${getSampleTOMap['type_act_id']['name']}',
                                          //                                                               overflow: TextOverflow.ellipsis),
                                          //                                                         ),
                                          //                                                       ],
                                          //                                                     ),
                                          //                                                   ),
                                          //
                                          //                                                 );
                                          //                                               }).toList(),
                                          //                                               decoration: const InputDecoration(
                                          //                                                   border: OutlineInputBorder()),
                                          //                                             ),
                                          //                                           ),
                                          //                                         ],
                                          //                                       ),
                                          //                                       const SizedBox(width: 20.0),
                                          //                                       /// март
                                          //                                       Column(
                                          //                                         crossAxisAlignment: CrossAxisAlignment.start,
                                          //                                         children: [
                                          //                                           const  Text('март'),
                                          //                                           SizedBox(
                                          //                                             width: 100.0,
                                          //                                             height: 50.0,
                                          //                                             child: DropdownButtonFormField(
                                          //                                               hint: const Text('№ ТО'),
                                          //                                               value: numMarSampleTO,
                                          //                                               onChanged: (newValue1) async {
                                          //                                                 numMarSampleTO = newValue1 as String?;
                                          //                                                 numMarSampleTO!.indexOf(newValue1!);
                                          //                                                 print(numMarSampleTO);
                                          //                                                 myStream.add(IntTest.indexScreens);
                                          //                                               },
                                          //                                               items: sampleTOList.map((jobTitleList) {
                                          //                                                 if(sampleTOList.isNotEmpty){
                                          //                                                   String stringTest = jobTitleList['step_list_fact'].replaceAll("'", '"');
                                          //                                                   getSampleTOMap = json.decode(stringTest);
                                          //                                                 }
                                          //                                                 return DropdownMenuItem(
                                          //                                                   value: jobTitleList['id'].toString(),
                                          //                                                   child: SizedBox(
                                          //                                                     width: 50.0,
                                          //                                                     child: Row(
                                          //                                                       children: [
                                          //                                                         Expanded(
                                          //                                                           child: Text('${getSampleTOMap['type_act_id']['name']}',
                                          //                                                               overflow: TextOverflow.ellipsis),
                                          //                                                         ),
                                          //                                                       ],
                                          //                                                     ),
                                          //                                                   ),
                                          //
                                          //                                                 );
                                          //                                               }).toList(),
                                          //                                               decoration: const InputDecoration(
                                          //                                                   border: OutlineInputBorder()),
                                          //                                             ),
                                          //                                           ),
                                          //                                         ],
                                          //                                       ),
                                          //                                     ],
                                          //                                   ),
                                          //                                   const SizedBox(height: 20.0),
                                          //                                   /// Апр, Май, Июнь
                                          //                                   Row(
                                          //                                     children: [
                                          //                                       /// Апр
                                          //                                       Column(
                                          //                                         crossAxisAlignment: CrossAxisAlignment.start,
                                          //                                         children: [
                                          //                                           const  Text('Апр'),
                                          //                                           SizedBox(
                                          //                                             width: 100.0,
                                          //                                             height: 50.0,
                                          //                                             child: DropdownButtonFormField(
                                          //                                               hint: const Text('№ ТО'),
                                          //                                               value: numAprSampleTO,
                                          //                                               onChanged: (newValue1) async {
                                          //                                                 numAprSampleTO = newValue1 as String?;
                                          //                                                 numAprSampleTO!.indexOf(newValue1!);
                                          //                                                 myStream.add(IntTest.indexScreens);
                                          //                                               },
                                          //                                               items: sampleTOList.map((jobTitleList) {
                                          //                                                 if(sampleTOList.isNotEmpty){
                                          //                                                   String stringTest = jobTitleList['step_list_fact'].replaceAll("'", '"');
                                          //                                                   getSampleTOMap = json.decode(stringTest);
                                          //                                                 }
                                          //                                                 return DropdownMenuItem(
                                          //                                                   value: jobTitleList['id'].toString(),
                                          //                                                   child: SizedBox(
                                          //                                                     width: 50.0,
                                          //                                                     child: Row(
                                          //                                                       children: [
                                          //                                                         Expanded(
                                          //                                                           child: Text('${getSampleTOMap['type_act_id']['name']}',
                                          //                                                               overflow: TextOverflow.ellipsis),
                                          //                                                         ),
                                          //                                                       ],
                                          //                                                     ),
                                          //                                                   ),
                                          //
                                          //                                                 );
                                          //                                               }).toList(),
                                          //                                               decoration: const InputDecoration(
                                          //                                                   border: OutlineInputBorder()),
                                          //                                             ),
                                          //                                           ),
                                          //                                         ],
                                          //                                       ),
                                          //                                       const SizedBox(width: 20.0),
                                          //                                       /// Май
                                          //                                       Column(
                                          //                                         crossAxisAlignment: CrossAxisAlignment.start,
                                          //                                         children: [
                                          //                                           const  Text('Май'),
                                          //                                           SizedBox(
                                          //                                             width: 100.0,
                                          //                                             height: 50.0,
                                          //                                             child: DropdownButtonFormField(
                                          //                                               hint: const Text('№ ТО'),
                                          //                                               value: numMaySampleTO,
                                          //                                               onChanged: (newValue1) async {
                                          //                                                 numMaySampleTO = newValue1 as String?;
                                          //                                                 numMaySampleTO!.indexOf(newValue1!);
                                          //                                                 myStream.add(IntTest.indexScreens);
                                          //                                               },
                                          //                                               items: sampleTOList.map((jobTitleList) {
                                          //                                                 if(sampleTOList.isNotEmpty){
                                          //                                                   String stringTest = jobTitleList['step_list_fact'].replaceAll("'", '"');
                                          //                                                   getSampleTOMap = json.decode(stringTest);
                                          //                                                 }
                                          //                                                 return DropdownMenuItem(
                                          //                                                   value: jobTitleList['id'].toString(),
                                          //                                                   child: SizedBox(
                                          //                                                     width: 50.0,
                                          //                                                     child: Row(
                                          //                                                       children: [
                                          //                                                         Expanded(
                                          //                                                           child: Text('${getSampleTOMap['type_act_id']['name']}',
                                          //                                                               overflow: TextOverflow.ellipsis),
                                          //                                                         ),
                                          //                                                       ],
                                          //                                                     ),
                                          //                                                   ),
                                          //
                                          //                                                 );
                                          //                                               }).toList(),
                                          //                                               decoration: const InputDecoration(
                                          //                                                   border: OutlineInputBorder()),
                                          //                                             ),
                                          //                                           ),
                                          //                                         ],
                                          //                                       ),
                                          //                                       const SizedBox(width: 20.0),
                                          //                                       /// Июнь
                                          //                                       Column(
                                          //                                         crossAxisAlignment: CrossAxisAlignment.start,
                                          //                                         children: [
                                          //                                           const  Text('Июнь'),
                                          //                                           SizedBox(
                                          //                                             width: 100.0,
                                          //                                             height: 50.0,
                                          //                                             child: DropdownButtonFormField(
                                          //                                               hint: const Text('№ ТО'),
                                          //                                               value: numJunSampleTO,
                                          //                                               onChanged: (newValue1) async {
                                          //                                                 numJunSampleTO = newValue1 as String?;
                                          //                                                 numJunSampleTO!.indexOf(newValue1!);
                                          //                                                 myStream.add(IntTest.indexScreens);
                                          //                                               },
                                          //                                               items: sampleTOList.map((jobTitleList) {
                                          //                                                 if(sampleTOList.isNotEmpty){
                                          //                                                   String stringTest = jobTitleList['step_list_fact'].replaceAll("'", '"');
                                          //                                                   getSampleTOMap = json.decode(stringTest);
                                          //                                                 }
                                          //                                                 return DropdownMenuItem(
                                          //                                                   value: jobTitleList['id'].toString(),
                                          //                                                   child: SizedBox(
                                          //                                                     width: 50.0,
                                          //                                                     child: Row(
                                          //                                                       children: [
                                          //                                                         Expanded(
                                          //                                                           child: Text('${getSampleTOMap['type_act_id']['name']}',
                                          //                                                               overflow: TextOverflow.ellipsis),
                                          //                                                         ),
                                          //                                                       ],
                                          //                                                     ),
                                          //                                                   ),
                                          //
                                          //                                                 );
                                          //                                               }).toList(),
                                          //                                               decoration: const InputDecoration(
                                          //                                                   border: OutlineInputBorder()),
                                          //                                             ),
                                          //                                           ),
                                          //                                         ],
                                          //                                       ),
                                          //                                     ],
                                          //                                   ),
                                          //                                   const SizedBox(height: 20.0),
                                          //                                   /// Июль, Авг, Сен
                                          //                                   Row(
                                          //                                     children: [
                                          //                                       /// Июль
                                          //                                       Column(
                                          //                                         crossAxisAlignment: CrossAxisAlignment.start,
                                          //                                         children: [
                                          //                                           const  Text('Июль'),
                                          //                                           SizedBox(
                                          //                                             width: 100.0,
                                          //                                             height: 50.0,
                                          //                                             child: DropdownButtonFormField(
                                          //                                               hint: const Text('№ ТО'),
                                          //                                               value: numJulSampleTO,
                                          //                                               onChanged: (newValue1) async {
                                          //                                                 numJulSampleTO = newValue1 as String?;
                                          //                                                 numJulSampleTO!.indexOf(newValue1!);
                                          //                                                 myStream.add(IntTest.indexScreens);
                                          //                                               },
                                          //                                               items: sampleTOList.map((jobTitleList) {
                                          //                                                 if(sampleTOList.isNotEmpty){
                                          //                                                   String stringTest = jobTitleList['step_list_fact'].replaceAll("'", '"');
                                          //                                                   getSampleTOMap = json.decode(stringTest);
                                          //                                                 }
                                          //                                                 return DropdownMenuItem(
                                          //                                                   value: jobTitleList['id'].toString(),
                                          //                                                   child: SizedBox(
                                          //                                                     width: 50.0,
                                          //                                                     child: Row(
                                          //                                                       children: [
                                          //                                                         Expanded(
                                          //                                                           child: Text('${getSampleTOMap['type_act_id']['name']}',
                                          //                                                               overflow: TextOverflow.ellipsis),
                                          //                                                         ),
                                          //                                                       ],
                                          //                                                     ),
                                          //                                                   ),
                                          //
                                          //                                                 );
                                          //                                               }).toList(),
                                          //                                               decoration: const InputDecoration(
                                          //                                                   border: OutlineInputBorder()),
                                          //                                             ),
                                          //                                           ),
                                          //                                         ],
                                          //                                       ),
                                          //                                       const SizedBox(width: 20.0),
                                          //                                       /// Авг
                                          //                                       Column(
                                          //                                         crossAxisAlignment: CrossAxisAlignment.start,
                                          //                                         children: [
                                          //                                           const  Text('Авг'),
                                          //                                           SizedBox(
                                          //                                             width: 100.0,
                                          //                                             height: 50.0,
                                          //                                             child: DropdownButtonFormField(
                                          //                                               hint: const Text('№ ТО'),
                                          //                                               value: numAugSampleTO,
                                          //                                               onChanged: (newValue1) async {
                                          //                                                 numAugSampleTO = newValue1 as String?;
                                          //                                                 numAugSampleTO!.indexOf(newValue1!);
                                          //                                                 myStream.add(IntTest.indexScreens);
                                          //                                               },
                                          //                                               items: sampleTOList.map((jobTitleList) {
                                          //                                                 if(sampleTOList.isNotEmpty){
                                          //                                                   String stringTest = jobTitleList['step_list_fact'].replaceAll("'", '"');
                                          //                                                   getSampleTOMap = json.decode(stringTest);
                                          //                                                 }
                                          //                                                 return DropdownMenuItem(
                                          //                                                   value: jobTitleList['id'].toString(),
                                          //                                                   child: SizedBox(
                                          //                                                     width: 50.0,
                                          //                                                     child: Row(
                                          //                                                       children: [
                                          //                                                         Expanded(
                                          //                                                           child: Text('${getSampleTOMap['type_act_id']['name']}',
                                          //                                                               overflow: TextOverflow.ellipsis),
                                          //                                                         ),
                                          //                                                       ],
                                          //                                                     ),
                                          //                                                   ),
                                          //
                                          //                                                 );
                                          //                                               }).toList(),
                                          //                                               decoration: const InputDecoration(
                                          //                                                   border: OutlineInputBorder()),
                                          //                                             ),
                                          //                                           ),
                                          //                                         ],
                                          //                                       ),
                                          //                                       const SizedBox(width: 20.0),
                                          //                                       /// Сен
                                          //                                       Column(
                                          //                                         crossAxisAlignment: CrossAxisAlignment.start,
                                          //                                         children: [
                                          //                                           const  Text('Сен'),
                                          //                                           SizedBox(
                                          //                                             width: 100.0,
                                          //                                             height: 50.0,
                                          //                                             child: DropdownButtonFormField(
                                          //                                               hint: const Text('№ ТО'),
                                          //                                               value: numSepSampleTO,
                                          //                                               onChanged: (newValue1) async {
                                          //                                                 numSepSampleTO = newValue1 as String?;
                                          //                                                 numSepSampleTO!.indexOf(newValue1!);
                                          //                                                 myStream.add(IntTest.indexScreens);
                                          //                                               },
                                          //                                               items: sampleTOList.map((jobTitleList) {
                                          //                                                 if(sampleTOList.isNotEmpty){
                                          //                                                   String stringTest = jobTitleList['step_list_fact'].replaceAll("'", '"');
                                          //                                                   getSampleTOMap = json.decode(stringTest);
                                          //                                                 }
                                          //                                                 return DropdownMenuItem(
                                          //                                                   value: jobTitleList['id'].toString(),
                                          //                                                   child: SizedBox(
                                          //                                                     width: 50.0,
                                          //                                                     child: Row(
                                          //                                                       children: [
                                          //                                                         Expanded(
                                          //                                                           child: Text('${getSampleTOMap['type_act_id']['name']}',
                                          //                                                               overflow: TextOverflow.ellipsis),
                                          //                                                         ),
                                          //                                                       ],
                                          //                                                     ),
                                          //                                                   ),
                                          //
                                          //                                                 );
                                          //                                               }).toList(),
                                          //                                               decoration: const InputDecoration(
                                          //                                                   border: OutlineInputBorder()),
                                          //                                             ),
                                          //                                           ),
                                          //                                         ],
                                          //                                       ),
                                          //                                     ],
                                          //                                   ),
                                          //                                   const SizedBox(height: 20.0),
                                          //                                   /// Окт, Ноя, Дек
                                          //                                   Row(
                                          //                                     children: [
                                          //                                       /// Окт
                                          //                                       Column(
                                          //                                         crossAxisAlignment: CrossAxisAlignment.start,
                                          //                                         children: [
                                          //                                           const  Text('Окт'),
                                          //                                           SizedBox(
                                          //                                             width: 100.0,
                                          //                                             height: 50.0,
                                          //                                             child: DropdownButtonFormField(
                                          //                                               hint: const Text('№ ТО'),
                                          //                                               value: numOctSampleTO,
                                          //                                               onChanged: (newValue1) async {
                                          //                                                 numOctSampleTO = newValue1 as String?;
                                          //                                                 numOctSampleTO!.indexOf(newValue1!);
                                          //                                                 myStream.add(IntTest.indexScreens);
                                          //                                               },
                                          //                                               items: sampleTOList.map((jobTitleList) {
                                          //                                                 if(sampleTOList.isNotEmpty){
                                          //                                                   String stringTest = jobTitleList['step_list_fact'].replaceAll("'", '"');
                                          //                                                   getSampleTOMap = json.decode(stringTest);
                                          //                                                 }
                                          //                                                 return DropdownMenuItem(
                                          //                                                   value: jobTitleList['id'].toString(),
                                          //                                                   child: SizedBox(
                                          //                                                     width: 50.0,
                                          //                                                     child: Row(
                                          //                                                       children: [
                                          //                                                         Expanded(
                                          //                                                           child: Text('${getSampleTOMap['type_act_id']['name']}',
                                          //                                                               overflow: TextOverflow.ellipsis),
                                          //                                                         ),
                                          //                                                       ],
                                          //                                                     ),
                                          //                                                   ),
                                          //
                                          //                                                 );
                                          //                                               }).toList(),
                                          //                                               decoration: const InputDecoration(
                                          //                                                   border: OutlineInputBorder()),
                                          //                                             ),
                                          //                                           ),
                                          //                                         ],
                                          //                                       ),
                                          //                                       const SizedBox(width: 20.0),
                                          //                                       /// Ноя
                                          //                                       Column(
                                          //                                         crossAxisAlignment: CrossAxisAlignment.start,
                                          //                                         children: [
                                          //                                           const  Text('Ноя'),
                                          //                                           SizedBox(
                                          //                                             width: 100.0,
                                          //                                             height: 50.0,
                                          //                                             child: DropdownButtonFormField(
                                          //                                               hint: const Text('№ ТО'),
                                          //                                               value: numNovSampleTO,
                                          //                                               onChanged: (newValue1) async {
                                          //                                                 numNovSampleTO = newValue1 as String?;
                                          //                                                 numNovSampleTO!.indexOf(newValue1!);
                                          //                                                 myStream.add(IntTest.indexScreens);
                                          //                                               },
                                          //                                               items: sampleTOList.map((jobTitleList) {
                                          //                                                 if(sampleTOList.isNotEmpty){
                                          //                                                   String stringTest = jobTitleList['step_list_fact'].replaceAll("'", '"');
                                          //                                                   getSampleTOMap = json.decode(stringTest);
                                          //                                                 }
                                          //                                                 return DropdownMenuItem(
                                          //                                                   value: jobTitleList['id'].toString(),
                                          //                                                   child: SizedBox(
                                          //                                                     width: 50.0,
                                          //                                                     child: Row(
                                          //                                                       children: [
                                          //                                                         Expanded(
                                          //                                                           child: Text('${getSampleTOMap['type_act_id']['name']}',
                                          //                                                               overflow: TextOverflow.ellipsis),
                                          //                                                         ),
                                          //                                                       ],
                                          //                                                     ),
                                          //                                                   ),
                                          //
                                          //                                                 );
                                          //                                               }).toList(),
                                          //                                               decoration: const InputDecoration(
                                          //                                                   border: OutlineInputBorder()),
                                          //                                             ),
                                          //                                           ),
                                          //                                         ],
                                          //                                       ),
                                          //                                       const SizedBox(width: 20.0),
                                          //                                       /// Дек
                                          //                                       Column(
                                          //                                         crossAxisAlignment: CrossAxisAlignment.start,
                                          //                                         children: [
                                          //                                           const  Text('Дек'),
                                          //                                           SizedBox(
                                          //                                             width: 100.0,
                                          //                                             height: 50.0,
                                          //                                             child: DropdownButtonFormField(
                                          //                                               hint: const Text('№ ТО'),
                                          //                                               value: numDecSampleTO,
                                          //                                               onChanged: (newValue1) async {
                                          //                                                 numDecSampleTO = newValue1 as String?;
                                          //                                                 numDecSampleTO!.indexOf(newValue1!);
                                          //                                                 myStream.add(IntTest.indexScreens);
                                          //                                               },
                                          //                                               items: sampleTOList.map((jobTitleList) {
                                          //                                                 if(sampleTOList.isNotEmpty){
                                          //                                                   String stringTest = jobTitleList['step_list_fact'].replaceAll("'", '"');
                                          //                                                   getSampleTOMap = json.decode(stringTest);
                                          //                                                 }
                                          //                                                 return DropdownMenuItem(
                                          //                                                   value: jobTitleList['id'].toString(),
                                          //                                                   child: SizedBox(
                                          //                                                     width: 50.0,
                                          //                                                     child: Row(
                                          //                                                       children: [
                                          //                                                         Expanded(
                                          //                                                           child: Text('${getSampleTOMap['type_act_id']['name']}',
                                          //                                                               overflow: TextOverflow.ellipsis),
                                          //                                                         ),
                                          //                                                       ],
                                          //                                                     ),
                                          //                                                   ),
                                          //
                                          //                                                 );
                                          //                                               }).toList(),
                                          //                                               decoration: const InputDecoration(
                                          //                                                   border: OutlineInputBorder()),
                                          //                                             ),
                                          //                                           ),
                                          //                                         ],
                                          //                                       ),
                                          //                                     ],
                                          //                                   ),
                                          //                                 ],
                                          //                               ),
                                          //                               const SizedBox(height: 30.0),
                                          //                               /// Кнопка год
                                          //                               Row(
                                          //                                 children: [
                                          //                                   SizedBox(
                                          //                                     width: 100.0,
                                          //                                     height: 60.0,
                                          //                                     child: Column(
                                          //                                       children: [
                                          //                                         const SizedBox(height: 5.0),
                                          //                                         TextFormField(
                                          //                                           cursorColor: ColorApp.myColorGray,
                                          //                                           controller: addDataYearTO,
                                          //                                           decoration:  const InputDecoration(
                                          //                                               suffixIcon: Icon(Icons.calendar_month_outlined,color: Colors.green),
                                          //                                               border: OutlineInputBorder(),
                                          //                                               focusedBorder: OutlineInputBorder(
                                          //                                                 borderSide: BorderSide(
                                          //                                                     color: ColorApp.myColorGreenAuth),
                                          //                                               ),
                                          //                                               // labelText: 'Документ',
                                          //                                               labelStyle: TextStyle(color: ColorApp.myColorGray)),
                                          //                                         ),
                                          //                                       ],
                                          //                                     ),
                                          //                                   ),
                                          //                                   const Spacer(),
                                          //                                   ElevatedButton(
                                          //                                       style: ElevatedButton.styleFrom(
                                          //                                           primary: Colors.lightGreen,
                                          //                                           padding: const EdgeInsets.symmetric(horizontal: 60.0,vertical: 26.0)),
                                          //                                       onPressed: () async {
                                          //                                         await creationTOGraphics(addDataYearTO.text, IntTest.pressHover);
                                          //                                         await getTOScheduleIdObject(IntTest.pressHover);
                                          //                                         // _showDialog(context, '$planetTO');
                                          //                                         Navigator.pop(context);
                                          //                                         myStream.add(IntTest.indexScreens);
                                          //                                       }, child: const Text('Добавить')),
                                          //
                                          //                                 ],
                                          //                               ),
                                          //                             ],
                                          //                           ),
                                          //                         ],
                                          //                       ),
                                          //                     );})
                                          //
                                          //           ));
                                          // });

                                        }, child: const Text('Создать Плановые ТО',style: TextStyle(fontSize: 20.0))))),
                              /// Месяцы
                              if(getTOScheduleList.isNotEmpty)
                                SizedBox(
                                  height: 100,
                                  child: ListView.builder(
                                    itemCount: getTOScheduleList.length,
                                    itemBuilder: (context, index) {

                                      listTo = getTOScheduleList[index];

                                      if(getTOScheduleList.isNotEmpty){
                                        if(listTo['january_to_id'] != null){
                                          String stringTest = listTo['january_to_id']['step_list_fact'].replaceAll("'", '"');
                                          listTOJanuary = json.decode(stringTest);

                                        }
                                        /// ===================================================================================
                                        if(listTo['february_to_id'] != null){
                                          String stringTestFeb = listTo['february_to_id']['step_list_fact'].replaceAll("'", '"');
                                          listTOFeb = json.decode(stringTestFeb);
                                        }
                                        /// =====================================================================================
                                        if(listTo['march_to_id'] != null){
                                          String stringTestMar = listTo['march_to_id']['step_list_fact'].replaceAll("'", '"');
                                          listTOMar = json.decode(stringTestMar);
                                        }
                                        /// =====================================================================================
                                        if(listTo['april_to_id'] != null){
                                          String stringTestApr = listTo['april_to_id']['step_list_fact'].replaceAll("'", '"');
                                          listTOApr = json.decode(stringTestApr);
                                        }
                                        /// =====================================================================================
                                        if(listTo['may_to_id'] != null){
                                          String stringTestMay = listTo['may_to_id']['step_list_fact'].replaceAll("'", '"');
                                          listTOMay = json.decode(stringTestMay);
                                        }
                                        /// =====================================================================================
                                        if(listTo['june_to_id'] != null){
                                          String stringTestJun = listTo['june_to_id']['step_list_fact'].replaceAll("'", '"');
                                          listTOJun = json.decode(stringTestJun);
                                        }
                                        /// =====================================================================================
                                        if(listTo['july_to_id'] != null){
                                          String stringTestJul = listTo['july_to_id']['step_list_fact'].replaceAll("'", '"');
                                          listTOJul = json.decode(stringTestJul);
                                        }
                                        /// =====================================================================================
                                        if(listTo['august_to_id'] != null){
                                          String stringTestAug = listTo['august_to_id']['step_list_fact'].replaceAll("'", '"');
                                          listTOAug = json.decode(stringTestAug);
                                        }
                                        /// =====================================================================================
                                        if(listTo['september_to_id'] != null){
                                          String stringTestSen = listTo['september_to_id']['step_list_fact'].replaceAll("'", '"');
                                          listTOSen = json.decode(stringTestSen);
                                        }
                                        /// =====================================================================================
                                        if(listTo['october_to_id'] != null){
                                          String stringTestOct = listTo['october_to_id']['step_list_fact'].replaceAll("'", '"');
                                          listTOOct = json.decode(stringTestOct);
                                        }
                                        /// =====================================================================================
                                        if(listTo['november_to_id'] != null){
                                          String stringTestNov = listTo['november_to_id']['step_list_fact'].replaceAll("'", '"');
                                          listTONov = json.decode(stringTestNov);
                                        }
                                        /// =====================================================================================
                                        if(listTo['december_to_id'] != null){
                                          String stringTestDec = listTo['december_to_id']['step_list_fact'].replaceAll("'", '"');
                                          listTODec = json.decode(stringTestDec);
                                        }
                                        /// =====================================================================================

                                      }

                                      return Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 20.0,vertical: 8.0),
                                        height: 80.0,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(5.0),
                                          color: Colors.white,
                                          boxShadow: const [
                                            BoxShadow(
                                              color: Colors.grey,
                                              blurRadius: 5,
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            /// Янв
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Text('Янв'),
                                                InkWell(
                                                  onTap: listTOJanuary.isEmpty
                                                      ? (){
                                                    setState(() {
                                                      showDialog(
                                                          context: context,
                                                          builder: (context) =>
                                                              AlertDialog(
                                                                  content: StreamBuilder(
                                                                      stream: myStream.stream,
                                                                      builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                                                                        return SizedBox(
                                                                          width: 800,
                                                                          child: Column(
                                                                            children: [
                                                                              /// Текст кнопка закрыть
                                                                              Row(
                                                                                children: [
                                                                                  /// Текст
                                                                                  Text(
                                                                                    'Назначить ТО месяцу ',
                                                                                    style: TextStyle(
                                                                                        fontWeight: FontWeight.w700,
                                                                                        fontSize: size.width > 570.0 ? 25.0 : 16.0),
                                                                                  ),
                                                                                  const Spacer(),
                                                                                  /// кнопка закрыть
                                                                                  IconButton(
                                                                                      onPressed: () {
                                                                                        Navigator.pop(context);
                                                                                      },
                                                                                      icon: const Icon(
                                                                                        Icons.close,
                                                                                        color: ColorApp.myColorGreenAuth,
                                                                                      )),
                                                                                ],
                                                                              ),
                                                                              const SizedBox(height: 10.0),
                                                                              /// Кнопки TO
                                                                              SizedBox(
                                                                                height: 50.0,
                                                                                child: ListView.builder(
                                                                                  scrollDirection: Axis.horizontal,
                                                                                  itemCount: templatesObject.length,
                                                                                  itemBuilder: (context, index) {
                                                                                    listInTO = templatesObject[index];
                                                                                    return InkWell(
                                                                                        onTap:(){
                                                                                          listIn = templatesObject[index];
                                                                                          addTOMon = index;
                                                                                          String stringTest = listIn['step_list'].replaceAll("'", '"');
                                                                                          listToCreatePlanetTO = json.decode(stringTest);
                                                                                          myStream.add(IntTest.indexScreens);
                                                                                        },
                                                                                        child: Padding(
                                                                                          padding: const EdgeInsets.symmetric(horizontal: 10.0),
                                                                                          child: Container(
                                                                                              padding: const EdgeInsets.symmetric(horizontal: 10.0),
                                                                                              decoration: BoxDecoration(borderRadius: BorderRadius.circular(5.0),color: addTOMon == index ? Colors.green[700] : ColorApp.myColorGreenAuth),
                                                                                              height: 30,child: Center(child: Text('${listInTO['type_act_id']['name']}',style: const TextStyle(color: Colors.white,fontWeight: FontWeight.bold)))),
                                                                                        ));
                                                                                  },
                                                                                ),
                                                                              ),
                                                                              const SizedBox(height: 10.0),
                                                                              /// Список ТО
                                                                              Column(
                                                                                children: [
                                                                                  /// Добавление нового пункта в ТО'
                                                                                  Padding(
                                                                                    padding: const EdgeInsets.all(5.0),
                                                                                    child: SizedBox(
                                                                                      height: 45.0,
                                                                                      child: Form(
                                                                                        key: keyNameTO1,
                                                                                        autovalidateMode: AutovalidateMode.onUserInteraction,
                                                                                        child: TextFormField(
                                                                                          // validator: (value) {
                                                                                          //   if (value!.isEmpty) {
                                                                                          //     return 'Заполните название';
                                                                                          //   } else {
                                                                                          //     return null;
                                                                                          //   }
                                                                                          // },
                                                                                          cursorColor: ColorApp.myColorGray,
                                                                                          controller: addNewNameTO,
                                                                                          decoration:  InputDecoration(
                                                                                              suffixIcon: IconButton(onPressed: (){
                                                                                                if(addNewNameTO.text.isNotEmpty){
                                                                                                  listToCreatePlanetTO.add({"text" : addNewNameTO.text, "bool" : false});
                                                                                                  print(addNewNameTO.text);
                                                                                                  openBoolTo1 = false;
                                                                                                  myStream.add(IntTest.indexScreens);
                                                                                                  addNewNameTO.clear();
                                                                                                }
                                                                                                // openBoolTo1 = false;
                                                                                                addNewNameTO.clear();
                                                                                                // keyNameTO1.currentState!.validate();

                                                                                              }, icon: const Icon(Icons.send,color: Colors.green)),
                                                                                              icon: IconButton(onPressed: (){
                                                                                                listToCreatePlanetTO.clear();
                                                                                                myStream.add(IntTest.indexScreens);

                                                                                              }, icon: Icon(Icons.settings_backup_restore,color: Colors.red[400])),
                                                                                              labelText: 'Добавление нового пункта в ТО',
                                                                                              border: const OutlineInputBorder(),
                                                                                              focusedBorder: const OutlineInputBorder(
                                                                                                borderSide: BorderSide(
                                                                                                    color: ColorApp.myColorGreenAuth),
                                                                                              ),
                                                                                              // labelText: 'Документ',
                                                                                              labelStyle:
                                                                                              const TextStyle(color: ColorApp.myColorGray)),
                                                                                        ),
                                                                                      ),
                                                                                    ),
                                                                                  ),
                                                                                  const SizedBox(height: 15.0),
                                                                                  /// Список ТО
                                                                                  SizedBox(
                                                                                    height: MediaQuery.of(context).size.height * 0.50,
                                                                                    child: ListView.builder(
                                                                                      itemCount: listToCreatePlanetTO.length,
                                                                                      itemBuilder: (context, index) {
                                                                                        final text = listToCreatePlanetTO[index]['text'];
                                                                                        return Row(
                                                                                          crossAxisAlignment: CrossAxisAlignment.center,
                                                                                          children: [
                                                                                            Expanded(
                                                                                              child: Padding(
                                                                                                padding: const EdgeInsets.only(left: 5.0, right: 5.0,bottom: 5.0),
                                                                                                child: Container(
                                                                                                  padding: const EdgeInsets.all(10.0),
                                                                                                  decoration: BoxDecoration(
                                                                                                      borderRadius: BorderRadius.circular(5.0),
                                                                                                      border: Border.all(color: Colors.grey, width: 1.5)
                                                                                                  ),
                                                                                                  child: Text('$text'),
                                                                                                ),
                                                                                              ),
                                                                                            ),
                                                                                            IconButton(
                                                                                                onPressed:  (){
                                                                                                  listToCreatePlanetTO.removeAt(index);
                                                                                                  myStream.add(IntTest.indexScreens);
                                                                                                }, icon: const Icon(Icons.delete_outline,color: Colors.red)),
                                                                                          ],
                                                                                        );
                                                                                      },
                                                                                    ),
                                                                                  ),

                                                                                ],
                                                                              ),
                                                                              const Spacer(),
                                                                              /// Кнопка Добавить
                                                                              Column(
                                                                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                                                                children: [
                                                                                  ElevatedButton(
                                                                                    style: ElevatedButton.styleFrom(
                                                                                        backgroundColor: listToCreatePlanetTO.isNotEmpty
                                                                                            ?  ColorApp.myColorGreenAuth : Colors.grey,
                                                                                        padding: const EdgeInsets.symmetric(vertical: 20.0)),
                                                                                    onPressed: listToCreatePlanetTO.isNotEmpty
                                                                                        ? () async {

                                                                                      /// ===========================================================
                                                                                      myGetPlanetTO['numberTo'] = listIn['type_act_id']['name'];
                                                                                      myGetPlanetTO['stepListTO'] = jsonEncode(listToCreatePlanetTO);
                                                                                      /// ===========================================================

                                                                                      /// Создаем факт акт
                                                                                      await creationFactActList(listIn['id']); // готово

                                                                                      /// Изменить ТО Обьекту
                                                                                      await changeTOGraphics('january_to_id', intMonTOTest, getTOScheduleList[0]['id']);


                                                                                      await getTOScheduleIdObject(IntTest.pressHover);


                                                                                      myStream.add(IntTest.indexScreens);
                                                                                      Navigator.pop(context);
                                                                                      setState(() {});
                                                                                    }
                                                                                        : (){},
                                                                                    child: Text(listToCreatePlanetTO.isNotEmpty
                                                                                        ? 'Добавить' : 'Создайте список',
                                                                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                                                                    ),
                                                                                  ),
                                                                                ],
                                                                              ),
                                                                            ],
                                                                          ),
                                                                        );


                                                                        //   SizedBox(
                                                                        //   width: 600.0,
                                                                        //   height: 200.0,
                                                                        //   child:
                                                                        //   listSelectedObject['data']['factory_model_id']['type_object_id']['id'] == 1
                                                                        //       ? const TOLiftNotMO() :
                                                                        //   listSelectedObject['data']['factory_model_id']['type_object_id']['id'] == 2
                                                                        //       ? const TOLiftMO() :
                                                                        //   listSelectedObject['data']['factory_model_id']['type_object_id']['id'] == 3
                                                                        //       ? const TOEscalatorTraveller() :
                                                                        //   listSelectedObject['data']['factory_model_id']['type_object_id']['id'] == 4
                                                                        //       ? const TOEscalatorTraveller() :
                                                                        //   listSelectedObject['data']['factory_model_id']['type_object_id']['id'] == 5
                                                                        //       ? const TOCargoDisabledPersonLift() : const TOCargoDisabledPersonLift(),
                                                                        // );
                                                                      })));
                                                    });}
                                                      : (){
                                                    // print(listTo['id']);
                                                    intMon = 1;
                                                    // print(monTO);
                                                    monTO = 'january_to_id';
                                                    myStream.add(IntTest.indexScreens);
                                                    setState(() {});
                                                    if(listTOJanuary['stepListTO'] != null){
                                                      getTOScheduleIdObject(IntTest.pressHover);
                                                      intMonTOTes = listTo['january_to_id']['id'];
                                                      String stringTestText = listTOJanuary['stepListTO'].replaceAll("'", '"');
                                                      listTOJanuaryText = json.decode(stringTestText);
                                                      listTOMonTaskText = listTOJanuaryText;
                                                      myStream.add(IntTest.indexScreens);
                                                      setState(() {});
                                                    }else{
                                                      listTOMonTaskText.clear();
                                                    }
                                                  },
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      borderRadius: BorderRadius.circular(5.0),
                                                      color: intMon == 1 ? Colors.green : ColorApp.myColorGreen,
                                                    ),
                                                    width: 40,
                                                    height: 40,
                                                    child: Center(child: listTOJanuary.isNotEmpty ? Text('${listTOJanuary['numberTo']}',style: const TextStyle(color: Colors.white, fontSize: 12.0)) : const Icon(Icons.add,color: Colors.white)),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(width: 10.0),
                                            /// Фев
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Text('Фев'),
                                                InkWell(
                                                  onTap: listTOFeb.isEmpty
                                                      ? (){setState(() {
                                                    showDialog(
                                                        context: context,
                                                        builder: (context) =>
                                                            AlertDialog(
                                                                content: StreamBuilder(
                                                                    stream: myStream.stream,
                                                                    builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                                                                      return SizedBox(
                                                                        width: 800,
                                                                        child: Column(
                                                                          children: [
                                                                            /// Текст кнопка закрыть
                                                                            Row(
                                                                              children: [
                                                                                /// Текст
                                                                                Text(
                                                                                  'Назначить ТО месяцу ',
                                                                                  style: TextStyle(
                                                                                      fontWeight: FontWeight.w700,
                                                                                      fontSize: size.width > 570.0 ? 25.0 : 16.0),
                                                                                ),
                                                                                const Spacer(),
                                                                                /// кнопка закрыть
                                                                                IconButton(
                                                                                    onPressed: () {
                                                                                      Navigator.pop(context);
                                                                                    },
                                                                                    icon: const Icon(
                                                                                      Icons.close,
                                                                                      color: ColorApp.myColorGreenAuth,
                                                                                    )),
                                                                              ],
                                                                            ),
                                                                            const SizedBox(height: 10.0),
                                                                            /// Кнопки TO
                                                                            SizedBox(
                                                                              height: 50.0,
                                                                              child: ListView.builder(
                                                                                scrollDirection: Axis.horizontal,
                                                                                itemCount: templatesObject.length,
                                                                                itemBuilder: (context, index) {
                                                                                  listInTO = templatesObject[index];
                                                                                  // print('=====================================');
                                                                                  // print(listInTO['id']);
                                                                                  // // print( listInTO['type_act_id']['name']);
                                                                                  // print('=====================================');
                                                                                  return InkWell(
                                                                                      onTap:(){
                                                                                        listIn = templatesObject[index];
                                                                                        addTOMon = index;
                                                                                        print('+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');
                                                                                        print(listIn['type_act_id']['id']);
                                                                                        // listGetSelectedTemplateTO = listIn['step_list'];
                                                                                        // print(index);
                                                                                        String stringTest = listIn['step_list'].replaceAll("'", '"');
                                                                                        listToCreatePlanetTO = json.decode(stringTest);



                                                                                        print('+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');


                                                                                        myStream.add(IntTest.indexScreens);
                                                                                      },
                                                                                      child: Padding(
                                                                                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                                                                                        child: Container(
                                                                                            padding: const EdgeInsets.symmetric(horizontal: 10.0),
                                                                                            decoration: BoxDecoration(borderRadius: BorderRadius.circular(5.0),color: addTOMon == index ? Colors.green[700] : ColorApp.myColorGreenAuth),
                                                                                            height: 30,child: Center(child: Text('${listInTO['type_act_id']['name']}',style: const TextStyle(color: Colors.white,fontWeight: FontWeight.bold)))),
                                                                                      ));
                                                                                },
                                                                              ),
                                                                            ),
                                                                            const SizedBox(height: 10.0),
                                                                            Column(
                                                                              children: [
                                                                                /// Добавление нового пункта в ТО'
                                                                                Padding(
                                                                                  padding: const EdgeInsets.all(5.0),
                                                                                  child: SizedBox(
                                                                                    height: 45.0,
                                                                                    child: Form(
                                                                                      key: keyNameTO1,
                                                                                      autovalidateMode: AutovalidateMode.onUserInteraction,
                                                                                      child: TextFormField(
                                                                                        // validator: (value) {
                                                                                        //   if (value!.isEmpty) {
                                                                                        //     return 'Заполните название';
                                                                                        //   } else {
                                                                                        //     return null;
                                                                                        //   }
                                                                                        // },
                                                                                        cursorColor: ColorApp.myColorGray,
                                                                                        controller: addNewNameTO,
                                                                                        decoration:  InputDecoration(
                                                                                            suffixIcon: IconButton(onPressed: (){
                                                                                              if(addNewNameTO.text.isNotEmpty){
                                                                                                listToCreatePlanetTO.add({"text" : addNewNameTO.text, "bool" : false});
                                                                                                print(addNewNameTO.text);
                                                                                                openBoolTo1 = false;
                                                                                                myStream.add(IntTest.indexScreens);
                                                                                                addNewNameTO.clear();
                                                                                              }
                                                                                              // openBoolTo1 = false;
                                                                                              addNewNameTO.clear();
                                                                                              // keyNameTO1.currentState!.validate();

                                                                                            }, icon: const Icon(Icons.send,color: Colors.green)),
                                                                                            icon: IconButton(onPressed: (){
                                                                                              listToCreatePlanetTO.clear();
                                                                                              myStream.add(IntTest.indexScreens);

                                                                                            }, icon: Icon(Icons.settings_backup_restore,color: Colors.red[400])),
                                                                                            labelText: 'Добавление нового пункта в ТО',
                                                                                            border: const OutlineInputBorder(),
                                                                                            focusedBorder: const OutlineInputBorder(
                                                                                              borderSide: BorderSide(
                                                                                                  color: ColorApp.myColorGreenAuth),
                                                                                            ),
                                                                                            // labelText: 'Документ',
                                                                                            labelStyle:
                                                                                            const TextStyle(color: ColorApp.myColorGray)),
                                                                                      ),
                                                                                    ),
                                                                                  ),
                                                                                ),
                                                                                const SizedBox(height: 15.0),
                                                                                /// Список ТО
                                                                                SizedBox(
                                                                                  height: MediaQuery.of(context).size.height * 0.50,
                                                                                  child: ListView.builder(
                                                                                    itemCount: listToCreatePlanetTO.length,
                                                                                    itemBuilder: (context, index) {
                                                                                      final text = listToCreatePlanetTO[index]['text'];
                                                                                      return Row(
                                                                                        crossAxisAlignment: CrossAxisAlignment.center,
                                                                                        children: [
                                                                                          Expanded(
                                                                                            child: Padding(
                                                                                              padding: const EdgeInsets.only(left: 5.0, right: 5.0,bottom: 5.0),
                                                                                              child: Container(
                                                                                                padding: const EdgeInsets.all(10.0),
                                                                                                decoration: BoxDecoration(
                                                                                                    borderRadius: BorderRadius.circular(5.0),
                                                                                                    border: Border.all(color: Colors.grey, width: 1.5)
                                                                                                ),
                                                                                                child: Text('$text'),
                                                                                              ),
                                                                                            ),
                                                                                          ),
                                                                                          IconButton(
                                                                                              onPressed:  (){
                                                                                                listToCreatePlanetTO.removeAt(index);
                                                                                                myStream.add(IntTest.indexScreens);
                                                                                              }, icon: const Icon(Icons.delete_outline,color: Colors.red)),
                                                                                        ],
                                                                                      );
                                                                                    },
                                                                                  ),
                                                                                ),

                                                                              ],
                                                                            ),
                                                                            const Spacer(),
                                                                            /// Кнопка Добавить
                                                                            Column(
                                                                              crossAxisAlignment: CrossAxisAlignment.stretch,
                                                                              children: [
                                                                                ElevatedButton(
                                                                                  style: ElevatedButton.styleFrom(
                                                                                      backgroundColor: listToCreatePlanetTO.isNotEmpty
                                                                                          ?  ColorApp.myColorGreenAuth : Colors.grey,
                                                                                      padding: const EdgeInsets.symmetric(vertical: 20.0)),
                                                                                  onPressed: listToCreatePlanetTO.isNotEmpty
                                                                                      ? () async {
                                                                                    /// ==============
                                                                                    myGetPlanetTO['numberTo'] = listIn['type_act_id']['name'] ;
                                                                                    myGetPlanetTO['stepListTO'] = jsonEncode(listToCreatePlanetTO) ;
                                                                                    /// ==================

                                                                                    /// Создаем факт акт
                                                                                    await creationFactActList(listIn['id']); // готово

                                                                                    /// Изменить ТО Обьекту
                                                                                    await changeTOGraphics('february_to_id', intMonTOTest, getTOScheduleList[0]['id']);

                                                                                    await getTOScheduleIdObject(IntTest.pressHover);


                                                                                    myStream.add(IntTest.indexScreens);
                                                                                    Navigator.pop(context);
                                                                                    setState(() {});
                                                                                  }
                                                                                      : (){},
                                                                                  child: Text(listToCreatePlanetTO.isNotEmpty
                                                                                      ? 'Добавить' : 'Создайте список',
                                                                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                                                                  ),
                                                                                ),
                                                                              ],
                                                                            ),
                                                                          ],
                                                                        ),
                                                                      );
                                                                    })));
                                                  });}
                                                      : (){
                                                    setState(() {
                                                      intMon = 2;
                                                      monTO = 'february_to_id';
                                                      // print(monTO);
                                                      if(listTOFeb['stepListTO'] != null){
                                                        getTOScheduleIdObject(IntTest.pressHover);
                                                        intMonTOTes = listTo['february_to_id']['id'];
                                                        String stringTestText = listTOFeb['stepListTO'].replaceAll("'", '"');
                                                        listTOJanuaryText = json.decode(stringTestText);
                                                        listTOMonTaskText = listTOJanuaryText;
                                                        myStream.add(IntTest.indexScreens);
                                                      }else{
                                                        listTOMonTaskText.clear();
                                                      }
                                                    });
                                                  },
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      borderRadius: BorderRadius.circular(5.0),
                                                      color: intMon == 2 ? Colors.green : ColorApp.myColorGreen,
                                                    ),
                                                    width: 40,
                                                    height: 40,
                                                    child: Center(child: listTOFeb.isNotEmpty ? Text('${listTOFeb['numberTo']}',style: const TextStyle(color: Colors.white, fontSize: 12.0)) : const Icon(Icons.add,color: Colors.white)),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(width: 10.0),
                                            /// Мар
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Text('Мар'),
                                                InkWell(
                                                  onTap: listTOMar.isEmpty
                                                      ? (){
                                                    setState(() {
                                                      showDialog(
                                                          context: context,
                                                          builder: (context) =>
                                                              AlertDialog(
                                                                  content: StreamBuilder(
                                                                      stream: myStream.stream,
                                                                      builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                                                                        return SizedBox(
                                                                          width: 800,
                                                                          child: Column(
                                                                            children: [
                                                                              /// Текст кнопка закрыть
                                                                              Row(
                                                                                children: [
                                                                                  /// Текст
                                                                                  Text(
                                                                                    'Назначить ТО месяцу ',
                                                                                    style: TextStyle(
                                                                                        fontWeight: FontWeight.w700,
                                                                                        fontSize: size.width > 570.0 ? 25.0 : 16.0),
                                                                                  ),
                                                                                  const Spacer(),
                                                                                  /// кнопка закрыть
                                                                                  IconButton(
                                                                                      onPressed: () {
                                                                                        Navigator.pop(context);
                                                                                      },
                                                                                      icon: const Icon(
                                                                                        Icons.close,
                                                                                        color: ColorApp.myColorGreenAuth,
                                                                                      )),
                                                                                ],
                                                                              ),
                                                                              const SizedBox(height: 10.0),
                                                                              /// Кнопки TO
                                                                              SizedBox(
                                                                                height: 50.0,
                                                                                child: ListView.builder(
                                                                                  scrollDirection: Axis.horizontal,
                                                                                  itemCount: templatesObject.length,
                                                                                  itemBuilder: (context, index) {
                                                                                    listInTO = templatesObject[index];
                                                                                    // print('=====================================');
                                                                                    // print(listInTO['id']);
                                                                                    // // print( listInTO['type_act_id']['name']);
                                                                                    // print('=====================================');
                                                                                    return InkWell(
                                                                                        onTap:(){
                                                                                          listIn = templatesObject[index];
                                                                                          addTOMon = index;
                                                                                          print('+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');
                                                                                          print(listIn['type_act_id']['id']);
                                                                                          // listGetSelectedTemplateTO = listIn['step_list'];
                                                                                          // print(index);
                                                                                          String stringTest = listIn['step_list'].replaceAll("'", '"');
                                                                                          listToCreatePlanetTO = json.decode(stringTest);



                                                                                          print('+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');


                                                                                          myStream.add(IntTest.indexScreens);
                                                                                        },
                                                                                        child: Padding(
                                                                                          padding: const EdgeInsets.symmetric(horizontal: 10.0),
                                                                                          child: Container(
                                                                                              padding: const EdgeInsets.symmetric(horizontal: 10.0),
                                                                                              decoration: BoxDecoration(borderRadius: BorderRadius.circular(5.0),color: addTOMon == index ? Colors.green[700] : ColorApp.myColorGreenAuth),
                                                                                              height: 30,child: Center(child: Text('${listInTO['type_act_id']['name']}',style: const TextStyle(color: Colors.white,fontWeight: FontWeight.bold)))),
                                                                                        ));
                                                                                  },
                                                                                ),
                                                                              ),
                                                                              const SizedBox(height: 10.0),
                                                                              Column(
                                                                                children: [
                                                                                  /// Добавление нового пункта в ТО'
                                                                                  Padding(
                                                                                    padding: const EdgeInsets.all(5.0),
                                                                                    child: SizedBox(
                                                                                      height: 45.0,
                                                                                      child: Form(
                                                                                        key: keyNameTO1,
                                                                                        autovalidateMode: AutovalidateMode.onUserInteraction,
                                                                                        child: TextFormField(
                                                                                          // validator: (value) {
                                                                                          //   if (value!.isEmpty) {
                                                                                          //     return 'Заполните название';
                                                                                          //   } else {
                                                                                          //     return null;
                                                                                          //   }
                                                                                          // },
                                                                                          cursorColor: ColorApp.myColorGray,
                                                                                          controller: addNewNameTO,
                                                                                          decoration:  InputDecoration(
                                                                                              suffixIcon: IconButton(onPressed: (){
                                                                                                if(addNewNameTO.text.isNotEmpty){
                                                                                                  listToCreatePlanetTO.add({"text" : addNewNameTO.text, "bool" : false});
                                                                                                  print(addNewNameTO.text);
                                                                                                  openBoolTo1 = false;
                                                                                                  myStream.add(IntTest.indexScreens);
                                                                                                  addNewNameTO.clear();
                                                                                                }
                                                                                                // openBoolTo1 = false;
                                                                                                addNewNameTO.clear();
                                                                                                // keyNameTO1.currentState!.validate();

                                                                                              }, icon: const Icon(Icons.send,color: Colors.green)),
                                                                                              icon: IconButton(onPressed: (){
                                                                                                listToCreatePlanetTO.clear();
                                                                                                myStream.add(IntTest.indexScreens);

                                                                                              }, icon: Icon(Icons.settings_backup_restore,color: Colors.red[400])),
                                                                                              labelText: 'Добавление нового пункта в ТО',
                                                                                              border: const OutlineInputBorder(),
                                                                                              focusedBorder: const OutlineInputBorder(
                                                                                                borderSide: BorderSide(
                                                                                                    color: ColorApp.myColorGreenAuth),
                                                                                              ),
                                                                                              // labelText: 'Документ',
                                                                                              labelStyle:
                                                                                              const TextStyle(color: ColorApp.myColorGray)),
                                                                                        ),
                                                                                      ),
                                                                                    ),
                                                                                  ),
                                                                                  const SizedBox(height: 15.0),
                                                                                  /// Список ТО
                                                                                  SizedBox(
                                                                                    height: MediaQuery.of(context).size.height * 0.50,
                                                                                    child: ListView.builder(
                                                                                      itemCount: listToCreatePlanetTO.length,
                                                                                      itemBuilder: (context, index) {
                                                                                        final text = listToCreatePlanetTO[index]['text'];
                                                                                        return Row(
                                                                                          crossAxisAlignment: CrossAxisAlignment.center,
                                                                                          children: [
                                                                                            Expanded(
                                                                                              child: Padding(
                                                                                                padding: const EdgeInsets.only(left: 5.0, right: 5.0,bottom: 5.0),
                                                                                                child: Container(
                                                                                                  padding: const EdgeInsets.all(10.0),
                                                                                                  decoration: BoxDecoration(
                                                                                                      borderRadius: BorderRadius.circular(5.0),
                                                                                                      border: Border.all(color: Colors.grey, width: 1.5)
                                                                                                  ),
                                                                                                  child: Text('$text'),
                                                                                                ),
                                                                                              ),
                                                                                            ),
                                                                                            IconButton(
                                                                                                onPressed:  (){
                                                                                                  listToCreatePlanetTO.removeAt(index);
                                                                                                  myStream.add(IntTest.indexScreens);
                                                                                                }, icon: const Icon(Icons.delete_outline,color: Colors.red)),
                                                                                          ],
                                                                                        );
                                                                                      },
                                                                                    ),
                                                                                  ),

                                                                                ],
                                                                              ),
                                                                              const Spacer(),
                                                                              /// Кнопка Добавить
                                                                              Column(
                                                                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                                                                children: [
                                                                                  ElevatedButton(
                                                                                    style: ElevatedButton.styleFrom(
                                                                                        backgroundColor: listToCreatePlanetTO.isNotEmpty
                                                                                            ?  ColorApp.myColorGreenAuth : Colors.grey,
                                                                                        padding: const EdgeInsets.symmetric(vertical: 20.0)),
                                                                                    onPressed: listToCreatePlanetTO.isNotEmpty
                                                                                        ? () async {
                                                                                      /// ==============
                                                                                      myGetPlanetTO['numberTo'] = listIn['type_act_id']['name'] ;
                                                                                      myGetPlanetTO['stepListTO'] = jsonEncode(listToCreatePlanetTO) ;
                                                                                      /// ==================

                                                                                      /// Создаем факт акт
                                                                                      await creationFactActList(listIn['id']); // готово

                                                                                      /// Изменить ТО Обьекту
                                                                                      await changeTOGraphics('march_to_id', intMonTOTest, getTOScheduleList[0]['id']);
                                                                                      await getTOScheduleIdObject(IntTest.pressHover);
                                                                                      myStream.add(IntTest.indexScreens);
                                                                                      Navigator.pop(context);
                                                                                      setState(() {});
                                                                                    }
                                                                                        : (){},
                                                                                    child: Text(listToCreatePlanetTO.isNotEmpty
                                                                                        ? 'Добавить' : 'Создайте список',
                                                                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                                                                    ),
                                                                                  ),
                                                                                ],
                                                                              ),
                                                                            ],
                                                                          ),
                                                                        );

                                                                      })));
                                                    });
                                                    /// =================================================================================
                                                    // print(listTo['id']);
                                                    // intMon = 1;
                                                    // print(monTO);
                                                    // monTO = 'january_to_id';
                                                    // myStream.add(IntTest.indexScreens);
                                                    // setState(() {});
                                                    // if(listTOJanuary['step_list'] != null){
                                                    //   String stringTestText = listTOJanuary['step_list'].replaceAll("'", '"');
                                                    //   listTOJanuaryText = json.decode(stringTestText);
                                                    //   listTOMonTaskText = listTOJanuaryText;
                                                    //   myStream.add(IntTest.indexScreens);
                                                    //   setState(() {});
                                                    // }else{
                                                    //   listTOMonTaskText.clear();
                                                    // }
                                                    /// =================================================================================
                                                  }
                                                      : (){
                                                    setState(() {
                                                      intMon = 3;
                                                      monTO = 'march_to_id';
                                                      if(listTOMar['stepListTO'] != null){
                                                        getTOScheduleIdObject(IntTest.pressHover);
                                                        intMonTOTes = listTo['march_to_id']['id'];
                                                        String stringTestText = listTOMar['stepListTO'].replaceAll("'", '"');
                                                        listTOJanuaryText = json.decode(stringTestText);
                                                        listTOMonTaskText = listTOJanuaryText;
                                                        myStream.add(IntTest.indexScreens);
                                                      }else{
                                                        listTOMonTaskText.clear();
                                                      }
                                                    });
                                                  },
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      borderRadius: BorderRadius.circular(5.0),
                                                      color: intMon == 3 ? Colors.green : ColorApp.myColorGreen,
                                                    ),
                                                    width: 40,
                                                    height: 40,
                                                    child: Center(child: listTOMar.isNotEmpty ? Text('${listTOMar['numberTo']}',style: const TextStyle(color: Colors.white, fontSize: 12.0)) : const Icon(Icons.add,color: Colors.white)),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(width: 10.0),
                                            /// Апр
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Text('Апр'),
                                                InkWell(
                                                  onTap: listTOApr.isEmpty
                                                      ? (){
                                                    setState(() {
                                                      showDialog(
                                                          context: context,
                                                          builder: (context) =>
                                                              AlertDialog(
                                                                  content: StreamBuilder(
                                                                      stream: myStream.stream,
                                                                      builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                                                                        return SizedBox(
                                                                          width: 800,
                                                                          child: Column(
                                                                            children: [
                                                                              /// Текст кнопка закрыть
                                                                              Row(
                                                                                children: [
                                                                                  /// Текст
                                                                                  Text(
                                                                                    'Назначить ТО месяцу ',
                                                                                    style: TextStyle(
                                                                                        fontWeight: FontWeight.w700,
                                                                                        fontSize: size.width > 570.0 ? 25.0 : 16.0),
                                                                                  ),
                                                                                  const Spacer(),
                                                                                  /// кнопка закрыть
                                                                                  IconButton(
                                                                                      onPressed: () {
                                                                                        Navigator.pop(context);
                                                                                      },
                                                                                      icon: const Icon(
                                                                                        Icons.close,
                                                                                        color: ColorApp.myColorGreenAuth,
                                                                                      )),
                                                                                ],
                                                                              ),
                                                                              const SizedBox(height: 10.0),
                                                                              /// Кнопки TO
                                                                              SizedBox(
                                                                                height: 50.0,
                                                                                child: ListView.builder(
                                                                                  scrollDirection: Axis.horizontal,
                                                                                  itemCount: templatesObject.length,
                                                                                  itemBuilder: (context, index) {
                                                                                    listInTO = templatesObject[index];
                                                                                    // print('=====================================');
                                                                                    // print(listInTO['id']);
                                                                                    // // print( listInTO['type_act_id']['name']);
                                                                                    // print('=====================================');
                                                                                    return InkWell(
                                                                                        onTap:(){
                                                                                          listIn = templatesObject[index];
                                                                                          addTOMon = index;
                                                                                          print('+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');
                                                                                          print(listIn['type_act_id']['id']);
                                                                                          // listGetSelectedTemplateTO = listIn['step_list'];
                                                                                          // print(index);
                                                                                          String stringTest = listIn['step_list'].replaceAll("'", '"');
                                                                                          listToCreatePlanetTO = json.decode(stringTest);



                                                                                          print('+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');


                                                                                          myStream.add(IntTest.indexScreens);
                                                                                        },
                                                                                        child: Padding(
                                                                                          padding: const EdgeInsets.symmetric(horizontal: 10.0),
                                                                                          child: Container(
                                                                                              padding: const EdgeInsets.symmetric(horizontal: 10.0),
                                                                                              decoration: BoxDecoration(borderRadius: BorderRadius.circular(5.0),color: addTOMon == index ? Colors.green[700] : ColorApp.myColorGreenAuth),
                                                                                              height: 30,child: Center(child: Text('${listInTO['type_act_id']['name']}',style: const TextStyle(color: Colors.white,fontWeight: FontWeight.bold)))),
                                                                                        ));
                                                                                  },
                                                                                ),
                                                                              ),
                                                                              const SizedBox(height: 10.0),
                                                                              Column(
                                                                                children: [
                                                                                  /// Добавление нового пункта в ТО'
                                                                                  Padding(
                                                                                    padding: const EdgeInsets.all(5.0),
                                                                                    child: SizedBox(
                                                                                      height: 45.0,
                                                                                      child: Form(
                                                                                        key: keyNameTO1,
                                                                                        autovalidateMode: AutovalidateMode.onUserInteraction,
                                                                                        child: TextFormField(
                                                                                          // validator: (value) {
                                                                                          //   if (value!.isEmpty) {
                                                                                          //     return 'Заполните название';
                                                                                          //   } else {
                                                                                          //     return null;
                                                                                          //   }
                                                                                          // },
                                                                                          cursorColor: ColorApp.myColorGray,
                                                                                          controller: addNewNameTO,
                                                                                          decoration:  InputDecoration(
                                                                                              suffixIcon: IconButton(onPressed: (){
                                                                                                if(addNewNameTO.text.isNotEmpty){
                                                                                                  listToCreatePlanetTO.add({"text" : addNewNameTO.text, "bool" : false});
                                                                                                  print(addNewNameTO.text);
                                                                                                  openBoolTo1 = false;
                                                                                                  myStream.add(IntTest.indexScreens);
                                                                                                  addNewNameTO.clear();
                                                                                                }
                                                                                                // openBoolTo1 = false;
                                                                                                addNewNameTO.clear();
                                                                                                // keyNameTO1.currentState!.validate();

                                                                                              }, icon: const Icon(Icons.send,color: Colors.green)),
                                                                                              icon: IconButton(onPressed: (){
                                                                                                listToCreatePlanetTO.clear();
                                                                                                myStream.add(IntTest.indexScreens);

                                                                                              }, icon: Icon(Icons.settings_backup_restore,color: Colors.red[400])),
                                                                                              labelText: 'Добавление нового пункта в ТО',
                                                                                              border: const OutlineInputBorder(),
                                                                                              focusedBorder: const OutlineInputBorder(
                                                                                                borderSide: BorderSide(
                                                                                                    color: ColorApp.myColorGreenAuth),
                                                                                              ),
                                                                                              // labelText: 'Документ',
                                                                                              labelStyle:
                                                                                              const TextStyle(color: ColorApp.myColorGray)),
                                                                                        ),
                                                                                      ),
                                                                                    ),
                                                                                  ),
                                                                                  const SizedBox(height: 15.0),
                                                                                  /// Список ТО
                                                                                  SizedBox(
                                                                                    height: MediaQuery.of(context).size.height * 0.50,
                                                                                    child: ListView.builder(
                                                                                      itemCount: listToCreatePlanetTO.length,
                                                                                      itemBuilder: (context, index) {
                                                                                        final text = listToCreatePlanetTO[index]['text'];
                                                                                        return Row(
                                                                                          crossAxisAlignment: CrossAxisAlignment.center,
                                                                                          children: [
                                                                                            Expanded(
                                                                                              child: Padding(
                                                                                                padding: const EdgeInsets.only(left: 5.0, right: 5.0,bottom: 5.0),
                                                                                                child: Container(
                                                                                                  padding: const EdgeInsets.all(10.0),
                                                                                                  decoration: BoxDecoration(
                                                                                                      borderRadius: BorderRadius.circular(5.0),
                                                                                                      border: Border.all(color: Colors.grey, width: 1.5)
                                                                                                  ),
                                                                                                  child: Text('$text'),
                                                                                                ),
                                                                                              ),
                                                                                            ),
                                                                                            IconButton(
                                                                                                onPressed:  (){
                                                                                                  listToCreatePlanetTO.removeAt(index);
                                                                                                  myStream.add(IntTest.indexScreens);
                                                                                                }, icon: const Icon(Icons.delete_outline,color: Colors.red)),
                                                                                          ],
                                                                                        );
                                                                                      },
                                                                                    ),
                                                                                  ),

                                                                                ],
                                                                              ),
                                                                              const Spacer(),
                                                                              /// Кнопка Добавить
                                                                              Column(
                                                                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                                                                children: [
                                                                                  ElevatedButton(
                                                                                    style: ElevatedButton.styleFrom(
                                                                                        backgroundColor: listToCreatePlanetTO.isNotEmpty
                                                                                            ?  ColorApp.myColorGreenAuth : Colors.grey,
                                                                                        padding: const EdgeInsets.symmetric(vertical: 20.0)),
                                                                                    onPressed: listToCreatePlanetTO.isNotEmpty
                                                                                        ? () async {
                                                                                      /// ==============
                                                                                      myGetPlanetTO['numberTo'] = listIn['type_act_id']['name'] ;
                                                                                      myGetPlanetTO['stepListTO'] = jsonEncode(listToCreatePlanetTO) ;
                                                                                      /// ==================

                                                                                      /// Создаем факт акт
                                                                                      await creationFactActList(listIn['id']); // готово

                                                                                      /// Изменить ТО Обьекту
                                                                                      await changeTOGraphics('april_to_id', intMonTOTest, getTOScheduleList[0]['id']);
                                                                                      await getTOScheduleIdObject(IntTest.pressHover);
                                                                                      myStream.add(IntTest.indexScreens);
                                                                                      Navigator.pop(context);
                                                                                      setState(() {});
                                                                                    }
                                                                                        : (){},
                                                                                    child: Text(listToCreatePlanetTO.isNotEmpty
                                                                                        ? 'Добавить' : 'Создайте список',
                                                                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                                                                    ),
                                                                                  ),
                                                                                ],
                                                                              ),
                                                                            ],
                                                                          ),
                                                                        );

                                                                      })));
                                                    });
                                                    /// =================================================================================
                                                    // print(listTo['id']);
                                                    // intMon = 1;
                                                    // print(monTO);
                                                    // monTO = 'january_to_id';
                                                    // myStream.add(IntTest.indexScreens);
                                                    // setState(() {});
                                                    // if(listTOJanuary['step_list'] != null){
                                                    //   String stringTestText = listTOJanuary['step_list'].replaceAll("'", '"');
                                                    //   listTOJanuaryText = json.decode(stringTestText);
                                                    //   listTOMonTaskText = listTOJanuaryText;
                                                    //   myStream.add(IntTest.indexScreens);
                                                    //   setState(() {});
                                                    // }else{
                                                    //   listTOMonTaskText.clear();
                                                    // }
                                                    /// =================================================================================
                                                  }
                                                      : (){
                                                    setState(() {
                                                      intMon = 4;
                                                      monTO = 'april_to_id';
                                                      if(listTOApr['stepListTO'] != null){
                                                        getTOScheduleIdObject(IntTest.pressHover);
                                                        intMonTOTes = listTo['april_to_id']['id'];
                                                        String stringTestText = listTOApr['stepListTO'].replaceAll("'", '"');
                                                        listTOJanuaryText = json.decode(stringTestText);
                                                        listTOMonTaskText = listTOJanuaryText;
                                                        myStream.add(IntTest.indexScreens);
                                                      }else{
                                                        listTOMonTaskText.clear();
                                                      }
                                                    });
                                                  },
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      borderRadius: BorderRadius.circular(5.0),
                                                      color: intMon == 4 ? Colors.green : ColorApp.myColorGreen,
                                                    ),
                                                    width: 40,
                                                    height: 40,
                                                    child: Center(child: listTOApr.isNotEmpty ? Text('${listTOApr['numberTo']}',style: const TextStyle(color: Colors.white, fontSize: 12.0)) : const Icon(Icons.add,color: Colors.white)),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(width: 10.0),
                                            /// Май
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Text('Май'),
                                                InkWell(
                                                  onTap: listTOMay.isEmpty
                                                      ? (){
                                                    setState(() {
                                                      showDialog(
                                                          context: context,
                                                          builder: (context) =>
                                                              AlertDialog(
                                                                  content: StreamBuilder(
                                                                      stream: myStream.stream,
                                                                      builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                                                                        return SizedBox(
                                                                          width: 800,
                                                                          child: Column(
                                                                            children: [
                                                                              /// Текст кнопка закрыть
                                                                              Row(
                                                                                children: [
                                                                                  /// Текст
                                                                                  Text(
                                                                                    'Назначить ТО месяцу ',
                                                                                    style: TextStyle(
                                                                                        fontWeight: FontWeight.w700,
                                                                                        fontSize: size.width > 570.0 ? 25.0 : 16.0),
                                                                                  ),
                                                                                  const Spacer(),
                                                                                  /// кнопка закрыть
                                                                                  IconButton(
                                                                                      onPressed: () {
                                                                                        Navigator.pop(context);
                                                                                      },
                                                                                      icon: const Icon(
                                                                                        Icons.close,
                                                                                        color: ColorApp.myColorGreenAuth,
                                                                                      )),
                                                                                ],
                                                                              ),
                                                                              const SizedBox(height: 10.0),
                                                                              /// Кнопки TO
                                                                              SizedBox(
                                                                                height: 50.0,
                                                                                child: ListView.builder(
                                                                                  scrollDirection: Axis.horizontal,
                                                                                  itemCount: templatesObject.length,
                                                                                  itemBuilder: (context, index) {
                                                                                    listInTO = templatesObject[index];
                                                                                    // print('=====================================');
                                                                                    // print( listInTO['type_act_id']['name']);
                                                                                    // print('=====================================');
                                                                                    return InkWell(
                                                                                        onTap:(){
                                                                                          listIn = templatesObject[index];
                                                                                          addTOMon = index;
                                                                                          // print('+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');
                                                                                          // print(listIn['type_act_id']['name']);
                                                                                          // listGetSelectedTemplateTO = listIn['step_list'];
                                                                                          // print(index);
                                                                                          String stringTest = listIn['step_list'].replaceAll("'", '"');
                                                                                          listToCreatePlanetTO = json.decode(stringTest);



                                                                                          // print('+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');


                                                                                          myStream.add(IntTest.indexScreens);
                                                                                        },
                                                                                        child: Padding(
                                                                                          padding: const EdgeInsets.symmetric(horizontal: 10.0),
                                                                                          child: Container(
                                                                                              height: 30.0,
                                                                                              padding: const EdgeInsets.symmetric(horizontal: 10.0),
                                                                                              decoration: BoxDecoration(borderRadius: BorderRadius.circular(5.0),color: addTOMon == index ? Colors.green[700] : ColorApp.myColorGreenAuth),
                                                                                              child: Center(child: Text('${listInTO['type_act_id']['name']}',style: const TextStyle(color: Colors.white,fontWeight: FontWeight.bold)))),
                                                                                        ));
                                                                                  },
                                                                                ),
                                                                              ),
                                                                              const SizedBox(height: 10.0),
                                                                              Column(
                                                                                children: [
                                                                                  /// Добавление нового пункта в ТО'
                                                                                  Padding(
                                                                                    padding: const EdgeInsets.all(5.0),
                                                                                    child: SizedBox(
                                                                                      height: 45.0,
                                                                                      child: Form(
                                                                                        key: keyNameTO1,
                                                                                        autovalidateMode: AutovalidateMode.onUserInteraction,
                                                                                        child: TextFormField(
                                                                                          // validator: (value) {
                                                                                          //   if (value!.isEmpty) {
                                                                                          //     return 'Заполните название';
                                                                                          //   } else {
                                                                                          //     return null;
                                                                                          //   }
                                                                                          // },
                                                                                          cursorColor: ColorApp.myColorGray,
                                                                                          controller: addNewNameTO,
                                                                                          decoration:  InputDecoration(
                                                                                              suffixIcon: IconButton(onPressed: (){
                                                                                                if(addNewNameTO.text.isNotEmpty){
                                                                                                  listToCreatePlanetTO.add({"text" : addNewNameTO.text, "bool" : false});
                                                                                                  print(addNewNameTO.text);
                                                                                                  openBoolTo1 = false;
                                                                                                  myStream.add(IntTest.indexScreens);
                                                                                                  addNewNameTO.clear();
                                                                                                }
                                                                                                // openBoolTo1 = false;
                                                                                                addNewNameTO.clear();
                                                                                                // keyNameTO1.currentState!.validate();

                                                                                              }, icon: const Icon(Icons.send,color: Colors.green)),
                                                                                              icon: IconButton(onPressed: (){
                                                                                                listToCreatePlanetTO.clear();
                                                                                                myStream.add(IntTest.indexScreens);

                                                                                              }, icon: Icon(Icons.settings_backup_restore,color: Colors.red[400])),
                                                                                              labelText: 'Добавление нового пункта в ТО',
                                                                                              border: const OutlineInputBorder(),
                                                                                              focusedBorder: const OutlineInputBorder(
                                                                                                borderSide: BorderSide(
                                                                                                    color: ColorApp.myColorGreenAuth),
                                                                                              ),
                                                                                              // labelText: 'Документ',
                                                                                              labelStyle:
                                                                                              const TextStyle(color: ColorApp.myColorGray)),
                                                                                        ),
                                                                                      ),
                                                                                    ),
                                                                                  ),
                                                                                  const SizedBox(height: 15.0),
                                                                                  /// Список ТО
                                                                                  SizedBox(
                                                                                    height: MediaQuery.of(context).size.height * 0.50,
                                                                                    child: ListView.builder(
                                                                                      itemCount: listToCreatePlanetTO.length,
                                                                                      itemBuilder: (context, index) {
                                                                                        final text = listToCreatePlanetTO[index]['text'];
                                                                                        return Row(
                                                                                          crossAxisAlignment: CrossAxisAlignment.center,
                                                                                          children: [
                                                                                            Expanded(
                                                                                              child: Padding(
                                                                                                padding: const EdgeInsets.only(left: 5.0, right: 5.0,bottom: 5.0),
                                                                                                child: Container(
                                                                                                  padding: const EdgeInsets.all(10.0),
                                                                                                  decoration: BoxDecoration(
                                                                                                      borderRadius: BorderRadius.circular(5.0),
                                                                                                      border: Border.all(color: Colors.grey, width: 1.5)
                                                                                                  ),
                                                                                                  child: Text('$text'),
                                                                                                ),
                                                                                              ),
                                                                                            ),
                                                                                            IconButton(
                                                                                                onPressed:  (){
                                                                                                  listToCreatePlanetTO.removeAt(index);
                                                                                                  myStream.add(IntTest.indexScreens);
                                                                                                }, icon: const Icon(Icons.delete_outline,color: Colors.red)),
                                                                                          ],
                                                                                        );
                                                                                      },
                                                                                    ),
                                                                                  ),

                                                                                ],
                                                                              ),
                                                                              const Spacer(),
                                                                              /// Кнопка Добавить
                                                                              Column(
                                                                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                                                                children: [
                                                                                  ElevatedButton(
                                                                                    style: ElevatedButton.styleFrom(
                                                                                        backgroundColor: listToCreatePlanetTO.isNotEmpty
                                                                                            ?  ColorApp.myColorGreenAuth : Colors.grey,
                                                                                        padding: const EdgeInsets.symmetric(vertical: 20.0)),
                                                                                    onPressed: listToCreatePlanetTO.isNotEmpty
                                                                                        ? () async {
                                                                                      /// ==============
                                                                                      myGetPlanetTO['numberTo'] = listIn['type_act_id']['name'];
                                                                                      myGetPlanetTO['stepListTO'] = jsonEncode(listToCreatePlanetTO) ;
                                                                                      /// ==================

                                                                                      /// Создаем факт акт
                                                                                      await creationFactActList(listIn['id']); // готово

                                                                                      /// Изменить ТО Обьекту
                                                                                      await changeTOGraphics('may_to_id', intMonTOTest, getTOScheduleList[0]['id']);
                                                                                      await getTOScheduleIdObject(IntTest.pressHover);
                                                                                      myStream.add(IntTest.indexScreens);
                                                                                      Navigator.pop(context);
                                                                                      setState(() {});
                                                                                    }
                                                                                        : (){},
                                                                                    child: Text(listToCreatePlanetTO.isNotEmpty
                                                                                        ? 'Добавить' : 'Создайте список',
                                                                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                                                                    ),
                                                                                  ),
                                                                                ],
                                                                              ),
                                                                            ],
                                                                          ),
                                                                        );

                                                                      })));
                                                    });
                                                    /// =================================================================================
                                                    // print(listTo['id']);
                                                    // intMon = 1;
                                                    // print(monTO);
                                                    // monTO = 'january_to_id';
                                                    // myStream.add(IntTest.indexScreens);
                                                    // setState(() {});
                                                    // if(listTOJanuary['step_list'] != null){
                                                    //   String stringTestText = listTOJanuary['step_list'].replaceAll("'", '"');
                                                    //   listTOJanuaryText = json.decode(stringTestText);
                                                    //   listTOMonTaskText = listTOJanuaryText;
                                                    //   myStream.add(IntTest.indexScreens);
                                                    //   setState(() {});
                                                    // }else{
                                                    //   listTOMonTaskText.clear();
                                                    // }
                                                    /// =================================================================================
                                                  }
                                                      : (){
                                                    setState(() {
                                                      intMon = 5;
                                                      monTO = 'may_to_id';
                                                      if(listTOMay['stepListTO'] != null){
                                                        getTOScheduleIdObject(IntTest.pressHover);
                                                        intMonTOTes = listTo['may_to_id']['id'];
                                                        String stringTestText = listTOMay['stepListTO'].replaceAll("'", '"');
                                                        listTOJanuaryText = json.decode(stringTestText);
                                                        listTOMonTaskText = listTOJanuaryText;
                                                        myStream.add(IntTest.indexScreens);
                                                      }else{
                                                        listTOMonTaskText.clear();
                                                      }
                                                    });
                                                  },
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      borderRadius: BorderRadius.circular(5.0),
                                                      color: intMon == 5 ? Colors.green : ColorApp.myColorGreen,
                                                    ),
                                                    width: 40,
                                                    height: 40,
                                                    child: Center(child: listTOMay.isNotEmpty ? Text('${listTOMay['numberTo']}',style: const TextStyle(color: Colors.white, fontSize: 12.0)) : const Icon(Icons.add,color: Colors.white)),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(width: 10.0),
                                            /// Июн
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Text('Июн'),
                                                InkWell(
                                                  onTap: listTOJun.isEmpty
                                                      ? (){
                                                    setState(() {
                                                      showDialog(
                                                          context: context,
                                                          builder: (context) =>
                                                              AlertDialog(
                                                                  content: StreamBuilder(
                                                                      stream: myStream.stream,
                                                                      builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                                                                        return SizedBox(
                                                                          width: 800,
                                                                          child: Column(
                                                                            children: [
                                                                              /// Текст кнопка закрыть
                                                                              Row(
                                                                                children: [
                                                                                  /// Текст
                                                                                  Text(
                                                                                    'Назначить ТО месяцу ',
                                                                                    style: TextStyle(
                                                                                        fontWeight: FontWeight.w700,
                                                                                        fontSize: size.width > 570.0 ? 25.0 : 16.0),
                                                                                  ),
                                                                                  const Spacer(),
                                                                                  /// кнопка закрыть
                                                                                  IconButton(
                                                                                      onPressed: () {
                                                                                        Navigator.pop(context);
                                                                                      },
                                                                                      icon: const Icon(
                                                                                        Icons.close,
                                                                                        color: ColorApp.myColorGreenAuth,
                                                                                      )),
                                                                                ],
                                                                              ),
                                                                              const SizedBox(height: 10.0),
                                                                              /// Кнопки TO
                                                                              SizedBox(
                                                                                height: 50.0,
                                                                                child: ListView.builder(
                                                                                  scrollDirection: Axis.horizontal,
                                                                                  itemCount: templatesObject.length,
                                                                                  itemBuilder: (context, index) {
                                                                                    listInTO = templatesObject[index];
                                                                                    // print('=====================================');
                                                                                    // print(listInTO['id']);
                                                                                    // // print( listInTO['type_act_id']['name']);
                                                                                    // print('=====================================');
                                                                                    return InkWell(
                                                                                        onTap:(){
                                                                                          listIn = templatesObject[index];
                                                                                          addTOMon = index;
                                                                                          print('+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');
                                                                                          print(listIn['type_act_id']['id']);
                                                                                          // listGetSelectedTemplateTO = listIn['step_list'];
                                                                                          // print(index);
                                                                                          String stringTest = listIn['step_list'].replaceAll("'", '"');
                                                                                          listToCreatePlanetTO = json.decode(stringTest);



                                                                                          print('+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');


                                                                                          myStream.add(IntTest.indexScreens);
                                                                                        },
                                                                                        child: Padding(
                                                                                          padding: const EdgeInsets.symmetric(horizontal: 10.0),
                                                                                          child: Container(
                                                                                              padding: const EdgeInsets.symmetric(horizontal: 10.0),
                                                                                              decoration: BoxDecoration(borderRadius: BorderRadius.circular(5.0),color: addTOMon == index ? Colors.green[700] : ColorApp.myColorGreenAuth),
                                                                                              height: 30,child: Center(child: Text('${listInTO['type_act_id']['name']}',style: const TextStyle(color: Colors.white,fontWeight: FontWeight.bold)))),
                                                                                        ));
                                                                                  },
                                                                                ),
                                                                              ),
                                                                              const SizedBox(height: 10.0),
                                                                              Column(
                                                                                children: [
                                                                                  /// Добавление нового пункта в ТО'
                                                                                  Padding(
                                                                                    padding: const EdgeInsets.all(5.0),
                                                                                    child: SizedBox(
                                                                                      height: 45.0,
                                                                                      child: Form(
                                                                                        key: keyNameTO1,
                                                                                        autovalidateMode: AutovalidateMode.onUserInteraction,
                                                                                        child: TextFormField(
                                                                                          // validator: (value) {
                                                                                          //   if (value!.isEmpty) {
                                                                                          //     return 'Заполните название';
                                                                                          //   } else {
                                                                                          //     return null;
                                                                                          //   }
                                                                                          // },
                                                                                          cursorColor: ColorApp.myColorGray,
                                                                                          controller: addNewNameTO,
                                                                                          decoration:  InputDecoration(
                                                                                              suffixIcon: IconButton(onPressed: (){
                                                                                                if(addNewNameTO.text.isNotEmpty){
                                                                                                  listToCreatePlanetTO.add({"text" : addNewNameTO.text, "bool" : false});
                                                                                                  print(addNewNameTO.text);
                                                                                                  openBoolTo1 = false;
                                                                                                  myStream.add(IntTest.indexScreens);
                                                                                                  addNewNameTO.clear();
                                                                                                }
                                                                                                // openBoolTo1 = false;
                                                                                                addNewNameTO.clear();
                                                                                                // keyNameTO1.currentState!.validate();

                                                                                              }, icon: const Icon(Icons.send,color: Colors.green)),
                                                                                              icon: IconButton(onPressed: (){
                                                                                                listToCreatePlanetTO.clear();
                                                                                                myStream.add(IntTest.indexScreens);

                                                                                              }, icon: Icon(Icons.settings_backup_restore,color: Colors.red[400])),
                                                                                              labelText: 'Добавление нового пункта в ТО',
                                                                                              border: const OutlineInputBorder(),
                                                                                              focusedBorder: const OutlineInputBorder(
                                                                                                borderSide: BorderSide(
                                                                                                    color: ColorApp.myColorGreenAuth),
                                                                                              ),
                                                                                              // labelText: 'Документ',
                                                                                              labelStyle:
                                                                                              const TextStyle(color: ColorApp.myColorGray)),
                                                                                        ),
                                                                                      ),
                                                                                    ),
                                                                                  ),
                                                                                  const SizedBox(height: 15.0),
                                                                                  /// Список ТО
                                                                                  SizedBox(
                                                                                    height: MediaQuery.of(context).size.height * 0.50,
                                                                                    child: ListView.builder(
                                                                                      itemCount: listToCreatePlanetTO.length,
                                                                                      itemBuilder: (context, index) {
                                                                                        final text = listToCreatePlanetTO[index]['text'];
                                                                                        return Row(
                                                                                          crossAxisAlignment: CrossAxisAlignment.center,
                                                                                          children: [
                                                                                            Expanded(
                                                                                              child: Padding(
                                                                                                padding: const EdgeInsets.only(left: 5.0, right: 5.0,bottom: 5.0),
                                                                                                child: Container(
                                                                                                  padding: const EdgeInsets.all(10.0),
                                                                                                  decoration: BoxDecoration(
                                                                                                      borderRadius: BorderRadius.circular(5.0),
                                                                                                      border: Border.all(color: Colors.grey, width: 1.5)
                                                                                                  ),
                                                                                                  child: Text('$text'),
                                                                                                ),
                                                                                              ),
                                                                                            ),
                                                                                            IconButton(
                                                                                                onPressed:  (){
                                                                                                  listToCreatePlanetTO.removeAt(index);
                                                                                                  myStream.add(IntTest.indexScreens);
                                                                                                }, icon: const Icon(Icons.delete_outline,color: Colors.red)),
                                                                                          ],
                                                                                        );
                                                                                      },
                                                                                    ),
                                                                                  ),
                                                                                ],
                                                                              ),
                                                                              const Spacer(),
                                                                              /// Кнопка Добавить
                                                                              Column(
                                                                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                                                                children: [
                                                                                  ElevatedButton(
                                                                                    style: ElevatedButton.styleFrom(
                                                                                        backgroundColor: listToCreatePlanetTO.isNotEmpty
                                                                                            ?  ColorApp.myColorGreenAuth : Colors.grey,
                                                                                        padding: const EdgeInsets.symmetric(vertical: 20.0)),
                                                                                    onPressed: listToCreatePlanetTO.isNotEmpty
                                                                                        ? () async {
                                                                                      /// ==============
                                                                                      myGetPlanetTO['numberTo'] = listIn['type_act_id']['name'] ;
                                                                                      myGetPlanetTO['stepListTO'] = jsonEncode(listToCreatePlanetTO) ;
                                                                                      /// ==================

                                                                                      /// Создаем факт акт
                                                                                      await creationFactActList(listIn['id']); // готово

                                                                                      /// Изменить ТО Обьекту
                                                                                      await changeTOGraphics('june_to_id', intMonTOTest, getTOScheduleList[0]['id']);
                                                                                      await getTOScheduleIdObject(IntTest.pressHover);
                                                                                      myStream.add(IntTest.indexScreens);
                                                                                      Navigator.pop(context);
                                                                                      setState(() {});
                                                                                    }
                                                                                        : (){},
                                                                                    child: Text(listToCreatePlanetTO.isNotEmpty
                                                                                        ? 'Добавить' : 'Создайте список',
                                                                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                                                                    ),
                                                                                  ),
                                                                                ],
                                                                              ),
                                                                            ],
                                                                          ),
                                                                        );

                                                                      })));
                                                    });
                                                    /// =================================================================================
                                                    // print(listTo['id']);
                                                    // intMon = 1;
                                                    // print(monTO);
                                                    // monTO = 'january_to_id';
                                                    // myStream.add(IntTest.indexScreens);
                                                    // setState(() {});
                                                    // if(listTOJanuary['step_list'] != null){
                                                    //   String stringTestText = listTOJanuary['step_list'].replaceAll("'", '"');
                                                    //   listTOJanuaryText = json.decode(stringTestText);
                                                    //   listTOMonTaskText = listTOJanuaryText;
                                                    //   myStream.add(IntTest.indexScreens);
                                                    //   setState(() {});
                                                    // }else{
                                                    //   listTOMonTaskText.clear();
                                                    // }
                                                    /// =================================================================================
                                                  }
                                                      : (){
                                                    setState(() {
                                                      intMon = 6;
                                                      monTO = 'june_to_id';
                                                      if(listTOJun['stepListTO'] != null){
                                                        getTOScheduleIdObject(IntTest.pressHover);
                                                        intMonTOTes = listTo['june_to_id']['id'];
                                                        String stringTestText = listTOJun['stepListTO'].replaceAll("'", '"');
                                                        listTOJanuaryText = json.decode(stringTestText);
                                                        listTOMonTaskText = listTOJanuaryText;
                                                        myStream.add(IntTest.indexScreens);
                                                      }else{
                                                        listTOMonTaskText.clear();
                                                      }
                                                    });
                                                  },
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      borderRadius: BorderRadius.circular(5.0),
                                                      color: intMon == 6 ? Colors.green : ColorApp.myColorGreen,
                                                    ),
                                                    width: 40,
                                                    height: 40,
                                                    child: Center(child: listTOJun.isNotEmpty ? Text('${listTOJun['numberTo']}',style: const TextStyle(color: Colors.white, fontSize: 12.0)) : const Icon(Icons.add,color: Colors.white)),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(width: 10.0),
                                            /// Июл
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Text('Июл'),
                                                InkWell(
                                                  onTap: listTOJul.isEmpty
                                                      ? (){
                                                    setState(() {
                                                      showDialog(
                                                          context: context,
                                                          builder: (context) =>
                                                              AlertDialog(
                                                                  content: StreamBuilder(
                                                                      stream: myStream.stream,
                                                                      builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                                                                        return SizedBox(
                                                                          width: 800,
                                                                          child: Column(
                                                                            children: [
                                                                              /// Текст кнопка закрыть
                                                                              Row(
                                                                                children: [
                                                                                  /// Текст
                                                                                  Text(
                                                                                    'Назначить ТО месяцу ',
                                                                                    style: TextStyle(
                                                                                        fontWeight: FontWeight.w700,
                                                                                        fontSize: size.width > 570.0 ? 25.0 : 16.0),
                                                                                  ),
                                                                                  const Spacer(),
                                                                                  /// кнопка закрыть
                                                                                  IconButton(
                                                                                      onPressed: () {
                                                                                        Navigator.pop(context);
                                                                                      },
                                                                                      icon: const Icon(
                                                                                        Icons.close,
                                                                                        color: ColorApp.myColorGreenAuth,
                                                                                      )),
                                                                                ],
                                                                              ),
                                                                              const SizedBox(height: 10.0),
                                                                              /// Кнопки TO
                                                                              SizedBox(
                                                                                height: 50.0,
                                                                                child: ListView.builder(
                                                                                  scrollDirection: Axis.horizontal,
                                                                                  itemCount: templatesObject.length,
                                                                                  itemBuilder: (context, index) {
                                                                                    listInTO = templatesObject[index];
                                                                                    // print('=====================================');
                                                                                    // print(listInTO['id']);
                                                                                    // // print( listInTO['type_act_id']['name']);
                                                                                    // print('=====================================');
                                                                                    return InkWell(
                                                                                        onTap:(){
                                                                                          listIn = templatesObject[index];
                                                                                          addTOMon = index;
                                                                                          print('+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');
                                                                                          print(listIn['type_act_id']['id']);
                                                                                          // listGetSelectedTemplateTO = listIn['step_list'];
                                                                                          // print(index);
                                                                                          String stringTest = listIn['step_list'].replaceAll("'", '"');
                                                                                          listToCreatePlanetTO = json.decode(stringTest);



                                                                                          print('+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');


                                                                                          myStream.add(IntTest.indexScreens);
                                                                                        },
                                                                                        child: Padding(
                                                                                          padding: const EdgeInsets.symmetric(horizontal: 10.0),
                                                                                          child: Container(
                                                                                              padding: const EdgeInsets.symmetric(horizontal: 10.0),
                                                                                              decoration: BoxDecoration(borderRadius: BorderRadius.circular(5.0),color: addTOMon == index ? Colors.green[700] : ColorApp.myColorGreenAuth),
                                                                                              height: 30,child: Center(child: Text('${listInTO['type_act_id']['name']}',style: const TextStyle(color: Colors.white,fontWeight: FontWeight.bold)))),
                                                                                        ));
                                                                                  },
                                                                                ),
                                                                              ),
                                                                              const SizedBox(height: 10.0),
                                                                              Column(
                                                                                children: [
                                                                                  /// Добавление нового пункта в ТО'
                                                                                  Padding(
                                                                                    padding: const EdgeInsets.all(5.0),
                                                                                    child: SizedBox(
                                                                                      height: 45.0,
                                                                                      child: Form(
                                                                                        key: keyNameTO1,
                                                                                        autovalidateMode: AutovalidateMode.onUserInteraction,
                                                                                        child: TextFormField(
                                                                                          // validator: (value) {
                                                                                          //   if (value!.isEmpty) {
                                                                                          //     return 'Заполните название';
                                                                                          //   } else {
                                                                                          //     return null;
                                                                                          //   }
                                                                                          // },
                                                                                          cursorColor: ColorApp.myColorGray,
                                                                                          controller: addNewNameTO,
                                                                                          decoration:  InputDecoration(
                                                                                              suffixIcon: IconButton(onPressed: (){
                                                                                                if(addNewNameTO.text.isNotEmpty){
                                                                                                  listToCreatePlanetTO.add({"text" : addNewNameTO.text, "bool" : false});
                                                                                                  print(addNewNameTO.text);
                                                                                                  openBoolTo1 = false;
                                                                                                  myStream.add(IntTest.indexScreens);
                                                                                                  addNewNameTO.clear();
                                                                                                }
                                                                                                // openBoolTo1 = false;
                                                                                                addNewNameTO.clear();
                                                                                                // keyNameTO1.currentState!.validate();

                                                                                              }, icon: const Icon(Icons.send,color: Colors.green)),
                                                                                              icon: IconButton(onPressed: (){
                                                                                                listToCreatePlanetTO.clear();
                                                                                                myStream.add(IntTest.indexScreens);

                                                                                              }, icon: Icon(Icons.settings_backup_restore,color: Colors.red[400])),
                                                                                              labelText: 'Добавление нового пункта в ТО',
                                                                                              border: const OutlineInputBorder(),
                                                                                              focusedBorder: const OutlineInputBorder(
                                                                                                borderSide: BorderSide(
                                                                                                    color: ColorApp.myColorGreenAuth),
                                                                                              ),
                                                                                              // labelText: 'Документ',
                                                                                              labelStyle:
                                                                                              const TextStyle(color: ColorApp.myColorGray)),
                                                                                        ),
                                                                                      ),
                                                                                    ),
                                                                                  ),
                                                                                  const SizedBox(height: 15.0),
                                                                                  /// Список ТО
                                                                                  SizedBox(
                                                                                    height: MediaQuery.of(context).size.height * 0.50,
                                                                                    child: ListView.builder(
                                                                                      itemCount: listToCreatePlanetTO.length,
                                                                                      itemBuilder: (context, index) {
                                                                                        final text = listToCreatePlanetTO[index]['text'];
                                                                                        return Row(
                                                                                          crossAxisAlignment: CrossAxisAlignment.center,
                                                                                          children: [
                                                                                            Expanded(
                                                                                              child: Padding(
                                                                                                padding: const EdgeInsets.only(left: 5.0, right: 5.0,bottom: 5.0),
                                                                                                child: Container(
                                                                                                  padding: const EdgeInsets.all(10.0),
                                                                                                  decoration: BoxDecoration(
                                                                                                      borderRadius: BorderRadius.circular(5.0),
                                                                                                      border: Border.all(color: Colors.grey, width: 1.5)
                                                                                                  ),
                                                                                                  child: Text('$text'),
                                                                                                ),
                                                                                              ),
                                                                                            ),
                                                                                            IconButton(
                                                                                                onPressed:  (){
                                                                                                  listToCreatePlanetTO.removeAt(index);
                                                                                                  myStream.add(IntTest.indexScreens);
                                                                                                }, icon: const Icon(Icons.delete_outline,color: Colors.red)),
                                                                                          ],
                                                                                        );
                                                                                      },
                                                                                    ),
                                                                                  ),

                                                                                ],
                                                                              ),
                                                                              const Spacer(),
                                                                              /// Кнопка Добавить
                                                                              Column(
                                                                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                                                                children: [
                                                                                  ElevatedButton(
                                                                                    style: ElevatedButton.styleFrom(
                                                                                        backgroundColor: listToCreatePlanetTO.isNotEmpty
                                                                                            ?  ColorApp.myColorGreenAuth : Colors.grey,
                                                                                        padding: const EdgeInsets.symmetric(vertical: 20.0)),
                                                                                    onPressed: listToCreatePlanetTO.isNotEmpty
                                                                                        ? () async {
                                                                                      /// ==============
                                                                                      myGetPlanetTO['numberTo'] = listIn['type_act_id']['name'] ;
                                                                                      myGetPlanetTO['stepListTO'] = jsonEncode(listToCreatePlanetTO) ;
                                                                                      /// ==================

                                                                                      /// Создаем факт акт
                                                                                      await creationFactActList(listIn['id']); // готово

                                                                                      /// Изменить ТО Обьекту
                                                                                      await changeTOGraphics('july_to_id', intMonTOTest, getTOScheduleList[0]['id']);
                                                                                      await getTOScheduleIdObject(IntTest.pressHover);
                                                                                      myStream.add(IntTest.indexScreens);
                                                                                      Navigator.pop(context);
                                                                                      setState(() {});
                                                                                    }
                                                                                        : (){},
                                                                                    child: Text(listToCreatePlanetTO.isNotEmpty
                                                                                        ? 'Добавить' : 'Создайте список',
                                                                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                                                                    ),
                                                                                  ),
                                                                                ],
                                                                              ),
                                                                            ],
                                                                          ),
                                                                        );

                                                                      })));
                                                    });
                                                    /// =================================================================================
                                                    // print(listTo['id']);
                                                    // intMon = 1;
                                                    // print(monTO);
                                                    // monTO = 'january_to_id';
                                                    // myStream.add(IntTest.indexScreens);
                                                    // setState(() {});
                                                    // if(listTOJanuary['step_list'] != null){
                                                    //   String stringTestText = listTOJanuary['step_list'].replaceAll("'", '"');
                                                    //   listTOJanuaryText = json.decode(stringTestText);
                                                    //   listTOMonTaskText = listTOJanuaryText;
                                                    //   myStream.add(IntTest.indexScreens);
                                                    //   setState(() {});
                                                    // }else{
                                                    //   listTOMonTaskText.clear();
                                                    // }
                                                    /// =================================================================================
                                                  }
                                                      : (){
                                                    setState(() {
                                                      intMon = 7;
                                                      monTO = 'july_to_id';
                                                      if(listTOJul['stepListTO'] != null){
                                                        getTOScheduleIdObject(IntTest.pressHover);
                                                        intMonTOTes = listTo['july_to_id']['id'];
                                                        String stringTestText = listTOJul['stepListTO'].replaceAll("'", '"');
                                                        listTOJanuaryText = json.decode(stringTestText);
                                                        listTOMonTaskText = listTOJanuaryText;
                                                        myStream.add(IntTest.indexScreens);
                                                      }else{listTOMonTaskText.clear();}
                                                    });
                                                  },
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      borderRadius: BorderRadius.circular(5.0),
                                                      color: intMon == 7 ? Colors.green : ColorApp.myColorGreen,
                                                    ),
                                                    width: 40,
                                                    height: 40,
                                                    child: Center(child: listTOJul.isNotEmpty ? Text('${listTOJul['numberTo']}',style: const TextStyle(color: Colors.white, fontSize: 12.0)) : const Icon(Icons.add,color: Colors.white)),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(width: 10.0),
                                            /// Авг
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Text('Авг'),
                                                InkWell(
                                                  onTap: listTOAug.isEmpty
                                                      ? (){
                                                    setState(() {
                                                      showDialog(
                                                          context: context,
                                                          builder: (context) =>
                                                              AlertDialog(
                                                                  content: StreamBuilder(
                                                                      stream: myStream.stream,
                                                                      builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                                                                        return SizedBox(
                                                                          width: 800,
                                                                          child: Column(
                                                                            children: [
                                                                              /// Текст кнопка закрыть
                                                                              Row(
                                                                                children: [
                                                                                  /// Текст
                                                                                  Text(
                                                                                    'Назначить ТО месяцу ',
                                                                                    style: TextStyle(
                                                                                        fontWeight: FontWeight.w700,
                                                                                        fontSize: size.width > 570.0 ? 25.0 : 16.0),
                                                                                  ),
                                                                                  const Spacer(),
                                                                                  /// кнопка закрыть
                                                                                  IconButton(
                                                                                      onPressed: () {
                                                                                        Navigator.pop(context);
                                                                                      },
                                                                                      icon: const Icon(
                                                                                        Icons.close,
                                                                                        color: ColorApp.myColorGreenAuth,
                                                                                      )),
                                                                                ],
                                                                              ),
                                                                              const SizedBox(height: 10.0),
                                                                              /// Кнопки TO
                                                                              SizedBox(
                                                                                height: 50.0,
                                                                                child: ListView.builder(
                                                                                  scrollDirection: Axis.horizontal,
                                                                                  itemCount: templatesObject.length,
                                                                                  itemBuilder: (context, index) {
                                                                                    listInTO = templatesObject[index];
                                                                                    // print('=====================================');
                                                                                    // print(listInTO['id']);
                                                                                    // // print( listInTO['type_act_id']['name']);
                                                                                    // print('=====================================');
                                                                                    return InkWell(
                                                                                        onTap:(){
                                                                                          listIn = templatesObject[index];
                                                                                          addTOMon = index;
                                                                                          print('+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');
                                                                                          print(listIn['type_act_id']['id']);
                                                                                          // listGetSelectedTemplateTO = listIn['step_list'];
                                                                                          // print(index);
                                                                                          String stringTest = listIn['step_list'].replaceAll("'", '"');
                                                                                          listToCreatePlanetTO = json.decode(stringTest);



                                                                                          print('+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');


                                                                                          myStream.add(IntTest.indexScreens);
                                                                                        },
                                                                                        child: Padding(
                                                                                          padding: const EdgeInsets.symmetric(horizontal: 10.0),
                                                                                          child: Container(
                                                                                              padding: const EdgeInsets.symmetric(horizontal: 10.0),
                                                                                              decoration: BoxDecoration(borderRadius: BorderRadius.circular(5.0),color: addTOMon == index ? Colors.green[700] : ColorApp.myColorGreenAuth),
                                                                                              height: 30,child: Center(child: Text('${listInTO['type_act_id']['name']}',style: const TextStyle(color: Colors.white,fontWeight: FontWeight.bold)))),
                                                                                        ));
                                                                                  },
                                                                                ),
                                                                              ),
                                                                              const SizedBox(height: 10.0),
                                                                              Column(
                                                                                children: [
                                                                                  /// Добавление нового пункта в ТО'
                                                                                  Padding(
                                                                                    padding: const EdgeInsets.all(5.0),
                                                                                    child: SizedBox(
                                                                                      height: 45.0,
                                                                                      child: Form(
                                                                                        key: keyNameTO1,
                                                                                        autovalidateMode: AutovalidateMode.onUserInteraction,
                                                                                        child: TextFormField(
                                                                                          // validator: (value) {
                                                                                          //   if (value!.isEmpty) {
                                                                                          //     return 'Заполните название';
                                                                                          //   } else {
                                                                                          //     return null;
                                                                                          //   }
                                                                                          // },
                                                                                          cursorColor: ColorApp.myColorGray,
                                                                                          controller: addNewNameTO,
                                                                                          decoration:  InputDecoration(
                                                                                              suffixIcon: IconButton(onPressed: (){
                                                                                                if(addNewNameTO.text.isNotEmpty){
                                                                                                  listToCreatePlanetTO.add({"text" : addNewNameTO.text, "bool" : false});
                                                                                                  print(addNewNameTO.text);
                                                                                                  openBoolTo1 = false;
                                                                                                  myStream.add(IntTest.indexScreens);
                                                                                                  addNewNameTO.clear();
                                                                                                }
                                                                                                // openBoolTo1 = false;
                                                                                                addNewNameTO.clear();
                                                                                                // keyNameTO1.currentState!.validate();

                                                                                              }, icon: const Icon(Icons.send,color: Colors.green)),
                                                                                              icon: IconButton(onPressed: (){
                                                                                                listToCreatePlanetTO.clear();
                                                                                                myStream.add(IntTest.indexScreens);

                                                                                              }, icon: Icon(Icons.settings_backup_restore,color: Colors.red[400])),
                                                                                              labelText: 'Добавление нового пункта в ТО',
                                                                                              border: const OutlineInputBorder(),
                                                                                              focusedBorder: const OutlineInputBorder(
                                                                                                borderSide: BorderSide(
                                                                                                    color: ColorApp.myColorGreenAuth),
                                                                                              ),
                                                                                              // labelText: 'Документ',
                                                                                              labelStyle:
                                                                                              const TextStyle(color: ColorApp.myColorGray)),
                                                                                        ),
                                                                                      ),
                                                                                    ),
                                                                                  ),
                                                                                  const SizedBox(height: 15.0),
                                                                                  /// Список ТО
                                                                                  SizedBox(
                                                                                    height: MediaQuery.of(context).size.height * 0.50,
                                                                                    child: ListView.builder(
                                                                                      itemCount: listToCreatePlanetTO.length,
                                                                                      itemBuilder: (context, index) {
                                                                                        final text = listToCreatePlanetTO[index]['text'];
                                                                                        return Row(
                                                                                          crossAxisAlignment: CrossAxisAlignment.center,
                                                                                          children: [
                                                                                            Expanded(
                                                                                              child: Padding(
                                                                                                padding: const EdgeInsets.only(left: 5.0, right: 5.0,bottom: 5.0),
                                                                                                child: Container(
                                                                                                  padding: const EdgeInsets.all(10.0),
                                                                                                  decoration: BoxDecoration(
                                                                                                      borderRadius: BorderRadius.circular(5.0),
                                                                                                      border: Border.all(color: Colors.grey, width: 1.5)
                                                                                                  ),
                                                                                                  child: Text('$text'),
                                                                                                ),
                                                                                              ),
                                                                                            ),
                                                                                            IconButton(
                                                                                                onPressed:  (){
                                                                                                  listToCreatePlanetTO.removeAt(index);
                                                                                                  myStream.add(IntTest.indexScreens);
                                                                                                }, icon: const Icon(Icons.delete_outline,color: Colors.red)),
                                                                                          ],
                                                                                        );
                                                                                      },
                                                                                    ),
                                                                                  ),
                                                                                ],
                                                                              ),
                                                                              const Spacer(),
                                                                              /// Кнопка Добавить
                                                                              Column(
                                                                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                                                                children: [
                                                                                  ElevatedButton(
                                                                                    style: ElevatedButton.styleFrom(
                                                                                        backgroundColor: listToCreatePlanetTO.isNotEmpty
                                                                                            ?  ColorApp.myColorGreenAuth : Colors.grey,
                                                                                        padding: const EdgeInsets.symmetric(vertical: 20.0)),
                                                                                    onPressed: listToCreatePlanetTO.isNotEmpty
                                                                                        ? () async {
                                                                                      /// ==============
                                                                                      myGetPlanetTO['numberTo'] = listIn['type_act_id']['name'] ;
                                                                                      myGetPlanetTO['stepListTO'] = jsonEncode(listToCreatePlanetTO) ;
                                                                                      /// ==================

                                                                                      /// Создаем факт акт
                                                                                      await creationFactActList(listIn['id']); // готово

                                                                                      /// Изменить ТО Обьекту
                                                                                      await changeTOGraphics('august_to_id', intMonTOTest, getTOScheduleList[0]['id']);
                                                                                      await getTOScheduleIdObject(IntTest.pressHover);
                                                                                      myStream.add(IntTest.indexScreens);
                                                                                      Navigator.pop(context);
                                                                                      setState(() {});
                                                                                    }
                                                                                        : (){},
                                                                                    child: Text(listToCreatePlanetTO.isNotEmpty
                                                                                        ? 'Добавить' : 'Создайте список',
                                                                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                                                                    ),
                                                                                  ),
                                                                                ],
                                                                              ),
                                                                            ],
                                                                          ),
                                                                        );

                                                                      })));
                                                    });
                                                    /// =================================================================================
                                                    // print(listTo['id']);
                                                    // intMon = 1;
                                                    // print(monTO);
                                                    // monTO = 'january_to_id';
                                                    // myStream.add(IntTest.indexScreens);
                                                    // setState(() {});
                                                    // if(listTOJanuary['step_list'] != null){
                                                    //   String stringTestText = listTOJanuary['step_list'].replaceAll("'", '"');
                                                    //   listTOJanuaryText = json.decode(stringTestText);
                                                    //   listTOMonTaskText = listTOJanuaryText;
                                                    //   myStream.add(IntTest.indexScreens);
                                                    //   setState(() {});
                                                    // }else{
                                                    //   listTOMonTaskText.clear();
                                                    // }
                                                    /// =================================================================================
                                                  }
                                                      : (){
                                                    setState(() {
                                                      intMon = 8;
                                                      monTO = 'august_to_id';
                                                      if(listTOAug['stepListTO'] != null){
                                                        getTOScheduleIdObject(IntTest.pressHover);
                                                        intMonTOTes = listTo['august_to_id']['id'];
                                                        String stringTestText = listTOAug['stepListTO'].replaceAll("'", '"');
                                                        listTOJanuaryText = json.decode(stringTestText);
                                                        listTOMonTaskText = listTOJanuaryText;
                                                        myStream.add(IntTest.indexScreens);
                                                      }else{
                                                        listTOMonTaskText.clear();
                                                      }
                                                    });
                                                  },
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      borderRadius: BorderRadius.circular(5.0),
                                                      color: intMon == 8 ? Colors.green : ColorApp.myColorGreen,
                                                    ),
                                                    width: 40,
                                                    height: 40,
                                                    child: Center(child: listTOAug.isNotEmpty ? Text('${listTOAug['numberTo']}',style: const TextStyle(color: Colors.white, fontSize: 12.0)) : const Icon(Icons.add,color: Colors.white)),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(width: 10.0),
                                            /// Сен
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Text('Сен'),
                                                InkWell(
                                                  onTap: listTOSen.isEmpty
                                                      ? (){
                                                    setState(() {
                                                      showDialog(
                                                          context: context,
                                                          builder: (context) =>
                                                              AlertDialog(
                                                                  content: StreamBuilder(
                                                                      stream: myStream.stream,
                                                                      builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                                                                        return SizedBox(
                                                                          width: 800,
                                                                          child: Column(
                                                                            children: [
                                                                              /// Текст кнопка закрыть
                                                                              Row(
                                                                                children: [
                                                                                  /// Текст
                                                                                  Text(
                                                                                    'Назначить ТО месяцу ',
                                                                                    style: TextStyle(
                                                                                        fontWeight: FontWeight.w700,
                                                                                        fontSize: size.width > 570.0 ? 25.0 : 16.0),
                                                                                  ),
                                                                                  const Spacer(),
                                                                                  /// кнопка закрыть
                                                                                  IconButton(
                                                                                      onPressed: () {
                                                                                        Navigator.pop(context);
                                                                                      },
                                                                                      icon: const Icon(
                                                                                        Icons.close,
                                                                                        color: ColorApp.myColorGreenAuth,
                                                                                      )),
                                                                                ],
                                                                              ),
                                                                              const SizedBox(height: 10.0),
                                                                              /// Кнопки TO
                                                                              SizedBox(
                                                                                height: 50.0,
                                                                                child: ListView.builder(
                                                                                  scrollDirection: Axis.horizontal,
                                                                                  itemCount: templatesObject.length,
                                                                                  itemBuilder: (context, index) {
                                                                                    listInTO = templatesObject[index];
                                                                                    // print('=====================================');
                                                                                    // print(listInTO['id']);
                                                                                    // // print( listInTO['type_act_id']['name']);
                                                                                    // print('=====================================');
                                                                                    return InkWell(
                                                                                        onTap:(){
                                                                                          listIn = templatesObject[index];
                                                                                          addTOMon = index;
                                                                                          print('+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');
                                                                                          print(listIn['type_act_id']['id']);
                                                                                          // listGetSelectedTemplateTO = listIn['step_list'];
                                                                                          // print(index);
                                                                                          String stringTest = listIn['step_list'].replaceAll("'", '"');
                                                                                          listToCreatePlanetTO = json.decode(stringTest);



                                                                                          print('+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');


                                                                                          myStream.add(IntTest.indexScreens);
                                                                                        },
                                                                                        child: Padding(
                                                                                          padding: const EdgeInsets.symmetric(horizontal: 10.0),
                                                                                          child: Container(
                                                                                              padding: const EdgeInsets.symmetric(horizontal: 10.0),
                                                                                              decoration: BoxDecoration(borderRadius: BorderRadius.circular(5.0),color: addTOMon == index ? Colors.green[700] : ColorApp.myColorGreenAuth),
                                                                                              height: 30,child: Center(child: Text('${listInTO['type_act_id']['name']}',style: const TextStyle(color: Colors.white,fontWeight: FontWeight.bold)))),
                                                                                        ));
                                                                                  },
                                                                                ),
                                                                              ),
                                                                              const SizedBox(height: 10.0),
                                                                              Column(
                                                                                children: [
                                                                                  /// Добавление нового пункта в ТО'
                                                                                  Padding(
                                                                                    padding: const EdgeInsets.all(5.0),
                                                                                    child: SizedBox(
                                                                                      height: 45.0,
                                                                                      child: Form(
                                                                                        key: keyNameTO1,
                                                                                        autovalidateMode: AutovalidateMode.onUserInteraction,
                                                                                        child: TextFormField(
                                                                                          // validator: (value) {
                                                                                          //   if (value!.isEmpty) {
                                                                                          //     return 'Заполните название';
                                                                                          //   } else {
                                                                                          //     return null;
                                                                                          //   }
                                                                                          // },
                                                                                          cursorColor: ColorApp.myColorGray,
                                                                                          controller: addNewNameTO,
                                                                                          decoration:  InputDecoration(
                                                                                              suffixIcon: IconButton(onPressed: (){
                                                                                                if(addNewNameTO.text.isNotEmpty){
                                                                                                  listToCreatePlanetTO.add({"text" : addNewNameTO.text, "bool" : false});
                                                                                                  print(addNewNameTO.text);
                                                                                                  openBoolTo1 = false;
                                                                                                  myStream.add(IntTest.indexScreens);
                                                                                                  addNewNameTO.clear();
                                                                                                }
                                                                                                // openBoolTo1 = false;
                                                                                                addNewNameTO.clear();
                                                                                                // keyNameTO1.currentState!.validate();

                                                                                              }, icon: const Icon(Icons.send,color: Colors.green)),
                                                                                              icon: IconButton(onPressed: (){
                                                                                                listToCreatePlanetTO.clear();
                                                                                                myStream.add(IntTest.indexScreens);

                                                                                              }, icon: Icon(Icons.settings_backup_restore,color: Colors.red[400])),
                                                                                              labelText: 'Добавление нового пункта в ТО',
                                                                                              border: const OutlineInputBorder(),
                                                                                              focusedBorder: const OutlineInputBorder(
                                                                                                borderSide: BorderSide(
                                                                                                    color: ColorApp.myColorGreenAuth),
                                                                                              ),
                                                                                              // labelText: 'Документ',
                                                                                              labelStyle:
                                                                                              const TextStyle(color: ColorApp.myColorGray)),
                                                                                        ),
                                                                                      ),
                                                                                    ),
                                                                                  ),
                                                                                  const SizedBox(height: 15.0),
                                                                                  /// Список ТО
                                                                                  SizedBox(
                                                                                    height: MediaQuery.of(context).size.height * 0.50,
                                                                                    child: ListView.builder(
                                                                                      itemCount: listToCreatePlanetTO.length,
                                                                                      itemBuilder: (context, index) {
                                                                                        final text = listToCreatePlanetTO[index]['text'];
                                                                                        return Row(
                                                                                          crossAxisAlignment: CrossAxisAlignment.center,
                                                                                          children: [
                                                                                            Expanded(
                                                                                              child: Padding(
                                                                                                padding: const EdgeInsets.only(left: 5.0, right: 5.0,bottom: 5.0),
                                                                                                child: Container(
                                                                                                  padding: const EdgeInsets.all(10.0),
                                                                                                  decoration: BoxDecoration(
                                                                                                      borderRadius: BorderRadius.circular(5.0),
                                                                                                      border: Border.all(color: Colors.grey, width: 1.5)
                                                                                                  ),
                                                                                                  child: Text('$text'),
                                                                                                ),
                                                                                              ),
                                                                                            ),
                                                                                            IconButton(
                                                                                                onPressed:  (){
                                                                                                  listToCreatePlanetTO.removeAt(index);
                                                                                                  myStream.add(IntTest.indexScreens);
                                                                                                }, icon: const Icon(Icons.delete_outline,color: Colors.red)),
                                                                                          ],
                                                                                        );
                                                                                      },
                                                                                    ),
                                                                                  ),

                                                                                ],
                                                                              ),
                                                                              const Spacer(),
                                                                              /// Кнопка Добавить
                                                                              Column(
                                                                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                                                                children: [
                                                                                  ElevatedButton(
                                                                                    style: ElevatedButton.styleFrom(
                                                                                        backgroundColor: listToCreatePlanetTO.isNotEmpty
                                                                                            ?  ColorApp.myColorGreenAuth : Colors.grey,
                                                                                        padding: const EdgeInsets.symmetric(vertical: 20.0)),
                                                                                    onPressed: listToCreatePlanetTO.isNotEmpty
                                                                                        ? () async {
                                                                                      /// ==============
                                                                                      myGetPlanetTO['numberTo'] = listIn['type_act_id']['name'] ;
                                                                                      myGetPlanetTO['stepListTO'] = jsonEncode(listToCreatePlanetTO) ;
                                                                                      /// ==================

                                                                                      /// Создаем факт акт
                                                                                      await creationFactActList(listIn['id']); // готово

                                                                                      /// Изменить ТО Обьекту
                                                                                      await changeTOGraphics('september_to_id', intMonTOTest, getTOScheduleList[0]['id']);
                                                                                      await getTOScheduleIdObject(IntTest.pressHover);
                                                                                      myStream.add(IntTest.indexScreens);
                                                                                      Navigator.pop(context);
                                                                                      setState(() {});
                                                                                    }
                                                                                        : (){},
                                                                                    child: Text(listToCreatePlanetTO.isNotEmpty
                                                                                        ? 'Добавить' : 'Создайте список',
                                                                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                                                                    ),
                                                                                  ),
                                                                                ],
                                                                              ),
                                                                            ],
                                                                          ),
                                                                        );

                                                                      })));
                                                    });
                                                    /// =================================================================================
                                                    // print(listTo['id']);
                                                    // intMon = 1;
                                                    // print(monTO);
                                                    // monTO = 'january_to_id';
                                                    // myStream.add(IntTest.indexScreens);
                                                    // setState(() {});
                                                    // if(listTOJanuary['step_list'] != null){
                                                    //   String stringTestText = listTOJanuary['step_list'].replaceAll("'", '"');
                                                    //   listTOJanuaryText = json.decode(stringTestText);
                                                    //   listTOMonTaskText = listTOJanuaryText;
                                                    //   myStream.add(IntTest.indexScreens);
                                                    //   setState(() {});
                                                    // }else{
                                                    //   listTOMonTaskText.clear();
                                                    // }
                                                    /// =================================================================================
                                                  }
                                                      : (){
                                                    setState(() {
                                                      intMon = 9;
                                                      monTO = 'september_to_id';
                                                      if(listTOSen['stepListTO'] != null){
                                                        getTOScheduleIdObject(IntTest.pressHover);
                                                        intMonTOTes = listTo['september_to_id']['id'];
                                                        String stringTestText = listTOSen['stepListTO'].replaceAll("'", '"');
                                                        listTOJanuaryText = json.decode(stringTestText);
                                                        listTOMonTaskText = listTOJanuaryText;
                                                        myStream.add(IntTest.indexScreens);
                                                      }else{
                                                        listTOMonTaskText.clear();
                                                      }
                                                    });
                                                  },
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      borderRadius: BorderRadius.circular(5.0),
                                                      color: intMon == 9 ? Colors.green : ColorApp.myColorGreen,
                                                    ),
                                                    width: 40,
                                                    height: 40,
                                                    child: Center(child: listTOSen.isNotEmpty ? Text('${listTOSen['numberTo']}',style: const TextStyle(color: Colors.white, fontSize: 12.0)) : const Icon(Icons.add,color: Colors.white)),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(width: 10.0),
                                            /// Окт
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Text('Окт'),
                                                InkWell(
                                                  onTap: listTOOct.isEmpty
                                                      ? (){
                                                    setState(() {
                                                      showDialog(
                                                          context: context,
                                                          builder: (context) =>
                                                              AlertDialog(
                                                                  content: StreamBuilder(
                                                                      stream: myStream.stream,
                                                                      builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                                                                        return SizedBox(
                                                                          width: 800,
                                                                          child: Column(
                                                                            children: [
                                                                              /// Текст кнопка закрыть
                                                                              Row(
                                                                                children: [
                                                                                  /// Текст
                                                                                  Text(
                                                                                    'Назначить ТО месяцу ',
                                                                                    style: TextStyle(
                                                                                        fontWeight: FontWeight.w700,
                                                                                        fontSize: size.width > 570.0 ? 25.0 : 16.0),
                                                                                  ),
                                                                                  const Spacer(),
                                                                                  /// кнопка закрыть
                                                                                  IconButton(
                                                                                      onPressed: () {
                                                                                        Navigator.pop(context);
                                                                                      },
                                                                                      icon: const Icon(
                                                                                        Icons.close,
                                                                                        color: ColorApp.myColorGreenAuth,
                                                                                      )),
                                                                                ],
                                                                              ),
                                                                              const SizedBox(height: 10.0),
                                                                              /// Кнопки TO
                                                                              SizedBox(
                                                                                height: 50.0,
                                                                                child: ListView.builder(
                                                                                  scrollDirection: Axis.horizontal,
                                                                                  itemCount: templatesObject.length,
                                                                                  itemBuilder: (context, index) {
                                                                                    listInTO = templatesObject[index];
                                                                                    // print('=====================================');
                                                                                    // print(listInTO['id']);
                                                                                    // // print( listInTO['type_act_id']['name']);
                                                                                    // print('=====================================');
                                                                                    return InkWell(
                                                                                        onTap:(){
                                                                                          listIn = templatesObject[index];
                                                                                          addTOMon = index;
                                                                                          print('+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');
                                                                                          print(listIn['type_act_id']['id']);
                                                                                          // listGetSelectedTemplateTO = listIn['step_list'];
                                                                                          // print(index);
                                                                                          String stringTest = listIn['step_list'].replaceAll("'", '"');
                                                                                          listToCreatePlanetTO = json.decode(stringTest);



                                                                                          print('+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');


                                                                                          myStream.add(IntTest.indexScreens);
                                                                                        },
                                                                                        child: Padding(
                                                                                          padding: const EdgeInsets.symmetric(horizontal: 10.0),
                                                                                          child: Container(
                                                                                              padding: const EdgeInsets.symmetric(horizontal: 10.0),
                                                                                              decoration: BoxDecoration(borderRadius: BorderRadius.circular(5.0),color: addTOMon == index ? Colors.green[700] : ColorApp.myColorGreenAuth),
                                                                                              height: 30,child: Center(child: Text('${listInTO['type_act_id']['name']}',style: const TextStyle(color: Colors.white,fontWeight: FontWeight.bold)))),
                                                                                        ));
                                                                                  },
                                                                                ),
                                                                              ),
                                                                              const SizedBox(height: 10.0),
                                                                              Column(
                                                                                children: [
                                                                                  /// Добавление нового пункта в ТО'
                                                                                  Padding(
                                                                                    padding: const EdgeInsets.all(5.0),
                                                                                    child: SizedBox(
                                                                                      height: 45.0,
                                                                                      child: Form(
                                                                                        key: keyNameTO1,
                                                                                        autovalidateMode: AutovalidateMode.onUserInteraction,
                                                                                        child: TextFormField(
                                                                                          // validator: (value) {
                                                                                          //   if (value!.isEmpty) {
                                                                                          //     return 'Заполните название';
                                                                                          //   } else {
                                                                                          //     return null;
                                                                                          //   }
                                                                                          // },
                                                                                          cursorColor: ColorApp.myColorGray,
                                                                                          controller: addNewNameTO,
                                                                                          decoration:  InputDecoration(
                                                                                              suffixIcon: IconButton(onPressed: (){
                                                                                                if(addNewNameTO.text.isNotEmpty){
                                                                                                  listToCreatePlanetTO.add({"text" : addNewNameTO.text, "bool" : false});
                                                                                                  print(addNewNameTO.text);
                                                                                                  openBoolTo1 = false;
                                                                                                  myStream.add(IntTest.indexScreens);
                                                                                                  addNewNameTO.clear();
                                                                                                }
                                                                                                // openBoolTo1 = false;
                                                                                                addNewNameTO.clear();
                                                                                                // keyNameTO1.currentState!.validate();

                                                                                              }, icon: const Icon(Icons.send,color: Colors.green)),
                                                                                              icon: IconButton(onPressed: (){
                                                                                                listToCreatePlanetTO.clear();
                                                                                                myStream.add(IntTest.indexScreens);

                                                                                              }, icon: Icon(Icons.settings_backup_restore,color: Colors.red[400])),
                                                                                              labelText: 'Добавление нового пункта в ТО',
                                                                                              border: const OutlineInputBorder(),
                                                                                              focusedBorder: const OutlineInputBorder(
                                                                                                borderSide: BorderSide(
                                                                                                    color: ColorApp.myColorGreenAuth),
                                                                                              ),
                                                                                              // labelText: 'Документ',
                                                                                              labelStyle:
                                                                                              const TextStyle(color: ColorApp.myColorGray)),
                                                                                        ),
                                                                                      ),
                                                                                    ),
                                                                                  ),
                                                                                  const SizedBox(height: 15.0),
                                                                                  /// Список ТО
                                                                                  SizedBox(
                                                                                    height: MediaQuery.of(context).size.height * 0.50,
                                                                                    child: ListView.builder(
                                                                                      itemCount: listToCreatePlanetTO.length,
                                                                                      itemBuilder: (context, index) {
                                                                                        final text = listToCreatePlanetTO[index]['text'];
                                                                                        return Row(
                                                                                          crossAxisAlignment: CrossAxisAlignment.center,
                                                                                          children: [
                                                                                            Expanded(
                                                                                              child: Padding(
                                                                                                padding: const EdgeInsets.only(left: 5.0, right: 5.0,bottom: 5.0),
                                                                                                child: Container(
                                                                                                  padding: const EdgeInsets.all(10.0),
                                                                                                  decoration: BoxDecoration(
                                                                                                      borderRadius: BorderRadius.circular(5.0),
                                                                                                      border: Border.all(color: Colors.grey, width: 1.5)
                                                                                                  ),
                                                                                                  child: Text('$text'),
                                                                                                ),
                                                                                              ),
                                                                                            ),
                                                                                            IconButton(
                                                                                                onPressed:  (){
                                                                                                  listToCreatePlanetTO.removeAt(index);
                                                                                                  myStream.add(IntTest.indexScreens);
                                                                                                }, icon: const Icon(Icons.delete_outline,color: Colors.red)),
                                                                                          ],
                                                                                        );
                                                                                      },
                                                                                    ),
                                                                                  ),
                                                                                ],
                                                                              ),
                                                                              const Spacer(),
                                                                              /// Кнопка Добавить
                                                                              Column(
                                                                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                                                                children: [
                                                                                  ElevatedButton(
                                                                                    style: ElevatedButton.styleFrom(
                                                                                        backgroundColor: listToCreatePlanetTO.isNotEmpty
                                                                                            ?  ColorApp.myColorGreenAuth : Colors.grey,
                                                                                        padding: const EdgeInsets.symmetric(vertical: 20.0)),
                                                                                    onPressed: listToCreatePlanetTO.isNotEmpty
                                                                                        ? () async {
                                                                                      /// ==============
                                                                                      myGetPlanetTO['numberTo'] = listIn['type_act_id']['name'] ;
                                                                                      myGetPlanetTO['stepListTO'] = jsonEncode(listToCreatePlanetTO) ;
                                                                                      /// ==================

                                                                                      /// Создаем факт акт
                                                                                      await creationFactActList(listIn['id']); // готово

                                                                                      /// Изменить ТО Обьекту
                                                                                      await changeTOGraphics('october_to_id', intMonTOTest, getTOScheduleList[0]['id']);
                                                                                      await getTOScheduleIdObject(IntTest.pressHover);
                                                                                      myStream.add(IntTest.indexScreens);
                                                                                      Navigator.pop(context);
                                                                                      setState(() {});
                                                                                    }
                                                                                        : (){},
                                                                                    child: Text(listToCreatePlanetTO.isNotEmpty
                                                                                        ? 'Добавить' : 'Создайте список',
                                                                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                                                                    ),
                                                                                  ),
                                                                                ],
                                                                              ),
                                                                            ],
                                                                          ),
                                                                        );

                                                                      })));
                                                    });
                                                    /// =================================================================================
                                                    // print(listTo['id']);
                                                    // intMon = 1;
                                                    // print(monTO);
                                                    // monTO = 'january_to_id';
                                                    // myStream.add(IntTest.indexScreens);
                                                    // setState(() {});
                                                    // if(listTOJanuary['step_list'] != null){
                                                    //   String stringTestText = listTOJanuary['step_list'].replaceAll("'", '"');
                                                    //   listTOJanuaryText = json.decode(stringTestText);
                                                    //   listTOMonTaskText = listTOJanuaryText;
                                                    //   myStream.add(IntTest.indexScreens);
                                                    //   setState(() {});
                                                    // }else{
                                                    //   listTOMonTaskText.clear();
                                                    // }
                                                    /// =================================================================================
                                                  }
                                                      : (){
                                                    setState(() {
                                                      intMon = 10;
                                                      monTO = 'october_to_id';
                                                      if(listTOOct['stepListTO'] != null){
                                                        getTOScheduleIdObject(IntTest.pressHover);
                                                        intMonTOTes = listTo['october_to_id']['id'];
                                                        String stringTestText = listTOOct['stepListTO'].replaceAll("'", '"');
                                                        listTOJanuaryText = json.decode(stringTestText);
                                                        listTOMonTaskText = listTOJanuaryText;
                                                        myStream.add(IntTest.indexScreens);
                                                      }else{
                                                        listTOMonTaskText.clear();
                                                      }
                                                    });
                                                  },
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      borderRadius: BorderRadius.circular(5.0),
                                                      color: intMon == 10 ? Colors.green : ColorApp.myColorGreen,
                                                    ),
                                                    width: 40,
                                                    height: 40,
                                                    child: Center(child: listTOOct.isNotEmpty ? Text('${listTOOct['numberTo']}',style: const TextStyle(color: Colors.white, fontSize: 12.0)) : const Icon(Icons.add,color: Colors.white)),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(width: 10.0),
                                            /// Ноя
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Text('Ноя'),
                                                InkWell(
                                                  onTap: listTONov.isEmpty
                                                      ? (){
                                                    setState(() {
                                                      showDialog(
                                                          context: context,
                                                          builder: (context) =>
                                                              AlertDialog(
                                                                  content: StreamBuilder(
                                                                      stream: myStream.stream,
                                                                      builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                                                                        return SizedBox(
                                                                          width: 800,
                                                                          child: Column(
                                                                            children: [
                                                                              /// Текст кнопка закрыть
                                                                              Row(
                                                                                children: [
                                                                                  /// Текст
                                                                                  Text(
                                                                                    'Назначить ТО месяцу ',
                                                                                    style: TextStyle(
                                                                                        fontWeight: FontWeight.w700,
                                                                                        fontSize: size.width > 570.0 ? 25.0 : 16.0),
                                                                                  ),
                                                                                  const Spacer(),
                                                                                  /// кнопка закрыть
                                                                                  IconButton(
                                                                                      onPressed: () {
                                                                                        Navigator.pop(context);
                                                                                      },
                                                                                      icon: const Icon(
                                                                                        Icons.close,
                                                                                        color: ColorApp.myColorGreenAuth,
                                                                                      )),
                                                                                ],
                                                                              ),
                                                                              const SizedBox(height: 10.0),
                                                                              /// Кнопки TO
                                                                              SizedBox(
                                                                                height: 50.0,
                                                                                child: ListView.builder(
                                                                                  scrollDirection: Axis.horizontal,
                                                                                  itemCount: templatesObject.length,
                                                                                  itemBuilder: (context, index) {
                                                                                    listInTO = templatesObject[index];
                                                                                    // print('=====================================');
                                                                                    // print(listInTO['id']);
                                                                                    // // print( listInTO['type_act_id']['name']);
                                                                                    // print('=====================================');
                                                                                    return InkWell(
                                                                                        onTap:(){
                                                                                          listIn = templatesObject[index];
                                                                                          addTOMon = index;
                                                                                          print('+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');
                                                                                          print(listIn['type_act_id']['id']);
                                                                                          // listGetSelectedTemplateTO = listIn['step_list'];
                                                                                          // print(index);
                                                                                          String stringTest = listIn['step_list'].replaceAll("'", '"');
                                                                                          listToCreatePlanetTO = json.decode(stringTest);



                                                                                          print('+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');


                                                                                          myStream.add(IntTest.indexScreens);
                                                                                        },
                                                                                        child: Padding(
                                                                                          padding: const EdgeInsets.symmetric(horizontal: 10.0),
                                                                                          child: Container(
                                                                                              padding: const EdgeInsets.symmetric(horizontal: 10.0),
                                                                                              decoration: BoxDecoration(borderRadius: BorderRadius.circular(5.0),color: addTOMon == index ? Colors.green[700] : ColorApp.myColorGreenAuth),
                                                                                              height: 30,child: Center(child: Text('${listInTO['type_act_id']['name']}',style: const TextStyle(color: Colors.white,fontWeight: FontWeight.bold)))),
                                                                                        ));
                                                                                  },
                                                                                ),
                                                                              ),
                                                                              const SizedBox(height: 10.0),
                                                                              Column(
                                                                                children: [
                                                                                  /// Добавление нового пункта в ТО'
                                                                                  Padding(
                                                                                    padding: const EdgeInsets.all(5.0),
                                                                                    child: SizedBox(
                                                                                      height: 45.0,
                                                                                      child: Form(
                                                                                        key: keyNameTO1,
                                                                                        autovalidateMode: AutovalidateMode.onUserInteraction,
                                                                                        child: TextFormField(
                                                                                          // validator: (value) {
                                                                                          //   if (value!.isEmpty) {
                                                                                          //     return 'Заполните название';
                                                                                          //   } else {
                                                                                          //     return null;
                                                                                          //   }
                                                                                          // },
                                                                                          cursorColor: ColorApp.myColorGray,
                                                                                          controller: addNewNameTO,
                                                                                          decoration:  InputDecoration(
                                                                                              suffixIcon: IconButton(onPressed: (){
                                                                                                if(addNewNameTO.text.isNotEmpty){
                                                                                                  listToCreatePlanetTO.add({"text" : addNewNameTO.text, "bool" : false});
                                                                                                  print(addNewNameTO.text);
                                                                                                  openBoolTo1 = false;
                                                                                                  myStream.add(IntTest.indexScreens);
                                                                                                  addNewNameTO.clear();
                                                                                                }
                                                                                                // openBoolTo1 = false;
                                                                                                addNewNameTO.clear();
                                                                                                // keyNameTO1.currentState!.validate();

                                                                                              }, icon: const Icon(Icons.send,color: Colors.green)),
                                                                                              icon: IconButton(onPressed: (){
                                                                                                listToCreatePlanetTO.clear();
                                                                                                myStream.add(IntTest.indexScreens);

                                                                                              }, icon: Icon(Icons.settings_backup_restore,color: Colors.red[400])),
                                                                                              labelText: 'Добавление нового пункта в ТО',
                                                                                              border: const OutlineInputBorder(),
                                                                                              focusedBorder: const OutlineInputBorder(
                                                                                                borderSide: BorderSide(
                                                                                                    color: ColorApp.myColorGreenAuth),
                                                                                              ),
                                                                                              // labelText: 'Документ',
                                                                                              labelStyle:
                                                                                              const TextStyle(color: ColorApp.myColorGray)),
                                                                                        ),
                                                                                      ),
                                                                                    ),
                                                                                  ),
                                                                                  const SizedBox(height: 15.0),
                                                                                  /// Список ТО
                                                                                  SizedBox(
                                                                                    height: MediaQuery.of(context).size.height * 0.50,
                                                                                    child: ListView.builder(
                                                                                      itemCount: listToCreatePlanetTO.length,
                                                                                      itemBuilder: (context, index) {
                                                                                        final text = listToCreatePlanetTO[index]['text'];
                                                                                        return Row(
                                                                                          crossAxisAlignment: CrossAxisAlignment.center,
                                                                                          children: [
                                                                                            Expanded(
                                                                                              child: Padding(
                                                                                                padding: const EdgeInsets.only(left: 5.0, right: 5.0,bottom: 5.0),
                                                                                                child: Container(
                                                                                                  padding: const EdgeInsets.all(10.0),
                                                                                                  decoration: BoxDecoration(
                                                                                                      borderRadius: BorderRadius.circular(5.0),
                                                                                                      border: Border.all(color: Colors.grey, width: 1.5)
                                                                                                  ),
                                                                                                  child: Text('$text'),
                                                                                                ),
                                                                                              ),
                                                                                            ),
                                                                                            IconButton(
                                                                                                onPressed:  (){
                                                                                                  listToCreatePlanetTO.removeAt(index);
                                                                                                  myStream.add(IntTest.indexScreens);
                                                                                                }, icon: const Icon(Icons.delete_outline,color: Colors.red)),
                                                                                          ],
                                                                                        );
                                                                                      },
                                                                                    ),
                                                                                  ),
                                                                                ],
                                                                              ),
                                                                              const Spacer(),
                                                                              /// Кнопка Добавить
                                                                              Column(
                                                                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                                                                children: [
                                                                                  ElevatedButton(
                                                                                    style: ElevatedButton.styleFrom(
                                                                                        backgroundColor: listToCreatePlanetTO.isNotEmpty
                                                                                            ?  ColorApp.myColorGreenAuth : Colors.grey,
                                                                                        padding: const EdgeInsets.symmetric(vertical: 20.0)),
                                                                                    onPressed: listToCreatePlanetTO.isNotEmpty
                                                                                        ? () async {
                                                                                      /// ==============
                                                                                      myGetPlanetTO['numberTo'] = listIn['type_act_id']['name'] ;
                                                                                      myGetPlanetTO['stepListTO'] = jsonEncode(listToCreatePlanetTO) ;
                                                                                      /// ==================

                                                                                      /// Создаем факт акт
                                                                                      await creationFactActList(listIn['id']); // готово

                                                                                      /// Изменить ТО Обьекту
                                                                                      await changeTOGraphics('november_to_id', intMonTOTest, getTOScheduleList[0]['id']);
                                                                                      await getTOScheduleIdObject(IntTest.pressHover);
                                                                                      myStream.add(IntTest.indexScreens);
                                                                                      Navigator.pop(context);
                                                                                      setState(() {});
                                                                                    }
                                                                                        : (){},
                                                                                    child: Text(listToCreatePlanetTO.isNotEmpty
                                                                                        ? 'Добавить' : 'Создайте список',
                                                                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                                                                    ),
                                                                                  ),
                                                                                ],
                                                                              ),
                                                                            ],
                                                                          ),
                                                                        );

                                                                      })));
                                                    });
                                                    /// =================================================================================
                                                    // print(listTo['id']);
                                                    // intMon = 1;
                                                    // print(monTO);
                                                    // monTO = 'january_to_id';
                                                    // myStream.add(IntTest.indexScreens);
                                                    // setState(() {});
                                                    // if(listTOJanuary['step_list'] != null){
                                                    //   String stringTestText = listTOJanuary['step_list'].replaceAll("'", '"');
                                                    //   listTOJanuaryText = json.decode(stringTestText);
                                                    //   listTOMonTaskText = listTOJanuaryText;
                                                    //   myStream.add(IntTest.indexScreens);
                                                    //   setState(() {});
                                                    // }else{
                                                    //   listTOMonTaskText.clear();
                                                    // }
                                                    /// =================================================================================
                                                  }
                                                      : (){
                                                    setState(() {
                                                      intMon = 11;
                                                      monTO = 'november_to_id';
                                                      if(listTONov['stepListTO'] != null){
                                                        getTOScheduleIdObject(IntTest.pressHover);
                                                        intMonTOTes = listTo['november_to_id']['id'];
                                                        String stringTestText = listTONov['stepListTO'].replaceAll("'", '"');
                                                        listTOJanuaryText = json.decode(stringTestText);
                                                        listTOMonTaskText = listTOJanuaryText;
                                                        myStream.add(IntTest.indexScreens);
                                                      }else{
                                                        listTOMonTaskText.clear();
                                                      }
                                                    });
                                                  },
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      borderRadius: BorderRadius.circular(5.0),
                                                      color: intMon == 11 ? Colors.green : ColorApp.myColorGreen,
                                                    ),
                                                    width: 40,
                                                    height: 40,
                                                    child: Center(child: listTONov.isNotEmpty ? Text('${listTONov['numberTo']}',style: const TextStyle(color: Colors.white, fontSize: 12.0)) : const Icon(Icons.add,color: Colors.white)),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(width: 10.0),
                                            /// Дек
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                const Text('Дек'),
                                                InkWell(
                                                  onTap: listTODec.isEmpty
                                                      ? (){
                                                    setState(() {
                                                      showDialog(
                                                          context: context,
                                                          builder: (context) =>
                                                              AlertDialog(
                                                                  content: StreamBuilder(
                                                                      stream: myStream.stream,
                                                                      builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                                                                        return SizedBox(
                                                                          width: 800,
                                                                          child: Column(
                                                                            children: [
                                                                              /// Текст кнопка закрыть
                                                                              Row(
                                                                                children: [
                                                                                  /// Текст
                                                                                  Text(
                                                                                    'Назначить ТО месяцу ',
                                                                                    style: TextStyle(
                                                                                        fontWeight: FontWeight.w700,
                                                                                        fontSize: size.width > 570.0 ? 25.0 : 16.0),
                                                                                  ),
                                                                                  const Spacer(),
                                                                                  /// кнопка закрыть
                                                                                  IconButton(
                                                                                      onPressed: () {
                                                                                        Navigator.pop(context);
                                                                                      },
                                                                                      icon: const Icon(
                                                                                        Icons.close,
                                                                                        color: ColorApp.myColorGreenAuth,
                                                                                      )),
                                                                                ],
                                                                              ),
                                                                              const SizedBox(height: 10.0),
                                                                              /// Кнопки TO
                                                                              SizedBox(
                                                                                height: 50.0,
                                                                                child: ListView.builder(
                                                                                  scrollDirection: Axis.horizontal,
                                                                                  itemCount: templatesObject.length,
                                                                                  itemBuilder: (context, index) {
                                                                                    listInTO = templatesObject[index];
                                                                                    return InkWell(
                                                                                        onTap:(){
                                                                                          listIn = templatesObject[index];
                                                                                          addTOMon = index;
                                                                                          String stringTest = listIn['step_list'].replaceAll("'", '"');
                                                                                          listToCreatePlanetTO = json.decode(stringTest);
                                                                                          myStream.add(IntTest.indexScreens);
                                                                                        },
                                                                                        child: Padding(
                                                                                          padding: const EdgeInsets.symmetric(horizontal: 10.0),
                                                                                          child: Container(
                                                                                              padding: const EdgeInsets.symmetric(horizontal: 10.0),
                                                                                              decoration: BoxDecoration(borderRadius: BorderRadius.circular(5.0),color: addTOMon == index ? Colors.green[700] : ColorApp.myColorGreenAuth),
                                                                                              height: 30,child: Center(child: Text('${listInTO['type_act_id']['name']}',style: const TextStyle(color: Colors.white,fontWeight: FontWeight.bold)))),
                                                                                        ));
                                                                                  },
                                                                                ),
                                                                              ),
                                                                              const SizedBox(height: 10.0),
                                                                              Column(
                                                                                children: [
                                                                                  /// Добавление нового пункта в ТО'
                                                                                  Padding(
                                                                                    padding: const EdgeInsets.all(5.0),
                                                                                    child: SizedBox(
                                                                                      height: 45.0,
                                                                                      child: Form(
                                                                                        key: keyNameTO1,
                                                                                        autovalidateMode: AutovalidateMode.onUserInteraction,
                                                                                        child: TextFormField(
                                                                                          // validator: (value) {
                                                                                          //   if (value!.isEmpty) {
                                                                                          //     return 'Заполните название';
                                                                                          //   } else {
                                                                                          //     return null;
                                                                                          //   }
                                                                                          // },
                                                                                          cursorColor: ColorApp.myColorGray,
                                                                                          controller: addNewNameTO,
                                                                                          decoration:  InputDecoration(
                                                                                              suffixIcon: IconButton(onPressed: (){
                                                                                                if(addNewNameTO.text.isNotEmpty){
                                                                                                  listToCreatePlanetTO.add({"text" : addNewNameTO.text, "bool" : false});
                                                                                                  print(addNewNameTO.text);
                                                                                                  openBoolTo1 = false;
                                                                                                  myStream.add(IntTest.indexScreens);
                                                                                                  addNewNameTO.clear();
                                                                                                }
                                                                                                // openBoolTo1 = false;
                                                                                                addNewNameTO.clear();
                                                                                                // keyNameTO1.currentState!.validate();

                                                                                              }, icon: const Icon(Icons.send,color: Colors.green)),
                                                                                              icon: IconButton(onPressed: (){
                                                                                                listToCreatePlanetTO.clear();
                                                                                                myStream.add(IntTest.indexScreens);

                                                                                              }, icon: Icon(Icons.settings_backup_restore,color: Colors.red[400])),
                                                                                              labelText: 'Добавление нового пункта в ТО',
                                                                                              border: const OutlineInputBorder(),
                                                                                              focusedBorder: const OutlineInputBorder(
                                                                                                borderSide: BorderSide(
                                                                                                    color: ColorApp.myColorGreenAuth),
                                                                                              ),
                                                                                              // labelText: 'Документ',
                                                                                              labelStyle:
                                                                                              const TextStyle(color: ColorApp.myColorGray)),
                                                                                        ),
                                                                                      ),
                                                                                    ),
                                                                                  ),
                                                                                  const SizedBox(height: 15.0),
                                                                                  /// Список ТО
                                                                                  SizedBox(
                                                                                    height: MediaQuery.of(context).size.height * 0.50,
                                                                                    child: ListView.builder(
                                                                                      itemCount: listToCreatePlanetTO.length,
                                                                                      itemBuilder: (context, index) {
                                                                                        final text = listToCreatePlanetTO[index]['text'];
                                                                                        return Row(
                                                                                          crossAxisAlignment: CrossAxisAlignment.center,
                                                                                          children: [
                                                                                            Expanded(
                                                                                              child: Padding(
                                                                                                padding: const EdgeInsets.only(left: 5.0, right: 5.0,bottom: 5.0),
                                                                                                child: Container(
                                                                                                  padding: const EdgeInsets.all(10.0),
                                                                                                  decoration: BoxDecoration(
                                                                                                      borderRadius: BorderRadius.circular(5.0),
                                                                                                      border: Border.all(color: Colors.grey, width: 1.5)
                                                                                                  ),
                                                                                                  child: Text('$text'),
                                                                                                ),
                                                                                              ),
                                                                                            ),
                                                                                            IconButton(
                                                                                                onPressed:  (){
                                                                                                  listToCreatePlanetTO.removeAt(index);
                                                                                                  myStream.add(IntTest.indexScreens);
                                                                                                }, icon: const Icon(Icons.delete_outline,color: Colors.red)),
                                                                                          ],
                                                                                        );
                                                                                      },
                                                                                    ),
                                                                                  ),
                                                                                ],
                                                                              ),
                                                                              const Spacer(),
                                                                              /// Кнопка Добавить
                                                                              Column(
                                                                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                                                                children: [
                                                                                  ElevatedButton(
                                                                                    style: ElevatedButton.styleFrom(
                                                                                        backgroundColor: listToCreatePlanetTO.isNotEmpty
                                                                                            ?  ColorApp.myColorGreenAuth : Colors.grey,
                                                                                        padding: const EdgeInsets.symmetric(vertical: 20.0)),
                                                                                    onPressed: listToCreatePlanetTO.isNotEmpty
                                                                                        ? () async {
                                                                                      /// ==============
                                                                                      myGetPlanetTO['numberTo'] = listIn['type_act_id']['name'] ;
                                                                                      myGetPlanetTO['stepListTO'] = jsonEncode(listToCreatePlanetTO) ;
                                                                                      /// ==================

                                                                                      /// Создаем факт акт
                                                                                      await creationFactActList(listIn['id']); // готово

                                                                                      /// Изменить ТО Обьекту
                                                                                      await changeTOGraphics('december_to_id', intMonTOTest, getTOScheduleList[0]['id']);
                                                                                      await getTOScheduleIdObject(IntTest.pressHover);
                                                                                      myStream.add(IntTest.indexScreens);
                                                                                      Navigator.pop(context);
                                                                                      setState(() {});
                                                                                    }
                                                                                        : (){},
                                                                                    child: Text(listToCreatePlanetTO.isNotEmpty
                                                                                        ? 'Добавить' : 'Создайте список',
                                                                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                                                                    ),
                                                                                  ),
                                                                                ],
                                                                              ),
                                                                            ],
                                                                          ),
                                                                        );

                                                                      })));
                                                    });}
                                                      : (){
                                                    setState(() {
                                                      intMon = 12;
                                                      monTO = 'december_to_id';
                                                      if(listTODec['stepListTO'] != null){
                                                        getTOScheduleIdObject(IntTest.pressHover);
                                                        intMonTOTes = listTo['december_to_id']['id'];
                                                        String stringTestText = listTODec['stepListTO'].replaceAll("'", '"');
                                                        listTOJanuaryText = json.decode(stringTestText);
                                                        listTOMonTaskText = listTOJanuaryText;
                                                        myStream.add(IntTest.indexScreens);
                                                      }else{
                                                        listTOMonTaskText.clear();
                                                      }
                                                    });

                                                  },
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      borderRadius: BorderRadius.circular(5.0),
                                                      color: intMon == 12 ? Colors.green : ColorApp.myColorGreen,
                                                    ),
                                                    width: 40,
                                                    height: 40,
                                                    child: Center(child: listTODec.isNotEmpty ? Text('${listTODec['numberTo']}',style: const TextStyle(color: Colors.white, fontSize: 12.0)) : const Icon(Icons.add,color: Colors.white)),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const Spacer(),
                                            Text(listTo['year']),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              /// Список назначеного ТО
                              if(intMon != 0)
                                Column(
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        /// Кнопка Изменить ТО месяцу
                                        ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                                backgroundColor: ColorApp.myColorGreenAuth),
                                            onPressed: () async {
                                              setState(() {
                                                showDialog(
                                                    context: context,
                                                    builder: (context) =>
                                                        AlertDialog(
                                                            content: StreamBuilder(
                                                                stream: myStream.stream,
                                                                builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                                                                  return SizedBox(
                                                                    width: 800,
                                                                    child: Column(
                                                                      children: [
                                                                        /// Текст кнопка закрыть
                                                                        Row(
                                                                          children: [
                                                                            /// Текст
                                                                            Text(
                                                                              'Назначить ТО месяцу ',
                                                                              style: TextStyle(
                                                                                  fontWeight: FontWeight.w700,
                                                                                  fontSize: size.width > 570.0 ? 25.0 : 16.0),
                                                                            ),
                                                                            const Spacer(),
                                                                            /// кнопка закрыть
                                                                            IconButton(
                                                                                onPressed: () {
                                                                                  Navigator.pop(context);
                                                                                },
                                                                                icon: const Icon(
                                                                                  Icons.close,
                                                                                  color: ColorApp.myColorGreenAuth,
                                                                                )),
                                                                          ],
                                                                        ),
                                                                        const SizedBox(height: 10.0),
                                                                        /// Кнопки TO
                                                                        SizedBox(
                                                                          height: 50.0,
                                                                          child: ListView.builder(
                                                                            scrollDirection: Axis.horizontal,
                                                                            itemCount: templatesObject.length,
                                                                            itemBuilder: (context, index) {
                                                                              listInTO = templatesObject[index];
                                                                              return InkWell(
                                                                                  onTap:(){
                                                                                    listIn = templatesObject[index];
                                                                                    print(listIn['type_act_id']['name']);
                                                                                    addTOMon = index;
                                                                                    String stringTest = listIn['step_list'].replaceAll("'", '"');
                                                                                    listToCreatePlanetTO = json.decode(stringTest);
                                                                                    myStream.add(IntTest.indexScreens);
                                                                                  },
                                                                                  child: Padding(
                                                                                    padding: const EdgeInsets.symmetric(horizontal: 10.0),
                                                                                    child: Container(
                                                                                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                                                                                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(5.0),color: addTOMon == index ? Colors.green[700] : ColorApp.myColorGreenAuth),
                                                                                        height: 30,child: Center(child: Text('${listInTO['type_act_id']['name']}',style: const TextStyle(color: Colors.white,fontWeight: FontWeight.bold)))),
                                                                                  ));
                                                                            },
                                                                          ),
                                                                        ),
                                                                        const SizedBox(height: 10.0),
                                                                        /// Список
                                                                        Column(
                                                                          children: [
                                                                            /// Добавление нового пункта в ТО'
                                                                            Padding(
                                                                              padding: const EdgeInsets.all(5.0),
                                                                              child: SizedBox(
                                                                                height: 45.0,
                                                                                child: Form(
                                                                                  key: keyNameTO1,
                                                                                  autovalidateMode: AutovalidateMode.onUserInteraction,
                                                                                  child: TextFormField(
                                                                                    // validator: (value) {
                                                                                    //   if (value!.isEmpty) {
                                                                                    //     return 'Заполните название';
                                                                                    //   } else {
                                                                                    //     return null;
                                                                                    //   }
                                                                                    // },
                                                                                    cursorColor: ColorApp.myColorGray,
                                                                                    controller: addNewNameTO,
                                                                                    decoration:  InputDecoration(
                                                                                        suffixIcon: IconButton(onPressed: (){
                                                                                          if(addNewNameTO.text.isNotEmpty){
                                                                                            listToCreatePlanetTO.add({"text" : addNewNameTO.text, "bool" : false});
                                                                                            print(addNewNameTO.text);
                                                                                            openBoolTo1 = false;
                                                                                            myStream.add(IntTest.indexScreens);
                                                                                            addNewNameTO.clear();
                                                                                          }
                                                                                          // openBoolTo1 = false;
                                                                                          addNewNameTO.clear();
                                                                                          // keyNameTO1.currentState!.validate();

                                                                                        }, icon: const Icon(Icons.send,color: Colors.green)),
                                                                                        icon: IconButton(onPressed: (){
                                                                                          listToCreatePlanetTO.clear();
                                                                                          myStream.add(IntTest.indexScreens);

                                                                                        }, icon: Icon(Icons.settings_backup_restore,color: Colors.red[400])),
                                                                                        labelText: 'Добавление нового пункта в ТО',
                                                                                        border: const OutlineInputBorder(),
                                                                                        focusedBorder: const OutlineInputBorder(
                                                                                          borderSide: BorderSide(
                                                                                              color: ColorApp.myColorGreenAuth),
                                                                                        ),
                                                                                        // labelText: 'Документ',
                                                                                        labelStyle:
                                                                                        const TextStyle(color: ColorApp.myColorGray)),
                                                                                  ),
                                                                                ),
                                                                              ),
                                                                            ),
                                                                            const SizedBox(height: 15.0),
                                                                            /// Список ТО
                                                                            SizedBox(
                                                                              height: MediaQuery.of(context).size.height*0.50,
                                                                              child: ListView.builder(
                                                                                itemCount: listToCreatePlanetTO.length,
                                                                                itemBuilder: (context, index) {
                                                                                  final text = listToCreatePlanetTO[index]['text'];
                                                                                  return Row(
                                                                                    crossAxisAlignment: CrossAxisAlignment.center,
                                                                                    children: [
                                                                                      Expanded(
                                                                                        child: Padding(
                                                                                          padding: const EdgeInsets.only(left: 5.0, right: 5.0,bottom: 5.0),
                                                                                          child: Container(
                                                                                            padding: const EdgeInsets.all(10.0),
                                                                                            decoration: BoxDecoration(
                                                                                                borderRadius: BorderRadius.circular(5.0),
                                                                                                border: Border.all(color: Colors.grey, width: 1.5)
                                                                                            ),
                                                                                            child: Text('$text'),
                                                                                          ),
                                                                                        ),
                                                                                      ),
                                                                                      IconButton(
                                                                                          onPressed:  (){
                                                                                            listToCreatePlanetTO.removeAt(index);
                                                                                            myStream.add(IntTest.indexScreens);
                                                                                          }, icon: const Icon(Icons.delete_outline,color: Colors.red)),
                                                                                    ],
                                                                                  );
                                                                                },
                                                                              ),
                                                                            ),
                                                                          ],
                                                                        ),
                                                                        const Spacer(),
                                                                        /// Кнопка Добавить
                                                                        Column(
                                                                          crossAxisAlignment: CrossAxisAlignment.stretch,
                                                                          children: [
                                                                            ElevatedButton(
                                                                              style: ElevatedButton.styleFrom(
                                                                                  backgroundColor: listToCreatePlanetTO.isNotEmpty
                                                                                      ?  ColorApp.myColorGreenAuth : Colors.grey,
                                                                                  padding: const EdgeInsets.symmetric(vertical: 20.0)),
                                                                              onPressed: listToCreatePlanetTO.isNotEmpty
                                                                                  ? () async {

                                                                                /// ===========================================================
                                                                                myGetPlanetTO['numberTo'] = listIn['type_act_id']['name'];
                                                                                myGetPlanetTO['stepListTO'] = jsonEncode(listToCreatePlanetTO);
                                                                                /// ===========================================================


                                                                                String listNewTo = json.encode(myGetPlanetTO);

                                                                                /// Изменить ТО Обьекту
                                                                                await correctFactActList(intMonTOTes, listNewTo);



                                                                                await getTOScheduleIdObject(IntTest.pressHover);


                                                                                myStream.add(IntTest.indexScreens);
                                                                                Navigator.pop(context);
                                                                                setState(() {});
                                                                              }
                                                                                  : (){},
                                                                              child: Text(listToCreatePlanetTO.isNotEmpty
                                                                                  ? 'Добавить' : 'Создайте список',
                                                                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                                                              ),
                                                                            ),
                                                                          ],
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  );


                                                                })));
                                              });
                                              // await creationTOGraphics('2025', IntTest.pressHover);
                                              // await getTOScheduleIdObject(IntTest.pressHover);
                                              myStream.add(IntTest.indexScreens);
                                            }, child: const Text('Изменить ТО месяцу')),
                                        const SizedBox(height: 10.0),
                                        /// Завершить ТО
                                        ///
                                        /// Единственное место, где акт получает
                                        /// дату окончания. От неё считается
                                        /// виджет «Выполнение графика» на
                                        /// главной: без закрытия акта участок
                                        /// выглядит проваленным.
                                        FinishTOButton(
                                          actId: intMonTOTes,
                                          finishedAt: listTo[monTO] is Map
                                              ? listTo[monTO]['finished_at']
                                              : null,
                                          onFinished: () async {
                                            await getTOScheduleIdObject(IntTest.pressHover);
                                            myStream.add(IntTest.indexScreens);
                                          },
                                        ),
                                        const SizedBox(height: 10.0),
                                        /// Список ТО
                                        StreamBuilder(
                                          stream: myStreamListPlanetTO.stream,
                                          builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                                            return  SizedBox(
                                              height: 400,
                                              child: ListView.builder(
                                                itemCount: listTOMonTaskText.length,
                                                itemBuilder: (context, index) {
                                                  final listToText = listTOMonTaskText[index];


                                                  ///================================
                                                  return Padding(
                                                    padding: const EdgeInsets.all(5.0),
                                                    child: Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 10.0,vertical: 10.0),
                                                      decoration: BoxDecoration(
                                                        borderRadius: BorderRadius.circular(5.0),
                                                        color: Colors.white,
                                                        boxShadow: const [
                                                          BoxShadow(
                                                            color: Colors.grey,
                                                            blurRadius: 5,
                                                          ),
                                                        ],
                                                      ),
                                                      child: Column(
                                                        children: [
                                                          Row(
                                                            children: [
                                                              Icon(Icons.circle,color: listToText['comment'] != '' ? Colors.red : listToText['bool'] == false ? Colors.orange : Colors.green),
                                                              const SizedBox(width: 10.0),
                                                              Expanded(child: Text('${listToText['text']}', style: const TextStyle(fontWeight: FontWeight.w600))),
                                                            ],
                                                          ),
                                                          if(listToText['comment'] != '')
                                                            Row(
                                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                              crossAxisAlignment: CrossAxisAlignment.center,
                                                              children: [
                                                                Expanded(
                                                                  child: Padding(
                                                                    padding: const EdgeInsets.all(10.0),
                                                                    child: Column(
                                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                                      children: [
                                                                        const SizedBox(height: 10.0),
                                                                        Text('Коментарий', style: TextStyle(color: Colors.grey.shade400)),
                                                                        const SizedBox(height: 5.0),
                                                                        Row(
                                                                          children: [
                                                                            Expanded(child: Container(
                                                                                decoration: BoxDecoration(
                                                                                    borderRadius: BorderRadius.circular(7.0),
                                                                                    border: Border.all(color: Colors.grey.shade300,width: 1.5)
                                                                                ),
                                                                                height: 150,
                                                                                child: Padding(
                                                                                  padding: const EdgeInsets.all(7.0),
                                                                                  child: Text('${listToText['comment']}'),
                                                                                ))),

                                                                            if(listToText['photo'] != null)
                                                                              Row(
                                                                                children: [
                                                                                  const SizedBox(width: 10.0),
                                                                                  InkWell(
                                                                                    onTap: (){
                                                                                      setState(() {
                                                                                        showDialog(
                                                                                            context: context,
                                                                                            builder: (context) =>
                                                                                                AlertDialog(
                                                                                                  contentPadding: const EdgeInsets.all(5.0),
                                                                                                  content: ClipRRect(
                                                                                                    borderRadius: BorderRadius.circular(10.0),
                                                                                                    child: Image.memory(
                                                                                                      Uint8List.fromList(List<int>.from(listToText['photo'])),
                                                                                                      width: 500,
                                                                                                      height: 500,
                                                                                                      fit: BoxFit.cover,
                                                                                                    ),
                                                                                                  ),

                                                                                                ));
                                                                                      });
                                                                                    },
                                                                                    child: ClipRRect(
                                                                                      borderRadius: BorderRadius.circular(10.0),
                                                                                      child: Image.memory(
                                                                                        Uint8List.fromList(List<int>.from(listToText['photo'])),
                                                                                        width: 150,
                                                                                        height: 150,
                                                                                        fit: BoxFit.cover,
                                                                                      ),
                                                                                    ),
                                                                                  ),
                                                                                ],
                                                                              ),
                                                                          ],
                                                                        ),

                                                                      ],
                                                                    ),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                        ],
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
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
        ],
      ),
    );
  }
}



