part of 'company_bloc.dart';

@immutable
abstract class CompanyState {}

class CompanyInitial extends CompanyState {}

class CompanyGetState extends CompanyState {
  final List listGetCompany;

  CompanyGetState({required this.listGetCompany});
}
