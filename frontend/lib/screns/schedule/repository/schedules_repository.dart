import '../models/schedule_filters.dart';
import '../models/schedule_row.dart';

/// Ошибка, которую экран может показать человеку.
///
/// Наружу отдаём короткий текст без кодов и стектрейсов — он уходит прямо в
/// плашку на экране.
class SchedulesException implements Exception {
  const SchedulesException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Одна страница ленты графиков.
class SchedulePage {
  const SchedulePage({
    required this.items,
    required this.page,
    required this.hasNext,
  });

  final List<ScheduleRow> items;
  final int page;

  /// Есть ли что догружать. Берётся из `meta.paginator.has_next`, а не из
  /// «список непуст»: на признаке «непуст» старый экран уезжал за последнюю
  /// страницу и показывал пустоту.
  final bool hasNext;

  static const SchedulePage empty =
      SchedulePage(items: <ScheduleRow>[], page: 1, hasNext: false);
}

/// Значения выпадающих фильтров.
///
/// Приходят отдельно от строк: список участков не должен зависеть от того,
/// какая страница объектов сейчас загружена, иначе фильтр показывал бы только
/// те участки, что попали в первые тридцать строк.
class ScheduleFilterOptions {
  const ScheduleFilterOptions({
    this.divisions = const <FilterOption>[],
    this.types = const <FilterOption>[],
    this.names = const <FilterOption>[],
    this.factoryNumbers = const <FilterOption>[],
  });

  final List<FilterOption> divisions;
  final List<FilterOption> types;
  final List<FilterOption> names;
  final List<FilterOption> factoryNumbers;

  static const ScheduleFilterOptions empty = ScheduleFilterOptions();
}

/// Откуда экран берёт графики.
///
/// Интерфейс, а не класс: на фазе отрисовки под ним стоит фикстура, дальше —
/// та же подпись поверх сети. Виджеты и блок при подмене не меняются.
abstract class SchedulesRepository {
  /// Лента графиков: объект и его двенадцать клеток за год.
  Future<SchedulePage> fetchRows({
    required ScheduleFilters filters,
    required int page,
  });

  /// Одна строка ленты — та же ручка, но по одному объекту.
  ///
  /// Нужна после закрытия ТО: перечитывать ленту целиком нельзя, страничная
  /// загрузка сбросилась бы на первую страницу, а считать клетку на клиенте
  /// нечем — состояние месяца знает только сервер.
  ///
  /// `null` означает «объекта в выдаче нет» — например, он вне области
  /// видимости. Это не ошибка: строку на экране просто оставляют прежней.
  Future<ScheduleRow?> fetchRow({
    required int objectId,
    required int year,
  });

  /// Значения выпадающих фильтров.
  Future<ScheduleFilterOptions> fetchFilterOptions();
}
