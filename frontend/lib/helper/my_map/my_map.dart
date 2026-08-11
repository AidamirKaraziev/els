import 'package:els/helper/class_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../screns/companies/widgets/AddObjectSelectedCompany.dart';
import '../../screns/home_page/home_page.dart';
import '../../screns/object/view/object_screen.dart';
import 'package:geolocator/geolocator.dart';
import '../button/my_button.dart';

/// Карта основная

var lat;
var long;

// dataObject[0]['geo']

///Карта всех объектов =====================
class MyMap extends StatefulWidget {
  const MyMap({Key? key}) : super(key: key);

  @override
  _MyMapState createState() => _MyMapState();
}
class _MyMapState extends State<MyMap> {

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    /// Проверяем, включены ли службы определения местоположения
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      /// Службы определения местоположения не включены, не продолжайте
      /// получаем доступ к позиции и запрашиваем пользователей
      /// Приложение для включения служб определения местоположения.
      return Future.error('Службы определения местоположения отключены.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        /// В разрешениях отказано, попробуйте в следующий раз
        /// снова запрашиваем разрешения (здесь также)
        /// Android должен показывать обоснование запроса разрешения
        /// вернуло истину. Согласно рекомендациям Android
        /// теперь ваше приложение должно отображать поясняющий пользовательский интерфейс.
        return Future.error('Разрешения на определение местоположения запрещены');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      /// Разрешения запрещены навсегда, обрабатывайте соответствующим образом.
      return Future.error(
          'Разрешения на определение местоположения навсегда запрещены, мы не можем запросить разрешения.');
    }

    /// Когда мы доберемся сюда, разрешения будут предоставлены, и мы сможем
    /// продолжаем получать доступ к положению устройства.
    return await Geolocator.getCurrentPosition();
  }

  @override
  void initState() {
    _determinePosition();
    _determinePosition().then((value){
      lat = value.latitude;
      long = value.longitude;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _calculateCenter();
      /// это временно
      _zoom();
      ///==========
    });
    print('=======$lat ============== $long =========');

    // TODO: implement initState
    super.initState();

  }

  double currentZoom = 17.0;
  MapController mapController = MapController();
  // LatLng currentCenter = LatLng(45.02940966586966, 39.04147912461196);


  void _zoom() {
    if(currentZoom > 3) {
      currentZoom = mapController.camera.zoom - 1;
    }
    mapController.move(mapController.camera.center, currentZoom);
  }
  void _zoomPlus() {
    if(currentZoom < 18) {
      currentZoom = mapController.camera.zoom + 1;
    }
    mapController.move(mapController.camera.center, currentZoom);
  }

  LatLng? _center;

  void _calculateCenter() {
    if (getAllObject.isEmpty) return;
    double minLat = double.parse(getAllObject[0]['geo'].split(',')[0]);
    double maxLat = double.parse(getAllObject[0]['geo'].split(',')[0]);
    double minLng = double.parse(getAllObject[0]['geo'].split(',')[1]);
    double maxLng = double.parse(getAllObject[0]['geo'].split(',')[1]);

    for (var loc in getAllObject) {
      minLat = double.parse(loc['geo'].split(',')[0]) < minLat ? double.parse(loc['geo'].split(',')[0]) : minLat;
      maxLat = double.parse(loc['geo'].split(',')[0]) > maxLat ? double.parse(loc['geo'].split(',')[0]) : maxLat;
      minLng = double.parse(loc['geo'].split(',')[1]) < minLng ? double.parse(loc['geo'].split(',')[1]) : minLng;
      maxLng = double.parse(loc['geo'].split(',')[1]) > maxLng ? double.parse(loc['geo'].split(',')[1]) : maxLng;
    }

    // Определим границы
    LatLngBounds bounds = LatLngBounds(
      LatLng(minLat, minLng),
      LatLng(maxLat, maxLng),
    );

    // Обновим контроллер карты для отображения всех точек
    mapController.fitCamera(CameraFit.bounds(bounds: bounds));


    _center = LatLng((minLat + maxLat) / 2, (minLng + maxLng) / 2);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
              backgroundColor: ColorApp.myColorGreen,
              onPressed: _zoomPlus, child: const Icon(Icons.add)),
          const SizedBox(height: 10.0),
          FloatingActionButton(
              backgroundColor: ColorApp.myColorGreen,
              onPressed: _zoom, child: const Icon(Icons.remove)),
        ],
      ),
      body: FlutterMap(
        mapController: mapController,
        options: MapOptions(
          initialZoom: currentZoom,
          // minZoom: 18.0,
          onTap: (pos, myLatLong) {
            setState(() {});
            print('${pos.relative} ${myLatLong.longitude}');
          },
          initialCenter: _center ?? const LatLng(45.034604, 39.035051),
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.app',
          ),
          // dataObject[0]['geo']

          MarkerLayer(
            markers: [
              for(var i = 0; i < getAllObject.length; i++)
              Marker(
                point: LatLng(double.parse(getAllObject[i]['geo'].split(',')[0]), double.parse(getAllObject[i]['geo'].split(',')[1])),
                width: 50,
                height: 50,
                child:
                    Tooltip(
                      message: '${getAllObject[i]['name']}',
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(25),
                          color: Colors.white.withOpacity(0.7),
                        ),
                        child: InkWell(
                          onTap: () async {
                            // print(dataObject[i]['name']);
                            // print(dataObject[i]['type_object_id']['id']);
                            setState(() {
                              showDialog(
                                  context: context,
                                  builder: (context) =>
                                      AlertDialog(
                                          content: StreamBuilder(
                                              stream: myStream.stream,
                                              builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                                                return SizedBox(
                                                  width: 300.0,
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      /// Текст кнопка закрыть
                                                      Row(
                                                        children: [
                                                          /// Текст
                                                          Text(
                                                            '${getAllObject[i]['factory_model_id']['type_object_id']['name']}',
                                                            style: const TextStyle(
                                                                fontWeight: FontWeight.w700,
                                                                fontSize:  25.0),
                                                          ),
                                                          const Spacer(),
                                                          /// кнопка закрыть
                                                          IconButton(
                                                              onPressed: () {
                                                                Navigator.pop(context);
                                                              },
                                                              icon: const Icon(
                                                                Icons.close,
                                                                color: ColorApp.myColorGreenAuth,
                                                              )),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 20.0),
                                                      Container(
                                                        padding: const EdgeInsets.all(5.0),
                                                        decoration: BoxDecoration(
                                                          borderRadius: BorderRadius.circular(5.0),
                                                          border: Border.all(color: Colors.green,width: 1.0),
                                                        ),
                                                        child: Text('${getAllObject[i]['name']}',
                                                          style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize:  18.0),),
                                                      ),
                                                      const SizedBox(height: 10.0),
                                                      Container(
                                                        padding: const EdgeInsets.all(5.0),
                                                        decoration: BoxDecoration(
                                                          borderRadius: BorderRadius.circular(5.0),
                                                          border: Border.all(color: Colors.green,width: 1.0),
                                                        ),
                                                        child: Text('${getAllObject[i]['mechanic_id']['name']}',
                                                          style: const TextStyle(
                                                              fontWeight: FontWeight.w600,
                                                              fontSize:  18.0),),
                                                      ),
                                                      const SizedBox(height: 10.0),
                                                      Container(
                                                        padding: const EdgeInsets.all(5.0),
                                                        decoration: BoxDecoration(
                                                          borderRadius: BorderRadius.circular(5.0),
                                                          border: Border.all(color: Colors.green,width: 1.0),
                                                        ),
                                                        child: Text('${getAllObject[i]['foreman_id']['name']}',
                                                          style: const TextStyle(
                                                              fontWeight: FontWeight.w600,
                                                              fontSize:  18.0),),
                                                      ),
                                                      const SizedBox(height: 10.0),
                                                      Container(
                                                        padding: const EdgeInsets.all(5.0),
                                                        decoration: BoxDecoration(
                                                          borderRadius: BorderRadius.circular(5.0),
                                                          border: Border.all(color: Colors.green,width: 1.0),
                                                        ),
                                                        child: Text('${getAllObject[i]['contact_person_id']['name']}',
                                                          style: const TextStyle(
                                                              fontWeight: FontWeight.w600,
                                                              fontSize:  18.0),),
                                                      ),
                                                      const SizedBox(height: 30.0),
                                                      MainButtonApp(textButton: 'Перейти в объект', press: () async {
                                                        await getListObjectInfo(getAllObject[i]['id']);
                                                        myStream.add(IntTest.indexScreens);
                                                        IntTest.indexScreens = 10;
                                                        Navigator.pop(context);
                                                      },),
                                                    ],
                                                  ),
                                                );})

                                      ));
                            });
                          },
                          child:
                          // dataObject[i]['factory_model_id']['type_object_id']['id'] == 2 ?
                          Center(
                            child: Image.asset(
                              getAllObject[i]['factory_model_id']['type_object_id']['id'] == 1
                                    ? 'assets/lift1.2.png'
                                    : getAllObject[i]['factory_model_id']['type_object_id']['id'] == 2
                                    ? 'assets/lift1.2.png'
                                    : getAllObject[i]['factory_model_id']['type_object_id']['id'] == 3
                                    ? 'assets/escalator1.png'
                                    : getAllObject[i]['factory_model_id']['type_object_id']['id'] == 4
                                    ? 'assets/escalator1.png'
                                    : getAllObject[i]['factory_model_id']['type_object_id']['id'] == 5
                                    ? 'assets/lift5.png'
                                    : 'assets/lift6.png',
                                    width: 30,
                              height: 30,
                            ),
                          ) ,
                            //   : Container(
                            // decoration: BoxDecoration(
                            //   borderRadius: BorderRadius.circular(25.0),
                            //   color: Colors.green),
                            // child:  Center(child: Text('${dataObject[i]['factory_model_id']['type_object_id']['id']}',style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold),)),),
                        ),
                      ),
                    ),
              ),
            ],
          ),
          // MarkerLayer(
          //   markers: [
          //     Marker(
          //       point: LatLng(myLatLong.longitude, myLatLong.latitude),
          //       width: 80,
          //       height: 80,
          //       child: const Icon(Icons.home_outlined,size: 40, ),
          //     ),
          //   ],
          // ),
        ],
      ),
    );
  }
}
/// ========================================


///Карта выбраного объекта =============================
class MyMapObject extends StatefulWidget {
  const MyMapObject({Key? key}) : super(key: key);

  @override
  State<MyMapObject> createState() => _MyMapObjectState();
}
class _MyMapObjectState extends State<MyMapObject> {

   double latObject = double.parse(listSelectedObject['data']['geo'].split(',')[0]);
   double longObject = double.parse(listSelectedObject['data']['geo'].split(',')[1]);
  var myLat;
  var myLatLong;


  double currentZoom = 17.0;
  MapController mapController = MapController();
  LatLng currentCenter = LatLng(double.parse(listSelectedObject['data']['geo'].split(',')[0]), double.parse(listSelectedObject['data']['geo'].split(',')[1]));

  @override
  void initState() {
    if(currentCenter == 'strind'){
      latObject = 45.02940966586966;
      longObject = 39.04147912461196;
      print('карта');
    }
    // TODO: implement initState
    super.initState();
  }

  void _zoom() {
    if(currentZoom > 3) {
      currentZoom = currentZoom - 1;
    }
    mapController.move(currentCenter, currentZoom);
  }
  void _zoomPlus() {
    if(currentZoom < 18) {
      currentZoom = currentZoom + 1;
    }
    mapController.move(currentCenter, currentZoom);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
              backgroundColor: ColorApp.myColorGreen,
              onPressed: _zoomPlus, child: const Icon(Icons.add)),
          const SizedBox(height: 10.0),
          FloatingActionButton(
              backgroundColor: ColorApp.myColorGreen,
              onPressed: _zoom, child: const Icon(Icons.remove)),
        ],
      ),
      body: FlutterMap(
        mapController: mapController,
        options: MapOptions(
          initialZoom: currentZoom,
          // minZoom: 18.0,
          onTap: (pos, myLatLong) {
            setState(() {});
            print('${pos.relative} ${myLatLong.longitude}');
          },
          initialCenter: currentCenter,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.app',
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: LatLng(latObject, longObject),
                width: 40,
                height: 40,
                child:
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(25.0),
                        color: Colors.green,),
                      child: const Center(child: Text('3',style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold),)),),
              ),
            ],
          ),
          // MarkerLayer(
          //   markers: [
          //     Marker(
          //       point: LatLng(myLat.longitude, myLatLong.latitude),
          //       width: 80,
          //       height: 80,
          //       child: const Icon(Icons.home_outlined,size: 40, ),
          //     ),
          //   ],
          // ),
        ],
      ),
    );
  }
}
/// ====================================================


///Карта выбраного объекта в графиках ==================================
class MyMapScheduleObject extends StatefulWidget {
  const MyMapScheduleObject({Key? key}) : super(key: key);

  @override
  State<MyMapScheduleObject> createState() => _MyMapScheduleObjectState();
}
class _MyMapScheduleObjectState extends State<MyMapScheduleObject> {

  double latObject = double.parse(listSelectedObject['data']['geo'].split(',')[0]);
  double longObject = double.parse(listSelectedObject['data']['geo'].split(',')[1]);
  var myLat;
  var myLatLong;


  double currentZoom = 17.0;
  MapController mapController = MapController();
  LatLng currentCenter = LatLng(double.parse(listSelectedObject['data']['geo'].split(',')[0]), double.parse(listSelectedObject['data']['geo'].split(',')[1]));

  @override
  void initState() {
    if(currentCenter == 'strind'){
      latObject = 45.02940966586966;
      longObject = 39.04147912461196;
      print('карта');
    }
    // TODO: implement initState
    super.initState();
  }

  void _zoom() {
    if(currentZoom > 3) {
      currentZoom = currentZoom - 1;
    }
    mapController.move(currentCenter, currentZoom);
  }
  void _zoomPlus() {
    if(currentZoom < 18) {
      currentZoom = currentZoom + 1;
    }
    mapController.move(currentCenter, currentZoom);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
              backgroundColor: ColorApp.myColorGreen,
              onPressed: _zoomPlus, child: const Icon(Icons.add)),
          const SizedBox(height: 10.0),
          FloatingActionButton(
              backgroundColor: ColorApp.myColorGreen,
              onPressed: _zoom, child: const Icon(Icons.remove)),
        ],
      ),
      body: FlutterMap(
        mapController: mapController,
        options: MapOptions(
          initialZoom: currentZoom,
          // minZoom: 18.0,
          onTap: (pos, myLatLong) {
            setState(() {});
            print('${pos.relative} ${myLatLong.longitude}');
          },
          initialCenter: currentCenter,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.app',
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: LatLng(latObject, longObject),
                width: 40,
                height: 40,
                child:
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(25.0),
                        color: Colors.green,),
                      child: const Center(child: Text('3',style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold),)),),
              ),
            ],
          ),
          // MarkerLayer(
          //   markers: [
          //     Marker(
          //       point: LatLng(myLat.longitude, myLatLong.latitude),
          //       width: 80,
          //       height: 80,
          //       child: const Icon(Icons.home_outlined,size: 40, ),
          //     ),
          //   ],
          // ),
        ],
      ),
    );
  }
}
/// ====================================================================






