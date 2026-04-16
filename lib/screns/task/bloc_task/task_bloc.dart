import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import '../../../helper/class_colors.dart';
import '../view/task_screen.dart';

part 'task_event.dart';
part 'task_state.dart';

class TaskBloc extends Bloc<TaskEvent, TaskState> {
  TaskBloc() : super(TaskInitial()) {
    on<TaskGetEvent>(_getTask);

  }
  _getTask(TaskGetEvent event, Emitter<TaskState> emit) async {
    final res = await http.get(
        Uri.parse('http://${IntTest.myIp}/api/v1/order/all'),
        // Uri.parse('http://${IntTest.myIp}/api/v1/order/for-me'),
        headers: {
          "Content-Type": "application/json; charset=utf-8",
          'Accept': 'application/json',
          'Authorization': 'Bearer ${IntTest.token}',
        });
    var vova = jsonDecode(utf8.decode(res.bodyBytes));
    getTask = vova['data'];
  }
}
