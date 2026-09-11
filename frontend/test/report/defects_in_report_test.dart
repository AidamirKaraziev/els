/// Блок дефектных актов в отчёте: плитка сводки, шторка списка, шапка
/// шторки объекта.
///
/// Проверяем то, ради чего блок заведён: число за период, серый вид при
/// нуле без тапа, тап при ненуле открывает список за тот же период, и в
/// шапке объекта число совпадает со строкой. Внешний вид утверждён глазами
/// на `dev/report_preview.dart`, здесь не проверяется.
///
/// Виджеты берутся по отдельности, а не через `ReportScreen`: экран тянет
/// справочники с сервера и шапку с аватаром, а проверяется не он.
library;

import 'package:els/screns/report/models/defect_row.dart';
import 'package:els/screns/report/models/works_report.dart';
import 'package:els/screns/report/repository/fixture_works_report_repository.dart';
import 'package:els/screns/report/repository/works_report_repository.dart';
import 'package:els/screns/report/widgets/defect_acts_sheet.dart';
import 'package:els/screns/report/widgets/object_works_sheet.dart';
import 'package:els/screns/report/widgets/report_summary_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const FixtureWorksReportRepository _repository =
    FixtureWorksReportRepository(delay: Duration.zero);

/// Весь 2026 год — в фикстуре 18 актов.
final ReportFilters _year = ReportFilters(
  dateFrom: DateTime(2026, 1, 1),
  dateTo: DateTime(2026, 12, 31),
);

/// Июнь — месяц, в котором у фикстуры актов нет.
final ReportFilters _june = ReportFilters(
  dateFrom: DateTime(2026, 6, 1),
  dateTo: DateTime(2026, 6, 30),
);

Future<WorksReport> _load(ReportFilters filters) =>
    _repository.fetch(filters: filters);

Future<void> _pumpSummary(
  WidgetTester tester,
  WorksReport report, {
  VoidCallback? onDefectsTap,
}) async {
  tester.view.physicalSize = const Size(1400.0, 1000.0);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: ReportSummaryView(
            report: report,
            onMonthTap: (_, __) {},
            onDefectsTap: onDefectsTap,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder _tileValue(String value) => find.descendant(
      of: find.ancestor(
        of: find.text('Дефектных актов'),
        matching: find.byType(Container),
      ).first,
      matching: find.text(value),
    );

void main() {
  testWidgets('плитка при ненуле красная, подсказка зовёт в список, тап работает',
      (WidgetTester tester) async {
    final WorksReport report = await _load(_year);
    expect(report.summary.counts.defects, 18);

    int taps = 0;
    await _pumpSummary(tester, report, onDefectsTap: () => taps++);

    final Text value = tester.widget<Text>(_tileValue('18'));
    expect(value.style?.color, isNot(Colors.grey));
    expect(find.text('открыть список'), findsOneWidget);

    await tester.tap(find.text('Дефектных актов'));
    await tester.pump();
    expect(taps, 1);
  });

  testWidgets('плитка при нуле серая и не нажимается',
      (WidgetTester tester) async {
    final WorksReport report = await _load(_june);
    expect(report.summary.counts.defects, 0);

    int taps = 0;
    await _pumpSummary(tester, report, onDefectsTap: () => taps++);

    expect(_tileValue('0'), findsOneWidget);
    expect(find.text('за период не составлялись'), findsOneWidget);
    expect(find.text('открыть список'), findsNothing);

    await tester.tap(find.text('Дефектных актов'), warnIfMissed: false);
    await tester.pump();
    expect(taps, 0);
  });

  testWidgets('шторка списка: заголовок с числом, строки называют объект',
      (WidgetTester tester) async {
    final WorksReport report = await _load(_year);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DefectActsSheet(
            filters: _year,
            period: report.period,
            expected: report.summary.counts.defects,
            repository: _repository,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Дефектные акты'), findsOneWidget);
    expect(find.text('за Янв 2026 — Дек 2026: 18'), findsOneWidget);
    // Объект с актами назван, объект без актов в списке отсутствует.
    expect(find.text('Лифт грузовой 2000 кг'), findsWidgets);
    expect(find.text('Лифт 7, подъезд 3'), findsNothing);
  });

  testWidgets('шторка списка: ошибка сервера показана словами, с «Повторить»',
      (WidgetTester tester) async {
    final WorksReport report = await _load(_year);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DefectActsSheet(
            filters: _year,
            period: report.period,
            expected: 18,
            repository: const _FailingRepository(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Не удалось связаться с сервером'), findsOneWidget);
    expect(find.text('Повторить'), findsOneWidget);
  });

  testWidgets('шапка шторки объекта показывает число актов из строки',
      (WidgetTester tester) async {
    final WorksReport report = await _load(_year);
    final ReportObjectRow row = report.items
        .firstWhere((ReportObjectRow item) => item.counts.defects == 15);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ObjectWorksSheet(
            row: row,
            filters: _year,
            repository: _repository,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('дефектных актов 15', findRichText: true), findsOneWidget);
    // Лента загрузилась и акты подписаны одним словом по всему экрану.
    expect(find.textContaining('Дефектный акт:'), findsWidgets);
    expect(find.textContaining('ведомост'), findsNothing);
  });
}

/// Живой репозиторий до S03: списка актов за период у него нет.
/// Живой репозиторий без сети: запрос к серверу падает, и шторка обязана
/// сказать об этом, а не показать пустой список как «актов не было».
class _FailingRepository extends WorksReportRepository {
  const _FailingRepository();

  @override
  Future<List<ReportDefectRow>> fetchDefects({
    required ReportFilters filters,
  }) async {
    throw const WorksReportException('Не удалось связаться с сервером');
  }
}
