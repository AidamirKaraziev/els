import 'schedule_responsible.dart';

/// Точка на карте: разобранная строка `geo` из карточки объекта.
///
/// Бэкенд хранит координаты **одной строкой** `"45.03,39.04"` (`ObjectBase.geo`),
/// и разбирать её в виджете карты нельзя: строка бывает пустой, бывает с
/// мусором, и падать из-за этого должен разбор, а не отрисовка.
class ScheduleGeoPoint {
  const ScheduleGeoPoint(this.latitude, this.longitude);

  final double latitude;
  final double longitude;

  /// Разобрать `geo`. Всё, что не «число, запятая, число», — это `null`, то
  /// есть «координат нет», и экран покажет плашку вместо карты.
  static ScheduleGeoPoint? tryParse(String? geo) {
    if (geo == null) {
      return null;
    }
    final List<String> parts = geo.split(',');
    if (parts.length != 2) {
      return null;
    }
    final double? latitude = double.tryParse(parts[0].trim());
    final double? longitude = double.tryParse(parts[1].trim());
    if (latitude == null || longitude == null) {
      return null;
    }
    return ScheduleGeoPoint(latitude, longitude);
  }
}

/// Карточка объекта на экране графика: всё, что показывают три верхних блока
/// кадра — «Информация об объекте», «Местоположение», «Ответственные».
///
/// Поля названы по `ObjectBase` бэкенда (`backend/src/schemas/object.py`),
/// хотя на экране это плоские строки: карточка приходит одной ручкой объекта,
/// и в `S2.2` разбор ляжет на эти же имена без переименований.
///
/// Почти всё необязательно. Объект в базе заполнен как заполнен: без
/// компании, без контактного лица, без договора — и это не ошибка загрузки,
/// а обычная строка. Пустое поле экран показывает прочерком.
class ScheduleObjectCard {
  const ScheduleObjectCard({
    required this.id,
    this.organization,
    this.division,
    this.address,
    this.type,
    this.model,
    this.modelId,
    this.registrationNumber,
    this.factoryNumber,
    this.company,
    this.contactPerson,
    this.contactPhone,
    this.contract,
    this.geo,
    this.foreman,
    this.mechanic,
  });

  final int id;

  /// `organization_id.name` — чей это объект.
  final String? organization;

  /// `division_id.title` — участок.
  final String? division;

  final String? address;

  /// `factory_model_id.type_object_id.name` — «Лифт», «Эскалатор».
  final String? type;

  /// `factory_model_id.model`.
  final String? model;

  /// `factory_model_id.id` — чья программа обслуживания.
  ///
  /// Нужен мастеру расстановки: программа принадлежит модели, и правится она
  /// по этому id. Из предпросмотра его брать нельзя во всех случаях — у
  /// модели без программы предпросмотр отвечает 404, а окно правки открывать
  /// как раз тогда и надо.
  final int? modelId;

  final String? registrationNumber;
  final String? factoryNumber;

  /// `company_id.name` — обслуживающая компания.
  final String? company;

  /// `contact_person_id.name`.
  final String? contactPerson;

  /// `contact_person_id.phone`. На кадре этой строки нет, но человеку с
  /// экрана надо звонить, а не переходить ради номера в карточку объекта.
  final String? contactPhone;

  /// Договор одной строкой, как на кадре: «Договор №2123 от 24.04.2022».
  final String? contract;

  final ScheduleGeoPoint? geo;

  /// Прораб и механик объекта. `null` — не назначен либо удалён: на кадре
  /// такого случая нет, плашку в этом месте гасим.
  final ScheduleResponsible? foreman;
  final ScheduleResponsible? mechanic;
}
