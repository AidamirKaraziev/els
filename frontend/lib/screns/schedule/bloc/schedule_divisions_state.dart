part of 'schedule_divisions_bloc.dart';

@immutable
abstract class ScheduleDivisionsState {
  const ScheduleDivisionsState({required this.year});

  /// Год живёт во всех состояниях, включая загрузку и ошибку: переключатель
  /// стоит в шапке и рисуется всегда, иначе на время запроса из него пропадало
  /// бы само число.
  final int year;
}

class ScheduleDivisionsInitial extends ScheduleDivisionsState {
  const ScheduleDivisionsInitial({required int year}) : super(year: year);
}

class ScheduleDivisionsLoading extends ScheduleDivisionsState {
  const ScheduleDivisionsLoading({required int year}) : super(year: year);
}

class ScheduleDivisionsLoaded extends ScheduleDivisionsState {
  const ScheduleDivisionsLoaded({
    required int year,
    required this.divisions,
  }) : super(year: year);

  final List<ScheduleDivision> divisions;
}

class ScheduleDivisionsFailure extends ScheduleDivisionsState {
  const ScheduleDivisionsFailure({
    required int year,
    required this.message,
  }) : super(year: year);

  final String message;
}
