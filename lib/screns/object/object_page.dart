// ignore_for_file: use_key_in_widget_constructors

import 'package:flutter/material.dart';

import '../../helper/class_colors.dart';
import '../../helper/my_map/my_map.dart';

class ObjectPage extends StatefulWidget {
  const ObjectPage({Key? key}) : super(key: key);

  @override
  State<ObjectPage> createState() => _ObjectPageState();
}

class _ObjectPageState extends State<ObjectPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: ColorApp.myColorTransparent,
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ///Body
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ///Левый Блок
                    Expanded(
                      flex: 3,
                      child: Column(
                        children: [
                          const SizedBox(height: 10.0),

                          ///кнопки
                          Row(
                            children: [
                              /// Назад
                              IconButton(
                                  onPressed: () {},
                                  icon: const Icon(
                                    Icons.arrow_circle_left_rounded,
                                    color: ColorApp.myColorGreenAuth,
                                  )),
                              const SizedBox(width: 10.0),
                              const Text(
                                'Информация',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(width: 10.0),

                              /// Изменить
                              IconButton(
                                  onPressed: () {
                                    setState(() {
                                      showDialog(
                                          context: context,
                                          builder: (context) =>
                                              const AlertDialog(
                                                  // content: EditingCompany(),
                                                  ));
                                    });
                                  },
                                  icon: const Icon(Icons.edit_outlined,
                                      color: ColorApp.myColorGray)),

                              /// Заморозить
                              IconButton(
                                  onPressed: () {
                                    setState(() {
                                      showDialog(
                                          context: context,
                                          builder: (context) => const AlertDialog(
                                              // content: CompanyAccountFreeze(),
                                              ));
                                    });
                                  },
                                  icon: const Icon(Icons.ac_unit_outlined,
                                      color: ColorApp.myColorGray)),
                            ],
                          ),
                          const SizedBox(height: 10.0),
                          Container(
                            padding: const EdgeInsets.all(20.0),
                            height: 790,
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
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: const [
                                IconAndText(
                                    icon: Icons.domain,
                                    title: 'Организация',
                                    subtitle: 'ООО «КПЭК»'),
                                IconAndText(
                                    icon: Icons.signpost_outlined,
                                    title: 'Участок',
                                    subtitle: 'Северная/Тургенева'),
                                IconAndText(
                                    icon: Icons.location_on_outlined,
                                    title: 'Адрес',
                                    subtitle:
                                        'г. Краснодар, ул. Северная, 356'),
                                IconAndText(
                                    icon: Icons.looks_one_outlined,
                                    title: 'Тип',
                                    subtitle: 'Лифт'),
                                IconAndText(
                                    icon: Icons.elevator_outlined,
                                    title: 'Модель',
                                    subtitle: 'LIFT A388509'),
                                IconAndText(
                                    icon: Icons.filter_1_outlined,
                                    title: 'Регистрационный номер',
                                    subtitle: '23834939003928282'),
                                IconAndText(
                                    icon: Icons.filter_1_outlined,
                                    title: 'Заводской номер',
                                    subtitle: '23834939003928282'),
                                IconAndText(
                                    icon: Icons.domain,
                                    title: 'Компания',
                                    subtitle: 'ООО “Гармония”'),
                                IconAndText(
                                    icon: Icons.person_outline,
                                    title: 'Контактное лицо',
                                    subtitle: 'П.С. Василенко'),
                                IconAndText(
                                    icon: Icons.insert_drive_file_outlined,
                                    title: 'Договор',
                                    subtitle: 'Договор №2123 от 24.04.2022'),
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Местоположение',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 20.0),
                              Container(
                                height: 250,
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
                                // child: MyMap(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20.0),

                          ///Ответственные
                          Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
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
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 20.0, vertical: 10.0),
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
                                            ///Прораб
                                            const Expanded(
                                              child: Text(
                                                'Прораб',
                                                style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                    color:
                                                        ColorApp.myColorWhite),
                                              ),
                                            ),

                                            Expanded(
                                              child: Container(
                                                height: 60,
                                                // padding: const EdgeInsets.all(10.0),
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  color: ColorApp
                                                      .myColorGrayShadow,
                                                ),
                                                child: Row(
                                                  children: const [
                                                    Padding(
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                              horizontal: 10.0),
                                                      child: CircleAvatar(
                                                        backgroundImage:
                                                            NetworkImage(
                                                                'assets/cat.jpeg'),
                                                        // foregroundImage: NetworkImage('http://' ''),
                                                      ),
                                                    ),
                                                    Expanded(
                                                      child: Text(
                                                        'В.А. Макаров',
                                                        style: TextStyle(
                                                            fontSize: 14,
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
                                    const SizedBox(width: 20.0),
                                    Expanded(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 20.0, vertical: 10.0),
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
                                                    color:
                                                        ColorApp.myColorWhite),
                                              ),
                                            ),
                                            Expanded(
                                              child: Container(
                                                height: 60,
                                                // padding: const EdgeInsets.all(10.0),
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  color: ColorApp
                                                      .myColorGrayShadow,
                                                ),
                                                child: Row(
                                                  children: const [
                                                    Padding(
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                              horizontal: 10.0),
                                                      child: CircleAvatar(
                                                        backgroundImage:
                                                            NetworkImage(
                                                                'assets/cat.jpeg'),
                                                        // foregroundImage: NetworkImage('http://' ''),
                                                      ),
                                                    ),
                                                    Expanded(
                                                      child: Text(
                                                        'Л.А. Терешков',
                                                        style: TextStyle(
                                                            fontSize: 14,
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
                                )]),
                          const SizedBox(height: 20.0),

                          ///Об объекте
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Об объекте',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 20.0),
                              Container(
                                padding: const EdgeInsets.all(20.0),
                                height: 180,
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
                                child: Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: const [
                                        Expanded(
                                            child: IconAndText(
                                                icon: Icons.height,
                                                title: 'Высота подъема',
                                                subtitle: '78')),
                                        Expanded(
                                            child: IconAndText(
                                                icon: Icons.elevator_outlined,
                                                title: 'Количество остановок',
                                                subtitle: '6')),
                                        Expanded(
                                            child: IconAndText(
                                                icon: Icons.scale_outlined,
                                                title: 'Грузоподъемность',
                                                subtitle: '1800')),
                                      ],
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: const [
                                        Expanded(
                                            child: IconAndText(
                                                icon: Icons.sync_alt_rounded,
                                                title: 'Ширина',
                                                subtitle: '2,5')),
                                        Expanded(
                                            child: IconAndText(
                                                icon: Icons
                                                    .currency_ruble_outlined,
                                                title: 'Стоимость ТО с НДС',
                                                subtitle: '25 345₽')),
                                        Expanded(
                                            child: IconAndText(
                                                icon: Icons
                                                    .currency_ruble_outlined,
                                                title: 'Стоимость ТО без НДС',
                                                subtitle: '20 276₽')),
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Инспекции',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 20.0),
                              Container(
                                padding: const EdgeInsets.all(20.0),
                                height: 115,
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
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: const [
                                    SizedBox(
                                        height: 40,
                                        child: IconAndText(
                                            icon: Icons.calendar_month_outlined,
                                            title: 'Дата полного ТО',
                                            subtitle: '19.10.2022')),
                                    SizedBox(
                                        height: 40,
                                        child: IconAndText(
                                            icon: Icons.calendar_month_outlined,
                                            title: 'Дата планового ТО',
                                            subtitle: '19.10.2022')),
                                    SizedBox(
                                        height: 40,
                                        child: IconAndText(
                                            icon: Icons.calendar_month_outlined,
                                            title: 'Период ТО',
                                            subtitle: '19.10.2022')),
                                  ],
                                ),
                              ),
                            ],
                          )
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
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 10.0),
                    Container(
                      padding: const EdgeInsets.all(20.0),
                      height: 250,
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
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text('Документ',
                                        style:
                                        TextStyle(fontWeight: FontWeight.w300, fontSize: 12)),
                                    SizedBox(height: 5.0),
                                    Text('Письмо о назначении',
                                        style:
                                        TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                                  height: 50.0,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(5.0),
                                    border: Border.all(width: 1,color: ColorApp.myColorAvatar)
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.picture_as_pdf_outlined,color: ColorApp.myColorGreen),
                                      const SizedBox(width: 10.0),
                                      const Text('doc28338_ndc.pdf',
                                        style:
                                        TextStyle(fontSize: 16, fontWeight: FontWeight.w600),),
                                      const Spacer(),
                                      Container(
                                        width: 30.0,
                                        height: 30.0,
                                        decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(5.0),
                                        color: ColorApp.myColorGreen,
                                        ),
                                        child: const Icon(Icons.open_in_full_outlined,color: ColorApp.myColorWhite,),
                                      ),
                                      const SizedBox(width: 10.0),
                                      Container(
                                        width: 30.0,
                                        height: 30.0,
                                        decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(5.0),
                                        color: ColorApp.myColorGreen,
                                        ),
                                        child: const Icon(Icons.download_for_offline_outlined,color: ColorApp.myColorWhite,),
                                      ),
                                      const SizedBox(width: 10.0),
                                      Container(
                                        width: 30.0,
                                        height: 30.0,
                                        decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(5.0),
                                        color: ColorApp.myColorRed,
                                        ),
                                        child: const Icon(Icons.delete_outline,color: ColorApp.myColorWhite,),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text('Документ',
                                        style:
                                        TextStyle(fontWeight: FontWeight.w300, fontSize: 12)),
                                    SizedBox(height: 5.0),
                                    Text('Сертификат',
                                        style:
                                        TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                                  height: 50.0,
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(5.0),
                                      border: Border.all(width: 1,color: ColorApp.myColorAvatar)
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.picture_as_pdf_outlined,color: ColorApp.myColorGreen),
                                      const SizedBox(width: 10.0),
                                      const Text('doc28338_ndc.pdf',
                                        style:
                                        TextStyle(fontSize: 16, fontWeight: FontWeight.w600),),
                                      const Spacer(),
                                      Container(
                                        width: 30.0,
                                        height: 30.0,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(5.0),
                                          color: ColorApp.myColorGreen,
                                        ),
                                        child: const Icon(Icons.open_in_full_outlined,color: ColorApp.myColorWhite,),
                                      ),
                                      const SizedBox(width: 10.0),
                                      Container(
                                        width: 30.0,
                                        height: 30.0,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(5.0),
                                          color: ColorApp.myColorGreen,
                                        ),
                                        child: const Icon(Icons.download_for_offline_outlined,color: ColorApp.myColorWhite,),
                                      ),
                                      const SizedBox(width: 10.0),
                                      Container(
                                        width: 30.0,
                                        height: 30.0,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(5.0),
                                          color: ColorApp.myColorRed,
                                        ),
                                        child: const Icon(Icons.delete_outline,color: ColorApp.myColorWhite,),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Text('Документ',
                                        style:
                                        TextStyle(fontWeight: FontWeight.w300, fontSize: 12)),
                                    SizedBox(height: 5.0),
                                    Text('Акт',
                                        style:
                                        TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                                  ],
                                ),
                              ),
                              Expanded(
                                flex: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                                  height: 50.0,
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(5.0),
                                      border: Border.all(width: 1,color: ColorApp.myColorAvatar)
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.picture_as_pdf_outlined,color: ColorApp.myColorGreen),
                                      const SizedBox(width: 10.0),
                                      const Text('doc28338_ndc.pdf',
                                        style:
                                        TextStyle(fontSize: 16, fontWeight: FontWeight.w600),),
                                      const Spacer(),
                                      Container(
                                        width: 30.0,
                                        height: 30.0,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(5.0),
                                          color: ColorApp.myColorGreen,
                                        ),
                                        child: const Icon(Icons.open_in_full_outlined,color: ColorApp.myColorWhite,),
                                      ),
                                      const SizedBox(width: 10.0),
                                      Container(
                                        width: 30.0,
                                        height: 30.0,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(5.0),
                                          color: ColorApp.myColorGreen,
                                        ),
                                        child: const Icon(Icons.download_for_offline_outlined,color: ColorApp.myColorWhite,),
                                      ),
                                      const SizedBox(width: 10.0),
                                      Container(
                                        width: 30.0,
                                        height: 30.0,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(5.0),
                                          color: ColorApp.myColorRed,
                                        ),
                                        child: const Icon(Icons.delete_outline,color: ColorApp.myColorWhite,),
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
                  ],
                ),
              ],
            ),
          ),
        ));
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
            Text(subtitle,
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          ],
        )
      ],
    );
  }
}
