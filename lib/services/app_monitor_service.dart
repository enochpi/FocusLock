import 'dart:async';
import 'package:app_usage/app_usage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class AppMonitorService {
  static final AppMonitorService _instance = AppMonitorService._internal();
  factory AppMonitorService() => _instance;
  AppMonitorService._internal();

  // Monitoring state
  Timer? _monitorTimer;
  DateTime? _lastCheck;
  bool _isMonitoring = false;

  // Storage key
  static const String _blockedAppsKey = 'blocked_apps';

  // Blocked apps list (package names)
  Set<String> _blockedApps = {};

  // Callback when blocked app detected
  Function(String appName, String packageName)? _onBlockedAppDetected;

  // Default blocked apps (will be added on first launch)
  final List<String> _defaultBlockedApps = [
    'com.instagram.android',
    'com.twitter.android',
    'com.facebook.katana',
    'com.snapchat.android',
    'com.zhiliaoapp.musically', // TikTok
    'com.reddit.frontpage',
    'com.pinterest',
    'com.tumblr',
  ];

  // ══════════════════════════════════════════════════════════════
  //  INITIALIZATION
  // ══════════════════════════════════════════════════════════════

  Future<void> init() async {
    await _loadBlockedApps();

    // If no blocked apps stored, use defaults
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

      if (stored != null) {
        _blockedApps = Set.from(stored);
      }
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

  /// Start monitoring for blocked apps
  void startMonitoring(Function(String appName, String packageName) onBlockedAppDetected) {
    if (_isMonitoring) {
      debugPrint('Already monitoring');
      return;
    }

    _onBlockedAppDetected = onBlockedAppDetected;
    _lastCheck = DateTime.now();
    _isMonitoring = true;

    // Check every 2 seconds
    _monitorTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      await _checkForBlockedApps();
    });

    debugPrint('Started monitoring for blocked apps');
  }

  /// Stop monitoring
  void stopMonitoring() {
    _monitorTimer?.cancel();
    _monitorTimer = null;
    _isMonitoring = false;
    _onBlockedAppDetected = null;
    _lastCheck = null;

    debugPrint('Stopped monitoring');
  }

  /// Check if currently monitoring
  bool get isMonitoring => _isMonitoring;

  // ══════════════════════════════════════════════════════════════
  //  APP DETECTION
  // ══════════════════════════════════════════════════════════════

  Future<void> _checkForBlockedApps() async {
    if (!_isMonitoring || _onBlockedAppDetected == null) {
      return;
    }

    try {
      final DateTime now = DateTime.now();
      final DateTime checkFrom = _lastCheck ?? now.subtract(const Duration(seconds: 3));

      // Get app usage data
      List<AppUsageInfo> infos = await AppUsage().getAppUsage(checkFrom, now);

      // Check each app
      for (var info in infos) {
        if (_blockedApps.contains(info.packageName)) {
          // ⚠️ BLOCKED APP DETECTED!
          debugPrint('🚫 Blocked app detected: ${info.appName} (${info.packageName})');

          // Trigger callback
          _onBlockedAppDetected!(info.appName, info.packageName);

          // Only trigger once per check cycle
          break;
        }
      }

      _lastCheck = now;
    } catch (e) {
      debugPrint('Error checking for blocked apps: $e');
      // Don't stop monitoring on error - permission might be temporarily unavailable
    }
  }

  // ══════════════════════════════════════════════════════════════
  //  BLOCKED APPS MANAGEMENT
  // ══════════════════════════════════════════════════════════════

  /// Add a blocked app
  Future<void> addBlockedApp(String packageName) async {
    _blockedApps.add(packageName);
    await _saveBlockedApps();
    debugPrint('✅ Added blocked app: $packageName');
  }

  /// Remove a blocked app
  Future<void> removeBlockedApp(String packageName) async {
    _blockedApps.remove(packageName);
    await _saveBlockedApps();
    debugPrint('✅ Removed blocked app: $packageName');
  }

  /// Get list of currently blocked apps
  Future<List<String>> getBlockedApps() async {
    return _blockedApps.toList();
  }

  /// Get list of blocked apps (synchronous)
  Set<String> get blockedApps => Set.from(_blockedApps);

  /// Get count of blocked apps
  int get blockedAppCount => _blockedApps.length;

  /// Check if app is blocked
  bool isAppBlocked(String packageName) {
    return _blockedApps.contains(packageName);
  }

  /// Clear all blocked apps
  Future<void> clearAllBlockedApps() async {
    _blockedApps.clear();
    await _saveBlockedApps();
    debugPrint('Cleared all blocked apps');
  }

  /// Reset to default blocked apps
  Future<void> resetToDefaults() async {
    _blockedApps = Set.from(_defaultBlockedApps);
    await _saveBlockedApps();
    debugPrint('✅ Reset to default blocked apps');
  }

  // ══════════════════════════════════════════════════════════════
  //  INSTALLED APPS DETECTION
  // ══════════════════════════════════════════════════════════════

  /// Get all installed apps (useful for blocked apps manager UI)
  Future<List<AppUsageInfo>> getAllInstalledApps() async {
    try {
      final DateTime endDate = DateTime.now();
      final DateTime startDate = endDate.subtract(const Duration(days: 30));

      // Get apps used in last 30 days
      List<AppUsageInfo> infos = await AppUsage().getAppUsage(startDate, endDate);

      // Sort by app name
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

  /// Increment block count
  Future<void> incrementBlockCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      int current = prefs.getInt(_blockCountKey) ?? 0;
      await prefs.setInt(_blockCountKey, current + 1);
    } catch (e) {
      debugPrint('Error incrementing block count: $e');
    }
  }

  /// Get total times apps were blocked
  Future<int> getTotalBlockCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_blockCountKey) ?? 0;
    } catch (e) {
      debugPrint('Error getting block count: $e');
      return 0;
    }
  }

  /// Reset block count
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