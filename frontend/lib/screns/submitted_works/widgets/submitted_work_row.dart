import 'package:flutter/material.dart';

import '../../../helper/class_colors.dart';
import '../../responsive_screens/responsive.dart';
import '../models/submitted_work.dart';

/// Строка ленты: что и где сдали, кто сдал, когда и кнопка «Проверил».
///
/// Строка нейтрально-серая, цвет — только на бейджах справа. Тот же приём,
/// что в «Топе поломок» на макете и в «Просроченных ТО»: если залить цветом
/// всю строку, десять строк подряд кричат одинаково громко и вид работы
/// перестаёт читаться.
class SubmittedWorkRow extends StatelessWidget {
  const SubmittedWorkRow({
    Key? key,
    required this.work,
    required this.onReview,
  }) : super(key: key);

  final SubmittedWork work;

  /// `null` — пока идёт запрос: повторный клик по той же строке ничего не
  /// добавит, а отметка на бэкенде и так идемпотентна.
  final VoidCallback? onReview;

  @override
  Widget build(BuildContext context) {
    final bool narrow = Responsive.isMobile(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
        decoration: BoxDecoration(
          color: ColorApp.myColorGrayShadow,
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: narrow
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Expanded(child: _Object(work: work)),
                      const SizedBox(width: 8.0),
                      _Badges(work: work),
                    ],
                  ),
                  const SizedBox(height: 8.0),
                  _Performer(work: work),
                  const SizedBox(height: 8.0),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: _Review(work: work, onReview: onReview),
                  ),
                ],
              )
            : Row(
                children: <Widget>[
                  Expanded(flex: 5, child: _Object(work: work)),
                  const SizedBox(width: 8.0),
                  Expanded(flex: 4, child: _Performer(work: work)),
                  const SizedBox(width: 8.0),
                  _Badges(work: work),
                  const SizedBox(width: 12.0),
                  SizedBox(width: 200.0, child: _Review(work: work, onReview: onReview)),
                ],
              ),
      ),
    );
  }
}

class _Object extends StatelessWidget {
  const _Object({Key? key, required this.work}) : super(key: key);

  final SubmittedWork work;

  @override
  Widget build(BuildContext context) {
    final String? address = work.addressLabel;
    final String? task = work.taskLabel;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          work.objectLabel,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        // Адрес второй строкой: по «Лифт 12» непонятно, о каком доме речь.
        if (address != null)
          Text(
            address,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11.0, color: ColorApp.myColorGray),
          ),
        // Задание есть только у заявок: у ТО задание — это чек-лист акта.
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

class _Performer extends StatelessWidget {
  const _Performer({Key? key, required this.work}) : super(key: key);

  final SubmittedWork work;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(work.performerLabel, overflow: TextOverflow.ellipsis),
        Text(
          work.closedLabel,
          style: const TextStyle(fontSize: 11.0, color: ColorApp.myColorGray),
        ),
      ],
    );
  }
}

class _Badges extends StatelessWidget {
  const _Badges({Key? key, required this.work}) : super(key: key);

  final SubmittedWork work;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _Badge(text: work.kindLabel, color: work.kindColor),
        // «Проблема» — отдельный бейдж, а не другой цвет вида работы: авария,
        // которую не смогли устранить, остаётся аварией в отчётах.
        if (work.isProblem) ...<Widget>[
          const SizedBox(width: 6.0),
          const _Badge(text: 'Проблема', color: ColorApp.myColorYellow),
        ],
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({Key? key, required this.text, required this.color})
      : super(key: key);

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12.0,
          fontWeight: FontWeight.w700,
          color: ColorApp.myColorWhite,
        ),
      ),
    );
  }
}

class _Review extends StatelessWidget {
  const _Review({Key? key, required this.work, required this.onReview})
      : super(key: key);

  final SubmittedWork work;
  final VoidCallback? onReview;

  @override
  Widget build(BuildContext context) {
    if (work.isReviewed) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(
            Icons.check_circle_outline,
            size: 16.0,
            color: ColorApp.myColorGreenAuth,
          ),
          const SizedBox(width: 6.0),
          Flexible(
            child: Text(
              work.reviewedLabel ?? 'Проверено',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11.0,
                color: ColorApp.myColorGray,
              ),
            ),
          ),
        ],
      );
    }

    return ElevatedButton(
      onPressed: onReview,
      style: ElevatedButton.styleFrom(
        backgroundColor: ColorApp.myColorGreenAuth,
        foregroundColor: ColorApp.myColorWhite,
        elevation: 0.0,
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
      child: const Text('Проверил'),
    );
  }
}
