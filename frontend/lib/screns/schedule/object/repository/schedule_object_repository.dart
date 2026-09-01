import '../models/schedule_object_card.dart';

/// Откуда экран берёт карточку объекта.
///
/// Интерфейс, а не класс: на фазе отрисовки под ним стоит фикстура, в `S2.2`
/// — та же подпись поверх ручки объекта. Экран и блок при подмене не меняются.
abstract class ScheduleObjectRepository {
  /// Карточка объекта: три верхних блока экрана целиком.
  Future<ScheduleObjectCard> fetchCard(int objectId);
}
