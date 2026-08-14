part of 'works_report_bloc.dart';

@immutable
abstract class WorksReportEvent {
  const WorksReportEvent();
}

/// Запросить отчёт.
///
/// `filters` пустые — берём текущий отбор из состояния: так листание страниц
/// не обязано таскать с собой весь набор фильтров.
class WorksReportRequested extends WorksReportEvent {
  const WorksReportRequested({
    this.filters,
    this.limit = 25,
    this.offset = 0,
  });

  final ReportFilters? filters;
  final int limit;
  final int offset;
}

/// Собрать ссылку на выгрузку и открыть её.
class WorksReportExportRequested extends WorksReportEvent {
  const WorksReportExportRequested({
    required this.format,
    this.withPhotos = false,
  });

  /// `xlsx` или `pdf`.
  final String format;

  /// Только для PDF и по умолчанию выключено: с фотографиями годовой отчёт
  /// весит сотни мегабайт.
  final bool withPhotos;
}
