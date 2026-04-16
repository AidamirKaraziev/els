import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:http/http.dart' as http;
import 'package:location/location.dart';
import 'package:open_street_map_search_and_pick/open_street_map_search_and_pick.dart';
import '../../../helper/class_colors.dart';
import '../../../widgets_create/organization_greate.dart';
import '../../companies/widgets/add_companies.dart';
import '../../employee/widgets/add_employee.dart';
import '../../home_page/home_page.dart';
import '../../object/view/object_screen.dart';
import '../../object/widgets/add_contact_person_object.dart';
import '../../object/widgets/add_contract.dart';
import '../../object/widgets/add_model.dart';
import '../../object/widgets/add_object.dart';
import '../../object/widgets/add_plot.dart';
import '../view/companies_screen.dart';
import 'add_contact_person.dart';


///Создание объекта для компании

class AddObjectCompanies extends StatefulWidget {
  const AddObjectCompanies({
    Key? key,
  }) : super(key: key);

  @override
  State<AddObjectCompanies> createState() => _AddObjectCompaniesState();
}

class _AddObjectCompaniesState extends State<AddObjectCompanies> {
  /// Создание Обьекта компании =====
  createObjectCompanies() async {
    var response = await http.post(
      Uri.parse("http://${IntTest.myIp}/api/v1/object/"), // listSelectedCompany['data']['id']
      headers: {
        "Content-Type": "application/json; charset=utf-8",
        'Authorization': 'Bearer ${IntTest.token}', // organizationTitle <<<<<
      },
      body: json.encode(
        {
          "name": nameObject.text,
          "organization_id": organizationTitle,
          "division_id": myPlotTitle,
          "address": myAddress,
          "factory_model_id": modelTitleId,
          "factory_number": factoryNumber.text,
          "registration_number": registrationNumber.text,
          "number_of_stops": int.parse(numberOfStops.text),//
          "lifting_heights": int.parse(liftingHeight.text),//
          "load_capacity": int.parse(loadCapacity.text),//
          "cost_nds": int.parse(priceNDS.text),
          "cost_no_nds": int.parse(priceNoNDS.text),
          "company_id": listSelectedCompany['data']['id'],
          "contact_person_id": contactPersonTitle,
          "contract_id": getTreatyTitle,
          "date_inspection": dateFullTO.millisecondsSinceEpoch / 1000,
          "planned_inspection": datePlannedTO.millisecondsSinceEpoch / 1000,
          "period_inspection": periodTO.millisecondsSinceEpoch / 1000,
          "foreman_id": foremanTitle,
          "mechanic_id": mechanicTitle,
          "geo": "$myLat ,$myLong"
        },
      ),
    );
    var listAddObject = jsonDecode(utf8.decode(response.bodyBytes));
    print('Новый обьект +++++${listAddObject}++++');
    listSelectedObjectCompany.add(listAddObject['data']);
    dataObject.add(listAddObject['data']);
    myStream.add(IntTest.indexScreens);
  }
  /// ===============================

  /// Название Обьекта
  TextEditingController nameObject = TextEditingController();

  /// адрес
  TextEditingController legalAddress = TextEditingController();

  /// Регистрационный номер
  TextEditingController registrationNumber = TextEditingController();

  /// Заводской номер
  TextEditingController factoryNumber = TextEditingController();

  /// Количество остановок
  TextEditingController numberOfStops = TextEditingController();

  /// Высота подъема
  TextEditingController liftingHeight = TextEditingController();

  /// Грузоподъемность
  TextEditingController loadCapacity = TextEditingController();

  /// Ширина
  TextEditingController elevatorWidth = TextEditingController();

  /// Стоимость ТО с НДС
  TextEditingController priceNDS = TextEditingController();

  /// Стоимость ТО без НДС
  TextEditingController priceNoNDS = TextEditingController();
  /// ================================================================

  var myDivider = Column(
    children: const [
      SizedBox(height: 40.0),
      Divider(color: ColorApp.myColorGrayText, height: 2),
      SizedBox(height: 30.0),
    ],
  );

  int my = 1;

  DateTime dateFullTO = DateTime.now();
  DateTime datePlannedTO = DateTime.now();
  DateTime periodTO = DateTime.now();

  /// Для карты ==============
  late String myAddress = '';

  late Future<PermissionStatus> myLatLong = location.requestPermission();

  Location location = Location();
  late bool _serviceEnabled;
  late PermissionStatus _permissionGranted;
  late LocationData _locationData;

  var myLat;
  var myLong;

  getLocation() async {
    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        return;
      }
    }

    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return;
      }
    }

    _locationData = await location.getLocation();
    // print('отработал');
    // print(_locationData.latitude);
    // print(_locationData.longitude);
  }

  /// ========================

  @override
  void initState() {
    organizationTitle = null;
    myPlotTitle = null;
    typeObjectTitle = null;
    modelTitleId = null;
    getCompanyTitle = null;
    contactPersonTitle = null;
    getTreatyTitle = null;
    mechanicTitle = null;
    foremanTitle = null;
    getOrganizationObjectList();
    getPlot();
    getCompanyObjectList();
    getTreatyObjectList();
    getForemanObjectList();
    getMechanicObjectList();
    getContactPersonObjectList();
    getContactPersonSelectedCompanyList();
    getTypeObjectList();
    getLocation();
    getTreatyObjectList();
    // TODO: implement initState
    super.initState();
  }

  final regNameObject = GlobalKey<FormState>();
  final regNum = GlobalKey<FormState>();
  final zavNum = GlobalKey<FormState>();
  final priceNds = GlobalKey<FormState>();
  final priceNoNds = GlobalKey<FormState>();
  final numLoadCapacity = GlobalKey<FormState>();
  final numLiftingHeight = GlobalKey<FormState>();
  final numSfStops = GlobalKey<FormState>();



  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    ScrollController addObjectScrollController = ScrollController();
    return StreamBuilder(
      stream: myStream.stream,
      builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
        return SingleChildScrollView(
          controller: addObjectScrollController,
          child: SizedBox(
            width: 790.0,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ///Текст и кнопкка закрыть
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Создание объекта',
                          style: TextStyle(
                              fontSize: 25.0, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 5.0),
                        Text(
                          'Заполните все поля, чтобы добавить новый объект в систему',
                          style: TextStyle(color: Colors.grey.shade400),
                        ),
                      ],
                    ),
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
                const Gap(30.0),

                ///Название Обьекта, Организация,
                Row(
                  children: [
                    /// Название Обьекта
                    Expanded(
                      child: Form(
                        key: regNameObject,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        child: TextFormField(
                          validator: (value) {
                            if (value!.isEmpty) {
                              return 'Заполните название';
                            } else {
                              return null;
                            }
                          },
                          cursorColor: ColorApp.myColorGray,
                          controller: nameObject,
                          decoration: const InputDecoration(
                              labelText: 'Название Обьекта',
                              border: OutlineInputBorder(),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: ColorApp.myColorGreenAuth),
                              ),
                              // labelText: 'Документ',
                              labelStyle:
                              TextStyle(color: ColorApp.myColorGray)),
                        ),
                      ),
                    ),
                    const Gap(20.0),

                    /// Организация
                    Expanded(
                      child: SizedBox(
                        height: 50.0,
                        child: DropdownButtonFormField(
                          value: organizationTitle,
                          hint: const Text('Организация'),
                          onChanged: (newValue1) async {
                            setState(() {
                              organizationTitle = newValue1 as String?;
                              organizationTitle!.indexOf(newValue1!);
                              print(organizationTitle);
                            });
                          },
                          items: organizationList.map((organizationTitleList) {
                            return DropdownMenuItem(
                              value: organizationTitleList['id'].toString(),
                              child: Text(organizationTitleList['title']),
                            );
                          }).toList(),
                          decoration: InputDecoration(
                              prefixIcon: IconButton(
                                  onPressed: () async {
                                    setState(() {
                                      showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            content: AddOrganization(),
                                          ))
                                          .then((value) => setState(() {}));
                                    });
                                  },
                                  icon: const Icon(Icons.add_box_rounded,
                                      size: 20.0,
                                      color: ColorApp.myColorGreenAuth)),
                              border: const OutlineInputBorder()),
                        ),
                      ),
                    ),
                    const Gap(20.0),

                    /// Участок
                    Expanded(
                      child: SizedBox(
                        height: 50.0,
                        child: DropdownButtonFormField(
                          value: myPlotTitle,
                          hint: const Text('Участок'),
                          onChanged: (newValue1) async {
                            setState(() {
                              myPlotTitle = newValue1 as String?;
                              myPlotTitle!.indexOf(newValue1!);
                              print(myPlotTitle);
                            });
                          },
                          items: plotList.map((jobTitleList) {
                            return DropdownMenuItem(
                              value: jobTitleList['id'].toString(),
                              child: SizedBox(
                                width: 160.0,
                                child: Row(
                                  children: [
                                    Expanded(
                                        child: Text('${jobTitleList['title']}',
                                            overflow: TextOverflow.ellipsis)),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                          decoration: InputDecoration(
                              prefixIcon: IconButton(
                                  onPressed: () async {
                                    setState(() {
                                      showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            content: AddPlot(),
                                          ))
                                          .then((value) => setState(() {}));
                                    });
                                  },
                                  icon: const Icon(Icons.add_box_rounded,
                                      size: 20.0,
                                      color: ColorApp.myColorGreenAuth)),
                              border: const OutlineInputBorder()),
                        ),
                      ),
                    ),
                  ],
                ),
                const Gap(30.0),

                /// Адрес Тип Модель
                Row(
                  children: [
                    /// Адрес
                    // Expanded(
                    //   child: InkWell(
                    //     onTap: (){
                    //       addObjectScrollController.animateTo(
                    //         addObjectScrollController.offset + 400,
                    //         duration: const Duration(milliseconds: 100),
                    //         curve: Curves.bounceOut,
                    //       );
                    //     },
                    //     child: TextFormField(
                    //       readOnly: true,
                    //       cursorColor: ColorApp.myColorGray,
                    //       controller: legalAddress,
                    //       decoration: const InputDecoration(
                    //           labelText: 'Адрес',
                    //           border: OutlineInputBorder(),
                    //           focusedBorder: OutlineInputBorder(
                    //             borderSide:
                    //             BorderSide(color: ColorApp.myColorGreenAuth),
                    //           ),
                    //           // labelText: 'Документ',
                    //           labelStyle: TextStyle(color: ColorApp.myColorGray)),
                    //     ),
                    //   ),
                    // ),
                    // const Gap(20.0),

                    /// Тип
                    Expanded(
                      child: SizedBox(
                        height: 50.0,
                        child: DropdownButtonFormField(
                          value: typeObjectTitle,
                          hint: const Text('Тип'),
                          onChanged: (newValue1) async {
                            typeObjectTitle = newValue1 as String?;
                            typeObjectTitle!.indexOf(newValue1!);
                            print(typeObjectTitle);
                            // print(typeSelectModel);
                            await getModelObjectListId(typeObjectTitle);
                            if (modelTitleId != null) {
                              modelTitleId = null;
                              print(typeSelectModel);
                            };
                            myStream.add(IntTest.indexScreens);
                          },
                          items: typeObjectList.map((jobTitleList) {
                            return DropdownMenuItem(
                              value: jobTitleList['id'].toString(),
                              child: SizedBox(
                                width: 150.0,
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text('${jobTitleList['name']}',
                                          overflow: TextOverflow.ellipsis),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                          decoration: const InputDecoration(
                            // prefixIcon: IconButton(
                            //     onPressed: () async {
                            //       setState(() {
                            //         showDialog(
                            //             context: context,
                            //             builder: (context) =>
                            //             const AlertDialog(
                            //               content: AddEmployee(),
                            //             )).then((value) => setState((){}));
                            //       });
                            //     },
                            //     icon: const Icon(
                            //         Icons.add_box_rounded,
                            //         size: 20.0,
                            //         color: ColorApp
                            //             .myColorGreenAuth)),
                              border: OutlineInputBorder()),
                        ),
                      ),
                    ),
                    const Gap(20.0),

                    /// Модель
                    Expanded(
                      child: SizedBox(
                        height: 50.0,
                        child: DropdownButtonFormField(
                          value: modelTitleId,
                          hint: const Text('Модель'),
                          onChanged: (newValue1) async {
                            setState(() {
                              modelTitleId = newValue1 as String?;
                              modelTitleId!.indexOf(newValue1!);
                            });
                          },
                          items: modelListId.map((jobTitleList) {
                            return DropdownMenuItem(
                              value: jobTitleList['id'].toString(),
                              child: SizedBox(
                                width: 150.0,
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text('${jobTitleList['model']}',
                                          overflow: TextOverflow.ellipsis),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                          decoration: InputDecoration(
                              prefixIcon: IconButton(
                                  onPressed: () async {
                                    setState(() {
                                      showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            content: AddModel(),
                                          ))
                                          .then((value) => setState(() {}));
                                    });
                                  },
                                  icon: const Icon(Icons.add_box_rounded,
                                      size: 20.0,
                                      color: ColorApp.myColorGreenAuth)),
                              border: const OutlineInputBorder()),
                        ),
                      ),
                    ),
                  ],
                ),

                /// Divider
                myDivider,

                /// Компания, Контактное лицо, Договор
                Row(
                  children: [
                    /// Компания
                    // Expanded(
                    //   child: SizedBox(
                    //     height: 50.0,
                    //     child: DropdownButtonFormField(
                    //       value: getCompanyTitle,
                    //       hint: const Text('Компания'),
                    //       onChanged: (newValue1) async {
                    //         setState(() {
                    //           getCompanyTitle = newValue1 as String?;
                    //           getCompanyTitle!.indexOf(newValue1!);
                    //         });
                    //       },
                    //       items: getCompanyList.map((jobTitleList) {
                    //         return DropdownMenuItem(
                    //           value: jobTitleList['id'].toString(),
                    //           child: SizedBox(
                    //             width: 130.0,
                    //             child: Row(
                    //               children: [
                    //                 Expanded(
                    //                   child: Text(jobTitleList['name'],
                    //                       overflow: TextOverflow.ellipsis),
                    //                 ),
                    //               ],
                    //             ),
                    //           ),
                    //         );
                    //       }).toList(),
                    //       decoration: InputDecoration(
                    //           prefixIcon: IconButton(
                    //               onPressed: () async {
                    //                 setState(() {
                    //                   showDialog(
                    //                       context: context,
                    //                       builder: (context) => AlertDialog(
                    //                         content: AddCompany(),
                    //                       ))
                    //                       .then((value) => setState(() {}));
                    //                 });
                    //               },
                    //               icon: const Icon(Icons.add_box_rounded,
                    //                   size: 20.0,
                    //                   color: ColorApp.myColorGreenAuth)),
                    //           border: const OutlineInputBorder()),
                    //     ),
                    //   ),
                    // ),
                    // const SizedBox(width: 20.0),

                    /// Контактное лицо
                    Expanded(
                      child: SizedBox(
                        height: 50.0,
                        child: DropdownButtonFormField(
                          value: contactPersonSelectedCompanyTitle,
                          hint: const Text('Контактное лицо'),
                          onChanged: (newValue1) async {
                            setState(() {
                              contactPersonSelectedCompanyTitle = newValue1 as String?;
                              contactPersonSelectedCompanyTitle!.indexOf(newValue1!);
                            });
                          },
                          items: contactPersonSelectedCompanyList.map((jobTitleList) {
                            return DropdownMenuItem(
                              value: jobTitleList['id'].toString(),
                              child: SizedBox(
                                width: 130.0,
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(jobTitleList['name'] ?? ''),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                          decoration: InputDecoration(
                              prefixIcon: IconButton(
                                  onPressed: () async {
                                    setState(() {
                                      showDialog(
                                          context: context,
                                          builder: (context) =>  AlertDialog(
                                            content: AddContactPerson())).then((value) => setState(() {}));
                                    });
                                  },
                                  icon: const Icon(Icons.add_box_rounded,
                                      size: 20.0,
                                      color: ColorApp.myColorGreenAuth)),
                              border: const OutlineInputBorder()),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20.0),

                    /// Договор
                    StreamBuilder(
                      stream: myStream.stream,
                      builder: (BuildContext context,
                          AsyncSnapshot<dynamic> snapshot) {
                        return Expanded(
                          child: SizedBox(
                            height: 50.0,
                            child: DropdownButtonFormField(
                              value: getTreatyTitle,
                              hint: const Text('Договор'),
                              onChanged: (newValue1) async {
                                setState(() {
                                  getTreatyTitle = newValue1 as String?;
                                  getTreatyTitle!.indexOf(newValue1!);
                                });
                              },
                              items: getTreatyList.map((jobTitleList) {
                                return DropdownMenuItem(
                                  value: jobTitleList['id'].toString(),
                                  child: SizedBox(
                                    width: 130.0,
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(jobTitleList['title'],
                                              overflow: TextOverflow.ellipsis),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                              decoration: InputDecoration(
                                  prefixIcon: IconButton(
                                      onPressed: () async {
                                        await getCompanyObjectList();
                                        setState(() {
                                          showDialog(
                                              context: context,
                                              builder: (context) => const AlertDialog(
                                                content: AddContract(),
                                              )).then(
                                                  (value) => setState(() {}));
                                        });
                                      },
                                      icon: const Icon(Icons.add_box_rounded,
                                          size: 20.0,
                                          color: ColorApp.myColorGreenAuth)),
                                  border: const OutlineInputBorder()),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),

                /// Divider
                myDivider,

                /// Механик, Прораб
                Row(
                  children: [
                    /// Механик
                    Expanded(
                      child: SizedBox(
                        height: 50.0,
                        child: DropdownButtonFormField(
                          value: mechanicTitle,
                          hint: const Text('Механик'),
                          onChanged: (newValue1) async {
                            setState(() {
                              mechanicTitle = newValue1 as String?;
                              mechanicTitle!.indexOf(newValue1!);
                            });
                          },
                          validator: (newValue1) {
                            if (newValue1 == null) {
                              return 'Заполните поля';
                            }
                          },
                          items: mechanicList.map((jobTitleList) {
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
                          decoration: InputDecoration(
                              prefixIcon: IconButton(
                                  onPressed: () async {
                                    setState(() {
                                      showDialog(
                                          context: context,
                                          builder: (context) =>
                                          const AlertDialog(
                                            content: AddEmployee(),
                                          ))
                                          .then((value) => setState(() {}));
                                    });
                                  },
                                  icon: const Icon(Icons.add_box_rounded,
                                      size: 20.0,
                                      color: ColorApp.myColorGreenAuth)),
                              border: const OutlineInputBorder()),
                        ),
                      ),
                    ),
                    const SizedBox(width: 20.0),

                    /// Прораб
                    Expanded(
                      child: SizedBox(
                        height: 50.0,
                        child: DropdownButtonFormField(
                          value: foremanTitle,
                          hint: const Text('Прораб'),
                          onChanged: (newValue1) async {
                            setState(() {
                              foremanTitle = newValue1 as String?;
                              foremanTitle!.indexOf(newValue1!);
                            });
                          },
                          items: foremanList.map((jobTitleList) {
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
                          decoration: InputDecoration(
                              prefixIcon: IconButton(
                                  onPressed: () async {
                                    setState(() {
                                      showDialog(
                                          context: context,
                                          builder: (context) =>
                                          const AlertDialog(
                                            content: AddEmployee(),
                                          ))
                                          .then((value) => setState(() {}));
                                    });
                                  },
                                  icon: const Icon(Icons.add_box_rounded,
                                      size: 20.0,
                                      color: ColorApp.myColorGreenAuth)),
                              border: const OutlineInputBorder()),
                        ),
                      ),
                    ),
                  ],
                ),

                /// Divider
                myDivider,

                /// Регистрационный номер, Заводской номер, Количество остановок, Высота подъема, Грузоподъемность
                Column(
                  children: [
                    /// Регистрационный номер, Заводской номер
                    Row(
                      children: [
                        /// Регистрационный номер
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Регистрационный номер',
                                style: TextStyle(
                                    fontSize: 15.0,
                                    fontWeight: FontWeight.bold,
                                    color: ColorApp.myColorGrayText),
                              ),
                              const SizedBox(height: 10.0),
                              Form(
                                autovalidateMode: AutovalidateMode.onUserInteraction,
                                key: regNum,
                                child: TextFormField(
                                  validator: (value) {
                                    if (value!.isEmpty) {
                                      return 'Некорректный Регистрационный номер';
                                    } else {
                                      return null;
                                    }
                                  },
                                  cursorColor: ColorApp.myColorGray,
                                  controller: registrationNumber,
                                  decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                            color: ColorApp.myColorGreenAuth),
                                      ),
                                      // labelText: 'Документ',
                                      labelStyle:
                                      TextStyle(color: ColorApp.myColorGray)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 20.0),

                        /// Заводской номер
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Заводской номер',
                                style: TextStyle(
                                    fontSize: 15.0,
                                    fontWeight: FontWeight.bold,
                                    color: ColorApp.myColorGrayText),
                              ),
                              const SizedBox(height: 10.0),
                              Form(
                                autovalidateMode: AutovalidateMode.onUserInteraction,
                                key: zavNum,
                                child: TextFormField(
                                  validator: (value) {
                                    if (value!.isEmpty) {
                                      return 'Некорректный Заводской номер';
                                    } else {
                                      return null;
                                    }
                                  },
                                  cursorColor: ColorApp.myColorGray,
                                  controller: factoryNumber,
                                  decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                            color: ColorApp.myColorGreenAuth),
                                      ),
                                      // labelText: 'Документ',
                                      labelStyle:
                                      TextStyle(color: ColorApp.myColorGray)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30.0),

                    /// Стоимость ТО с НДС и без НДС
                    Row(
                      children: [
                        /// Стоимость ТО с НДС
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Стоимость ТО с НДС',
                                style: TextStyle(
                                    fontSize: 15.0,
                                    fontWeight: FontWeight.bold,
                                    color: ColorApp.myColorGrayText),
                              ),
                              const SizedBox(height: 10.0),
                              Form(
                                autovalidateMode: AutovalidateMode.onUserInteraction,
                                key: priceNds,
                                child: TextFormField(
                                  validator: (value) {
                                    if (value!.isEmpty ||
                                        !RegExp(r'^[+]*[(]{0,1}[0-9]{1,4}[)]{0,1}[-\s\./0-9]+$')
                                            .hasMatch(value)) {
                                      return 'Некорректный ввод';
                                    } else {
                                      return null;
                                    }
                                  },
                                  cursorColor: ColorApp.myColorGray,
                                  controller: priceNDS,
                                  decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                            color: ColorApp.myColorGreenAuth),
                                      ),
                                      // labelText: 'Документ',
                                      labelStyle:
                                      TextStyle(color: ColorApp.myColorGray)),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 20.0),

                        /// Стоимость ТО без НДС
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Стоимость ТО без НДС',
                                style: TextStyle(
                                    fontSize: 15.0,
                                    fontWeight: FontWeight.bold,
                                    color: ColorApp.myColorGrayText),
                              ),
                              const SizedBox(height: 10.0),
                              Form(
                                autovalidateMode: AutovalidateMode.onUserInteraction,
                                key: priceNoNds,
                                child: TextFormField(
                                  validator: (value) {
                                    if (value!.isEmpty ||
                                        !RegExp(r'^[+]*[(]{0,1}[0-9]{1,4}[)]{0,1}[-\s\./0-9]+$')
                                            .hasMatch(value)) {
                                      return 'Некорректный ввод';
                                    } else {
                                      return null;
                                    }
                                  },
                                  cursorColor: ColorApp.myColorGray,
                                  controller: priceNoNDS,
                                  decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                      focusedBorder: OutlineInputBorder(
                                        borderSide: BorderSide(
                                            color: ColorApp.myColorGreenAuth),
                                      ),
                                      // labelText: 'Документ',
                                      labelStyle:
                                      TextStyle(color: ColorApp.myColorGray)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30.0),
                    Column(
                      children: [
                        /// Высота подъема, Грузоподъемность Ширина, Количество остановок
                        Row(
                          children: [
                            /// Высота подъема
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Высота подъема',
                                    style: TextStyle(
                                        fontSize: 15.0,
                                        fontWeight: FontWeight.bold,
                                        color: ColorApp.myColorGrayText),
                                  ),
                                  const SizedBox(height: 10.0),
                                  Form(
                                    autovalidateMode: AutovalidateMode.onUserInteraction,
                                    key: numLiftingHeight,
                                    child: TextFormField(
                                      validator: (value) {
                                        if (value!.isEmpty ||
                                            !RegExp(r'^[+]*[(]{0,1}[0-9]{1,4}[)]{0,1}[-\s\./0-9]+$')
                                                .hasMatch(value)) {
                                          return 'Некорректный ввод';
                                        } else {
                                          return null;
                                        }
                                      },
                                      cursorColor: ColorApp.myColorGray,
                                      controller: liftingHeight,
                                      decoration: const InputDecoration(
                                          border: OutlineInputBorder(),
                                          focusedBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                                color:
                                                ColorApp.myColorGreenAuth),
                                          ),
                                          // labelText: 'Документ',
                                          labelStyle: TextStyle(
                                              color: ColorApp.myColorGray)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 20.0),

                            /// Грузоподъемность
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Грузоподъемность',
                                    style: TextStyle(
                                        fontSize: 15.0,
                                        fontWeight: FontWeight.bold,
                                        color: ColorApp.myColorGrayText),
                                  ),
                                  const SizedBox(height: 10.0),
                                  Form(
                                    autovalidateMode: AutovalidateMode.onUserInteraction,
                                    key: numLoadCapacity,
                                    child: TextFormField(
                                      validator: (value) {
                                        if (value!.isEmpty ||
                                            !RegExp(r'^[+]*[(]{0,1}[0-9]{1,4}[)]{0,1}[-\s\./0-9]+$')
                                                .hasMatch(value)) {
                                          return 'Некорректный ввод';
                                        } else {
                                          return null;
                                        }
                                      },
                                      cursorColor: ColorApp.myColorGray,
                                      controller: loadCapacity,
                                      decoration: const InputDecoration(
                                          border: OutlineInputBorder(),
                                          focusedBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                                color:
                                                ColorApp.myColorGreenAuth),
                                          ),
                                          // labelText: 'Документ',
                                          labelStyle: TextStyle(
                                              color: ColorApp.myColorGray)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 20.0),

                            /// Количество остановок
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Количество остановок',
                                    style: TextStyle(
                                        fontSize: 15.0,
                                        fontWeight: FontWeight.bold,
                                        color: ColorApp.myColorGrayText),
                                  ),
                                  const SizedBox(height: 10.0),
                                  Form(
                                    autovalidateMode: AutovalidateMode.onUserInteraction,
                                    key: numSfStops,
                                    child: TextFormField(
                                      validator: (value) {
                                        if (value!.isEmpty ||
                                            !RegExp(r'^[+]*[(]{0,1}[0-9]{1,4}[)]{0,1}[-\s\./0-9]+$')
                                                .hasMatch(value)) {
                                          return 'Некорректный ввод';
                                        } else {
                                          return null;
                                        }
                                      },
                                      cursorColor: ColorApp.myColorGray,
                                      controller: numberOfStops,
                                      decoration: const InputDecoration(
                                          border: OutlineInputBorder(),
                                          focusedBorder: OutlineInputBorder(
                                            borderSide: BorderSide(
                                                color:
                                                ColorApp.myColorGreenAuth),
                                          ),
                                          // labelText: 'Документ',
                                          labelStyle: TextStyle(
                                              color: ColorApp.myColorGray)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),

                /// Divider
                myDivider,

                /// Дата полного ТО, Дата планового ТО, Период ТО
                Row(
                  children: [
                    /// Дата полного ТО
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Дата полного ТО',
                            style: TextStyle(
                                fontSize: 15.0,
                                fontWeight: FontWeight.bold,
                                color: ColorApp.myColorGrayText),
                          ),
                          const SizedBox(height: 10.0),
                          InkWell(
                              onTap: () async {
                                final DateTime? dateTime = await showDatePicker(
                                    context: context,
                                    initialDate: dateFullTO,
                                    firstDate: DateTime(2000),
                                    lastDate: DateTime(3000));
                                if (dateTime != null) {
                                  dateFullTO = dateTime;
                                  setState(() {});
                                }
                              },
                              child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10.0),
                                  height: 50,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(5.0),
                                    border: Border.all(
                                        width: 1.0, color: Colors.grey),
                                  ),
                                  child: Row(
                                      mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '${dateFullTO.day} - ${dateFullTO.month} - ${dateFullTO.year}',
                                          style: const TextStyle(
                                              color: Colors.grey,
                                              fontSize: 16.0),
                                        ),
                                        const Icon(
                                            Icons.calendar_month_outlined,
                                            color: Colors.grey)
                                      ]))),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20.0),

                    /// Дата планового ТО
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Дата планового ТО',
                            style: TextStyle(
                                fontSize: 15.0,
                                fontWeight: FontWeight.bold,
                                color: ColorApp.myColorGrayText),
                          ),
                          const SizedBox(height: 10.0),
                          InkWell(
                              onTap: () async {
                                final DateTime? dateTime = await showDatePicker(
                                    context: context,
                                    initialDate: datePlannedTO,
                                    firstDate: DateTime(2000),
                                    lastDate: DateTime(3000));
                                if (dateTime != null) {
                                  datePlannedTO = dateTime;
                                  setState(() {});
                                }
                              },
                              child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10.0),
                                  height: 50,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(5.0),
                                    border: Border.all(
                                        width: 1.0, color: Colors.grey),
                                  ),
                                  child: Row(
                                      mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '${datePlannedTO.day} - ${datePlannedTO.month} - ${datePlannedTO.year}',
                                          style: const TextStyle(
                                              color: Colors.grey,
                                              fontSize: 16.0),
                                        ),
                                        const Icon(
                                            Icons.calendar_month_outlined,
                                            color: Colors.grey)
                                      ]))),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20.0),

                    /// Период ТО
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Период ТО',
                            style: TextStyle(
                                fontSize: 15.0,
                                fontWeight: FontWeight.bold,
                                color: ColorApp.myColorGrayText),
                          ),
                          const SizedBox(height: 10.0),
                          InkWell(
                              onTap: () async {
                                final DateTime? dateTime = await showDatePicker(
                                    context: context,
                                    initialDate: periodTO,
                                    firstDate: DateTime(2000),
                                    lastDate: DateTime(3000));
                                if (dateTime != null) {
                                  periodTO = dateTime;
                                  setState(() {});
                                }
                              },
                              child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10.0),
                                  height: 50,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(5.0),
                                    border: Border.all(
                                        width: 1.0, color: Colors.grey),
                                  ),
                                  child: Row(
                                      mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '${periodTO.day} - ${periodTO.month} - ${periodTO.year}',
                                          style: const TextStyle(
                                              color: Colors.grey,
                                              fontSize: 16.0),
                                        ),
                                        const Icon(
                                            Icons.calendar_month_outlined,
                                            color: Colors.grey)
                                      ]))),
                        ],
                      ),
                    ),
                  ],
                ),

                /// Divider
                myDivider,

                /// Письмо о назначении, Сертификат, Акт
                // Row(
                //   children: [
                //     /// Письмо о назначении
                //     Expanded(
                //       child: Column(
                //         crossAxisAlignment: CrossAxisAlignment.start,
                //         children: [
                //           const Text(
                //             'Письмо о назначении',
                //             style: TextStyle(
                //                 fontSize: 15.0,
                //                 fontWeight: FontWeight.bold,
                //                 color: ColorApp.myColorGrayText),
                //           ),
                //           const SizedBox(height: 10.0),
                //           InkWell(
                //             onTap: () {
                //               setState(() {
                //                 showDialog(
                //                     context: context,
                //                     builder: (context) => const AlertDialog(
                //                       content: LetterOfAppointment(),
                //                     )).then((value) => setState(() {}));
                //               });
                //             },
                //             child: Container(
                //               height: 50.0,
                //               decoration: BoxDecoration(
                //                 borderRadius: BorderRadius.circular(5.0),
                //                 border:
                //                 Border.all(width: 1.1, color: Colors.grey),
                //               ),
                //               child: Row(
                //                 children: [
                //                   const Spacer(),
                //                   IconButton(
                //                       onPressed: () {
                //                         setState(() {});
                //                       },
                //                       icon: const Icon(
                //                           Icons.cloud_download_outlined,
                //                           color: Colors.grey)),
                //                   const SizedBox(width: 10.0),
                //                 ],
                //               ),
                //             ),
                //           ),
                //         ],
                //       ),
                //     ),
                //     const Gap(20.0),
                //
                //     /// Сертификат
                //     // Expanded(
                //     //   child: Column(
                //     //     crossAxisAlignment: CrossAxisAlignment.start,
                //     //     children: [
                //     //       const Text(
                //     //         'Сертификат',
                //     //         style: TextStyle(
                //     //             fontSize: 15.0,
                //     //             fontWeight: FontWeight.bold,
                //     //             color: ColorApp.myColorGrayText),
                //     //       ),
                //     //       const SizedBox(height: 10.0),
                //     //       TextFormField(
                //     //         cursorColor: ColorApp.myColorGray,
                //     //         // controller: site,
                //     //         decoration: InputDecoration(
                //     //             suffixIcon: IconButton(
                //     //                 onPressed: () {
                //     //                   setState(() {});
                //     //                 },
                //     //                 icon:
                //     //                 const Icon(Icons.cloud_download_outlined)),
                //     //             border: const OutlineInputBorder(),
                //     //             focusedBorder: const OutlineInputBorder(
                //     //               borderSide:
                //     //               BorderSide(color: ColorApp.myColorGreenAuth),
                //     //             ),
                //     //             // labelText: 'Документ',
                //     //             labelStyle:
                //     //             const TextStyle(color: ColorApp.myColorGray)),
                //     //       ),
                //     //     ],
                //     //   ),
                //     // ),
                //     // const SizedBox(width: 20.0),
                //
                //     /// Акт
                //     Expanded(
                //       child: Column(
                //         crossAxisAlignment: CrossAxisAlignment.start,
                //         children: [
                //           const Text(
                //             'Акт',
                //             style: TextStyle(
                //                 fontSize: 15.0,
                //                 fontWeight: FontWeight.bold,
                //                 color: ColorApp.myColorGrayText),
                //           ),
                //           const SizedBox(height: 10.0),
                //           InkWell(
                //             onTap: () async {
                //               setState(() {
                //                 showDialog(
                //                     context: context,
                //                     builder: (context) => const AlertDialog(
                //                       content: AcceptanceCertificate(),
                //                     )).then((value) => setState(() {}));
                //               });
                //             },
                //             child: Container(
                //               height: 50.0,
                //               decoration: BoxDecoration(
                //                 borderRadius: BorderRadius.circular(5.0),
                //                 border:
                //                 Border.all(width: 1.1, color: Colors.grey),
                //               ),
                //               child: Row(
                //                 children: [
                //                   const Spacer(),
                //                   IconButton(
                //                       onPressed: () {
                //                         setState(() {});
                //                       },
                //                       icon: const Icon(
                //                           Icons.cloud_download_outlined,
                //                           color: Colors.grey)),
                //                   const SizedBox(width: 10.0),
                //                 ],
                //               ),
                //             ),
                //           ),
                //         ],
                //       ),
                //     ),
                //   ],
                // ),
                // const Gap(30.0),

                /// Местоположение и Карта
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Местоположение',
                        style: TextStyle(
                            fontSize: 15.0,
                            fontWeight: FontWeight.bold,
                            color: ColorApp.myColorGrayText)),
                    const SizedBox(height: 10.0),
                    SizedBox(
                        width: MediaQuery.of(context).size.width,
                        height: 350.0,
                        child: OpenStreetMapSearchAndPick(
                            locationPinText: myAddress ?? '',
                            center: const LatLong(45.034604, 39.035051),
                            zoomInIcon: Icons.add,
                            zoomOutIcon: Icons.remove,
                            buttonColor: Colors.green.shade300,
                            buttonText: '+ добавить адресс',
                            onPicked: (pickedData) {
                              setState(() {
                                myAddress =
                                '${pickedData.address['road']} ${pickedData.address['house_number']}';
                                legalAddress.text = myAddress;
                                myLat = pickedData.latLong.latitude;
                                myLong = pickedData.latLong.longitude;
                              });
                              print(
                                  '${pickedData.address['road']} ${pickedData.address['house_number']}');
                              print(myLat);
                              print(myLong);
                              print(myAddress);
                              print(pickedData.address);
                              // print(pickedData.);
                            })),
                  ],
                ),
                const Gap(30.0),

                /// Кнопка сохранить
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    mechanicTitle != null
                        && foremanTitle != null
                        && organizationTitle != null
                        && myPlotTitle != null
                        && typeObjectTitle != null
                        && modelTitleId != null
                        ? ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColorApp.myColorGreenAuth,
                          padding: const EdgeInsets.symmetric(vertical: 20.0),
                        ),
                        onPressed: () async {
                          regNameObject.currentState!.validate();
                          regNum.currentState!.validate();
                          zavNum.currentState!.validate();
                          priceNds.currentState!.validate();
                          priceNoNds.currentState!.validate();
                          numLoadCapacity.currentState!.validate();
                          numLiftingHeight.currentState!.validate();
                          numSfStops.currentState!.validate();
                          if(nameObject.text.isNotEmpty && legalAddress.text.isNotEmpty){
                            await createObjectCompanies();
                            myStream.add(IntTest.indexScreens);
                            Navigator.pop(context);
                            setState(() {});
                          }
                        }, child: const Text('Сохранить',style: TextStyle(fontSize: 18.0,fontWeight: FontWeight.bold)))
                        : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColorApp.myColorGray,
                          padding: const EdgeInsets.symmetric(vertical: 20.0),
                        ),
                        onPressed: null, child: const Text('Заполните все поля',style: TextStyle(fontSize: 18.0,fontWeight: FontWeight.bold))),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}