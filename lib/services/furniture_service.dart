import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

enum FurnitureType {
  bed,
  desk,
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
  final FurnitureType type;
  final int requiredHouseTier; // 0 = cave, 1 = cabin, etc.

  Furniture({
    required this.id,
    required this.name,
    required this.emoji,
    required this.description,
    required this.cost,
    required this.boost,
    required this.type,
    this.requiredHouseTier = 0,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'emoji': emoji,
    'description': description,
    'cost': cost,
    'boost': boost,
    'type': type.toString(),
    'requiredHouseTier': requiredHouseTier,
  };
}

class FurnitureSpot {
  final String id;
  final FurnitureType type;
  String? placedFurnitureId; // null = empty spot

  FurnitureSpot({
    required this.id,
    required this.type,
    this.placedFurnitureId,
  });

  bool get isEmpty => placedFurnitureId == null;
  bool get hasItem => placedFurnitureId != null;
}

class FurnitureService {
  static final FurnitureService _instance = FurnitureService._internal();
  factory FurnitureService() => _instance;
  FurnitureService._internal();

  // All available furniture in the game
  final List<Furniture> allFurniture = [
    // ========== BEDS (Better sleep = boost) ==========
    Furniture(
      id: 'hay_bed',
      name: 'Hay Bed',
      emoji: '🛏️',
      description: '+3% boost',
      cost: 20,
      boost: 0.03,
      type: FurnitureType.bed,
      requiredHouseTier: 0,
    ),
    Furniture(
      id: 'simple_cot',
      name: 'Simple Cot',
      emoji: '🛏️',
      description: '+5% boost',
      cost: 50,
      boost: 0.05,
      type: FurnitureType.bed,
      requiredHouseTier: 0,
    ),
    Furniture(
      id: 'wood_bed',
      name: 'Wood Frame Bed',
      emoji: '🛏️',
      description: '+8% boost',
      cost: 100,
      boost: 0.08,
      type: FurnitureType.bed,
      requiredHouseTier: 1, // Requires cabin
    ),

    // ========== DESKS (Focus space = boost) ==========
    Furniture(
      id: 'old_stool',
      name: 'Old Stool',
      emoji: '🪑',
      description: '+2% boost',
      cost: 15,
      boost: 0.02,
      type: FurnitureType.desk,
      requiredHouseTier: 0,
    ),
    Furniture(
      id: 'wooden_bench',
      name: 'Wooden Bench',
      emoji: '🪑',
      description: '+3% boost',
      cost: 40,
      boost: 0.03,
      type: FurnitureType.desk,
      requiredHouseTier: 0,
    ),
    Furniture(
      id: 'simple_desk',
      name: 'Simple Desk',
      emoji: '🪑',
      description: '+5% boost',
      cost: 80,
      boost: 0.05,
      type: FurnitureType.desk,
      requiredHouseTier: 1, // Requires cabin
    ),

    // ========== KITCHEN (Energy = boost) ==========
    Furniture(
      id: 'campfire',
      name: 'Campfire',
      emoji: '🔥',
      description: '+2% boost',
      cost: 25,
      boost: 0.02,
      type: FurnitureType.kitchen,
      requiredHouseTier: 0,
    ),
    Furniture(
      id: 'simple_stove',
      name: 'Simple Stove',
      emoji: '🍳',
      description: '+4% boost',
      cost: 60,
      boost: 0.04,
      type: FurnitureType.kitchen,
      requiredHouseTier: 0,
    ),
    Furniture(
      id: 'wood_stove',
      name: 'Wood Stove',
      emoji: '🍳',
      description: '+6% boost',
      cost: 120,
      boost: 0.06,
      type: FurnitureType.kitchen,
      requiredHouseTier: 1, // Requires cabin
    ),

    // ========== DECORATIONS (Comfort = boost) ==========
    Furniture(
      id: 'small_plant',
      name: 'Small Plant',
      emoji: '🪴',
      description: '+1% boost',
      cost: 10,
      boost: 0.01,
      type: FurnitureType.decoration,
      requiredHouseTier: 0,
    ),
    Furniture(
      id: 'torch',
      name: 'Wall Torch',
      emoji: '🔦',
      description: '+2% boost',
      cost: 20,
      boost: 0.02,
      type: FurnitureType.decoration,
      requiredHouseTier: 0,
    ),
    Furniture(
      id: 'painting',
      name: 'Simple Painting',
      emoji: '🖼️',
      description: '+3% boost',
      cost: 45,
      boost: 0.03,
      type: FurnitureType.decoration,
      requiredHouseTier: 0,
    ),
  ];

  // Furniture spots in the cave
  final List<FurnitureSpot> spots = [
    FurnitureSpot(id: 'bed_spot', type: FurnitureType.bed),
    FurnitureSpot(id: 'desk_spot', type: FurnitureType.desk),
    FurnitureSpot(id: 'kitchen_spot', type: FurnitureType.kitchen),
    FurnitureSpot(id: 'decoration_spot', type: FurnitureType.decoration),
  ];

  /// Initialize - Load saved furniture placements
  Future<void> init() async {
    await loadPlacements();
  }

  /// Get all furniture of a specific type
  List<Furniture> getFurnitureByType(FurnitureType type, {int houseTier = 0}) {
    return allFurniture
        .where((f) => f.type == type && f.requiredHouseTier <= houseTier)
        .toList();
  }

  /// Get furniture by ID
  Furniture? getFurnitureById(String id) {
    try {
      return allFurniture.firstWhere((f) => f.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get spot by ID
  FurnitureSpot? getSpotById(String id) {
    try {
      return spots.firstWhere((s) => s.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get spot by type
  FurnitureSpot? getSpotByType(FurnitureType type) {
    try {
      return spots.firstWhere((s) => s.type == type);
    } catch (e) {
      return null;
    }
  }

  /// Place furniture in a spot
  Future<bool> placeFurniture(String spotId, String furnitureId, int currentCoins) async {
    FurnitureSpot? spot = getSpotById(spotId);
    Furniture? furniture = getFurnitureById(furnitureId);

    if (spot == null || furniture == null) return false;
    if (spot.type != furniture.type) return false; // Wrong type for this spot
    if (currentCoins < furniture.cost) return false; // Can't afford

    spot.placedFurnitureId = furnitureId;
    await savePlacements();
    return true;
  }

  /// Remove furniture from a spot
  Future<void> removeFurniture(String spotId) async {
    FurnitureSpot? spot = getSpotById(spotId);
    if (spot != null) {
      spot.placedFurnitureId = null;
      await savePlacements();
    }
  }
  /// Upgrade furniture (remove old, place new)
  /// Upgrade furniture (remove old, place new)
  Future<bool> upgradeFurniture(String spotId, String newFurnitureId, int currentCoins) async {
    FurnitureSpot? spot = getSpotById(spotId);
    Furniture? furniture = getFurnitureById(newFurnitureId);

    if (spot == null || furniture == null) return false;
    if (currentCoins < furniture.cost) return false;

    // Place new furniture (replaces old automatically)
    spot.placedFurnitureId = newFurnitureId;
    await savePlacements();
    return true;
  }

  /// Get furniture placed in a spot
  Furniture? getPlacedFurniture(String spotId) {
    FurnitureSpot? spot = getSpotById(spotId);
    if (spot == null || spot.isEmpty) return null;
    return getFurnitureById(spot.placedFurnitureId!);
  }

  /// Calculate total boost from all placed furniture
  double getTotalBoost() {
    double total = 0.0;
    for (var spot in spots) {
      if (spot.hasItem) {
        Furniture? furniture = getFurnitureById(spot.placedFurnitureId!);
        if (furniture != null) {
          total += furniture.boost;
        }
      }
    }
    return total;
  }

  /// Get boost percentage string
  String getBoostString() {
    double boost = getTotalBoost() * 100;
    if (boost == 0) return "No bonus yet";
    return "+${boost.toStringAsFixed(0)}%";
  }

  /// Get multiplier for calculations (1.0 + boost)
  double getMultiplier() {
    return 1.0 + getTotalBoost();
  }

  /// Check if can afford furniture
  bool canAfford(Furniture furniture, int currentCoins) {
    return currentCoins >= furniture.cost;
  }

  /// Save furniture placements
  Future<void> savePlacements() async {
    final prefs = await SharedPreferences.getInstance();
    Map<String, String> placements = {};

    for (var spot in spots) {
      if (spot.hasItem) {
        placements[spot.id] = spot.placedFurnitureId!;
      }
    }

    await prefs.setString('furniture_placements', json.encode(placements));
  }

  /// Load furniture placements
  Future<void> loadPlacements() async {
    final prefs = await SharedPreferences.getInstance();
    String? savedData = prefs.getString('furniture_placements');

    if (savedData != null) {
      Map<String, dynamic> placements = json.decode(savedData);

      for (var spot in spots) {
        if (placements.containsKey(spot.id)) {
          spot.placedFurnitureId = placements[spot.id];
        }
      }
    }
  }

  /// Reset all furniture (for testing)
  Future<void> reset() async {
    for (var spot in spots) {
      spot.placedFurnitureId = null;
    }
    await savePlacements();
  }

  /// Get summary of placed furniture
  Map<String, int> getPlacementSummary() {
    Map<String, int> summary = {
      'total': 0,
      'beds': 0,
      'desks': 0,
      'kitchen': 0,
      'decorations': 0,
    };

    for (var spot in spots) {
      if (spot.hasItem) {
        summary['total'] = summary['total']! + 1;
        switch (spot.type) {
          case FurnitureType.bed:
            summary['beds'] = summary['beds']! + 1;
            break;
          case FurnitureType.desk:
            summary['desks'] = summary['desks']! + 1;
            break;
          case FurnitureType.kitchen:
            summary['kitchen'] = summary['kitchen']! + 1;
            break;
          case FurnitureType.decoration:
            summary['decorations'] = summary['decorations']! + 1;
            break;
        }
      }
    }

    return summary;
  }
}