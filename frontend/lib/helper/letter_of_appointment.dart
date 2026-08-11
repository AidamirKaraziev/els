import 'package:flutter/material.dart';
import '../screns/object/view/object_screen.dart';
import 'class_colors.dart';

/// Письмо о назначении

class LetterOfAppointment extends StatelessWidget {
  const LetterOfAppointment({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 690.0,
      height: 750.0,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Приказ и кнопка удалить
            Row(
              children: [
                const Spacer(),
                /// Приказ
                Text('ПРИКАЗ № ${listSelectedObject['data']['id']}', style: const TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                /// кнопка закрыть
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
            Row(
              children: const [
                Spacer(),
                Text(
                  'г. Краснодар',
                  textAlign: TextAlign.center,
                  style:
                  TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                ),
                Spacer(),
                Text(
                  '«25» августа 2021 г.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
                ),/// <<<< Решить по дате
                Spacer(),
              ],
            ),
            const SizedBox(height: 30.0),
            /// О назначении
            const Text(
              '«О назначении ответственных лиц за техническое обслуживание и исправное состояние»',
              textAlign: TextAlign.center,
              style:
              TextStyle(fontSize: 20.0, fontWeight: FontWeight.bold,),
            ),
            const SizedBox(height: 20.0),
            /// В соответствии с Правилами
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'В соответствии с Правилами организации безопасного использования и содержания лифтов, подъемных платформ для инвалидов, пассажирских конвейеров (движущихся пешеходных дорожек) и эскалаторов, за исключением эскалаторов в метрополитенах, утвержденных постановлением Правительства Российской Федерации от 24 июня 2017 г. № 743, национальными стандартами, ПТЭЭП, ПОТЭУ и надлежащей организации работ по техническому обслуживанию и ремонту:',
                ),
                const SizedBox(height: 10.0),
                Row(
                  children: [
                    const Text('• оборудование (см. приложение №1), установленных по адресу: '),
                    Text('${listSelectedObject['data']['address']}', style: const TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 10.0),
                Row(
                  children: [
                    const Text('• Заказчик: '),
                    Text('${listSelectedObject['data']['company_id']['name']}', style: const TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold)),
                  ],
                ),
                // const SizedBox(height: 10.0),
                // Text('• ',),
              ],
            ),
            const SizedBox(height: 20.0),
            /// ПРИКАЗЫВАЮ
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children:  [
                const Text(
                  'ПРИКАЗЫВАЮ:',
                  textAlign: TextAlign.center,
                  style:
                  TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold,),
                ),
                const SizedBox(height: 10.0),
                RichText(
                  text:  TextSpan(
                    text: '• Назначить начальника сервисного',
                    style: const TextStyle(fontSize: 16.0),
                    children: <TextSpan>[
                      TextSpan(text: ' ${listSelectedObject['data']['division_id']['title']} ', style: const TextStyle(fontWeight: FontWeight.bold,fontSize: 14.0)),
                      TextSpan(text: ' ${listSelectedObject['data']['foreman_id']['name']}, ', style: const TextStyle(fontWeight: FontWeight.bold,fontSize: 14.0)),
                      const TextSpan(text: ' группа по электробезопасности IV до 1000 В, специалистом, ответственным за организацию выполнения работ по техническому обслуживанию оборудования, установленных по адресу '),
                      TextSpan(text: ' ${listSelectedObject['data']['address']}, ', style: const TextStyle(fontWeight: FontWeight.bold,fontSize: 14.0)),
                      const TextSpan(text: ' в соответствии с п.17 подпунктом и) «Правил организации безопасного использования и содержания лифтов, подъемных платформ для инвалидов, пассажирских конвейеров (движущихся пешеходных дорожек) и эскалаторов, за исключением эскалаторов в метрополитенах», утвержденных постановлением Правительства Российской Федерации от 24 июня 2017 г. № 743 и закрепить за ним оборудование этого участка.'),

                    ],
                  ),
                ), /// Назначить начальника сервисного
                const SizedBox(height: 10.0),
                RichText(
                  text:  TextSpan(
                    text: '• Ответственность за исправное состояние оборудования, установленных по адресу:',
                    style: const TextStyle(fontSize: 16.0),
                    children: <TextSpan>[
                      TextSpan(text: ' ${listSelectedObject['data']['address']} ', style: const TextStyle(fontWeight: FontWeight.bold,fontSize: 14.0)),
                      const TextSpan(text: ' и возложить на электромеханика участка '),
                      TextSpan(text: ' ${listSelectedObject['data']['mechanic_id']['name']}, ', style: const TextStyle(fontWeight: FontWeight.bold,fontSize: 14.0)),
                    ],
                  ),
                ), /// Ответственность за исправное состояние оборудования
                const SizedBox(height: 10.0),
                RichText(
                  text:  TextSpan(
                    text: '• Право единоличного осмотра электроустановки до 1000 В:',
                    style: const TextStyle(fontSize: 16.0),
                    children: <TextSpan>[
                      const TextSpan(text: ' становленного по адресу '),
                      TextSpan(text: ' ${listSelectedObject['data']['address']} ', style: const TextStyle(fontWeight: FontWeight.bold,fontSize: 14.0)),
                      const TextSpan(text: ' предоставить электромеханику '),
                      TextSpan(text: ' ${listSelectedObject['data']['mechanic_id']['name']}, ', style: const TextStyle(fontWeight: FontWeight.bold,fontSize: 14.0)),
                      const TextSpan(text: ' группа по электробезопасности III до 1000 В. '),
                    ],
                  ),
                ), /// Право единоличного осмотра электроустановки до 1000 В
                const SizedBox(height: 10.0),
                const Text('• К исполнению настоящего приказа приступить с 01.09.2021 года.',),
                const SizedBox(height: 10.0),
                const Text('• Контроль за исполнением приказа оставляю за собой.',),
              ],
            ),
            const SizedBox(height: 60.0),
            /// Кнопки Печать и Закрыть
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                /// Кнопка Печать
                ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: ColorApp.myColorGreen),
                    onPressed: (){
                      Navigator.pop(context);
                    }, child: Row(
                      children: const [
                        Icon(Icons.print_outlined),
                        SizedBox(width: 10.0),
                        Text('Печать'),
                      ],
                    )),
                const SizedBox(width: 40.0),
                /// Кнопка Закрыть
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
            const SizedBox(height: 20.0),
          ],
        ),
      ),
    );
  }
}
