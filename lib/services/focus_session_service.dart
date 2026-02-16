import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../services/focus_session_service.dart';

class FocusSessionService {
  static final FocusSessionService _instance = FocusSessionService._internal();
  factory FocusSessionService() => _instance;
  FocusSessionService._internal();

  // Storage keys
  static const String _isActiveKey = 'focus_session_active';
  static const String _startTimeKey = 'focus_session_start_time';
  static const String _durationKey = 'focus_session_duration';
  static const String _remainingKey = 'focus_session_remaining';
  static const String _lastUpdateKey = 'focus_session_last_update';

  // ══════════════════════════════════════════════════════════════
  //  SAVE SESSION
  // ══════════════════════════════════════════════════════════════

  /// Start a new focus session
  Future<void> startSession({
    required int durationMinutes,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();

      await prefs.setBool(_isActiveKey, true);
      await prefs.setString(_startTimeKey, now.toIso8601String());
      await prefs.setInt(_durationKey, durationMinutes);
      await prefs.setInt(_remainingKey, durationMinutes * 60);
      await prefs.setString(_lastUpdateKey, now.toIso8601String());

      debugPrint('💾 Focus session started: $durationMinutes min');
    } catch (e) {
      debugPrint('Error starting session: $e');
    }
  }

  /// Update remaining time (call this every second or so)
  Future<void> updateRemainingTime(int remainingSeconds) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();

      await prefs.setInt(_remainingKey, remainingSeconds);
      await prefs.setString(_lastUpdateKey, now.toIso8601String());
    } catch (e) {
      debugPrint('Error updating session: $e');
    }
  }

  /// Mark session as complete
  Future<void> completeSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await _clearSession(prefs);
      debugPrint('✅ Focus session completed');
    } catch (e) {
      debugPrint('Error completing session: $e');
    }
  }

  /// Cancel session (user stopped early)
  Future<void> cancelSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await _clearSession(prefs);
      debugPrint('❌ Focus session cancelled');
    } catch (e) {
      debugPrint('Error cancelling session: $e');
    }
  }

  Future<void> _clearSession(SharedPreferences prefs) async {
    await prefs.remove(_isActiveKey);
    await prefs.remove(_startTimeKey);
    await prefs.remove(_durationKey);
    await prefs.remove(_remainingKey);
    await prefs.remove(_lastUpdateKey);
  }

  // ══════════════════════════════════════════════════════════════
  //  LOAD SESSION
  // ══════════════════════════════════════════════════════════════

  /// Check if there's an active session
  Future<bool> hasActiveSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_isActiveKey) ?? false;
    } catch (e) {
      debugPrint('Error checking active session: $e');
      return false;
    }
  }

  /// Get session data (returns null if no active session or expired)
  Future<FocusSessionData?> getActiveSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final isActive = prefs.getBool(_isActiveKey) ?? false;
      if (!isActive) {
        return null;
      }

      final startTimeStr = prefs.getString(_startTimeKey);
      final durationMinutes = prefs.getInt(_durationKey);
      final remainingSeconds = prefs.getInt(_remainingKey);
      final lastUpdateStr = prefs.getString(_lastUpdateKey);

      if (startTimeStr == null || durationMinutes == null || remainingSeconds == null || lastUpdateStr == null) {
        // Corrupted data, clear it
        await _clearSession(prefs);
        return null;
      }

      final startTime = DateTime.parse(startTimeStr);
      final lastUpdate = DateTime.parse(lastUpdateStr);
      final now = DateTime.now();

      // Calculate how much time passed since last update
      final secondsSinceUpdate = now.difference(lastUpdate).inSeconds;

      // Adjust remaining time
      int adjustedRemaining = remainingSeconds - secondsSinceUpdate;

      // If session expired while app was closed
      if (adjustedRemaining <= 0) {
        debugPrint('⏰ Session expired while app was closed');
        // Session finished! Need to give rewards
        await _clearSession(prefs);
        return FocusSessionData(
          startTime: startTime,
          durationMinutes: durationMinutes,
          remainingSeconds: 0,
          wasCompleted: true, // Session finished naturally
        );
      }

      return FocusSessionData(
        startTime: startTime,
        durationMinutes: durationMinutes,
        remainingSeconds: adjustedRemaining,
        wasCompleted: false,
      );
    } catch (e) {
      debugPrint('Error getting active session: $e');
      return null;
    }
  }
}

// ══════════════════════════════════════════════════════════════
//  DATA CLASS
// ══════════════════════════════════════════════════════════════

class FocusSessionData {
  final DateTime startTime;
  final int durationMinutes;
  final int remainingSeconds;
  final bool wasCompleted; // True if session finished while app was closed

  FocusSessionData({
    required this.startTime,
    required this.durationMinutes,
    required this.remainingSeconds,
    required this.wasCompleted,
  });

  int get elapsedSeconds => (durationMinutes * 60) - remainingSeconds;
  int get elapsedMinutes => elapsedSeconds ~/ 60;

  @override
  String toString() {
    return 'FocusSession(duration: $durationMinutes min, remaining: $remainingSeconds sec, completed: $wasCompleted)';
  }
}