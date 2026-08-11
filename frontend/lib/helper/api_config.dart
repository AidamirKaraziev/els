import 'package:flutter/foundation.dart' show kIsWeb;

/// Единственное место, которое знает адрес бэкенда.
///
/// Раньше адрес лежал в `IntTest.myIp` — в файле с цветами — и подставлялся
/// в 185 строк интерполяцией с жёстко зашитой схемой `http`. Поменять окружение
/// можно было только правкой кода и пересборкой.
///
/// Кто какой адрес получает:
///
/// * **веб** — тот же origin, откуда отдана страница. nginx отдаёт и приложение,
///   и API, поэтому одна и та же сборка работает и на `localhost:8080`,
///   и на боевом домене, и по HTTPS — без пересборки и без CORS.
/// * **iOS / Android** — из `--dart-define`, потому что телефону нужен адрес
///   машины в сети:
///   `flutter run --dart-define=API_ORIGIN=http://192.168.1.5:8080`
///   (Android-эмулятор: `http://10.0.2.2:8080`).
class ApiConfig {
  /// Задаётся при сборке: `--dart-define=API_ORIGIN=http://host:port`.
  /// Пустая строка означает «не задано» — const-строки не бывают null.
  static const _originOverride = String.fromEnvironment('API_ORIGIN');

  /// Адрес, на котором работал фронт до переноса в моно-репо.
  ///
  /// Нужен только как запасной вариант для мобильной сборки без `--dart-define`,
  /// чтобы поведение не менялось молча. Когда шаг с мобильными сборками будет
  /// закрыт, `API_ORIGIN` станет обязательным и эту константу можно убрать.
  static const _legacyOrigin = 'http://185.154.193.42:8000';

  /// Схема, хост и порт бэкенда, без завершающего слэша.
  static String get origin {
    if (_originOverride.isNotEmpty) return _originOverride;
    if (kIsWeb) return Uri.base.origin;
    return _legacyOrigin;
  }

  /// Префикс REST API. Именно его подставляют в запросы.
  static String get base => '$origin/api/v1';
}
