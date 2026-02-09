import 'package:flutter/material.dart';

/// Achievement Model
class Achievement {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final int targetValue;
  final AchievementType type;
  final AchievementReward reward;
  final AchievementRarity rarity;

  bool isUnlocked;
  int currentProgress;
  DateTime? unlockedAt;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.targetValue,
    required this.type,
    required this.reward,
    this.rarity = AchievementRarity.common,
    this.isUnlocked = false,
    this.currentProgress = 0,
    this.unlockedAt,
  });

  /// Progress percentage (0.0 to 1.0)
  double get progressPercentage {
    if (targetValue == 0) return 0.0;
    return (currentProgress / targetValue).clamp(0.0, 1.0);
  }

  /// Check if achievement should be unlocked
  bool shouldUnlock() {
    return !isUnlocked && currentProgress >= targetValue;
  }

  /// Unlock this achievement
  void unlock() {
    isUnlocked = true;
    unlockedAt = DateTime.now();
  }

  /// Update progress
  void updateProgress(int value) {
    if (!isUnlocked) {
      currentProgress = value;
      if (shouldUnlock()) {
        unlock();
      }
    }
  }

  /// Increment progress by amount
  void incrementProgress(int amount) {
    if (!isUnlocked) {
      currentProgress += amount;
      if (shouldUnlock()) {
        unlock();
      }
    }
  }

  /// Convert to JSON for saving
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'isUnlocked': isUnlocked,
      'currentProgress': currentProgress,
      'unlockedAt': unlockedAt?.toIso8601String(),
    };
  }

  /// Create from JSON
  factory Achievement.fromJson(Map<String, dynamic> json, Achievement template) {
    return Achievement(
      id: template.id,
      title: template.title,
      description: template.description,
      icon: template.icon,
      targetValue: template.targetValue,
      type: template.type,
      reward: template.reward,
      rarity: template.rarity,
      isUnlocked: json['isUnlocked'] ?? false,
      currentProgress: json['currentProgress'] ?? 0,
      unlockedAt: json['unlockedAt'] != null
          ? DateTime.parse(json['unlockedAt'])
          : null,
    );
  }
}

/// Achievement Type (what triggers it)
enum AchievementType {
  focusTime,      // Total time spent focusing
  focusSessions,  // Number of sessions completed
  peasEarned,     // Total peas earned
  coinsEarned,    // Total coins earned
  furniturePlaced, // Furniture items placed
  furnitureBought, // Furniture purchased
  levelReached,   // Character level
  streakDays,     // Daily streak
  gardenHarvests, // Times harvested garden
  factsRead,      // Facts read from Bob
  buttonClicks,   // Total UI interactions (for fun)
}

/// Achievement Rarity
enum AchievementRarity {
  common,    // Easy to get
  uncommon,  // Moderate effort
  rare,      // Significant effort
  epic,      // Very difficult
  legendary, // Extremely rare
}

/// Achievement Reward
class AchievementReward {
  final int peas;
  final int coins;
  final String? specialItem; // Future: unlock special furniture

  const AchievementReward({
    this.peas = 0,
    this.coins = 0,
    this.specialItem,
  });

  /// Get total value description
  String getDescription() {
    List<String> parts = [];
    if (peas > 0) parts.add('$peas peas');
    if (coins > 0) parts.add('$coins coins');
    if (specialItem != null) parts.add(specialItem!);
    return parts.isEmpty ? 'No reward' : parts.join(', ');
  }
}

/// Helper to get rarity color
extension AchievementRarityColor on AchievementRarity {
  Color get color {
    switch (this) {
      case AchievementRarity.common:
        return Colors.grey;
      case AchievementRarity.uncommon:
        return Colors.green;
      case AchievementRarity.rare:
        return Colors.blue;
      case AchievementRarity.epic:
        return Colors.purple;
      case AchievementRarity.legendary:
        return Colors.amber;
    }
  }

  String get displayName {
    switch (this) {
      case AchievementRarity.common:
        return 'Common';
      case AchievementRarity.uncommon:
        return 'Uncommon';
      case AchievementRarity.rare:
        return 'Rare';
      case AchievementRarity.epic:
        return 'Epic';
      case AchievementRarity.legendary:
        return 'Legendary';
    }
  }
}