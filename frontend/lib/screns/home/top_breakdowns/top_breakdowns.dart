import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../helper/calendar/month_picker.dart';
import '../../../helper/class_colors.dart';
import '../../responsive_screens/responsive.dart';
import 'bloc/breakdowns_bloc.dart';
import 'models/breakdowns_report.dart';
import 'widgets/breakdown_row.dart';
import 'widgets/severity_chips.dart';

/// Топ поломок ============================================
///
/// Раньше здесь стояли пять захардкоженных строк «№12 / УК "Престиж" /
/// В.Р. Никифоров / 4», а календарь в шапке ни к чему не был привязан.
/// Теперь карточка ходит в `GET /api/v1/statistics/breakdowns` за выбранный
/// месяц и умеет показывать загрузку, ошибку и пустой месяц.
class TopBreakdowns extends StatelessWidget {
  const TopBreakdowns({Key? key, this.onShowAll, this.onObjectTap})
      : super(key: key);

  /// Переход на экран подробностей. Появится вместе с самим экраном.
  final VoidCallback? onShowAll;

  /// Переход к заявкам объекта за выбранный месяц.
  final void Function(BreakdownObject item, DateTime month)? onObjectTap;

  /// Сколько строк помещается в карточку на главной.
  static const int rowsOnHome = 5;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<BreakdownsBloc>(
      create: (_) => BreakdownsBloc()
        ..add(BreakdownsRequested(month: DateTime.now(), limit: rowsOnHome)),
      child: _TopBreakdownsView(
        onShowAll: onShowAll,
        onObjectTap: onObjectTap,
      ),
    );
  }
}

class _TopBreakdownsView extends StatelessWidget {
  const _TopBreakdownsView({Key? key, this.onShowAll, this.onObjectTap})
      : super(key: key);

  final VoidCallback? onShowAll;
  final void Function(BreakdownObject item, DateTime month)? onObjectTap;

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final bool isMobile = Responsive.isMobile(context);
    // На узком телефоне колонка с механиком не помещается — она уходит
    // на экран подробностей, как и в старой вёрстке.
    final bool showMechanic = !isMobile || size.width > 430;

    return BlocBuilder<BreakdownsBloc, BreakdownsState>(
      builder: (BuildContext context, BreakdownsState state) {
        final DateTime month = state.month ?? DateTime.now();

        final Widget card = _Card(
          isMobile: isMobile,
          header: _Header(
            month: month,
            enabled: state is! BreakdownsLoading,
            compact: isMobile && size.width <= 430,
            onMonthChanged: (DateTime value) => context
                .read<BreakdownsBloc>()
                .add(BreakdownsRequested(
                  month: value,
                  limit: TopBreakdowns.rowsOnHome,
                )),
          ),
          state: state,
          showMechanic: showMechanic,
          onShowAll: onShowAll,
          onObjectTap: onObjectTap,
          month: month,
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
    required this.isMobile,
    required this.header,
    required this.state,
    required this.showMechanic,
    required this.month,
    this.onShowAll,
    this.onObjectTap,
  }) : super(key: key);

  final bool isMobile;
  final Widget header;
  final BreakdownsState state;
  final bool showMechanic;
  final DateTime month;
  final VoidCallback? onShowAll;
  final void Function(BreakdownObject item, DateTime month)? onObjectTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15.0),
        color: Colors.white,
        boxShadow: const [BoxShadow(color: Colors.grey, blurRadius: 5)],
      ),
      // Растягивать список можно только внутри ограниченной высоты. Ширина
      // экрана об этом ничего не говорит: на главной карточка стоит в
      // Expanded, а в `desktop_version.dart` — в SingleChildScrollView, где
      // высота бесконечна и Expanded роняет вёрстку. Спрашиваем у родителя.
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final bool bounded = constraints.maxHeight.isFinite;

          final Widget body = _Body(
            state: state,
            showMechanic: showMechanic,
            month: month,
            onShowAll: onShowAll,
            onObjectTap: onObjectTap,
            isMobile: isMobile,
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
            'Топ поломок',
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: compact ? 15.0 : 21.0,
            ),
          ),
        ),
        MonthPicker(
          value: month,
          enabled: enabled,
          onChanged: onMonthChanged,
        ),
      ],
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    Key? key,
    required this.state,
    required this.showMechanic,
    required this.month,
    required this.isMobile,
    required this.bounded,
    this.onShowAll,
    this.onObjectTap,
  }) : super(key: key);

  final BreakdownsState state;
  final bool showMechanic;
  final DateTime month;
  final bool isMobile;

  /// Высота карточки ограничена родителем — значит список можно растягивать.
  final bool bounded;

  final VoidCallback? onShowAll;
  final void Function(BreakdownObject item, DateTime month)? onObjectTap;

  @override
  Widget build(BuildContext context) {
    final BreakdownsState current = state;

    if (current is BreakdownsFailure) {
      return _Message(
        icon: Icons.cloud_off_outlined,
        title: current.message,
        actionLabel: 'Повторить',
        onAction: () => context.read<BreakdownsBloc>().add(
              BreakdownsRequested(
                month: month,
                limit: TopBreakdowns.rowsOnHome,
              ),
            ),
        bounded: bounded,
      );
    }

    if (current is BreakdownsLoaded) {
      if (current.report.isEmpty) {
        return _Message(
          icon: Icons.check_circle_outline,
          title: 'За этот месяц поломок нет',
          bounded: bounded,
        );
      }
      return _Report(
        report: current.report,
        showMechanic: showMechanic,
        month: month,
        isMobile: isMobile,
        bounded: bounded,
        onShowAll: onShowAll,
        onObjectTap: onObjectTap,
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
    required this.showMechanic,
    required this.month,
    required this.isMobile,
    required this.bounded,
    this.onShowAll,
    this.onObjectTap,
  }) : super(key: key);

  final BreakdownsReport report;
  final bool showMechanic;
  final DateTime month;
  final bool isMobile;
  final bool bounded;
  final VoidCallback? onShowAll;
  final void Function(BreakdownObject item, DateTime month)? onObjectTap;

  @override
  Widget build(BuildContext context) {
    final int maxCount = report.items.first.breakdownCount;

    final List<Widget> rows = <Widget>[];
    for (final BreakdownObject item in report.items) {
      rows.add(
        BreakdownRow(
          item: item,
          maxCount: maxCount,
          showMechanic: showMechanic,
          onTap: onObjectTap == null ? null : () => onObjectTap!(item, month),
        ),
      );
    }

    final Widget list = bounded
        ? ListView(padding: EdgeInsets.zero, children: rows)
        : Column(children: rows);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: bounded ? MainAxisSize.max : MainAxisSize.min,
      children: [
        /// Свод по категориям тяжести
        SeverityChips(items: report.severitySummary, compact: isMobile),
        const SizedBox(height: 10.0),

        /// Шапка таблицы
        _ColumnTitles(showMechanic: showMechanic),
        Divider(color: Colors.grey.shade300, thickness: 1),

        if (bounded) Expanded(child: list) else list,

        /// «Показано 5 из 23»
        if (report.hiddenObjects > 0)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    'Показано ${report.items.length} из ${report.objectsAffected}',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.0,
                      color: ColorApp.myColorGrayText,
                    ),
                  ),
                ),
                if (onShowAll != null)
                  TextButton(
                    onPressed: onShowAll,
                    child: const Text(
                      'Подробнее',
                      style: TextStyle(color: ColorApp.myColorGreenAuth),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ColumnTitles extends StatelessWidget {
  const _ColumnTitles({Key? key, required this.showMechanic}) : super(key: key);

  final bool showMechanic;

  @override
  Widget build(BuildContext context) {
    const TextStyle style = TextStyle(color: Colors.black, fontSize: 13.0);

    return Padding(
      // Отступ справа равен ширине плашки со счётчиком, чтобы заголовки
      // стояли ровно над своими колонками.
      padding: const EdgeInsets.only(left: 10.0, right: 64.0),
      child: Row(
        children: [
          const Expanded(flex: 4, child: Text('Объект', style: style)),
          const SizedBox(width: 8.0),
          const Expanded(flex: 3, child: Text('Клиент', style: style)),
          if (showMechanic) ...[
            const SizedBox(width: 8.0),
            const Expanded(flex: 3, child: Text('Ответственный', style: style)),
          ],
        ],
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

  /// Внутри ограниченной высоты сообщение растягивается на карточку, иначе
  /// ему нужен свой размер — иначе Column схлопнется по контенту иконки.
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
/// ========================================================
