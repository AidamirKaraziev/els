import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

import '../../helper/session.dart';
import '../../screns/user/user_contact.dart';

part 'user_event.dart';
part 'user_state.dart';

class UserBloc extends Bloc<UserEvent, UserState> {
  UserBloc() : super(UserInitial()) {
    on<UserGetEvent>(_getUser);
  }

  /// Отдаёт экранам профиль вошедшего.
  ///
  /// Сам профиль загружает `loadProfile` — она же ходит на `/auth/me`,
  /// заполняет `userProfile` и определяет роль. Блок к ней только
  /// пристраивается: к моменту события профиль обычно уже загружен входом
  /// или восстановлением сессии, и второй запрос за тем же самым не нужен.
  ///
  /// Прежний адрес `/cp/universal-user/me/` больше не существует: `me`
  /// теперь попадает в `/cp/universal-user/{user_id}/` и не разбирается
  /// как число.
  Future<void> _getUser(UserGetEvent event, Emitter<UserState> emit) async {
    if (userProfile.isEmpty) {
      final bool loaded = await loadProfile();
      if (!loaded) return;
    }
    emit(UserGetState(getUser: userProfile[0] as Map));
  }
}
