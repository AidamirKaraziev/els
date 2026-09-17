/// Push по заявкам: приём на телефоне и регистрация токена на сервере.
///
/// Сервер (`backend/src/services/push.py`) шлёт через FCM сообщение с
/// `notification{title, body}` и `data{kind, order_id}` в канал `emergency`.
/// Что с ним делает телефон, зависит от состояния приложения:
///
/// * **закрыто или свёрнуто** — уведомление показывает система сама, со
///   звуком канала; нам остаётся только заранее этот канал создать. Тап по
///   уведомлению открывает приложение — обновляем список.
/// * **открыто** — система в фореграунде ничего не показывает. Ловим
///   `onMessage`, показываем то же уведомление локально и обновляем список.
///
/// В журнал уведомлений (`notifications.dart`) отсюда ничего не пишется:
/// обновление вытянет изменения синхронизацией, и она сама положит «Новая
/// задача» / «снята» по разнице. Писать ещё раз — задвоить запись.
///
/// Только Android. На вебе `Firebase.initializeApp()` без параметров падает,
/// iOS-сборки нет, поэтому каждый вход в класс начинается с проверки
/// платформы, а на остальных всё это — пустые вызовы.
library;

import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../../helper/api_client.dart';
import '../../helper/api_config.dart';

class PushService {
  PushService._();

  static final PushService instance = PushService._();

  /// Тот же канал, что сервер ставит в `android.notification.channel_id`.
  /// Звук и важность — свойства канала, а не сообщения: Android читает их
  /// один раз при создании, дальше менять их может только человек в
  /// настройках. Поэтому имя канала лучше не переиспользовать под другое.
  static const String channelId = 'emergency';

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    channelId,
    'Заявки',
    description: 'Назначение и снятие заявок',
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
  );

  /// Иконка и цвет по `data.look` — тот же справочник, что `LOOKS` в
  /// `backend/src/services/push.py`. Иконки лежат в `android/.../res/drawable`.
  /// Закрытому приложению их подставляет система из самого сообщения; здесь
  /// то же для открытого. Неизвестный look — авария: лучше лишний красный.
  static const Map<String, _Look> _looks = {
    'alarm': _Look('ic_push_alarm', Color(0xFFD32F2F)),
    'maintenance': _Look('ic_push_maintenance', Color(0xFF2E7D32)),
    'request': _Look('ic_push_request', Color(0xFF1565C0)),
    'removed': _Look('ic_push_removed', Color(0xFF757575)),
  };

  final FlutterLocalNotificationsPlugin _local = FlutterLocalNotificationsPlugin();

  bool _ready = false;
  StreamSubscription<RemoteMessage>? _onMessage;
  StreamSubscription<RemoteMessage>? _onOpened;
  StreamSubscription<String>? _onToken;

  static bool get _supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  /// Готовит Firebase, канал и разрешение. Зовётся из `main()` до входа:
  /// канал должен существовать раньше, чем придёт первый push, а он может
  /// прийти и в закрытое приложение.
  Future<void> init() async {
    if (!_supported || _ready) return;
    try {
      await Firebase.initializeApp();
      await _local.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        ),
      );
      await _local
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_channel);
      // Android 13+ без этого уведомления молча не показывает. Ответ не
      // важен: отказал — значит отказал, заявки всё равно видны в списке.
      await FirebaseMessaging.instance.requestPermission();
      _ready = true;
    } catch (error) {
      // Нет google-services.json, нет Play-сервисов — приложение работает
      // без push, как и до этого этапа.
      debugPrint('push: не включён — $error');
    }
  }

  /// Подписывает вошедшего: сообщения → [onMessage], токен → сервер.
  /// Повторный вызов (сменился человек) снимает прежние подписки.
  Future<void> attach({required Future<void> Function() onMessage}) async {
    if (!_supported) return;
    await init();
    if (!_ready) return;
    await detach();

    _onMessage = FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      unawaited(_showLocally(message));
      unawaited(onMessage());
    });
    _onOpened = FirebaseMessaging.onMessageOpenedApp.listen((_) {
      unawaited(onMessage());
    });
    _onToken = FirebaseMessaging.instance.onTokenRefresh.listen((String token) {
      unawaited(_register(token));
    });

    // Приложение открыли тапом по уведомлению из закрытого состояния.
    final RemoteMessage? initial =
        await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) unawaited(onMessage());

    await register();
  }

  Future<void> detach() async {
    await _onMessage?.cancel();
    await _onOpened?.cancel();
    await _onToken?.cancel();
    _onMessage = null;
    _onOpened = null;
    _onToken = null;
  }

  /// Регистрирует токен этого телефона за вошедшим.
  Future<void> register() async {
    if (!_supported || !_ready) return;
    final String? token = await _token();
    if (token != null) await _register(token);
  }

  /// Снимает токен при выходе. Зовётся до `Api.logout()`, пока access ещё
  /// жив. Ошибки глотаем: выйти всё равно нужно.
  Future<void> unregister() async {
    if (!_supported || !_ready) return;
    await detach();
    final String? token = await _token();
    if (token == null) return;
    try {
      await Api.delete(
        Uri.parse('${ApiConfig.base}/device-token/'),
        headers: const {'Content-Type': 'application/json; charset=utf-8'},
        body: jsonEncode({'token': token, 'platform': 'android'}),
      );
    } catch (error) {
      debugPrint('push: токен не снят — $error');
    }
  }

  Future<String?> _token() async {
    try {
      final String? token = await FirebaseMessaging.instance.getToken();
      // В лог намеренно: по нему шлётся проверочное сообщение мимо сайта —
      // `uv run python -m src.services.push --token …`.
      debugPrint('push: токен $token');
      return token;
    } catch (error) {
      debugPrint('push: токен не получен — $error');
      return null;
    }
  }

  Future<void> _register(String token) async {
    try {
      await Api.post(
        Uri.parse('${ApiConfig.base}/device-token/'),
        headers: const {'Content-Type': 'application/json; charset=utf-8'},
        body: jsonEncode({'token': token, 'platform': 'android'}),
      );
    } catch (error) {
      // Сети нет — сервер узнает токен при следующем входе или обновлении.
      debugPrint('push: токен не зарегистрирован — $error');
    }
  }

  Future<void> _showLocally(RemoteMessage message) async {
    final RemoteNotification? note = message.notification;
    if (note == null) return;
    final look = _looks[message.data['look']] ?? _looks['alarm']!;
    await _local.show(
      message.hashCode,
      note.title,
      note.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.max,
          priority: Priority.high,
          icon: look.icon,
          color: look.color,
        ),
      ),
    );
  }
}

class _Look {
  const _Look(this.icon, this.color);

  final String icon;
  final Color color;
}
