/// «Назад» с экрана, который оболочка показывает по индексу.
///
/// Экраны подрядчика живут двумя жизнями: обычно они — тело корневого
/// маршрута своей оболочки, но карточку сотрудника мы открываем маршрутом
/// поверх карточки работы. Вернуть человека надо туда, откуда он пришёл, а
/// прежнее поведение внутри оболочки при этом тронуть нельзя.
library;

import 'package:els/helper/class_colors.dart';
import 'package:els/helper/session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Экран, который умеет уходить назад, — как карточка сотрудника.
class _Section extends StatelessWidget {
  const _Section({Key? key, required this.fallback}) : super(key: key);

  final int fallback;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: TextButton(
          onPressed: () => goBackFromSection(context, fallback),
          child: const Text('назад'),
        ),
      ),
    );
  }
}

void main() {
  setUp(() {
    idUserTest = Roles.foreman;
    IntTest.indexScreensForeman = 21;
  });

  tearDown(() {
    idUserTest = 0;
    IntTest.indexScreensForeman = 0;
  });

  testWidgets('внутри оболочки — переключает раздел, как было',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: _Section(fallback: 5)),
    );

    await tester.tap(find.text('назад'));
    await tester.pump();

    expect(IntTest.indexScreensForeman, 5);
  });

  testWidgets('поверх другого экрана — снимает маршрут, раздел не двигает',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (BuildContext context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const _Section(fallback: 5),
                  ),
                ),
                child: const Text('открыть'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('открыть'));
    await tester.pumpAndSettle();
    expect(find.text('назад'), findsOneWidget);

    await tester.tap(find.text('назад'));
    await tester.pumpAndSettle();

    // Вернулись на экран, с которого пришли, и раздел оболочки остался тем
    // же: под маршрутами всё это время лежит лента сданных работ.
    expect(find.text('открыть'), findsOneWidget);
    expect(find.text('назад'), findsNothing);
    expect(IntTest.indexScreensForeman, 21);
  });
}
