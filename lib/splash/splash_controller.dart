import 'dart:developer';
import 'package:get/get.dart';
import 'package:parentsupport/dashboard/controller/controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SplashController extends GetxController {
  RxString versionName = ''.obs;
  RxBool isInitializing = true.obs;
  final DashboardController controller = Get.put(DashboardController());

  @override
  void onInit() {
    super.onInit();
    initializeApp();
    
  }

  Future<void> initializeApp() async {
    try {
      isInitializing.value = true;

      // Run all initialization tasks in parallel
      await Future.wait([
        getAppVersion(),
        checkInitialSetup(),
      ]);

      // Wait for DashboardController to finish loading device details
      await controller.fetchData(controller.mobile.value);  // You can use any mobile number or the one stored
      await controller.refreshData();  // Fetch device details and refresh data

      // Check login status and navigate accordingly
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

      // Navigate based on login status
      if (isLoggedIn) {
        log('Navigating to dashboard');
        Get.offNamed('/dashboard');
      } else {
        log('Navigating to login');
        Get.offNamed('/login');
      }
    } catch (e) {
      log('Initialization error: $e');
      // Fallback to login screen in case of error
      Get.offNamed('/login');
    } finally {
      isInitializing.value = false;
    }
  }

  Future<void> getAppVersion() async {
    try {
      // Retrieve the version from the app's metadata
      final packageInfo = await PackageInfo.fromPlatform();
      versionName.value = packageInfo.version;
      log('App version retrieved: ${versionName.value}');

      // Save version to preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('app_version', versionName.value);
    } catch (e) {
      log('Error getting app version: $e');
      // Set a default version in case of error
      versionName.value = '1.0.0';
    }
  }

  Future<void> checkInitialSetup() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Check if this is the first launch
      final isFirstLaunch = !prefs.containsKey('first_launch');

      if (isFirstLaunch) {
        // Perform first launch setup
        await prefs.setBool('first_launch', false);
        log('First launch setup completed');
      }

      // Add any additional initialization logic here
      // For example, loading configuration, checking for updates, etc.
    } catch (e) {
      log('Error during initial setup: $e');
    }
  }
}
