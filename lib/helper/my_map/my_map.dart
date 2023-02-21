import 'package:flutter/material.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:latlong/latlong.dart';
import 'dart:async';
import 'package:location/location.dart';

///Карта



// class MyMap extends StatefulWidget {
//   MyMap({Key? key}) : super(key: key);
//   @override
//   _MyMapState createState() => _MyMapState();
// }
// class _MyMapState extends State<MyMap> {
//
//   MapController controller = MapController(
//     initMapWithUserPosition: false,
//     initPosition: GeoPoint(latitude: 47.4358055, longitude: 8.4737324),
//     areaLimit: BoundingBox(
//       east: 10.4922941,
//       north: 47.8084648,
//       south: 45.817995,
//       west:  5.9559113,
//     ),
//   );
// // or
//
//   MapController mapController = MapController.withPosition(
//     initPosition: GeoPoint(
//       latitude: 47.4358055,
//       longitude: 8.4737324
//       ,),
//     areaLimit: BoundingBox(
//       east: 10.4922941,
//       north: 47.8084648,
//       south: 45.817995,
//       west:  5.9559113,
//     ),
//   );
//
//   Location location = Location();
//   var latlong;
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: latlong == null ? Center(child: Text('loading...')) : maps(),
//       floatingActionButton: FloatingActionButton(
//         onPressed: null,
//         tooltip: 'Increment',
//         child: Icon(Icons.add),
//       ),
//     );
//   }
//   // ignore: must_call_super
//   void didChangeDependencies() async {
//     Timer timer = Timer.periodic(Duration(seconds: 1), (_) {
//       location.getLocation().then((p) {
//         setState(() {
//
//           print(p.latitude);
//         });
//       });
//     });
//   }
//   maps() {
//     return OSMFlutter(
//       controller:mapController,
//       trackMyPosition: false,
//       initZoom: 12,
//       minZoomLevel: 8,
//       maxZoomLevel: 14,
//       stepZoom: 1.0,
//       userLocationMarker: UserLocationMaker(
//         personMarker: MarkerIcon(
//           icon: Icon(
//             Icons.location_history_rounded,
//             color: Colors.red,
//             size: 48,
//           ),
//         ),
//         directionArrowMarker: MarkerIcon(
//           icon: Icon(
//             Icons.double_arrow,
//             size: 48,
//           ),
//         ),
//       ),
//       roadConfiguration: RoadConfiguration(
//         startIcon: MarkerIcon(
//           icon: Icon(
//             Icons.person,
//             size: 64,
//             color: Colors.brown,
//           ),
//         ),
//         roadColor: Colors.yellowAccent,
//       ),
//       markerOption: MarkerOption(
//           defaultMarker: MarkerIcon(
//             icon: Icon(
//               Icons.person_pin_circle,
//               color: Colors.blue,
//               size: 56,
//             ),
//           )
//       ),
//     );;
//   }
// }
