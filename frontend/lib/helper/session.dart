/// Сессия приложения: кто вошёл, куда его вести и как выйти.
///
/// Раньше это было размазано: роль вычислялась в блоке пользователя,
/// маршрут выбирался в заставке по таймеру на две секунды, а выхода не было
/// вовсе. Здесь всё в одном месте, потому что и вход, и восстановление
/// сессии при старте, и увод на экран входа по протухшему токену должны
/// вести себя одинаково.
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../bloc/company_bloc/company_bloc.dart';
import '../bloc/user_bloc/user_bloc.dart';
import '../dispatcher/home_dispatcher.dart';
import '../foreman/home_foreman.dart';
import '../mechanic/mechanic_shell.dart';
import '../owner/home_owner.dart';
import '../screns/auth/auth.dart';
import '../screns/auth/role_stub_screen.dart';
import '../screns/employee/bloc/employee_bloc.dart';
import '../screns/home_page/home_page.dart';
import '../screns/object/bloc/object_bloc.dart';
import '../screns/task/bloc_task/task_bloc.dart';
import '../screns/user/user_contact.dart';
import 'api_client.dart';
import 'api_config.dart';
import 'class_colors.dart';

import 'package:flutter_bloc/flutter_bloc.dart';

/// Ключ навигатора приложения.
///
/// Нужен клиенту API: увести человека на экран входа он обязан, а
/// `BuildContext` ему взять неоткуда — запрос уходит не из виджета.
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

/// Идентификаторы ролей. Те же числа, что в `backend/src/core/roles.py`;
/// бэкенд отдаёт их в `/auth/me` полем `role_id: {id, name}`.
class Roles {
  static const int admin = 1;
  static const int foreman = 2;
  static const int mechanic = 3;
  static const int engineer = 4;
  static const int dispatcher = 5;
  static const int client = 6;

  static const Map<int, String> names = <int, String>{
    admin: 'Админ',
    foreman: 'Прораб',
    mechanic: 'Механик',
    engineer: 'Инженер наладчик',
    dispatcher: 'Диспетчер',
    client: 'Клиент',
  };
}

/// Роль вошедшего. Экраны читают её напрямую — так было и раньше, когда она
/// лежала в блоке пользователя. Ноль означает «профиль ещё не загружен».
int idUserTest = 0;

/// Стоим ли мы уже на экране входа.
///
/// Запросов в полёте бывает несколько, и `401` придёт по каждому. Без этого
/// флага навигатор перестраивал бы экран входа столько раз, сколько было
/// неудачных запросов.
bool _atLogin = false;

/// Загружает профиль вошедшего и запоминает его роль.
///
/// Профиль лежит в глобальном `userProfile`, из которого читают 73 места
/// экранов. Возвращает `false`, если профиль получить не вышло — это значит
/// «сессии нет», и звать надо экран входа.
Future<bool> loadProfile() async {
  http.Response response;
  try {
    response = await Api.get(Uri.parse('${ApiConfig.base}/auth/me'));
  } catch (_) {
    // Сети нет. Это не «выйдите из системы», это «сейчас не получилось».
    return false;
  }

  if (response.statusCode != 200) return false;

  final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));
  final dynamic data = decoded is Map ? decoded['data'] : null;
  if (data is! Map) return false;

  // Именно заменяем, а не дополняем: при повторном входе под нулевым
  // индексом остался бы прежний человек, а его читают все экраны.
  userProfile
    ..clear()
    ..add(data);

  final dynamic role = data['role_id'];
  idUserTest = role is Map && role['id'] is int ? role['id'] as int : 0;
  return true;
}

/// Экран, на который попадает человек с такой ролью.
///
/// Механик получает свою оболочку — четыре вкладки по макету «Механик |
/// Мобильная версия», локальную базу и очередь исходящих действий.
/// Инженер-наладчик пока остаётся на заглушке: работа у него та же, но
/// оболочка сделана и проверена под механика, а пускать в неё роль, которую
/// никто не смотрел, — значит выдать непроверенный экран за готовый.
/// Показать обоим админский набор нельзя: половина его кнопок ответит `403`,
/// потому что по матрице прав эти роли не заводят людей и не правят
/// справочники.
Widget homeScreenForRole(int roleId) {
  switch (roleId) {
    case Roles.admin:
      return const HomePage();
    case Roles.foreman:
      return const HomeForeman();
    case Roles.dispatcher:
      return const HomeDispatcher();
    case Roles.client:
      return const HomeOwner();
    case Roles.mechanic:
      return const MechanicShell();
    case Roles.engineer:
      return RoleStubScreen(roleId: roleId);
    default:
      // Роль неизвестна — показывать наугад нельзя, это выдача чужих данных.
      return RoleStubScreen(roleId: roleId);
  }
}

/// Догружает списки, которые экраны ждут готовыми.
///
/// Раньше эти пять событий стреляли в `main` — то есть до входа, с пустым
/// токеном. Пока ручки были открыты, это работало; теперь каждое такое
/// обращение получает `401`.
void primeData(BuildContext context) {
  // Механику эти списки не нужны вовсе: его оболочка не читает ни один из
  // этих блоков, а данные берёт из локальной базы. Пять запросов на старте —
  // это ровно та болезнь, от которой лечили фронт: телефон на объекте платит
  // за них трафиком и батареей, а показать ему нечего.
  if (idUserTest == Roles.mechanic) return;

  context.read<UserBloc>().add(UserGetEvent());
  context.read<MyObjectBloc>().add(ObjectGetEvent());
  context.read<TaskBloc>().add(TaskGetEvent());

  // Клиенту сотрудники и контрагенты закрыты правами — спрашивать их значит
  // гарантированно получить `403` на старте каждого его сеанса.
  if (idUserTest != Roles.client) {
    context.read<EmployeeBloc>().add(EmployeeGetUserEvent());
    context.read<CompanyBloc>().add(CompanyGetUserEvent());
  }
}

/// Статус заявки «Выполнено». Идентификаторы статусов заданы справочником и
/// не меняются: 2 и 3 — в работе, 4 — выполнено, 5 — отклонено.
const int statusDone = 4;

/// Может ли вошедший поставить заявке такой статус.
///
/// Закрывать заявки диспетчер больше не может. Право `order:close`
/// существовало и раньше, но его не спрашивала ни одна ручка: закрытие
/// отличается от обычной правки не адресом, а телом запроса. Теперь
/// `PUT /order/{id}/` со `status_id: 4` отвечает диспетчеру `403` с кодом
/// `1023`, поэтому и в списке статусов этот пункт ему показывать нечестно.
/// Остальные статусы он ставит как прежде.
bool canPickStatus(dynamic status) {
  final dynamic id = status is Map ? status['id'] : null;
  if (id != statusDone) return true;
  return idUserTest != Roles.dispatcher;
}

/// Забывает вошедшего. Токены гасит `Api.logout`, здесь — данные экранов.
void resetSession() {
  userProfile.clear();
  newUserProfile.clear();
  idUserTest = 0;
}

/// Выход по кнопке: гасит сессию на бэкенде и ведёт на экран входа.
Future<void> signOut() async {
  await Api.logout();
  resetSession();
  goToLogin();
}

/// Увести на экран входа, не спрашивая ни у кого разрешения.
///
/// Зовётся из двух мест: кнопкой выхода и клиентом API, когда обновить
/// токен не удалось.
void goToLogin() {
  if (_atLogin) return;

  final NavigatorState? navigator = appNavigatorKey.currentState;
  if (navigator == null) return;

  _atLogin = true;
  resetSession();
  navigator.pushAndRemoveUntil(
    MaterialPageRoute<void>(builder: (_) => const Auth()),
    (Route<dynamic> route) => false,
  );
}

/// Вход состоялся — снимаем флаг, иначе следующий `401` не сработает.
void markSignedIn() {
  _atLogin = false;
}

/// ===== Переход в «Личный профиль» и обратно =====
///
/// Оболочки подрядчика держат открытый раздел одной глобальной переменной на
/// роль (`IntTest.indexScreens*`) и перерисовываются по `myStream`. Истории
/// переходов в них нет вовсе, поэтому «назад» из профиля приходится делать
/// руками: запоминаем раздел перед уходом и возвращаем его.
///
/// Одной переменной хватает: у вошедшего оболочка одна, сменить роль без
/// повторного входа нельзя.

/// Индекс экрана `MyProfile` в списке экранов своей оболочки.
///
/// Числа разные, потому что списки у ролей разные и собраны подрядчиком в
/// произвольном порядке. Экраны тоже разные: у админа это `MyProfile`, у
/// прораба `OpenViewUserForeman`, у диспетчера `OpenViewUserDispatcher` —
/// три копии одного и того же, унаследованные от подрядчика. Роли, которой
/// здесь нет, профиль не показывается: у механика своя оболочка со своей
/// вкладкой, у владельца экрана нет.
const Map<int, int> _profileIndex = <int, int>{
  Roles.admin: 9,
  Roles.foreman: 24,
  Roles.dispatcher: 4,
};

/// Раздел, с которого зашли в профиль. `null` — заходили не из раздела
/// (например, сразу после входа), тогда «назад» ведёт на стартовый.
int? _sectionBeforeProfile;

/// Показывать ли этой роли переход в профиль по аватарке.
bool get hasProfileScreen => _profileIndex.containsKey(idUserTest);

/// Открытый сейчас раздел своей оболочки.
int _currentSection() {
  switch (idUserTest) {
    case Roles.foreman:
      return IntTest.indexScreensForeman;
    case Roles.dispatcher:
      return IntTest.indexScreensDispatcher;
    default:
      return IntTest.indexScreens;
  }
}

/// Переключить раздел и перерисовать оболочку.
void _setSection(int index) {
  switch (idUserTest) {
    case Roles.foreman:
      IntTest.indexScreensForeman = index;
      break;
    case Roles.dispatcher:
      IntTest.indexScreensDispatcher = index;
      break;
    default:
      IntTest.indexScreens = index;
  }
  myStream.add(index);
}

/// Уйти в «Личный профиль», запомнив, откуда пришли.
///
/// Повторное нажатие по аватарке, когда профиль уже открыт, не должно
/// затирать запомненный раздел — иначе «назад» вернёт в сам профиль.
void openProfile() {
  final int? target = _profileIndex[idUserTest];
  if (target == null) return;

  final int current = _currentSection();
  if (current == target) return;

  _sectionBeforeProfile = current;
  _setSection(target);
}

/// Вернуться из профиля туда, откуда зашли.
///
/// Стартовый раздел у всех оболочек нулевой: у админа «Главная», у прораба
/// «Объекты», у диспетчера «Заявки».
void leaveProfile() {
  _setSection(_sectionBeforeProfile ?? 0);
  _sectionBeforeProfile = null;
}

/// «Назад» с экрана, который оболочка показывает по индексу.
///
/// Такой экран живёт двумя жизнями. Обычно он — тело корневого маршрута своей
/// оболочки, и «назад» в нём значит «переключить индекс на [fallbackSection]»:
/// снимать нечего, маршрут один. Но его же можно открыть маршрутом поверх
/// другого экрана — тогда «назад» обязано снять маршрут, иначе человек жмёт
/// кнопку, а на экране ничего не меняется.
///
/// Различаем по [Navigator.canPop]: внутри оболочки попать некуда, поверх
/// чужого экрана — есть куда. Так карточка сотрудника, открытая из карточки
/// работы, возвращает в неё же, а открытая из списка сотрудников — в список,
/// как было.
void goBackFromSection(BuildContext context, int fallbackSection) {
  final NavigatorState navigator = Navigator.of(context);
  if (navigator.canPop()) {
    navigator.pop();
    return;
  }
  _setSection(fallbackSection);
}
