import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'settings_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
  FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );

    _initialized = true;
  }

  // ── Called when any notification setting is toggled ───────────────────
  Future<void> syncWithSettings() async {
    await init();
    final s = SettingsService();

    if (!s.dailyReminder && !s.streakReminders && !s.breakReminders) {
      await cancelAll();
      return;
    }

    if (s.dailyReminder) {
      await scheduleDailyReminder();
    } else {
      await _plugin.cancel(1);
    }

    if (s.streakReminders) {
      await scheduleStreakReminder();
    } else {
      await _plugin.cancel(2);
    }
  }

  // ── Daily reminder ────────────────────────────────────────────────────
  Future<void> scheduleDailyReminder() async {
    await init();
    final timeStr = SettingsService().dailyReminderTime; // "09:00"
    final parts = timeStr.split(':');
    final hour = int.tryParse(parts[0]) ?? 9;
    final minute = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;

    await _plugin.zonedSchedule(
      1,
      'Time to Focus! 🌱',
      'Start a focus session and grow your farm.',
      _nextInstanceOfTime(hour, minute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reminder',
          'Daily Reminder',
          channelDescription: 'Daily focus reminder',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexact,
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // ── Streak reminder ───────────────────────────────────────────────────
  Future<void> scheduleStreakReminder() async {
    await init();
    // Fire at 8 PM every day
    await _plugin.zonedSchedule(
      2,
      'Keep your streak alive! 🔥',
      "Don't forget to focus today!",
      _nextInstanceOfTime(20, 0),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'streak_reminder',
          'Streak Reminder',
          channelDescription: 'Streak reminder',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexact,
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation:
      UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  // ── Immediate notification (session complete etc.) ────────────────────
  Future<void> showInstant({
    required int id,
    required String title,
    required String body,
  }) async {
    await init();
    await _plugin.show(
      id,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'instant',
          'Instant',
          channelDescription: 'Instant notifications',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  Future<void> cancelAll() async {
    await init();
    await _plugin.cancelAll();
  }

  Future<void> cancelStreakReminder() async {
    await _plugin.cancel(2);
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}