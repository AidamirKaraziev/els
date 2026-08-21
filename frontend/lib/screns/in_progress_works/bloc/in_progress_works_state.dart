part of 'in_progress_works_bloc.dart';

@immutable
abstract class InProgressWorksState {
  const InProgressWorksState();

  /// Список, который сейчас на руках. У загрузки это предыдущий: при
  /// обновлении раздел не должен пропадать с экрана и дёргать ленту сданных.
  InProgressWorks? get works => null;
}

class InProgressWorksInitial extends InProgressWorksState {
  const InProgressWorksInitial();
}

class InProgressWorksLoading extends InProgressWorksState {
  const InProgressWorksLoading({InProgressWorks? previous})
      : _previous = previous;

  final InProgressWorks? _previous;

  @override
  InProgressWorks? get works => _previous;
}

class InProgressWorksLoaded extends InProgressWorksState {
  const InProgressWorksLoaded({required InProgressWorks works})
      : _works = works;

  final InProgressWorks _works;

  @override
  InProgressWorks get works => _works;
}

/// Раздел не загрузился. Лента сданных при этом живёт своей жизнью — это два
/// независимых запроса, и падение одного не должно гасить второй.
///
/// Прежний список остаётся при сбое на руках: запросы идут сами раз в минуту,
/// и обрыв связи на одну секунду не повод стирать с экрана работы, которые
/// никуда не делись. Пусто [works] только тогда, когда списка ещё и не было.
class InProgressWorksFailure extends InProgressWorksState {
  const InProgressWorksFailure({required this.message, InProgressWorks? previous})
      : _previous = previous;

  final String message;

  final InProgressWorks? _previous;

  @override
  InProgressWorks? get works => _previous;
}
