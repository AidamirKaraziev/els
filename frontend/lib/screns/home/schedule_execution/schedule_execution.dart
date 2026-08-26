import 'package:flutter/material.dart';
import '../../../helper/hints/hints.dart';
import '../../../helper/hints/hint_icon.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

import '../../../helper/app_section.dart';
import '../../../helper/calendar/month_picker.dart';
import '../../../helper/class_colors.dart';
import '../../responsive_screens/responsive.dart';
import '../../schedule/models/schedule_filters.dart';
import 'bloc/schedule_execution_bloc.dart';
import 'models/schedule_execution_report.dart';

/// Выполнение графика ==============================
///
/// Раньше здесь стояли пять одинаковых строк «№1 / В.Р. Никифоров / 82 %», а
/// календарь в шапке ни к чему не был привязан. Теперь карточка ходит в
/// `GET /api/v1/statistics/schedule-execution` за выбранный месяц и умеет
/// показывать загрузку, ошибку и незаполненный график.
class ScheduleExecution extends StatelessWidget {
  const ScheduleExecution({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ScheduleExecutionBloc>(
      create: (_) => ScheduleExecutionBloc()
        ..add(ScheduleExecutionRequested(month: DateTime.now())),
      child: const _ScheduleExecutionView(),
    );
  }
}

class _ScheduleExecutionView extends StatelessWidget {
  const _ScheduleExecutionView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final bool isMobile = Responsive.isMobile(context);
    // На узком телефоне колонка с прорабом не помещается — как и в старой
    // вёрстке, она уходит первой.
    final bool showResponsible = !isMobile || size.width > 430;

    return BlocBuilder<ScheduleExecutionBloc, ScheduleExecutionState>(
      builder: (BuildContext context, ScheduleExecutionState state) {
        final DateTime month = state.month ?? DateTime.now();

        final Widget card = _Card(
          header: _Header(
            month: month,
            enabled: state is! ScheduleExecutionLoading,
            compact: isMobile && size.width <= 430,
            onMonthChanged: (DateTime value) => context
                .read<ScheduleExecutionBloc>()
                .add(ScheduleExecutionRequested(month: value)),
          ),
          state: state,
          month: month,
          showResponsible: showResponsible,
        );

        return isMobile
            ? Padding(padding: const EdgeInsets.all(10.0), child: card)
            : card;
      },
    );
  }
}

/// Оформление карточки один раз на оба варианта вёрстки. В прежнем файле
/// белый прямоугольник с тенью был скопирован дважды, и правки расходились.
class _Card extends StatelessWidget {
  const _Card({
    Key? key,
    required this.header,
    required this.state,
    required this.month,
    required this.showResponsible,
  }) : super(key: key);

  final Widget header;
  final ScheduleExecutionState state;
  final DateTime month;
  final bool showResponsible;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15.0),
        color: Colors.white,
        boxShadow: const [BoxShadow(color: Colors.grey, blurRadius: 5)],
      ),
      // Растягивать список можно только внутри ограниченной высоты, и ширина
      // экрана об этом ничего не говорит: на главной карточка стоит в Expanded,
      // а в `desktop_version.dart` — в SingleChildScrollView, где высота
      // бесконечна и Expanded роняет вёрстку. Спрашиваем у родителя.
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool bounded = constraints.maxHeight.isFinite;

          final Widget body = _Body(
            state: state,
            month: month,
            showResponsible: showResponsible,
            bounded: bounded,
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: bounded ? MainAxisSize.max : MainAxisSize.min,
            children: [
              header,
              const SizedBox(height: 12.0),
              if (bounded) Expanded(child: body) else body,
            ],
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    Key? key,
    required this.month,
    required this.enabled,
    required this.compact,
    required this.onMonthChanged,
  }) : super(key: key);

  final DateTime month;
  final bool enabled;
  final bool compact;
  final ValueChanged<DateTime> onMonthChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            'Выполнение графика',
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: compact ? 15.0 : 21.0,
            ),
          ),
        ),
        const HintIcon(id: HintIds.completionByFinishDate),
        MonthPicker(value: month, enabled: enabled, onChanged: onMonthChanged),
      ],
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    Key? key,
    required this.state,
    required this.month,
    required this.showResponsible,
    required this.bounded,
  }) : super(key: key);

  final ScheduleExecutionState state;
  final DateTime month;
  final bool showResponsible;

  /// Высота карточки ограничена родителем — значит список можно растягивать.
  final bool bounded;

  @override
  Widget build(BuildContext context) {
    final ScheduleExecutionState current = state;

    if (current is ScheduleExecutionFailure) {
      return _Message(
        icon: Icons.cloud_off_outlined,
        title: current.message,
        actionLabel: 'Повторить',
        onAction: () => context
            .read<ScheduleExecutionBloc>()
            .add(ScheduleExecutionRequested(month: month)),
        bounded: bounded,
      );
    }

    if (current is ScheduleExecutionLoaded) {
      if (current.report.isEmpty) {
        // Именно «не заполнен», а не «выполнено 0 %»: пустой ответ означает,
        // что на этот месяц не заведено ни одного ТО, и винить в этом участки
        // нельзя.
        return _Message(
          icon: Icons.event_busy_outlined,
          title: 'На этот месяц график ТО не заполнен',
          bounded: bounded,
        );
      }
      return _Report(
        report: current.report,
        year: month.year,
        showResponsible: showResponsible,
        bounded: bounded,
      );
    }

    // Initial и Loading выглядят одинаково: карточка не должна мигать пустотой
    // между созданием блока и первым ответом.
    return SizedBox(
      height: bounded ? null : 140.0,
      child: const Center(
        child: SizedBox(
          width: 26.0,
          height: 26.0,
          child: CircularProgressIndicator(
            strokeWidth: 2.4,
            color: ColorApp.myColorGreenAuth,
          ),
        ),
      ),
    );
  }
}

class _Report extends StatelessWidget {
  const _Report({
    Key? key,
    required this.report,
    required this.year,
    required this.showResponsible,
    required this.bounded,
  }) : super(key: key);

  final ScheduleExecutionReport report;

  /// Год выбранного в шапке месяца. Именно он уходит в «Графики»: человек
  /// смотрит на декабрь прошлого года — и ленту должен увидеть за него, а не
  /// за текущий.
  final int year;

  final bool showResponsible;
  final bool bounded;

  @override
  Widget build(BuildContext context) {
    final List<Widget> rows = report.items
        .map((ScheduleExecutionDivision item) => _DivisionRow(
              item: item,
              year: year,
              showResponsible: showResponsible,
            ))
        .toList(growable: false);

    final Widget list = bounded
        ? ListView(padding: EdgeInsets.zero, children: rows)
        : Column(children: rows);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: bounded ? MainAxisSize.max : MainAxisSize.min,
      children: [
        _Totals(report: report),
        const SizedBox(height: 10.0),
        _ColumnTitles(showResponsible: showResponsible),
        Divider(color: Colors.grey.shade300, thickness: 1),
        if (bounded) Expanded(child: list) else list,
      ],
    );
  }
}

/// Итог по всем участкам. Считает его бэкенд от общих чисел, а не средним из
/// процентов: участок с одним ТО не должен весить столько же, сколько участок
/// с сорока.
class _Totals extends StatelessWidget {
  const _Totals({Key? key, required this.report}) : super(key: key);

  final ScheduleExecutionReport report;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(
          child: Text(
            'Выполнено ${report.completedCount} из ${report.plannedCount}'
            ' — ${_percent(report.completionPercent)}',
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: ColorApp.myColorGray,
            ),
          ),
        ),
        if (report.completedLateCount > 0) ...[
          const SizedBox(width: 8.0),
          Text(
            'с просрочкой: ${report.completedLateCount}',
            style: const TextStyle(
              fontSize: 12.0,
              color: ColorApp.myColorRed,
            ),
          ),
        ],
      ],
    );
  }
}

class _ColumnTitles extends StatelessWidget {
  const _ColumnTitles({Key? key, required this.showResponsible})
      : super(key: key);

  final bool showResponsible;

  @override
  Widget build(BuildContext context) {
    const TextStyle style = TextStyle(color: Colors.black, fontSize: 13.0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      child: Row(
        children: [
          const Expanded(flex: 3, child: Text('Участок', style: style)),
          if (showResponsible) ...[
            const SizedBox(width: 8.0),
            const Expanded(flex: 4, child: Text('Ответственный', style: style)),
          ],
          const SizedBox(width: 8.0),
          const SizedBox(
            width: 84.0,
            child: Text('Выполнение', style: style, textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }
}

class _DivisionRow extends StatelessWidget {
  const _DivisionRow({
    Key? key,
    required this.item,
    required this.year,
    required this.showResponsible,
  }) : super(key: key);

  final ScheduleExecutionDivision item;
  final int year;
  final bool showResponsible;

  /// Отбор, с которым откроются «Графики».
  ///
  /// У строки «Без участка» своего `division_id` нет — она уходит отдельным
  /// пунктом фильтра: объекты без участка иначе не отобрать.
  ScheduleFilters get _filters => ScheduleFilters(
        year: year,
        division: item.divisionId == null
            ? kWithoutDivision
            : FilterOption(id: item.divisionId!, title: item.divisionLabel),
      );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          // Клик уводит в «Графики» этого участка: карточка отвечает на
          // вопрос «где болит», а лечится это уже там, на ленте объектов.
          return InkWell(
            onTap: () => openSchedules(filters: _filters),
            borderRadius: BorderRadius.circular(20.0),
            child: LinearPercentIndicator(
              // Ширину задаём явно: без неё индикатор берёт ширину экрана и
              // вылезает за карточку на узких раскладках.
              width: constraints.maxWidth,
              padding: EdgeInsets.zero,
              barRadius: const Radius.circular(20.0),
              lineHeight: 40.0,
              percent: item.fraction,
              progressColor: item.color,
              backgroundColor: ColorApp.myColorTransparent,
              center: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        item.divisionLabel,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    if (showResponsible) ...[
                      const SizedBox(width: 8.0),
                      Expanded(
                        flex: 4,
                        child: Text(
                          item.responsibleLabel,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                    const SizedBox(width: 8.0),
                    SizedBox(
                      width: 84.0,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            _percent(item.completionPercent),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          // Без этой подписи «50 %» одинаково выглядит и у
                          // участка с двумя ТО, и у участка с сорока.
                          Text(
                            '${item.completedCount} из ${item.plannedCount}',
                            style: const TextStyle(
                              fontSize: 11.0,
                              color: ColorApp.myColorGray,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Пустой месяц и ошибка выглядят одинаково устроенными: иконка, текст и,
/// если есть что делать, кнопка.
class _Message extends StatelessWidget {
  const _Message({
    Key? key,
    required this.icon,
    required this.title,
    required this.bounded,
    this.actionLabel,
    this.onAction,
  }) : super(key: key);

  final IconData icon;
  final String title;

  /// Внутри ограниченной высоты сообщение растягивается на карточку, иначе ему
  /// нужен свой размер — иначе Column схлопнется по высоте иконки.
  final bool bounded;

  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: bounded ? null : 140.0,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 32.0, color: ColorApp.myColorGrayText),
          const SizedBox(height: 8.0),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(color: ColorApp.myColorGray),
          ),
          if (actionLabel != null && onAction != null)
            TextButton(
              onPressed: onAction,
              child: Text(
                actionLabel!,
                style: const TextStyle(color: ColorApp.myColorGreenAuth),
              ),
            ),
        ],
      ),
    );
  }
}

/// Проценты без хвоста «.0»: в карточке важен порядок величины, а не сотые.
String _percent(double value) {
  final double rounded = value.roundToDouble();
  return '${rounded.toInt()} %';
}
/// =================================================
