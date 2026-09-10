/// Что за сборка приложения лежит на сервере и как её скачать.
///
/// Механик работает в подвале, где связи нет, поэтому веб-версии ему мало —
/// нужен установленный APK. Взять его неоткуда: в магазины приложение не
/// выложено, а открытая ссылка означала бы, что сборку со всеми внутренними
/// адресами скачивает кто угодно. Отсюда закрытая страница и эти три вызова.
///
/// Своя версия приезжает не из плагина, а из `--dart-define`: CI подставляет
/// её при сборке APK (`APP_VERSION_CODE`), а веб-сборка не подставляет ничего.
/// Это ровно то поведение, которое нужно — в браузере обновлять нечего, и
/// баннер «вышло обновление» там не появляется. Плагин ради одного числа
/// добавил бы в pubspec ещё одну зависимость, а он и так собран с трудом.
library;

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../helper/api_client.dart';
import '../helper/api_config.dart';

/// Сборка, выложенная на сервере.
class AppRelease {
  const AppRelease({
    required this.versionName,
    required this.versionCode,
    required this.size,
    this.sha256,
    this.publishedAt,
    this.notes,
  });

  final String versionName;
  final int versionCode;
  final int size;
  final String? sha256;
  final String? publishedAt;
  final String? notes;

  /// Размер для человека. Мегабайты, без долей: разница между 41,7 и 42 МБ
  /// механику ничего не говорит.
  String get sizeLabel => '${(size / 1024 / 1024).round()} МБ';

  static AppRelease? fromJson(Map<String, dynamic> json) {
    final dynamic name = json['version_name'];
    final dynamic code = json['version_code'];
    final dynamic size = json['size'];
    if (name is! String || code is! int || size is! int) return null;

    return AppRelease(
      versionName: name,
      versionCode: code,
      size: size,
      sha256: json['sha256'] as String?,
      publishedAt: json['published_at'] as String?,
      notes: json['notes'] as String?,
    );
  }
}

/// Чем закончился запрос: сборка, «ещё не выложили» или обрыв связи.
///
/// Три состояния, а не «данные или null»: экран показывает разное. «Не
/// выложили» — это нормальное состояние сервера до первого выката, а не
/// поломка, и пугать им человека нечем.
class AppReleaseResult {
  const AppReleaseResult({this.release, this.notPublished = false, this.error});

  final AppRelease? release;
  final bool notPublished;
  final String? error;
}

class AppReleaseApi {
  /// Версия сборки, в которой этот код сейчас работает.
  ///
  /// Ноль означает «неизвестно»: так выглядит веб, где обновлять нечего.
  static const int installedVersionCode =
      int.fromEnvironment('APP_VERSION_CODE');

  static const String installedVersionName =
      String.fromEnvironment('APP_VERSION_NAME');

  /// Работаем ли внутри установленного приложения.
  static bool get isInstalledApp => installedVersionCode > 0;

  static Future<AppReleaseResult> fetch() async {
    final http.Response response;
    try {
      response = await Api.get(Uri.parse('${ApiConfig.base}/app/release'));
    } catch (_) {
      // Связи нет — единственная причина, по которой сюда можно попасть.
      // Текст исключения человеку не показываем: он на английском и про
      // сокеты.
      return const AppReleaseResult(error: 'Нет связи с сервером');
    }

    if (response.statusCode == 404) {
      return const AppReleaseResult(notPublished: true);
    }
    if (response.statusCode != 200) {
      return AppReleaseResult(error: 'Сервер ответил ${response.statusCode}');
    }

    try {
      final Map<String, dynamic> body =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final AppRelease? release =
          AppRelease.fromJson(body['data'] as Map<String, dynamic>);
      if (release == null) {
        return const AppReleaseResult(error: 'Сервер ответил непонятным');
      }
      return AppReleaseResult(release: release);
    } catch (_) {
      return const AppReleaseResult(error: 'Сервер ответил непонятным');
    }
  }

  /// Адрес скачивания с токеном в строке запроса.
  ///
  /// Заголовок `Authorization` при переходе по ссылке браузер не отправляет,
  /// поэтому ссылку подписывает бэкенд — она живёт минуту и открывает только
  /// этот один адрес.
  static Future<String?> downloadUrl() async {
    final http.Response response;
    try {
      response = await Api.post(Uri.parse('${ApiConfig.base}/app/link'));
    } catch (_) {
      return null;
    }
    if (response.statusCode != 200) return null;

    try {
      final Map<String, dynamic> body =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final String url =
          (body['data'] as Map<String, dynamic>)['url'] as String;
      // Адрес приходит без схемы, см. `ApiConfig.withScheme`.
      return ApiConfig.withScheme(url);
    } catch (_) {
      return null;
    }
  }
}
