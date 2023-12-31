import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Google Maps',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late Timer _timer;

  Location location = Location();
  LatLng? currentLocation;
  LocationData? _locationData;
  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();

  List<LatLng> polylineCoordinates = [];
  Set<Polyline> polylines = {};

  @override
  void initState() {
    super.initState();
    getLocationUpdate();
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      getLocationUpdate();
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Google Map")),
      body: _locationData == null
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : GoogleMap(
              initialCameraPosition: CameraPosition(
                  target: LatLng(
                      _locationData!.latitude!, _locationData!.longitude!),
                  zoom: 15),
              mapType: MapType.normal,
              onMapCreated: (GoogleMapController controller) {
                _controller.complete(controller);
              },
              markers: {
                Marker(
                  infoWindow: InfoWindow(
                    title: 'My Current Location',
                    snippet:
                        '${_locationData!.latitude},${_locationData!.longitude}',
                  ),
                  markerId: const MarkerId('user_location'),
                  icon: BitmapDescriptor.defaultMarker,
                  position: LatLng(
                      _locationData!.latitude!, _locationData!.longitude!),
                ),
              },
              polylines: polylines,
            ),
    );
  }

  // Function to update the polyline with new coordinates
  void updatePolyline(LatLng newCoordinate) {
    setState(() {
      polylineCoordinates.add(newCoordinate);
      polylines.clear();
      polylines.add(
        Polyline(
          polylineId: const PolylineId("poly"),
          color: Colors.blue,
          points: polylineCoordinates,
        ),
      );
    });
  }

  Future<void> _updateLocation(LatLng location) async {
    final GoogleMapController controller = await _controller.future;
    await controller.animateCamera(CameraUpdate.newCameraPosition(
        CameraPosition(
            zoom: 15, target: LatLng(location.latitude, location.longitude))));
  }

  Future<void> getLocationUpdate() async {
    bool serviceEnabled;
    PermissionStatus permissionGranted;
    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        return;
      }
    }

    permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        return;
      }
    }
    _locationData = await location.getLocation();
    final newCoord =
        LatLng(_locationData!.latitude!, _locationData!.longitude!);
    _updateLocation(newCoord);
    updatePolyline(newCoord);
    setState(() {});

    // location.onLocationChanged.listen((newLocation) async {
    //   if (newLocation.latitude != null && newLocation.longitude != null) {
    //     _locationData = await location.getLocation();
    //     final newCoord = LatLng(newLocation.latitude!, newLocation.longitude!);
    //     _updateLocation(newCoord);
    //     updatePolyline(newCoord);
    //     setState(() {});
    //   }
    // });
  }
}
