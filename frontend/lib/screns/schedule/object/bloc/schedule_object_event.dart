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

/// Расставить график на показанный год по программе модели.
///
/// Года в событии нет намеренно: создаём ровно то, на что человек смотрит, и
/// подпись на кнопке с годом запроса разъехаться не может.
class ScheduleObjectGenerateRequested extends ScheduleObjectEvent {
  const ScheduleObjectGenerateRequested();
}
