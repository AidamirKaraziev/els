import 'package:flutter/material.dart';

import 'class_colors.dart';

class DefectiveAct extends StatelessWidget {
  const DefectiveAct({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 1000,
      height: 800,
      child: SingleChildScrollView(
        child: Column(
          children: [
            /// Кнопка закрыть
            Row(
              children: [
                const Spacer(),
                /// кнопка закрыть
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
            const SizedBox(height: 10.0),
            /// Logo и о компании
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: 400,
                  height: 220,
                  child: Center(child: Image.asset('assets/plk_logo.png',fit: BoxFit.cover)),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: const [
                    Text('ООО "Профессиональная лифтовая компания"'),
                    Text('ИНН 2308258486 КПП 230801001 ОРГН 1182375068908'),
                    Text('350049, Краснодарский край,'),
                    Text('г. Краснодар, ул Им. Котовского, д. 42, офис 134'),
                    Text('e-mail: plk_krd@mail.ru'),
                    Text('Техническое обслуживание лифтов и эскалаторов'),
                  ],
                ),
              ],
            ),
            /// Divider
            Column(
              children: const [
                SizedBox(height: 20.0),
                Divider(color: ColorApp.myColorGray),
                SizedBox(height: 20.0),
              ],
            ),
            const SizedBox(height: 10.0),
            /// Дата и Кому
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                const Text('От  15.06.2025'),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Кому: Главному инженеру'),
                    Text('ЗАО "МИРИОН"'),
                    Text('Иванову П.В'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 40.0),
            const Text('ДЕФЕКТНАЯ  ВЕДОМОСТЬ', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18.0)),
            const SizedBox(height: 10.0),
            const Text('В процессе эксплуатации перечисленного оборудования обнаружены следущие дефекты: ', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16.0)),
            const SizedBox(height: 40.0),
            /// Таблица дефектов
            Table(
              border: TableBorder.all(color: Colors.black),
              children: const [
                TableRow(
                  children: [
                    Center(child: Text('Наиминование\nоборудования', style: TextStyle(fontWeight: FontWeight.bold))),
                    Center(child: Text('Обнаруженные дефекты', style: TextStyle(fontWeight: FontWeight.bold))),
                    Center(child: Text('Для устранения дефектов\nнеобходимо произвести\nработы', style: TextStyle(fontWeight: FontWeight.bold))),
                    Center(child: Text('Примечание', style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                ),
                TableRow(
                  children: [
                    Center(child: Text('1', style: TextStyle(fontWeight: FontWeight.bold))),
                    Center(child: Text('2', style: TextStyle(fontWeight: FontWeight.bold))),
                    Center(child: Text('3', style: TextStyle(fontWeight: FontWeight.bold))),
                    Center(child: Text('4', style: TextStyle(fontWeight: FontWeight.bold))),
                  ],
                ),
                TableRow(
                  children: [
                    Text("12th Grade"),
                    Text("High School"),
                    Text("CBSE"),
                    Text("CBSE"),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20.0),
            /// Фото дефектов
            Row(children: [
              Container(
                  width: 300,
                  height: 300,
                  color: Colors.red,
                  child: Image.asset('assets/liftyTest.jpg',fit: BoxFit.cover)),
              const SizedBox(width: 20.0),
              Container(
                  width: 300,
                  height: 300,
                  color: Colors.grey,
                  child: Image.asset('assets/liftTest2.webp',fit: BoxFit.cover)),
              const SizedBox(width: 20.0),
              Container(
                  width: 300,
                  height: 300,
                  color: Colors.yellow,
                  child: Image.asset('assets/liftTest3.jpeg',fit: BoxFit.cover)),
            ]),
            const SizedBox(height: 40.0),
            /// Подписи представителя
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  children: const [
                    Text('Представитель ООО "ПЛК"', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18.0)),
                    SizedBox(height: 20.0),
                    Text('Начальник сервисного участка', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16.0)),
                  ],
                ),
                const Text('__________________________________________________'),
              ],
            ),
            const SizedBox(height: 60.0),
            /// Кнопки Печать и Закрыть
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                /// Печать
                ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: ColorApp.myColorGreen,
                        padding: const EdgeInsets.symmetric(vertical: 20.0,horizontal: 80)),
                    onPressed: (){
                      Navigator.pop(context);
                    }, child: const Text('Печать',style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),)),
                /// Закрыть
                ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[200],
                        padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 80)),
                    onPressed: (){
                      Navigator.pop(context);
                    }, child: const Text('Закрыть', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),)),
              ],
            ),
            const SizedBox(height: 40.0),
          ],
        ),
      ),
    );
  }
}
