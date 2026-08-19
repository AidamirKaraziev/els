/// Локальная база механика: то, что телефон помнит без сети.
///
/// Связь на объектах рвётся — в машинном помещении её нет почти всегда.
/// Поэтому списки заявок и ТО лежат на устройстве, а сеть нужна только чтобы
/// догнать изменения и отправить сделанное.
///
/// Хранилище намеренно за интерфейсом `KeyValueStore`: сейчас под ним
/// `SharedPreferences` — он есть в зависимостях, работает и в APK, и в вебе,
/// и не тянет ни новых пакетов, ни кодогенерации. Записей у одного механика
/// сотни, не миллионы, и этого хватает. Когда упрёмся (полный офлайн по
/// объектам и справочникам — отдельный разговор), под тем же интерфейсом
/// появится настоящая база, и ни один экран об этом не узнает.
///
/// Два правила, из которых всё остальное следует:
///
/// * **Ключи привязаны к вошедшему.** Один телефон бывает общим на бригаду, и
///   после смены человека чужие заявки показывать нельзя.
/// * **Метка синхронизации — это `updated_at` с сервера, а не «сейчас».**
///   Часы телефона врут, и по местному времени клиент либо пропустит правки,
///   либо будет качать одно и то же вечно.
library;

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Минимум, который нужен хранилищу: строка по ключу.
///
/// Всё остальное — списки, метки, разбор JSON — считается поверх и потому
/// проверяется тестами без телефона.
abstract class KeyValueStore {
  Future<String?> read(String key);

  Future<void> write(String key, String value);

  Future<void> remove(String key);

  /// Ключи, начинающиеся с префикса. Нужен только для «забыть всё про
  /// человека» при выходе.
  Future<List<String>> keys(String prefix);
}

/// Хранилище на `SharedPreferences` — то, что работает в собранном
/// приложении.
class PreferencesStore implements KeyValueStore {
  const PreferencesStore();

  @override
  Future<String?> read(String key) async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    return preferences.getString(key);
  }

  @override
  Future<void> write(String key, String value) async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setString(key, value);
  }

  @override
  Future<void> remove(String key) async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.remove(key);
  }

  @override
  Future<List<String>> keys(String prefix) async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    return preferences
        .getKeys()
        .where((String key) => key.startsWith(prefix))
        .toList();
  }
}

/// Хранилище в памяти — для тестов.
class MemoryStore implements KeyValueStore {
  final Map<String, String> _values = <String, String>{};

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> write(String key, String value) async {
    _values[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    _values.remove(key);
  }

  @override
  Future<List<String>> keys(String prefix) async {
    return _values.keys.where((String key) => key.startsWith(prefix)).toList();
  }
}

/// Списки, которые механик носит с собой.
class LocalCollection {
  /// Заявки, назначенные на него, — `GET /order/for-me`.
  static const String orders = 'orders';

  /// Плановые ТО — `GET /act-fact/for-me`.
  static const String maintenance = 'maintenance';

  /// Журнал уведомлений. Считается на телефоне: на бэкенде уведомлений нет.
  static const String events = 'events';

  /// Отметки «эту правку сделал я сам» — чтобы своя же отметка, приехавшая
  /// обратно синхронизацией, не показалась чужим изменением.
  static const String myChanges = 'my-changes';
}

/// Локальная база одного человека.
class LocalStore {
  LocalStore({required this.userId, KeyValueStore store = const PreferencesStore()})
      : _store = store;

  /// Кому принадлежат данные. Ноль означает «профиль ещё не загружен» — с
  /// таким значением писать нельзя, иначе после входа данные окажутся
  /// ничьими.
  final int userId;

  final KeyValueStore _store;

  static const String _prefix = 'mechanic';

  String _dataKey(String collection) => '$_prefix.$userId.$collection';

  String _markKey(String collection) => '$_prefix.$userId.$collection.mark';

  /// Записи коллекции, как их отдал бэкенд.
  ///
  /// Разбирать их в модели здесь незачем: экраны заявок и ТО читают те же
  /// поля, что и из ответа, и лишний слой означал бы третье описание одних и
  /// тех же данных — после схемы на бэкенде и разбора на экране.
  Future<List<Map<String, dynamic>>> read(String collection) async {
    final String? raw = await _store.read(_dataKey(collection));
    if (raw == null || raw.isEmpty) return <Map<String, dynamic>>[];
    try {
      final dynamic decoded = jsonDecode(raw);
      if (decoded is! List) return <Map<String, dynamic>>[];
      return decoded
          .whereType<Map<dynamic, dynamic>>()
          .map((Map<dynamic, dynamic> row) => row.cast<String, dynamic>())
          .toList();
    } on FormatException {
      // Хранилище испорчено — это не повод не пустить человека в приложение.
      // Считаем, что данных нет: следующая синхронизация нальёт их заново.
      return <Map<String, dynamic>>[];
    }
  }

  Future<void> write(String collection, List<Map<String, dynamic>> rows) {
    return _store.write(_dataKey(collection), jsonEncode(rows));
  }

  /// Метка «до какого времени мы всё знаем», в секундах эпохи.
  Future<int?> mark(String collection) async {
    final String? raw = await _store.read(_markKey(collection));
    return raw == null ? null : int.tryParse(raw);
  }

  Future<void> setMark(String collection, int seconds) {
    return _store.write(_markKey(collection), '$seconds');
  }

  /// Забывает всё про этого человека. Зовётся при выходе: телефон бригадный.
  Future<void> forget() async {
    for (final String key in await _store.keys('$_prefix.$userId.')) {
      await _store.remove(key);
    }
  }
}

/// Слияние присланного с тем, что уже лежит на телефоне.
///
/// Бэкенд по `changed_since` отдаёт только изменившееся, **включая
/// удалённое**: заархивированная запись приходит с `is_actual: false`. Это
/// единственный способ узнать об удалении — записи, которая просто перестала
/// приходить, клиент не отличит от записи, до которой не дошла страница.
///
/// Удалённое **остаётся на телефоне**, а не выбрасывается: механик должен
/// видеть, что задачу, которая на него ставилась, сняли, — иначе она просто
/// исчезает с экрана и человек считает, что приложение её потеряло. На экране
/// такие записи уходят серым в свёрнутый архив.
///
/// Чтобы архив не рос вечно, удалённых записей хранится не больше
/// [keepArchived] — самых свежих по метке правки. Остальные забываются: это
/// список «что у меня сняли», а не журнал за все годы.
List<Map<String, dynamic>> mergeRows(
  List<Map<String, dynamic>> stored,
  List<Map<String, dynamic>> incoming, {
  required String idField,
  int keepArchived = 30,
}) {
  final Map<Object, Map<String, dynamic>> byId = <Object, Map<String, dynamic>>{
    for (final Map<String, dynamic> row in stored)
      if (row[idField] != null) row[idField] as Object: row,
  };

  for (final Map<String, dynamic> row in incoming) {
    final Object? id = row[idField] as Object?;
    if (id == null) continue;
    byId[id] = row;
  }

  final List<Map<String, dynamic>> rows = byId.values.toList();

  final List<Map<String, dynamic>> archived = rows
      .where((Map<String, dynamic> row) => row['is_actual'] == false)
      .toList()
    ..sort((Map<String, dynamic> a, Map<String, dynamic> b) =>
        _markOf(b).compareTo(_markOf(a)));
  if (archived.length <= keepArchived) return rows;

  final Set<Object> forgotten = <Object>{
    for (final Map<String, dynamic> row in archived.skip(keepArchived))
      if (row[idField] != null) row[idField] as Object,
  };
  return rows
      .where((Map<String, dynamic> row) => !forgotten.contains(row[idField]))
      .toList();
}

int _markOf(Map<String, dynamic> row) {
  final dynamic value = row['updated_at'];
  return value is int ? value : 0;
}

/// Новая метка синхронизации: самая поздняя правка из присланного.
///
/// Берём именно её, а не текущее время: между запросом и ответом на бэкенде
/// могла появиться правка, и «сейчас» пропустило бы её навсегда. Ничего не
/// пришло — метка остаётся прежней.
int? latestMark(List<Map<String, dynamic>> rows, int? current) {
  int? mark = current;
  for (final Map<String, dynamic> row in rows) {
    final dynamic value = row['updated_at'];
    if (value is int && (mark == null || value > mark)) mark = value;
  }
  return mark;
}
