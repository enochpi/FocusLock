import 'package:flutter/material.dart';
import 'package:app_usage/app_usage.dart';
import 'package:app_settings/app_settings.dart';  // ADD THIS
import 'home_screen.dart';

class PermissionScreen extends StatefulWidget {
  @override
  _PermissionScreenState createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen> {
  bool isChecking = false;

  Future<void> checkPermission() async {
    setState(() {
      isChecking = true;
    });

    try {
      // Try to get app usage data
      DateTime endDate = DateTime.now();
      DateTime startDate = endDate.subtract(Duration(seconds: 1));

      List<AppUsageInfo> infos = await AppUsage().getAppUsage(startDate, endDate);

      // If we got here, permission is granted!
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    } catch (e) {
      // Permission not granted
      setState(() {
        isChecking = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Please enable Usage Access for Focus Life"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shield, size: 100, color: Colors.blue),
              SizedBox(height: 30),
              Text(
                "Permission Required",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              Text(
                "Focus Life needs Usage Access permission to detect when you open distracting apps.",
                style: TextStyle(color: Colors.white70, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 40),
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[850],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Steps:",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "1. Tap 'Open Settings' below\n"
                          "2. Find 'Focus Life' in the list\n"
                          "3. Toggle it ON\n"
                          "4. Come back and tap 'Check Permission'",
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 40),
              ElevatedButton(
                onPressed: () async {
                  await AppSettings.openAppSettings(type: AppSettingsType.settings);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  "Open Settings",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
              SizedBox(height: 20),
              OutlinedButton(
                onPressed: isChecking ? null : checkPermission,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.white70),
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isChecking
                    ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : Text(
                  "Check Permission",
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}