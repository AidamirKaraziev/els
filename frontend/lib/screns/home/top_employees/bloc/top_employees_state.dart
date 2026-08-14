part of 'top_employees_bloc.dart';

@immutable
abstract class TopEmployeesState {
  const TopEmployeesState();

  /// Отчёт, который сейчас есть на руках. У загрузки это предыдущий: при
  /// переключении месяца или порядка карточка не должна мигать пустотой.
  TopEmployeesReport? get report => null;

  /// Выбранный месяц. `null` — до первого запроса.
  DateTime? get month => null;

  EmployeeKind get kind => EmployeeKind.mechanic;

  EmployeeOrder get order => EmployeeOrder.best;

  int get offset => 0;
}

class TopEmployeesInitial extends TopEmployeesState {
  const TopEmployeesInitial();
}

class TopEmployeesLoading extends TopEmployeesState {
  const TopEmployeesLoading({
    TopEmployeesReport? previous,
    required DateTime month,
    required EmployeeKind kind,
    required EmployeeOrder order,
    int offset = 0,
  })  : _previous = previous,
        _month = month,
        _kind = kind,
        _order = order,
        _offset = offset;

  final TopEmployeesReport? _previous;
  final DateTime _month;
  final EmployeeKind _kind;
  final EmployeeOrder _order;
  final int _offset;

  @override
  TopEmployeesReport? get report => _previous;

  @override
  DateTime get month => _month;

  @override
  EmployeeKind get kind => _kind;

  @override
  EmployeeOrder get order => _order;

  @override
  int get offset => _offset;
}

class TopEmployeesLoaded extends TopEmployeesState {
  const TopEmployeesLoaded({
    required TopEmployeesReport report,
    required DateTime month,
    required EmployeeKind kind,
    required EmployeeOrder order,
    int offset = 0,
  })  : _report = report,
        _month = month,
        _kind = kind,
        _order = order,
        _offset = offset;

  final TopEmployeesReport _report;
  final DateTime _month;
  final EmployeeKind _kind;
  final EmployeeOrder _order;
  final int _offset;

  @override
  TopEmployeesReport get report => _report;

  @override
  DateTime get month => _month;

  @override
  EmployeeKind get kind => _kind;

  @override
  EmployeeOrder get order => _order;

  @override
  int get offset => _offset;
}

class TopEmployeesFailure extends TopEmployeesState {
  const TopEmployeesFailure({
    required this.message,
    required DateTime month,
    required EmployeeKind kind,
    required EmployeeOrder order,
  })  : _month = month,
        _kind = kind,
        _order = order;

  final String message;
  final DateTime _month;
  final EmployeeKind _kind;
  final EmployeeOrder _order;

  @override
  DateTime get month => _month;

  @override
  EmployeeKind get kind => _kind;

  @override
  EmployeeOrder get order => _order;
}
