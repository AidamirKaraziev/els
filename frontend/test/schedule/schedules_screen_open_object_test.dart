/// Клик по строке ленты открывает экран «График» этого объекта.
///
/// Открывает не лента: экран графика живёт в оболочке подрядчика и
/// показывается сменой её номера экрана. Лента только зовёт
/// [ScheduleObjectOpener], и в тесте он подставной — иначе проверка ушла бы в
/// сеть и в глобальные переменные подрядчика.
library;

import 'dart:async';

import 'package:els/screns/schedule/bloc/schedules_bloc.dart';
import 'package:els/screns/schedule/models/schedule_row.dart';
import 'package:els/screns/schedule/view/schedule_object_opener.dart';
import 'package:els/screns/schedule/view/schedules_screen.dart';
import 'package:els/screns/schedule/widgets/schedule_row_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fixture_schedules_repository.dart';

/// Подставной вход в экран графика: помнит, кого просили открыть, и
/// отвечает тогда, когда решит тест.
class _OpenerSpy extends ScheduleObjectOpener {
  _OpenerSpy({this.fails = false});

  final bool fails;
  final List<ScheduleRow> opened = <ScheduleRow>[];
  final Completer<void> gate = Completer<void>();

  @override
  Future<void> open(ScheduleRow row) async {
    opened.add(row);
    await gate.future;
    if (fails) throw Exception('ручка ответила 500');
  }
}

Future<SchedulesBloc> _pump(WidgetTester tester, _OpenerSpy opener) async {
  tester.view.physicalSize = const Size(400.0, 900.0);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  // Без задержки: фикстура ждёт 350 мс, чтобы человек увидел загрузку, а тесту
  // это лишний таймер.
  final SchedulesBloc bloc = SchedulesBloc(
    repository: FixtureSchedulesRepository(
      delay: Duration.zero,
      objectCount: 3,
    ),
  );
  addTearDown(bloc.close);

  await tester.pumpWidget(
    MaterialApp(
      home: BlocProvider<SchedulesBloc>.value(
        value: bloc,
        child: SchedulesScreen(opener: opener),
      ),
    ),
  );
  await tester.pumpAndSettle();

  return bloc;
}

/// Ткнуть в название объекта — место строки, свободное от клеток.
///
/// [blocked] — про клик, который должен уткнуться в заслонку: до строки он не
/// доходит, и `tap` без этого признака ругается на промах.
Future<void> _tapRow(
  WidgetTester tester,
  ScheduleRow row, {
  bool blocked = false,
}) async {
  await tester.tap(
    find.descendant(
      of: find.byType(ScheduleRowTile).first,
      matching: find.text(row.nameLabel),
    ),
    warnIfMissed: !blocked,
  );
  await tester.pump();
}

void main() {
  testWidgets('клик по строке отдаёт наверх объект этой строки',
      (WidgetTester tester) async {
    final _OpenerSpy opener = _OpenerSpy();
    final SchedulesBloc bloc = await _pump(tester, opener);

    final ScheduleRow row = (bloc.state as SchedulesLoaded).rows.first;
    await _tapRow(tester, row);

    expect(opener.opened.single.objectId, row.objectId);

    opener.gate.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('пока экран готовится, лента закрыта и второй клик не проходит',
      (WidgetTester tester) async {
    final _OpenerSpy opener = _OpenerSpy();
    final SchedulesBloc bloc = await _pump(tester, opener);

    final ScheduleRow row = (bloc.state as SchedulesLoaded).rows.first;
    await _tapRow(tester, row);

    // Индикатор поверх ленты: без него человек, не увидев отклика, жмёт
    // вторую строку и уезжает на объект, которого не выбирал.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await _tapRow(tester, row, blocked: true);
    expect(opener.opened.length, 1);

    opener.gate.complete();
    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('упавшая загрузка оставляет человека в ленте и говорит об этом',
      (WidgetTester tester) async {
    final _OpenerSpy opener = _OpenerSpy(fails: true);
    final SchedulesBloc bloc = await _pump(tester, opener);

    final ScheduleRow row = (bloc.state as SchedulesLoaded).rows.first;
    await _tapRow(tester, row);

    opener.gate.complete();
    await tester.pumpAndSettle();

    expect(find.text('Не удалось открыть график: ${row.nameLabel}'),
        findsOneWidget);
    // Лента на месте, и повторить попытку есть по чему.
    expect(find.byType(ScheduleRowTile), findsWidgets);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}
