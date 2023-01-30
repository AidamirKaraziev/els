import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';
import '../class_colors.dart';

///Календарь

DateRangePickerController myCalendar = DateRangePickerController();

class MyCalendar extends StatelessWidget {
  const MyCalendar({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: SizedBox(
        width: 270,
        height: 350,
        child: Column(
          children: [
            SfDateRangePicker(
              monthCellStyle: DateRangePickerMonthCellStyle(
                todayCellDecoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(color: ColorApp.myColorGreenAuth)),
                todayTextStyle: const TextStyle(color: ColorApp.myColorGreenAuth),
              ),
              headerStyle: const DateRangePickerHeaderStyle(
                textAlign: TextAlign.center,
              ),
              controller: myCalendar,
              monthViewSettings: const DateRangePickerMonthViewSettings(firstDayOfWeek: 1),
              selectionMode: DateRangePickerSelectionMode.range,
              rangeSelectionColor: ColorApp.myColorGreenLine,
              startRangeSelectionColor: ColorApp.myColorGreen,
              endRangeSelectionColor: ColorApp.myColorGreen,
            ),
            ///Кнопки Отмена и Выбрать
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                /// Отмена
                Expanded(
                  child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20.0,
                            vertical: 10.0),
                        side: const BorderSide(
                            color: ColorApp.myColorGreenAuth,
                            width: 1.0),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius.circular(20.0),
                        ),
                      ),
                      onPressed: () {
                        myCalendar.selectedRanges = null;
                        Navigator.pop(context);
                      },
                      child: const Text('Отмена',
                          style: TextStyle(
                              fontSize: 10.0,
                              color:
                              ColorApp.myColorGreenAuth))),
                ),
                const SizedBox(width: 10.0),
                /// Выбрать
                Expanded(
                  child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20.0,
                            vertical: 10.0),
                        side: const BorderSide(
                            color: ColorApp.myColorGreenAuth,
                            width: 1.0),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius.circular(20.0),
                        ),
                      ),
                      onPressed: () {},
                      child: const Text('Выбрать',
                          style: TextStyle(
                              fontSize: 10.0,
                              color: ColorApp.myColorGreenAuth))),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// ============================================================
var myDataCalendar = DateFormat.MMMM('ru').format(DateTime.now());
/// ============================================================

class MyDataCalendar extends StatelessWidget {
  const MyDataCalendar({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: (){
        showDialog(
            context: context,
            builder: (context) {
              return const MyCalendar();
            });
      },
      child: Row(
        children: [
          const Icon(Icons.chevron_left),
          Text(
            myDataCalendar,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}
