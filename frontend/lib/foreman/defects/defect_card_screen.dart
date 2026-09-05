/// Карточка дефектного акта: текст, реквизиты и фотогалерея.
///
/// Открывается из списка (`defects_screen.dart`). Строка списка уже несёт всё,
/// кроме описания и снимков, поэтому экран рисуется сразу по ней, а полный
/// акт дозапрашивается следом: прораб видит заголовок и состояние мгновенно,
/// а не смотрит на крутилку ради текста, который уже приехал.
library;

import 'package:flutter/material.dart';

import '../../helper/api_image.dart';
import '../../helper/class_colors.dart';
import 'defect_entry.dart';
import 'defects_layout.dart';
import 'defects_repository.dart';

class DefectCardScreen extends StatefulWidget {
  const DefectCardScreen({
    Key? key,
    required this.entry,
    this.repository,
    this.loadFull = true,
  }) : super(key: key);

  /// То, что известно из списка. Показывается сразу.
  final DefectEntry entry;

  final DefectsRepository? repository;

  /// Набросок и тесты работают на готовой записи и в сеть не ходят.
  final bool loadFull;

  @override
  State<DefectCardScreen> createState() => _DefectCardScreenState();
}

class _DefectCardScreenState extends State<DefectCardScreen> {
  late DefectEntry _entry;
  late DefectsRepository _repository;

  @override
  void initState() {
    super.initState();
    _entry = widget.entry;
    _repository = widget.repository ?? const DefectsRepository();
    if (widget.loadFull) _load();
  }

  /// Дозагрузка молчаливая: если полный акт не приехал, на экране остаётся то,
  /// что пришло со списком. Ругаться на прораба нечем — показывать есть что.
  Future<void> _load() async {
    try {
      final DefectEntry full = await _repository.byId(widget.entry.id);
      if (!mounted) return;
      setState(() => _entry = full);
    } catch (_) {
      // Молча: см. выше.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorApp.myColorTransparent,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _Header(
              title: _entry.title,
              state: _entry.state,
              onBack: () => Navigator.of(context).maybePop(),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 32.0),
                children: <Widget>[
                  _Block(
                    title: 'Что нашли',
                    child: Text(
                      _entry.description ?? 'Описание не заполнено.',
                      style: TextStyle(
                        fontSize: 14.0,
                        height: 1.45,
                        color: _entry.description == null
                            ? ColorApp.myColorGrayText
                            : ColorApp.myColorBlack,
                      ),
                    ),
                  ),
                  _Block(
                    title: 'Реквизиты',
                    child: Column(
                      children: <Widget>[
                        _Row(label: 'Откуда заведён', value: _entry.source.label),
                        _Row(
                          label: 'Дата',
                          value: _entry.createdAt == null
                              ? null
                              : _formatDate(_entry.createdAt!),
                        ),
                        _Row(label: 'Объект', value: _entry.objectName),
                        _Row(label: 'Вид ТО', value: _entry.typeActName),
                        _Row(label: 'Месяц ТО', value: _entry.monthName),
                        _Row(label: 'Год плана', value: _entry.year),
                        _Row(label: 'Кто нашёл', value: _entry.authorName),
                        _Row(
                          label: 'Состояние',
                          value: _entry.state.label,
                          last: true,
                        ),
                      ],
                    ),
                  ),
                  _Block(
                    title: 'Фотографии',
                    child: _entry.photos.isEmpty
                        ? const Text(
                            'Механик не приложил снимков.',
                            style: TextStyle(
                              fontSize: 14.0,
                              color: ColorApp.myColorGrayText,
                            ),
                          )
                        : _Gallery(photos: _entry.photos),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.state,
    required this.onBack,
  });

  final String title;
  final DefectState state;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: ColorApp.myColorWhite,
      padding: const EdgeInsets.fromLTRB(
        DefectsLayout.screenPadding,
        14.0,
        DefectsLayout.screenPadding,
        14.0,
      ),
      child: Row(
        children: <Widget>[
          InkWell(
            onTap: onBack,
            borderRadius: BorderRadius.circular(DefectsLayout.cardRadius),
            child: Container(
              width: 32.0,
              height: 32.0,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(DefectsLayout.cardRadius),
                border:
                    Border.all(color: ColorApp.myColorGrayBorder, width: 1.0),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 13.0,
                color: ColorApp.myColorBlack,
              ),
            ),
          ),
          const SizedBox(width: 16.0),
          Expanded(
            child: Text(
              title,
              style: DefectsLayout.screenTitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12.0),
          DefectStatePill(state: state),
        ],
      ),
    );
  }
}

/// Белый блок с заголовком — карточка складывается из трёх таких.
class _Block extends StatelessWidget {
  const _Block({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        DefectsLayout.screenPadding,
        DefectsLayout.cardGap,
        DefectsLayout.screenPadding,
        0.0,
      ),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: ColorApp.myColorWhite,
          borderRadius: BorderRadius.circular(DefectsLayout.cardRadius),
        ),
        padding: const EdgeInsets.fromLTRB(16.0, 14.0, 16.0, 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(title, style: DefectsLayout.rowLabel),
            const SizedBox(height: 10.0),
            child,
          ],
        ),
      ),
    );
  }
}

/// Строка реквизита. Незаполненное показывается прочерком, а не пропускается:
/// пустое место читается как «поле потерялось».
class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value, this.last = false});

  final String label;
  final String? value;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              flex: 4,
              child: Text(label, style: DefectsLayout.rowLabel),
            ),
            Expanded(
              flex: 6,
              child: Text(
                value ?? '—',
                style: value == null
                    ? DefectsLayout.rowValue.copyWith(
                        color: ColorApp.myColorGrayText,
                        fontWeight: FontWeight.w300,
                      )
                    : DefectsLayout.rowValue,
              ),
            ),
          ],
        ),
        if (!last)
          const Divider(height: 21.0, color: DefectsLayout.divider),
      ],
    );
  }
}

/// Галерея: плитка на всю ширину, снимок открывается поверх экрана.
///
/// Картинки грузятся через `helper/api_image.dart` — статика требует токена,
/// и без заголовка вместо каждой фотографии приходит `401`.
class _Gallery extends StatelessWidget {
  const _Gallery({required this.photos});

  final List<DefectPhoto> photos;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10.0,
      runSpacing: 10.0,
      children: photos
          .map(
            (DefectPhoto photo) => InkWell(
              onTap: () => showDialog<void>(
                context: context,
                builder: (_) => _FullPhoto(photo: photo),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(DefectsLayout.cardRadius),
                child: SizedBox(
                  width: 104.0,
                  height: 104.0,
                  child: apiImageWidget(photo.url, fit: BoxFit.cover),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _FullPhoto extends StatelessWidget {
  const _FullPhoto({required this.photo});

  final DefectPhoto photo;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(24.0),
      child: Stack(
        children: <Widget>[
          InteractiveViewer(
            child: apiImageWidget(photo.url, fit: BoxFit.contain),
          ),
          Positioned(
            top: 0.0,
            right: 0.0,
            child: Material(
              color: ColorApp.myColorWhite,
              borderRadius: BorderRadius.circular(DefectsLayout.cardRadius),
              child: InkWell(
                onTap: () => Navigator.of(context).maybePop(),
                child: const Padding(
                  padding: EdgeInsets.all(6.0),
                  child: Icon(Icons.close, size: 20.0),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatDate(DateTime date) {
  final String day = date.day.toString().padLeft(2, '0');
  final String month = date.month.toString().padLeft(2, '0');
  return '$day.$month.${date.year}';
}
