/// Вкладка «Уведомления» — кадр `1826:270`.
///
/// Кадр взят целиком: заголовок 34, серые подписи дней, карточка 337×36 со
/// скруглением 8, слева квадрат 36×36 со значком, справа время мелким, две
/// строки текста — заголовок 14 и подпись 12 серым. Жёлтый квадрат из макета
/// достался событию «новая задача»; остальным видам событий цвет назначен по
/// смыслу, потому что в кадре нарисовано одно-единственное уведомление.
///
/// Список считает телефон, а не сервер: таблицы уведомлений на бэкенде нет —
/// см. `mechanic/data/notifications.dart`. Push тоже пока нет, это отдельный
/// этап; здесь только то, что человек увидит, открыв приложение.
///
/// Счётчик гаснет при открытии вкладки: человек её открыл, значит увидел.
library;

import 'package:flutter/material.dart';

import '../../helper/calendar/month_picker.dart';
import '../../helper/class_colors.dart';
import '../data/mechanic_workspace.dart';
import '../data/notifications.dart';
import '../mechanic_theme.dart';

class MechanicNotificationsScreen extends StatefulWidget {
  const MechanicNotificationsScreen({Key? key}) : super(key: key);

  @override
  State<MechanicNotificationsScreen> createState() =>
      _MechanicNotificationsScreenState();
}

class _MechanicNotificationsScreenState
    extends State<MechanicNotificationsScreen> {
  List<MechanicEvent> _events = <MechanicEvent>[];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _reload();
    MechanicWorkspace.current?.status.addListener(_reload);
  }

  @override
  void dispose() {
    MechanicWorkspace.current?.status.removeListener(_reload);
    super.dispose();
  }

  Future<void> _reload() async {
    final MechanicWorkspace? workspace = MechanicWorkspace.current;
    final List<MechanicEvent> events =
        await workspace?.journal.all() ?? <MechanicEvent>[];
    if (!mounted) return;
    setState(() {
      _events = events;
      _loaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();
    final List<Widget> body = <Widget>[
      const Padding(
        padding: EdgeInsets.fromLTRB(
          MechanicLayout.screenPadding,
          24.0,
          MechanicLayout.screenPadding,
          8.0,
        ),
        child: Text('Уведомления', style: MechanicLayout.screenTitle),
      ),
    ];

    String? day;
    for (final MechanicEvent event in _events) {
      final String eventDay = _dayLabel(event.at);
      if (eventDay != day) {
        day = eventDay;
        body.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(
              MechanicLayout.screenPadding,
              16.0,
              MechanicLayout.screenPadding,
              8.0,
            ),
            child: Text(eventDay, style: MechanicLayout.groupLabel),
          ),
        );
      }
      body.add(_EventRow(event: event, now: now));
    }

    if (_loaded && _events.isEmpty) body.add(const _Quiet());

    return RefreshIndicator(
      onRefresh: () async {
        await MechanicWorkspace.current?.refresh();
        await _reload();
      },
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24.0),
        physics: const AlwaysScrollableScrollPhysics(),
        children: body,
      ),
    );
  }

  /// «23 мая» — как в макете.
  String _dayLabel(int atMs) {
    final DateTime at = DateTime.fromMillisecondsSinceEpoch(atMs);
    return '${at.day} ${kMonthsGenitive[at.month - 1]}';
  }
}

class _EventRow extends StatelessWidget {
  const _EventRow({required this.event, required this.now});

  final MechanicEvent event;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20.0, 0.0, 18.0, 14.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 36.0,
            height: 36.0,
            decoration: BoxDecoration(
              color: _color(event.kind),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Icon(_icon(event.kind), size: 18.0, color: ColorApp.myColorWhite),
          ),
          const SizedBox(width: 12.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  event.title,
                  style: TextStyle(
                    fontSize: 14.0,
                    fontWeight: event.read ? FontWeight.w400 : FontWeight.w500,
                    color: ColorApp.myColorBlack,
                  ),
                ),
                const SizedBox(height: 2.0),
                Text(
                  event.subtitle,
                  style: const TextStyle(fontSize: 12.0, color: Color(0xff6C6C70)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8.0),
          Text(
            _ago(event.at, now),
            style: const TextStyle(fontSize: 10.0, color: Color(0xff6C6C70)),
          ),
        ],
      ),
    );
  }

  static Color _color(MechanicEventKind kind) {
    switch (kind) {
      case MechanicEventKind.assigned:
        return ColorApp.myColorYellow;
      case MechanicEventKind.statusChanged:
        return ColorApp.myColorBlue;
      case MechanicEventKind.removed:
        return ColorApp.myColorGrayText;
      case MechanicEventKind.rejected:
        return ColorApp.myColorRed;
    }
  }

  static IconData _icon(MechanicEventKind kind) {
    switch (kind) {
      case MechanicEventKind.assigned:
        return Icons.assignment_outlined;
      case MechanicEventKind.statusChanged:
        return Icons.sync_alt;
      case MechanicEventKind.removed:
        return Icons.remove_circle_outline;
      case MechanicEventKind.rejected:
        return Icons.error_outline;
    }
  }

  /// «1 мин назад», «1 час назад», «15:39» — три вида из макета.
  static String _ago(int atMs, DateTime now) {
    final DateTime at = DateTime.fromMillisecondsSinceEpoch(atMs);
    final Duration passed = now.difference(at);

    if (passed.inMinutes < 1) return 'только что';
    if (passed.inMinutes < 60) return '${passed.inMinutes} мин назад';
    if (passed.inHours < 6) return '${passed.inHours} ч назад';
    return '${at.hour.toString().padLeft(2, '0')}:'
        '${at.minute.toString().padLeft(2, '0')}';
  }
}

class _Quiet extends StatelessWidget {
  const _Quiet();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(32.0, 64.0, 32.0, 32.0),
      child: Column(
        children: <Widget>[
          Icon(
            Icons.notifications_none,
            size: 48.0,
            color: ColorApp.myColorGrayText,
          ),
          SizedBox(height: 16.0),
          Text(
            'Пока тихо. Здесь появятся новые задачи, чужие отметки по вашим '
            'заявкам и отказы сервера.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14.0, color: ColorApp.myColorGray),
          ),
        ],
      ),
    );
  }
}
