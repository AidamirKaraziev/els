import 'package:flutter/material.dart';

import '../../../helper/class_colors.dart';
import '../models/month_cell.dart';
import '../models/schedule_row.dart';
import 'month_strip.dart';

/// Строка списка «Графики»: объект и его годовая лента.
///
/// Раскладка по кадру Figma `83:312` — таблица в один ряд высотой 80:
/// название · заводской номер · плашка «адрес + прораб» · пилюля типа · лента.
/// Колонки и их доли сняты с кадра, не придуманы.
///
/// На узком экране ряд складывается в колонку: пять колонок макета рассчитаны
/// на 1440, и на телефоне из них получается каша. Порог — [kWideLayout].
class ScheduleRowTile extends StatelessWidget {
  const ScheduleRowTile({
    Key? key,
    required this.row,
    required this.onCellTap,
    this.onRowTap,
  }) : super(key: key);

  final ScheduleRow row;

  /// Клик мимо клеток: открыть экран «График» этого объекта.
  ///
  /// Клетка своё нажатие забирает себе — у неё свой `InkWell` внутри, и
  /// карточка работы по-прежнему открывается ею. Пустой месяц нажатия не
  /// перехватывает, и клик по нему считается кликом в строку: за ним нет
  /// работы, зато есть объект, которому график только предстоит завести.
  final VoidCallback? onRowTap;

  /// Наверх уходит и строка, и клетка: карточке работы нужно название объекта
  /// для шапки, а по одной клетке его не восстановить.
  final void Function(ScheduleRow row, MonthCell cell) onCellTap;

  /// Ниже этой ширины табличный ряд не собирается.
  ///
  /// Число не с потолка, а посчитано от ленты. Лента в макете — 213 px
  /// (12 клеток по 15 плюс зазоры), и уже её сжать нельзя. Колонка ленты
  /// получает 22 доли из 91, к ним добавляются поля 36 и четыре промежутка
  /// по 12: `213 · 91 / 22 + 48 + 36 ≈ 965`. Поэтому ряд в кадре и занимает
  /// 990. На меньшей ширине лента обрезалась бы справа — проверено глазами.
  static const double kWideLayout = 970;

  /// Высота ряда в кадре.
  static const double kRowHeight = 80;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool wide = constraints.maxWidth >= kWideLayout;

        final Widget content = Container(
          color: ColorApp.myColorWhite,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: wide ? _wide(context) : _narrow(context),
        );

        final VoidCallback? tap = onRowTap;
        if (tap == null) return content;

        return Material(
          color: ColorApp.myColorWhite,
          child: InkWell(onTap: tap, child: content),
        );
      },
    );
  }

  void _tap(MonthCell cell) => onCellTap(row, cell);

  /// Доли колонок взяты из x-координат кадра при ширине ряда 990:
  /// название 18, номер 196, плашка 377, тип 589, лента 751.
  Widget _wide(BuildContext context) {
    return SizedBox(
      height: kRowHeight - 24,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Expanded(flex: 18, child: _PlainText(text: row.nameLabel)),
          const SizedBox(width: 12),
          Expanded(flex: 18, child: _PlainText(text: row.factoryNumberLabel)),
          const SizedBox(width: 12),
          Expanded(flex: 18, child: _PlaceBlock(row: row)),
          const SizedBox(width: 12),
          Expanded(
            flex: 15,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _TypePill(row: row),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 22,
            child: Align(
              alignment: Alignment.centerRight,
              child: MonthStrip(cells: row.cells, onCellTap: _tap),
            ),
          ),
        ],
      ),
    );
  }

  /// Узкий экран: та же информация сверху вниз. Порядок тот же, что в ряду, —
  /// чтобы человек, привыкший к десктопу, читал строку так же.
  Widget _narrow(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(child: _PlainText(text: row.nameLabel)),
            const SizedBox(width: 8),
            _TypePill(row: row),
          ],
        ),
        const SizedBox(height: 4),
        _PlainText(text: row.factoryNumberLabel),
        const SizedBox(height: 8),
        _PlaceBlock(row: row),
        const SizedBox(height: 8),
        MonthStrip(cells: row.cells, onCellTap: _tap),
      ],
    );
  }
}

/// Текст колонки: кегль 10, средняя жирность, чёрный — как в кадре.
class _PlainText extends StatelessWidget {
  const _PlainText({Key? key, required this.text}) : super(key: key);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: ColorApp.myColorBlack,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}

/// Плашка «адрес + прораб»: серый фон, скругление 10, иконки-подписи.
///
/// Адрес и прораб стоят вместе не для красоты: это ответ на вопрос «куда ехать
/// и с кого спрашивать», и разносить их по разным колонкам незачем.
class _PlaceBlock extends StatelessWidget {
  const _PlaceBlock({Key? key, required this.row}) : super(key: key);

  final ScheduleRow row;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: ColorApp.myColorGrayShadow,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _IconLine(icon: Icons.location_on, text: row.addressLabel),
          const SizedBox(height: 6),
          _IconLine(icon: Icons.person, text: row.foremanLabel),
        ],
      ),
    );
  }
}

class _IconLine extends StatelessWidget {
  const _IconLine({Key? key, required this.icon, required this.text})
      : super(key: key);

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Icon(icon, size: 10, color: ColorApp.myColorGreenAuth),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 8,
              color: ColorApp.myColorBlack,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// Пилюля типа оборудования: зелёная заливка, белый текст — как в кадре.
/// Раньше здесь был серый чип с серым текстом, к макету он отношения не имел.
class _TypePill extends StatelessWidget {
  const _TypePill({Key? key, required this.row}) : super(key: key);

  final ScheduleRow row;

  @override
  Widget build(BuildContext context) {
    if (row.typeName == null || row.typeName!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: ColorApp.myColorGreen,
        borderRadius: BorderRadius.circular(2),
      ),
      child: Text(
        row.typeLabel,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: ColorApp.myColorWhite,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
