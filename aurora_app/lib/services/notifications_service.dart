// NotificationService
// Lightweight wrapper around flutter_local_notifications providing
// initialization + a daily journal reminder scheduling helper. Timezone
// handling is performed up front to support precise scheduling on all
// platforms. All public methods are idempotent; calling init twice is safe.
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// Comprehensive notification manager.
/// Responsibilities:
/// - Timezone initialization
/// - Permission requests (Android 13+, iOS)
/// - Channel setup (Android)
/// - Daily journal reminder scheduling w/ persistence flag
/// - One-off scheduling & immediate notifications
/// - Pending notification introspection & cancellation utilities
/// - Tap callback registration (payload delivery)

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool _permissionsRequested = false;
  Function(String? payload)? _onTap; // external tap handler

  static const _dailyId = 1001;
  static const _dailyChannelId = 'daily_journal_channel';
  static const _dailyChannelName = 'Daily Journal Reminders';
  static const _prefDailyScheduled = 'daily_journal_scheduled';

  /// Initializes timezone data + platform specific notification settings.
  /// Safe to call multiple times; subsequent calls are no-ops.
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
      requestAlertPermission: false, // we request explicitly later
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings =
        InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        _onTap?.call(response.payload);
      },
      // Background tap handler requires a top-level entry point; we provide one below.
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    // Android channel creation (redundant if exists).
    final androidPlatform = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlatform != null) {
      await androidPlatform.createNotificationChannel(
        const AndroidNotificationChannel(
          _dailyChannelId,
          _dailyChannelName,
          description: 'Reminders to write in your journal',
          importance: Importance.high,
        ),
      );
    }

    _initialized = true;
  }

  /// Request user notification permissions (safe multi-call).
  Future<bool> requestPermissions() async {
    if (_permissionsRequested) return true; // assume granted previously
    bool granted = true;
    final ios = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      final res = await ios.requestPermissions(alert: true, badge: true, sound: true);
      granted = res ?? false;
    }
    final macos = _plugin.resolvePlatformSpecificImplementation<MacOSFlutterLocalNotificationsPlugin>();
    if (macos != null) {
      await macos.requestPermissions(alert: true, badge: true, sound: true);
    }
    final android = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final aGranted = await android.requestNotificationsPermission();
      if (aGranted == null) {
        // treat null as granted on pre-Android 13
      } else {
        granted = granted && aGranted;
      }
    }
    _permissionsRequested = true;
    return granted;
  }

  /// Register a handler for notification taps (foreground & background).
  void setOnNotificationTap(Function(String? payload) handler) {
    _onTap = handler;
  }

  /// Schedules a daily notification reminding the user to journal.
  /// Default time is 21:00 (9PM) local timezone. Persists a flag so repeated
  /// calls do not duplicate scheduling unless [force] is true.
  Future<void> scheduleDailyJournalReminder({
    int hour = 21,
    int minute = 0,
    String title = 'Time to reflect ✨',
    String body = 'Take a minute to write in your journal.',
    bool force = false,
  }) async {
    if (!_initialized) {
      await init();
    }
    await requestPermissions();

    final prefs = await SharedPreferences.getInstance();
    final already = prefs.getBool(_prefDailyScheduled) ?? false;
    if (already && !force) return;

    const androidDetails = AndroidNotificationDetails(
      _dailyChannelId,
      _dailyChannelName,
      channelDescription: 'Reminders to write in your journal',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final scheduled = _nextInstanceOfTime(hour, minute);

    await _plugin.zonedSchedule(
      _dailyId,
      title,
      body,
      scheduled,
        details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // repeat daily
    );
    await prefs.setBool(_prefDailyScheduled, true);
  }

  /// Cancels the previously scheduled daily journal reminder notification.
  Future<void> cancelDailyJournalReminder() async {
    await _plugin.cancel(_dailyId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefDailyScheduled);
  }

  /// Show an immediate notification.
  Future<void> showInstant({
    required int id,
    required String title,
    required String body,
    String? payload,
    Importance importance = Importance.defaultImportance,
    Priority priority = Priority.defaultPriority,
  }) async {
    if (!_initialized) await init();
    await requestPermissions();
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        'instant_channel',
        'Instant Notifications',
        importance: importance,
        priority: priority,
      ),
      iOS: const DarwinNotificationDetails(),
    );
    await _plugin.show(id, title, body, details, payload: payload);
  }

  /// Schedule a one-off notification at an exact local time.
  Future<void> scheduleOneOff({
    required int id,
    required DateTime when,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_initialized) await init();
    await requestPermissions();
    final tzTime = tz.TZDateTime.from(when, tz.local);
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'one_off_channel',
        'One Off Notifications',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      tzTime,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  /// Returns all pending scheduled notifications.
  Future<List<PendingNotificationRequest>> pending() => _plugin.pendingNotificationRequests();

  /// Cancel all notifications.
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefDailyScheduled);
  }

  /// Computes the next occurrence of given hour/minute in local timezone.
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

// Top-level background tap handler required by flutter_local_notifications.
// Must be a top-level or static function and annotated as an entry point so it
// isn't tree-shaken in release builds.
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {
  // Currently we just log; real implementation could route based on payload.
  if (kDebugMode) {
    debugPrint('Background notification tap: id=${response.id} payload=${response.payload}');
  }
}
