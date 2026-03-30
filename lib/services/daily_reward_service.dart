import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math' as math;

import 'currency_service.dart';

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

  Map<String, int> _calculateReward(int day) {
    final currency = CurrencyService();
    final percent = (0.20 + (day - 1) * 0.01).clamp(0.20, 1.0);
    final coins = (currency.coins * percent).round();
    final crops = (currency.peas * percent).round();
    return {'coins': coins, 'crops': crops};
  }
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