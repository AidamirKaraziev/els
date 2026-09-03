import 'package:flutter/material.dart';

import '../../../../helper/calendar/month_picker.dart' show kMonthsGenitive;
import '../../../../helper/class_colors.dart';
import '../../../../helper/hints/hint_icon.dart';
import '../../../../helper/hints/hints.dart';
import '../../models/month_cell.dart';
import '../../models/schedule_role.dart';
import '../../widgets/month_strip.dart';
import '../../widgets/schedule_year_picker.dart';
import 'object_block.dart';

/// Блок «Техническое обслуживание»: годовая лента плановых ТО.
///
/// Расхождения с кадром `1182:232`, принятые сознательно:
///
/// * **Переключателя года в кадре нет** — лента там одна и без года. Год
///   переключается по решению заказчика от 27 августа (пункт 8), и ставить
///   его больше некуда: он управляет всей лентой.
/// * **Подписей на клетках в кадре тоже нет** — ни вида ТО, ни месяца.
///   Показываем то, что влезает: «ТО 1» внутри клетки на широкой ленте и
///   «Янв» под ней. Без них месяц приходится отсчитывать пальцем, а вид
///   работы не виден вовсе.
/// * **Цвета — насыщенные из палитры проекта**, а не бледные плашки кадра.
///   Те же пять состояний, что в ленте раздела «Графики» (решение 11): один
///   и тот же месяц не может быть в двух местах разного цвета.
/// * **Иконок выгрузки и дефектных актов рядом с заголовком нет** — это S3.
/// * **Срок справа от ленты считаем сами.** В кадре там «11 января –
///   17 января» — точный плановый интервал работы. Такого интервала в данных
///   нет вовсе: у работы есть только фактические `started_at` и
///   `finished_at`, а плановый срок ТО — целый календарный месяц, по концу
///   которого бэкенд и считает просрочку. Поэтому показываем то, что правда:
///   срок **ближайшего незакрытого** ТО года, месяцем целиком.
class ObjectScheduleCard extends StatelessWidget {
  const ObjectScheduleCard({
    Key? key,
    required this.year,
    required this.cells,
    required this.onYearChanged,
    required this.onCellTap,
    this.role = ScheduleRole.admin,
    this.isLoading = false,
    this.isGenerating = false,
    this.error,
    this.onGenerate,
  }) : super(key: key);

  final int year;
  final List<MonthCell> cells;
  final ValueChanged<int> onYearChanged;
  final ValueChanged<MonthCell> onCellTap;

  /// Чьими глазами открыт экран. График расставляют админ и прораб
  /// (`planned_to:write`); остальным кнопки создания не показываем — она
  /// всё равно вернула бы 403.
  final ScheduleRole role;

  final bool isLoading;
  final bool isGenerating;

  /// Что не получилось с лентой. Текст готовый, прямо от ручки.
  final String? error;

  final VoidCallback? onGenerate;

  /// Ширина, ниже которой подпись «Плановые ТО» встаёт над лентой.
  ///
  /// Рядом с лентой она держится только на широком экране: на телефоне
  /// подпись и двенадцать клеток в одну строку дают клетки по три пикселя.
  static const double _inlineLabelWidth = 620.0;

  bool get _hasNoSchedule =>
      cells.every((MonthCell cell) => cell.status == MonthStatus.none);

  /// Ближайшее незакрытое ТО года — то, к чему прорабу готовиться.
  ///
  /// Сначала самое раннее **просроченное** (`overdue`): срок по нему уже
  /// вышел, и делать его надо раньше, чем то, что только назначено. Долгов
  /// нет — берём ближайшее назначенное (`pending`). Всё закрыто или год пуст
  /// — `null`, и строки не будет: «Ближайшее ТО: нет» занимает место и ничего
  /// не сообщает.
  MonthCell? get _nextDue {
    MonthCell? pending;
    MonthCell? overdue;
    for (final MonthCell cell in cells) {
      if (cell.status == MonthStatus.pending) {
        if (pending == null || cell.month < pending.month) pending = cell;
      } else if (cell.status == MonthStatus.overdue) {
        if (overdue == null || cell.month < overdue.month) overdue = cell;
      }
    }
    return overdue ?? pending;
  }

  bool get _canGenerate =>
      role == ScheduleRole.admin || role == ScheduleRole.foreman;

  @override
  Widget build(BuildContext context) {
    return ObjectBlock(
      title: 'Техническое обслуживание',
      titleTrailing: ScheduleYearPicker(year: year, onChanged: onYearChanged),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16.0),
        decoration: objectCardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _strip(context),
            if (error != null) ...<Widget>[
              const SizedBox(height: 12.0),
              _Message(text: error!, color: ColorApp.myColorRed),
            ],
            if (_hasNoSchedule && !isLoading && error == null) ...<Widget>[
              const SizedBox(height: 16.0),
              _Message(
                text: 'График на $year год не заводили',
                color: ColorApp.myColorGray,
              ),
              if (_canGenerate && onGenerate != null) ...<Widget>[
                const SizedBox(height: 12.0),
                _GenerateButton(
                  year: year,
                  isGenerating: isGenerating,
                  onPressed: onGenerate!,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _strip(BuildContext context) {
    final Widget label = Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        const Flexible(
          child: Text(
            'Плановые ТО',
            style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const HintIcon(id: HintIds.scheduleMonthCreatesAct),
        if (isLoading) ...<Widget>[
          const SizedBox(width: 8.0),
          const SizedBox(
            width: 12.0,
            height: 12.0,
            child: CircularProgressIndicator(strokeWidth: 2.0),
          ),
        ],
      ],
    );

    final Widget strip = MonthStrip(
      cells: cells,
      onCellTap: onCellTap,
      showMonthLabels: true,
    );

    final MonthCell? due = _nextDue;
    final Widget? dueLine =
        due == null ? null : _DueLine(year: year, cell: due);

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        if (constraints.maxWidth < _inlineLabelWidth) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              label,
              const SizedBox(height: 12.0),
              strip,
              if (dueLine != null) ...<Widget>[
                const SizedBox(height: 12.0),
                dueLine,
              ],
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Подпись фиксированной ширины: иначе лента разъезжается по
            // ширине от того, крутится ли рядом кружок загрузки.
            SizedBox(width: 160.0, child: label),
            const SizedBox(width: 16.0),
            Expanded(child: strip),
            if (dueLine != null) ...<Widget>[
              const SizedBox(width: 16.0),
              dueLine,
            ],
          ],
        );
      },
    );
  }
}

/// Срок ближайшего незакрытого ТО: «ТО 1 · 1 – 31 марта» и значок календаря.
///
/// Место в кадре занимал точный интервал работы; здесь стоит плановый месяц
/// целиком — см. пояснение у [ObjectScheduleCard]. Вид работы приписан
/// спереди: без него строка говорит, *когда*, но не *что*.
class _DueLine extends StatelessWidget {
  const _DueLine({Key? key, required this.year, required this.cell})
      : super(key: key);

  final int year;
  final MonthCell cell;

  /// Последний день месяца — через нулевой день следующего, чтобы не держать
  /// в коде свою таблицу длин месяцев и правило високосного года.
  int get _lastDay => DateTime(year, cell.month + 1, 0).day;

  String get _text {
    final String month = kMonthsGenitive[cell.month - 1];
    final String dates = '1 – $_lastDay $month';
    final String name = cell.toName ?? '';
    return name.isEmpty ? dates : '$name · $dates';
  }

  @override
  Widget build(BuildContext context) {
    // Просроченное ТО тем же красным, что и его клетка: строка и лента не
    // должны расходиться в том, тревожный это срок или обычный.
    final bool isOverdue = cell.status == MonthStatus.overdue;
    final Color color =
        isOverdue ? ColorApp.myColorRed : ColorApp.myColorGrayText;
    return Tooltip(
      message: isOverdue
          ? 'Ближайшее незакрытое ТО, срок вышел'
          : 'Ближайшее назначенное ТО',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            _text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 13.0, color: color),
          ),
          const SizedBox(width: 6.0),
          Icon(Icons.calendar_today_outlined, size: 14.0, color: color),
        ],
      ),
    );
  }
}

/// Строка пояснения под лентой: пустой год или неудача.
class _Message extends StatelessWidget {
  const _Message({Key? key, required this.text, required this.color})
      : super(key: key);

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(fontSize: 13.0, color: color),
    );
  }
}

/// «Создать график на 2027».
class _GenerateButton extends StatelessWidget {
  const _GenerateButton({
    Key? key,
    required this.year,
    required this.isGenerating,
    required this.onPressed,
  }) : super(key: key);

  final int year;
  final bool isGenerating;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      // Пока идёт создание, кнопка выключена: ручка от повтора не портится,
      // но два запроса из одного нажатия — не то, что человек имел в виду.
      onPressed: isGenerating ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: ColorApp.myColorGreenAuth,
        foregroundColor: ColorApp.myColorWhite,
        elevation: 0.0,
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
      ),
      child: isGenerating
          ? const SizedBox(
              width: 16.0,
              height: 16.0,
              child: CircularProgressIndicator(
                strokeWidth: 2.0,
                color: ColorApp.myColorWhite,
              ),
            )
          : Text('Создать график на $year'),
    );
  }
}
