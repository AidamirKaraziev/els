import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../helper/class_colors.dart';
part 'employee_state.dart';
part 'employee_event.dart';

class EmployeeBloc extends Bloc<EmployeeEvent, EmployeeState> {
  EmployeeBloc() : super(EmployeeState()) {
    on<EmployeeGetUserEvent>(_getEmployee);
    on<EmployeeViewUserEvent>(_getViewEmployee);
  }

  // final EmployeeBloc apiEmployee = EmployeeBloc();

  _getEmployee(EmployeeGetUserEvent event, Emitter<EmployeeState> emit) async {
    final res = await http.get(
        Uri.parse('http://${IntTest.myIp}/api/v1/cp/all-employee/?page=1'),
        headers: {
          "Content-Type": "application/json; charset=utf-8",
          'Accept': 'application/json',
          'Authorization': 'Bearer ${IntTest.token}',
        });
    var getEmployee = jsonDecode(utf8.decode(res.bodyBytes));
    emit(state.copyWith(listGetEmployee: getEmployee['data']));
    print(getEmployee['data'][0]);
  }

  _getViewEmployee(EmployeeViewUserEvent event, Emitter<EmployeeState> emit) async {
    final res = await http.get(
        Uri.parse('http://${IntTest.myIp}/api/v1/cp/all-employee/?page=1'),
        headers: {
          "Content-Type": "application/json; charset=utf-8",
          'Accept': 'application/json',
          'Authorization': 'Bearer ${IntTest.token}',
        });
    var getEmployee = jsonDecode(utf8.decode(res.bodyBytes));
    print('Получение из блок выбранного сотрудника ${getEmployee['data'][0]['name']}');
    emit(state.copyWith(listGetEmployeeView: getEmployee['data']));
  }
}
