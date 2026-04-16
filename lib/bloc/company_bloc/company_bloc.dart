import 'dart:convert';
import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:http/http.dart' as http;
import '../../helper/class_colors.dart';
import '../../screns/companies/view/companies_screen.dart';

part 'company_event.dart';
part 'company_state.dart';

class CompanyBloc extends Bloc<CompanyEvent, CompanyState> {
  CompanyBloc() : super(CompanyInitial()) {
    on<CompanyGetUserEvent>(_getCompany);
  }
  _getCompany(CompanyGetUserEvent event, Emitter<CompanyState> emit) async {
    final res = await http.get(
        Uri.parse('http://${IntTest.myIp}/api/v1/all-company/?page=$newScreensCompany'),
        headers: {
          "Content-Type": "application/json; charset=utf-8",
          'Accept': 'application/json',
          'Authorization': 'Bearer ${IntTest.token}',
        });
    var getCompanyBloc = jsonDecode(utf8.decode(res.bodyBytes));
    dataCompany = getCompanyBloc['data'];
    // dataCompany = getCompany;
    // print('Получение из блок список Компаний ${getCompany}');
    // print('имя Компании ${getCompany['data']['name']} ===>>>>> актуальность ${getCompany['data']['is_actual']}');
  }
}
