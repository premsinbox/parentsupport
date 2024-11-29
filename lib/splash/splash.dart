import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:parentsupport/splash/splash_controller.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final SplashController splashController = Get.put(SplashController());
    String? _fcmToken;

  @override
  void initState() {
    super.initState();
   // _getFcmToken();
  }
  //   Future<void> _getFcmToken() async {
  //   FirebaseMessaging messaging = FirebaseMessaging.instance;

  //   // Request permission for iOS
  //   NotificationSettings settings = await messaging.requestPermission();

  //   if (settings.authorizationStatus == AuthorizationStatus.authorized) {
  //     // Retrieve the token
  //     String? token = await FirebaseMessaging.instance.getToken();
  //     setState(() {
  //       _fcmToken = token;
  //     });
  //     print("FCM Token: $_fcmToken");

  //     // Send the token to your server (via your backend API)
  //     _registerToken(token);
  //   } else {
  //     print("Permission Denied");
  //   }
  // }

  // // Send token to your PHP backend
  // Future<void> _registerToken(String? token) async {
  //   if (token != null) {
  //     final response = await http.post(
  //       Uri.parse("http://192.168.1.6/register_token.php"),
  //       body: {'token': token},
  //     );

  //     if (response.statusCode == 200) {
  //       print("Token registered successfully");
  //       // After registering token, navigate to the next screen
  //       Get.offNamed('/login'); // or '/dashboard', depending on your flow
  //     } else {
  //       print("Failed to register token");
  //     }
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              'assets/images/map.jpg',
              fit: BoxFit.cover,
            ),
          ),
          // Centered icon and loading indicator
          Align(
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  'assets/images/companylogo.png',
                  height: 100,
                ),
                const SizedBox(height: 20),
                Obx(() => splashController.isInitializing.value
                    ? const CircularProgressIndicator()
                    : const SizedBox.shrink()),
              ],
            ),
          ),
          // Company name
          const Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                'Real Tech Systems',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          // Version number
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
              child: Obx(() => Text(
                'Version: ${splashController.versionName.value}',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              )),
            ),
          ),
        ],
      ),
    );
  }
  
}