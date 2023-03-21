import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import '../../../helper/class_colors.dart';
import '../model/model_object.dart';

part 'object_event.dart';
part 'object_state.dart';

class MyObjectBloc extends Bloc<MyObjectEvent, MyObjectState> {
  MyObjectBloc() : super(MyObjectState()) {
    on<ObjectGetEvent>(_getObject);
  }

  Map getObjectList = {};

  _getObject(ObjectGetEvent event, Emitter<MyObjectState> emit) async {
    final res = await http.get(
        Uri.parse('http://185.119.58.63/api/v1/all-objects/?page=1'),
        headers: {
          "Content-Type": "application/json; charset=utf-8",
          'Accept': 'application/json',
          'Authorization': 'Bearer ${IntTest.token}',
        });
    getObjectList = jsonDecode(utf8.decode(res.bodyBytes));
    emit(state.copyWith(modelObjectList: getObjectList['data']));
    print('Получение из Блок Обьекты ${getObjectList['data'][0]}');
  }
}










// Получение из Блок Обьекты {
// id: 1,
// organization_id: {
// id: 1,
// title: ПЛК,
// director_id: {
// id: 5,
// name: Андрей,
// email: andrey,
// contact_phone: +79180010015,
// birthday: 2005-03-18,
// photo: 185.119.58.63/api/v1/static/universal_user/5/photo/f14ece2ea9ce40d9a27bda9bc61a1f39.jpg,
// location_id: {
// id: 1,
// name: Краснодар},
// role_id: {
// id: 1,
// name: Администратор},
// working_specialty_id: {
// id: 2,
// name: Руководитель},
// identity_card: null,
// qualification_file: null,
// company_id: null,
// division_id: null,
// date_of_employment: null,
// is_actual: true},
// phone_office: null,
// phone_dispatcher: null,
// phone_accountant: null,
// photo: 185.119.58.63/api/v1/static/organization/1/photo/64a943f071254c43ae82f92c0c6b4c67.png,
// email: null, site: null,
// address: Ул. Котовского д. 42,
// is_actual: true}, division_id: {
// id: 1, title: Престиж 1,
// photo: null, is_actual: true},
// address: Красная 12 дом 11 подъезд 1,
// factory_model_id: {
// id: 1,
// type_object_id: {
// id: 1,
// name: lift_no_mr},
// factory: OTIS,
// model: SF-520},
// factory_number: 1123123,
// registration_number: 23444123213,
// number_of_stops: 12,
// lifting_heights: 0,
// load_capacity: 400,
// width: 0,
// cost_nds: 2450,
// cost_no_nds: 2000,
// company_id: {
// id: 3,
// name: ТАНДЕР,
// director_name: Виктор Олегович,
// cont_phone: 89457342893492,
// cont_address: г. Москва ул. Снежная д. 51,
// photo: null,
// email: tander@mail.ru,
// site: tander.com,
// location_id: {
// id: 1,
// name: Краснодар},
// is_actual: true},
// contact_person_id: {
// id: 1,
// name: Фернан Мондего,
// company_id: {
// id: 2, name: ООО ТАНДЕР,
// director_name: Виктор Павлович,
// cont_phone: 88005353535,
// cont_address: Северная 34,
// photo: null,
// email: tander@gmail.com,
// site: null, location_id: {
// id: 1, name: Краснодар},
// is_actual: true},
// phone: 89881133555,
// email: fernan@mail.ru,
// address: Московская 5,
// photo: null, is_actual: true},
// contract_id: {
// id: 1,
// company_id: {
// id: 2,
// name: ООО ТАНДЕР,
// director_name: Виктор Павлович,
// cont_phone: 88005353535,
// cont_address: Северная 34,
// photo: null,
// email: tander@gmail.com,
// site: null,
// location_id: {
// id: 1, name: Краснодар},
// is_actual: true},
// title: тандер ндс,
// validity_period: 1970-05-23,
// type_contract_id: {
// id: 1,
// name: Коммерческий},
// cost_type_id: {
// id: 1,
// name: с НДС},
// file: null,
// is_actual: true},
// date_inspection: 1970-01-01,
// planned_inspection: 1970-01-01,
// period_inspection: 1970-01-01,
// foreman_id: {
// id: 20,
// name: Изменил Вова Только Что,
// email: Антон.@mail.ru,
// contact_phone: 3333333333,
// birthday: 2023-03-05,
// photo: null, location_id: {
// id: 1, name: Краснодар},
// role_id: {
// id: 2,
// name: Прораб},
// working_specialty_id: {
// id: 2,
// name: Руководитель},
// identity_card: null,
// qualification_file: null,
// company_id: null,
// division_id: {
// id: 2, title: Триумф 2,
// photo: null,
// is_actual: true},
// date_of_employment: 2023-03-05,
// is_actual: false},
// mechanic_id: {
// id: 9,
// name: Геннадий Анатольевич,
// email: mech1,
// contact_phone: +79283323477,
// birthday: 1977-01-16,
// photo: 185.119.58.63/api/v1/static/universal_user/9/photo/dd3ba1187f2044b48c49afcdbef408d4.jpg,
// location_id: {
// id: 1,
// name: Краснодар},
// role_id: {
// id: 3,
// name: Механик},
// working_specialty_id: null,
// identity_card: null,
// qualification_file: null,
// company_id: null,
// division_id: {
// id: 1, title: Престиж 1,
// photo: null,
// is_actual: true},
// date_of_employment: null,
// is_actual: true},
// letter_of_appointment: null,
// acceptance_certificate: null,
// act_pto: null,
// geo: 45.016798, 38.968863,
// is_actual: true}
