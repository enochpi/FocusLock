import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

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

  Furniture({
    required this.id,
    required this.name,
    required this.emoji,
    required this.description,
    required this.cost,
    required this.boost,
    required this.category,
  });
}

class FurnitureService {
  static final FurnitureService _instance = FurnitureService._internal();
  factory FurnitureService() => _instance;
  FurnitureService._internal();

  // Placed furniture (spot_id -> furniture_id)
  Map<String, String?> placedFurniture = {
    // BEDS (only 1)
    'bed_spot': null,

    // DESKS (multiple spots)
    'desk_spot': null,

    // CHAIRS (multiple spots)
    'chair_spot': null,

    // KITCHEN (only 1)
    'kitchen_spot': null,

    // DECORATIONS (multiple - can stack)
    'decoration_spot_1': null,
    'decoration_spot_2': null,
    'decoration_spot_3': null,
    'decoration_spot_4': null,
    'decoration_spot_5': null,
    'decoration_spot_6': null,
  };

  Set<String> ownedFurniture = {};

  // All furniture
  final List<Furniture> allFurniture = [
    // ========== BEDS (Only 1 at a time) ==========
    Furniture(
      id: 'hay_bed',
      name: 'Hay Bed',
      emoji: '🛏️',
      description: '+10% peas',
      cost: 20,
      boost: 0.10,
      category: FurnitureCategory.bed,
    ),
    Furniture(
      id: 'simple_cot',
      name: 'Simple Cot',
      emoji: '🛏️',
      description: '+20% peas',
      cost: 50,
      boost: 0.25,
      category: FurnitureCategory.bed,
    ),
    Furniture(
      id: 'wood_bed',
      name: 'Wood Frame Bed',
      emoji: '🛏️',
      description: '+35% peas',
      cost: 100,
      boost: 0.35,
      category: FurnitureCategory.bed,
    ),

    // ========== DESKS ==========
    Furniture(
      id: 'simple_desk',
      name: 'Simple Desk',
      emoji: '📚', // ← CHANGED from 🪑
      description: '+8% peas',
      cost: 30,
      boost: 0.08,
      category: FurnitureCategory.desk,
    ),
    Furniture(
      id: 'oak_desk',
      name: 'Oak Desk',
      emoji: '📚', // ← CHANGED from 🪑
      description: '+15% peas',
      cost: 80,
      boost: 0.15,
      category: FurnitureCategory.desk,
    ),
    Furniture(
      id: 'executive_desk',
      name: 'Executive Desk',
      emoji: '📚', // ← CHANGED from 🪑
      description: '+40% peas',
      cost: 150,
      boost: 0.40,
      category: FurnitureCategory.desk,
    ),

    // ========== CHAIRS ==========
    Furniture(
      id: 'old_stool',
      name: 'Old Stool',
      emoji: '🪑',
      description: '+4 peas',
      cost: 15,
      boost: 0.04,
      category: FurnitureCategory.chair,
    ),
    Furniture(
      id: 'wooden_chair',
      name: 'Wooden Chair',
      emoji: '🪑',
      description: '+15% peas',
      cost: 40,
      boost: 0.15,
      category: FurnitureCategory.chair,
    ),
    Furniture(
      id: 'comfy_chair',
      name: 'Comfy Chair',
      emoji: '🪑',
      description: '+25% peas',
      cost: 90,
      boost: 0.25,
      category: FurnitureCategory.chair,
    ),

    // ========== KITCHEN ==========
    Furniture(
      id: 'campfire',
      name: 'Campfire',
      emoji: '🔥',
      description: '+15% peas',
      cost: 25,
      boost: 0.15,
      category: FurnitureCategory.kitchen,
    ),
    Furniture(
      id: 'simple_stove',
      name: 'Simple Stove',
      emoji: '🍳',
      description: '+30% peas',
      cost: 60,
      boost: 0.30,
      category: FurnitureCategory.kitchen,
    ),
    Furniture(
      id: 'wood_stove',
      name: 'Wood Stove',
      emoji: '🍳',
      description: '+6% peas',
      cost: 120,
      boost: 0.45,
      category: FurnitureCategory.kitchen,
    ),

    // ========== DECORATIONS (Can have multiple) ==========
    Furniture(
      id: 'hanging_plant',
      name: 'Hanging Plant',
      emoji: '🌿',
      description: '+9% peas',
      cost: 20,
      boost: 0.9,
      category: FurnitureCategory.decoration,
    ),
    Furniture(
      id: 'wall_torch',
      name: 'Wall Torch',
      emoji: '🔥',
      description: '+14% peas',
      cost: 30,
      boost: 0.14,
      category: FurnitureCategory.decoration,
    ),
    Furniture(
      id: 'simple_painting',
      name: 'Simple Painting',
      emoji: '🖼️',
      description: '+20% peas',
      cost: 50,
      boost: 0.20,
      category: FurnitureCategory.decoration,
    ),
    Furniture(
      id: 'wall_crystal',
      name: 'Wall Crystal',
      emoji: '💎',
      description: '+35% peas',
      cost: 120,
      boost: 0.35,
      category: FurnitureCategory.decoration,
    ),
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

  Furniture? getPlacedFurniture(String spotId) {
    String? furnitureId = placedFurniture[spotId];
    if (furnitureId == null) return null;
    return getFurnitureById(furnitureId);
  }

  List<Furniture> getFurnitureByCategory(FurnitureCategory category) {
    return allFurniture.where((f) => f.category == category).toList();
  }

  bool isSpotEmpty(String spotId) {
    return placedFurniture[spotId] == null;
  }

  // Place furniture (different logic for beds vs others)
  Future<bool> placeFurnitureInSpot(String spotId, String furnitureId, int currentCoins) async {
    if (!placedFurniture.containsKey(spotId)) return false;

    Furniture? furniture = getFurnitureById(furnitureId);
    if (furniture == null) return false;
    if (currentCoins < furniture.cost) return false;

    // For beds: replace any existing bed
    if (furniture.category == FurnitureCategory.bed) {
      placedFurniture['bed_spot'] = furnitureId;
    } else {
      placedFurniture[spotId] = furnitureId;
    }

    await saveFurniture();
    return true;
  }

  // Find first empty spot for a category
  String? findEmptySpot(FurnitureCategory category) {
    switch (category) {
      case FurnitureCategory.bed:
        return placedFurniture['bed_spot'] == null ? 'bed_spot' : null;

      case FurnitureCategory.desk:
        return placedFurniture['desk_spot'] == null ? 'desk_spot' : null;  // ← CHECK THIS!

      case FurnitureCategory.chair:
        return placedFurniture['chair_spot'] == null ? 'chair_spot' : null;

      case FurnitureCategory.kitchen:
        return placedFurniture['kitchen_spot'] == null ? 'kitchen_spot' : null;

      case FurnitureCategory.decoration:
        for (int i = 1; i <= 6; i++) {
          String spot = 'decoration_spot_$i';
          if (placedFurniture[spot] == null) return spot;
        }
        return null;
    }
  }

  Future<void> removeFurniture(String spotId) async {
    if (placedFurniture.containsKey(spotId)) {
      placedFurniture[spotId] = null;
      await saveFurniture();
    }
  }

  double getTotalBoost() {
    double total = 0.0;
    for (String? furnitureId in placedFurniture.values) {
      if (furnitureId != null) {
        Furniture? furniture = getFurnitureById(furnitureId);
        if (furniture != null) {
          total += furniture.boost;
        }
      }
    }
    return total;
  }

  String getBoostString() {
    double boost = getTotalBoost();
    if (boost == 0) return "No furniture bonus";
    return "+${(boost * 100).toStringAsFixed(0)}%";
  }

  Future<void> saveFurniture() async {
    final prefs = await SharedPreferences.getInstance();

    // Save placed furniture
    Map<String, String> saveData = {};
    placedFurniture.forEach((spotId, furnitureId) {
      if (furnitureId != null) {
        saveData[spotId] = furnitureId;
      }
    });
    await prefs.setString('placed_furniture', json.encode(saveData));

    // Save owned furniture - NEW!
    await prefs.setStringList('owned_furniture', ownedFurniture.toList());
  }

  Future<void> loadFurniture() async {
    final prefs = await SharedPreferences.getInstance();

    // Load placed furniture
    String? savedData = prefs.getString('placed_furniture');
    if (savedData != null) {
      try {
        Map<String, dynamic> loadedData = json.decode(savedData);
        placedFurniture.updateAll((key, value) => null);
        loadedData.forEach((spotId, furnitureId) {
          if (placedFurniture.containsKey(spotId)) {
            placedFurniture[spotId] = furnitureId.toString();
          }
        });
      } catch (e) {
        print('Error loading furniture: $e');
      }
    }

    // Load owned furniture - NEW!
    List<String>? ownedList = prefs.getStringList('owned_furniture');
    if (ownedList != null) {
      ownedFurniture = ownedList.toSet();
    }
  }

  Future<void> reset() async {
    placedFurniture.updateAll((key, value) => null);
    await saveFurniture();
  }
}