/// Части, из которых собраны и строка ленты сданных работ, и шапка её карточки.
///
/// Лежат отдельно по той же причине, что и части строки текущей работы в
/// `in_progress_works/widgets/work_parts.dart`: карточка обязана повторять
/// строку, по которой её открыли, **буквально**. Скопируй их в экран карточки —
/// и однажды бейдж «Проблема» поправят в одном месте, а прораб увидит разное
/// там и там.
library;

import 'package:flutter/material.dart';

import '../../../helper/class_colors.dart';
import '../models/submitted_work.dart';

class SubmittedWorkObject extends StatelessWidget {
  const SubmittedWorkObject({Key? key, required this.work}) : super(key: key);

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
class SubmittedWorkBadges extends StatelessWidget {
  const SubmittedWorkBadges({Key? key, required this.work}) : super(key: key);

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
