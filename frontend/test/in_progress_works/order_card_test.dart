/// Карточка заявки глазами прораба.
///
/// Проверяется то, чем заявка отличается от ТО: чек-листа и времён у неё нет,
/// зато есть задание, категория и время заведения. Незаполненное задание
/// названо словами — исчезнувшая строка читалась бы как «не загрузилось».
/// Шапка и звонок те же самые, и это тоже проверяется: разъехаться им нельзя.
library;

import 'package:els/bloc/user_bloc/user_bloc.dart';
import 'package:els/screns/in_progress_works/models/in_progress_work.dart';
import 'package:els/screns/in_progress_works/models/order_details.dart';
import 'package:els/screns/in_progress_works/models/work_details.dart';
import 'package:els/screns/in_progress_works/repository/work_details_repository.dart';
import 'package:els/screns/in_progress_works/view/work_card_screen.dart';
import 'package:els/screns/submitted_works/models/submitted_work.dart'
    show WorkKind;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

/// Репозиторий, который отвечает тем, что ему велели, — и не ходит в сеть.
class _FakeRepository extends WorkDetailsRepository {
  const _FakeRepository({
    this.order,
    this.photos = OrderPhotos.empty,
    this.orderError,
  });

  final OrderDetails? order;
  final OrderPhotos photos;
  final String? orderError;

  @override
  Future<OrderDetails> fetchOrder(int orderId) async {
    final String? error = orderError;
    if (error != null) throw WorkDetailsException(error);
    return order ?? OrderDetails(id: orderId);
  }

  @override
  Future<OrderPhotos> fetchOrderPhotos(int orderId) async => photos;
}

InProgressWork _work() {
  return InProgressWork(
    kind: WorkKind.breakdown,
    workId: 34,
    state: WorkState.running,
    objectId: 5,
    objectName: 'Лифт 1, подъезд 5',
    objectAddress: 'ул. Мира, 7',
    taskText: 'Не открываются двери на четвёртом этаже',
    performer: 'Титов И.',
    since: DateTime.now().subtract(const Duration(minutes: 25)),
    startedAt: DateTime.now().subtract(const Duration(minutes: 25)),
  );
}

OrderDetails _order({
  String? task = 'Не открываются двери на четвёртом этаже',
  String? phone = '9990000000',
  bool executor = true,
  int? statusId,
  String? statusName,
}) {
  return OrderDetails(
    id: 34,
    statusId: statusId,
    statusName: statusName,
    taskText: task,
    categoryName: 'AA (Застревание пассажира. Опасность)',
    categoryCode: 'AA',
    createdAt: DateTime(2026, 8, 21, 9, 40),
    executor: executor
        ? Performer(
            id: 7,
            name: 'Титов И.',
            specialty: 'Механик',
            phone: phone,
          )
        : null,
  );
}

Future<void> _pump(
  WidgetTester tester, {
  required WorkDetailsRepository repository,
  Size size = const Size(400.0, 900.0),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    BlocProvider<UserBloc>(
      create: (_) => UserBloc(),
      child: MaterialApp(
        home: WorkCardScreen(work: _work(), repository: repository),
      ),
    ),
  );
}

void main() {
  testWidgets('шапка рисуется до ответа сервера', (WidgetTester tester) async {
    await _pump(tester, repository: _FakeRepository(order: _order()));

    // Первый кадр: запрос ещё в пути, а объект, адрес, бейдж и пилюля уже на
    // экране — они приехали со строкой списка.
    expect(find.text('Лифт 1, подъезд 5'), findsOneWidget);
    expect(find.text('ул. Мира, 7'), findsOneWidget);
    expect(find.text('Авария'), findsOneWidget);
    expect(find.textContaining('В работе'), findsOneWidget);

    await tester.pumpAndSettle();
  });

  testWidgets('заявка говорит, что просили сделать',
      (WidgetTester tester) async {
    await _pump(tester, repository: _FakeRepository(order: _order()));
    await tester.pumpAndSettle();

    expect(find.text('Заявка'), findsOneWidget);
    expect(find.text('Задание'), findsOneWidget);
    expect(
      find.text('Не открываются двери на четвёртом этаже'),
      findsOneWidget,
    );
    expect(find.text('Категория'), findsOneWidget);
    expect(find.text('AA · Застревание пассажира. Опасность'), findsOneWidget);
    expect(find.text('Заведена'), findsOneWidget);
    // Без времени суток: его бэкенд не отдаёт, а полночь — не факт, а ноль.
    expect(find.text('21.08.2026'), findsOneWidget);
  });

  // Диспетчер завёл заявку по звонку и текст не написал. Строка остаётся на
  // месте: исчезнувшее поле прораб читает как «не загрузилось».
  testWidgets('незаполненное задание названо словами',
      (WidgetTester tester) async {
    await _pump(
      tester,
      repository: _FakeRepository(order: _order(task: null)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Задание'), findsOneWidget);
    expect(find.text('Задание не описано'), findsOneWidget);
  });

  // Пустой блок «Чек-лист» сказал бы, что механик ничего не отметил. Отмечать
  // у заявки нечего — блока нет вовсе, как и блока времён.
  testWidgets('у заявки нет ни чек-листа, ни времён',
      (WidgetTester tester) async {
    await _pump(tester, repository: _FakeRepository(order: _order()));
    await tester.pumpAndSettle();

    expect(find.textContaining('Чек-лист'), findsNothing);
    expect(find.text('Времена'), findsNothing);
    expect(find.text('Начал работу'), findsNothing);
  });

  testWidgets('снимки заявки встают миниатюрами', (WidgetTester tester) async {
    await _pump(
      tester,
      repository: _FakeRepository(
        order: _order(),
        photos: const OrderPhotos(<String>['host/a.jpg', 'host/b.jpg']),
      ),
    );
    await tester.pumpAndSettle();

    // Аватарка в шапке сейчас не рисуется: профиль в тесте не загружен.
    expect(find.byType(Image), findsNWidgets(2));

    // Сами файлы в тесте не качаются: `TestWidgetsFlutterBinding` отвечает на
    // любой запрос кодом 400. Ошибку снимаем — проверяем, что миниатюры
    // встали на место, а не что сеть работает.
    expect(tester.takeException(), isNotNull);
  });

  testWidgets('звонок такой же, как у ТО', (WidgetTester tester) async {
    await _pump(tester, repository: _FakeRepository(order: _order()));
    await tester.pumpAndSettle();

    expect(find.text('Позвонить'), findsOneWidget);
    expect(find.text('Титов И.'), findsOneWidget);
    // Регламента у заявки нет — рядом с именем остаётся одна специальность.
    expect(find.text('Механик'), findsOneWidget);
    expect(find.text('Номер не указан'), findsNothing);
  });

  testWidgets('номера нет — кнопки нет, но сказано, чего не хватает',
      (WidgetTester tester) async {
    await _pump(
      tester,
      repository: _FakeRepository(order: _order(phone: null)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Позвонить'), findsNothing);
    expect(find.text('Номер не указан'), findsOneWidget);
  });

  // Телефон заявки приезжает вместе с ней самой, второго запроса нет —
  // значит и сказать «не загрузился» карточке не о чем.
  testWidgets('заявка без исполнителя не жалуется на справочник',
      (WidgetTester tester) async {
    await _pump(
      tester,
      repository: _FakeRepository(order: _order(executor: false)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Телефон не загрузился'), findsNothing);
    expect(find.text('Номер не указан'), findsOneWidget);
    // Имя показываем то, что пришло со строкой списка.
    expect(find.text('Титов И.'), findsOneWidget);
  });

  // Шапка живёт своей жизнью: всё, что в ней есть, пришло со строкой списка.
  testWidgets('заявка не загрузилась — шапка остаётся',
      (WidgetTester tester) async {
    await _pump(
      tester,
      repository: const _FakeRepository(orderError: 'Не удалось загрузить'),
    );
    await tester.pumpAndSettle();

    expect(find.text('Лифт 1, подъезд 5'), findsOneWidget);
    expect(find.text('Не удалось загрузить'), findsOneWidget);
    expect(find.text('Повторить'), findsOneWidget);
  });

  // Заявку закрыли, пока прораб шёл в карточку. У неё это статус, а не
  // `finished_at`, но разговор с прорабом тот же самый, что у ТО.
  testWidgets('заявку выполнили — карточка говорит об этом',
      (WidgetTester tester) async {
    await _pump(
      tester,
      repository: _FakeRepository(
        order: _order(statusId: kOrderDone, statusName: 'Выполнено'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Работу сдали'), findsOneWidget);
    expect(find.text('К списку'), findsOneWidget);
    expect(find.text('Задание'), findsNothing);
    expect(find.text('Позвонить'), findsNothing);
  });

  // «Проблема» заявку тоже закрывает и уводит в ленту сданных.
  testWidgets('заявка с проблемой уходит туда же',
      (WidgetTester tester) async {
    await _pump(
      tester,
      repository: _FakeRepository(
        order: _order(statusId: kOrderProblem, statusName: 'Проблема'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Работу сдали'), findsOneWidget);
  });

  // А вот откат статуса — не сдача: в ленте сданных такой заявки не будет, и
  // обещать её там нельзя.
  testWidgets('статус откатили — это не «сдали»',
      (WidgetTester tester) async {
    await _pump(
      tester,
      repository: _FakeRepository(
        order: _order(statusId: 2, statusName: 'Принято'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Работа больше не идёт'), findsOneWidget);
    expect(find.text('Работу сдали'), findsNothing);
    expect(find.text('К списку'), findsOneWidget);
  });

  // Статуса в ответе нет вовсе — молчащее поле не повод объявить работу
  // сданной: карточка показывает заявку, как показывала.
  testWidgets('без статуса заявка считается идущей',
      (WidgetTester tester) async {
    await _pump(tester, repository: _FakeRepository(order: _order()));
    await tester.pumpAndSettle();

    expect(find.text('Задание'), findsOneWidget);
    expect(find.text('Работу сдали'), findsNothing);
  });
}
