// Berry Focused focus-session API v3.
// Required by GardenFocusScreen and CaveSceneScreen.
// Includes: initialRemainingSeconds, pauseSession, resumeSession,
// completeSession, acknowledgeCompletion, and recovery support.

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FocusSessionData {
  final DateTime startTime;
  final int durationMinutes;
  final int remainingSeconds;
  final bool wasCompleted;
  final bool isPaused;
  final DateTime? endTime;

  const FocusSessionData({
    required this.startTime,
    required this.durationMinutes,
    required this.remainingSeconds,
    required this.wasCompleted,
    required this.isPaused,
    required this.endTime,
  });
}

class FocusSessionService {
  static final FocusSessionService _instance =
      FocusSessionService._internal();
  factory FocusSessionService() => _instance;
  FocusSessionService._internal();

  static const String _activeKey = 'focus_session_active';
  static const String _startTimeKey = 'focus_session_start_time';
  static const String _durationKey = 'focus_session_duration';
  static const String _lastUpdateKey = 'focus_session_last_update';
  static const String _remainingAtUpdateKey =
      'focus_session_remaining_at_update';

  static const String _endTimeKey = 'focus_session_end_time_v2';
  static const String _pausedKey = 'focus_session_paused_v2';
  static const String _completedKey = 'focus_session_completed_v2';
  static const String _versionKey = 'focus_session_version';

  static const String _legacyJsonKey = 'active_focus_session';

  Future<void> startSession({
    required int durationMinutes,
    int? initialRemainingSeconds,
  }) async {
    final safeDuration = durationMinutes.clamp(1, 24 * 60).toInt();
    final totalSeconds = safeDuration * 60;
    final remaining = (initialRemainingSeconds ?? totalSeconds)
        .clamp(1, totalSeconds)
        .toInt();
    final now = DateTime.now();
    final endTime = now.add(Duration(seconds: remaining));
    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt(_versionKey, 2);
    await prefs.setBool(_activeKey, true);
    await prefs.setInt(_startTimeKey, now.millisecondsSinceEpoch);
    await prefs.setInt(_durationKey, safeDuration);
    await prefs.setInt(_lastUpdateKey, now.millisecondsSinceEpoch);
    await prefs.setInt(_remainingAtUpdateKey, remaining);
    await prefs.setInt(_endTimeKey, endTime.millisecondsSinceEpoch);
    await prefs.setBool(_pausedKey, false);
    await prefs.setBool(_completedKey, false);
    await prefs.remove(_legacyJsonKey);

    debugPrint('💾 Session started: $safeDuration min ($remaining sec)');
  }

  Future<void> updateRemainingTime(int remainingSeconds) async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool(_activeKey) ?? false)) return;

    final remaining = remainingSeconds.clamp(0, 24 * 60 * 60).toInt();
    final now = DateTime.now();
    final paused = prefs.getBool(_pausedKey) ?? false;

    await prefs.setInt(_lastUpdateKey, now.millisecondsSinceEpoch);
    await prefs.setInt(_remainingAtUpdateKey, remaining);

    if (remaining <= 0) {
      await prefs.setBool(_completedKey, true);
      await prefs.setBool(_pausedKey, false);
      await prefs.remove(_endTimeKey);
    } else if (!paused) {
      await prefs.setInt(
        _endTimeKey,
        now.add(Duration(seconds: remaining)).millisecondsSinceEpoch,
      );
    }
  }

  Future<void> pauseSession({required int remainingSeconds}) async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool(_activeKey) ?? false)) return;

    final remaining = remainingSeconds.clamp(0, 24 * 60 * 60).toInt();
    final now = DateTime.now();

    await prefs.setBool(_pausedKey, true);
    await prefs.setInt(_remainingAtUpdateKey, remaining);
    await prefs.setInt(_lastUpdateKey, now.millisecondsSinceEpoch);
    await prefs.remove(_endTimeKey);
  }

  Future<void> resumeSession({required int remainingSeconds}) async {
    final prefs = await SharedPreferences.getInstance();
    final remaining = remainingSeconds.clamp(1, 24 * 60 * 60).toInt();
    final now = DateTime.now();

    // Recovery from an older session may not have every v2 key yet.
    await prefs.setBool(_activeKey, true);
    await prefs.setBool(_pausedKey, false);
    await prefs.setBool(_completedKey, false);
    await prefs.setInt(_remainingAtUpdateKey, remaining);
    await prefs.setInt(_lastUpdateKey, now.millisecondsSinceEpoch);
    await prefs.setInt(
      _endTimeKey,
      now.add(Duration(seconds: remaining)).millisecondsSinceEpoch,
    );
  }

  Future<void> completeSession() async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool(_activeKey) ?? false)) return;

    await prefs.setBool(_completedKey, true);
    await prefs.setBool(_pausedKey, false);
    await prefs.setInt(_remainingAtUpdateKey, 0);
    await prefs.setInt(
      _lastUpdateKey,
      DateTime.now().millisecondsSinceEpoch,
    );
    await prefs.remove(_endTimeKey);
  }

  // Call this only after rewards/stats have been written successfully.
  Future<void> acknowledgeCompletion() => _clearSession();

  Future<void> cancelSession() => _clearSession();

  Future<bool> hasActiveSession() async {
    final session = await getActiveSession();
    return session != null;
  }

  Future<FocusSessionData?> getActiveSession() async {
    final prefs = await SharedPreferences.getInstance();
    await _migrateLegacyJsonIfNeeded(prefs);

    if (!(prefs.getBool(_activeKey) ?? false)) return null;

    final now = DateTime.now();
    final durationMinutes =
        (prefs.getInt(_durationKey) ?? 1).clamp(1, 24 * 60).toInt();
    final startMillis = prefs.getInt(_startTimeKey) ??
        now.millisecondsSinceEpoch;
    final startTime = DateTime.fromMillisecondsSinceEpoch(startMillis);
    final paused = prefs.getBool(_pausedKey) ?? false;
    bool completed = prefs.getBool(_completedKey) ?? false;
    int remaining = (prefs.getInt(_remainingAtUpdateKey) ??
            durationMinutes * 60)
        .clamp(0, 24 * 60 * 60)
        .toInt();

    DateTime? endTime;
    final endMillis = prefs.getInt(_endTimeKey);
    if (endMillis != null) {
      endTime = DateTime.fromMillisecondsSinceEpoch(endMillis);
    }

    if (!paused && !completed) {
      if (endTime != null) {
        final msLeft = endTime.difference(now).inMilliseconds;
        remaining = msLeft <= 0 ? 0 : (msLeft / 1000).ceil();
      } else {
        // Backward-compatible calculation from the old snapshot keys.
        final lastUpdateMillis = prefs.getInt(_lastUpdateKey);
        if (lastUpdateMillis != null) {
          final lastUpdate =
              DateTime.fromMillisecondsSinceEpoch(lastUpdateMillis);
          final elapsed = now.difference(lastUpdate).inSeconds;
          remaining = (remaining - elapsed).clamp(0, 24 * 60 * 60).toInt();
          if (remaining > 0) {
            endTime = now.add(Duration(seconds: remaining));
            await prefs.setInt(
              _endTimeKey,
              endTime.millisecondsSinceEpoch,
            );
          }
        }
      }
    }

    if (remaining <= 0) {
      remaining = 0;
      completed = true;
      await prefs.setBool(_completedKey, true);
      await prefs.setBool(_pausedKey, false);
      await prefs.setInt(_remainingAtUpdateKey, 0);
      await prefs.remove(_endTimeKey);
      endTime = null;
    } else {
      await prefs.setInt(_remainingAtUpdateKey, remaining);
      await prefs.setInt(_lastUpdateKey, now.millisecondsSinceEpoch);
    }

    return FocusSessionData(
      startTime: startTime,
      durationMinutes: durationMinutes,
      remainingSeconds: remaining,
      wasCompleted: completed,
      isPaused: paused,
      endTime: endTime,
    );
  }

  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_activeKey);
    await prefs.remove(_startTimeKey);
    await prefs.remove(_durationKey);
    await prefs.remove(_lastUpdateKey);
    await prefs.remove(_remainingAtUpdateKey);
    await prefs.remove(_endTimeKey);
    await prefs.remove(_pausedKey);
    await prefs.remove(_completedKey);
    await prefs.remove(_versionKey);
    await prefs.remove(_legacyJsonKey);
  }

  Future<void> _migrateLegacyJsonIfNeeded(
    SharedPreferences prefs,
  ) async {
    if (prefs.getBool(_activeKey) == true) return;

    final raw = prefs.getString(_legacyJsonKey);
    if (raw == null || raw.trim().isEmpty) return;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return;
      final data = Map<String, dynamic>.from(decoded);

      int readInt(String key, int fallback) {
        final value = data[key];
        if (value is int) return value;
        if (value is num) return value.toInt();
        return int.tryParse(value?.toString() ?? '') ?? fallback;
      }

      final duration = readInt('durationMinutes', 1).clamp(1, 24 * 60).toInt();
      final remaining = readInt(
        'remainingSeconds',
        duration * 60,
      ).clamp(0, duration * 60).toInt();
      final startTime = DateTime.tryParse(
            data['startTime']?.toString() ?? '',
          ) ??
          DateTime.now();

      await prefs.setBool(_activeKey, true);
      await prefs.setInt(_durationKey, duration);
      await prefs.setInt(
        _startTimeKey,
        startTime.millisecondsSinceEpoch,
      );
      await prefs.setInt(_remainingAtUpdateKey, remaining);
      await prefs.setInt(
        _lastUpdateKey,
        DateTime.now().millisecondsSinceEpoch,
      );
      await prefs.setBool(_pausedKey, false);
      await prefs.setBool(_completedKey, remaining <= 0);
      if (remaining > 0) {
        await prefs.setInt(
          _endTimeKey,
          DateTime.now()
              .add(Duration(seconds: remaining))
              .millisecondsSinceEpoch,
        );
      }
    } catch (error) {
      debugPrint('Could not migrate legacy focus session: $error');
    } finally {
      await prefs.remove(_legacyJsonKey);
    }
  }
}
