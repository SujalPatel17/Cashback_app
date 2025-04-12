import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    WidgetsFlutterBinding.ensureInitialized();
    tz.initializeTimeZones(); // 🌐 Important for scheduling with timezone

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    final initializationSettings = InitializationSettings(
      android: androidSettings,
    );

    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> showNotification(int id, String title, String body) async {
    const androidDetails = AndroidNotificationDetails(
      'cashback_channel',
      'Cashback Notifications',
      channelDescription: 'Notifications for cashback checks',
      importance: Importance.high,
      priority: Priority.high,
    );
    const platformDetails = NotificationDetails(android: androidDetails);

    await _flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      platformDetails,
    );
  }

  Future<void> scheduleNotification(
    int id,
    String title,
    String body,
    DateTime date,
  ) async {
    final androidDetails = AndroidNotificationDetails(
      'cashback_channel',
      'Cashback Notifications',
      channelDescription: 'Notifications for cashback checks',
      importance: Importance.high,
      priority: Priority.high,
    );
    final platformDetails = NotificationDetails(android: androidDetails);

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(date, tz.local), // 🔁 Convert to TZDateTime
      platformDetails,
      androidScheduleMode:
          AndroidScheduleMode.exactAllowWhileIdle, // ✅ Required
    );
  }
}
