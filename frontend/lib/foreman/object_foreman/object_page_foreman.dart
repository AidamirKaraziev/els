import 'package:els/foreman/object_foreman/widgets_object_foreman/editing_object_foreman.dart';
import 'package:gap/gap.dart';
import 'package:flutter/material.dart';
import '../../../../helper/class_colors.dart';
import 'package:http/http.dart' as http;
import '../../screns/home_page/home_page.dart';
import '../user_page_foreman.dart';
import '../defects/defects_screen.dart';
import 'act_foreman.dart';
import 'letter_of_appointment_foreman.dart';
import 'object_screen_foreman.dart';
import 'package:els/helper/api_config.dart';
import 'package:els/helper/api_image.dart';

/// Окно выбранного обьекта

class ObjectPageForeman extends StatefulWidget {
  const ObjectPageForeman({Key? key}) : super(key: key);

  @override
  State<ObjectPageForeman> createState() => _ObjectPageForemanState();
}

class _ObjectPageForemanState extends State<ObjectPageForeman> {

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final viewObjectPage = listSelectedObjectForeman['data'];
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
                                          color: ColorApp.myColorGrayBorder, width: 1),
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
                                            IntTest.indexScreensForeman = 0;
                                            myStream.add(IntTest.indexScreensForeman);
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
                              const MyUserForeman(),
                            ],
                          )),

                      /// Body ======
                      Padding(
                        padding: const EdgeInsets.all(ColorApp.kPadding),
                        child: Column(
                          children: [
                            ///Левый Блок, Правый Блок
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceAround,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ///Левый Блок
                                Expanded(
                                  flex: 3,
                                  child: Column(
                                    children: [
                                      const SizedBox(height: 10.0),
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
                                                    IconButton(
                                                        onPressed: () {
                                                          setState(() {
                                                            showDialog(
                                                                context:
                                                                    context,
                                                                builder:
                                                                    (context) =>
                                                                        const AlertDialog(
                                                                          content:
                                                                              EditingObjectForeman(),
                                                                        ));
                                                          });
                                                        },
                                                        icon: const Icon(
                                                            Icons
                                                                .edit_outlined,
                                                            color: ColorApp
                                                                .myColorGray)),

                                                    /// Заморозить
                                                    // IconButton(
                                                    //     onPressed: () {
                                                    //       setState(() async {
                                                    //         await showDialog(
                                                    //             context:
                                                    //                 context,
                                                    //             builder:
                                                    //                 (context) =>
                                                    //                     const AlertDialog(
                                                    //                       content: ObjectAccountFreezeForeman(),
                                                    //                     ));
                                                    //         setState(() {});
                                                    //       });
                                                    //     },
                                                    //     icon: const Icon(
                                                    //         Icons
                                                    //             .ac_unit_outlined,
                                                    //         color: ColorApp
                                                    //             .myColorGray)),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
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
                                            ),
                                            // viewObjectPage['geo'] == 'string'
                                            //     ? Container(
                                            //         decoration: BoxDecoration(
                                            //           borderRadius:
                                            //               BorderRadius
                                            //                   .circular(5.0),
                                            //           color: ColorApp
                                            //               .myColorWhite,
                                            //           boxShadow: const [
                                            //             BoxShadow(
                                            //               color: Colors.grey,
                                            //               blurRadius: 5,
                                            //             ),
                                            //           ],
                                            //         ),
                                            //         child: const Center(
                                            //             child: Text(
                                            //                 'Нет данных')),
                                            //       )
                                            //     : const MyMapObject(),
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
                                                  fontWeight:
                                                  FontWeight.w600),
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
                                                                        foregroundImage: apiImage(viewObjectPage['foreman_id']['photo']))),
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
                                                const SizedBox(width: 20.0),

                                                /// Механик
                                                Expanded(
                                                  child: Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 20.0,
                                                        vertical: 10.0),
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
                                                            'Механик',
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
                                                                        foregroundImage: apiImage(viewObjectPage['mechanic_id']['photo']))),
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
                                            padding:
                                                const EdgeInsets.all(20.0),
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
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
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
                                            padding:
                                                const EdgeInsets.all(20.0),
                                            height: 115,
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(5.0),
                                              color: viewObjectPage['is_actual'] ==
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
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
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
                                          Expanded(
                                            flex: 2,
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: const [
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
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 10.0),
                                              height: 50.0,
                                              decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          5.0),
                                                  border: Border.all(
                                                      width: 1,
                                                      color: ColorApp
                                                          .myColorAvatar)),
                                              child: Row(
                                                children: [
                                                  const Icon(
                                                      Icons
                                                          .picture_as_pdf_outlined,
                                                      color: ColorApp
                                                          .myColorGreen),
                                                  const SizedBox(width: 10.0),
                                                  const Text(
                                                    'doc28338_ndc.pdf',
                                                    style: TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w600),
                                                  ),
                                                  const Spacer(),
                                                  InkWell(
                                                    onTap: () {
                                                      setState(() {
                                                        showDialog(
                                                            context: context,
                                                            builder: (context) =>
                                                                const AlertDialog(
                                                                  content: LetterOfAppointmentForeman(),
                                                                )).then(
                                                            (value) =>
                                                                setState(
                                                                    () {}));
                                                      });
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
                                                  Container(
                                                    width: 30.0,
                                                    height: 30.0,
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius
                                                              .circular(5.0),
                                                      color: ColorApp
                                                          .myColorGreen,
                                                    ),
                                                    child: const Icon(
                                                      Icons
                                                          .download_for_offline_outlined,
                                                      color: ColorApp
                                                          .myColorWhite,
                                                    ),
                                                  ),
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
                                          Expanded(
                                            flex: 2,
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: const [
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
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 10.0),
                                              height: 50.0,
                                              decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          5.0),
                                                  border: Border.all(
                                                      width: 1,
                                                      color: ColorApp
                                                          .myColorAvatar)),
                                              child: Row(
                                                children: [
                                                  const Icon(
                                                      Icons
                                                          .picture_as_pdf_outlined,
                                                      color: ColorApp
                                                          .myColorGreen),
                                                  const SizedBox(width: 10.0),
                                                  const Text(
                                                    'doc28338_ndc.pdf',
                                                    style: TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w600),
                                                  ),
                                                  const Spacer(),
                                                  InkWell(
                                                    onTap: () async {
                                                      setState(() {
                                                        showDialog(
                                                            context: context,
                                                            builder: (context) =>
                                                                const AlertDialog(
                                                                  content: AcceptanceCertificateForeman(),
                                                                )).then(
                                                            (value) =>
                                                                setState(
                                                                    () {}));
                                                      });
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
                                                  Container(
                                                    width: 30.0,
                                                    height: 30.0,
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius
                                                              .circular(5.0),
                                                      color: ColorApp
                                                          .myColorGreen,
                                                    ),
                                                    child: const Icon(
                                                      Icons
                                                          .download_for_offline_outlined,
                                                      color: ColorApp
                                                          .myColorWhite,
                                                    ),
                                                  ),
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

                                      /// Дефекты
                                      Row(
                                        children: [
                                          const Expanded(
                                            flex: 2,
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text('Журнал',
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w300,
                                                        fontSize: 12)),
                                                SizedBox(height: 5.0),
                                                Text('Дефекты',
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontSize: 15)),
                                              ],
                                            ),
                                          ),
                                          Expanded(
                                            flex: 8,
                                            child: InkWell(
                                              onTap: () {
                                                Navigator.of(context).push(
                                                  MaterialPageRoute<void>(
                                                    builder: (_) =>
                                                        DefectsScreen(
                                                      objectId: viewObjectPage[
                                                          'id'] as int,
                                                      objectName:
                                                          '${viewObjectPage['name']}',
                                                    ),
                                                  ),
                                                );
                                              },
                                              child: Container(
                                                padding: const EdgeInsets
                                                    .symmetric(
                                                    horizontal: 10.0),
                                                height: 50.0,
                                                decoration: BoxDecoration(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            5.0),
                                                    border: Border.all(
                                                        width: 1,
                                                        color: ColorApp
                                                            .myColorAvatar)),
                                                child: const Row(
                                                  children: [
                                                    Icon(
                                                        Icons
                                                            .report_gmailerrorred_outlined,
                                                        color: ColorApp
                                                            .myColorGreen),
                                                    SizedBox(width: 10.0),
                                                    Text(
                                                      'Дефекты объекта',
                                                      style: TextStyle(
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.w600),
                                                    ),
                                                    Spacer(),
                                                    _OpenSquare(
                                                        icon: Icons
                                                            .open_in_full_outlined),
                                                  ],
                                                ),
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

/// Зелёный квадрат-кнопка справа в строке документа — как у секции «Акт».
class _OpenSquare extends StatelessWidget {
  final IconData icon;

  const _OpenSquare({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 30.0,
      height: 30.0,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5.0),
        color: ColorApp.myColorGreen,
      ),
      child: Icon(icon, color: ColorApp.myColorWhite),
    );
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
