/// Части, из которых собраны и строка раздела, и шапка карточки работы.
///
/// Лежат отдельным файлом не ради порядка: карточка обязана повторять строку,
/// на которую нажали, **буквально**. Скопируй эти четыре виджета в экран
/// карточки — и однажды они разойдутся: цвет пилюли поправят в одном месте,
/// а прораб увидит разное там и там. Поэтому источник один.
library;

import 'dart:async';

import 'package:flutter/material.dart';

import '../../../helper/class_colors.dart';
import '../models/in_progress_work.dart';
import '../state_colors.dart';

/// Объект и адрес. Адрес второй строкой: по «Лифт 12» непонятно, куда ехать.
class WorkObject extends StatelessWidget {
  const WorkObject({Key? key, required this.work, this.withTask = false})
      : super(key: key);

  final InProgressWork work;

  /// На широком экране задание живёт в колонке объекта, на телефоне — своей
  /// строкой ниже.
  final bool withTask;

  @override
  Widget build(BuildContext context) {
    final String? address = work.addressLabel;
    final String? task = withTask ? work.taskLabel : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          work.objectLabel,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        if (address != null)
          Text(
            address,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11.0, color: ColorApp.myColorGray),
          ),
        if (task != null) ...<Widget>[
          const SizedBox(height: 4.0),
          Text(
            task,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12.0),
          ),
        ],
      ],
    );
  }
}

/// Бейдж вида работы: сплошная заливка, цвет тот же, что в сданных работах.
/// Держит ширину и не режется.
class WorkBadge extends StatelessWidget {
  const WorkBadge({Key? key, required this.work}) : super(key: key);

  final InProgressWork work;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
      decoration: BoxDecoration(
        color: work.kindColor,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Text(
        work.kindLabel,
        style: const TextStyle(
          fontSize: 12.0,
          fontWeight: FontWeight.w700,
          color: ColorApp.myColorWhite,
        ),
      ),
    );
  }
}

/// Слова механика с левой чертой: это цитата, а не подпись системы.
///
/// В строке списка обрывается двумя строками, в карточке показывается
/// целиком — карточку и открывают затем, чтобы дочитать.
class WorkReason extends StatelessWidget {
  const WorkReason({Key? key, required this.text, this.maxLines = 2})
      : super(key: key);

  final String text;

  /// `null` — не обрывать вовсе.
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 8.0),
      decoration: const BoxDecoration(
        border: Border(
          left: BorderSide(color: ColorApp.myColorGrayBorder, width: 2.0),
        ),
      ),
      child: Text(
        text,
        maxLines: maxLines,
        overflow: maxLines == null ? null : TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 12.0, color: ColorApp.myColorGray),
      ),
    );
  }
}

/// Пилюля состояния с живым счётом времени.
///
/// Тик минутный: экран прораба держат открытым подолгу, и застывшее
/// «Идёт · 40 мин» врёт ровно тогда, когда важно, — когда человек решает,
/// звонить механику или подождать. Секундной точности здесь не нужно.
///
/// Таймер на пилюлю, а не один на раздел: список обрезан двадцатью строками,
/// и двадцать минутных таймеров дешевле, чем перерисовка всего раздела.
class WorkPill extends StatefulWidget {
  const WorkPill({Key? key, required this.work}) : super(key: key);

  final InProgressWork work;

  @override
  State<WorkPill> createState() => _WorkPillState();
}

class _WorkPillState extends State<WorkPill> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void didUpdateWidget(WorkPill old) {
    super.didUpdateWidget(old);
    // Список перечитали: работа могла встать на паузу или уйти в проблему —
    // отсчёт начинается заново, а у проблемы таймер лишний.
    if (widget.work.pillSince != old.work.pillSince ||
        widget.work.state != old.work.state) {
      _tick?.cancel();
      _start();
    }
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  void _start() {
    _tick = widget.work.pillSince == null
        ? null
        : Timer.periodic(
            const Duration(minutes: 1),
            (Timer _) => setState(() {}),
          );
  }

  @override
  Widget build(BuildContext context) {
    final InProgressWork work = widget.work;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9.0, vertical: 3.0),
      decoration: BoxDecoration(
        color: _background(work.state),
        borderRadius: BorderRadius.circular(999.0),
      ),
      child: Text(
        work.pillLabel(now: DateTime.now()),
        softWrap: false,
        style: TextStyle(
          fontSize: 12.0,
          fontWeight: FontWeight.w600,
          color: _foreground(work.state),
        ),
      ),
    );
  }

  Color _background(WorkState state) {
    switch (state) {
      case WorkState.problem:
        return problemBackground;
      case WorkState.paused:
        return pauseBackground;
      case WorkState.running:
        return ColorApp.myColorGreenLine;
    }
  }

  Color _foreground(WorkState state) {
    switch (state) {
      case WorkState.problem:
        return problemText;
      case WorkState.paused:
        return pauseText;
      case WorkState.running:
        return runningText;
    }
  }
}

/// Пилюля состояния и серый хвост.
///
/// Пилюля — то, что меняет решение прямо сейчас, и не режется никогда. Хвост —
/// числа для понимания: на узком экране жертвуем ими, а не состоянием.
class WorkStateLine extends StatelessWidget {
  const WorkStateLine({Key? key, required this.work, this.tail})
      : super(key: key);

  final InProgressWork work;

  /// Чем подписать пилюлю. По умолчанию — телефонный хвост строки.
  final String? tail;

  @override
  Widget build(BuildContext context) {
    final String? text = tail ?? work.tailLabel;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        WorkPill(work: work),
        if (text != null) ...<Widget>[
          const SizedBox(width: 8.0),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12.0,
                color: ColorApp.myColorGray,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
