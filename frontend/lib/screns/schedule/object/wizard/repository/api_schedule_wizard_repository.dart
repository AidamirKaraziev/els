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
  }) : _send = send ?? _getViaApi;

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

  static Future<http.Response> _getViaApi(Uri uri) =>
      Api.get(uri, headers: <String, String>{'Accept': 'application/json'});

  /// Номер ошибки «якорь не восстановился» (`backend/.../schedule_plan.py`).
  static const int _anchorRequiredCode = 144;

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
      previousYearAnchor: anchorPassed ? null : asInt(preview['anchor_month']),
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
