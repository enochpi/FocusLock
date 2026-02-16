import 'package:shared_preferences/shared_preferences.dart';
import 'furniture_service.dart';
import 'upgrade_service.dart';

class CurrencyService {
  static final CurrencyService _instance = CurrencyService._internal();
  factory CurrencyService() => _instance;
  CurrencyService._internal();

  // ========== CROP STAGE SYSTEM ==========
  int _currentStage = 0;

  static const List<Map<String, dynamic>> cropStages = [
    {'name': 'Peas', 'emoji': '🌱', 'rate': 100},
    {'name': 'Carrots', 'emoji': '🥕', 'rate': 70},
    {'name': 'Corn', 'emoji': '🌽', 'rate': 50},
    {'name': 'Strawberries', 'emoji': '🍓', 'rate': 30},
    {'name': 'Golden Wheat', 'emoji': '🌾', 'rate': 15},
  ];

  int get currentStage => _currentStage;
  String get cropName => cropStages[_currentStage]['name'];
  String get cropEmoji => cropStages[_currentStage]['emoji'];
  int get cropRate => cropStages[_currentStage]['rate'];

  // Currency amounts
  int _peas = 0;
  int _coins = 0;

  // Getters
  int get peas => _peas;
  int get coins => _coins;
  int get PEAS_PER_COIN => cropRate;

  // Max safe value
  static const int MAX_CURRENCY = 9000000000000000000;

  /// Calculate peas earned from focus duration
  static int calculatePeasFromFocus(int minutes, {double upgradeMultiplier = 1.0}) {
    int basePeas = minutes;
    int timeBonus1 = minutes ~/ 3;
    int timeBonus2 = (minutes ~/ 5) * 2;
    int totalBase = basePeas + timeBonus1 + timeBonus2;
    double furnitureMultiplier = FurnitureService().getBoostMultiplier();
    int finalPeas = (totalBase * furnitureMultiplier * upgradeMultiplier).round();
    return finalPeas;
  }

  /// Initialize
  Future<void> init() async {
    await loadCurrencies();
  }

  /// Upgrade to next house stage
  Future<bool> upgradeStage() async {
    int newStage = UpgradeService().currentStage;
    if (_currentStage >= cropStages.length - 1) return false;
    _currentStage++;
    _peas = 0;
    await saveCurrencies();
    return true;
  }

  /// Add peas (with overflow protection)
  Future<void> addPeas(int amount) async {
    if (amount < 0) return;
    _peas += amount;
    if (_peas > MAX_CURRENCY) _peas = MAX_CURRENCY;
    if (_peas < 0) _peas = 0;
    await saveCurrencies();
  }

  /// Remove peas
  Future<bool> removePeas(int amount) async {
    if (amount < 0 || _peas < amount) return false;
    _peas -= amount;
    await saveCurrencies();
    return true;
  }

  /// Add coins (with overflow protection)
  Future<void> addCoins(int amount) async {
    if (amount < 0) return;
    _coins += amount;
    if (_coins > MAX_CURRENCY) _coins = MAX_CURRENCY;
    if (_coins < 0) _coins = 0;
    await saveCurrencies();
  }

  /// Remove coins
  Future<bool> removeCoins(int amount) async {
    if (amount < 0 || _coins < amount) return false;
    _coins -= amount;
    await saveCurrencies();
    return true;
  }

  /// Convert crop to coins (dynamic rate)
  Future<bool> convertPeasToCoins(int peasAmount) async {
    if (peasAmount < PEAS_PER_COIN) return false;
    if (_peas < peasAmount) return false;

    int coinsToGive = peasAmount ~/ PEAS_PER_COIN;
    int peasToRemove = coinsToGive * PEAS_PER_COIN;

    _peas -= peasToRemove;
    _coins += coinsToGive;
    if (_coins > MAX_CURRENCY) _coins = MAX_CURRENCY;
    if (_coins < 0) _coins = 0;

    await saveCurrencies();
    return true;
  }

  /// Check if can convert
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
    await prefs.setString('peas', _peas.toString());
    await prefs.setString('coins', _coins.toString());
    await prefs.setInt('current_stage', _currentStage);
  }

  /// Load currencies from storage
  Future<void> loadCurrencies() async {
    final prefs = await SharedPreferences.getInstance();
    _currentStage = prefs.getInt('current_stage') ?? 0;

    final rawPeas = prefs.get('peas');
    if (rawPeas is String) {
      _peas = int.tryParse(rawPeas) ?? 0;
    } else if (rawPeas is int) {
      _peas = rawPeas;
    } else {
      _peas = 0;
    }

    final rawCoins = prefs.get('coins');
    if (rawCoins is String) {
      _coins = int.tryParse(rawCoins) ?? 0;
    } else if (rawCoins is int) {
      _coins = rawCoins;
    } else {
      _coins = 0;
    }
  }

  /// Reset currencies (for testing)
  Future<void> reset() async {
    _peas = 0;
    _coins = 0;
    _currentStage = 0;
    await saveCurrencies();
  }

  /// Debug: Add currencies for testing (with overflow protection)
  Future<void> addDebugCurrency({int peas = 0, int coins = 0}) async {
    _peas += peas;
    _coins += coins;
    if (_peas > MAX_CURRENCY) _peas = MAX_CURRENCY;
    if (_peas < 0) _peas = 0;
    if (_coins > MAX_CURRENCY) _coins = MAX_CURRENCY;
    if (_coins < 0) _coins = 0;
    await saveCurrencies();
  }
}