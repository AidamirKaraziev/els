import 'package:flutter/material.dart';

import '../screns/object/view/object_screen.dart';
import 'class_colors.dart';

/// Акт приемки

class AcceptanceCertificate extends StatelessWidget {
  const AcceptanceCertificate({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 690.0,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// АКТ ОСМОТРА и кнопка удалить
            Row(
              children: [
                const Spacer(),
                /// Приказ
                const Text('АКТ ОСМОТРА', style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                /// кнопка удалить
                IconButton(
                    onPressed: () {
                      print(IntTest.pressHover);
                      Navigator.pop(context);
                    },
                    icon: const Icon(
                      Icons.close,
                      color: ColorApp.myColorGreenAuth,
                    )),
              ],
            ),
            const SizedBox(height: 20.0),
            /// ОСМОТР
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Text('(ЛИФТА, ЭСКАТОРА, ТРАВОЛАТОРА ГРУЗОВОГО ПОДЪЁМНИКА)',
                  style: TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 20.0),
            /// Город дата
            Row(
              children: const [
                Spacer(),
                /// Город
                Text(
                  'г. Краснодар',
                  textAlign: TextAlign.center,
                  style:
                  TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold,),
                ),
                Spacer(),
                /// дата
                Text(
                  '«25» августа 2021 г.',
                  textAlign: TextAlign.center,
                  style:
                  TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold,),
                ),
                Spacer(),
              ],
            ),
            const SizedBox(height: 30.0),
            /// В соответствии с Правилами
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children:  [
                /// Отвественное лицо компания
                Row(
                  children: const [
                    Text(
                      'Мы нижеподписавшиеся:',
                    ),
                    SizedBox(width: 20.0),
                    Text(
                      '=Компания=',
                      style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 20.0),
                /// Отвественное лицо механик
                Row(
                  children:  [
                    const Text(
                      'В лице: ',
                    ),
                    const SizedBox(width: 20.0),
                    Text(
                      '${listSelectedObject['data']['mechanic_id']['name']}',
                      style: const TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 20.0),
                /// Отвественное лицо заказчик
                Row(
                  children: [
                    const Text(
                      'Представитель заказчика  в лице ',
                    ),
                    const SizedBox(width: 20.0),
                    Text(
                      '${listSelectedObject['data']['company_id']['name']}',
                      style: const TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 20.0),
                /// После осмотра
                const Text(
                  'После осмотра и проверки технического состояния оборудования расположенного по адресу: ',
                ),
                const SizedBox(height: 10.0),
                /// Адресс
                 Text(
                  '${listSelectedObject['data']['address']}',
                  style: const TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20.0),
                const Text('Составили настоящий акт с указанием следующих замечаний:'),
                const SizedBox(height: 20.0),
                /// 1.Осмотр
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('1.Осмотр (внешний вид, целостность конструкций, полнота комплектации и прочее)'),
                    const SizedBox(height: 20.0),
                    SizedBox(
                      height: 300.0,
                      child: ListView.builder(
                          itemCount: 5,
                          itemBuilder: (context, index) {
                            return const ListTile(
                              leading: Text('• ',),
                              title: Text('dsvsdvsdvdsvsdvs'),
                            );
                          }
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20.0),
                /// '2.Описание повреждений'
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('2.Описание повреждений'),
                    const SizedBox(height: 20.0),
                    SizedBox(
                      height: 300.0,
                      child: ListView.builder(
                          itemCount: 3,
                          itemBuilder: (context, index) {
                            return const ListTile(
                              leading: Text('• ',),
                              title: Text('dsvsdvsdvdsvsdvs'),
                            );
                          }
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20.0),
                const Text('Настоящий акт составлен в 2 (двух) экземплярах.'),
                const SizedBox(height: 20.0),
                const Text('Представители:'),
                const SizedBox(height: 20.0),
                /// Сервисного подразделения
                Row(
                  children: const [
                    Text(
                      'Сервисного подразделения:',
                    ),
                    SizedBox(width: 20.0),
                    Text(
                      '=Представители=',
                      style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 20.0),
                /// Заказчика
                Row(
                  children: const [
                    Text(
                      'Заказчика:',
                    ),
                    SizedBox(width: 20.0),
                    Text(
                      '=Представители=',
                      style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 60.0),
            /// Кнопки Печать Закрыть
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                /// Печать
                ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: ColorApp.myColorGreen),
                    onPressed: (){
                      Navigator.pop(context);
                    }, child: const Row(
                  children: [
                    Icon(Icons.print_outlined),
                    SizedBox(width: 10.0),
                    Text('Печать'),
                  ],
                )),
                const SizedBox(width: 40.0),
                /// Закрыть
                ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: ColorApp.myColorGreen),
                    onPressed: (){  Navigator.pop(context);}, child: Row(
                  children: const [
                    Icon(Icons.close),
                    SizedBox(width: 10.0),
                    Text('Закрыть'),
                  ],
                )),
              ],
            ),
          ],
        ),
      ),
    );
  }
}