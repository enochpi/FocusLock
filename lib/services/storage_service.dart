import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cave_decorations.dart';
import '../models/character.dart';
import '../models/farm.dart';

class StorageService {
  static const String CHARACTER_KEY = 'character_data';
  static const String FARM_KEY = 'farm_data';

  // Save character
  Future<void> saveCharacter(Character character) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(character.toJson());
      await prefs.setString(CHARACTER_KEY, json);
      print("💾 Character saved!");
    } catch (e) {
      print("❌ Error saving character: $e");
    }
  }

  // Load character
  Future<Character?> loadCharacter() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(CHARACTER_KEY);

      if (json != null) {
        print("📂 Character loaded!");
        return Character.fromJson(jsonDecode(json));
      }
    } catch (e) {
      print("❌ Error loading character: $e");
    }
    return null;
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
      print("💾 Farm saved! ${farm.crops.length} crops");
    } catch (e) {
      print("❌ Error saving farm: $e");
    }
  }
  Future<void> saveCaveDecorations(CaveDecorations decorations) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(decorations.toJson());
      await prefs.setString('cave_decorations', json);
      print("💾 Cave decorations saved!");
    } catch (e) {
      print("❌ Error saving decorations: $e");
    }
  }

  Future<CaveDecorations> loadCaveDecorations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString('cave_decorations');

      if (json != null) {
        print("📂 Cave decorations loaded!");
        return CaveDecorations.fromJson(jsonDecode(json));
      }
    } catch (e) {
      print("❌ Error loading decorations: $e");
    }
    return CaveDecorations();
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

        print("📂 Farm loaded! ${farm.crops.length} crops");
      }
    } catch (e) {
      print("❌ Error loading farm: $e");
    }

    return farm;
  }

  // Clear all data (for testing)
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    print("🗑️ All data cleared");
  }
}