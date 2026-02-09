import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'achievement_model.dart';

class AchievementsService {
  static final AchievementsService _instance = AchievementsService._internal();
  factory AchievementsService() => _instance;
  AchievementsService._internal();

  // All achievements in the game
  final List<Achievement> _allAchievements = [];

  // Callbacks for when achievements are unlocked
  final List<Function(Achievement)> _unlockCallbacks = [];

  /// Initialize achievements
  void initialize() {
    _allAchievements.clear();
    _allAchievements.addAll(_createAllAchievements());
  }

  /// Create all achievements
  List<Achievement> _createAllAchievements() {
    return [
      // ==========================================
      // FOCUS TIME ACHIEVEMENTS (Total minutes)
      // ==========================================
      Achievement(
        id: 'focus_1min',
        title: 'First Step',
        description: 'Complete your first minute of focus',
        icon: Icons.timer,
        targetValue: 1,
        type: AchievementType.focusTime,
        reward: AchievementReward(peas: 50, coins: 5),
        rarity: AchievementRarity.common,
      ),
      Achievement(
        id: 'focus_10min',
        title: 'Getting Started',
        description: 'Focus for 10 minutes total',
        icon: Icons.access_time,
        targetValue: 10,
        type: AchievementType.focusTime,
        reward: AchievementReward(peas: 100, coins: 10),
        rarity: AchievementRarity.common,
      ),
      Achievement(
        id: 'focus_30min',
        title: 'Half Hour Hero',
        description: 'Focus for 30 minutes total',
        icon: Icons.schedule,
        targetValue: 30,
        type: AchievementType.focusTime,
        reward: AchievementReward(peas: 300, coins: 25),
        rarity: AchievementRarity.common,
      ),
      Achievement(
        id: 'focus_1hr',
        title: 'One Hour Wonder',
        description: 'Focus for 1 hour total',
        icon: Icons.alarm,
        targetValue: 60,
        type: AchievementType.focusTime,
        reward: AchievementReward(peas: 500, coins: 50),
        rarity: AchievementRarity.uncommon,
      ),
      Achievement(
        id: 'focus_3hr',
        title: 'Deep Work',
        description: 'Focus for 3 hours total',
        icon: Icons.work,
        targetValue: 180,
        type: AchievementType.focusTime,
        reward: AchievementReward(peas: 1000, coins: 100),
        rarity: AchievementRarity.uncommon,
      ),
      Achievement(
        id: 'focus_10hr',
        title: 'Focus Master',
        description: 'Focus for 10 hours total',
        icon: Icons.psychology,
        targetValue: 600,
        type: AchievementType.focusTime,
        reward: AchievementReward(peas: 3000, coins: 250),
        rarity: AchievementRarity.rare,
      ),
      Achievement(
        id: 'focus_25hr',
        title: 'Concentration King',
        description: 'Focus for 25 hours total',
        icon: Icons.emoji_events,
        targetValue: 1500,
        type: AchievementType.focusTime,
        reward: AchievementReward(peas: 5000, coins: 500),
        rarity: AchievementRarity.rare,
      ),
      Achievement(
        id: 'focus_50hr',
        title: 'Productivity Legend',
        description: 'Focus for 50 hours total',
        icon: Icons.military_tech,
        targetValue: 3000,
        type: AchievementType.focusTime,
        reward: AchievementReward(peas: 10000, coins: 1000),
        rarity: AchievementRarity.epic,
      ),
      Achievement(
        id: 'focus_100hr',
        title: 'Century of Focus',
        description: 'Focus for 100 hours total',
        icon: Icons.star,
        targetValue: 6000,
        type: AchievementType.focusTime,
        reward: AchievementReward(peas: 25000, coins: 2500),
        rarity: AchievementRarity.epic,
      ),
      Achievement(
        id: 'focus_500hr',
        title: 'Monk Mind',
        description: 'Focus for 500 hours total',
        icon: Icons.self_improvement,
        targetValue: 30000,
        type: AchievementType.focusTime,
        reward: AchievementReward(peas: 100000, coins: 10000),
        rarity: AchievementRarity.legendary,
      ),
      Achievement(
        id: 'focus_1000hr',
        title: 'Enlightened One',
        description: 'Focus for 1,000 hours total - Ultimate dedication!',
        icon: Icons.workspace_premium,
        targetValue: 60000,
        type: AchievementType.focusTime,
        reward: AchievementReward(peas: 500000, coins: 50000),
        rarity: AchievementRarity.legendary,
      ),

      // ==========================================
      // FOCUS SESSIONS ACHIEVEMENTS
      // ==========================================
      Achievement(
        id: 'sessions_1',
        title: 'Session Starter',
        description: 'Complete your first focus session',
        icon: Icons.play_circle,
        targetValue: 1,
        type: AchievementType.focusSessions,
        reward: AchievementReward(peas: 100, coins: 10),
        rarity: AchievementRarity.common,
      ),
      Achievement(
        id: 'sessions_10',
        title: 'Dedicated',
        description: 'Complete 10 focus sessions',
        icon: Icons.repeat,
        targetValue: 10,
        type: AchievementType.focusSessions,
        reward: AchievementReward(peas: 500, coins: 50),
        rarity: AchievementRarity.uncommon,
      ),
      Achievement(
        id: 'sessions_50',
        title: 'Habit Builder',
        description: 'Complete 50 focus sessions',
        icon: Icons.trending_up,
        targetValue: 50,
        type: AchievementType.focusSessions,
        reward: AchievementReward(peas: 2000, coins: 200),
        rarity: AchievementRarity.rare,
      ),
      Achievement(
        id: 'sessions_100',
        title: 'Century Sessions',
        description: 'Complete 100 focus sessions',
        icon: Icons.auto_awesome,
        targetValue: 100,
        type: AchievementType.focusSessions,
        reward: AchievementReward(peas: 5000, coins: 500),
        rarity: AchievementRarity.epic,
      ),
      Achievement(
        id: 'sessions_500',
        title: 'Unstoppable',
        description: 'Complete 500 focus sessions',
        icon: Icons.bolt,
        targetValue: 500,
        type: AchievementType.focusSessions,
        reward: AchievementReward(peas: 25000, coins: 2500),
        rarity: AchievementRarity.legendary,
      ),

      // ==========================================
      // PEAS EARNED ACHIEVEMENTS
      // ==========================================
      Achievement(
        id: 'peas_1k',
        title: 'First Harvest',
        description: 'Earn 1,000 peas',
        icon: Icons.grass,
        targetValue: 1000,
        type: AchievementType.peasEarned,
        reward: AchievementReward(coins: 20),
        rarity: AchievementRarity.common,
      ),
      Achievement(
        id: 'peas_10k',
        title: 'Growing Rich',
        description: 'Earn 10,000 peas',
        icon: Icons.eco,
        targetValue: 10000,
        type: AchievementType.peasEarned,
        reward: AchievementReward(coins: 100),
        rarity: AchievementRarity.uncommon,
      ),
      Achievement(
        id: 'peas_100k',
        title: 'Pea Tycoon',
        description: 'Earn 100,000 peas',
        icon: Icons.account_balance,
        targetValue: 100000,
        type: AchievementType.peasEarned,
        reward: AchievementReward(coins: 500),
        rarity: AchievementRarity.rare,
      ),
      Achievement(
        id: 'peas_1m',
        title: 'Pea Millionaire',
        description: 'Earn 1,000,000 peas',
        icon: Icons.diamond,
        targetValue: 1000000,
        type: AchievementType.peasEarned,
        reward: AchievementReward(coins: 2500),
        rarity: AchievementRarity.epic,
      ),
      Achievement(
        id: 'peas_10m',
        title: 'Pea Emperor',
        description: 'Earn 10,000,000 peas',
        icon: Icons.castle,
        targetValue: 10000000,
        type: AchievementType.peasEarned,
        reward: AchievementReward(coins: 10000),
        rarity: AchievementRarity.legendary,
      ),

      // ==========================================
      // COINS EARNED ACHIEVEMENTS
      // ==========================================
      Achievement(
        id: 'coins_100',
        title: 'Coin Collector',
        description: 'Earn 100 coins',
        icon: Icons.monetization_on,
        targetValue: 100,
        type: AchievementType.coinsEarned,
        reward: AchievementReward(peas: 500),
        rarity: AchievementRarity.common,
      ),
      Achievement(
        id: 'coins_1k',
        title: 'Wealthy',
        description: 'Earn 1,000 coins',
        icon: Icons.attach_money,
        targetValue: 1000,
        type: AchievementType.coinsEarned,
        reward: AchievementReward(peas: 3000),
        rarity: AchievementRarity.uncommon,
      ),
      Achievement(
        id: 'coins_10k',
        title: 'Coin Baron',
        description: 'Earn 10,000 coins',
        icon: Icons.savings,
        targetValue: 10000,
        type: AchievementType.coinsEarned,
        reward: AchievementReward(peas: 20000),
        rarity: AchievementRarity.rare,
      ),
      Achievement(
        id: 'coins_100k',
        title: 'Treasure Hoarder',
        description: 'Earn 100,000 coins',
        icon: Icons.public,
        targetValue: 100000,
        type: AchievementType.coinsEarned,
        reward: AchievementReward(peas: 100000),
        rarity: AchievementRarity.legendary,
      ),

      // ==========================================
      // FURNITURE ACHIEVEMENTS
      // ==========================================
      Achievement(
        id: 'furniture_1',
        title: 'First Decoration',
        description: 'Place your first furniture',
        icon: Icons.chair,
        targetValue: 1,
        type: AchievementType.furniturePlaced,
        reward: AchievementReward(peas: 200, coins: 20),
        rarity: AchievementRarity.common,
      ),
      Achievement(
        id: 'furniture_10',
        title: 'Interior Designer',
        description: 'Place 10 furniture items',
        icon: Icons.weekend,
        targetValue: 10,
        type: AchievementType.furniturePlaced,
        reward: AchievementReward(peas: 1000, coins: 100),
        rarity: AchievementRarity.uncommon,
      ),
      Achievement(
        id: 'furniture_50',
        title: 'Cave Decorator',
        description: 'Place 50 furniture items',
        icon: Icons.home,
        targetValue: 50,
        type: AchievementType.furniturePlaced,
        reward: AchievementReward(peas: 5000, coins: 500),
        rarity: AchievementRarity.rare,
      ),
      Achievement(
        id: 'furniture_buy_25',
        title: 'Shop Enthusiast',
        description: 'Purchase 25 furniture items',
        icon: Icons.shopping_cart,
        targetValue: 25,
        type: AchievementType.furnitureBought,
        reward: AchievementReward(peas: 3000, coins: 300),
        rarity: AchievementRarity.rare,
      ),

      // ==========================================
      // LEVEL ACHIEVEMENTS
      // ==========================================
      Achievement(
        id: 'level_5',
        title: 'Rising Star',
        description: 'Reach level 5',
        icon: Icons.star_half,
        targetValue: 5,
        type: AchievementType.levelReached,
        reward: AchievementReward(peas: 500, coins: 50),
        rarity: AchievementRarity.common,
      ),
      Achievement(
        id: 'level_10',
        title: 'Double Digits',
        description: 'Reach level 10',
        icon: Icons.looks_two,
        targetValue: 10,
        type: AchievementType.levelReached,
        reward: AchievementReward(peas: 2000, coins: 200),
        rarity: AchievementRarity.uncommon,
      ),
      Achievement(
        id: 'level_25',
        title: 'Quarter Century',
        description: 'Reach level 25',
        icon: Icons.trending_up,
        targetValue: 25,
        type: AchievementType.levelReached,
        reward: AchievementReward(peas: 10000, coins: 1000),
        rarity: AchievementRarity.rare,
      ),
      Achievement(
        id: 'level_50',
        title: 'Halfway to 100',
        description: 'Reach level 50',
        icon: Icons.whatshot,
        targetValue: 50,
        type: AchievementType.levelReached,
        reward: AchievementReward(peas: 25000, coins: 2500),
        rarity: AchievementRarity.epic,
      ),
      Achievement(
        id: 'level_100',
        title: 'Centurion',
        description: 'Reach level 100',
        icon: Icons.emoji_events,
        targetValue: 100,
        type: AchievementType.levelReached,
        reward: AchievementReward(peas: 100000, coins: 10000),
        rarity: AchievementRarity.legendary,
      ),

      // ==========================================
      // STREAK ACHIEVEMENTS
      // ==========================================
      Achievement(
        id: 'streak_3',
        title: 'Three Day Streak',
        description: 'Focus for 3 days in a row',
        icon: Icons.local_fire_department,
        targetValue: 3,
        type: AchievementType.streakDays,
        reward: AchievementReward(peas: 300, coins: 30),
        rarity: AchievementRarity.common,
      ),
      Achievement(
        id: 'streak_7',
        title: 'One Week Warrior',
        description: 'Focus for 7 days in a row',
        icon: Icons.calendar_today,
        targetValue: 7,
        type: AchievementType.streakDays,
        reward: AchievementReward(peas: 1000, coins: 100),
        rarity: AchievementRarity.uncommon,
      ),
      Achievement(
        id: 'streak_30',
        title: 'Monthly Master',
        description: 'Focus for 30 days in a row',
        icon: Icons.calendar_month,
        targetValue: 30,
        type: AchievementType.streakDays,
        reward: AchievementReward(peas: 10000, coins: 1000),
        rarity: AchievementRarity.epic,
      ),
      Achievement(
        id: 'streak_100',
        title: 'Streak Legend',
        description: 'Focus for 100 days in a row',
        icon: Icons.whatshot,
        targetValue: 100,
        type: AchievementType.streakDays,
        reward: AchievementReward(peas: 50000, coins: 5000),
        rarity: AchievementRarity.legendary,
      ),

      // ==========================================
      // FUN ACHIEVEMENTS
      // ==========================================
      Achievement(
        id: 'facts_10',
        title: 'Curious Mind',
        description: 'Read 10 facts from Bob',
        icon: Icons.lightbulb,
        targetValue: 10,
        type: AchievementType.factsRead,
        reward: AchievementReward(peas: 100, coins: 10),
        rarity: AchievementRarity.common,
      ),
      Achievement(
        id: 'facts_100',
        title: 'Knowledge Seeker',
        description: 'Read 100 facts from Bob',
        icon: Icons.school,
        targetValue: 100,
        type: AchievementType.factsRead,
        reward: AchievementReward(peas: 1000, coins: 100),
        rarity: AchievementRarity.uncommon,
      ),
      Achievement(
        id: 'facts_all',
        title: 'Encyclopedia',
        description: 'Read all 400+ facts!',
        icon: Icons.menu_book,
        targetValue: 400,
        type: AchievementType.factsRead,
        reward: AchievementReward(peas: 10000, coins: 1000),
        rarity: AchievementRarity.legendary,
      ),
      Achievement(
        id: 'garden_10',
        title: 'Green Thumb',
        description: 'Harvest the garden 10 times',
        icon: Icons.local_florist,
        targetValue: 10,
        type: AchievementType.gardenHarvests,
        reward: AchievementReward(peas: 500, coins: 50),
        rarity: AchievementRarity.common,
      ),
      Achievement(
        id: 'garden_100',
        title: 'Master Gardener',
        description: 'Harvest the garden 100 times',
        icon: Icons.agriculture,
        targetValue: 100,
        type: AchievementType.gardenHarvests,
        reward: AchievementReward(peas: 5000, coins: 500),
        rarity: AchievementRarity.rare,
      ),
    ];
  }

  /// Update achievement progress
  void updateProgress(AchievementType type, int value) {
    for (var achievement in _allAchievements) {
      if (achievement.type == type && !achievement.isUnlocked) {
        bool wasLocked = !achievement.isUnlocked;
        achievement.updateProgress(value);

        // Trigger callback if newly unlocked
        if (wasLocked && achievement.isUnlocked) {
          _notifyUnlock(achievement);
        }
      }
    }
  }

  /// Increment achievement progress
  void incrementProgress(AchievementType type, int amount) {
    for (var achievement in _allAchievements) {
      if (achievement.type == type && !achievement.isUnlocked) {
        bool wasLocked = !achievement.isUnlocked;
        achievement.incrementProgress(amount);

        // Trigger callback if newly unlocked
        if (wasLocked && achievement.isUnlocked) {
          _notifyUnlock(achievement);
        }
      }
    }
  }

  /// Notify listeners of unlock
  void _notifyUnlock(Achievement achievement) {
    for (var callback in _unlockCallbacks) {
      callback(achievement);
    }
  }

  /// Add unlock callback
  void addUnlockCallback(Function(Achievement) callback) {
    _unlockCallbacks.add(callback);
  }

  /// Get all achievements
  List<Achievement> get allAchievements => _allAchievements;

  /// Get unlocked achievements
  List<Achievement> get unlockedAchievements {
    return _allAchievements.where((a) => a.isUnlocked).toList();
  }

  /// Get locked achievements
  List<Achievement> get lockedAchievements {
    return _allAchievements.where((a) => !a.isUnlocked).toList();
  }

  /// Get achievements by type
  List<Achievement> getAchievementsByType(AchievementType type) {
    return _allAchievements.where((a) => a.type == type).toList();
  }

  /// Get achievements by rarity
  List<Achievement> getAchievementsByRarity(AchievementRarity rarity) {
    return _allAchievements.where((a) => a.rarity == rarity).toList();
  }

  /// Get total rewards earned
  AchievementReward getTotalRewardsEarned() {
    int totalPeas = 0;
    int totalCoins = 0;

    for (var achievement in unlockedAchievements) {
      totalPeas += achievement.reward.peas;
      totalCoins += achievement.reward.coins;
    }

    return AchievementReward(peas: totalPeas, coins: totalCoins);
  }

  /// Get completion percentage
  double get completionPercentage {
    if (_allAchievements.isEmpty) return 0.0;
    return unlockedAchievements.length / _allAchievements.length;
  }

  // ============================================================
  // PERSISTENCE (Save/Load)
  // ============================================================

  /// Save achievements to storage
  Future<void> saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      List<Map<String, dynamic>> data = _allAchievements
          .map((a) => a.toJson())
          .toList();

      await prefs.setString('achievements', jsonEncode(data));
    } catch (e) {
      print('Error saving achievements: $e');
    }
  }

  /// Load achievements from storage
  Future<void> loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? data = prefs.getString('achievements');

      if (data != null) {
        List<dynamic> jsonList = jsonDecode(data);

        for (int i = 0; i < jsonList.length && i < _allAchievements.length; i++) {
          _allAchievements[i] = Achievement.fromJson(
            jsonList[i],
            _allAchievements[i],
          );
        }
      }
    } catch (e) {
      print('Error loading achievements: $e');
    }
  }
}