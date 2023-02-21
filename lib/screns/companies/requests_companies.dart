import 'dart:convert';

import 'package:http/http.dart' as http;

import '../auth/auth_log_and_pass/log_and_pass.dart';

// var token = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxIiwiZXhwIjoxNjczODgxOTI0LCJpYXQiOjE2NzMxOTA3MjQsIm5iZiI6MTY3MzE5MDcyNCwianRpIjoiMzc1ZTMxMDgtZGIyMC00MjM3LWEwMjYtNjA5N2MyNWZiMTU1In0.2gKt44kC0dTwFcoo7a8VN0jTZQ_XgRMajNyftXmuIsg';

///Получение данных всех компаний =====
// getListCompanies() async {
//   await Future(() async {
//     final res = await http
//         .get(Uri.parse('http://$myIp/api/v1/all-company/?page=1'), headers: {
//       "Content-Type": "application/json; charset=utf-8",
//       'Accept': 'application/json',
//       'Authorization': 'Bearer $token',
//     });
//     var vova = jsonDecode(utf8.decode(res.bodyBytes));
//     listCompanies = vova;
//     print('Получение данных всех сомпаний ${listCompanies['data'][0]}');
//   });
// }

///=======================================

/// Список сотрудников
// Map listCompanies = {};

///Класс компаний
// class Companies {
//   final int id;
//   final String nameCompanies;
//   final String nameDirector;
//   final String phoneCompanies;
//   final String addressCompanies;
//   final String photoCompanies;
//   final String emailCompanies;
//   final String siteCompanies;
//   final int locationId;
//   final String cityName;
//   // final bool isActual;
//
//   Companies({
//     required this.id,
//     required this.nameCompanies,
//     required this.nameDirector,
//     required this.phoneCompanies,
//     required this.addressCompanies,
//     required this.photoCompanies,
//     required this.emailCompanies,
//     required this.siteCompanies,
//     required this.locationId,
//     required this.cityName,
//     // required this.isActual,
//   });
// }

/// Список сотрудники
// final List<Companies> companies = [
//   for (var i = 0; i < listCompanies['data'].length; i++)
//     Companies(
//       id: listCompanies['data'][i]['id'] ?? 0,
//       nameCompanies: listCompanies['data'][i]['name'] ?? '',
//       nameDirector: listCompanies['data'][i]['director_name'] ?? '',
//       phoneCompanies: listCompanies['data'][i]['cont_phone'] ?? '',
//       addressCompanies: listCompanies['data'][i]['cont_address'] ?? '',
//       photoCompanies: 'http://${listCompanies['data'][i]['photo']}',
//       emailCompanies: listCompanies['data'][i]['email'] ?? '',
//       siteCompanies: listCompanies['data'][i]['site'] ?? '',
//       locationId: listCompanies['data'][i]['location_id']['id'] ?? 0,
//       cityName: listCompanies['data'][i]['location_id']['name'] ?? '',
//         // 'http://$myIp/api/v1/cp/all-employee/?page=1'
//     ),
// ];
