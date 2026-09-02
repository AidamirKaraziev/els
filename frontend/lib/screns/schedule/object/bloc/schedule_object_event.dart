part of 'schedule_object_bloc.dart';

@immutable
abstract class ScheduleObjectEvent {
  const ScheduleObjectEvent();
}

/// Загрузить карточку объекта и ленту года.
///
/// Годится и первому открытию экрана, и повтору после ошибки: запрос один и
/// тот же, и разводить их по двум событиям значило бы дважды писать один путь.
class ScheduleObjectRequested extends ScheduleObjectEvent {
  const ScheduleObjectRequested();
}

/// Показать ленту другого года.
///
/// Карточку объекта при этом не трогаем: организация, адрес и ответственные
/// от года не зависят.
class ScheduleObjectYearRequested extends ScheduleObjectEvent {
  const ScheduleObjectYearRequested(this.year);

  final int year;
}

/// Перенести ТО на другой месяц показанного года.
///
/// Года в событии нет по той же причине, что и у расстановки: двигаем ровно
/// в той ленте, на которую человек смотрит.
class ScheduleObjectCellMoved extends ScheduleObjectEvent {
  const ScheduleObjectCellMoved({required this.cell, required this.toMonth});

  /// Клетка, которую тащили: из неё берём акт и месяц-источник.
  final MonthCell cell;

  final int toMonth;
}

/// Расставить график на показанный год по программе модели.
///
/// Года в событии нет намеренно: создаём ровно то, на что человек смотрит, и
/// подпись на кнопке с годом запроса разъехаться не может.
@Deprecated(
  'График расставляет мастер: WizardApproved шлёт generate с выбранным '
  'месяцем. Событие оставлено живым — оно в проде.',
)
class ScheduleObjectGenerateRequested extends ScheduleObjectEvent {
  const ScheduleObjectGenerateRequested();
}
