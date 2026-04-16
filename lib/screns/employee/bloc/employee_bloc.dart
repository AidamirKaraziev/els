import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../helper/class_colors.dart';
import '../../home_page/home_page.dart';
import '../view/employees_screen.dart';
part 'employee_state.dart';
part 'employee_event.dart';

class EmployeeBloc extends Bloc<EmployeeEvent, EmployeeState> {
  EmployeeBloc() : super(EmployeeState()) {
    on<EmployeeGetUserEvent>(_getEmployee);
  }

  _getEmployee(EmployeeGetUserEvent event, Emitter<EmployeeState> emit) async {
    final res = await http.get(
        Uri.parse('http://${IntTest.myIp}/api/v1/cp/all-employee/?page=$newScreensEmployee'),
        headers: {
          "Content-Type": "application/json; charset=utf-8",
          'Accept': 'application/json',
          'Authorization': 'Bearer ${IntTest.token}',
        });
    var getEmployeeMap = jsonDecode(utf8.decode(res.bodyBytes));
    getEmployee = getEmployeeMap['data'];
    getEmployee.removeWhere((key) => key['role_id']['id'] == 1);

  }
}
