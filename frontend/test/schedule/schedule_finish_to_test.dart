/// Закрытие ТО с карточки работы.
///
/// До этого закрыть ТО было нечем: кнопка была написана, но нигде не
/// смонтирована, а подсказка в шапке карточки её уже обещала. Проверяем то,
/// ради чего она нужна: запрос уходит с тем актом, который открыт, отмена
/// ничего не шлёт, а у закрытого ТО на месте кнопки стоит дата.
library;

import 'package:els/screns/in_progress_works/models/work_details.dart';
import 'package:els/screns/in_progress_works/repository/work_details_repository.dart';
import 'package:els/screns/schedule/view/schedule_work_card_screen.dart';
import 'package:els/screns/schedule/widgets/finish_to_button.dart';
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

WorkDetails _details({DateTime? finishedAt}) {
  return WorkDetails(
    id: 311,
    checklist: const WorkChecklist(
      title: 'ТО 3',
      steps: <ChecklistStep>[
        ChecklistStep(id: 1, title: 'Проверка табличек', done: false),
      ],
    ),
    startedAt: DateTime(2027, 7, 4, 9, 30),
    finishedAt: finishedAt,
  );
}

void main() {
  late List<int> asked;
  late int refreshed;

  Future<void> pump(
    WidgetTester tester, {
    DateTime? finishedAt,
    bool answer = true,
  }) async {
    asked = <int>[];
    refreshed = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: ScheduleWorkCardScreen(
          workId: 311,
          objectName: 'ТЦ Карнавал 3 этаж 1',
          repository: _FakeRepository(_details(finishedAt: finishedAt)),
          onToFinished: () => refreshed++,
          finishRequest: (int actId) async {
            asked.add(actId);
            return answer;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('у незакрытого ТО внизу стоит кнопка «Завершить ТО»',
      (WidgetTester tester) async {
    await pump(tester);

    expect(find.byType(FinishTOButton), findsOneWidget);
    expect(find.text('Завершить ТО'), findsOneWidget);
  });

  testWidgets('подтверждение шлёт запрос с открытым актом и зовёт обновление',
      (WidgetTester tester) async {
    await pump(tester);

    await tester.tap(find.text('Завершить ТО'));
    await tester.pumpAndSettle();
    expect(find.text('Завершить ТО?'), findsOneWidget);

    await tester.tap(find.text('Завершить'));
    await tester.pumpAndSettle();

    expect(asked, <int>[311]);
    expect(refreshed, 1);
    expect(find.text('ТО завершено'), findsOneWidget);
  });

  testWidgets('отмена в диалоге ничего не шлёт', (WidgetTester tester) async {
    await pump(tester);

    await tester.tap(find.text('Завершить ТО'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Отмена'));
    await tester.pumpAndSettle();

    expect(asked, isEmpty);
    expect(refreshed, 0);
  });

  testWidgets('неудача не выдаёт закрытие за состоявшееся',
      (WidgetTester tester) async {
    await pump(tester, answer: false);

    await tester.tap(find.text('Завершить ТО'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Завершить'));
    await tester.pumpAndSettle();

    expect(asked, <int>[311]);
    expect(refreshed, 0);
    expect(find.text('Не удалось завершить ТО'), findsOneWidget);
  });

  testWidgets('у закрытого ТО вместо кнопки дата окончания',
      (WidgetTester tester) async {
    await pump(tester, finishedAt: DateTime(2027, 7, 4, 10, 15));

    expect(find.text('Завершить ТО'), findsNothing);
    expect(find.text('ТО завершено 04.07.2027'), findsOneWidget);
  });
}
