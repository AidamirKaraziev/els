/// Значок-счётчик дефектных актов: два состояния и переход в список.
///
/// Проверяем то, ради чего значок стоит на экране: число за показанный год,
/// серый вид при нуле и список, который открывается на том же году, что
/// посчитан. Внешний вид (цвет, размер пилюли) не проверяем — он утверждён
/// глазами на `dev/defects_badge_preview.dart`.
library;

import 'package:els/foreman/defects/defects_badge.dart';
import 'package:els/foreman/defects/defects_repository.dart';
import 'package:els/foreman/defects/defects_screen.dart';
import 'package:els/foreman/defects/live_defects_badge.dart';
import 'package:els/screns/schedule/models/schedule_role.dart';
import 'package:els/screns/schedule/object/repository/fixture_schedule_object_repository.dart';
import 'package:els/screns/schedule/object/view/schedule_object_screen.dart';
import 'package:els/screns/schedule/object/wizard/repository/fixture_maintenance_program_repository.dart';
import 'package:els/screns/schedule/object/wizard/repository/fixture_schedule_wizard_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Год, на который фикстура кладёт и ленту, и дефекты.
const int _filledYear = 2026;

/// Репозиторий дефектов, который отвечает заданным числом — или не отвечает.
class _StubDefectsRepository extends DefectsRepository {
  const _StubDefectsRepository(this.count);

  /// `null` — запрос не удался.
  final int? count;

  @override
  Future<int> countByObjectAndYear({
    required int objectId,
    required int year,
  }) async {
    final int? value = count;
    if (value == null) throw Exception('связи нет');
    return value;
  }
}

Future<void> _pumpBadge(WidgetTester tester, {required int count}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: DefectsBadge(count: count, year: _filledYear, onTap: () {}),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _pumpScheduleScreen(
  WidgetTester tester, {
  int initialYear = _filledYear,
}) async {
  tester.view.physicalSize = const Size(1600.0, 1400.0);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      home: ScheduleObjectScreen(
        objectId: 1,
        repository: FixtureScheduleObjectRepository(filledYear: _filledYear),
        wizardRepository: (String modelName) =>
            const FixtureScheduleWizardRepository(delay: Duration.zero),
        programRepository: FixtureMaintenanceProgramRepository(
          delay: Duration.zero,
        ),
        role: ScheduleRole.foreman,
        initialYear: initialYear,
        objectName: 'ТЦ Карнавал 3 этаж 1',
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('значок дефектных актов', () {
    testWidgets('есть дефекты — число видно', (WidgetTester tester) async {
      await _pumpBadge(tester, count: 3);

      expect(find.text('3'), findsOneWidget);
      expect(
        find.byTooltip('Дефектных актов за $_filledYear год: 3'),
        findsOneWidget,
      );
    });

    testWidgets('дефектов нет — числа нет, сказано подсказкой',
        (WidgetTester tester) async {
      await _pumpBadge(tester, count: 0);

      expect(find.text('0'), findsNothing);
      expect(
        find.byTooltip('Дефектных актов не было за $_filledYear год'),
        findsOneWidget,
      );
    });
  });

  group('значок в окне «График объекта»', () {
    testWidgets('показывает число за показанный год',
        (WidgetTester tester) async {
      await _pumpScheduleScreen(tester);

      expect(find.byType(DefectsBadge), findsOneWidget);
      expect(
        find.byTooltip('Дефектных актов за $_filledYear год: 3'),
        findsOneWidget,
      );
    });

    testWidgets('на другом году считает заново', (WidgetTester tester) async {
      await _pumpScheduleScreen(tester, initialYear: _filledYear - 1);

      // На пустом годе дефектов у фикстуры нет — значок серый и без числа.
      expect(
        find.byTooltip('Дефектных актов не было за ${_filledYear - 1} год'),
        findsOneWidget,
      );

      await tester.tap(find.byTooltip('Следующий год'));
      await tester.pumpAndSettle();

      expect(
        find.byTooltip('Дефектных актов за $_filledYear год: 3'),
        findsOneWidget,
      );
    });

    testWidgets('клик открывает список за тот же год',
        (WidgetTester tester) async {
      await _pumpScheduleScreen(tester);

      await tester.tap(find.byType(DefectsBadge));
      // Без `pumpAndSettle`: список уходит в сеть, которой в тесте нет, и
      // ждать его тишины бессмысленно — проверяем сам переход.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(DefectsScreen), findsOneWidget);
      expect(
        tester.widget<DefectsScreen>(find.byType(DefectsScreen)).initialYear,
        _filledYear,
      );
    });
  });

  group('значок, который сам ходит за числом', () {
    testWidgets('пока числа нет — пусто, потом появляется',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LiveDefectsBadge(
              objectId: 82,
              year: _filledYear,
              repository: _StubDefectsRepository(2),
            ),
          ),
        ),
      );

      // Первый кадр — запрос ещё не ответил.
      expect(find.byType(DefectsBadge), findsNothing);

      await tester.pumpAndSettle();
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('запрос не удался — значка нет вовсе',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LiveDefectsBadge(
              objectId: 82,
              year: _filledYear,
              repository: _StubDefectsRepository(null),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(DefectsBadge), findsNothing);
    });
  });
}
