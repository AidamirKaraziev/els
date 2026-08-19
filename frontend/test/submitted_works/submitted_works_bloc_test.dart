/// Поведение ленты сданных работ.
///
/// Проверяется то, что глазами ловится плохо: отбор «только непросмотренные»
/// переживает листание, отметка сначала чинит строку на месте, а потом идёт за
/// настоящими «кто и когда», и страница за концом выдачи не выглядит как
/// «лента кончилась».
library;

import 'package:els/screns/submitted_works/bloc/submitted_works_bloc.dart';
import 'package:els/screns/submitted_works/models/submitted_work.dart';
import 'package:els/screns/submitted_works/repository/submitted_works_repository.dart';
import 'package:flutter_test/flutter_test.dart';

/// Запрос к ленте, как его увидел репозиторий.
class _Call {
  const _Call(this.page, this.onlyUnreviewed);

  final int page;
  final bool onlyUnreviewed;

  @override
  String toString() => 'page=$page, onlyUnreviewed=$onlyUnreviewed';

  @override
  bool operator ==(Object other) =>
      other is _Call && other.page == page &&
      other.onlyUnreviewed == onlyUnreviewed;

  @override
  int get hashCode => Object.hash(page, onlyUnreviewed);
}

/// Репозиторий без сети: сеть проверяется живым прогоном, а не тестом.
class _FakeRepository extends SubmittedWorksRepository {
  _FakeRepository({this.pages = const <int, List<int>>{}, this.markFails = false});

  /// Номер страницы → id работ на ней.
  final Map<int, List<int>> pages;
  final bool markFails;

  final List<_Call> calls = <_Call>[];
  final List<int> marked = <int>[];

  @override
  Future<SubmittedWorksPage> fetch({
    int page = 1,
    bool onlyUnreviewed = false,
  }) async {
    calls.add(_Call(page, onlyUnreviewed));
    final List<int> ids = pages[page] ?? const <int>[];
    return SubmittedWorksPage(
      items: ids
          .map((int id) => SubmittedWork(
                kind: WorkKind.breakdown,
                workId: id,
                outcome: WorkOutcome.done,
                // Отметку сервер уже знает — так строка и приезжает обратно.
                reviewedAt: marked.contains(id) ? DateTime(2026, 8, 12) : null,
                reviewer: marked.contains(id) ? 'Прораб Сидоров' : null,
              ))
          .toList(growable: false),
      page: page,
      pageCount: pages.length,
      hasPrev: page > 1,
      hasNext: page < pages.length,
    );
  }

  @override
  Future<int> markReviewed({
    required WorkKind kind,
    required int workId,
  }) async {
    if (markFails) {
      throw const SubmittedWorksException('Этой работы больше нет в ленте');
    }
    marked.add(workId);
    return 0;
  }
}

/// Даёт блоку доработать: события он берёт по одному, а отметка добавляет себе
/// второе.
Future<void> _settle() async {
  for (int i = 0; i < 8; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  group('SubmittedWorksBloc', () {
    test('первый запрос отдаёт первую страницу', () async {
      final _FakeRepository repository = _FakeRepository(
        pages: <int, List<int>>{1: <int>[7, 8]},
      );
      final SubmittedWorksBloc bloc =
          SubmittedWorksBloc(repository: repository);

      bloc.add(const SubmittedWorksRequested());
      await _settle();

      expect(bloc.state, isA<SubmittedWorksLoaded>());
      expect(bloc.state.page!.items.map((SubmittedWork w) => w.workId),
          <int>[7, 8]);
      expect(repository.calls, <_Call>[const _Call(1, false)]);

      await bloc.close();
    });

    test('отбор переживает листание', () async {
      final _FakeRepository repository = _FakeRepository(
        pages: <int, List<int>>{1: <int>[7], 2: <int>[8]},
      );
      final SubmittedWorksBloc bloc =
          SubmittedWorksBloc(repository: repository);

      bloc.add(const SubmittedWorksRequested(onlyUnreviewed: true));
      await _settle();
      bloc.add(const SubmittedWorksRequested(page: 2));
      await _settle();

      // Вторая страница спрошена с тем же отбором: переключатель не обязан
      // помнить номер страницы, а стрелки — отбор.
      expect(repository.calls.last, const _Call(2, true));
      expect(bloc.state.onlyUnreviewed, isTrue);

      await bloc.close();
    });

    test('отметка чинит строку сразу и перезапрашивает страницу', () async {
      final _FakeRepository repository = _FakeRepository(
        pages: <int, List<int>>{1: <int>[7, 8]},
      );
      final SubmittedWorksBloc bloc =
          SubmittedWorksBloc(repository: repository);

      bloc.add(const SubmittedWorksRequested());
      await _settle();

      final SubmittedWork work = bloc.state.page!.items.first;
      final Future<SubmittedWorksState> patched = bloc.stream.firstWhere(
        (SubmittedWorksState state) => state is SubmittedWorksLoading,
      );

      bloc.add(SubmittedWorkReviewed(work));

      // Кнопка отвечает не дожидаясь сети: строка помечена ещё до перезапроса.
      final SubmittedWork optimistic = (await patched)
          .page!
          .items
          .firstWhere((SubmittedWork item) => item.workId == work.workId);
      expect(optimistic.isReviewed, isTrue);

      await _settle();

      // А в конце в строке настоящие «кто и когда» — имени проверившего у
      // клиента нет, и выдумывать его нельзя.
      final SubmittedWork fromServer = bloc.state.page!.items
          .firstWhere((SubmittedWork item) => item.workId == work.workId);
      expect(fromServer.reviewedLabel, contains('Прораб Сидоров'));
      expect(repository.marked, <int>[work.workId]);
      expect(repository.calls.last, const _Call(1, false));

      await bloc.close();
    });

    test('несостоявшаяся отметка не уносит список с экрана', () async {
      final _FakeRepository repository = _FakeRepository(
        pages: <int, List<int>>{1: <int>[7]},
        markFails: true,
      );
      final SubmittedWorksBloc bloc =
          SubmittedWorksBloc(repository: repository);

      bloc.add(const SubmittedWorksRequested());
      await _settle();

      final Future<SubmittedWorksState> failure = bloc.stream.firstWhere(
        (SubmittedWorksState state) => state is SubmittedWorksActionFailed,
      );
      bloc.add(SubmittedWorkReviewed(bloc.state.page!.items.first));

      expect((await failure).page!.items, hasLength(1));

      await _settle();
      // Работа могла уехать из ленты вовсе — показываем то, что на сервере.
      expect(repository.calls.last, const _Call(1, false));

      await bloc.close();
    });

    test('страница за концом выдачи возвращает на первую', () async {
      final _FakeRepository repository = _FakeRepository(
        pages: <int, List<int>>{1: <int>[7]},
      );
      final SubmittedWorksBloc bloc =
          SubmittedWorksBloc(repository: repository);

      bloc.add(const SubmittedWorksRequested(page: 4));
      await _settle();

      // Пустая четвёртая страница выглядела бы как «лента кончилась».
      expect(repository.calls, <_Call>[const _Call(4, false), const _Call(1, false)]);
      expect(bloc.state.page!.items, hasLength(1));

      await bloc.close();
    });

    test('отказ сервера показывается человеком читаемым текстом', () async {
      final SubmittedWorksBloc bloc = SubmittedWorksBloc(
        repository: const _BrokenRepository(),
      );

      bloc.add(const SubmittedWorksRequested());
      await _settle();

      expect(bloc.state, isA<SubmittedWorksFailure>());
      expect((bloc.state as SubmittedWorksFailure).message,
          'Не удалось связаться с сервером');

      await bloc.close();
    });
  });
}

class _BrokenRepository extends SubmittedWorksRepository {
  const _BrokenRepository();

  @override
  Future<SubmittedWorksPage> fetch({
    int page = 1,
    bool onlyUnreviewed = false,
  }) async {
    throw const SubmittedWorksException('Не удалось связаться с сервером');
  }
}
