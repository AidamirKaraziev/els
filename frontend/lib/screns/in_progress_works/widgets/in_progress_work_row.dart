import 'package:flutter/material.dart';

import '../../../helper/class_colors.dart';
import '../../responsive_screens/responsive.dart';
import '../models/in_progress_work.dart';

/// Оттенки пилюль состояния. Светлая подложка, цветные буквы — так пилюля не
/// спорит с бейджем вида работы и видно, что это разные вещи.
///
/// В `class_colors.dart` из них есть только зелёная подложка
/// ([ColorApp.myColorGreenLine]); остальные живут здесь, а не в общем файле:
/// он достался от подрядчика, и своими цветами мы его не разбавляем, пока они
/// нужны одному разделу.
const Color _pauseBackground = Color(0xffFBEFC7);
const Color _pauseText = Color(0xff8A6A00);
const Color _problemBackground = Color(0xffF7DCDB);
const Color _problemText = Color(0xffB03F3B);
const Color _runningText = Color(0xff4C7A1F);

/// Строка раздела «Сейчас в работе»: что делают, кто делает и что с работой
/// происходит прямо сейчас.
///
/// Серый блок и бейдж — те же, что у сданной работы: строки лежат в одной
/// прокрутке, и соседка снизу должна узнаваться без усилия. Отличие одно —
/// вместо кнопки «Проверил» состояние: проверять нечего, работа идёт.
class InProgressWorkRow extends StatelessWidget {
  const InProgressWorkRow({Key? key, required this.work, this.onTap})
      : super(key: key);

  final InProgressWork work;

  /// Нажимается вся строка целиком: других целей в ней нет, промахнуться
  /// некуда. `null` — пока нет экрана карточки работы (этап 9.1).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    // Тот же порог, что у строки сданной работы: две ленты одного экрана
    // обязаны переключать раскладку одновременно, иначе на середине прокрутки
    // колонки разъедутся.
    final bool narrow = Responsive.isMobile(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Material(
        color: ColorApp.myColorGrayShadow,
        borderRadius: BorderRadius.circular(10.0),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10.0),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
            child: narrow ? _Narrow(work: work) : _Wide(work: work),
          ),
        ),
      ),
    );
  }
}

/// Телефон: всё друг под другом — объект, задание, состояние, кто ведёт,
/// причина.
class _Narrow extends StatelessWidget {
  const _Narrow({Key? key, required this.work}) : super(key: key);

  final InProgressWork work;

  @override
  Widget build(BuildContext context) {
    final String? task = work.taskLabel;
    final String? reason = work.reasonLabel;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(child: _Object(work: work)),
            const SizedBox(width: 8.0),
            _Badge(work: work),
          ],
        ),
        // Задание есть только у заявок: у ТО задание — это чек-лист акта.
        if (task != null) ...<Widget>[
          const SizedBox(height: 6.0),
          Text(
            task,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12.0),
          ),
        ],
        const SizedBox(height: 6.0),
        _StateLine(work: work),
        const SizedBox(height: 6.0),
        _Performer(work: work),
        if (reason != null) ...<Widget>[
          const SizedBox(height: 6.0),
          _Reason(text: reason),
        ],
      ],
    );
  }
}

/// Широкий экран: три колонки. Первые две те же, что у сданной работы —
/// объект и исполнитель, — чтобы глаз не перестраивался на середине экрана.
/// Расходится только третья: у текущей работы там состояние, у сданной кнопка.
class _Wide extends StatelessWidget {
  const _Wide({Key? key, required this.work}) : super(key: key);

  final InProgressWork work;

  @override
  Widget build(BuildContext context) {
    final String? reason = work.reasonLabel;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          flex: 7,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(child: _Object(work: work, withTask: true)),
              const SizedBox(width: 8.0),
              _Badge(work: work),
            ],
          ),
        ),
        const SizedBox(width: 12.0),
        Expanded(flex: 4, child: _Performer(work: work, withTitle: false)),
        const SizedBox(width: 12.0),
        Expanded(
          flex: 6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // На широком экране время начала и регламент уже стоят под
              // именем механика — в хвосте остаётся только прогресс.
              _StateLine(work: work, tail: work.progress?.label),
              if (reason != null) ...<Widget>[
                const SizedBox(height: 6.0),
                _Reason(text: reason),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _Object extends StatelessWidget {
  const _Object({Key? key, required this.work, this.withTask = false})
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

/// Кому звонить. Рядом серым — регламент у ТО («ТО-1») или дата заявки; на
/// широком экране туда же уезжает время начала работы.
class _Performer extends StatelessWidget {
  const _Performer({Key? key, required this.work, this.withTitle = true})
      : super(key: key);

  final InProgressWork work;
  final bool withTitle;

  @override
  Widget build(BuildContext context) {
    if (withTitle) {
      // Телефон: имя и регламент одной строкой — «Ковалёв А. · ТО-1».
      final String? title = work.titleLabel;
      return Text.rich(
        TextSpan(
          text: work.performerLabel,
          children: <TextSpan>[
            if (title != null)
              TextSpan(
                text: ' · $title',
                style: const TextStyle(color: ColorApp.myColorGray),
              ),
          ],
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 12.0),
      );
    }

    // Широкий экран: под именем серым регламент и время начала работы —
    // «ТО-1 · начал 09:30». У заявки там дата, когда её завели.
    final String? meta = work.metaLabel;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          work.performerLabel,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12.0),
        ),
        if (meta != null)
          Text(
            meta,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11.0,
              color: ColorApp.myColorGray,
            ),
          ),
      ],
    );
  }
}

/// Пилюля состояния и серый хвост.
///
/// Пилюля — то, что меняет решение прямо сейчас, и не режется никогда. Хвост —
/// числа для понимания: на узком экране жертвуем ими, а не состоянием.
class _StateLine extends StatelessWidget {
  const _StateLine({Key? key, required this.work, this.tail}) : super(key: key);

  final InProgressWork work;

  /// Чем подписать пилюлю. По умолчанию — телефонный хвост строки.
  final String? tail;

  @override
  Widget build(BuildContext context) {
    final String? text = tail ?? work.tailLabel;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        _Pill(work: work),
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

class _Pill extends StatelessWidget {
  const _Pill({Key? key, required this.work}) : super(key: key);

  final InProgressWork work;

  @override
  Widget build(BuildContext context) {
    final Color background = _background(work.state);
    final Color foreground = _foreground(work.state);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9.0, vertical: 3.0),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999.0),
      ),
      child: Text(
        work.pillLabel,
        softWrap: false,
        style: TextStyle(
          fontSize: 12.0,
          fontWeight: FontWeight.w600,
          color: foreground,
        ),
      ),
    );
  }

  Color _background(WorkState state) {
    switch (state) {
      case WorkState.problem:
        return _problemBackground;
      case WorkState.paused:
        return _pauseBackground;
      case WorkState.running:
        return ColorApp.myColorGreenLine;
    }
  }

  Color _foreground(WorkState state) {
    switch (state) {
      case WorkState.problem:
        return _problemText;
      case WorkState.paused:
        return _pauseText;
      case WorkState.running:
        return _runningText;
    }
  }
}

/// Бейдж вида работы: сплошная заливка, цвет тот же, что в сданных работах.
/// Держит ширину и не режется.
class _Badge extends StatelessWidget {
  const _Badge({Key? key, required this.work}) : super(key: key);

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

/// Слова механика с левой чертой: это цитата, а не подпись системы. Дальше
/// двух строк — многоточие, целиком причина видна в карточке работы.
class _Reason extends StatelessWidget {
  const _Reason({Key? key, required this.text}) : super(key: key);

  final String text;

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
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 12.0, color: ColorApp.myColorGray),
      ),
    );
  }
}
