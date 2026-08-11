import 'dart:convert';

import 'package:els/foreman/companies_foreman/companies_screen_foreman.dart';
import 'package:flutter/material.dart';
import '../../../helper/class_colors.dart';
import '../../../helper/my_map/my_map.dart';
import 'package:http/http.dart' as http;
import '../../../screns/companies/widgets/add_object_companies.dart';
import '../../../screns/home_page/home_page.dart';
import '../../../screns/object/view/object_page.dart';
import '../../../screns/object/view/object_screen.dart';
import '../company_page_foreman.dart';

/// отображения списка обьектов компании  Просмотр объекта

Map listSelectedObjectViewingCompany = {};

/// Класс для отображения списка обьектов компании =============================================
class AddObjectSelectedCompanyForeman extends StatefulWidget {
  const AddObjectSelectedCompanyForeman({Key? key}) : super(key: key);

  @override
  State<AddObjectSelectedCompanyForeman> createState() => _AddObjectSelectedCompanyForemanState();
}
class _AddObjectSelectedCompanyForemanState extends State<AddObjectSelectedCompanyForeman> {

  /// Данные выбраного обьекта ============
  getListObjectInfo(int userId) async {
    await Future(() async {
      final res = await http.get(
          Uri.parse("http://${IntTest.myIp}/api/v1/object/$userId/"),
          headers: {
            "Content-Type": "application/json; charset=utf-8",
            'Authorization': 'Bearer ${IntTest.token}',
          });
      var vova = jsonDecode(utf8.decode(res.bodyBytes));
      listSelectedObjectViewingCompany = vova['data'];
      // print('Данные выбраного обьекта >>> ${listSelectedObjectViewingCompany['data']} <<<');
    });
  }
  /// =====================================

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: myStream.stream,
      builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Текст Объекты Иконка добавить
            Row(
              children: const [
                /// Текст Объекты
                Text(
                  'Объекты',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600),
                ),
                SizedBox(width: 20.0),
                /// Иконка добавить
                // IconButton(
                //     onPressed: listSelectedCompanyForeman['data']['is_actual'] == false ? null : () {
                //       setState(() {
                //         showDialog(
                //             context: context,
                //             builder: (context) => AlertDialog(
                //               content: AddObjectCompanies(),
                //             ));
                //       });
                //     },
                //     icon: const Icon(
                //       Icons.add_box_rounded,
                //       color: ColorApp.myColorGreenAuth,
                //     )),
              ],
            ),
            const SizedBox(height: 20.0),
            Container(
              width: double.infinity,
              height: 300,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(5.0),
                color: listSelectedCompanyForeman['data']['is_actual'] == true ? ColorApp.myColorWhite : Colors.grey[400],
                boxShadow: const [
                  BoxShadow(
                    color: Colors.grey,
                    blurRadius: 5,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    /// Название Адрес Прораб
                    if(listSelectedObjectCompanyForeman.isNotEmpty)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        SizedBox(width: 10.0),
                        /// Название
                        Expanded(
                            child: Text('Название',
                                style: TextStyle(
                                    fontSize: 12.0,
                                    fontWeight:
                                    FontWeight.w500,
                                    color: ColorApp
                                        .myColorGray))),
                        /// Адрес
                        Expanded(
                            child: Text('Адрес',
                                style: TextStyle(
                                    fontSize: 12.0,
                                    fontWeight:
                                    FontWeight.w500,
                                    color: ColorApp
                                        .myColorGray))),
                        /// Прораб
                        Expanded(
                            child: Text('Прораб',
                                style: TextStyle(
                                    fontSize: 12.0,
                                    fontWeight:
                                    FontWeight.w500,
                                    color: ColorApp
                                        .myColorGray))),
                      ],
                    ),
                    const SizedBox(height: 20.0),
                    listSelectedObjectCompanyForeman.isNotEmpty
                        ? Expanded(child: ListView.builder(
                        itemExtent: 70.0,
                          itemCount: listSelectedObjectCompanyForeman.length,
                          itemBuilder: (context, index) {
                            final listAddSelectedObjectCompany = listSelectedObjectCompanyForeman[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 5.0),
                              child: Card(
                                // key: ValueKey(listSelectedObjectCompany[index]),
                                child: InkWell(
                                  onTap: () async {
                                    IntTest.pressHover = listAddSelectedObjectCompany['id'];
                                    await getListObjectInfo(IntTest.pressHover);
                                    setState(() {
                                      showDialog(
                                          context: context,
                                          builder: (context) => const AlertDialog(
                                            content: ViewSelectedObjectForeman(),
                                          ));
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 10.0),
                                    decoration: BoxDecoration(
                                      color: listSelectedCompanyForeman['data']['is_actual'] == true ? ColorApp.myColorWhite : Colors.grey[400],
                                      border: Border.all(color: Colors.grey, width: 1),
                                      borderRadius: BorderRadius.circular(5.0),
                                    ),

                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const SizedBox(width: 10.0),
                                        /// Название
                                        Expanded(
                                            child: Text(listAddSelectedObjectCompany['name'] == null ? '':  '${listAddSelectedObjectCompany['name']}',
                                                style: const TextStyle(
                                                    fontSize: 12.0,
                                                    fontWeight:
                                                    FontWeight
                                                        .w600))),
                                        const SizedBox(width: 10.0),
                                        /// Адрес
                                        Expanded(
                                            child: Text(listAddSelectedObjectCompany['address'] == null ? '':
                                            '${listAddSelectedObjectCompany['address']}',
                                                style: const TextStyle(
                                                    fontSize: 12.0,
                                                    fontWeight: FontWeight.w600))),
                                        const SizedBox(width: 10.0),
                                        /// Прораб
                                        Expanded(
                                            child: Text(listAddSelectedObjectCompany['foreman_id'] == null ? '':
                                                '${listAddSelectedObjectCompany['foreman_id']['name']}',
                                                style: const TextStyle(
                                                    fontSize: 12.0,
                                                    fontWeight: FontWeight.w600))),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }
                      ))
                        : const Center(child: Text('Список пустой')),
                    // CircularProgressIndicator(color: ColorApp.myColorGreen))

                  ],
                ),
              ),
            ),
          ],
        );},);
  }
}
/// ============================================================================================

/// Просмотр объекта ===============================================================
class ViewSelectedObjectForeman extends StatefulWidget {
  const ViewSelectedObjectForeman({Key? key}) : super(key: key);

  @override
  State<ViewSelectedObjectForeman> createState() => _ViewSelectedObjectForemanState();
}
class _ViewSelectedObjectForemanState extends State<ViewSelectedObjectForeman> {
  @override
  Widget build(BuildContext context) {
    final viewObjectPage = listSelectedObjectViewingCompany;
    return SingleChildScrollView(
      child:
      Padding(
        padding: const EdgeInsets.all(ColorApp.kPadding),
        child: Column(
          children: [
            /// Просмотр Объекта и кнопка закрыть
            Row(
              children:  [
                const Spacer(),
                const Text('Просмотр Объекта', style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.w600)),
                const Spacer(),
                IconButton(onPressed: (){
                  Navigator.pop(context);
                }, icon: const Icon(Icons.close)),
              ],
            ),
            /// Body
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ///Левый Блок
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20.0),
                      const Text(
                        'Информация',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,color: Colors.black),
                      ),
                      const SizedBox(height: 20.0),
                      Container(
                        padding: const EdgeInsets.all(20.0),
                        height: 790,
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
                          mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                          children: [
                            /// Название
                            IconAndText(
                                icon: Icons.domain,
                                title: 'Название',
                                subtitle: '${viewObjectPage['name']}'),
                            /// Участок
                            IconAndText(
                                icon: Icons.signpost_outlined,
                                title: 'Участок',
                                subtitle: '${viewObjectPage['division_id']['title']}'),
                            /// Адрес
                            IconAndText(
                                icon: Icons.location_on_outlined,
                                title: 'Адрес',
                                subtitle: '${viewObjectPage['address']}'),
                            /// Тип
                            IconAndText(
                                icon: Icons.looks_one_outlined,
                                title: 'Тип',
                                subtitle: '${viewObjectPage['factory_model_id']['type_object_id']['name']}'),
                            /// Модель
                            IconAndText(
                                icon: Icons.elevator_outlined,
                                title: 'Модель',
                                subtitle: '${viewObjectPage['factory_model_id']['model']}'),
                            /// Регистрационный номер
                            IconAndText(
                                icon: Icons.filter_1_outlined,
                                title: 'Регистрационный номер',
                                subtitle: '${viewObjectPage['registration_number']}'),
                            /// Заводской номер
                            IconAndText(
                                icon: Icons.filter_1_outlined,
                                title: 'Заводской номер',
                                subtitle: '${viewObjectPage['factory_number']}'),
                            /// Компания
                            IconAndText(
                                  icon: Icons.domain,
                                  title: 'Компания',
                                  subtitle: '${viewObjectPage['company_id']['name']}'),
                            /// Контактное лицо
                            if(viewObjectPage['contact_person_id'] != null)
                            IconAndText(
                                icon: Icons.person_outline,
                                title: 'Контактное лицо',
                                subtitle: '${viewObjectPage['contact_person_id']['name']}'),
                            /// Телефон
                            if(viewObjectPage['contact_person_id'] != null)
                            IconAndText(
                                icon: Icons.phone_outlined,
                                title: 'Телефон',
                                subtitle: '${viewObjectPage['contact_person_id']['phone']}'),
                            /// Договор
                            IconAndText(
                                icon: Icons.insert_drive_file_outlined,
                                title: 'Договор',
                                subtitle: '${viewObjectPage['contract_id']['title']}'),
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
                            child: Container(
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
                            ),
                            //   viewObjectPage['geo'] == null
                            //     ? Container(
                            //   decoration: BoxDecoration(
                            //     borderRadius:
                            //     BorderRadius.circular(5.0),
                            //     color: ColorApp.myColorWhite,
                            //     boxShadow: const [
                            //       BoxShadow(
                            //         color: Colors.grey,
                            //         blurRadius: 5,
                            //       ),
                            //     ],
                            //   ),
                            //   child: const Center(child: Text('Нет данных')),
                            // )
                            //     : const MyMapScheduleObject(),
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
                                Expanded(
                                  child: Container(
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
                                        Expanded(
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
                                                Padding(padding: const EdgeInsets.symmetric(horizontal: 10.0),
                                                    child: CircleAvatar(
                                                        backgroundImage: const NetworkImage('assets/user.png'),
                                                        foregroundImage: NetworkImage('http://${viewObjectPage['foreman_id']['photo']},'))),
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
                                Expanded(
                                  child: Container(
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
                                        Expanded(
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
                                                        foregroundImage: NetworkImage('http://${viewObjectPage['mechanic_id']['photo']}'))),
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
                          Container(
                            padding: const EdgeInsets.all(20.0),
                            height: 180,
                            decoration: BoxDecoration(
                              borderRadius:
                              BorderRadius.circular(5.0),
                              color: viewObjectPage['is_actual'] == true?  ColorApp.myColorWhite : Colors.grey[300],
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
                                /// Высота подъема, Количество остановок, Грузоподъемность
                                Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment
                                      .spaceBetween,
                                  children: [
                                    /// Высота подъема
                                    Expanded(
                                        child: IconAndText(
                                            icon: Icons.height,
                                            title: 'Высота подъема',
                                            subtitle: viewObjectPage['lifting_heights'].toString() ?? ''
                                        )),
                                    /// Количество остановок
                                    Expanded(
                                        child: IconAndText(
                                            icon: Icons.elevator_outlined,
                                            title: 'Количество остановок',
                                            subtitle: viewObjectPage['number_of_stops'].toString() ?? '')),

                                    /// Грузоподъемность
                                    Expanded(
                                        child: IconAndText(
                                            icon: Icons.scale_outlined,
                                            title: 'Грузоподъемность',
                                            subtitle: viewObjectPage['load_capacity'].toString() ?? '')),
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
                                            subtitle: viewObjectPage['cost_nds'].toString()
                                                ?? '')),

                                    /// Стоимость ТО без НДС
                                    Expanded(
                                        child: IconAndText(
                                            icon: Icons
                                                .currency_ruble_outlined,
                                            title:
                                            'Стоимость ТО без НДС',
                                            subtitle: viewObjectPage
                                            ['cost_no_nds'].toString()
                                                ?? '')),
                                    /// Для красоты
                                    Expanded(child: Container()),
                                  ],
                                ),
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
                          const Text(
                            'Инспекции',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 20.0),
                          Container(
                            padding: const EdgeInsets.all(20.0),
                            height: 115,
                            decoration: BoxDecoration(
                              borderRadius:
                              BorderRadius.circular(5.0),
                              color: viewObjectPage['is_actual'] == true?  ColorApp.myColorWhite : Colors.grey[300],
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.grey,
                                  blurRadius: 5,
                                ),
                              ],
                            ),
                            child: Row(
                              crossAxisAlignment:
                              CrossAxisAlignment.center,
                              mainAxisAlignment:
                              MainAxisAlignment.spaceBetween,
                              children: [
                                /// Дата полного ТО
                                SizedBox(
                                    height: 40,
                                    child: IconAndText(
                                        icon: Icons
                                            .calendar_month_outlined,
                                        title: 'Дата полного ТО',
                                        subtitle: '${viewObjectPage['date_inspection']}')),

                                /// Дата планового ТО
                                SizedBox(
                                    height: 40,
                                    child: IconAndText(
                                        icon: Icons
                                            .calendar_month_outlined,
                                        title: 'Дата планового ТО',
                                        subtitle: '${viewObjectPage['planned_inspection']}')),

                                /// Период ТО
                                SizedBox(
                                    height: 40,
                                    child: IconAndText(
                                        icon: Icons
                                            .calendar_month_outlined,
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
          ],
        ),
      ),
    );
  }
}
/// ================================================================================
