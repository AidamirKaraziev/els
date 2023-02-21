part of 'employee_bloc.dart';

abstract class EmployeeEvent  {}

class EmployeeGetUserEvent extends EmployeeEvent {}

class EmployeeViewUserEvent extends EmployeeEvent {
  // final int userId;
  //
  // EmployeeViewUserEvent(this.userId);
}

