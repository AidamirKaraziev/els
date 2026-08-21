import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../class_colors.dart';

///Кнопка SideBar ===================================
class MenuButton extends StatefulWidget {
  final String title;
  final VoidCallback press;
  final IconData myIcons;
  final Color colorButton;

  /// Что стоит в конце строки — числа у пункта меню.
  ///
  /// Раньше их клали поверх кнопки через `Stack`, и с тремя числами они
  /// наезжали на заголовок: «Сданные работ» без последней буквы. Здесь они
  /// занимают своё место, а заголовку остаётся всё остальное.
  final Widget? trailing;

  const MenuButton({
    Key? key,
    required this.title,
    required this.press,
    required this.myIcons,
    required this.colorButton,
    this.trailing,
  }) : super(key: key);

  @override
  State<MenuButton> createState() => _MenuButtonState();
}

class _MenuButtonState extends State<MenuButton> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5.0),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(10),
            hoverColor: ColorApp.myColorTransparent,
            onTap: widget.press,
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: widget.colorButton,
                borderRadius: BorderRadius.circular(10.0),
                // color: Colors.red
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(width: 10.0),
                  Icon(
                    widget.myIcons,
                    color: ColorApp.myColorGreenAuth,
                  ),
                  const SizedBox(width: 10.0),
                  // Без чисел заголовок живёт как жил — своей шириной: так
                  // ведут себя все остальные пункты меню, и трогать их
                  // раскладку заодно ни к чему.
                  if (widget.trailing == null)
                    Text(
                      widget.title,
                      style: const TextStyle(
                          fontSize: 15.0, fontWeight: FontWeight.w500),
                    )
                  else ...[
                    Expanded(
                      child: Text(
                        widget.title,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 15.0, fontWeight: FontWeight.w500),
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    widget.trailing!,
                    const SizedBox(width: 8.0),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 10.0),
        ],
      ),
    );
  }
}

/// ==================================================

///Заявки
var numberApplications = 5;

///Отчеты
var numberReports = 3;
Color indicatorColor = Colors.transparent;

///Охрана Труда
var numberLaborProtection = 2;

///Задачи
var numberTask = 4;

/// Функция перемены цвета по цифре
myColorAlert() {
  if (numberApplications >= 6) {
    indicatorColor = ColorApp.myColorRed;
  } else if (numberApplications <= 3) {
    indicatorColor = ColorApp.myColorGreen;
  } else if (numberApplications >= 4) {
    indicatorColor = ColorApp.myColorYellow;
  } else {
    indicatorColor = ColorApp.myColorTransparent;
  }
}

/// ===============================

/// Класс перемены цвета по цифре ==============
class AlertsWidget extends StatelessWidget {
  const AlertsWidget({
    Key? key,
    required this.alertsNumber,
    required this.myColor,
  }) : super(key: key);

  final Color myColor;

  // ignore: prefer_typing_uninitialized_variables
  final alertsNumber;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5.0),
        color: myColor,
      ),
      width: 25,
      height: 25,
      child: Center(
          child: Text(
            '$alertsNumber',
            style:
            const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
          )),
    );
  }
}
/// ============================================
