part of 'top_employees_bloc.dart';

@immutable
abstract class TopEmployeesEvent {
  const TopEmployeesEvent();
}

/// Запросить рейтинг за месяц.
///
/// Событие одно на все три переключателя: месяц, порядок и вид списка
/// меняются одинаково — новым запросом с новым набором параметров. Отдельные
/// события пришлось бы согласовывать между собой, а запрос всё равно один.
class TopEmployeesRequested extends TopEmployeesEvent {
  const TopEmployeesRequested({
    required this.month,
    this.kind = EmployeeKind.mechanic,
    this.order = EmployeeOrder.best,
    this.limit = 5,
    this.offset = 0,
  });

  /// Любой день нужного месяца: до сервера едут только год и номер месяца.
  final DateTime month;

  final EmployeeKind kind;
  final EmployeeOrder order;

  /// Сколько строк показать. Счётчики в подписи считаются по всей выборке,
  /// поэтому обрезка списка не искажает цифры.
  final int limit;

  /// Сколько строк пропустить — страница списка.
  final int offset;
}
