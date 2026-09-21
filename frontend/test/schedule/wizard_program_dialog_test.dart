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
  Future<TypeAct> createTypeAct(String name) async => TypeAct(id: 3, name: name);

  @override
  Future<void> save(MaintenanceProgram program) async {}
}

/// Та же программа с дырой, но справочник помнит, что в него заводили:
/// проверяем, что «Добавить вид ТО» доходит до `POST` и чем отвечает окно.
class _BookRepository extends _GappyProgramRepository {
  _BookRepository({this.failure});

  /// Чем сервер отказывает. `null` — вид заводится.
  final String? failure;

  final List<String> created = <String>[];

  @override
  Future<TypeAct> createTypeAct(String name) async {
    created.add(name);
    final String? message = failure;
    if (message != null) throw MaintenanceProgramException(message);
    return TypeAct(id: 10 + created.length, name: name);
  }
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
  Future<TypeAct> createTypeAct(String name) async => TypeAct(id: 1, name: name);

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

/// Кнопка «Добавить вид ТО» — в подвале списка позиций, до неё надо
/// докрутить; дальше окно «Новый вид ТО» с одним полем.
Future<void> _addTypeAct(WidgetTester tester, String name) async {
  // Подвал списка строится, только когда до него докрутили: тянем ленту
  // позиций, пока кнопка не появится.
  for (int i = 0; i < 6 && find.text('Добавить вид ТО').evaluate().isEmpty; i++) {
    await tester.drag(find.byType(Scrollable).last, const Offset(0.0, -400.0));
    await tester.pumpAndSettle();
  }
  await tester.tap(find.text('Добавить вид ТО'));
  await tester.pumpAndSettle();
  await tester.enterText(find.byType(TextField).last, name);
  await tester.pump();
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

  testWidgets('«Добавить вид ТО» заводит вид в справочнике, и он сразу обычный',
      (WidgetTester tester) async {
    final _BookRepository repository = _BookRepository();
    await _open(tester, repository);

    await _addTypeAct(tester, 'ТО 4');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Добавить'));
    await tester.pumpAndSettle();

    // Вид ушёл в базу, окно закрылось.
    expect(repository.created, <String>['ТО 4']);
    expect(find.text('Новый вид ТО'), findsNothing);

    // В позицию без вида ставится как любой другой — без пометки и без
    // красного, и «Сохранить» от него не гаснет.
    await tester.tap(find.text('вид ТО не выбран'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ТО 4').last);
    await tester.pumpAndSettle();

    expect(find.textContaining('не в справочнике'), findsNothing);
    expect(_canSave(tester), isTrue);
  });

  testWidgets('сервер отказал заводить вид — окно остаётся и говорит почему',
      (WidgetTester tester) async {
    final _BookRepository repository =
        _BookRepository(failure: 'Вид ТО с таким именем уже есть');
    await _open(tester, repository);

    await _addTypeAct(tester, 'ТО 4');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Добавить'));
    await tester.pumpAndSettle();

    expect(repository.created, <String>['ТО 4']);
    expect(find.text('Новый вид ТО'), findsOneWidget);
    expect(find.text('Вид ТО с таким именем уже есть'), findsOneWidget);
    // В список вид не попал: сервер его не завёл.
    await tester.tap(find.text('Отмена').last);
    await tester.pumpAndSettle();
    expect(find.text('ТО 4'), findsNothing);
  });
}
