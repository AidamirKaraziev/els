import '../models/schedule_object_card.dart';
import '../models/schedule_responsible.dart';
import 'schedule_object_repository.dart';

/// Карточка объекта из кадра макета, без сети.
///
/// Нужна, пока внешний вид не утверждён: сеть подключается в `S2.2`, и до тех
/// пор экран должен открываться где угодно — в браузере с отдельной точки
/// входа, в виджет-тесте — не требуя ни входа в систему, ни живой базы.
///
/// Значения взяты с кадра `1182:232` дословно, включая опечатки в кавычках:
/// сверять вёрстку удобнее с тем же текстом, что на картинке.
class FixtureScheduleObjectRepository implements ScheduleObjectRepository {
  const FixtureScheduleObjectRepository({this.delay = Duration.zero});

  /// Задержка ответа. По умолчанию мгновенно; ненулевая нужна, только чтобы
  /// посмотреть глазами состояние загрузки.
  final Duration delay;

  @override
  Future<ScheduleObjectCard> fetchCard(int objectId) async {
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    return ScheduleObjectCard(
      id: objectId,
      organization: 'ООО «КПЭК»',
      division: 'Северная/Тургенева',
      address: 'г. Краснодар, ул. Северная, 356',
      type: 'Лифт',
      model: 'LIFT A388509',
      registrationNumber: '23834939003928282',
      factoryNumber: '23834939003928282',
      company: 'ООО "Гармония"',
      contactPerson: 'П.С. Василенко',
      contactPhone: '+7 (918) 456-78-90',
      contract: 'Договор №2123 от 24.04.2022',
      // Точка на кадре — центр Краснодара, там же стоит маркер.
      geo: const ScheduleGeoPoint(45.035470, 38.975313),
      foreman: const ScheduleResponsible(
        title: 'Прораб',
        fullName: 'Н.В. Гоголевский',
      ),
      mechanic: const ScheduleResponsible(
        title: 'Механик',
        fullName: 'Л.А. Терешков',
      ),
    );
  }
}
