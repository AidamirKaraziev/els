/// Порядок работы мастера: когда он спрашивает месяц, а когда нет.
///
/// Ровно то, ради чего мастер сажали на живую ручку. Ответ сервера здесь
/// подставлен, вёрстки нет: проверяем последовательность запросов и то, какие
/// состояния из неё выходят.
library;

import 'dart:async';

import 'package:els/screns/schedule/object/wizard/bloc/schedule_wizard_bloc.dart';
import 'package:els/screns/schedule/object/wizard/fixture_schedule_wizard_data.dart';
import 'package:els/screns/schedule/object/wizard/models/schedule_wizard_data.dart';
import 'package:els/screns/schedule/object/wizard/repository/schedule_wizard_repository.dart';
import 'package:els/screns/schedule/repository/schedules_repository.dart';
import 'package:flutter_test/flutter_test.dart';

/// Репозиторий, который записывает вопросы и отвечает по указке теста.
class _Recorder implements ScheduleWizardRepository {
  _Recorder({
    this.knownAnchor,
    this.failWith,
    this.generateFailure,
    this.generateGate,
  });

  /// Якорь, который «восстановился по прошлому году». `null` — сервер просит
  /// назвать месяц.
  final int? knownAnchor;

  /// Чем ответить на запрос **с** якорем. Нужен ветке «перезапрос не удался».
  final SchedulesException? failWith;

  /// Чем ответить на создание графика. `null` — удачей.
  final SchedulesException? generateFailure;

  /// Задержка создания, которой управляет тест. Нужна ветке «второе нажатие
  /// при идущем запросе»: без неё запрос успевает закончиться раньше.
  final Completer<void>? generateGate;

  /// Все запросы по порядку: `null` — без якоря.
  final List<int?> asked = <int?>[];

  /// Месяцы, с которыми звали создание графика.
  final List<int> generated = <int>[];

  @override
  Future<ScheduleWizardData> preview(
    int objectId,
    int year, {
    int? anchorMonth,
  }) async {
    asked.add(anchorMonth);

    if (anchorMonth == null) {
      if (knownAnchor == null) {
        throw const ScheduleAnchorRequiredException('Укажите месяц начала цикла');
      }
      return buildWizardFixture(
        WizardFixture.ok,
        year: year,
        withKnownAnchor: true,
        anchorMonth: knownAnchor!,
      );
    }

    if (failWith != null) throw failWith!;
    return buildWizardFixture(
      WizardFixture.ok,
      year: year,
      anchorMonth: anchorMonth,
    );
  }

  @override
  Future<void> generate(
    int objectId,
    int year, {
    required int anchorMonth,
  }) async {
    generated.add(anchorMonth);
    if (generateGate != null) await generateGate!.future;
    if (generateFailure != null) throw generateFailure!;
  }
}

ScheduleWizardBloc _bloc(_Recorder repository) => ScheduleWizardBloc(
      repository: repository,
      objectId: 7,
      year: 2027,
    );

void main() {
  test('прошлогодний график: один запрос и шага «Точка отсчёта» нет', () async {
    final _Recorder repository = _Recorder(knownAnchor: 3);
    final ScheduleWizardBloc bloc = _bloc(repository)..add(const WizardOpened());
    addTearDown(bloc.close);

    final ScheduleWizardState state = await bloc.stream.firstWhere(
      (ScheduleWizardState state) => state is! ScheduleWizardLoading,
    );

    expect(repository.asked, <int?>[null]);
    expect(state, isA<ScheduleWizardLoaded>());
    final ScheduleWizardLoaded loaded = state as ScheduleWizardLoaded;
    expect(loaded.anchorMonth, 3);
    expect(loaded.hasAnchorStep, isFalse);
  });

  test('якоря нет: повторный запрос с январём и шаг «Точка отсчёта»', () async {
    final _Recorder repository = _Recorder();
    final ScheduleWizardBloc bloc = _bloc(repository)..add(const WizardOpened());
    addTearDown(bloc.close);

    final ScheduleWizardState state = await bloc.stream.firstWhere(
      (ScheduleWizardState state) => state is! ScheduleWizardLoading,
    );

    // Заготовку всё равно показываем: 144 — это вопрос человеку, а не отказ.
    expect(repository.asked, <int?>[null, 1]);
    final ScheduleWizardLoaded loaded = state as ScheduleWizardLoaded;
    expect(loaded.anchorMonth, 1);
    expect(loaded.hasAnchorStep, isTrue);
  });

  test('смена месяца перезапрашивает заготовку', () async {
    final _Recorder repository = _Recorder();
    final ScheduleWizardBloc bloc = _bloc(repository)..add(const WizardOpened());
    addTearDown(bloc.close);

    await bloc.stream.firstWhere(
      (ScheduleWizardState state) => state is ScheduleWizardLoaded,
    );

    bloc.add(const WizardAnchorChanged(5));
    final ScheduleWizardLoaded loaded = await bloc.stream.firstWhere(
      (ScheduleWizardState state) =>
          state is ScheduleWizardLoaded && !state.isReloading,
    ) as ScheduleWizardLoaded;

    // Раскладку считает сервер: мастер не проворачивает цикл сам.
    expect(repository.asked, <int?>[null, 1, 5]);
    expect(loaded.anchorMonth, 5);
    // Май — якорь, значит первая позиция цикла пришлась на пятый месяц.
    expect(loaded.data.cells[4].position, 1);
  });

  test('тот же месяц второй раз сервер не дёргает', () async {
    final _Recorder repository = _Recorder(knownAnchor: 3);
    final ScheduleWizardBloc bloc = _bloc(repository)..add(const WizardOpened());
    addTearDown(bloc.close);

    await bloc.stream.firstWhere(
      (ScheduleWizardState state) => state is ScheduleWizardLoaded,
    );

    bloc.add(const WizardAnchorChanged(3));
    await Future<void>.delayed(Duration.zero);

    expect(repository.asked, <int?>[null]);
  });

  test('неудачный перезапрос оставляет прежнюю заготовку и месяц', () async {
    final _Recorder repository = _Recorder(
      knownAnchor: 3,
      failWith: const SchedulesException('Не удалось связаться с сервером'),
    );
    final ScheduleWizardBloc bloc = _bloc(repository)..add(const WizardOpened());
    addTearDown(bloc.close);

    await bloc.stream.firstWhere(
      (ScheduleWizardState state) => state is ScheduleWizardLoaded,
    );

    bloc.add(const WizardAnchorChanged(5));
    final ScheduleWizardLoaded loaded = await bloc.stream.firstWhere(
      (ScheduleWizardState state) =>
          state is ScheduleWizardLoaded && state.error != null,
    ) as ScheduleWizardLoaded;

    // Показывать ленту старого якоря под подписью нового нельзя: человек
    // решит, что выбор применился.
    expect(loaded.anchorMonth, 3);
    expect(loaded.isReloading, isFalse);
    expect(loaded.error, 'Не удалось связаться с сервером');
  });

  test('первая загрузка не удалась — экран ошибки', () async {
    final _Recorder repository = _Recorder(
      failWith: const SchedulesException('Сервер ответил ошибкой 500'),
    );
    final ScheduleWizardBloc bloc = _bloc(repository)..add(const WizardOpened());
    addTearDown(bloc.close);

    final ScheduleWizardState state = await bloc.stream.firstWhere(
      (ScheduleWizardState state) => state is! ScheduleWizardLoading,
    );

    expect(state, isA<ScheduleWizardFailure>());
    expect((state as ScheduleWizardFailure).message, 'Сервер ответил ошибкой 500');
  });

  // ------------------------------------------------- «Утвердить»

  test('«Утвердить» создаёт график с показанным месяцем', () async {
    final _Recorder repository = _Recorder(knownAnchor: 3);
    final ScheduleWizardBloc bloc = _bloc(repository)..add(const WizardOpened());
    addTearDown(bloc.close);

    await bloc.stream.firstWhere(
      (ScheduleWizardState state) => state is ScheduleWizardLoaded,
    );

    bloc.add(const WizardApproved());
    final ScheduleWizardState state = await bloc.stream.firstWhere(
      (ScheduleWizardState state) => state is ScheduleWizardApproved,
    );

    expect(repository.generated, <int>[3]);
    expect(state, isA<ScheduleWizardApproved>());
  });

  test('в базу уходит выбранный человеком месяц, а не первый показанный',
      () async {
    final _Recorder repository = _Recorder();
    final ScheduleWizardBloc bloc = _bloc(repository)..add(const WizardOpened());
    addTearDown(bloc.close);

    await bloc.stream.firstWhere(
      (ScheduleWizardState state) => state is ScheduleWizardLoaded,
    );

    bloc.add(const WizardAnchorChanged(5));
    await bloc.stream.firstWhere(
      (ScheduleWizardState state) =>
          state is ScheduleWizardLoaded && !state.isReloading,
    );

    bloc.add(const WizardApproved());
    await bloc.stream.firstWhere(
      (ScheduleWizardState state) => state is ScheduleWizardApproved,
    );

    // Ровно ради этого мастер и заводили: без якоря сервер подобрал бы месяц
    // заново и записал не то, что человек утвердил.
    expect(repository.generated, <int>[5]);
  });

  test('неудача создания оставляет мастер на месте с причиной', () async {
    final _Recorder repository = _Recorder(
      knownAnchor: 3,
      generateFailure: const SchedulesException('Не удалось связаться с сервером'),
    );
    final ScheduleWizardBloc bloc = _bloc(repository)..add(const WizardOpened());
    addTearDown(bloc.close);

    await bloc.stream.firstWhere(
      (ScheduleWizardState state) => state is ScheduleWizardLoaded,
    );

    bloc.add(const WizardApproved());
    final ScheduleWizardLoaded loaded = await bloc.stream.firstWhere(
      (ScheduleWizardState state) =>
          state is ScheduleWizardLoaded && state.error != null,
    ) as ScheduleWizardLoaded;

    // Заготовку не теряем: человеку есть что перечитать и куда нажать снова.
    expect(loaded.isApproving, isFalse);
    expect(loaded.anchorMonth, 3);
    expect(loaded.error, 'Не удалось связаться с сервером');
  });

  test('второе нажатие при идущем создании запроса не делает', () async {
    final Completer<void> gate = Completer<void>();
    final _Recorder repository = _Recorder(
      knownAnchor: 3,
      generateGate: gate,
    );
    final ScheduleWizardBloc bloc = _bloc(repository)..add(const WizardOpened());
    addTearDown(bloc.close);

    await bloc.stream.firstWhere(
      (ScheduleWizardState state) => state is ScheduleWizardLoaded,
    );

    bloc.add(const WizardApproved());
    await bloc.stream.firstWhere(
      (ScheduleWizardState state) =>
          state is ScheduleWizardLoaded && state.isApproving,
    );

    bloc.add(const WizardApproved());
    await Future<void>.delayed(Duration.zero);
    expect(repository.generated, <int>[3]);

    gate.complete();
    await bloc.stream.firstWhere(
      (ScheduleWizardState state) => state is ScheduleWizardApproved,
    );
    expect(repository.generated, <int>[3]);
  });
}
