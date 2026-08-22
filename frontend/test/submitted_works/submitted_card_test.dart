/// Карточка сданной работы — то, что прораб отмечает проверенным.
///
/// Проверяется то, ради чего её и делали: чек-лист сданного ТО виден целиком,
/// у времён есть «Закончил», а «Обновлено» нет — сданная работа не меняется;
/// отметка «Проверил» доступна из карточки и сменяется подписью; работа,
/// открытая заново, честно говорит об этом вместо чек-листа.
library;

import 'package:els/bloc/user_bloc/user_bloc.dart';
import 'package:els/screns/in_progress_works/models/order_details.dart';
import 'package:els/screns/in_progress_works/models/work_details.dart';
import 'package:els/screns/in_progress_works/repository/work_details_repository.dart';
import 'package:els/screns/submitted_works/models/submitted_work.dart';
import 'package:els/screns/submitted_works/view/submitted_work_card_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

/// Репозиторий, который отвечает тем, что ему велели, — и не ходит в сеть.
class _FakeRepository extends WorkDetailsRepository {
  const _FakeRepository({
    this.details,
    this.photos = WorkPhotos.empty,
    this.order,
    this.detailsError,
  });

  final WorkDetails? details;
  final WorkPhotos photos;
  final OrderDetails? order;
  final String? detailsError;

  @override
  Future<WorkDetails> fetchDetails(int actId) async {
    final String? error = detailsError;
    if (error != null) throw WorkDetailsException(error);
    return details ?? _details();
  }

  @override
  Future<WorkPhotos> fetchPhotos(int actId) async => photos;

  @override
  Future<OrderDetails> fetchOrder(int orderId) async {
    final String? error = detailsError;
    if (error != null) throw WorkDetailsException(error);
    return order ?? _order();
  }

  @override
  Future<OrderPhotos> fetchOrderPhotos(int orderId) async => OrderPhotos.empty;

  @override
  Future<Performer> fetchPerformer(int userId) async =>
      Performer(id: userId, name: 'Сафин Р.', phone: '9990000000');
}

SubmittedWork _work({
  WorkKind kind = WorkKind.maintenance,
  bool reviewed = false,
  WorkOutcome outcome = WorkOutcome.done,
}) {
  return SubmittedWork(
    kind: kind,
    workId: kind == WorkKind.maintenance ? 12 : 34,
    outcome: outcome,
    objectId: 3,
    objectName: 'Лифт 12, подъезд 1',
    objectAddress: 'пр. Ленина, 48',
    taskText: kind == WorkKind.maintenance ? null : 'Не открываются двери',
    performer: 'Сафин Р.',
    closedAt: DateTime(2026, 8, 21, 17, 40),
    reviewedAt: reviewed ? DateTime(2026, 8, 22, 10, 15) : null,
    reviewer: reviewed ? 'Петров А.' : null,
  );
}

/// Закрытый акт: `finished_at` проставлен — работа сдана.
///
/// `finished: false` — тот же акт, открытый заново: из ленты сданных он ушёл.
WorkDetails _details({bool finished = true, int steps = 4}) {
  return WorkDetails(
    id: 12,
    mainMechanicId: 7,
    startedAt: DateTime(2026, 8, 21, 8, 15),
    finishedAt: finished ? DateTime(2026, 8, 21, 17, 40) : null,
    checklist: WorkChecklist(
      title: 'ТО-2',
      steps: List<ChecklistStep>.generate(
        steps,
        (int i) => ChecklistStep(
          id: i + 1,
          title: 'Пункт ${i + 1}',
          done: true,
          comment: i == 1 ? 'Колодки в норме' : null,
        ),
      ),
    ),
  );
}

/// Закрытая заявка: статус «Выполнено».
OrderDetails _order({int? statusId = kOrderDone}) {
  return OrderDetails(
    id: 34,
    statusId: statusId,
    statusName: 'Выполнено',
    taskText: 'Не открываются двери',
    categoryName: 'AA (Застревание пассажира. Опасность)',
    categoryCode: 'AA',
    createdAt: DateTime(2026, 8, 21, 9, 40),
    executor: const Performer(
      id: 7,
      name: 'Титов И.',
      specialty: 'Механик',
      phone: '9990000000',
    ),
  );
}

Future<void> _pump(
  WidgetTester tester, {
  required WorkDetailsRepository repository,
  SubmittedWork? work,
  VoidCallback? onReview,
  Size size = const Size(400.0, 900.0),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    BlocProvider<UserBloc>(
      create: (_) => UserBloc(),
      child: MaterialApp(
        home: SubmittedWorkCardScreen(
          work: work ?? _work(),
          onReview: onReview ?? () {},
          repository: repository,
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('шапка рисуется до ответа сервера', (WidgetTester tester) async {
    await _pump(tester, repository: const _FakeRepository());

    // Первый кадр: запросы ещё в пути, а объект, адрес, бейдж и «кто сдал» уже
    // на экране — они приехали со строкой ленты.
    expect(find.text('Лифт 12, подъезд 1'), findsOneWidget);
    expect(find.text('пр. Ленина, 48'), findsOneWidget);
    expect(find.text('ТО'), findsOneWidget);
    expect(find.text('21.08.2026, 17:40'), findsOneWidget);

    await tester.pumpAndSettle();
  });

  testWidgets('у сданного ТО виден чек-лист и время окончания',
      (WidgetTester tester) async {
    await _pump(tester, repository: const _FakeRepository());
    await tester.pumpAndSettle();

    expect(find.text('Чек-лист · 4 из 4'), findsOneWidget);
    expect(find.text('Колодки в норме'), findsOneWidget);
    expect(find.text('Закончил'), findsOneWidget);
    // «Обновлено» у сданной работы нет: перечитывать нечего, работа кончилась.
    expect(find.text('Обновлено'), findsNothing);
  });

  // Снимки живут внутри своего пункта и после сдачи: «износ выше нормы» без
  // названия шага не значит ничего и в проверке.
  testWidgets('снимки механика остаются в своих пунктах',
      (WidgetTester tester) async {
    await _pump(
      tester,
      repository: const _FakeRepository(
        photos: WorkPhotos(<int, List<String>>{
          2: <String>['host/a.jpg'],
        }),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(Image), findsOneWidget);
    // Сам файл в тесте не качается: биндинг отвечает на любой запрос кодом
    // 400. Проверяем, что миниатюра встала на место, а не что сеть работает.
    expect(tester.takeException(), isNotNull);
  });

  testWidgets('у сданной заявки видно задание и категорию',
      (WidgetTester tester) async {
    await _pump(
      tester,
      work: _work(kind: WorkKind.breakdown),
      repository: const _FakeRepository(),
    );
    await tester.pumpAndSettle();

    expect(find.text('Заявка'), findsOneWidget);
    expect(find.text('AA · Застревание пассажира. Опасность'), findsOneWidget);
    expect(find.text('Заведена'), findsOneWidget);
    // Чек-листа у заявки нет вовсе — пустой блок сказал бы, что механик
    // ничего не отметил.
    expect(find.textContaining('Чек-лист'), findsNothing);
  });

  testWidgets('«Проверил» отмечает работу прямо из карточки',
      (WidgetTester tester) async {
    int marked = 0;
    await _pump(
      tester,
      repository: const _FakeRepository(),
      onReview: () => marked++,
    );
    await tester.pumpAndSettle();

    expect(find.text('Работу ещё не смотрели.'), findsOneWidget);

    await tester.tap(find.text('Проверил'));
    await tester.pumpAndSettle();

    expect(marked, 1);
    // Кнопки больше нет, на её месте — подпись: отмечать дважды нечего.
    expect(find.text('Проверил'), findsNothing);
    expect(find.textContaining('Проверено'), findsOneWidget);
  });

  testWidgets('у проверенной работы кнопки нет, есть кто и когда',
      (WidgetTester tester) async {
    await _pump(
      tester,
      work: _work(reviewed: true),
      repository: const _FakeRepository(),
    );
    await tester.pumpAndSettle();

    expect(find.text('Проверил Петров А., 22.08.2026, 10:15'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Проверил'), findsNothing);
  });

  testWidgets('работу открыли заново — карточка говорит об этом',
      (WidgetTester tester) async {
    await _pump(
      tester,
      repository: _FakeRepository(details: _details(finished: false)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Работа снова в работе'), findsOneWidget);
    expect(find.text('К списку'), findsOneWidget);
    // Ни чек-листа, ни отметки: проверять нечего, работа не сдана.
    expect(find.textContaining('Чек-лист'), findsNothing);
    expect(find.widgetWithText(ElevatedButton, 'Проверил'), findsNothing);
  });

  testWidgets('заявку вернули в работу — тот же разговор',
      (WidgetTester tester) async {
    await _pump(
      tester,
      work: _work(kind: WorkKind.breakdown),
      repository: _FakeRepository(order: _order(statusId: kOrderInProgress)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Работа снова в работе'), findsOneWidget);
  });

  testWidgets('подробности не загрузились — шапка и отметка остаются',
      (WidgetTester tester) async {
    await _pump(
      tester,
      repository: const _FakeRepository(detailsError: 'Не удалось загрузить'),
    );
    await tester.pumpAndSettle();

    expect(find.text('Не удалось загрузить'), findsOneWidget);
    expect(find.text('Повторить'), findsOneWidget);
    // Всё, что пришло со строкой ленты, серверу не нужно — оно на месте.
    expect(find.text('Лифт 12, подъезд 1'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Проверил'), findsOneWidget);
  });
}
