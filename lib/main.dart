import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'game_state.dart';
import 'pages/loading_screen.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final gameState = GameState();

  // ─────────────────────────────────────────────
  // NOTIFICATIONS BOOTSTRAP (FIXED + SAFE)
  // ─────────────────────────────────────────────
  final notificationService = NotificationService();

  try {
    await notificationService.initialize();
    await notificationService.requestPermissions();

    final prefs = await SharedPreferences.getInstance();
    final bool notificationsScheduled =
        prefs.getBool('notifications_scheduled') ?? false;

    // تشغيل أول مرة فقط (system safe)
    if (!notificationsScheduled) {
      await notificationService.scheduleDailyNotifications();

      await prefs.setBool('notifications_scheduled', true);

      debugPrint("✅ Notifications scheduled for first time");
    } else {
      // حتى لو سبق تشغيلها، نعيد التأكد أنها شغالة
      await notificationService.scheduleDailyNotifications();

      debugPrint("🔁 Notifications already existed → refreshed");
    }

    // اختبار سريع (اختياري لكن مهم للتحقق)
    await notificationService.testNotification();
    debugPrint("🧪 Test notification triggered (check phone)");

  } catch (e) {
    debugPrint("❌ Notification system failed: $e");
  }

  runApp(MyApp(gameState: gameState));
}

class MyApp extends StatelessWidget {
  final GameState gameState;

  const MyApp({super.key, required this.gameState});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: gameState,
      child: MaterialApp(
        title: 'Memoschool',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          fontFamily: 'Poppins',
        ),
        home: const LoadingScreen(),
      ),
    );
  }
}