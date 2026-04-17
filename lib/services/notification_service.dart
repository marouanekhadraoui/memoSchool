// // lib/services/notification_service.dart
// import 'dart:math';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:timezone/data/latest.dart' as tz;
// import 'package:timezone/timezone.dart' as tz;
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:flutter/material.dart';

// class NotificationService {
//   static final NotificationService _instance = NotificationService._internal();
//   factory NotificationService() => _instance;
//   NotificationService._internal();

//   final FlutterLocalNotificationsPlugin _notificationsPlugin =
//       FlutterLocalNotificationsPlugin();

//   final List<String> _notificationMessages = [
//     "🧠 Time to train your brain! Open the app now.",
//     "🎓 Have you done your daily exercise? Don't miss out.",
//     "💪 Your daily return is a step towards a brighter future.",
//     "✨ A journey of a thousand miles begins with a single step. What's yours today?",
//     "🏆 Keep your streak alive! Play and learn.",
//     "🧩 A new puzzle awaits you in Sudoku!",
//     "📖 Discover a new poem and sharpen your skills.",
//     "🧮 Test your calculation speed and challenge yourself.",
//     "⭐ Points and rewards are waiting for you. Join now!",
//     "🔥 Don't break your momentum! Come and earn more points."
//   ];

//   String _getRandomMessage() {
//     final randomIndex = DateTime.now().millisecondsSinceEpoch % _notificationMessages.length;
//     return _notificationMessages[randomIndex];
//   }

//   /// Generate two random times with at least 4 hours difference
//   (int hour1, int minute1, int hour2, int minute2) _generateRandomTimes() {
//     final random = Random();
//     int hour1 = random.nextInt(15) + 8; // 8 to 22
//     int minute1 = random.nextInt(60);
//     int offsetHours = random.nextInt(5) + 4; // 4 to 8 hours later
//     int hour2 = (hour1 + offsetHours) % 24;
//     int minute2 = random.nextInt(60);
//     return (hour1, minute1, hour2, minute2);
//   }

//   /// Save generated times to SharedPreferences
//   Future<void> _saveRandomTimes() async {
//     final prefs = await SharedPreferences.getInstance();
//     final times = _generateRandomTimes();
//     await prefs.setInt('notif_hour1', times.$1);
//     await prefs.setInt('notif_minute1', times.$2);
//     await prefs.setInt('notif_hour2', times.$3);
//     await prefs.setInt('notif_minute2', times.$4);
//     await prefs.setBool('times_generated', true);
//   }

//   /// Load saved times or generate new ones if not exist
//   Future<(int, int, int, int)> _getSavedTimes() async {
//     final prefs = await SharedPreferences.getInstance();
//     final bool generated = prefs.getBool('times_generated') ?? false;
//     if (!generated) {
//       await _saveRandomTimes();
//     }
//     final h1 = prefs.getInt('notif_hour1') ?? 10;
//     final m1 = prefs.getInt('notif_minute1') ?? 0;
//     final h2 = prefs.getInt('notif_hour2') ?? 18;
//     final m2 = prefs.getInt('notif_minute2') ?? 0;
//     return (h1, m1, h2, m2);
//   }

//   Future<void> initialize() async {
//     tz.initializeTimeZones();
//     tz.setLocalLocation(tz.getLocation('UTC'));

//     const AndroidInitializationSettings androidSettings =
//         AndroidInitializationSettings('@mipmap/ic_launcher');
//     const DarwinInitializationSettings iosSettings =
//         DarwinInitializationSettings(
//       requestAlertPermission: true,
//       requestBadgePermission: true,
//       requestSoundPermission: true,
//     );
//     const InitializationSettings settings = InitializationSettings(
//       android: androidSettings,
//       iOS: iosSettings,
//     );

//     await _notificationsPlugin.initialize(settings);
//   }

//   Future<void> requestPermissions() async {
//     await _notificationsPlugin.resolvePlatformSpecificImplementation<
//         IOSFlutterLocalNotificationsPlugin>()?.requestPermissions(
//       alert: true,
//       badge: true,
//       sound: true,
//     );
//     // Request exact alarm permission for Android 12+ (optional, only for exact scheduling)
//     await _notificationsPlugin
//         .resolvePlatformSpecificImplementation<
//             AndroidFlutterLocalNotificationsPlugin>()
//         ?.requestExactAlarmsPermission();
//   }

//   /// Schedule a daily notification using inexact mode (no exact alarm permission needed)
//   Future<void> _scheduleFixedDailyNotification({
//     required int id,
//     required int hour,
//     required int minute,
//   }) async {
//     final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
//     tz.TZDateTime scheduledDate = tz.TZDateTime(
//       tz.local,
//       now.year,
//       now.month,
//       now.day,
//       hour,
//       minute,
//     );

//     if (scheduledDate.isBefore(now)) {
//       scheduledDate = scheduledDate.add(const Duration(days: 1));
//     }

//     final String randomMessage = _getRandomMessage();

//     const AndroidNotificationDetails androidDetails =
//         AndroidNotificationDetails(
//       'reminder_channel',
//       'Daily Reminder',
//       channelDescription: 'Daily reminder to play games and train your brain',
//       importance: Importance.high,
//       priority: Priority.high,
//     );
//     const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();
//     const NotificationDetails details = NotificationDetails(
//       android: androidDetails,
//       iOS: iosDetails,
//     );

//     await _notificationsPlugin.zonedSchedule(
//       id,
//       'MemoSchool Daily Reminder 🧠',
//       randomMessage,
//       scheduledDate,
//       details,
//       androidScheduleMode: AndroidScheduleMode.inexact,
//       uiLocalNotificationDateInterpretation:
//           UILocalNotificationDateInterpretation.absoluteTime,
//       matchDateTimeComponents: DateTimeComponents.time,
//     );
//   }

//   /// Schedule two random daily notifications (times are fixed after first generation)
//   Future<void> scheduleRandomDailyNotifications() async {
//     final times = await _getSavedTimes();
//     await _scheduleFixedDailyNotification(id: 1, hour: times.$1, minute: times.$2);
//     await _scheduleFixedDailyNotification(id: 2, hour: times.$3, minute: times.$4);
//   }

//   /// Schedule a test notification (uses exact mode, may require permission)
//   Future<void> scheduleTestNotification({int delayInSeconds = 5}) async {
//     final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
//     final tz.TZDateTime scheduledDate = now.add(Duration(seconds: delayInSeconds));

//     const AndroidNotificationDetails androidDetails =
//         AndroidNotificationDetails(
//       'test_channel',
//       'Test Notifications',
//       channelDescription: 'Channel for test notifications',
//       importance: Importance.high,
//       priority: Priority.high,
//     );
//     const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();
//     const NotificationDetails details = NotificationDetails(
//       android: androidDetails,
//       iOS: iosDetails,
//     );

//     try {
//       await _notificationsPlugin.zonedSchedule(
//         999,
//         '🧪 Test Notification',
//         'This is a test notification from MemoSchool! (${DateTime.now().toLocal()})',
//         scheduledDate,
//         details,
//         androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
//         uiLocalNotificationDateInterpretation:
//             UILocalNotificationDateInterpretation.absoluteTime,
//       );
//     } catch (e) {
//       debugPrint('Test notification exact mode failed: $e, falling back to inexact');
//       await _notificationsPlugin.zonedSchedule(
//         999,
//         '🧪 Test Notification',
//         'This is a test notification from MemoSchool! (${DateTime.now().toLocal()})',
//         scheduledDate,
//         details,
//         androidScheduleMode: AndroidScheduleMode.inexact,
//         uiLocalNotificationDateInterpretation:
//             UILocalNotificationDateInterpretation.absoluteTime,
//       );
//     }
//   }

//   Future<void> cancelAllNotifications() async {
//     await _notificationsPlugin.cancelAll();
//   }

//   Future<List<PendingNotificationRequest>> getPendingNotifications() async {
//     return await _notificationsPlugin.pendingNotificationRequests();
//   }
// }