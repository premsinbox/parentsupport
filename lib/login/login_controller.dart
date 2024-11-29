import 'package:get/get.dart';
import 'package:parentsupport/otp/otp_ui.dart'; // Import the OTP verification page
import 'package:parentsupport/utils/utils.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class LoginController extends GetxController {
  var isLoading = false.obs;  // Reactive variable for loading state
  TextEditingController phoneController = TextEditingController();
  

  // Function to handle login
  Future<void> loginUser(String phoneNumber, BuildContext context) async {
    const String url = "http://${Utils.ipaddress}/schools/api/school_app_api.php";

    try {
      isLoading.value = true; // Show loading

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "action": "login",
          "mobile": phoneNumber,
        }),
      );

      isLoading.value = false; // Hide loading

      if (response.statusCode == 200) {
        String responseMessage = response.body;
        print(responseMessage);

        // Check if login is successful
        if (responseMessage == 'success') {
          print("Login successful");

          // Save the phone number and login status in SharedPreferences
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setBool('isLoggedIn', true); // Store login status
          await prefs.setString('phone_number', phoneNumber); // Save phone number

          // Navigate to OTP verification page using GetX navigation
          Get.to(() => OtpVerificationPage(mobilenumber: phoneNumber));
        } else {
          print("Login failed: $responseMessage");
          Get.snackbar(
            'Login Failed',
            'Incorrect credentials or network issue.',
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 2),
          );
        }
      } else {
        print("Error: ${response.statusCode}");
        // Handle server errors (e.g., show an error message)
        Get.snackbar(
          'Error',
          'Failed to connect to the server.',
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 2),
        );
      }
    } catch (e) {
      print("An error occurred: $e");
      // Handle network or parsing errors
      Get.snackbar(
        'Error',
        'An error occurred. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    }
  }
}
