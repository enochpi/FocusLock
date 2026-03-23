import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:focus_life/painters/outdoor_sky_painter.dart';
import 'package:focus_life/screens/achievements_screen.dart';
import 'package:focus_life/services/achievements_service.dart';
import 'package:focus_life/services/daily_reward_service.dart';
import 'package:focus_life/services/stage_theme.dart';
import 'package:focus_life/services/streak_service.dart';
import 'package:focus_life/widgets/dialy_reward_dialog.dart';
import 'dart:async';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'dart:math' show Random;
import 'package:rive/rive.dart' hide LinearGradient, RadialGradient, Image;
import 'package:focus_life/models/character.dart';
import 'package:focus_life/models/farm.dart';
import 'package:focus_life/models/cave_decorations.dart';
import 'package:focus_life/services/storage_service.dart';
import 'package:focus_life/screens/garden_focus_screen.dart';
import 'package:focus_life/screens/cave_interior_screen.dart';
import 'package:focus_life/services/currency_service.dart';
import 'package:focus_life/widgets/converter_dialog.dart';
import 'package:focus_life/services/upgrade_service.dart';
import 'package:focus_life/services/furniture_service.dart';
import 'package:focus_life/services/facts_service.dart';
import 'package:focus_life/utils/number_formatter.dart';
import 'package:focus_life/painters/garden_painters.dart';
import 'package:focus_life/services/focus_session_service.dart';
import 'package:focus_life/widgets/achievement_notification.dart';

import '../furniture/flame.dart';
void resetCaveBoostFlags() {
  _CaveSceneScreenState.resetBoostFlags();
}

class CaveSceneScreen extends StatefulWidget {
  final Character character;
  final Farm farm;
  final CaveDecorations decorations;
  final VoidCallback onUpdate;

  const CaveSceneScreen({
    super.key,
    required this.character,
    required this.farm,
    required this.decorations,
    required this.onUpdate,
  });


  @override
  _CaveSceneScreenState createState() => _CaveSceneScreenState();
}

String _getHouseImage(int stage) {
  switch (stage) {
    case 0: return 'assets/images/cave.png';
    case 1: return 'assets/images/shack.png';
    case 2: return 'assets/images/house.png';
    default: return 'assets/images/cave.png';
  }
}

class _CaveSceneScreenState extends State<CaveSceneScreen> with TickerProviderStateMixin {
  StorageService storage = StorageService();
  final CurrencyService currency = CurrencyService();

  int _viewingStage = -1;

  // ── Static flags ──────────────────────────────────────────
  static bool torchesOwned  = false;
  static bool chimesOwned   = false;
  static bool fountainOwned = false;

  static void resetBoostFlags() {
    torchesOwned  = false;
    chimesOwned   = false;
    fountainOwned = false;
  }


  // ── Torch system (cave only) ──────────────────────────────────────────
  bool _torchPurchased = false;
  static const int    _torchCost  = 50;
  static const double _torchBoost = 0.15;

  // ── Wind chimes system (shack only) ──────────────────────────────────
  bool _windChimesPurchased = false;
  AnimationController? _chimesController;
  static const int    _windChimesCost  = 80;
  static const double _windChimesBoost = 0.10;

  // ── Fountain system (house only) ──────────────────────────────────────
  bool _fountainPurchased = false;
  AnimationController? _fountainController;
  static const int    _fountainCost  = 120;
  static const double _fountainBoost = 0.12;

  // ── Other state ───────────────────────────────────────────────────────
  double alexX = 150;
  double alexY = 300;
  bool facingRight = true;
  AnimationController? _walkController;
  AnimationController? _butterflyController;
  bool isWalking = false;

  double butterflyX = -50;
  double butterflyY = 0;
  bool showButterfly = false;

  double _caveScale   = 1.0;
  double _gardenScale = 1.0;

  // ── displayStage ─────────────────────────────────────────────────────
  int get displayStage {
    int stage = _viewingStage == -1
        ? UpgradeService().currentStage
        : _viewingStage;
    return stage.clamp(0, 2);
  }
  // ── initState ────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();

    _walkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..repeat(reverse: true);

    _butterflyController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    _chimesController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);

    _fountainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();

    _startButterflyLoop();
    _checkForRecoveredSession();
    _loadTorchState();
    _loadChimesState();
    _loadFountainState();

    AchievementService().onAchievementUnlocked = (achievement) {
      _grantAchievementRewards(achievement);
      if (mounted) showAchievementUnlocked(context, achievement);
    };

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && DailyRewardService().canClaimReward()) {
        showDailyRewardDialog(context);
      }
    });
  }

  @override
  void dispose() {
    _walkController?.dispose();
    _butterflyController?.dispose();
    _chimesController?.dispose();
    _fountainController?.dispose();
    super.dispose();
  }

  // ── Torch persistence ─────────────────────────────────────────────────
  Future<void> _loadTorchState() async {
    final prefs = await SharedPreferences.getInstance();
    final bought = prefs.getBool('torches_purchased') ?? false;
    if (bought && mounted) {
      setState(() {
        _torchPurchased = true;
        _CaveSceneScreenState.torchesOwned = true;
      });
    }
  }

  Future<void> _saveTorchState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('torches_purchased', true);
  }

  // ── Chimes persistence ────────────────────────────────────────────────
  Future<void> _loadChimesState() async {
    final prefs = await SharedPreferences.getInstance();
    final bought = prefs.getBool('wind_chimes_purchased') ?? false;
    if (bought && mounted) {
      setState(() {
        _windChimesPurchased = true;
        _CaveSceneScreenState.chimesOwned = true;
      });
    }
  }

  Future<void> _saveChimesState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('wind_chimes_purchased', true);
  }

  // ── Fountain persistence ──────────────────────────────────────────────
  Future<void> _loadFountainState() async {
    final prefs = await SharedPreferences.getInstance();
    final bought = prefs.getBool('fountain_purchased') ?? false;
    if (bought && mounted) {
      setState(() {
        _fountainPurchased = true;
        _CaveSceneScreenState.fountainOwned = true;
      });
    }
  }
  Widget _stageTab(int stage, String label) {
    final isActive = displayStage == stage;
    return GestureDetector(
      onTap: () => setState(() => _viewingStage = stage),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? Colors.white.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.white38,
            fontSize: 13,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Future<void> _saveFountainState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('fountain_purchased', true);
  }

  // ── Torch purchase dialog ─────────────────────────────────────────────
  void _onTorchSpotTapped() {
    if (_torchPurchased) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF16213e),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Buy Torches',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(width: 50, height: 110, child: CustomPaint(painter: _TorchPainter())),
                const SizedBox(width: 20),
                SizedBox(width: 50, height: 110, child: CustomPaint(painter: _TorchPainter())),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Place a pair of torches outside your cave entrance.',
              style: TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orange, width: 1.5),
              ),
              child: const Text('+15% 🌱 Pea Boost',
                  style: TextStyle(
                      color: Colors.orange, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD700).withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFD700), width: 1.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🪙', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 8),
                  Text('$_torchCost coins',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (currency.coins >= _torchCost) {
                Navigator.pop(ctx);
                await currency.removeCoins(_torchCost);
                await _saveTorchState();
                if (!mounted) return;
                setState(() {
                  _torchPurchased = true;
                  _CaveSceneScreenState.torchesOwned = true;
                });
              } else {
                Navigator.pop(ctx);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Not enough coins!')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD700),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Buy',
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ── Wind chimes purchase dialog ───────────────────────────────────────
  void _onWindChimesTapped() {
    if (_windChimesPurchased) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF16213e),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Buy Wind Chimes',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 80, height: 120,
              child: CustomPaint(painter: _WindChimesPainter(swing: 0.0)),
            ),
            const SizedBox(height: 12),
            const Text(
              'Hang wind chimes outside your shack entrance.',
              style: TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.tealAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.tealAccent, width: 1.5),
              ),
              child: const Text('+10% 🥕 Carrot Boost',
                  style: TextStyle(
                      color: Colors.tealAccent,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD700).withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFD700), width: 1.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🪙', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 8),
                  Text('$_windChimesCost coins',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (currency.coins >= _windChimesCost) {
                Navigator.pop(ctx);
                await currency.removeCoins(_windChimesCost);
                await _saveChimesState();
                if (!mounted) return;
                setState(() {
                  _windChimesPurchased = true;
                  _CaveSceneScreenState.chimesOwned = true;
                });
              } else {
                Navigator.pop(ctx);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Not enough coins!')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD700),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Buy',
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ── Fountain purchase dialog ──────────────────────────────────────────
  void _onFountainTapped() {
    if (_fountainPurchased) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF16213e),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Buy Garden Fountain',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 100, height: 100,
              child: CustomPaint(painter: _FountainPainter(ripple: 0.5)),
            ),
            const SizedBox(height: 12),
            const Text(
              'A stone fountain for your front garden.',
              style: TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blueAccent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blueAccent, width: 1.5),
              ),
              child: const Text('+12% 🌽 Corn Boost',
                  style: TextStyle(
                      color: Colors.blueAccent,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD700).withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFD700), width: 1.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🪙', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 8),
                  Text('$_fountainCost coins',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (currency.coins >= _fountainCost) {
                Navigator.pop(ctx);
                await currency.removeCoins(_fountainCost);
                await _saveFountainState();
                if (!mounted) return;
                setState(() {
                  _fountainPurchased = true;
                  _CaveSceneScreenState.fountainOwned = true;
                });
              } else {
                Navigator.pop(ctx);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Not enough coins!')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD700),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Buy',
                style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
  void openCave() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CaveInteriorScreen(
          character: widget.character,
          decorations: widget.decorations,
          stage: displayStage,
        ),
      ),
    ).then((_) {
      setState(() {});
      widget.onUpdate();
    });
  }

  void startFocus() async {
    int? minutes = await showDialog<int>(
      context: context,
      builder: (context) => const TimerPickerDialog(),
    );
    if (minutes != null && minutes > 0) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GardenFocusScreen(
            character: widget.character,
            focusDurationMinutes: minutes,
          ),
        ),
      ).then((_) {
        storage.saveCharacter(widget.character);
        setState(() {});
        widget.onUpdate();
      });
    }
  }

  void refreshCurrencyUI() => setState(() {});

  // ── Butterfly ─────────────────────────────────────────────────────────
  void _startButterflyLoop() {
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          showButterfly = true;
          butterflyX    = -50;
          butterflyY    = MediaQuery.of(context).size.height * 0.5;
        });
        _butterflyController?.forward(from: 0).then((_) {
          if (mounted) {
            setState(() => showButterfly = false);
            _startButterflyLoop();
          }
        });
      }
    });
  }

  // ── Alex movement ─────────────────────────────────────────────────────
  void moveAlexTo(double x, double y) {
    setState(() {
      if (x > alexX) facingRight = true;
      else if (x < alexX) facingRight = false;
      alexX    = x - 30;
      alexY    = y - 60;
      isWalking = true;
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => isWalking = false);
    });
  }

  // ── Achievement rewards ───────────────────────────────────────────────
  void _grantAchievementRewards(Achievement achievement) async {
    final currency = CurrencyService();
    for (var reward in achievement.rewards) {
      switch (reward.type) {
        case RewardType.coins:
          await currency.addCoins(reward.value as int);
          break;
        case RewardType.peas:
          await currency.addPeas(reward.value as int);
          break;
        case RewardType.furniture:
          FurnitureService().ownedFurniture.add(reward.value as String);
          await FurnitureService().saveFurniture();
          break;
        case RewardType.cosmetic:
          break;
        case RewardType.multiplier:
          break;
      }
    }
  }

  // ── BUILD ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final double screenW = MediaQuery.of(context).size.width;

    return SafeArea(
      child: Column(
        children: [
          // ── Top Bar ──────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: StageTheme.getTheme(UpgradeService().currentStage.clamp(0, 2)).shopHeaderColor,
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 2)),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Peas counter
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withOpacity(0.3),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF4CAF50), width: 2),
                  ),
                  child: Row(
                    children: [
                      Text(currency.cropEmoji, style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 6),
                      Text(NumberFormatter.format(currency.peas),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                // Debug +100
                GestureDetector(
                  onTap: () async {
                    await currency.addPeas(100000000000000000);
                    setState(() {});
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                        color: Colors.red, borderRadius: BorderRadius.circular(8)),
                    child: const Text('0',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
                // Achievements
                IconButton(
                  icon: const Icon(Icons.emoji_events, color: Color(0xFFFFD700)),
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const AchievementsScreen())),
                ),
                // Converter
                ElevatedButton(
                  onPressed: () async {
                    bool? converted = await showConverterDialog(context);
                    if (converted == true) refreshCurrencyUI();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(currency.cropEmoji, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward, size: 16, color: Colors.white),
                      const SizedBox(width: 4),
                      const Text('🪙', style: TextStyle(fontSize: 16)),
                    ],
                  ),
                ),
                // Coins counter
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD700).withOpacity(0.3),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFFFD700), width: 2),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🪙', style: TextStyle(fontSize: 20)),
                        const SizedBox(width: 6),
                        Text(NumberFormatter.format(currency.coins),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (UpgradeService().currentStage > 0)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 6),
              color: Colors.black26,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Colors.black38,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _stageTab(0, '🪨 Cave'),
                        if (UpgradeService().currentStage >= 1) _stageTab(1, '🛖 Shack'),
                        if (UpgradeService().currentStage >= 2) _stageTab(2, '🏠 House'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // ── Scene ────────────────────────────────────────────────────
          Expanded(
            child: GestureDetector(
              onTapDown: (d) => moveAlexTo(d.localPosition.dx, d.localPosition.dy),
              onPanUpdate: (d) => moveAlexTo(d.localPosition.dx, d.localPosition.dy),
              child: SizedBox(
                width: double.infinity,
                child: Stack(
                  children: [
                    // Sky
                    Positioned.fill(child: CustomPaint(painter: OutdoorSkyPainter())),

                    // Grass
                    Positioned(
                      bottom: 0, left: 0, right: 0,
                      height: MediaQuery.of(context).size.height * 0.4,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              StageTheme.getTheme(displayStage).groundColor,
                              StageTheme.getTheme(displayStage).groundAccent,
                            ],
                          ),
                        ),
                        child: CustomPaint(painter: GrassTexturePainter()),
                      ),
                    ),

                    // House / Cave image
                    Positioned(
                      top: 50,
                      left: MediaQuery.of(context).size.width * 0.16,
                      child: GestureDetector(
                        onTapDown: (_) => setState(() => _caveScale = 0.95),
                        onTapUp: (_) {
                          setState(() => _caveScale = 1.0);
                          openCave();
                        },
                        onTapCancel: () => setState(() => _caveScale = 1.0),
                        child: AnimatedScale(
                          scale: _caveScale,
                          duration: const Duration(milliseconds: 100),
                          child: SizedBox(
                            width: MediaQuery.of(context).size.width * 0.7,
                            height: 350,
                            child: Image.asset(_getHouseImage(displayStage),
                                fit: BoxFit.contain),
                          ),
                        ),
                      ),
                    ),

                    // ── TORCHES (cave only, stage 0) ──────────────────
                    if (displayStage == 0) ...[
                      // Left torch
                      Positioned(
                        top: 180,
                        left: screenW * 0.38,
                        child: GestureDetector(
                          onTap: _onTorchSpotTapped,
                          child: FlameWidget(width: 30, height: 40, opacity: _torchPurchased ? 1.0 : 0.18),
                        ),
                      ),
                      // Right torch
                      Positioned(
                        top: 180,
                        left: screenW * 0.58,
                        child: GestureDetector(
                          onTap: _onTorchSpotTapped,
                          child: FlameWidget(width: 30, height: 40, opacity: _torchPurchased ? 1.0 : 0.18),
                        ),
                      ),
                    ],

                    // ── WIND CHIMES (shack only, stage 1) ────────────
                    if (displayStage == 1)
                      Positioned(
                        top: 230,
                        left: screenW * 0.57,
                        child: GestureDetector(
                          onTap: _onWindChimesTapped,
                          child: SizedBox(
                            width: 30, height: 60,
                            child: _windChimesPurchased
                                ? AnimatedBuilder(
                              animation: _chimesController!,
                              builder: (_, __) => CustomPaint(
                                size: const Size(30, 60),
                                painter: _WindChimesPainter(
                                  swing: (_chimesController!.value - 0.5) * 0.3,
                                ),
                              ),
                            )
                                : Opacity(
                              opacity: 0.18,
                              child: CustomPaint(
                                  size: const Size(30, 60),
                                  painter: _WindChimesPainter(swing: 0.0)),
                            ),
                          ),
                        ),
                      ),

                    // ── FOUNTAIN (house only, stage 2) ────────────────
                    if (displayStage == 2)
                      Positioned(
                        top: 280,
                        left: screenW * 0.41,
                        child: GestureDetector(
                          onTap: _onFountainTapped,
                          child: SizedBox(
                            width: 90, height: 90,
                            child: _fountainPurchased
                                ? AnimatedBuilder(
                              animation: _fountainController!,
                              builder: (_, __) => CustomPaint(
                                painter: _FountainPainter(
                                  ripple: _fountainController!.value,
                                ),
                              ),
                            )
                                : Opacity(
                              opacity: 0.18,
                              child: CustomPaint(
                                  painter: _FountainPainter(ripple: 0.4)),
                            ),
                          ),
                        ),
                      ),

                    // Garden painter
                    Positioned(
                      bottom: MediaQuery.of(context).size.height * 0.05,
                      left: MediaQuery.of(context).size.width * 0.05,
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width * 0.9,
                        height: 240,
                        child: CustomPaint(
                          painter: getGardenPainter(displayStage),
                          size: Size.infinite,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 30, left: 0, right: 0,
                      child: Center(
                        child: GestureDetector(
                          onTapDown: (_) => setState(() => _gardenScale = 0.95),
                          onTapUp: (_) {
                            setState(() => _gardenScale = 1.0);
                            startFocus();
                          },
                          onTapCancel: () => setState(() => _gardenScale = 1.0),
                          child: AnimatedScale(
                            scale: _gardenScale,
                            duration: const Duration(milliseconds: 100),
                            curve: Curves.easeInOut,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 35, vertical: 16),
                              decoration: BoxDecoration(
                                color: StageTheme.getTheme(
                                    UpgradeService().currentStage.clamp(0, 2))
                                    .primaryColor,
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: const [
                                  BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 10,
                                      offset: Offset(0, 4)),
                                ],
                              ),
                              child: const Text('Focus',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1)),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Alex character
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      left: alexX,
                      top:  alexY,
                      child: GestureDetector(
                        onTap: _showRandomFact,
                        child: _buildAlex(),
                      ),
                    ),

                    // Butterfly
                    if (showButterfly && _butterflyController != null)
                      AnimatedBuilder(
                        animation: _butterflyController!,
                        builder: (context, _) {
                          double progress  = _butterflyController!.value;
                          double screenWidth = MediaQuery.of(context).size.width;
                          double x = -50 + (screenWidth + 100) * progress;
                          double y = butterflyY + math.sin(progress * math.pi * 4) * 30;
                          return Positioned(
                            left: x, top: y,
                            child: Transform.rotate(
                              angle: math.sin(progress * math.pi * 8) * 0.2,
                              child: const Text('🦋',
                                  style: TextStyle(fontSize: 24)),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helper widgets / dialogs ──────────────────────────────────────────
  void _showRandomFact() {
    final fact = FactsService().getRandomFact();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF16213e),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              width: 50, height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFF00d4ff).withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF00d4ff), width: 2),
              ),
              child: const Center(child: Text('😊', style: TextStyle(fontSize: 30))),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.character.name,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                  const Text('says...',
                      style: TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
        content: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0f3460).withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: const Color(0xFF00d4ff).withOpacity(0.3), width: 2),
          ),
          child: Text(fact,
              style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.5)),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00d4ff),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Cool! 😎',
                style:
                TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildAlex() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
              color: Colors.black54, borderRadius: BorderRadius.circular(10)),
          child: Text(widget.character.name,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 5),

        Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..scale(facingRight ? 1.0 : -1.0, 1.0),
          child: SizedBox(
            width: 140, height: 170,
            child: RiveAnimation.asset(
              'assets/animations/bob_idle.riv',
              fit: BoxFit.contain,
              stateMachines: const ['State Machine 1'],
            ),
          ),
        ),
      ],
    );
  }

  // ── Session recovery ──────────────────────────────────────────────────
  Future<void> _checkForRecoveredSession() async {
    final sessionService = FocusSessionService();
    final hasSession = await sessionService.hasActiveSession();
    if (!hasSession) return;
    final sessionData = await sessionService.getActiveSession();
    if (sessionData == null || !mounted) return;
    if (sessionData.wasCompleted) {
      _showSessionCompletedDialog(sessionData);
    } else {
      _showResumeSessionDialog(sessionData);
    }
  }

  void _showSessionCompletedDialog(FocusSessionData session) async {
    double torchMultiplier = (_CaveSceneScreenState.torchesOwned  ? 1.15 : 1.0)
        * (_CaveSceneScreenState.chimesOwned   ? 1.10 : 1.0)
        * (_CaveSceneScreenState.fountainOwned ? 1.12 : 1.0);

    int peasEarned = CurrencyService.calculatePeasFromFocus(
      session.durationMinutes,
      upgradeMultiplier: UpgradeService().getTotalMultiplier(),
      torchMultiplier: torchMultiplier,
    );
    await CurrencyService().addPeas(peasEarned);
    int earnings = session.durationMinutes * 5;
    widget.character.earnMoney(earnings);
    widget.character.addFocusMinutes(session.durationMinutes);
    await StreakService().recordFocusSession();
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2d2d2d),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Session Completed! 🎉',
            style: TextStyle(color: Colors.white), textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Your focus session finished while the app was closed!',
                style: TextStyle(color: Colors.white70),
                textAlign: TextAlign.center),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF4CAF50), width: 2),
              ),
              child: Column(
                children: [
                  Text('$peasEarned ${CurrencyService().cropEmoji}',
                      style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4CAF50))),
                  const SizedBox(height: 8),
                  Text('${session.durationMinutes} minutes completed!',
                      style: const TextStyle(color: Colors.white70)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Awesome!',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  void _showResumeSessionDialog(FocusSessionData session) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2d2d2d),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Resume Focus Session?',
            style: TextStyle(color: Colors.white), textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('You have an active focus session:',
                style: TextStyle(color: Colors.white70),
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text('${session.durationMinutes} minute session',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('${session.remainingSeconds ~/ 60} minutes remaining',
                      style: const TextStyle(color: Color(0xFF4CAF50))),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await FocusSessionService().cancelSession();
              Navigator.pop(context);
            },
            child: const Text('Cancel Session',
                style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GardenFocusScreen(
                    character: widget.character,
                    focusDurationMinutes: session.durationMinutes,
                  ),
                ),
              ).then((_) {
                setState(() {});
                widget.onUpdate();
              });
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50)),
            child: const Text('Resume',
                style:
                TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// TORCH PAINTER
// ═══════════════════════════════════════════════════════════════
class _TorchPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;

    // Handle
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - 5, size.height * 0.45, 10, size.height * 0.55),
        const Radius.circular(3),
      ),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8B5E3C), Color(0xFF5C3A1E)],
        ).createShader(Rect.fromLTWH(cx - 5, 0, 10, size.height)),
    );

    // Bowl
    canvas.drawPath(
      Path()
        ..moveTo(cx - 12, size.height * 0.45)
        ..lineTo(cx + 12, size.height * 0.45)
        ..lineTo(cx + 8,  size.height * 0.55)
        ..lineTo(cx - 8,  size.height * 0.55)
        ..close(),
      Paint()..color = const Color(0xFF7A4E2D),
    );

    // Flame outer
    canvas.drawPath(
      Path()
        ..moveTo(cx, 0)
        ..cubicTo(cx + 14, size.height * 0.10, cx + 14, size.height * 0.28, cx, size.height * 0.46)
        ..cubicTo(cx - 14, size.height * 0.28, cx - 14, size.height * 0.10, cx, 0)
        ..close(),
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(0, 0.4),
          radius: 0.8,
          colors: [Color(0xFFFFD700), Color(0xFFFF6600)],
        ).createShader(Rect.fromLTWH(cx - 14, 0, 28, size.height * 0.5)),
    );

    // Flame inner
    canvas.drawPath(
      Path()
        ..moveTo(cx, size.height * 0.06)
        ..cubicTo(cx + 7, size.height * 0.14, cx + 7, size.height * 0.30, cx, size.height * 0.44)
        ..cubicTo(cx - 7, size.height * 0.30, cx - 7, size.height * 0.14, cx, size.height * 0.06)
        ..close(),
      Paint()
        ..color = const Color(0xFFFFF176).withOpacity(0.85)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    // Glow
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx, size.height * 0.25), width: 36, height: 42),
      Paint()
        ..color = const Color(0xFFFF8C00).withOpacity(0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ═══════════════════════════════════════════════════════════════
// FOUNTAIN PAINTER
// ═══════════════════════════════════════════════════════════════
class _FountainPainter extends CustomPainter {
  final double ripple;
  const _FountainPainter({required this.ripple});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final by = size.height * 0.82;
    final arcPhase = math.sin(ripple * math.pi * 2);

    // ── Shadow ────────────────────────────────────────────────
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, by + 5), width: 88, height: 14),
      Paint()..color = Colors.black.withOpacity(0.18),
    );

    // ── Outer basin back rim ──────────────────────────────────
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, by - 20), width: 84, height: 26),
      Paint()..color = const Color(0xFF757575),
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, by - 20), width: 84, height: 26),
      Paint()
        ..color = const Color(0xFF9E9E9E)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );

    // ── Basin side body ───────────────────────────────────────
    // Dark side (left)
    canvas.drawPath(
      Path()
        ..moveTo(cx - 42, by - 20)
        ..lineTo(cx - 42, by - 2)
        ..lineTo(cx, by - 2)
        ..lineTo(cx, by - 20)
        ..close(),
      Paint()..color = const Color(0xFF616161),
    );
    // Light side (right)
    canvas.drawPath(
      Path()
        ..moveTo(cx, by - 20)
        ..lineTo(cx, by - 2)
        ..lineTo(cx + 42, by - 2)
        ..lineTo(cx + 42, by - 20)
        ..close(),
      Paint()..color = const Color(0xFF757575),
    );

    // ── Front rim ─────────────────────────────────────────────
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, by - 2), width: 84, height: 26),
      Paint()..color = const Color(0xFF9E9E9E),
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, by - 2), width: 84, height: 26),
      Paint()
        ..color = const Color(0xFFBDBDBD)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5,
    );
    // Front rim highlight strip
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, by - 4), width: 64, height: 8),
      Paint()..color = Colors.white.withOpacity(0.20),
    );

    // ── Water surface ─────────────────────────────────────────
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, by - 20), width: 72, height: 20),
      Paint()..color = const Color(0xFF1565C0).withOpacity(0.9),
    );
    // Water color variation
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx + 8, by - 22), width: 36, height: 10),
      Paint()..color = const Color(0xFF1E88E5).withOpacity(0.6),
    );
    // Water shimmer
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx - 12, by - 22), width: 22, height: 5),
      Paint()..color = Colors.white.withOpacity(0.28),
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx + 10, by - 19), width: 10, height: 3),
      Paint()..color = Colors.white.withOpacity(0.15),
    );

    // ── Ripples ───────────────────────────────────────────────
    for (int i = 0; i < 3; i++) {
      final phase = (ripple + i / 3.0) % 1.0;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx, by - 20),
          width: 6 + phase * 52,
          height: (6 + phase * 52) * 0.28,
        ),
        Paint()
          ..color = Colors.white.withOpacity((1 - phase) * 0.38)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
    }

    // ── Pedestal base ─────────────────────────────────────────
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, by - 22), width: 20, height: 7),
      Paint()..color = const Color(0xFF616161),
    );
    // Pedestal column
    canvas.drawPath(
      Path()
        ..moveTo(cx - 6, by - 22)
        ..lineTo(cx - 5, by - 56)
        ..lineTo(cx + 5, by - 56)
        ..lineTo(cx + 6, by - 22)
        ..close(),
      Paint()..color = const Color(0xFF757575),
    );
    // Column highlight
    canvas.drawPath(
      Path()
        ..moveTo(cx - 1, by - 22)
        ..lineTo(cx - 1, by - 56)
        ..lineTo(cx + 2, by - 56)
        ..lineTo(cx + 2, by - 22)
        ..close(),
      Paint()..color = Colors.white.withOpacity(0.15),
    );
    // Pedestal cap
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, by - 56), width: 18, height: 6),
      Paint()..color = const Color(0xFFAAAAAA),
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, by - 57), width: 14, height: 4),
      Paint()..color = Colors.white.withOpacity(0.25),
    );

    // ── Water arcs ────────────────────────────────────────────
    for (int side in [-1, 1]) {
      final endX = cx + side * 30;
      final endY = by - 18 + arcPhase * 1.5;
      final ctrlX = cx + side * 16;
      final ctrlY = by - 68 + arcPhase * 2.5;

      final arcPath = Path()
        ..moveTo(cx, by - 56)
        ..quadraticBezierTo(ctrlX, ctrlY, endX, endY);

      // Arc glow
      canvas.drawPath(arcPath,
          Paint()
            ..color = const Color(0xFF42A5F5).withOpacity(0.25)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 6
            ..strokeCap = StrokeCap.round);
      // Arc body
      canvas.drawPath(arcPath,
          Paint()
            ..color = const Color(0xFF90CAF9)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5
            ..strokeCap = StrokeCap.round);
      // Arc highlight
      canvas.drawPath(arcPath,
          Paint()
            ..color = Colors.white.withOpacity(0.4)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1
            ..strokeCap = StrokeCap.round);

      // Splash droplets at landing
      for (int d = 0; d < 3; d++) {
        final dPhase = (ripple * 3 + d / 3.0) % 1.0;
        final angle = (side == -1 ? math.pi * 0.7 : math.pi * 0.3) +
            d * 0.3 * side;
        canvas.drawCircle(
          Offset(
            endX + math.cos(angle) * dPhase * 6,
            endY - math.sin(angle) * dPhase * 5,
          ),
          (1.5 - dPhase) * 2.5,
          Paint()..color = const Color(0xFFBBDEFB).withOpacity(1 - dPhase),
        );
      }
    }

    // ── Center spout ──────────────────────────────────────────
    final spoutH = 22 + arcPhase * 4;
    // Spout glow
    canvas.drawLine(
      Offset(cx, by - 56),
      Offset(cx, by - 56 - spoutH),
      Paint()
        ..color = const Color(0xFF42A5F5).withOpacity(0.3)
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round,
    );
    // Spout body
    canvas.drawLine(
      Offset(cx, by - 56),
      Offset(cx, by - 56 - spoutH),
      Paint()
        ..color = const Color(0xFF90CAF9)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
    // Spout highlight
    canvas.drawLine(
      Offset(cx - 0.5, by - 56),
      Offset(cx - 0.5, by - 56 - spoutH),
      Paint()
        ..color = Colors.white.withOpacity(0.35)
        ..strokeWidth = 1
        ..strokeCap = StrokeCap.round,
    );
    // Top droplet
    canvas.drawCircle(
      Offset(cx, by - 56 - spoutH), 5,
      Paint()..color = const Color(0xFF90CAF9),
    );
    canvas.drawCircle(
      Offset(cx, by - 56 - spoutH), 3,
      Paint()..color = const Color(0xFFBBDEFB),
    );
    canvas.drawCircle(
      Offset(cx, by - 56 - spoutH), 1.5,
      Paint()..color = Colors.white.withOpacity(0.9),
    );
  }

  @override
  bool shouldRepaint(_FountainPainter old) => old.ripple != ripple;
}

// ═══════════════════════════════════════════════════════════════
// WIND CHIMES PAINTER
// ═══════════════════════════════════════════════════════════════
class _WindChimesPainter extends CustomPainter {
  final double swing;
  const _WindChimesPainter({required this.swing});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    const double s = 0.40; // scale factor

    canvas.save();
    canvas.translate(cx, 0);
    canvas.rotate(swing);
    canvas.translate(-cx, 0);

    final woodPaint = Paint()
      ..color = const Color(0xFFa0724a)
      ..strokeWidth = 3 * s
      ..strokeCap = StrokeCap.round;

    final stringPaint = Paint()
      ..color = const Color(0xFFdddddd)
      ..strokeWidth = 1.2 * s;

    final chimePaint = Paint()
      ..color = const Color(0xFFc8d8e8)
      ..style = ui.PaintingStyle.fill;

    final chimeStroke = Paint()
      ..color = const Color(0xFF8aabcc)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 1 * s;

    canvas.drawLine(Offset(cx, 0), Offset(cx, 14 * s), stringPaint);
    canvas.drawLine(Offset(cx - 28 * s, 14 * s), Offset(cx + 28 * s, 14 * s), woodPaint);

    final chimeXs  = [cx - 24.0 * s, cx - 12.0 * s, cx, cx + 12.0 * s, cx + 24.0 * s];
    final chimeLens = [38.0 * s, 50.0 * s, 44.0 * s, 48.0 * s, 36.0 * s];

    for (int i = 0; i < 5; i++) {
      final x   = chimeXs[i];
      final len = chimeLens[i];

      canvas.drawLine(Offset(x, 14 * s), Offset(x, 20 * s), stringPaint);

      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(x, 20 * s + len / 2), width: 7 * s, height: len),
        const Radius.circular(3 * s),
      );
      canvas.drawRRect(rect, chimePaint);
      canvas.drawRRect(rect, chimeStroke);

      canvas.drawLine(
        Offset(x - 1.5 * s, 22 * s),
        Offset(x - 1.5 * s, 20 * s + len - 6 * s),
        Paint()
          ..color = Colors.white.withOpacity(0.4)
          ..strokeWidth = 1.5 * s,
      );
    }

    canvas.drawCircle(Offset(cx, 20 * s + chimeLens[2] + 6 * s), 4 * s, chimePaint);
    canvas.drawCircle(Offset(cx, 20 * s + chimeLens[2] + 6 * s), 4 * s, chimeStroke);

    canvas.restore();
  }

  @override
  bool shouldRepaint(_WindChimesPainter old) => old.swing != swing;
}

// ═══════════════════════════════════════════════════════════════
// MISC PAINTERS (kept for compatibility)
// ═══════════════════════════════════════════════════════════════
class RaggedClothPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF3d3426)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawLine(const Offset(5, 10), const Offset(15, 15), paint);
    canvas.drawLine(const Offset(20, 8), const Offset(25, 18), paint);
    canvas.drawLine(const Offset(10, 25), const Offset(18, 30), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class GrassTexturePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Random random = Random(123);
    for (int i = 0; i < 150; i++) {
      double x     = random.nextDouble() * size.width;
      double baseY  = random.nextDouble() * size.height;
      double h      = 15 + random.nextDouble() * 12;
      double w      = 1.5 + random.nextDouble();
      double bend   = (random.nextDouble() - 0.5) * 5;
      double cr     = random.nextDouble();
      Color color   = cr < 0.3
          ? const Color(0xFF689F38)
          : cr < 0.6
          ? const Color(0xFF7CB342)
          : const Color(0xFF8BC34A);
      canvas.drawPath(
        Path()
          ..moveTo(x, baseY + h)
          ..quadraticBezierTo(x + bend, baseY + h / 2, x + bend * 1.5, baseY),
        Paint()..color = color..strokeWidth = w..strokeCap = StrokeCap.round,
      );
    }
    for (int i = 0; i < 12; i++) {
      double x = random.nextDouble() * size.width;
      double y = random.nextDouble() * size.height;
      final colors = [
        const Color(0xFFFFEB3B), const Color(0xFFFFFFFF),
        const Color(0xFFFF69B4), const Color(0xFFE1BEE7),
      ];
      canvas.drawCircle(Offset(x, y), 2,
          Paint()..color = colors[random.nextInt(colors.length)]);
      canvas.drawLine(Offset(x, y), Offset(x, y + 5),
          Paint()..color = const Color(0xFF558B2F)..strokeWidth = 1);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ═══════════════════════════════════════════════════════════════
// TIMER PICKER DIALOG
// ═══════════════════════════════════════════════════════════════
class TimerPickerDialog extends StatefulWidget {
  const TimerPickerDialog({super.key});

  @override
  _TimerPickerDialogState createState() => _TimerPickerDialogState();
}

class _TimerPickerDialogState extends State<TimerPickerDialog> {
  double selectedMinutes = 25.0;
  Timer? _repeatTimer;

  void _startRepeating(int direction) {
    _repeatTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      setState(() {
        selectedMinutes = (selectedMinutes + direction).clamp(1, 600);
      });
    });
  }

  void _stopRepeating() {
    _repeatTimer?.cancel();
    _repeatTimer = null;
  }

  @override
  void dispose() {
    _repeatTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    int minutes = selectedMinutes.round();
    int hours   = minutes ~/ 60;
    int mins    = minutes % 60;

    String timeDisplay;
    if (hours > 0 && mins > 0)      timeDisplay = '${hours}hr ${mins}min';
    else if (hours > 0)             timeDisplay = '${hours}hr';
    else                            timeDisplay = '${mins}min';

    // Combined multiplier including torch and chimes boosts
    double totalMultiplier = UpgradeService().getTotalMultiplier()
        * (_CaveSceneScreenState.torchesOwned  ? 1.15 : 1.0)
        * (_CaveSceneScreenState.chimesOwned   ? 1.10 : 1.0)
        * (_CaveSceneScreenState.fountainOwned ? 1.12 : 1.0);

    int peaEarnings = CurrencyService.calculatePeasFromFocus(
      minutes,
      upgradeMultiplier: totalMultiplier,
    );

    return AlertDialog(
      backgroundColor: const Color(0xFF16213e),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Choose Focus Duration',
          style: TextStyle(
              color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Time selector row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () =>
                    setState(() { if (selectedMinutes > 1) selectedMinutes -= 1; }),
                onLongPressStart: (_) => _startRepeating(-1),
                onLongPressEnd:   (_) => _stopRepeating(),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.remove, color: Colors.white70, size: 28),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                children: [
                  Text(timeDisplay,
                      style: const TextStyle(
                          color: Color(0xFF4CAF50),
                          fontSize: 29,
                          fontWeight: FontWeight.bold)),
                  Text('($minutes minutes)',
                      style: const TextStyle(
                          color: Colors.white38, fontSize: 15)),
                ],
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: () =>
                    setState(() { if (selectedMinutes < 600) selectedMinutes += 1; }),
                onLongPressStart: (_) => _startRepeating(1),
                onLongPressEnd:   (_) => _stopRepeating(),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.add, color: Colors.white70, size: 28),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Slider
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor:   const Color(0xFF4CAF50),
              inactiveTrackColor: const Color(0xFF2d3e5f),
              thumbColor:         const Color(0xFF4CAF50),
              overlayColor:       const Color(0xFF4CAF50).withOpacity(0.3),
              thumbShape:         const RoundSliderThumbShape(enabledThumbRadius: 12),
              trackHeight:        6,
            ),
            child: Slider(
              value: selectedMinutes, min: 1, max: 600, divisions: 599,
              onChanged: (v) => setState(() => selectedMinutes = v),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('1min',  style: TextStyle(color: Colors.white54, fontSize: 12)),
                Text('10hrs', style: TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Earnings box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF4CAF50), width: 2),
            ),
            child: Column(
              children: [
                const Text('You will earn:',
                    style: TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 8),
                Text('~${NumberFormatter.format(peaEarnings)} ${CurrencyService().cropEmoji}',
                    style: const TextStyle(
                        color: Color(0xFF4CAF50),
                        fontSize: 36,
                        fontWeight: FontWeight.bold)),
                Text(CurrencyService().cropName.toLowerCase(),
                    style: const TextStyle(color: Colors.white60, fontSize: 14)),
                const SizedBox(height: 12),
                // Furniture boost
                Text(FurnitureService().getBoostString(),
                    style: const TextStyle(
                        color: Colors.amber,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
                const Text('Furniture Boost',
                    style: TextStyle(color: Colors.white54, fontSize: 12)),
                const SizedBox(height: 8),
                // Upgrade boost
                Text(UpgradeService().getBonusPercentageString(),
                    style: const TextStyle(
                        color: Colors.cyanAccent,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
                const Text('Upgrade Boost',
                    style: TextStyle(color: Colors.white54, fontSize: 12)),
                const SizedBox(height: 8),
                // Torch boost
                Text(
                  _CaveSceneScreenState.torchesOwned ? '+15%' : '+0%',
                  style: const TextStyle(
                      color: Colors.orangeAccent,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
                const Text('Torch Boost',
                    style: TextStyle(color: Colors.white54, fontSize: 12)),
                const SizedBox(height: 8),
                // Wind chimes boost
                Text(
                  _CaveSceneScreenState.chimesOwned ? '+10%' : '+0%',
                  style: const TextStyle(
                      color: Colors.tealAccent,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
                const Text('Wind Chimes Boost',
                    style: TextStyle(color: Colors.white54, fontSize: 12)),
                const SizedBox(height: 8),
                // Fountain boost
                Text(
                  _CaveSceneScreenState.fountainOwned ? '+12%' : '+0%',
                  style: const TextStyle(
                      color: Colors.blueAccent,
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
                const Text('Fountain Boost',
                    style: TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel',
              style: TextStyle(color: Colors.white54, fontSize: 16)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, selectedMinutes.round()),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4CAF50),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Start Focus',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
        ),
      ],
    );
  }
}