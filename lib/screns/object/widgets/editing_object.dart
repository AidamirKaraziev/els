import 'dart:convert';
import 'package:els/helper/button/my_button.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../../helper/class_colors.dart';
import '../../../widgets_create/organization_greate.dart';
import '../../companies/widgets/add_companies.dart';
import '../../employee/widgets/add_employee.dart';
import '../../home_page/home_page.dart';
import '../view/object_screen.dart';
import 'package:http/http.dart' as http;
import 'add_contact_person_object.dart';
import 'add_model.dart';
import 'add_object.dart';
import 'add_plot.dart';

///Редактирование объекта

Map editingObjectMap = {};

class EditingObject extends StatefulWidget {
  EditingObject({
    Key? key,
  }) : super(key: key);

  @override
  State<EditingObject> createState() => _EditingObjectState();
}

class _EditingObjectState extends State<EditingObject> {

  /// Функция Редактирование объекта ==
  editingObject(int userId) async {
    var response = await http.put(
      Uri.parse("http://${IntTest.myIp}/api/v1/object/$userId/"),
      headers: {
        "Content-Type": "application/json; charset=utf-8",
        'Authorization': 'Bearer ${IntTest.token}',
      },
      body: json.encode(
        {
          "name": newObjectName.text,
          // "organization_id": organizationTitle,
          // "division_id": myPlotTitle,
          // if(newAddressObject.text != null && newAddressObject.text.isNotEmpty)
          // "address": newAddressObject.text,
          // "factory_model_id": modelTitleId,

          if(newRegistrationNumber.text != null && newRegistrationNumber.text.isNotEmpty)
          "registration_number": newRegistrationNumber.text,

          /// Колл остановок
          "number_of_stops": int.parse(newNumberOfStops.text),

          // if(newLiftHeight.text != null && newLiftHeight.text.isNotEmpty)
          // "lifting_heights": int.parse(newLiftHeight.text),

          // if(newLoadCapacity.text != null && newLoadCapacity.text.isNotEmpty)
          // "load_capacity": int.parse(newLoadCapacity.text),

          // if(newWidth.text != null && newWidth.text.isNotEmpty)
          // "width": int.parse(newWidth.text),

          // if(newPriceNDS.text != null && newPriceNDS.text.isNotEmpty)
          // "cost_nds": int.parse(newPriceNDS.text),

          // if(newPriceNoNDS.text != null && newPriceNoNDS.text.isNotEmpty)
          // "cost_no_nds": int.parse(newPriceNoNDS.text),
          // "company_id": getCompanyTitle,
          // "contact_person_id": contactPersonTitle,
          // "contract_id": getTreatyTitle,
          // "date_inspection": newDateFullTO.millisecondsSinceEpoch/1000,
          // "planned_inspection": newDatePlannedTO.millisecondsSinceEpoch/1000,
          // "period_inspection": newPeriodTO.millisecondsSinceEpoch/1000,
          // "foreman_id": foremanTitle,
          // "mechanic_id": mechanicTitle,
          // "geo": "45.034604, 39.035051"
        },
      ),
    );
    var vova = jsonDecode(utf8.decode(response.bodyBytes));
    editingObjectMap = vova;
    print('Измененный обьект : ${editingObjectMap['data']['company_id']['name']}');
  }
  /// =================================

  /// Новое имя Обьекта
  TextEditingController newObjectName = TextEditingController(text: '${listSelectedObject['data']['name']}');

  /// Новый адресс
  TextEditingController newAddressObject = TextEditingController(text: listSelectedObject['data']['address']);

  /// Новый Регистрационный номер
  TextEditingController newRegistrationNumber = TextEditingController(text: listSelectedObject['data']['registration_number'].toString());

  /// Новый Заводской номер
  TextEditingController newFactoryNumber = TextEditingController(text: listSelectedObject['data']['factory_number'].toString());

  /// Новая Высота подъема
  TextEditingController newLiftHeight = TextEditingController(text: listSelectedObject['data']['lifting_heights'].toString());

  /// Новое Количество остановок
  TextEditingController newNumberOfStops = TextEditingController(text: listSelectedObject['data']['number_of_stops'].toString());

  /// Новая Грузоподъемность
  TextEditingController newLoadCapacity = TextEditingController(text: listSelectedObject['data']['load_capacity'].toString());

  /// Новая Ширина
  TextEditingController newWidth = TextEditingController(text: listSelectedObject['data']['load_capacity'].toString());

  /// Новая цена с НДС
  TextEditingController newPriceNDS = TextEditingController(text: listSelectedObject['data']['load_capacity'].toString());

  /// Новая цена без НДС
  TextEditingController newPriceNoNDS = TextEditingController(text: listSelectedObject['data']['load_capacity'].toString());

  DateTime newDateFullTO = DateTime.now();
  DateTime newDatePlannedTO = DateTime.now();
  DateTime newPeriodTO = DateTime.now();

  @override
  void initState() {
    /// ==========================================================================================
    getOrganizationObjectList();
    getPlot();
    getCompanyObjectList();
    getTreatyObjectList();
    getForemanObjectList();
    getMechanicObjectList();
    getContactPersonObjectList();
    getTypeObjectList();
    // getModelObjectListId(typeObjectTitle);

    /// ==========================================================================================
    organizationTitle = '${listSelectedObject['data']['organization_id']}';
    myPlotTitle = '${listSelectedObject['data']['division_id']['id']}';
    typeObjectTitle = '${listSelectedObject['data']['factory_model_id']['type_object_id']['id']}';
    modelTitleId = '${listSelectedObject['data']['factory_model_id']['id']}';
    getCompanyTitle = '${listSelectedObject['data']['company_id']['id']}';
    contactPersonTitle = '${listSelectedObject['data']['contact_person_id']['id']}';
    getTreatyTitle = '${listSelectedObject['data']['contract_id']['id']}' ?? '';
    foremanTitle = '${listSelectedObject['data']['foreman_id']['id']}';
    mechanicTitle = '${listSelectedObject['data']['mechanic_id']['id']}';
    /// ==========================================================================================


    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: myStream.stream,
      builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
        return SizedBox(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ///Тест и кнопкка закрыть
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Редактирование объекта',
                          style:
                          TextStyle(fontSize: 25.0, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 5.0),
                        Text(
                          'Заполните все поля, чтобы изменить объект',
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
                        ))
                  ],
                ),
                const SizedBox(height: 30.0),
                /// Название Обьекта Адрес
                Row(
                  children: [
                    /// Название Обьекта
                    Expanded(
                      child: SizedBox(
                        height: 50.0,
                        child: Form(
                          // key: regNameObject,
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
                            controller: newObjectName,
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
                    ),
                    const Gap(10.0),
                    /// Адрес
                    Expanded(
                      child: TextFormField(
                        readOnly: true,
                        cursorColor: ColorApp.myColorGray,
                        controller: newAddressObject,
                        decoration: const InputDecoration(
                            labelText: 'Адрес',
                            border: OutlineInputBorder(),
                            focusedBorder: OutlineInputBorder(
                              borderSide:
                              BorderSide(color: ColorApp.myColorGreenAuth),
                            ),
                            // labelText: 'Документ',
                            labelStyle: TextStyle(color: ColorApp.myColorGray)),
                      ),
                    ),
                  ],
                ),
                const Gap(20.0),
                /// Организация, Участок,
                Row(
                  children: [
                    /// Организация
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Организация',style: TextStyle(
                              fontSize: 15.0,
                              fontWeight: FontWeight.bold,
                              color: ColorApp.myColorGrayText)),
                          const SizedBox(height: 5.0),
                          SizedBox(
                            height: 50.0,
                            child: DropdownButtonFormField(
                              value: organizationTitle,
                              hint: const Text('Организация'),
                              onChanged: (newValue1) async {
                                setState(() {
                                  organizationTitle = newValue1 as String?;
                                  organizationTitle!.indexOf(newValue1!);
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
                        ],
                      ),
                    ),
                    const Gap(10.0),
                    /// Участок
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Участок',style: TextStyle(
                              fontSize: 15.0,
                              fontWeight: FontWeight.bold,
                              color: ColorApp.myColorGrayText)),
                          const SizedBox(height: 5.0),
                          SizedBox(
                            height: 50.0,
                            child: DropdownButtonFormField(
                              value: myPlotTitle,
                              hint: const Text('Участок'),
                              onChanged: (newValue1) async {
                                setState(() {
                                  myPlotTitle = newValue1 as String?;
                                  myPlotTitle!.indexOf(newValue1!);
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
                        ],
                      ),
                    ),
                  ],
                ),
                const Gap(20.0),
                /// Тип Модель
                Row(
                  children: [
                    /// Тип
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Тип',style: TextStyle(
                              fontSize: 15.0,
                              fontWeight: FontWeight.bold,
                              color: ColorApp.myColorGrayText)),
                          const SizedBox(height: 5.0),
                          SizedBox(
                            height: 50.0,
                            child: DropdownButtonFormField(
                              value: typeObjectTitle,
                              hint: const Text('Тип'),
                              onChanged: (newValue1) async {
                                typeObjectTitle = newValue1 as String?;
                                typeObjectTitle!.indexOf(newValue1!);
                                await getModelObjectListId(typeObjectTitle);
                                if (modelTitleId != null) {
                                  modelTitleId = null;
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
                        ],
                      ),
                    ),
                    const Gap(10.0),

                    /// Модель
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Модель',style: TextStyle(
                              fontSize: 15.0,
                              fontWeight: FontWeight.bold,
                              color: ColorApp.myColorGrayText)),
                          const SizedBox(height: 5.0),
                          SizedBox(
                            height: 50.0,
                            child: DropdownButtonFormField(
                              value: modelTitleId,
                              hint: const Text('Модель'),
                              onChanged: (newValue1) async {
                                setState(() {
                                  modelTitleId = newValue1 as String?;
                                  modelTitleId!.indexOf(newValue1!);
                                  // print(modelTitleId);
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
                        ],
                      ),
                    ),
                  ],
                ),
                const Gap(20.0),
                /// Компания, Контактное лицо, Договор
                Row(
                  children: [
                    /// Компания
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Компания',style: TextStyle(
                              fontSize: 15.0,
                              fontWeight: FontWeight.bold,
                              color: ColorApp.myColorGrayText)),
                          const SizedBox(height: 5.0),
                          SizedBox(
                            height: 50.0,
                            child: DropdownButtonFormField(
                              value: getCompanyTitle,
                              hint: const Text('Компания'),
                              onChanged: (newValue1) async {
                                setState(() {
                                  getCompanyTitle = newValue1 as String?;
                                  getCompanyTitle!.indexOf(newValue1!);
                                });
                              },
                              items: getCompanyList.map((jobTitleList) {
                                return DropdownMenuItem(
                                  value: jobTitleList['id'].toString(),
                                  child: SizedBox(
                                    width: 130.0,
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
                                              builder: (context) => const AlertDialog(
                                                content: AddCompany(),
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
                        ],
                      ),
                    ),
                    const Gap(10.0),

                    /// Контактное лицо
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Контактное лицо',style: TextStyle(
                              fontSize: 15.0,
                              fontWeight: FontWeight.bold,
                              color: ColorApp.myColorGrayText)),
                          const SizedBox(height: 5.0),
                          SizedBox(
                            height: 50.0,
                            child: DropdownButtonFormField(
                              value: contactPersonTitle,
                              hint: const Text('Контактное лицо'),
                              onChanged: (newValue1) async {
                                setState(() {
                                  contactPersonTitle = newValue1 as String?;
                                  contactPersonTitle!.indexOf(newValue1!);
                                });
                              },
                              items: contactPersonList.map((jobTitleList) {
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
                                              builder: (context) => AlertDialog(
                                                content: AddContactPersonObject(),
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
                        ],
                      ),
                    ),
                    const Gap(10.0),

                    /// Договор
                    StreamBuilder(
                      stream: myStream.stream,
                      builder: (BuildContext context,
                          AsyncSnapshot<dynamic> snapshot) {
                        return Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Договор',style: TextStyle(
                                  fontSize: 15.0,
                                  fontWeight: FontWeight.bold,
                                  color: ColorApp.myColorGrayText)),
                              const SizedBox(height: 5.0),
                              SizedBox(
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
                                                    content: AddCompany(),
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
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const Gap(30.0),
                /// Механик, Прораб
                Row(
                  children: [

                    /// Прораб
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Прораб',style: TextStyle(
                              fontSize: 15.0,
                              fontWeight: FontWeight.bold,
                              color: ColorApp.myColorGrayText)),
                          const SizedBox(height: 5.0),
                          SizedBox(
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
                        ],
                      ),
                    ),

                    const Gap(10.0),

                    /// Механик
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Механик',style: TextStyle(
                              fontSize: 15.0,
                              fontWeight: FontWeight.bold,
                              color: ColorApp.myColorGrayText)),
                          const SizedBox(height: 5.0),
                          SizedBox(
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
                        ],
                      ),
                    ),

                  ],
                ),
                const Gap(20.0),
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
                              TextFormField(
                                cursorColor: ColorApp.myColorGray,
                                controller: newRegistrationNumber,
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
                            ],
                          ),
                        ),
                        const Gap(10.0),

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
                              TextFormField(
                                enabled: false,
                                cursorColor: ColorApp.myColorGray,
                                controller: newFactoryNumber,
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
                              TextFormField(
                                cursorColor: ColorApp.myColorGray,
                                controller: newPriceNDS,
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
                            ],
                          ),
                        ),
                        const Gap(10.0),

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
                              TextFormField(
                                cursorColor: ColorApp.myColorGray,
                                controller: newPriceNoNDS,
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
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30.0),
                    // if (typeObjectTitle == '1' ||
                    //     typeObjectTitle == '2' ||
                    //     typeObjectTitle == '5' ||
                    //     typeObjectTitle == '6')
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
                                  TextFormField(
                                    cursorColor: ColorApp.myColorGray,
                                    controller: newLiftHeight,
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
                                ],
                              ),
                            ),
                            const Gap(10.0),
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
                                  TextFormField(
                                    cursorColor: ColorApp.myColorGray,
                                    controller: newLoadCapacity,
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
                                ],
                              ),
                            ),
                            const Gap(10.0),
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
                                  TextFormField(
                                    cursorColor: ColorApp.myColorGray,
                                    controller: newNumberOfStops,
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
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    // if (typeObjectTitle == '3') const Text('Траволатор'),
                    // if (typeObjectTitle == '4') const Text('Эскалатор'),
                  ],
                ),
                const Gap(20.0),
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
                                    initialDate: newDateFullTO,
                                    firstDate: DateTime(2000),
                                    lastDate: DateTime(3000));
                                if (dateTime != null) {
                                  newDateFullTO = dateTime;
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
                                          '${newDateFullTO.day} - ${newDateFullTO.month} - ${newDateFullTO.year}',
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
                                    initialDate: newDatePlannedTO,
                                    firstDate: DateTime(2000),
                                    lastDate: DateTime(3000));
                                if (dateTime != null) {
                                  newDatePlannedTO = dateTime;
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
                                          '${newDatePlannedTO.day} - ${newDatePlannedTO.month} - ${newDatePlannedTO.year}',
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
                                    initialDate: newPeriodTO,
                                    firstDate: DateTime(2000),
                                    lastDate: DateTime(3000));
                                if (dateTime != null) {
                                  newPeriodTO = dateTime;
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
                                          '${newPeriodTO.day} - ${newPeriodTO.month} - ${newPeriodTO.year}',
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
                const Gap(40.0),
                /// Кнопка Сохранить
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    MainButtonApp(textButton: 'Сохранить', press: () async {
                      await editingObject(IntTest.pressHover);

                      /// Новое название объекта
                      listSelectedObject['data']['name'] = newObjectName.text;
                      // /// Новый адресс
                      // // listSelectedObject['data']['address'] = newAddressObject.text;
                      // // getObject[IntTest.indexObjectList]['address'] = newAddressObject.text;
                      /// Новый Регистрационный номер
                      if(listSelectedObject['data']['registration_number'] != null){
                        getObject[IntTest.indexObjectList]['registration_number'] = newRegistrationNumber.text;
                        listSelectedObject['data']['registration_number'] = newRegistrationNumber.text;
                      }

                      /// Новый Заводской номер
                      // if(listSelectedObject['data']['factory_number'] != null){
                      //   listSelectedObject['data']['factory_number'] = newFactoryNumber.text;
                      //   getObject[IntTest.indexObjectList]['factory_number'] = newFactoryNumber.text;
                      // }

                      /// Новая Высота подъема
                      // listSelectedObject['data']['lifting_heights'] = newLiftHeight.text;

                      /// Новое Количество остановок
                      listSelectedObject['data']['number_of_stops'] = newNumberOfStops.text;

                      // /// Новая Грузоподъемность
                      // listSelectedObject['data']['load_capacity'] = newLoadCapacity.text;

                      // /// Новая цена с ндс
                      // listSelectedObject['data']['cost_nds'] = newPriceNDS.text;

                      // /// Новая цена без ндс
                      // listSelectedObject['data']['cost_no_nds'] = newPriceNoNDS.text;

                      // /// Дата полного ТО
                      // listSelectedObject['data']['date_inspection'] = newDateFullTO.millisecondsSinceEpoch/1000;
                      // /// Дата планового ТО
                      // listSelectedObject['data']['planned_inspection'] = newDatePlannedTO.millisecondsSinceEpoch/1000;
                      // /// Период ТО
                      // listSelectedObject['data']['period_inspection'] = newPeriodTO.millisecondsSinceEpoch/1000;
                      // ///
                      // listSelectedObject['data']['organization_id'] = editingObjectMap['data']['organization_id'];
                      //
                      // listSelectedObject['data']['division_id']['title'] = editingObjectMap['data']['division_id']['title'];
                      //
                      // listSelectedObject['data']['factory_model_id']['type_object_id']['name'] = editingObjectMap['data']['factory_model_id']['type_object_id']['name'] ?? '';
                      //
                      //
                      // listSelectedObject['data']['factory_model_id']['model'] = editingObjectMap['data']['factory_model_id']['model'] ?? '';
                      //
                      // listSelectedObject['data']['company_id']['name'] = editingObjectMap['data']['company_id']['name']?? '';
                      //
                      // /// Контактное лицо
                      // listSelectedObject['data']['contact_person_id']['name']= editingObjectMap['data']['contact_person_id']['name'] ?? '';
                      //
                      // /// Договор
                      // listSelectedObject['data']['contract_id']['title'] = editingObjectMap['data']['contract_id']['title'] ?? '';
                      //
                      // /// Прораб
                      // listSelectedObject['data']['foreman_id']['name']= editingObjectMap['data']['foreman_id']['name'] ?? '';
                      //
                      // /// Механик
                      // listSelectedObject['data']['mechanic_id']['name'] = editingObjectMap['data']['mechanic_id']['name'] ?? '';
                      //
                      //
                      // listSelectedObject['data']['date_inspection'] = newDateFullTO.millisecondsSinceEpoch/1000;
                      // listSelectedObject['data']['planned_inspection'] = newDatePlannedTO.millisecondsSinceEpoch/1000;
                      // listSelectedObject['data']['period_inspection'] = newPeriodTO.millisecondsSinceEpoch/1000;


                      dataObject[IntTest.indexObjectList]['name'] = newObjectName.text;
                      await getListObjectInfo(IntTest.pressHover);
                      myStream.add(IntTest.indexScreens);
                      Navigator.pop(context);
                    },),
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