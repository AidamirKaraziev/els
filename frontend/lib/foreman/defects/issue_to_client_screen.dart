/// Экран «Оформить клиенту»: прораб делает из дефекта механика документ
/// заказчику.
///
/// Кадра в макете нет — вёрстка утверждена по наброску и собрана из тех же
/// величин, что список и карточка дефекта (`defects_layout.dart`): поле 20,
/// белые блоки со скруглением 5, зелёная кнопка. Заводить здесь третий вид
/// одного и того же окна нельзя.
///
/// Экран **только собирает написанное**. Отправку он не делает и в сеть не
/// ходит: что делать с готовым черновиком, решает тот, кто экран открыл, —
/// так его видно в наброске (`lib/dev/issue_to_client_preview.dart`) и в
/// тесте, не поднимая сервера.
///
/// Три поля черновика — ровно те, что принимает
/// `POST /defective-act/{id}/issue-to-client/`
/// (`backend/src/schemas/defective_act.py`, `DefectiveActIssueToClient`):
/// оба текста необязательны, пустые сервер берёт из внутреннего акта, а
/// `photo_ids` — снимки того же акта, чужой снимок даёт 422. Поэтому
/// выбирать здесь можно только из `entry.photos` — списка взять больше
/// неоткуда.
library;

import 'package:flutter/material.dart';

import '../../helper/api_image.dart';
import '../../helper/class_colors.dart';
import 'defect_entry.dart';
import 'defects_layout.dart';

/// Что прораб оформил клиенту.
///
/// Пустые тексты отдаём как `null`, а не пустой строкой: сервер по `null`
/// подставляет текст механика, а пустая строка — это пустой заголовок в
/// документе заказчика.
class IssueDraft {
  const IssueDraft({
    this.clientTitle,
    this.clientDescription,
    this.photoIds = const <int>[],
  });

  final String? clientTitle;
  final String? clientDescription;

  /// Отобранные снимки — в том порядке, в каком они лежат в акте.
  final List<int> photoIds;

  /// Тело запроса `issue-to-client`. `photo_ids` уходит всегда, в том числе
  /// пустым списком: пустой — это «клиенту без фотографий», и умолчания на
  /// сервере для него нет.
  Map<String, dynamic> toBody() {
    return <String, dynamic>{
      if (clientTitle != null) 'client_title': clientTitle,
      if (clientDescription != null) 'client_description': clientDescription,
      'photo_ids': photoIds,
    };
  }
}

class IssueToClientScreen extends StatefulWidget {
  const IssueToClientScreen({
    Key? key,
    required this.entry,
    this.onIssue,
  }) : super(key: key);

  /// Внутренний акт, из которого оформляем. Из него берутся снимки и тексты
  /// по умолчанию.
  final DefectEntry entry;

  /// Что делать с черновиком. Пока не передан — кнопка просто возвращает
  /// черновик через `Navigator.pop`, и экран остаётся вёрсткой.
  final Future<void> Function(IssueDraft draft)? onIssue;

  @override
  State<IssueToClientScreen> createState() => _IssueToClientScreenState();
}

class _IssueToClientScreenState extends State<IssueToClientScreen> {
  final TextEditingController _title = TextEditingController();
  final TextEditingController _description = TextEditingController();

  /// Отмеченные снимки. По умолчанию отмечены все: прораб чаще убирает
  /// лишний кадр, чем набирает нужные с нуля.
  late final Set<int> _picked = widget.entry.photos
      .map((DefectPhoto photo) => photo.id)
      .toSet();

  bool _busy = false;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  /// Снимки в порядке акта, а не в порядке нажатий: в документе они пойдут
  /// так же, как в карточке, и переставлять их галочкой прораб не собирался.
  List<int> get _photoIds => widget.entry.photos
      .map((DefectPhoto photo) => photo.id)
      .where(_picked.contains)
      .toList();

  IssueDraft get _draft => IssueDraft(
        clientTitle: _trimmed(_title.text),
        clientDescription: _trimmed(_description.text),
        photoIds: _photoIds,
      );

  Future<void> _submit() async {
    if (_busy) return;
    final IssueDraft draft = _draft;

    final Future<void> Function(IssueDraft draft)? issue = widget.onIssue;
    if (issue == null) {
      Navigator.of(context).pop(draft);
      return;
    }

    setState(() => _busy = true);
    try {
      await issue(draft);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<DefectPhoto> photos = widget.entry.photos;

    return Scaffold(
      backgroundColor: ColorApp.myColorTransparent,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _Header(onBack: () => Navigator.of(context).maybePop()),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 32.0),
                children: <Widget>[
                  _Block(
                    title: 'Заголовок для клиента',
                    footer: 'Оставьте пустым — возьмём заголовок механика.',
                    child: _Field(
                      controller: _title,
                      hint: widget.entry.title,
                      hintIsDefault: true,
                    ),
                  ),
                  _Block(
                    title: 'Описание для клиента',
                    footer: widget.entry.description == null
                        ? 'У механика описания нет — клиенту уйдёт без него.'
                        : 'Пусто — подставим описание из внутреннего акта.',
                    child: _Field(
                      controller: _description,
                      hint: widget.entry.description ??
                          'Что сообщаем заказчику…',
                      hintIsDefault: widget.entry.description != null,
                      lines: 4,
                    ),
                  ),
                  _Block(
                    title: 'Какие снимки показать',
                    footer: photos.isEmpty
                        ? null
                        : 'Выбрано ${_picked.length} из ${photos.length}'
                            '${_picked.isEmpty ? ' · уйдёт без фото' : ''}',
                    child: photos.isEmpty
                        ? const Text(
                            'Механик не приложил снимков — документ будет без '
                            'фотографий.',
                            style: TextStyle(
                              fontSize: 14.0,
                              height: 1.45,
                              color: ColorApp.myColorGrayText,
                            ),
                          )
                        : _PhotoPicker(
                            photos: photos,
                            picked: _picked,
                            onToggle: (int id) => setState(() {
                              if (!_picked.remove(id)) _picked.add(id);
                            }),
                          ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      DefectsLayout.screenPadding,
                      DefectsLayout.cardGap,
                      DefectsLayout.screenPadding,
                      0.0,
                    ),
                    child: _SubmitButton(busy: _busy, onTap: _submit),
                  ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(
                      DefectsLayout.screenPadding,
                      10.0,
                      DefectsLayout.screenPadding,
                      0.0,
                    ),
                    child: Text(
                      'Акт перейдёт в состояние «Выдан клиенту». Оформить '
                      'документ заново можно и после этого.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11.0,
                        height: 1.4,
                        color: ColorApp.myColorGrayText,
                      ),
                    ),
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

/// Пустое поле — это `null`, а не пустая строка: см. `IssueDraft`.
String? _trimmed(String raw) {
  final String value = raw.trim();
  return value.isEmpty ? null : value;
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});

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
          const Expanded(
            child: Text('Оформить клиенту', style: DefectsLayout.screenTitle),
          ),
        ],
      ),
    );
  }
}

/// Белый блок с заголовком и подписью снизу — тот же, что в карточке, плюс
/// подпись: здесь ей место, объяснять поля больше негде.
class _Block extends StatelessWidget {
  const _Block({required this.title, required this.child, this.footer});

  final String title;
  final Widget child;
  final String? footer;

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
            if (footer != null) ...<Widget>[
              const SizedBox(height: 8.0),
              Text(footer!, style: DefectsLayout.fieldHint),
            ],
          ],
        ),
      ),
    );
  }
}

/// Поле ввода.
///
/// Подсказкой стоит текст механика, когда он есть: прораб видит, что уйдёт
/// клиенту, если он не напишет ничего своего.
class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.hint,
    required this.hintIsDefault,
    this.lines = 1,
  });

  final TextEditingController controller;
  final String hint;

  /// Подсказка — это текст механика, который и уйдёт клиенту, а не пример.
  final bool hintIsDefault;

  final int lines;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      minLines: lines,
      maxLines: lines,
      style: const TextStyle(fontSize: 14.0, height: 1.45),
      decoration: InputDecoration(
        isDense: true,
        hintText: hint,
        hintMaxLines: 3,
        hintStyle: TextStyle(
          fontSize: 14.0,
          height: 1.45,
          color: hintIsDefault
              ? ColorApp.myColorGrayText
              : DefectsLayout.hintFaint,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12.0,
          vertical: 10.0,
        ),
        border: DefectsLayout.fieldBorder,
        enabledBorder: DefectsLayout.fieldBorder,
        focusedBorder: DefectsLayout.fieldBorderFocused,
      ),
    );
  }
}

/// Сетка снимков с галочками.
///
/// Три в ряд — так плитка остаётся крупнее пальца на телефоне и при этом
/// пять снимков (потолок механика) укладываются в два ряда.
class _PhotoPicker extends StatelessWidget {
  const _PhotoPicker({
    required this.photos,
    required this.picked,
    required this.onToggle,
  });

  final List<DefectPhoto> photos;
  final Set<int> picked;
  final void Function(int id) onToggle;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        const double gap = 8.0;
        final double side = (constraints.maxWidth - gap * 2) / 3;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: photos.map((DefectPhoto photo) {
            final bool on = picked.contains(photo.id);
            return _PhotoCell(
              // Ключ — номер снимка: по нему плитку находит тест, а список
              // при перестройке не путает соседние.
              key: ValueKey<int>(photo.id),
              photo: photo,
              side: side,
              picked: on,
              onTap: () => onToggle(photo.id),
            );
          }).toList(),
        );
      },
    );
  }
}

class _PhotoCell extends StatelessWidget {
  const _PhotoCell({
    Key? key,
    required this.photo,
    required this.side,
    required this.picked,
    required this.onTap,
  }) : super(key: key);

  final DefectPhoto photo;
  final double side;
  final bool picked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: side,
        height: side,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(DefectsLayout.cardRadius),
              child: apiImageWidget(photo.url, fit: BoxFit.cover),
            ),
            // Рамка поверх снимка, а не вокруг: обводка вокруг сдвигала бы
            // плитку на два пикселя при каждом нажатии.
            IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius:
                      BorderRadius.circular(DefectsLayout.cardRadius),
                  border: Border.all(
                    color: picked
                        ? ColorApp.myColorGreenAuth
                        : ColorApp.myColorGrayBorder,
                    width: picked ? 2.0 : 1.0,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 5.0,
              right: 5.0,
              child: _Tick(picked: picked),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tick extends StatelessWidget {
  const _Tick({required this.picked});

  final bool picked;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20.0,
      height: 20.0,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: picked ? ColorApp.myColorGreenAuth : ColorApp.myColorWhite,
        border: Border.all(
          color: picked ? ColorApp.myColorGreenAuth : ColorApp.myColorGrayBorder,
        ),
      ),
      child: Icon(
        Icons.check,
        size: 13.0,
        color: picked ? ColorApp.myColorWhite : DefectsLayout.hintFaint,
      ),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  const _SubmitButton({required this.busy, required this.onTap});

  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: busy ? null : onTap,
      borderRadius: BorderRadius.circular(DefectsLayout.cardRadius),
      child: Container(
        height: 48.0,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: busy
              ? ColorApp.myColorGreenWhite
              : ColorApp.myColorGreenAuth,
          borderRadius: BorderRadius.circular(DefectsLayout.cardRadius),
        ),
        child: busy
            ? const SizedBox(
                width: 20.0,
                height: 20.0,
                child: CircularProgressIndicator(
                  strokeWidth: 2.0,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(ColorApp.myColorWhite),
                ),
              )
            : const Text(
                'Сформировать PDF',
                style: TextStyle(
                  fontSize: 15.0,
                  fontWeight: FontWeight.w600,
                  color: ColorApp.myColorWhite,
                ),
              ),
      ),
    );
  }
}
