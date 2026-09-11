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
import 'widgets/defect_acts_sheet.dart';
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
  const ReportScreen({
    Key? key,
    this.drawer = const MyDrawer(),
    this.repository = const WorksReportRepository(),
  }) : super(key: key);

  /// Источник данных. Подменяется фикстурой в наброске
  /// `dev/report_preview.dart` и в тестах; в приложении — живой.
  final WorksReportRepository repository;

  /// Боковое меню экрана. Раздел общий для админа и прораба, а меню у них
  /// разные: своё жёстко прошитое `MyDrawer` подменяло прорабу бургер на
  /// админский. Передаём меню снаружи — тем же приёмом, что и лента сданных.
  final Widget drawer;

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();
    return BlocProvider<WorksReportBloc>(
      create: (_) => WorksReportBloc(
        repository: repository,
        initialFilters: ReportFilters(
          dateFrom: DateTime(now.year, 1, 1),
          dateTo: DateTime(now.year, 12, 31),
        ),
        // Год целиком — то, зачем раздел и заводили: показать клиенту, что
        // делалось на объектах за год.
      )..add(const WorksReportRequested()),
      child: _ReportView(drawer: drawer, repository: repository),
    );
  }
}

class _ReportView extends StatefulWidget {
  const _ReportView({
    Key? key,
    required this.drawer,
    required this.repository,
  }) : super(key: key);

  final Widget drawer;
  final WorksReportRepository repository;

  @override
  State<_ReportView> createState() => _ReportViewState();
}

class _ReportViewState extends State<_ReportView> {
  /// Справочники фильтров грузятся один раз за жизнь экрана.
  ///
  /// Не в bloc и не в `build`: на этом фронте уже был случай, когда список
  /// объектов запрашивался бесконечно, потому что запрос жил в перерисовке.
  ReportDictionaries _dictionaries = const ReportDictionaries();

  /// Отмеченные лифты: id объектов по всем страницам отбора.
  ///
  /// Живёт на экране, а не в bloc: это не данные отчёта, а то, что человек
  /// собрался выгрузить. Смена отбора сбрасывает выбор — иначе в PDF уедут
  /// лифты, которых на экране уже нет.
  final Set<int> _selected = <int>{};

  /// «Выбрать все» — весь отбор целиком, включая страницы, которых не
  /// листали. Тогда выгрузка идёт без списка id, как раньше.
  bool _allSelected = false;

  /// Галочка «с фотографиями» для PDF. По умолчанию выключена: годовой
  /// отчёт с фото весит сотни мегабайт.
  bool _withPhotos = false;

  ReportFilters? _selectionFilters;

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
      drawer: widget.drawer,
      backgroundColor: ColorApp.myColorTransparent,
      body: BlocConsumer<WorksReportBloc, WorksReportState>(
        listener: (BuildContext context, WorksReportState state) {
          if (_selectionFilters != null &&
              _selectionFilters != state.filters &&
              (_selected.isNotEmpty || _allSelected)) {
            setState(_clearSelection);
          }
          _selectionFilters = state.filters;
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
                      withPhotos: _withPhotos,
                      onWithPhotosChanged: (bool value) =>
                          setState(() => _withPhotos = value),
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
              onDefectsTap: () => DefectActsSheet.show(
                context,
                filters: state.filters,
                period: report.period,
                expected: report.summary.counts.defects,
                repository: widget.repository,
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
            else ...<Widget>[
              _SelectionBar(
                selectedCount: _allSelected
                    ? report.totalObjects
                    : _selected.length,
                total: report.totalObjects,
                withPhotos: _withPhotos,
                onClear: () => setState(_clearSelection),
                onExport: (String format) => _exportSelected(
                  context,
                  format,
                ),
              ),
              _Matrix(
                report: report,
                filters: state.filters,
                repository: widget.repository,
                selected: _selected,
                allSelected: _allSelected,
                onToggle: (int objectId) => setState(() => _toggle(objectId)),
                onToggleAll: () => setState(_toggleAll),
              ),
            ],
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

  void _clearSelection() {
    _selected.clear();
    _allSelected = false;
  }

  void _toggle(int objectId) {
    if (_allSelected) {
      // Снятая галочка при «всех» превращает выбор в явный список видимых
      // строк без этой — так человек видит ровно то, что уедет в файл.
      _allSelected = false;
      final WorksReport? report =
          context.read<WorksReportBloc>().state.report;
      _selected.addAll(
        (report?.items ?? const <ReportObjectRow>[])
            .map((ReportObjectRow row) => row.objectId),
      );
    }
    if (!_selected.remove(objectId)) _selected.add(objectId);
  }

  void _toggleAll() {
    if (_allSelected || _selected.isNotEmpty) {
      _clearSelection();
    } else {
      _allSelected = true;
    }
  }

  /// Выгрузка по отмеченным. «Все» уходит без списка — это тот же файл по
  /// всему отбору, что и кнопка в панели фильтров.
  void _exportSelected(BuildContext context, String format) {
    context.read<WorksReportBloc>().add(
          WorksReportExportRequested(
            format: format,
            withPhotos: format == 'pdf' && _withPhotos,
            objectIds: _allSelected ? null : (_selected.toList()..sort()),
          ),
        );
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
    required this.withPhotos,
    required this.onWithPhotosChanged,
  }) : super(key: key);

  final WorksReportState state;
  final ReportDictionaries dictionaries;
  final bool withPhotos;
  final ValueChanged<bool> onWithPhotosChanged;

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
                onTap: () => context.read<WorksReportBloc>().add(
                      WorksReportExportRequested(
                        format: 'pdf',
                        withPhotos: withPhotos,
                      ),
                    ),
              ),
              _PhotosToggle(value: withPhotos, onChanged: onWithPhotosChanged),
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

/// Галочка «с фотографиями» рядом с кнопкой PDF.
///
/// Компактная, в одну строку с кнопками: `CheckboxListTile` растянулся бы
/// на всю ширину панели и разорвал ряд.
class _PhotosToggle extends StatelessWidget {
  const _PhotosToggle({
    Key? key,
    required this.value,
    required this.onChanged,
  }) : super(key: key);

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(6.0),
      child: Padding(
        padding: const EdgeInsets.only(right: 8.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SizedBox(
              width: 32.0,
              height: 32.0,
              child: Checkbox(
                value: value,
                activeColor: ColorApp.myColorGreenAuth,
                onChanged: (bool? checked) => onChanged(checked ?? false),
              ),
            ),
            const Text(
              'С фотографиями',
              style: TextStyle(fontSize: 13.0),
            ),
          ],
        ),
      ),
    );
  }
}

/// Полоса над матрицей: сколько лифтов отмечено и выгрузка по ним.
///
/// Появляется только при непустом выборе — пока галочек нет, кнопки в панели
/// фильтров выгружают весь отбор, и вторая пара кнопок только путала бы.
class _SelectionBar extends StatelessWidget {
  const _SelectionBar({
    Key? key,
    required this.selectedCount,
    required this.total,
    required this.withPhotos,
    required this.onClear,
    required this.onExport,
  }) : super(key: key);

  final int selectedCount;
  final int total;
  final bool withPhotos;
  final VoidCallback onClear;
  final ValueChanged<String> onExport;

  @override
  Widget build(BuildContext context) {
    if (selectedCount == 0) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 8.0),
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: ColorApp.myColorGreenAuth.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(
          color: ColorApp.myColorGreenAuth.withValues(alpha: 0.4),
        ),
      ),
      child: Wrap(
        spacing: 8.0,
        runSpacing: 8.0,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          Text(
            selectedCount == total
                ? 'Выбраны все $total'
                : 'Выбрано $selectedCount из $total',
            style: const TextStyle(
              fontSize: 13.0,
              fontWeight: FontWeight.w500,
            ),
          ),
          TextButton(
            onPressed: onClear,
            style: TextButton.styleFrom(
              foregroundColor: ColorApp.myColorGrayText,
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
            ),
            child: const Text('Снять'),
          ),
          _ExportButton(
            icon: Icons.table_view_outlined,
            label: 'Excel по выбранным',
            onTap: () => onExport('xlsx'),
          ),
          _ExportButton(
            icon: Icons.picture_as_pdf_outlined,
            label: withPhotos ? 'PDF по выбранным, с фото' : 'PDF по выбранным',
            onTap: () => onExport('pdf'),
          ),
        ],
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
  const _Matrix({
    Key? key,
    required this.report,
    required this.filters,
    required this.repository,
    required this.selected,
    required this.allSelected,
    required this.onToggle,
    required this.onToggleAll,
  }) : super(key: key);

  final WorksReport report;
  final WorksReportRepository repository;
  final Set<int> selected;
  final bool allSelected;
  final ValueChanged<int> onToggle;
  final VoidCallback onToggleAll;

  /// Тот же отбор уходит в шторку: раскрытая строка обязана показывать работы
  /// за тот же период, что и ячейки рядом с ней.
  final ReportFilters filters;

  static const double _monthWidth = 34.0;
  static const double _objectWidth = 260.0;

  /// Колонка галочек слева от объекта.
  static const double _checkWidth = 36.0;

  /// Две узкие колонки справа: «ТО» и «Акты».
  static const double _maintenanceWidth = 60.0;
  static const double _defectsWidth = 50.0;

  /// Боковые отступы строки; без них в ширине последняя колонка выезжала
  /// за край и Flutter рисовал полосу переполнения.
  static const double _rowPadding = 12.0;

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
          width: _checkWidth +
              _objectWidth +
              _monthWidth * monthCount +
              _maintenanceWidth +
              _defectsWidth +
              _rowPadding * 2,
          child: Column(
            children: <Widget>[
              _HeaderRow(
                report: report,
                checked: allSelected
                    ? true
                    : selected.isEmpty
                        ? false
                        : null,
                onToggleAll: onToggleAll,
              ),
              ...report.items.map(
                (ReportObjectRow row) => _ObjectRow(
                  row: row,
                  filters: filters,
                  repository: repository,
                  checked: allSelected || selected.contains(row.objectId),
                  onToggle: () => onToggle(row.objectId),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({
    Key? key,
    required this.report,
    required this.checked,
    required this.onToggleAll,
  }) : super(key: key);

  final WorksReport report;

  /// `true` — выбран весь отбор, `null` — часть, `false` — никто.
  final bool? checked;
  final VoidCallback onToggleAll;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: _Matrix._rowPadding,
        vertical: 10.0,
      ),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: ColorApp.myColorGrayBorder),
        ),
      ),
      child: Row(
        children: <Widget>[
          _RowCheckbox(
            value: checked,
            tristate: true,
            tooltip: checked == true ? 'Снять выбор' : 'Выбрать весь отбор',
            onTap: onToggleAll,
          ),
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
            width: _Matrix._maintenanceWidth,
            child: Text(
              'ТО',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12.0,
                color: ColorApp.myColorGrayText,
              ),
            ),
          ),
          const SizedBox(
            width: _Matrix._defectsWidth,
            child: Text(
              'Акты',
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
  const _ObjectRow({
    Key? key,
    required this.row,
    required this.filters,
    required this.repository,
    required this.checked,
    required this.onToggle,
  }) : super(key: key);

  final ReportObjectRow row;
  final ReportFilters filters;
  final WorksReportRepository repository;
  final bool checked;
  final VoidCallback onToggle;

  void _open(BuildContext context) => ObjectWorksSheet.show(
        context,
        row: row,
        filters: filters,
        repository: repository,
      );

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _open(context),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: _Matrix._rowPadding,
          vertical: 6.0,
        ),
        decoration: BoxDecoration(
          // Отмеченная строка подсвечена: галочка слева одна на 36 пикселей,
          // а строка с двенадцатью ячейками длинная — иначе выбор теряется.
          color: checked
              ? ColorApp.myColorGreenAuth.withValues(alpha: 0.06)
              : null,
          border: const Border(
            bottom: BorderSide(color: ColorApp.myColorGrayShadow),
          ),
        ),
        child: Row(
          children: <Widget>[
            _RowCheckbox(value: checked, onTap: onToggle),
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
              width: _Matrix._maintenanceWidth,
              child: Text(
                row.maintenanceSummary,
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 12.0),
              ),
            ),
            // Число актов за период: красным при ненуле, серым при нуле —
            // как плитка сводки и значок в ленте графиков.
            SizedBox(
              width: _Matrix._defectsWidth,
              child: Text(
                '${row.counts.defects}',
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 12.0,
                  fontWeight: row.counts.defects > 0
                      ? FontWeight.w600
                      : FontWeight.w400,
                  color: row.counts.defects > 0
                      ? ColorApp.myColorRed
                      : ColorApp.myColorGrayText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Галочка в строке матрицы.
///
/// Свой виджет, а не голый `Checkbox`: у того область нажатия 48 пикселей и
/// он раздувает строку; здесь квадрат 36 и своя зона тапа, а нажатие не
/// уходит в `InkWell` строки — иначе галочка ещё и открывала бы шторку.
class _RowCheckbox extends StatelessWidget {
  const _RowCheckbox({
    Key? key,
    required this.value,
    required this.onTap,
    this.tristate = false,
    this.tooltip,
  }) : super(key: key);

  final bool? value;
  final bool tristate;
  final String? tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Widget box = SizedBox(
      width: _Matrix._checkWidth,
      height: 32.0,
      child: Align(
        alignment: Alignment.centerLeft,
        child: SizedBox(
          width: 24.0,
          height: 24.0,
          child: Checkbox(
            value: value,
            tristate: tristate,
            activeColor: ColorApp.myColorGreenAuth,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
            onChanged: (_) => onTap(),
          ),
        ),
      ),
    );
    if (tooltip == null) return box;
    return Tooltip(message: tooltip!, child: box);
  }
}

/// Размеры страницы, которые можно выбрать в пейджере.
const List<int> _pageSizes = <int>[25, 50, 100];

/// Листание: «Показаны 26–50 из 62», размер страницы и стрелки.
///
/// Стрелки крупнее стандартной `IconButton` и с рамкой: на телефоне в
/// серую стрелку 22 пикселя не попасть, а недоступная и доступная сливались.
class _Pager extends StatelessWidget {
  const _Pager({Key? key, required this.state}) : super(key: key);

  final WorksReportState state;

  @override
  Widget build(BuildContext context) {
    if (state is! WorksReportLoaded) return const SizedBox.shrink();
    final WorksReportLoaded loaded = state as WorksReportLoaded;
    final int total = loaded.report!.totalObjects;
    final int pageCount = (total / loaded.limit).ceil().clamp(1, 1 << 30);
    final int page = loaded.offset ~/ loaded.limit + 1;

    void go(int offset, {int? limit}) => context.read<WorksReportBloc>().add(
          WorksReportRequested(offset: offset, limit: limit ?? loaded.limit),
        );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: ColorApp.myColorWhite,
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Wrap(
        spacing: 12.0,
        runSpacing: 8.0,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        children: <Widget>[
          Text(
            loaded.pageLabel,
            style: const TextStyle(
              fontSize: 12.0,
              color: ColorApp.myColorGrayText,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Text(
                'На странице',
                style: TextStyle(
                  fontSize: 12.0,
                  color: ColorApp.myColorGrayText,
                ),
              ),
              const SizedBox(width: 6.0),
              DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _pageSizes.contains(loaded.limit)
                      ? loaded.limit
                      : _pageSizes.first,
                  isDense: true,
                  style: const TextStyle(
                    fontSize: 13.0,
                    color: ColorApp.myColorBlack,
                  ),
                  items: _pageSizes
                      .map(
                        (int size) => DropdownMenuItem<int>(
                          value: size,
                          child: Text('$size'),
                        ),
                      )
                      .toList(growable: false),
                  // Новый размер — с первой страницы: смещение 26 при
                  // странице в 100 показало бы кусок без начала.
                  onChanged: (int? size) =>
                      size == null ? null : go(0, limit: size),
                ),
              ),
              const SizedBox(width: 16.0),
              _PagerArrow(
                icon: Icons.chevron_left,
                onTap: loaded.hasPrevious
                    ? () => go(loaded.offset - loaded.limit)
                    : null,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: Text(
                  '$page / $pageCount',
                  style: const TextStyle(fontSize: 13.0),
                ),
              ),
              _PagerArrow(
                icon: Icons.chevron_right,
                onTap: loaded.hasNext
                    ? () => go(loaded.offset + loaded.limit)
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PagerArrow extends StatelessWidget {
  const _PagerArrow({Key? key, required this.icon, required this.onTap})
      : super(key: key);

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final bool enabled = onTap != null;
    return SizedBox(
      width: 40.0,
      height: 40.0,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          foregroundColor: ColorApp.myColorGreenAuth,
          side: BorderSide(
            color: enabled
                ? ColorApp.myColorGreenAuth
                : ColorApp.myColorGrayBorder,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6.0),
          ),
        ),
        child: Icon(
          icon,
          size: 24.0,
          color: enabled ? ColorApp.myColorGreenAuth : ColorApp.myColorGrayBorder,
        ),
      ),
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
