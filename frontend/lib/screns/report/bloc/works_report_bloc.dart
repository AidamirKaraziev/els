// `package:bloc` и `package:meta` в pubspec.yaml не объявлены — остальной код
// импортирует их транзитивно. Берём то же самое из flutter_bloc и foundation,
// которые объявлены явно.
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/works_report.dart';
import '../repository/works_report_repository.dart';

part 'works_report_event.dart';
part 'works_report_state.dart';

/// Состояние экрана «Отчёты».
///
/// Хранит текущий отбор рядом с отчётом: по нему собирается и запрос, и
/// ссылка на выгрузку. Разъехаться они не должны — иначе человек скачает
/// файл не по тому отбору, что видит на экране.
class WorksReportBloc extends Bloc<WorksReportEvent, WorksReportState> {
  WorksReportBloc({
    required ReportFilters initialFilters,
    WorksReportRepository? repository,
  })  : _repository = repository ?? const WorksReportRepository(),
        super(WorksReportInitial(filters: initialFilters)) {
    on<WorksReportRequested>(_onRequested);
    on<WorksReportExportRequested>(_onExportRequested);
  }

  final WorksReportRepository _repository;

  /// Номер последнего запроса: отсекает ответы, которые уже никому не нужны.
  /// Человек сменил период дважды подряд, а ответ на первый пришёл после
  /// второго и перезаписал бы его.
  int _requestId = 0;

  Future<void> _onRequested(
    WorksReportRequested event,
    Emitter<WorksReportState> emit,
  ) async {
    final int requestId = ++_requestId;
    final ReportFilters filters = event.filters ?? state.filters;

    // Предыдущий отчёт отдаём в состояние загрузки: при смене страницы шапка
    // со сводкой не должна мигать между запросами.
    emit(WorksReportLoading(
      filters: filters,
      previous: state.report,
      offset: event.offset,
    ));

    try {
      WorksReport report = await _repository.fetch(
        filters: filters,
        limit: event.limit,
        offset: event.offset,
      );
      int offset = event.offset;

      // Страница за концом выдачи: объектов стало меньше, пока человек
      // листал. Пустой список при ненулевом счётчике выглядел бы как «нет
      // данных», поэтому молча возвращаемся на первую страницу.
      if (report.items.isEmpty && offset > 0 && report.totalObjects > 0) {
        report = await _repository.fetch(filters: filters, limit: event.limit);
        offset = 0;
      }

      if (requestId != _requestId) return;

      emit(WorksReportLoaded(
        filters: filters,
        report: report,
        offset: offset,
        limit: event.limit,
      ));
    } on WorksReportException catch (error) {
      if (requestId != _requestId) return;
      emit(WorksReportFailure(filters: filters, message: error.message));
    }
  }

  Future<void> _onExportRequested(
    WorksReportExportRequested event,
    Emitter<WorksReportState> emit,
  ) async {
    // Отчёт при выгрузке не перезапрашиваем: файл собирает сервер по тем же
    // параметрам, и второй запрос на экран только мигал бы данными.
    try {
      final String url = await _repository.exportUrl(
        filters: state.filters,
        format: event.format,
        withPhotos: event.withPhotos,
      );
      emit(WorksReportExportReady(
        filters: state.filters,
        report: state.report,
        url: url,
      ));
    } on WorksReportException catch (error) {
      emit(WorksReportExportFailed(
        filters: state.filters,
        report: state.report,
        message: error.message,
      ));
    }
  }
}
