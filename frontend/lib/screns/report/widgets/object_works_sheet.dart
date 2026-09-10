import 'package:flutter/material.dart';

import '../../../helper/class_colors.dart';
import '../models/object_works.dart';
import '../models/works_report.dart';
import '../repository/works_report_repository.dart';
import 'report_cards.dart';

/// Все работы на объекте за период — то, что открывается кликом по строке.
///
/// Уровень 2 — лента работ по датам, уровень 3 — что именно сделано: чек-лист
/// акта, дефектный акт, детали заявки. Собирается слиянием двух списков
/// по времени: у ТО и у заявки нет общего набора полей, поэтому бэкенд отдаёт
/// их раздельно, а лента — дело показа.
class ObjectWorksSheet extends StatefulWidget {
  const ObjectWorksSheet({
    Key? key,
    required this.row,
    required this.filters,
    this.repository = const WorksReportRepository(),
  }) : super(key: key);

  final ReportObjectRow row;
  final ReportFilters filters;
  final WorksReportRepository repository;

  /// Открыть шторку. Вынесено сюда, чтобы экран не знал про её устройство.
  static Future<void> show(
    BuildContext context, {
    required ReportObjectRow row,
    required ReportFilters filters,
    WorksReportRepository repository = const WorksReportRepository(),
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ObjectWorksSheet(
        row: row,
        filters: filters,
        repository: repository,
      ),
    );
  }

  @override
  State<ObjectWorksSheet> createState() => _ObjectWorksSheetState();
}

class _ObjectWorksSheetState extends State<ObjectWorksSheet> {
  ObjectWorksReport? _report;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _report = null;
      _error = null;
    });
    try {
      final ObjectWorksReport report =
          await widget.repository.fetchObjectWorks(
        objectId: widget.row.objectId,
        filters: widget.filters,
      );
      if (!mounted) return;
      setState(() => _report = report);
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

  Widget _header() {
    final ReportObjectRow row = widget.row;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20.0, 0, 20.0, 14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            row.objectLabel,
            style: const TextStyle(fontSize: 18.0, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2.0),
          Text(
            row.addressLabel,
            style: const TextStyle(
              fontSize: 13.0,
              color: ColorApp.myColorGrayText,
            ),
          ),
          const SizedBox(height: 8.0),
          Wrap(
            spacing: 14.0,
            runSpacing: 4.0,
            children: <Widget>[
              _fact('ТО', row.maintenanceSummary),
              if (row.maintenanceOverdue > 0)
                _fact('просрочено', '${row.maintenanceOverdue}',
                    color: ColorApp.myColorRed),
              _fact('аварий', '${row.counts.breakdowns}'),
              _fact('заявок заказчика', '${row.counts.clientRequests}'),
              // Число актов рядом с авариями, красным при ненуле — тот же
              // ряд, что бейдж в ленте графиков и колонка матрицы.
              _fact(
                'дефектных актов',
                '${row.counts.defects}',
                color: row.counts.defects > 0 ? ColorApp.myColorRed : null,
              ),
              if (row.division != null) _fact('участок', row.division!),
              if (row.responsibleMechanic != null)
                _fact('механик', row.responsibleMechanic!),
            ],
          ),
        ],
      ),
    );
  }

  Widget _fact(String label, String value, {Color? color}) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 12.0, color: ColorApp.myColorBlack),
        children: <TextSpan>[
          TextSpan(
            text: '$label ',
            style: const TextStyle(color: ColorApp.myColorGrayText),
          ),
          TextSpan(
            text: value,
            style: TextStyle(fontWeight: FontWeight.w600, color: color),
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
    final ObjectWorksReport? report = _report;
    if (report == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 60.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (report.isEmpty) {
      return const ReportCentered(
        icon: Icons.inbox_outlined,
        title: 'За этот период работ на объекте не было',
        subtitle: 'Ни планового ТО, ни заявок. Если ТО положено — значит '
            'график на объект не заведён.',
      );
    }

    // Лента по датам: два списка сливаются в один и сортируются по времени.
    // Так видно, что за месяц было не только плановое ТО.
    final List<_Entry> entries = <_Entry>[
      ...report.maintenance.map(_Entry.maintenance),
      ...report.requests.map(_Entry.request),
    ]..sort((_Entry a, _Entry b) => a.date.compareTo(b.date));

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20.0, 12.0, 20.0, 24.0),
      itemCount: entries.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10.0),
      itemBuilder: (BuildContext context, int index) => entries[index].build(),
    );
  }
}

/// Одна работа в ленте: либо ТО, либо заявка.
class _Entry {
  _Entry.maintenance(MaintenanceWork work)
      : date = work.sortDate,
        _maintenance = work,
        _request = null;

  _Entry.request(RequestWork work)
      : date = work.sortDate,
        _maintenance = null,
        _request = work;

  final DateTime date;
  final MaintenanceWork? _maintenance;
  final RequestWork? _request;

  Widget build() => _maintenance != null
      ? _MaintenanceCard(work: _maintenance!)
      : _RequestCard(work: _request!);
}

String _formatDate(DateTime? value, {bool withTime = false}) {
  if (value == null) return '—';
  final String date = '${value.day.toString().padLeft(2, '0')}.'
      '${value.month.toString().padLeft(2, '0')}.${value.year}';
  if (!withTime) return date;
  return '$date ${value.hour.toString().padLeft(2, '0')}:'
      '${value.minute.toString().padLeft(2, '0')}';
}

class _MaintenanceCard extends StatefulWidget {
  const _MaintenanceCard({Key? key, required this.work}) : super(key: key);

  final MaintenanceWork work;

  @override
  State<_MaintenanceCard> createState() => _MaintenanceCardState();
}

class _MaintenanceCardState extends State<_MaintenanceCard> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final MaintenanceWork work = widget.work;

    return ReportCard(
      accent: maintenanceColor(work.status),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'Плановое ТО за ${monthFullNames[work.month - 1]} '
                  '${work.year}',
                  style: const TextStyle(
                    fontSize: 14.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ReportStatusBadge(
                label: maintenanceLabel(work.status),
                color: maintenanceColor(work.status),
              ),
            ],
          ),
          const SizedBox(height: 4.0),
          Text(
            <String>[
              'закрыт ${_formatDate(work.finishedAt)}',
              if (work.daysLate != null && work.daysLate! > 0)
                'с опозданием на ${work.daysLate} дн.',
              if (work.mechanic != null) 'механик ${work.mechanic}',
              if (work.foreman != null) 'прораб ${work.foreman}',
            ].join(' · '),
            style: const TextStyle(
              fontSize: 12.0,
              color: ColorApp.myColorGrayText,
            ),
          ),
          const SizedBox(height: 8.0),
          if (!work.hasChecklist)
            // Пустой чек-лист — это «механик не заполнял», а не «работ не
            // было». Пустое место здесь читалось бы как второе.
            const Text(
              'Чек-лист работ не заполнен',
              style: TextStyle(
                fontSize: 12.0,
                fontStyle: FontStyle.italic,
                color: ColorApp.myColorGrayText,
              ),
            )
          else
            InkWell(
              onTap: () => setState(() => _open = !_open),
              child: Row(
                children: <Widget>[
                  Text(
                    'Выполнено ${work.doneSteps} из ${work.steps.length} пунктов',
                    style: const TextStyle(
                      fontSize: 12.0,
                      color: ColorApp.myColorGreenAuth,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Icon(
                    _open ? Icons.expand_less : Icons.expand_more,
                    size: 18.0,
                    color: ColorApp.myColorGreenAuth,
                  ),
                ],
              ),
            ),
          if (_open)
            Padding(
              padding: const EdgeInsets.only(top: 6.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: work.steps
                    .map((WorkStep step) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Icon(
                                step.done
                                    ? Icons.check_circle_outline
                                    : Icons.radio_button_unchecked,
                                size: 15.0,
                                color: step.done
                                    ? ColorApp.myColorGreenAuth
                                    : ColorApp.myColorGrayText,
                              ),
                              const SizedBox(width: 6.0),
                              Expanded(
                                child: Text(
                                  step.title,
                                  style: const TextStyle(fontSize: 12.0),
                                ),
                              ),
                            ],
                          ),
                        ))
                    .toList(growable: false),
              ),
            ),
          if (work.defects.isNotEmpty) ...<Widget>[
            const SizedBox(height: 8.0),
            ...work.defects.map((DefectItem defect) => _DefectLine(defect: defect)),
          ],
        ],
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({Key? key, required this.work}) : super(key: key);

  final RequestWork work;

  Color get _accent {
    switch (work.kind) {
      case WorkKind.breakdown:
        return ColorApp.myColorRed;
      case WorkKind.clientRequest:
        return ColorApp.myColorBlue;
      default:
        return ColorApp.myColorGray;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ReportCard(
      accent: _accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  work.title,
                  style: const TextStyle(
                    fontSize: 14.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ReportStatusBadge(label: workKindLabel(work.kind), color: _accent),
            ],
          ),
          const SizedBox(height: 4.0),
          Text(
            <String>[
              _formatDate(work.createdAt, withTime: true),
              if (work.category != null) work.category!,
              if (work.reason != null) 'причина: ${work.reason}',
            ].join(' · '),
            style: const TextStyle(
              fontSize: 12.0,
              color: ColorApp.myColorGrayText,
            ),
          ),
          const SizedBox(height: 2.0),
          Text(
            <String>[
              if (work.reactionHours != null)
                'реакция ${work.reactionHours} ч'
              else
                'не принята',
              if (work.doneAt != null)
                'устранена ${_formatDate(work.doneAt, withTime: true)}',
              if (work.executor != null) 'исполнитель ${work.executor}',
            ].join(' · '),
            style: const TextStyle(
              fontSize: 12.0,
              color: ColorApp.myColorGrayText,
            ),
          ),
          if (work.commentary != null) ...<Widget>[
            const SizedBox(height: 4.0),
            Text(work.commentary!, style: const TextStyle(fontSize: 12.0)),
          ],
        ],
      ),
    );
  }
}

class _DefectLine extends StatelessWidget {
  const _DefectLine({Key? key, required this.defect}) : super(key: key);

  final DefectItem defect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(
            Icons.assignment_outlined,
            size: 15.0,
            color: ColorApp.myColorYellow,
          ),
          const SizedBox(width: 6.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Дефектный акт: ${defect.title}',
                  style: const TextStyle(fontSize: 12.0),
                ),
                if (defect.description != null)
                  Text(
                    defect.description!,
                    style: const TextStyle(
                      fontSize: 11.0,
                      color: ColorApp.myColorGrayText,
                    ),
                  ),
                if (defect.photoCount > 0)
                  Text(
                    'фотографий: ${defect.photoCount}',
                    style: const TextStyle(
                      fontSize: 11.0,
                      color: ColorApp.myColorGrayText,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
