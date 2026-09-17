/// Экран «Очередь отправки» — что механик сделал без связи и что ещё не ушло.
///
/// Кадра в макете нет: там нет и офлайна. Набросок утверждён в E10·S05:
/// заголовок как у вкладок, серая подпись «N ждут · связи нет с …», одна
/// главная кнопка «Отправить всё», ниже две группы — «Ждут отправки» и
/// «Отклонено сервером». У ждущих кнопок нет: очередь уходит по порядку, и
/// «повторить одно» означало бы обогнать стоящее впереди — а порядок там
/// не случайный (см. `outbox.dart`). У отклонённых по две тихие кнопки:
/// «Повторить», когда причину устранили, и «Убрать», когда нет.
///
/// Снимок в карточке показывается превью: без него «Фото к заявке №14» и
/// «Фото к заявке №14» — две одинаковые строки, и какая из них не ушла,
/// человек не поймёт. Байты читаются с диска один раз на действие и
/// держатся в состоянии экрана, а не в `FutureBuilder` на карточку: список
/// перестраивается на каждое изменение очереди, и читать диск заново
/// на каждый кадр незачем.
///
/// Экран открывается из полосы состояния и из личного кабинета; оба входа
/// ведут сюда же, потому что полоса скрыта, когда всё отправлено, а
/// отклонённое человеку может понадобиться и потом.
library;

import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../helper/class_colors.dart';
import '../data/mechanic_workspace.dart';
import '../data/outbox.dart';
import '../mechanic_theme.dart';
import 'quiet_button.dart';

class MechanicOutboxScreen extends StatefulWidget {
  const MechanicOutboxScreen({Key? key, this.workspace}) : super(key: key);

  /// Рабочее место; `null` — текущее. Параметр нужен тестам.
  final MechanicWorkspace? workspace;

  @override
  State<MechanicOutboxScreen> createState() => _MechanicOutboxScreenState();
}

class _MechanicOutboxScreenState extends State<MechanicOutboxScreen> {
  List<OutboxAction> _pending = <OutboxAction>[];
  List<OutboxAction> _rejected = <OutboxAction>[];

  /// Превью по `id` действия. `null` в значении — файла нет или он
  /// потерян; отсутствие ключа — ещё не читали.
  final Map<String, Uint8List?> _previews = <String, Uint8List?>{};
  bool _loaded = false;
  bool _sending = false;

  MechanicWorkspace? get _workspace =>
      widget.workspace ?? MechanicWorkspace.current;

  @override
  void initState() {
    super.initState();
    _reload();
    _workspace?.status.addListener(_reload);
  }

  @override
  void dispose() {
    _workspace?.status.removeListener(_reload);
    super.dispose();
  }

  Future<void> _reload() async {
    final Outbox? outbox = _workspace?.outbox;
    if (outbox == null) {
      if (mounted) setState(() => _loaded = true);
      return;
    }
    final List<OutboxAction> pending = await outbox.pending();
    final List<OutboxAction> rejected = await outbox.rejected();
    for (final OutboxAction action in <OutboxAction>[...pending, ...rejected]) {
      if (action.fileKey == null || _previews.containsKey(action.id)) continue;
      _previews[action.id] = await outbox.attachment(action);
    }
    if (!mounted) return;
    setState(() {
      _pending = pending;
      _rejected = rejected;
      _loaded = true;
    });
  }

  Future<void> _sendAll() async {
    final MechanicWorkspace? workspace = _workspace;
    if (workspace == null || _sending) return;
    setState(() => _sending = true);
    try {
      await workspace.refresh();
    } finally {
      if (mounted) setState(() => _sending = false);
    }
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final WorkspaceStatus status =
        _workspace?.status.value ?? const WorkspaceStatus();

    return Scaffold(
      backgroundColor: ColorApp.myColorWhite,
      appBar: AppBar(
        backgroundColor: ColorApp.myColorWhite,
        foregroundColor: ColorApp.myColorBlack,
        elevation: 0.0,
        title: const Text('Очередь отправки', style: MechanicLayout.sectionTitle),
      ),
      body: !_loaded
          ? const SizedBox.shrink()
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                MechanicLayout.screenPadding,
                8.0,
                MechanicLayout.screenPadding,
                32.0,
              ),
              children: <Widget>[
                Text(
                  _summary(status),
                  style: const TextStyle(
                    fontSize: 12.0,
                    color: ColorApp.myColorGrayText,
                  ),
                ),
                const SizedBox(height: 12.0),
                if (_pending.isNotEmpty) ...<Widget>[
                  SizedBox(
                    height: 48.0,
                    child: ElevatedButton(
                      onPressed: _sending ? null : _sendAll,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorApp.myColorGreenAuth,
                        foregroundColor: ColorApp.myColorWhite,
                        elevation: 0.0,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(MechanicLayout.cardRadius),
                        ),
                      ),
                      child: Text(
                        _sending ? 'Отправляем…' : 'Отправить всё',
                        style: const TextStyle(fontSize: 15.0),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  const Text('Ждут отправки', style: MechanicLayout.groupLabel),
                  const SizedBox(height: 8.0),
                  for (final OutboxAction action in _pending)
                    _ActionCard(
                      action: action,
                      preview: _previews[action.id],
                      status: _pendingStatus(action),
                    ),
                ],
                if (_rejected.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 8.0),
                  const Text('Отклонено сервером', style: MechanicLayout.groupLabel),
                  const SizedBox(height: 8.0),
                  for (final OutboxAction action in _rejected)
                    _ActionCard(
                      action: action,
                      preview: _previews[action.id],
                      status: action.lastError ?? 'сервер отказал',
                      rejected: true,
                      onRetry: () => _workspace?.outbox.retryRejected(action.id),
                      onDismiss: () =>
                          _workspace?.outbox.dismissRejected(action.id),
                    ),
                ],
                if (_pending.isEmpty && _rejected.isEmpty) const _AllSent(),
              ],
            ),
    );
  }

  /// «3 ждут отправки · связи нет с 14:02» / «Всё отправлено · связь была
  /// в 14:31».
  String _summary(WorkspaceStatus status) {
    final String head = _pending.isEmpty
        ? 'Всё отправлено'
        : '${_pending.length} ${_plural(_pending.length, 'ждёт', 'ждут', 'ждут')} отправки';
    final DateTime? synced = status.lastSyncAt;
    if (synced == null) return head;
    final String at = _clock(synced);
    return status.lastError != null
        ? '$head · связи нет с $at'
        : '$head · связь была в $at';
  }

  static String _pendingStatus(OutboxAction action) {
    final String at = _clock(DateTime.fromMillisecondsSinceEpoch(action.createdAt));
    if (action.attempts == 0) return '$at · ждёт';
    final String tries =
        '${action.attempts} ${_plural(action.attempts, 'попытка', 'попытки', 'попыток')}';
    final String? why = action.lastError;
    return why == null ? '$at · $tries' : '$at · $tries · $why';
  }

  static String _clock(DateTime at) =>
      '${at.hour.toString().padLeft(2, '0')}:${at.minute.toString().padLeft(2, '0')}';

  static String _plural(int n, String one, String few, String many) {
    final int tail = n % 10;
    final int hundred = n % 100;
    if (hundred >= 11 && hundred <= 14) return many;
    if (tail == 1) return one;
    if (tail >= 2 && tail <= 4) return few;
    return many;
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.action,
    required this.preview,
    required this.status,
    this.rejected = false,
    this.onRetry,
    this.onDismiss,
  });

  final OutboxAction action;
  final Uint8List? preview;
  final String status;
  final bool rejected;
  final VoidCallback? onRetry;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8.0),
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: ColorApp.myColorWhite,
        borderRadius: BorderRadius.circular(MechanicLayout.cardRadius),
        border: Border.all(color: MechanicLayout.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _Thumb(action: action, preview: preview),
          const SizedBox(width: 10.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  action.title,
                  style: const TextStyle(
                    fontSize: 14.0,
                    color: ColorApp.myColorBlack,
                  ),
                ),
                const SizedBox(height: 2.0),
                Text(
                  status,
                  style: TextStyle(
                    fontSize: 12.0,
                    color: rejected
                        ? ColorApp.myColorRed
                        : ColorApp.myColorGrayText,
                  ),
                ),
                if (rejected)
                  Row(
                    children: <Widget>[
                      MechanicQuietButton(
                        icon: Icons.refresh,
                        label: 'Повторить',
                        ink: ColorApp.myColorGreenAuth,
                        onTap: onRetry,
                      ),
                      const SizedBox(width: 8.0),
                      MechanicQuietButton(
                        icon: Icons.close,
                        label: 'Убрать',
                        ink: ColorApp.myColorGrayText,
                        onTap: onDismiss,
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Превью снимка или значок по виду действия.
class _Thumb extends StatelessWidget {
  const _Thumb({required this.action, required this.preview});

  final OutboxAction action;
  final Uint8List? preview;

  static const double _size = 48.0;

  @override
  Widget build(BuildContext context) {
    final Uint8List? bytes = preview;
    if (bytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(MechanicLayout.cardRadius),
        child: Image.memory(
          bytes,
          width: _size,
          height: _size,
          fit: BoxFit.cover,
          // Список на экране один, снимков в нём единицы; полноразмерный
          // декод 1600 точек ради квадрата 48 — лишняя память.
          cacheWidth: (_size * MediaQuery.of(context).devicePixelRatio).round(),
        ),
      );
    }

    final bool photo = action.fileKey != null;
    final bool defect = action.path.startsWith('/defective-act');
    return Container(
      width: _size,
      height: _size,
      decoration: BoxDecoration(
        color: photo
            ? ColorApp.myColorGrayText
            : defect
                ? ColorApp.myColorYellowLight
                : ColorApp.myColorGreenLine,
        borderRadius: BorderRadius.circular(MechanicLayout.cardRadius),
      ),
      child: Icon(
        photo
            ? Icons.photo_outlined
            : defect
                ? mechanicDefectIcon
                : Icons.upload_outlined,
        size: 22.0,
        color: photo ? ColorApp.myColorWhite : ColorApp.myColorBlack,
      ),
    );
  }
}

class _AllSent extends StatelessWidget {
  const _AllSent();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 48.0),
      child: Column(
        children: <Widget>[
          Icon(Icons.cloud_done_outlined, size: 48.0, color: ColorApp.myColorGrayText),
          SizedBox(height: 8.0),
          Text(
            'Всё ушло на сервер',
            style: TextStyle(fontSize: 14.0, color: ColorApp.myColorGrayText),
          ),
        ],
      ),
    );
  }
}
