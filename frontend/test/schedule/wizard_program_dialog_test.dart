/// Окно правки программы модели: что оно грузит и когда даёт сохранить.
///
/// Сети здесь нет: под окном фикстурный репозиторий и пара самодельных. `PUT`
/// из окна не уходит вовсе — оно возвращает программу мастеру, и проверяем мы
/// именно то, что оно возвращает.
library;

import 'package:els/screns/schedule/object/wizard/models/maintenance_program.dart';
import 'package:els/screns/schedule/object/wizard/repository/fixture_maintenance_program_repository.dart';
import 'package:els/screns/schedule/object/wizard/repository/maintenance_program_repository.dart';
import 'package:els/screns/schedule/object/wizard/widgets/wizard_program_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const String _modelName = 'LIFT A388509';

/// Программа, у которой на третьей позиции вида ТО нет.
///
/// Так приходит программа, заведённая наполовину: ручка отдаёт позицию
/// пустой, а не молчит о ней, и сохранить такую нельзя.
class _GappyProgramRepository implements MaintenanceProgramRepository {
  const _GappyProgramRepository();

  static const List<TypeAct> _acts = <TypeAct>[
    TypeAct(id: 1, name: 'ТО 1'),
    TypeAct(id: 2, name: 'ТО 3'),
  ];

  @override
  Future<MaintenanceProgram?> program(int modelId) async {
    return MaintenanceProgram(
      modelId: modelId,
      name: _modelName,
      items: <MaintenanceProgramItem>[
        for (int position = 1; position <= kProgramLength; position++)
          MaintenanceProgramItem(
            position: position,
            typeActId: position == 3 ? null : 1,
            typeActName: position == 3 ? '' : 'ТО 1',
          ),
      ],
    );
  }

  @override
  Future<MaintenanceProgram> suggestion(int modelId) async =>
      MaintenanceProgram.empty(modelId);

  @override
  Future<List<TypeAct>> typeActs() async => _acts;

  @override
  Future<void> save(MaintenanceProgram program) async {}
}

/// Справочник не ответил: править нечем, и окно должно сказать это словами.
class _FailingProgramRepository implements MaintenanceProgramRepository {
  const _FailingProgramRepository();

  @override
  Future<MaintenanceProgram?> program(int modelId) async => null;

  @override
  Future<MaintenanceProgram> suggestion(int modelId) async =>
      MaintenanceProgram.empty(modelId);

  @override
  Future<List<TypeAct>> typeActs() async {
    throw const MaintenanceProgramException('Сервер ответил ошибкой 500');
  }

  @override
  Future<void> save(MaintenanceProgram program) async {}
}

/// Открыть окно и вернуть то, чем оно закрылось.
///
/// Через кнопку, а не `pumpWidget` самого окна: окно живёт маршрутом, и его
/// `Navigator.pop` иначе некуда деть.
Future<MaintenanceProgram?> _open(
  WidgetTester tester,
  MaintenanceProgramRepository repository,
) async {
  tester.view.physicalSize = const Size(1200.0, 1600.0);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  MaintenanceProgram? result;
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (BuildContext context) => TextButton(
            onPressed: () async {
              result = await showWizardProgramDialog(
                context,
                repository: repository,
                modelId: 1,
                modelName: _modelName,
              );
            },
            child: const Text('Открыть'),
          ),
        ),
      ),
    ),
  );

  await tester.tap(find.text('Открыть'));
  await tester.pumpAndSettle();
  return result;
}

/// «Сохранить»: нажимается или нет.
bool _canSave(WidgetTester tester) {
  final ElevatedButton button = tester.widget<ElevatedButton>(
    find.widgetWithText(ElevatedButton, 'Сохранить').first,
  );
  return button.onPressed != null;
}

void main() {
  testWidgets('заведённая программа открывается на правку', (
    WidgetTester tester,
  ) async {
    await _open(
      tester,
      FixtureMaintenanceProgramRepository(delay: Duration.zero),
    );

    expect(find.text('Программа модели'), findsOneWidget);
    expect(find.text('Цикл обслуживания'), findsOneWidget);
    // Позиции — своим выбором вида ТО у каждой. Ровно двенадцати здесь не
    // ищем: список ленивый, и нижние позиции пока не построены. Что их
    // двенадцать, проверяет ветка с сохранением — по тому, что окно вернуло.
    expect(find.byType(DropdownButton<String>), findsWidgets);
    expect(find.text('ТО 1'), findsWidgets);
    expect(_canSave(tester), isTrue);
  });

  testWidgets('программы нет — окно открывается на создание с подсказкой '
      'сервера', (WidgetTester tester) async {
    await _open(
      tester,
      FixtureMaintenanceProgramRepository(
        withProgram: false,
        delay: Duration.zero,
      ),
    );

    // Заголовок другой: собирать цикл с нуля и править готовый — разные
    // работы, и человек должен видеть, какую делает.
    expect(find.text('Создание программы модели'), findsOneWidget);
    // Пустых двенадцать строк никто не заполняет руками — раскладку
    // предложил сервер, и она уже в окне.
    expect(find.text('вид ТО не выбран'), findsNothing);
  });

  testWidgets('позиция без вида ТО гасит «Сохранить»',
      (WidgetTester tester) async {
    await _open(tester, const _GappyProgramRepository());

    expect(find.text('вид ТО не выбран'), findsOneWidget);
    expect(_canSave(tester), isFalse);
  });

  testWidgets('название собирается из модели и дописанного человеком',
      (WidgetTester tester) async {
    // Марка с моделью уходит в базу вместе с дополнением: хранить в имени
    // одно дописанное значило бы получить программу без имени модели.
    MaintenanceProgram? saved;
    tester.view.physicalSize = const Size(1200.0, 1600.0);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (BuildContext context) => TextButton(
              onPressed: () async {
                saved = await showWizardProgramDialog(
                  context,
                  repository: FixtureMaintenanceProgramRepository(
                    delay: Duration.zero,
                  ),
                  modelId: 1,
                  modelName: _modelName,
                );
              },
              child: const Text('Открыть'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Открыть'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'после капремонта');
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Сохранить'));
    await tester.pumpAndSettle();

    expect(saved, isNotNull);
    expect(saved!.name, '$_modelName — после капремонта');
    expect(saved!.items.length, kProgramLength);
    expect(saved!.hasEmptyPosition, isFalse);
  });

  testWidgets('справочник не ответил — окно говорит причину и даёт повторить',
      (WidgetTester tester) async {
    await _open(tester, const _FailingProgramRepository());

    expect(find.text('Сервер ответил ошибкой 500'), findsOneWidget);
    expect(find.text('Повторить'), findsOneWidget);
    // Править нечего — сохранять тоже нечего.
    expect(_canSave(tester), isFalse);
  });
}
