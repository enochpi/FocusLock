import 'package:flutter/material.dart';
import 'package:app_usage/app_usage.dart';
import 'package:focus_life/services/app_monitor_service.dart';
import 'screens/permission_screen.dart';
import 'screens/main_game_screen.dart';
import 'services/currency_service.dart';
import 'services/upgrade_service.dart';
import 'services/furniture_service.dart';
import 'services/settings_service.dart';
import 'services/streak_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Initialize all services with error handling
  try {
    await CurrencyService().init();
    debugPrint('✅ CurrencyService initialized');
  } catch (e) {
    debugPrint('❌ CurrencyService init failed: $e');
  }

  try {
    await UpgradeService().init();
    debugPrint('✅ UpgradeService initialized');
  } catch (e) {
    debugPrint('❌ UpgradeService init failed: $e');
  }

  try {
    await FurnitureService().init();
    debugPrint('✅ FurnitureService initialized');
  } catch (e) {
    debugPrint('❌ FurnitureService init failed: $e');
  }

  try {
    await SettingsService().init();
    debugPrint('✅ SettingsService initialized');
  } catch (e) {
    debugPrint('❌ SettingsService init failed: $e');
  }

  try {
    await StreakService().init();
    debugPrint('✅ StreakService initialized');
  } catch (e) {
    debugPrint('❌ StreakService init failed: $e');
  }

  try {
    await AppMonitorService().init();
    debugPrint('✅ AppMonitorService initialized');
  } catch (e) {
    debugPrint('❌ AppMonitorService init failed: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Focus Life',
      theme: ThemeData.dark(),
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    checkPermission();
  }

  Future<void> checkPermission() async {
    await Future.delayed(const Duration(seconds: 1));

    try {
      DateTime endDate = DateTime.now();
      DateTime startDate = endDate.subtract(const Duration(seconds: 1));

      List<AppUsageInfo> infos = await AppUsage().getAppUsage(startDate, endDate);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainGameScreen()),
      );
    } catch (e) {
      debugPrint('❌ Permission check failed: $e');

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const PermissionScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.psychology, size: 80, color: Color(0xFF00d4ff)),
            SizedBox(height: 20),
            Text(
              "Focus Life",
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 30),
            CircularProgressIndicator(color: Color(0xFF00d4ff)),
          ],
        ),
      ),
    );
  }
}