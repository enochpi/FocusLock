
import 'package:shared_preferences/shared_preferences.dart';
import 'furniture_service.dart';

class CurrencyService {
  static final CurrencyService _instance = CurrencyService._internal();
  factory CurrencyService() => _instance;
  CurrencyService._internal();

  // ── Crop stage system ─────────────────────────────────────
  // Conversion rate: how many crops = 1 coin
  static const List<Map<String, dynamic>> cropStages = [
    {'name': 'Peas',    'emoji': '🌱', 'rate': 100},  // 100 peas = 1 coin
    {'name': 'Carrots', 'emoji': '🥕', 'rate': 70},   // 70 carrots = 1 coin
    {'name': 'Corn',    'emoji': '🌽', 'rate': 50},   // 50 corn = 1 coin
  ];

  int _currentStage = 0;

  int get currentStage => _currentStage;
  String get cropName  => cropStages[_currentStage.clamp(0, cropStages.length - 1)]['name'];
  String get cropEmoji => cropStages[_currentStage.clamp(0, cropStages.length - 1)]['emoji'];
  int    get cropRate  => cropStages[_currentStage.clamp(0, cropStages.length - 1)]['rate'];

  int _peas  = 0;
  int _coins = 0;

  int get peas  => _peas;
  int get coins => _coins;
  int get PEAS_PER_COIN => cropRate;

  static const int MAX_CURRENCY = 9000000000000000000;

  /// Calculate peas earned from a focus session.
  ///
  /// Design goals:
  ///   •  1 min  session →   1 pea    (bare minimum)
  ///   •  5 min  session →   6 peas
  ///   • 25 min  session →  37 peas   → ~3 coins
  ///   • 60 min  session → 132 peas   → ~13 coins
  ///
  /// With no multipliers, buying first upgrade (100 coins) takes
  /// roughly 33 sessions of 25 min — a satisfying early grind.
  /// Multipliers from upgrades/furniture scale this up fast.
  ///
  /// Formula:
  ///   base        = minutes * 1.0
  ///   timeBonus   = minutes² * 0.02   (rewards longer sessions)
  ///   totalBase   = base + timeBonus
  ///   final       = totalBase * furniture * upgrade * streak
  static int calculatePeasFromFocus(int minutes, {
    double upgradeMultiplier = 1.0,
    double torchMultiplier   = 1.0,
  }) {
    final double furnitureMultiplier  = FurnitureService().getBoostMultiplier();
    final double windchimesMultiplier = FurnitureService().isFurnitureOwned('windchimes') ? 1.10 : 1.0;
    final double fountainMultiplier   = FurnitureService().isFurnitureOwned('fountain')   ? 1.10 : 1.0;

    final int finalPeas = (minutes
        * furnitureMultiplier
        * upgradeMultiplier
        * torchMultiplier
        * windchimesMultiplier
        * fountainMultiplier).round();

    return finalPeas;
  }
  Future<void> init() async => await loadCurrencies();

  Future<bool> upgradeStage() async {
    if (_currentStage >= cropStages.length - 1) return false;
    _currentStage++;
    _peas = 0;
    await saveCurrencies();
    return true;
  }

  Future<void> addPeas(int amount) async {
    if (amount < 0) return;
    _peas = (_peas + amount).clamp(0, MAX_CURRENCY);
    await saveCurrencies();
  }

  Future<bool> removePeas(int amount) async {
    if (amount < 0 || _peas < amount) return false;
    _peas -= amount;
    await saveCurrencies();
    return true;
  }

  Future<void> addCoins(int amount) async {
    if (amount < 0) return;
    _coins = (_coins + amount).clamp(0, MAX_CURRENCY);
    await saveCurrencies();
  }

  Future<bool> removeCoins(int amount) async {
    if (amount < 0 || _coins < amount) return false;
    _coins -= amount;
    await saveCurrencies();
    return true;
  }

  Future<bool> convertPeasToCoins(int peasAmount) async {
    if (peasAmount < PEAS_PER_COIN || _peas < peasAmount) return false;
    final int coinsToGive  = peasAmount ~/ PEAS_PER_COIN;
    final int peasToRemove = coinsToGive * PEAS_PER_COIN;
    _peas   -= peasToRemove;
    _coins   = (_coins + coinsToGive).clamp(0, MAX_CURRENCY);
    await saveCurrencies();
    return true;
  }

  bool canConvert() => _peas >= PEAS_PER_COIN;
  int getMaxConvertibleCoins() => _peas ~/ PEAS_PER_COIN;

  Future<void> saveCurrencies() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('peas',  _peas.toString());
    await prefs.setString('coins', _coins.toString());
    await prefs.setInt('current_stage', _currentStage);
  }

  Future<void> loadCurrencies() async {
    final prefs = await SharedPreferences.getInstance();
    _currentStage = prefs.getInt('current_stage') ?? 0;

    final rawPeas = prefs.get('peas');
    _peas = rawPeas is String ? (int.tryParse(rawPeas) ?? 0)
        : rawPeas is int    ? rawPeas
        : 0;

    final rawCoins = prefs.get('coins');
    _coins = rawCoins is String ? (int.tryParse(rawCoins) ?? 0)
        : rawCoins is int    ? rawCoins
        : 0;
  }

  Future<void> reset() async {
    _peas = 0; _coins = 0; _currentStage = 0;
    await saveCurrencies();
  }
}