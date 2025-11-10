// lib/services/notification_service.dart
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    // 1. init timezones
    tz.initializeTimeZones();
    // if you want to be extra explicit:
    tz.setLocalLocation(tz.getLocation(tz.local.name));

    // 2. android init
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // 3. iOS init
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings =
        InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _plugin.initialize(initSettings);

    _initialized = true;
  }

  Future<void> scheduleDailyJournalReminder({
    int hour = 21,
    int minute = 0,
    String title = 'Time to reflect ✨',
    String body = 'Take a minute to write in your journal.',
  }) async {
    if (!_initialized) {
      await init();
    }

    const androidDetails = AndroidNotificationDetails(
      'daily_journal_channel',
      'Daily Journal Reminders',
      channelDescription: 'Reminders to write in your journal',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    final details = const NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final scheduled = _nextInstanceOfTime(hour, minute);

    await _plugin.zonedSchedule(
      1001,
      title,
      body,
      scheduled,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // repeat daily
    );
  }

  Future<void> cancelDailyJournalReminder() async {
    await _plugin.cancel(1001);
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}
