import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:get/get.dart';
import 'dart:ui' as ui;
import 'package:parentsupport/dashboard/controller/controller.dart';
import 'package:parentsupport/dashboard/model/dashboard_model.dart';
import 'package:parentsupport/dashboard/view/dashboard.dart';
import 'package:parentsupport/locationpage/locationpage_view.dart';

class MarkerController extends GetxController {
  final Map<String, BitmapDescriptor> _iconCache = {};
  var deviceLocations = <String, Marker>{}.obs;
  Set<Marker> get allDeviceMarkers => deviceLocations.values.toSet();
  var homeCircles = <Circle>{}.obs; 
  Set<Circle> get allHomeCircles => homeCircles;
  bool _iconsPreloaded = false;


  @override
  void onInit() {
    super.onInit();
    //preloadIcons(); // Preload icons once during initialization
  }

    @override
  void onClose() {
    _iconCache.clear();
    deviceLocations.clear();
    super.onClose();
  }


  bool isDeviceExpired(String expiryDt) {
    final expiryDate = DateTime.parse(expiryDt);
    final currentDate = DateTime.now();
    return expiryDate.isBefore(currentDate);
  }


  // Future<void> preloadIcons() async {
  //   if (_iconsPreloaded) return; // Prevent reloading icons if already done

  //   try {
  //     log('Starting icon preloading...');
  //     await Future.wait([
  //       loadAndCacheIcon('assets/images/busrun.png', 'running'),
  //       loadAndCacheIcon('assets/images/bushalt.png', 'halt'),
  //       loadAndCacheIcon('assets/images/schoolicon.png', 'school'),
  //       loadAndCacheIcon('assets/images/homeicon.png', 'home'),
  //     ]);
  //     _iconsPreloaded = true; // Mark as loaded
  //     log('Icons preloaded successfully');
  //   } catch (e) {
  //     log('Error preloading icons: $e');
  //   }
  // }




// Future<void> loadAndCacheIcon(String path, String key) async {
//   try {
//     final file = await DefaultCacheManager().getSingleFile(path);
//     final bytes = await file.readAsBytes();
//     final ui.Codec codec = await ui.instantiateImageCodec(bytes);
//     final ui.FrameInfo fi = await codec.getNextFrame();
//     final ui.Image resizedImage = await fi.image.toByteData(format: ImageByteFormat.png);
//     _iconCache[key] = BitmapDescriptor.fromBytes(resizedImage.buffer.asUint8List());
//     log('Icon $key cached successfully');
//   } catch (e) {
//     log('Error caching icon $path: $e');
//   }
// }



  Future<void> updateDeviceLocation(String imei, double lat, double lon) async {
    try {
      final deviceDetailsList =
          Get.find<DashboardController>().deviceDetailsList;
      final vehicleDetail =
          deviceDetailsList.firstWhereOrNull((detail) => detail.imei == imei);

      if (vehicleDetail == null) return;
      if (isDeviceExpired(vehicleDetail.expiryDt)) return;

      BusStatus busStatus = getBusStatus(vehicleDetail.deviceIgnition);
      BitmapDescriptor busIcon = _getIconForStatus(busStatus);

      // Create custom marker for vehicle number above the bus marker
      final balloonIcon =
          await _createMarkerWithBalloon(vehicleDetail.vehicleNo);

      final busMarker = Marker(
        markerId: MarkerId('${imei}_busIcon'),
        position: LatLng(lat, lon),
        icon: busIcon,
        anchor: const Offset(0.5, 0.5),
        rotation: double.tryParse(vehicleDetail.deviceCourse) ?? 0.0,
        infoWindow: InfoWindow(
            title: vehicleDetail.vehicleNo,
            snippet: 'Speed: ${vehicleDetail.deviceSpeed} km/h'),
      );

      final textMarker = Marker(
        markerId: MarkerId('${imei}_text'),
        position: LatLng(lat, lon),
        icon: balloonIcon,
        anchor: const Offset(0.5, 2.2), // Place it on top of the bus marker
      );

      deviceLocations[imei] = busMarker;
      deviceLocations['${imei}_text'] = textMarker;

      // Fetch and add school and home markers
      await _addSchoolAndHomeMarkers(vehicleDetail);

      deviceLocations.refresh();
    } catch (e) {
      log('Error updating device location: $e');
    }
  }

  // Create text-based marker with vehicle number
  Future<BitmapDescriptor> _createMarkerWithBalloon(String vehicleNo) async {
    final textPainter = TextPainter(
      text: TextSpan(
          text: vehicleNo,
          style: const TextStyle(
              color: Colors.black, fontSize: 35, fontWeight: FontWeight.bold)),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    final width = textPainter.width + 16;
    final height = textPainter.height + 8;

    final recorder = PictureRecorder();
    final canvas = Canvas(
        recorder, Rect.fromPoints(const Offset(0, 0), Offset(width, height)));
    final paint = Paint()..color = Colors.white;
    final rect = Rect.fromLTWH(0, 0, width, height);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(4));
    canvas.drawRRect(rrect, paint);

    textPainter.paint(canvas, const Offset(8, 4));

    final picture = recorder.endRecording();
    final img = await picture.toImage(width.toInt(), height.toInt());
    final byteData = await img.toByteData(format: ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
  }

  // Add school and home markers
  Future<void> _addSchoolAndHomeMarkers(DeviceDetails vehicleDetail) async {
    final schoolLat = double.tryParse(vehicleDetail.schoolLat) ?? 0.0;
    final schoolLng = double.tryParse(vehicleDetail.schoolLng) ?? 0.0;
    final homeLat = double.tryParse(vehicleDetail.homeLat) ?? 0.0;
    final homeLng = double.tryParse(vehicleDetail.homeLng) ?? 0.0;

    if (schoolLat != 0.0 && schoolLng != 0.0) {
      final schoolMarker = Marker(
        markerId: MarkerId('${vehicleDetail.imei}_school'),
        position: LatLng(schoolLat, schoolLng),
        icon: _iconCache['school'] ?? BitmapDescriptor.defaultMarker,
        infoWindow: InfoWindow(
            title: 'School',
            snippet: '${vehicleDetail.vehicleNo} School Location'),
      );
      deviceLocations['${vehicleDetail.imei}_school'] = schoolMarker;
    }

    if (homeLat != 0.0 && homeLng != 0.0) {
      final homeMarker = Marker(
        markerId: MarkerId('${vehicleDetail.imei}_home'),
        position: LatLng(homeLat, homeLng),
        icon: _iconCache['home'] ?? BitmapDescriptor.defaultMarker,
        infoWindow: InfoWindow(
            title: 'Home', snippet: '${vehicleDetail.vehicleNo} Home Location'),
      );
      deviceLocations['${vehicleDetail.imei}_home'] = homeMarker;
    }
  }

  void addHomeRadiusCircle(double lat, double lng, double radius) {
    // Create a Circle around the home location
    final homeCircle = Circle(
      circleId: CircleId('home_radius'),
      center: LatLng(lat, lng),
      radius: radius, // Set the radius in meters
      strokeColor: Colors.blue.withOpacity(0.5),
      strokeWidth: 2,
      fillColor: Colors.blue.withOpacity(0.2),
    );

    // Add the circle to the homeCircles set
    homeCircles.add(homeCircle);
    homeCircles.refresh(); // Refresh to update UI with the new circle
  }

  // Return the appropriate icon for the bus status
  BitmapDescriptor _getIconForStatus(BusStatus status) {
    switch (status) {
      case BusStatus.offline:
        return _iconCache['offline'] ?? BitmapDescriptor.defaultMarker;
      case BusStatus.running:
        return _iconCache['running'] ?? BitmapDescriptor.defaultMarker;
      case BusStatus.halt:
        return _iconCache['halt'] ?? BitmapDescriptor.defaultMarker;
      default:
        return BitmapDescriptor.defaultMarker;
    }
  }
}

BusStatus getBusStatus(String ignitionStatus) {
  switch (ignitionStatus) {
    case '1':
      return BusStatus.running;
    case '0':
      return BusStatus.halt;
    default:
      return BusStatus.offline;
  }
}

enum BusStatus { offline, running, halt }

Color getBusStatusColor(String ignitionStatus) {
  switch (ignitionStatus) {
    case '1': // Running
      return Colors.green; // Green for running
    case '0': // Halt
      return const Color.fromARGB(255, 207, 152, 0); // Yellow for halt
    default: // Offline
      return Colors.red; // Red for offline
  }
}
