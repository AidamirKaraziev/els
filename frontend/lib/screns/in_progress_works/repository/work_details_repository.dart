import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../helper/api_client.dart';
import '../../../helper/api_config.dart';
import '../models/order_details.dart';
import '../models/work_details.dart';

/// Ошибка карточки работы, которую можно показать человеку.
///
/// Своя, а не общая с разделом: сбой раздела гасит список, сбой карточки —
/// только подробности под живой шапкой, и ловить их приходится по отдельности.
class WorkDetailsException implements Exception {
  const WorkDetailsException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Всё, что карточка знает сверх строки списка.
///
/// Пять ручек, все в проде: три про ТО, две про заявку. Запросы идут через
/// [Api]: заголовок с токеном, обновление пары токенов и повтор после `401`
/// живут там.
class WorkDetailsRepository {
  const WorkDetailsRepository({this.timeout = const Duration(seconds: 20)});

  final Duration timeout;

  /// Чек-лист, времена и id механика. `actId` — это `work_id` строки: у ТО
  /// он и есть id фактического акта.
  Future<WorkDetails> fetchDetails(int actId) async {
    final Uri uri = Uri.parse('${ApiConfig.base}/act-fact/$actId/');
    return WorkDetails.fromJson(_decode(await _get(uri)));
  }

  /// Снимки шагов. Отдельным запросом от подробностей: без снимков карточка
  /// годна, поэтому их сбой не должен гасить чек-лист.
  Future<WorkPhotos> fetchPhotos(int actId) async {
    final Uri uri = Uri.parse('${ApiConfig.base}/act-fact/$actId/photos/');
    return WorkPhotos.fromJson(_decode(await _get(uri)));
  }

  /// Заявка целиком: задание, категория, время заведения и исполнитель.
  /// `orderId` — это `work_id` строки: у заявки он и есть её собственный id.
  ///
  /// Исполнитель приезжает внутри ответа, поэтому за телефоном отдельно идти
  /// не нужно — в отличие от акта, который знает механика только номером.
  Future<OrderDetails> fetchOrder(int orderId) async {
    final Uri uri = Uri.parse('${ApiConfig.base}/order/$orderId/');
    return OrderDetails.fromJson(_decode(await _get(uri)));
  }

  /// Снимки заявки. Как и у ТО, отдельным запросом: без них карточка годна.
  ///
  /// Адрес **без** хвостовой косой черты: с ней это другая ручка — правка
  /// снимка по его собственному id.
  Future<OrderPhotos> fetchOrderPhotos(int orderId) async {
    final Uri uri = Uri.parse('${ApiConfig.base}/order-photo/$orderId');
    return OrderPhotos.fromJson(_decode(await _get(uri)));
  }

  /// Кому звонить. Идём за этим только когда акт назвал механика.
  Future<Performer> fetchPerformer(int userId) async {
    final Uri uri = Uri.parse('${ApiConfig.base}/cp/universal-user/$userId/');
    return Performer.fromJson(_decode(await _get(uri)));
  }

  Future<http.Response> _get(Uri uri) async {
    try {
      return await Api.get(
        uri,
        headers: <String, String>{'Accept': 'application/json'},
      ).timeout(timeout);
    } catch (_) {
      // Обрыв сети, таймаут и CORS попадают сюда вместе: различать их для
      // человека смысла нет, действие одно — повторить.
      throw const WorkDetailsException('Не удалось загрузить');
    }
  }

  void _check(http.Response response) {
    if (response.statusCode == 401 || response.statusCode == 403) {
      throw const WorkDetailsException('Недостаточно прав или истёк вход');
    }
    if (response.statusCode == 404) {
      throw const WorkDetailsException('Работа не найдена');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw WorkDetailsException(
        'Сервер ответил ошибкой ${response.statusCode}',
      );
    }
  }

  Map<String, dynamic> _decode(http.Response response) {
    _check(response);
    try {
      final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is! Map) {
        throw const WorkDetailsException('Сервер вернул неожиданный ответ');
      }
      return decoded.cast<String, dynamic>();
    } on WorkDetailsException {
      rethrow;
    } catch (_) {
      throw const WorkDetailsException('Не удалось прочитать ответ сервера');
    }
  }
}
