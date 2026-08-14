import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../helper/calendar/month_picker.dart';
import '../../../helper/class_colors.dart';
import 'bloc/breakdowns_bloc.dart';
import 'models/breakdowns_report.dart';
import 'repository/breakdowns_repository.dart';
import 'widgets/export_report_button.dart';
import 'widgets/object_orders_sheet.dart';
import 'widgets/severity_chips.dart';

/// Экран «Подробнее» к карточке «Топ поломок».
///
/// Здесь живёт то, что не поместилось в карточку на главной: все колонки,
/// фильтры по участку и клиенту, сортировка по любому столбцу и сравнение с
/// прошлым месяцем.
///
/// Открывается обычным `Navigator.push`, а не через `IntTest.indexScreens`.
/// Это ветка вглубь от главной, а не пункт бокового меню: возврат — кнопкой
/// «назад», состояние главной при этом сохраняется.
class BreakdownsDetailsScreen extends StatelessWidget {
  const BreakdownsDetailsScreen({Key? key, required this.month})
      : super(key: key);

  final DateTime month;

  /// Столько объектов запрашиваем у бэкенда. Сортировка и фильтрация идут
  /// по загруженному списку, поэтому он должен приезжать целиком; 200 —
  /// потолок, который принимает ручка.
  static const int limit = 200;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<BreakdownsBloc>(
      create: (_) => BreakdownsBloc()
        ..add(
          BreakdownsRequested(month: month, limit: limit, withPrevious: true),
        ),
      child: _DetailsView(initialMonth: month),
    );
  }
}

/// По какому столбцу сортируем.
enum _SortColumn { count, reaction, delta, object, client }

class _DetailsView extends StatefulWidget {
  const _DetailsView({Key? key, required this.initialMonth}) : super(key: key);

  final DateTime initialMonth;

  @override
  State<_DetailsView> createState() => _DetailsViewState();
}

class _DetailsViewState extends State<_DetailsView> {
  late DateTime _month = widget.initialMonth;

  int? _divisionId;
  int? _organizationId;

  _SortColumn _sort = _SortColumn.count;
  bool _descending = true;

  final BreakdownsRepository _repository = const BreakdownsRepository();
  List<NamedRef> _divisions = const <NamedRef>[];
  List<NamedRef> _organizations = const <NamedRef>[];

  @override
  void initState() {
    super.initState();
    _loadFilterDictionaries();
  }

  /// Справочники для выпадающих списков.
  ///
  /// Если они не загрузились, экран продолжает работать — просто без
  /// фильтров. Падать из-за необязательной части незачем.
  Future<void> _loadFilterDictionaries() async {
    try {
      final List<NamedRef> divisions = await _repository.fetchDivisions();
      final List<NamedRef> organizations =
          await _repository.fetchOrganizations();
      if (!mounted) return;
      setState(() {
        _divisions = divisions;
        _organizations = organizations;
      });
    } on BreakdownsException {
      // Молча: фильтры не появятся, таблица останется полной.
    }
  }

  void _reload() {
    context.read<BreakdownsBloc>().add(
          BreakdownsRequested(
            month: _month,
            limit: BreakdownsDetailsScreen.limit,
            divisionId: _divisionId,
            organizationId: _organizationId,
            withPrevious: true,
          ),
        );
  }

  void _onSort(_SortColumn column) {
    setState(() {
      if (_sort == column) {
        _descending = !_descending;
      } else {
        _sort = column;
        // Числовые столбцы человек почти всегда хочет видеть «сначала
        // большие», а текстовые — по алфавиту.
        _descending = column != _SortColumn.object && column != _SortColumn.client;
      }
    });
  }

  List<BreakdownObject> _sorted(List<BreakdownObject> items) {
    final List<BreakdownObject> result = List<BreakdownObject>.of(items);
    int compare(BreakdownObject a, BreakdownObject b) {
      switch (_sort) {
        case _SortColumn.count:
          return a.breakdownCount.compareTo(b.breakdownCount);
        case _SortColumn.reaction:
          // Объекты без времени реакции держим внизу при любом направлении:
          // «нет данных» — это не «быстрее всех».
          if (a.avgReactionHours == null && b.avgReactionHours == null) return 0;
          if (a.avgReactionHours == null) return _descending ? -1 : 1;
          if (b.avgReactionHours == null) return _descending ? 1 : -1;
          return a.avgReactionHours!.compareTo(b.avgReactionHours!);
        case _SortColumn.delta:
          return (a.delta ?? 0).compareTo(b.delta ?? 0);
        case _SortColumn.object:
          return a.title.toLowerCase().compareTo(b.title.toLowerCase());
        case _SortColumn.client:
          return (a.client ?? '').toLowerCase().compareTo(
                (b.client ?? '').toLowerCase(),
              );
      }
    }

    result.sort((BreakdownObject a, BreakdownObject b) {
      final int value = compare(a, b);
      return _descending ? -value : value;
    });
    return result;
  }

  void _openOrders(BreakdownObject item) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ObjectOrdersSheet(item: item, month: _month),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorApp.myColorTransparent,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: ColorApp.myColorBlack,
        elevation: 0,
        title: const Text(
          'Топ поломок',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          BlocBuilder<BreakdownsBloc, BreakdownsState>(
            builder: (BuildContext context, BreakdownsState state) {
              return Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: MonthPicker(
                  value: _month,
                  enabled: state is! BreakdownsLoading,
                  onChanged: (DateTime value) {
                    setState(() => _month = value);
                    _reload();
                  },
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Filters(
            divisions: _divisions,
            organizations: _organizations,
            divisionId: _divisionId,
            organizationId: _organizationId,
            onDivision: (int? value) {
              setState(() => _divisionId = value);
              _reload();
            },
            onOrganization: (int? value) {
              setState(() => _organizationId = value);
              _reload();
            },
          ),
          Expanded(
            child: BlocBuilder<BreakdownsBloc, BreakdownsState>(
              builder: (BuildContext context, BreakdownsState state) {
                if (state is BreakdownsFailure) {
                  return _Centered(
                    icon: Icons.cloud_off_outlined,
                    text: state.message,
                    actionLabel: 'Повторить',
                    onAction: _reload,
                  );
                }
                if (state is! BreakdownsLoaded) {
                  return const Center(
                    child: SizedBox(
                      width: 28.0,
                      height: 28.0,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: ColorApp.myColorGreenAuth,
                      ),
                    ),
                  );
                }
                if (state.report.isEmpty) {
                  return const _Centered(
                    icon: Icons.check_circle_outline,
                    text: 'За этот месяц поломок нет',
                  );
                }
                return _Table(
                  report: state.report,
                  items: _sorted(state.report.items),
                  sort: _sort,
                  descending: _descending,
                  onSort: _onSort,
                  onTap: _openOrders,
                  // Тот же отбор уходит в выгрузку: файл обязан совпадать с
                  // тем, что на экране.
                  month: _month,
                  divisionId: _divisionId,
                  organizationId: _organizationId,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Filters extends StatelessWidget {
  const _Filters({
    Key? key,
    required this.divisions,
    required this.organizations,
    required this.divisionId,
    required this.organizationId,
    required this.onDivision,
    required this.onOrganization,
  }) : super(key: key);

  final List<NamedRef> divisions;
  final List<NamedRef> organizations;
  final int? divisionId;
  final int? organizationId;
  final ValueChanged<int?> onDivision;
  final ValueChanged<int?> onOrganization;

  @override
  Widget build(BuildContext context) {
    if (divisions.isEmpty && organizations.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20.0, 0, 20.0, 12.0),
      child: Wrap(
        spacing: 12.0,
        runSpacing: 8.0,
        children: [
          if (divisions.isNotEmpty)
            _Dropdown(
              hint: 'Все участки',
              value: divisionId,
              items: divisions,
              onChanged: onDivision,
            ),
          if (organizations.isNotEmpty)
            _Dropdown(
              hint: 'Все клиенты',
              value: organizationId,
              items: organizations,
              onChanged: onOrganization,
            ),
        ],
      ),
    );
  }
}

class _Dropdown extends StatelessWidget {
  const _Dropdown({
    Key? key,
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
  }) : super(key: key);

  final String hint;
  final int? value;
  final List<NamedRef> items;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 260.0),
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: ColorApp.myColorGrayBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int?>(
          value: value,
          isExpanded: true,
          hint: Text(hint, style: const TextStyle(fontSize: 14.0)),
          items: <DropdownMenuItem<int?>>[
            // Первый пункт снимает фильтр: без него выбранное значение
            // некуда было бы сбросить.
            DropdownMenuItem<int?>(
              value: null,
              child: Text(hint, style: const TextStyle(fontSize: 14.0)),
            ),
            ...items.map(
              (NamedRef ref) => DropdownMenuItem<int?>(
                value: ref.id,
                child: Text(
                  ref.title,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14.0),
                ),
              ),
            ),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _Table extends StatefulWidget {
  const _Table({
    Key? key,
    required this.report,
    required this.items,
    required this.sort,
    required this.descending,
    required this.onSort,
    required this.onTap,
    required this.month,
    required this.divisionId,
    required this.organizationId,
  }) : super(key: key);

  final BreakdownsReport report;
  final List<BreakdownObject> items;
  final _SortColumn sort;
  final bool descending;
  final ValueChanged<_SortColumn> onSort;
  final ValueChanged<BreakdownObject> onTap;
  final DateTime month;
  final int? divisionId;
  final int? organizationId;

  /// Ниже этой ширины десять колонок превращаются в кашу из переносов.
  /// Уже — таблица едет вбок, шире — растягивается на всю карточку.
  static const double minWidth = 1000.0;

  @override
  State<_Table> createState() => _TableState();
}

class _TableState extends State<_Table> {
  /// Свой контроллер нужен полосе прокрутки: без него `Scrollbar` не знает,
  /// за каким списком следить, и на вебе колонки справа просто обрезаются
  /// без единого намёка, что таблицу можно сдвинуть.
  final ScrollController _horizontal = ScrollController();

  @override
  void dispose() {
    _horizontal.dispose();
    super.dispose();
  }

  BreakdownsReport get report => widget.report;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20.0),
      children: [
        /// Свод, итог и выгрузка
        Row(
          children: [
            Expanded(
              child: Wrap(
                spacing: 16.0,
                runSpacing: 8.0,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'Поломок ${report.totalBreakdowns} на ${report.objectsAffected} объектах',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  SeverityChips(items: report.severitySummary),
                ],
              ),
            ),
            const SizedBox(width: 12.0),
            ExportReportButton(
              month: widget.month,
              divisionId: widget.divisionId,
              organizationId: widget.organizationId,
            ),
          ],
        ),
        const SizedBox(height: 16.0),

        /// Таблица карточкой, как виджеты на главной: до этого она лежала
        /// белыми строками прямо на сером фоне и выглядела недоделанной.
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15.0),
            boxShadow: const [
              BoxShadow(color: ColorApp.myColorGrayBorder, blurRadius: 6.0),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              /// Горизонтальная прокрутка: колонок много, на планшете и
              /// телефоне они не помещаются. Пусть таблица едет вбок, а не
              /// сжимается в кашу. На широком мониторе, наоборот, тянем её на
              /// всю ширину — иначе справа остаётся пустая полоса в треть
              /// экрана.
              final double width =
                  math.max(_Table.minWidth, constraints.maxWidth);

              return Scrollbar(
                controller: _horizontal,
                thumbVisibility: true,
                child: SingleChildScrollView(
                  controller: _horizontal,
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: width),
                    // Полоса прокрутки лежит поверх содержимого, и без этого
                    // отступа она перечёркивает последнюю строку таблицы.
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: _dataTable(context),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _dataTable(BuildContext context) {
    final List<BreakdownObject> items = widget.items;
    final ValueChanged<_SortColumn> onSort = widget.onSort;

    return DataTable(
      headingRowColor: MaterialStateProperty.all(Colors.white),
      // Строку выбирать нечем и незачем: клик по ней открывает заявки
      // объекта. Без этого флага DataTable рисует слева колонку с
      // чекбоксами, которые ничего не выделяют.
      showCheckboxColumn: false,
      sortColumnIndex: _sortIndex,
      sortAscending: !widget.descending,
      columns: [
        DataColumn(
          label: const Text('Объект'),
          onSort: (_, __) => onSort(_SortColumn.object),
        ),
        const DataColumn(label: Text('Адрес')),
        DataColumn(
          label: const Text('Клиент'),
          onSort: (_, __) => onSort(_SortColumn.client),
        ),
        const DataColumn(label: Text('Участок')),
        const DataColumn(label: Text('Модель')),
        const DataColumn(label: Text('Механик')),
        DataColumn(
          label: const Text('Поломок'),
          numeric: true,
          onSort: (_, __) => onSort(_SortColumn.count),
        ),
        const DataColumn(label: Text('По тяжести')),
        DataColumn(
          label: const Text('Реакция'),
          numeric: true,
          onSort: (_, __) => onSort(_SortColumn.reaction),
        ),
        DataColumn(
          label: const Text('К прошлому'),
          numeric: true,
          onSort: (_, __) => onSort(_SortColumn.delta),
        ),
      ],
      rows: items
          .map((BreakdownObject item) => _row(context, item))
          .toList(growable: false),
    );
  }

  int get _sortIndex {
    switch (widget.sort) {
      case _SortColumn.object:
        return 0;
      case _SortColumn.client:
        return 2;
      case _SortColumn.count:
        return 6;
      case _SortColumn.reaction:
        return 8;
      case _SortColumn.delta:
        return 9;
    }
  }

  DataRow _row(BuildContext context, BreakdownObject item) {
    return DataRow(
      onSelectChanged: (_) => widget.onTap(item),
      cells: [
        DataCell(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                item.title,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              if (item.registrationNumber != null)
                Text(
                  '№ ${item.registrationNumber}',
                  style: const TextStyle(
                    fontSize: 11.0,
                    color: ColorApp.myColorGrayText,
                  ),
                ),
            ],
          ),
        ),
        DataCell(_text(item.address)),
        DataCell(_text(item.client)),
        DataCell(_text(item.division)),
        DataCell(_text(item.factoryModel)),
        DataCell(_text(item.responsibleMechanic, empty: 'Не назначен')),
        DataCell(
          Text(
            '${item.breakdownCount}',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        DataCell(SeverityChips(items: item.severity, compact: true)),
        DataCell(_ReactionCell(item: item)),
        DataCell(_DeltaCell(delta: item.delta)),
      ],
    );
  }

  Widget _text(String? value, {String empty = '—'}) {
    final bool isEmpty = value == null || value.trim().isEmpty;
    return Text(
      isEmpty ? empty : value,
      style: TextStyle(
        color: isEmpty ? ColorApp.myColorGrayText : ColorApp.myColorBlack,
      ),
    );
  }
}

/// Среднее время реакции и по скольким заявкам оно посчитано.
///
/// Число заявок показываем рядом намеренно: «2 ч» по одной заявке из сорока
/// и «2 ч» по сорока — разные утверждения, а выглядят одинаково.
class _ReactionCell extends StatelessWidget {
  const _ReactionCell({Key? key, required this.item}) : super(key: key);

  final BreakdownObject item;

  @override
  Widget build(BuildContext context) {
    if (item.avgReactionHours == null || item.reactedCount == 0) {
      return const Text('—', style: TextStyle(color: ColorApp.myColorGrayText));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('${item.avgReactionHours} ч'),
        Text(
          'по ${item.reactedCount} из ${item.breakdownCount}',
          style: const TextStyle(
            fontSize: 11.0,
            color: ColorApp.myColorGrayText,
          ),
        ),
      ],
    );
  }
}

class _DeltaCell extends StatelessWidget {
  const _DeltaCell({Key? key, required this.delta}) : super(key: key);

  final int? delta;

  @override
  Widget build(BuildContext context) {
    if (delta == null) {
      return const Text('—', style: TextStyle(color: ColorApp.myColorGrayText));
    }
    if (delta == 0) {
      return const Text(
        'без изменений',
        style: TextStyle(fontSize: 12.0, color: ColorApp.myColorGrayText),
      );
    }
    // Больше поломок — хуже, поэтому рост красный, а не зелёный.
    final bool worse = delta! > 0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          worse ? Icons.arrow_upward : Icons.arrow_downward,
          size: 14.0,
          color: worse ? ColorApp.myColorRed : ColorApp.myColorGreenAuth,
        ),
        const SizedBox(width: 2.0),
        Text(
          '${delta!.abs()}',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: worse ? ColorApp.myColorRed : ColorApp.myColorGreenAuth,
          ),
        ),
      ],
    );
  }
}

class _Centered extends StatelessWidget {
  const _Centered({
    Key? key,
    required this.icon,
    required this.text,
    this.actionLabel,
    this.onAction,
  }) : super(key: key);

  final IconData icon;
  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 36.0, color: ColorApp.myColorGrayText),
          const SizedBox(height: 8.0),
          Text(text, style: const TextStyle(color: ColorApp.myColorGray)),
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
