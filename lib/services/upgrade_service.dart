import 'package:shared_preferences/shared_preferences.dart';

import 'currency_service.dart';

class Upgrade {
  final String id;
  final String name;
  final String emoji;
  final String description;
  final double cost;
  final double multiplier;
  final int stageRequired;
  bool isPurchased;

  Upgrade({
    required this.id,
    required this.name,
    required this.emoji,
    required this.description,
    required this.cost,
    required this.multiplier,
    this.stageRequired = 0,
    this.isPurchased = false,
  });

  Map<String, dynamic> toJson() => {'id': id, 'isPurchased': isPurchased};

  static Upgrade fromJson(Map<String, dynamic> json, Upgrade template) {
    return Upgrade(
      id: template.id, name: template.name, emoji: template.emoji,
      description: template.description, cost: template.cost,
      multiplier: template.multiplier, stageRequired: template.stageRequired,
      isPurchased: json['isPurchased'] ?? false,
    );
  }
}

class HouseUnlock {
  final String id;
  final String name;
  final String emoji;
  final String description;
  final double cost;      // peas cost
  final int coinCost;     // coins cost
  final int unlocksStage;
  final double houseMultiplier;
  bool isPurchased;

  HouseUnlock({
    required this.id,
    required this.name,
    required this.emoji,
    required this.description,
    required this.cost,
    this.coinCost = 0,
    required this.unlocksStage,
    this.houseMultiplier = 1.0,
    this.isPurchased = false,
  });

  Map<String, dynamic> toJson() => {'id': id, 'isPurchased': isPurchased};

  static HouseUnlock fromJson(Map<String, dynamic> json, HouseUnlock template) {
    return HouseUnlock(
      id: template.id, name: template.name, emoji: template.emoji,
      description: template.description, cost: template.cost,
      unlocksStage: template.unlocksStage, houseMultiplier: template.houseMultiplier,
      isPurchased: json['isPurchased'] ?? false,
    );
  }
}

class UpgradeService {
  static final UpgradeService _instance = UpgradeService._internal();
  factory UpgradeService() => _instance;
  UpgradeService._internal();

  int _currentStage = 0;

  final List<Upgrade> _upgrades = [

    // ╔══════════════════════════════════════════╗
    // ║  CAVE — 10 upgrades                      ║
    // ║  First upgrade reachable in ~5 sessions  ║
    // ╚══════════════════════════════════════════╝
    Upgrade(id: 'cave_hoe',        name: 'Basic Hoe',        emoji: '⛏️', description: '+25% strawberries/focus', cost: 1,   multiplier: 0.25, stageRequired: 0),
    Upgrade(id: 'cave_seeds',      name: 'Good Seeds',       emoji: '🌱', description: '+22% strawberries/focus', cost: 20,   multiplier: 0.22, stageRequired: 0),
    Upgrade(id: 'cave_bucket',     name: 'Water Bucket',     emoji: '🪣', description: '+20% strawberries/focus', cost: 50,  multiplier: 0.20, stageRequired: 0),
    Upgrade(id: 'cave_tools',      name: 'Sharp Tools',      emoji: '🔨', description: '+18% strawberries/focus', cost: 100,  multiplier: 0.18, stageRequired: 0),
    Upgrade(id: 'cave_fertilizer', name: 'Fertilizer',       emoji: '🌿', description: '+16% strawberries/focus', cost: 200,  multiplier: 0.16, stageRequired: 0),
    Upgrade(id: 'cave_watering',   name: 'Watering Can',     emoji: '💧', description: '+14% strawberries/focus', cost: 350,  multiplier: 0.14, stageRequired: 0),
    Upgrade(id: 'cave_soil',       name: 'Rich Soil',        emoji: '🪴', description: '+13% strawberries/focus', cost: 550,  multiplier: 0.13, stageRequired: 0),
    Upgrade(id: 'cave_compost',    name: 'Compost',          emoji: '♻️', description: '+12% strawberries/focus', cost: 800, multiplier: 0.12, stageRequired: 0),
    Upgrade(id: 'cave_greenhouse', name: 'Mini Greenhouse',  emoji: '🏡', description: '+11% strawberries/focus', cost: 1000, multiplier: 0.11, stageRequired: 0),
    Upgrade(id: 'cave_irrigation', name: 'Basic Irrigation', emoji: '💦', description: '+10% strawberries/focus', cost: 5000, multiplier: 0.10, stageRequired: 0),

// ╔══════════════════════════════════════════╗
// ║  SHACK — 12 upgrades                     ║
// ╚══════════════════════════════════════════╝
    Upgrade(id: 'shack_advanced_hoe',     name: 'Advanced Hoe',       emoji: '⚒️',  description: '+24% strawberries/focus', cost: 1500,   multiplier: 0.24, stageRequired: 1),
    Upgrade(id: 'shack_premium_seeds',    name: 'Premium Seeds',      emoji: '🌾',  description: '+22% strawberries/focus', cost: 3500,   multiplier: 0.22, stageRequired: 1),
    Upgrade(id: 'shack_sprinklers',       name: 'Sprinkler System',   emoji: '🚿',  description: '+20% strawberries/focus', cost: 7000,   multiplier: 0.20, stageRequired: 1),
    Upgrade(id: 'shack_pro_tools',        name: 'Professional Tools', emoji: '🔧',  description: '+18% strawberries/focus', cost: 13000,  multiplier: 0.18, stageRequired: 1),
    Upgrade(id: 'shack_super_fertilizer', name: 'Super Fertilizer',   emoji: '🧪',  description: '+16% strawberries/focus', cost: 22000,  multiplier: 0.16, stageRequired: 1),
    Upgrade(id: 'shack_auto_water',       name: 'Auto Watering',      emoji: '⚡',   description: '+15% strawberries/focus', cost: 36000,  multiplier: 0.15, stageRequired: 1),
    Upgrade(id: 'shack_premium_soil',     name: 'Premium Soil Mix',   emoji: '🌱',  description: '+13% strawberries/focus', cost: 52000,  multiplier: 0.13, stageRequired: 1),
    Upgrade(id: 'shack_biotech',          name: 'Bio-Technology',     emoji: '🧬',  description: '+12% strawberries/focus', cost: 70000,  multiplier: 0.12, stageRequired: 1),
    Upgrade(id: 'shack_climate',          name: 'Climate Control',    emoji: '🌡️',  description: '+11% strawberries/focus', cost: 88000,  multiplier: 0.11, stageRequired: 1),
    Upgrade(id: 'shack_hydroponics',      name: 'Hydroponic System',  emoji: '💧',  description: '+10% strawberries/focus', cost: 107000, multiplier: 0.10, stageRequired: 1),
    Upgrade(id: 'shack_led_grow',         name: 'LED Grow Lights',    emoji: '💡',  description: '+9% strawberries/focus',  cost: 128000, multiplier: 0.09, stageRequired: 1),
    Upgrade(id: 'shack_master_gardener',  name: 'Master Gardener',    emoji: '👨‍🌾',  description: '+8% strawberries/focus', cost: 150000, multiplier: 0.08, stageRequired: 1),

// ╔══════════════════════════════════════════╗
// ║  HOUSE — 15 upgrades                     ║
// ╚══════════════════════════════════════════╝
    Upgrade(id: 'house_quantum_hoe',      name: 'Quantum Hoe',            emoji: '⚛️',  description: '+15% strawberries/focus', cost: 500000,       multiplier: 0.15, stageRequired: 2),
    Upgrade(id: 'house_genetic_seeds',    name: 'GMO Seeds',              emoji: '🔬',  description: '+14% strawberries/focus', cost: 860514,       multiplier: 0.14, stageRequired: 2),
    Upgrade(id: 'house_laser_irrigation', name: 'Laser Irrigation',       emoji: '🔴',  description: '+13% strawberries/focus', cost: 1480968,      multiplier: 0.13, stageRequired: 2),
    Upgrade(id: 'house_ai_tools',         name: 'AI-Powered Tools',       emoji: '🤖',  description: '+12% strawberries/focus', cost: 2548787,      multiplier: 0.12, stageRequired: 2),
    Upgrade(id: 'house_nano_fertilizer',  name: 'Nano-Fertilizer',        emoji: '🔭',  description: '+11% strawberries/focus', cost: 4386533,      multiplier: 0.11, stageRequired: 2),
    Upgrade(id: 'house_plasma_water',     name: 'Plasma Water',           emoji: '💥',  description: '+10% strawberries/focus', cost: 7549345,      multiplier: 0.10, stageRequired: 2),
    Upgrade(id: 'house_cosmic_soil',      name: 'Cosmic Soil',            emoji: '🌌',  description: '+9% strawberries/focus',  cost: 12992632,     multiplier: 0.09, stageRequired: 2),
    Upgrade(id: 'house_dimension_tech',   name: 'Dimensional Tech',       emoji: '🌀',  description: '+8% strawberries/focus',  cost: 22360679,     multiplier: 0.08, stageRequired: 2),
    Upgrade(id: 'house_fusion_climate',   name: 'Fusion Climate',         emoji: '☢️',  description: '+8% strawberries/focus',  cost: 38483348,     multiplier: 0.08, stageRequired: 2),
    Upgrade(id: 'house_mega_hydro',       name: 'Mega-Hydroponic Array',  emoji: '🏭',  description: '+7% strawberries/focus',  cost: 66230907,     multiplier: 0.07, stageRequired: 2),
    Upgrade(id: 'house_neural_network',   name: 'Neural Network Farm',    emoji: '🧠',  description: '+6% strawberries/focus',  cost: 113985225,    multiplier: 0.06, stageRequired: 2),
    Upgrade(id: 'house_photon_boost',     name: 'Photon Accelerator',     emoji: '🌟',  description: '+5% strawberries/focus',  cost: 196171728,    multiplier: 0.05, stageRequired: 2),
    Upgrade(id: 'house_dark_matter',      name: 'Dark Matter Fertilizer', emoji: '🕳️', description: '+5% strawberries/focus',  cost: 337616975,    multiplier: 0.05, stageRequired: 2),
    Upgrade(id: 'house_antimatter',       name: 'Antimatter Generator',   emoji: '💫',  description: '+4% strawberries/focus',  cost: 581048161,    multiplier: 0.04, stageRequired: 2),
    Upgrade(id: 'house_singularity',      name: 'Singularity Core',       emoji: '⚫',  description: '+3% strawberries/focus',  cost: 999999972,    multiplier: 0.03, stageRequired: 2),
  ];

  final List<HouseUnlock> _houseUnlocks = [
    HouseUnlock(
      id: 'unlock_shack',
      name: 'Cave Door',
      emoji: '🚪',
      description: 'Unlock Shack (3x bonus!)',
      cost: 10000,      // 10,000 peas
      unlocksStage: 1,
      houseMultiplier: 3.0,
    ),
    HouseUnlock(
      id: 'unlock_house',
      name: 'Shack Upgrade',
      emoji: '🏠',
      description: 'Unlock House & House Shop (10x bonus!)',
      cost: 200000,
      unlocksStage: 2,
      houseMultiplier: 10.0,
    ),
  ];

  List<Upgrade>     get allUpgrades       => _upgrades;
  List<Upgrade>     get purchasedUpgrades => _upgrades.where((u) => u.isPurchased).toList();
  List<Upgrade>     get availableUpgrades => _upgrades.where((u) => !u.isPurchased).toList();
  List<HouseUnlock> get houseUnlocks      => _houseUnlocks;
  int               get currentStage      => _currentStage;

  List<Upgrade> getUpgradesForStage(int stage) =>
      _upgrades.where((u) => u.stageRequired == stage).toList();

  HouseUnlock? getNextUnlock() {
    for (var unlock in _houseUnlocks) {
      if (!unlock.isPurchased && unlock.unlocksStage == _currentStage + 1) {
        return unlock;
      }
    }
    return null;
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _currentStage = prefs.getInt('current_stage') ?? 0;
    await loadUpgrades();
    await loadHouseUnlocks();
  }

  /// Total multiplier — all purchased upgrades compound multiplicatively,
  /// then house bonuses are applied on top.
  double getTotalMultiplier() {
    double total = 1.0;
    for (var upgrade in _upgrades) {
      if (upgrade.isPurchased) total *= (1.0 + upgrade.multiplier);
    }
    for (var unlock in _houseUnlocks) {
      if (unlock.isPurchased) total *= unlock.houseMultiplier;
    }
    return total;
  }

  String getMultiplierString() {
    final m = getTotalMultiplier();
    if (m >= 10000) return '${(m / 1000).toStringAsFixed(1)}Kx';
    if (m >= 100)   return '${m.toStringAsFixed(0)}x';
    if (m >= 10)    return '${m.toStringAsFixed(1)}x';
    return '${m.toStringAsFixed(2)}x';
  }

  String getBonusPercentageString() {
    final m = getTotalMultiplier();
    if (m <= 1.0) return 'No boost yet';
    return '${m.toStringAsFixed(1)}x boost';
  }

  Future<bool> purchaseUpgrade(String upgradeId, double currentPeas) async {
    final upgrade = _upgrades.firstWhere(
          (u) => u.id == upgradeId,
      orElse: () => throw Exception('Upgrade not found'),
    );
    if (upgrade.isPurchased || currentPeas < upgrade.cost) return false;
    upgrade.isPurchased = true;
    await saveUpgrades();
    return true;
  }

  Future<bool> purchaseHouseUnlock(String unlockId, double currentPeas) async {
    final unlock = _houseUnlocks.firstWhere((u) => u.id == unlockId);
    if (unlock.isPurchased) return false;
    if (currentPeas < unlock.cost) return false;
    if (CurrencyService().coins < unlock.coinCost) return false;

    // ✅ Currency deduction is handled by the caller (shop_screen.dart)
    unlock.isPurchased = true;
    _currentStage = unlock.unlocksStage;
    await saveUpgrades();
    await saveHouseUnlocks();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('current_stage', _currentStage);
    return true;
  }

  Upgrade? getUpgrade(String id) {
    try { return _upgrades.firstWhere((u) => u.id == id); }
    catch (_) { return null; }
  }

  bool isPurchased(String id) => getUpgrade(id)?.isPurchased ?? false;

  Future<void> saveUpgrades() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'purchased_upgrades',
      _upgrades.where((u) => u.isPurchased).map((u) => u.id).toList(),
    );
  }

  Future<void> loadUpgrades() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList('purchased_upgrades');
    if (ids != null) {
      for (var upgrade in _upgrades) {
        upgrade.isPurchased = ids.contains(upgrade.id);
      }
    }
  }

  Future<void> saveHouseUnlocks() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'purchased_house_unlocks',
      _houseUnlocks.where((u) => u.isPurchased).map((u) => u.id).toList(),
    );
  }

  Future<void> loadHouseUnlocks() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = prefs.getStringList('purchased_house_unlocks');
    if (ids != null) {
      for (var unlock in _houseUnlocks) {
        unlock.isPurchased = ids.contains(unlock.id);
        if (unlock.isPurchased && unlock.unlocksStage > _currentStage) {
          _currentStage = unlock.unlocksStage;
        }
      }
    }
  }

  Future<void> reset() async {
    for (var u in _upgrades)     { u.isPurchased = false; }
    for (var u in _houseUnlocks) { u.isPurchased = false; }
    _currentStage = 0;
    await saveUpgrades();
    await saveHouseUnlocks();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('current_stage', 0);
  }

  Upgrade? getNextAffordableUpgrade(double currentPeas) {
    final sorted = availableUpgrades..sort((a, b) => a.cost.compareTo(b.cost));
    for (var u in sorted) { if (currentPeas >= u.cost) return u; }
    return null;
  }

  Upgrade? getNextGoal(double currentPeas) {
    final sorted = availableUpgrades..sort((a, b) => a.cost.compareTo(b.cost));
    for (var u in sorted) { if (currentPeas < u.cost) return u; }
    return null;
  }

  int getTotalUpgradesPurchased() {
    // ✅ Count directly from the upgrades list instead of
    // looping through hardcoded stage numbers — automatically
    // handles any number of stages added in future
    return _upgrades.where((u) => u.isPurchased).length;
  }
}