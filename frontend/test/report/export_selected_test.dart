/// Выгрузка по отмеченным лифтам: событие несёт список id и галочку фото,
/// репозиторий получает их как есть, «все» уходит без списка.
///
/// Экран целиком не поднимаем — он тянет справочники и шапку; проверяем
/// тот шов, где галочки превращаются в параметры запроса.
library;

import 'package:els/screns/report/bloc/works_report_bloc.dart';
import 'package:els/screns/report/repository/works_report_repository.dart';
import 'package:els/screns/report/repository/fixture_works_report_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class _Recording extends FixtureWorksReportRepository {
  const _Recording() : super(delay: Duration.zero);

  static List<int>? lastObjectIds;
  static bool? lastWithPhotos;
  static String? lastFormat;

  @override
  Future<String> exportUrl({
    required ReportFilters filters,
    required String format,
    bool withPhotos = false,
    List<int>? objectIds,
  }) async {
    lastObjectIds = objectIds;
    lastWithPhotos = withPhotos;
    lastFormat = format;
    return 'about:blank';
  }
}

final ReportFilters _year = ReportFilters(
  dateFrom: DateTime(2026, 1, 1),
  dateTo: DateTime(2026, 12, 31),
);

Future<WorksReportBloc> _bloc() async {
  final WorksReportBloc bloc = WorksReportBloc(
    repository: const _Recording(),
    initialFilters: _year,
  );
  return bloc;
}

void main() {
  test('два отмеченных лифта уходят списком, фото — галочкой', () async {
    final WorksReportBloc bloc = await _bloc();

    bloc.add(const WorksReportExportRequested(
      format: 'pdf',
      withPhotos: true,
      objectIds: <int>[44, 46],
    ));
    await expectLater(
      bloc.stream,
      emitsThrough(isA<WorksReportExportReady>()),
    );

    expect(_Recording.lastFormat, 'pdf');
    expect(_Recording.lastWithPhotos, isTrue);
    expect(_Recording.lastObjectIds, <int>[44, 46]);
    await bloc.close();
  });

  test('без выбора список не передаётся — файл по всему отбору', () async {
    final WorksReportBloc bloc = await _bloc();

    bloc.add(const WorksReportExportRequested(format: 'xlsx'));
    await expectLater(
      bloc.stream,
      emitsThrough(isA<WorksReportExportReady>()),
    );

    expect(_Recording.lastFormat, 'xlsx');
    expect(_Recording.lastWithPhotos, isFalse);
    expect(_Recording.lastObjectIds, isNull);
    await bloc.close();
  });
}
