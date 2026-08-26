/// Карточка работы из графика показывает и незакрытую работу.
///
/// Клетка месяца ведёт в работу любого состояния: назначенную, идущую и
/// закрытую. Раньше карточка создавала блок с фазой ленты сданных, и на
/// незакрытом акте блок отвечал «работа ушла из ленты» — состояние, которого
/// экран не рисует. Человек, нажавший на жёлтую клетку, получал белый лист.
library;

import 'package:els/screns/in_progress_works/models/work_details.dart';
import 'package:els/screns/in_progress_works/repository/work_details_repository.dart';
import 'package:els/screns/schedule/view/schedule_work_card_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Репозиторий, который отвечает заданной работой и не ходит в сеть.
class _FakeRepository extends WorkDetailsRepository {
  const _FakeRepository(this.details);

  final WorkDetails details;

  @override
  Future<WorkDetails> fetchDetails(int actId) async => details;

  @override
  Future<WorkPhotos> fetchPhotos(int actId) async => WorkPhotos.empty;

  @override
  Future<Performer> fetchPerformer(int userId) async => Performer(id: userId);
}

WorkDetails _details({DateTime? startedAt, DateTime? finishedAt}) {
  return WorkDetails(
    id: 300,
    checklist: const WorkChecklist(
      title: 'ТО 3',
      steps: <ChecklistStep>[
        ChecklistStep(id: 1, title: 'Проверка табличек', done: false),
        ChecklistStep(id: 2, title: 'Проверка площадок', done: false),
      ],
    ),
    startedAt: startedAt,
    finishedAt: finishedAt,
  );
}

Future<void> _pumpCard(WidgetTester tester, WorkDetails details) async {
  await tester.pumpWidget(
    MaterialApp(
      home: ScheduleWorkCardScreen(
        workId: details.id,
        objectName: '136 Воздух.верх',
        repository: _FakeRepository(details),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('назначенная работа: чек-лист на месте, а не пустой экран',
      (WidgetTester tester) async {
    await _pumpCard(tester, _details());

    expect(find.text('136 Воздух.верх'), findsOneWidget);
    expect(find.textContaining('Чек-лист'), findsOneWidget);
    expect(find.text('Проверка табличек'), findsOneWidget);
    expect(find.text('Работа ещё не начата'), findsOneWidget);
  });

  testWidgets('идущая работа: сноска говорит, что времени окончания ещё нет',
      (WidgetTester tester) async {
    await _pumpCard(
      tester,
      _details(startedAt: DateTime(2025, 3, 4, 9, 30)),
    );

    expect(find.text('Работа идёт'), findsOneWidget);
    expect(find.text('Проверка площадок'), findsOneWidget);
  });

  testWidgets('закрытая работа: сноска прежняя',
      (WidgetTester tester) async {
    await _pumpCard(
      tester,
      _details(
        startedAt: DateTime(2025, 3, 4, 9, 30),
        finishedAt: DateTime(2025, 3, 4, 10, 15),
      ),
    );

    expect(find.text('Информация о выполнении работы'), findsOneWidget);
  });
}
