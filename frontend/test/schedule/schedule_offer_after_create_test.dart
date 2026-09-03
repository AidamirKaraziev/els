/// Предложение расставить график сразу после создания объекта (S2.5).
///
/// Проверяем сам путь, а не то, что покажет мастер: репозитории у него
/// боевые, сети в тесте нет, и содержимое его экрана здесь ни при чём.
/// Важно другое — когда предложение появляется, когда молчит и что делает
/// каждая из двух кнопок.
library;

import 'package:els/screns/schedule/models/schedule_role.dart';
import 'package:els/screns/schedule/object/widgets/schedule_offer_dialog.dart';
import 'package:els/screns/schedule/object/wizard/view/schedule_wizard_screen.dart';
import 'package:els/screns/schedule/view/schedule_after_create_offer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Ответ `POST /object/` — только те поля, которые читает предложение.
Map<String, dynamic> _created({
  Object? id = 42,
  String name = 'г. Краснодар, ул. Северная, 356',
}) {
  return <String, dynamic>{
    if (id != null) 'id': id,
    'name': name,
    'factory_model_id': <String, dynamic>{
      'id': 7,
      'model': 'LIFT A388509',
    },
  };
}

/// Экран с кнопкой, которая зовёт предложение — вместо формы подрядчика: та
/// ходит в сеть прямо из `initState` и в тесте не поднимается.
Future<void> _pumpCaller(
  WidgetTester tester, {
  required Map<String, dynamic> created,
}) async {
  tester.view.physicalSize = const Size(1600.0, 1200.0);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      home: Builder(
        builder: (BuildContext context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => offerScheduleForNewObject(
                context,
                created: created,
                role: ScheduleRole.admin,
              ),
              child: const Text('Сохранить'),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('после создания объекта предлагают расставить график',
      (WidgetTester tester) async {
    await _pumpCaller(tester, created: _created());
    await tester.tap(find.text('Сохранить'));
    await tester.pumpAndSettle();

    expect(find.byType(ScheduleOfferDialog), findsOneWidget);
    expect(find.text('Расставить график ТО?'), findsOneWidget);
    // Название объекта и текущий год — в тексте вопроса.
    expect(
      find.textContaining(
        'г. Краснодар, ул. Северная, 356',
        findRichText: true,
      ),
      findsOneWidget,
    );
    expect(
      find.textContaining('${DateTime.now().year} год', findRichText: true),
      findsOneWidget,
    );
  });

  testWidgets('«Позже» закрывает предложение и мастер не открывает',
      (WidgetTester tester) async {
    await _pumpCaller(tester, created: _created());
    await tester.tap(find.text('Сохранить'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Позже'));
    await tester.pumpAndSettle();

    expect(find.byType(ScheduleOfferDialog), findsNothing);
    expect(find.byType(ScheduleWizardScreen), findsNothing);
  });

  testWidgets('«Расставить» открывает мастер расстановки',
      (WidgetTester tester) async {
    await _pumpCaller(tester, created: _created());
    await tester.tap(find.text('Сохранить'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Расставить'));
    await tester.pumpAndSettle();

    expect(find.byType(ScheduleOfferDialog), findsNothing);
    expect(find.byType(ScheduleWizardScreen), findsOneWidget);
  });

  testWidgets('ответ без id: предложения нет', (WidgetTester tester) async {
    await _pumpCaller(tester, created: _created(id: null));
    await tester.tap(find.text('Сохранить'));
    await tester.pumpAndSettle();

    expect(find.byType(ScheduleOfferDialog), findsNothing);
  });

  testWidgets('объект без названия: в тексте нет пустых кавычек',
      (WidgetTester tester) async {
    await _pumpCaller(tester, created: _created(name: ''));
    await tester.tap(find.text('Сохранить'));
    await tester.pumpAndSettle();

    expect(find.byType(ScheduleOfferDialog), findsOneWidget);
    expect(find.textContaining('«»', findRichText: true), findsNothing);
  });

  testWidgets('форма закрывается раньше предложения',
      (WidgetTester tester) async {
    // Формы подрядчика открыты через `showDialog`. Предложение, показанное
    // до их закрытия, встало бы под формой — порядок и проверяем.
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (BuildContext outer) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => showDialog<void>(
                  context: outer,
                  builder: (BuildContext context) => AlertDialog(
                    content: ElevatedButton(
                      onPressed: () => closeFormAndOfferSchedule(
                        context,
                        created: _created(),
                        role: ScheduleRole.admin,
                      ),
                      child: const Text('Сохранить'),
                    ),
                  ),
                ),
                child: const Text('Добавить объект'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Добавить объект'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Сохранить'));
    await tester.pumpAndSettle();

    expect(find.text('Сохранить'), findsNothing);
    expect(find.byType(ScheduleOfferDialog), findsOneWidget);
  });
}
