/// Экран чек-листа ТО: что можно нажать и когда.
///
/// Проверяется правило, а не вёрстка: до начала работы регламент открывается
/// **на просмотр** — отметить пункт и закрыть акт оттуда нельзя. Если это
/// сломается, механик отметит пункты в ТО, за которое ещё не брался, и прораб
/// увидит работу сделанной.
library;

import 'package:els/mechanic/data/acts.dart';
import 'package:els/mechanic/data/tasks.dart';
import 'package:els/mechanic/screens/act_steps_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

ActDetails act({bool secondDone = false}) {
  return ActDetails(
    id: 2481,
    title: 'ТО-1',
    steps: <ActStep>[
      const ActStep(id: 1, title: 'Осмотр машинного помещения', done: true),
      ActStep(id: 2, title: 'Проверка тормоза лебёдки', done: secondDone),
      const ActStep(id: 3, title: 'Осмотр канатов'),
    ],
  );
}

MechanicTask task() {
  return const MechanicTask(
    kind: TaskKind.maintenance,
    id: 2481,
    title: 'Лифт 12',
    section: TaskSection.maintenance,
    rank: 1,
    order: 0,
    badge: 'ТО',
    address: 'улица Ленина 45',
    raw: <String, dynamic>{
      'act_id': 2481,
      'year': 2026,
      'month': 8,
      'steps_total': 3,
      'steps_done': 1,
    },
  );
}

Future<void> show(WidgetTester tester, {required bool viewOnly}) {
  return tester.pumpWidget(
    MaterialApp(
      home: MechanicActStepsScreen(
        task: task(),
        act: act(),
        viewOnly: viewOnly,
      ),
    ),
  );
}

void main() {
  testWidgets('в работе видны прогресс, пункты и кнопка завершения',
      (WidgetTester tester) async {
    await show(tester, viewOnly: false);
    await tester.pumpAndSettle();

    expect(find.text('Пройдено 1 из 3'), findsOneWidget);
    expect(find.text('Осмотр канатов'), findsOneWidget);
    expect(find.text('Завершить работу'), findsOneWidget);
    expect(find.text('2 не отмечено'), findsOneWidget);
  });

  testWidgets('на просмотре завершить работу нельзя', (WidgetTester tester) async {
    await show(tester, viewOnly: true);
    await tester.pumpAndSettle();

    expect(find.text('Осмотр канатов'), findsOneWidget);
    expect(find.text('Завершить работу'), findsNothing);
    expect(
      find.textContaining('Чтобы отмечать пункты, начните ТО'),
      findsOneWidget,
    );
  });

  testWidgets('отметка пункта видна сразу, не дожидаясь сервера',
      (WidgetTester tester) async {
    await show(tester, viewOnly: false);
    await tester.pumpAndSettle();

    // Второй квадратик — пункт «Проверка тормоза лебёдки».
    await tester.tap(find.byType(InkWell).at(3));
    await tester.pumpAndSettle();

    expect(find.text('Пройдено 2 из 3'), findsOneWidget);
    expect(find.text('1 не отмечено'), findsOneWidget);
  });

  testWidgets('подтверждение завершения перечисляет неотмеченное',
      (WidgetTester tester) async {
    await show(tester, viewOnly: false);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Завершить работу'));
    await tester.pumpAndSettle();

    expect(find.text('Завершить ТО-1?'), findsOneWidget);
    expect(
      find.textContaining('проверка тормоза лебёдки'),
      findsOneWidget,
      reason: 'механик должен видеть, что именно уйдёт неотмеченным',
    );
    expect(find.text('Вернуться к пунктам'), findsOneWidget);
  });

  testWidgets('пустой регламент: отмечать нечего и завершать нечего',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MechanicActStepsScreen(
          task: task(),
          act: const ActDetails(id: 2481, title: 'ТО-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Регламент не заполнен'), findsOneWidget);
    expect(find.text('Завершить работу'), findsNothing);
  });
}
