import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../helper/class_colors.dart';
import '../../helper/header/header.dart';
import '../../helper/hints/hint_icon.dart';
import '../../helper/hints/hints.dart';
import '../../helper/my_drawer/my_drawer.dart';
import '../../helper/my_user.dart';
import 'bloc/works_report_bloc.dart';
import 'models/works_report.dart';
import 'repository/report_dictionaries.dart';
import 'repository/works_report_repository.dart';
import 'widgets/month_cell.dart';
import 'widgets/object_works_sheet.dart';
import 'widgets/report_summary_view.dart';

/// Раздел «Отчёты»: что делали на объектах за период.
///
/// Экран собран из приёмов соседних кадров макета — своего кадра у отчётов
/// нет, дизайнер его не рисовал. Матрица месяцев повторяет «Окно с
/// графиками»: строка объекта и цветные ячейки месяцев. Панель фильтров —
/// белая полоса с чипами, как на «Компаниях».
class ReportScreen extends StatelessWidget {
  const ReportScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();
    return BlocProvider<WorksReportBloc>(
      create: (_) => WorksReportBloc(
        initialFilters: ReportFilters(
          dateFrom: DateTime(now.year, 1, 1),
          dateTo: DateTime(now.year, 12, 31),
        ),
        // Год целиком — то, зачем раздел и заводили: показать клиенту, что
        // делалось на объектах за год.
      )..add(const WorksReportRequested()),
      child: const _ReportView(),
    );
  }
}

class _ReportView extends StatefulWidget {
  const _ReportView({Key? key}) : super(key: key);

  @override
  State<_ReportView> createState() => _ReportViewState();
}

class _ReportViewState extends State<_ReportView> {
  /// Справочники фильтров грузятся один раз за жизнь экрана.
  ///
  /// Не в bloc и не в `build`: на этом фронте уже был случай, когда список
  /// объектов запрашивался бесконечно, потому что запрос жил в перерисовке.
  ReportDictionaries _dictionaries = const ReportDictionaries();

  @override
  void initState() {
    super.initState();
    _loadDictionaries();
  }

  Future<void> _loadDictionaries() async {
    final ReportDictionaries loaded =
        await const ReportDictionariesRepository().load();
    if (!mounted) return;
    setState(() => _dictionaries = loaded);
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return Scaffold(
      key: myOpenDrawer,
      drawer: const MyDrawer(),
      backgroundColor: ColorApp.myColorTransparent,
      body: BlocConsumer<WorksReportBloc, WorksReportState>(
        listener: (BuildContext context, WorksReportState state) {
          if (state is WorksReportExportReady) {
            // Ссылка живёт минуту и открывается в новой вкладке: боевой токен
            // в адрес не попадает, а nginx не пишет его в журнал доступа.
            launchUrl(
              Uri.parse(state.url),
              mode: LaunchMode.externalApplication,
            );
          }
          if (state is WorksReportExportFailed) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (BuildContext context, WorksReportState state) {
          return Column(
            children: <Widget>[
              _Header(size: size),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(ColorApp.kPadding),
                  children: <Widget>[
                    _FiltersBar(
                      state: state,
                      dictionaries: _dictionaries,
                    ),
                    const SizedBox(height: 16.0),
                    ..._body(context, state),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Widget> _body(BuildContext context, WorksReportState state) {
    if (state is WorksReportFailure) {
      return <Widget>[
        _Message(
          icon: Icons.cloud_off_outlined,
          title: state.message,
          action: 'Повторить',
          onAction: () => context
              .read<WorksReportBloc>()
              .add(const WorksReportRequested()),
        ),
      ];
    }

    final WorksReport? report = state.report;
    if (report == null) {
      return const <Widget>[
        SizedBox(height: 80.0),
        Center(child: CircularProgressIndicator()),
      ];
    }

    final bool loading = state is WorksReportLoading;

    return <Widget>[
      Opacity(
        opacity: loading ? 0.5 : 1.0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ReportSummaryView(
              report: report,
              onMonthTap: (int year, int month) => _narrowToMonth(
                context,
                state,
                year,
                month,
              ),
            ),
            const SizedBox(height: 20.0),
            if (report.isEmpty)
              const _Message(
                icon: Icons.inbox_outlined,
                title: 'За этот период работ не нашлось',
                subtitle:
                    'Проверьте период и фильтры. Пустой отчёт также значит, '
                    'что на объектах отбора не заведён график ТО.',
              )
            else
              _Matrix(report: report, filters: state.filters),
            if (!report.isEmpty) ...<Widget>[
              const SizedBox(height: 12.0),
              const MonthCellLegend(),
              const SizedBox(height: 12.0),
              _Pager(state: state),
            ],
          ],
        ),
      ),
    ];
  }

  /// Клик по столбику полосы сужает период до этого месяца.
  ///
  /// Тот же отбор, что и счётчик, на который нажали: цифра и то, что
  /// открывается по клику, обязаны совпадать.
  void _narrowToMonth(
    BuildContext context,
    WorksReportState state,
    int year,
    int month,
  ) {
    final DateTime from = DateTime(year, month, 1);
    final DateTime to = DateTime(year, month + 1, 0);
    context.read<WorksReportBloc>().add(
          WorksReportRequested(
            filters: state.filters.copyWith(dateFrom: from, dateTo: to),
          ),
        );
  }
}

class _Header extends StatelessWidget {
  const _Header({Key? key, required this.size}) : super(key: key);

  final Size size;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: ColorApp.kPadding),
      color: ColorApp.myColorWhite,
      height: 70,
      width: double.infinity,
      child: Row(
        children: <Widget>[
          if (size.width <= 1350)
            Row(
              children: <Widget>[
                IconButton(
                  onPressed: () => myOpenDrawer.currentState!.openDrawer(),
                  icon: Icon(Icons.menu, size: size.width > 350 ? 25.0 : 20.0),
                ),
                const SizedBox(width: 10.0),
              ],
            ),
          Text(
            'Отчеты',
            style: TextStyle(
              fontSize: size.width > 350 ? 25.0 : 18.0,
              fontWeight: size.width > 350 ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          const HintIcon(id: HintIds.reportWorkKinds, size: 18.0),
          const HintIcon(id: HintIds.reportRowOpens, size: 18.0),
          const Spacer(),
          SizedBox(width: size.width > 500 ? 40.0 : 10.0),
          const MyUser(),
        ],
      ),
    );
  }
}

/// Панель фильтров: пресеты периода и кнопки выгрузки.
///
/// Пресетов в макете нет — такого элемента нет нигде, — но период
/// произвольными датами без быстрых кнопок означает четыре клика ради
/// «за этот год», а это главный сценарий раздела.
class _FiltersBar extends StatelessWidget {
  const _FiltersBar({
    Key? key,
    required this.state,
    required this.dictionaries,
  }) : super(key: key);

  final WorksReportState state;
  final ReportDictionaries dictionaries;

  @override
  Widget build(BuildContext context) {
    final ReportFilters filters = state.filters;
    final DateTime now = DateTime.now();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: ColorApp.myColorWhite,
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: <Widget>[
              _PresetChip(
                label: 'Год',
                selected: _isYear(filters, now.year),
                onTap: () => _apply(
                  context,
                  DateTime(now.year, 1, 1),
                  DateTime(now.year, 12, 31),
                ),
              ),
              _PresetChip(
                label: 'Квартал',
                selected: false,
                onTap: () {
                  final int firstMonth = ((now.month - 1) ~/ 3) * 3 + 1;
                  _apply(
                    context,
                    DateTime(now.year, firstMonth, 1),
                    DateTime(now.year, firstMonth + 3, 0),
                  );
                },
              ),
              _PresetChip(
                label: 'Месяц',
                selected: false,
                onTap: () => _apply(
                  context,
                  DateTime(now.year, now.month, 1),
                  DateTime(now.year, now.month + 1, 0),
                ),
              ),
              _PresetChip(
                label: _periodLabel(filters),
                selected: true,
                icon: Icons.date_range_outlined,
                onTap: () => _pickRange(context, filters),
              ),
              if (dictionaries.companies.isNotEmpty)
                _FilterDropdown(
                  hint: 'Компания',
                  items: dictionaries.companies,
                  value: filters.companyId,
                  onChanged: (int? id) => _applyFilters(
                    context,
                    filters.copyWith(companyId: id, clearCompany: id == null),
                  ),
                ),
              if (dictionaries.organizations.isNotEmpty)
                _FilterDropdown(
                  hint: 'Организация',
                  items: dictionaries.organizations,
                  value: filters.organizationId,
                  onChanged: (int? id) => _applyFilters(
                    context,
                    filters.copyWith(
                      organizationId: id,
                      clearOrganization: id == null,
                    ),
                  ),
                ),
              if (dictionaries.divisions.isNotEmpty)
                _FilterDropdown(
                  hint: 'Участок',
                  items: dictionaries.divisions,
                  value: filters.divisionId,
                  onChanged: (int? id) => _applyFilters(
                    context,
                    filters.copyWith(divisionId: id, clearDivision: id == null),
                  ),
                ),
              const SizedBox(width: 8.0),
              _ExportButton(
                icon: Icons.table_view_outlined,
                label: 'Excel',
                onTap: () => context
                    .read<WorksReportBloc>()
                    .add(const WorksReportExportRequested(format: 'xlsx')),
              ),
              _ExportButton(
                icon: Icons.picture_as_pdf_outlined,
                label: 'PDF',
                onTap: () => context
                    .read<WorksReportBloc>()
                    .add(const WorksReportExportRequested(format: 'pdf')),
              ),
              const HintIcon(id: HintIds.reportExport),
            ],
          ),
          if (state.report?.period.widerThanAsked == true) ...<Widget>[
            const SizedBox(height: 8.0),
            Row(
              children: <Widget>[
                Flexible(
                  child: Text(
                    _widerNote(state.report!.period),
                    style: const TextStyle(
                      fontSize: 12.0,
                      color: ColorApp.myColorGrayText,
                    ),
                  ),
                ),
                const HintIcon(id: HintIds.reportPeriodBoundaries),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Пояснение про разные границы у ТО и у заявок.
  ///
  /// Без него человек увидит ТО за март в отчёте «с 15 марта» и решит, что
  /// мы ошиблись в счёте.
  String _widerNote(ReportPeriod period) {
    final String from =
        '${monthFullNames[period.monthFrom.month - 1]} ${period.monthFrom.year}';
    final String to =
        '${monthFullNames[period.monthTo.month - 1]} ${period.monthTo.year}';
    return 'Заявки посчитаны точно по датам, плановые ТО — по месяцам '
        'целиком: $from — $to.';
  }

  bool _isYear(ReportFilters filters, int year) =>
      filters.dateFrom.year == year &&
      filters.dateFrom.month == 1 &&
      filters.dateFrom.day == 1 &&
      filters.dateTo.month == 12 &&
      filters.dateTo.day == 31;

  String _periodLabel(ReportFilters filters) =>
      '${_short(filters.dateFrom)} — ${_short(filters.dateTo)}';

  String _short(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}.'
      '${date.month.toString().padLeft(2, '0')}.${date.year}';

  void _applyFilters(BuildContext context, ReportFilters filters) {
    context
        .read<WorksReportBloc>()
        .add(WorksReportRequested(filters: filters));
  }

  void _apply(BuildContext context, DateTime from, DateTime to) {
    context.read<WorksReportBloc>().add(
          WorksReportRequested(
            filters: context
                .read<WorksReportBloc>()
                .state
                .filters
                .copyWith(dateFrom: from, dateTo: to),
          ),
        );
  }

  Future<void> _pickRange(BuildContext context, ReportFilters filters) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2015, 1, 1),
      lastDate: DateTime(DateTime.now().year + 1, 12, 31),
      initialDateRange: DateTimeRange(
        start: filters.dateFrom,
        end: filters.dateTo,
      ),
      helpText: 'Отчётный период',
      saveText: 'Готово',
    );
    if (picked != null) {
      _apply(context, picked.start, picked.end);
    }
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({
    Key? key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  }) : super(key: key);

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: selected ? ColorApp.myColorGreenLine : ColorApp.myColorWhite,
          borderRadius: BorderRadius.circular(6.0),
          border: Border.all(color: ColorApp.myColorGreenAuth),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (icon != null) ...<Widget>[
              Icon(icon, size: 15.0, color: ColorApp.myColorGreenAuth),
              const SizedBox(width: 6.0),
            ],
            Text(label, style: const TextStyle(fontSize: 13.0)),
          ],
        ),
      ),
    );
  }
}

/// Выпадающий список фильтра.
///
/// Оформлен чипом с зелёной обводкой — так фильтры нарисованы в макете на
/// кадрах «Компании» и «Графики». Первый пункт всегда «все»: выйти из
/// фильтра должно быть так же просто, как войти.
class _FilterDropdown extends StatelessWidget {
  const _FilterDropdown({
    Key? key,
    required this.hint,
    required this.items,
    required this.value,
    required this.onChanged,
  }) : super(key: key);

  final String hint;
  final List<DictionaryItem> items;
  final int? value;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    // Значение, которого нет в списке, роняет DropdownButton. Так бывает,
    // когда область видимости человека уже, чем сохранённый отбор.
    final bool known =
        value != null && items.any((DictionaryItem item) => item.id == value);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0),
      decoration: BoxDecoration(
        color: known ? ColorApp.myColorGreenLine : ColorApp.myColorWhite,
        borderRadius: BorderRadius.circular(6.0),
        border: Border.all(color: ColorApp.myColorGreenAuth),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int?>(
          value: known ? value : null,
          hint: Text(hint, style: const TextStyle(fontSize: 13.0)),
          isDense: true,
          borderRadius: BorderRadius.circular(8.0),
          icon: const Icon(Icons.arrow_drop_down,
              color: ColorApp.myColorGreenAuth),
          items: <DropdownMenuItem<int?>>[
            DropdownMenuItem<int?>(
              value: null,
              child: Text('$hint: все', style: const TextStyle(fontSize: 13.0)),
            ),
            ...items.map(
              (DictionaryItem item) => DropdownMenuItem<int?>(
                value: item.id,
                child: Text(
                  item.title,
                  style: const TextStyle(fontSize: 13.0),
                  overflow: TextOverflow.ellipsis,
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

class _ExportButton extends StatelessWidget {
  const _ExportButton({
    Key? key,
    required this.icon,
    required this.label,
    required this.onTap,
  }) : super(key: key);

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18.0),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: ColorApp.myColorGreenAuth,
        side: const BorderSide(color: ColorApp.myColorGreenAuth),
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6.0),
        ),
      ),
    );
  }
}

/// Матрица «объект × месяц».
///
/// Повторяет кадр «Окно с графиками»: слева объект и адрес, справа ячейки
/// месяцев. Прокрутка по горизонтали нужна на узких экранах — двенадцать
/// месяцев в телефон не влезают, а резать их было бы враньём.
class _Matrix extends StatelessWidget {
  const _Matrix({Key? key, required this.report, required this.filters})
      : super(key: key);

  final WorksReport report;

  /// Тот же отбор уходит в шторку: раскрытая строка обязана показывать работы
  /// за тот же период, что и ячейки рядом с ней.
  final ReportFilters filters;

  static const double _monthWidth = 34.0;
  static const double _objectWidth = 260.0;

  @override
  Widget build(BuildContext context) {
    final int monthCount = report.months.length;

    return Container(
      decoration: BoxDecoration(
        color: ColorApp.myColorWhite,
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: _objectWidth + _monthWidth * monthCount + 60.0,
          child: Column(
            children: <Widget>[
              _HeaderRow(report: report),
              ...report.items.map(
                (ReportObjectRow row) =>
                    _ObjectRow(row: row, filters: filters),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({Key? key, required this.report}) : super(key: key);

  final WorksReport report;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: ColorApp.myColorGrayBorder),
        ),
      ),
      child: Row(
        children: <Widget>[
          const SizedBox(
            width: _Matrix._objectWidth,
            child: Text(
              'Объект',
              style: TextStyle(
                fontSize: 12.0,
                color: ColorApp.myColorGrayText,
              ),
            ),
          ),
          ...report.months.map(
            (MonthTotals month) => SizedBox(
              width: _Matrix._monthWidth,
              child: Center(
                child: Text(
                  monthShortNames[month.month - 1],
                  style: const TextStyle(
                    fontSize: 11.0,
                    color: ColorApp.myColorGrayText,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(
            width: 60.0,
            child: Text(
              'ТО',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12.0,
                color: ColorApp.myColorGrayText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ObjectRow extends StatelessWidget {
  const _ObjectRow({Key? key, required this.row, required this.filters})
      : super(key: key);

  final ReportObjectRow row;
  final ReportFilters filters;

  void _open(BuildContext context) => ObjectWorksSheet.show(
        context,
        row: row,
        filters: filters,
      );

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _open(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: ColorApp.myColorGrayShadow),
          ),
        ),
        child: Row(
          children: <Widget>[
            SizedBox(
              width: _Matrix._objectWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    row.objectLabel,
                    style: const TextStyle(
                      fontSize: 13.0,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  // Адрес второй строкой: по «Лифт 12» непонятно, о каком доме
                  // речь, а отчёт читают именно по домам.
                  Text(
                    row.addressLabel,
                    style: const TextStyle(
                      fontSize: 11.0,
                      color: ColorApp.myColorGrayText,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            ...row.months.map(
              (MonthCell cell) => SizedBox(
                width: _Matrix._monthWidth,
                child: MonthCellTile(
                  cell: cell,
                  onTap: () => _open(context),
                ),
              ),
            ),
            SizedBox(
              width: 60.0,
              child: Text(
                row.maintenanceSummary,
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 12.0),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pager extends StatelessWidget {
  const _Pager({Key? key, required this.state}) : super(key: key);

  final WorksReportState state;

  @override
  Widget build(BuildContext context) {
    if (state is! WorksReportLoaded) return const SizedBox.shrink();
    final WorksReportLoaded loaded = state as WorksReportLoaded;

    return Row(
      children: <Widget>[
        Text(
          loaded.pageLabel,
          style: const TextStyle(
            fontSize: 12.0,
            color: ColorApp.myColorGrayText,
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: loaded.hasPrevious
              ? () => context.read<WorksReportBloc>().add(
                    WorksReportRequested(
                      offset: loaded.offset - loaded.limit,
                      limit: loaded.limit,
                    ),
                  )
              : null,
          icon: const Icon(Icons.chevron_left, size: 22.0),
        ),
        IconButton(
          onPressed: loaded.hasNext
              ? () => context.read<WorksReportBloc>().add(
                    WorksReportRequested(
                      offset: loaded.offset + loaded.limit,
                      limit: loaded.limit,
                    ),
                  )
              : null,
          icon: const Icon(Icons.chevron_right, size: 22.0),
        ),
      ],
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    Key? key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
    this.onAction,
  }) : super(key: key);

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 40.0),
      decoration: BoxDecoration(
        color: ColorApp.myColorWhite,
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Column(
        children: <Widget>[
          Icon(icon, size: 36.0, color: ColorApp.myColorGrayText),
          const SizedBox(height: 12.0),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15.0),
          ),
          if (subtitle != null) ...<Widget>[
            const SizedBox(height: 6.0),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12.0,
                color: ColorApp.myColorGrayText,
              ),
            ),
          ],
          if (action != null) ...<Widget>[
            const SizedBox(height: 16.0),
            OutlinedButton(onPressed: onAction, child: Text(action!)),
          ],
        ],
      ),
    );
  }
}
