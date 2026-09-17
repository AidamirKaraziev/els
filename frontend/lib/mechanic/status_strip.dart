/// Полоса состояния над вкладками механика и плашка «вышла новая версия».
///
/// Механик работает там, где связи нет, и главный его вопрос — «ушло или
/// не ушло». Полоса отвечает на него одной строкой и не показывается, когда
/// отвечать нечего: сеть есть, очередь пуста, сервер не ругался.
///
/// Состояния читаются по цвету раньше, чем по тексту: жёлтая — сети нет или
/// сервер не отвечает, ждём; зелёная — сеть есть, очередь уходит; красный
/// акцент — сервер отказал по существу, это надо открыть и посмотреть.
///
/// Плашка обновления — отдельный виджет над полосой, а не ещё одно её
/// состояние: обновиться можно и без сети (файл уже скачан), и «офлайн» с
/// «вышла версия» не должны вытеснять друг друга.
library;

import 'package:flutter/material.dart';

import '../app_download/app_release.dart';
import '../helper/class_colors.dart';
import 'data/mechanic_workspace.dart';

/// Строка полосы для [status]; null — показывать нечего.
///
/// Вынесено из виджета, чтобы тексты проверялись тестом без дерева виджетов.
String? statusStripText(WorkspaceStatus status) {
  final List<String> parts = <String>[];
  if (status.offline) {
    parts.add('Офлайн');
    parts.add(
      status.pending > 0 ? 'ждут отправки: ${status.pending}' : 'всё отправлено',
    );
  } else {
    if (status.lastError != null) parts.add(status.lastError!);
    if (status.pending > 0) parts.add('Отправляем: ${status.pending}');
  }
  if (status.rejected > 0) parts.add('Отклонено сервером: ${status.rejected}');
  return parts.isEmpty ? null : parts.join(' · ');
}

class MechanicStatusStrip extends StatelessWidget {
  const MechanicStatusStrip({
    Key? key,
    required this.status,
    required this.onOpenQueue,
  }) : super(key: key);

  final WorkspaceStatus status;

  /// Открыть экран очереди — там видно, что именно не ушло.
  final VoidCallback onOpenQueue;

  @override
  Widget build(BuildContext context) {
    final String? text = statusStripText(status);
    if (text == null) return const SizedBox.shrink();

    final bool waiting = status.offline || status.lastError != null;
    final bool hasQueue = status.pending > 0 || status.rejected > 0;
    final IconData icon = status.rejected > 0
        ? Icons.error_outline
        : waiting
            ? Icons.cloud_off
            : Icons.cloud_upload_outlined;
    final Color iconColor =
        status.rejected > 0 ? ColorApp.myColorRed : ColorApp.myColorBlack;

    return Material(
      color: waiting ? ColorApp.myColorYellow : ColorApp.myColorGreenLine,
      child: InkWell(
        // Без очереди открывать нечего: «Офлайн · всё отправлено» — просто
        // сообщение, нажатие на него ничего не даст.
        onTap: hasQueue ? onOpenQueue : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: <Widget>[
              Icon(icon, size: 16.0, color: iconColor),
              const SizedBox(width: 8.0),
              Expanded(
                child: Text(text, style: const TextStyle(fontSize: 12.0)),
              ),
              if (hasQueue)
                const Text(
                  'Открыть',
                  style: TextStyle(fontSize: 12.0, fontWeight: FontWeight.w500),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// «Вышла версия N» — над полосой состояния, до следующего запуска или
/// пока человек не закроет её крестиком.
class MechanicUpdateBanner extends StatelessWidget {
  const MechanicUpdateBanner({
    Key? key,
    required this.release,
    required this.onOpen,
    required this.onDismiss,
  }) : super(key: key);

  final AppRelease release;

  /// Открыть экран «Приложение» — там кнопка «Скачать» и «что нового».
  final VoidCallback onOpen;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ColorApp.myColorGreen,
      child: Padding(
        padding: const EdgeInsets.only(left: 16.0, right: 4.0),
        child: Row(
          children: <Widget>[
            const Icon(Icons.system_update, size: 16.0),
            const SizedBox(width: 8.0),
            Expanded(
              child: Text(
                'Вышла версия ${release.versionName}',
                style: const TextStyle(fontSize: 12.0),
              ),
            ),
            TextButton(
              onPressed: onOpen,
              style: TextButton.styleFrom(
                foregroundColor: ColorApp.myColorBlack,
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                minimumSize: const Size(0.0, 32.0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Обновить',
                style: TextStyle(fontSize: 12.0, fontWeight: FontWeight.w500),
              ),
            ),
            IconButton(
              onPressed: onDismiss,
              tooltip: 'Скрыть',
              iconSize: 16.0,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 32.0, height: 32.0),
              icon: const Icon(Icons.close),
            ),
          ],
        ),
      ),
    );
  }
}
