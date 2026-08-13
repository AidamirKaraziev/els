import 'dart:convert';
import 'package:els/helper/api_config.dart';
import 'package:http/http.dart' as http;
import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';
import '../../../helper/class_colors.dart';
import '../view/task_screen.dart';
import 'package:els/helper/api_client.dart';

part 'task_event.dart';
part 'task_state.dart';

class TaskBloc extends Bloc<TaskEvent, TaskState> {
  TaskBloc() : super(TaskInitial()) {
    on<TaskGetEvent>(_getTask);

  }
  _getTask(TaskGetEvent event, Emitter<TaskState> emit) async {
    final res = await Api.get(
        Uri.parse('${ApiConfig.base}/order/all'),
        // Uri.parse('${ApiConfig.base}/order/for-me'),
        headers: {
          "Content-Type": "application/json; charset=utf-8",
          'Accept': 'application/json',
        });
    var vova = jsonDecode(utf8.decode(res.bodyBytes));
    getTask = vova['data'];
  }
}
