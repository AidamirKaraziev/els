import 'dart:convert';
import 'package:els/helper/api_config.dart';
import 'package:els/screns/companies/widgets/company_account_freeze.dart';
import 'package:flutter/material.dart';
import '../../../helper/class_colors.dart';
import '../../../helper/my_user.dart';
import '../../home_page/home_page.dart';
import '../../object/bloc/object_bloc.dart';
import '../widgets/AddAccount.dart';
import '../widgets/AddObjectSelectedCompany.dart';
import '../widgets/ContactFaces.dart';
import '../widgets/editing_company.dart';
import 'package:http/http.dart' as http;
import 'companies_screen.dart';
import 'companies_screen_archive.dart';
import 'company_page.dart';

/// Окно выбранной компании Архив

bool addObjectSelectedCompany = false;


class CompanyPageArchive extends StatefulWidget {
  const CompanyPageArchive({Key? key}) : super(key: key);

  @override
  State<CompanyPageArchive> createState() => _CompanyPageArchiveState();
}




/// Разморозка компании =================
defrostingCompany(int userId) async {
  await Future(() async {
    final res = await http.get(
        Uri.parse("${ApiConfig.base}/company/$userId/unzip/"),
        headers: {
          "Content-Type": "application/json; charset=utf-8",
          'Authorization': 'Bearer ${IntTest.token}',
        });
    // var vova = jsonDecode(utf8.decode(res.bodyBytes));
    // listSelectedCompany = vova;
  });
}
/// =====================================

class _CompanyPageArchiveState extends State<CompanyPageArchive> {

  @override
  void initState() {
    print(listSelectedCompanyArchive['data']);
    getContactPersonCompany();
    getAccountCompany(IntTest.pressHover);
    getListObjectCompany(IntTest.pressHover);
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final viewCompanyListArchive = listSelectedCompany['data'];
    return StreamBuilder(
      stream: myStream.stream,
      builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
        return Scaffold(
          backgroundColor: ColorApp.myColorTransparent,
          body: SingleChildScrollView(
            child: Container(
              color: ColorApp.myColorTransparent,
              child: Column(
                children: [
                  ///Header =====
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal:ColorApp.kPadding),
                    color: Colors.white,
                    height: 70,
                    width: double.infinity,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        /// Кнопка Назад
                          Row(
                            children: [
                              Container(
                                width: 32.0,
                                height: 32.0,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(5.0),
                                  border: Border.all(color: ColorApp.myColorGrayBorder,width: 1),
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
                                        IntTest.indexScreens = 17;
                                        getCompanyArchive();
                                        myStream.add(IntTest.indexScreens);
                                      });
                                    },
                                    icon: const Icon(
                                      Icons.arrow_back_ios_new_rounded,
                                      color: Colors.black,size: 13.0,
                                    )),
                              ),
                              const SizedBox(width: 30.0),
                            ],
                          ),
                        ///Text
                        Text('Компания',
                            style: TextStyle(
                                fontSize: size.width > 350
                                    ? 25.0
                                    : 18.0,
                                fontWeight: size.width > 350
                                    ? FontWeight.w700
                                    : FontWeight.w500)),
                        const Spacer(),
                        ///Колокольчик
                        if (size.width > 400)
                          Badge(
                            alignment:
                            const AlignmentDirectional(21, 4),
                            backgroundColor: ColorApp.myColorRed,
                            isLabelVisible: IntTest.badgeCount > 0
                                ? true
                                : false,
                            label: IntTest.badgeCount < 1
                                ? const SizedBox.shrink()
                                : Text(
                                IntTest.badgeCount.toString(),
                                style: const TextStyle(
                                    fontSize: 12.0,
                                    color:
                                    ColorApp.myColorWhite,
                                    fontWeight:
                                    FontWeight.w500)),
                            child: IconButton(
                              onPressed: () {},
                              icon: const Icon(
                                  Icons
                                      .notifications_none_outlined,
                                  size: 25.0),
                            ),
                          ),
                        SizedBox(width: size.width > 500 ? 40.0 : 10.0),
                        ///Аватар Юзера
                        const MyUser(),
                      ],
                    ),
                  ),
                  /// Body
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        ///кнопки
                        const Row(
                          children: [
                            /// Информация
                            Text(
                              'Информация',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20.0),
                        Column(
                          children: [
                            /// Лого и Инфа
                            Row(
                              children: [
                                /// Лого
                                  Stack(
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(5.0),
                                          color: Colors.grey[400],
                                          boxShadow: const [
                                            BoxShadow(
                                              color: Colors.grey,
                                              blurRadius: 5,
                                            ),
                                          ],
                                        ),
                                        height: 250,
                                        width: 250,
                                        child: Padding(
                                          padding: const EdgeInsets.all(50.0),
                                          child: CircleAvatar(
                                            backgroundColor: Colors.grey.shade200,
                                            backgroundImage: const AssetImage('assets/comp.jpeg'),
                                            foregroundImage: NetworkImage('http://${viewCompanyListArchive['photo']}'),
                                          ),
                                        ),
                                      ),
                                      Positioned(

                                        left: 30.0,
                                        right: 30.0,
                                        bottom: 10.0,
                                        child: ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                                shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(5.0)),
                                                backgroundColor: ColorApp.myColorBlue),
                                            onPressed: () async {
                                              await defrostingCompany(IntTest.pressHover);
                                              getCompanyArchive();
                                              MyObjectBloc().add(ObjectGetEvent());
                                              IntTest.indexScreens = 4;
                                              // listSelectedCompanyArchive['data']['is_actual'] = true;
                                              myStream.add(IntTest.indexScreens);
                                              setState(() {});
                                            },
                                            child: const Text('Разморозить',style: TextStyle(color: Colors.white),)),
                                      )
                                    ],
                                  ),
                                const SizedBox(width: 20.0),

                                /// Инфа
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(5.0),
                                      color: Colors.grey[400],
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Colors.grey,
                                          blurRadius: 5,
                                        ),
                                      ],
                                    ),
                                    height: size.width > 600 ? 250 : null,
                                    child: Padding(
                                      padding: const EdgeInsets.all(30.0),
                                      child:
                                      Row(
                                        children: [
                                          /// Название Адрес Директор
                                          Expanded(
                                            child: Column(
                                              mainAxisAlignment:
                                              MainAxisAlignment
                                                  .spaceAround,
                                              children: [
                                                /// Название
                                                Row(
                                                  children: [
                                                    const Icon(Icons.business,
                                                        color: ColorApp
                                                            .myColorGreenWhite),
                                                    const SizedBox(
                                                        width: 20.0),
                                                    Column(
                                                      crossAxisAlignment:
                                                      CrossAxisAlignment
                                                          .start,
                                                      children: [
                                                        const Text('Название',
                                                            style: TextStyle(
                                                                fontSize:
                                                                12)),
                                                        Text( viewCompanyListArchive['name'] == null ? '' :
                                                            '${viewCompanyListArchive['name']}',
                                                            style: const TextStyle(
                                                                fontSize: 15,
                                                                fontWeight:
                                                                FontWeight
                                                                    .w600)),
                                                      ],
                                                    ),
                                                  ],
                                                ),

                                                /// Адрес
                                                Row(
                                                  children: [
                                                    const Icon(
                                                        Icons
                                                            .location_on_outlined,
                                                        color: ColorApp
                                                            .myColorGreenWhite),
                                                    const SizedBox(
                                                        width: 20.0),
                                                    Column(
                                                      crossAxisAlignment:
                                                      CrossAxisAlignment
                                                          .start,
                                                      children: [
                                                        const Text('Адрес',
                                                            style: TextStyle(
                                                                fontSize:
                                                                12)),
                                                        Text(viewCompanyListArchive['cont_address'] == null ? '' :
                                                            '${viewCompanyListArchive['cont_address']}',
                                                            style: const TextStyle(
                                                                fontSize: 15,
                                                                fontWeight:
                                                                FontWeight
                                                                    .w600)),
                                                      ],
                                                    ),
                                                  ],
                                                ),

                                                /// Директор
                                                Row(
                                                  children: [
                                                    const Icon(
                                                        Icons.person_outline,
                                                        color: ColorApp
                                                            .myColorGreenWhite),
                                                    const SizedBox(
                                                        width: 20.0),
                                                    Column(
                                                      crossAxisAlignment:
                                                      CrossAxisAlignment
                                                          .start,
                                                      children: [
                                                        const Text('Директор',
                                                            style: TextStyle(
                                                                fontSize:
                                                                12)),
                                                        Text(viewCompanyListArchive['director_name'] == null ? '' :
                                                            '${viewCompanyListArchive['director_name']}',
                                                            style: const TextStyle(
                                                                fontSize: 15,
                                                                fontWeight:
                                                                FontWeight
                                                                    .w600)),
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
                                              mainAxisAlignment:
                                              MainAxisAlignment
                                                  .spaceAround,
                                              children: [
                                                ///Сайт
                                                Row(
                                                  children: [
                                                    const Icon(Icons.language,
                                                        color: ColorApp
                                                            .myColorGreenWhite),
                                                    const SizedBox(
                                                        width: 20.0),
                                                    Column(
                                                      crossAxisAlignment:
                                                      CrossAxisAlignment
                                                          .start,
                                                      children: [
                                                        const Text('Сайт',
                                                            style: TextStyle(
                                                                fontSize:
                                                                12)),
                                                        Text(viewCompanyListArchive['site'] == null ? '' :
                                                            '${viewCompanyListArchive['site']}',
                                                            style: const TextStyle(
                                                                fontSize: 15,
                                                                fontWeight:
                                                                FontWeight
                                                                    .w600)),
                                                      ],
                                                    ),
                                                  ],
                                                ),

                                                ///Телефон
                                                Row(
                                                  children: [
                                                    const Icon(
                                                        Icons.phone_outlined,
                                                        color: ColorApp
                                                            .myColorGreenWhite),
                                                    const SizedBox(
                                                        width: 20.0),
                                                    Column(
                                                      crossAxisAlignment:
                                                      CrossAxisAlignment
                                                          .start,
                                                      children: [
                                                        const Text('Телефон',
                                                            style: TextStyle(
                                                                fontSize:
                                                                12)),
                                                        Text(viewCompanyListArchive['cont_phone'] == null ? '' :
                                                            '+7${viewCompanyListArchive['cont_phone']}',
                                                            style: const TextStyle(
                                                                fontSize: 15,
                                                                fontWeight:
                                                                FontWeight
                                                                    .w600)),
                                                      ],
                                                    ),
                                                  ],
                                                ),

                                                ///Эл.почта
                                                Row(
                                                  children: [
                                                    const Icon(
                                                        Icons.email_outlined,
                                                        color: ColorApp
                                                            .myColorGreenWhite),
                                                    const SizedBox(
                                                        width: 20.0),
                                                    Column(
                                                      crossAxisAlignment:
                                                      CrossAxisAlignment
                                                          .start,
                                                      children: [
                                                        const Text('Эл.почта',
                                                            style: TextStyle(
                                                                fontSize:
                                                                12)),
                                                        Text(viewCompanyListArchive['email'] == null ? '' :
                                                            '${viewCompanyListArchive['email']}',
                                                            style: const TextStyle(
                                                                fontSize: 15,
                                                                fontWeight:
                                                                FontWeight
                                                                    .w600)),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20.0),
                            /// Аккаунты Объекты Контактные лица
                            Row(
                              children:  [
                                /// Аккаунты
                                Expanded(
                                  flex: 3,
                                  child: Column(
                                    children: [
                                      /// Текст Аккаунты и иконка добавить
                                      const Row(
                                        children: [
                                          /// Текст Аккаунты
                                          Text(
                                            'Аккаунты',
                                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                          ),
                                          SizedBox(width: 20.0),

                                        ],
                                      ),
                                      Container(
                                        width: double.infinity,
                                        height: 300,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(5.0),
                                          color: Colors.grey[400],
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
                                              /// Имя, Должность
                                              if (listSelectedAccountCompany.isNotEmpty)
                                                const Row(
                                                  children: [
                                                    SizedBox(width: 10.0),
                                                    Expanded(
                                                        flex: 3,
                                                        child: Text('Имя',
                                                            style: TextStyle(
                                                                fontSize: 10.0,
                                                                fontWeight: FontWeight.w500,
                                                                color: ColorApp.myColorGray))),
                                                    SizedBox(width: 10.0),
                                                    Expanded(
                                                        flex: 2,
                                                        child: Text('Телефон',
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
                                                    SizedBox(width: 10.0),
                                                  ],
                                                ),
                                              const SizedBox(height: 10.0),
                                              listSelectedAccountCompany.isNotEmpty
                                                  ? Expanded(
                                                child: ListView.builder(
                                                    itemCount: listSelectedAccountCompany.length,
                                                    itemBuilder: (context, index) {
                                                      final listAddAccount = listSelectedAccountCompany[index];
                                                      return Padding(
                                                        padding: const EdgeInsets.only(bottom: 10.0),
                                                        child: Card(
                                                            key: ValueKey(listSelectedAccountCompany[index]),
                                                            child: InkWell(
                                                              // onTap: () {
                                                              //   setState(() {
                                                              //     showDialog(
                                                              //         context: context,
                                                              //         builder: (context) => const AlertDialog(
                                                              //           content: ViewAccount(),
                                                              //         ));
                                                              //   });
                                                              // },
                                                                child: Container(
                                                                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                                                                  decoration: BoxDecoration(
                                                                      color: Colors.grey.shade400,
                                                                      border: Border.all(
                                                                          color: Colors.grey, width: 1),
                                                                      borderRadius: BorderRadius.circular(5.0)),
                                                                  child: Row(
                                                                    children: [
                                                                      const SizedBox(width: 10.0),
                                                                      /// Имя
                                                                      Expanded(
                                                                        flex: 3,
                                                                        child: Text(
                                                                            listAddAccount['name'],
                                                                            style: const TextStyle(
                                                                                fontSize: 12.0,
                                                                                fontWeight: FontWeight.w600)),
                                                                      ),
                                                                      /// Телефон
                                                                      Expanded(
                                                                        flex: 2,
                                                                        child: Text('+7${listAddAccount['contact_phone']}',
                                                                            style: const TextStyle(
                                                                                fontSize: 12.0,
                                                                                fontWeight: FontWeight.w600)),
                                                                      ),
                                                                      /// Должность
                                                                      Expanded(
                                                                        child: Text(
                                                                            listAddAccount['role_id']['name'],
                                                                            style: const TextStyle(
                                                                                fontSize: 12.0,
                                                                                fontWeight:
                                                                                FontWeight.w600)),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                ))),
                                                      );
                                                    }),
                                              )
                                                  : const Center(child: Text('Список пустой')),
                                              // CircularProgressIndicator(color: ColorApp.myColorGreen)),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 20.0),

                                ///Объекты
                                Expanded(
                                  flex: 3,
                                  child:
                                  Container(
                                    width: double.infinity,
                                    height: 300,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(5.0),
                                      color: Colors.grey[400],
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
                                          if(listSelectedObjectCompany.isNotEmpty)
                                            const Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
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
                                          listSelectedObjectCompany.isNotEmpty
                                              ? Expanded(child: ListView.builder(
                                              itemExtent: 70.0,
                                              itemCount: listSelectedObjectCompany.length,
                                              itemBuilder: (context, index) {
                                                final listAddSelectedObjectCompany = listSelectedObjectCompany[index];
                                                return Padding(
                                                  padding: const EdgeInsets.only(bottom: 5.0),
                                                  child: Card(
                                                    key: ValueKey(listSelectedObjectCompany[index]),
                                                    child: InkWell(
                                                      onTap: () async {
                                                        IntTest.pressHover = listAddSelectedObjectCompany['id'];
                                                        // await getListObjectInfo(IntTest.pressHover);
                                                        setState(() {
                                                          showDialog(
                                                              context: context,
                                                              builder: (context) => const AlertDialog(
                                                                content: ViewSelectedObject(),
                                                              ));
                                                        });
                                                      },
                                                      child: Container(
                                                        padding: const EdgeInsets.symmetric(
                                                            vertical: 10.0),
                                                        decoration: BoxDecoration(
                                                          color: Colors.grey[400],
                                                          border: Border.all(color: Colors.grey, width: 1),
                                                          borderRadius: BorderRadius.circular(5.0),
                                                        ),

                                                        child: Row(
                                                          mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .spaceBetween,
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
                                ),
                                const SizedBox(width: 20.0),

                                ///Контактные лица
                                Expanded(
                                  flex: 2,
                                  child: Container(
                                    width: double.infinity,
                                    height: 300,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(5.0),
                                      color: Colors.grey[400],
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
                                          if (listSelectedContactPersonCompany.isNotEmpty)
                                          /// Текст Имя,Телефон
                                            const Row(children: [
                                              SizedBox(width: 10.0),

                                              /// Текст Имя
                                              Expanded(
                                                  child: Text('Имя',
                                                      style: TextStyle(
                                                          fontSize: 12.0,
                                                          fontWeight: FontWeight.w500,
                                                          color: ColorApp.myColorGray))),

                                              /// Текст Телефон
                                              Expanded(
                                                  child: Text('Телефон',
                                                      style: TextStyle(
                                                          fontSize: 12.0,
                                                          fontWeight: FontWeight.w500,
                                                          color: ColorApp.myColorGray))),

                                              /// Текст Должность
                                              Expanded(
                                                  child: Text('Должность',
                                                      style: TextStyle(
                                                          fontSize: 12.0,
                                                          fontWeight: FontWeight.w500,
                                                          color: ColorApp.myColorGray))),

                                            ]),
                                          const SizedBox(height: 10.0),
                                          listSelectedContactPersonCompany.isNotEmpty
                                              ? Expanded(
                                            child: ListView.builder(
                                              itemCount: listSelectedContactPersonCompany.length,
                                              itemBuilder: (context, index) {
                                                final listTest = listSelectedContactPersonCompany[index];
                                                return Padding(
                                                  padding: const EdgeInsets.only(bottom: 10.0),
                                                  child: Card(
                                                      key: ValueKey(listSelectedContactPersonCompany[index]),
                                                      child: InkWell(
                                                          onTap: () async {
                                                            await getSelectContactFacesCompany(listSelectedContactPersonCompany[index]['id']);
                                                            setState(() {
                                                              showDialog(
                                                                  context: context,
                                                                  builder: (context) =>
                                                                  const AlertDialog(
                                                                      content: ViewContactPerson()));
                                                            });
                                                          },
                                                          child: Container(
                                                            padding: const EdgeInsets.all(10.0),
                                                            decoration: BoxDecoration(
                                                              borderRadius:
                                                              BorderRadius.circular(5.0),
                                                              border: Border.all(
                                                                  color: Colors.grey, width: 1),
                                                            ),
                                                            child: Row(
                                                              children: [
                                                                CircleAvatar(
                                                                    minRadius: 25.0,
                                                                    foregroundImage: NetworkImage('http://${listTest['photo']}'),
                                                                    backgroundImage: const AssetImage('assets/user.png')
                                                                ),
                                                                const SizedBox(width: 20.0),
                                                                Column(
                                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                                  children: [
                                                                    Text('${listTest['name']}'),
                                                                    const SizedBox(height: 3.0),
                                                                    Text('+7${listTest['phone']}'),
                                                                    const SizedBox(height: 3.0),
                                                                    const Text('Должность'),
                                                                  ],),
                                                              ],
                                                            ),
                                                          ))),
                                                );
                                              },
                                            ),
                                          )
                                              : const Center(child: Text('Список пустой')),
                                          // CircularProgressIndicator(color: ColorApp.myColorGreen)),

                                        ],
                                      ),
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
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}