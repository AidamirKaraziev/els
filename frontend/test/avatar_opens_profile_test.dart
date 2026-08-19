import 'package:els/foreman/user_page_foreman.dart';
import 'package:els/helper/class_colors.dart';
import 'package:els/helper/session.dart';
import 'package:els/screns/user/user_contact.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Нажатие по аватарке в шапке уводит в профиль своей роли.
void main() {
  setUp(() {
    IntTest.indexScreensForeman = 0;
    userProfile
      ..clear()
      ..add(<String, dynamic>{'id': 3, 'photo': null});
  });

  tearDown(() {
    idUserTest = 0;
    userProfile.clear();
  });

  testWidgets('аватарка прораба открывает профиль', (WidgetTester tester) async {
    idUserTest = Roles.foreman;
    IntTest.indexScreensForeman = 5;

    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: Center(child: MyUserForeman())),
    ));

    await tester.tap(find.byType(MyUserForeman));
    await tester.pump();

    expect(IntTest.indexScreensForeman, 24);
  });
}
