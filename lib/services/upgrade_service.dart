import 'package:shared_preferences/shared_preferences.dart';

class Upgrade {
  final String id;
  final String name;
  final String emoji;
  final String description;
  final double cost; // ← CHANGED FROM int TO double
  final double multiplier;
  final int stageRequired; // ← ADDED THIS FIELD
  bool isPurchased;

  Upgrade({
    required this.id,
    required this.name,
    required this.emoji,
    required this.description,
    required this.cost,
    required this.multiplier,
    this.stageRequired = 0, // ← DEFAULT VALUE
    this.isPurchased = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'isPurchased': isPurchased,
  };

  static Upgrade fromJson(Map<String, dynamic> json, Upgrade template) {
    return Upgrade(
      id: template.id,
      name: template.name,
      emoji: template.emoji,
      description: template.description,
      cost: template.cost,
      multiplier: template.multiplier,
      stageRequired: template.stageRequired,
      isPurchased: json['isPurchased'] ?? false,
    );
  }
}
class HouseUnlock {
  final String id;
  final String name;
  final String emoji;
  final String description;
  final double cost;
  final int unlocksStage;
  final double houseMultiplier; // ← NEW! Huge bonus when you buy a house
  bool isPurchased;

  HouseUnlock({
    required this.id,
    required this.name,
    required this.emoji,
    required this.description,
    required this.cost,
    required this.unlocksStage,
    this.houseMultiplier = 1.0,
    this.isPurchased = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'isPurchased': isPurchased,
  };

  static HouseUnlock fromJson(Map<String, dynamic> json, HouseUnlock template) {
    return HouseUnlock(
      id: template.id,
      name: template.name,
      emoji: template.emoji,
      description: template.description,
      cost: template.cost,
      unlocksStage: template.unlocksStage,
      houseMultiplier: template.houseMultiplier,
      isPurchased: json['isPurchased'] ?? false,
    );
  }
}

class UpgradeService {
  static final UpgradeService _instance = UpgradeService._internal();
  factory UpgradeService() => _instance;
  UpgradeService._internal();

  int _currentStage = 0;


  List<Upgrade> _upgrades = [
    // ========================================
    // STAGE 0: CAVE SHOP — UNCHANGED
    // ========================================
    Upgrade(id: 'cave_hoe', name: 'Basic Hoe', emoji: '⛏️', description: '2.10x per focus', cost: 100, multiplier: 1.10, stageRequired: 0),
    Upgrade(id: 'cave_seeds', name: 'Good Seeds', emoji: '🌱', description: '1.88x per focus', cost: 300, multiplier: 0.88, stageRequired: 0),
    Upgrade(id: 'cave_bucket', name: 'Water Bucket', emoji: '🪣', description: '1.66x per focus', cost: 800, multiplier: 0.66, stageRequired: 0),
    Upgrade(id: 'cave_tools', name: 'Sharp Tools', emoji: '🔨', description: '1.55x per focus', cost: 2000, multiplier: 0.55, stageRequired: 0),
    Upgrade(id: 'cave_fertilizer', name: 'Fertilizer', emoji: '🌿', description: '1.44x per focus', cost: 5000, multiplier: 0.44, stageRequired: 0),
    Upgrade(id: 'cave_watering', name: 'Watering Can', emoji: '💧', description: '1.39x per focus', cost: 12000, multiplier: 0.39, stageRequired: 0),
    Upgrade(id: 'cave_soil', name: 'Rich Soil', emoji: '🪴', description: '1.33x per focus', cost: 28000, multiplier: 0.33, stageRequired: 0),
    Upgrade(id: 'cave_compost', name: 'Compost', emoji: '♻️', description: '1.28x per focus', cost: 65000, multiplier: 0.28, stageRequired: 0),
    Upgrade(id: 'cave_greenhouse', name: 'Tiny Greenhouse', emoji: '🏡', description: '1.22x per focus', cost: 150000, multiplier: 0.22, stageRequired: 0),
    Upgrade(id: 'cave_irrigation', name: 'Basic Irrigation', emoji: '💦', description: '1.17x per focus', cost: 350000, multiplier: 0.17, stageRequired: 0),

    // ========================================
    // STAGE 1: SHACK — 50% mult cut, 47% cost cut
    // ========================================
    Upgrade(id: 'shack_advanced_hoe', name: 'Advanced Hoe', emoji: '⚒️', description: '1.50x per focus', cost: 143000, multiplier: 0.50, stageRequired: 1),
    Upgrade(id: 'shack_premium_seeds', name: 'Premium Seeds', emoji: '🌾', description: '1.33x per focus', cost: 322000, multiplier: 0.33, stageRequired: 1),
    Upgrade(id: 'shack_sprinklers', name: 'Sprinkler System', emoji: '🚿', description: '1.27x per focus', cost: 716000, multiplier: 0.27, stageRequired: 1),
    Upgrade(id: 'shack_pro_tools', name: 'Professional Tools', emoji: '🔧', description: '1.23x per focus', cost: 1550000, multiplier: 0.23, stageRequired: 1),
    Upgrade(id: 'shack_super_fertilizer', name: 'Super Fertilizer', emoji: '🧪', description: '1.20x per focus', cost: 3580000, multiplier: 0.20, stageRequired: 1),
    Upgrade(id: 'shack_auto_water', name: 'Auto Watering', emoji: '⚡', description: '1.17x per focus', cost: 7870000, multiplier: 0.17, stageRequired: 1),
    Upgrade(id: 'shack_premium_soil', name: 'Premium Soil Mix', emoji: '🌱', description: '1.15x per focus', cost: 17900000, multiplier: 0.15, stageRequired: 1),
    Upgrade(id: 'shack_biotech', name: 'Bio-Technology', emoji: '🧬', description: '1.13x per focus', cost: 39400000, multiplier: 0.13, stageRequired: 1),
    Upgrade(id: 'shack_climate', name: 'Climate Control', emoji: '🌡️', description: '1.12x per focus', cost: 89400000, multiplier: 0.12, stageRequired: 1),
    Upgrade(id: 'shack_hydroponics', name: 'Hydroponic System', emoji: '💧', description: '1.10x per focus', cost: 200000000, multiplier: 0.10, stageRequired: 1),
    Upgrade(id: 'shack_led_grow', name: 'LED Grow Lights', emoji: '💡', description: '1.09x per focus', cost: 451000000, multiplier: 0.09, stageRequired: 1),
    Upgrade(id: 'shack_ph_optimizer', name: 'pH Optimizer', emoji: '🔬', description: '1.07x per focus', cost: 1000000000, multiplier: 0.07, stageRequired: 1),
    Upgrade(id: 'shack_nutrient_mix', name: 'Nutrient Mix System', emoji: '🧫', description: '1.06x per focus', cost: 2270000000, multiplier: 0.06, stageRequired: 1),
    Upgrade(id: 'shack_smart_sensors', name: 'Smart Sensors', emoji: '📡', description: '1.05x per focus', cost: 5130000000, multiplier: 0.05, stageRequired: 1),
    Upgrade(id: 'shack_master_gardener', name: 'Master Gardener Training', emoji: '👨‍🌾', description: '1.04x per focus', cost: 11400000000, multiplier: 0.04, stageRequired: 1),

    // ========================================
    // STAGE 2: HOUSE — 50% mult cut, 44% cost cut
    // ========================================
    Upgrade(id: 'house_quantum_hoe', name: 'Quantum Hoe', emoji: '⚛️', description: '1.40x per focus', cost: 25200000000, multiplier: 0.40, stageRequired: 2),
    Upgrade(id: 'house_genetic_seeds', name: 'Genetically Modified Seeds', emoji: '🔬', description: '1.30x per focus', cost: 54600000000, multiplier: 0.30, stageRequired: 2),
    Upgrade(id: 'house_laser_irrigation', name: 'Laser Irrigation', emoji: '🔴', description: '1.23x per focus', cost: 122000000000, multiplier: 0.23, stageRequired: 2),
    Upgrade(id: 'house_ai_tools', name: 'AI-Powered Tools', emoji: '🤖', description: '1.20x per focus', cost: 269000000000, multiplier: 0.20, stageRequired: 2),
    Upgrade(id: 'house_nano_fertilizer', name: 'Nano-Fertilizer', emoji: '🔭', description: '1.17x per focus', cost: 588000000000, multiplier: 0.17, stageRequired: 2),
    Upgrade(id: 'house_plasma_water', name: 'Plasma Water Treatment', emoji: '💥', description: '1.15x per focus', cost: 1300000000000, multiplier: 0.15, stageRequired: 2),
    Upgrade(id: 'house_cosmic_soil', name: 'Cosmic Soil Enhancement', emoji: '🌌', description: '1.13x per focus', cost: 2800000000000, multiplier: 0.13, stageRequired: 2),
    Upgrade(id: 'house_dimension_tech', name: 'Dimensional Technology', emoji: '🌀', description: '1.12x per focus', cost: 6300000000000, multiplier: 0.12, stageRequired: 2),
    Upgrade(id: 'house_fusion_climate', name: 'Fusion Climate System', emoji: '☢️', description: '1.10x per focus', cost: 13900000000000, multiplier: 0.10, stageRequired: 2),
    Upgrade(id: 'house_mega_hydro', name: 'Mega-Hydroponic Array', emoji: '🏭', description: '1.09x per focus', cost: 30200000000000, multiplier: 0.09, stageRequired: 2),
    Upgrade(id: 'house_neural_network', name: 'Neural Network Farm', emoji: '🧠', description: '1.07x per focus', cost: 67200000000000, multiplier: 0.07, stageRequired: 2),
    Upgrade(id: 'house_photon_boost', name: 'Photon Accelerator', emoji: '🌟', description: '1.06x per focus', cost: 147000000000000, multiplier: 0.06, stageRequired: 2),
    Upgrade(id: 'house_dark_matter', name: 'Dark Matter Fertilizer', emoji: '🕳️', description: '1.06x per focus', cost: 323000000000000, multiplier: 0.06, stageRequired: 2),
    Upgrade(id: 'house_antimatter', name: 'Antimatter Generator', emoji: '💫', description: '1.05x per focus', cost: 714000000000000, multiplier: 0.05, stageRequired: 2),
    Upgrade(id: 'house_wormhole', name: 'Wormhole Irrigation', emoji: '🌪️', description: '1.05x per focus', cost: 1550000000000000, multiplier: 0.05, stageRequired: 2),
    Upgrade(id: 'house_singularity', name: 'Singularity Core', emoji: '⚫', description: '1.04x per focus', cost: 3440000000000000, multiplier: 0.04, stageRequired: 2),
    Upgrade(id: 'house_parallel_universe', name: 'Parallel Universe Farm', emoji: '🌐', description: '1.04x per focus', cost: 7560000000000000, multiplier: 0.04, stageRequired: 2),
    Upgrade(id: 'house_quantum_entangle', name: 'Quantum Entanglement', emoji: '🔗', description: '1.04x per focus', cost: 16800000000000000, multiplier: 0.04, stageRequired: 2),
    Upgrade(id: 'house_multiverse', name: 'Multiverse Harvesting', emoji: '🎭', description: '1.03x per focus', cost: 37000000000000000, multiplier: 0.03, stageRequired: 2),
    Upgrade(id: 'house_legendary_mastery', name: 'Legendary Mastery', emoji: '⚡', description: '1.02x per focus', cost: 79800000000000000, multiplier: 0.02, stageRequired: 2),

    // ========================================
    // STAGE 3: MANSION — 50% mult cut, costs compressed to cap at ~4e18
    // ========================================
    Upgrade(id: 'mansion_divine_hoe', name: 'Divine Hoe', emoji: '🙏', description: '1.40x per focus', cost: 6.5e14, multiplier: 0.40, stageRequired: 3),
    Upgrade(id: 'mansion_god_seeds', name: 'Seeds of the Gods', emoji: '✨', description: '1.30x per focus', cost: 8.8e14, multiplier: 0.30, stageRequired: 3),
    Upgrade(id: 'mansion_reality_water', name: 'Reality-Bending Water', emoji: '🌊', description: '1.24x per focus', cost: 1.19e15, multiplier: 0.24, stageRequired: 3),
    Upgrade(id: 'mansion_infinity_tools', name: 'Infinity Tools', emoji: '♾️', description: '1.21x per focus', cost: 1.60e15, multiplier: 0.21, stageRequired: 3),
    Upgrade(id: 'mansion_omnipotent_fertilizer', name: 'Omnipotent Fertilizer', emoji: '👑', description: '1.18x per focus', cost: 2.16e15, multiplier: 0.18, stageRequired: 3),
    Upgrade(id: 'mansion_eternal_irrigation', name: 'Eternal Irrigation', emoji: '💎', description: '1.15x per focus', cost: 2.92e15, multiplier: 0.15, stageRequired: 3),
    Upgrade(id: 'mansion_transcendent_soil', name: 'Transcendent Soil', emoji: '🔱', description: '1.14x per focus', cost: 3.94e15, multiplier: 0.14, stageRequired: 3),
    Upgrade(id: 'mansion_perfect_growth', name: 'Perfect Growth Matrix', emoji: '🌈', description: '1.12x per focus', cost: 5.32e15, multiplier: 0.12, stageRequired: 3),
    Upgrade(id: 'mansion_ultimate_climate', name: 'Ultimate Climate', emoji: '🏆', description: '1.11x per focus', cost: 7.18e15, multiplier: 0.11, stageRequired: 3),
    Upgrade(id: 'mansion_absolute_mastery', name: 'Absolute Mastery', emoji: '⭐', description: '1.09x per focus', cost: 9.69e15, multiplier: 0.09, stageRequired: 3),
    Upgrade(id: 'mansion_celestial_power', name: 'Celestial Power', emoji: '🌠', description: '1.08x per focus', cost: 1.31e16, multiplier: 0.08, stageRequired: 3),
    Upgrade(id: 'mansion_primordial_force', name: 'Primordial Force', emoji: '💠', description: '1.07x per focus', cost: 1.77e16, multiplier: 0.07, stageRequired: 3),
    Upgrade(id: 'mansion_cosmic_throne', name: 'Cosmic Throne', emoji: '👸', description: '1.06x per focus', cost: 2.39e16, multiplier: 0.06, stageRequired: 3),
    Upgrade(id: 'mansion_universal_law', name: 'Universal Law Rewrite', emoji: '📜', description: '1.06x per focus', cost: 3.22e16, multiplier: 0.06, stageRequired: 3),
    Upgrade(id: 'mansion_time_lord', name: 'Time Lord Powers', emoji: '⏳', description: '1.05x per focus', cost: 4.35e16, multiplier: 0.05, stageRequired: 3),
    Upgrade(id: 'mansion_space_bender', name: 'Space Bending', emoji: '🌌', description: '1.05x per focus', cost: 5.87e16, multiplier: 0.05, stageRequired: 3),
    Upgrade(id: 'mansion_soul_harvest', name: 'Soul Harvesting', emoji: '👻', description: '1.04x per focus', cost: 7.93e16, multiplier: 0.04, stageRequired: 3),
    Upgrade(id: 'mansion_elder_god', name: 'Elder God Blessing', emoji: '🦑', description: '1.04x per focus', cost: 1.07e17, multiplier: 0.04, stageRequired: 3),
    Upgrade(id: 'mansion_void_essence', name: 'Void Essence', emoji: '🕳️', description: '1.04x per focus', cost: 1.44e17, multiplier: 0.04, stageRequired: 3),
    Upgrade(id: 'mansion_chaos_energy', name: 'Chaos Energy', emoji: '⚡', description: '1.04x per focus', cost: 1.95e17, multiplier: 0.04, stageRequired: 3),
    Upgrade(id: 'mansion_order_matrix', name: 'Order Matrix', emoji: '🔶', description: '1.03x per focus', cost: 2.63e17, multiplier: 0.03, stageRequired: 3),
    Upgrade(id: 'mansion_balance_keeper', name: 'Balance Keeper', emoji: '⚖️', description: '1.03x per focus', cost: 3.55e17, multiplier: 0.03, stageRequired: 3),
    Upgrade(id: 'mansion_dream_weaver', name: 'Dream Weaver', emoji: '💭', description: '1.03x per focus', cost: 4.79e17, multiplier: 0.03, stageRequired: 3),
    Upgrade(id: 'mansion_reality_architect', name: 'Reality Architect', emoji: '🏗️', description: '1.03x per focus', cost: 6.47e17, multiplier: 0.03, stageRequired: 3),
    Upgrade(id: 'mansion_existence_itself', name: 'Existence Itself', emoji: '🌍', description: '1.02x per focus', cost: 8.73e17, multiplier: 0.02, stageRequired: 3),
    Upgrade(id: 'mansion_creation_spark', name: 'Creation Spark', emoji: '🔥', description: '1.02x per focus', cost: 1.18e18, multiplier: 0.02, stageRequired: 3),
    Upgrade(id: 'mansion_destruction_wave', name: 'Destruction Wave', emoji: '💥', description: '1.02x per focus', cost: 1.59e18, multiplier: 0.02, stageRequired: 3),
    Upgrade(id: 'mansion_rebirth_cycle', name: 'Rebirth Cycle', emoji: '🔄', description: '1.02x per focus', cost: 2.15e18, multiplier: 0.02, stageRequired: 3),
    Upgrade(id: 'mansion_alpha_omega', name: 'Alpha & Omega', emoji: '🅰️', description: '1.01x per focus', cost: 2.90e18, multiplier: 0.01, stageRequired: 3),
    Upgrade(id: 'mansion_supreme_being', name: 'Supreme Being', emoji: '🔯', description: '1.01x per focus', cost: 3.91e18, multiplier: 0.01, stageRequired: 3),
  ];

  final List<HouseUnlock> _houseUnlocks = [
    HouseUnlock(
      id: 'unlock_shack',
      name: 'Cave Door',
      emoji: '🚪',
      description: 'Unlock Shack & Shack Shop (3.5x bonus!)',
      cost: 204000,         // 49% cost cut
      unlocksStage: 1,
      houseMultiplier: 3.5, // 50% mult cut
    ),
    HouseUnlock(
      id: 'unlock_house',
      name: 'Shack Upgrade',
      emoji: '🏠',
      description: 'Unlock House & House Shop (18.5x bonus!)',
      cost: 2240000000,     // 44% cost cut
      unlocksStage: 2,
      houseMultiplier: 18.5, // 50% mult cut
    ),
    HouseUnlock(
      id: 'unlock_mansion',
      name: 'House Upgrade',
      emoji: '🏰',
      description: 'Unlock Mansion & Mansion Shop (83.5x bonus!)',
      cost: 1.8e16,         // 40% cost cut
      unlocksStage: 3,
      houseMultiplier: 83.5, // 50% mult cut
    ),
  ];


  // Getters
  List<Upgrade> get allUpgrades => _upgrades;
  List<Upgrade> get purchasedUpgrades => _upgrades.where((u) => u.isPurchased).toList();
  List<Upgrade> get availableUpgrades => _upgrades.where((u) => !u.isPurchased).toList();
  List<HouseUnlock> get houseUnlocks => _houseUnlocks;
  int get currentStage => _currentStage;

  // Get upgrades for a specific stage
  List<Upgrade> getUpgradesForStage(int stage) {
    return _upgrades.where((u) => u.stageRequired == stage).toList();
  }

  // Get the unlock for current stage
  HouseUnlock? getNextUnlock() {
    for (var unlock in _houseUnlocks) {
      if (!unlock.isPurchased && unlock.unlocksStage == _currentStage + 1) {
        return unlock;
      }
    }
    return null;
  }

  /// Initialize - Load saved upgrades AND house unlocks
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _currentStage = prefs.getInt('current_stage') ?? 0;
    await loadUpgrades();
    await loadHouseUnlocks();
  }

  /// Calculate total multiplier - MULTIPLICATIVE (boosts compound!)
  double getTotalMultiplier() {
    double total = 1.0;

    // Multiply each purchased upgrade (they compound!)
    for (var upgrade in _upgrades) {
      if (upgrade.isPurchased) {
        total *= (1.0 + upgrade.multiplier);
      }
    }

    // Multiply by house bonuses (HUGE jumps!)
    for (var unlock in _houseUnlocks) {
      if (unlock.isPurchased) {
        total *= unlock.houseMultiplier;
      }
    }

    return total;
  }

  String getMultiplierString() {
    double multiplier = getTotalMultiplier();
    if (multiplier >= 10000) {
      return "${(multiplier / 1000).toStringAsFixed(1)}Kx";
    } else if (multiplier >= 100) {
      return "${multiplier.toStringAsFixed(0)}x";
    } else if (multiplier >= 10) {
      return "${multiplier.toStringAsFixed(1)}x";
    }
    return "${multiplier.toStringAsFixed(2)}x";
  }

  String getBonusPercentageString() {
    double multiplier = getTotalMultiplier();
    if (multiplier <= 1.0) return "No bonus yet";
    return "${multiplier.toStringAsFixed(1)}x boost";
  }

  /// Purchase an upgrade
  Future<bool> purchaseUpgrade(String upgradeId, double currentPeas) async {
    // Find upgrade
    Upgrade? upgrade = _upgrades.firstWhere(
          (u) => u.id == upgradeId,
      orElse: () => throw Exception('Upgrade not found'),
    );

    // Check if already purchased
    if (upgrade.isPurchased) {
      return false;
    }

    // Check if can afford
    if (currentPeas < upgrade.cost) {
      return false;
    }

    // Purchase!
    upgrade.isPurchased = true;
    await saveUpgrades();
    return true;
  }

  /// Purchase a house unlock
  Future<bool> purchaseHouseUnlock(String unlockId, double currentPeas) async {
    HouseUnlock unlock = _houseUnlocks.firstWhere((u) => u.id == unlockId);

    if (unlock.isPurchased || currentPeas < unlock.cost) {
      return false;
    }

    unlock.isPurchased = true;
    _currentStage = unlock.unlocksStage;
    await saveUpgrades();
    await saveHouseUnlocks();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('current_stage', _currentStage);

    return true;
  }

  /// Get upgrade by ID
  Upgrade? getUpgrade(String id) {
    try {
      return _upgrades.firstWhere((u) => u.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Check if upgrade is purchased
  bool isPurchased(String id) {
    Upgrade? upgrade = getUpgrade(id);
    return upgrade?.isPurchased ?? false;
  }

  /// Save upgrades to storage
  Future<void> saveUpgrades() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> purchasedIds = _upgrades
        .where((u) => u.isPurchased)
        .map((u) => u.id)
        .toList();
    await prefs.setStringList('purchased_upgrades', purchasedIds);
  }

  /// Load upgrades from storage
  Future<void> loadUpgrades() async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? purchasedIds = prefs.getStringList('purchased_upgrades');

    if (purchasedIds != null) {
      for (var upgrade in _upgrades) {
        upgrade.isPurchased = purchasedIds.contains(upgrade.id);
      }
    }
  }

  /// Save house unlocks
  Future<void> saveHouseUnlocks() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> purchasedIds = _houseUnlocks
        .where((u) => u.isPurchased)
        .map((u) => u.id)
        .toList();
    await prefs.setStringList('purchased_house_unlocks', purchasedIds);
  }

  /// Load house unlocks
  Future<void> loadHouseUnlocks() async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? purchasedIds = prefs.getStringList('purchased_house_unlocks');

    if (purchasedIds != null) {
      for (var unlock in _houseUnlocks) {
        unlock.isPurchased = purchasedIds.contains(unlock.id);
        if (unlock.isPurchased && unlock.unlocksStage > _currentStage) {
          _currentStage = unlock.unlocksStage;
        }
      }
    }
  }

  /// Reset all upgrades and house unlocks (for testing)
  Future<void> reset() async {
    for (var upgrade in _upgrades) {
      upgrade.isPurchased = false;
    }
    for (var unlock in _houseUnlocks) {
      unlock.isPurchased = false;
    }
    _currentStage = 0;
    await saveUpgrades();
    await saveHouseUnlocks();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('current_stage', 0);
  }

  /// Get next affordable upgrade (based on current peas)
  Upgrade? getNextAffordableUpgrade(double currentPeas) {
    var available = availableUpgrades;
    available.sort((a, b) => a.cost.compareTo(b.cost));

    for (var upgrade in available) {
      if (currentPeas >= upgrade.cost) {
        return upgrade;
      }
    }
    return null;
  }

  /// Get next upgrade to save for
  Upgrade? getNextGoal(double currentPeas) {
    var available = availableUpgrades;
    available.sort((a, b) => a.cost.compareTo(b.cost));

    for (var upgrade in available) {
      if (currentPeas < upgrade.cost) {
        return upgrade;
      }
    }
    return null;
  }
}