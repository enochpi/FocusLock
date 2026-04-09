import 'package:flutter/material.dart';
import 'package:app_usage/app_usage.dart';
import 'package:app_settings/app_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'main_game_screen.dart';

class PermissionScreen extends StatefulWidget {
  const PermissionScreen({super.key});

  @override
  _PermissionScreenState createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen> {
  bool isChecking = false;

  void _goToGame() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MainGameScreen()),
    );
  }

  Future<void> checkPermission() async {
    setState(() => isChecking = true);
    await Future.delayed(const Duration(seconds: 1));

    try {
      DateTime endDate = DateTime.now();
      DateTime startDate = endDate.subtract(const Duration(seconds: 1));
      await AppUsage().getAppUsage(startDate, endDate);
    } catch (e) {
      debugPrint('Permission not granted yet: $e');
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('permission_screen_shown', true);

    if (!mounted) return;
    _goToGame();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF16213e),
      body: SafeArea(
        // ✅ SingleChildScrollView prevents overflow on small screens
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              const Text('🔒', style: TextStyle(fontSize: 70)),
              const SizedBox(height: 20),

              // ✅ Simpler title
              const Text(
                'One Quick Step',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // ✅ Much shorter description
              const Text(
                'To block distracting apps during focus sessions, we need Usage Access permission.\n\nThis is optional — you can skip it.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // ✅ Simpler instructions
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white12),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('How to enable:',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold)),
                    SizedBox(height: 10),
                    Text(
                      '1. Tap "Open Settings"\n'
                          '2. Find Focus Life in the list\n'
                          '3. Toggle it ON\n'
                          '4. Come back and tap Done',
                      style: TextStyle(
                          color: Colors.white60,
                          fontSize: 13,
                          height: 1.6),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Open Settings button
              ElevatedButton(
                onPressed: () async {
                  await AppSettings.openAppSettings(
                      type: AppSettingsType.settings);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Open Settings',
                    style: TextStyle(
                        fontSize: 15,
                        color: Colors.white,
                        fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 10),

              // Done button
              OutlinedButton(
                onPressed: isChecking ? null : checkPermission,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white30),
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: isChecking
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
                    : const Text('Done →',
                    style: TextStyle(
                        fontSize: 15, color: Colors.white70)),
              ),
              const SizedBox(height: 10),

              // Skip button
              TextButton(
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('permission_screen_shown', true);
                  if (!mounted) return;
                  _goToGame();
                },
                child: const Text('Skip for now',
                    style: TextStyle(
                        color: Colors.white38, fontSize: 13)),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }
}