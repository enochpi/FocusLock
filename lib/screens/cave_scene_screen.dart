import 'package:flutter/material.dart';
import 'package:focus_life/painters/outdoor_sky_painter.dart';
import 'package:focus_life/services/stage_theme.dart';
import 'package:focus_life/services/streak_service.dart';
import 'dart:async';
import 'dart:math' as math;
import 'dart:math' show Random;
import 'package:rive/rive.dart' hide LinearGradient, RadialGradient;
import '../models/character.dart';
import '../models/farm.dart';
import '../models/cave_decorations.dart';
import '../services/storage_service.dart';
import 'garden_focus_screen.dart';
import 'cave_interior_screen.dart';
import '../services/currency_service.dart';
import '../widgets/converter_dialog.dart';
import '../services/upgrade_service.dart';
import '../services/furniture_service.dart';
import '../services/facts_service.dart';
import '../utils/number_formatter.dart';
import '../painters/house_painters.dart';
import '../painters/garden_painters.dart';
import '../services/focus_session_service.dart';





class CaveSceneScreen extends StatefulWidget {
  final Character character;
  final Farm farm;
  final CaveDecorations decorations;
  final VoidCallback onUpdate;

  const CaveSceneScreen({super.key, 
    required this.character,
    required this.farm,
    required this.decorations,
    required this.onUpdate,
  });

  @override
  _CaveSceneScreenState createState() => _CaveSceneScreenState();
}

class _CaveSceneScreenState extends State<CaveSceneScreen> with TickerProviderStateMixin {
  StorageService storage = StorageService();
  final CurrencyService currency = CurrencyService();

  int _viewingStage = -1;

  int get displayStage => _viewingStage == -1
      ? UpgradeService().currentStage
      : _viewingStage;

  void refreshCurrencyUI() {
    setState(() {});
  }

  double alexX = 150;
  double alexY = 300;
  bool facingRight = true;
  AnimationController? _walkController;
  AnimationController? _butterflyController;
  bool isWalking = false;

  // Butterfly animation
  double butterflyX = -50;
  double butterflyY = 0;
  bool showButterfly = false;

  // Cave click animation
  double _caveScale = 1.0;

  // Garden click animation
  double _gardenScale = 1.0;

  @override
  void initState() {
    super.initState();
    _walkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..repeat(reverse: true);

    // Butterfly controller
    _butterflyController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );

    // Start butterfly animation periodically
    _startButterflyLoop();

    // ✅ CHECK FOR RECOVERED SESSION
    _checkForRecoveredSession();
  }

  void _startButterflyLoop() {
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          showButterfly = true;
          butterflyX = -50;
          butterflyY = MediaQuery.of(context).size.height * 0.5;
        });

        _butterflyController?.forward(from: 0).then((_) {
          if (mounted) {
            setState(() {
              showButterfly = false;
            });
            _startButterflyLoop(); // Loop again
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _walkController?.dispose();
    _butterflyController?.dispose();
    super.dispose();
  }

  void moveAlexTo(double x, double y) {
    setState(() {
      if (x > alexX) {
        facingRight = true;
      } else if (x < alexX) {
        facingRight = false;
      }

      alexX = x - 30;
      alexY = y - 60;
      isWalking = true;
    });

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          isWalking = false;
        });
      }
    });
  }

  void openCave() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CaveInteriorScreen(
          character: widget.character,
          decorations: widget.decorations,
          stage: displayStage,  // ← ADD THIS
        ),
      ),
    ).then((_) {
      setState(() {});
      widget.onUpdate();
    });
  }
  // ✅ UPDATED - Goes to garden instead of FocusActiveScreen
  void startFocus() async {
    int? minutes = await showDialog<int>(
      context: context,
      builder: (context) => const TimerPickerDialog(),
    );

    if (minutes != null && minutes > 0) {
      // ✅ Navigate to GARDEN instead!
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GardenFocusScreen(
            character: widget.character,
            focusDurationMinutes: minutes,
          ),
        ),
      ).then((_) {
        // Save and update after returning from garden
        storage.saveCharacter(widget.character);
        setState(() {});
        widget.onUpdate();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // Top Bar
          // Top Bar - Currency System
          // Top Bar - Currency System
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: StageTheme.getTheme(UpgradeService().currentStage).shopHeaderColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Peas counter (left)
                // Peas counter (left) - DYNAMIC CROP
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
                      Text(
                        NumberFormatter.format(currency.peas),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () async {
                    await currency.addPeas(100000000000000000);
                    setState(() {});
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text("+100000000000000000", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),


                // Converter button (center)
                // Converter button (center) - DYNAMIC CROP
                ElevatedButton(
                  onPressed: () async {
                    bool? converted = await showConverterDialog(context);
                    if (converted == true) refreshCurrencyUI();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4CAF50),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(currency.cropEmoji, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward, size: 16, color: Colors.white),
                      const SizedBox(width: 4),
                      const Text("🪙", style: TextStyle(fontSize: 16)),
                    ],
                  ),
                ),

                // Coins counter (right)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700).withOpacity(0.3),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFFD700), width: 2),
                  ),
                  child: Row(
                    children: [
                      const Text("🪙", style: TextStyle(fontSize: 20)),
                      const SizedBox(width: 6),
                      Text(
                        NumberFormatter.format(currency.coins),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Cave Scene
          Expanded(
            child: GestureDetector(
              onTapDown: (details) {
                moveAlexTo(
                  details.localPosition.dx,
                  details.localPosition.dy,
                );
              },
              onPanUpdate: (details) {
                moveAlexTo(
                  details.localPosition.dx,
                  details.localPosition.dy,
                );
              },
              child: SizedBox(
                width: double.infinity,
                child: Stack(
                  children: [
                    // SKY (top portion)
                    Positioned.fill(
                      child: CustomPaint(
                        painter: OutdoorSkyPainter(),
                      ),
                    ),

                    // GRASS (bottom portion)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      height: MediaQuery.of(context).size.height * 0.4, // Bottom 40%
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
                        child: CustomPaint(
                          painter: GrassTexturePainter(),
                        ),
                      ),
                    ),

                    if (displayStage == 0)
                    // Keep your existing Rive cave for stage 0
                      Positioned(
                        top: MediaQuery.of(context).size.height * 0.2 - 176,
                        left: MediaQuery.of(context).size.width / 2 - 140,
                        child: SizedBox(
                          width: 300,
                          height: 350,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              AnimatedScale(
                                scale: _caveScale,
                                duration: const Duration(milliseconds: 100),
                                curve: Curves.easeInOut,
                                child: const RiveAnimation.asset(
                                  'assets/animations/cave.riv',
                                  fit: BoxFit.contain,
                                  alignment: Alignment.bottomCenter,
                                  stateMachines: ['State Machine 1'],
                                ),
                              ),
                              Positioned(
                                left: 50, top: 150,
                                child: GestureDetector(
                                  behavior: HitTestBehavior.translucent,
                                  onTapDown: (_) => setState(() => _caveScale = .95),
                                  onTapUp: (_) { setState(() => _caveScale = 1.0); openCave(); },
                                  onTapCancel: () => setState(() => _caveScale = 1.0),
                                  child: Container(
                                    width: 230, height: 200,
                                    color: Colors.transparent,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                    // CustomPainter house for stages 1-3
                      Positioned(
                        top: 154,
                        left: MediaQuery.of(context).size.width * 0.25,
                        child: GestureDetector(
                          onTapDown: (_) => setState(() => _caveScale = 0.95),
                          onTapUp: (_) { setState(() => _caveScale = 1.0); openCave(); },
                          onTapCancel: () => setState(() => _caveScale = 1.0),
                          child: AnimatedScale(
                            scale: _caveScale,
                            duration: const Duration(milliseconds: 100),
                            child: SizedBox(
                              width: MediaQuery.of(context).size.width * 0.5,
                              height: 150,
                              child: CustomPaint(
                                painter: getHousePainter(displayStage),
                                size: Size.infinite,
                              ),
                            ),
                          ),
                        ),
                      ),


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
                      bottom: 300,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (displayStage > 0)
                            GestureDetector(
                              onTap: () => setState(() { _viewingStage = displayStage - 1; }),
                              child: Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                                child: Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
                              ),
                            )
                          else SizedBox(width: 34),
                          SizedBox(width: 12),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(16)),
                            child: Text(
                              ['Cave', 'Shack', 'House', 'Mansion'][displayStage] +
                                  (displayStage == UpgradeService().currentStage ? '' : '  👀'),
                              style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                          ),
                          SizedBox(width: 12),
                          if (displayStage < UpgradeService().currentStage)
                            GestureDetector(
                              onTap: () => setState(() { _viewingStage = displayStage + 1; }),
                              child: Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                                child: Icon(Icons.arrow_forward_ios, color: Colors.white, size: 18),
                              ),
                            )
                          else SizedBox(width: 34),
                        ],
                      ),
                    ),
                    // FOCUS BUTTON (better centered)
                    Positioned(
                      bottom: 30,
                      left: 0,
                      right: 0, // This makes it truly centered
                      child: Center(
                        child: GestureDetector(
                          onTapDown: (_) {
                            setState(() => _gardenScale = 0.95);
                          },
                          onTapUp: (_) {
                            setState(() => _gardenScale = 1.0);
                            startFocus();
                          },
                          onTapCancel: () {
                            setState(() => _gardenScale = 1.0);
                          },
                          child: AnimatedScale(
                            scale: _gardenScale,
                            duration: const Duration(milliseconds: 100),
                            curve: Curves.easeInOut,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 35, vertical: 16),
                              decoration: BoxDecoration(
                                color: StageTheme.getTheme(UpgradeService().currentStage).primaryColor,
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 10,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Text(
                                "Focus",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Alex
                    // Alex (tappable for facts!)
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      left: alexX,
                      top: alexY,
                      child: GestureDetector(
                        onTap: () => _showRandomFact(),  // ← ADD THIS
                        child: _buildAlex(),
                      ),
                    ),
                    // Animated Butterfly
                    if (showButterfly && _butterflyController != null)
                      AnimatedBuilder(
                        animation: _butterflyController!,
                        builder: (context, child) {
                          double progress = _butterflyController!.value;
                          double screenWidth = MediaQuery.of(context).size.width;

                          // Butterfly flies from left to right
                          double x = -50 + (screenWidth + 100) * progress;

                          // Sine wave motion for natural flight
                          double y = butterflyY + math.sin(progress * math.pi * 4) * 30;

                          return Positioned(
                            left: x,
                            top: y,
                            child: Transform.rotate(
                              angle: math.sin(progress * math.pi * 8) * 0.2, // Wing flapping
                              child: const Text(
                                "🦋",
                                style: TextStyle(fontSize: 24),
                              ),
                            ),
                          );
                        },
                      ),
                    // TOP BAR WITH CURRENCIES
                    // TOP BAR WITH CURRENCIES (SIMPLIFIED)

                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  // ============================================================
// ✅ COMPLETE UPDATED METHOD
// Replace the _showRandomFact() method in cave_scene_screen.dart
// ============================================================

  void _showRandomFact() {
    final FactsService facts = FactsService();
    String fact = facts.getRandomFact();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF16213e),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            // Character avatar (large emoji circle)
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFF00d4ff).withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF00d4ff),
                  width: 2,
                ),
              ),
              child: const Center(
                child: Text(
                  '😊', // ← Change this to any emoji you want!
                  style: TextStyle(fontSize: 30),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Character name + "says..."
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.character.name, // ← This shows "Bob", "Fred", etc.
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'says...',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        // The fact itself in a styled box
        content: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0f3460).withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF00d4ff).withOpacity(0.3),
              width: 2,
            ),
          ),
          child: Text(
            fact,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ),

        // Close button
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00d4ff),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Cool! 😎',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlex() {
    return Column(
      children: [
        // Name tag
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            widget.character.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 5),

        // Bob Rive animation
        Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()..scale(facingRight ? 1.0 : -1.0, 1.0),
          child: const SizedBox(
            width: 140,   // ← INCREASED from 60
            height: 170, // ← INCREASED from 80
            child: RiveAnimation.asset(
              'assets/animations/bob_idle.riv',
              fit: BoxFit.contain,
              stateMachines: ['State Machine 1'],
            ),
          ),
        ),
      ],
    );
  }
  Future<void> _checkForRecoveredSession() async {
    final sessionService = FocusSessionService();
    final hasSession = await sessionService.hasActiveSession();

    if (!hasSession) return;

    final sessionData = await sessionService.getActiveSession();

    if (sessionData == null) return;

    if (!mounted) return;

    // If session was completed while app was closed
    if (sessionData.wasCompleted) {
      _showSessionCompletedDialog(sessionData);
    } else {
      // Session still in progress, ask to resume
      _showResumeSessionDialog(sessionData);
    }
  }

  void _showSessionCompletedDialog(FocusSessionData session) async {
    // Calculate rewards
    double multiplier = UpgradeService().getTotalMultiplier();
    int peasEarned = CurrencyService.calculatePeasFromFocus(
      session.durationMinutes,
      upgradeMultiplier: multiplier,
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
        title: const Text(
          "Session Completed! 🎉",
          style: TextStyle(color: Colors.white),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Your focus session finished while the app was closed!",
              style: TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
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
                  Text(
                    "$peasEarned ${CurrencyService().cropEmoji}",
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4CAF50),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "${session.durationMinutes} minutes completed!",
                    style: const TextStyle(color: Colors.white70),
                  ),
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
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                "Awesome!",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
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
        title: const Text(
          "Resume Focus Session?",
          style: TextStyle(color: Colors.white),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "You have an active focus session:",
              style: TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    "${session.durationMinutes} minute session",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "${session.remainingSeconds ~/ 60} minutes remaining",
                    style: const TextStyle(color: Color(0xFF4CAF50)),
                  ),
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
            child: const Text(
              "Cancel Session",
              style: TextStyle(color: Colors.red),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GardenFocusScreen(
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
              backgroundColor: const Color(0xFF4CAF50),
            ),
            child: const Text(
              "Resume",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCaveDecorations() {
    return [
      Positioned(
        top: 50,
        left: 10,
        child: _buildRock(40, 60),
      ),
      Positioned(
        top: 80,
        right: 20,
        child: _buildRock(50, 50),
      ),
      Positioned(
        bottom: 150,
        left: 30,
        child: _buildRock(35, 45),
      ),
      Positioned(
        bottom: 200,
        right: 40,
        child: _buildRock(45, 55),
      ),
      Positioned(
        bottom: 180,
        left: 50,
        child: Column(
          children: [
            const Text("🔥", style: TextStyle(fontSize: 30)),
            Container(
              width: 40,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.brown[900],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    ];
  }

  Widget _buildRock(double width, double height) {
    return Container(
      width: width,
      height: height,
      decoration: const BoxDecoration(
        color: Color(0xFF3a3a3a),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(25),
          bottomLeft: Radius.circular(10),
          bottomRight: Radius.circular(15),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 8,
            offset: Offset(2, 4),
          ),
        ],
      ),
    );
  }

  Widget _buildStatBox(String emoji, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0f3460),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class RaggedClothPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF3d3426)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawLine(const Offset(5, 10), const Offset(15, 15), paint);
    canvas.drawLine(const Offset(20, 8), const Offset(25, 18), paint);
    canvas.drawLine(const Offset(10, 25), const Offset(18, 30), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Realistic grass texture painter
class GrassTexturePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Random random = Random(123); // Fixed seed for consistency

    // Draw individual grass blades with variation
    for (int i = 0; i < 150; i++) {
      double x = random.nextDouble() * size.width;
      double baseY = random.nextDouble() * size.height;

      // Grass blade properties
      double height = 15 + random.nextDouble() * 12;
      double width = 1.5 + random.nextDouble() * 1;
      double bend = (random.nextDouble() - 0.5) * 5;

      // Color variation (different shades of green)
      Color grassColor;
      double colorRand = random.nextDouble();
      if (colorRand < 0.3) {
        grassColor = const Color(0xFF689F38);
      } else if (colorRand < 0.6) {
        grassColor = const Color(0xFF7CB342);
      } else {
        grassColor = const Color(0xFF8BC34A);
      }

      final grassPaint = Paint()
        ..color = grassColor
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round;

      // Draw curved grass blade
      final path = Path()
        ..moveTo(x, baseY + height)
        ..quadraticBezierTo(
          x + bend,
          baseY + height / 2,
          x + bend * 1.5,
          baseY,
        );

      canvas.drawPath(path, grassPaint);
    }

    // Add some small flowers scattered
    for (int i = 0; i < 12; i++) {
      double x = random.nextDouble() * size.width;
      double y = random.nextDouble() * size.height;

      // Flower colors
      List<Color> flowerColors = [
        const Color(0xFFFFEB3B), // Yellow
        const Color(0xFFFFFFFF), // White
        const Color(0xFFFF69B4), // Pink
        const Color(0xFFE1BEE7), // Light purple
      ];

      Color flowerColor = flowerColors[random.nextInt(flowerColors.length)];

      // Draw small flower
      final flowerPaint = Paint()..color = flowerColor;
      canvas.drawCircle(Offset(x, y), 2, flowerPaint);

      // Stem
      final stemPaint = Paint()
        ..color = const Color(0xFF558B2F)
        ..strokeWidth = 1;
      canvas.drawLine(Offset(x, y), Offset(x, y + 5), stemPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ========== TIMER PICKER DIALOG WITH SLIDER ==========
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
    int hours = minutes ~/ 60;
    int mins = minutes % 60;

    // Format display string
    String timeDisplay;
    if (hours > 0 && mins > 0) {
      timeDisplay = '${hours}hr ${mins}min';
    } else if (hours > 0) {
      timeDisplay = '${hours}hr';
    } else {
      timeDisplay = '${mins}min';
    }

    // PEA earnings (with all boosts!)
    int peaEarnings = CurrencyService.calculatePeasFromFocus(
      minutes,
      upgradeMultiplier: UpgradeService().getTotalMultiplier(),
    );

    return AlertDialog(
      backgroundColor: const Color(0xFF16213e),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: const Text(
        'Choose Focus Duration',
        style: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Time display with arrows
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Down arrow
              GestureDetector(
                onTap: () {
                  setState(() {
                    if (selectedMinutes > 1) selectedMinutes -= 1;
                  });
                },
                onLongPressStart: (_) => _startRepeating(-1),
                onLongPressEnd: (_) => _stopRepeating(),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.remove,
                    color: Colors.white70,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Time display
              Column(
                children: [
                  Text(
                    timeDisplay,
                    style: const TextStyle(
                      color: Color(0xFF4CAF50),
                      fontSize: 29,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '($minutes minutes)',
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              // Up arrow
              GestureDetector(
                onTap: () {
                  setState(() {
                    if (selectedMinutes < 600) selectedMinutes += 1;
                  });
                },
                onLongPressStart: (_) => _startRepeating(1),
                onLongPressEnd: (_) => _stopRepeating(),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.add,
                    color: Colors.white70,
                    size: 28,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Slider
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFF4CAF50),
              inactiveTrackColor: const Color(0xFF2d3e5f),
              thumbColor: const Color(0xFF4CAF50),
              overlayColor: const Color(0xFF4CAF50).withOpacity(0.3),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
              trackHeight: 6,
            ),
            child: Slider(
              value: selectedMinutes,
              min: 1,
              max: 600,
              divisions: 599,
              onChanged: (value) {
                setState(() {
                  selectedMinutes = value;
                });
              },
            ),
          ),

          // Min/Max labels
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('1min', style: TextStyle(color: Colors.white54, fontSize: 12)),
                Text('10hrs', style: TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Estimated earnings display
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF4CAF50), width: 2),
            ),
            child: Column(
              children: [
                const Text(
                  'You will earn:',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '~${NumberFormatter.format(peaEarnings)} ${CurrencyService().cropEmoji}',
                  style: const TextStyle(
                    color: Color(0xFF4CAF50),
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                Text(
                  CurrencyService().cropName.toLowerCase(),
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  FurnitureService().getBoostString(),
                  style: const TextStyle(
                    color: Colors.amber,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Furniture Boost',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  UpgradeService().getBonusPercentageString(),
                  style: const TextStyle(
                    color: Colors.cyanAccent,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Upgrade Boost',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Cancel',
            style: TextStyle(color: Colors.white54, fontSize: 16),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, selectedMinutes.round()),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4CAF50),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Start Focus',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }


  Widget _buildQuickButton(int minutes) {
    bool isSelected = selectedMinutes.round() == minutes;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedMinutes = minutes.toDouble();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4CAF50) : const Color(0xFF1e2a47),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF4CAF50) : const Color(0xFF2d3e5f),
            width: 2,
          ),
        ),
        child: Text(
          '${minutes}m',
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}