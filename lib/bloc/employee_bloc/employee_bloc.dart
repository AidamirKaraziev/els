import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../helper/class_colors.dart';
import '../../screns/auth/auth_log_and_pass/log_and_pass.dart';

part 'employee_state.dart';
part 'employee_event.dart';



class EmployeeBloc extends Bloc<EmployeeEvent, EmployeeState> {
  EmployeeBloc() : super(EmployeeInitialState()) {
    on<EmployeeGetUserEvent>(_getEmployee);
  }

  _getEmployee(EmployeeGetUserEvent event, Emitter<EmployeeState> emit) async {
    final res = await http.get(
        Uri.parse('http://${IntTest.myIp}/api/v1/cp/all-employee/?page=1'),
        headers: {
          "Content-Type": "application/json; charset=utf-8",
          'Accept': 'application/json',
          'Authorization': 'Bearer ${IntTest.token}',
        });
    var getEmployee = jsonDecode(utf8.decode(res.bodyBytes));
    print('Получение из блок Сотрудников ${getEmployee['data'][0]}');
    for (var i = 0; i < getEmployee.length; i++) {
      emit(EmployeeGetUserState(listGetEmployee: getEmployee['data']));
    }
  }
}
