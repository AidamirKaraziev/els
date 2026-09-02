/// Перенос ТО перетаскиванием и строка срока под лентой.
///
/// Проверяем правила, а не картинку: тащить можно только незакрытое ТО,
/// класть — только на свободный месяц, и после переноса запрос уходит ровно
/// один, с теми месяцами, между которыми тащили.
library;

import 'package:els/screns/schedule/models/month_cell.dart';
import 'package:els/screns/schedule/models/schedule_role.dart';
import 'package:els/screns/schedule/object/models/schedule_object_card.dart';
import 'package:els/screns/schedule/object/repository/fixture_schedule_object_repository.dart';
import 'package:els/screns/schedule/object/repository/schedule_object_repository.dart';
import 'package:els/screns/schedule/object/view/schedule_object_screen.dart';
import 'package:els/screns/schedule/object/widgets/object_schedule_card.dart';
import 'package:els/screns/schedule/object/wizard/repository/fixture_schedule_wizard_repository.dart';
import 'package:els/screns/schedule/widgets/month_strip.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Год, на который фикстура кладёт заполненную ленту. Берём заданный, а не
/// «текущий»: тест не должен ломаться первого января.
const int _filledYear = 2026;

/// Фикстура, которая запоминает переносы.
class _RecordingRepository implements ScheduleObjectRepository {
  _RecordingRepository(this._inner);

  final FixtureScheduleObjectRepository _inner;

  final List<List<int>> moves = <List<int>>[];

  @override
  Future<ScheduleObjectCard> fetchCard(int objectId) => _inner.fetchCard(objectId);

  @override
  Future<List<MonthCell>> fetchYear(int objectId, int year) =>
      _inner.fetchYear(objectId, year);

  @override
  Future<void> moveCell(
    int objectId,
    int year, {
    required int actId,
    required int fromMonth,
    required int toMonth,
  }) async {
    moves.add(<int>[actId, fromMonth, toMonth]);
    await _inner.moveCell(
      objectId,
      year,
      actId: actId,
      fromMonth: fromMonth,
      toMonth: toMonth,
    );
  }

  @override
  // ignore: deprecated_member_use
  Future<void> generateYear(int objectId, int year) =>
      // ignore: deprecated_member_use
      _inner.generateYear(objectId, year);
}

Future<_RecordingRepository> _pump(
  WidgetTester tester, {
  ScheduleRole role = ScheduleRole.admin,
  int initialYear = _filledYear,
}) async {
  tester.view.physicalSize = const Size(1600.0, 1400.0);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final _RecordingRepository repository = _RecordingRepository(
    FixtureScheduleObjectRepository(filledYear: _filledYear),
  );

  await tester.pumpWidget(
    MaterialApp(
      home: ScheduleObjectScreen(
        objectId: 1,
        repository: repository,
        wizardRepository: (String modelName) =>
            const FixtureScheduleWizardRepository(delay: Duration.zero),
        role: role,
        initialYear: initialYear,
        objectName: 'График',
      ),
    ),
  );
  await tester.pumpAndSettle();
  return repository;
}

/// Клетки ленты по порядку месяцев.
Finder _cells() => find.descendant(
      of: find.byType(MonthStrip),
      matching: find.byType(Tooltip),
    );

/// Перетащить клетку месяца [from] на месяц [to].
Future<void> _drag(
  WidgetTester tester,
  int from,
  int to, {
  PointerDeviceKind kind = PointerDeviceKind.mouse,
}) async {
  final Offset start = tester.getCenter(_cells().at(from - 1));
  final Offset end = tester.getCenter(_cells().at(to - 1));
  final TestGesture gesture = await tester.startGesture(start, kind: kind);
  // Через середину: `DragTarget` считает попадание по положению курсора, и
  // прыжок сразу в конец мимо промежуточных клеток тоже годится, но так
  // ближе к тому, как ведёт руку человек.
  await tester.pump(const Duration(milliseconds: 100));
  await gesture.moveTo(Offset((start.dx + end.dx) / 2, start.dy));
  await tester.pump();
  await gesture.moveTo(end);
  await tester.pump();
  await gesture.up();
  await tester.pumpAndSettle();
}

void main() {
  group('перенос ТО перетаскиванием', () {
    testWidgets('назначенное ТО переезжает на свободный месяц',
        (WidgetTester tester) async {
      final _RecordingRepository repository = await _pump(tester);

      // Фикстура: сентябрь — назначенное ТО, ноябрь — пустой месяц.
      await _drag(tester, 9, 11);

      expect(repository.moves, hasLength(1));
      expect(repository.moves.single.sublist(1), <int>[9, 11]);

      // Лента после переноса: ноябрь занят, сентябрь пуст.
      final MonthStrip strip = tester.widget<MonthStrip>(find.byType(MonthStrip));
      expect(strip.cells[10].status, isNot(MonthStatus.none));
      expect(strip.cells[10].toName, 'ТО 3');
      expect(strip.cells[8].status, MonthStatus.none);
    });

    testWidgets('выполненное ТО перетащить нельзя', (WidgetTester tester) async {
      final _RecordingRepository repository = await _pump(tester);

      // Январь в фикстуре выполнен: работа сделана в свой месяц.
      await _drag(tester, 1, 11);

      expect(repository.moves, isEmpty);
    });

    testWidgets('на занятый месяц не кладётся', (WidgetTester tester) async {
      final _RecordingRepository repository = await _pump(tester);

      // Сентябрь назначен, октябрь тоже занят.
      await _drag(tester, 9, 10);

      expect(repository.moves, isEmpty);
    });

    testWidgets('лента раздела «Графики» остаётся неподвижной',
        (WidgetTester tester) async {
      // Без `onCellMoved` в ленте нет ни одного `Draggable`: строк там много,
      // и случайное перетаскивание в чужой строке — худшее, что может
      // случиться с плановым графиком.
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MonthStrip(
              cells: <MonthCell>[
                for (int month = 1; month <= 12; month++)
                  MonthCell(
                    month: month,
                    status: MonthStatus.pending,
                    toName: 'ТО 1',
                    actId: month,
                  ),
              ],
              onCellTap: (MonthCell _) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Draggable<MonthCell>), findsNothing);
    });
  });

  group('срок ближайшего ТО', () {
    testWidgets('показан месяц самого раннего просроченного',
        (WidgetTester tester) async {
      await _pump(tester);

      // В фикстуре просрочен май, а назначенные — сентябрь и дальше: долг
      // делать раньше, чем то, что только назначено.
      expect(find.text('ТО 1 · 1 – 31 мая'), findsOneWidget);
    });

    testWidgets('года без графика строку не показывают',
        (WidgetTester tester) async {
      await _pump(tester, initialYear: _filledYear + 1);

      expect(find.textContaining(' – '), findsNothing);
      expect(find.textContaining('График на'), findsOneWidget);
    });

    testWidgets('прораб и админ видят строку одинаково',
        (WidgetTester tester) async {
      await _pump(tester, role: ScheduleRole.foreman);

      expect(find.text('ТО 1 · 1 – 31 мая'), findsOneWidget);
      expect(find.byType(ObjectScheduleCard), findsOneWidget);
    });
  });
}
