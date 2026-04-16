part of 'task_bloc.dart';

@immutable
abstract class TaskState {}

class TaskInitial extends TaskState {}

class TaskGetState extends TaskState {
  final List listGetTask;
  TaskGetState({required this.listGetTask});
}
