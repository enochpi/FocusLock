import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// ═══════════════════════════════════════════════════════════
//  ACHIEVEMENT CATEGORIES
// ═══════════════════════════════════════════════════════════

enum AchievementCategory {
  focus,      // Focus sessions and streaks
  furniture,  // Furniture collection and upgrades
  wealth,     // Currency milestones
  property,   // House unlocks
  power,      // Multiplier achievements
  secret,     // Hidden achievements
}

// ═══════════════════════════════════════════════════════════
//  ACHIEVEMENT REWARD TYPES
// ═══════════════════════════════════════════════════════════

enum RewardType {
  coins,
  peas,
  furniture,
  cosmetic,
  multiplier,
}

class AchievementReward {
  final RewardType type;
  final dynamic value; // Can be int (currency), String (item ID), or double (multiplier)
  final String displayText;

  AchievementReward({
    required this.type,
    required this.value,
    required this.displayText,
  });
}

// ═══════════════════════════════════════════════════════════
//  ACHIEVEMENT CLASS
// ═══════════════════════════════════════════════════════════

class Achievement {
  final String id;
  final String name;
  final String description;
  final String emoji;
  final AchievementCategory category;
  final int targetValue;
  final List<AchievementReward> rewards;
  final bool isSecret; // Hidden until unlocked

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

// ═══════════════════════════════════════════════════════════
//  ACHIEVEMENT SERVICE
// ═══════════════════════════════════════════════════════════

class AchievementService {
  static final AchievementService _instance = AchievementService._internal();
  factory AchievementService() => _instance;
  AchievementService._internal();

  final List<Achievement> _achievements = [];

  // Callback for when achievements are unlocked (for UI notifications)
  Function(Achievement)? onAchievementUnlocked;

  // ═══════════════════════════════════════════════════════════
  //  ACHIEVEMENT DEFINITIONS
  // ═══════════════════════════════════════════════════════════

  void _initializeAchievements() {
    _achievements.addAll([
      // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      // 🎯 FOCUS ACHIEVEMENTS
      // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      Achievement(
        id: 'first_focus',
        name: 'First Steps',
        description: 'Complete your first focus session',
        emoji: '🌱',
        category: AchievementCategory.focus,
        targetValue: 1,
        rewards: [
          AchievementReward(
            type: RewardType.coins,
            value: 100,
            displayText: '100 coins',
          ),
        ],
      ),
      Achievement(
        id: 'focus_10_sessions',
        name: 'Getting Started',
        description: 'Complete 10 focus sessions',
        emoji: '🔥',
        category: AchievementCategory.focus,
        targetValue: 10,
        rewards: [
          AchievementReward(
            type: RewardType.coins,
            value: 500,
            displayText: '500 coins',
          ),
        ],
      ),
      Achievement(
        id: 'focus_50_sessions',
        name: 'Dedicated',
        description: 'Complete 50 focus sessions',
        emoji: '⚡',
        category: AchievementCategory.focus,
        targetValue: 50,
        rewards: [
          AchievementReward(
            type: RewardType.coins,
            value: 2000,
            displayText: '2,000 coins',
          ),
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
          AchievementReward(
            type: RewardType.coins,
            value: 5000,
            displayText: '5,000 coins',
          ),
          AchievementReward(
            type: RewardType.peas,
            value: 100000,
            displayText: '100K peas',
          ),
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
          AchievementReward(
            type: RewardType.coins,
            value: 25000,
            displayText: '25,000 coins',
          ),
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
          AchievementReward(
            type: RewardType.peas,
            value: 10000,
            displayText: '10K peas',
          ),
        ],
      ),
      Achievement(
        id: 'focus_600_minutes',
        name: 'Ten Hours',
        description: 'Focus for 10 total hours',
        emoji: '⏳',
        category: AchievementCategory.focus,
        targetValue: 600,
        rewards: [
          AchievementReward(
            type: RewardType.coins,
            value: 3000,
            displayText: '3,000 coins',
          ),
        ],
      ),
      Achievement(
        id: 'focus_3000_minutes',
        name: 'Fifty Hours',
        description: 'Focus for 50 total hours',
        emoji: '🌟',
        category: AchievementCategory.focus,
        targetValue: 3000,
        rewards: [
          AchievementReward(
            type: RewardType.coins,
            value: 15000,
            displayText: '15,000 coins',
          ),
        ],
      ),
      Achievement(
        id: 'focus_6000_minutes',
        name: 'Hundred Hours',
        description: 'Focus for 100 total hours',
        emoji: '💎',
        category: AchievementCategory.focus,
        targetValue: 6000,
        rewards: [
          AchievementReward(
            type: RewardType.coins,
            value: 50000,
            displayText: '50,000 coins',
          ),
          AchievementReward(
            type: RewardType.peas,
            value: 1000000,
            displayText: '1M peas',
          ),
        ],
      ),
      Achievement(
        id: 'streak_3',
        name: 'Hot Streak',
        description: 'Focus 3 days in a row',
        emoji: '🔥',
        category: AchievementCategory.focus,
        targetValue: 3,
        rewards: [
          AchievementReward(
            type: RewardType.coins,
            value: 500,
            displayText: '500 coins',
          ),
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
          AchievementReward(
            type: RewardType.coins,
            value: 2000,
            displayText: '2,000 coins',
          ),
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
          AchievementReward(
            type: RewardType.coins,
            value: 10000,
            displayText: '10,000 coins',
          ),
          AchievementReward(
            type: RewardType.peas,
            value: 500000,
            displayText: '500K peas',
          ),
        ],
      ),

      // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      // 🛋️ FURNITURE ACHIEVEMENTS
      // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      Achievement(
        id: 'first_furniture',
        name: 'Interior Designer',
        description: 'Buy your first furniture',
        emoji: '🛋️',
        category: AchievementCategory.furniture,
        targetValue: 1,
        rewards: [
          AchievementReward(
            type: RewardType.coins,
            value: 200,
            displayText: '200 coins',
          ),
        ],
      ),
      Achievement(
        id: 'furniture_5',
        name: 'Decorator',
        description: 'Own 5 pieces of furniture',
        emoji: '🏠',
        category: AchievementCategory.furniture,
        targetValue: 5,
        rewards: [
          AchievementReward(
            type: RewardType.coins,
            value: 1000,
            displayText: '1,000 coins',
          ),
        ],
      ),
      Achievement(
        id: 'furniture_all',
        name: 'Complete Collection',
        description: 'Own all furniture items',
        emoji: '🎯',
        category: AchievementCategory.furniture,
        targetValue: 20, // Adjust based on total furniture count
        rewards: [
          AchievementReward(
            type: RewardType.coins,
            value: 20000,
            displayText: '20,000 coins',
          ),
        ],
      ),
      Achievement(
        id: 'first_legendary',
        name: 'Legendary Item',
        description: 'Upgrade any furniture to level 10',
        emoji: '👑',
        category: AchievementCategory.furniture,
        targetValue: 1,
        rewards: [
          AchievementReward(
            type: RewardType.coins,
            value: 5000,
            displayText: '5,000 coins',
          ),
        ],
      ),
      Achievement(
        id: 'all_legendary',
        name: 'Legendary Collection',
        description: 'Max upgrade all placed furniture',
        emoji: '⭐',
        category: AchievementCategory.furniture,
        targetValue: 12, // All furniture slots
        rewards: [
          AchievementReward(
            type: RewardType.coins,
            value: 100000,
            displayText: '100,000 coins',
          ),
          AchievementReward(
            type: RewardType.peas,
            value: 10000000,
            displayText: '10M peas',
          ),
        ],
      ),
      Achievement(
        id: 'furniture_upgrade_10',
        name: 'Improvement Expert',
        description: 'Upgrade any furniture 10 times',
        emoji: '⬆️',
        category: AchievementCategory.furniture,
        targetValue: 10,
        rewards: [
          AchievementReward(
            type: RewardType.coins,
            value: 1500,
            displayText: '1,500 coins',
          ),
        ],
      ),
      Achievement(
        id: 'furniture_upgrade_100',
        name: 'Upgrade Addict',
        description: 'Perform 100 total furniture upgrades',
        emoji: '📈',
        category: AchievementCategory.furniture,
        targetValue: 100,
        rewards: [
          AchievementReward(
            type: RewardType.coins,
            value: 15000,
            displayText: '15,000 coins',
          ),
        ],
      ),

      // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      // 💰 WEALTH ACHIEVEMENTS
      // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      Achievement(
        id: 'earn_10k_peas',
        name: 'First Harvest',
        description: 'Earn 10,000 total peas',
        emoji: '🌾',
        category: AchievementCategory.wealth,
        targetValue: 10000,
        rewards: [
          AchievementReward(
            type: RewardType.coins,
            value: 300,
            displayText: '300 coins',
          ),
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
          AchievementReward(
            type: RewardType.coins,
            value: 5000,
            displayText: '5,000 coins',
          ),
        ],
      ),
      Achievement(
        id: 'earn_1b_peas',
        name: 'Pea Baron',
        description: 'Earn 1 billion total peas',
        emoji: '💎',
        category: AchievementCategory.wealth,
        targetValue: 1000000000,
        rewards: [
          AchievementReward(
            type: RewardType.coins,
            value: 50000,
            displayText: '50,000 coins',
          ),
        ],
      ),
      Achievement(
        id: 'spend_1k_coins',
        name: 'Big Spender',
        description: 'Spend 1,000 total coins',
        emoji: '💸',
        category: AchievementCategory.wealth,
        targetValue: 1000,
        rewards: [
          AchievementReward(
            type: RewardType.peas,
            value: 50000,
            displayText: '50K peas',
          ),
        ],
      ),
      Achievement(
        id: 'spend_100k_coins',
        name: 'Investment Guru',
        description: 'Spend 100,000 total coins',
        emoji: '🏦',
        category: AchievementCategory.wealth,
        targetValue: 100000,
        rewards: [
          AchievementReward(
            type: RewardType.peas,
            value: 5000000,
            displayText: '5M peas',
          ),
        ],
      ),
      Achievement(
        id: 'convert_10k',
        name: 'Currency Trader',
        description: 'Convert 10,000 peas to coins',
        emoji: '🔄',
        category: AchievementCategory.wealth,
        targetValue: 10000,
        rewards: [
          AchievementReward(
            type: RewardType.coins,
            value: 500,
            displayText: '500 coins',
          ),
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
          AchievementReward(
            type: RewardType.coins,
            value: 2000,
            displayText: '2,000 coins',
          ),
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
          AchievementReward(
            type: RewardType.coins,
            value: 10000,
            displayText: '10,000 coins',
          ),
        ],
      ),
      Achievement(
        id: 'unlock_mansion',
        name: 'Living Large',
        description: 'Unlock the Mansion',
        emoji: '🏰',
        category: AchievementCategory.property,
        targetValue: 1,
        rewards: [
          AchievementReward(
            type: RewardType.coins,
            value: 50000,
            displayText: '50,000 coins',
          ),
          AchievementReward(
            type: RewardType.peas,
            value: 100000000,
            displayText: '100M peas',
          ),
        ],
      ),

      // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      // ⚡ POWER ACHIEVEMENTS
      // ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
      Achievement(
        id: 'multiplier_5x',
        name: 'Power Boost',
        description: 'Reach 5x multiplier',
        emoji: '⚡',
        category: AchievementCategory.power,
        targetValue: 5,
        rewards: [
          AchievementReward(
            type: RewardType.coins,
            value: 1000,
            displayText: '1,000 coins',
          ),
        ],
      ),
      Achievement(
        id: 'multiplier_50x',
        name: 'Power Surge',
        description: 'Reach 50x multiplier',
        emoji: '⚡⚡',
        category: AchievementCategory.power,
        targetValue: 50,
        rewards: [
          AchievementReward(
            type: RewardType.coins,
            value: 10000,
            displayText: '10,000 coins',
          ),
        ],
      ),
      Achievement(
        id: 'multiplier_500x',
        name: 'Unstoppable',
        description: 'Reach 500x multiplier',
        emoji: '💥',
        category: AchievementCategory.power,
        targetValue: 500,
        rewards: [
          AchievementReward(
            type: RewardType.coins,
            value: 100000,
            displayText: '100,000 coins',
          ),
        ],
      ),
      Achievement(
        id: 'buy_10_upgrades',
        name: 'Upgrade Enthusiast',
        description: 'Purchase 10 upgrades',
        emoji: '📦',
        category: AchievementCategory.power,
        targetValue: 10,
        rewards: [
          AchievementReward(
            type: RewardType.peas,
            value: 100000,
            displayText: '100K peas',
          ),
        ],
      ),
      Achievement(
        id: 'buy_all_cave_upgrades',
        name: 'Cave Master',
        description: 'Buy all Cave upgrades',
        emoji: '🏔️',
        category: AchievementCategory.power,
        targetValue: 10, // Number of cave upgrades
        rewards: [
          AchievementReward(
            type: RewardType.coins,
            value: 5000,
            displayText: '5,000 coins',
          ),
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
          AchievementReward(
            type: RewardType.coins,
            value: 1000,
            displayText: '1,000 coins',
          ),
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
          AchievementReward(
            type: RewardType.coins,
            value: 3000,
            displayText: '3,000 coins',
          ),
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
          AchievementReward(
            type: RewardType.peas,
            value: 500000,
            displayText: '500K peas',
          ),
        ],
      ),
    ]);
  }

  // ═══════════════════════════════════════════════════════════
  //  INITIALIZATION
  // ═══════════════════════════════════════════════════════════

  Future<void> init() async {
    _initializeAchievements();
    await _loadProgress();
  }

  // ═══════════════════════════════════════════════════════════
  //  GETTERS
  // ═══════════════════════════════════════════════════════════

  List<Achievement> get allAchievements => _achievements;

  List<Achievement> get unlockedAchievements =>
      _achievements.where((a) => a.isUnlocked).toList();

  List<Achievement> get lockedAchievements =>
      _achievements.where((a) => !a.isUnlocked).toList();

  List<Achievement> getByCategory(AchievementCategory category) =>
      _achievements.where((a) => a.category == category).toList();

  int get totalUnlocked => unlockedAchievements.length;
  int get totalAchievements => _achievements.length;

  double get completionPercent =>
      (totalUnlocked / totalAchievements * 100);

  // ═══════════════════════════════════════════════════════════
  //  PROGRESS TRACKING
  // ═══════════════════════════════════════════════════════════

  Future<void> updateProgress(String achievementId, int newProgress) async {
    final achievement = _achievements.firstWhere(
          (a) => a.id == achievementId,
      orElse: () => throw Exception('Achievement not found: $achievementId'),
    );

    if (achievement.isUnlocked) return; // Already unlocked

    achievement.currentProgress = newProgress;

    // Check if unlocked
    if (achievement.isComplete && !achievement.isUnlocked) {
      await _unlockAchievement(achievement);
    }

    await _saveProgress();
  }

  Future<void> incrementProgress(String achievementId, [int amount = 1]) async {
    final achievement = _achievements.firstWhere(
          (a) => a.id == achievementId,
      orElse: () => throw Exception('Achievement not found: $achievementId'),
    );

    if (achievement.isUnlocked) return;

    achievement.currentProgress += amount;

    if (achievement.isComplete && !achievement.isUnlocked) {
      await _unlockAchievement(achievement);
    }

    await _saveProgress();
  }

  Future<void> _unlockAchievement(Achievement achievement) async {
    achievement.isUnlocked = true;
    achievement.unlockedAt = DateTime.now();

    // Grant rewards
    await _grantRewards(achievement.rewards);

    // Trigger callback for UI notification
    onAchievementUnlocked?.call(achievement);

    await _saveProgress();
  }

  Future<void> _grantRewards(List<AchievementReward> rewards) async {
    // This will be called by the UI layer to actually grant rewards
    // The service just marks them as pending
  }

  // ═══════════════════════════════════════════════════════════
  //  PERSISTENCE
  // ═══════════════════════════════════════════════════════════

  Future<void> _saveProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final progressData = _achievements.map((a) => a.toJson()).toList();
    await prefs.setString('achievement_progress', json.encode(progressData));
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final progressJson = prefs.getString('achievement_progress');

    if (progressJson == null) return;

    final List<dynamic> progressData = json.decode(progressJson);

    for (var i = 0; i < progressData.length && i < _achievements.length; i++) {
      final saved = progressData[i];
      _achievements[i] = Achievement.fromJson(saved, _achievements[i]);
    }
  }

  // ═══════════════════════════════════════════════════════════
  //  HELPER METHODS FOR TRACKING
  // ═══════════════════════════════════════════════════════════

  // Call these from your app when events happen:

  Future<void> onFocusSessionCompleted(int minutes) async {
    await incrementProgress('first_focus');
    await incrementProgress('focus_10_sessions');
    await incrementProgress('focus_50_sessions');
    await incrementProgress('focus_100_sessions');
    await incrementProgress('focus_500_sessions');
    await incrementProgress('focus_60_minutes', minutes);
    await incrementProgress('focus_600_minutes', minutes);
    await incrementProgress('focus_3000_minutes', minutes);
    await incrementProgress('focus_6000_minutes', minutes);

    // Check for secret achievements
    if (minutes >= 120) {
      await incrementProgress('marathon_session');
    }

    final hour = DateTime.now().hour;
    if (hour >= 0 && hour < 6) {
      await incrementProgress('night_owl');
    }
  }

  Future<void> onStreakUpdated(int currentStreak) async {
    await updateProgress('streak_3', currentStreak);
    await updateProgress('streak_7', currentStreak);
    await updateProgress('streak_30', currentStreak);
  }

  Future<void> onFurniturePurchased() async {
    await incrementProgress('first_furniture');
    await incrementProgress('furniture_5');
    await incrementProgress('furniture_all');
  }

  Future<void> onFurnitureUpgraded(int newLevel) async {
    await incrementProgress('furniture_upgrade_10');
    await incrementProgress('furniture_upgrade_100');

    if (newLevel == 10) {
      await incrementProgress('first_legendary');
      await incrementProgress('all_legendary');
    }
  }

  Future<void> onPeasEarned(int amount) async {
    await incrementProgress('earn_10k_peas', amount);
    await incrementProgress('earn_1m_peas', amount);
    await incrementProgress('earn_1b_peas', amount);
  }

  Future<void> onCoinsSpent(int amount) async {
    await incrementProgress('spend_1k_coins', amount);
    await incrementProgress('spend_100k_coins', amount);
  }

  Future<void> onPeasConverted(int amount) async {
    await incrementProgress('convert_10k', amount);
  }

  Future<void> onHouseUnlocked(int stage) async {
    if (stage == 1) await incrementProgress('unlock_shack');
    if (stage == 2) await incrementProgress('unlock_house');
    if (stage == 3) await incrementProgress('unlock_mansion');
  }

  Future<void> onMultiplierReached(int multiplier) async {
    await updateProgress('multiplier_5x', multiplier);
    await updateProgress('multiplier_50x', multiplier);
    await updateProgress('multiplier_500x', multiplier);
  }

  Future<void> onUpgradePurchased(String stageType) async {
    await incrementProgress('buy_10_upgrades');

    if (stageType == 'cave') {
      await incrementProgress('buy_all_cave_upgrades');
    }
  }
}