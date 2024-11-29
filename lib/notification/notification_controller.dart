import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:parentsupport/notification/motification_model.dart';
import 'package:parentsupport/notification/notification_db.dart';
import 'package:intl/intl.dart';

class NotificationController extends GetxController {
  final NotificationDBHelper dbHelper = NotificationDBHelper();
  final RxList<NotificationModel> notifications = <NotificationModel>[].obs;
  final RxList<DateTime> availableDates = <DateTime>[].obs;
  final Rx<DateTime> selectedDate = DateTime.now().obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadNotifications();
  }

  Future<void> loadNotifications() async {
    isLoading.value = true;
    try {
      final allNotifications = await dbHelper.getNotifications();
      notifications.value = allNotifications;

      // Get unique dates from notifications
      final dates = allNotifications
          .map((n) => DateTime(n.timestamp.year, n.timestamp.month, n.timestamp.day))
          .toSet()
          .toList();
      dates.sort((a, b) => b.compareTo(a));
      availableDates.value = dates;

      filterNotificationsByDate(selectedDate.value);
    } catch (e) {
      print('Error loading notifications: $e');
    } finally {
      isLoading.value = false;
    }
  }

void filterNotificationsByDate(DateTime date) {
  selectedDate.value = date;

  // Filter notifications for the selected date
  final filtered = notifications.where((n) {
    return n.timestamp.year == date.year &&
           n.timestamp.month == date.month &&
           n.timestamp.day == date.day;
  }).toList();

  notifications.value = filtered; // Update the notifications list
}


void previousDate() {
  final previousDate = selectedDate.value.subtract(Duration(days: 1));
  filterNotificationsByDate(previousDate);
}

void nextDate() {
  if (selectedDate.value.isBefore(DateTime.now())) {
    final nextDate = selectedDate.value.add(Duration(days: 1));
    filterNotificationsByDate(nextDate);
  }
}

String getCustomDayName(DateTime date) {
  const daysOfWeek = [
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday'
  ];
  return daysOfWeek[date.weekday % 7];
}


  String formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);  // Show year in the date format
  }

  String formatTime(DateTime date) {
    return DateFormat('HH:mm').format(date);
  }

  Future<void> showDatePickerDialog(BuildContext context) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate.value,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null && pickedDate != selectedDate.value) {
      filterNotificationsByDate(pickedDate);
    }
  }
}
