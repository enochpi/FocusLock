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

    // Mark as seen and go to game regardless
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
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🔒', style: TextStyle(fontSize: 80)),
              const SizedBox(height: 24),
              const Text(
                "One quick thing",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                "Focus Life can block distracting apps while you focus. To do this it needs Usage Access permission.\n\nThis is optional — you can skip it and still use the app.",
                style: TextStyle(color: Colors.white70, fontSize: 15, height: 1.6),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white12),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("How to enable:",
                        style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                    SizedBox(height: 10),
                    Text(
                      "1. Tap 'Open Settings' below\n"
                          "2. Find 'Focus Life' in the list\n"
                          "3. Toggle it ON\n"
                          "4. Come back and tap 'Done'",
                      style: TextStyle(color: Colors.white60, fontSize: 14, height: 1.7),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () async {
                  await AppSettings.openAppSettings(type: AppSettingsType.settings);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text("Open Settings",
                    style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: isChecking ? null : checkPermission,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white30),
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: isChecking
                    ? const SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
                    : const Text("Done →",
                    style: TextStyle(fontSize: 16, color: Colors.white70)),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('permission_screen_shown', true);
                  if (!mounted) return;
                  _goToGame();
                },
                child: const Text("Skip for now",
                    style: TextStyle(color: Colors.white38, fontSize: 14)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}