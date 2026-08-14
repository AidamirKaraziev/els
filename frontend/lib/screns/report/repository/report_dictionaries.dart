import 'dart:convert';

import 'package:els/helper/api_client.dart';
import 'package:http/http.dart' as http;

import '../../../helper/api_config.dart';

/// Один пункт выпадающего списка фильтра.
class DictionaryItem {
  const DictionaryItem({required this.id, required this.title});

  final int id;
  final String title;
}

/// Справочники для панели фильтров: компании, организации, участки.
///
/// Загружаются **один раз** и держатся в состоянии экрана. Отдельный класс
/// именно поэтому: список объектов на этом фронте уже становился причиной
/// бесконечных запросов к `/all-objects/`, и повторять это на каждой
/// перерисовке фильтров нельзя.
///
/// Объекта в списках нет намеренно. Лифтов на боевой базе десятки, а список
/// из них — это выпадающий список на сотню строк, в котором нечего искать.
/// Отбор по конкретному объекту делается кликом по строке матрицы: он
/// открывает все работы этого лифта за тот же период.
class ReportDictionaries {
  const ReportDictionaries({
    this.companies = const <DictionaryItem>[],
    this.organizations = const <DictionaryItem>[],
    this.divisions = const <DictionaryItem>[],
  });

  final List<DictionaryItem> companies;
  final List<DictionaryItem> organizations;
  final List<DictionaryItem> divisions;

  bool get isEmpty =>
      companies.isEmpty && organizations.isEmpty && divisions.isEmpty;
}

class ReportDictionariesRepository {
  const ReportDictionariesRepository({
    this.timeout = const Duration(seconds: 20),
  });

  final Duration timeout;

  /// Тянет три справочника разом.
  ///
  /// Неудача любого из них не роняет экран: фильтр просто не появится, а
  /// отчёт покажется целиком. Списки — вспомогательная вещь, ради них не
  /// стоит лишать человека данных.
  Future<ReportDictionaries> load() async {
    final List<List<DictionaryItem>> lists = await Future.wait(
      <Future<List<DictionaryItem>>>[
        _list('/all-company/', 'name'),
        _list('/all-organization/', 'title'),
        _list('/divisions/', 'title'),
      ],
    );

    return ReportDictionaries(
      companies: lists[0],
      organizations: lists[1],
      divisions: lists[2],
    );
  }

  Future<List<DictionaryItem>> _list(String path, String titleField) async {
    try {
      final http.Response response = await Api.get(
        Uri.parse('${ApiConfig.base}$path'),
        headers: <String, String>{'Accept': 'application/json'},
      ).timeout(timeout);

      if (response.statusCode != 200) return const <DictionaryItem>[];

      final dynamic decoded = jsonDecode(utf8.decode(response.bodyBytes));
      final dynamic data = decoded is Map ? decoded['data'] : null;
      if (data is! List) return const <DictionaryItem>[];

      final List<DictionaryItem> items = <DictionaryItem>[];
      for (final dynamic raw in data) {
        if (raw is! Map) continue;
        final dynamic id = raw['id'];
        final dynamic title = raw[titleField];
        if (id is num && title is String && title.trim().isNotEmpty) {
          items.add(DictionaryItem(id: id.toInt(), title: title.trim()));
        }
      }
      items.sort((DictionaryItem a, DictionaryItem b) =>
          a.title.toLowerCase().compareTo(b.title.toLowerCase()));
      return items;
    } catch (_) {
      return const <DictionaryItem>[];
    }
  }
}
