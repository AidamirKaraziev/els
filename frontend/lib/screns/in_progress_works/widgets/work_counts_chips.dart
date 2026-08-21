import 'package:flutter/material.dart';

import '../../../helper/count_chip.dart';
import '../../submitted_works/unreviewed_counter.dart';
import '../in_progress_counts.dart';

/// Три числа у пункта меню «Сданные работы»: сколько сданных работ ждёт
/// проверки, сколько работ идёт и сколько из них встало с проблемой.
///
/// Порядок — от спокойного к срочному, и строка читается как фраза: «три ждут
/// меня, пять в работе, одна стоит». Серое впереди намеренно: это привычный
/// долг по проверке, а не событие сегодняшнего дня.
///
/// Нули не показываются. Никто не работает — нет зелёной таблетки; всё
/// проверено — нет серой. Пустая строка меню без чисел это нормальный вечер,
/// а не поломка.
///
/// Слов в таблетках нет намеренно: «5 в работе» на узком телефоне переносит
/// строку, и пункт меню становится двухэтажным.
class WorkCountsChips extends StatelessWidget {
  const WorkCountsChips({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Числа приходят из двух разных мест: непросмотренное считает лента
    // сданных работ, идущие работы — раздел «Сейчас в работе». Слушаем оба.
    return ValueListenableBuilder<int>(
      valueListenable: unreviewedWorksCount,
      builder: (BuildContext context, int unreviewed, _) {
        return ValueListenableBuilder<InProgressCounts>(
          valueListenable: inProgressCounts,
          builder: (BuildContext context, InProgressCounts counts, _) {
            final List<Widget> chips = <Widget>[
              if (unreviewed > 0)
                CountChip(count: unreviewed, tone: CountTone.neutral),
              if (counts.total > 0)
                CountChip(count: counts.total, tone: CountTone.running),
              if (counts.problems > 0)
                CountChip(count: counts.problems, tone: CountTone.problem),
            ];

            return Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                for (int i = 0; i < chips.length; i++) ...<Widget>[
                  if (i > 0) const SizedBox(width: 6.0),
                  chips[i],
                ],
              ],
            );
          },
        );
      },
    );
  }
}
