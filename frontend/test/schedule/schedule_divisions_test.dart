/// Первое окно «Графиков» у админа — участки.
///
/// Экран отвечает на один вопрос: где график проваливается. Поэтому в строке
/// номер, название, прораб и процент, а цвет процента берётся по тем же
/// порогам, что у карточки «Выполнение графика» на главной — иначе один и тот
/// же участок был бы зелёным там и жёлтым здесь.
library;

import 'package:els/helper/class_colors.dart';
import 'package:els/screns/schedule/bloc/schedule_divisions_bloc.dart';
import 'package:els/screns/schedule/bloc/schedules_bloc.dart';
import 'package:els/screns/schedule/models/schedule_division.dart';
import 'package:els/screns/schedule/repository/fixture_schedules_repository.dart';
import 'package:els/screns/schedule/view/schedule_divisions_screen.dart';
import 'package:els/screns/schedule/view/schedule_section.dart';
import 'package:els/screns/schedule/view/schedules_screen.dart';
import 'package:els/screns/schedule/widgets/schedule_division_tile.dart';
import 'package:els/screns/schedule/widgets/schedule_filters_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void _setSize(WidgetTester tester) {
  tester.view.physicalSize = const Size(1440.0, 900.0);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

Future<void> _pumpSection(WidgetTester tester, ScheduleRole role) async {
  _setSize(tester);

  await tester.pumpWidget(
    MaterialApp(
      home: ScheduleSection(
        role: role,
        repository: FixtureSchedulesRepository(delay: Duration.zero),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<ScheduleDivisionsBloc> _pumpDivisions(WidgetTester tester) async {
  _setSize(tester);

  final ScheduleDivisionsBloc bloc = ScheduleDivisionsBloc(
    repository: FixtureSchedulesRepository(delay: Duration.zero),
    year: 2026,
  );
  addTearDown(bloc.close);

  await tester.pumpWidget(
    MaterialApp(
      home: BlocProvider<ScheduleDivisionsBloc>.value(
        value: bloc,
        child: const ScheduleDivisionsScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();

  return bloc;
}

/// Цвет пилюли процента у строки с заданным названием участка.
Color _percentColor(WidgetTester tester, String title) {
  final Finder tile = find.ancestor(
    of: find.text(title),
    matching: find.byType(ScheduleDivisionTile),
  );
  final ScheduleDivisionTile widget = tester.widget<ScheduleDivisionTile>(tile);
  return widget.division.color;
}

void main() {
  testWidgets('в строке участка видно номер, название, прораба и процент',
      (WidgetTester tester) async {
    await _pumpDivisions(tester);

    expect(find.byType(ScheduleDivisionTile), findsNWidgets(5));
    expect(find.text('Участок № 1'), findsOneWidget);
    // Прорабов в фикстуре трое на пять участков — фамилия повторяется.
    expect(find.text('Н.В. Гоголевский'), findsWidgets);
    expect(find.text('82 %'), findsOneWidget);
    // Номер в кружке — порядковый, а не id.
    expect(find.text('1'), findsOneWidget);
  });

  testWidgets('цвет процента живёт по порогам 90 и 70',
      (WidgetTester tester) async {
    await _pumpDivisions(tester);

    // Фикстура: 82 / 63 / 49 / 94 / 71 — все три цвета на экране сразу.
    expect(_percentColor(tester, 'Московская/40 лет Победы'),
        ColorApp.myColorGreen);
    expect(_percentColor(tester, 'Участок № 1'), ColorApp.myColorYellow);
    expect(_percentColor(tester, 'Северная/Тургенева'), ColorApp.myColorRed);
  });

  testWidgets('пороги те же, что у карточки на главной',
      (WidgetTester tester) async {
    // Значения, а не поведение: если кто-то поправит их в одном месте, тест
    // напомнит про второе.
    expect(ScheduleDivision.kGoodPercent, 90);
    expect(ScheduleDivision.kFairPercent, 70);
  });

  testWidgets('смена года перезапрашивает участки',
      (WidgetTester tester) async {
    final ScheduleDivisionsBloc bloc = await _pumpDivisions(tester);

    expect(bloc.state.year, 2026);

    await tester.tap(find.byTooltip('Предыдущий год'));
    await tester.pumpAndSettle();

    expect(bloc.state.year, 2025);
    expect(bloc.state, isA<ScheduleDivisionsLoaded>());
  });

  testWidgets('клик по участку открывает ленту с фильтром «Участок»',
      (WidgetTester tester) async {
    await _pumpDivisions(tester);

    await tester.tap(find.text('Участок № 2'));
    await tester.pumpAndSettle();

    expect(find.byType(SchedulesScreen), findsOneWidget);
    expect(find.byType(ScheduleFiltersBar), findsOneWidget);

    final SchedulesBloc bloc = BlocProvider.of<SchedulesBloc>(
      tester.element(find.byType(SchedulesScreen)),
    );
    expect(bloc.state.filters.division?.title, 'Участок № 2');
    expect(bloc.state.filters.year, 2026);
  });

  testWidgets('админ начинает с участков', (WidgetTester tester) async {
    await _pumpSection(tester, ScheduleRole.admin);

    expect(find.byType(ScheduleDivisionsScreen), findsOneWidget);
    expect(find.byType(SchedulesScreen), findsNothing);
  });

  testWidgets('прораб участков не видит и попадает сразу в объекты',
      (WidgetTester tester) async {
    await _pumpSection(tester, ScheduleRole.foreman);

    expect(find.byType(SchedulesScreen), findsOneWidget);
    expect(find.byType(ScheduleDivisionsScreen), findsNothing);
    expect(find.byType(ScheduleDivisionTile), findsNothing);
  });
}
