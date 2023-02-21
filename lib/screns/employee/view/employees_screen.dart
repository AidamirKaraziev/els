import 'package:els/screns/employee/widgets/topButton.dart';
import 'package:flutter/material.dart';
import '../../../helper/class_colors.dart';
import '../widgets/add_employee_class.dart';

///Сотрудники ==================================================

class EmployeesScreen extends StatefulWidget {


  const EmployeesScreen({
    Key? key,
  }) : super(key: key);

  @override
  State<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends State<EmployeesScreen> {
  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return Container(
      color: ColorApp.myColorTransparent,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children:  [
                const TopButton(),
                const SizedBox(height: 20.0),
                CartInfoPeople(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

///=============================================================