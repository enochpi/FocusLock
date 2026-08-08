import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:berry_focused/painters/outdoor_sky_painter.dart';
import 'package:berry_focused/screens/achievements_screen.dart';
import 'package:berry_focused/screens/focus_stats_screen.dart';
import 'package:berry_focused/services/achievements_service.dart';
import 'package:berry_focused/services/daily_reward_service.dart';
import 'package:berry_focused/services/stage_theme.dart';
import 'package:berry_focused/services/streak_service.dart';
import 'package:berry_focused/widgets/dialy_reward_dialog.dart';
import 'dart:async';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'dart:math' show Random;
import 'package:berry_focused/models/character.dart';
import 'package:berry_focused/services/storage_service.dart';
import 'package:berry_focused/screens/garden_focus_screen.dart';
import 'package:berry_focused/screens/cave_interior_screen.dart';
import 'package:berry_focused/services/currency_service.dart';
import 'package:berry_focused/widgets/converter_dialog.dart';
import 'package:berry_focused/services/upgrade_service.dart';
import 'package:berry_focused/services/furniture_service.dart';
import 'package:berry_focused/services/facts_service.dart';
import 'package:berry_focused/utils/number_formatter.dart';
import 'package:berry_focused/painters/garden_painters.dart';
import 'package:berry_focused/services/focus_session_service.dart';
import 'package:berry_focused/services/focus_stats_service.dart';

import '../furniture/flame.dart';
import '../services/settings_service.dart';
import '../services/sound_service.dart';
void resetCaveBoostFlags() {
  _CaveSceneScreenState.resetBoostFlags();
}


class _AchievementGrantResult {
  final int coins;
  final int peas;
  final List<String> items;
  final bool alreadyGranted;

  const _AchievementGrantResult({
    required this.coins,
    required this.peas,
    required this.items,
    this.alreadyGranted = false,
  });

  bool get hasVisibleReward => coins > 0 || peas > 0 || items.isNotEmpty;

  String get summary {
    final parts = <String>[];
    if (coins > 0) parts.add('+$coins coins');
    if (peas > 0) parts.add('+$peas crops');
    parts.addAll(items.map((item) => '+$item'));
    return parts.isEmpty ? 'Achievement recorded' : parts.join('  •  ');
  }
}

class _AchievementNotice {
  final Achievement achievement;
  final _AchievementGrantResult result;

  const _AchievementNotice(this.achievement, this.result);
}

class CaveSceneScreen extends StatefulWidget {
  final Character character;
  final VoidCallback onUpdate;

  const CaveSceneScreen({
    super.key,
    required this.character,
    required this.onUpdate,
  });


  @override
  _CaveSceneScreenState createState() => _CaveSceneScreenState();
}

String _getHouseImage(int stage) {
  switch (stage) {
    case 0: return 'assets/images/cave.webp';
    case 1: return 'assets/images/shack.webp';
    case 2: return 'assets/images/house.webp';
    default: return 'assets/images/cave.webp';
  }
}


class _CaveSceneScreenState extends State<CaveSceneScreen> with TickerProviderStateMixin, WidgetsBindingObserver {
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
  AnimationController? _butterflyController;
  bool isWalking = false;
  Timer? _walkStopTimer;

  double butterflyX = -50;
  double butterflyY = 0;
  bool showButterfly = false;

  double _caveScale   = 1.0;
  double _gardenScale = 1.0;

  bool _dialogShowing = false;
  bool _openingFocus = false;
  bool _checkingRecoveredSession = false;
  bool _handlingRecoveredCompletion = false;

  // Achievement rewards can unlock while a purchase dialog is still open.
  // Queue notices so the player always sees why their balance changed.
  final List<_AchievementNotice> _achievementNotices = [];
  final Set<String> _queuedAchievementTitles = <String>{};
  bool _showingAchievementNotice = false;
  bool _achievementHandlerActive = true;

  // ── displayStage ─────────────────────────────────────────────────────
  int get displayStage {
    int stage = _viewingStage == -1
        ? UpgradeService().currentStage
        : _viewingStage;
    return stage.clamp(0, 2).toInt();
  }
  void resetViewingStage() {
    if (mounted) setState(() => _viewingStage = -1);
  }
  // ── initState ────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_checkForRecoveredSession());
    });
    _loadTorchState();
    _loadChimesState();
    _loadFountainState();

    if (!SoundService().isPlaying) SoundService().playBackgroundMusic();

    AchievementService().onAchievementUnlocked = (achievement) async {
      if (!_achievementHandlerActive) return;

      final result = await _grantAchievementRewardsOnce(achievement);
      if (!_achievementHandlerActive || !mounted) return;

      setState(() {});
      SoundService().playAchievement();
      _queueAchievementNotice(achievement, result);
    };
    Future.delayed(const Duration(milliseconds: 500), () async {
      final prefs = await SharedPreferences.getInstance();
      final isFirstLaunch = prefs.getBool('has_launched_before') ?? false;
      if (!isFirstLaunch) {
        await prefs.setBool('has_launched_before', true);
        return; // skip daily reward on very first launch
      }
      if (mounted && DailyRewardService().canClaimReward()) {
        await showDailyRewardDialog(context);
        if (mounted) setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _achievementHandlerActive = false;
    _achievementNotices.clear();
    _queuedAchievementTitles.clear();
    WidgetsBinding.instance.removeObserver(this);
    _walkStopTimer?.cancel();
    _butterflyController?.dispose();
    _chimesController?.dispose();
    _fountainController?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused) {
      SoundService().onAppBackground();
    } else if (state == AppLifecycleState.resumed) {
      SoundService().onAppForeground();
    } else if (state == AppLifecycleState.detached) {
      SoundService().stopMusic();
    }
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
      onTap: () => setState(() {
        // ✅ If tapping the current unlocked stage, reset to auto-follow
        // so future unlocks automatically switch the view
        if (stage == UpgradeService().currentStage) {
          _viewingStage = -1;
        } else {
          _viewingStage = stage;
        }
      }),
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
    if (_torchPurchased || _dialogShowing) return;
    _dialogShowing = true;
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
              child: const Text('+15% 🍓 Strawberry Boost',
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
    ).then((_) => _dialogShowing = false);
  }

  // ── Wind chimes purchase dialog ───────────────────────────────────────
  void _onWindChimesTapped() {
    if (_windChimesPurchased || _dialogShowing) return;
    _dialogShowing = true;
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
              child: const Text('+10% 🍓 Strawberry Boost',
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
    ).then((_) => _dialogShowing = false);
  }

  // ── Fountain purchase dialog ──────────────────────────────────────────
  void _onFountainTapped() {
    if (_fountainPurchased || _dialogShowing) return;
    _dialogShowing = true;
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
              child: const Text('+12% 🍓 strawberry Boost',
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
    ).then((_) => _dialogShowing = false);
  }
  void openCave() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CaveInteriorScreen(
          character: widget.character,
          stage: displayStage,
        ),
      ),
    ).then((_) {
      setState(() {
        _viewingStage = -1; // ✅ reset so displayStage follows currentStage
      });
      widget.onUpdate();
    });
  }

  Future<void> startFocus() async {
    if (_openingFocus) return;
    _openingFocus = true;

    try {
      final sessionService = FocusSessionService();
      if (await sessionService.hasActiveSession()) {
        await _checkForRecoveredSession();
        return;
      }

      if (!mounted) return;
      final minutes = await showDialog<int>(
        context: context,
        builder: (_) => const TimerPickerDialog(),
      );

      if (!mounted || minutes == null || minutes <= 0) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => GardenFocusScreen(
            character: widget.character,
            focusDurationMinutes: minutes,
          ),
        ),
      );

      await storage.saveCharacter(widget.character);
      if (!mounted) return;
      setState(() {});
      widget.onUpdate();
    } finally {
      _openingFocus = false;
    }
  }

  Future<void> _openFocusStats() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FocusStatsScreen()),
    );

    if (mounted) setState(() {});
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
    _walkStopTimer?.cancel();
    _walkStopTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) setState(() => isWalking = false);
    });
  }

  // ── Achievement compatibility helpers ─────────────────────────────────
  // Different versions of achievements_service.dart have used `name`,
  // `title`, `id`, or `key`. Dynamic access keeps this screen compatible
  // without forcing a replacement of the user's achievement service.
  String _achievementLabel(Achievement achievement) {
    final dynamic value = achievement;

    try {
      final Object? name = value.name;
      if (name is String && name.trim().isNotEmpty) {
        return name.trim();
      }
    } catch (_) {}

    try {
      final Object? title = value.title;
      if (title is String && title.trim().isNotEmpty) {
        return title.trim();
      }
    } catch (_) {}

    try {
      final Object? id = value.id;
      if (id != null) {
        final text = id.toString().split('.').last.trim();
        if (text.isNotEmpty) return text;
      }
    } catch (_) {}

    return 'Achievement unlocked';
  }

  String _achievementStableKey(Achievement achievement) {
    final dynamic value = achievement;

    for (final getter in <Object? Function()>[
          () {
        try {
          return value.id;
        } catch (_) {
          return null;
        }
      },
          () {
        try {
          return value.key;
        } catch (_) {
          return null;
        }
      },
          () {
        try {
          return value.name;
        } catch (_) {
          return null;
        }
      },
          () {
        try {
          return value.title;
        } catch (_) {
          return null;
        }
      },
    ]) {
      final candidate = getter();
      if (candidate != null) {
        final normalized = candidate
            .toString()
            .trim()
            .toLowerCase()
            .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
            .replaceAll(RegExp(r'^_+|_+$'), '');

        if (normalized.isNotEmpty) return normalized;
      }
    }

    // Last-resort deterministic key for older achievement models.
    final rewardSignature = achievement.rewards
        .map((reward) => '${reward.type}:${reward.value}')
        .join('|');

    return '${achievement.runtimeType}:$rewardSignature'
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
  }

  // ── Achievement rewards ───────────────────────────────────────────────
  Future<_AchievementGrantResult> _grantAchievementRewardsOnce(
      Achievement achievement,
      ) async {
    final prefs = await SharedPreferences.getInstance();
    final achievementKey = _achievementStableKey(achievement);
    final rewardKey = 'achievement_reward_granted_$achievementKey';

    int coins = 0;
    int peas = 0;
    final items = <String>[];

    for (final reward in achievement.rewards) {
      switch (reward.type) {
        case RewardType.coins:
          coins += reward.value as int;
          break;
        case RewardType.peas:
          peas += reward.value as int;
          break;
        case RewardType.furniture:
          items.add(reward.value as String);
          break;
        case RewardType.cosmetic:
          items.add('cosmetic reward');
          break;
        case RewardType.multiplier:
          items.add('reward boost');
          break;
      }
    }

    // A callback can fire again after navigation or a rebuild. Never add the
    // same reward twice; instead show that it was already collected.
    if (prefs.getBool(rewardKey) ?? false) {
      return _AchievementGrantResult(
        coins: coins,
        peas: peas,
        items: items,
        alreadyGranted: true,
      );
    }

    // Write the marker before changing balances. This favors preventing
    // duplicate money over accidentally granting twice after a route rebuild.
    await prefs.setBool(rewardKey, true);

    final currency = CurrencyService();
    try {
      if (coins > 0) await currency.addCoins(coins);
      if (peas > 0) await currency.addPeas(peas);

      // Achievement rewards do not feed back into wealth achievements.
      // That old recursive call could unlock another reward immediately and
      // make the balance look like it randomly doubled.
      for (final item in items) {
        if (item == 'cosmetic reward' || item == 'reward boost') continue;
        if (!FurnitureService().ownedFurniture.contains(item)) {
          FurnitureService().ownedFurniture.add(item);
        }
      }
      if (items.any(
            (item) => item != 'cosmetic reward' && item != 'reward boost',
      )) {
        await FurnitureService().saveFurniture();
      }
    } catch (error) {
      debugPrint('Could not grant achievement reward: $error');
    }

    return _AchievementGrantResult(
      coins: coins,
      peas: peas,
      items: items,
    );
  }

  void _queueAchievementNotice(
      Achievement achievement,
      _AchievementGrantResult result,
      ) {
    if (!mounted) return;

    // The same achievement may be reported twice in one frame by two purchase
    // trackers. Keep only one notice in the queue.
    final achievementKey = _achievementStableKey(achievement);
    if (!_queuedAchievementTitles.add(achievementKey)) return;
    _achievementNotices.add(_AchievementNotice(achievement, result));
    unawaited(_drainAchievementNotices());
  }

  Future<void> _drainAchievementNotices() async {
    if (_showingAchievementNotice || !mounted) return;
    _showingAchievementNotice = true;

    try {
      while (_achievementNotices.isNotEmpty && mounted) {
        // Purchases use their own dialogs and routes. Wait until the cave is
        // visible again so the achievement cannot appear behind another UI.
        while (mounted &&
            (_dialogShowing || ModalRoute.of(context)?.isCurrent != true)) {
          await Future.delayed(const Duration(milliseconds: 180));
        }
        if (!mounted) break;

        final notice = _achievementNotices.removeAt(0);
        _queuedAchievementTitles.remove(
          _achievementStableKey(notice.achievement),
        );
        await _showAchievementRewardNotice(notice);
        await Future.delayed(const Duration(milliseconds: 120));
      }
    } finally {
      _showingAchievementNotice = false;
    }
  }

  Future<void> _showAchievementRewardNotice(
      _AchievementNotice notice,
      ) async {
    final result = notice.result;
    final message = result.alreadyGranted
        ? 'This achievement reward was already added earlier.'
        : result.hasVisibleReward
        ? 'Your balance changed because you earned:'
        : 'Achievement completed!';

    if (!SettingsService().achievementAlerts) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '🏆 ${_achievementLabel(notice.achievement)}: ${result.summary}',
          ),
          duration: const Duration(seconds: 4),
          backgroundColor: const Color(0xFF7B5E00),
        ),
      );
      return;
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: Color(0xFFFFD54F), width: 1.5),
        ),
        title: const Row(
          children: [
            Text('🏆', style: TextStyle(fontSize: 34)),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Achievement Unlocked!',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _achievementLabel(notice.achievement),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFFFD54F),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD54F).withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFFFFD54F).withOpacity(0.55),
                ),
              ),
              child: Text(
                result.summary,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFFFE082),
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFFD54F),
              foregroundColor: Colors.black,
            ),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
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
              color: StageTheme.getTheme(
                  UpgradeService().currentStage.clamp(0, 2).toInt()
              ).shopHeaderColor,
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 2)),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Peas counter
                // Peas counter
                GestureDetector(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
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
                ),

                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 36,
                      height: 36,
                      child: IconButton(
                        tooltip: 'Focus Stats',
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(
                          Icons.insights_rounded,
                          color: Color(0xFF81C784),
                          size: 22,
                        ),
                        onPressed: _openFocusStats,
                      ),
                    ),
                    SizedBox(
                      width: 36,
                      height: 36,
                      child: IconButton(
                        tooltip: 'Achievements',
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(
                          Icons.emoji_events,
                          color: Color(0xFFFFD700),
                          size: 22,
                        ),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AchievementsScreen(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                // Converter
                ElevatedButton(
                  onPressed: () async {
                    bool? converted = await showConverterDialog(context);
                    if (converted == true) refreshCurrencyUI();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
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
          Visibility(
            visible: UpgradeService().currentStage > 0,
            maintainSize: true,
            maintainAnimation: true,
            maintainState: true,
            child: Container(
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
                      top: 70,
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
                        top: 200,
                        left: screenW * 0.38,
                        child: GestureDetector(
                          onTap: _onTorchSpotTapped,
                          child: FlameWidget(width: 30, height: 40, opacity: _torchPurchased ? 1.0 : 0.18),
                        ),
                      ),
                      // Right torch
                      Positioned(
                        top: 200,
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
                                    UpgradeService().currentStage.clamp(0, 2).toInt()
                                )
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
    if (_dialogShowing) return;
    _dialogShowing = true;
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
    ).then((_) => _dialogShowing = false);
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
            width: 140,
            height: 170,
            child: Image.asset(
              'assets/images/farmer.png',
              fit: BoxFit.contain,
            ),
          ),
        ),
      ],
    );
  }

  // ── Session recovery ──────────────────────────────────────────────────
  Future<void> _checkForRecoveredSession() async {
    if (_checkingRecoveredSession) return;
    _checkingRecoveredSession = true;

    try {
      final sessionService = FocusSessionService();
      final sessionData = await sessionService.getActiveSession();
      if (sessionData == null || !mounted) return;

      if (sessionData.wasCompleted) {
        await _showSessionCompletedDialog(sessionData);
      } else {
        _showResumeSessionDialog(sessionData);
      }
    } finally {
      _checkingRecoveredSession = false;
    }
  }

  Future<void> _showSessionCompletedDialog(
      FocusSessionData session,
      ) async {
    if (_handlingRecoveredCompletion) return;
    _handlingRecoveredCompletion = true;
    int peasEarned = CurrencyService.calculatePeasFromFocus(
      session.durationMinutes,
      upgradeMultiplier:  UpgradeService().getTotalMultiplier(),
      torchMultiplier:    _CaveSceneScreenState.torchesOwned  ? 1.15 : 1.0,
      chimesMultiplier:   _CaveSceneScreenState.chimesOwned   ? 1.10 : 1.0, // ✅
      fountainMultiplier: _CaveSceneScreenState.fountainOwned ? 1.12 : 1.0, // ✅
    );
    await CurrencyService().addPeas(peasEarned);
    await AchievementService().onPeasEarned(peasEarned); // ✅ add this
    int earnings = session.durationMinutes * 5;
    widget.character.earnMoney(earnings);
    widget.character.addFocusMinutes(session.durationMinutes);
    await StorageService().saveCharacter(widget.character);
    await StreakService().recordFocusSession();
    await FocusStatsService().recordSession(
      plannedMinutes: session.durationMinutes,
      focusedMinutes: session.durationMinutes,
      mode: FocusStatsService.modeForMinutes(session.durationMinutes),
      peasEarned: peasEarned,
      completed: true,
    );
    await FocusSessionService().acknowledgeCompletion();
    if (!mounted) {
      _handlingRecoveredCompletion = false;
      return;
    }
    await showDialog<void>(
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
    _handlingRecoveredCompletion = false;
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
              final elapsedSeconds =
                  (session.durationMinutes * 60) - session.remainingSeconds;
              final elapsedMinutes = (elapsedSeconds ~/ 60)
                  .clamp(0, session.durationMinutes)
                  .toInt();

              await FocusSessionService().cancelSession();
              await FocusStatsService().recordSession(
                plannedMinutes: session.durationMinutes,
                focusedMinutes: elapsedMinutes,
                mode: FocusStatsService.modeForMinutes(
                  session.durationMinutes,
                ),
                peasEarned: 0,
                completed: false,
              );

              if (!mounted) return;
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
                    initialRemainingSeconds: session.remainingSeconds, // ✅
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50)),
            child: const Text('Resume',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
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

class _FocusMode {
  final String emoji;
  final String title;
  final String subtitle;
  final int minutes;

  const _FocusMode({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.minutes,
  });
}

class _TimerPickerDialogState extends State<TimerPickerDialog> {
  double selectedMinutes = 25.0;
  Timer? _repeatTimer;
  bool _submitting = false;

  static const List<_FocusMode> _quickModes = [
    _FocusMode(
      emoji: '🧪',
      title: 'Practice',
      subtitle: 'test the timer',
      minutes: 1,
    ),
    _FocusMode(
      emoji: '⚡',
      title: 'Homework Panic',
      subtitle: 'quick push',
      minutes: 15,
    ),
    _FocusMode(
      emoji: '📚',
      title: 'Study',
      subtitle: 'classic focus',
      minutes: 25,
    ),
    _FocusMode(
      emoji: '📵',
      title: 'No Phone',
      subtitle: 'reset your brain',
      minutes: 30,
    ),
    _FocusMode(
      emoji: '🧠',
      title: 'Deep Work',
      subtitle: 'serious session',
      minutes: 50,
    ),
  ];

  void _startRepeating(int direction) {
    _repeatTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      setState(() {
        selectedMinutes =
            (selectedMinutes + direction).clamp(1, 420).toDouble();
      });
    });
  }

  void _stopRepeating() {
    _repeatTimer?.cancel();
    _repeatTimer = null;
  }

  void _startMode(int minutes) {
    if (_submitting) return;
    _submitting = true;
    _stopRepeating();
    Navigator.pop(context, minutes);
  }

  Widget _buildQuickModeButton(_FocusMode mode) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => _startMode(mode.minutes),
      child: Container(
        width: 142,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFF4CAF50).withOpacity(0.45),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(mode.emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 6),
            Text(
              mode.title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${mode.minutes} min',
              style: const TextStyle(
                color: Color(0xFF4CAF50),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              mode.subtitle,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white54, fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _repeatTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    int minutes = selectedMinutes.round().clamp(1, 420).toInt();
    int hours   = minutes ~/ 60;
    int mins    = minutes % 60;

    String timeDisplay;
    if (hours > 0 && mins > 0)      timeDisplay = '${hours}hr ${mins}min';
    else if (hours > 0)             timeDisplay = '${hours}hr';
    else                            timeDisplay = '${mins}min';

    double totalMultiplier = UpgradeService().getTotalMultiplier()
        * (_CaveSceneScreenState.torchesOwned ? 1.15 : 1.0);

    int peaEarnings = CurrencyService.calculatePeasFromFocus(
      minutes,
      upgradeMultiplier:  totalMultiplier,
      chimesMultiplier:   _CaveSceneScreenState.chimesOwned   ? 1.10 : 1.0,
      fountainMultiplier: _CaveSceneScreenState.fountainOwned ? 1.12 : 1.0,
    );

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      backgroundColor: const Color(0xFF16213e),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text(
        'Start a Focus Session',
        style: TextStyle(
            color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Quick Start',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 10),

            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: _quickModes.map(_buildQuickModeButton).toList(),
            ),

            const SizedBox(height: 18),
            Container(height: 1, color: Colors.white.withOpacity(0.12)),
            const SizedBox(height: 14),

            const Text(
              'Custom Time',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),

            // Time selector row
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () =>
                      setState(() => selectedMinutes =
                          (selectedMinutes - 5).clamp(1, 420).toDouble()),
                  onLongPressStart: (_) => _startRepeating(-5),
                  onLongPressEnd:   (_) => _stopRepeating(),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.remove, color: Colors.white70, size: 24),
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  children: [
                    Text(
                      timeDisplay,
                      style: const TextStyle(
                        color: Color(0xFF4CAF50),
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '($minutes minutes)',
                      style: const TextStyle(color: Colors.white38, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(width: 14),
                GestureDetector(
                  onTap: () =>
                      setState(() => selectedMinutes =
                          (selectedMinutes + 5).clamp(1, 420).toDouble()),
                  onLongPressStart: (_) => _startRepeating(5),
                  onLongPressEnd:   (_) => _stopRepeating(),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.add, color: Colors.white70, size: 24),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

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
                value: selectedMinutes.clamp(1, 420).toDouble(),
                min: 1,
                max: 420,
                divisions: 419,
                onChanged: (v) {
                  setState(() {
                    selectedMinutes = (v / 5).round() * 5.0;
                    if (selectedMinutes < 1) selectedMinutes = 1;
                  });
                },
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('1min',  style: TextStyle(color: Colors.white54, fontSize: 12)),
                  Text('7hrs', style: TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Earnings box
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF4CAF50), width: 2),
              ),
              child: Column(
                children: [
                  const Text('Custom session will earn:',
                      style: TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 6),
                  Text(
                    '~${NumberFormatter.format(peaEarnings)} ${CurrencyService().cropEmoji}',
                    style: const TextStyle(
                      color: Color(0xFF4CAF50),
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    CurrencyService().cropName.toLowerCase(),
                    style: const TextStyle(color: Colors.white60, fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel',
              style: TextStyle(color: Colors.white54, fontSize: 16)),
        ),
        ElevatedButton(
          onPressed: _submitting
              ? null
              : () {
            _submitting = true;
            _stopRepeating();
            Navigator.pop(context, minutes);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4CAF50),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text(
            'Start Custom',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16),
          ),
        ),
      ],
    );
  }
}