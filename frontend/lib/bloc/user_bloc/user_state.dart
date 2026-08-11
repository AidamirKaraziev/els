part of 'user_bloc.dart';

@immutable
abstract class UserState {}

class UserInitial extends UserState {}

class UserGetState extends UserState {
  final Map getUser;
  UserGetState({required this.getUser});
}

