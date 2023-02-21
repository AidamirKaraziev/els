import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:els/screns/employee/models/employee.dart';
import 'package:http/http.dart';

import '../../../helper/class_colors.dart';


///Запрос списка Сотрудников

// class UserRepository {
//   String endpoint = 'https://reqres.in/api/users?page=2';
//   Future<List<Employee>> getUsers() async {
//     Response response = await get(Uri.parse(endpoint),
//         headers: {
//           "Content-Type": "application/json; charset=utf-8",
//           'Accept': 'application/json',
//           'Authorization': 'Bearer ${IntTest.token}',
//         }
//     );
//     if(response.statusCode == 200){
//       final List result = jsonDecode(response.body)['data'];
//       print(result);
//       return result.map(((e) => Employee().fromJson(e))).toList();
//     }else{
//       throw Exception(response.reasonPhrase);
//     }
//   }
// }
///==========================
// class EmployeeRepository {
//   Future<List<Employee>> getEmployee() async {
//     final res = await http.get(
//         Uri.parse('http://${IntTest.myIp}/api/v1/cp/all-employee/?page=1'),
//         headers: {
//           "Content-Type": "application/json; charset=utf-8",
//           'Accept': 'application/json',
//           'Authorization': 'Bearer ${IntTest.token}',
//         });
//     return (res as List)
//         .map((json) => Employee(
//               id: json['data']['id'],
//               name: json['data']['name'],
//               email: json['data']['email'],
//               contactPhone: json['data']['contact_phone'],
//               birthday: json['data']['birthday'],
//               photo: json['data']['photo'],
//               locationId: json['data']['location_id']['id'],
//               locationIdName: json['data']['location_id']['name'],
//               roleId: json['data']['role_id']['id'],
//               roleIdName: json['data']['role_id']['name'],
//               workingSpecialtyId: json['data']['working_specialty_id'],
//               identityCard: json['data']['identity_card'],
//               qualificationFile: json['data']['qualification_file'],
//             ))
//         .toList();
//   }
// }


// class EmployeeRepository {
//   String endpoint = 'http://${IntTest.myIp}/api/v1/cp/all-employee/?page=1';
//   Future<List> getEmployee() async {
//     var response = await get(Uri.parse(endpoint),
//         headers: {
//           "Content-Type": "application/json; charset=utf-8",
//           'Accept': 'application/json',
//           'Authorization': 'Bearer ${IntTest.token}',
//         }
//     );
//     if(response.statusCode == 200){
//       final List result = jsonDecode(response.body)['data'];
//       print(result);
//       return result.map(((e) => Employee.fromJson(e))).toList();
//     }else{
//       throw Exception(response.reasonPhrase);
//     }
//   }
// }