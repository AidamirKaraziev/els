/// Точки входа дефекта: где кнопка есть, а где её быть не должно.
///
/// Проверяется правило, а не вёрстка. Записать дефект механик должен там, где
/// он его нашёл, — на пункте чек-листа и в заявке, — но привязать дефект
/// можно только к тому, у чего есть номер, и на просмотре чужой закрытой
/// работы кнопки быть не должно.
library;

import 'package:els/mechanic/data/acts.dart';
import 'package:els/mechanic/data/objects.dart';
import 'package:els/mechanic/data/tasks.dart';
import 'package:els/mechanic/screens/act_step_screen.dart';
import 'package:els/mechanic/screens/objects_screen.dart';
import 'package:els/mechanic/screens/order_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

ActDetails _act({int? stepId = 2}) {
  return ActDetails(
    id: 2481,
    title: 'ТО-1',
    steps: <ActStep>[
      ActStep(id: stepId, title: 'Проверка тормоза лебёдки'),
    ],
  );
}

Future<void> _openStep(
  WidgetTester tester, {
  int? stepId = 2,
  bool readOnly = false,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: MechanicActStepScreen(
        act: _act(stepId: stepId),
        index: 0,
        readOnly: readOnly,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

MechanicTask _order({int? statusId, bool watchingOnly = false}) {
  return MechanicTask(
    kind: TaskKind.order,
    id: 507,
    title: 'Лифт 12',
    section: TaskSection.now,
    rank: 1,
    order: 0,
    statusId: statusId,
    watchingOnly: watchingOnly,
    raw: const <String, dynamic>{'id': 507, 'task_text': 'Не открываются двери'},
  );
}

Future<void> _openOrder(WidgetTester tester, MechanicTask task) async {
  await tester.pumpWidget(MaterialApp(home: MechanicOrderScreen(task: task)));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('на пункте чек-листа дефект записать можно',
      (WidgetTester tester) async {
    await _openStep(tester);

    expect(find.text('Дефект по пункту'), findsOneWidget);

    await tester.tap(find.text('Дефект по пункту'));
    await tester.pumpAndSettle();

    expect(
      find.text('Что не так'),
      findsOneWidget,
      reason: 'открывается тот же лист «Дефект», что и в карточке ТО',
    );
  });

  testWidgets('пункт без номера привязать не к чему',
      (WidgetTester tester) async {
    await _openStep(tester, stepId: null);

    expect(find.text('Дефект по пункту'), findsNothing);
  });

  testWidgets('на просмотре кнопки дефекта нет', (WidgetTester tester) async {
    await _openStep(tester, readOnly: true);

    expect(find.text('Дефект по пункту'), findsNothing);
  });

  testWidgets('в заявке дефект записывает и наблюдатель',
      (WidgetTester tester) async {
    await _openOrder(tester, _order(watchingOnly: true));

    expect(
      find.text('Принять заявку'),
      findsNothing,
      reason: 'кнопки статуса наблюдателю не положены',
    );
    expect(find.text('Дефект по заявке'), findsOneWidget);
  });

  testWidgets('у закрытой заявки кнопки дефекта нет',
      (WidgetTester tester) async {
    await _openOrder(tester, _order(statusId: OrderStatus.done));

    expect(find.text('Дефект по заявке'), findsNothing);
  });

  testWidgets('у каждого объекта своя кнопка дефекта',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MechanicObjectsScreen(
          objects: <MechanicObject>[
            MechanicObject(id: 7, name: 'Лифт 12', address: 'Ленина 45'),
            MechanicObject(id: 9, name: 'Травалатор 1'),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Лифт 12'), findsOneWidget);
    expect(find.text('Дефект'), findsNWidgets(2));

    await tester.tap(find.text('Дефект').first);
    await tester.pumpAndSettle();

    expect(find.text('Что не так'), findsOneWidget);
  });

  testWidgets('пустой список объясняется словами', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MechanicObjectsScreen(objects: <MechanicObject>[]),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Объекты появятся вместе с работой'), findsOneWidget);
    expect(find.text('Дефект'), findsNothing);
  });
}
