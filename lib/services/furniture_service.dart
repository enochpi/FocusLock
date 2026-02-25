import 'package:focus_life/services/achievements_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:focus_life/services/upgrade_service.dart';

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
  final int stageRequired; // 0=cave, 1=shack, 2=house, 3=mansion

  final int upgradesRequired; // how many upgrades needed to unlock

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


  /// Get the Furniture object placed in a specific spot
  Furniture? getPlacedFurniture(String spotId) {
    final furnitureId = placedFurniture[spotId];
    if (furnitureId == null) return null;
    return getFurnitureById(furnitureId);

  }

  // Placed furniture (spot_id -> furniture_id)
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

  /// Get furniture filtered by stage
  List<Furniture> getFurnitureForStage(int stage) {
    return allFurniture.where((f) => f.stageRequired == stage).toList();
  }

  /// Get furniture for a specific stage and category
  List<Furniture> getFurnitureForStageAndCategory(int stage, FurnitureCategory category) {
    return allFurniture.where((f) => f.stageRequired == stage && f.category == category).toList();
  }

  // ════════════════════════════════════════════════════════════════
  //  ALL FURNITURE — 4 stages × (3 beds + 3 desks + 3 chairs +
  //                                3 kitchen + 8 decorations) = 80 items
  // ════════════════════════════════════════════════════════════════
  final List<Furniture> allFurniture = [

    // ╔══════════════════════════════════════════════════════════╗
    // ║  STAGE 0: CAVE — Primitive & Rustic                     ║
    // ║  Theme: Stone, hay, fire, raw materials                 ║
    // ║  Costs: 5–600 coins  |  Boosts: 4–40%                  ║
    // ╚══════════════════════════════════════════════════════════╝

    // ── Cave Beds ──
    Furniture(id: 'hay_pile', name: 'Hay Pile', emoji: '🛏️',
        description: '+15% peas', cost: 5, boost: 0.15,
        category: FurnitureCategory.bed, stageRequired: 0),
    Furniture(id: 'simple_cot', name: 'Simple Cot', emoji: '🛏️',
        description: '+25% peas', cost: 15, boost: 0.25,
        category: FurnitureCategory.bed, stageRequired: 0),
    Furniture(id: 'wood_bed', name: 'Wood Frame Bed', emoji: '🛌',
        description: '+40% peas', cost: 40, boost: 0.40,
        category: FurnitureCategory.bed, stageRequired: 0),

    // ── Cave Desks ──
    Furniture(id: 'rock_desk', name: 'Rock Desk', emoji: '📚',
        description: '+12% peas', cost: 8, boost: 0.12,
        category: FurnitureCategory.desk, stageRequired: 0),
    Furniture(id: 'wooden_desk', name: 'Wooden Desk', emoji: '📚',
        description: '+20% peas', cost: 20, boost: 0.20,
        category: FurnitureCategory.desk, stageRequired: 0),
    Furniture(id: 'sturdy_desk', name: 'Sturdy Desk', emoji: '📚',
        description: '+30% peas', cost: 50, boost: 0.30,
        category: FurnitureCategory.desk, stageRequired: 0),

    // ── Cave Chairs ──
    Furniture(id: 'tree_stump', name: 'Tree Stump', emoji: '🪵',
        description: '+10% peas', cost: 5, boost: 0.10,
        category: FurnitureCategory.chair, stageRequired: 0),
    Furniture(id: 'wooden_chair', name: 'Wooden Chair', emoji: '🪑',
        description: '+18% peas', cost: 15, boost: 0.18,
        category: FurnitureCategory.chair, stageRequired: 0),
    Furniture(id: 'comfy_chair', name: 'Comfy Chair', emoji: '🪑',
        description: '+25% peas', cost: 35, boost: 0.25,
        category: FurnitureCategory.chair, stageRequired: 0),

    // ── Cave Kitchen ──
    Furniture(id: 'small_fire', name: 'Small Fire', emoji: '🔥',
        description: '+15% peas', cost: 10, boost: 0.15,
        category: FurnitureCategory.kitchen, stageRequired: 0),
    Furniture(id: 'campfire', name: 'Campfire', emoji: '🔥',
        description: '+25% peas', cost: 25, boost: 0.25,
        category: FurnitureCategory.kitchen, stageRequired: 0),
    Furniture(id: 'stone_oven', name: 'Stone Oven', emoji: '🍳',
        description: '+35% peas', cost: 60, boost: 0.35,
        category: FurnitureCategory.kitchen, stageRequired: 0),

    // ── Cave Decorations (8) ──
    Furniture(id: 'small_rock', name: 'Small Rock', emoji: '🪨',
        description: '+5% peas', cost: 5, boost: 0.05,
        category: FurnitureCategory.decoration, stageRequired: 0),
    Furniture(id: 'moss_patch', name: 'Moss Patch', emoji: '🌿',
        description: '+8% peas', cost: 12, boost: 0.08,
        category: FurnitureCategory.decoration, stageRequired: 0),
    Furniture(id: 'wall_torch', name: 'Wall Torch', emoji: '🔦',
        description: '+12% peas', cost: 25, boost: 0.12,
        category: FurnitureCategory.decoration, stageRequired: 0),
    Furniture(id: 'cave_painting', name: 'Cave Painting', emoji: '🖼️',
        description: '+15% peas', cost: 50, boost: 0.15,
        category: FurnitureCategory.decoration, stageRequired: 0),
    Furniture(id: 'glowing_mushroom', name: 'Glowing Mushroom', emoji: '🍄',
        description: '+20% peas', cost: 100, boost: 0.20,
        category: FurnitureCategory.decoration, stageRequired: 0),
    Furniture(id: 'crystal_cluster', name: 'Crystal Cluster', emoji: '💎',
        description: '+25% peas', cost: 200, boost: 0.25,
        category: FurnitureCategory.decoration, stageRequired: 0),
    Furniture(id: 'ancient_artifact', name: 'Ancient Artifact', emoji: '🗿',
        description: '+30% peas', cost: 350, boost: 0.30,
        category: FurnitureCategory.decoration, stageRequired: 0),
    Furniture(id: 'enchanted_crystal', name: 'Enchanted Crystal', emoji: '✨',
        description: '+40% peas', cost: 600, boost: 0.40,
        category: FurnitureCategory.decoration, stageRequired: 0),

    // ╔══════════════════════════════════════════════════════════╗
    // ║  STAGE 1: SHACK — Country & Handmade                   ║
    // ║  Theme: Wood, iron, quilts, warmth                      ║
    // ║  Costs: 500–5,000 coins  |  Boosts: 20–60%             ║
    // ╚══════════════════════════════════════════════════════════╝

    // ── Shack Beds ──
    Furniture(id: 'shack_bunk', name: 'Bunk Bed', emoji: '🛏️',
        description: '+20% carrots', cost: 500, boost: 0.20,
        category: FurnitureCategory.bed, stageRequired: 1),
    Furniture(id: 'shack_quilted', name: 'Quilted Bed', emoji: '🛏️',
        description: '+35% carrots', cost: 1200, boost: 0.35,
        category: FurnitureCategory.bed, stageRequired: 1),
    Furniture(id: 'shack_feather', name: 'Feather Bed', emoji: '🛌',
        description: '+50% carrots', cost: 2800, boost: 0.50,
        category: FurnitureCategory.bed, stageRequired: 1),

    // ── Shack Desks ──
    Furniture(id: 'shack_workbench', name: 'Workbench', emoji: '🔨',
        description: '+18% carrots', cost: 400, boost: 0.18,
        category: FurnitureCategory.desk, stageRequired: 1),
    Furniture(id: 'shack_writing_desk', name: 'Writing Desk', emoji: '📝',
        description: '+28% carrots', cost: 1000, boost: 0.28,
        category: FurnitureCategory.desk, stageRequired: 1),
    Furniture(id: 'shack_craft_table', name: 'Craft Table', emoji: '🪚',
        description: '+42% carrots', cost: 2200, boost: 0.42,
        category: FurnitureCategory.desk, stageRequired: 1),

    // ── Shack Chairs ──
    Furniture(id: 'shack_rocking', name: 'Rocking Chair', emoji: '🪑',
        description: '+15% carrots', cost: 350, boost: 0.15,
        category: FurnitureCategory.chair, stageRequired: 1),
    Furniture(id: 'shack_cushioned', name: 'Cushioned Chair', emoji: '🪑',
        description: '+25% carrots', cost: 900, boost: 0.25,
        category: FurnitureCategory.chair, stageRequired: 1),
    Furniture(id: 'shack_armchair', name: 'Armchair', emoji: '🛋️',
        description: '+38% carrots', cost: 2000, boost: 0.38,
        category: FurnitureCategory.chair, stageRequired: 1),

    // ── Shack Kitchen ──
    Furniture(id: 'shack_woodstove', name: 'Wood Stove', emoji: '🪵',
        description: '+22% carrots', cost: 600, boost: 0.22,
        category: FurnitureCategory.kitchen, stageRequired: 1),
    Furniture(id: 'shack_iron_pot', name: 'Iron Cooking Pot', emoji: '🍲',
        description: '+33% carrots', cost: 1400, boost: 0.33,
        category: FurnitureCategory.kitchen, stageRequired: 1),
    Furniture(id: 'shack_brick_oven', name: 'Brick Oven', emoji: '🧱',
        description: '+48% carrots', cost: 3200, boost: 0.48,
        category: FurnitureCategory.kitchen, stageRequired: 1),

    // ── Shack Decorations (8) ──
    Furniture(id: 'shack_flower_pot', name: 'Flower Pot', emoji: '🌻',
        description: '+8% carrots', cost: 300, boost: 0.08,
        category: FurnitureCategory.decoration, stageRequired: 1),
    Furniture(id: 'shack_oil_lantern', name: 'Oil Lantern', emoji: '🏮',
        description: '+12% carrots', cost: 550, boost: 0.12,
        category: FurnitureCategory.decoration, stageRequired: 1),
    Furniture(id: 'shack_woven_rug', name: 'Woven Rug', emoji: '🧶',
        description: '+16% carrots', cost: 850, boost: 0.16,
        category: FurnitureCategory.decoration, stageRequired: 1),
    Furniture(id: 'shack_bookshelf', name: 'Small Bookshelf', emoji: '📚',
        description: '+20% carrots', cost: 1200, boost: 0.20,
        category: FurnitureCategory.decoration, stageRequired: 1),
    Furniture(id: 'shack_cuckoo_clock', name: 'Cuckoo Clock', emoji: '🕰️',
        description: '+25% carrots', cost: 1800, boost: 0.25,
        category: FurnitureCategory.decoration, stageRequired: 1),
    Furniture(id: 'shack_quilt', name: 'Handmade Quilt', emoji: '🧵',
        description: '+30% carrots', cost: 2500, boost: 0.30,
        category: FurnitureCategory.decoration, stageRequired: 1),
    Furniture(id: 'shack_wind_chime', name: 'Wind Chime', emoji: '🎐',
        description: '+38% carrots', cost: 3500, boost: 0.38,
        category: FurnitureCategory.decoration, stageRequired: 1),
    Furniture(id: 'shack_grandfather_clock', name: 'Grandfather Clock', emoji: '⏰',
        description: '+50% carrots', cost: 5000, boost: 0.50,
        category: FurnitureCategory.decoration, stageRequired: 1),

    // ╔══════════════════════════════════════════════════════════╗
    // ║  STAGE 2: HOUSE — Modern & Comfortable                  ║
    // ║  Theme: Clean lines, tech, comfort                      ║
    // ║  Costs: 3,000–30,000 coins  |  Boosts: 30–80%          ║
    // ╚══════════════════════════════════════════════════════════╝

    // ── House Beds ──
    Furniture(id: 'house_twin', name: 'Twin Bed', emoji: '🛏️',
        description: '+30% corn', cost: 3000, boost: 0.30,
        category: FurnitureCategory.bed, stageRequired: 2),
    Furniture(id: 'house_queen', name: 'Queen Bed', emoji: '🛏️',
        description: '+50% corn', cost: 8000, boost: 0.50,
        category: FurnitureCategory.bed, stageRequired: 2),
    Furniture(id: 'house_king', name: 'King Bed', emoji: '🛌',
        description: '+70% corn', cost: 18000, boost: 0.70,
        category: FurnitureCategory.bed, stageRequired: 2),

    // ── House Desks ──
    Furniture(id: 'house_office_desk', name: 'Office Desk', emoji: '💼',
        description: '+25% corn', cost: 2500, boost: 0.25,
        category: FurnitureCategory.desk, stageRequired: 2),
    Furniture(id: 'house_standing_desk', name: 'Standing Desk', emoji: '🖥️',
        description: '+40% corn', cost: 7000, boost: 0.40,
        category: FurnitureCategory.desk, stageRequired: 2),
    Furniture(id: 'house_corner_desk', name: 'L-Shape Corner Desk', emoji: '📐',
        description: '+60% corn', cost: 16000, boost: 0.60,
        category: FurnitureCategory.desk, stageRequired: 2),

    // ── House Chairs ──
    Furniture(id: 'house_office_chair', name: 'Office Chair', emoji: '🪑',
        description: '+22% corn', cost: 2200, boost: 0.22,
        category: FurnitureCategory.chair, stageRequired: 2),
    Furniture(id: 'house_recliner', name: 'Leather Recliner', emoji: '🛋️',
        description: '+38% corn', cost: 6500, boost: 0.38,
        category: FurnitureCategory.chair, stageRequired: 2),
    Furniture(id: 'house_massage_chair', name: 'Massage Chair', emoji: '💆',
        description: '+55% corn', cost: 14000, boost: 0.55,
        category: FurnitureCategory.chair, stageRequired: 2),

    // ── House Kitchen ──
    Furniture(id: 'house_modern_stove', name: 'Modern Stove', emoji: '🍳',
        description: '+28% corn', cost: 3500, boost: 0.28,
        category: FurnitureCategory.kitchen, stageRequired: 2),
    Furniture(id: 'house_kitchen_island', name: 'Kitchen Island', emoji: '🏝️',
        description: '+45% corn', cost: 9000, boost: 0.45,
        category: FurnitureCategory.kitchen, stageRequired: 2),
    Furniture(id: 'house_chef_kitchen', name: 'Chef\'s Kitchen', emoji: '👨‍🍳',
        description: '+65% corn', cost: 20000, boost: 0.65,
        category: FurnitureCategory.kitchen, stageRequired: 2),

    // ── House Decorations (8) ──
    Furniture(id: 'house_plant', name: 'Potted Plant', emoji: '🪴',
        description: '+12% corn', cost: 2000, boost: 0.12,
        category: FurnitureCategory.decoration, stageRequired: 2),
    Furniture(id: 'house_smart_speaker', name: 'Smart Speaker', emoji: '🔊',
        description: '+18% corn', cost: 3500, boost: 0.18,
        category: FurnitureCategory.decoration, stageRequired: 2),
    Furniture(id: 'house_painting', name: 'Modern Painting', emoji: '🎨',
        description: '+24% corn', cost: 5500, boost: 0.24,
        category: FurnitureCategory.decoration, stageRequired: 2),
    Furniture(id: 'house_aquarium', name: 'Fish Aquarium', emoji: '🐠',
        description: '+32% corn', cost: 8000, boost: 0.32,
        category: FurnitureCategory.decoration, stageRequired: 2),
    Furniture(id: 'house_fireplace', name: 'Electric Fireplace', emoji: '🔥',
        description: '+40% corn', cost: 12000, boost: 0.40,
        category: FurnitureCategory.decoration, stageRequired: 2),
    Furniture(id: 'house_home_theater', name: 'Home Theater', emoji: '📺',
        description: '+50% corn', cost: 17000, boost: 0.50,
        category: FurnitureCategory.decoration, stageRequired: 2),
    Furniture(id: 'house_wine_rack', name: 'Wine Collection', emoji: '🍷',
        description: '+60% corn', cost: 22000, boost: 0.60,
        category: FurnitureCategory.decoration, stageRequired: 2),
    Furniture(id: 'house_chandelier', name: 'Crystal Chandelier', emoji: '💡',
        description: '+75% corn', cost: 30000, boost: 0.75,
        category: FurnitureCategory.decoration, stageRequired: 2),

    // ╔══════════════════════════════════════════════════════════╗
    // ║  STAGE 3: MANSION — Luxury & Grand                      ║
    // ║  Theme: Gold, marble, rare artifacts                    ║
    // ║  Costs: 20,000–200,000 coins  |  Boosts: 50–120%       ║
    // ╚══════════════════════════════════════════════════════════╝

    // ── Mansion Beds ──
    Furniture(id: 'mansion_canopy', name: 'Canopy Bed', emoji: '🛏️',
        description: '+50% strawberries', cost: 20000, boost: 0.50,
        category: FurnitureCategory.bed, stageRequired: 3),
    Furniture(id: 'mansion_emperor', name: 'Emperor Bed', emoji: '👑',
        description: '+75% strawberries', cost: 55000, boost: 0.75,
        category: FurnitureCategory.bed, stageRequired: 3),
    Furniture(id: 'mansion_floating', name: 'Floating Bed', emoji: '🛸',
        description: '+100% strawberries', cost: 120000, boost: 1.00,
        category: FurnitureCategory.bed, stageRequired: 3),

    // ── Mansion Desks ──
    Furniture(id: 'mansion_mahogany', name: 'Mahogany Desk', emoji: '🪵',
        description: '+40% strawberries', cost: 18000, boost: 0.40,
        category: FurnitureCategory.desk, stageRequired: 3),
    Furniture(id: 'mansion_presidential', name: 'Presidential Desk', emoji: '🏛️',
        description: '+65% strawberries', cost: 48000, boost: 0.65,
        category: FurnitureCategory.desk, stageRequired: 3),
    Furniture(id: 'mansion_holographic', name: 'Holographic Desk', emoji: '🔮',
        description: '+90% strawberries', cost: 100000, boost: 0.90,
        category: FurnitureCategory.desk, stageRequired: 3),

    // ── Mansion Chairs ──
    Furniture(id: 'mansion_throne', name: 'Golden Throne', emoji: '🪑',
        description: '+35% strawberries', cost: 15000, boost: 0.35,
        category: FurnitureCategory.chair, stageRequired: 3),
    Furniture(id: 'mansion_zero_gravity', name: 'Zero Gravity Chair', emoji: '🧘',
        description: '+55% strawberries', cost: 42000, boost: 0.55,
        category: FurnitureCategory.chair, stageRequired: 3),
    Furniture(id: 'mansion_diamond', name: 'Diamond Throne', emoji: '💎',
        description: '+80% strawberries', cost: 90000, boost: 0.80,
        category: FurnitureCategory.chair, stageRequired: 3),

    // ── Mansion Kitchen ──
    Furniture(id: 'mansion_gourmet', name: 'Gourmet Kitchen', emoji: '🍽️',
        description: '+45% strawberries', cost: 22000, boost: 0.45,
        category: FurnitureCategory.kitchen, stageRequired: 3),
    Furniture(id: 'mansion_michelin', name: 'Michelin Kitchen', emoji: '⭐',
        description: '+70% strawberries', cost: 58000, boost: 0.70,
        category: FurnitureCategory.kitchen, stageRequired: 3),
    Furniture(id: 'mansion_molecular', name: 'Molecular Kitchen', emoji: '🧪',
        description: '+100% strawberries', cost: 130000, boost: 1.00,
        category: FurnitureCategory.kitchen, stageRequired: 3),

    // ── Mansion Decorations (8) ──
    Furniture(id: 'mansion_sculpture', name: 'Marble Sculpture', emoji: '🗿',
        description: '+20% strawberries', cost: 15000, boost: 0.20,
        category: FurnitureCategory.decoration, stageRequired: 3),
    Furniture(id: 'mansion_grand_piano', name: 'Grand Piano', emoji: '🎹',
        description: '+30% strawberries', cost: 25000, boost: 0.30,
        category: FurnitureCategory.decoration, stageRequired: 3),
    Furniture(id: 'mansion_fountain', name: 'Indoor Fountain', emoji: '⛲',
        description: '+40% strawberries', cost: 38000, boost: 0.40,
        category: FurnitureCategory.decoration, stageRequired: 3),
    Furniture(id: 'mansion_art_gallery', name: 'Art Gallery Wall', emoji: '🎨',
        description: '+55% strawberries', cost: 55000, boost: 0.55,
        category: FurnitureCategory.decoration, stageRequired: 3),
    Furniture(id: 'mansion_observatory', name: 'Mini Observatory', emoji: '🔭',
        description: '+70% strawberries', cost: 75000, boost: 0.70,
        category: FurnitureCategory.decoration, stageRequired: 3),
    Furniture(id: 'mansion_infinity_pool', name: 'Infinity Pool', emoji: '🏊',
        description: '+85% strawberries', cost: 100000, boost: 0.85,
        category: FurnitureCategory.decoration, stageRequired: 3),
    Furniture(id: 'mansion_gold_vault', name: 'Gold Vault', emoji: '🏦',
        description: '+100% strawberries', cost: 140000, boost: 1.00,
        category: FurnitureCategory.decoration, stageRequired: 3),
    Furniture(id: 'mansion_wishing_well', name: 'Enchanted Wishing Well', emoji: '🌟',
        description: '+120% strawberries', cost: 200000, boost: 1.20,
        category: FurnitureCategory.decoration, stageRequired: 3),
  ];

  // ════════════════════════════════════════════
  //  EXISTING METHODS — unchanged below
  // ════════════════════════════════════════════

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

  /// Check if furniture is unlocked (has enough upgrades purchased)
  bool isFurnitureUnlocked(String furnitureId) {
    final furniture = getFurnitureById(furnitureId);
    if (furniture == null) return false;

    final totalUpgrades = UpgradeService().getTotalUpgradesPurchased();
    return totalUpgrades >= furniture.upgradesRequired;
  }

  /// Get list of furniture that just unlocked (for notifications)
  List<Furniture> getNewlyUnlockedFurniture(int oldUpgradeCount, int newUpgradeCount) {
    List<Furniture> newlyUnlocked = [];

    for (var furniture in allFurniture) {
      // Was locked before, now unlocked
      if (furniture.upgradesRequired > oldUpgradeCount &&
          furniture.upgradesRequired <= newUpgradeCount) {
        newlyUnlocked.add(furniture);
      }
    }

    return newlyUnlocked;
  }

  /// Get furniture filtered by stage AND unlock status
  List<Furniture> getAvailableFurnitureForStage(int stage) {
    return allFurniture
        .where((f) => f.stageRequired == stage && isFurnitureUnlocked(f.id))
        .toList();
  }

  /// Get locked furniture for stage (to show in shop with lock icon)
  List<Furniture> getLockedFurnitureForStage(int stage) {
    return allFurniture
        .where((f) => f.stageRequired == stage && !isFurnitureUnlocked(f.id))
        .toList();
  }

  /// Get the spot a placed furniture is in
  String? getPlacedSpot(String furnitureId) {
    for (var entry in placedFurniture.entries) {
      if (entry.value == furnitureId) return entry.key;
    }
    return null;
  }

  /// Find empty spot for a category
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

  /// Place furniture in a spot (auto-swap for single-slot categories)
  void placeFurniture(String furnitureId) {
    final furniture = getFurnitureById(furnitureId);
    if (furniture == null) return;

    // For single-slot categories, remove old one first
    if (furniture.category != FurnitureCategory.decoration) {
      final spot = findEmptySpot(furniture.category)!;
      // Clear current if occupied
      placedFurniture[spot] = furnitureId;
    } else {
      // Find empty decoration spot
      final spot = findEmptySpot(furniture.category);
      if (spot != null) {
        placedFurniture[spot] = furnitureId;
      }
    }
    saveFurniture();
  }

  /// Remove furniture from its spot
  void removeFurniture(String furnitureId) {
    final spot = getPlacedSpot(furnitureId);
    if (spot != null) {
      placedFurniture[spot] = null;
      saveFurniture();
    }
  }

  /// Buy furniture
  /// Buy furniture
  Future<bool> buyFurniture(String furnitureId) async {  // ✅ ADD async
    if (!ownedFurniture.contains(furnitureId)) {
      ownedFurniture.add(furnitureId);
      await saveFurniture();  // ✅ ADD await
      await _achievementService.onFurniturePurchased();
      return true;
    }
    return false;
  }

  /// Get total boost from ALL placed furniture (across ALL stages)
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

  /// Get boost multiplier (1.0 + total boost)
  double getBoostMultiplier() => 1.0 + getTotalBoost();

  /// Get boost as display string
  String getBoostString() {
    final boost = getTotalBoost();
    if (boost == 0) return 'No boost';
    return '+${(boost * 100).toStringAsFixed(0)}% (${getBoostMultiplier().toStringAsFixed(2)}x)';
  }

  /// Save to SharedPreferences
  Future<void> saveFurniture() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('owned_furniture', ownedFurniture.toList());
    await prefs.setString('placed_furniture', json.encode(placedFurniture));
  }

  /// Load from SharedPreferences
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

  /// Reset all furniture
  Future<void> reset() async {
    ownedFurniture.clear();
    for (var key in placedFurniture.keys) {
      placedFurniture[key] = null;
    }
    await saveFurniture();
  }
}