import 'package:berry_focused/services/achievements_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:berry_focused/services/upgrade_service.dart';

enum FurnitureCategory {
  bed,
  desk,
  chair,
  kitchen,
  decoration,
}

class Furniture {
  final String id;
  final String name;
  final String emoji;
  final String description;
  final int cost;
  final double boost;
  final FurnitureCategory category;
  final int stageRequired;
  final int upgradesRequired;

  Furniture({
    required this.id,
    required this.name,
    required this.emoji,
    required this.description,
    required this.cost,
    required this.boost,
    required this.category,
    this.stageRequired = 0,
    this.upgradesRequired = 0,
  });
}

class FurnitureService {
  final AchievementService _achievementService = AchievementService();
  static final FurnitureService _instance = FurnitureService._internal();
  factory FurnitureService() => _instance;
  FurnitureService._internal();

  Furniture? getPlacedFurniture(String spotId) {
    final furnitureId = placedFurniture[spotId];
    if (furnitureId == null) return null;
    return getFurnitureById(furnitureId);
  }

  Map<String, String?> placedFurniture = {
    'bed_spot': null,
    'desk_spot': null,
    'chair_spot': null,
    'kitchen_spot': null,
    'decoration_spot_1': null,
    'decoration_spot_2': null,
    'decoration_spot_3': null,
    'decoration_spot_4': null,
    'decoration_spot_5': null,
    'decoration_spot_6': null,
    'decoration_spot_7': null,
    'decoration_spot_8': null,
  };

  Set<String> ownedFurniture = {};

  // ── Direct boost map — all buyable image furniture ────────────────────
  // These are owned via buyFurniture() and never placed in a spot.
  // Adjust boost values here as needed.
  static const Map<String, double> _directBoosts = {
    // Cave
    'stone_window': 0.10,
    'stone_rug':    0.22,
    'stone_fire':   0.30,
    'stone_chair':  0.38,
    'stone_bed':    0.55,
    'stone_table':  0.72,
    // Shack
    'shack_lights':  0.15,
    'shack_window':  0.22,
    'shack_picture': 0.22,
    'shack_table':   0.28,
    'shack_bed':     0.42,
    'shack_stove':   0.55,
    // House kitchen
    'house_light':   0.54,
    'house_cabinet': 0.54,
    'house_table':   0.72,
    'house_stove':   0.95,
    'house_fridge':  1.20,
    // Bedroom
    'bedroom_clock':   0.54,
    'bedroom_picture': 0.54,
    'bedroom_desk':    0.78,
    'bedroom_bunkbed': 1.00,
    'bedroom_bed':     1.30,
    // Special — handled as multipliers
    'windchimes': 0.0,
    'fountain':   0.0,
  };

  List<Furniture> getFurnitureForStage(int stage) {
    return allFurniture.where((f) => f.stageRequired == stage).toList();
  }

  List<Furniture> getFurnitureForStageAndCategory(int stage, FurnitureCategory category) {
    return allFurniture.where((f) => f.stageRequired == stage && f.category == category).toList();
  }

  final List<Furniture> allFurniture = [

  ];

  Future<void> init() async {
    await loadFurniture();
  }

  Furniture? getFurnitureById(String id) {
    try {
      return allFurniture.firstWhere((f) => f.id == id);
    } catch (e) {
      return null;
    }
  }

  bool isFurnitureOwned(String id) => ownedFurniture.contains(id);

  bool isFurniturePlaced(String id) => placedFurniture.containsValue(id);

  bool isFurnitureUnlocked(String furnitureId) {
    final furniture = getFurnitureById(furnitureId);
    if (furniture == null) return false;
    final totalUpgrades = UpgradeService().getTotalUpgradesPurchased();
    return totalUpgrades >= furniture.upgradesRequired;
  }

  List<Furniture> getNewlyUnlockedFurniture(int oldUpgradeCount, int newUpgradeCount) {
    List<Furniture> newlyUnlocked = [];
    for (var furniture in allFurniture) {
      if (furniture.upgradesRequired > oldUpgradeCount &&
          furniture.upgradesRequired <= newUpgradeCount) {
        newlyUnlocked.add(furniture);
      }
    }
    return newlyUnlocked;
  }

  List<Furniture> getAvailableFurnitureForStage(int stage) {
    return allFurniture
        .where((f) => f.stageRequired == stage && isFurnitureUnlocked(f.id))
        .toList();
  }

  List<Furniture> getLockedFurnitureForStage(int stage) {
    return allFurniture
        .where((f) => f.stageRequired == stage && !isFurnitureUnlocked(f.id))
        .toList();
  }

  String? getPlacedSpot(String furnitureId) {
    for (var entry in placedFurniture.entries) {
      if (entry.value == furnitureId) return entry.key;
    }
    return null;
  }

  String? findEmptySpot(FurnitureCategory category) {
    switch (category) {
      case FurnitureCategory.bed:
        return 'bed_spot';
      case FurnitureCategory.desk:
        return 'desk_spot';
      case FurnitureCategory.chair:
        return 'chair_spot';
      case FurnitureCategory.kitchen:
        return 'kitchen_spot';
      case FurnitureCategory.decoration:
        for (int i = 1; i <= 8; i++) {
          String spot = 'decoration_spot_$i';
          if (placedFurniture[spot] == null) return spot;
        }
        return null;
    }
  }

  void placeFurniture(String furnitureId) {
    final furniture = getFurnitureById(furnitureId);
    if (furniture == null) return;
    if (furniture.category != FurnitureCategory.decoration) {
      final spot = findEmptySpot(furniture.category)!;
      placedFurniture[spot] = furnitureId;
    } else {
      final spot = findEmptySpot(furniture.category);
      if (spot != null) {
        placedFurniture[spot] = furnitureId;
      }
    }
    saveFurniture();
  }

  void removeFurniture(String furnitureId) {
    final spot = getPlacedSpot(furnitureId);
    if (spot != null) {
      placedFurniture[spot] = null;
      saveFurniture();
    }
  }

  Future<bool> buyFurniture(String furnitureId) async {
    if (!ownedFurniture.contains(furnitureId)) {
      ownedFurniture.add(furnitureId);
      await saveFurniture();
      await _achievementService.onFurniturePurchased(ownedFurniture.length);
      return true;
    }
    return false;
  }

  /// Boost from placed furniture (shop items placed in spots)
  double getTotalBoost() {
    double total = 0;
    for (var entry in placedFurniture.entries) {
      if (entry.value != null) {
        final furniture = getFurnitureById(entry.value!);
        if (furniture != null) {
          total += furniture.boost;
        }
      }
    }
    return total;
  }

  /// Boost from directly owned image-based furniture (cave/shack/house/bedroom)
  double getDirectBoost() {
    double total = 0;
    for (final entry in _directBoosts.entries) {
      if (ownedFurniture.contains(entry.key)) {
        total += entry.value;
      }
    }
    return total;
  }

  double getBoostMultiplier() {
    final directBoost  = 1.0 + getDirectBoost();   // furniture items
    final placedBoost  = 1.0 + getTotalBoost();     // shop items
    return directBoost * placedBoost;
  }

  /// Display string
  String getBoostString() {
    final boost = getTotalBoost() + getDirectBoost();
    if (boost == 0) return 'No boost';
    return '+${(boost * 100).toStringAsFixed(0)}% (${getBoostMultiplier().toStringAsFixed(2)}x)';
  }

  Future<void> saveFurniture() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('owned_furniture', ownedFurniture.toList());
    await prefs.setString('placed_furniture', json.encode(placedFurniture));
  }

  Future<void> loadFurniture() async {
    final prefs = await SharedPreferences.getInstance();
    final owned = prefs.getStringList('owned_furniture');
    if (owned != null) {
      ownedFurniture = owned.toSet();
    }
    final placed = prefs.getString('placed_furniture');
    if (placed != null) {
      final Map<String, dynamic> decoded = json.decode(placed);
      for (var key in decoded.keys) {
        if (placedFurniture.containsKey(key)) {
          placedFurniture[key] = decoded[key];
        }
      }
    }
  }

  Future<void> reset() async {
    ownedFurniture.clear();
    for (var key in placedFurniture.keys) {
      placedFurniture[key] = null;
    }
    await saveFurniture();
  }
}