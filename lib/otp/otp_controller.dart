import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:parentsupport/dashboard/view/dashboard.dart';
import 'package:parentsupport/preferences/preferences.dart'; // Assuming the preferences are stored here
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:developer';

class OtpController extends GetxController {
  var isLoading = false.obs; // Observable for loading state
  String fcmToken = ""; // Set this dynamically
  TextEditingController pinController = TextEditingController();
  FocusNode focusNode = FocusNode();

  // Method to verify OTP
  Future<void> verifyOtp(BuildContext context, String mobileNumber, String otp, String token) async {
    const String url = "http://igps.io/schools/api/school_app_api.php";

    try {
      isLoading.value = true;

      log("Mobile Number: $mobileNumber");
      log("OTP: $otp");
      log("Platform: ${defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android'}");

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "action": "otp",
          "mobile": mobileNumber,
          "otp": otp,
          "fcm_token": token,
          "platform": defaultTargetPlatform == TargetPlatform.iOS ? "ios" : "android",
        }),
      );

      // Log response for debugging
      log('Response: ${response.body}');

      if (response.statusCode == 200) {
        String responseMessage = response.body; // Adjust this based on your API response

        if (responseMessage == 'ok') {
          log('OTP verification successful');

          // Save login status and phone number in SharedPreferences
          await saveLoginStatus(true);
          await savePhoneNumber(mobileNumber);

          // Use GetX to navigate to the Dashboard after OTP verification
          Get.offAll(Dashboard());  // Replace Navigator.push with Get.offAll for smooth navigation
        } else {
          showError(context, "OTP verification failed. Please try again.");
        }
      } else {
        log('Error occurred: ${response.statusCode}');
        showError(context, "Error during verification. Please try again.");
      }
    } catch (e) {
      log('Error occurred: $e');
      showError(context, "An error occurred. Please try again.");
    } finally {
      isLoading.value = false;
    }
  }

  // Method to display error messages using a SnackBar
  void showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  

  @override
  void onClose() {
    pinController.dispose();
    focusNode.dispose();
    super.onClose();
  }
}
