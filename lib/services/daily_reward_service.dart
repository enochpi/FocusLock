import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;

class DailyRewardService {
  static final DailyRewardService _instance = DailyRewardService._internal();
  factory DailyRewardService() => _instance;
  DailyRewardService._internal();

  int _currentStreak = 0;
  int _longestStreak = 0;
  DateTime? _lastClaimDate;
  bool _hasClaimedToday = false;

  // Getters
  int get currentStreak => _currentStreak;
  int get longestStreak => _longestStreak;
  bool get hasClaimedToday => _hasClaimedToday;
  DateTime? get lastClaimDate => _lastClaimDate;

  /// Initialize - check if user should get a reward
  Future<void> init() async {
    await _load();
    await _checkStreak();
  }

  /// Check if streak is still valid or broken
  Future<void> _checkStreak() async {
    if (_lastClaimDate == null) return;

    final now = DateTime.now();
    final lastClaim = _lastClaimDate!;

    // Same day - already claimed
    if (_isSameDay(now, lastClaim)) {
      _hasClaimedToday = true;
      return;
    }

    // Yesterday - streak continues, can claim
    if (_isYesterday(now, lastClaim)) {
      _hasClaimedToday = false;
      return;
    }

    // More than 1 day ago - streak broken!
    _currentStreak = 0;
    _hasClaimedToday = false;
    await _save();
  }

  /// Check if user can claim today's reward
  bool canClaimReward() {
    return !_hasClaimedToday;
  }

  /// Claim today's reward - returns (coins, crops)
  Future<Map<String, int>> claimReward() async {
    if (_hasClaimedToday) {
      return {'coins': 0, 'crops': 0};
    }

    // Increment streak
    _currentStreak++;
    if (_currentStreak > _longestStreak) {
      _longestStreak = _currentStreak;
    }

    // Mark as claimed
    _lastClaimDate = DateTime.now();
    _hasClaimedToday = true;

    // Calculate rewards based on current streak
    final rewards = _calculateReward(_currentStreak);

    await _save();
    return rewards;
  }

  /// ═══════════════════════════════════════════════════════════
  /// REWARD CALCULATION - LOGARITHMIC GROWTH (Slow down over time)
  /// ═══════════════════════════════════════════════════════════
  ///
  /// Formula: base * (1 + log(day))^power
  /// This creates BIG jumps early, then MUCH slower growth forever
  ///
  /// Examples:
  /// Day 1:    53 coins,    935 crops
  /// Day 2:    69 coins,  1,279 crops
  /// Day 3:    79 coins,  1,486 crops
  /// Day 7:   103 coins,  1,985 crops
  /// Day 14:  122 coins,  2,410 crops
  /// Day 30:  148 coins,  2,915 crops
  /// Day 100: 187 coins,  3,695 crops
  /// Day 365: 230 coins,  4,540 crops
  /// Day 1000: 281 coins, 5,550 crops
  ///
  Map<String, int> _calculateReward(int day) {
    // Very slow logarithmic growth for coins
    // Starts at 53, grows quickly at first, then much slower
    final coinBase = 30.0;
    final coinGrowth = math.pow(1 + math.log(day + 1), 1.2);
    final coins = (coinBase * coinGrowth).round();

    // Slow logarithmic growth for crops (peas/carrots/corn/strawberries/wheat)
    // Starts at 935, grows quickly at first, then much slower
    final cropBase = 500.0;
    final cropGrowth = math.pow(1 + math.log(day + 1), 1.4);
    final crops = (cropBase * cropGrowth).round();

    return {
      'coins': coins,
      'crops': crops,  // Changed from 'peas' to 'crops'
    };
  }

  /// ═══════════════════════════════════════════════════════════
  /// STREAK MULTIPLIER - INFINITE GROWTH (Never caps!)
  /// ═══════════════════════════════════════════════════════════
  ///
  /// Formula: 1.0 + (sqrt(streak) * 0.03) + (log(streak) * 0.02)
  /// This creates BIG jumps early, then much slower growth forever
  ///
  /// Examples:
  /// Day 1:   1.03x  (+3%)
  /// Day 3:   1.07x  (+7%)
  /// Day 7:   1.12x  (+12%)
  /// Day 14:  1.18x  (+18%)
  /// Day 30:  1.23x  (+23%)
  /// Day 60:  1.29x  (+29%)
  /// Day 100: 1.39x  (+39%)
  /// Day 365: 1.69x  (+69%)
  /// Day 1000: 2.01x (+101%)
  ///
  double getStreakMultiplier() {
    if (_currentStreak == 0) return 1.0;

    // Square root component - big jumps early (reduced from 0.05 to 0.03)
    final sqrtBonus = math.sqrt(_currentStreak) * 0.03;

    // Logarithmic component - keeps growing forever but slower (reduced from 0.03 to 0.02)
    final logBonus = math.log(_currentStreak + 1) * 0.02;

    return 1.0 + sqrtBonus + logBonus;
  }

  /// Get next day's reward (for preview)
  Map<String, int> getNextReward() {
    return _calculateReward(_currentStreak + 1);
  }

  /// Get formatted multiplier string
  String getMultiplierString() {
    final multiplier = getStreakMultiplier();
    if (multiplier <= 1.0) return "No bonus";

    final percent = ((multiplier - 1.0) * 100).round();
    return "+$percent% (${multiplier.toStringAsFixed(2)}x)";
  }

  /// Get days until next milestone
  Map<String, dynamic> getNextMilestone() {
    final milestones = [3, 7, 14, 30, 60, 100, 365, 1000];

    for (var milestone in milestones) {
      if (_currentStreak < milestone) {
        final daysLeft = milestone - _currentStreak;
        final milestoneMultiplier = _calculateMilestoneMultiplier(milestone);
        return {
          'days': milestone,
          'daysLeft': daysLeft,
          'multiplier': milestoneMultiplier,
        };
      }
    }

    // If past all milestones, show next 100-day increment
    final nextMilestone = ((_currentStreak ~/ 100) + 1) * 100;
    final daysLeft = nextMilestone - _currentStreak;
    final milestoneMultiplier = _calculateMilestoneMultiplier(nextMilestone);

    return {
      'days': nextMilestone,
      'daysLeft': daysLeft,
      'multiplier': milestoneMultiplier,
    };
  }

  double _calculateMilestoneMultiplier(int day) {
    final sqrtBonus = math.sqrt(day) * 0.03;
    final logBonus = math.log(day + 1) * 0.02;
    return 1.0 + sqrtBonus + logBonus;
  }

  /// Helper: Check if two dates are the same day
  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Helper: Check if b is yesterday relative to a
  bool _isYesterday(DateTime a, DateTime b) {
    final yesterday = a.subtract(const Duration(days: 1));
    return _isSameDay(yesterday, b);
  }

  /// Save to storage
  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('daily_reward_streak', _currentStreak);
    await prefs.setInt('daily_reward_longest', _longestStreak);
    await prefs.setBool('daily_reward_claimed', _hasClaimedToday);

    if (_lastClaimDate != null) {
      await prefs.setString('daily_reward_last_claim', _lastClaimDate!.toIso8601String());
    }
  }

  /// Load from storage
  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _currentStreak = prefs.getInt('daily_reward_streak') ?? 0;
    _longestStreak = prefs.getInt('daily_reward_longest') ?? 0;
    _hasClaimedToday = prefs.getBool('daily_reward_claimed') ?? false;

    final lastClaimStr = prefs.getString('daily_reward_last_claim');
    if (lastClaimStr != null) {
      _lastClaimDate = DateTime.parse(lastClaimStr);
    }
  }

  /// Reset (for testing)
  Future<void> reset() async {
    _currentStreak = 0;
    _longestStreak = 0;
    _lastClaimDate = null;
    _hasClaimedToday = false;
    await _save();
  }

  /// Debug: Force claim availability (for testing)
  Future<void> debugForceClaimable() async {
    _hasClaimedToday = false;
    await _save();
  }
}