/// Лента живёт переменами: что bloc делает со строками, которые приехали по
/// `updated_since`, и с ответом на «назначить».
///
/// Репозиторий здесь — ручной: тесту нужно самому решать, что «изменилось»,
/// и считать, сколько раз и с чем его спросили.
library;

import 'package:els/screns/works/bloc/works_bloc.dart';
import 'package:els/screns/works/models/new_work_draft.dart';
import 'package:els/screns/works/models/work_counts.dart';
import 'package:els/screns/works/models/work_employee.dart';
import 'package:els/screns/works/models/work_filters.dart';
import 'package:els/screns/works/models/work_item.dart';
import 'package:els/screns/works/repository/works_repository.dart';
import 'package:els/screns/submitted_works/unreviewed_counter.dart';
import 'package:flutter_test/flutter_test.dart';

final DateTime _now = DateTime(2026, 9, 12, 12);

WorkItem _item(
  int id, {
  WorkKind kind = WorkKind.request,
  WorkStatus status = WorkStatus.fresh,
  int? performerId,
  bool isActual = true,
  int sectionId = 1,
  double hoursAgo = 0.5,
}) {
  return WorkItem(
    id: id,
    kind: kind,
    status: status,
    objectName: 'Объект $id',
    createdAt: _now.subtract(Duration(minutes: (hoursAgo * 60).round())),
    acceptedAt: status == WorkStatus.fresh
        ? null
        : _now.subtract(const Duration(minutes: 10)),
    performerId: performerId,
    performer: performerId == null ? null : 'Механик $performerId',
    isActual: isActual,
    sectionId: sectionId,
  );
}

class _Repository implements WorksRepository {
  _Repository(this.items);

  List<WorkItem> items;
  List<WorkItem> changed = <WorkItem>[];
  final List<WorkFilters> fetched = <WorkFilters>[];
  final List<int?> limits = <int?>[];
  final List<DateTime> sinces = <DateTime>[];
  WorkCounts counts = WorkCounts.empty;
  bool failAssign = false;
  int unreviewed = 0;
  int unreviewedAsked = 0;

  // Форма «Новая работа» через блок не ходит — экран зовёт репозиторий сам.
  @override
  Future<NewWorkContext> newWorkContext() => throw UnimplementedError();

  @override
  Future<int> createWork(NewWorkDraft draft) => throw UnimplementedError();

  @override
  Future<WorksFeed> fetch(
    WorkFilters filters, {
    String? cursor,
    int? limit,
  }) async {
    fetched.add(filters);
    limits.add(limit);
    return WorksFeed(
      items: limit == null ? List<WorkItem>.of(items) : const <WorkItem>[],
      counts: counts,
      attentionCount: items
          .where((WorkItem i) => i.status == WorkStatus.fresh)
          .length,
      nextCursor: cursor == null && items.length > 1 ? 'next' : null,
      mySections: const <int>{1},
    );
  }

  @override
  Future<List<WorkItem>> changes(WorkFilters filters, DateTime since) async {
    sinces.add(since);
    final List<WorkItem> out = changed;
    changed = <WorkItem>[];
    return out;
  }

  @override
  Future<WorkItem> assign(WorkItem item, WorkEmployee who) async {
    if (failAssign) throw const WorksException('Нет прав');
    return item.copyWith(
      status: WorkStatus.accepted,
      performerId: who.id,
      performer: who.name,
      acceptedAt: _now,
    );
  }

  @override
  Future<WorkItem> review(WorkItem item) async =>
      item.copyWith(reviewed: true);

  @override
  Future<int> unreviewedCount() async {
    unreviewedAsked++;
    return unreviewed;
  }
}

Future<WorksBloc> _loaded(_Repository repository) async {
  final WorksBloc bloc = WorksBloc(repository: repository, clock: () => _now);
  bloc.add(const WorksRequested());
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
  expect(bloc.state.loading, isFalse);
  return bloc;
}

Future<void> _settle() async {
  for (int i = 0; i < 4; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

List<String> _keys(WorksBloc bloc) =>
    bloc.state.feed!.items.map((WorkItem i) => i.key).toList();

void main() {
  setUp(() {
    unreviewedWorksCount.value = 0;
  });

  test('первый запрос ставит момент опроса до ответа', () async {
    final _Repository repository = _Repository(<WorkItem>[_item(1)]);
    final WorksBloc bloc = await _loaded(repository);
    expect(bloc.state.syncedAt, _now);
    expect(bloc.state.feed!.items, hasLength(1));
  });

  test('перемена подменяет строку на месте, не убирая её', () async {
    final _Repository repository = _Repository(<WorkItem>[
      _item(1, hoursAgo: 3),
      _item(2),
    ]);
    final WorksBloc bloc = await _loaded(repository);

    repository.changed = <WorkItem>[
      _item(2, status: WorkStatus.accepted, performerId: 11),
    ];
    bloc.add(const WorksSynced());
    await _settle();

    expect(_keys(bloc), containsAll(<String>['request:1', 'request:2']));
    final WorkItem two = bloc.state.feed!.items.firstWhere(
      (WorkItem i) => i.id == 2,
    );
    expect(two.status, WorkStatus.accepted);
    expect(two.performer, 'Механик 11');
    expect(repository.sinces.single, _now);
    // Блок внимания пересчитан: принятая с исполнителем в нём не стоит.
    expect(bloc.state.feed!.attentionCount, 1);
  });

  test('ушедшая из-под чипса и архивная убираются сразу', () async {
    final _Repository repository = _Repository(<WorkItem>[
      _item(1),
      _item(2),
      _item(3),
    ]);
    final WorksBloc bloc = WorksBloc(repository: repository, clock: () => _now);
    bloc.add(
      const WorksRequested(filters: WorkFilters(status: WorkStatus.fresh)),
    );
    await _settle();

    repository.changed = <WorkItem>[
      _item(1, status: WorkStatus.accepted, performerId: 11),
      _item(2, isActual: false),
    ];
    bloc.add(const WorksSynced());
    await _settle();

    expect(_keys(bloc), <String>['request:3']);
  });

  test('новая строка под отбор встаёт в ленту', () async {
    final _Repository repository = _Repository(<WorkItem>[_item(1)]);
    final WorksBloc bloc = await _loaded(repository);

    repository.changed = <WorkItem>[_item(9, kind: WorkKind.breakdown)];
    bloc.add(const WorksSynced());
    await _settle();

    expect(_keys(bloc), containsAll(<String>['request:1', 'breakdown:9']));
  });

  test('непустая перемена перечитывает счётчики лёгким запросом', () async {
    final _Repository repository = _Repository(<WorkItem>[_item(1)]);
    final WorksBloc bloc = await _loaded(repository);
    repository.counts = const WorkCounts(
      byStatus: <WorkStatus, int>{WorkStatus.accepted: 7},
      byKind: <WorkKind, int>{},
    );

    bloc.add(const WorksSynced());
    await _settle();
    // Пусто — ни одного запроса за счётчиками.
    expect(repository.limits, <int?>[null]);

    repository.changed = <WorkItem>[_item(1, status: WorkStatus.accepted)];
    bloc.add(const WorksSynced());
    await _settle();

    expect(repository.limits, <int?>[null, 1]);
    expect(bloc.state.feed!.counts.ofStatus(WorkStatus.accepted), 7);
    // Строки от лёгкого запроса не берутся: он отдаёт их пустыми.
    expect(_keys(bloc), <String>['request:1']);
  });

  test('перемена и «проверил» обновляют бейдж непросмотренных в бургере',
      () async {
    final _Repository repository = _Repository(<WorkItem>[
      _item(1, status: WorkStatus.submitted),
    ]);
    final WorksBloc bloc = await _loaded(repository);
    // Первый запрос за бейджем не ходит: число при входе кладёт оболочка.
    expect(repository.unreviewedAsked, 0);

    bloc.add(const WorksSynced());
    await _settle();
    // Пустой диф — бейдж не трогаем.
    expect(repository.unreviewedAsked, 0);
    expect(unreviewedWorksCount.value, 0);

    repository.unreviewed = 4;
    repository.changed = <WorkItem>[_item(2, status: WorkStatus.submitted)];
    bloc.add(const WorksSynced());
    await _settle();
    expect(repository.unreviewedAsked, 1);
    expect(unreviewedWorksCount.value, 4);

    repository.unreviewed = 3;
    bloc.add(WorkReviewed(bloc.state.feed!.items.first));
    await _settle();
    expect(repository.unreviewedAsked, 2);
    expect(unreviewedWorksCount.value, 3);
  });

  test('«назначить» подменяет строку ответом без перезапроса ленты', () async {
    final _Repository repository = _Repository(<WorkItem>[_item(1), _item(2)]);
    final WorksBloc bloc = await _loaded(repository);

    bloc.add(
      WorkAssigned(
        bloc.state.feed!.items.first,
        const WorkEmployee(id: 11, name: 'Иванов', specialty: 'Механик'),
      ),
    );
    await _settle();

    final WorksState state = bloc.state;
    expect(state.loading, isFalse);
    expect(state.message, '№ 1 назначена: Иванов');
    expect(
      state.feed!.items.firstWhere((WorkItem i) => i.id == 1).status,
      WorkStatus.accepted,
    );
    // Полный запрос — только первый; дальше лишь счётчики.
    expect(repository.limits, <int?>[null, 1]);
  });

  test('ошибка действия — словом в снекбар, лента на месте', () async {
    final _Repository repository = _Repository(<WorkItem>[_item(1)])
      ..failAssign = true;
    final WorksBloc bloc = await _loaded(repository);

    bloc.add(
      WorkAssigned(
        bloc.state.feed!.items.first,
        const WorkEmployee(id: 11, name: 'Иванов', specialty: 'Механик'),
      ),
    );
    await _settle();

    expect(bloc.state.loading, isFalse);
    expect(bloc.state.message, 'Нет прав');
    expect(bloc.state.feed!.items.single.status, WorkStatus.fresh);
  });

  test('смена отбора обесценивает опрос, что был в пути', () async {
    final _Repository repository = _Repository(<WorkItem>[_item(1), _item(2)]);
    final WorksBloc bloc = await _loaded(repository);

    repository.changed = <WorkItem>[_item(2, status: WorkStatus.running)];
    bloc.add(const WorksSynced());
    bloc.add(
      const WorksRequested(filters: WorkFilters(status: WorkStatus.fresh)),
    );
    await _settle();

    // Ответ опроса выброшен: лента — свежий полный ответ под новый отбор.
    expect(
      bloc.state.feed!.items.every((WorkItem i) => i.status == WorkStatus.fresh),
      isTrue,
    );
  });
}
