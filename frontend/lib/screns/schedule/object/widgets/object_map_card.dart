import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../helper/app_config.dart';
import '../../../../helper/class_colors.dart';
import '../models/schedule_object_card.dart';
import 'object_block.dart';

/// Блок «Местоположение»: карта с меткой объекта.
///
/// Карта перенесена от подрядчика как есть — тот же `flutter_map`, тот же
/// источник тайлов `AppConfig.mapTileUrl`, тот же зелёный кружок вместо метки.
/// Отличие одно: координаты приходят **аргументом**, а не читаются из
/// глобальной `listSelectedObject`. С глобалью карту нельзя ни показать на
/// фикстуре, ни собрать в тесте: она падает на разборе `geo` ещё в поле класса.
///
/// Кнопок зума у подрядчика две, плавающие поверх карты (`FloatingActionButton`
/// в собственном `Scaffold`). На кадре их нет, и второй `Scaffold` внутри
/// экрана нам не нужен: масштаб меняется колесом и жестом.
class ObjectMapCard extends StatefulWidget {
  const ObjectMapCard({Key? key, required this.geo}) : super(key: key);

  /// Точка объекта. `null` — координат в карточке нет, показываем плашку.
  final ScheduleGeoPoint? geo;

  @override
  State<ObjectMapCard> createState() => _ObjectMapCardState();
}

class _ObjectMapCardState extends State<ObjectMapCard> {
  /// Приближение, на котором дом виден вместе с улицей — как на кадре.
  static const double _zoom = 15.0;

  static const double _height = 260.0;

  @override
  Widget build(BuildContext context) {
    final ScheduleGeoPoint? geo = widget.geo;
    return ObjectBlock(
      title: 'Местоположение',
      child: Container(
        height: _height,
        decoration: objectCardDecoration(),
        clipBehavior: Clip.antiAlias,
        child: geo == null ? const _NoGeo() : _map(geo),
      ),
    );
  }

  Widget _map(ScheduleGeoPoint geo) {
    final LatLng center = LatLng(geo.latitude, geo.longitude);
    return FlutterMap(
      options: MapOptions(
        initialCenter: center,
        initialZoom: _zoom,
      ),
      children: <Widget>[
        TileLayer(
          urlTemplate: AppConfig.mapTileUrl,
          userAgentPackageName: AppConfig.osmUserAgent,
        ),
        MarkerLayer(
          markers: <Marker>[
            Marker(
              point: center,
              width: 34.0,
              height: 34.0,
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: ColorApp.myColorGreenAuth,
                ),
                child: const Icon(
                  Icons.place,
                  size: 20.0,
                  color: ColorApp.myColorWhite,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// У объекта не заполнен `geo` — вместо карты плашка.
class _NoGeo extends StatelessWidget {
  const _NoGeo({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Нет данных',
        style: TextStyle(color: ColorApp.myColorGrayText),
      ),
    );
  }
}
