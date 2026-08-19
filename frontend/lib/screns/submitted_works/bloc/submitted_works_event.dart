part of 'submitted_works_bloc.dart';

@immutable
abstract class SubmittedWorksEvent {
  const SubmittedWorksEvent();
}

/// Запросить страницу ленты.
class SubmittedWorksRequested extends SubmittedWorksEvent {
  const SubmittedWorksRequested({this.page = 1, this.onlyUnreviewed});

  /// Страницы бэкенд режет по 30 строк и считает с единицы.
  final int page;

  /// `null` — оставить отбор, который уже стоит. Так листание не сбрасывает
  /// переключатель, а переключатель не обязан помнить номер страницы.
  final bool? onlyUnreviewed;
}

/// Отметить работу проверенной.
class SubmittedWorkReviewed extends SubmittedWorksEvent {
  const SubmittedWorkReviewed(this.work);

  final SubmittedWork work;
}
