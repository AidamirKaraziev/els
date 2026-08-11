part of 'employee_bloc.dart';

 class EmployeeState {
  final List listGetEmployee;
  final List listGetEmployeeView;
  final bool isLoading;

  EmployeeState({
    this.listGetEmployee = const [],
    this.listGetEmployeeView = const [],
    this.isLoading = false,
  });

  EmployeeState copyWith({
    List? listGetEmployee,
    List? listGetEmployeeView,
    bool isLoading = false,
  }) {
    return EmployeeState(
      listGetEmployee: listGetEmployee ?? this.listGetEmployee,
      listGetEmployeeView: listGetEmployeeView ?? this.listGetEmployeeView,
        isLoading: isLoading,
    );
  }
}

