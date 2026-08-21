/// Три числа у пункта меню «Сданные работы».
///
/// Проверяется то, что решает макет и чего не видно в коде: порядок от
/// спокойного к срочному, нули не показываются, сотни сворачиваются в «99+»,
/// а числа работ приходят из того же ответа, что и список, и переживают
/// неудачный запрос.
library;

import 'package:els/screns/in_progress_works/bloc/in_progress_works_bloc.dart';
import 'package:els/screns/in_progress_works/in_progress_counts.dart';
import 'package:els/screns/in_progress_works/models/in_progress_work.dart';
import 'package:els/screns/in_progress_works/repository/in_progress_works_repository.dart';
import 'package:els/screns/in_progress_works/widgets/work_counts_chips.dart';
import 'package:els/screns/submitted_works/unreviewed_counter.dart';
import 'package:els/helper/count_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _feed({int total = 4, int problems = 1}) {
  return <String, dynamic>{
    'data': <String, dynamic>{
      'items': <Map<String, dynamic>>[
        <String, dynamic>{
          'kind': 'maintenance',
          'work_id': 12,
          'state': 'running',
          'since': 1786000000,
          'started_at': 1786000000,
          'performer': 'Механик Ковалёв',
          'object': const <String, dynamic>{'id': 3, 'name': 'Лифт 12'},
        },
      ],
      'total': total,
      'problems': problems,
    },
  };
}

class _Repository extends InProgressWorksRepository {
  _Repository({this.total = 4, this.problems = 1});

  final int total;
  final int problems;

  bool fails = false;

  @override
  Future<InProgressWorks> fetch() async {
    if (fails) throw const InProgressWorksException('Не удалось загрузить');
    return InProgressWorks.fromJson(_feed(total: total, problems: problems));
  }
}

Future<void> _pumpChips(WidgetTester tester) {
  return tester.pumpWidget(
    const MaterialApp(
      home: Scaffold(body: WorkCountsChips()),
    ),
  );
}

/// Слева направо, как их видит человек.
double _x(WidgetTester tester, String text) =>
    tester.getTopLeft(find.text(text)).dx;

void main() {
  setUp(() {
    inProgressCounts.value = InProgressCounts.none;
    unreviewedWorksCount.value = 0;
  });

  testWidgets('порядок чисел — от спокойного к срочному',
      (WidgetTester tester) async {
    unreviewedWorksCount.value = 3;
    inProgressCounts.value = const InProgressCounts(total: 5, problems: 1);
    await _pumpChips(tester);

    // «Три ждут меня, пять в работе, одна стоит».
    expect(_x(tester, '3'), lessThan(_x(tester, '5')));
    expect(_x(tester, '5'), lessThan(_x(tester, '1')));
  });

  testWidgets('всё проверено — серой таблетки нет, работы на месте',
      (WidgetTester tester) async {
    inProgressCounts.value = const InProgressCounts(total: 4, problems: 1);
    await _pumpChips(tester);

    expect(find.text('4'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.byType(CountChip), findsNWidgets(2));
  });

  testWidgets('проблем нет — нет и второй таблетки',
      (WidgetTester tester) async {
    inProgressCounts.value = const InProgressCounts(total: 4, problems: 0);
    await _pumpChips(tester);

    expect(find.text('4'), findsOneWidget);
    expect(find.text('0'), findsNothing);
  });

  testWidgets('ничего не идёт и всё проверено — в меню пусто, а не нули',
      (WidgetTester tester) async {
    await _pumpChips(tester);

    expect(find.byType(CountChip), findsNothing);
    expect(find.byType(Text), findsNothing);
  });

  testWidgets('сотня работ сворачивается в «99+», строка меню не разъезжается',
      (WidgetTester tester) async {
    inProgressCounts.value = const InProgressCounts(total: 137, problems: 100);
    await _pumpChips(tester);

    expect(find.text('99+'), findsNWidgets(2));
  });

  testWidgets('числа меняются сами, вслед за значением',
      (WidgetTester tester) async {
    inProgressCounts.value = const InProgressCounts(total: 4, problems: 1);
    await _pumpChips(tester);

    inProgressCounts.value = const InProgressCounts(total: 5, problems: 0);
    await tester.pump();

    expect(find.text('5'), findsOneWidget);
    expect(find.text('1'), findsNothing);
  });

  test('числа берутся из того же ответа, что и список', () async {
    final InProgressWorksBloc bloc =
        InProgressWorksBloc(repository: _Repository(total: 7, problems: 2));
    addTearDown(bloc.close);

    bloc.add(const InProgressWorksRequested());
    await bloc.stream.firstWhere((s) => s is InProgressWorksLoaded);

    expect(inProgressCounts.value,
        const InProgressCounts(total: 7, problems: 2));
  });

  test('неудачный запрос числа не обнуляет — они последние известные',
      () async {
    final _Repository repository = _Repository(total: 7, problems: 2);
    final InProgressWorksBloc bloc =
        InProgressWorksBloc(repository: repository);
    addTearDown(bloc.close);

    bloc.add(const InProgressWorksRequested());
    await bloc.stream.firstWhere((s) => s is InProgressWorksLoaded);

    repository.fails = true;
    bloc.add(const InProgressWorksRequested());
    await bloc.stream.firstWhere((s) => s is InProgressWorksFailure);

    expect(inProgressCounts.value,
        const InProgressCounts(total: 7, problems: 2));
  });
}
