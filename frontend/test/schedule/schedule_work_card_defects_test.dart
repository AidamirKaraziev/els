/// Дефекты в карточке работы по ТО.
///
/// Прораб, открыв работу, должен видеть без лишних переходов, всплыл ли на
/// ней дефект. Блок стоит между чек-листом и временами и остаётся на месте
/// во всех трёх случаях: акты есть, актов нет, спросить не вышло. Последнее —
/// не придирка: исчезнув при отказе, блок сказал бы «дефектов нет».
library;

import 'package:els/foreman/defects/defect_card_screen.dart';
import 'package:els/foreman/defects/defect_entry.dart';
import 'package:els/foreman/defects/defects_repository.dart';
import 'package:els/screns/in_progress_works/models/work_details.dart';
import 'package:els/screns/in_progress_works/repository/work_details_repository.dart';
import 'package:els/screns/schedule/view/schedule_work_card_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Работа, которая отвечает сама и в сеть не ходит.
class _FakeWorkRepository extends WorkDetailsRepository {
  const _FakeWorkRepository(this.details);

  final WorkDetails details;

  @override
  Future<WorkDetails> fetchDetails(int actId) async => details;

  @override
  Future<WorkPhotos> fetchPhotos(int actId) async => WorkPhotos.empty;

  @override
  Future<Performer> fetchPerformer(int userId) async => Performer(id: userId);
}

/// Дефекты работы: либо заданный список, либо отказ.
class _FakeDefectsRepository extends DefectsRepository {
  const _FakeDefectsRepository({this.entries, this.fails = false});

  final List<DefectEntry>? entries;
  final bool fails;

  @override
  Future<List<DefectEntry>> byActFact(int actFactId) async {
    if (fails) throw Exception('нет сети');
    return entries ?? const <DefectEntry>[];
  }

  /// Карточка акта дозапрашивает описание и снимки — отвечаем тем же актом.
  @override
  Future<DefectEntry> byId(int id) async =>
      entries!.firstWhere((DefectEntry entry) => entry.id == id);
}

const WorkDetails _work = WorkDetails(
  id: 300,
  checklist: WorkChecklist(
    title: 'ТО 3',
    steps: <ChecklistStep>[
      ChecklistStep(id: 1, title: 'Проверка табличек', done: true),
    ],
  ),
);

DefectEntry _entry({
  required int id,
  required String title,
  DefectState state = DefectState.created,
}) {
  return DefectEntry(
    id: id,
    title: title,
    source: DefectSource.work,
    state: state,
    createdAt: DateTime(2026, 8, 14),
  );
}

Future<void> _pump(WidgetTester tester, DefectsRepository defects) async {
  await tester.pumpWidget(
    MaterialApp(
      home: ScheduleWorkCardScreen(
        workId: _work.id,
        objectName: '136 Воздух.верх',
        repository: const _FakeWorkRepository(_work),
        defectsRepository: defects,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('акты работы показаны с их состоянием',
      (WidgetTester tester) async {
    await _pump(
      tester,
      _FakeDefectsRepository(
        entries: <DefectEntry>[
          _entry(id: 11, title: 'Течь редуктора', state: DefectState.issued),
          _entry(id: 12, title: 'Не горит освещение'),
        ],
      ),
    );

    expect(find.text('Дефекты · 2'), findsOneWidget);
    expect(find.text('Течь редуктора'), findsOneWidget);
    expect(find.text('Не горит освещение'), findsOneWidget);
    expect(find.text('Выдан клиенту'), findsOneWidget);
  });

  testWidgets('дефектов нет: блок на месте и говорит об этом словами',
      (WidgetTester tester) async {
    await _pump(tester, const _FakeDefectsRepository());

    expect(find.text('Дефекты'), findsOneWidget);
    expect(find.text('Дефектов на этой работе не заводили'), findsOneWidget);
    // Ноль в заголовке читался бы так же, как «спросить не вышло».
    expect(find.text('Дефекты · 0'), findsNothing);
  });

  testWidgets('запрос не удался: блок не исчезает и не врёт про ноль',
      (WidgetTester tester) async {
    await _pump(tester, const _FakeDefectsRepository(fails: true));

    expect(find.text('Дефекты'), findsOneWidget);
    expect(find.text('Дефекты не загрузились'), findsOneWidget);
    expect(find.text('Дефектов на этой работе не заводили'), findsNothing);
  });

  testWidgets('строка открывает карточку акта', (WidgetTester tester) async {
    await _pump(
      tester,
      _FakeDefectsRepository(
        entries: <DefectEntry>[_entry(id: 11, title: 'Течь редуктора')],
      ),
    );

    await tester.tap(find.text('Течь редуктора'));
    await tester.pumpAndSettle();

    expect(find.byType(DefectCardScreen), findsOneWidget);
    expect(find.text('136 Воздух.верх'), findsWidgets);
  });
}
