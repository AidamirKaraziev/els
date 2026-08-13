/// Картинки из API: фото, аватарки и сканы документов.
///
/// `/api/v1/static/...` теперь требует токена, и без заголовка вместо каждой
/// фотографии приходит `401`. Заголовок к картинке отправить можно — вопреки
/// первому впечатлению: `Image.network` и `NetworkImage` принимают `headers`,
/// и на вебе Flutter в этом случае грузит картинку запросом, а не тегом
/// `<img>`, куда заголовок не подставить.
///
/// Поэтому короткоживущая ссылка (`POST /files/link`) здесь не нужна: она
/// осталась для случаев, где запрос делает не приложение, а браузер —
/// открытие файла в новой вкладке и выгрузка отчёта.
///
/// Адрес бэкенд отдаёт без схемы (`host:port/api/v1/static/…`,
/// см. `backend/src/getters/static_url.py`), её дописывает `ApiConfig`.
library;

import 'dart:convert';

import 'package:flutter/material.dart';

import 'api_client.dart';
import 'api_config.dart';

/// Прозрачный пиксель на случай, когда фотографии нет.
///
/// Раньше из пустого поля получался адрес вида `http://null`, и на экране
/// возникала иконка битой картинки. Пустое место честнее: под аватаркой
/// уже лежит серый кружок-заглушка, и он остаётся виден.
final ImageProvider _blank = MemoryImage(
  base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAC'
    'hwGA60e6kgAAAABJRU5ErkJggg==',
  ),
);

/// Заголовки для запроса за файлом.
///
/// Пустая карта означает «токена нет»: тогда Flutter на вебе вернётся к
/// загрузке через `<img>`, и картинка не откроется. Это верное поведение —
/// без входа файлы и не должны быть видны.
Map<String, String> _headers() {
  final String? access = TokenStore.access;
  if (access == null || access.isEmpty) return const <String, String>{};
  return <String, String>{'Authorization': 'Bearer $access'};
}

/// Картинка по пути из ответа API — для `foregroundImage`, `backgroundImage`
/// и прочих мест, где нужен `ImageProvider`.
ImageProvider apiImage(Object? path) {
  final String value = path?.toString() ?? '';
  // `'null'` приходит из интерполяции незаполненного поля: в коде экранов
  // путь подставляется прямо в строку, без проверки на null.
  if (value.isEmpty || value == 'null') return _blank;

  return NetworkImage('${ApiConfig.scheme}://$value', headers: _headers());
}

/// То же самое, но виджетом — на замену `Image.network`.
Widget apiImageWidget(Object? path, {BoxFit? fit}) {
  return Image(image: apiImage(path), fit: fit);
}
