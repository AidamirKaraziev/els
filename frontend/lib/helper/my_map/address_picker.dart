import 'package:flutter/material.dart';
import 'package:location_picker_flutter_map/location_picker_flutter_map.dart';

import 'package:els/helper/app_config.dart';

/// Выбор адреса объекта на карте OpenStreetMap.
///
/// Единственное место в приложении, которое знает про пакет-выборщик точки.
/// Раньше виджет из `open_street_map_search_and_pick` вставлялся напрямую в три
/// экрана (`add_object`, `add_object_companies`, `add_object_foreman`), и разбор
/// адреса был скопирован в каждый из них. Пакет заброшен с декабря 2023 и держал
/// `flutter_map ^3`, поэтому заменён на живой `location_picker_flutter_map`.
///
/// Экранам про это знать не нужно: они получают готовую строку адреса и
/// координаты. Следующая замена пакета — правка одного этого файла.
class AddressPicker extends StatelessWidget {
  const AddressPicker({
    super.key,
    required this.onPicked,
    this.initialCenter = const LatLong(45.034604, 39.035051),
    this.buttonText = '+ добавить адресс',
  });

  /// Отдаёт улицу с номером дома и координаты выбранной точки.
  final void Function(String address, double latitude, double longitude)
      onPicked;

  /// Куда смотрит карта при открытии. По умолчанию — Краснодар.
  final LatLong initialCenter;

  final String buttonText;

  /// Улица и номер дома, если геокодер их вернул.
  ///
  /// Раньше строка собиралась как `'${address['road']} ${address['house_number']}'`
  /// без проверок, и при неполном ответе в поле адреса уезжало «null null».
  static String _formatAddress(PickedData data) {
    final road = data.addressData['road'] as String?;
    final houseNumber = data.addressData['house_number'] as String?;

    if (road == null || road.isEmpty) return data.address;
    if (houseNumber == null || houseNumber.isEmpty) return road;
    return '$road $houseNumber';
  }

  @override
  Widget build(BuildContext context) {
    return FlutterLocationPicker(
      userAgent: AppConfig.osmUserAgent,
      initPosition: initialCenter,
      selectLocationButtonText: buttonText,
      selectLocationButtonStyle: ButtonStyle(
        backgroundColor: WidgetStatePropertyAll(Colors.green.shade300),
      ),
      onPicked: (pickedData) => onPicked(
        _formatAddress(pickedData),
        pickedData.latLong.latitude,
        pickedData.latLong.longitude,
      ),
    );
  }
}
