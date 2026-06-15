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
    await _createChannels();
  }

  static Future<void> _createChannels() async {
    final androidImplementation = _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    // Tracking channel — used for template activity notifications
    await androidImplementation?.createNotificationChannel(
      const AndroidNotificationChannel(
        'tracking_channel',
        'Tracking Aktivitas',
        description: 'Notifikasi saat tracking berjalan',
        importance: Importance.high,
        playSound: true,
      ),
    );
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
      icon: '@drawable/notification_icon',
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

  // ── Tracking Activity Notification ────────────────────────────────
  static const _trackingNotificationId = 100;

  /// Show a standard notification while a template activity is running.
  /// User can dismiss it anytime by swiping.
  static Future<void> showTrackingNotification(
    String name,
    String emoji,
  ) async {
    const androidDetails = AndroidNotificationDetails(
      'tracking_channel',
      'Tracking Aktivitas',
      channelDescription: 'Notifikasi saat tracking berjalan',
      icon: '@drawable/notification_icon',
      importance: Importance.high,
      priority: Priority.high,
      autoCancel: true,
      playSound: true,
    );

    const details = NotificationDetails(android: androidDetails);

    await _notifications.show(
      _trackingNotificationId,
      '$emoji $name dimulai',
      'Tracking sedang berjalan. Ketuk untuk membuka app.',
      details,
    );

    debugPrint('TRACKING NOTIFICATION SHOWN: $emoji $name');
  }

  /// Cancel the ongoing tracking notification and show a "saved" notification.
  static Future<void> finishTrackingNotification(
    String name,
    String emoji,
  ) async {
    // Cancel the ongoing notification
    await _notifications.cancel(_trackingNotificationId);

    // Show a brief "saved" notification (dismissible by user)
    const androidDetails = AndroidNotificationDetails(
      'tracking_channel',
      'Tracking Aktivitas',
      channelDescription: 'Notifikasi saat tracking berjalan',
      icon: '@drawable/notification_icon',
      importance: Importance.high,
      priority: Priority.high,
      autoCancel: true,
      playSound: true,
    );

    const details = NotificationDetails(android: androidDetails);

    await _notifications.show(
      _trackingNotificationId + 1,
      '$emoji $name tersimpan!',
      'Aktivitas berhasil dicatat.',
      details,
    );

    debugPrint('FINISH NOTIFICATION SHOWN: $emoji $name');
  }

  /// Cancel the tracking notification without showing a saved notification.
  static Future<void> cancelTrackingNotification() async {
    await _notifications.cancel(_trackingNotificationId);
  }
}