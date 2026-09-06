part of 'schedule_object_bloc.dart';

@immutable
abstract class ScheduleObjectState {
  const ScheduleObjectState();
}

class ScheduleObjectInitial extends ScheduleObjectState {
  const ScheduleObjectInitial();
}

class ScheduleObjectLoading extends ScheduleObjectState {
  const ScheduleObjectLoading();
}

/// Экран загружен: карточка объекта и лента выбранного года.
///
/// Лента живёт в том же состоянии, что и карточка, но своими признаками
/// загрузки и ошибки: год человек переключает поверх уже открытого экрана, и
/// на время запроса ленты ни адрес, ни ответственные пропадать не должны.
class ScheduleObjectLoaded extends ScheduleObjectState {
  const ScheduleObjectLoaded({
    required this.card,
    required this.year,
    required this.cells,
    this.isYearLoading = false,
    this.isGenerating = false,
    this.yearError,
    this.defectsCount,
  });

  final ScheduleObjectCard card;

  /// Год, за который показана лента.
  final int year;

  /// Ровно двенадцать клеток, январь..декабрь.
  final List<MonthCell> cells;

  /// Идёт запрос ленты за другой год.
  final bool isYearLoading;

  /// Идёт создание графика. Кнопку на это время гасим: повторный вызов ручке
  /// не вредит, но два запроса подряд из одного нажатия — это не то, что
  /// человек имел в виду.
  final bool isGenerating;

  /// Сколько дефектных актов у объекта за [year]. `null` — ещё не посчитали
  /// или посчитать не удалось: значок тогда не показываем вовсе. Ноль от
  /// «неизвестно» отличается, и рисовать серый значок вместо неотвеченного
  /// запроса значило бы соврать, что дефектов не было.
  final int? defectsCount;

  /// Что пошло не так с лентой: не загрузился год, не создался график.
  ///
  /// Живёт рядом с лентой, а не отдельным состоянием экрана: карточка
  /// объекта загружена и должна остаться на месте. И не всплывающей плашкой:
  /// текст «нет шаблона чек-листа на ТО 6» человеку нужно дочитать и, скорее
  /// всего, пойти его заводить — за три секунды `SnackBar` он не успеет.
  final String? yearError;

  /// Графика на этот год нет вовсе — все двенадцать клеток пустые.
  ///
  /// Это не «ничего не выполнено»: плана объекту просто не поставили.
  bool get hasNoSchedule =>
      cells.every((MonthCell cell) => cell.status == MonthStatus.none);

  /// [yearError] задаётся только явно: `null` в аргументе означает «убрать
  /// прошлую ошибку», а не «оставить как было». Иначе текст неудачи висел бы
  /// на экране и после удачного повтора.
  ScheduleObjectLoaded copyWith({
    int? year,
    List<MonthCell>? cells,
    bool? isYearLoading,
    bool? isGenerating,
    String? yearError,
    int? defectsCount,
  }) {
    return ScheduleObjectLoaded(
      card: card,
      year: year ?? this.year,
      cells: cells ?? this.cells,
      isYearLoading: isYearLoading ?? this.isYearLoading,
      isGenerating: isGenerating ?? this.isGenerating,
      yearError: yearError,
      defectsCount: defectsCount ?? this.defectsCount,
    );
  }
}

/// Карточку загрузить не удалось.
///
/// Текст показываем прямо человеку, поэтому он приходит уже готовым из
/// репозитория — без кодов ответа и стектрейсов.
class ScheduleObjectFailure extends ScheduleObjectState {
  const ScheduleObjectFailure(this.message);

  final String message;
}
