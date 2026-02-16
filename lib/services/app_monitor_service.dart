import 'dart:async';
import 'package:app_usage/app_usage.dart';

class AppMonitorService {
  Timer? _monitorTimer;

  // Common social media apps to block
  List<String> blockedApps = [
    'com.instagram.android',
    'com.zhiliaoapp.musically', // TikTok
    'com.twitter.android',
    'com.google.android.youtube',
    'com.reddit.frontpage',
    'com.facebook.katana',
    'com.snapchat.android',
    'com.discord',
  ];

  Function(String)? onBlockedAppOpened;
  bool isMonitoring = false;

  void startMonitoring() {
    if (isMonitoring) return;

    print("👀 Starting app monitoring...");
    isMonitoring = true;

    _monitorTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      String? currentApp = await getCurrentApp();

      if (currentApp != null && blockedApps.contains(currentApp)) {
        print("🚫 BLOCKED APP DETECTED: $currentApp");
        onBlockedAppOpened?.call(currentApp);
      }
    });
  }

  Future<String?> getCurrentApp() async {
    try {
      DateTime endDate = DateTime.now();
      DateTime startDate = endDate.subtract(const Duration(seconds: 2));

      List<AppUsageInfo> infos = await AppUsage().getAppUsage(startDate, endDate);

      if (infos.isNotEmpty) {
        return infos.first.packageName;
      }
    } catch (e) {
      // Permission error - ignore
    }
    return null;
  }

  void stopMonitoring() {
    _monitorTimer?.cancel();
    isMonitoring = false;
    print("✋ Stopped monitoring");
  }

  void addBlockedApp(String packageName) {
    if (!blockedApps.contains(packageName)) {
      blockedApps.add(packageName);
    }
  }

  void removeBlockedApp(String packageName) {
    blockedApps.remove(packageName);
  }
}