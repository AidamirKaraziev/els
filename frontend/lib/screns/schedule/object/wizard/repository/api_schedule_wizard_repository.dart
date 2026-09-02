import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../../helper/api_client.dart';
import '../../../../../helper/api_config.dart';
import '../../../repository/api_envelope.dart';
import '../../../repository/schedules_repository.dart';
import '../models/schedule_wizard_data.dart';
import 'schedule_wizard_repository.dart';

/// Тот же интерфейс, что у фикстуры, но поверх боевой ручки
/// `GET /planned-to/preview/`.
///
/// В базу предпросмотр не пишет ничего: это заготовка, которую человек ещё
/// утверждает. Раскладку — какая позиция программы попала в какой месяц —
/// целиком считает сервер, и второй такой арифметики здесь нет и быть не
/// должно: мастер её показывает, а не выводит.
class ApiScheduleWizardRepository implements ScheduleWizardRepository {
  ApiScheduleWizardRepository({
    required this.modelName,
    this.timeout = const Duration(seconds: 20),
    Future<http.Response> Function(Uri uri)? send,
    Future<http.Response> Function(Uri uri, String body)? sendPost,
  })  : _send = send ?? _getViaApi,
        _sendPost = sendPost ?? _postViaApi;

  /// Модель оборудования — чья это программа. В ответе `preview` её нет, а
  /// человеку надо видеть, программу какой модели он смотрит: правка касается
  /// всех объектов модели. Берём из уже загруженной карточки объекта, а не
  /// отдельным запросом.
  final String modelName;

  final Duration timeout;

  /// Как уходит запрос. Подменяется только в тестах: разбор ответа — половина
  /// смысла класса, а проверить его иначе, чем подставив готовый ответ,
  /// нельзя.
  final Future<http.Response> Function(Uri uri) _send;

  /// Как уходит создание графика. Отдельно от [_send]: у POST другое тело и
  /// другие заголовки, и подменять их одной функцией пришлось бы с пустой
  /// строкой вместо тела у каждого GET.
  final Future<http.Response> Function(Uri uri, String body) _sendPost;

  static Future<http.Response> _getViaApi(Uri uri) =>
      Api.get(uri, headers: <String, String>{'Accept': 'application/json'});

  static Future<http.Response> _postViaApi(Uri uri, String body) => Api.post(
        uri,
        headers: <String, String>{
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: body,
      );

  /// Номер ошибки «якорь не восстановился» (`backend/.../schedule_plan.py`).
  static const int _anchorRequiredCode = 144;

  /// Номер ошибки «у модели нет программы обслуживания» — там же.
  static const int _programMissingCode = 143;

  @override
  Future<ScheduleWizardData> preview(
    int objectId,
    int year, {
    int? anchorMonth,
  }) async {
    final Uri uri = Uri.parse('${ApiConfig.base}/planned-to/preview/').replace(
      queryParameters: <String, String>{
        'object_id': '$objectId',
        'year': '$year',
        if (anchorMonth != null) 'anchor_month': '$anchorMonth',
      },
    );

    http.Response response;
    try {
      response = await _send(uri).timeout(timeout);
    } catch (_) {
      // Обрыв сети, таймаут и CORS попадают сюда вместе: различать их для
      // человека смысла нет, действие одно — повторить.
      throw const SchedulesException('Не удалось связаться с сервером');
    }

    if (response.statusCode != 200) {
      final String text = errorText(response);
      if (response.statusCode == 422 &&
          errorCode(response) == _anchorRequiredCode) {
        throw ScheduleAnchorRequiredException(text);
      }
      if (response.statusCode == 404 &&
          errorCode(response) == _programMissingCode) {
        throw ScheduleProgramMissingException(text);
      }
      throw SchedulesException(text);
    }

    final dynamic data = decodeEnvelope(response)['data'];
    if (data is! Map) {
      throw const SchedulesException('Сервер вернул неожиданный ответ');
    }
    return _data(
      data.cast<String, dynamic>(),
      year: year,
      anchorPassed: anchorMonth != null,
    );
  }

  @override
  Future<void> generate(
    int objectId,
    int year, {
    required int anchorMonth,
  }) async {
    final Uri uri = Uri.parse('${ApiConfig.base}/planned-to/generate/');
    // Месяц шлём всегда: без него сервер подбирает якорь заново по прошлому
    // году, и в базу лёг бы не тот расклад, что человек утверждал.
    final String body = jsonEncode(<String, dynamic>{
      'object_id': objectId,
      'year': year,
      'anchor_month': anchorMonth,
    });

    http.Response response;
    try {
      response = await _sendPost(uri, body).timeout(timeout);
    } catch (_) {
      throw const SchedulesException('Не удалось связаться с сервером');
    }

    // Отдельного типа на 146 («у модели нет шаблонов чек-листа») здесь нет:
    // ветки работы у него не заводится — кнопка «Утвердить» до этого места и
    // не пускает, — а текст сервера человеку понятен как есть.
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw SchedulesException(errorText(response));
    }
  }

  ScheduleWizardData _data(
    Map<String, dynamic> preview, {
    required int year,
    required bool anchorPassed,
  }) {
    final List<WizardPreviewCell> cells = _cells(preview['cells']);

    // Программа — те же клетки, разложенные по циклу: ручка отдаёт вид ТО на
    // каждую позицию, и спрашивать программу вторым запросом незачем.
    final List<WizardPreviewCell> byPosition = <WizardPreviewCell>[...cells]
      ..sort((WizardPreviewCell a, WizardPreviewCell b) =>
          a.position.compareTo(b.position));

    return ScheduleWizardData(
      year: asInt(preview['year']) ?? year,
      modelName: modelName,
      program: <WizardProgramItem>[
        for (final WizardPreviewCell cell in byPosition)
          WizardProgramItem(
            position: cell.position,
            typeActName: cell.typeActName,
          ),
      ],
      cells: cells,
      // `anchor_month` в ответе — тот, что применён: либо подобранный по
      // прошлому году, либо переданный нами. Прошлогодним он считается только
      // во втором случае, иначе шаг «Точка отсчёта» пропал бы сразу после
      // первого же выбора месяца.
      knownAnchor: anchorPassed ? null : asInt(preview['anchor_month']),
    );
  }

  List<WizardPreviewCell> _cells(dynamic value) {
    if (value is! List) {
      throw const SchedulesException('Сервер вернул неожиданный ответ');
    }

    final Map<int, WizardPreviewCell> byMonth = <int, WizardPreviewCell>{};
    for (final dynamic item in value) {
      if (item is! Map) continue;
      final Map<String, dynamic> cell = item.cast<String, dynamic>();
      final int? month = asInt(cell['month']);
      if (month == null) continue;
      byMonth[month] = WizardPreviewCell(
        month: month,
        position: asInt(cell['position']) ?? month,
        typeActName: asString(cell['type_act_name']) ?? '',
        occupied: cell['occupied'] == true,
        templateMissing: cell['template_missing'] == true,
      );
    }

    // Ручка обещает полные двенадцать клеток. Если месяца всё же нет, ленту
    // не рвём: пустая клетка лучше, чем разъехавшийся год.
    return <WizardPreviewCell>[
      for (int month = 1; month <= 12; month++)
        byMonth[month] ??
            WizardPreviewCell(
              month: month,
              position: month,
              typeActName: '',
            ),
    ];
  }
}
