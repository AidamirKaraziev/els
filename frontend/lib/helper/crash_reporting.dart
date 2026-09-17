/// Крэш-репорты: падения APK уходят в Sentry с версией сборки.
///
/// О падениях у механиков мы узнаём только со слов — «приложение вылетело»,
/// без экрана и без версии. Sentry даёт стек и `release`, по которому видно,
/// какая именно сборка упала и починено ли это уже.
///
/// Включается только при `--dart-define=SENTRY_DSN=…` — его подставляет CI в
/// сборку APK из секрета. Веб и локальные сборки DSN не получают, и тогда
/// здесь ничего не инициализируется: приложение запускается как раньше,
/// ни одного запроса наружу. DSN в коде не хранится намеренно: репозиторий
/// открыт шире, чем проект в Sentry.
///
/// `release` — `els@<versionName>+<versionCode>`, те же значения, что
/// показывает экран «Приложение» и что лежат в `release.json` на сервере:
/// по событию в Sentry сразу ясно, обновился человек или нет.
library;

import 'dart:async';

import 'package:sentry_flutter/sentry_flutter.dart';

import '../app_download/app_release.dart';

class CrashReporting {
  CrashReporting._();

  static const String _dsn = String.fromEnvironment('SENTRY_DSN');

  /// Задан ли DSN в этой сборке.
  static bool get enabled => _dsn.isNotEmpty;

  /// Версия сборки в формате Sentry.
  static String get release =>
      'els@${AppReleaseApi.installedVersionName}'
      '+${AppReleaseApi.installedVersionCode}';

  /// Запускает приложение; с DSN — под присмотром Sentry.
  ///
  /// `SentryFlutter.init` сам перехватывает `FlutterError.onError` и
  /// необработанные исключения в зоне, поэтому [app] не оборачивается
  /// ничем дополнительно.
  static Future<void> run(FutureOr<void> Function() app) async {
    if (!enabled) {
      await app();
      return;
    }
    await SentryFlutter.init(
      (SentryFlutterOptions options) {
        options.dsn = _dsn;
        options.release = release;
        options.environment = 'prod';
        // Только падения. Трассировка запросов и кадров — отдельная
        // тема и отдельный трафик, а у механика в подвале его нет.
        options.tracesSampleRate = 0.0;
        options.sendDefaultPii = false;
      },
      appRunner: app,
    );
  }

  /// Отправить пойманную ошибку — ту, что не роняет приложение, но о которой
  /// стоит знать. Без DSN — ничего не делает.
  static Future<void> report(Object error, [StackTrace? stackTrace]) async {
    if (!enabled) return;
    await Sentry.captureException(error, stackTrace: stackTrace);
  }
}
