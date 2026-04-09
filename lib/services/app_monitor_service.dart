import 'dart:async';
import 'package:app_usage/app_usage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

// ✅ Top level function required for compute()
Future<List<AppUsageInfo>> _fetchAppUsage(List<DateTime> args) async {
  return await AppUsage().getAppUsage(args[0], args[1]);
}

class AppMonitorService {
  static final AppMonitorService _instance = AppMonitorService._internal();
  factory AppMonitorService() => _instance;
  AppMonitorService._internal();

  Timer? _monitorTimer;
  DateTime? _lastCheck;
  bool _isMonitoring = false;

  // ✅ Track which apps already triggered this session
  final Set<String> _triggeredThisSession = {};

  // ✅ Cooldown tracking
  final Map<String, DateTime> _lastTriggered = {};
  static const int _cooldownSeconds = 30;

  static const String _blockedAppsKey = 'blocked_apps';
  Set<String> _blockedApps = {};

  Function(String appName, String packageName)? _onBlockedAppDetected;

  final List<String> _defaultBlockedApps = [
    'com.instagram.android',
    'com.twitter.android',
    'com.facebook.katana',
    'com.snapchat.android',
    'com.zhiliaoapp.musically',
    'com.reddit.frontpage',
    'com.pinterest',
    'com.tumblr',
  ];

  // ══════════════════════════════════════════════════════════════
  //  INITIALIZATION
  // ══════════════════════════════════════════════════════════════

  Future<void> init() async {
    await _loadBlockedApps();
    if (_blockedApps.isEmpty) {
      _blockedApps = Set.from(_defaultBlockedApps);
      await _saveBlockedApps();
    }
    debugPrint('AppMonitorService initialized with ${_blockedApps.length} blocked apps');
  }

  Future<void> _loadBlockedApps() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String>? stored = prefs.getStringList(_blockedAppsKey);
      if (stored != null) _blockedApps = Set.from(stored);
    } catch (e) {
      debugPrint('Error loading blocked apps: $e');
      _blockedApps = {};
    }
  }

  Future<void> _saveBlockedApps() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_blockedAppsKey, _blockedApps.toList());
    } catch (e) {
      debugPrint('Error saving blocked apps: $e');
    }
  }

  // ══════════════════════════════════════════════════════════════
  //  MONITORING CONTROL
  // ══════════════════════════════════════════════════════════════

  void startMonitoring(
      Function(String appName, String packageName) onBlockedAppDetected) {
    if (_isMonitoring) return;

    _onBlockedAppDetected = onBlockedAppDetected;
    _lastCheck = DateTime.now();
    _isMonitoring = true;
    _triggeredThisSession.clear();

    // ✅ Increased to 3 seconds to reduce frequency of heavy native calls
    _monitorTimer =
        Timer.periodic(const Duration(seconds: 3), (timer) async {
          await _checkForBlockedApps();
        });

    debugPrint('Started monitoring for blocked apps');
  }

  void stopMonitoring() {
    _monitorTimer?.cancel();
    _monitorTimer = null;
    _isMonitoring = false;
    _onBlockedAppDetected = null;
    _lastCheck = null;
    _triggeredThisSession.clear();
    debugPrint('Stopped monitoring');
  }

  // ✅ Call when blocking screen dismissed
  void onBlockDismissed(String packageName) {
    _triggeredThisSession.remove(packageName);
    _lastTriggered[packageName] = DateTime.now();
    debugPrint('🔓 Block dismissed for $packageName — cooldown started');
  }

  bool get isMonitoring => _isMonitoring;

  // ══════════════════════════════════════════════════════════════
  //  APP DETECTION
  // ══════════════════════════════════════════════════════════════

  Future<void> _checkForBlockedApps() async {
    if (!_isMonitoring || _onBlockedAppDetected == null) return;

    try {
      final DateTime now = DateTime.now();
      final DateTime checkFrom =
          _lastCheck ?? now.subtract(const Duration(seconds: 4));

      // ✅ Run on separate isolate so it NEVER blocks the main thread
      final List<AppUsageInfo> infos =
      await compute(_fetchAppUsage, [checkFrom, now]);

      for (var info in infos) {
        if (!_blockedApps.contains(info.packageName)) continue;
        if (_triggeredThisSession.contains(info.packageName)) continue;

        final lastTime = _lastTriggered[info.packageName];
        if (lastTime != null) {
          final secondsSince = now.difference(lastTime).inSeconds;
          if (secondsSince < _cooldownSeconds) {
            debugPrint(
                '⏳ ${info.packageName} in cooldown ($secondsSince/${_cooldownSeconds}s)');
            continue;
          }
        }

        _triggeredThisSession.add(info.packageName);
        debugPrint(
            '🚫 Blocked app detected: ${info.appName} (${info.packageName})');
        _onBlockedAppDetected!(info.appName, info.packageName);
        break;
      }

      _lastCheck = now;
    } catch (e) {
      debugPrint('Error checking for blocked apps: $e');
    }
  }

  // ══════════════════════════════════════════════════════════════
  //  BLOCKED APPS MANAGEMENT
  // ══════════════════════════════════════════════════════════════

  Future<void> addBlockedApp(String packageName) async {
    _blockedApps.add(packageName);
    await _saveBlockedApps();
  }

  Future<void> removeBlockedApp(String packageName) async {
    _blockedApps.remove(packageName);
    await _saveBlockedApps();
  }

  Future<List<String>> getBlockedApps() async => _blockedApps.toList();

  Set<String> get blockedApps => Set.from(_blockedApps);
  int get blockedAppCount => _blockedApps.length;
  bool isAppBlocked(String packageName) => _blockedApps.contains(packageName);

  Future<void> clearAllBlockedApps() async {
    _blockedApps.clear();
    await _saveBlockedApps();
  }

  Future<void> resetToDefaults() async {
    _blockedApps = Set.from(_defaultBlockedApps);
    await _saveBlockedApps();
    debugPrint('✅ Reset to default blocked apps');
  }

  // ══════════════════════════════════════════════════════════════
  //  INSTALLED APPS DETECTION
  // ══════════════════════════════════════════════════════════════

  Future<List<AppUsageInfo>> getAllInstalledApps() async {
    try {
      final DateTime endDate = DateTime.now();
      // ✅ Reduced from 90 to 14 days — much faster query
      final DateTime startDate = endDate.subtract(const Duration(days: 14));

      // ✅ Also runs on isolate so blocked apps screen doesn't freeze
      final List<AppUsageInfo> infos =
      await compute(_fetchAppUsage, [startDate, endDate]);

      infos.sort((a, b) => a.appName.compareTo(b.appName));
      return infos;
    } catch (e) {
      debugPrint('Error getting installed apps: $e');
      return [];
    }
  }

  // ══════════════════════════════════════════════════════════════
  //  STATISTICS
  // ══════════════════════════════════════════════════════════════

  static const String _blockCountKey = 'block_count';

  Future<void> incrementBlockCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      int current = prefs.getInt(_blockCountKey) ?? 0;
      await prefs.setInt(_blockCountKey, current + 1);
    } catch (e) {
      debugPrint('Error incrementing block count: $e');
    }
  }

  Future<int> getTotalBlockCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_blockCountKey) ?? 0;
    } catch (e) {
      debugPrint('Error getting block count: $e');
      return 0;
    }
  }

  Future<void> resetBlockCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_blockCountKey, 0);
    } catch (e) {
      debugPrint('Error resetting block count: $e');
    }
  }

  // ══════════════════════════════════════════════════════════════
  //  CLEANUP
  // ══════════════════════════════════════════════════════════════

  void dispose() {
    stopMonitoring();
  }
}