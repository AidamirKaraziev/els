import 'dart:convert';
import 'package:els/helper/api_config.dart';
import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import 'package:http/http.dart' as http;
import '../../helper/class_colors.dart';
import '../../screns/companies/view/companies_screen.dart';
import 'package:els/helper/api_client.dart';

part 'company_event.dart';
part 'company_state.dart';

class CompanyBloc extends Bloc<CompanyEvent, CompanyState> {
  CompanyBloc() : super(CompanyInitial()) {
    on<CompanyGetUserEvent>(_getCompany);
  }
  _getCompany(CompanyGetUserEvent event, Emitter<CompanyState> emit) async {
    final res = await Api.get(
        Uri.parse('${ApiConfig.base}/all-company/?page=$newScreensCompany'),
        headers: {
          "Content-Type": "application/json; charset=utf-8",
          'Accept': 'application/json',
        });
    var getCompanyBloc = jsonDecode(utf8.decode(res.bodyBytes));
    dataCompany = getCompanyBloc['data'];
    // dataCompany = getCompany;
    // print('Получение из блок список Компаний ${getCompany}');
    // print('имя Компании ${getCompany['data']['name']} ===>>>>> актуальность ${getCompany['data']['is_actual']}');
  }
}
