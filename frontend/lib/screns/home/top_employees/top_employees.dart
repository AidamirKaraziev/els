import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../helper/calendar/month_picker.dart';
import '../../../helper/class_colors.dart';
import '../../../helper/session.dart';
import '../../responsive_screens/responsive.dart';
import 'bloc/top_employees_bloc.dart';
import 'models/top_employees_report.dart';

/// Сколько строк показываем на одной странице карточки.
const int _kPageSize = 5;

/// Топ сотрудников ==================================
///
/// Раньше здесь стоял список всех сотрудников подряд, покрашенный в зелёный
/// на десктопе и в красный на телефоне, — без единой метрики: цвет ничего не
/// значил, а календарь в шапке ни к чему не был привязан. Теперь карточка
/// ходит в `GET /api/v1/statistics/top-employees` и показывает балл 0–100.
///
/// Своего кадра в макете у этого виджета нет: на «Главном экране» нарисованы
/// только три карточки. Оформление собрано из приёмов соседей — белая
/// карточка, жирный заголовок, выбор месяца стрелками, серая шапка колонок,
/// нейтральная строка с цветным бейджем справа.
class TopEmployees extends StatelessWidget {
  const TopEmployees({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider<TopEmployeesBloc>(
      create: (_) => TopEmployeesBloc()
        ..add(TopEmployeesRequested(
          month: DateTime.now(),
          limit: _kPageSize,
        )),
      child: const _TopEmployeesView(),
    );
  }
}

class _TopEmployeesView extends StatelessWidget {
  const _TopEmployeesView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final bool isMobile = Responsive.isMobile(context);
    // На узком телефоне колонка с участком не помещается — уходит первой, как
    // и в соседних карточках.
    final bool showDivision = !isMobile || size.width > 430;

    return BlocBuilder<TopEmployeesBloc, TopEmployeesState>(
      builder: (BuildContext context, TopEmployeesState state) {
        final DateTime month = state.month ?? DateTime.now();

        final Widget card = _Card(
          state: state,
          month: month,
          compact: isMobile && size.width <= 430,
          showDivision: showDivision,
        );

        return isMobile
            ? Padding(padding: const EdgeInsets.all(10.0), child: card)
            : card;
      },
    );
  }
}

/// Перезапрос с новым набором переключателей. Один на все три: месяц, вид
/// списка и порядок меняются одинаково — новым запросом.
void _request(
  BuildContext context,
  TopEmployeesState state, {
  DateTime? month,
  EmployeeKind? kind,
  EmployeeOrder? order,
  int? offset,
}) {
  context.read<TopEmployeesBloc>().add(TopEmployeesRequested(
        month: month ?? state.month ?? DateTime.now(),
        kind: kind ?? state.kind,
        order: order ?? state.order,
        limit: _kPageSize,
        // Переключили месяц или порядок — список начинается заново: страница
        // «6–10» в новой выборке означала бы других людей.
        offset: offset ?? 0,
      ));
}

/// Оформление карточки один раз на оба варианта вёрстки. В прежнем файле
/// белый прямоугольник с тенью был скопирован дважды, и правки расходились.
class _Card extends StatelessWidget {
  const _Card({
    Key? key,
    required this.state,
    required this.month,
    required this.compact,
    required this.showDivision,
  }) : super(key: key);

  final TopEmployeesState state;
  final DateTime month;
  final bool compact;
  final bool showDivision;

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
            showDivision: showDivision,
            bounded: bounded,
          );

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: bounded ? MainAxisSize.max : MainAxisSize.min,
            children: [
              _Header(state: state, month: month, compact: compact),
              const SizedBox(height: 10.0),
              _Switches(state: state, compact: compact),
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
    required this.state,
    required this.month,
    required this.compact,
  }) : super(key: key);

  final TopEmployeesState state;
  final DateTime month;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            'Топ сотрудников',
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: compact ? 15.0 : 21.0,
            ),
          ),
        ),
        MonthPicker(
          value: month,
          enabled: state is! TopEmployeesLoading,
          onChanged: (DateTime value) =>
              _request(context, state, month: value),
        ),
      ],
    );
  }
}

/// Два переключателя: «лучшие или худшие» и — только у админа — «механики или
/// прорабы». Прорабу второй не показываем: ручка ответит ему `403`, а кнопка,
/// которая гарантированно ошибается, хуже её отсутствия.
class _Switches extends StatelessWidget {
  const _Switches({Key? key, required this.state, required this.compact})
      : super(key: key);

  final TopEmployeesState state;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final bool enabled = state is! TopEmployeesLoading;
    final bool isAdmin = idUserTest == Roles.admin;

    return Wrap(
      spacing: 8.0,
      runSpacing: 8.0,
      children: [
        _Segmented<EmployeeOrder>(
          value: state.order,
          enabled: enabled,
          compact: compact,
          options: const <EmployeeOrder>[
            EmployeeOrder.best,
            EmployeeOrder.worst,
          ],
          labelOf: (EmployeeOrder value) => value.label,
          onChanged: (EmployeeOrder value) =>
              _request(context, state, order: value),
        ),
        if (isAdmin)
          _Segmented<EmployeeKind>(
            value: state.kind,
            enabled: enabled,
            compact: compact,
            options: const <EmployeeKind>[
              EmployeeKind.mechanic,
              EmployeeKind.foreman,
            ],
            labelOf: (EmployeeKind value) => value.label,
            onChanged: (EmployeeKind value) =>
                _request(context, state, kind: value),
          ),
      ],
    );
  }
}

class _Segmented<T> extends StatelessWidget {
  const _Segmented({
    Key? key,
    required this.value,
    required this.options,
    required this.labelOf,
    required this.onChanged,
    required this.enabled,
    required this.compact,
  }) : super(key: key);

  final T value;
  final List<T> options;
  final String Function(T) labelOf;
  final ValueChanged<T> onChanged;
  final bool enabled;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3.0),
      decoration: BoxDecoration(
        color: ColorApp.myColorGrayShadow,
        borderRadius: BorderRadius.circular(20.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: options.map((T option) {
          final bool selected = option == value;
          return GestureDetector(
            onTap: enabled && !selected ? () => onChanged(option) : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 10.0 : 14.0,
                vertical: 5.0,
              ),
              decoration: BoxDecoration(
                color: selected
                    ? ColorApp.myColorGreenAuth
                    : ColorApp.myColorTransparent,
                borderRadius: BorderRadius.circular(18.0),
              ),
              child: Text(
                labelOf(option),
                style: TextStyle(
                  fontSize: compact ? 12.0 : 13.0,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected
                      ? ColorApp.myColorWhite
                      : ColorApp.myColorGray,
                ),
              ),
            ),
          );
        }).toList(growable: false),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    Key? key,
    required this.state,
    required this.showDivision,
    required this.bounded,
  }) : super(key: key);

  final TopEmployeesState state;
  final bool showDivision;

  /// Высота карточки ограничена родителем — значит список можно растягивать.
  final bool bounded;

  @override
  Widget build(BuildContext context) {
    final TopEmployeesState current = state;

    if (current is TopEmployeesFailure) {
      return _Message(
        icon: Icons.cloud_off_outlined,
        title: current.message,
        actionLabel: 'Повторить',
        onAction: () => _request(context, current),
        bounded: bounded,
      );
    }

    if (current is TopEmployeesLoaded) {
      if (current.report.isEmpty) {
        // Людей может не быть вовсе, а может не быть их работы за месяц —
        // это разные новости, и выводы у руководителя из них разные.
        return _Message(
          icon: Icons.people_outline,
          title: current.report.totalCount == 0
              ? 'Сотрудников в этой выдаче нет'
              : 'За этот месяц работ не заведено',
          bounded: bounded,
        );
      }
      return _Report(
        report: current.report,
        offset: current.offset,
        state: current,
        showDivision: showDivision,
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
    required this.offset,
    required this.state,
    required this.showDivision,
    required this.bounded,
  }) : super(key: key);

  final TopEmployeesReport report;
  final int offset;
  final TopEmployeesState state;
  final bool showDivision;
  final bool bounded;

  @override
  Widget build(BuildContext context) {
    final List<Widget> rows = report.items
        .map((EmployeeScoreItem item) =>
            _EmployeeRow(item: item, showDivision: showDivision))
        .toList(growable: false);

    final Widget list = bounded
        ? ListView(padding: EdgeInsets.zero, children: rows)
        : Column(children: rows);

    final bool paged = report.totalCount > _kPageSize;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: bounded ? MainAxisSize.max : MainAxisSize.min,
      children: [
        _ColumnTitles(showDivision: showDivision),
        Divider(color: Colors.grey.shade300, thickness: 1),
        if (bounded) Expanded(child: list) else list,
        // Все строки без балла — это не поломка виджета: за месяц просто
        // нет закрытых работ. Без этой подписи столбец из прочерков читается
        // как «сервер не ответил».
        if (report.rankedCount == 0) ...[
          const SizedBox(height: 4.0),
          Text(
            'Ни у кого нет ${report.minWorks} закрытых работ за месяц —'
            ' балл появится, когда работы начнут закрывать в системе',
            style: const TextStyle(
              fontSize: 12.0,
              color: ColorApp.myColorGray,
            ),
          ),
        ],
        if (paged) ...[
          const SizedBox(height: 4.0),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Показаны ${offset + 1}–${offset + report.items.length}'
                  ' из ${report.totalCount}',
                  style: const TextStyle(
                    fontSize: 12.0,
                    color: ColorApp.myColorGray,
                  ),
                ),
              ),
              _ArrowButton(
                icon: Icons.chevron_left,
                tooltip: 'Предыдущие',
                onPressed: offset > 0
                    ? () => _request(context, state,
                        offset: offset - _kPageSize < 0 ? 0 : offset - _kPageSize)
                    : null,
              ),
              _ArrowButton(
                icon: Icons.chevron_right,
                tooltip: 'Следующие',
                onPressed: offset + _kPageSize < report.totalCount
                    ? () => _request(context, state, offset: offset + _kPageSize)
                    : null,
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _ArrowButton extends StatelessWidget {
  const _ArrowButton({
    Key? key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  }) : super(key: key);

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon),
      tooltip: tooltip,
      iconSize: 20.0,
      splashRadius: 18.0,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 28.0, minHeight: 28.0),
      color: ColorApp.myColorBlack,
      disabledColor: ColorApp.myColorGrayBorder,
    );
  }
}

class _ColumnTitles extends StatelessWidget {
  const _ColumnTitles({Key? key, required this.showDivision}) : super(key: key);

  final bool showDivision;

  @override
  Widget build(BuildContext context) {
    const TextStyle style = TextStyle(color: Colors.black, fontSize: 13.0);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Row(
        children: [
          const Expanded(flex: 5, child: Text('Сотрудник', style: style)),
          if (showDivision) ...[
            const SizedBox(width: 8.0),
            const Expanded(flex: 3, child: Text('Участок', style: style)),
          ],
          const SizedBox(width: 8.0),
          const SizedBox(
            width: 56.0,
            child: Text(
              'Балл',
              style: style,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmployeeRow extends StatelessWidget {
  const _EmployeeRow({
    Key? key,
    required this.item,
    required this.showDivision,
  }) : super(key: key);

  final EmployeeScoreItem item;
  final bool showDivision;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
        decoration: BoxDecoration(
          // Спокойная серая строка, цвет — только на бейдже с баллом. Пять
          // цветных прямоугольников подряд кричали бы одинаково громко, а
          // разговор о человеке начинается именно с цифры.
          color: ColorApp.myColorGrayShadow,
          borderRadius: BorderRadius.circular(10.0),
        ),
        child: Row(
          children: [
            Expanded(
              flex: 5,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.nameLabel,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  // Из чего сложился балл — второй строкой. Без неё цифра
                  // выглядит приговором, который нечем объяснить человеку.
                  Text(
                    item.isProvisional ? 'Мало данных' : item.workLabel,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.0,
                      fontStyle: item.isProvisional
                          ? FontStyle.italic
                          : FontStyle.normal,
                      color: ColorApp.myColorGray,
                    ),
                  ),
                ],
              ),
            ),
            if (showDivision) ...[
              const SizedBox(width: 8.0),
              Expanded(
                flex: 3,
                child: Text(
                  item.divisionLabel,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
            const SizedBox(width: 8.0),
            Container(
              width: 56.0,
              height: 32.0,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: item.color,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Text(
                item.scoreLabel,
                style: const TextStyle(
                  fontSize: 13.0,
                  fontWeight: FontWeight.w700,
                  color: ColorApp.myColorWhite,
                ),
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
