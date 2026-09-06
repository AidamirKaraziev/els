/// Карточка дефекта: то, что карточка знает не из акта.
///
/// Сеть здесь не поднимается: `loadFull: false` — ровно тот режим, в котором
/// работают набросок и тесты.
library;

import 'package:els/foreman/defects/defect_card_screen.dart';
import 'package:els/foreman/defects/defect_entry.dart';
import 'package:els/foreman/defects/defects_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Репозиторий, который считает вызовы вместо того, чтобы ходить в сеть.
class _FakeRepository extends DefectsRepository {
  _FakeRepository({this.parentAfterIssue});

  final List<String> calls = <String>[];

  /// Каким родитель приезжает при перечитывании после выпуска.
  final DefectEntry? parentAfterIssue;

  @override
  Future<DefectEntry> issueToClient(int id, Map<String, dynamic> body) async {
    final Object? ids = body['photo_ids'];
    calls.add('issue:$id:$ids');
    return const DefectEntry(
      id: 31,
      title: 'Износ каната',
      source: DefectSource.object,
      state: DefectState.issued,
      isClient: true,
    );
  }

  @override
  Future<DefectEntry> generatePdf(int id) async {
    calls.add('pdf:$id');
    return DefectEntry(
      id: id,
      title: 'Износ каната',
      source: DefectSource.object,
      state: DefectState.issued,
      isClient: true,
      pdfPath: 'h/api/v1/static/defective_act/31/pdf/a.pdf',
    );
  }

  @override
  Future<DefectEntry> byId(int id) async {
    calls.add('byId:$id');
    return parentAfterIssue ?? _entry();
  }

  @override
  Future<String> downloadLink(String pdfPath) async {
    calls.add('link:${staticPathOf(pdfPath)}');
    return 'https://els.example/api/v1/static/${staticPathOf(pdfPath)}?token=t';
  }
}

DefectEntry _entry({
  String? objectName,
  List<DefectClientAct> clientActs = const <DefectClientAct>[],
  bool isClient = false,
  List<DefectPhoto> photos = const <DefectPhoto>[],
}) =>
    DefectEntry(
      id: 3,
      title: 'Неисправность дверей',
      source: DefectSource.order,
      state: DefectState.created,
      objectName: objectName,
      clientActs: clientActs,
      isClient: isClient,
      photos: photos,
    );

Widget _app(Widget child) => MaterialApp(home: child);

/// Карточка длиннее экрана, и всё, что ниже фотографий, в тесте попросту не
/// построено: `ListView` создаёт только видимое. Поэтому докручиваем, а не
/// ищем по невидимому — иначе тест проверял бы вёрстку 800×600, которой ни у
/// кого нет.
Future<void> _reveal(WidgetTester tester, Finder finder) async {
  // Прокручиваем верхний экран: пока открыт экран оформления, прежний
  // остаётся в дереве, и `Scrollable` в нём не один.
  await tester.scrollUntilVisible(
    finder,
    200.0,
    scrollable: find.byType(Scrollable).last,
  );
  await tester.pumpAndSettle();
}

/// Докрутить до конца — для случаев, где проверяется отсутствие.
Future<void> _toBottom(WidgetTester tester) async {
  await tester.drag(find.byType(ListView), const Offset(0.0, -2000.0));
  await tester.pumpAndSettle();
}

void main() {
  group('объект в реквизитах', () {
    testWidgets('имя берётся из ленты, когда в акте его нет', (tester) async {
      await tester.pumpWidget(_app(DefectCardScreen(
        entry: _entry(),
        objectName: 'AAAAAAAAAAAA',
        loadFull: false,
      )));

      expect(find.text('AAAAAAAAAAAA'), findsOneWidget);
    });

    testWidgets('имя из акта важнее: оно относится к самому акту',
        (tester) async {
      await tester.pumpWidget(_app(DefectCardScreen(
        entry: _entry(objectName: 'Лифт из планового ТО'),
        objectName: 'AAAAAAAAAAAA',
        loadFull: false,
      )));

      expect(find.text('Лифт из планового ТО'), findsOneWidget);
      expect(find.text('AAAAAAAAAAAA'), findsNothing);
    });
  });

  group('оформление клиенту', () {
    testWidgets('кнопка есть у внутреннего акта', (tester) async {
      await tester.pumpWidget(_app(DefectCardScreen(
        entry: _entry(),
        loadFull: false,
      )));

      await _reveal(tester, find.text('Оформить клиенту'));
      expect(find.text('Оформить клиенту'), findsOneWidget);
    });

    testWidgets('у клиентского акта кнопки нет: из потомка не оформляют',
        (tester) async {
      await tester.pumpWidget(_app(DefectCardScreen(
        entry: _entry(isClient: true),
        loadFull: false,
      )));

      await _toBottom(tester);
      expect(find.text('Оформить клиенту'), findsNothing);
    });

    testWidgets('после первого выпуска кнопка говорит «ещё раз»',
        (tester) async {
      await tester.pumpWidget(_app(DefectCardScreen(
        entry: _entry(clientActs: <DefectClientAct>[
          const DefectClientAct(id: 31, title: 'Замена троса'),
        ]),
        loadFull: false,
      )));

      await _reveal(tester, find.text('Оформить клиенту ещё раз'));
      expect(find.text('Оформить клиенту ещё раз'), findsOneWidget);
    });

    testWidgets('выпуск зовёт обе ручки по порядку и перечитывает акт',
        (tester) async {
      final _FakeRepository repository = _FakeRepository(
        parentAfterIssue: _entry(clientActs: <DefectClientAct>[
          const DefectClientAct(
            id: 31,
            title: 'Замена троса',
            pdfPath: 'h/api/v1/static/defective_act/31/pdf/a.pdf',
          ),
        ]),
      );
      await tester.pumpWidget(_app(DefectCardScreen(
        // Пустой путь: снимок рисуется заглушкой, и тест не лезет в сеть за
        // картинкой, которой в тестовой среде всё равно нет.
        entry: _entry(photos: const <DefectPhoto>[
          DefectPhoto(id: 7, url: ''),
        ]),
        repository: repository,
        loadFull: false,
      )));

      await _reveal(tester, find.text('Оформить клиенту'));
      await tester.tap(find.text('Оформить клиенту'));
      await tester.pumpAndSettle();
      await _reveal(tester, find.text('Сформировать PDF'));
      await tester.tap(find.text('Сформировать PDF'));
      await tester.pumpAndSettle();

      expect(repository.calls, <String>['issue:3:[7]', 'pdf:31', 'byId:3']);
      // Вернулись в карточку, и она уже знает про потомка.
      await _reveal(tester, find.text('Оформлено клиенту'));
      expect(find.text('Оформлено клиенту'), findsOneWidget);
      expect(find.text('Замена троса'), findsOneWidget);
    });
  });

  group('блок «Оформлено клиенту»', () {
    testWidgets('без собранного файла кнопка молчит словом, а не пустотой',
        (tester) async {
      await tester.pumpWidget(_app(DefectCardScreen(
        entry: _entry(clientActs: <DefectClientAct>[
          const DefectClientAct(id: 31, title: 'Замена троса'),
        ]),
        loadFull: false,
      )));

      await _reveal(tester, find.text('Файл не собран'));
      expect(find.text('Файл не собран'), findsOneWidget);
      expect(
        tester.widget<TextButton>(find.byType(TextButton)).onPressed,
        isNull,
      );
    });

    testWidgets('готовый файл открывается по короткоживущей ссылке',
        (tester) async {
      final _FakeRepository repository = _FakeRepository();
      final List<String> opened = <String>[];
      await tester.pumpWidget(_app(DefectCardScreen(
        entry: _entry(clientActs: <DefectClientAct>[
          const DefectClientAct(
            id: 31,
            title: 'Замена троса',
            pdfPath: 'h:8000/api/v1/static/defective_act/31/pdf/a.pdf',
          ),
        ]),
        repository: repository,
        loadFull: false,
        openLink: (String url) async => opened.add(url),
      )));

      await _reveal(tester, find.text('Скачать PDF'));
      await tester.tap(find.text('Скачать PDF'));
      await tester.pumpAndSettle();

      expect(repository.calls, <String>['link:defective_act/31/pdf/a.pdf']);
      expect(opened.single, contains('token=t'));
    });
  });
}
