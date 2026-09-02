/// Разбор ответа предпросмотра годового графика.
///
/// Экранные тесты мастера держатся за фикстуру и проверяют вёрстку. Здесь
/// наоборот: вёрстки нет, есть готовый ответ сервера и вопрос, что
/// репозиторий из него достанет, по какому адресу сходит и как отличит
/// «якорь назовите сами» от настоящей поломки.
library;

import 'dart:convert';

import 'package:els/screns/schedule/object/wizard/models/schedule_wizard_data.dart';
import 'package:els/screns/schedule/object/wizard/repository/api_schedule_wizard_repository.dart';
import 'package:els/screns/schedule/object/wizard/repository/schedule_wizard_repository.dart';
import 'package:els/screns/schedule/repository/schedules_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

http.Response _json(Object body, {int status = 200}) =>
    http.Response.bytes(utf8.encode(jsonEncode(body)), status);

/// Ответ ручки: двенадцать клеток по программе «ТО 1 … ТО 12».
///
/// Клетки идут не по порядку месяцев — так же, как их может отдать сервер:
/// раскладка по календарю остаётся заботой репозитория.
Map<String, dynamic> _preview({
  int anchorMonth = 3,
  Set<int> occupied = const <int>{},
  Set<int> templateMissing = const <int>{},
}) {
  final List<Map<String, dynamic>> cells = <Map<String, dynamic>>[
    for (int month = 12; month >= 1; month--)
      <String, dynamic>{
        'month': month,
        'position': (month - anchorMonth + 12) % 12 + 1,
        'type_act_id': 1,
        'type_act_name': 'ТО ${(month - anchorMonth + 12) % 12 + 1}',
        'occupied': occupied.contains(month),
        'template_missing': templateMissing.contains(month),
      },
  ];

  return <String, dynamic>{
    'object_id': 7,
    'year': 2027,
    'anchor_month': anchorMonth,
    'factory_model_id': 3,
    'program_id': 5,
    'cells': cells,
  };
}

/// Ошибка в конверте бэкенда: `errors[0].code` — тот самый `num`.
http.Response _error(int code, String message, {int status = 422}) => _json(
      <String, dynamic>{
        'message': 'Error',
        'errors': <Map<String, dynamic>>[
          <String, dynamic>{'code': code, 'message': message},
        ],
        'description': message,
      },
      status: status,
    );

ApiScheduleWizardRepository _repository(
  http.Response response, {
  List<Uri>? seen,
}) {
  return ApiScheduleWizardRepository(
    modelName: 'LIFT A388509',
    send: (Uri uri) async {
      seen?.add(uri);
      return response;
    },
  );
}

void main() {
  test('клетки раскладываются по месяцам, программа — по позициям', () async {
    final List<Uri> seen = <Uri>[];
    final ScheduleWizardData data = await _repository(
      _json(<String, dynamic>{'data': _preview()}),
      seen: seen,
    ).preview(7, 2027);

    expect(seen.single.path, endsWith('/planned-to/preview/'));
    expect(seen.single.queryParameters['object_id'], '7');
    expect(seen.single.queryParameters['year'], '2027');
    // Якорь не передавали — параметра в адресе быть не должно, иначе прошлый
    // год сервер смотреть не станет.
    expect(seen.single.queryParameters.containsKey('anchor_month'), isFalse);

    expect(data.cells, hasLength(12));
    expect(data.cells.first.month, 1);
    expect(data.cells.last.month, 12);
    // Март — якорь, значит первая позиция цикла.
    expect(data.cells[2].position, 1);
    expect(data.cells[2].typeActName, 'ТО 1');

    expect(data.program, hasLength(12));
    expect(data.program.first.position, 1);
    expect(data.program.last.position, 12);
    expect(data.program.last.typeActName, 'ТО 12');

    expect(data.modelName, 'LIFT A388509');
    expect(data.year, 2027);
  });

  test('пометки клеток доходят до вида', () async {
    final ScheduleWizardData data = await _repository(
      _json(<String, dynamic>{
        'data': _preview(
          occupied: <int>{4},
          templateMissing: <int>{6},
        ),
      }),
    ).preview(7, 2027);

    expect(data.cells[3].mark, WizardCellMark.occupied);
    expect(data.cells[5].mark, WizardCellMark.templateMissing);
    expect(data.cells[0].mark, WizardCellMark.toAdd);
    expect(data.hasMissingTemplate, isTrue);
  });

  test('якорь без параметра считается прошлогодним, с параметром — нет',
      () async {
    final http.Response response = _json(<String, dynamic>{'data': _preview()});

    final ScheduleWizardData restored =
        await _repository(response).preview(7, 2027);
    expect(restored.knownAnchor, 3);
    expect(restored.hasKnownAnchor, isTrue);

    // Тот же ответ, но месяц назвали мы: шаг «Точка отсчёта» обязан остаться.
    final List<Uri> seen = <Uri>[];
    final ScheduleWizardData chosen = await _repository(response, seen: seen)
        .preview(7, 2027, anchorMonth: 5);
    expect(seen.single.queryParameters['anchor_month'], '5');
    expect(chosen.knownAnchor, isNull);
    expect(chosen.hasKnownAnchor, isFalse);
  });

  test('422 с кодом 144 — это вопрос человеку, а не поломка', () async {
    final ApiScheduleWizardRepository repository = _repository(
      _error(144, 'Укажите anchor_month — месяц, с которого начинается цикл'),
    );

    await expectLater(
      repository.preview(7, 2027),
      throwsA(isA<ScheduleAnchorRequiredException>().having(
        (ScheduleAnchorRequiredException error) => error.message,
        'message',
        contains('месяц'),
      )),
    );
  });

  test('прочая 422 доносит объяснение сервера до человека', () async {
    final ApiScheduleWizardRepository repository = _repository(
      _error(143, 'Нет шаблона чек-листа на ТО 6'),
    );

    await expectLater(
      repository.preview(7, 2027),
      throwsA(
        isA<SchedulesException>()
            .having(
              (SchedulesException error) => error.message,
              'message',
              'Нет шаблона чек-листа на ТО 6',
            )
            // Развилка мастера — только 144: на прочих ошибках он показывает
            // плашку, а не спрашивает месяц.
            .having(
              (SchedulesException error) => error is ScheduleAnchorRequiredException,
              'anchor required',
              isFalse,
            ),
      ),
    );
  });

  test('403 объясняется правами, а не текстом сервера', () async {
    await expectLater(
      _repository(_error(0, 'Forbidden', status: 403)).preview(7, 2027),
      throwsA(isA<SchedulesException>().having(
        (SchedulesException error) => error.message,
        'message',
        'Недостаточно прав или истёк вход',
      )),
    );
  });

  test('обрыв связи — отдельный текст, а не код ответа', () async {
    final ApiScheduleWizardRepository repository = ApiScheduleWizardRepository(
      modelName: 'LIFT',
      send: (Uri uri) async => throw Exception('нет сети'),
    );

    await expectLater(
      repository.preview(7, 2027),
      throwsA(isA<SchedulesException>().having(
        (SchedulesException error) => error.message,
        'message',
        'Не удалось связаться с сервером',
      )),
    );
  });

  // ------------------------------------------------- создание графика

  test('generate шлёт выбранный месяц в теле, а не в адресе', () async {
    final List<Uri> seen = <Uri>[];
    final List<String> bodies = <String>[];
    final ApiScheduleWizardRepository repository = ApiScheduleWizardRepository(
      modelName: 'LIFT',
      sendPost: (Uri uri, String body) async {
        seen.add(uri);
        bodies.add(body);
        return _json(<String, dynamic>{'data': <String, dynamic>{}});
      },
    );

    await repository.generate(7, 2027, anchorMonth: 5);

    expect(seen.single.path, endsWith('/planned-to/generate/'));
    expect(seen.single.queryParameters, isEmpty);
    expect(
      jsonDecode(bodies.single),
      <String, dynamic>{'object_id': 7, 'year': 2027, 'anchor_month': 5},
    );
  });

  test('201 — тоже удача: график создан', () async {
    final ApiScheduleWizardRepository repository = ApiScheduleWizardRepository(
      modelName: 'LIFT',
      sendPost: (Uri uri, String body) async =>
          _json(<String, dynamic>{'data': <String, dynamic>{}}, status: 201),
    );

    await expectLater(repository.generate(7, 2027, anchorMonth: 1), completes);
  });

  test('нет шаблонов чек-листа — причина словами из конверта', () async {
    final ApiScheduleWizardRepository repository = ApiScheduleWizardRepository(
      modelName: 'LIFT',
      sendPost: (Uri uri, String body) async =>
          _error(146, 'У модели нет шаблонов чек-листа на виды ТО [6]!'),
    );

    await expectLater(
      repository.generate(7, 2027, anchorMonth: 1),
      throwsA(isA<SchedulesException>().having(
        (SchedulesException error) => error.message,
        'message',
        'У модели нет шаблонов чек-листа на виды ТО [6]!',
      )),
    );
  });

  test('обрыв связи при создании — тот же текст, что и у предпросмотра',
      () async {
    final ApiScheduleWizardRepository repository = ApiScheduleWizardRepository(
      modelName: 'LIFT',
      sendPost: (Uri uri, String body) async => throw Exception('нет сети'),
    );

    await expectLater(
      repository.generate(7, 2027, anchorMonth: 1),
      throwsA(isA<SchedulesException>().having(
        (SchedulesException error) => error.message,
        'message',
        'Не удалось связаться с сервером',
      )),
    );
  });
}
