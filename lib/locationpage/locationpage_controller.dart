import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:parentsupport/dashboard/model/dashboard_model.dart';
import 'package:parentsupport/dashboard/view/dashboard.dart';
import 'package:parentsupport/utils/utils.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';


class LocationController extends GetxController {
  GoogleMapController? mapController;
  LatLng? currentLocation;
  Marker? marker;
  Set<Circle> circles = {};
  bool isLoading = true;
  double radius = 100; // Default radius in meters
  var deviceLocations = <String, Marker>{}.obs;
  var locationUpdated = false.obs; // Flag to notify the DashboardController
   var homeLat = 0.0.obs;
  var homeLng = 0.0.obs;
  TextEditingController latLngController = TextEditingController();
  TextEditingController radiusController = TextEditingController();
  var isLatLngValid = true.obs; // Add this line
  var isRadiusValid = true.obs; // Optional if you want radius validation
  late BitmapDescriptor customMarkerIcon;

  @override
  void onInit() {
    super.onInit();
    _loadCustomMarker();
    latLngController.text =
        '${currentLocation?.latitude ?? ''}, ${currentLocation?.longitude ?? ''}';
  }


  bool isHomeLocationSet() {
    return homeLat.value != 0.0 || homeLng.value != 0.0;
  }

  void updateHomeLocation(double lat, double lng) {
    homeLat.value = lat;
    homeLng.value = lng;
  }

  Future<void> loadInitialHomeLocation(DeviceDetails vehicleDetail) async {
    try {
      final homeLat = double.tryParse(vehicleDetail.homeLat) ?? 0.0;
      final homeLng = double.tryParse(vehicleDetail.homeLng) ?? 0.0;
      final homeRadius = double.tryParse(vehicleDetail.homeRadius) ?? 0.0;

      if (homeLat != 0.0 && homeLng != 0.0) {
        currentLocation = LatLng(homeLat, homeLng);
        updateMarker(currentLocation!);
        radius = homeRadius;  // Set the initial radius
        radiusController.text = homeRadius.toStringAsFixed(0);  // Set the TextField value
        isLoading = false; // Set loading to false after fetching the location
        update();
      } else {
        log('Invalid home location coordinates');
      }
    } catch (e) {
      log('Error loading initial home location: $e');
      isLoading = false;
      update();
    }
  }

    void _loadCustomMarker() async {
    customMarkerIcon = await BitmapDescriptor.fromAssetImage(
      ImageConfiguration(devicePixelRatio: 2.5),
      'assets/images/homeicon.png', // Path to your custom marker image
    );
  }

  Future<void> requestLocationPermission(BuildContext context) async {
    if (await Permission.location.request().isGranted) {
      await getCurrentLocation();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Location permission is required to access the map.'),
        ),
      );
    }
  }

  Future<void> showConfirmationDialog(BuildContext context) async {
    final result = await showDialog<bool>( 
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Confirm Location'),
          content: Text('Do you want to fix this location as your home?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text('OK'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      fixLocation(); // Call fixLocation only when the user confirms
    }
  }

  Future<void> getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      currentLocation = LatLng(position.latitude, position.longitude);
      updateMarker(currentLocation!);
      isLoading = false;
      update();
    } catch (e) {
      log('Error fetching location: $e');
    }
  }



  void updateCircles() {
    if (currentLocation != null) {
      circles = {
        Circle(
          circleId: const CircleId('radius'),
          center: currentLocation!,
          radius: radius,
          fillColor: Colors.blue.withOpacity(0.2),
          strokeColor: Colors.blue,
          strokeWidth: 2,
        ),
      };
      update();
    }
  }

  void animateToCurrentLocation() {
    if (mapController != null && currentLocation != null) {
      mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(currentLocation!, 15),
      );
    }
  }

  void updateMarker(LatLng position) {
    marker = Marker(
      markerId: const MarkerId('dropped_pin'),
      position: position,
      infoWindow: const InfoWindow(title: 'Dropped Pin'),
      draggable: true,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      onDragEnd: (newPosition) {
        currentLocation = newPosition;
        updateLatLngTextBox(newPosition);
        updateCircles();
      },
    );
    currentLocation = position;
    updateLatLngTextBox(position);
    updateCircles();
    update();
  }

  void updateLatLngTextBox(LatLng position) {
    latLngController.text = '${position.latitude}, ${position.longitude}';
  }

 Future<void> fixLocation() async {
  try {
    final latLng = latLngController.text.split(',');
    if (latLng.length != 2) {
      throw Exception('Invalid latitude and longitude format');
    }

    final latitude = double.tryParse(latLng[0].trim());
    final longitude = double.tryParse(latLng[1].trim());

    if (latitude == null || longitude == null) {
      throw Exception('Invalid latitude or longitude value');
    }

    // Prevent updating for (0,0) coordinates
    if ((latitude.toString().startsWith('0.') || latitude == 0.0) &&
    (longitude.toString().startsWith('0.') || longitude == 0.0)) {
      Get.snackbar(
        'Error',
        'Invalid location. You cannot set a marker at (0,0).',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
      return;
    }

    final radius = double.tryParse(radiusController.text.trim());

    if (radius == null || radius <= 0) {
      throw Exception('Please enter a valid radius greater than 0');
    }

    final locationString = '${latitude.toStringAsFixed(6)},${longitude.toStringAsFixed(6)}';

    final Map<String, String> requestBody = {
      'action': 'update_home_location',
      'mobile': '9080701219',
      'location': locationString,
      'km': radius.toStringAsFixed(1),
    };

    final response = await http.post(
      Uri.parse('http://${Utils.ipaddress}/schools/api/school_app_api.php'),
      body: json.encode(requestBody),
    ).timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        throw Exception('Request timed out');
      },
    );

    if (response.statusCode == 200 &&
        (response.body.isEmpty || response.body.trim().toLowerCase() == 'ok')) {
      homeLat.value = latitude;
      homeLng.value = longitude;
      locationUpdated.value = true;

      Get.snackbar(
        'Success',
        'Home location updated successfully',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
      );
      Get.off(() => Dashboard());
    } else {
      throw Exception('Unexpected response: ${response.body}');
    }
  } catch (e) {
    Get.snackbar(
      'Error',
      'Failed to update home location: $e',
      backgroundColor: Colors.red,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 5),
    );
  } finally {
    locationUpdated.value = false;
  }
}

  

  Future<void> updateRadius(double newRadius) async {
    radius = newRadius;
    updateCircles();
    update();

    // Update the API with the new radius
    await fixLocation(); // Call directly after user input is finished
  }
}
