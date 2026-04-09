import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart'; // ✅ add this line

enum AchievementCategory {
  focus,
  furniture,
  wealth,
  property,
  power,
  secret,
}

enum RewardType {
  coins,
  peas,
  furniture,
  cosmetic,
  multiplier,
}

class AchievementReward {
  final RewardType type;
  final dynamic value;
  final String displayText;

  AchievementReward({
    required this.type,
    required this.value,
    required this.displayText,
  });
}

class Achievement {
  final String id;
  final String name;
  final String description;
  final String emoji;
  final AchievementCategory category;
  final int targetValue;
  final List<AchievementReward> rewards;
  final bool isSecret;

  int currentProgress;
  bool isUnlocked;
  DateTime? unlockedAt;

  Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.emoji,
    required this.category,
    required this.targetValue,
    required this.rewards,
    this.isSecret = false,
    this.currentProgress = 0,
    this.isUnlocked = false,
    this.unlockedAt,
  });

  double get progressPercent =>
      (currentProgress / targetValue * 100).clamp(0, 100);
  bool get isComplete => currentProgress >= targetValue;

  Map<String, dynamic> toJson() => {
    'id': id,
    'currentProgress': currentProgress,
    'isUnlocked': isUnlocked,
    'unlockedAt': unlockedAt?.toIso8601String(),
  };

  static Achievement fromJson(Map<String, dynamic> json, Achievement template) {
    return Achievement(
      id: template.id,
      name: template.name,
      description: template.description,
      emoji: template.emoji,
      category: template.category,
      targetValue: template.targetValue,
      rewards: template.rewards,
      isSecret: template.isSecret,
      currentProgress: json['currentProgress'] ?? 0,
      isUnlocked: json['isUnlocked'] ?? false,
      unlockedAt: json['unlockedAt'] != null
          ? DateTime.parse(json['unlockedAt'])
          : null,
    );
  }
}

class AchievementService {
  static final AchievementService _instance = AchievementService._internal();
  static const String _sessionsInDayKey = 'achievement_sessions_today';
  static const String _sessionsInDayDateKey = 'achievement_sessions_today_date';
  factory AchievementService() => _instance;
  AchievementService._internal();

  final List<Achievement> _achievements = [];
  Function(Achievement)? onAchievementUnlocked;

  void _initializeAchievements() {
    _achievements.addAll([

      // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      // 🎯 FOCUS ACHIEVEMENTS
      // Early ones give PEAS (useful immediately)
      // Later ones give COINS (useful mid/late game)
      // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

      Achievement(
        id: 'first_focus',
        name: 'First Steps',
        description: 'Complete your first focus session',
        emoji: '🌱',
        category: AchievementCategory.focus,
        targetValue: 1,
        rewards: [
          AchievementReward(type: RewardType.peas, value: 50, displayText: '50 peas'),
          AchievementReward(type: RewardType.coins, value: 5, displayText: '5 coins'),
        ],
      ),
      Achievement(
        id: 'focus_5_sessions',
        name: 'Getting Going',
        description: 'Complete 5 focus sessions',
        emoji: '🔥',
        category: AchievementCategory.focus,
        targetValue: 5,
        rewards: [
          AchievementReward(type: RewardType.peas, value: 200, displayText: '200 peas'),
          AchievementReward(type: RewardType.coins, value: 10, displayText: '10 coins'),
        ],
      ),
      Achievement(
        id: 'focus_10_sessions',
        name: 'Getting Started',
        description: 'Complete 10 focus sessions',
        emoji: '⚡',
        category: AchievementCategory.focus,
        targetValue: 10,
        rewards: [
          AchievementReward(type: RewardType.peas, value: 500, displayText: '500 peas'),
          AchievementReward(type: RewardType.coins, value: 20, displayText: '20 coins'),
        ],
      ),
      Achievement(
        id: 'focus_50_sessions',
        name: 'Dedicated',
        description: 'Complete 50 focus sessions',
        emoji: '💪',
        category: AchievementCategory.focus,
        targetValue: 50,
        rewards: [
          AchievementReward(type: RewardType.peas, value: 3000, displayText: '3,000 peas'),
          AchievementReward(type: RewardType.coins, value: 100, displayText: '100 coins'),
        ],
      ),
      Achievement(
        id: 'focus_100_sessions',
        name: 'Century Club',
        description: 'Complete 100 focus sessions',
        emoji: '💯',
        category: AchievementCategory.focus,
        targetValue: 100,
        rewards: [
          AchievementReward(type: RewardType.peas, value: 8000, displayText: '8,000 peas'),
          AchievementReward(type: RewardType.coins, value: 300, displayText: '300 coins'),
        ],
      ),
      Achievement(
        id: 'focus_500_sessions',
        name: 'Focus Legend',
        description: 'Complete 500 focus sessions',
        emoji: '🏆',
        category: AchievementCategory.focus,
        targetValue: 500,
        rewards: [
          AchievementReward(type: RewardType.coins, value: 2000, displayText: '2,000 coins'),
        ],
      ),

      // ── Focus time achievements ──
      Achievement(
        id: 'focus_30_minutes',
        name: 'Half Hour Hero',
        description: 'Focus for 30 total minutes',
        emoji: '⏱️',
        category: AchievementCategory.focus,
        targetValue: 30,
        rewards: [
          AchievementReward(type: RewardType.peas, value: 100, displayText: '100 peas'),
        ],
      ),
      Achievement(
        id: 'focus_60_minutes',
        name: 'First Hour',
        description: 'Focus for 60 total minutes',
        emoji: '⏰',
        category: AchievementCategory.focus,
        targetValue: 60,
        rewards: [
          AchievementReward(type: RewardType.peas, value: 300, displayText: '300 peas'),
          AchievementReward(type: RewardType.coins, value: 5, displayText: '5 coins'),
        ],
      ),
      Achievement(
        id: 'focus_300_minutes',
        name: 'Five Hours',
        description: 'Focus for 5 total hours',
        emoji: '⏳',
        category: AchievementCategory.focus,
        targetValue: 300,
        rewards: [
          AchievementReward(type: RewardType.peas, value: 1500, displayText: '1,500 peas'),
          AchievementReward(type: RewardType.coins, value: 20, displayText: '20 coins'),
        ],
      ),
      Achievement(
        id: 'focus_600_minutes',
        name: 'Ten Hours',
        description: 'Focus for 10 total hours',
        emoji: '🌟',
        category: AchievementCategory.focus,
        targetValue: 600,
        rewards: [
          AchievementReward(type: RewardType.peas, value: 4000, displayText: '4,000 peas'),
          AchievementReward(type: RewardType.coins, value: 50, displayText: '50 coins'),
        ],
      ),
      Achievement(
        id: 'focus_3000_minutes',
        name: 'Fifty Hours',
        description: 'Focus for 50 total hours',
        emoji: '💎',
        category: AchievementCategory.focus,
        targetValue: 3000,
        rewards: [
          AchievementReward(type: RewardType.coins, value: 500, displayText: '500 coins'),
        ],
      ),
      Achievement(
        id: 'focus_6000_minutes',
        name: 'Hundred Hours',
        description: 'Focus for 100 total hours',
        emoji: '👑',
        category: AchievementCategory.focus,
        targetValue: 6000,
        rewards: [
          AchievementReward(type: RewardType.coins, value: 2000, displayText: '2,000 coins'),
        ],
      ),

      // ── Streak achievements ──
      Achievement(
        id: 'streak_3',
        name: 'Hot Streak',
        description: 'Focus 3 days in a row',
        emoji: '🔥',
        category: AchievementCategory.focus,
        targetValue: 3,
        rewards: [
          AchievementReward(type: RewardType.peas, value: 300, displayText: '300 peas'),
          AchievementReward(type: RewardType.coins, value: 5, displayText: '5 coins'),
        ],
      ),
      Achievement(
        id: 'streak_7',
        name: 'Week Warrior',
        description: 'Focus 7 days in a row',
        emoji: '📅',
        category: AchievementCategory.focus,
        targetValue: 7,
        rewards: [
          AchievementReward(type: RewardType.peas, value: 1000, displayText: '1,000 peas'),
          AchievementReward(type: RewardType.coins, value: 20, displayText: '20 coins'),
        ],
      ),
      Achievement(
        id: 'streak_30',
        name: 'Monthly Master',
        description: 'Focus 30 days in a row',
        emoji: '🌙',
        category: AchievementCategory.focus,
        targetValue: 30,
        rewards: [
          AchievementReward(type: RewardType.coins, value: 300, displayText: '300 coins'),
        ],
      ),

      // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      // 🛋️ FURNITURE ACHIEVEMENTS
      // Give peas early to help buy more furniture
      // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

      Achievement(
        id: 'first_furniture',
        name: 'Interior Designer',
        description: 'Buy your first piece of furniture',
        emoji: '🛋️',
        category: AchievementCategory.furniture,
        targetValue: 1,
        rewards: [
          AchievementReward(type: RewardType.peas, value: 100, displayText: '100 peas'),
          AchievementReward(type: RewardType.coins, value: 3, displayText: '3 coins'),
        ],
      ),
      Achievement(
        id: 'furniture_3',
        name: 'Decorator',
        description: 'Own 3 pieces of furniture',
        emoji: '🏠',
        category: AchievementCategory.furniture,
        targetValue: 3,
        rewards: [
          AchievementReward(type: RewardType.peas, value: 300, displayText: '300 peas'),
          AchievementReward(type: RewardType.coins, value: 8, displayText: '8 coins'),
        ],
      ),
      Achievement(
        id: 'furniture_5',
        name: 'Home Builder',
        description: 'Own 5 pieces of furniture',
        emoji: '🏡',
        category: AchievementCategory.furniture,
        targetValue: 5,
        rewards: [
          AchievementReward(type: RewardType.peas, value: 600, displayText: '600 peas'),
          AchievementReward(type: RewardType.coins, value: 15, displayText: '15 coins'),
        ],
      ),
      Achievement(
        id: 'furniture_all_cave',
        name: 'Cave Decorator',
        description: 'Own all cave furniture',
        emoji: '🏔️',
        category: AchievementCategory.furniture,
        targetValue: 6,
        rewards: [
          AchievementReward(type: RewardType.peas, value: 2000, displayText: '2,000 peas'),
          AchievementReward(type: RewardType.coins, value: 50, displayText: '50 coins'),
        ],
      ),
      Achievement(
        id: 'furniture_all',
        name: 'Complete Collection',
        description: 'Own all furniture items',
        emoji: '🎯',
        category: AchievementCategory.furniture,
        targetValue: 22,
        rewards: [
          AchievementReward(type: RewardType.coins, value: 1000, displayText: '1,000 coins'),
        ],
      ),

      // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      // 💰 WEALTH ACHIEVEMENTS
      // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

      Achievement(
        id: 'earn_500_peas',
        name: 'First Harvest',
        description: 'Earn 500 total peas',
        emoji: '🌾',
        category: AchievementCategory.wealth,
        targetValue: 500,
        rewards: [
          AchievementReward(type: RewardType.peas, value: 100, displayText: '100 peas'),
        ],
      ),
      Achievement(
        id: 'earn_5k_peas',
        name: 'Growing Farm',
        description: 'Earn 5,000 total peas',
        emoji: '🌿',
        category: AchievementCategory.wealth,
        targetValue: 5000,
        rewards: [
          AchievementReward(type: RewardType.peas, value: 500, displayText: '500 peas'),
          AchievementReward(type: RewardType.coins, value: 5, displayText: '5 coins'),
        ],
      ),
      Achievement(
        id: 'earn_50k_peas',
        name: 'Big Farmer',
        description: 'Earn 50,000 total peas',
        emoji: '🚜',
        category: AchievementCategory.wealth,
        targetValue: 50000,
        rewards: [
          AchievementReward(type: RewardType.coins, value: 50, displayText: '50 coins'),
        ],
      ),
      Achievement(
        id: 'earn_1m_peas',
        name: 'Millionaire Farmer',
        description: 'Earn 1 million total peas',
        emoji: '💚',
        category: AchievementCategory.wealth,
        targetValue: 1000000,
        rewards: [
          AchievementReward(type: RewardType.coins, value: 500, displayText: '500 coins'),
        ],
      ),
      Achievement(
        id: 'convert_first',
        name: 'Money Changer',
        description: 'Convert peas to coins for the first time',
        emoji: '🔄',
        category: AchievementCategory.wealth,
        targetValue: 1,
        rewards: [
          AchievementReward(type: RewardType.peas, value: 200, displayText: '200 peas'),
        ],
      ),
      Achievement(
        id: 'convert_1k',
        name: 'Currency Trader',
        description: 'Convert 1,000 peas to coins',
        emoji: '💱',
        category: AchievementCategory.wealth,
        targetValue: 1000,
        rewards: [
          AchievementReward(type: RewardType.peas, value: 500, displayText: '500 peas'),
          AchievementReward(type: RewardType.coins, value: 10, displayText: '10 coins'),
        ],
      ),
      Achievement(
        id: 'spend_50_coins',
        name: 'First Purchase',
        description: 'Spend 50 total coins',
        emoji: '💸',
        category: AchievementCategory.wealth,
        targetValue: 50,
        rewards: [
          AchievementReward(type: RewardType.peas, value: 300, displayText: '300 peas'),
        ],
      ),
      Achievement(
        id: 'spend_500_coins',
        name: 'Big Spender',
        description: 'Spend 500 total coins',
        emoji: '🏦',
        category: AchievementCategory.wealth,
        targetValue: 500,
        rewards: [
          AchievementReward(type: RewardType.coins, value: 50, displayText: '50 coins'),
        ],
      ),

      // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      // 🏠 PROPERTY ACHIEVEMENTS
      // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

      Achievement(
        id: 'unlock_shack',
        name: 'Moving Up',
        description: 'Unlock the Shack',
        emoji: '🏚️',
        category: AchievementCategory.property,
        targetValue: 1,
        rewards: [
          AchievementReward(type: RewardType.coins, value: 200, displayText: '200 coins'),
        ],
      ),
      Achievement(
        id: 'unlock_house',
        name: 'Homeowner',
        description: 'Unlock the House',
        emoji: '🏡',
        category: AchievementCategory.property,
        targetValue: 1,
        rewards: [
          AchievementReward(type: RewardType.coins, value: 1000, displayText: '1,000 coins'),
        ],
      ),

      // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      // ⚡ POWER ACHIEVEMENTS
      // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

      Achievement(
        id: 'first_upgrade',
        name: 'Power Up',
        description: 'Buy your first upgrade',
        emoji: '⬆️',
        category: AchievementCategory.power,
        targetValue: 1,
        rewards: [
          AchievementReward(type: RewardType.peas, value: 150, displayText: '150 peas'),
        ],
      ),
      Achievement(
        id: 'buy_5_upgrades',
        name: 'Upgrade Enthusiast',
        description: 'Purchase 5 upgrades',
        emoji: '📦',
        category: AchievementCategory.power,
        targetValue: 5,
        rewards: [
          AchievementReward(type: RewardType.peas, value: 500, displayText: '500 peas'),
          AchievementReward(type: RewardType.coins, value: 10, displayText: '10 coins'),
        ],
      ),
      Achievement(
        id: 'buy_10_upgrades',
        name: 'Upgrade Addict',
        description: 'Purchase 10 upgrades',
        emoji: '🔧',
        category: AchievementCategory.power,
        targetValue: 10,
        rewards: [
          AchievementReward(type: RewardType.peas, value: 1500, displayText: '1,500 peas'),
          AchievementReward(type: RewardType.coins, value: 30, displayText: '30 coins'),
        ],
      ),
      Achievement(
        id: 'buy_all_cave_upgrades',
        name: 'Cave Master',
        description: 'Buy all Cave upgrades',
        emoji: '🏔️',
        category: AchievementCategory.power,
        targetValue: 10,
        rewards: [
          AchievementReward(type: RewardType.peas, value: 3000, displayText: '3,000 peas'),
          AchievementReward(type: RewardType.coins, value: 100, displayText: '100 coins'),
        ],
      ),
      Achievement(
        id: 'multiplier_2x',
        name: 'Double Up',
        description: 'Reach 2x multiplier',
        emoji: '✌️',
        category: AchievementCategory.power,
        targetValue: 2,
        rewards: [
          AchievementReward(type: RewardType.peas, value: 200, displayText: '200 peas'),
        ],
      ),
      Achievement(
        id: 'multiplier_5x',
        name: 'Power Boost',
        description: 'Reach 5x multiplier',
        emoji: '⚡',
        category: AchievementCategory.power,
        targetValue: 5,
        rewards: [
          AchievementReward(type: RewardType.peas, value: 800, displayText: '800 peas'),
          AchievementReward(type: RewardType.coins, value: 20, displayText: '20 coins'),
        ],
      ),
      Achievement(
        id: 'multiplier_10x',
        name: 'Power Surge',
        description: 'Reach 10x multiplier',
        emoji: '💥',
        category: AchievementCategory.power,
        targetValue: 10,
        rewards: [
          AchievementReward(type: RewardType.coins, value: 100, displayText: '100 coins'),
        ],
      ),
      Achievement(
        id: 'multiplier_50x',
        name: 'Unstoppable',
        description: 'Reach 50x multiplier',
        emoji: '🌪️',
        category: AchievementCategory.power,
        targetValue: 50,
        rewards: [
          AchievementReward(type: RewardType.coins, value: 500, displayText: '500 coins'),
        ],
      ),

      // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      // 🎭 SECRET ACHIEVEMENTS
      // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

      Achievement(
        id: 'night_owl',
        name: 'Night Owl',
        description: 'Complete a focus session after midnight',
        emoji: '🦉',
        category: AchievementCategory.secret,
        targetValue: 1,
        isSecret: true,
        rewards: [
          AchievementReward(type: RewardType.peas, value: 500, displayText: '500 peas'),
          AchievementReward(type: RewardType.coins, value: 10, displayText: '10 coins'),
        ],
      ),
      Achievement(
        id: 'marathon_session',
        name: 'Marathon Runner',
        description: 'Complete a 2+ hour focus session',
        emoji: '🏃',
        category: AchievementCategory.secret,
        targetValue: 1,
        isSecret: true,
        rewards: [
          AchievementReward(type: RewardType.peas, value: 800, displayText: '800 peas'),
          AchievementReward(type: RewardType.coins, value: 20, displayText: '20 coins'),
        ],
      ),
      Achievement(
        id: 'speed_demon',
        name: 'Speed Demon',
        description: 'Complete 5 sessions in one day',
        emoji: '⚡',
        category: AchievementCategory.secret,
        targetValue: 5,
        isSecret: true,
        rewards: [
          AchievementReward(type: RewardType.peas, value: 1000, displayText: '1,000 peas'),
          AchievementReward(type: RewardType.coins, value: 15, displayText: '15 coins'),
        ],
      ),
      Achievement(
        id: 'early_bird',
        name: 'Early Bird',
        description: 'Complete a focus session before 7am',
        emoji: '🌅',
        category: AchievementCategory.secret,
        targetValue: 1,
        isSecret: true,
        rewards: [
          AchievementReward(type: RewardType.peas, value: 500, displayText: '500 peas'),
          AchievementReward(type: RewardType.coins, value: 10, displayText: '10 coins'),
        ],
      ),
    ]);
  }

  Future<void> init() async {
    _achievements.clear();
    _initializeAchievements();
    await _loadProgress();
  }

  List<Achievement> get allAchievements => _achievements;
  List<Achievement> get unlockedAchievements =>
      _achievements.where((a) => a.isUnlocked).toList();
  List<Achievement> get lockedAchievements =>
      _achievements.where((a) => !a.isUnlocked).toList();
  List<Achievement> getByCategory(AchievementCategory category) =>
      _achievements.where((a) => a.category == category).toList();
  int get totalUnlocked => unlockedAchievements.length;
  int get totalAchievements => _achievements.length;
  double get completionPercent => (totalUnlocked / totalAchievements * 100);

  Future<void> updateProgress(String achievementId, int newProgress) async {
    try {
      final achievement = _achievements.firstWhere((a) => a.id == achievementId);
      if (achievement.isUnlocked) return;
      achievement.currentProgress = newProgress;
      if (achievement.isComplete) await _unlockAchievement(achievement);
      await _saveProgress();
    } catch (_) {}
  }

  Future<void> incrementProgress(String achievementId, [int amount = 1]) async {
    try {
      final achievement = _achievements.firstWhere((a) => a.id == achievementId);
      if (achievement.isUnlocked) return;
      achievement.currentProgress += amount;
      if (achievement.isComplete) await _unlockAchievement(achievement);
      await _saveProgress();
    } catch (_) {}
  }

  Future<void> _unlockAchievement(Achievement achievement) async {
    achievement.isUnlocked = true;
    achievement.unlockedAt = DateTime.now();
    onAchievementUnlocked?.call(achievement);
    await _saveProgress();
  }

  Future<void> _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    // ✅ Save as a map keyed by ID instead of a positional list
    // so reordering or adding achievements never corrupts saved progress
    final Map<String, dynamic> progressMap = {};
    for (final achievement in _achievements) {
      progressMap[achievement.id] = achievement.toJson();
    }
    await prefs.setString('achievement_progress', json.encode(progressMap));
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final progressJson = prefs.getString('achievement_progress');
    if (progressJson == null) return;

    final decoded = json.decode(progressJson);

    // ✅ Handle both old format (List) and new format (Map)
    // so existing players don't lose their progress on first update
    if (decoded is List) {
      // Old index-based format — migrate it gracefully
      // Match by position for the last time, then next save
      // will write the new ID-keyed format automatically
      debugPrint('📦 Migrating achievement progress to ID-keyed format');
      for (var i = 0; i < decoded.length && i < _achievements.length; i++) {
        final data = decoded[i] as Map<String, dynamic>;
        _achievements[i] = Achievement.fromJson(data, _achievements[i]);
      }
    } else if (decoded is Map<String, dynamic>) {
      // New ID-keyed format — match each saved entry to its achievement by ID
      for (final achievement in _achievements) {
        final data = decoded[achievement.id];
        if (data != null) {
          final updated = Achievement.fromJson(
            data as Map<String, dynamic>,
            achievement,
          );
          final index = _achievements.indexOf(achievement);
          _achievements[index] = updated;
        }
        // If no saved data for this achievement ID, it stays at default
        // which is correct for newly added achievements
      }
    }
  }

  // ── Event handlers ────────────────────────────────────────
  Future<void> onFocusSessionCompleted(int minutes) async {
    await incrementProgress('first_focus');
    await incrementProgress('focus_5_sessions');
    await incrementProgress('focus_10_sessions');
    await incrementProgress('focus_50_sessions');
    await incrementProgress('focus_100_sessions');
    await incrementProgress('focus_500_sessions');
    await incrementProgress('focus_30_minutes', minutes);
    await incrementProgress('focus_60_minutes', minutes);
    await incrementProgress('focus_300_minutes', minutes);
    await incrementProgress('focus_600_minutes', minutes);
    await incrementProgress('focus_3000_minutes', minutes);
    await incrementProgress('focus_6000_minutes', minutes);

    if (minutes >= 120) await incrementProgress('marathon_session');

    final hour = DateTime.now().hour;
    if (hour >= 0 && hour < 6)  await incrementProgress('night_owl');
    if (hour >= 4 && hour < 7)  await incrementProgress('early_bird');
  }

  Future<void> onStreakUpdated(int currentStreak) async {
    await updateProgress('streak_3', currentStreak);
    await updateProgress('streak_7', currentStreak);
    await updateProgress('streak_30', currentStreak);
  }

  Future<void> onFurniturePurchased(int totalOwned) async {
    // ✅ updateProgress sets the value directly — won't go backwards
    // and won't increment past 1 for first_furniture
    await updateProgress('first_furniture', totalOwned);
    await updateProgress('furniture_3', totalOwned);
    await updateProgress('furniture_5', totalOwned);
    await updateProgress('furniture_all_cave', totalOwned);
    await updateProgress('furniture_all', totalOwned);
  }

  Future<void> onPeasEarned(int amount) async {
    await incrementProgress('earn_500_peas', amount);
    await incrementProgress('earn_5k_peas', amount);
    await incrementProgress('earn_50k_peas', amount);
    await incrementProgress('earn_1m_peas', amount);
  }

  Future<void> onCoinsSpent(int amount) async {
    await incrementProgress('spend_50_coins', amount);
    await incrementProgress('spend_500_coins', amount);
  }

  Future<void> onPeasConverted(int amount) async {
    await incrementProgress('convert_first');
    await incrementProgress('convert_1k', amount);
  }

  Future<void> onHouseUnlocked(int stage) async {
    if (stage == 1) await incrementProgress('unlock_shack');
    if (stage == 2) await incrementProgress('unlock_house');
  }

  Future<void> onMultiplierReached(double multiplier) async {
    await updateProgress('multiplier_2x',  multiplier.floor());
    await updateProgress('multiplier_5x',  multiplier.floor());
    await updateProgress('multiplier_10x', multiplier.floor());
    await updateProgress('multiplier_50x', multiplier.floor());
  }

  Future<void> onUpgradePurchased(int totalPurchased, String stageType) async {
    await incrementProgress('first_upgrade');
    await updateProgress('buy_5_upgrades',  totalPurchased);
    await updateProgress('buy_10_upgrades', totalPurchased);
    if (stageType == 'cave') {
      await updateProgress('buy_all_cave_upgrades', totalPurchased);
    }
  }

  Future<void> onSessionsInDay() async {
    final prefs = await SharedPreferences.getInstance();

    // Check if we're still on the same day
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month}-${today.day}';
    final savedDate = prefs.getString(_sessionsInDayDateKey) ?? '';

    int count;
    if (savedDate != todayStr) {
      // New day — reset counter
      count = 1;
    } else {
      // Same day — increment
      count = (prefs.getInt(_sessionsInDayKey) ?? 0) + 1;
    }

    // Save updated count and date
    await prefs.setInt(_sessionsInDayKey, count);
    await prefs.setString(_sessionsInDayDateKey, todayStr);

    // Now check achievement
    await updateProgress('speed_demon', count);

    debugPrint('📊 Sessions today: $count');
  }
}