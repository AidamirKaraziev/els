part of 'employee_bloc.dart';

abstract class EmployeeState  {}

class EmployeeInitialState extends EmployeeState{}

class EmployeeGetUserState extends EmployeeState {
  final List listGetEmployee;

  EmployeeGetUserState({required this.listGetEmployee});
}






