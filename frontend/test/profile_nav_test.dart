import 'package:els/helper/class_colors.dart';
import 'package:els/helper/session.dart';
import 'package:flutter_test/flutter_test.dart';

/// Переход в «Личный профиль» и обратно.
///
/// Проверяем именно то, чего не было: у каждой роли свой список экранов и
/// своя переменная с открытым разделом, а истории переходов нет вовсе.
void main() {
  setUp(() {
    IntTest.indexScreens = 0;
    IntTest.indexScreensForeman = 0;
    IntTest.indexScreensDispatcher = 0;
  });

  tearDown(() {
    idUserTest = 0;
  });

  test('прораб уходит в свой профиль и возвращается на свой раздел', () {
    idUserTest = Roles.foreman;
    IntTest.indexScreensForeman = 2;

    openProfile();
    expect(IntTest.indexScreensForeman, 24);
    // Чужие оболочки трогать нельзя: раньше аватарка правила именно их.
    expect(IntTest.indexScreens, 0);

    leaveProfile();
    expect(IntTest.indexScreensForeman, 2);
  });

  test('админ попадает в профиль, а не в «Охрану труда»', () {
    idUserTest = Roles.admin;
    IntTest.indexScreens = 4;

    openProfile();
    expect(IntTest.indexScreens, 9);

    leaveProfile();
    expect(IntTest.indexScreens, 4);
  });

  test('диспетчеру профиль тоже доступен', () {
    idUserTest = Roles.dispatcher;
    IntTest.indexScreensDispatcher = 2;

    expect(hasProfileScreen, isTrue);
    openProfile();
    expect(IntTest.indexScreensDispatcher, 4);

    leaveProfile();
    expect(IntTest.indexScreensDispatcher, 2);
  });

  test('повторный заход из профиля не затирает запомненный раздел', () {
    idUserTest = Roles.foreman;
    IntTest.indexScreensForeman = 3;

    openProfile();
    openProfile();

    leaveProfile();
    expect(IntTest.indexScreensForeman, 3);
  });

  test('без предыдущего раздела возврат ведёт на стартовый', () {
    idUserTest = Roles.foreman;

    openProfile();
    leaveProfile();

    expect(IntTest.indexScreensForeman, 0);
  });

  test('у ролей без экрана профиля перехода нет', () {
    idUserTest = Roles.client;
    IntTest.indexScreens = 1;

    expect(hasProfileScreen, isFalse);
    openProfile();
    expect(IntTest.indexScreens, 1);
  });
}
