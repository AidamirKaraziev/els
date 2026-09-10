import 'package:flutter/material.dart';

import '../../../helper/class_colors.dart';
import '../models/defect_row.dart';
import '../models/object_works.dart';
import '../models/works_report.dart';
import '../repository/works_report_repository.dart';
import 'report_cards.dart';

/// Дефектные акты всего отбора за период — то, что открывается с плитки
/// сводки.
///
/// Своя шторка, а не переход в список актов объекта (`DefectsScreen`): тот
/// показывает один объект за год, а здесь — все объекты отбора за период,
/// который бывает и кварталом, и месяцем. Устроена как шторка объекта:
/// шапка с итогом, лента карточек с полосой слева. Строка обязана назвать
/// объект — иначе в общем списке акты не отличить.
class DefectActsSheet extends StatefulWidget {
  const DefectActsSheet({
    Key? key,
    required this.filters,
    required this.period,
    required this.expected,
    this.repository = const WorksReportRepository(),
  }) : super(key: key);

  final ReportFilters filters;
  final ReportPeriod period;

  /// Число с плитки. Идёт в шапку сразу, до ответа, — чтобы человек видел,
  /// что открыл тот же счётчик, на который нажал.
  final int expected;

  final WorksReportRepository repository;

  static Future<void> show(
    BuildContext context, {
    required ReportFilters filters,
    required ReportPeriod period,
    required int expected,
    WorksReportRepository repository = const WorksReportRepository(),
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DefectActsSheet(
        filters: filters,
        period: period,
        expected: expected,
        repository: repository,
      ),
    );
  }

  @override
  State<DefectActsSheet> createState() => _DefectActsSheetState();
}

class _DefectActsSheetState extends State<DefectActsSheet> {
  List<ReportDefectRow>? _rows;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _rows = null;
      _error = null;
    });
    try {
      final List<ReportDefectRow> rows =
          await widget.repository.fetchDefects(filters: widget.filters);
      if (!mounted) return;
      setState(() => _rows = rows);
    } on WorksReportException catch (error) {
      if (!mounted) return;
      setState(() => _error = error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double maxHeight = MediaQuery.of(context).size.height * 0.85;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: const BoxDecoration(
        color: ColorApp.myColorWhite,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const ReportSheetHandle(),
          _header(),
          const Divider(height: 1.0),
          Flexible(child: _content()),
        ],
      ),
    );
  }

  String get _periodLabel {
    final ReportMonth from = widget.period.monthFrom;
    final ReportMonth to = widget.period.monthTo;
    if (from.year == to.year && from.month == to.month) {
      return '${monthFullNames[from.month - 1]} ${from.year}';
    }
    return '${monthShortNames[from.month - 1]} ${from.year} — '
        '${monthShortNames[to.month - 1]} ${to.year}';
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20.0, 0, 20.0, 14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Дефектные акты',
            style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2.0),
          Text(
            'за $_periodLabel: ${widget.expected}',
            style: const TextStyle(
              fontSize: 13.0,
              color: ColorApp.myColorGrayText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _content() {
    if (_error != null) {
      return ReportCentered(
        icon: Icons.cloud_off_outlined,
        title: _error!,
        action: 'Повторить',
        onAction: _load,
      );
    }
    final List<ReportDefectRow>? rows = _rows;
    if (rows == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 60.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (rows.isEmpty) {
      return const ReportCentered(
        icon: Icons.inbox_outlined,
        title: 'За этот период актов не было',
      );
    }

    // Свежие сверху: прораб ищет то, что составили на днях.
    final List<ReportDefectRow> sorted = List<ReportDefectRow>.of(rows)
      ..sort((ReportDefectRow a, ReportDefectRow b) =>
          _sortDate(b).compareTo(_sortDate(a)));

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20.0, 12.0, 20.0, 24.0),
      itemCount: sorted.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10.0),
      itemBuilder: (BuildContext context, int index) =>
          _DefectActCard(row: sorted[index]),
    );
  }

  static DateTime _sortDate(ReportDefectRow row) =>
      row.defect.createdAt ?? DateTime(1970);
}

class _DefectActCard extends StatelessWidget {
  const _DefectActCard({Key? key, required this.row}) : super(key: key);

  final ReportDefectRow row;

  @override
  Widget build(BuildContext context) {
    final DefectItem defect = row.defect;
    final bool open = defect.status != 'done';

    return ReportCard(
      accent: open ? ColorApp.myColorRed : ColorApp.myColorGrayText,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  row.objectLabel,
                  style: const TextStyle(
                    fontSize: 13.0,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8.0),
              ReportStatusBadge(
                label: open ? 'не устранён' : 'устранён',
                color: open ? ColorApp.myColorRed : ColorApp.myColorGreen,
              ),
            ],
          ),
          Text(
            row.addressLabel,
            style: const TextStyle(
              fontSize: 11.0,
              color: ColorApp.myColorGrayText,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6.0),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Тот же значок и цвет, что у строки акта в шторке объекта и у
              // точки в легенде матрицы: в отчёте акт помечен янтарным.
              const Icon(
                Icons.assignment_outlined,
                size: 15.0,
                color: ColorApp.myColorYellow,
              ),
              const SizedBox(width: 6.0),
              Expanded(
                child: Text(
                  defect.title,
                  style: const TextStyle(fontSize: 12.0),
                ),
              ),
            ],
          ),
          if (defect.description != null)
            Padding(
              padding: const EdgeInsets.only(left: 21.0),
              child: Text(
                defect.description!,
                style: const TextStyle(
                  fontSize: 11.0,
                  color: ColorApp.myColorGrayText,
                ),
              ),
            ),
          const SizedBox(height: 4.0),
          Wrap(
            spacing: 12.0,
            children: <Widget>[
              _meta('${monthFullNames[_monthIndex(defect.month)]}'
                  '${defect.createdAt != null ? ', ${_date(defect.createdAt!)}' : ''}'),
              if (defect.responsible != null) _meta('механик ${defect.responsible}'),
              if (defect.photoCount > 0) _meta('фотографий: ${defect.photoCount}'),
            ],
          ),
        ],
      ),
    );
  }

  static int _monthIndex(int month) => month < 1 || month > 12 ? 0 : month - 1;

  static String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}.'
      '${value.month.toString().padLeft(2, '0')}.${value.year}';

  Widget _meta(String text) => Text(
        text,
        style: const TextStyle(fontSize: 11.0, color: ColorApp.myColorGrayText),
      );
}
