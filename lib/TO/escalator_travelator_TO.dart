
import 'package:flutter/material.dart';

import '../helper/button/my_button.dart';
import '../helper/class_colors.dart';
import '../screns/home_page/home_page.dart';
import '../screns/object/view/object_screen.dart';
import '../screns/schedule/schedule_page.dart';


/// TO Эскалатор Траволатор

// TOEscalatorTraveller



class TestTO extends StatefulWidget {
  const TestTO({Key? key}) : super(key: key);

  @override
  State<TestTO> createState() => _TestTOState();
}

class _TestTOState extends State<TestTO> {

  bool singleCheckBox = false;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: escalatorTO1.length,
      itemBuilder: (context, index) {
        final text = escalatorTO1[index];
        return Padding(
          padding: const EdgeInsets.all(5.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10.0,vertical: 10.0),
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
            child: Row(
              children: [
                const Icon(Icons.circle,color: Colors.red),
                const SizedBox(width: 10.0),
                Expanded(
                  child: Text(
                    '$text',
                    style: const TextStyle(
                        fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}


/// Эскалатор Травалотор TO ==
List escalatorTO1 = [
  {"text" : 'Проверка табличек и переносных ограждений (наличие, целостность, актуальность данных).', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Проверка подвижности входных площадок.', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Проверка функционирования всех концевых выключателей цепи безопасности:', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'устья поручня', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'плиты крепления гребёнок', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'плиты перекрытия', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'обрыва или чрезмерного натяжения поручня', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'целостности тяговой цепи и пластин полотна', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'целостности тяговой цепи (натяжного устройства)', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Проверка подвижности входных площадок.', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Проверка настила нижней и верхней входной площадки. Целостность покрытия, отсутствие качения.', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Осмотр устройства защиты пластин гребенки.', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Осмотр пластмассовых устьев поручня, дефлекторов и кожухов, креплений элементов обшивки, зазоров при вхождении поручня в лицевой кожух на нижней и верхней входных площадок.', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Проверка поручней на отсутствие трещин, резиновой крошки, посторенних звуков и от повышенного нагрева во время работы и при необходимости регулировка.', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Проверка целостности зубцов гребенки', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Проверка целостности противоскользящего покрытия', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Проверка пульта управления и дисплея, визуальный осмотр пульта управления и дисплея.', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Осмотр главного привода (мотор, редуктор).', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Проверка уровня масла в редукторе и в баке насоса автоматической смазки (если установлен).', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Регулировка натяжения цепей привода поручней, смазка.', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Регулировка натяжения поручней.', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Проверка стабильности работы и отсутствие посторонних звуков эскалатора во время движения.', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Проверка работы эскалаторов на всех рабочих режимах.', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Проверка надежности креплений демаркационных линий ступеней.', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Уборка приямков и элементов оборудования объекта от загрязнений.', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Сделать запись в журнале о выполнения ТО.', "bool" : false, "comment" : '', "photo" : ''},
];

List escalatorTO3 = [
  {"text" : 'Проверка табличек и переносных ограждений (наличие, целостность, актуальность данных).', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Проверка подвижности входных площадок.', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Проверка функционирования всех концевых выключателей цепи безопасности:', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'устья поручня', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'плиты крепления гребёнок', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'плиты перекрытия', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'обрыва или чрезмерного натяжения поручня', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'целостности тяговой цепи и пластин полотна', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'целостности тяговой цепи (натяжного устройства)', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Проверка подвижности входных площадок.', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Проверка настила нижней и верхней входной площадки. Целостность покрытия, отсутствие качения.', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Осмотр устройства защиты пластин гребенки.', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Осмотр пластмассовых устьев поручня, дефлекторов и кожухов, креплений элементов обшивки, зазоров при вхождении поручня в лицевой кожух на нижней и верхней входных площадок.', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Проверка поручней на отсутствие трещин, резиновой крошки, посторенних звуков и от повышенного нагрева во время работы и при необходимости регулировка.', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Проверка целостности зубцов гребенки', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Проверка целостности противоскользящего покрытия', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Проверка пульта управления и дисплея, визуальный осмотр пульта управления и дисплея.', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Осмотр главного привода (мотор, редуктор).', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Проверка уровня масла в редукторе и в баке насоса автоматической смазки (если установлен).', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Регулировка натяжения цепей привода поручней, смазка.', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Регулировка натяжения поручней.', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Проверка стабильности работы и отсутствие посторонних звуков эскалатора во время движения.', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Проверка работы эскалаторов на всех рабочих режимах.', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Проверка надежности креплений демаркационных линий ступеней.', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Уборка приямков и элементов оборудования объекта от загрязнений.', "bool" : false, "comment" : '', "photo" : ''},
 /// =============================================================================================
  {"text" : 'Контроль работы пассажирских указателей (в случае необходимости).', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Осмотр контакта обрыва цепи ступеней (проверка регулировка функционирования).', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Проверка и регулировка натяжной каретки эскалатора.', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Осмотр приводной цепи.', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Чистка, осмотр и смазка ведущих частей, привода тяговой цени и главного вала', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Проверка освещения бортовых панелей и ступеней, в случае необходимости - замена ламп.', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Проверка устройства натяжения приводного ремня.', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Осмотр и очистка направляющих и фермы.', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Сделать запись в журнале о выполнения ТО.', "bool" : false, "comment" : '', "photo" : ''},
];

List escalatorTO6 = [
  {"text" : 'Проверка табличек и переносных ограждений (наличие, целостность, актуальность данных).', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Проверка подвижности входных площадок.', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Проверка функционирования всех концевых выключателей цепи безопасности:', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'устья поручня', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'плиты крепления гребёнок', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'плиты перекрытия', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'обрыва или чрезмерного натяжения поручня', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'целостности тяговой цепи и пластин полотна', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'целостности тяговой цепи (натяжного устройства)', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Проверка подвижности входных площадок.', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Проверка настила нижней и верхней входной площадки. Целостность покрытия, отсутствие качения.', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Осмотр устройства защиты пластин гребенки.', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Осмотр пластмассовых устьев поручня, дефлекторов и кожухов, креплений элементов обшивки, зазоров при вхождении поручня в лицевой кожух на нижней и верхней входных площадок.', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Проверка поручней на отсутствие трещин, резиновой крошки, посторенних звуков и от повышенного нагрева во время работы и при необходимости регулировка.', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Проверка целостности зубцов гребенки', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Проверка целостности противоскользящего покрытия', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Проверка пульта управления и дисплея, визуальный осмотр пульта управления и дисплея.', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Осмотр главного привода (мотор, редуктор).', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Проверка уровня масла в редукторе и в баке насоса автоматической смазки (если установлен).', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Регулировка натяжения цепей привода поручней, смазка.', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Регулировка натяжения поручней.', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Проверка стабильности работы и отсутствие посторонних звуков эскалатора во время движения.', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Проверка работы эскалаторов на всех рабочих режимах.', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Проверка надежности креплений демаркационных линий ступеней.', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Уборка приямков и элементов оборудования объекта от загрязнений.', "bool" : false, "comment" : '', "photo" : ''},
  /// ================================================================================================================================
  {"text" : 'Контроль работы пассажирских указателей (в случае необходимости).', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Осмотр контакта обрыва цепи ступеней (проверка регулировка функционирования).', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Проверка и регулировка натяжной каретки эскалатора.', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Осмотр приводной цепи.', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Чистка, осмотр и смазка ведущих частей, привода тяговой цени и главного вала', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Проверка освещения бортовых панелей и ступеней, в случае необходимости - замена ламп.', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Проверка устройства натяжения приводного ремня.', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Осмотр и очистка направляющих и фермы.', "bool" : false, "comment" : '', "photo" : ''},
  /// ================================================================================================================================
  {"text" : 'Чистка скользящего башмака. Проверка работы блокировочного выключателя.', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Осмотр и регулировка всей системы привода поручней.', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Смазка подшипников тяговых звездочек лестничного полотна и поручня', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Осмотр тяговой цепи лестничного полотна.', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Проверка целостности фрикционное колесо.', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Сделать запись в журнале о выполнения ТО.', "bool" : false, "comment" : '', "photo" : ''},
];

List escalatorTO12 = [
  {"text" : 'Проверка табличек и переносных ограждений (наличие, целостность, актуальность данных).', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Проверка подвижности входных площадок.', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Проверка функционирования всех концевых выключателей цепи безопасности:', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'устья поручня', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'плиты крепления гребёнок', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'плиты перекрытия', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'обрыва или чрезмерного натяжения поручня', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'целостности тяговой цепи и пластин полотна', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'целостности тяговой цепи (натяжного устройства)', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Проверка подвижности входных площадок.', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Проверка настила нижней и верхней входной площадки. Целостность покрытия, отсутствие качения.', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Осмотр устройства защиты пластин гребенки.', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Осмотр пластмассовых устьев поручня, дефлекторов и кожухов, креплений элементов обшивки, зазоров при вхождении поручня в лицевой кожух на нижней и верхней входных площадок.', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Проверка поручней на отсутствие трещин, резиновой крошки, посторенних звуков и от повышенного нагрева во время работы и при необходимости регулировка.', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Проверка целостности зубцов гребенки', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Проверка целостности противоскользящего покрытия', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Проверка пульта управления и дисплея, визуальный осмотр пульта управления и дисплея.', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Осмотр главного привода (мотор, редуктор).', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Проверка уровня масла в редукторе и в баке насоса автоматической смазки (если установлен).', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Регулировка натяжения цепей привода поручней, смазка.', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Регулировка натяжения поручней.', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Проверка стабильности работы и отсутствие посторонних звуков эскалатора во время движения.', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Проверка работы эскалаторов на всех рабочих режимах.', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Проверка надежности креплений демаркационных линий ступеней.', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Уборка приямков и элементов оборудования объекта от загрязнений.', "bool" : false, "comment" : '', "photo" : ''},
  /// ================================================================================================================================
  {"text" : 'Контроль работы пассажирских указателей (в случае необходимости).', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Осмотр контакта обрыва цепи ступеней (проверка регулировка функционирования).', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Проверка и регулировка натяжной каретки эскалатора.', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Осмотр приводной цепи.', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Чистка, осмотр и смазка ведущих частей, привода тяговой цени и главного вала', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Проверка освещения бортовых панелей и ступеней, в случае необходимости - замена ламп.', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Проверка устройства натяжения приводного ремня.', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Осмотр и очистка направляющих и фермы.', "bool" : false, "comment" : '', "photo" : ''},
  /// =================================================================================================================================
  {"text" : 'Чистка скользящего башмака. Проверка работы блокировочного выключателя.', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Осмотр и регулировка всей системы привода поручней.', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Смазка подшипников тяговых звездочек лестничного полотна и поручня', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Осмотр тяговой цепи лестничного полотна.', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Проверка целостности фрикционное колесо.', "bool" : false, "comment" : '', "photo" : ''},
  /// =================================================================================================================================
  {"text" : 'Проверка работы автоматической системы смазки.', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Проверка срабатывания аварийного тормоза (при наличии).', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Подготовка к ежегодному техническому освидетельствованию.', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Сделать запись в журнале о выполнения ТО.', "bool" : false, "comment" : '', "photo" : ''},
];

///===========================

class TOEscalatorTraveller extends StatefulWidget {
  const TOEscalatorTraveller({Key? key}) : super(key: key);

  @override
  State<TOEscalatorTraveller> createState() => _TOEscalatorTravellerState();
}

class _TOEscalatorTravellerState extends State<TOEscalatorTraveller> {
  final keyNameTO1 = GlobalKey<FormState>();
  TextEditingController addNewNameTO = TextEditingController();
  bool openBoolTo1 = false;

  @override
  void initState() {
    saveTO1 = false;
    saveTO2 = false;
    saveTO3 = false;
    saveTO4 = false;
    // TODO: implement initState
    super.initState();
  }



  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          /// Текст кнопка закрыть
          Row(
            children: [
              /// Текст
              Row(
                children: [
                  Text(
                    'Создать шаблон ТО   Эскалатор Траволатор',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: size.width > 570.0 ? 25.0 : 16.0),
                  ),
                  // const SizedBox(width: 20.0),
                  // SizedBox(
                  //   height: 40.0,
                  //   width: 70.0,
                  //   child: TextFormField(
                  //     validator: (value) {
                  //       if (value!.isEmpty) {
                  //         return 'Заполните № ТО';
                  //       } else {
                  //         return null;
                  //       }
                  //     },
                  //     cursorColor: ColorApp.myColorGray,
                  //     controller: addNumberTO,
                  //     decoration:  const InputDecoration(
                  //       // suffixIcon: IconButton(onPressed: (){
                  //       //   if(addNewNameTO.text.isNotEmpty){
                  //       //     newListTO.add(addNewNameTO.text);
                  //       //     print(addNewNameTO.text);
                  //       //     openBoolTo1 = false;
                  //       //     myStream.add(IntTest.indexScreens);
                  //       //     addNewNameTO.clear();
                  //       //   }
                  //       //   // openBoolTo1 = false;
                  //       //   addNewNameTO.clear();
                  //       //   // keyNameTO1.currentState!.validate();
                  //       //
                  //       // }, icon: const Icon(Icons.send,color: Colors.green)),
                  //       // labelText: 'Добавление нового пункта в ТО',
                  //         border: OutlineInputBorder(),
                  //         focusedBorder: OutlineInputBorder(
                  //           borderSide: BorderSide(
                  //               color: ColorApp.myColorGreenAuth),
                  //         ),
                  //         labelText: '№ ТО',
                  //         labelStyle:
                  //         TextStyle(color: ColorApp.myColorGray)),
                  //   ),
                  // ),
                ],
              ),
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
          const SizedBox(height: 20.0),
          Column(
            children: [
              /// Кнопка TO 1 и 3
              Row(
                children: [
                  /// Кнопка TO 1
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.lightGreen,
                          padding: const EdgeInsets.symmetric(vertical: 20.0)),
                      onPressed: (){
                        setState(() {
                          showDialog(
                              context: context,
                              builder: (context) =>
                                  AlertDialog(
                                      content: StreamBuilder(
                                          stream: myStream.stream,
                                          builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                                            return  SizedBox(
                                              width: 800.0,
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  /// Текст кнопка закрыть
                                                  Row(
                                                    children: [
                                                      /// Текст
                                                      Text(
                                                        'Добавить ТО 1',
                                                        style: TextStyle(
                                                            fontWeight: FontWeight.w700,
                                                            fontSize: size.width > 570.0 ? 25.0 : 16.0),
                                                      ),
                                                      const SizedBox(width: 20.0),
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
                                                  const SizedBox(height: 20.0),
                                                  /// Добавление нового пункта в ТО'
                                                  Padding(
                                                    padding: const EdgeInsets.all(5.0),
                                                    child: SizedBox(
                                                      height: 45.0,
                                                      child: Form(
                                                        key: keyNameTO1,
                                                        autovalidateMode: AutovalidateMode.onUserInteraction,
                                                        child: TextFormField(
                                                          // validator: (value) {
                                                          //   if (value!.isEmpty) {
                                                          //     return 'Заполните название';
                                                          //   } else {
                                                          //     return null;
                                                          //   }
                                                          // },
                                                          cursorColor: ColorApp.myColorGray,
                                                          controller: addNewNameTO,
                                                          decoration:  InputDecoration(
                                                              suffixIcon: IconButton(onPressed: (){
                                                                if(addNewNameTO.text.isNotEmpty){
                                                                  escalatorTO1.add({"text" : addNewNameTO.text, "bool" : false});
                                                                  openBoolTo1 = false;
                                                                  myStream.add(IntTest.indexScreens);
                                                                  addNewNameTO.clear();
                                                                }
                                                                // openBoolTo1 = false;
                                                                addNewNameTO.clear();
                                                                // keyNameTO1.currentState!.validate();

                                                              }, icon: const Icon(Icons.send,color: Colors.green)),
                                                              labelText: 'Добавление нового пункта в ТО',
                                                              border: const OutlineInputBorder(),
                                                              focusedBorder: const OutlineInputBorder(
                                                                borderSide: BorderSide(
                                                                    color: ColorApp.myColorGreenAuth),
                                                              ),
                                                              // labelText: 'Документ',
                                                              labelStyle:
                                                              const TextStyle(color: ColorApp.myColorGray)),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 15.0),
                                                  /// Список ТО
                                                  SizedBox(
                                                    height: MediaQuery.of(context).size.height * 0.60,
                                                    child: ListView.builder(
                                                      itemCount: escalatorTO1.length,
                                                      itemBuilder: (context, index) {
                                                        final text = escalatorTO1[index]['text'];
                                                        return Row(
                                                          crossAxisAlignment: CrossAxisAlignment.center,
                                                          children: [
                                                            Expanded(
                                                              child: Padding(
                                                                padding: const EdgeInsets.only(left: 5.0, right: 5.0,bottom: 5.0),
                                                                child: Container(
                                                                  padding: const EdgeInsets.all(10.0),
                                                                  decoration: BoxDecoration(
                                                                      borderRadius: BorderRadius.circular(5.0),
                                                                      border: Border.all(color: Colors.grey, width: 1.5)
                                                                  ),
                                                                  child: Text('$text'),
                                                                ),
                                                              ),
                                                            ),
                                                            IconButton(
                                                                onPressed: (){
                                                                  escalatorTO1.removeAt(index);
                                                                  myStream.add(IntTest.indexScreens);
                                                                }, icon: const Icon(Icons.delete_outline,color: Colors.red)),
                                                          ],
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                  const SizedBox(height: 20.0),
                                                  MainButtonApp(
                                                      textButton: 'Добавить',
                                                      press: () async {
                                                        createTemplateTO(listSelectedObject['data']['factory_model_id']['id'],1,escalatorTO1);
                                                        myStream.add(IntTest.indexScreens);
                                                        Navigator.pop(context);
                                                        setState(() {});
                                                      }
                                                  ),
                                                ],
                                              ),
                                            );})
                                  ));
                        });
                      },
                      child: const Text(
                        'TO 1',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10.0),
                  /// Кнопка TO 3
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.lightGreen,
                          padding: const EdgeInsets.symmetric(vertical: 20.0)),
                      onPressed: (){
                        setState(() {
                          showDialog(
                              context: context,
                              builder: (context) =>
                                  AlertDialog(
                                      content: StreamBuilder(
                                          stream: myStream.stream,
                                          builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                                            return  SizedBox(
                                              width: 800.0,
                                              child: Column(
                                                children: [
                                                  /// Текст кнопка закрыть
                                                  Row(
                                                    children: [
                                                      /// Текст
                                                      Text(
                                                        'Добавить ТО 3',
                                                        style: TextStyle(
                                                            fontWeight: FontWeight.w700,
                                                            fontSize: size.width > 570.0 ? 25.0 : 16.0),
                                                      ),
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
                                                  const SizedBox(height: 20.0),
                                                  /// Добавление нового пункта в ТО'
                                                  Padding(
                                                    padding: const EdgeInsets.all(5.0),
                                                    child: SizedBox(
                                                      height: 45.0,
                                                      child: Form(
                                                        key: keyNameTO1,
                                                        autovalidateMode: AutovalidateMode.onUserInteraction,
                                                        child: TextFormField(
                                                          // validator: (value) {
                                                          //   if (value!.isEmpty) {
                                                          //     return 'Заполните название';
                                                          //   } else {
                                                          //     return null;
                                                          //   }
                                                          // },
                                                          cursorColor: ColorApp.myColorGray,
                                                          controller: addNewNameTO,
                                                          decoration:  InputDecoration(
                                                              suffixIcon: IconButton(onPressed: (){
                                                                if(addNewNameTO.text.isNotEmpty){
                                                                  escalatorTO3.add({"text" : addNewNameTO.text, "bool" : false});
                                                                  print(addNewNameTO.text);
                                                                  openBoolTo1 = false;
                                                                  myStream.add(IntTest.indexScreens);
                                                                  addNewNameTO.clear();
                                                                }
                                                                // openBoolTo1 = false;
                                                                addNewNameTO.clear();
                                                                // keyNameTO1.currentState!.validate();

                                                              }, icon: const Icon(Icons.send,color: Colors.green)),
                                                              labelText: 'Добавление нового пункта в ТО',
                                                              border: const OutlineInputBorder(),
                                                              focusedBorder: const OutlineInputBorder(
                                                                borderSide: BorderSide(
                                                                    color: ColorApp.myColorGreenAuth),
                                                              ),
                                                              // labelText: 'Документ',
                                                              labelStyle:
                                                              const TextStyle(color: ColorApp.myColorGray)),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 15.0),
                                                  /// Список ТО
                                                  SizedBox(
                                                    height: MediaQuery.of(context).size.height * 0.60,
                                                    child: ListView.builder(
                                                      itemCount: escalatorTO3.length,
                                                      itemBuilder: (context, index) {
                                                        final text = escalatorTO3[index]['text'];
                                                        return Row(
                                                          crossAxisAlignment: CrossAxisAlignment.center,
                                                          children: [
                                                            Expanded(
                                                              child: Padding(
                                                                padding: const EdgeInsets.only(left: 5.0, right: 5.0,bottom: 5.0),
                                                                child: Container(
                                                                  padding: const EdgeInsets.all(10.0),
                                                                  decoration: BoxDecoration(
                                                                      borderRadius: BorderRadius.circular(5.0),
                                                                      border: Border.all(color: Colors.grey, width: 1.5)
                                                                  ),
                                                                  child: Text('$text'),
                                                                ),
                                                              ),
                                                            ),
                                                            IconButton(
                                                                onPressed: (){
                                                                  escalatorTO3.removeAt(index);
                                                                  myStream.add(IntTest.indexScreens);
                                                                }, icon: const Icon(Icons.delete_outline,color: Colors.red)),
                                                          ],
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                  const SizedBox(height: 20.0),
                                                  /// Кнопка
                                                  MainButtonApp(
                                                      textButton: 'Добавить',
                                                      press: () async {
                                                        await createTemplateTO(listSelectedObject['data']['factory_model_id']['id'],3,escalatorTO3);
                                                        myStream.add(IntTest.indexScreens);
                                                        Navigator.pop(context);
                                                        setState(() {});
                                                      }
                                                  ),
                                                ],
                                              ),
                                            );})

                                  ));
                        });
                      },
                      child: const Text(
                        'TO 3',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20.0),
              /// Кнопка TO 6 и 12
              Row(
                children: [
                  /// Кнопка TO 6
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.lightGreen,
                          padding: const EdgeInsets.symmetric(vertical: 20.0)),
                      onPressed: (){
                        setState(() {
                          showDialog(
                              context: context,
                              builder: (context) =>
                                  AlertDialog(
                                      content: StreamBuilder(
                                          stream: myStream.stream,
                                          builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                                            return SizedBox(
                                              width: 800.0,
                                              child: Column(
                                                children: [
                                                  /// Текст кнопка закрыть
                                                  Row(
                                                    children: [
                                                      /// Текст
                                                      Text(
                                                        'Добавить ТО 6',
                                                        style: TextStyle(
                                                            fontWeight: FontWeight.w700,
                                                            fontSize: size.width > 570.0 ? 25.0 : 16.0),
                                                      ),
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
                                                  const SizedBox(height: 20.0),
                                                  /// Добавление нового пункта в ТО'
                                                  Padding(
                                                    padding: const EdgeInsets.all(5.0),
                                                    child: SizedBox(
                                                      height: 45.0,
                                                      child: Form(
                                                        key: keyNameTO1,
                                                        autovalidateMode: AutovalidateMode.onUserInteraction,
                                                        child: TextFormField(
                                                          validator: (value) {
                                                            if (value!.isEmpty) {
                                                              return 'Заполните название';
                                                            } else {
                                                              return null;
                                                            }
                                                          },
                                                          cursorColor: ColorApp.myColorGray,
                                                          controller: addNewNameTO,
                                                          decoration:  InputDecoration(
                                                              suffixIcon: IconButton(onPressed: (){
                                                                if(addNewNameTO.text.isNotEmpty){
                                                                  escalatorTO6.add({"text" : addNewNameTO.text, "bool" : false});
                                                                  print(addNewNameTO.text);
                                                                  openBoolTo1 = false;
                                                                  myStream.add(IntTest.indexScreens);
                                                                  addNewNameTO.clear();
                                                                }
                                                                // openBoolTo1 = false;
                                                                addNewNameTO.clear();
                                                                // keyNameTO1.currentState!.validate();

                                                              }, icon: const Icon(Icons.send,color: Colors.green)),
                                                              labelText: 'Добавление нового пункта в ТО',
                                                              border: const OutlineInputBorder(),
                                                              focusedBorder: const OutlineInputBorder(
                                                                borderSide: BorderSide(
                                                                    color: ColorApp.myColorGreenAuth),
                                                              ),
                                                              // labelText: 'Документ',
                                                              labelStyle:
                                                              const TextStyle(color: ColorApp.myColorGray)),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 15.0),
                                                  /// Список ТО
                                                  SizedBox(
                                                    height: MediaQuery.of(context).size.height * 0.60,
                                                    child: ListView.builder(
                                                      itemCount: escalatorTO6.length,
                                                      itemBuilder: (context, index) {
                                                        final text = escalatorTO6[index]['text'];
                                                        return Row(
                                                          crossAxisAlignment: CrossAxisAlignment.center,
                                                          children: [
                                                            Expanded(
                                                              child: Padding(
                                                                padding: const EdgeInsets.only(left: 5.0, right: 5.0,bottom: 5.0),
                                                                child: Container(
                                                                  padding: const EdgeInsets.all(10.0),
                                                                  decoration: BoxDecoration(
                                                                      borderRadius: BorderRadius.circular(5.0),
                                                                      border: Border.all(color: Colors.grey, width: 1.5)
                                                                  ),
                                                                  child: Text('$text'),
                                                                ),
                                                              ),
                                                            ),
                                                            IconButton(
                                                                onPressed: (){
                                                                  escalatorTO6.removeAt(index);
                                                                  myStream.add(IntTest.indexScreens);
                                                                }, icon: const Icon(Icons.delete_outline,color: Colors.red)),
                                                          ],
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                  const SizedBox(height: 20.0),
                                                  /// Кноака добавить
                                                  MainButtonApp(
                                                      textButton: 'Добавить',
                                                      press: () async {
                                                        await createTemplateTO(listSelectedObject['data']['factory_model_id']['id'],6,escalatorTO6);
                                                        myStream.add(IntTest.indexScreens);
                                                        Navigator.pop(context);
                                                        setState(() {});
                                                      }
                                                  ),
                                                ],
                                              ),
                                            );})

                                  ));
                        });
                      },
                      child: const Text(
                        'TO 6',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10.0),
                  /// Кнопка TO 12
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.lightGreen,
                          padding: const EdgeInsets.symmetric(vertical: 20.0)),
                      onPressed: (){
                        setState(() {
                          showDialog(
                              context: context,
                              builder: (context) =>
                                  AlertDialog(
                                      content: StreamBuilder(
                                          stream: myStream.stream,
                                          builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                                            return   SizedBox(
                                              width: 800.0,
                                              child: Column(
                                                children: [
                                                  /// Текст кнопка закрыть
                                                  Row(
                                                    children: [
                                                      /// Текст
                                                      Text(
                                                        'Добавить ТО 12',
                                                        style: TextStyle(
                                                            fontWeight: FontWeight.w700,
                                                            fontSize: size.width > 570.0 ? 25.0 : 16.0),
                                                      ),
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
                                                  const SizedBox(height: 20.0),
                                                  /// Добавление нового пункта в ТО'
                                                  Padding(
                                                    padding: const EdgeInsets.all(5.0),
                                                    child: SizedBox(
                                                      height: 45.0,
                                                      child: Form(
                                                        key: keyNameTO1,
                                                        autovalidateMode: AutovalidateMode.onUserInteraction,
                                                        child: TextFormField(
                                                          // validator: (value) {
                                                          //   if (value!.isEmpty) {
                                                          //     return 'Заполните название';
                                                          //   } else {
                                                          //     return null;
                                                          //   }
                                                          // },
                                                          cursorColor: ColorApp.myColorGray,
                                                          controller: addNewNameTO,
                                                          decoration:  InputDecoration(
                                                              suffixIcon: IconButton(onPressed: (){
                                                                if(addNewNameTO.text.isNotEmpty){
                                                                  escalatorTO12.add({"text" : addNewNameTO.text, "bool" : false});
                                                                  print(addNewNameTO.text);
                                                                  openBoolTo1 = false;
                                                                  myStream.add(IntTest.indexScreens);
                                                                  addNewNameTO.clear();
                                                                }
                                                                // openBoolTo1 = false;
                                                                addNewNameTO.clear();
                                                                // keyNameTO1.currentState!.validate();

                                                              }, icon: const Icon(Icons.send,color: Colors.green)),
                                                              labelText: 'Добавление нового пункта в ТО',
                                                              border: const OutlineInputBorder(),
                                                              focusedBorder: const OutlineInputBorder(
                                                                borderSide: BorderSide(
                                                                    color: ColorApp.myColorGreenAuth),
                                                              ),
                                                              // labelText: 'Документ',
                                                              labelStyle:
                                                              const TextStyle(color: ColorApp.myColorGray)),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 15.0),
                                                  /// Список ТО
                                                  SizedBox(
                                                    height: MediaQuery.of(context).size.height * 0.60,
                                                    child: ListView.builder(
                                                      itemCount: escalatorTO12.length,
                                                      itemBuilder: (context, index) {
                                                        final text = escalatorTO12[index]['text'];
                                                        return Row(
                                                          crossAxisAlignment: CrossAxisAlignment.center,
                                                          children: [
                                                            Expanded(
                                                              child: Padding(
                                                                padding: const EdgeInsets.only(left: 5.0, right: 5.0,bottom: 5.0),
                                                                child: Container(
                                                                  padding: const EdgeInsets.all(10.0),
                                                                  decoration: BoxDecoration(
                                                                      borderRadius: BorderRadius.circular(5.0),
                                                                      border: Border.all(color: Colors.grey, width: 1.5)
                                                                  ),
                                                                  child: Text('$text'),
                                                                ),
                                                              ),
                                                            ),
                                                            IconButton(
                                                                onPressed: (){
                                                                  escalatorTO12.removeAt(index);
                                                                  myStream.add(IntTest.indexScreens);
                                                                }, icon: const Icon(Icons.delete_outline,color: Colors.red)),
                                                          ],
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                  const SizedBox(height: 20.0),
                                                  /// Кнопка добавить
                                                  MainButtonApp(
                                                      textButton: 'Добавить',
                                                      press: () async {
                                                        await createTemplateTO(listSelectedObject['data']['factory_model_id']['id'],12,escalatorTO12);
                                                        await getAllTemplateTOInIdObject(IntTest.pressHover);
                                                        myStream.add(IntTest.indexScreens);
                                                        Navigator.pop(context);
                                                        setState(() {});
                                                      }
                                                  ),
                                                ],
                                              ),
                                            );})

                                  ));
                        });
                      },
                      child: const Text(
                        'TO 12',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20.0),
              /// Кнопка создать новое TO
              // Row(
              //   children: [
              //     Expanded(
              //       child: ElevatedButton(
              //         style: ElevatedButton.styleFrom(
              //             primary: Colors.lightGreen,
              //             padding: const EdgeInsets.symmetric(vertical: 20.0)),
              //         onPressed: (){
              //           setState(() {
              //             showDialog(
              //                 context: context,
              //                 builder: (context) =>
              //                     AlertDialog(
              //                         content: StreamBuilder(
              //                             stream: myStream.stream,
              //                             builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
              //                               return SizedBox(
              //                                 width: 800.0,
              //                                 child: Column(
              //                                   children: [
              //                                     /// Текст кнопка закрыть
              //                                     Row(
              //                                       children: [
              //                                         /// Текст
              //                                         Row(
              //                                           children: [
              //                                             Text(
              //                                               'Создать новое ТО',
              //                                               style: TextStyle(
              //                                                   fontWeight: FontWeight.w700,
              //                                                   fontSize: size.width > 570.0 ? 25.0 : 16.0),
              //                                             ),
              //                                             const SizedBox(width: 20.0),
              //                                             SizedBox(
              //                                               height: 40.0,
              //                                               width: 70.0,
              //                                               child: TextFormField(
              //                                                 validator: (value) {
              //                                                   if (value!.isEmpty) {
              //                                                     return 'Заполните № ТО';
              //                                                   } else {
              //                                                     return null;
              //                                                   }
              //                                                 },
              //                                                 cursorColor: ColorApp.myColorGray,
              //                                                 controller: addNumberTO,
              //                                                 decoration:  const InputDecoration(
              //                                                   // suffixIcon: IconButton(onPressed: (){
              //                                                   //   if(addNewNameTO.text.isNotEmpty){
              //                                                   //     newListTO.add(addNewNameTO.text);
              //                                                   //     print(addNewNameTO.text);
              //                                                   //     openBoolTo1 = false;
              //                                                   //     myStream.add(IntTest.indexScreens);
              //                                                   //     addNewNameTO.clear();
              //                                                   //   }
              //                                                   //   // openBoolTo1 = false;
              //                                                   //   addNewNameTO.clear();
              //                                                   //   // keyNameTO1.currentState!.validate();
              //                                                   //
              //                                                   // }, icon: const Icon(Icons.send,color: Colors.green)),
              //                                                   // labelText: 'Добавление нового пункта в ТО',
              //                                                     border: OutlineInputBorder(),
              //                                                     focusedBorder: OutlineInputBorder(
              //                                                       borderSide: BorderSide(
              //                                                           color: ColorApp.myColorGreenAuth),
              //                                                     ),
              //                                                     labelText: '№ ТО',
              //                                                     labelStyle:
              //                                                     TextStyle(color: ColorApp.myColorGray)),
              //                                               ),
              //                                             ),
              //                                           ],
              //                                         ),
              //                                         const Spacer(),
              //                                         /// кнопка закрыть
              //                                         IconButton(
              //                                             onPressed: () {
              //                                               Navigator.pop(context);
              //                                             },
              //                                             icon: const Icon(
              //                                               Icons.close,
              //                                               color: ColorApp.myColorGreenAuth,
              //                                             )),
              //                                       ],
              //                                     ),
              //                                     const SizedBox(height: 20.0),
              //                                     /// Добавление нового пункта в ТО'
              //                                     Padding(
              //                                       padding: const EdgeInsets.all(5.0),
              //                                       child: SizedBox(
              //                                         height: 45.0,
              //                                         child: Form(
              //                                           key: keyNameTO1,
              //                                           autovalidateMode: AutovalidateMode.onUserInteraction,
              //                                           child: TextFormField(
              //                                             // validator: (value) {
              //                                             //   if (value!.isEmpty) {
              //                                             //     return 'Заполните название';
              //                                             //   } else {
              //                                             //     return null;
              //                                             //   }
              //                                             // },
              //                                             cursorColor: ColorApp.myColorGray,
              //                                             controller: addNewNameTO,
              //                                             decoration:  InputDecoration(
              //                                                 suffixIcon: IconButton(onPressed: (){
              //                                                   if(addNewNameTO.text.isNotEmpty){
              //                                                     newTOLiftNotMO.add(addNewNameTO.text);
              //                                                     print(addNewNameTO.text);
              //                                                     openBoolTo1 = false;
              //                                                     myStream.add(IntTest.indexScreens);
              //                                                     addNewNameTO.clear();
              //                                                   }
              //                                                   // openBoolTo1 = false;
              //                                                   addNewNameTO.clear();
              //                                                   // keyNameTO1.currentState!.validate();
              //
              //                                                 }, icon: const Icon(Icons.send,color: Colors.green)),
              //                                                 labelText: 'Добавление нового пункта в ТО',
              //                                                 border: const OutlineInputBorder(),
              //                                                 focusedBorder: const OutlineInputBorder(
              //                                                   borderSide: BorderSide(
              //                                                       color: ColorApp.myColorGreenAuth),
              //                                                 ),
              //                                                 // labelText: 'Документ',
              //                                                 labelStyle:
              //                                                 const TextStyle(color: ColorApp.myColorGray)),
              //                                           ),
              //                                         ),
              //                                       ),
              //                                     ),
              //                                     const SizedBox(height: 15.0),
              //                                     /// Список нового ТО
              //                                     SizedBox(
              //                                       height: MediaQuery.of(context).size.height * 0.60,
              //                                       child: ListView.builder(
              //                                         itemCount: newTOLiftNotMO.length,
              //                                         itemBuilder: (context, index) {
              //                                           final text = newTOLiftNotMO[index];
              //                                           return Row(
              //                                             crossAxisAlignment: CrossAxisAlignment.center,
              //                                             children: [
              //                                               Expanded(
              //                                                 child: Padding(
              //                                                   padding: const EdgeInsets.only(left: 5.0, right: 5.0,bottom: 5.0),
              //                                                   child: Container(
              //                                                     padding: const EdgeInsets.all(10.0),
              //                                                     decoration: BoxDecoration(
              //                                                         borderRadius: BorderRadius.circular(5.0),
              //                                                         border: Border.all(color: Colors.grey, width: 1.5)
              //                                                     ),
              //                                                     child: Text('$text'),
              //                                                   ),
              //                                                 ),
              //                                               ),
              //                                               IconButton(
              //                                                   onPressed: (){
              //                                                     newTOLiftNotMO.removeAt(index);
              //                                                     myStream.add(IntTest.indexScreens);
              //                                                   }, icon: const Icon(Icons.delete_outline,color: Colors.red)),
              //                                             ],
              //                                           );
              //                                         },
              //                                       ),
              //                                     ),
              //                                     const SizedBox(height: 20.0),
              //                                     /// Кнопка добавить
              //                                     MainButtonApp(
              //                                         textButton: 'Добавить',
              //                                         press: () async {
              //                                           if(addNumberTO.text.isNotEmpty){
              //                                             myStream.add(IntTest.indexScreens);
              //                                             Navigator.pop(context);
              //                                           }
              //                                           keyNumberTO.currentState!.validate();
              //                                           setState(() {});
              //                                         }
              //                                     ),
              //
              //                                   ],
              //                                 ),
              //                               );})
              //
              //                     ));
              //           });
              //         },
              //         child: const Text(
              //           'Создать новое TO',
              //           style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              //         ),
              //       ),
              //     ),
              //   ],
              // ),
            ],
          ),
        ],
      ),
    );
  }
}


/// Грузовой Инвалидный Лифт ТО 1 ======
List cargoDisabledPersonLiftTO1 = [
  {"text" : 'Ознакомиться с техническим состоянием подъемника по записям в вахтенном журнале.', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Осмотреть место установки подъемника.', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Проверить наружным осмотром состояние подъемника и комплектность его узлов.', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Проверить наличие и достаточность освещения подъемника и приемных мест.', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Проверить работу аппаратов управления и тормоза.', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Проверить работу сигнализации.', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Проверить состояние электрокабеля.', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Проверить смазку согласно карте смазки.', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'После проведения работ по ТО - 1 опробовать подъемник в работе, при этом проверить работу тормоза, замерить тормозной путь каретки.', "bool" : false, "comment" : '', "photo" : ''},
];

/// Грузовой Инвалидный Лифт ТО 2
List cargoDisabledPersonLiftTO2 = [
  {"text" : 'Выполнить работы ТО-1 в полном объеме.', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Проверить крепления основных узлов и деталей.', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Проверить уровень масла в редукторе.', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Проверить и подтянуть крепление клеммных соединений электропроводки.', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Осмотреть состояние ловителей.', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Проверить состояние каретки. Неисправности устранить.', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Проверить затяжку болтов крепления всей металлоконструкции.', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Проверить состояние роликов каретки, привода ловителей.', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Проверить состояние металлоконструкций секций мачты.', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Проверить надежность приборов безопасности.', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'Проверить смазку узлов согласно карте смазки.', "bool" : false, "comment" : '', "photo" : ''},
  {"text" : 'После проведения работ по ТО-2 опробовать подъемник в работе, при этом проверить работу тормоза, замерить тормозной путь каретки.', "bool" : false, "comment" : '', "photo" : ''},
];
///======================================

class TOCargoDisabledPersonLift extends StatefulWidget {
  const TOCargoDisabledPersonLift({Key? key}) : super(key: key);

  @override
  State<TOCargoDisabledPersonLift> createState() => _TOCargoDisabledPersonLiftState();
}

class _TOCargoDisabledPersonLiftState extends State<TOCargoDisabledPersonLift> {
  final keyNameTO1 = GlobalKey<FormState>();
  TextEditingController addNewNameTO = TextEditingController();
  bool openBoolTo1 = false;

  @override
  void initState() {
    saveTO1 = false;
    saveTO2 = false;
    saveTO3 = false;
    saveTO4 = false;
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          /// Текст кнопка закрыть
          Row(
            children: [
              /// Текст
              Row(
                children: [
                  Text(
                    'Создать шаблон ТО  Грузовой Инвалидный',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: size.width > 570.0 ? 25.0 : 16.0),
                  ),
                  // const SizedBox(width: 20.0),
                  // SizedBox(
                  //   height: 40.0,
                  //   width: 70.0,
                  //   child: TextFormField(
                  //     validator: (value) {
                  //       if (value!.isEmpty) {
                  //         return 'Заполните № ТО';
                  //       } else {
                  //         return null;
                  //       }
                  //     },
                  //     cursorColor: ColorApp.myColorGray,
                  //     controller: addNumberTO,
                  //     decoration:  const InputDecoration(
                  //       // suffixIcon: IconButton(onPressed: (){
                  //       //   if(addNewNameTO.text.isNotEmpty){
                  //       //     newListTO.add(addNewNameTO.text);
                  //       //     print(addNewNameTO.text);
                  //       //     openBoolTo1 = false;
                  //       //     myStream.add(IntTest.indexScreens);
                  //       //     addNewNameTO.clear();
                  //       //   }
                  //       //   // openBoolTo1 = false;
                  //       //   addNewNameTO.clear();
                  //       //   // keyNameTO1.currentState!.validate();
                  //       //
                  //       // }, icon: const Icon(Icons.send,color: Colors.green)),
                  //       // labelText: 'Добавление нового пункта в ТО',
                  //         border: OutlineInputBorder(),
                  //         focusedBorder: OutlineInputBorder(
                  //           borderSide: BorderSide(
                  //               color: ColorApp.myColorGreenAuth),
                  //         ),
                  //         labelText: '№ ТО',
                  //         labelStyle:
                  //         TextStyle(color: ColorApp.myColorGray)),
                  //   ),
                  // ),
                ],
              ),
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
          const SizedBox(height: 20.0),
          Column(
            children: [
              /// Кнопка TO 1 и 2
              Row(
                children: [
                  /// Кнопка TO 1
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: saveTO1 == true ? Colors.grey : Colors.lightGreen,
                          padding: const EdgeInsets.symmetric(vertical: 20.0)),
                      onPressed: saveTO1 == true ? (){} : (){
                        setState(() {
                          showDialog(
                              context: context,
                              builder: (context) =>
                                  AlertDialog(
                                      content: StreamBuilder(
                                          stream: myStream.stream,
                                          builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                                            return  SizedBox(
                                              width: 800.0,
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  /// Текст кнопка закрыть
                                                  Row(
                                                    children: [
                                                      /// Текст
                                                      Text(
                                                        'Добавить ТО 1',
                                                        style: TextStyle(
                                                            fontWeight: FontWeight.w700,
                                                            fontSize: size.width > 570.0 ? 25.0 : 16.0),
                                                      ),
                                                      const SizedBox(width: 20.0),
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
                                                  const SizedBox(height: 20.0),
                                                  /// Добавление нового пункта в ТО'
                                                  Padding(
                                                    padding: const EdgeInsets.all(5.0),
                                                    child: SizedBox(
                                                      height: 45.0,
                                                      child: Form(
                                                        key: keyNameTO1,
                                                        autovalidateMode: AutovalidateMode.onUserInteraction,
                                                        child: TextFormField(
                                                          // validator: (value) {
                                                          //   if (value!.isEmpty) {
                                                          //     return 'Заполните название';
                                                          //   } else {
                                                          //     return null;
                                                          //   }
                                                          // },
                                                          cursorColor: ColorApp.myColorGray,
                                                          controller: addNewNameTO,
                                                          decoration:  InputDecoration(
                                                              suffixIcon: IconButton(onPressed: (){
                                                                if(addNewNameTO.text.isNotEmpty){
                                                                  cargoDisabledPersonLiftTO1.add({"text" : addNewNameTO.text, "bool" : false});
                                                                  openBoolTo1 = false;
                                                                  myStream.add(IntTest.indexScreens);
                                                                  addNewNameTO.clear();
                                                                }
                                                                // openBoolTo1 = false;
                                                                addNewNameTO.clear();
                                                                // keyNameTO1.currentState!.validate();

                                                              }, icon: const Icon(Icons.send,color: Colors.green)),
                                                              labelText: 'Добавление нового пункта в ТО',
                                                              border: const OutlineInputBorder(),
                                                              focusedBorder: const OutlineInputBorder(
                                                                borderSide: BorderSide(
                                                                    color: ColorApp.myColorGreenAuth),
                                                              ),
                                                              // labelText: 'Документ',
                                                              labelStyle:
                                                              const TextStyle(color: ColorApp.myColorGray)),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 15.0),
                                                  /// Список ТО
                                                  SizedBox(
                                                    height: MediaQuery.of(context).size.height * 0.60,
                                                    child: ListView.builder(
                                                      itemCount: cargoDisabledPersonLiftTO1.length,
                                                      itemBuilder: (context, index) {
                                                        final text = cargoDisabledPersonLiftTO1[index]['text'];
                                                        return Row(
                                                          crossAxisAlignment: CrossAxisAlignment.center,
                                                          children: [
                                                            Expanded(
                                                              child: Padding(
                                                                padding: const EdgeInsets.only(left: 5.0, right: 5.0,bottom: 5.0),
                                                                child: Container(
                                                                  padding: const EdgeInsets.all(10.0),
                                                                  decoration: BoxDecoration(
                                                                      borderRadius: BorderRadius.circular(5.0),
                                                                      border: Border.all(color: Colors.grey, width: 1.5)
                                                                  ),
                                                                  child: Text('$text'),
                                                                ),
                                                              ),
                                                            ),
                                                            IconButton(
                                                                onPressed: (){
                                                                  cargoDisabledPersonLiftTO1.removeAt(index);
                                                                  myStream.add(IntTest.indexScreens);
                                                                }, icon: const Icon(Icons.delete_outline,color: Colors.red)),
                                                          ],
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                  const SizedBox(height: 20.0),
                                                  MainButtonApp(
                                                      textButton: 'Добавить',
                                                      press: () async {
                                                        createTemplateTO(listSelectedObject['data']['factory_model_id']['id'],1,cargoDisabledPersonLiftTO1);
                                                        saveTO1 = true;
                                                        myStream.add(IntTest.indexScreens);
                                                        Navigator.pop(context);
                                                        setState(() {});
                                                      }
                                                  ),
                                                ],
                                              ),
                                            );})
                                  ));
                        });
                      },
                      child:  Text(
                        saveTO1 == true ? 'Создано' : 'TO 1',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10.0),
                  /// Кнопка TO 3
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: saveTO2 == true ? Colors.grey : Colors.lightGreen,
                          padding: const EdgeInsets.symmetric(vertical: 20.0)),
                      onPressed: saveTO2 == true ? (){} : (){
                        setState(() {
                          showDialog(
                              context: context,
                              builder: (context) =>
                                  AlertDialog(
                                      content: StreamBuilder(
                                          stream: myStream.stream,
                                          builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                                            return  SizedBox(
                                              width: 800.0,
                                              child: Column(
                                                children: [
                                                  /// Текст кнопка закрыть
                                                  Row(
                                                    children: [
                                                      /// Текст
                                                      Text(
                                                        'Добавить ТО 3',
                                                        style: TextStyle(
                                                            fontWeight: FontWeight.w700,
                                                            fontSize: size.width > 570.0 ? 25.0 : 16.0),
                                                      ),
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
                                                  const SizedBox(height: 20.0),
                                                  /// Добавление нового пункта в ТО'
                                                  Padding(
                                                    padding: const EdgeInsets.all(5.0),
                                                    child: SizedBox(
                                                      height: 45.0,
                                                      child: Form(
                                                        key: keyNameTO1,
                                                        autovalidateMode: AutovalidateMode.onUserInteraction,
                                                        child: TextFormField(
                                                          // validator: (value) {
                                                          //   if (value!.isEmpty) {
                                                          //     return 'Заполните название';
                                                          //   } else {
                                                          //     return null;
                                                          //   }
                                                          // },
                                                          cursorColor: ColorApp.myColorGray,
                                                          controller: addNewNameTO,
                                                          decoration:  InputDecoration(
                                                              suffixIcon: IconButton(onPressed: (){
                                                                if(addNewNameTO.text.isNotEmpty){
                                                                  cargoDisabledPersonLiftTO2.add({"text" : addNewNameTO.text, "bool" : false});
                                                                  print(addNewNameTO.text);
                                                                  openBoolTo1 = false;
                                                                  myStream.add(IntTest.indexScreens);
                                                                  addNewNameTO.clear();
                                                                }
                                                                // openBoolTo1 = false;
                                                                addNewNameTO.clear();
                                                                // keyNameTO1.currentState!.validate();

                                                              }, icon: const Icon(Icons.send,color: Colors.green)),
                                                              labelText: 'Добавление нового пункта в ТО',
                                                              border: const OutlineInputBorder(),
                                                              focusedBorder: const OutlineInputBorder(
                                                                borderSide: BorderSide(
                                                                    color: ColorApp.myColorGreenAuth),
                                                              ),
                                                              // labelText: 'Документ',
                                                              labelStyle:
                                                              const TextStyle(color: ColorApp.myColorGray)),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 15.0),
                                                  /// Список ТО
                                                  SizedBox(
                                                    height: MediaQuery.of(context).size.height * 0.60,
                                                    child: ListView.builder(
                                                      itemCount: cargoDisabledPersonLiftTO2.length,
                                                      itemBuilder: (context, index) {
                                                        final text = cargoDisabledPersonLiftTO2[index]['text'];
                                                        return Row(
                                                          crossAxisAlignment: CrossAxisAlignment.center,
                                                          children: [
                                                            Expanded(
                                                              child: Padding(
                                                                padding: const EdgeInsets.only(left: 5.0, right: 5.0,bottom: 5.0),
                                                                child: Container(
                                                                  padding: const EdgeInsets.all(10.0),
                                                                  decoration: BoxDecoration(
                                                                      borderRadius: BorderRadius.circular(5.0),
                                                                      border: Border.all(color: Colors.grey, width: 1.5)
                                                                  ),
                                                                  child: Text('$text'),
                                                                ),
                                                              ),
                                                            ),
                                                            IconButton(
                                                                onPressed: (){
                                                                  cargoDisabledPersonLiftTO2.removeAt(index);
                                                                  myStream.add(IntTest.indexScreens);
                                                                }, icon: const Icon(Icons.delete_outline,color: Colors.red)),
                                                          ],
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                  const SizedBox(height: 20.0),
                                                  /// Кнопка
                                                  MainButtonApp(
                                                      textButton: 'Добавить',
                                                      press: () async {
                                                        await createTemplateTO(listSelectedObject['data']['factory_model_id']['id'],3,cargoDisabledPersonLiftTO2);
                                                        saveTO2 = true;
                                                        await getAllTemplateTOInIdObject(IntTest.pressHover);
                                                        myStream.add(IntTest.indexScreens);
                                                        Navigator.pop(context);
                                                        setState(() {});
                                                      }
                                                  ),
                                                ],
                                              ),
                                            );})

                                  ));
                        });
                      },
                      child: Text( saveTO2 == true ? 'Создано' :'TO 3',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}



