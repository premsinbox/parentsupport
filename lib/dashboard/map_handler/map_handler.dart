import 'dart:math';
import 'package:parentsupport/dashboard/mqtt/mqtt_handler.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';


class MapHandler extends GetxController {
  final MqttController mqttController = Get.put(MqttController());
  GoogleMapController? mapController;


  // Call this method to fit all markers in the visible area of the map
  void fitMarkersToMap(Set<Marker> markers) {
    if (mapController == null || markers.isEmpty) return;

    // Create bounds for all markers
    LatLngBounds bounds;
    List<LatLng> markerPositions = markers.map((m) => m.position).toList();

    if (markerPositions.length == 1) {
      bounds = LatLngBounds(
        southwest: markerPositions.first,
        northeast: markerPositions.first,
      );
    } else {
      bounds = _createBounds(markerPositions);
    }

    // Animate camera to fit all markers within the bounds
    mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
  }

  // Helper function to calculate bounds from a list of LatLng positions
  LatLngBounds _createBounds(List<LatLng> positions) {
    double south = positions.map((p) => p.latitude).reduce(min);
    double north = positions.map((p) => p.latitude).reduce(max);
    double west = positions.map((p) => p.longitude).reduce(min);
    double east = positions.map((p) => p.longitude).reduce(max);

    return LatLngBounds(
      southwest: LatLng(south, west),
      northeast: LatLng(north, east),
    );
  }

  // Call this in onMapCreated to initialize the controller
  void onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  // Animate the camera to the device's location
  void animateToDeviceLocation(LatLng target) {
    mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: target, zoom: 15),
      ),
    );
  }
}
