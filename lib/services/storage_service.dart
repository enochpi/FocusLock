import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/character.dart';
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
    await prefs.remove('current_stage'); // house stage
    await prefs.remove('crop_stage');    // ✅ crop stage

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

  // Clear all data (for testing)
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    debugPrint("🗑️ All data cleared");
  }
}