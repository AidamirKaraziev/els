import 'dart:convert';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import '../../../helper/class_colors.dart';
import '../../home_page/home_page.dart';
import '../widgets/add_employee_class.dart';
import '../widgets/employee_acount_freeze.dart';
import 'package:http/http.dart' as http;



/// Замозморозка юзера =============
freezingUser(int userId) async {
  await Future(() async {
    final res = await http.get(
        Uri.parse("http://${IntTest.myIp}/api/v1/cp/admin/$userId/archive/"),
        headers: {
          "Content-Type": "application/json; charset=utf-8",
          'Authorization': 'Bearer ${IntTest.token}',
        });
    var vova = jsonDecode(utf8.decode(res.bodyBytes));
    listSelectedEmployee = vova;
    print(IntTest.pressHover);
  });
}
/// ================================

/// Разморозка юзера =================
defrostingUser(int userId) async {
  await Future(() async {
    final res = await http.get(
        Uri.parse("http://${IntTest.myIp}/api/v1/cp/admin/$userId/unzip/"),
        headers: {
          "Content-Type": "application/json; charset=utf-8",
          'Authorization': 'Bearer ${IntTest.token}',
        });
    var vova = jsonDecode(utf8.decode(res.bodyBytes));
    listSelectedEmployee = vova;
    print(IntTest.pressHover);
  });
}
/// ==================================

/// Окно выбранного сотрудника

class OpenViewUser extends StatefulWidget {
  const OpenViewUser({Key? key}) : super(key: key);

  @override
  State<OpenViewUser> createState() => _OpenViewUserState();
}

class _OpenViewUserState extends State<OpenViewUser> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: pointsMapController.stream,
      builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
        return Scaffold(
          backgroundColor: ColorApp.myColorGrayShadow,
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  /// Photo & Info
                  Row(
                    children: [
                      ///Photo
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Профиль',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 20.0),
                          if (listSelectedEmployee['data']['is_actual'] == true)
                            Container(
                            height: 250,
                            width: 250,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(5.0),
                              color: ColorApp.myColorWhite,
                              boxShadow: const [
                                BoxShadow(
                                  color: ColorApp.myColorAvatar,
                                  blurRadius: 5,
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // if(state is UserGetState)
                                Badge(
                                    smallSize: 30.0,
                                    largeSize: 50.0,
                                    alignment: const AlignmentDirectional(100, 90),
                                    backgroundColor: ColorApp.myColorGreen,
                                    label: IconButton(
                                        onPressed: () {},
                                        icon: const Icon(
                                          Icons.camera_alt_outlined,
                                          color: ColorApp.myColorWhite,
                                        )),
                                    child: CircleAvatar(
                                      radius: 70.0,
                                      backgroundImage:
                                      const AssetImage('assets/user.png'),
                                      foregroundImage: NetworkImage(
                                          'http://${listSelectedEmployee['data']['photo']}'),
                                    )),
                                const SizedBox(height: 10.0),
                                  Center(
                                    child: Text(listSelectedEmployee['data']['name'],
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                            fontSize: 16.0,
                                            fontWeight: FontWeight.w600)),
                                  ),
                                const SizedBox(height: 10.0),

                                ///Кнопка Редактировать и Заморозить
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    /// Редактировать
                                    OutlinedButton(
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 20.0, vertical: 10.0),
                                          side: BorderSide(
                                              color: Colors.grey.shade400,
                                              width: 1.0),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                            BorderRadius.circular(20.0),
                                          ),
                                        ),
                                        onPressed: () async {
                                          await defrostingUser(IntTest.pressHover);
                                          pointsMapController.add(IntTest.indexScreens);
                                        },
                                        child: Text('Редактировать',
                                            style: TextStyle(
                                                fontSize: 10.0,
                                                color: Colors.grey.shade400))),
                                    const SizedBox(width: 10.0),

                                    /// Заморозить
                                    IconButton(
                                        onPressed: () {
                                          setState(() {
                                            showDialog(
                                                context: context,
                                                builder: (context) =>
                                                const AlertDialog(
                                                  content:
                                                  EmployeeAccountFreeze(),
                                                ));
                                          });
                                        },
                                        icon: const Icon(Icons.ac_unit_outlined,
                                            color: ColorApp.myColorAvatar)),
                                  ],
                                ),
                              ],
                            ),
                          )
                          else Stack(
                            children: [
                              Container(
                                height: 250,
                                width: 250,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(5.0),
                                  color: Colors.grey[400],
                                  boxShadow: const [
                                    BoxShadow(
                                      color: ColorApp.myColorAvatar,
                                      blurRadius: 5,
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Badge(
                                        smallSize: 30.0,
                                        largeSize: 50.0,
                                        alignment: const AlignmentDirectional(100, 90),
                                        backgroundColor: ColorApp.myColorGray,
                                        label: const IconButton(
                                            onPressed: null,
                                            icon: Icon(
                                              Icons.camera_alt_outlined,
                                              color: ColorApp.myColorGrayShadow,
                                            )),
                                        child: CircleAvatar(
                                          radius: 70.0,
                                          backgroundImage:
                                          const AssetImage('assets/user.png'),
                                          foregroundImage: NetworkImage(
                                              'http://${listSelectedEmployee['data']['photo']}'),
                                          backgroundColor: ColorApp.myColorGray,
                                        )),
                                    const SizedBox(height: 10.0),
                                    Center(
                                      child: Text(listSelectedEmployee['data']['name'],
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                              fontSize: 16.0,
                                              fontWeight: FontWeight.w600)),
                                    ),
                                    const SizedBox(height: 10.0),

                                    ///Кнопка Редактировать и Заморозить
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        /// Редактировать
                                        OutlinedButton(
                                            style: OutlinedButton.styleFrom(
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 20.0, vertical: 10.0),
                                              side: BorderSide(
                                                  color: Colors.grey.shade400,
                                                  width: 1.0),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                BorderRadius.circular(20.0),
                                              ),
                                            ),
                                            onPressed: () async {},
                                            child: Text('Редактировать',
                                                style: TextStyle(
                                                    fontSize: 10.0,
                                                    color: Colors.grey.shade400))),
                                        const SizedBox(width: 10.0),

                                        /// Заморозить
                                        const IconButton(
                                            onPressed: null,
                                            icon: Icon(Icons.ac_unit_outlined,
                                                color: ColorApp.myColorAvatar)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Positioned(
                                left: 30.0,
                                right: 30.0,
                                bottom: 20.0,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: ColorApp.myColorBlue
                                  ),
                                    onPressed: () async {
                                  await defrostingUser(IntTest.pressHover);
                                  pointsMapController.add(IntTest.indexScreens);
                                }, child: const Text('Аккаунт заморожен')),
                              )
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(width: 20),

                      /// Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Информация',
                                style: TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 20.0),
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
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  ///Участок
                                  Row(
                                    children: [
                                      const Icon(Icons.location_on_outlined),
                                      const SizedBox(width: 20.0),
                                      Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        children: [
                                          const Text('Участок'),
                                          const SizedBox(height: 10.0),
                                          listSelectedEmployee['data']
                                          ['division_id'] ==
                                              null
                                              ? const Text('Не заполнено')
                                              : Text(
                                              '${listSelectedEmployee['data']['division_id']['title']}',
                                              style: const TextStyle(
                                                  fontSize: 16.0,
                                                  fontWeight: FontWeight.w600)),
                                        ],
                                      ),
                                    ],
                                  ),

                                  ///Должность
                                  Row(
                                    children: [
                                      const Icon(Icons.person_outline_outlined),
                                      const SizedBox(width: 20.0),
                                      Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        children: [
                                          const Text('Должность'),
                                          const SizedBox(height: 10.0),
                                          listSelectedEmployee['data']['role_id'] ==
                                              null
                                              ? const Text('Не заполнено')
                                              : Text(
                                              '${listSelectedEmployee['data']['role_id']['name']}',
                                              style: const TextStyle(
                                                  fontSize: 16.0,
                                                  fontWeight: FontWeight.w600)),
                                        ],
                                      ),
                                    ],
                                  ),

                                  ///Компания
                                  Row(
                                    children: [
                                      const Icon(Icons.domain),
                                      const SizedBox(width: 20.0),
                                      Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        children: [
                                          const Text('Компания'),
                                          const SizedBox(height: 10.0),
                                          listSelectedEmployee['data']
                                          ['company_id'] ==
                                              null
                                              ? const Text('Не заполнено')
                                              : Text(
                                              '${listSelectedEmployee['company_id']['name']}',
                                              style: const TextStyle(
                                                  fontSize: 16.0,
                                                  fontWeight: FontWeight.w600)),
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
                    ],
                  ),
                  const SizedBox(height: 20),
                  /// Contact
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Контакты',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 20.0),
                            Container(
                              padding: const EdgeInsets.all(20.0),
                              width: double.infinity,
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
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  ///ФИО
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('ФИО'),
                                      const SizedBox(height: 10.0),
                                      listSelectedEmployee['data']['role_id'] ==
                                          null
                                          ? const Text('Не заполнено')
                                          : Text(
                                        '${listSelectedEmployee['data']['name']}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),

                                  ///Номер телефона
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Номер телефона'),
                                      const SizedBox(height: 10.0),
                                      listSelectedEmployee['data']
                                      ['contact_phone'] ==
                                          null
                                          ? const Text('Не заполнено')
                                          : Text(
                                        '${listSelectedEmployee['data']['contact_phone']}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),

                                  ///Эл. почта
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Эл. почта'),
                                      const SizedBox(height: 10.0),
                                      listSelectedEmployee['data']['email'] == null
                                          ? const Text('Не заполнено')
                                          : Text(
                                        '${listSelectedEmployee['data']['email']}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Документы',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 20.0),
                            Container(
                              padding: const EdgeInsets.all(20.0),
                              width: double.infinity,
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
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                          children: const [
                                            Text('Документ'),
                                            SizedBox(height: 10.0),
                                            Text(
                                              'Удостоверение',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.w600),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        child: Container(
                                          constraints:
                                          const BoxConstraints(maxWidth: 300),
                                          child: GestureDetector(
                                            onTap: () async {
                                              // final imageClassification =
                                              // await ImagePickerWeb.getImageAsBytes();
                                            },
                                            child: DottedBorder(
                                              color: ColorApp.myColorGray,
                                              child: const SizedBox(
                                                height: 44.0,
                                                child: Center(
                                                  child: Icon(Icons.backup_outlined,
                                                      color: ColorApp.myColorGray),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 20.0),
                                  Row(
                                    mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                          children: const [
                                            Text('Документ'),
                                            SizedBox(height: 10.0),
                                            Text(
                                              'ЦОК',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.w600),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        child: GestureDetector(
                                          onTap: () async {
                                            // final imageClassification =
                                            // await ImagePickerWeb.getImageAsBytes();
                                          },
                                          child: DottedBorder(
                                            color: ColorApp.myColorGray,
                                            child: const SizedBox(
                                              height: 44.0,
                                              child: Center(
                                                child: Icon(Icons.backup_outlined,
                                                    color: ColorApp.myColorGray),
                                              ),
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
                      ),
                    ],
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
