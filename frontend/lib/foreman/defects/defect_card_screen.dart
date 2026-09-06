/// Карточка дефектного акта: текст, реквизиты и фотогалерея.
///
/// Открывается из списка (`defects_screen.dart`). Строка списка уже несёт всё,
/// кроме описания и снимков, поэтому экран рисуется сразу по ней, а полный
/// акт дозапрашивается следом: прораб видит заголовок и состояние мгновенно,
/// а не смотрит на крутилку ради текста, который уже приехал.
library;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../helper/api_image.dart';
import '../../helper/class_colors.dart';
import 'defect_entry.dart';
import 'defects_layout.dart';
import 'defects_repository.dart';
import 'issue_to_client_screen.dart';

class DefectCardScreen extends StatefulWidget {
  const DefectCardScreen({
    Key? key,
    required this.entry,
    this.objectName,
    this.repository,
    this.loadFull = true,
    this.openLink,
  }) : super(key: key);

  /// То, что известно из списка. Показывается сразу.
  final DefectEntry entry;

  /// Имя объекта, на котором открыт список.
  ///
  /// В самом акте его нет: сервер отдаёт `object_id` числом, а имя
  /// разворачивается только через плановое ТО — то есть у одной точки входа
  /// из четырёх. Карточка всегда открывается из ленты объекта, и лента имя
  /// знает, поэтому берём оттуда, а не расширяем ради этого контракт.
  final String? objectName;

  final DefectsRepository? repository;

  /// Набросок и тесты работают на готовой записи и в сеть не ходят.
  final bool loadFull;

  /// Чем открыть готовую ссылку на PDF. По умолчанию — браузером; подменяется
  /// в тестах, где `url_launcher` уходит в платформенный канал.
  final Future<void> Function(String url)? openLink;

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

  /// Оформление клиенту: выпуск, следом сборка файла, потом перечитывание.
  ///
  /// Возврат назад делаем здесь, а не в экране оформления: пока запрос не
  /// прошёл, черновик прораба — единственное место, где живут его правки, и
  /// закрывать экран до ответа нельзя. Ошибку показываем и остаёмся там же.
  Future<void> _issue(IssueDraft draft) async {
    final DefectEntry child =
        await _repository.issueToClient(_entry.id, draft.toBody());
    // Файл собирается отдельным запросом. Если он не собрался, выпуск всё
    // равно состоялся: акт клиенту оформлен, кнопка PDF в строке просто
    // останется неактивной до следующего раза.
    try {
      await _repository.generatePdf(child.id);
    } catch (_) {
      // Молча: сам выпуск прошёл, и ронять его сообщением об ошибке незачем.
    }
    if (!mounted) return;
    Navigator.of(context).pop();
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Акт оформлен клиенту')),
    );
  }

  Future<void> _openPdf(String path) async {
    try {
      final String url = await _repository.downloadLink(path);
      final Future<void> Function(String url) open = widget.openLink ??
          (String value) =>
              launchUrl(Uri.parse(value), mode: LaunchMode.externalApplication);
      // Ссылка живёт минуту, поэтому открываем сразу, а не кладём в состояние.
      await open(url);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Не удалось открыть файл: $error')),
      );
    }
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
                        _Row(
                          label: 'Объект',
                          value: _entry.objectName ?? widget.objectName,
                        ),
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
                  if (_entry.clientActs.isNotEmpty)
                    _Block(
                      title: 'Оформлено клиенту',
                      child: Column(
                        children: <Widget>[
                          for (final DefectClientAct act in _entry.clientActs)
                            _ClientActRow(
                              act: act,
                              last: act == _entry.clientActs.last,
                              onOpen: () => _openPdf(act.pdfPath!),
                            ),
                        ],
                      ),
                    ),
                  // Кнопки нет только у самого клиентского акта: из
                  // порождённой записи дальше не оформляют. Повторный выпуск
                  // разрешён — на сервере это ещё одна запись.
                  if (!_entry.isClient)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        DefectsLayout.screenPadding,
                        DefectsLayout.cardGap,
                        DefectsLayout.screenPadding,
                        0.0,
                      ),
                      child: _IssueButton(
                        again: _entry.clientActs.isNotEmpty,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => IssueToClientScreen(
                              entry: _entry,
                              onIssue: _issue,
                            ),
                          ),
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


/// Строка блока «Оформлено клиенту»: когда ушло, под каким заголовком и файл.
///
/// Пока PDF не собран, кнопка неактивна и говорит об этом словом: молчащая
/// кнопка читалась бы как сломанная.
class _ClientActRow extends StatelessWidget {
  const _ClientActRow({
    required this.act,
    required this.onOpen,
    this.last = false,
  });

  final DefectClientAct act;
  final VoidCallback onOpen;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final bool ready = act.pdfPath != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    act.title ?? 'Без заголовка',
                    style: DefectsLayout.rowValue,
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    act.createdAt == null
                        ? 'Дата неизвестна'
                        : _formatDate(act.createdAt!),
                    style: DefectsLayout.rowLabel,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12.0),
            TextButton.icon(
              onPressed: ready ? onOpen : null,
              icon: const Icon(Icons.picture_as_pdf_outlined, size: 18.0),
              label: Text(ready ? 'Скачать PDF' : 'Файл не собран'),
              style: TextButton.styleFrom(
                foregroundColor: ColorApp.myColorGreenAuth,
              ),
            ),
          ],
        ),
        if (!last) const Divider(height: 21.0, color: DefectsLayout.divider),
      ],
    );
  }
}

/// Кнопка «Оформить клиенту» — вход на экран выпуска.
class _IssueButton extends StatelessWidget {
  const _IssueButton({required this.onTap, this.again = false});

  /// Клиенту уже оформляли: подпись меняется, чтобы прораб не решил, что
  /// первое нажатие не сработало.
  final bool again;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: ColorApp.myColorGreenAuth,
          foregroundColor: ColorApp.myColorWhite,
          padding: const EdgeInsets.symmetric(vertical: 14.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DefectsLayout.cardRadius),
          ),
        ),
        child: Text(
          again ? 'Оформить клиенту ещё раз' : 'Оформить клиенту',
          style: const TextStyle(fontSize: 15.0, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}
