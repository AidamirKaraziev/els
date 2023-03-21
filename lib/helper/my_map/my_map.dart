import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

///Карта

class MyMap extends StatefulWidget {
  const MyMap({Key? key}) : super(key: key);
  @override
  _MyMapState createState() => _MyMapState();
}
class _MyMapState extends State<MyMap> {

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      options: MapOptions(
        center: LatLng(45.034604, 39.035051),
        zoom: 17,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.app',
        ),
      ],
    );
  }
}