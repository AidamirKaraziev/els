import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

import '../../helper/class_colors.dart';
import '../../screns/user/user_contact.dart';

part 'user_event.dart';
part 'user_state.dart';


int idUserTest = 0;

class UserBloc extends Bloc<UserEvent, UserState> {
  UserBloc() : super(UserInitial()) {
    on<UserGetEvent>(_getUser);
  }
  _getUser(UserGetEvent event, Emitter<UserState> emit) async {
    final res = await http.get(
        Uri.parse('http://${IntTest.myIp}/api/v1/cp/universal-user/me/'),
        headers: {
          "Content-Type": "application/json; charset=utf-8",
          'Accept': 'application/json',
          'Authorization': 'Bearer ${IntTest.token}',
        });
    var getUserData = jsonDecode(utf8.decode(res.bodyBytes));
    emit(UserGetState(getUser: getUserData['data']));
    userProfile.add(getUserData['data']);
    idUserTest = userProfile[0]['role_id']['id'];
    // print('>>>>>>>>> id ==>${userProfile[0]['id']}<<<<<<<<<<');
    // print(getUserData);
  }

}
