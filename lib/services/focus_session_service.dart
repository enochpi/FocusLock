import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter/foundation.dart';

class FocusSessionService {
  static final FocusSessionService _instance = FocusSessionService._internal();
  factory FocusSessionService() => _instance;
  FocusSessionService._internal();

  static const String _isActiveKey      = 'focus_session_active';
  static const String _startTimeKey     = 'focus_session_start_time';
  static const String _durationKey      = 'focus_session_duration';
  static const String _lastUpdateKey    = 'focus_session_last_update';
  static const String _remainingKey     = 'focus_session_remaining_at_update';

  // ══════════════════════════════════════════════════════════════
  //  START SESSION
  // ══════════════════════════════════════════════════════════════

  Future<void> startSession({required int durationMinutes}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();

      await prefs.setBool(_isActiveKey, true);
      await prefs.setString(_startTimeKey, now.toIso8601String());
      await prefs.setInt(_durationKey, durationMinutes);
      await prefs.setString(_lastUpdateKey, now.toIso8601String());
      await prefs.setInt(_remainingKey, durationMinutes * 60);

      await FlutterForegroundTask.saveData(
        key: 'remainingSeconds',
        value: durationMinutes * 60,
      );

      debugPrint('💾 Session started: $durationMinutes min');
    } catch (e) {
      debugPrint('Error starting session: $e');
    }
  }

  // ══════════════════════════════════════════════════════════════
  //  UPDATE — called every 5 seconds while running
  // ══════════════════════════════════════════════════════════════

  Future<void> updateRemainingTime(int remainingSeconds) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      // ✅ Save BOTH the timestamp AND the remaining seconds together
      // so when phone turns back on we know exactly where we left off
      await prefs.setString(_lastUpdateKey, now.toIso8601String());
      await prefs.setInt(_remainingKey, remainingSeconds);
    } catch (e) {
      debugPrint('Error updating session: $e');
    }
  }

  // ══════════════════════════════════════════════════════════════
  //  COMPLETE / CANCEL
  // ══════════════════════════════════════════════════════════════

  Future<void> completeSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await _clearSession(prefs);
      debugPrint('✅ Session completed');
    } catch (e) {
      debugPrint('Error completing session: $e');
    }
  }

  Future<void> cancelSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await _clearSession(prefs);
      debugPrint('❌ Session cancelled');
    } catch (e) {
      debugPrint('Error cancelling session: $e');
    }
  }

  Future<void> _clearSession(SharedPreferences prefs) async {
    await prefs.remove(_isActiveKey);
    await prefs.remove(_startTimeKey);
    await prefs.remove(_durationKey);
    await prefs.remove(_lastUpdateKey);
    await prefs.remove(_remainingKey);
    await FlutterForegroundTask.saveData(key: 'remainingSeconds', value: 0);
  }

  // ══════════════════════════════════════════════════════════════
  //  GET ACTIVE SESSION
  // ══════════════════════════════════════════════════════════════

  Future<bool> hasActiveSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_isActiveKey) ?? false;
    } catch (e) {
      return false;
    }
  }

  Future<FocusSessionData?> getActiveSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final isActive = prefs.getBool(_isActiveKey) ?? false;
      if (!isActive) return null;

      final startTimeStr    = prefs.getString(_startTimeKey);
      final durationMinutes = prefs.getInt(_durationKey);
      final lastUpdateStr   = prefs.getString(_lastUpdateKey);
      final remainingAtUpdate = prefs.getInt(_remainingKey);

      if (startTimeStr == null || durationMinutes == null) {
        await _clearSession(prefs);
        return null;
      }

      final startTime  = DateTime.parse(startTimeStr);
      final now        = DateTime.now();
      final totalSeconds = durationMinutes * 60;

      int remainingSeconds;

      if (lastUpdateStr != null && remainingAtUpdate != null) {
        // ✅ We know exactly how many seconds were left at last update
        // AND exactly when that update was saved
        // So: remaining = remainingAtUpdate - secondsSinceLastUpdate
        final lastUpdate = DateTime.parse(lastUpdateStr);
        final secondsSinceUpdate = now.difference(lastUpdate).inSeconds;

        remainingSeconds = remainingAtUpdate - secondsSinceUpdate;

        debugPrint('📱 Last update: $lastUpdateStr');
        debugPrint('📱 Remaining at update: ${remainingAtUpdate}s');
        debugPrint('📱 Seconds since update: ${secondsSinceUpdate}s');
        debugPrint('📱 Calculated remaining: ${remainingSeconds}s');
      } else {
        // ✅ Fallback: calculate from session start time
        // Less accurate but better than nothing
        final elapsed = now.difference(startTime).inSeconds;
        remainingSeconds = totalSeconds - elapsed;
        debugPrint('📱 Using start time fallback: ${remainingSeconds}s remaining');
      }

      // ✅ Session finished while phone was off
      if (remainingSeconds <= 0) {
        debugPrint('⏰ Session finished while phone was off!');
        await _clearSession(prefs);
        return FocusSessionData(
          startTime: startTime,
          durationMinutes: durationMinutes,
          remainingSeconds: 0,
          wasCompleted: true,
        );
      }

      return FocusSessionData(
        startTime: startTime,
        durationMinutes: durationMinutes,
        remainingSeconds: remainingSeconds,
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
  final bool wasCompleted;

  FocusSessionData({
    required this.startTime,
    required this.durationMinutes,
    required this.remainingSeconds,
    required this.wasCompleted,
  });

  int get elapsedSeconds => (durationMinutes * 60) - remainingSeconds;
  int get elapsedMinutes => elapsedSeconds ~/ 60;

  @override
  String toString() =>
      'FocusSession(duration: $durationMinutes min, remaining: $remainingSeconds sec, completed: $wasCompleted)';
}