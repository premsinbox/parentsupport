import 'package:avatar_glow/avatar_glow.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:parentsupport/dashboard/controller/controller.dart';
import 'package:parentsupport/dashboard/map_handler/map_handler.dart';
import 'package:parentsupport/dashboard/markers/marker.dart';
import 'package:parentsupport/locationpage/locationpage_controller.dart';
import 'package:parentsupport/notification/notification_ui.dart';
import 'package:parentsupport/locationpage/locationpage_view.dart';
import 'package:parentsupport/login/login_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Dashboard extends StatelessWidget {
  final MapHandler mapHandler = Get.put(MapHandler());
  final MarkerController markerController = Get.put(MarkerController());
  final isLocationUpdated = false.obs;
  final DashboardController controller = Get.put(DashboardController());
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final LocationController locationController = Get.put(LocationController());

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final padding = screenSize.height * 0.02;
    final iconSize = screenSize.width * 0.07;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.refreshData();
    });

    return WillPopScope(
        onWillPop: () async {
          if (controller.isLocationUpdated.value) {
            controller.refreshData(); // Update the map if location changes
          }
          return true; // Allow the back action to continue
        },
        child: Scaffold(
            key: _scaffoldKey, // Assign the key to Scaffold
            backgroundColor: const Color.fromARGB(255, 247, 247, 247),
            drawer: Drawer(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  // Drawer Header
                  DrawerHeader(
                    decoration: BoxDecoration(
                      color: Colors.blue,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.account_circle,
                            size: 60, color: Colors.white),
                        SizedBox(height: 10),
                        Obx(() {
                          return Text(
                            controller.deviceDetailsList.isEmpty
                                ? "Hello"
                                : controller.deviceDetailsList[0].studentName,
                            style: const TextStyle(
                                fontSize: 22, color: Colors.white),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          );
                        }),
                      ],
                    ),
                  ),
                  // Notifications Button
                  ListTile(
                    leading: Icon(Icons.notifications),
                    title: Text("Notifications"),
                    onTap: () {
                      // Close the drawer first, then navigate
                      Navigator.of(context).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (context) => NotificationsPage()),
                      );
                    },
                  ),
                  // Add more menu items as needed
                  ListTile(
                    leading: Icon(Icons.logout),
                    title: Text("Logout"),

                    onTap: () async {
                      // Show confirmation dialog
                      bool shouldLogout = await showDialog<bool>(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text("Logout"),
                            content: const Text(
                                "Are you sure you want to log out?"),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(
                                    context, false), // Return false
                                child: const Text("Cancel"),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(
                                    context, true), // Return true
                                child: const Text("Logout"),
                              ),
                            ],
                          );
                        },
                      ) ??
                          false; // Handle null case by defaulting to false

                      if (shouldLogout) {
                        // Clear user session data
                        SharedPreferences prefs =
                        await SharedPreferences.getInstance();
                        await prefs.setBool('isLoggedIn', false);
                        await prefs.remove('phone_number');

                        // Navigate to login page and clear stack
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                              builder: (context) => LoginPage()),
                              (route) => false,
                        );
                      }
                    },
                  ),
                  Container(
                    padding: EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 237, 237, 237),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // First Circle with Name
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 15, // Adjust the size of the circle
                              backgroundColor: const Color.fromARGB(255, 198, 159, 3),
                            ),
                            SizedBox(width: 15),
                            Text(
                              'Bus Halt',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        SizedBox(height: 16), // Space between the two circles
                        // Second Circle with Name
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 15,
                              backgroundColor: Colors.green,
                            ),
                            SizedBox(width: 15),
                            Text(
                              'Bus Running',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )

                ],
              ),
            ),
            body: SafeArea(
              child: Stack(children: [
                // Google Map
                Obx(() {
                  // Check if deviceDetailsList is not empty
                  if (controller.deviceDetailsList.isNotEmpty) {
                    // Extract initial position
                    final firstDevice = controller.deviceDetailsList.first;

                    // Parse coordinates safely
                    final double lat = double.tryParse(firstDevice.deviceLat) ?? 0.0;
                    final double lng = double.tryParse(firstDevice.deviceLng) ?? 0.0;

                    return GoogleMap(
                      onMapCreated: (googleMapController) {
                        mapHandler.onMapCreated(googleMapController);
                        mapHandler.fitMarkersToMap(markerController.allDeviceMarkers);
                      },
                      initialCameraPosition: CameraPosition(
                        target: LatLng(lat, lng), // Use parsed coordinates
                        zoom: 12,
                      ),
                      markers: markerController.deviceLocations.values.toSet(),
                      circles: locationController.circles, // Use allHomeCircles
                    );
                  } else {
                    // Show a loading indicator if no device details are available
                    return Center(
                      child: Image.asset(
                        'assets/images/locationmarker.gif', // Path to your GIF
                        width: 250, // Optional size
                        height: 250, // Optional size
                      ),
                    );
                  }
                }),



                // Custom Header Section
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    child: Row(
                      children: [
                        // Menu Icon
                        IconButton(
                          icon: Icon(Icons.menu, size: 30),
                          onPressed: () {
                            // Open the drawer programmatically
                            _scaffoldKey.currentState!.openDrawer();
                          },
                        ),
                        const SizedBox(width: 10),
                        // Student Name
                        Expanded(
                          child: Obx(() {
                            return Text(
                              controller.deviceDetailsList.isEmpty
                                  ? "Hello"
                                  : controller.deviceDetailsList[0].studentName,
                              style: const TextStyle(fontSize: 22),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            );
                          }),
                        ),
                        // Refresh Button
                        Obx(() {
                          return IconButton(
                            icon: Icon(
                              Icons.refresh,
                              color: controller.isRefreshDisabled.value
                                  ? Colors.grey
                                  : Colors.black,
                            ),
                            onPressed: controller.isRefreshDisabled.value
                                ? null
                                : () async => await controller.refreshData(),
                          );
                        }),
                        // MQTT Connection Button
                        GestureDetector(
                          onTap: () => controller.toggleConnection(),
                          child: Obx(() {
                            final isConnected = controller.isConnected.value;
                            return AvatarGlow(
                              glowColor:
                              isConnected ? Colors.green : Colors.red,
                              duration: const Duration(milliseconds: 2500),
                              repeat: isConnected,
                              child: CircleAvatar(
                                backgroundColor: Colors.white,
                                radius: 20,
                                child: Icon(
                                  isConnected
                                      ? Icons.cloud_done
                                      : Icons.cloud_off,
                                  color:
                                  isConnected ? Colors.green : Colors.red,
                                  size: 20,
                                ),
                              ),
                            );
                          }),
                        ),
                        // Location Icon
                        IconButton(
                          icon: Image.asset(
                            'assets/images/house_location.png',
                            width: 24,
                            height: 24,
                          ),
                          onPressed: () {
                            Get.to(() => CurrentLocationPage());
                          },
                        ),
                        // Logout Icon

                      ],
                    ),
                  ),
                ),

                DraggableScrollableSheet(
                  initialChildSize: 0.2,
                  minChildSize: 0.2,
                  maxChildSize: 0.45,
                  builder: (context, scrollController) {
                    return Column(children: [
                      Container(
                        width: 50,
                        height: 5,
                        margin: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(16.0)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            child: Obx(() {
                              if (controller.isLoading.value) {
                                return Center(
                                  child: Image.asset(
                                    'assets/images/locationmarker.gif', // Path to your GIF
                                    width: 250, // Optional: Adjust size of the GIF
                                    height: 250, // Optional: Adjust size of the GIF
                                  ),
                                );
                              }

                              if (controller.deviceDetailsList.isEmpty) {
                                return Center(
                                  child: Image.asset(
                                    'assets/images/locationmarker.gif', // Path to your GIF
                                    width: 250, // Optional: Adjust size of the GIF
                                    height: 250, // Optional: Adjust size of the GIF
                                  ),
                                );
                              }

                              return ListView.builder(
                                controller: scrollController,
                                itemCount: controller.deviceDetailsList.length,
                                itemBuilder: (context, index) {
                                  final detail =
                                  controller.deviceDetailsList[index];
                                  final isExpired = markerController
                                      .isDeviceExpired(detail.expiryDt);
                                  final RxBool showContacts = RxBool(
                                      false); // Consider using a global map for this if required

                                  if (isExpired) {
                                    return Container(
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 16.0, vertical: 16.0),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[300],
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.1),
                                            blurRadius: 6,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            detail.vehicleNo,
                                            style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black),
                                          ),
                                          const Row(
                                            children: [
                                              Text(
                                                'Vehicle Expired',
                                                style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.black),
                                              ),
                                              SizedBox(width: 8),
                                              Icon(Icons.warning,
                                                  color: Colors.red, size: 24),
                                            ],
                                          ),
                                        ],
                                      ),
                                    );
                                  }

                                  return GestureDetector(
                                    onTap: () {
                                      mapHandler.animateToDeviceLocation(
                                        LatLng(double.parse(detail.deviceLat),
                                            double.parse(detail.deviceLng)),
                                      );
                                    },
                                    child: Container(
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 16.0, vertical: 8.0),
                                      decoration: BoxDecoration(
                                        color: isExpired
                                            ? Colors.grey[300]
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.1),
                                            blurRadius: 6,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.all(16),
                                            child: Column(
                                              crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                              children: [
                                                // Vehicle No in Bold

                                                Text(
                                                  detail.vehicleNo,
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: getBusStatusColor(detail
                                                        .deviceIgnition), // Color based on bus status
                                                  ),
                                                ),
                                                const SizedBox(height: 10),
                                                Row(
                                                  mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .spaceBetween,
                                                  children: [
                                                    Column(
                                                      children: [
                                                        const Row(
                                                          children: [
                                                            Icon(Icons.school,
                                                                color: Colors.grey),
                                                            SizedBox(width: 5),
                                                            Text('To School',
                                                                style: TextStyle(
                                                                    color: Colors
                                                                        .grey)),
                                                          ],
                                                        ),
                                                        Text(
                                                          '${controller.calculateDistance(
                                                            double.parse(detail
                                                                .schoolLat),
                                                            double.parse(detail
                                                                .schoolLng),
                                                            double.parse(detail
                                                                .deviceLat),
                                                            double.parse(detail
                                                                .deviceLng),
                                                          ).toStringAsFixed(2)} Km',
                                                          style: const TextStyle(
                                                              fontSize: 14,
                                                              fontWeight:
                                                              FontWeight.bold),
                                                        ),
                                                      ],
                                                    ),
                                                    Column(
                                                      children: [
                                                        const Row(
                                                          children: [
                                                            Icon(Icons.home,
                                                                color: Colors.grey),
                                                            SizedBox(width: 5),
                                                            Text('To Home',
                                                                style: TextStyle(
                                                                    color: Colors
                                                                        .grey)),
                                                          ],
                                                        ),
                                                        Text(
                                                          '${controller.calculateDistance(
                                                            double.parse(
                                                                detail.homeLat),
                                                            double.parse(
                                                                detail.homeLng),
                                                            double.parse(detail
                                                                .deviceLat),
                                                            double.parse(detail
                                                                .deviceLng),
                                                          ).toStringAsFixed(2)} Km',
                                                          style: const TextStyle(
                                                              fontSize: 14,
                                                              fontWeight:
                                                              FontWeight.bold),
                                                        ),
                                                      ],
                                                    ),
                                                    IconButton(
                                                      icon: Icon(Icons.contacts,
                                                          color: getBusStatusColor(
                                                              detail
                                                                  .deviceIgnition)),
                                                      onPressed: () =>
                                                      showContacts.value =
                                                      !showContacts.value,
                                                    ),
                                                  ],
                                                ),
                                                // Conditional Contacts Section
                                                Obx(() {
                                                  if (showContacts.value &&
                                                      !isExpired) {
                                                    return Column(
                                                      children: [
                                                        const SizedBox(height: 10),
                                                        Row(
                                                          mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                          children: [
                                                            Flexible(
                                                              flex: 2,
                                                              child:
                                                              _buildContactSection(
                                                                context,
                                                                detail.vehicleNo,
                                                                'Driver',
                                                                detail.mobile,
                                                                'assets/images/driver.png',
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                                width: 32),
                                                            Flexible(
                                                              flex: 2,
                                                              child:
                                                              _buildContactSection(
                                                                context,
                                                                detail.vehicleNo,
                                                                'Incharge',
                                                                detail.inchargeNo,
                                                                'assets/images/incharge.png',
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ],
                                                    );
                                                  }
                                                  return const SizedBox.shrink();
                                                }),
                                                // Address Section
                                                const SizedBox(height: 10),
                                                FutureBuilder<String>(
                                                  future: controller.getAddress(
                                                    double.parse(detail.deviceLat),
                                                    double.parse(detail.deviceLng),
                                                  ),
                                                  builder: (context, snapshot) {
                                                    if (snapshot.connectionState ==
                                                        ConnectionState.waiting) {
                                                      return Center(
                                                        child: Image.asset(
                                                          'assets/images/barline.gif', // Path to your GIF
                                                          width:
                                                          100, // Optional: Adjust size of the GIF
                                                          height:
                                                          50, // Optional: Adjust size of the GIF
                                                        ),
                                                      );
                                                    } else if (snapshot.hasError) {
                                                      return Text(
                                                          'Error: ${snapshot.error}');
                                                    } else {
                                                      return Row(
                                                        children: [
                                                          Icon(Icons.location_on,
                                                              color: getBusStatusColor(
                                                                  detail
                                                                      .deviceIgnition)),
                                                          const SizedBox(width: 5),
                                                          Expanded(
                                                            child: Text(
                                                              snapshot.data ??
                                                                  'Address not found',
                                                              style:
                                                              const TextStyle(
                                                                  fontSize: 14),
                                                              maxLines: 2,
                                                              overflow: TextOverflow
                                                                  .ellipsis,
                                                            ),
                                                          ),
                                                        ],
                                                      );
                                                    }
                                                  },
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                            }),
                          ))
                    ]);
                  },
                )
              ]),
            )));
  }

  // Helper method for contact sections
  Widget _buildContactSection(BuildContext context, String vehicleNo,
      String type, String number, String imagePath) {
    return GestureDetector(
      onTap: () {
        // Implement phone call logic
        controller.makePhoneCall(number);
      },
      child: Column(
        children: [
          Image.asset(imagePath, height: 80, width: 80),
          Text(type, style: const TextStyle(fontSize: 14)),
          Text(number, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}
