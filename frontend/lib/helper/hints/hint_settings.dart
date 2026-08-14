import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Что человек решил про подсказки.
///
/// Хранится локально, а не на сервере: поле у пользователя потребовало бы
/// миграции и новой ручки ради настройки, которую меняют один раз в жизни.
/// Цена — на другом устройстве подсказки покажутся заново; если это окажется
/// неудобным, состояние переедет на бэкенд отдельной задачей.
///
/// В вебе `shared_preferences` — это `localStorage`, так что чистка кэша
/// браузера сбрасывает и подсказки. Для «показать заново» это скорее плюс.
class HintSettings extends ChangeNotifier {
  HintSettings._();

  /// Один экземпляр на приложение: карточка на главной и переключатель в
  /// профиле обязаны видеть одно и то же состояние.
  static final HintSettings instance = HintSettings._();

  static const String _kEnabled = 'hints_enabled';
  static const String _kDismissedPrefix = 'hint_dismissed_';

  bool _enabled = true;
  Set<String> _dismissed = <String>{};
  bool _loaded = false;

  bool get enabled => _enabled;
  bool get loaded => _loaded;

  /// Читает настройки из хранилища. Вызывается один раз при старте.
  ///
  /// Неудача чтения не должна ломать приложение: подсказки — украшение, а не
  /// функция. При ошибке остаёмся на умолчаниях, то есть подсказки включены.
  Future<void> load() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      _enabled = prefs.getBool(_kEnabled) ?? true;
      _dismissed = prefs
          .getKeys()
          .where((String key) => key.startsWith(_kDismissedPrefix))
          .where((String key) => prefs.getBool(key) == true)
          .map((String key) => key.substring(_kDismissedPrefix.length))
          .toSet();
    } catch (_) {
      _enabled = true;
      _dismissed = <String>{};
    }
    _loaded = true;
    notifyListeners();
  }

  /// Показывать ли карточку с этим идентификатором.
  bool shows(String id) => _enabled && !_dismissed.contains(id);

  /// «Больше не показывать» по конкретной карточке.
  Future<void> dismiss(String id) async {
    if (_dismissed.contains(id)) return;
    _dismissed = <String>{..._dismissed, id};
    notifyListeners();
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('$_kDismissedPrefix$id', true);
    } catch (_) {
      // Не сохранилось — карточка вернётся после перезагрузки. Неприятно,
      // но это не повод показывать человеку ошибку.
    }
  }

  /// Переключатель в профиле.
  ///
  /// Включение возвращает **все** скрытые карточки: человек, который жмёт
  /// «показывать подсказки», хочет увидеть их, а не узнать, что когда-то
  /// закрыл их навсегда.
  Future<void> setEnabled(bool value) async {
    _enabled = value;
    if (value) _dismissed = <String>{};
    notifyListeners();

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kEnabled, value);
      if (value) {
        for (final String key in prefs
            .getKeys()
            .where((String key) => key.startsWith(_kDismissedPrefix))
            .toList()) {
          await prefs.remove(key);
        }
      }
    } catch (_) {
      // См. выше: настройка не сохранилась, но в этой сессии работает.
    }
  }
}
