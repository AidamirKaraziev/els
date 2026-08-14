part of 'works_report_bloc.dart';

@immutable
abstract class WorksReportState {
  const WorksReportState({required this.filters, this.report, this.offset = 0});

  /// Текущий отбор. Живёт во всех состояниях, включая ошибку: экран рисует
  /// панель фильтров всегда, и после неудачного запроса человек должен
  /// увидеть, что именно он спрашивал.
  final ReportFilters filters;

  /// Последний удачно полученный отчёт. В загрузке и ошибке это предыдущий:
  /// сводка не должна мигать между запросами.
  final WorksReport? report;

  final int offset;
}

class WorksReportInitial extends WorksReportState {
  const WorksReportInitial({required ReportFilters filters})
      : super(filters: filters);
}

class WorksReportLoading extends WorksReportState {
  const WorksReportLoading({
    required ReportFilters filters,
    WorksReport? previous,
    int offset = 0,
  }) : super(filters: filters, report: previous, offset: offset);
}

class WorksReportLoaded extends WorksReportState {
  const WorksReportLoaded({
    required ReportFilters filters,
    required WorksReport report,
    required this.limit,
    int offset = 0,
  }) : super(filters: filters, report: report, offset: offset);

  final int limit;

  /// «Показаны 1–25 из 47». Без этой подписи непонятно, весь ли отчёт перед
  /// глазами, а сводка при этом считается по всему отбору.
  String get pageLabel {
    if (report == null || report!.items.isEmpty) return '';
    final int first = offset + 1;
    final int last = offset + report!.items.length;
    return 'Показаны $first–$last из ${report!.totalObjects}';
  }

  bool get hasPrevious => offset > 0;

  bool get hasNext =>
      report != null && offset + report!.items.length < report!.totalObjects;
}

class WorksReportFailure extends WorksReportState {
  const WorksReportFailure({
    required ReportFilters filters,
    required this.message,
  }) : super(filters: filters);

  final String message;
}

/// Ссылка на файл готова — экран открывает её в новой вкладке.
class WorksReportExportReady extends WorksReportState {
  const WorksReportExportReady({
    required ReportFilters filters,
    required WorksReport? report,
    required this.url,
  }) : super(filters: filters, report: report);

  final String url;
}

class WorksReportExportFailed extends WorksReportState {
  const WorksReportExportFailed({
    required ReportFilters filters,
    required WorksReport? report,
    required this.message,
  }) : super(filters: filters, report: report);

  final String message;
}
