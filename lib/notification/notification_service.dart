import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:parentsupport/notification/motification_model.dart';
import 'package:parentsupport/notification/notification_db.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static final NotificationDBHelper _dbHelper = NotificationDBHelper();

  static void initialize() {
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings settings =
        InitializationSettings(android: androidSettings);

    _localNotificationsPlugin.initialize(settings);
  }

  static Future<void> showNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails('channel_id', 'channel_name',
            channelDescription: 'channel_description',
            importance: Importance.high,
            priority: Priority.high);

    const NotificationDetails platformDetails =
        NotificationDetails(android: androidDetails);

    await _localNotificationsPlugin.show(
      0,
      message.notification?.title,
      message.notification?.body,
      platformDetails,
      payload: message.data.toString(),
    );

    // Save the notification in the local database
    final notification = NotificationModel(
      title: message.notification?.title ?? "No Title",
      body: message.notification?.body ?? "No Body",
      data: message.data.toString(),
      timestamp: DateTime.now(),
    );

    await _dbHelper.insertNotification(notification);
  }
}
