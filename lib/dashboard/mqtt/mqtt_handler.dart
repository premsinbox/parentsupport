import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:get/get.dart';
import 'package:parentsupport/dashboard/controller/controller.dart';
import 'package:parentsupport/dashboard/markers/marker.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'dart:async';
import 'dart:developer';

class MqttController extends GetxController {
  MqttServerClient? client;

  var isConnected = false.obs;
  var connectionStatus = ''.obs;
  var logs = <String>[].obs;

  // Define your device location map here
  var deviceLocations = <String, Marker>{}.obs;

  // Fetch subscription topics from the DashboardController
  List<String> get subscriptionTopics {
    return Get.find<DashboardController>()
        .deviceDetailsList
        .map((device) => 'BB/${device.imei}')
        .toList();
  }

  @override
  void onInit() {
    super.onInit();
    setupMqttClient();
  }

  @override
  void onClose() {
    client?.disconnect();
    super.onClose();
  }


  // Initialize MQTT client and connect
  Future<void> setupMqttClient() async {
    client = MqttServerClient('igps.io', 'flutter_client_${DateTime.now()}');
    client!.port = 1883;
    client!.logging(on: true);
    client!.keepAlivePeriod = 60;
    client!.onDisconnected = onDisconnected;
    client!.onConnected = onConnected;
    client!.onSubscribed = onSubscribed;

    final connMessage = MqttConnectMessage()
        .authenticateAs('realiot', 'realmqtt@123')
        .withClientIdentifier('flutter_client_${DateTime.now()}')
        .startClean()
        .withWillQos(MqttQos.atLeastOnce);

    client!.connectionMessage = connMessage;

    try {
      log('MQTT: Connecting to igps.io...');
      connectionStatus.value = 'Connecting...';
      await client!.connect();
    } catch (e) {
      log('MQTT: Connection failed - $e');
      connectionStatus.value = 'Connection failed: $e';
      client!.disconnect();
    }
  }

  // MQTT connected callback
  void onConnected() {
    log('MQTT: Connected successfully');
    connectionStatus.value = 'Connected';
    isConnected.value = true;
    subscribeToTopics();
  }

  // MQTT disconnected callback
  void onDisconnected() {
    log('MQTT: Disconnected');
    connectionStatus.value = 'Disconnected';
    isConnected.value = false;

    // Retry connecting after 5 seconds
    Timer(const Duration(seconds: 5), () {
      if (!isConnected.value) {
        log('MQTT: Attempting to reconnect...');
        setupMqttClient();
      }
    });
  }

  // Subscribe to MQTT topics
  void subscribeToTopics() {
    if (client?.connectionStatus?.state == MqttConnectionState.connected) {
      final topics = subscriptionTopics;
      for (var topic in topics) {
        log('MQTT: Subscribing to topic: $topic');
        client!.subscribe(topic, MqttQos.atLeastOnce);
      }

      client!.updates!
          .listen((List<MqttReceivedMessage<MqttMessage>> messages) {
        final MqttPublishMessage message =
            messages[0].payload as MqttPublishMessage;
        final payload =
            MqttPublishPayload.bytesToStringAsString(message.payload.message);

        log('MQTT: Received raw message: $payload');

        try {
          final data = payload.split(',');
          if (data.length > 5) {
            final lat = double.parse(data[4]);
            final lon = double.parse(data[5]);
            final imei = messages[0].topic.split('/').last;
          
            // Update device location by calling MarkerController method
            Get.find<MarkerController>().updateDeviceLocation(imei, lat, lon);
          } else {
            log('MQTT: Insufficient data in payload to extract location.');
          }
        } catch (e) {
          log('MQTT: Error parsing payload - $e');
        }
      });
    }
  }

  // MQTT subscription callback
  void onSubscribed(String topic) {
    log('MQTT: Successfully subscribed to topic: $topic');
  }
}
