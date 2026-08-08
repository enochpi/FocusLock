import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FocusSessionStat {
  final DateTime timestamp;
  final int plannedMinutes;
  final int focusedMinutes;
  final int peasEarned;
  final String mode;
  final bool completed;

  const FocusSessionStat({
    required this.timestamp,
    required this.plannedMinutes,
    required this.focusedMinutes,
    required this.peasEarned,
    required this.mode,
    required this.completed,
  });

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'plannedMinutes': plannedMinutes,
      'focusedMinutes': focusedMinutes,
      'peasEarned': peasEarned,
      'mode': mode,
      'completed': completed,
    };
  }

  factory FocusSessionStat.fromJson(Map<String, dynamic> json) {
    return FocusSessionStat(
      timestamp: DateTime.tryParse(json['timestamp']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      plannedMinutes: _readInt(json['plannedMinutes']),
      focusedMinutes: _readInt(json['focusedMinutes']),
      peasEarned: _readInt(json['peasEarned']),
      mode: json['mode']?.toString().trim().isNotEmpty == true
          ? json['mode'].toString()
          : 'Custom Focus',
      completed: json['completed'] == true,
    );
  }

  static int _readInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class BlockedAttemptStat {
  final DateTime timestamp;
  final String appName;
  final String packageName;

  const BlockedAttemptStat({
    required this.timestamp,
    required this.appName,
    required this.packageName,
  });

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'appName': appName,
      'packageName': packageName,
    };
  }

  factory BlockedAttemptStat.fromJson(Map<String, dynamic> json) {
    return BlockedAttemptStat(
      timestamp: DateTime.tryParse(json['timestamp']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      appName: json['appName']?.toString().trim().isNotEmpty == true
          ? json['appName'].toString()
          : 'Blocked app',
      packageName: json['packageName']?.toString() ?? '',
    );
  }
}

class DailyFocusStat {
  final DateTime date;
  final int focusMinutes;
  final int completedSessions;
  final int blockedAttempts;

  const DailyFocusStat({
    required this.date,
    required this.focusMinutes,
    required this.completedSessions,
    required this.blockedAttempts,
  });
}

class FocusStatsSummary {
  final int todayMinutes;
  final int weekMinutes;
  final int totalMinutes;
  final int completedSessions;
  final int stoppedSessions;
  final int totalSessions;
  final int blockedToday;
  final int totalBlocked;
  final int totalPeasEarned;
  final int averageSessionMinutes;
  final double completionRate;
  final String mostUsedMode;
  final String bestDayLabel;
  final String bestTimeOfDay;
  final String mostBlockedApp;
  final List<DailyFocusStat> last7Days;
  final List<FocusSessionStat> recentSessions;

  const FocusStatsSummary({
    required this.todayMinutes,
    required this.weekMinutes,
    required this.totalMinutes,
    required this.completedSessions,
    required this.stoppedSessions,
    required this.totalSessions,
    required this.blockedToday,
    required this.totalBlocked,
    required this.totalPeasEarned,
    required this.averageSessionMinutes,
    required this.completionRate,
    required this.mostUsedMode,
    required this.bestDayLabel,
    required this.bestTimeOfDay,
    required this.mostBlockedApp,
    required this.last7Days,
    required this.recentSessions,
  });

  bool get hasActivity => totalSessions > 0 || totalBlocked > 0;
}

class FocusStatsService {
  static final FocusStatsService _instance = FocusStatsService._internal();
  factory FocusStatsService() => _instance;
  FocusStatsService._internal();

  static const String sessionsKey = 'focus_stats_sessions_v1';
  static const String blockedAttemptsKey = 'focus_stats_blocked_attempts_v1';

  static const int _maximumSessionRecords = 1500;
  static const int _maximumBlockedRecords = 3000;

  Future<void> _writeQueue = Future<void>.value();

  Future<void> _enqueueWrite(Future<void> Function() operation) {
    final next = _writeQueue.then(
      (_) => operation(),
      onError: (_) => operation(),
    );
    _writeQueue = next;
    return next;
  }

  Future<void> _waitForPendingWrites() async {
    try {
      await _writeQueue;
    } catch (_) {
      // Individual write methods already log their own errors.
    }
  }

  static String modeForMinutes(int minutes) {
    switch (minutes) {
      case 1:
        return 'Practice';
      case 15:
        return 'Homework Panic';
      case 25:
        return 'Study';
      case 30:
        return 'No Phone';
      case 50:
        return 'Deep Work';
      default:
        return 'Custom Focus';
    }
  }

  Future<void> recordSession({
    required int plannedMinutes,
    required int focusedMinutes,
    required String mode,
    required int peasEarned,
    required bool completed,
    DateTime? timestamp,
  }) async {
    try {
      await _enqueueWrite(() async {
        final prefs = await SharedPreferences.getInstance();
        final sessions = _decodeSessions(prefs.getString(sessionsKey));

      sessions.add(
        FocusSessionStat(
          timestamp: timestamp ?? DateTime.now(),
          plannedMinutes: plannedMinutes.clamp(0, 24 * 60).toInt(),
          focusedMinutes: focusedMinutes.clamp(0, 24 * 60).toInt(),
          peasEarned: peasEarned < 0 ? 0 : peasEarned,
          mode: mode.trim().isEmpty ? modeForMinutes(plannedMinutes) : mode,
          completed: completed,
        ),
      );

      sessions.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      if (sessions.length > _maximumSessionRecords) {
        sessions.removeRange(
          0,
          sessions.length - _maximumSessionRecords,
        );
      }

        await prefs.setString(
          sessionsKey,
          jsonEncode(sessions.map((session) => session.toJson()).toList()),
        );
      });
    } catch (e) {
      debugPrint('FocusStatsService recordSession error: $e');
    }
  }

  Future<void> recordBlockedAttempt({
    required String appName,
    required String packageName,
    DateTime? timestamp,
  }) async {
    try {
      await _enqueueWrite(() async {
        final prefs = await SharedPreferences.getInstance();
        final attempts =
            _decodeBlockedAttempts(prefs.getString(blockedAttemptsKey));

      attempts.add(
        BlockedAttemptStat(
          timestamp: timestamp ?? DateTime.now(),
          appName: appName.trim().isEmpty ? 'Blocked app' : appName.trim(),
          packageName: packageName.trim(),
        ),
      );

      attempts.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      if (attempts.length > _maximumBlockedRecords) {
        attempts.removeRange(
          0,
          attempts.length - _maximumBlockedRecords,
        );
      }

        await prefs.setString(
          blockedAttemptsKey,
          jsonEncode(attempts.map((attempt) => attempt.toJson()).toList()),
        );
      });
    } catch (e) {
      debugPrint('FocusStatsService recordBlockedAttempt error: $e');
    }
  }

  Future<List<FocusSessionStat>> getSessions() async {
    await _waitForPendingWrites();
    final prefs = await SharedPreferences.getInstance();
    final sessions = _decodeSessions(prefs.getString(sessionsKey));
    sessions.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return sessions;
  }

  Future<List<BlockedAttemptStat>> getBlockedAttempts() async {
    await _waitForPendingWrites();
    final prefs = await SharedPreferences.getInstance();
    final attempts =
        _decodeBlockedAttempts(prefs.getString(blockedAttemptsKey));
    attempts.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return attempts;
  }

  Future<FocusStatsSummary> getSummary() async {
    await _waitForPendingWrites();
    final prefs = await SharedPreferences.getInstance();
    final sessions = _decodeSessions(prefs.getString(sessionsKey));
    final attempts =
        _decodeBlockedAttempts(prefs.getString(blockedAttemptsKey));

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(Duration(days: today.weekday - 1));
    final last7Start = today.subtract(const Duration(days: 6));

    int todayMinutes = 0;
    int weekMinutes = 0;
    int totalMinutes = 0;
    int completedSessions = 0;
    int stoppedSessions = 0;
    int totalPeasEarned = 0;

    final Map<String, int> minutesByDay = {};
    final Map<String, int> completedByDay = {};
    final Map<String, int> modeCounts = {};
    final Map<String, int> minutesByTimeOfDay = {
      'Morning': 0,
      'Afternoon': 0,
      'Evening': 0,
      'Late night': 0,
    };

    for (final session in sessions) {
      final localTime = session.timestamp.toLocal();
      final sessionDate =
          DateTime(localTime.year, localTime.month, localTime.day);
      final dateKey = _dateKey(sessionDate);
      final focusedMinutes = session.focusedMinutes < 0
          ? 0
          : session.focusedMinutes;

      totalMinutes += focusedMinutes;
      totalPeasEarned += session.peasEarned;

      if (_isSameDay(sessionDate, today)) {
        todayMinutes += focusedMinutes;
      }

      if (!sessionDate.isBefore(weekStart)) {
        weekMinutes += focusedMinutes;
      }

      minutesByDay[dateKey] =
          (minutesByDay[dateKey] ?? 0) + focusedMinutes;

      if (session.completed) {
        completedSessions++;
        completedByDay[dateKey] =
            (completedByDay[dateKey] ?? 0) + 1;
      } else {
        stoppedSessions++;
      }

      if (focusedMinutes > 0) {
        modeCounts[session.mode] = (modeCounts[session.mode] ?? 0) + 1;
        final period = _timeOfDayLabel(localTime.hour);
        minutesByTimeOfDay[period] =
            (minutesByTimeOfDay[period] ?? 0) + focusedMinutes;
      }
    }

    final Map<String, int> blockedByDay = {};
    final Map<String, int> blockedAppCounts = {};
    int blockedToday = 0;

    for (final attempt in attempts) {
      final localTime = attempt.timestamp.toLocal();
      final attemptDate =
          DateTime(localTime.year, localTime.month, localTime.day);
      final dateKey = _dateKey(attemptDate);

      blockedByDay[dateKey] = (blockedByDay[dateKey] ?? 0) + 1;

      if (_isSameDay(attemptDate, today)) {
        blockedToday++;
      }

      final appKey = attempt.appName.trim().isEmpty
          ? 'Blocked app'
          : attempt.appName.trim();
      blockedAppCounts[appKey] =
          (blockedAppCounts[appKey] ?? 0) + 1;
    }

    final int legacyBlockCount = prefs.getInt('block_count') ?? 0;
    final int totalBlocked = attempts.length > legacyBlockCount
        ? attempts.length
        : legacyBlockCount;

    final last7Days = <DailyFocusStat>[];
    for (int offset = 0; offset < 7; offset++) {
      final date = last7Start.add(Duration(days: offset));
      final key = _dateKey(date);

      last7Days.add(
        DailyFocusStat(
          date: date,
          focusMinutes: minutesByDay[key] ?? 0,
          completedSessions: completedByDay[key] ?? 0,
          blockedAttempts: blockedByDay[key] ?? 0,
        ),
      );
    }

    final recentSessions = List<FocusSessionStat>.from(sessions)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    final int totalSessions = sessions.length;
    final double completionRate = totalSessions == 0
        ? 0.0
        : completedSessions / totalSessions;

    final int sessionsWithTime =
        sessions.where((session) => session.focusedMinutes > 0).length;
    final int averageSessionMinutes = sessionsWithTime == 0
        ? 0
        : (totalMinutes / sessionsWithTime).round();

    return FocusStatsSummary(
      todayMinutes: todayMinutes,
      weekMinutes: weekMinutes,
      totalMinutes: totalMinutes,
      completedSessions: completedSessions,
      stoppedSessions: stoppedSessions,
      totalSessions: totalSessions,
      blockedToday: blockedToday,
      totalBlocked: totalBlocked,
      totalPeasEarned: totalPeasEarned,
      averageSessionMinutes: averageSessionMinutes,
      completionRate: completionRate,
      mostUsedMode: _largestKey(modeCounts, fallback: 'No mode yet'),
      bestDayLabel: _bestDayLabel(minutesByDay),
      bestTimeOfDay:
          _largestKey(minutesByTimeOfDay, fallback: 'No pattern yet'),
      mostBlockedApp:
          _largestKey(blockedAppCounts, fallback: 'No app yet'),
      last7Days: last7Days,
      recentSessions: recentSessions.take(8).toList(),
    );
  }

  Future<void> clearStats() async {
    await _enqueueWrite(() async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(sessionsKey);
      await prefs.remove(blockedAttemptsKey);
      await prefs.remove('block_count');
    });
  }

  List<FocusSessionStat> _decodeSessions(String? raw) {
    if (raw == null || raw.trim().isEmpty) return [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];

      return decoded
          .whereType<Map>()
          .map(
            (entry) => FocusSessionStat.fromJson(
              Map<String, dynamic>.from(entry),
            ),
          )
          .where(
            (session) =>
                session.timestamp.millisecondsSinceEpoch > 0,
          )
          .toList();
    } catch (e) {
      debugPrint('FocusStatsService decode sessions error: $e');
      return [];
    }
  }

  List<BlockedAttemptStat> _decodeBlockedAttempts(String? raw) {
    if (raw == null || raw.trim().isEmpty) return [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];

      return decoded
          .whereType<Map>()
          .map(
            (entry) => BlockedAttemptStat.fromJson(
              Map<String, dynamic>.from(entry),
            ),
          )
          .where(
            (attempt) =>
                attempt.timestamp.millisecondsSinceEpoch > 0,
          )
          .toList();
    } catch (e) {
      debugPrint('FocusStatsService decode blocked attempts error: $e');
      return [];
    }
  }

  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year &&
        a.month == b.month &&
        a.day == b.day;
  }

  static String _dateKey(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  static String _timeOfDayLabel(int hour) {
    if (hour >= 5 && hour < 12) return 'Morning';
    if (hour >= 12 && hour < 17) return 'Afternoon';
    if (hour >= 17 && hour < 22) return 'Evening';
    return 'Late night';
  }

  static String _largestKey(
    Map<String, int> values, {
    required String fallback,
  }) {
    if (values.isEmpty) return fallback;

    String bestKey = fallback;
    int bestValue = -1;

    values.forEach((key, value) {
      if (value > bestValue) {
        bestKey = key;
        bestValue = value;
      }
    });

    if (bestValue <= 0) return fallback;
    return bestKey;
  }

  static String _bestDayLabel(Map<String, int> minutesByDay) {
    if (minutesByDay.isEmpty) return 'No focus day yet';

    String? bestKey;
    int bestMinutes = -1;

    minutesByDay.forEach((key, value) {
      if (value > bestMinutes) {
        bestKey = key;
        bestMinutes = value;
      }
    });

    if (bestKey == null || bestMinutes <= 0) {
      return 'No focus day yet';
    }

    final date = DateTime.tryParse(bestKey!);
    if (date == null) return bestKey!;

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${months[date.month - 1]} ${date.day} · $bestMinutes min';
  }
}
