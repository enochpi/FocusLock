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

  /// Initialize - Load saved streak data
  Future<void> init() async {
    await loadStreak();
    await checkAndUpdateStreak();
  }

  /// Check if today's focus is done
  bool get isTodayComplete {
    if (_lastFocusDate == null) return false;
    DateTime now = DateTime.now();
    return _lastFocusDate!.year == now.year &&
        _lastFocusDate!.month == now.month &&
        _lastFocusDate!.day == now.day;
  }

  /// Record a focus session (call this after completing a session)
  Future<void> recordFocusSession() async {
    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);

    // If already focused today, don't update streak
    if (isTodayComplete) {
      return;
    }

    // Check if last focus was yesterday
    if (_lastFocusDate != null) {
      DateTime yesterday = today.subtract(const Duration(days: 1));
      DateTime lastDate = DateTime(
        _lastFocusDate!.year,
        _lastFocusDate!.month,
        _lastFocusDate!.day,
      );

      if (lastDate == yesterday) {
        // Consecutive day - increase streak
        _currentStreak++;
      } else if (lastDate != today) {
        // Broke streak - reset
        _currentStreak = 1;
      }
    } else {
      // First ever focus session
      _currentStreak = 1;
    }

    // Update last focus date
    _lastFocusDate = now;

    // Update longest streak if needed
    if (_currentStreak > _longestStreak) {
      _longestStreak = _currentStreak;
    }

    await saveStreak();
  }

  /// Check and update streak (call this on app start)
  Future<void> checkAndUpdateStreak() async {
    if (_lastFocusDate == null) return;

    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    DateTime lastDate = DateTime(
      _lastFocusDate!.year,
      _lastFocusDate!.month,
      _lastFocusDate!.day,
    );

    // If last focus was more than 1 day ago, reset streak
    Duration difference = today.difference(lastDate);
    if (difference.inDays > 1) {
      _currentStreak = 0;
      await saveStreak();
    }
  }

  /// Get days until streak breaks
  int get daysUntilBreak {
    if (_lastFocusDate == null) return 0;
    if (isTodayComplete) return 1; // Safe for today

    DateTime now = DateTime.now();
    DateTime today = DateTime(now.year, now.month, now.day);
    DateTime lastDate = DateTime(
      _lastFocusDate!.year,
      _lastFocusDate!.month,
      _lastFocusDate!.day,
    );

    Duration difference = today.difference(lastDate);
    return 1 - difference.inDays; // Returns 0 if today, negative if broken
  }

  /// Save streak data
  Future<void> saveStreak() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('current_streak', _currentStreak);
    await prefs.setInt('longest_streak', _longestStreak);
    if (_lastFocusDate != null) {
      await prefs.setString('last_focus_date', _lastFocusDate!.toIso8601String());
    }
  }

  /// Load streak data
  Future<void> loadStreak() async {
    final prefs = await SharedPreferences.getInstance();
    _currentStreak = prefs.getInt('current_streak') ?? 0;
    _longestStreak = prefs.getInt('longest_streak') ?? 0;
    String? dateString = prefs.getString('last_focus_date');
    if (dateString != null) {
      _lastFocusDate = DateTime.parse(dateString);
    }
  }

  /// Reset streak (for testing or user request)
  Future<void> resetStreak() async {
    _currentStreak = 0;
    _longestStreak = 0;
    _lastFocusDate = null;
    await saveStreak();
  }

  /// Get streak emoji
  String get streakEmoji {
    if (_currentStreak == 0) return "💤";
    if (_currentStreak < 3) return "🔥";
    if (_currentStreak < 7) return "🔥🔥";
    if (_currentStreak < 30) return "🔥🔥🔥";
    return "🔥🔥🔥🔥"; // 30+ days!
  }

  /// Get streak message
  String get streakMessage {
    if (_currentStreak == 0) return "Start your streak today!";
    if (_currentStreak == 1) return "Great start! Keep it going!";
    if (_currentStreak < 7) return "$_currentStreak day streak! You're on fire!";
    if (_currentStreak < 30) return "$_currentStreak days! Incredible dedication!";
    return "$_currentStreak days! You're unstoppable!";
  }
}