/// Лист «Дефект»: механик записывает найденное, не выходя из работы.
///
/// Кадра в макете нет — вёрстка собрана по соседним листам оболочки механика
/// (`close_act_sheet.dart` и лист «Проблема» в `act_screen.dart`), чтобы
/// человек не встретил здесь третий по счёту вид одного и того же окна.
///
/// Почему лист, а не экран: дефект находят посреди работы, между двумя
/// пунктами чек-листа, и уводить механика с карточки ТО ради трёх полей
/// значит потерять место, куда он возвращается.
///
/// **Слово «акт» человеку не показываем.** В базе это дефектный акт, на
/// экране — дефект: механик его так и называет, а акт из него делает прораб.
///
/// Обязателен только заголовок — ровно как в `POST /defective-act/`
/// (`backend/src/schemas/defective_act.py`). Описание и снимки
/// необязательны: дефект, записанный одной строкой, лучше незаписанного.
library;

import 'package:flutter/material.dart';

import '../../helper/class_colors.dart';
import '../../helper/image_picking.dart';
import '../mechanic_theme.dart';

/// Сколько снимков механик прикладывает к одному дефекту.
///
/// Пять — столько же, сколько к пункту чек-листа: очередь держит снимки в
/// хранилище телефона, и лимит там взят из его размера, а не из вкуса.
const int defectPhotoLimit = 5;

/// Что механик написал про дефект. `null` из листа — передумал.
class DefectDraft {
  const DefectDraft({
    required this.title,
    this.description,
    this.photos = const <PickedImage>[],
  });

  /// Единственное обязательное поле.
  final String title;

  /// Пустое описание отдаём как `null`, а не пустой строкой: в базе это
  /// разные вещи, и прорабу пустая строка ничего не говорит.
  final String? description;

  final List<PickedImage> photos;
}

/// Показывает лист и возвращает написанное.
///
/// `pickPhoto` подменяется в тестах: настоящий выбор снимка открывает камеру
/// и в виджет-тесте недоступен.
Future<DefectDraft?> showDefectSheet(
  BuildContext context, {
  Future<PickedImage?> Function({required bool fromCamera})? pickPhoto,
}) {
  return showModalBottomSheet<DefectDraft>(
    context: context,
    isScrollControlled: true,
    backgroundColor: ColorApp.myColorWhite,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(12.0)),
    ),
    builder: (BuildContext context) =>
        _DefectSheet(pickPhoto: pickPhoto ?? pickWorkPhoto),
  );
}

class _DefectSheet extends StatefulWidget {
  const _DefectSheet({required this.pickPhoto});

  final Future<PickedImage?> Function({required bool fromCamera}) pickPhoto;

  @override
  State<_DefectSheet> createState() => _DefectSheetState();
}

class _DefectSheetState extends State<_DefectSheet> {
  final TextEditingController _title = TextEditingController();
  final TextEditingController _description = TextEditingController();
  final List<PickedImage> _photos = <PickedImage>[];

  /// Пока заголовка нет, кнопка гаснет: отправлять нечего, и сказать об этом
  /// видом кнопки честнее, чем руганью после нажатия.
  bool _empty = true;

  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _title.addListener(() {
      final bool empty = _title.text.trim().isEmpty;
      if (empty != _empty) setState(() => _empty = empty);
    });
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Отступ снизу — под клавиатуру: без него она закрывает описание и
    // кнопку целиком, а лист прокручивается, потому что со снимками он выше
    // экрана телефона.
    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20.0,
          12.0,
          20.0,
          20.0 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Center(
              child: Container(
                width: 36.0,
                height: 4.0,
                decoration: BoxDecoration(
                  color: ColorApp.myColorGrayBorder,
                  borderRadius: BorderRadius.circular(2.0),
                ),
              ),
            ),
            const SizedBox(height: 14.0),
            const Text(
              'Записать дефект',
              style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10.0),
            const Text(
              'Дефект уйдёт прорабу вместе с этой работой. Работу он не '
              'останавливает — чек-лист можно проходить дальше.',
              style: TextStyle(
                fontSize: 14.0,
                fontWeight: FontWeight.w300,
                color: Color(0xff1C1C1E),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14.0),
            TextField(
              controller: _title,
              textCapitalization: TextCapitalization.sentences,
              style: const TextStyle(fontSize: 14.0),
              decoration: _fieldStyle(
                label: 'Что не так',
                hint: 'Например: течёт редуктор',
              ),
            ),
            const SizedBox(height: 12.0),
            // Описание — то, чего не видно на снимке: с каких пор, при каком
            // режиме, что уже пробовали.
            TextField(
              controller: _description,
              minLines: 2,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              style: const TextStyle(fontSize: 14.0),
              decoration: _fieldStyle(
                label: 'Подробности',
                hint: 'Необязательно',
              ),
            ),
            const SizedBox(height: 14.0),
            _Photos(
              photos: _photos,
              busy: _busy,
              onAdd: _addPhoto,
              onRemove: (int at) => setState(() => _photos.removeAt(at)),
            ),
            const SizedBox(height: 14.0),
            SizedBox(
              height: 48.0,
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _empty || _busy ? null : _send,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorApp.myColorGreenAuth,
                  foregroundColor: ColorApp.myColorWhite,
                  elevation: 0.0,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(MechanicLayout.cardRadius),
                  ),
                ),
                child: const Text(
                  'Записать дефект',
                  style: TextStyle(fontSize: 15.0),
                ),
              ),
            ),
            SizedBox(
              height: 48.0,
              width: double.infinity,
              child: TextButton(
                onPressed: _busy ? null : () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  foregroundColor: ColorApp.myColorGray,
                ),
                child: const Text(
                  'Не сейчас',
                  style: TextStyle(fontSize: 15.0),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _fieldStyle({required String label, required String hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(fontSize: 14.0, color: ColorApp.myColorGray),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(MechanicLayout.cardRadius),
      ),
    );
  }

  void _send() {
    final String description = _description.text.trim();
    Navigator.of(context).pop(
      DefectDraft(
        title: _title.text.trim(),
        description: description.isEmpty ? null : description,
        photos: List<PickedImage>.unmodifiable(_photos),
      ),
    );
  }

  Future<void> _addPhoto() async {
    if (_photos.length >= defectPhotoLimit) {
      _say('Больше $defectPhotoLimit снимков к одному дефекту не прикладываем.');
      return;
    }

    final bool? fromCamera = await showModalBottomSheet<bool>(
      context: context,
      builder: (BuildContext context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Снять сейчас'),
              onTap: () => Navigator.of(context).pop(true),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Выбрать из галереи'),
              onTap: () => Navigator.of(context).pop(false),
            ),
          ],
        ),
      ),
    );
    if (fromCamera == null) return;

    setState(() => _busy = true);
    try {
      final PickedImage? shot = await widget.pickPhoto(fromCamera: fromCamera);
      if (shot?.data == null || !mounted) return;
      setState(() => _photos.add(shot!));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _say(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }
}

/// Снимки дефекта: строка превью и кнопка «Добавить снимок».
///
/// Снимок можно убрать до отправки — в отличие от фото пункта чек-листа,
/// которое уходит в очередь сразу. Здесь очередь получит всё разом, вместе с
/// самим дефектом, и до нажатия кнопки человек ещё хозяин своему выбору.
class _Photos extends StatelessWidget {
  const _Photos({
    required this.photos,
    required this.busy,
    required this.onAdd,
    required this.onRemove,
  });

  final List<PickedImage> photos;
  final bool busy;
  final VoidCallback onAdd;
  final void Function(int at) onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (photos.isNotEmpty)
          SizedBox(
            height: 72.0,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: photos.length,
              separatorBuilder: (BuildContext context, int at) =>
                  const SizedBox(width: 8.0),
              itemBuilder: (BuildContext context, int at) => _Preview(
                photo: photos[at],
                onRemove: () => onRemove(at),
              ),
            ),
          ),
        if (photos.isNotEmpty) const SizedBox(height: 8.0),
        TextButton.icon(
          onPressed: busy ? null : onAdd,
          icon: const Icon(Icons.add_a_photo_outlined, size: 18.0),
          label: Text(
            photos.isEmpty ? 'Добавить снимок' : 'Ещё снимок',
            style: const TextStyle(fontSize: 14.0),
          ),
          style: TextButton.styleFrom(
            foregroundColor: ColorApp.myColorGreenAuth,
            padding: EdgeInsets.zero,
          ),
        ),
      ],
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({required this.photo, required this.onRemove});

  final PickedImage photo;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child: Image.memory(
            photo.data!,
            width: 72.0,
            height: 72.0,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 2.0,
          right: 2.0,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              decoration: BoxDecoration(
                color: ColorApp.myColorBlack.withOpacity(0.55),
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(2.0),
              child: const Icon(
                Icons.close,
                size: 14.0,
                color: ColorApp.myColorWhite,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
