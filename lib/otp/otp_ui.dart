import 'package:flutter/material.dart';
import 'package:get/get.dart'; 
import 'package:parentsupport/otp/otp_controller.dart';
import 'package:pinput/pinput.dart';

class OtpVerificationPage extends StatelessWidget {
  final String mobilenumber;
  final OtpController _otpController = Get.put(OtpController()); // Using GetX controller

  // Constructor to accept mobilenumber
  OtpVerificationPage({required this.mobilenumber});

  // Method to handle OTP submission
  void onOtpSubmit(BuildContext context) {
    String otp = _otpController.pinController.text;

    // Check if OTP is valid (6 digits)
    if (otp.length == 6) {
      _otpController.verifyOtp(
        context,
        mobilenumber,
        otp,
        _otpController.fcmToken, // You can dynamically set this token
      );
    } else {
      print("Please enter a valid 6-digit OTP.");
      _otpController.showError(context, "Please enter a valid 6-digit OTP.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    final pinWidth = screenSize.width * 0.1;
    final pinHeight = screenSize.height * 0.06;

    final defaultPinTheme = PinTheme(
      width: pinWidth,
      height: pinHeight,
      textStyle: const TextStyle(
        fontSize: 20,
        color: Colors.black,
        fontWeight: FontWeight.w600,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(8),
      ),
    );

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/map.jpg'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Enter OTP',
                              style: TextStyle(
                                color: Colors.blue,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: screenSize.height * 0.02),
                            Pinput(
                              length: 6,
                              controller: _otpController.pinController,
                              focusNode: _otpController.focusNode,
                              defaultPinTheme: defaultPinTheme,
                              separatorBuilder: (index) => const SizedBox(width: 8),
                              pinAnimationType: PinAnimationType.fade,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              focusedPinTheme: defaultPinTheme.copyWith(
                                decoration: defaultPinTheme.decoration!.copyWith(
                                  border: Border.all(color: Colors.blue),
                                ),
                              ),
                              errorPinTheme: defaultPinTheme.copyWith(
                                decoration: defaultPinTheme.decoration!.copyWith(
                                  border: Border.all(color: Colors.red),
                                ),
                              ),
                            ),
                            SizedBox(height: screenSize.height * 0.02),
                            Obx(() {
                              return GestureDetector(
                                onTap: () {
                                  if (!_otpController.isLoading.value) {
                                    onOtpSubmit(context); // Trigger OTP verification if not loading
                                  }
                                },
                                child: Container(
                                  height: screenSize.height * 0.07,
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: _otpController.isLoading.value
                                        ? Colors.blue[300]
                                        : Colors.blue,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: _otpController.isLoading.value
                                      ? const CircularProgressIndicator(
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        )
                                      : const Text(
                                          'Submit',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                ),
                              );
                            }),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
