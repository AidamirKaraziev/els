import 'package:flutter/material.dart';
import '../../../helper/class_colors.dart';
import '../../home_page/home_page.dart';
import '../view/companies_screen.dart';
import '../view/company_page.dart';
import 'add_accounts.dart';

/// Класс для отображения списка акаунтов компаний

class DisplayAccountCompany extends StatefulWidget {
  const DisplayAccountCompany({Key? key}) : super(key: key);

  @override
  State<DisplayAccountCompany> createState() => _DisplayAccountCompanyState();
}

class _DisplayAccountCompanyState extends State<DisplayAccountCompany> {
  @override
  void initState() {
    getAccountCompany(IntTest.pressHover);
    myStream.add(IntTest.indexScreens);
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: myStream.stream,
      builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
        return Column(
          children: [
            /// Текст Аккаунты и иконка добавить
            Row(
              children: [
                /// Текст Аккаунты
                const Text(
                  'Аккаунты',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 20.0),

                /// Иконка добавить
                IconButton(
                    onPressed: listSelectedCompany['data']['is_actual'] == false ? null : () {
                      setState(() {
                        showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                                  content: AddAccounts(),
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
                color: listSelectedCompany['data']['is_actual'] == true ? ColorApp.myColorWhite : Colors.grey[400],
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
                      Row(
                        children: const [
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
                                                color: listSelectedCompany['data']['is_actual'] == true ? Colors.white : Colors.grey.shade400,
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
        );
      },
    );
  }
}
