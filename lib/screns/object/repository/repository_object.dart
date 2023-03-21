import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:els/screns/employee/models/employee.dart';
import 'package:http/http.dart';

import '../../../helper/class_colors.dart';
import '../model/model_object.dart';

///Запрос списка Сотрудников

// class ObjectRepository {
//   final Dio _client = Dio(
//       BaseOptions(baseUrl: 'http://185.119.58.63/api/v1/all-objects/?page=1'));
//
//   Future<Iterable<ModelObject>> getModelObject() async {
//     final response = await _client.get('path');
//     return (response.data as List).map(
//       (json) => ModelObject(
//           id: json['id'],
//           name: json['name'],
//           email: json['email'],
//           contactPhone: json['contactPhone'],
//           birthday: json['birthday'],
//           photo: json['photo'],
//           locationId: json['locationId'],
//           locationIdName: json['locationIdName'],
//           roleId: json['roleId'],
//           roleIdName: json['roleIdName'],
//           workingSpecialtyId: json['workingSpecialtyId'],
//           identityCard: json['identityCard'],
//           qualificationFile: json['qualificationFile'],
//       ),
//     ).toList();
//   }
// // String endpoint = 'http://185.119.58.63/api/v1/all-objects/?page=1';
// // Future<List<Employee>> getUsers() async {
// //   Response response = await get(Uri.parse(endpoint),
// //       headers: {
// //         "Content-Type": "application/json; charset=utf-8",
// //         'Accept': 'application/json',
// //         'Authorization': 'Bearer ${IntTest.token}',
// //       }
// //   );
// //   if(response.statusCode == 200){
// //     final List result = jsonDecode(response.body)['data'];
// //     print(result);
// //     return result.map(((e) => ModelObject().fromJson(e))).toList();
// //   }else{
// //     throw Exception(response.reasonPhrase);
// //   }
// // }
// }
