/// Что панель отдаёт наверх.
///
/// Проверяем ровно то, чего не делал старый экран: кнопки там красились, а
/// отбор не менялся ни на йоту — «Графики» вообще висели на пустом
/// `press: () {}`. Поэтому смотрим не на вид пилюли, а на отбор, который
/// уходит из панели.
library;

import 'package:els/screns/schedule/models/schedule_filters.dart';
import 'package:els/screns/schedule/repository/schedules_repository.dart';
import 'package:els/screns/schedule/widgets/schedule_filters_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const ScheduleFilterOptions _options = ScheduleFilterOptions(
  divisions: <FilterOption>[
    FilterOption(id: 1, title: 'Участок № 1'),
    FilterOption(id: 2, title: 'Участок № 2'),
  ],
  types: <FilterOption>[
    FilterOption(id: 1, title: 'Лифт без МП'),
    FilterOption(id: 2, title: 'Эскалатор'),
  ],
  names: <FilterOption>[
    FilterOption(id: 1, title: 'ТЦ Карнавал 3 этаж 1'),
  ],
  factoryNumbers: <FilterOption>[
    FilterOption(id: 1, title: 'B7NS 3400'),
  ],
);

/// Панель под тестом вместе с последним отбором, который она отдала.
class _Harness {
  ScheduleFilters? last;
}

Future<_Harness> _pump(
  WidgetTester tester, {
  required ScheduleFilters filters,
  double width = 1440,
}) async {
  tester.view.physicalSize = Size(width, 900.0);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final _Harness harness = _Harness();

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ScheduleFiltersBar(
          filters: filters,
          options: _options,
          onChanged: (ScheduleFilters next) => harness.last = next,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  return harness;
}

/// Раскрыть пилюлю по её заголовку.
///
/// Тыкаем в саму пилюлю, а не в надпись внутри: надпись сидит в `hint`
/// выпадающего списка и в проверку попадания не входит — `tap` по ней ругается
/// и попадает мимо.
Future<void> _openPill(WidgetTester tester, String hint) async {
  await tester.tap(find.ancestor(
    of: find.text(hint),
    matching: find.byType(DropdownButtonHideUnderline),
  ));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('выбор участка уходит наверх сразу, без кнопки «Применить»',
      (WidgetTester tester) async {
    final _Harness harness = await _pump(
      tester,
      filters: const ScheduleFilters(year: 2026),
    );

    await _openPill(tester, 'Участок');
    await tester.tap(find.text('Участок № 2').last);
    await tester.pumpAndSettle();

    expect(harness.last, isNotNull);
    expect(harness.last!.division, const FilterOption(id: 2, title: 'Участок № 2'));
    expect(harness.last!.year, 2026);
  });

  testWidgets('«Графики» отдают состояние ТО, а не пустое нажатие',
      (WidgetTester tester) async {
    final _Harness harness = await _pump(
      tester,
      filters: const ScheduleFilters(year: 2026),
    );

    await _openPill(tester, 'Графики');
    await tester.tap(find.text(ScheduleState.hasOverdue.title).last);
    await tester.pumpAndSettle();

    expect(harness.last!.state, ScheduleState.hasOverdue);
  });

  testWidgets('активная пилюля показывает значение вместо заголовка',
      (WidgetTester tester) async {
    await _pump(
      tester,
      filters: const ScheduleFilters(
        year: 2026,
        division: FilterOption(id: 1, title: 'Участок № 1'),
      ),
    );

    expect(find.text('Участок № 1'), findsOneWidget);
    // Заголовок «Участок» уступает место выбранному значению: иначе на панели
    // из пяти пилюль не видно, какая из них стоит.
    expect(find.text('Участок'), findsNothing);
  });

  testWidgets('крестик сбрасывает свой фильтр и не трогает соседний',
      (WidgetTester tester) async {
    final _Harness harness = await _pump(
      tester,
      filters: const ScheduleFilters(
        year: 2026,
        division: FilterOption(id: 1, title: 'Участок № 1'),
        typeObject: FilterOption(id: 2, title: 'Эскалатор'),
      ),
    );

    await tester.tap(find.byTooltip('Сбросить фильтр').first);
    await tester.pumpAndSettle();

    expect(harness.last!.division, isNull);
    expect(harness.last!.typeObject,
        const FilterOption(id: 2, title: 'Эскалатор'));
  });

  testWidgets('«Сбросить всё» чистит условия, но оставляет год',
      (WidgetTester tester) async {
    final _Harness harness = await _pump(
      tester,
      filters: const ScheduleFilters(
        year: 2024,
        search: 'Карнавал',
        division: FilterOption(id: 1, title: 'Участок № 1'),
        state: ScheduleState.hasOverdue,
      ),
    );

    await tester.tap(find.text('Сбросить всё (3)'));
    await tester.pumpAndSettle();

    expect(harness.last!.isEmpty, isTrue);
    // Год — не условие отбора, а то, на что смотрим: сброс его не трогает.
    expect(harness.last!.year, 2024);
  });

  testWidgets('одно условие обходится своим крестиком, без «Сбросить всё»',
      (WidgetTester tester) async {
    await _pump(
      tester,
      filters: const ScheduleFilters(
        year: 2026,
        division: FilterOption(id: 1, title: 'Участок № 1'),
      ),
    );

    expect(find.textContaining('Сбросить всё'), findsNothing);
  });

  testWidgets('стрелка года меняет год, не задевая фильтры',
      (WidgetTester tester) async {
    final _Harness harness = await _pump(
      tester,
      filters: const ScheduleFilters(
        year: 2026,
        division: FilterOption(id: 1, title: 'Участок № 1'),
      ),
    );

    await tester.tap(find.byTooltip('Предыдущий год'));
    await tester.pumpAndSettle();

    expect(harness.last!.year, 2025);
    expect(harness.last!.division,
        const FilterOption(id: 1, title: 'Участок № 1'));
  });
}
