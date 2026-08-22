part of 'work_details_bloc.dart';

@immutable
abstract class WorkDetailsEvent {
  const WorkDetailsEvent();
}

/// Загрузить подробности. Повтор после сбоя — то же самое действие, что и
/// первая загрузка.
class WorkDetailsRequested extends WorkDetailsEvent {
  const WorkDetailsRequested();
}

/// Перечитать работу молча — такт живой карточки.
///
/// Не то же самое, что [WorkDetailsRequested]: тот гасит экран скелетом, и
/// раз в минуту у прораба схлопывался бы развёрнутый чек-лист. Здесь данные
/// подменяются на месте, а упавший запрос не меняет ничего — карточка с
/// прежним чек-листом честнее, чем «Не удалось загрузить» от одного дрогнувшего
/// такта.
class WorkDetailsRefreshed extends WorkDetailsEvent {
  const WorkDetailsRefreshed();
}

/// Перечитать одного исполнителя.
///
/// Нужно после возврата из карточки сотрудника: прораб ходил туда вписать
/// телефон, и вернуться он должен к кнопке «Позвонить». Перезапрашивать ради
/// этого весь акт нельзя — развёрнутый чек-лист схлопнулся бы, а человек его
/// разворачивал руками.
class WorkPerformerRequested extends WorkDetailsEvent {
  const WorkPerformerRequested();
}
