import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/character.dart';
import '../models/farm.dart';
import 'furniture_service.dart';

class StorageService {
  static const String CHARACTER_KEY = 'character_data';
  static const String FARM_KEY = 'farm_data';

  // Save character
  Future<void> saveCharacter(Character character) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(character.toJson());
      await prefs.setString(CHARACTER_KEY, json);
      debugPrint("💾 Character saved!");
    } catch (e) {
      debugPrint("❌ Error saving character: $e");
    }
  }

  // Load character
  Future<Character?> loadCharacter() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(CHARACTER_KEY);

      if (json != null) {
        debugPrint("📂 Character loaded!");
        return Character.fromJson(jsonDecode(json));
      }
    } catch (e) {
      debugPrint("❌ Error loading character: $e");
    }
    return null;
  }

  Future<void> resetAll() async {
    final prefs = await SharedPreferences.getInstance();

    // Core game data
    await prefs.remove(CHARACTER_KEY);
    await prefs.remove(FARM_KEY);
    await prefs.remove('cave_decorations');

    // Currency
    await prefs.remove('coins');
    await prefs.remove('peas');

    // Furniture
    await prefs.remove('owned_furniture');
    await prefs.remove('placed_furniture');

    // Upgrades
    await prefs.remove('upgrades');
    await prefs.remove('current_stage');

    // Achievements
    await prefs.remove('achievement_progress');

    // Streak & daily reward
    await prefs.remove('last_focus_date');
    await prefs.remove('current_streak');
    await prefs.remove('last_reward_date');

    // Torches / chimes / fountain
    await prefs.setBool('torches_purchased', false);
    await prefs.setBool('wind_chimes_purchased', false);
    await prefs.setBool('fountain_purchased', false);

    // Focus session
    await prefs.remove('active_focus_session');

    // In-memory reset
    FurnitureService().ownedFurniture.clear();
    for (var key in FurnitureService().placedFurniture.keys) {
      FurnitureService().placedFurniture[key] = null;
    }

    debugPrint("🗑️ Full reset complete");
  }

  // Save farm
  Future<void> saveFarm(Farm farm) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      List<Map<String, dynamic>> cropsJson = farm.crops.map((crop) => {
        'type': crop.type,
        'growthProgress': crop.growthProgress,
        'growthRequired': crop.growthRequired,
        'sellPrice': crop.sellPrice,
        'plantedAt': crop.plantedAt.toIso8601String(),
      }).toList();

      Map<String, dynamic> farmData = {
        'crops': cropsJson,
        'maxPlots': farm.maxPlots,
      };

      await prefs.setString(FARM_KEY, jsonEncode(farmData));
      debugPrint("💾 Farm saved! ${farm.crops.length} crops");
    } catch (e) {
      debugPrint("❌ Error saving farm: $e");
    }
  }

  // Load farm
  Future<Farm> loadFarm() async {
    Farm farm = Farm();

    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(FARM_KEY);

      if (json != null) {
        Map<String, dynamic> farmData = jsonDecode(json);
        List<dynamic> cropsJson = farmData['crops'] ?? [];
        farm.maxPlots = farmData['maxPlots'] ?? 5;

        farm.crops = cropsJson.map((c) {
          Crop crop = Crop(
            type: c['type'],
            growthRequired: c['growthRequired'],
            sellPrice: c['sellPrice'],
          );
          crop.growthProgress = c['growthProgress'];
          return crop;
        }).toList();

        debugPrint("📂 Farm loaded! ${farm.crops.length} crops");
      }
    } catch (e) {
      debugPrint("❌ Error loading farm: $e");
    }

    return farm;
  }

  // Clear all data (for testing)
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    debugPrint("🗑️ All data cleared");
  }
}