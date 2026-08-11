import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

/// Выбор изображения — одинаково в браузере и на телефоне.
///
/// Раньше экраны звали `ImagePickerWeb.getImageInfo` из пакета `image_picker_web`,
/// который внутри тянет `dart:html`. Из-за этого сборка под Android и iOS падала
/// на этапе компиляции: `dart:html` в мобильном рантайме не существует.
///
/// Условные импорты для этого не нужны: `image_picker` — federated plugin,
/// он сам подключает `image_picker_for_web` в вебе и нативные реализации на
/// телефонах. Один вызов, одна кодовая база, никаких веток по платформе.
class PickedImage {
  /// Имя файла и байты объявлены **nullable** намеренно: так подпись совпадает
  /// с `MediaInfo` из прежнего пакета, и 54 обращения вида `imageFile.data!`
  /// и `imageFile.fileName ?? ''` в экранах остались нетронутыми.
  final String? fileName;
  final Uint8List? data;

  const PickedImage({this.fileName, this.data});
}

/// Открывает галерею (в вебе — диалог выбора файла).
///
/// Возвращает `null`, если человек закрыл диалог, ничего не выбрав.
Future<PickedImage?> pickImageFromGallery() async {
  final file = await ImagePicker().pickImage(source: ImageSource.gallery);
  if (file == null) return null;

  // Читаем именно байты, а не путь: в вебе `XFile.path` — это blob-ссылка,
  // и загрузить по ней файл на бэкенд нельзя.
  return PickedImage(fileName: file.name, data: await file.readAsBytes());
}
