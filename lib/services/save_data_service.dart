import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'currency_service.dart';
import 'upgrade_service.dart';
import 'furniture_service.dart';
import 'streak_service.dart';

class SaveDataService {
  static final SaveDataService _instance = SaveDataService._internal();
  factory SaveDataService() => _instance;
  SaveDataService._internal();

  Future<Map<String, dynamic>> _buildSaveData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'version': 1,
      'exported_at': DateTime.now().toIso8601String(),
      'currency': {
        'peas': CurrencyService().peas,
        'coins': CurrencyService().coins,
        'stage': CurrencyService().currentStage,
      },
      'upgrades': {
        'purchased': UpgradeService().allUpgrades
            .where((u) => u.isPurchased).map((u) => u.id).toList(),
        'house_unlocks': UpgradeService().houseUnlocks
            .where((u) => u.isPurchased).map((u) => u.id).toList(),
        'current_stage': UpgradeService().currentStage,
      },
      'furniture': {
        'owned': FurnitureService().ownedFurniture.toList(),
        'torches': prefs.getBool('torches_purchased') ?? false,
        'wind_chimes': prefs.getBool('wind_chimes_purchased') ?? false,
        'fountain': prefs.getBool('fountain_purchased') ?? false,
      },
      'streak': {
        'current': StreakService().currentStreak,
        'longest': StreakService().longestStreak,
        'last_focus_date': StreakService().lastFocusDate?.toIso8601String(),
        'daily_streak': prefs.getInt('daily_reward_streak') ?? 0,
        'daily_longest': prefs.getInt('daily_reward_longest') ?? 0,
        'daily_claimed': prefs.getBool('daily_reward_claimed') ?? false,
        'last_claim': prefs.getString('daily_reward_last_claim') ?? '',
      },
    };
  }

  Future<void> exportSave(BuildContext context) async {
    try {
      final data = await _buildSaveData();
      final jsonStr = const JsonEncoder.withIndent('  ').convert(data);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/focuslife_save.json');
      await file.writeAsString(jsonStr);
      await Share.shareXFiles([XFile(file.path)], subject: 'Focus Life Save Data');
    } catch (e) {
      debugPrint('Export error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }

  Future<void> shareExport(BuildContext context) => exportSave(context);

  Future<void> copyToClipboard(BuildContext context) async {
    try {
      final data = await _buildSaveData();
      final jsonStr = const JsonEncoder.withIndent('  ').convert(data);
      await Clipboard.setData(ClipboardData(text: jsonStr));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Save data copied to clipboard!'),
            backgroundColor: Color(0xFF4CAF50),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Copy failed: $e')),
        );
      }
    }
  }

  Future<bool> importSave(String jsonStr, BuildContext context) async {
    try {
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      final prefs = await SharedPreferences.getInstance();

      final currency = data['currency'] as Map<String, dynamic>?;
      if (currency != null) {
        await prefs.setString('peas', currency['peas'].toString());
        await prefs.setString('coins', currency['coins'].toString());
        await prefs.setInt('current_stage', currency['stage'] as int? ?? 0);
        await CurrencyService().init();
      }

      final upgrades = data['upgrades'] as Map<String, dynamic>?;
      if (upgrades != null) {
        await prefs.setStringList('purchased_upgrades',
            List<String>.from(upgrades['purchased'] ?? []));
        await prefs.setStringList('purchased_house_unlocks',
            List<String>.from(upgrades['house_unlocks'] ?? []));
        await prefs.setInt('current_stage', upgrades['current_stage'] as int? ?? 0);
        await UpgradeService().init();
      }

      final furniture = data['furniture'] as Map<String, dynamic>?;
      if (furniture != null) {
        await prefs.setStringList('owned_furniture',
            List<String>.from(furniture['owned'] ?? []));
        await prefs.setBool('torches_purchased', furniture['torches'] ?? false);
        await prefs.setBool('wind_chimes_purchased', furniture['wind_chimes'] ?? false);
        await prefs.setBool('fountain_purchased', furniture['fountain'] ?? false);
        await FurnitureService().init();
      }

      final streak = data['streak'] as Map<String, dynamic>?;
      if (streak != null) {
        await prefs.setInt('current_streak', streak['current'] as int? ?? 0);
        await prefs.setInt('longest_streak', streak['longest'] as int? ?? 0);
        if (streak['last_focus_date'] != null) {
          await prefs.setString('last_focus_date', streak['last_focus_date']);
        }
        await prefs.setInt('daily_reward_streak', streak['daily_streak'] ?? 0);
        await prefs.setInt('daily_reward_longest', streak['daily_longest'] ?? 0);
        await prefs.setBool('daily_reward_claimed', streak['daily_claimed'] ?? false);
        if ((streak['last_claim'] as String? ?? '').isNotEmpty) {
          await prefs.setString('daily_reward_last_claim', streak['last_claim']);
        }
        await StreakService().init();
      }

      return true;
    } catch (e) {
      debugPrint('Import error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import failed: $e')),
        );
      }
      return false;
    }
  }
}