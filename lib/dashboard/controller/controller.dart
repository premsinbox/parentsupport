import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:parentsupport/dashboard/map_handler/map_handler.dart';
import 'package:parentsupport/dashboard/markers/marker.dart';
import 'package:parentsupport/dashboard/model/dashboard_model.dart';
import 'package:parentsupport/dashboard/mqtt/mqtt_handler.dart';
import 'package:parentsupport/locationpage/locationpage_controller.dart';
import 'package:parentsupport/locationpage/locationpage_view.dart';
import 'package:parentsupport/utils/utils.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';


class DashboardController extends GetxController {

  final Set<String> processedDevices = {};

  // Observable variables
  var mobile = ''.obs;
  var deviceDetailsList = <DeviceDetails>[].obs;
  var isConnected = true.obs; 
  var isLoading = false.obs; 
  var isRefreshDisabled = false.obs; 
  var isLocationUpdated = false.obs;

  // Dependencies and utilities
  final MqttController mqttController = Get.put(MqttController());
  final MarkerController markerController = Get.put(MarkerController());
  final LocationController locationController = Get.put(LocationController());
  final MapHandler mapHandler = Get.put(MapHandler());
   var isDialogShowing = false.obs;
   
  // Map-related variables
  GoogleMapController? mapController;
  Timer? locationTimer;

  @override
  void onInit() {
    super.onInit();
    // Listen to LocationController's locationUpdated flag
    ever(locationController.locationUpdated, (_) {
      if (locationController.locationUpdated.value) {
        refreshData(); // Trigger the data refresh when location is updated
      }
    });
  }

  /// Fetch device details from API using the provided mobile number
  Future<List<DeviceDetails>> fetchData(String mobileNumber) async {
    try {
      final response = await http.post(
        Uri.parse("http://${Utils.ipaddress}/schools/api/school_app_api.php"),
        body: jsonEncode({
          "action": "get_details",
          "mobile": "9080701219",
        }),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print("Parsed data: $data"); // Log parsed data
        return data.map((item) => DeviceDetails.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      throw Exception('Error fetching data: $e');
    }
  }

/// Refresh data by reloading device details and markers
Future<void> refreshData() async {
  if (isRefreshDisabled.value) return; // Prevent multiple refreshes

  isRefreshDisabled.value = true; // Disable refresh button
  isLoading.value = true; // Show loading indicator

  try {
    // Call the method to refresh the map or other UI elements
    if (isLocationUpdated.value) {
      isLocationUpdated.value = false; // Reset after refreshing
    }

    await _loadPhoneNumber(); // Reload device details

  } catch (e) {
    Get.snackbar('Error', 'Failed to refresh data: $e');
  } finally {
    isLoading.value = false; // Hide loading indicator
    isRefreshDisabled.value = false; // Re-enable refresh button
  }
}


Future<void> _loadPhoneNumber() async {
  try {
    var data = await fetchData(mobile.value);
    deviceDetailsList.value = data.cast<DeviceDetails>();

    // Initialize device markers on the map
    initializeDeviceMarkers(deviceDetailsList);
    print('Device details loaded');

    // Check and fetch home location only if necessary
    for (var device in deviceDetailsList) {
      // Parse homeLat and homeLng
      final homeLat = double.tryParse(device.homeLat);
      final homeLng = double.tryParse(device.homeLng);

      // Fetch home location only if it's 0.0, 0.0
      if (homeLat.toString().startsWith('0.') && homeLng.toString().startsWith('0.') && homeLat == 0.0 && homeLng == 0.0) {
        fetchHomeLocation(device);
      } else {
        print('Home location already set for ${device.vehicleNo}');
      }
    }
  } catch (e) {
    Get.snackbar('Error', 'Failed to load device details: $e');
  }
}

void fetchHomeLocation(DeviceDetails vehicleDetail) async {
  final homeLat = double.tryParse(vehicleDetail.homeLat) ?? 0.0;
  final homeLng = double.tryParse(vehicleDetail.homeLng) ?? 0.0;
  final homeRadius = double.tryParse(vehicleDetail.homeRadius) ?? 0.0;

  // Avoid processing if the device is already marked or home location is valid
  if (processedDevices.contains(vehicleDetail.vehicleNo)) {
    print('Device ${vehicleDetail.vehicleNo} already processed.');
    return;
  }

  print('Checking home location for ${vehicleDetail.vehicleNo}');



  if (homeLat.toString().startsWith('0.') && homeLng.toString().startsWith('0.') && homeLat == 0.0 && homeLng == 0.0 && !isDialogShowing.value) {
    isDialogShowing.value = true; // Prevent multiple dialogs

    Get.defaultDialog(
      title: 'Set Home Location',
      middleText: 'Your home location is not set. Please set your location to proceed.',
      barrierDismissible: false,
      actions: [
        TextButton(
          onPressed: () {
            exit(0);
          },
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            Get.to(() => CurrentLocationPage());
          },
          child: const Text('Set Location'),
        ),
      ],
    ).then((_) {
      isDialogShowing.value = false; // Reset flag after dialog closes
    });

    return;
  }

  // Add the home radius as a circle to the map
  if (homeRadius > 0.0) {
    markerController.addHomeRadiusCircle(homeLat, homeLng, homeRadius);
  }

  // Mark the device as processed
  processedDevices.add(vehicleDetail.vehicleNo);
}


  /// Initialize map markers for all devices
  void initializeDeviceMarkers(List<DeviceDetails> devices) {
    for (final device in devices) {
      try {
        final lat = double.parse(device.deviceLat);
        final lng = double.parse(device.deviceLng);
        markerController.updateDeviceLocation(device.imei, lat, lng);
      } catch (e) {
        print("Error initializing device marker: $e");
      }
    }
  }

  /// Toggle MQTT connection and update status
  void toggleConnection() {
    isConnected.toggle();
    if (isConnected.value) {
      mqttController.onConnected();
      Get.snackbar(
        'Connected',
        'Server Connected',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
    } else {
      mqttController.onDisconnected();
      Get.snackbar(
        'Disconnected',
        'Server Disconnected!',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  /// Get address from latitude and longitude
  Future<String> getAddress(double lat, double lng) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        Placemark placemark = placemarks.first;
        return '${placemark.street}, ${placemark.locality}, ${placemark.country}';
      }
      return 'Address not found';
    } catch (e) {
      return 'Error: $e';
    }
  }

  /// Calculate distance between two geographic coordinates
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double R = 6371; // Radius of Earth in km
    double dLat = _degToRad(lat2 - lat1);
    double dLon = _degToRad(lon2 - lon1);

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degToRad(lat1)) *
            cos(_degToRad(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c; // Distance in km
  }

  /// Convert degrees to radians
  double _degToRad(double degrees) {
    return degrees * (pi / 180);
  }

  /// Get the initial camera position for the map
  CameraPosition getInitialCameraPosition() {
    if (deviceDetailsList.isNotEmpty) {
      try {
        final firstDevice = deviceDetailsList.first;
        final lat = double.parse(firstDevice.deviceLat);
        final lng = double.parse(firstDevice.deviceLng);
        return CameraPosition(target: LatLng(lat, lng), zoom: 12);
      } catch (e) {
        print("Error parsing initial camera position: $e");
      }
    }
    return const CameraPosition(target: LatLng(0, 0), zoom: 5);
  }

  /// Make a phone call
  Future<void> makePhoneCall(String phoneNumber) async {
    final Uri phoneUrl = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunch(phoneUrl.toString())) {
      await launch(phoneUrl.toString());
    } else {
      print('Could not launch $phoneNumber');
    }
  }

  @override
  void onClose() {
    locationTimer?.cancel();
    super.onClose();
  }
}
