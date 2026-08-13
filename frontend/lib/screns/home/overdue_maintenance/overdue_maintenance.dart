import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../helper/class_colors.dart';
import '../../responsive_screens/responsive.dart';
import 'bloc/overdue_maintenance_bloc.dart';
import 'models/overdue_maintenance_report.dart';

/// Просроченные ТО ==================================
///
/// Раньше здесь стояли пять одинаковых красных строк «№13 / В.Р. Никифоров /
/// УК “Престиж” / 09.10.2022», а календарь в шапке ни к чему не был привязан.
/// Теперь карточка ходит в `GET /api/v1/statistics/overdue-maintenance`.
///
/// Календаря нет намеренно, в отличие от двух соседних виджетов: просрочка —
/// это состояние на сегодня, а не срез месяца. Выбор месяца здесь означал бы
/// «покажи долги, какими они были в марте», и читался бы неверно. Вместо
/// календаря в шапке стоит счётчик.
class OverdueMaintenance extends StatelessWidget {
  const OverdueMaintenance({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider<OverdueMaintenanceBloc>(
      create: (_) =>
          OverdueMaintenanceBloc()..add(const OverdueMaintenanceRequested()),
      child: const _OverdueMaintenanceView(),
    );
  }
}

class _OverdueMaintenanceView extends StatelessWidget {
  const _OverdueMaintenanceView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final bool isMobile = Responsive.isMobile(context);
    // На узком телефоне колонка с механиком не помещается — как и в старой
    // вёрстке, она уходит первой.
    final bool showResponsible = !isMobile || size.width > 430;

    return BlocBuilder<OverdueMaintenanceBloc, OverdueMaintenanceState>(
      builder: (BuildContext context, OverdueMaintenanceState state) {
        final Widget card = _Card(
          state: state,
          compact: isMobile && size.width <= 430,
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
    required this.state,
    required this.compact,
    required this.showResponsible,
  }) : super(key: key);

  final OverdueMaintenanceState state;
  final bool compact;
  final bool showResponsible;

  @override
  Widget build(BuildContext context) {
    final OverdueMaintenanceState current = state;
    final OverdueMaintenanceReport? report =
        current is OverdueMaintenanceLoaded ? current.report : null;

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
            showResponsible: showResponsible,
            bounded: bounded,
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: bounded ? MainAxisSize.max : MainAxisSize.min,
            children: [
              _Header(compact: compact, report: report),
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
  const _Header({Key? key, required this.compact, required this.report})
      : super(key: key);

  final bool compact;

  /// `null`, пока идёт загрузка или случилась ошибка — счётчика тогда нет.
  final OverdueMaintenanceReport? report;

  @override
  Widget build(BuildContext context) {
    final OverdueMaintenanceReport? current = report;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            'Просроченные ТО',
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: compact ? 15.0 : 21.0,
            ),
          ),
        ),
        if (current != null && current.totalCount > 0) ...[
          const SizedBox(width: 8.0),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
            decoration: BoxDecoration(
              color: ColorApp.myColorRed,
              borderRadius: BorderRadius.circular(20.0),
            ),
            child: Text(
              '${current.totalCount}',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: ColorApp.myColorWhite,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    Key? key,
    required this.state,
    required this.showResponsible,
    required this.bounded,
  }) : super(key: key);

  final OverdueMaintenanceState state;
  final bool showResponsible;

  /// Высота карточки ограничена родителем — значит список можно растягивать.
  final bool bounded;

  @override
  Widget build(BuildContext context) {
    final OverdueMaintenanceState current = state;

    if (current is OverdueMaintenanceFailure) {
      return _Message(
        icon: Icons.cloud_off_outlined,
        title: current.message,
        actionLabel: 'Повторить',
        onAction: () => context
            .read<OverdueMaintenanceBloc>()
            .add(const OverdueMaintenanceRequested()),
        bounded: bounded,
      );
    }

    if (current is OverdueMaintenanceLoaded) {
      if (current.report.isEmpty) {
        // Пусто — это хорошая новость, а не незаполненный график: все
        // заведённые ТО прошедших месяцев закрыты.
        return _Message(
          icon: Icons.check_circle_outline,
          title: 'Просроченных ТО нет',
          bounded: bounded,
        );
      }
      return _Report(
        report: current.report,
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
    required this.showResponsible,
    required this.bounded,
  }) : super(key: key);

  final OverdueMaintenanceReport report;
  final bool showResponsible;
  final bool bounded;

  @override
  Widget build(BuildContext context) {
    final List<Widget> rows = report.items
        .map((OverdueMaintenanceItem item) =>
            _MaintenanceRow(item: item, showResponsible: showResponsible))
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
        if (report.hasMore) ...[
          const SizedBox(height: 4.0),
          // Список обрезан `limit`, и молчать об этом нельзя: пять строк
          // выглядят как весь долг.
          Text(
            'Показано ${report.items.length} из ${report.totalCount}',
            style: const TextStyle(
              fontSize: 12.0,
              color: ColorApp.myColorGray,
            ),
          ),
        ],
      ],
    );
  }
}

/// Итог одной строкой. Долгов может быть больше, чем объектов: один лифт с
/// тремя пропущенными месяцами — это три ТО и один объект.
class _Totals extends StatelessWidget {
  const _Totals({Key? key, required this.report}) : super(key: key);

  final OverdueMaintenanceReport report;

  @override
  Widget build(BuildContext context) {
    return Text(
      'Просрочено ${report.totalCount} ТО'
      ' на ${report.objectsAffected} объектах',
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        fontWeight: FontWeight.w600,
        color: ColorApp.myColorGray,
      ),
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
          const Expanded(flex: 3, child: Text('Объект', style: style)),
          if (showResponsible) ...[
            const SizedBox(width: 8.0),
            const Expanded(flex: 4, child: Text('Ответственный', style: style)),
          ],
          const SizedBox(width: 8.0),
          const Expanded(flex: 4, child: Text('Клиент', style: style)),
          const SizedBox(width: 8.0),
          const SizedBox(
            width: 76.0,
            child: Text('Плановый ТО', style: style, textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }
}

class _MaintenanceRow extends StatelessWidget {
  const _MaintenanceRow({
    Key? key,
    required this.item,
    required this.showResponsible,
  }) : super(key: key);

  final OverdueMaintenanceItem item;
  final bool showResponsible;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10.0),
        height: 40.0,
        decoration: BoxDecoration(
          color: item.color,
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Text(
                item.objectLabel,
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
            Expanded(
              flex: 4,
              child: Text(
                item.clientLabel,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8.0),
            SizedBox(
              width: 76.0,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    item.plannedLabel,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  // Без этой подписи ТО, просроченное на месяц, выглядит так
                  // же, как забытое полгода назад.
                  Text(
                    item.overdueLabel,
                    style: const TextStyle(fontSize: 11.0),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Пустой ответ и ошибка выглядят одинаково устроенными: иконка, текст и,
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
/// ==================================================
