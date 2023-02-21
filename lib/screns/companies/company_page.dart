import 'package:els/screns/companies/add_contact_person.dart';
import 'package:els/screns/companies/company_account_freeze.dart';
import 'package:flutter/material.dart';
import '../../helper/class_colors.dart';
import '../home_page/home_page.dart';
import 'editing_company.dart';

class CompanyPage extends StatefulWidget {
  const CompanyPage({Key? key}) : super(key: key);

  @override
  State<CompanyPage> createState() => _CompanyPageState();
}

class _CompanyPageState extends State<CompanyPage> {
  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return Scaffold(
      body: Container(
        color: ColorApp.myColorTransparent,
        child: SingleChildScrollView(
          child: size.width > 1150
              ? Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      ///кнопки
                      Row(
                        children: [
                          /// Назад
                          IconButton(
                              onPressed: () {
                                setState(() {
                                  IntTest.indexScreens = 4;
                                  pointsMapController.add(IntTest.indexScreens);
                                });
                              },
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
                                      builder: (context) => const AlertDialog(
                                            content: EditingCompany(),
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
                                            content: CompanyAccountFreeze(),
                                          ));
                                });
                              },
                              icon: const Icon(Icons.ac_unit_outlined,
                                  color: ColorApp.myColorGray)),
                        ],
                      ),
                      const SizedBox(height: 20.0),
                      Column(
                        children: [
                          /// Лого и Инфа
                          Row(
                            children: const [
                              /// Лого
                              CompanyProfile(),
                              SizedBox(width: 20.0),

                              /// Инфа
                              Expanded(
                                child: CompanyInfo(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20.0),

                          /// Аккаунты Объекты Контактные лица
                          Row(
                            children: const [
                              /// Аккаунты
                              Expanded(
                                flex: 3,
                                child: CompanyAccount(),
                              ),
                              SizedBox(width: 20.0),

                              ///Объекты
                              Expanded(
                                flex: 3,
                                child: CompanyObject(),
                              ),
                              SizedBox(width: 20.0),

                              ///Контактные лица
                              Expanded(
                                flex: 2,
                                child: CompanyContactFaces(),
                              ),
                            ],
                          ),
                        ],
                      )
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
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
                                      builder: (context) => const AlertDialog(
                                            content: EditingCompany(),
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
                                            content: CompanyAccountFreeze(),
                                          ));
                                });
                              },
                              icon: const Icon(Icons.ac_unit_outlined,
                                  color: ColorApp.myColorGray)),
                        ],
                      ),
                      const SizedBox(height: 20.0),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          /// Лого и Инфа
                          CompanyProfile(),
                          SizedBox(height: 20.0),

                          /// Инфа
                          CompanyInfo(),
                          SizedBox(height: 20.0),

                          /// Аккаунты Объекты Контактные лица
                          CompanyAccount(),
                          SizedBox(height: 20.0),

                          ///Объекты
                          CompanyObject(),
                          SizedBox(height: 20.0),

                          ///Контактные лица
                          CompanyContactFaces(),
                        ],
                      )
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

/// Инфа
class CompanyInfo extends StatelessWidget {
  const CompanyInfo({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return Container(
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
      height: size.width > 600 ?  250 : null,
      child: Padding(
        padding: const EdgeInsets.all(30.0),
        child: size.width > 600
            ? Row(
                children: [
                  /// Название Адрес Директор
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        /// Название
                        Row(
                          children: [
                            const Icon(Icons.business,
                                color: ColorApp.myColorGreenWhite),
                            const SizedBox(width: 20.0),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text('Название',
                                    style: TextStyle(fontSize: 12)),
                                Text('ООО «Гармония»',
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ],
                        ),

                        /// Адрес
                        Row(
                          children: [
                            const Icon(Icons.location_on_outlined,
                                color: ColorApp.myColorGreenWhite),
                            const SizedBox(width: 20.0),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text('Адрес', style: TextStyle(fontSize: 12)),
                                Text('ул. Промышленная, 22',
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ],
                        ),

                        /// Директор
                        Row(
                          children: [
                            const Icon(Icons.person_outline,
                                color: ColorApp.myColorGreenWhite),
                            const SizedBox(width: 20.0),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text('Директор',
                                    style: TextStyle(fontSize: 12)),
                                Text('И.Н. Васильев',
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  /// Сайт Телефон Эл.почта
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        ///Сайт
                        Row(
                          children: [
                            const Icon(Icons.language,
                                color: ColorApp.myColorGreenWhite),
                            const SizedBox(width: 20.0),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text('Сайт', style: TextStyle(fontSize: 12)),
                                Text('garmonia.ru»',
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ],
                        ),

                        ///Телефон
                        Row(
                          children: [
                            const Icon(Icons.phone_outlined,
                                color: ColorApp.myColorGreenWhite),
                            const SizedBox(width: 20.0),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text('Телефон', style: TextStyle(fontSize: 12)),
                                Text('+7 (918) 123 45 67',
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ],
                        ),

                        ///Эл.почта
                        Row(
                          children: [
                            const Icon(Icons.email_outlined,
                                color: ColorApp.myColorGreenWhite),
                            const SizedBox(width: 20.0),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text('Эл.почта',
                                    style: TextStyle(fontSize: 12)),
                                Text('garmonia_krd@mail.ru',
                                    style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                /// Название
                Row(
                  children: [
                    const Icon(Icons.business,
                        color: ColorApp.myColorGreenWhite),
                    const SizedBox(width: 20.0),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Название',
                            style: TextStyle(fontSize: 12)),
                        Text('ООО «Гармония»',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10.0),
                /// Адрес
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined,
                        color: ColorApp.myColorGreenWhite),
                    const SizedBox(width: 20.0),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Адрес', style: TextStyle(fontSize: 12)),
                        Text('ул. Промышленная, 22',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10.0),
                /// Директор
                Row(
                  children: [
                    const Icon(Icons.person_outline,
                        color: ColorApp.myColorGreenWhite),
                    const SizedBox(width: 20.0),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Директор',
                            style: TextStyle(fontSize: 12)),
                        Text('И.Н. Васильев',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10.0),
                ///Сайт
                Row(
                  children: [
                    const Icon(Icons.language,
                        color: ColorApp.myColorGreenWhite),
                    const SizedBox(width: 20.0),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Сайт', style: TextStyle(fontSize: 12)),
                        Text('garmonia.ru»',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10.0),
                ///Телефон
                Row(
                  children: [
                    const Icon(Icons.phone_outlined,
                        color: ColorApp.myColorGreenWhite),
                    const SizedBox(width: 20.0),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Телефон', style: TextStyle(fontSize: 12)),
                        Text('+7 (918) 123 45 67',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10.0),
                ///Эл.почта
                Row(
                  children: [
                    const Icon(Icons.email_outlined,
                        color: ColorApp.myColorGreenWhite),
                    const SizedBox(width: 20.0),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Эл.почта',
                            style: TextStyle(fontSize: 12)),
                        Text('garmonia_krd@mail.ru',
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
      ),
    );
  }
}

/// Лого
class CompanyProfile extends StatelessWidget {
  const CompanyProfile({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
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
      height: 250,
      width: 250,
      child: const Padding(
        padding: EdgeInsets.all(50.0),
        child: CircleAvatar(
          backgroundImage: NetworkImage('assets/cat.jpeg'),
        ),
      ),
    );
  }
}

/// Аккаунты
class CompanyAccount extends StatelessWidget {
  const CompanyAccount({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            const Text(
              'Аккаунты',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            IconButton(
                onPressed: () {},
                icon: const Icon(
                  Icons.add_box_rounded,
                  color: ColorApp.myColorGreenAuth,
                ))
          ],
        ),
        Container(
          width: double.infinity,
          height: 300,
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
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    SizedBox(width: 10.0),
                    Expanded(
                        child: Text('Имя',
                            style: TextStyle(
                                fontSize: 10.0,
                                fontWeight: FontWeight.w500,
                                color: ColorApp.myColorGray))),
                    Expanded(
                        child: Text('Должность',
                            style: TextStyle(
                                fontSize: 10.0,
                                fontWeight: FontWeight.w500,
                                color: ColorApp.myColorGray))),
                    Expanded(
                        child: Text('Номер',
                            style: TextStyle(
                                fontSize: 10.0,
                                fontWeight: FontWeight.w500,
                                color: ColorApp.myColorGray))),
                  ],
                ),
                const SizedBox(height: 20.0),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey, width: 1),
                    borderRadius: BorderRadius.circular(5.0),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 3.0),
                      Expanded(
                          child: Row(
                        children: [
                          Container(
                            width: 25,
                            height: 25,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(25),
                              color: const Color(0xff6F00A4),
                            ),
                          ),
                          const SizedBox(width: 3.0),
                          const Text('И. В. Васильев',
                              style: TextStyle(
                                  fontSize: 12.0, fontWeight: FontWeight.w600)),
                        ],
                      )),
                      const Expanded(
                          child: Text('Северная 242/1',
                              style: TextStyle(
                                  fontSize: 12.0,
                                  fontWeight: FontWeight.w600))),
                      const Expanded(
                          child: Text('+7 (918) 123 45 67',
                              style: TextStyle(
                                  fontSize: 12.0,
                                  fontWeight: FontWeight.w600))),
                    ],
                  ),
                ),
                const SizedBox(height: 10.0),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey, width: 1),
                    borderRadius: BorderRadius.circular(5.0),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 3.0),
                      Expanded(
                          child: Row(
                        children: [
                          Container(
                            width: 25,
                            height: 25,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(25),
                              color: const Color(0xff6F00A4),
                            ),
                          ),
                          const SizedBox(width: 3.0),
                          const Text('И. В. Васильев',
                              style: TextStyle(
                                  fontSize: 12.0, fontWeight: FontWeight.w600)),
                        ],
                      )),
                      const Expanded(
                          child: Text('Северная 242/1',
                              style: TextStyle(
                                  fontSize: 12.0,
                                  fontWeight: FontWeight.w600))),
                      const Expanded(
                          child: Text('+7 (918) 123 45 67',
                              style: TextStyle(
                                  fontSize: 12.0,
                                  fontWeight: FontWeight.w600))),
                    ],
                  ),
                ),
                const SizedBox(height: 10.0),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey, width: 1),
                    borderRadius: BorderRadius.circular(5.0),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 3.0),
                      Expanded(
                          child: Row(
                        children: [
                          Container(
                            width: 25,
                            height: 25,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(25),
                              color: const Color(0xff6F00A4),
                            ),
                          ),
                          const SizedBox(width: 3.0),
                          const Text('И. В. Васильев',
                              style: TextStyle(
                                  fontSize: 12.0, fontWeight: FontWeight.w600)),
                        ],
                      )),
                      const Expanded(
                          child: Text('Северная 242/1',
                              style: TextStyle(
                                  fontSize: 12.0,
                                  fontWeight: FontWeight.w600))),
                      const Expanded(
                          child: Text('+7 (918) 123 45 67',
                              style: TextStyle(
                                  fontSize: 12.0,
                                  fontWeight: FontWeight.w600))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

///Объекты
class CompanyObject extends StatelessWidget {
  const CompanyObject({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Объекты',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 20.0),
            IconButton(
                onPressed: () {},
                icon: const Icon(
                  Icons.add_box_rounded,
                  color: ColorApp.myColorGreenAuth,
                ))
          ],
        ),
        Container(
          width: double.infinity,
          height: 300,
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
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    SizedBox(width: 10.0),
                    Expanded(
                        child: Text('Название',
                            style: TextStyle(
                                fontSize: 12.0,
                                fontWeight: FontWeight.w500,
                                color: ColorApp.myColorGray))),
                    Expanded(
                        child: Text('Адрес',
                            style: TextStyle(
                                fontSize: 12.0,
                                fontWeight: FontWeight.w500,
                                color: ColorApp.myColorGray))),
                    Expanded(
                        child: Text('Прораб',
                            style: TextStyle(
                                fontSize: 12.0,
                                fontWeight: FontWeight.w500,
                                color: ColorApp.myColorGray))),
                  ],
                ),
                const SizedBox(height: 20.0),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey, width: 1),
                    borderRadius: BorderRadius.circular(5.0),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      SizedBox(width: 10.0),
                      Expanded(
                          child: Text('Объект №324',
                              style: TextStyle(
                                  fontSize: 12.0,
                                  fontWeight: FontWeight.w600))),
                      Expanded(
                          child: Text('Северная 242/1',
                              style: TextStyle(
                                  fontSize: 12.0,
                                  fontWeight: FontWeight.w600))),
                      Expanded(
                          child: Text('Н.В. Гоголевский',
                              style: TextStyle(
                                  fontSize: 12.0,
                                  fontWeight: FontWeight.w600))),
                    ],
                  ),
                ),
                const SizedBox(height: 5.0),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey, width: 1),
                    borderRadius: BorderRadius.circular(5.0),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      SizedBox(width: 10.0),
                      Expanded(
                          child: Text('Объект №324',
                              style: TextStyle(
                                  fontSize: 12.0,
                                  fontWeight: FontWeight.w600))),
                      Expanded(
                          child: Text('Северная 242/1',
                              style: TextStyle(
                                  fontSize: 12.0,
                                  fontWeight: FontWeight.w600))),
                      Expanded(
                          child: Text('Н.В. Гоголевский',
                              style: TextStyle(
                                  fontSize: 12.0,
                                  fontWeight: FontWeight.w600))),
                    ],
                  ),
                ),
                const SizedBox(height: 5.0),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey, width: 1),
                    borderRadius: BorderRadius.circular(5.0),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      SizedBox(width: 10.0),
                      Expanded(
                          child: Text('Объект №324',
                              style: TextStyle(
                                  fontSize: 12.0,
                                  fontWeight: FontWeight.w600))),
                      Expanded(
                          child: Text('Северная 242/1',
                              style: TextStyle(
                                  fontSize: 12.0,
                                  fontWeight: FontWeight.w600))),
                      Expanded(
                          child: Text('Н.В. Гоголевский',
                              style: TextStyle(
                                  fontSize: 12.0,
                                  fontWeight: FontWeight.w600))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

///Контактные лица
class CompanyContactFaces extends StatefulWidget {
  const CompanyContactFaces({Key? key}) : super(key: key);

  @override
  State<CompanyContactFaces> createState() => _CompanyContactFacesState();
}

class _CompanyContactFacesState extends State<CompanyContactFaces> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Контактные лица',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 20.0),
            IconButton(
                onPressed: () {
                  setState(() {
                    showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                              content: AddContactPerson(),
                            ));
                  });
                },
                icon: const Icon(
                  Icons.add_box_rounded,
                  color: ColorApp.myColorGreenAuth,
                ))
          ],
        ),
        Container(
          width: double.infinity,
          height: 300,
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
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              children: [
                Row(
                  children: const [
                    SizedBox(width: 10.0),
                    Expanded(
                        child: Text('Имя',
                            style: TextStyle(
                                fontSize: 12.0,
                                fontWeight: FontWeight.w500,
                                color: ColorApp.myColorGray))),
                    Expanded(
                        child: Text('Телефон',
                            style: TextStyle(
                                fontSize: 12.0,
                                fontWeight: FontWeight.w500,
                                color: ColorApp.myColorGray))),
                  ],
                ),
                const SizedBox(height: 20.0),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey, width: 1),
                    borderRadius: BorderRadius.circular(5.0),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 3.0),
                      Expanded(
                          child: Row(
                        children: [
                          Container(
                            width: 25,
                            height: 25,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(25),
                              color: const Color(0xff6F00A4),
                            ),
                          ),
                          const SizedBox(width: 3.0),
                          const Text('И. В. Васильев',
                              style: TextStyle(
                                  fontSize: 12.0, fontWeight: FontWeight.w600)),
                        ],
                      )),
                      const Expanded(
                          child: Text('+7 (918) 123 45 67',
                              style: TextStyle(
                                  fontSize: 12.0,
                                  fontWeight: FontWeight.w600))),
                    ],
                  ),
                ),
                const SizedBox(height: 10.0),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey, width: 1),
                    borderRadius: BorderRadius.circular(5.0),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 3.0),
                      Expanded(
                          child: Row(
                        children: [
                          Container(
                            width: 25,
                            height: 25,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(25),
                              color: const Color(0xff6F00A4),
                            ),
                          ),
                          const SizedBox(width: 3.0),
                          const Text('И. В. Васильев',
                              style: TextStyle(
                                  fontSize: 12.0, fontWeight: FontWeight.w600)),
                        ],
                      )),
                      const Expanded(
                          child: Text('+7 (918) 123 45 67',
                              style: TextStyle(
                                  fontSize: 12.0,
                                  fontWeight: FontWeight.w600))),
                    ],
                  ),
                ),
                const SizedBox(height: 10.0),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey, width: 1),
                    borderRadius: BorderRadius.circular(5.0),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 3.0),
                      Expanded(
                          child: Row(
                        children: [
                          Container(
                            width: 25,
                            height: 25,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(25),
                              color: const Color(0xff6F00A4),
                            ),
                          ),
                          const SizedBox(width: 3.0),
                          const Text('И. В. Васильев',
                              style: TextStyle(
                                  fontSize: 12.0, fontWeight: FontWeight.w600)),
                        ],
                      )),
                      const Expanded(
                          child: Text('+7 (918) 123 45 67',
                              style: TextStyle(
                                  fontSize: 12.0,
                                  fontWeight: FontWeight.w600))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
