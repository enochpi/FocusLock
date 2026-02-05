import 'package:flutter/material.dart';
import 'package:app_usage/app_usage.dart';
import 'screens/permission_screen.dart';
import 'screens/main_game_screen.dart';
import 'services/currency_service.dart';
import 'services/upgrade_service.dart';
import 'services/furniture_service.dart';
import 'services/settings_service.dart';  // ← ADD
import 'services/streak_service.dart';    // ← ADD

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize services
  await CurrencyService().init();
  await UpgradeService().init();
  await FurnitureService().init();
  await SettingsService().init();  // ← ADD
  await StreakService().init();    // ← ADD

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Focus Life',
      theme: ThemeData.dark(),
      home: SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class SplashScreen extends StatefulWidget {
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
    await Future.delayed(Duration(seconds: 1));

    try {
      DateTime endDate = DateTime.now();
      DateTime startDate = endDate.subtract(Duration(seconds: 1));

      List<AppUsageInfo> infos = await AppUsage().getAppUsage(startDate, endDate);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MainGameScreen()),
      );
    } catch (e) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => PermissionScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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