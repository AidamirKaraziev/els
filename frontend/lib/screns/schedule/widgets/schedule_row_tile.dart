import 'package:flutter/material.dart';

import '../../../foreman/defects/defects_badge.dart';
import '../../../helper/class_colors.dart';
import '../models/month_cell.dart';
import '../models/schedule_row.dart';
import 'month_strip.dart';

/// Строка списка «Графики»: объект и его годовая лента.
///
/// Раскладка по кадру Figma `83:312` — таблица в один ряд:
/// название · заводской номер · плашка «адрес + прораб» · пилюля типа · лента.
/// Порядок колонок с кадра; размеры крупнее кадра примерно в полтора раза —
/// на сдаче 10.09.2026 заказчик попросил «окно графика крупнее»: ряд в 80
/// с кеглем 10 и клетками по 15 на живом экране не читался. Отдельного
/// кадра под крупный ряд нет, пропорции утверждены по скрину.
///
/// Рядом с названием — значок дефектных актов, тот же `DefectsBadge`, что в
/// карточке объекта. Число даёт сервер вместе с лентой (`defects_count`);
/// нет числа — нет значка. Тап по значку — свой, наверх через [onDefectsTap]:
/// он открывает список актов, а не график объекта, как клик по строке.
///
/// На узком экране ряд складывается в колонку: пять колонок макета рассчитаны
/// на 1440, и на телефоне из них получается каша. Порог — [kWideLayout].
class ScheduleRowTile extends StatelessWidget {
  const ScheduleRowTile({
    Key? key,
    required this.row,
    required this.onCellTap,
    this.onRowTap,
    this.onDefectsTap,
  }) : super(key: key);

  final ScheduleRow row;

  /// Клик мимо клеток: открыть экран «График» этого объекта.
  ///
  /// Клетка своё нажатие забирает себе — у неё свой `InkWell` внутри, и
  /// карточка работы по-прежнему открывается ею. Пустой месяц нажатия не
  /// перехватывает, и клик по нему считается кликом в строку: за ним нет
  /// работы, зато есть объект, которому график только предстоит завести.
  final VoidCallback? onRowTap;

  /// Тап по значку дефектных актов: открыть их список за год ленты.
  ///
  /// Не сливается с [onRowTap]: значок обещает список актов, а строка —
  /// график объекта. Пусто — значок только показывает число.
  final VoidCallback? onDefectsTap;

  /// Наверх уходит и строка, и клетка: карточке работы нужно название объекта
  /// для шапки, а по одной клетке его не восстановить.
  final void Function(ScheduleRow row, MonthCell cell) onCellTap;

  /// Ниже этой ширины табличный ряд не собирается.
  ///
  /// Число посчитано от ленты. Клетка не бывает уже макетных 15
  /// (см. `MonthStrip`), то есть лента — `12 · 15 + 11 · 3 = 213`. Колонка
  /// ленты получает 30 долей из 100, к ним поля 48 и четыре промежутка по
  /// 16: `213 · 100 / 30 + 64 + 48 ≈ 820`; округлено вверх до 1000, чтобы
  /// колонкам текста хватало на слово. Подписи месяцев лента сама убирает,
  /// когда клетке не хватает 24 — на ноутбуке 1366 с меню-колонкой ряд
  /// остаётся рядом, только без подписей.
  static const double kWideLayout = 1000;

  /// Высота ряда: 80 в кадре, здесь — с запасом под кегль 14 и ленту с
  /// подписями месяцев.
  static const double kRowHeight = 112;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool wide = constraints.maxWidth >= kWideLayout;

        final Widget content = Container(
          color: ColorApp.myColorWhite,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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

  /// Порядок колонок с кадра; доли — под крупный ряд: лента с подписями
  /// месяцев шире макетной вдвое, и ей отдана почти треть.
  Widget _wide(BuildContext context) {
    return SizedBox(
      height: kRowHeight - 32,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Expanded(flex: 18, child: _PlainText(text: row.nameLabel)),
          const SizedBox(width: 8),
          _BadgeSlot(row: row, onTap: onDefectsTap),
          const SizedBox(width: 16),
          Expanded(flex: 14, child: _PlainText(text: row.factoryNumberLabel)),
          const SizedBox(width: 16),
          Expanded(flex: 22, child: _PlaceBlock(row: row)),
          const SizedBox(width: 16),
          Expanded(
            flex: 14,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _TypePill(row: row),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 30,
            child: Align(
              alignment: Alignment.centerRight,
              child: MonthStrip(
                cells: row.cells,
                onCellTap: _tap,
                showMonthLabels: true,
              ),
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
            _BadgeSlot(row: row, onTap: onDefectsTap),
            const SizedBox(width: 8),
            _TypePill(row: row),
          ],
        ),
        const SizedBox(height: 6),
        _PlainText(text: row.factoryNumberLabel),
        const SizedBox(height: 10),
        _PlaceBlock(row: row),
        const SizedBox(height: 10),
        MonthStrip(cells: row.cells, onCellTap: _tap),
      ],
    );
  }
}

/// Колонка значка дефектных актов — своя, фиксированной ширины.
///
/// Значки стоят в одной вертикали независимо от длины названия: глаз бежит
/// по столбцу и сравнивает объекты, а значок, привязанный к концу текста,
/// прыгал бы по строке. Ширина — под значок с выносным числом, чтобы
/// «12» не двигало соседнюю колонку. Нет числа от сервера — пустое место
/// той же ширины, колонки не съезжают.
///
/// Нажатие у значка своё: `DefectsBadge` забирает его себе, и в строку
/// под ним оно не проваливается — иначе тап открывал бы и список, и график.
class _BadgeSlot extends StatelessWidget {
  const _BadgeSlot({Key? key, required this.row, this.onTap}) : super(key: key);

  final ScheduleRow row;
  final VoidCallback? onTap;

  static const double _width = 44;

  @override
  Widget build(BuildContext context) {
    final int? count = row.defectsCount;

    return SizedBox(
      width: _width,
      child: count == null
          ? null
          : Align(
              alignment: Alignment.centerLeft,
              child: DefectsBadge(count: count, year: row.year, onTap: onTap),
            ),
    );
  }
}

/// Текст колонки: средняя жирность, чёрный — как в кадре; кегль 14 вместо
/// макетных 10.
class _PlainText extends StatelessWidget {
  const _PlainText({Key? key, required this.text}) : super(key: key);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
        Icon(icon, size: 14, color: ColorApp.myColorGreenAuth),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            style: const TextStyle(fontSize: 12, color: ColorApp.myColorBlack),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: ColorApp.myColorGreen,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        row.typeLabel,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: ColorApp.myColorWhite,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
