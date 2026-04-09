import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
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

    // ✅ Guard against clock being set backwards —
    // if "now" is somehow before the last claim, something is wrong.
    // Don't allow a claim and don't reset the streak.
    if (now.isBefore(lastClaim)) {
      debugPrint('⚠️ Clock appears to have moved backwards — blocking claim');
      _hasClaimedToday = true;
      return;
    }

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
    if (_hasClaimedToday) return false;
    if (_lastClaimDate == null) return true;

    final now = DateTime.now();

    // ✅ Block if clock was moved backwards
    if (now.isBefore(_lastClaimDate!)) {
      debugPrint('⚠️ Clock manipulation detected — blocking daily reward');
      return false;
    }

    // ✅ Enforce minimum 20 hours between claims
    // This stops someone from claiming at 11:59 PM then
    // immediately again at 12:01 AM by blocking claims
    // that are less than 20 hours apart
    final hoursSinceLastClaim = now.difference(_lastClaimDate!).inHours;
    if (hoursSinceLastClaim < 20) {
      debugPrint('⏰ Too soon to claim again ($hoursSinceLastClaim hours since last claim)');
      return false;
    }

    return true;
  }

  /// Claim today's reward - returns (coins, crops)
  Future<Map<String, int>> claimReward() async {
    // ✅ Re-validate at claim time, not just at dialog open time
    if (!canClaimReward()) {
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

  // Base rewards guaranteed for the first 7 days
  // so new players always get something meaningful
  static const List<Map<String, int>> _baseRewards = [
    {'coins': 0,  'crops': 0},    // index 0 — unused, streak starts at 1
    {'coins': 5,  'crops': 100},  // day 1  — welcome bonus
    {'coins': 8,  'crops': 150},  // day 2
    {'coins': 10, 'crops': 200},  // day 3
    {'coins': 12, 'crops': 250},  // day 4
    {'coins': 15, 'crops': 300},  // day 5
    {'coins': 18, 'crops': 400},  // day 6
    {'coins': 20, 'crops': 500},  // day 7 — week milestone
  ];

  Map<String, int> _calculateReward(int day) {
    // Days 1-7: guaranteed base rewards so new players
    // always get something regardless of their balance
    if (day <= 7) {
      return {
        'coins': _baseRewards[day]['coins']!,
        'crops': _baseRewards[day]['crops']!,
      };
    }

    // Day 8+: percentage of current balance
    // with a guaranteed minimum floor so it never returns zero
    final currency = CurrencyService();
    final percent = (0.20 + (day - 8) * 0.005).clamp(0.20, 1.0);

    final coins = (currency.coins * percent).round();
    final crops = (currency.peas * percent).round();

    // Minimum floor grows every 7 days so it's always worth logging in
    final minCoins = 25 + (day ~/ 7) * 5;
    final minCrops = 500 + (day ~/ 7) * 100;

    return {
      'coins': coins < minCoins ? minCoins : coins,
      'crops': crops < minCrops ? minCrops : crops,
    };
  }

  /// Public wrapper so the dialog can preview today's reward before claiming
  Map<String, int> calculateTodayReward(int day) => _calculateReward(day);

  double getStreakMultiplier() {
    if (_currentStreak == 0) return 1.0;

    // Square root component - big jumps early
    final sqrtBonus = math.sqrt(_currentStreak) * 0.03;

    // Logarithmic component - keeps growing forever but slower
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