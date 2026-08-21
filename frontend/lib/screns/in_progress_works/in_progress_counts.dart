import 'package:flutter/foundation.dart';

/// Сколько работ идёт прямо сейчас и сколько из них встало с проблемой.
///
/// Одна пара чисел на всё приложение: её показывает боковое меню, а меняет
/// раздел «Сейчас в работе», когда получает свежий ответ. Держим в
/// `ValueNotifier` — тем же приёмом, что и счётчик непросмотренного
/// (`unreviewed_counter.dart`), чтобы меню перерисовывалось само.
///
/// Числа берутся из той же ручки, что и список раздела: считать их отдельным
/// запросом значило бы завести второе место, где они могут разойтись с лентой.
/// За ними меню не ходит: пока прораб сидит в «Объектах», числа стоят на
/// последнем известном значении.
@immutable
class InProgressCounts {
  const InProgressCounts({required this.total, required this.problems});

  static const InProgressCounts none =
      InProgressCounts(total: 0, problems: 0);

  /// Сколько работ идёт всего — считая те, что не поместились в список.
  final int total;

  /// Сколько из них встало с проблемой.
  final int problems;

  @override
  bool operator ==(Object other) =>
      other is InProgressCounts &&
      other.total == total &&
      other.problems == problems;

  @override
  int get hashCode => Object.hash(total, problems);
}

final ValueNotifier<InProgressCounts> inProgressCounts =
    ValueNotifier<InProgressCounts>(InProgressCounts.none);
