import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:async';
import 'package:location/location.dart';

///Карта

class MyMap extends StatefulWidget {
  MyMap({Key? key}) : super(key: key);
  @override
  _MyMapState createState() => _MyMapState();
}
class _MyMapState extends State<MyMap> {
  Location location = Location();
  var latlong;
  late Marker markerUser;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: latlong == null ? Center(child: Text('loading...')) : maps(),
      floatingActionButton: FloatingActionButton(
        onPressed: null,
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ),
    );
  }
  // ignore: must_call_super
  void didChangeDependencies() async {
    Timer timer = Timer.periodic(Duration(seconds: 1), (_) {
      location.getLocation().then((p) {
        setState(() {
          markerUser = Marker(
            width: 25.0,
            height: 25.0,
            point: LatLng(p.latitude!, p.longitude!),
            builder: (context) => Container(
              child: Icon(
                Icons.navigation,
                color: Colors.indigo,
              ),
            ),
          );
          latlong = p;
          print(p.latitude);
        });
      });
    });
  }
  maps() {
    return FlutterMap(
      options: MapOptions(
        center: LatLng(latlong.latitude, latlong.longitude),
        zoom: 16.0,
      ),
      layers: [
        TileLayerOptions(
          urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
          subdomains: ['a', 'b', 'c'],
        ),
        MarkerLayerOptions(markers: <Marker>[markerUser]),
      ],
    );
  }
}
