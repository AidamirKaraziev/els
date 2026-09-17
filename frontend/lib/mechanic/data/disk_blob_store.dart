/// Снимки очереди исходящих — файлами на диске телефона.
///
/// Отдельным файлом от `local_store.dart`, потому что здесь `dart:io` и
/// `path_provider`: в вебе их нет, а `local_store.dart` импортируют и тесты,
/// и веб-сборка. Выбор между этим хранилищем и base64 в настройках делает
/// `MechanicWorkspace` по платформе.
///
/// Папка — `getApplicationSupportDirectory()/outbox`, а не temp: временную
/// систему разрешено чистить, а снимок, который ждёт связи третий день, —
/// это сделанная работа, и терять её нельзя. Ключ хранилища —
/// `mechanic.<userId>.outbox.file.<id>` — уже годится в имя файла.
library;

import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

import 'local_store.dart';

class DiskBlobStore implements BlobStore {
  DiskBlobStore({Future<Directory> Function()? root}) : _root = root ?? _defaultRoot;

  final Future<Directory> Function() _root;

  static Future<Directory> _defaultRoot() async {
    final Directory support = await getApplicationSupportDirectory();
    return Directory('${support.path}/outbox');
  }

  Future<File> _file(String key) async {
    final Directory dir = await _root();
    return File('${dir.path}/$key');
  }

  @override
  Future<void> write(String key, List<int> bytes) async {
    final File file = await _file(key);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes, flush: true);
  }

  @override
  Future<Uint8List?> read(String key) async {
    final File file = await _file(key);
    if (!await file.exists()) return null;
    return file.readAsBytes();
  }

  @override
  Future<void> remove(String key) async {
    final File file = await _file(key);
    if (await file.exists()) await file.delete();
  }

  @override
  Future<void> removeAll(String prefix) async {
    final Directory dir = await _root();
    if (!await dir.exists()) return;
    await for (final FileSystemEntity entry in dir.list()) {
      if (entry is File && entry.uri.pathSegments.last.startsWith(prefix)) {
        await entry.delete();
      }
    }
  }
}
