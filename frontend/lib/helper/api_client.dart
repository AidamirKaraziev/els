/// Единая точка исходящих запросов: заголовок, обновление токена, повтор.
///
/// До рефакторинга авторизации токен жил 8 дней и лежал одной строкой в
/// статике `IntTest.token`, а заголовок писался руками в каждом из 166 мест.
/// Теперь токенов два: access на 30 минут и refresh, и по истечении первого
/// бэкенд отвечает `401`. Разбирать это в каждом экране бессмысленно —
/// поэтому все запросы идут сюда.
///
/// Что делает клиент:
///   * подставляет `Authorization` из хранилища, а не из кода экрана;
///   * обновляет пару токенов заранее, если access вот-вот истечёт;
///   * получив `401`, обновляет токен и повторяет запрос ровно один раз;
///   * если обновиться не вышло — гасит сессию и зовёт `onSessionExpired`.
///
/// Обновление намеренно сделано single-flight: ротация на бэкенде гасит
/// предъявленный refresh, и два параллельных обновления привели бы к тому,
/// что второе пришло бы на уже погашенную сессию. Повторное использование
/// там считается кражей и гасит **все** сессии человека.
library;

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'api_config.dart';

/// Пара токенов и срок жизни access — всё, что нужно знать о сессии.
///
/// Хранится и в памяти, и в `SharedPreferences`: память нужна, чтобы не
/// ждать диск на каждом запросе, диск — чтобы перезагрузка вкладки не
/// требовала вводить пароль заново.
class TokenStore {
  static const String _accessKey = 'access_token';
  static const String _refreshKey = 'refresh_token';
  static const String _expiresAtKey = 'access_expires_at';

  /// Прежний ключ, под которым лежал единственный токен. Читается один раз
  /// при старте и стирается: пары в нём нет, и предъявлять его бэкенду
  /// бесполезно — он всё равно ответит `401`.
  static const String _legacyKey = 'token';

  static String? _access;
  static String? _refresh;
  static DateTime? _expiresAt;

  static String? get access => _access;

  static String? get refresh => _refresh;

  /// Есть ли что восстанавливать при старте приложения.
  static bool get hasSession => _refresh != null && _refresh!.isNotEmpty;

  /// Истёк ли access или истечёт в ближайшую минуту.
  ///
  /// Запас нужен, чтобы запрос, отправленный за секунду до истечения, не
  /// приходил на бэкенд уже просроченным.
  static bool get isAccessStale {
    if (_access == null || _access!.isEmpty) return true;
    final DateTime? until = _expiresAt;
    if (until == null) return true;
    return DateTime.now().isAfter(until.subtract(const Duration(seconds: 60)));
  }

  /// Поднимает сессию с диска. Зовётся один раз при старте приложения.
  static Future<void> load() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    _access = preferences.getString(_accessKey);
    _refresh = preferences.getString(_refreshKey);
    final int? millis = preferences.getInt(_expiresAtKey);
    _expiresAt = millis == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(millis);

    // Токен старого образца ничего не открывает: сессии на бэкенде теперь
    // строками в базе, а этот выдан до рефакторинга.
    if (preferences.getString(_legacyKey) != null) {
      await preferences.remove(_legacyKey);
    }
  }

  /// Сохраняет выданную пару. `expiresIn` — срок жизни access в секундах.
  static Future<void> save({
    required String access,
    required String refresh,
    required int expiresIn,
  }) async {
    _access = access;
    _refresh = refresh;
    _expiresAt = DateTime.now().add(Duration(seconds: expiresIn));

    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setString(_accessKey, access);
    await preferences.setString(_refreshKey, refresh);
    await preferences.setInt(_expiresAtKey, _expiresAt!.millisecondsSinceEpoch);
  }

  /// Забывает сессию — и в памяти, и на диске.
  static Future<void> clear() async {
    _access = null;
    _refresh = null;
    _expiresAt = null;

    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.remove(_accessKey);
    await preferences.remove(_refreshKey);
    await preferences.remove(_expiresAtKey);
    await preferences.remove(_legacyKey);
  }
}

/// Разбор тела ошибки бэкенда.
///
/// Формат один на все ручки:
/// `{"message": ..., "errors": [{"code": 136, "message": ...}], "description": ...}`.
class ApiError {
  /// Запись существует, но человеку не видна — `403` с кодом `136`.
  ///
  /// Отличать это от обычной нехватки прав обязательно: `403` без кода
  /// значит «кнопка вам не положена вообще» и её надо прятать интерфейсом,
  /// `403` с кодом `136` — «кнопка ваша, но запись чужая», и это показывают
  /// текстом. Оба ответа приходят на одних и тех же ручках.
  static const int foreignRecord = 136;

  /// Код из первой ошибки в теле, если он там есть.
  static int? codeOf(http.Response response) {
    final Map<String, dynamic>? body = _body(response);
    if (body == null) return null;
    final dynamic errors = body['errors'];
    if (errors is! List || errors.isEmpty) return null;
    final dynamic first = errors.first;
    if (first is! Map) return null;
    final dynamic code = first['code'];
    return code is int ? code : null;
  }

  /// Текст, который можно показать человеку.
  ///
  /// Бэкенд кладёт осмысленную фразу в `description` («Вход временно
  /// заблокирован», «Неверный логин или пароль»), а короткую — в
  /// `errors[].message`. Берём то, что есть, и не выдумываем своё: тексты
  /// согласованы на стороне API.
  static String messageOf(http.Response response, {String fallback = 'Не удалось выполнить запрос'}) {
    final Map<String, dynamic>? body = _body(response);
    if (body == null) return fallback;

    final dynamic description = body['description'];
    if (description is String && description.isNotEmpty) return description;

    final dynamic errors = body['errors'];
    if (errors is List && errors.isNotEmpty) {
      final dynamic first = errors.first;
      if (first is Map && first['message'] is String) {
        return first['message'] as String;
      }
    }

    final dynamic message = body['message'];
    if (message is String && message.isNotEmpty) return message;

    return fallback;
  }

  /// Чужая ли это запись — то самое отличие `136` от обычного отказа.
  static bool isForeignRecord(http.Response response) {
    return response.statusCode == 403 && codeOf(response) == foreignRecord;
  }

  static Map<String, dynamic>? _body(http.Response response) {
    if (response.bodyBytes.isEmpty) return null;
    try {
      final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));
      return decoded is Map<String, dynamic> ? decoded : null;
    } on FormatException {
      // Бывает на 500 и на ответах nginx: тело не JSON. Это не повод падать.
      return null;
    }
  }
}

/// Клиент API. Все запросы приложения идут через него.
class Api {
  /// Зовётся, когда сессию восстановить не удалось и нужен экран входа.
  ///
  /// Ставится один раз при старте приложения. Сам клиент навигацией не
  /// занимается: `BuildContext` ему взять неоткуда, да и не его дело.
  static void Function()? onSessionExpired;

  /// Идущее обновление токена. Пока оно не завершилось, остальные запросы
  /// ждут его результат, а не запускают своё.
  static Future<bool>? _refreshing;

  // ---------------------------------------------------------------- запросы

  static Future<http.Response> get(Uri url, {Map<String, String>? headers}) {
    return _send(() => http.get(url, headers: _headers(headers)));
  }

  static Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) {
    return _send(
      () => http.post(url, headers: _headers(headers), body: body, encoding: encoding),
    );
  }

  static Future<http.Response> put(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) {
    return _send(
      () => http.put(url, headers: _headers(headers), body: body, encoding: encoding),
    );
  }

  static Future<http.Response> delete(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
  }) {
    return _send(
      () => http.delete(url, headers: _headers(headers), body: body, encoding: encoding),
    );
  }

  /// Запрос с файлом. Заголовок уже проставлен, добавлять руками не нужно.
  ///
  /// Отдельный метод, потому что тело такого запроса — поток, и отправить
  /// его дважды нельзя: повторить после `401` не выйдет. Поэтому токен
  /// обновляется **до** отправки, а не после отказа.
  static Future<http.MultipartRequest> multipart(String method, Uri url) async {
    await _ensureFresh();
    final http.MultipartRequest request = http.MultipartRequest(method, url);
    request.headers.addAll(_headers(null));
    return request;
  }

  /// Отправляет подготовленный `multipart`-запрос.
  ///
  /// Повтора здесь нет — см. `multipart`. Если токен всё-таки протух между
  /// подготовкой и отправкой, человек увидит экран входа и повторит
  /// действие сам.
  static Future<http.StreamedResponse> sendMultipart(
    http.MultipartRequest request,
  ) async {
    // Токен проставляем здесь, а не только в `multipart`. Экраны собирают
    // свою карту заголовков заранее и дописывают её через
    // `request.headers.addAll(headers)` уже после сборки запроса — то есть
    // затирают свежий токен тем, который был на момент сборки карты. Это
    // последнее место перед отправкой, и здесь слово остаётся за хранилищем.
    final String? access = TokenStore.access;
    if (access != null && access.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $access';
    }

    final http.StreamedResponse response = await request.send();
    if (response.statusCode == 401) {
      await _dropSession();
    }
    return response;
  }

  // ------------------------------------------------------------ авторизация

  /// Вход. При успехе пара токенов уже сохранена.
  ///
  /// Мимо `_send` намеренно: обновлять здесь нечего, а `401` на входе
  /// означает «неверный пароль», а не «истёк токен».
  static Future<http.Response> login({
    required String email,
    required String password,
  }) async {
    final http.Response response = await http.post(
      Uri.parse('${ApiConfig.base}/auth/login'),
      headers: const {'Content-Type': 'application/json; charset=utf-8'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      await _savePair(response);
    }
    return response;
  }

  /// Выход. Гасит сессию на бэкенде и забывает токены здесь.
  ///
  /// Ответ не проверяем: если сессия на сервере уже погашена, выйти всё
  /// равно надо.
  static Future<void> logout() async {
    final String? refresh = TokenStore.refresh;
    if (refresh != null && refresh.isNotEmpty) {
      try {
        await http.post(
          Uri.parse('${ApiConfig.base}/auth/logout'),
          headers: const {'Content-Type': 'application/json; charset=utf-8'},
          body: jsonEncode({'refresh_token': refresh}),
        );
      } catch (_) {
        // Сеть отвалилась — локально выйти всё равно нужно.
      }
    }
    await TokenStore.clear();
  }

  /// Восстанавливает сессию при старте приложения.
  ///
  /// Возвращает `true`, если работать можно: либо access ещё жив, либо его
  /// удалось обновить по refresh.
  static Future<bool> restoreSession() async {
    await TokenStore.load();
    if (!TokenStore.hasSession) return false;
    if (!TokenStore.isAccessStale) return true;
    return _refreshTokens();
  }

  // --------------------------------------------------------------- внутреннее

  /// Общий путь любого запроса: обновить токен заранее, отправить, а при
  /// `401` обновить и повторить ровно один раз.
  static Future<http.Response> _send(
    Future<http.Response> Function() attempt,
  ) async {
    await _ensureFresh();

    http.Response response = await attempt();
    if (response.statusCode != 401) return response;

    // Токен мог протухнуть раньше срока: сменили пароль, уволили сотрудника,
    // перезапустили бэкенд с другим ключом. Пробуем обновиться.
    final bool refreshed = await _refreshTokens();
    if (!refreshed) return response;

    response = await attempt();
    if (response.statusCode == 401) await _dropSession();
    return response;
  }

  /// Обновляет пару заранее, если access вот-вот истечёт.
  static Future<void> _ensureFresh() async {
    if (!TokenStore.hasSession) return;
    if (!TokenStore.isAccessStale) return;
    await _refreshTokens();
  }

  /// Обновление пары, не больше одного за раз.
  static Future<bool> _refreshTokens() {
    // Если обновление уже идёт — ждём его, а не запускаем своё: второй
    // запрос пришёл бы на погашенную сессию и был бы принят за кражу.
    final Future<bool>? running = _refreshing;
    if (running != null) return running;

    final Future<bool> started = _doRefresh();
    _refreshing = started;
    return started.whenComplete(() {
      _refreshing = null;
    });
  }

  static Future<bool> _doRefresh() async {
    final String? refresh = TokenStore.refresh;
    if (refresh == null || refresh.isEmpty) return false;

    http.Response response;
    try {
      response = await http.post(
        Uri.parse('${ApiConfig.base}/auth/refresh'),
        headers: const {'Content-Type': 'application/json; charset=utf-8'},
        body: jsonEncode({'refresh_token': refresh}),
      );
    } catch (_) {
      // Сети нет. Сессию не гасим: токен может быть ещё жив, а человека
      // выкидывать на экран входа из-за пропавшего вайфая незачем.
      return false;
    }

    if (response.statusCode == 200) {
      await _savePair(response);
      return true;
    }

    // `403` с кодом 136 — refresh предъявлен повторно, все сессии погашены.
    // `422` с кодом 137 — refresh недействителен или истёк.
    // `403` с кодом 138 — доступ закрыт администратором.
    // Во всех трёх случаях помочь можно только новым входом.
    await _dropSession();
    return false;
  }

  static Future<void> _savePair(http.Response response) async {
    final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));
    final dynamic data = decoded is Map ? decoded['data'] : null;
    if (data is! Map) return;

    final dynamic access = data['access_token'];
    final dynamic refresh = data['refresh_token'];
    if (access is! String || refresh is! String) return;

    final dynamic expiresIn = data['expires_in'];
    await TokenStore.save(
      access: access,
      refresh: refresh,
      expiresIn: expiresIn is int ? expiresIn : 1800,
    );
  }

  /// Сессии больше нет: забыть токены и увести на экран входа.
  static Future<void> _dropSession() async {
    await TokenStore.clear();
    onSessionExpired?.call();
  }

  /// Заголовки запроса: то, что просил экран, плюс токен поверх.
  ///
  /// Токен ставится последним намеренно: карта заголовков приходит из экрана,
  /// собранная до отправки, и слово должно остаться за хранилищем — иначе в
  /// запрос уедет значение, устаревшее за время обновления.
  static Map<String, String> _headers(Map<String, String>? headers) {
    final Map<String, String> result = <String, String>{
      'Content-Type': 'application/json; charset=utf-8',
      if (headers != null) ...headers,
    };

    final String? access = TokenStore.access;
    if (access != null && access.isNotEmpty) {
      result['Authorization'] = 'Bearer $access';
    } else {
      // Пустой `Bearer` бэкенд разбирает как испорченный токен. Если токена
      // нет, честнее не посылать заголовок вовсе.
      result.remove('Authorization');
    }
    return result;
  }
}
