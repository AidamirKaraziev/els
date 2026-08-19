part of 'submitted_works_bloc.dart';

@immutable
abstract class SubmittedWorksState {
  const SubmittedWorksState();

  /// Страница, которая сейчас на руках. У загрузки это предыдущая: при
  /// листании и после отметки список не должен пропадать с экрана.
  SubmittedWorksPage? get page => null;

  /// Стоит ли отбор «только непросмотренные». Живёт в состоянии, а не в
  /// виджете: его нужно помнить и при листании, и при перезапросе после
  /// отметки.
  bool get onlyUnreviewed => false;
}

class SubmittedWorksInitial extends SubmittedWorksState {
  const SubmittedWorksInitial();
}

class SubmittedWorksLoading extends SubmittedWorksState {
  const SubmittedWorksLoading({
    SubmittedWorksPage? previous,
    bool onlyUnreviewed = false,
  })  : _previous = previous,
        _onlyUnreviewed = onlyUnreviewed;

  final SubmittedWorksPage? _previous;
  final bool _onlyUnreviewed;

  @override
  SubmittedWorksPage? get page => _previous;

  @override
  bool get onlyUnreviewed => _onlyUnreviewed;
}

class SubmittedWorksLoaded extends SubmittedWorksState {
  const SubmittedWorksLoaded({
    required SubmittedWorksPage page,
    bool onlyUnreviewed = false,
  })  : _page = page,
        _onlyUnreviewed = onlyUnreviewed;

  final SubmittedWorksPage _page;
  final bool _onlyUnreviewed;

  @override
  SubmittedWorksPage get page => _page;

  @override
  bool get onlyUnreviewed => _onlyUnreviewed;
}

class SubmittedWorksFailure extends SubmittedWorksState {
  const SubmittedWorksFailure({
    required this.message,
    bool onlyUnreviewed = false,
  }) : _onlyUnreviewed = onlyUnreviewed;

  final String message;
  final bool _onlyUnreviewed;

  @override
  bool get onlyUnreviewed => _onlyUnreviewed;
}

/// Лента на месте, но отметка не прошла. Отдельно от [SubmittedWorksFailure]:
/// список остаётся на экране, а сообщение показывается всплывающей строкой.
class SubmittedWorksActionFailed extends SubmittedWorksState {
  const SubmittedWorksActionFailed({
    required this.message,
    required SubmittedWorksPage page,
    bool onlyUnreviewed = false,
  })  : _page = page,
        _onlyUnreviewed = onlyUnreviewed;

  final String message;
  final SubmittedWorksPage _page;
  final bool _onlyUnreviewed;

  @override
  SubmittedWorksPage get page => _page;

  @override
  bool get onlyUnreviewed => _onlyUnreviewed;
}
