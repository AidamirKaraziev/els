/// Отбор ленты переживает уход в другой раздел.
///
/// Оболочка подрядчика держит разделы одной позицией в дереве: открывая
/// «Заявки», человек выносит «Графики» оттуда целиком. Пока блок ленты
/// создавался внутри раздела, он умирал вместе с ним — вернувшись, человек
/// видел текущий год и пустой отбор вместо своих. Поэтому блоком владеет
/// оболочка, а раздел его получает; здесь проверяется, что переданный блок
/// раздел не закрывает и что отбор виден после возвращения.
library;

import 'package:els/screns/schedule/bloc/schedules_bloc.dart';
import 'package:els/screns/schedule/models/schedule_filters.dart';
import 'package:els/screns/schedule/view/schedule_section.dart';
import 'package:els/screns/schedule/view/schedules_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:els/screns/schedule/repository/fixture_schedules_repository.dart';

/// Оболочка из двух разделов: «Графики» и что угодно ещё.
class _Shell extends StatefulWidget {
  const _Shell({Key? key, required this.bloc}) : super(key: key);

  final SchedulesBloc bloc;

  @override
  State<_Shell> createState() => _ShellState();
}

class _ShellState extends State<_Shell> {
  bool _onSchedules = true;

  void leave() => setState(() => _onSchedules = false);

  void comeBack() => setState(() => _onSchedules = true);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: _onSchedules
          ? ScheduleSection(role: ScheduleRole.admin, bloc: widget.bloc)
          : const Scaffold(body: Center(child: Text('Заявки'))),
    );
  }
}

void main() {
  testWidgets('год и отбор остаются после захода в другой раздел',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1440.0, 900.0);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final SchedulesBloc bloc = SchedulesBloc(
      repository: FixtureSchedulesRepository(delay: Duration.zero),
    );
    addTearDown(bloc.close);

    await tester.pumpWidget(_Shell(bloc: bloc));
    await tester.pumpAndSettle();

    // Человек выбрал год руками.
    bloc.add(SchedulesRequested(filters: const ScheduleFilters(year: 2021)));
    await tester.pumpAndSettle();
    expect(find.text('2021'), findsOneWidget);

    final _ShellState shell = tester.state(find.byType(_Shell));
    shell.leave();
    await tester.pumpAndSettle();
    expect(find.text('Заявки'), findsOneWidget);

    shell.comeBack();
    await tester.pumpAndSettle();

    // Блок пережил уход: раздел его не закрывал, состояние на месте.
    expect(bloc.isClosed, isFalse);
    expect(bloc.state.filters.year, 2021);
    expect(find.text('2021'), findsOneWidget);
  });
}
