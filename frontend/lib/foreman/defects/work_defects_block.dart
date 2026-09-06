/// Блок «Дефекты» в карточке работы по ТО — только внешний вид.
///
/// Кадра в макете нет, поэтому язык блока взят не с потолка, а у соседей по
/// той же карточке (`screns/in_progress_works/widgets/work_card_body.dart`):
/// заголовок `WorkBlockTitle`, кегль 13 у строк, разделитель снизу у каждой
/// строки, кроме последней — ровно как у пунктов чек-листа. Пилюля состояния
/// и цвета — общие с экранами дефектов (`defects_layout.dart`), второго
/// набора зелёных не заводим.
///
/// Блок ничего не грузит: список ему дают снаружи. Кто ходит за ним в сеть —
/// `work_defects_section.dart`.
library;

import 'package:flutter/material.dart';

import '../../helper/class_colors.dart';
import '../../screns/in_progress_works/widgets/work_card_body.dart'
    show WorkBlockTitle;
import 'defect_entry.dart';
import 'defects_layout.dart';

class WorkDefectsBlock extends StatelessWidget {
  const WorkDefectsBlock({
    Key? key,
    required this.entries,
    this.onTap,
    this.failure,
    this.onRetry,
    this.loading = false,
  }) : super(key: key);

  /// Акты, заведённые на этой работе. Пусто — так и пишем словами.
  final List<DefectEntry> entries;

  final void Function(DefectEntry entry)? onTap;

  /// Запрос не удался. Блок остаётся на месте: исчезнув, он соврал бы
  /// «дефектов нет» вместо «спросить не вышло».
  final String? failure;

  final VoidCallback? onRetry;

  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        WorkBlockTitle(text: _title),
        const SizedBox(height: 4.0),
        ..._content(),
      ],
    );
  }

  String get _title {
    // Число в заголовке — как «Чек-лист · 3 из 12» у соседа. Пока не
    // ответили и когда не ответили вовсе, числа нет: ноль в этом месте
    // читался бы как «дефектов не было».
    if (loading || failure != null || entries.isEmpty) return 'Дефекты';
    return 'Дефекты · ${entries.length}';
  }

  List<Widget> _content() {
    if (loading) {
      return const <Widget>[
        SizedBox(height: 6.0),
        SizedBox(
          height: 18.0,
          width: 18.0,
          child: CircularProgressIndicator(strokeWidth: 2.0),
        ),
        SizedBox(height: 6.0),
      ];
    }

    if (failure != null) {
      return <Widget>[
        const SizedBox(height: 6.0),
        const Text(
          'Дефекты не загрузились',
          style: TextStyle(fontSize: 13.0, color: ColorApp.myColorGray),
        ),
        if (onRetry != null)
          InkWell(
            onTap: onRetry,
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'Повторить',
                style: TextStyle(
                  fontSize: 13.0,
                  color: ColorApp.myColorGreenAuth,
                ),
              ),
            ),
          ),
      ];
    }

    if (entries.isEmpty) {
      return const <Widget>[
        SizedBox(height: 6.0),
        // «Дефектов нет» — это про работу, а не про экран. Пустое место
        // прораб прочитал бы как недогруженный блок.
        Text(
          'Дефектов на этой работе не заводили',
          style: TextStyle(fontSize: 13.0, color: ColorApp.myColorGray),
        ),
      ];
    }

    return <Widget>[
      for (int i = 0; i < entries.length; i++)
        _DefectRow(
          entry: entries[i],
          last: i == entries.length - 1,
          onTap: onTap == null ? null : () => onTap!(entries[i]),
        ),
    ];
  }
}

/// Одна строка блока: заголовок, состояние и короткие приметы под ними.
class _DefectRow extends StatelessWidget {
  const _DefectRow({
    Key? key,
    required this.entry,
    required this.last,
    this.onTap,
  }) : super(key: key);

  final DefectEntry entry;
  final bool last;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10.0),
        decoration: BoxDecoration(
          border: last
              ? null
              : const Border(
                  bottom: BorderSide(color: ColorApp.myColorGrayBorder),
                ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    entry.title,
                    style: const TextStyle(fontSize: 13.0),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    _facts(entry),
                    style: DefectsLayout.cardSubtitle,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10.0),
            DefectStatePill(state: entry.state),
            const SizedBox(width: 2.0),
            const Icon(
              Icons.chevron_right,
              size: 18.0,
              color: ColorApp.myColorGrayText,
            ),
          ],
        ),
      ),
    );
  }

  /// Приметы одной строкой через точку: дата, откуда заведён, сколько
  /// снимков. Вида ТО тут нет намеренно — он у всех один и тот же, это вид
  /// работы, в карточке которой мы стоим.
  static String _facts(DefectEntry entry) {
    final List<String> parts = <String>[
      if (entry.createdAt != null) _formatDate(entry.createdAt!),
      if (entry.source == DefectSource.checklistStep) 'пункт чек-листа',
      if (entry.photos.isNotEmpty) 'снимков: ${entry.photos.length}',
    ];
    return parts.join(' · ');
  }
}

String _formatDate(DateTime date) {
  final String day = date.day.toString().padLeft(2, '0');
  final String month = date.month.toString().padLeft(2, '0');
  return '$day.$month.${date.year}';
}
