import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {

  static final _notifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {

    tz.initializeTimeZones();
    final String timeZoneName = (await FlutterTimezone.getLocalTimezone()).identifier;
    tz.setLocalLocation(tz.getLocation(timeZoneName));

    const androidSettings =
        AndroidInitializationSettings(
          '@mipmap/ic_launcher',
        );

    const settings =
        InitializationSettings(
          android: androidSettings,
        );

    await _notifications.initialize(
      settings,
    );

    await _requestPermission();
  }

  static Future<void>
      _requestPermission() async {

    final androidImplementation =
        _notifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

    await androidImplementation
        ?.requestNotificationsPermission();
  }

  static Future<void>
      showInstantNotification() async {

    const androidDetails =
        AndroidNotificationDetails(
          'catat_in_channel',
          'Catat-In Notifications',

          channelDescription:
              'Reminder dan insight productivity',

          importance: Importance.max,
          priority: Priority.high,

          playSound: true,
        );

    const details =
        NotificationDetails(
          android: androidDetails,
        );

    await _notifications.show(
      0,
      'Catat-In 🔥',
      'Jangan lupa catat aktivitas hari ini!',
      details,
    );

    debugPrint(
      'NOTIFICATION TRIGGERED',
    );
  }

  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  static Future<void> scheduleDailyReminder(int hour, int minute) async {
    const androidDetails = AndroidNotificationDetails(
      'daily_reminder_channel',
      'Daily Reminder',
      icon: '@mipmap/ic_launcher',
      channelDescription: 'Reminder harian Catat-In',
      importance: Importance.max,
      priority: Priority.high,
    );

    const details = NotificationDetails(android: androidDetails);

    await _notifications.zonedSchedule(
      1,
      'Catat-In 🔥',
      'Sudahkah kamu mencatat aktivitas hari ini?',
      _nextInstanceOfTime(hour, minute),
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    debugPrint('PERIODIC REMINDER SCHEDULED AT $hour:${minute.toString().padLeft(2, '0')}');
  }

  static Future<void> cancelDailyReminder() async {
    await _notifications.cancel(1);
    debugPrint('PERIODIC REMINDER CANCELLED');
  }
}