part of 'in_progress_works_bloc.dart';

@immutable
abstract class InProgressWorksEvent {
  const InProgressWorksEvent();
}

/// Перечитать раздел. Единственное событие: параметров у ручки нет, и
/// запрашивать частями нечего.
class InProgressWorksRequested extends InProgressWorksEvent {
  const InProgressWorksRequested();
}
