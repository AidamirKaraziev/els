/// Экран «Шаблоны ТО» и отказы сервера.
///
/// Отказ не молчит и не роняет экран: причина словами в плашке, список
/// прежний. А отказ «по шаблону стоят ТО» — не ошибка, а вопрос: экран
/// спрашивает и повторяет запрос с `force`.
library;

import 'package:els/screns/schedule/repository/schedules_repository.dart';
import 'package:els/screns/schedule/templates/models/checklist_template.dart';
import 'package:els/screns/schedule/templates/repository/templates_repository.dart';
import 'package:els/screns/schedule/templates/view/templates_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Одна модель с одним видом; каждое действие отвечает тем, что ему велели.
class _Stub implements TemplatesRepository {
  _Stub({this.onRemove});

  final Future<void> Function(bool force)? onRemove;
  final List<String> calls = <String>[];
  int loads = 0;

  @override
  Future<List<ModelTemplates>> loadAll() async {
    loads++;
    return <ModelTemplates>[
      const ModelTemplates(
        model: TemplateModel(id: 1, name: 'ЩЛЗ-400'),
        types: <TemplateTypeAct>[
          TemplateTypeAct(
            typeActId: 1,
            typeActName: 'ТО 1',
            templateId: 11,
            steps: <String>['Осмотр'],
          ),
        ],
      ),
    ];
  }

  @override
  Future<void> removeTypeAct({
    required int modelId,
    required int typeActId,
    bool force = false,
  }) async {
    calls.add('remove force=$force');
    await onRemove?.call(force);
  }

  @override
  Future<void> restoreTypeAct({
    required int modelId,
    required int typeActId,
  }) async {
    calls.add('restore');
  }

  @override
  Future<void> save({
    required int modelId,
    required int typeActId,
    required List<String> steps,
  }) async {}

  @override
  Future<void> addTypeAct({required int modelId, required String name}) async {}

  @override
  Future<List<TemplateSource>> sources() async => const <TemplateSource>[];
}

Future<void> _pump(WidgetTester tester, TemplatesRepository repository) async {
  tester.view.physicalSize = const Size(1200.0, 800.0);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(home: TemplatesScreen(repository: repository)),
  );
  await tester.pumpAndSettle();
}

/// Корзина у строки и «Удалить» в вопросе — шаблон непустой, вопрос будет.
Future<void> _deleteWithConfirm(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Удалить вид ТО'));
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(TextButton, 'Удалить'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('отказ сервера — плашка с причиной, список на месте',
      (WidgetTester tester) async {
    final _Stub stub = _Stub(
      onRemove: (bool force) async =>
          throw const SchedulesException('Сервер ответил ошибкой 502'),
    );
    await _pump(tester, stub);

    await _deleteWithConfirm(tester);

    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('Сервер ответил ошибкой 502'), findsOneWidget);
    expect(find.text('ТО 1'), findsOneWidget);
    // Список после отказа не перечитывался: показывать нечего нового.
    expect(stub.loads, 1);
  });

  testWidgets('стоят ТО — вопрос; «Оставить» ничего не шлёт',
      (WidgetTester tester) async {
    final _Stub stub = _Stub(
      onRemove: (bool force) async {
        if (!force) throw const TemplateInUseException('По шаблону стоят 3 ТО');
      },
    );
    await _pump(tester, stub);

    await _deleteWithConfirm(tester);

    expect(find.text('По шаблону стоят ТО'), findsOneWidget);
    expect(find.textContaining('По шаблону стоят 3 ТО'), findsOneWidget);
    await tester.tap(find.text('Оставить'));
    await tester.pumpAndSettle();

    expect(stub.calls, <String>['remove force=false']);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('стоят ТО — «Удалить всё равно» повторяет запрос с force',
      (WidgetTester tester) async {
    final _Stub stub = _Stub(
      onRemove: (bool force) async {
        if (!force) throw const TemplateInUseException('По шаблону стоят 3 ТО');
      },
    );
    await _pump(tester, stub);

    await _deleteWithConfirm(tester);
    await tester.tap(find.text('Удалить всё равно'));
    await tester.pumpAndSettle();

    expect(stub.calls, <String>['remove force=false', 'remove force=true']);
    expect(stub.loads, 2);
  });
}
