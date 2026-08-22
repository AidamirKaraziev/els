import 'package:flutter/material.dart';

import '../../../helper/class_colors.dart';
import '../../responsive_screens/responsive.dart';
import '../models/in_progress_work.dart';
import 'work_parts.dart';

/// Строка раздела «Сейчас в работе»: что делают, кто делает и что с работой
/// происходит прямо сейчас.
///
/// Серый блок и бейдж — те же, что у сданной работы: строки лежат в одной
/// прокрутке, и соседка снизу должна узнаваться без усилия. Отличие одно —
/// вместо кнопки «Проверил» состояние: проверять нечего, работа идёт.
///
/// Объект, бейдж, пилюлю и причину рисуют общие виджеты из
/// [work_parts.dart]: карточка работы повторяет эту же строку, и разойтись
/// им нельзя.
class InProgressWorkRow extends StatelessWidget {
  const InProgressWorkRow({Key? key, required this.work, this.onTap})
      : super(key: key);

  final InProgressWork work;

  /// Нажимается вся строка целиком: других целей в ней нет, промахнуться
  /// некуда. `null` оставляет строку без карточки — так она выглядит там, где
  /// её показывают, но открывать нечего.
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
            Expanded(child: WorkObject(work: work)),
            const SizedBox(width: 8.0),
            WorkBadge(work: work),
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
        WorkStateLine(work: work),
        const SizedBox(height: 6.0),
        _Performer(work: work),
        if (reason != null) ...<Widget>[
          const SizedBox(height: 6.0),
          WorkReason(text: reason),
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
              Expanded(child: WorkObject(work: work, withTask: true)),
              const SizedBox(width: 8.0),
              WorkBadge(work: work),
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
              WorkStateLine(work: work, tail: work.progress?.label),
              if (reason != null) ...<Widget>[
                const SizedBox(height: 6.0),
                WorkReason(text: reason),
              ],
            ],
          ),
        ),
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
