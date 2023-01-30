import 'dart:convert';
import 'package:bloc/bloc.dart';
import 'package:els/screns/auth/auth_log_and_pass/log_and_pass.dart';
import 'package:meta/meta.dart';
import 'package:http/http.dart' as http;

import '../../helper/class_colors.dart';

part 'company_event.dart';
part 'company_state.dart';

class CompanyBloc extends Bloc<CompanyEvent, CompanyState> {
  CompanyBloc() : super(CompanyInitial()) {
    on<CompanyGetUserEvent>(_getCompany);
  }
  _getCompany(CompanyGetUserEvent event, Emitter<CompanyState> emit) async {
    final res = await http.get(
        Uri.parse('http://${IntTest.myIp}/api/v1/all-company/?page=1'),
        headers: {
          "Content-Type": "application/json; charset=utf-8",
          'Accept': 'application/json',
          'Authorization': 'Bearer ${IntTest.token}',
        });
    var getCompany = jsonDecode(utf8.decode(res.bodyBytes));
    print('Получение из блок список Компаний : ${getCompany['data']}');
    for (var i = 0; i < getCompany.length; i++) {
      emit(CompanyGetState(listGetCompany: getCompany['data']));
    }
  }
}
