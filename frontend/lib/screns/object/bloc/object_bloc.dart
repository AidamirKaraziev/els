import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import '../../../helper/class_colors.dart';
import '../../home_page/home_page.dart';
import '../view/object_screen.dart';

part 'object_event.dart';
part 'object_state.dart';

// Map getObjectList = {};

class MyObjectBloc extends Bloc<MyObjectEvent, MyObjectState> {
  MyObjectBloc() : super(MyObjectState()) {
    on<ObjectGetEvent>(_getObject);
  }

  _getObject(ObjectGetEvent event, Emitter<MyObjectState> emit) async {
    final res = await http.get(
        Uri.parse('http://${IntTest.myIp}/api/v1/all-objects/?page=$newScreensObject'),
        headers: {
          "Content-Type": "application/json; charset=utf-8",
          'Accept': 'application/json',
          'Authorization': 'Bearer ${IntTest.token}',
        });
    var getObjectListBlock = jsonDecode(utf8.decode(res.bodyBytes));
    dataObject = getObjectListBlock['data'];
    getAllListOfObjects();
    // print(dataObject[0]);
    // print('Механик ======================================');
    // print(dataObject[0]['mechanic_id']);
    // print(dataObject[0]['mechanic_id']['is_actual']);
    // print('===============================================');

    // print('Прораб ========================================');
    // print(dataObject[0]['foreman_id']);
    // print(dataObject[0]['foreman_id']['is_actual']);
    // print('===============================================');
    myStream.add(IntTest.indexScreens);
  }
}

