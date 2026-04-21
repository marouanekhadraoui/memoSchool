import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance =
      NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  final Random _random = Random();

  // ─────────────────────────────────────────────
  // LOG SYSTEM (VERIFICATION CORE)
  // ─────────────────────────────────────────────
  Future<void> _log(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("log_$key", value);
  }

  Future<String?> getLog(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("log_$key");
  }

  // ─────────────────────────────────────────────
  // MESSAGES
  // ─────────────────────────────────────────────
  final List<String> _messages = [
    "🧠 Time to train your brain!",
    "🎓 Don’t skip your daily practice.",
    "💪 Small effort today = big results tomorrow.",
    "✨ One step today, mastery tomorrow.",
    "🏆 Keep your learning streak alive!",
    "📖 A quick session can change your day.",
    "🧮 Challenge your mind today!",
    "⭐ Points are waiting for you!",
    "🔥 Stay consistent, stay strong!"
  ];

  String _randomMessage() {
    return _messages[_random.nextInt(_messages.length)];
  }

  // ─────────────────────────────────────────────
  // INIT (CRITICAL FIX)
  // ─────────────────────────────────────────────
  Future<void> initialize() async {
    tz.initializeTimeZones();

    // IMPORTANT: proper local timezone setup
    tz.setLocalLocation(tz.getLocation('UTC'));

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');

    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: android,
      iOS: ios,
    );

    await _plugin.initialize(settings);

    await _log("init", "OK");
  }

  // ─────────────────────────────────────────────
  // PERMISSIONS
  // ─────────────────────────────────────────────
  Future<void> requestPermissions() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestExactAlarmsPermission();

    await _log("permissions", "OK");
  }

  // ─────────────────────────────────────────────
  // DAILY RANDOM TIMES ENGINE
  // ─────────────────────────────────────────────
  Future<(int, int, int, int)> _generateTimes() async {
    int h1 = _random.nextInt(14) + 8; // 8 → 22
    int m1 = _random.nextInt(60);

    int h2 = (h1 + _random.nextInt(6) + 3) % 24;
    int m2 = _random.nextInt(60);

    await _log("generated_times", "$h1:$m1 | $h2:$m2");

    return (h1, m1, h2, m2);
  }

  Future<void> _ensureDailyTimes() async {
    final prefs = await SharedPreferences.getInstance();

    final today = DateTime.now().toIso8601String().substring(0, 10);
    final last = prefs.getString("schedule_day");

    if (last != today) {
      final t = await _generateTimes();

      await prefs.setInt("h1", t.$1);
      await prefs.setInt("m1", t.$2);
      await prefs.setInt("h2", t.$3);
      await prefs.setInt("m2", t.$4);

      await prefs.setString("schedule_day", today);

      await _log("schedule", "NEW_DAY");
    } else {
      await _log("schedule", "EXISTING_DAY");
    }
  }

  Future<(int, int, int, int)> _getTimes() async {
    final prefs = await SharedPreferences.getInstance();

    return (
      prefs.getInt("h1") ?? 10,
      prefs.getInt("m1") ?? 0,
      prefs.getInt("h2") ?? 18,
      prefs.getInt("m2") ?? 0,
    );
  }

  // ─────────────────────────────────────────────
  // SCHEDULE CORE
  // ─────────────────────────────────────────────
  Future<void> _schedule({
    required int id,
    required int hour,
    required int minute,
  }) async {
    final now = tz.TZDateTime.now(tz.local);

    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _log("schedule_$id", "$hour:$minute");

    const android = AndroidNotificationDetails(
      'memo_channel',
      'MemoSchool',
      channelDescription: 'Daily learning reminders',
      importance: Importance.max,
      priority: Priority.high,
    );

    const details = NotificationDetails(android: android);

    await _plugin.zonedSchedule(
      id,
      "MemoSchool 🧠",
      _randomMessage(),
      scheduled,
      details,
      androidScheduleMode: AndroidScheduleMode.inexact,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );

    await _log("scheduled_$id", "OK");
  }

  // ─────────────────────────────────────────────
  // PUBLIC MAIN ENGINE
  // ─────────────────────────────────────────────
  Future<void> scheduleDailyNotifications() async {
    await _ensureDailyTimes();

    final t = await _getTimes();

    await _schedule(id: 1, hour: t.$1, minute: t.$2);
    await _schedule(id: 2, hour: t.$3, minute: t.$4);

    await _log("final", "ALL_OK");
  }

  // ─────────────────────────────────────────────
  // TEST NOTIFICATION (REAL VERIFICATION)
  // ─────────────────────────────────────────────
  Future<void> testNotification() async {
    final now = tz.TZDateTime.now(tz.local).add(
      const Duration(seconds: 5),
    );

    const android = AndroidNotificationDetails(
      'test_channel',
      'Test',
      importance: Importance.max,
      priority: Priority.high,
    );

    const details = NotificationDetails(android: android);

    await _plugin.zonedSchedule(
      999,
      "TEST 🧪",
      "If you see this → WORKING",
      now,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );

    await _log("test", "FIRED");
  }

  // ─────────────────────────────────────────────
  // DEBUG STATUS CHECKER
  // ─────────────────────────────────────────────
  Future<Map<String, String?>> debugStatus() async {
    return {
      "init": await getLog("init"),
      "permissions": await getLog("permissions"),
      "schedule": await getLog("schedule"),
      "final": await getLog("final"),
      "test": await getLog("test"),
    };
  }

  // ─────────────────────────────────────────────
  // CANCEL
  // ─────────────────────────────────────────────
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
    await _log("cancel", "CLEARED");
  }
}