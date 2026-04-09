import 'package:shared_preferences/shared_preferences.dart';

class StreakService {
  static final StreakService _instance = StreakService._internal();
  factory StreakService() => _instance;
  StreakService._internal();

  int _currentStreak = 0;
  int _longestStreak = 0;
  DateTime? _lastFocusDate;

  // Getters
  int get currentStreak => _currentStreak;
  int get longestStreak => _longestStreak;
  DateTime? get lastFocusDate => _lastFocusDate;

  /// Initialize - just load saved data, never mutate on app open
  Future<void> init() async {
    await loadStreak();
    // ✅ No longer calls checkAndUpdateStreak() here
    // Streak state is only ever changed when a session completes
  }

  /// Check if today's focus is done
  bool get isTodayComplete {
    if (_lastFocusDate == null) return false;
    DateTime now = DateTime.now();
    return _lastFocusDate!.year == now.year &&
        _lastFocusDate!.month == now.month &&
        _lastFocusDate!.day == now.day;
  }

  /// Whether the streak is currently alive (focused yesterday or today)
  bool get isStreakAlive {
    if (_lastFocusDate == null) return false;
    if (_currentStreak == 0) return false;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastDate = DateTime(
      _lastFocusDate!.year,
      _lastFocusDate!.month,
      _lastFocusDate!.day,
    );

    final difference = today.difference(lastDate).inDays;
    // Streak is alive if focused today or yesterday
    return difference <= 1;
  }

  /// The streak the player should SEE — 0 if broken, actual value if alive
  int get displayStreak {
    if (!isStreakAlive) return 0;
    return _currentStreak;
  }

  /// Record a focus session (call this after completing a session)
  Future<void> recordFocusSession() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Already focused today — don't update streak again
    if (isTodayComplete) return;

    if (_lastFocusDate != null) {
      final lastDate = DateTime(
        _lastFocusDate!.year,
        _lastFocusDate!.month,
        _lastFocusDate!.day,
      );

      final difference = today.difference(lastDate).inDays;

      if (difference == 1) {
        // Focused yesterday — streak continues ✅
        _currentStreak++;
      } else if (difference == 0) {
        // Same day edge case — shouldn't reach here due to
        // isTodayComplete check above, but guard anyway
        // Don't change streak
      } else {
        // Gap of 2+ days — streak was broken, start fresh
        // ✅ Only reset HERE at session completion, never on app open
        _currentStreak = 1;
      }
    } else {
      // First ever focus session
      _currentStreak = 1;
    }

    _lastFocusDate = now;

    if (_currentStreak > _longestStreak) {
      _longestStreak = _currentStreak;
    }

    await saveStreak();
  }

  /// Get days until streak breaks
  /// Returns 1 if focused today (safe), 0 if need to focus today, negative if broken
  int get daysUntilBreak {
    if (_lastFocusDate == null) return 0;
    if (isTodayComplete) return 1;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastDate = DateTime(
      _lastFocusDate!.year,
      _lastFocusDate!.month,
      _lastFocusDate!.day,
    );

    final difference = today.difference(lastDate).inDays;
    return 1 - difference;
  }

  /// Save streak data
  Future<void> saveStreak() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('current_streak', _currentStreak);
    await prefs.setInt('longest_streak', _longestStreak);
    if (_lastFocusDate != null) {
      await prefs.setString(
          'last_focus_date', _lastFocusDate!.toIso8601String());
    }
  }

  /// Load streak data
  Future<void> loadStreak() async {
    final prefs = await SharedPreferences.getInstance();
    _currentStreak = prefs.getInt('current_streak') ?? 0;
    _longestStreak = prefs.getInt('longest_streak') ?? 0;
    final dateString = prefs.getString('last_focus_date');
    if (dateString != null) {
      _lastFocusDate = DateTime.parse(dateString);
    }
  }

  /// Reset streak
  Future<void> resetStreak() async {
    _currentStreak = 0;
    _longestStreak = 0;
    _lastFocusDate = null;
    await saveStreak();
  }

  /// Get streak emoji
  String get streakEmoji {
    final streak = displayStreak;
    if (streak == 0) return '💤';
    if (streak < 3) return '🔥';
    if (streak < 7) return '🔥🔥';
    if (streak < 30) return '🔥🔥🔥';
    return '🔥🔥🔥🔥';
  }

  /// Get streak message
  String get streakMessage {
    final streak = displayStreak;
    if (streak == 0) return 'Start your streak today!';
    if (streak == 1) return 'Great start! Keep it going!';
    if (streak < 7) return '$streak day streak! You\'re on fire!';
    if (streak < 30) return '$streak days! Incredible dedication!';
    return '$streak days! You\'re unstoppable!';
  }
}