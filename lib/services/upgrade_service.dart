import 'package:shared_preferences/shared_preferences.dart';

class Upgrade {
  final String id;
  final String name;
  final String emoji;
  final String description;
  final int cost;
  final double multiplier; // e.g., 0.10 for +10%
  bool isPurchased;

  Upgrade({
    required this.id,
    required this.name,
    required this.emoji,
    required this.description,
    required this.cost,
    required this.multiplier,
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
      isPurchased: json['isPurchased'] ?? false,
    );
  }
}

class UpgradeService {
  static final UpgradeService _instance = UpgradeService._internal();
  factory UpgradeService() => _instance;
  UpgradeService._internal();

  // Available upgrades
  List<Upgrade> _upgrades = [
    // Tier 1: Starter upgrades (affordable early game)
    Upgrade(
      id: 'better_hoe',
      name: 'Better Hoe',
      emoji: '⛏️',
      description: '+10% peas per focus',
      cost: 50,
      multiplier: 0.10,
    ),
    Upgrade(
      id: 'watering_can',
      name: 'Watering Can',
      emoji: '💧',
      description: '+15% peas per focus',
      cost: 100,
      multiplier: 0.15,
    ),
    Upgrade(
      id: 'fertilizer',
      name: 'Fertilizer',
      emoji: '🌿',
      description: '+20% peas per focus',
      cost: 200,
      multiplier: 0.20,
    ),

    // Tier 2: Mid-game upgrades
    Upgrade(
      id: 'good_soil',
      name: 'Good Soil',
      emoji: '🪴',
      description: '+25% peas per focus',
      cost: 400,
      multiplier: 0.25,
    ),
    Upgrade(
      id: 'greenhouse',
      name: 'Small Greenhouse',
      emoji: '🏡',
      description: '+30% peas per focus',
      cost: 800,
      multiplier: 0.30,
    ),

    // Tier 3: Late game upgrades
    Upgrade(
      id: 'irrigation',
      name: 'Irrigation System',
      emoji: '💦',
      description: '+40% peas per focus',
      cost: 1500,
      multiplier: 0.40,
    ),
    Upgrade(
      id: 'expert_tools',
      name: 'Expert Tools',
      emoji: '🔧',
      description: '+50% peas per focus',
      cost: 3000,
      multiplier: 0.50,
    ),
  ];

  // Getters
  List<Upgrade> get allUpgrades => _upgrades;
  List<Upgrade> get purchasedUpgrades => _upgrades.where((u) => u.isPurchased).toList();
  List<Upgrade> get availableUpgrades => _upgrades.where((u) => !u.isPurchased).toList();

  /// Initialize - Load saved upgrades
  Future<void> init() async {
    await loadUpgrades();
  }

  /// Calculate total multiplier from all purchased upgrades
  double getTotalMultiplier() {
    double total = 1.0; // Base multiplier
    for (var upgrade in _upgrades) {
      if (upgrade.isPurchased) {
        total += upgrade.multiplier;
      }
    }
    return total;
  }

  /// Get multiplier as percentage string (e.g., "1.65x" or "+65%")
  String getMultiplierString() {
    double multiplier = getTotalMultiplier();
    return "${multiplier.toStringAsFixed(2)}x";
  }

  /// Get bonus percentage (e.g., if 1.65x multiplier, returns "+65%")
  String getBonusPercentageString() {
    double bonus = (getTotalMultiplier() - 1.0) * 100;
    if (bonus == 0) return "No bonus yet";
    return "+${bonus.toStringAsFixed(0)}%";
  }

  /// Purchase an upgrade
  Future<bool> purchaseUpgrade(String upgradeId, int currentPeas) async {
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

  /// Reset all upgrades (for testing)
  Future<void> reset() async {
    for (var upgrade in _upgrades) {
      upgrade.isPurchased = false;
    }
    await saveUpgrades();
  }

  /// Get next affordable upgrade
  Upgrade? getNextAffordableUpgrade(int currentPeas) {
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
  Upgrade? getNextGoal(int currentPeas) {
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