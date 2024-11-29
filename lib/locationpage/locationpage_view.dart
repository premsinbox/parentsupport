import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:parentsupport/dashboard/controller/controller.dart';
import 'package:parentsupport/locationpage/locationpage_controller.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:parentsupport/dashboard/controller/controller.dart';
import 'package:parentsupport/locationpage/locationpage_controller.dart';

class CurrentLocationPage extends StatelessWidget {
  final LocationController locationController = Get.put(LocationController());

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final deviceDetailsList =
          Get.find<DashboardController>().deviceDetailsList;
      if (deviceDetailsList.isNotEmpty) {
        final vehicleDetail =
            deviceDetailsList.first; // Example: Get the first vehicle
        await locationController.loadInitialHomeLocation(vehicleDetail);
      }
    });

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 247, 247, 247),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Column(
              children: [
                Container(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    constraints.maxHeight * 0.01,
                    20,
                    constraints.maxHeight * 0.01,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back_ios, color: Colors.black),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                      Expanded(
                        child: Text(
                          'Your Location',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: constraints.maxWidth * 0.06,
                            fontFamily: 'BeVietnamPro',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.location_pin, color: Colors.black),
                        onPressed: () async {
                          await locationController
                              .requestLocationPermission(context);
                          locationController.animateToCurrentLocation();
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.check, color: Colors.green),
                        onPressed: () async {
                          await locationController
                              .fixLocation(); // Trigger the location update
                        },
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      child: TextFormField(
                        controller: locationController.latLngController,
                        keyboardType: TextInputType.text,
                        decoration: InputDecoration(
                          hintText: 'Latitude, Longitude',
                          filled: true,
                          fillColor: Colors.white,
                          prefixIcon: Icon(Icons.location_on),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (value) {
                          // Optionally validate input while typing
                          if (value.split(',').length != 2) {
                            locationController.isLatLngValid.value = false;
                          } else {
                            locationController.isLatLngValid.value = true;
                          }
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      child: TextFormField(
                        controller: locationController.radiusController,
                        keyboardType:
                            TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          hintText: 'Radius (in meters)',
                          filled: true,
                          fillColor: Colors.white,
                          prefixIcon: Icon(Icons.radar),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onChanged: (value) {
                          // Optionally validate input while typing
                          locationController.isRadiusValid.value =
                              double.tryParse(value) != null;
                        },
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: Stack(
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.2),
                              blurRadius: 4,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(25),
                            topRight: Radius.circular(25),
                          ),
                          child: GetBuilder<LocationController>(
                            builder: (_) {
                              return locationController.isLoading
                                  ? Center(
    child: Image.asset(
      'assets/images/locationmarker.gif', // Path to your GIF
      width: 250,  // Optional: Adjust size of the GIF
      height: 250, // Optional: Adjust size of the GIF
    ),
  )
                                  : 
                                  GoogleMap(
                                      onMapCreated: (mapController) {
                                        locationController.mapController =
                                            mapController;
                                        locationController
                                            .animateToCurrentLocation();
                                      },
                                      initialCameraPosition: CameraPosition(
                                        target: locationController
                                                .currentLocation ??
                                            const LatLng(0, 0),
                                        zoom: locationController
                                                    .currentLocation !=
                                                null
                                            ? 15
                                            : 1,
                                      ),
                                      myLocationEnabled: false,
                                      myLocationButtonEnabled: false,
                                      
                                      markers: locationController.marker != null
                                          ? {
                                            Marker(
            markerId: MarkerId('custom_marker'),
            position: locationController.currentLocation ?? LatLng(0, 0),
            icon: locationController.customMarkerIcon, // Use custom marker icon here
          ),
                                          }
                                          : {},
                                      circles: locationController.circles,
                                      onTap: (LatLng position) {
                                        locationController
                                            .updateMarker(position);
                                      },
                                    );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
