import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'game_state.dart';
import 'pages/loading_screen.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final gameState = GameState();

//   final NotificationService notificationService = NotificationService();
//   await notificationService.initialize();
//   await notificationService.requestPermissions();

//   final prefs = await SharedPreferences.getInstance();
//   final bool notificationsScheduled = prefs.getBool('notifications_scheduled') ?? false;

//   if (!notificationsScheduled) {
//     // Schedule two random daily notifications (times are saved and will be reused)
//     await notificationService.scheduleRandomDailyNotifications();
//     await prefs.setBool('notifications_scheduled', true);

//     
// try {
//   await notificationService.scheduleRandomDailyNotifications();
//   await prefs.setBool('notifications_scheduled', true);
// } catch (e) {
//   debugPrint('Failed to schedule daily notifications: $e');
// }
//   }

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