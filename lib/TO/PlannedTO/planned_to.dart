import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../helper/class_colors.dart';
import '../../screns/home_page/home_page.dart';
import '../../screns/schedule/schedule_page.dart';
import '../liftNotMO.dart';

class PlanedTOClass extends StatefulWidget {
  const PlanedTOClass({Key? key}) : super(key: key);

  @override
  State<PlanedTOClass> createState() => _PlanedTOClassState();
}

class _PlanedTOClassState extends State<PlanedTOClass> {


  TextEditingController addDataYearTO = TextEditingController(text: DateFormat.y('ru').format(DateTime.now()));
  TextEditingController addNumberTO = TextEditingController();
  TextEditingController addNewNameTO = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20.0,vertical: 20.0),
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
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Плановые ТО',style: TextStyle(fontWeight: FontWeight.bold,fontSize: 20.0)),
              /// Кнопки месяцы
              Row(
                children: [
                  /// 1
                  Column(
                    children: [
                      const  Text('Янв'),
                      InkWell(
                        onTap: (){
                          monthSchedule = 1;
                          //january_to_id
                          // creationGraphics('2025', 'january_to_id', 1, 1); /// Функция назначения номера ТО
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
                                                          'Создание Планового ТО',
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
                                                    /// Список ТО

                                                  ],
                                                ),
                                              );})

                                    ));
                          });
                        },
                        child: Container(
                          height: 30.0,
                          width: 30.0,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5.0),
                            color:monthSchedule == 1 ? Colors.green : ColorApp.myColorGreen,
                          ),
                          child: const Center(child: Text('TO1',style: TextStyle(color: Colors.white,fontSize: 11.0))),
                          // getTOScheduleList[2]['january_to_id'] != null
                          //     ? const Text('TO1',style: TextStyle(color: Colors.white,fontSize: 11.0))
                          //     : const Icon(Icons.add,color: Colors.white,size: 16.0)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 5.0),
                  /// 2
                  Column(
                    children: [
                      const Text('Фев'),
                      InkWell(
                        onTap: (){
                          // february_to_id
                          monthSchedule = 2;
                          print(monthSchedule);
                          setState(() {});
                        },
                        child: Container(
                          height: 30.0,
                          width: 30.0,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5.0),
                            color:monthSchedule == 2 ? Colors.green : ColorApp.myColorGreen,
                          ),
                          child: const Center(child: Icon(Icons.add,color: Colors.white,size: 16.0)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 5.0),
                  /// 3
                  Column(
                    children: [
                      const Text('Мар'),
                      InkWell(
                        onTap: (){
                          // march_to_id
                          monthSchedule = 3;
                          print(monthSchedule);
                          setState(() {});
                        },
                        child: Container(
                          height: 30.0,
                          width: 30.0,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5.0),
                            color:monthSchedule == 3 ? Colors.green : ColorApp.myColorGreen,
                          ),
                          child: const Center(child: Text('TO3',style: TextStyle(color: Colors.white,fontSize: 11.0),)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 5.0),
                  /// 4
                  Column(
                    children: [
                      const Text('Апр'),
                      InkWell(
                        onTap: (){
                          // april_to_id
                          monthSchedule = 4;
                          print(monthSchedule);
                          setState(() {});
                        },
                        child: Container(
                          height: 30.0,
                          width: 30.0,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5.0),
                            color:monthSchedule == 4 ? Colors.green : ColorApp.myColorGreen,
                          ),
                          child: const Center(child: Icon(Icons.add,color: Colors.white,size: 16.0)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 5.0),
                  /// 5
                  Column(
                    children: [
                      const Text('Май'),
                      InkWell(
                        onTap: (){
                          // may_to_id
                          monthSchedule = 5;
                          print(monthSchedule);
                          setState(() {});
                        },
                        child: Container(
                          height: 30.0,
                          width: 30.0,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5.0),
                            color:monthSchedule == 5 ? Colors.green : ColorApp.myColorGreen,
                          ),
                          child: const Center(child: Icon(Icons.add,color: Colors.white,size: 16.0)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 5.0),
                  /// 6
                  Column(
                    children: [
                      const Text('Июн'),
                      InkWell(
                        onTap: (){
                          // june_to_id
                          monthSchedule = 6;
                          print(monthSchedule);
                          setState(() {});
                        },
                        child: Container(
                          height: 30.0,
                          width: 30.0,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5.0),
                            color:monthSchedule == 6 ? Colors.green : ColorApp.myColorGreen,
                          ),
                          child: const Center(child: Text('TO6',style: TextStyle(color: Colors.white,fontSize: 11.0),)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 5.0),
                  /// 7
                  Column(
                    children: [
                      const Text('Июл'),
                      InkWell(
                        onTap: (){
                          // july_to_id
                          monthSchedule = 7;
                          print(monthSchedule);
                          setState(() {});
                        },
                        child: Container(
                          height: 30.0,
                          width: 30.0,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5.0),
                            color:monthSchedule == 7 ? Colors.green : ColorApp.myColorGreen,
                          ),
                          child: const Center(child: Icon(Icons.add,color: Colors.white,size: 16.0)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 5.0),
                  /// 8
                  Column(
                    children: [
                      const Text('Авг'),
                      InkWell(
                        onTap: (){
                          // august_to_id
                          monthSchedule = 8;
                          print(monthSchedule);
                          setState(() {});
                        },
                        child: Container(
                          height: 30.0,
                          width: 30.0,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5.0),
                            color:monthSchedule == 8 ? Colors.green : ColorApp.myColorGreen,
                          ),
                          child: const Center(child: Icon(Icons.add,color: Colors.white,size: 16.0)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 5.0),
                  /// 9
                  Column(
                    children: [
                      const Text('Сен'),
                      InkWell(
                        onTap: (){
                          // "september_to_id"


                          monthSchedule = 9;
                          print(monthSchedule);
                          setState(() {});
                        },
                        child: Container(
                          height: 30.0,
                          width: 30.0,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5.0),
                            color:monthSchedule == 9 ? Colors.green : ColorApp.myColorGreen,
                          ),
                          child: const Center(child: Icon(Icons.add,color: Colors.white,size: 16.0)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 5.0),
                  /// 10
                  Column(
                    children: [
                      const Text('Окт'),
                      InkWell(
                        onTap: (){
                          // "october_to_id"

                          monthSchedule = 10;
                          print(monthSchedule);
                          setState(() {});
                        },
                        child: Container(
                          height: 30.0,
                          width: 30.0,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5.0),
                            color:monthSchedule == 10 ? Colors.green : ColorApp.myColorGreen,
                          ),
                          child: const Center(child: Icon(Icons.add,color: Colors.white,size: 16.0)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 5.0),
                  /// 11
                  Column(
                    children: [
                      const Text('Ноя'),
                      InkWell(
                        onTap: (){
                          // "november_to_id"

                          monthSchedule = 11;
                          print(monthSchedule);
                          setState(() {});
                        },
                        child: Container(
                          height: 30.0,
                          width: 30.0,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5.0),
                            color:monthSchedule == 11 ? Colors.green : ColorApp.myColorGreen,
                          ),
                          child: const Center(child: Icon(Icons.add,color: Colors.white,size: 16.0)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 5.0),
                  /// 12
                  Column(
                    children: [
                      const Text('Дек'),
                      InkWell(
                        onTap: (){
                          //  "december_to_id"
                          monthSchedule = 12;
                          print(monthSchedule);
                          setState(() {});
                        },
                        child: Container(
                          height: 30.0,
                          width: 30.0,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(5.0),
                            color:monthSchedule == 12 ? Colors.green : ColorApp.myColorGreen,
                          ),
                          child: const Center(child: Text('TO12',style: TextStyle(color: Colors.white,fontSize: 11.0))),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 5.0),
                ],
              ),
              /// Кнопка год
              SizedBox(
                width: 100.0,
                height: 60.0,
                child: TextFormField(

                  cursorColor: ColorApp.myColorGray,
                  controller: addDataYearTO,
                  decoration:  InputDecoration(
                      suffixIcon: IconButton(onPressed: (){
                        if(addNewNameTO.text.isNotEmpty){
                          liftNotMOTO1.add(addNewNameTO.text);
                          print(addNewNameTO.text);
                          openBoolTo1 = false;
                          myStream.add(IntTest.indexScreens);
                          addNewNameTO.clear();
                        }
                        // openBoolTo1 = false;
                        addNewNameTO.clear();
                        // keyNameTO1.currentState!.validate();

                      }, icon: const Icon(Icons.calendar_month_outlined,color: Colors.green)),
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
            ],
          ),
        ),
      ),
    );
  }
}
