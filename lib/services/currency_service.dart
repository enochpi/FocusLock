import 'package:shared_preferences/shared_preferences.dart';
import 'furniture_service.dart';

class CurrencyService {
  static final CurrencyService _instance = CurrencyService._internal();
  factory CurrencyService() => _instance;
  CurrencyService._internal();

  // Currency amounts
  int _peas = 0;
  int _coins = 0;

  // Getters
  int get peas => _peas;
  int get coins => _coins;

  // Constants
  static const int PEAS_PER_COIN = 100;

  /// Calculate peas earned from focus duration (with double time bonus + furniture boost)
  static int calculatePeasFromFocus(int minutes, {double upgradeMultiplier = 1.0}) {
    // Base peas = 1 per minute
    int basePeas = minutes;

    // Time bonus 1: +1 pea per 3 minutes
    int timeBonus1 = minutes ~/ 3;

    // Time bonus 2: +2 peas per 5 minutes (stacks with bonus 1!)
    int timeBonus2 = (minutes ~/ 5) * 2;

    // Total base (before multipliers)
    int totalBase = basePeas + timeBonus1 + timeBonus2;

    // Get furniture boost multiplier
    double furnitureMultiplier = FurnitureService().getBoostMultiplier();

    // Apply furniture boost AND upgrade multiplier
    int finalPeas = (totalBase * furnitureMultiplier * upgradeMultiplier).round();

    return finalPeas;
  }

  /// Initialize - Load saved currencies
  Future<void> init() async {
    await loadCurrencies();
  }

  /// Add peas (earned from focus sessions)
  Future<void> addPeas(int amount) async {
    if (amount < 0) return;
    _peas += amount;
    await saveCurrencies();
  }

  /// Remove peas (for upgrades or conversion)
  Future<bool> removePeas(int amount) async {
    if (amount < 0 || _peas < amount) return false;
    _peas -= amount;
    await saveCurrencies();
    return true;
  }

  /// Add coins
  Future<void> addCoins(int amount) async {
    if (amount < 0) return;
    _coins += amount;
    await saveCurrencies();
  }

  /// Remove coins (for upgrades)
  Future<bool> removeCoins(int amount) async {
    if (amount < 0 || _coins < amount) return false;
    _coins -= amount;
    await saveCurrencies();
    return true;
  }

  /// Convert peas to coins (100 peas = 1 coin)
  Future<bool> convertPeasToCoins(int peasAmount) async {
    if (peasAmount < PEAS_PER_COIN) return false;
    if (_peas < peasAmount) return false;

    // Calculate coins to give
    int coinsToGive = peasAmount ~/ PEAS_PER_COIN;
    int peasToRemove = coinsToGive * PEAS_PER_COIN;

    // Update currencies
    _peas -= peasToRemove;
    _coins += coinsToGive;

    await saveCurrencies();
    return true;
  }

  /// Check if can convert (have at least 100 peas)
  bool canConvert() {
    return _peas >= PEAS_PER_COIN;
  }

  /// Get max coins that can be converted
  int getMaxConvertibleCoins() {
    return _peas ~/ PEAS_PER_COIN;
  }

  /// Save currencies to storage
  Future<void> saveCurrencies() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('peas', _peas);
    await prefs.setInt('coins', _coins);
  }

  /// Load currencies from storage
  Future<void> loadCurrencies() async {
    final prefs = await SharedPreferences.getInstance();
    _peas = prefs.getInt('peas') ?? 0;
    _coins = prefs.getInt('coins') ?? 0;
  }

  /// Reset currencies (for testing)
  Future<void> reset() async {
    _peas = 0;
    _coins = 0;
    await saveCurrencies();
  }

  /// Debug: Add currencies for testing
  Future<void> addDebugCurrency({int peas = 0, int coins = 0}) async {
    _peas += peas;
    _coins += coins;
    await saveCurrencies();
  }
}