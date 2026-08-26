import 'package:flutter/material.dart';

import '../../../helper/class_colors.dart';
import '../models/schedule_division.dart';

/// Строка списка участков (кадр Figma `3:339`).
///
/// Кружок с номером · название и прораб под ним · пилюля с процентом.
/// Больше в строке ничего нет намеренно: экран отвечает на один вопрос — где
/// график проваливается, — а подробности лежат уровнем ниже, в ленте объектов.
class ScheduleDivisionTile extends StatelessWidget {
  const ScheduleDivisionTile({
    Key? key,
    required this.division,
    required this.onTap,
  }) : super(key: key);

  final ScheduleDivision division;
  final ValueChanged<ScheduleDivision> onTap;

  static const double kRowHeight = 64;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: ColorApp.myColorWhite,
      child: InkWell(
        onTap: () => onTap(division),
        child: Container(
          constraints: const BoxConstraints(minHeight: kRowHeight),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Row(
            children: <Widget>[
              _Number(number: division.number),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      division.titleLabel,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: ColorApp.myColorBlack,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      division.foremanLabel,
                      style: const TextStyle(
                        fontSize: 12,
                        color: ColorApp.myColorGrayText,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _Percent(division: division),
            ],
          ),
        ),
      ),
    );
  }
}

/// Номер участка в кружке.
class _Number extends StatelessWidget {
  const _Number({Key? key, required this.number}) : super(key: key);

  final int number;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: ColorApp.myColorGreenAuth,
      ),
      child: Text(
        '$number',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: ColorApp.myColorWhite,
        ),
      ),
    );
  }
}

/// Пилюля с процентом выполнения.
///
/// Пороги живут в [ScheduleDivision.color] — те же 90 и 70, что у карточки
/// «Выполнение графика» на главной.
class _Percent extends StatelessWidget {
  const _Percent({Key? key, required this.division}) : super(key: key);

  final ScheduleDivision division;

  @override
  Widget build(BuildContext context) {
    // График на участке не заводили — процент считать не от чего, и ноль тут
    // означал бы «работают плохо», а не «работы не назначены».
    if (division.hasNoPlan) {
      return const Text(
        'нет графика',
        style: TextStyle(fontSize: 12, color: ColorApp.myColorGrayText),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: division.color,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Text(
        division.percentLabel,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: division.foreground,
        ),
      ),
    );
  }
}
