/// Состояние карточки работы — ТО и заявки.
///
/// Отдельно от виджет-теста проверяется то, что нельзя увидеть глазами:
/// сбой снимков и телефона не гасит чек-лист, у заявки телефон приезжает
/// вместе с ней самой, а возврат из карточки сотрудника перечитывает
/// **только** телефон.
library;

import 'package:els/screns/in_progress_works/bloc/work_details_bloc.dart';
import 'package:els/screns/in_progress_works/models/order_details.dart';
import 'package:els/screns/in_progress_works/models/work_details.dart';
import 'package:els/screns/in_progress_works/repository/work_details_repository.dart';
import 'package:els/screns/submitted_works/models/submitted_work.dart'
    show WorkKind;
import 'package:flutter_test/flutter_test.dart';

class _Repository extends WorkDetailsRepository {
  _Repository({
    this.photosFail = false,
    this.performerFail = false,
    this.phones = const <String?>[null],
    this.mechanicId = 7,
    this.orderFail = false,
    this.executorPhone,
  });

  final bool photosFail;
  final bool performerFail;

  /// Заявка не открылась вовсе — карточке нечего показывать под шапкой.
  final bool orderFail;

  /// Телефон исполнителя внутри самой заявки: `null` — поле в справочнике
  /// пустое.
  final String? executorPhone;

  /// Что отдавать на первый, второй и следующие запросы телефона. Так
  /// проверяется правка справочника: сходил, вписал, вернулся.
  final List<String?> phones;

  final int? mechanicId;

  int performerCalls = 0;

  @override
  Future<WorkDetails> fetchDetails(int actId) async {
    return WorkDetails(
      id: actId,
      mainMechanicId: mechanicId,
      checklist: const WorkChecklist(
        title: 'ТО-1',
        steps: <ChecklistStep>[
          ChecklistStep(id: 1, title: 'Осмотр', done: true),
          ChecklistStep(id: 2, title: 'Канаты', done: false),
        ],
      ),
    );
  }

  @override
  Future<WorkPhotos> fetchPhotos(int actId) async {
    if (photosFail) throw const WorkDetailsException('Не удалось загрузить');
    return const WorkPhotos(<int, List<String>>{
      1: <String>['host/a.jpg'],
    });
  }

  @override
  Future<OrderDetails> fetchOrder(int orderId) async {
    if (orderFail) throw const WorkDetailsException('Не удалось загрузить');
    return OrderDetails(
      id: orderId,
      taskText: 'Не открываются двери на четвёртом этаже',
      categoryName: 'AA (Застревание пассажира. Опасность)',
      categoryCode: 'AA',
      createdAt: DateTime(2026, 8, 21, 9, 40),
      executor: Performer(id: 7, name: 'Титов И.', phone: executorPhone),
    );
  }

  @override
  Future<OrderPhotos> fetchOrderPhotos(int orderId) async {
    if (photosFail) throw const WorkDetailsException('Не удалось загрузить');
    return const OrderPhotos(<String>['host/order.jpg']);
  }

  @override
  Future<Performer> fetchPerformer(int userId) async {
    if (performerFail) {
      throw const WorkDetailsException('Не удалось загрузить');
    }
    final String? phone =
        phones[performerCalls < phones.length ? performerCalls : phones.length - 1];
    performerCalls++;
    return Performer(id: userId, name: 'Ковалёв А.', phone: phone);
  }
}

Future<WorkDetailsReady> _ready(WorkDetailsBloc bloc) async {
  bloc.add(const WorkDetailsRequested());
  return await bloc.stream.firstWhere(
    (WorkDetailsState state) => state is WorkDetailsReady,
  ) as WorkDetailsReady;
}

/// Блок карточки заявки: тот же экран, другая ветка.
WorkDetailsBloc _orderBloc(_Repository repository) => WorkDetailsBloc(
      workId: 34,
      kind: WorkKind.breakdown,
      repository: repository,
    );

Future<OrderReady> _orderReady(WorkDetailsBloc bloc) async {
  bloc.add(const WorkDetailsRequested());
  return await bloc.stream.firstWhere(
    (WorkDetailsState state) => state is OrderReady,
  ) as OrderReady;
}

void main() {
  test('сбой снимков не гасит чек-лист', () async {
    final WorkDetailsBloc bloc = WorkDetailsBloc(
      workId: 12,
      repository: _Repository(photosFail: true),
    );

    final WorkDetailsReady state = await _ready(bloc);

    expect(state.details.checklist.total, 2);
    expect(state.photos.byStep, isEmpty);
    await bloc.close();
  });

  // Молчащий справочник и незаполненное поле — разные вещи, и карточка
  // говорит их разными словами. Различает их блок.
  test('молчащий справочник помечается отдельно', () async {
    final WorkDetailsBloc bloc = WorkDetailsBloc(
      workId: 12,
      repository: _Repository(performerFail: true),
    );

    final WorkDetailsReady state = await _ready(bloc);

    expect(state.performer, isNull);
    expect(state.performerFailed, isTrue);
    await bloc.close();
  });

  test('механика в акте нет — это не сбой справочника', () async {
    final WorkDetailsBloc bloc = WorkDetailsBloc(
      workId: 12,
      repository: _Repository(mechanicId: null),
    );

    final WorkDetailsReady state = await _ready(bloc);

    expect(state.performer, isNull);
    expect(state.performerFailed, isFalse);
    await bloc.close();
  });

  group('возврат из карточки сотрудника', () {
    test('телефон перечитывается, а чек-лист и снимки остаются', () async {
      final _Repository repository =
          _Repository(phones: <String?>[null, '9990000000']);
      final WorkDetailsBloc bloc =
          WorkDetailsBloc(workId: 12, repository: repository);

      final WorkDetailsReady before = await _ready(bloc);
      expect(before.performer?.hasPhone, isFalse);

      bloc.add(const WorkPerformerRequested());
      final WorkDetailsReady after = await bloc.stream.first
          as WorkDetailsReady;

      expect(after.performer?.callUri, '+79990000000');
      // Акт не перезапрашивался: развёрнутый чек-лист схлопывать нельзя,
      // человек разворачивал его руками.
      expect(after.details, same(before.details));
      expect(after.photos, same(before.photos));
      expect(repository.performerCalls, 2);

      await bloc.close();
    });

    test('без механика в акте перечитывать нечего', () async {
      final _Repository repository = _Repository(mechanicId: null);
      final WorkDetailsBloc bloc =
          WorkDetailsBloc(workId: 12, repository: repository);

      await _ready(bloc);
      bloc.add(const WorkPerformerRequested());
      await Future<void>.delayed(Duration.zero);

      expect(repository.performerCalls, 0);
      await bloc.close();
    });
  });

  group('заявка', () {
    test('исполнитель приезжает вместе с заявкой, а не из справочника',
        () async {
      final _Repository repository = _Repository(executorPhone: '9990000000');
      final WorkDetailsBloc bloc = _orderBloc(repository);

      final OrderReady state = await _orderReady(bloc);

      expect(state.order.taskLabel, 'Не открываются двери на четвёртом этаже');
      expect(state.performer?.callUri, '+79990000000');
      // Второго запроса нет: телефон лежит внутри заявки, и «не загрузился»
      // сказать не о чем.
      expect(repository.performerCalls, 0);
      expect(state.performerFailed, isFalse);

      await bloc.close();
    });

    test('сбой снимков не гасит задание', () async {
      final WorkDetailsBloc bloc = _orderBloc(_Repository(photosFail: true));

      final OrderReady state = await _orderReady(bloc);

      expect(state.order.taskLabel, isNotNull);
      expect(state.photos.isEmpty, isTrue);
      await bloc.close();
    });

    test('заявка не открылась — карточка говорит словами', () async {
      final WorkDetailsBloc bloc = _orderBloc(_Repository(orderFail: true));

      bloc.add(const WorkDetailsRequested());
      final WorkDetailsFailure state = await bloc.stream.firstWhere(
        (WorkDetailsState state) => state is WorkDetailsFailure,
      ) as WorkDetailsFailure;

      expect(state.message, 'Не удалось загрузить');
      await bloc.close();
    });

    test('возврат из карточки сотрудника перечитывает только телефон',
        () async {
      final _Repository repository =
          _Repository(phones: <String?>['9990000000']);
      final WorkDetailsBloc bloc = _orderBloc(repository);

      final OrderReady before = await _orderReady(bloc);
      expect(before.performer?.hasPhone, isFalse);

      bloc.add(const WorkPerformerRequested());
      final OrderReady after = await bloc.stream.first as OrderReady;

      expect(after.performer?.callUri, '+79990000000');
      // Саму заявку не перезапрашивали: прораб ходил в справочник, а не в
      // работу.
      expect(after.order, same(before.order));
      expect(after.photos, same(before.photos));
      expect(repository.performerCalls, 1);

      await bloc.close();
    });
  });
}
