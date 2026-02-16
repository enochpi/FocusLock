import 'package:flutter/material.dart';
import 'package:focus_life/services/streak_service.dart';
import 'dart:math' as math;
import '../models/character.dart';
import '../services/currency_service.dart';
import '../services/upgrade_service.dart';


class GardenFocusScreen extends StatefulWidget {
  final Character character;
  final int focusDurationMinutes;

  const GardenFocusScreen({super.key, 
    required this.character,
    required this.focusDurationMinutes,
  });

  @override
  _GardenFocusScreenState createState() => _GardenFocusScreenState();
}

class _GardenFocusScreenState extends State<GardenFocusScreen>
    with TickerProviderStateMixin {
  final CurrencyService currency = CurrencyService(); // ← MOVED HERE
  final UpgradeService upgrades = UpgradeService();
  late AnimationController _characterController;
  bool _isWorking = false;
  int _remainingSeconds = 0;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.focusDurationMinutes * 60;

    // Character animation (idle movement)
    _characterController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _startFocusSession();
  }

  void _startFocusSession() {
    setState(() {
      _isWorking = true;
    });

    // Start countdown
    Future.delayed(const Duration(seconds: 1), _countdown);
  }

  void _countdown() {
    if (_remainingSeconds > 0 && _isWorking) {
      setState(() {
        _remainingSeconds--;
      });
      Future.delayed(const Duration(seconds: 1), _countdown);
    } else if (_remainingSeconds == 0) {
      _finishSession();
    }
  }

  /// Calculate peas earned so far (for partial completion)
  int _calculatePeasSoFar() {
    int elapsedMinutes = widget.focusDurationMinutes - (_remainingSeconds ~/ 60);
    double multiplier = upgrades.getTotalMultiplier();
    return CurrencyService.calculatePeasFromFocus(
      elapsedMinutes,
      upgradeMultiplier: multiplier,
    );
  }

  void _finishSession() async {
    // Get upgrade multiplier (furniture boost is applied automatically inside calculatePeasFromFocus)
    double upgradeMultiplier = upgrades.getTotalMultiplier();
    await StreakService().recordFocusSession();

    // Calculate peas (furniture boost applied inside this method)
    int peasEarned = CurrencyService.calculatePeasFromFocus(
      widget.focusDurationMinutes,
      upgradeMultiplier: upgradeMultiplier,
    );

    await currency.addPeas(peasEarned);

    // Reward money AND track focus minutes (keep existing functionality)
    int earnings = widget.focusDurationMinutes * 5; // $5 per minute
    widget.character.earnMoney(earnings);
    widget.character.addFocusMinutes(widget.focusDurationMinutes);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2d2d2d),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          "Focus Complete! 🎉",
          style: TextStyle(color: Colors.white),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "You earned:",
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 16),

            // Peas earned (main reward)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF4CAF50),
                  width: 2,
                ),
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
                    CurrencyService().cropName,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),
            Text(
              "${widget.focusDurationMinutes} min + 10% bonus!",
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white60,
                fontStyle: FontStyle.italic,
              ),
            ),

            const SizedBox(height: 16),

            // Additional info (money + focus minutes)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    "Also earned: \$$earnings",
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "+${widget.focusDurationMinutes} focus minutes",
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
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
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Return to cave scene
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "Awesome!",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(int totalSeconds) {
    int hours = totalSeconds ~/ 3600;
    int minutes = (totalSeconds % 3600) ~/ 60;
    int seconds = totalSeconds % 60;

    if (hours > 0) {
      return '${hours}h ${minutes.toString().padLeft(2, '0')}m ${seconds.toString().padLeft(2, '0')}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds.toString().padLeft(2, '0')}s';
    }
    return '${seconds}s';
  }

  @override
  void dispose() {
    _characterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF87CEEB), // Sky blue
      body: Stack(
        children: [
          // Garden scene
          // Garden scene
          CustomPaint(
            size: Size.infinite,
            painter: GardenPainter(
              characterAnimation: _characterController.value,
              isWorking: _isWorking,
              totalSeconds: widget.focusDurationMinutes * 60, // ← ADD
              remainingSeconds: _remainingSeconds, // ← ADD
            ),
          ),

          // Timer display at top
          Positioned(
            top: 60,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  _formatTime(_remainingSeconds),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ),
          ),

          // Stop button
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton(
                onPressed: () {
                  // Calculate current progress
                  int elapsedSeconds = (widget.focusDurationMinutes * 60) - _remainingSeconds;
                  int elapsedMinutes = elapsedSeconds ~/ 60;

                  // CASE 1: Less than 5 minutes - Get nothing!
                  if (elapsedMinutes < 5) {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: const Color(0xFF16213e),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        title: const Row(
                          children: [
                            Text("⏱️", style: TextStyle(fontSize: 28)),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                "Stop Session?",
                                style: TextStyle(color: Colors.white, fontSize: 18),
                              ),
                            ),
                          ],
                        ),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.red.withOpacity(0.5)),
                              ),
                              child: Column(
                                children: [
                                  const Icon(Icons.block, color: Colors.red, size: 48),
                                  const SizedBox(height: 12),
                                  const Text(
                                    "You won't earn any peas!",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    "You need at least 5 minutes of focus to earn peas.",
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    "Current: $elapsedMinutes min\nRequired: 5 min",
                                    style: TextStyle(
                                      color: Colors.red[300],
                                      fontSize: 13,
                                    ),
                                    textAlign: TextAlign.center,
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
                              "Keep Focusing",
                              style: TextStyle(
                                color: Color(0xFF00d4ff),
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              // Stop but get nothing
                              Navigator.pop(context); // Close dialog
                              Navigator.pop(context); // Return to cave
                            },
                            child: const Text(
                              "Stop Anyway",
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                    return;
                  }

                  // CASE 2: 5+ minutes - Get peas with penalty
                  int peasSoFar = _calculatePeasSoFar();
                  int peasLost = (peasSoFar * 0.20).floor(); // 20% penalty
                  int peasKept = peasSoFar - peasLost;

                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: const Color(0xFF16213e),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      title: const Row(
                        children: [
                          Text("⚠️", style: TextStyle(fontSize: 28)),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "Stop Focus Session?",
                              style: TextStyle(color: Colors.white, fontSize: 18),
                            ),
                          ),
                        ],
                      ),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Progress so far
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4CAF50).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "Earned so far:",
                                  style: TextStyle(color: Colors.white70),
                                ),
                                Text(
                                  "$peasSoFar 🌱",
                                  style: const TextStyle(
                                    color: Color(0xFF4CAF50),
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "$elapsedMinutes of ${widget.focusDurationMinutes} minutes completed",
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Penalty warning
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.withOpacity(0.5)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "If you stop now:",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    const Text("❌", style: TextStyle(fontSize: 16)),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        "Lose $peasLost peas (20% penalty)",
                                        style: TextStyle(color: Colors.red[300]),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Text("✅", style: TextStyle(fontSize: 16)),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        "Keep $peasKept peas",
                                        style: const TextStyle(color: Color(0xFF4CAF50)),
                                      ),
                                    ),
                                  ],
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
                            "Keep Focusing",
                            style: TextStyle(
                              color: Color(0xFF00d4ff),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            // Stop early - apply penalty
                            if (peasKept > 0) {
                              await currency.addPeas(peasKept);
                            }

                            // Add focus minutes (partial)
                            widget.character.addFocusMinutes(elapsedMinutes);

                            Navigator.pop(context); // Close warning dialog
                            Navigator.pop(context); // Return to cave
                          },
                          child: const Text(
                            "Stop",
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  "Stop Session",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
// ENHANCED GARDEN PAINTER - PROGRESSIVE FARMING ANIMATION
class GardenPainter extends CustomPainter {
  final double characterAnimation;
  final bool isWorking;
  final int totalSeconds;
  final int remainingSeconds;

  GardenPainter({
    required this.characterAnimation,
    required this.isWorking,
    required this.totalSeconds,
    required this.remainingSeconds,
  });

  // Calculate progress (0.0 to 1.0)
  double get progress => totalSeconds > 0 ? 1.0 - (remainingSeconds / totalSeconds) : 0.0;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Background elements
    _drawSun(canvas, w, h);
    _drawClouds(canvas, w, h);
    _drawGround(canvas, w, h);
    _drawCaveEntrance(canvas, w, h);
    _drawTrees(canvas, w, h);
    _drawRocks(canvas, w, h);

    // Garden and character
    _drawGarden(canvas, w, h);
    _drawCharacter(canvas, w, h);

    // Foreground flowers
    _drawFlowers(canvas, w, h);
  }

  void _drawSun(Canvas canvas, double w, double h) {
    // Bright sun
    canvas.drawCircle(
      Offset(w * 0.85, h * 0.12),
      38,
      Paint()..color = const Color(0xFFFDB813),
    );

    // Sun glow
    canvas.drawCircle(
      Offset(w * 0.85, h * 0.12),
      45,
      Paint()
        ..color = const Color(0xFFFFD700).withOpacity(0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
    );

    // Animated sun rays (rotate)
    for (int i = 0; i < 12; i++) {
      double angle = (i * 30 + characterAnimation * 20) * (3.14159 / 180);
      double startX = w * 0.85 + (cos(angle) * 48);
      double startY = h * 0.12 + (sin(angle) * 48);
      double endX = w * 0.85 + (cos(angle) * 65);
      double endY = h * 0.12 + (sin(angle) * 65);

      canvas.drawLine(
        Offset(startX, startY),
        Offset(endX, endY),
        Paint()
          ..color = const Color(0xFFFFD700)
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _drawClouds(Canvas canvas, double w, double h) {
    final cloudPaint = Paint()..color = Colors.white.withOpacity(0.8);

    // Cloud 1 (fluffy)
    canvas.drawCircle(Offset(w * 0.18, h * 0.14), 38, cloudPaint);
    canvas.drawCircle(Offset(w * 0.21, h * 0.13), 48, cloudPaint);
    canvas.drawCircle(Offset(w * 0.24, h * 0.14), 42, cloudPaint);
    canvas.drawCircle(Offset(w * 0.26, h * 0.15), 35, cloudPaint);

    // Cloud 2 (fluffy)
    canvas.drawCircle(Offset(w * 0.63, h * 0.18), 32, cloudPaint);
    canvas.drawCircle(Offset(w * 0.66, h * 0.17), 42, cloudPaint);
    canvas.drawCircle(Offset(w * 0.69, h * 0.18), 38, cloudPaint);
    canvas.drawCircle(Offset(w * 0.71, h * 0.19), 30, cloudPaint);
  }

  void _drawGround(Canvas canvas, double w, double h) {
    // Grass gradient
    final grassRect = Rect.fromLTWH(0, h * 0.6, w, h * 0.4);
    final grassPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF81C784), Color(0xFF66BB6A), Color(0xFF4CAF50)],
      ).createShader(grassRect);

    canvas.drawRect(grassRect, grassPaint);

    // Grass blades (more detailed)
    final grassTexture = Paint()
      ..color = const Color(0xFF66BB6A)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 80; i++) {
      double x = (i * w / 80);
      double y = h * 0.6 + ((i % 4) * 6);
      double height = 10 + ((i % 3) * 4);
      canvas.drawLine(Offset(x, y), Offset(x + 1, y + height), grassTexture);
    }
  }

  void _drawCaveEntrance(Canvas canvas, double w, double h) {
    final cavePath = Path()
      ..moveTo(w * 0.06, h * 0.54)
      ..quadraticBezierTo(w * 0.12, h * 0.30, w * 0.24, h * 0.54)
      ..lineTo(w * 0.24, h * 0.6)
      ..lineTo(w * 0.06, h * 0.6)
      ..close();

    // Cave darkness
    canvas.drawPath(cavePath, Paint()..color = const Color(0xFF0D0C0A));

    // Cave stone border
    canvas.drawPath(
      cavePath,
      Paint()
        ..color = const Color(0xFF4A4440)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6,
    );

    // Cave entrance detail
    canvas.drawPath(
      cavePath,
      Paint()
        ..color = const Color(0xFF2A2420)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  void _drawTrees(Canvas canvas, double w, double h) {
    _drawTree(canvas, w * 0.10, h * 0.6, 75);
    _drawTree(canvas, w * 0.90, h * 0.6, 68);
  }

  void _drawTree(Canvas canvas, double x, double y, double size) {
    // Tree trunk with texture
    final trunkRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(x - size * 0.12, y - size * 0.5, size * 0.24, size * 0.5),
      const Radius.circular(3),
    );
    canvas.drawRRect(trunkRect, Paint()..color = const Color(0xFF6D4C41));

    // Bark texture
    for (int i = 0; i < 4; i++) {
      canvas.drawLine(
        Offset(x - size * 0.08, y - size * 0.4 + (i * size * 0.1)),
        Offset(x + size * 0.08, y - size * 0.38 + (i * size * 0.1)),
        Paint()
          ..color = const Color(0xFF5D4037)
          ..strokeWidth = 2,
      );
    }

    // Layered foliage (3D effect)
    canvas.drawCircle(Offset(x, y - size * 0.7), size * 0.48, Paint()..color = const Color(0xFF1B5E20));
    canvas.drawCircle(Offset(x - size * 0.28, y - size * 0.45), size * 0.38, Paint()..color = const Color(0xFF2E7D32));
    canvas.drawCircle(Offset(x + size * 0.28, y - size * 0.45), size * 0.38, Paint()..color = const Color(0xFF388E3C));
    canvas.drawCircle(Offset(x - size * 0.15, y - size * 0.55), size * 0.32, Paint()..color = const Color(0xFF43A047));
    canvas.drawCircle(Offset(x + size * 0.15, y - size * 0.55), size * 0.32, Paint()..color = const Color(0xFF4CAF50));
  }

  void _drawRocks(Canvas canvas, double w, double h) {
    _drawRock(canvas, w * 0.25, h * 0.72, 28);
    _drawRock(canvas, w * 0.77, h * 0.75, 22);
    _drawRock(canvas, w * 0.30, h * 0.78, 18);
  }

  void _drawRock(Canvas canvas, double x, double y, double size) {
    final rockPath = Path()
      ..moveTo(x - size * 0.4, y)
      ..lineTo(x, y - size * 0.7)
      ..lineTo(x + size * 0.6, y - size * 0.2)
      ..lineTo(x + size * 0.4, y)
      ..close();

    // Rock body
    canvas.drawPath(rockPath, Paint()..color = const Color(0xFF424242));

    // Rock highlights
    final highlightPath = Path()
      ..moveTo(x - size * 0.2, y - size * 0.1)
      ..lineTo(x + size * 0.1, y - size * 0.5)
      ..lineTo(x + size * 0.3, y - size * 0.15);

    canvas.drawPath(
      highlightPath,
      Paint()
        ..color = const Color(0xFF616161)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Rock outline
    canvas.drawPath(
      rockPath,
      Paint()
        ..color = const Color(0xFF212121)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  void _drawGarden(Canvas canvas, double w, double h) {
    // Garden plot dimensions (4 wide × 3 tall)
    final gardenRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(w * 0.55, h * 0.72),
        width: w * 0.45, // 4 plants width
        height: h * 0.18, // 3 plants height
      ),
      const Radius.circular(8),
    );

    // Dirt color varies by progress
    Color dirtColor = progress < 0.17 ? const Color(0xFF8D6E63) : const Color(0xFF6D4C41);
    canvas.drawRRect(gardenRect, Paint()..color = dirtColor);

    // Garden border
    canvas.drawRRect(
      gardenRect,
      Paint()
        ..color = const Color(0xFF5D4037)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    // Tilled rows (show after hoeing)
    if (progress > 0.17) {
      final rowPaint = Paint()
        ..color = const Color(0xFF5D4037)
        ..strokeWidth = 2;

      double startX = w * 0.325;
      double endX = w * 0.775;

      for (int row = 0; row < 3; row++) {
        double y = h * 0.66 + (row * 24);
        canvas.drawLine(Offset(startX, y), Offset(endX, y), rowPaint);
      }
    }

    // Draw plants
    _drawPlants(canvas, w, h);
  }

  void _drawPlants(Canvas canvas, double w, double h) {
    // Plant growth stages
    int growthStage = 0;
    if (progress >= 0.50) growthStage = 1; // Sprouts
    if (progress >= 0.60) growthStage = 2; // Small
    if (progress >= 0.70) growthStage = 3; // Medium
    if (progress >= 0.80) growthStage = 4; // Full grown

    double startX = w * 0.365;
    double startY = h * 0.66;
    double spacingX = (w * 0.37) / 4; // 4 plants
    double spacingY = 24.0; // 3 rows

    for (int row = 0; row < 3; row++) {
      for (int col = 0; col < 4; col++) {
        double x = startX + (col * spacingX);
        double y = startY + (row * spacingY);

        _drawPlantStage(canvas, x, y, growthStage);
      }
    }
  }

  void _drawPlantStage(Canvas canvas, double x, double y, int stage) {
    if (stage == 0) return;

    final plantPaint = Paint()..color = const Color(0xFF4CAF50);
    final stemPaint = Paint()
      ..color = const Color(0xFF558B2F)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    if (stage == 1) {
      // Tiny sprout
      canvas.drawCircle(Offset(x, y - 2), 3.5, Paint()..color = const Color(0xFF81C784));
      canvas.drawLine(Offset(x, y), Offset(x, y - 4), stemPaint..strokeWidth = 1.5);
    } else if (stage == 2) {
      // Small plant
      canvas.drawCircle(Offset(x - 5, y - 4), 4.5, plantPaint);
      canvas.drawCircle(Offset(x + 5, y - 4), 4.5, plantPaint);
      canvas.drawLine(Offset(x, y), Offset(x, y - 8), stemPaint);
    } else if (stage == 3) {
      // Medium plant
      canvas.drawCircle(Offset(x - 6, y - 6), 5.5, plantPaint);
      canvas.drawCircle(Offset(x + 6, y - 6), 5.5, plantPaint);
      canvas.drawCircle(Offset(x - 4, y - 11), 4.5, plantPaint);
      canvas.drawCircle(Offset(x + 4, y - 11), 4.5, plantPaint);
      canvas.drawLine(Offset(x, y), Offset(x, y - 14), stemPaint);
    } else if (stage >= 4) {
      // Full grown with pea pods!
      canvas.drawCircle(Offset(x - 7, y - 8), 6.5, plantPaint);
      canvas.drawCircle(Offset(x + 7, y - 8), 6.5, plantPaint);
      canvas.drawCircle(Offset(x - 5, y - 14), 5.5, plantPaint);
      canvas.drawCircle(Offset(x + 5, y - 14), 5.5, plantPaint);
      canvas.drawCircle(Offset(x, y - 18), 4.5, plantPaint);
      canvas.drawLine(Offset(x, y), Offset(x, y - 18), stemPaint..strokeWidth = 3);

      // Pea pods (bright green)
      final peaPaint = Paint()..color = const Color(0xFF7CB342);
      canvas.drawCircle(Offset(x - 8, y - 12), 4.5, peaPaint);
      canvas.drawCircle(Offset(x + 8, y - 12), 4.5, peaPaint);
      canvas.drawCircle(Offset(x - 3, y - 16), 4, peaPaint);
      canvas.drawCircle(Offset(x + 3, y - 16), 4, peaPaint);

      // Pea highlights
      canvas.drawCircle(Offset(x - 9, y - 13), 1.5, Paint()..color = const Color(0xFF9CCC65));
      canvas.drawCircle(Offset(x + 7, y - 13), 1.5, Paint()..color = const Color(0xFF9CCC65));
    }
  }

  void _drawCharacter(Canvas canvas, double w, double h) {
    double charX = w * 0.55;
    double charY = h * 0.68;

    // Animation phases
    if (progress < 0.17) {
      _drawHoeingPhase(canvas, charX, charY);
    } else if (progress < 0.33) {
      _drawSeedingPhase(canvas, charX, charY);
    } else if (progress < 0.50) {
      _drawWateringPhase(canvas, charX, charY);
    } else if (progress < 0.83) {
      _drawWaitingPhase(canvas, charX, charY);
    } else if (progress < 0.95) {
      _drawHarvestingPhase(canvas, charX, charY);
    } else {
      _drawSuccessPhase(canvas, charX, charY);
    }
  }

  void _drawHoeingPhase(Canvas canvas, double x, double y) {
    // Shadow
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x, y + 38), width: 42, height: 11),
      Paint()..color = Colors.black.withOpacity(0.25),
    );

    // Body
    canvas.drawCircle(Offset(x, y + 2), 22, Paint()..color = const Color(0xFFFFD54F));

    // Head
    canvas.drawCircle(Offset(x, y - 23), 16, Paint()..color = const Color(0xFFFFE082));

    // Hoeing motion (up and down)
    double hoeY = y + 10 + (characterAnimation * 15);
    double armAngle = characterAnimation * 0.4;

    // Arms holding hoe
    canvas.drawLine(
      Offset(x + 14, y - 8),
      Offset(x + 25, hoeY - 10),
      Paint()
        ..color = const Color(0xFFFFD54F)
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      Offset(x - 14, y - 8),
      Offset(x + 20, hoeY - 15),
      Paint()
        ..color = const Color(0xFFFFD54F)
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round,
    );

    // Hoe handle
    canvas.drawLine(
      Offset(x + 22, hoeY - 12),
      Offset(x + 22, hoeY + 22),
      Paint()
        ..color = const Color(0xFF8D6E63)
        ..strokeWidth = 5,
    );

    // Hoe blade
    canvas.drawRect(
      Rect.fromCenter(center: Offset(x + 22, hoeY + 28), width: 25, height: 6),
      Paint()..color = const Color(0xFF757575),
    );

    // Dirt flying up
    if (characterAnimation > 0.5) {
      for (int i = 0; i < 4; i++) {
        canvas.drawCircle(
          Offset(x + 30 + (i * 6), hoeY + 20 - (characterAnimation * 12)),
          2.5,
          Paint()..color = const Color(0xFF8D6E63),
        );
      }
    }

    _drawFace(canvas, x, y - 23, false);
  }

  void _drawSeedingPhase(Canvas canvas, double x, double y) {
    // Shadow
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x, y + 38), width: 42, height: 11),
      Paint()..color = Colors.black.withOpacity(0.25),
    );

    // Body
    canvas.drawCircle(Offset(x, y), 22, Paint()..color = const Color(0xFFFFD54F));

    // Head
    canvas.drawCircle(Offset(x, y - 26), 16, Paint()..color = const Color(0xFFFFE082));

    // Seed sack in left hand
    final sackPath = Path()
      ..moveTo(x - 28, y)
      ..lineTo(x - 22, y - 8)
      ..lineTo(x - 18, y + 2)
      ..lineTo(x - 24, y + 8)
      ..close();
    canvas.drawPath(sackPath, Paint()..color = const Color(0xFF8D6E63));

    // Sack opening
    canvas.drawLine(
      Offset(x - 22, y - 8),
      Offset(x - 18, y + 2),
      Paint()
        ..color = const Color(0xFF5D4037)
        ..strokeWidth = 2,
    );

    // Right arm throwing
    double throwY = y - 8 - (sin(characterAnimation * 3.14159) * 12);
    canvas.drawLine(
      Offset(x + 14, y - 6),
      Offset(x + 32, throwY),
      Paint()
        ..color = const Color(0xFFFFD54F)
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round,
    );

    // Seeds falling in arc
    double seedAnim = characterAnimation;
    for (int i = 0; i < 6; i++) {
      double seedX = x + 35 + (i * 8) + (seedAnim * 15);
      double seedY = throwY + 5 + (seedAnim * seedAnim * 40); // Parabolic fall

      if (seedY < y + 35) { // Only show while falling
        canvas.drawCircle(
          Offset(seedX, seedY),
          2.5,
          Paint()..color = const Color(0xFF8D6E63),
        );
      }
    }

    _drawFace(canvas, x, y - 26, false);
  }

  void _drawWateringPhase(Canvas canvas, double x, double y) {
    // Shadow
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x, y + 38), width: 42, height: 11),
      Paint()..color = Colors.black.withOpacity(0.25),
    );

    // Body
    canvas.drawCircle(Offset(x, y), 22, Paint()..color = const Color(0xFFFFD54F));

    // Head
    canvas.drawCircle(Offset(x, y - 26), 16, Paint()..color = const Color(0xFFFFE082));

    // Watering can (tilted)
    canvas.save();
    canvas.translate(x + 28, y - 2);
    canvas.rotate(-0.3);

    // Can body
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-10, -12, 20, 24),
        const Radius.circular(4),
      ),
      Paint()..color = const Color(0xFF78909C),
    );

    // Can handle
    final handlePath = Path()
      ..addOval(Rect.fromCenter(center: const Offset(-12, 0), width: 8, height: 16));
    canvas.drawPath(
      handlePath,
      Paint()
        ..color = const Color(0xFF546E7A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    // Spout
    canvas.drawLine(
      const Offset(10, -8),
      const Offset(20, -12),
      Paint()
        ..color = const Color(0xFF78909C)
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round,
    );

    canvas.restore();

    // CONTINUOUS WATERFALL of water drops
    for (int i = 0; i < 12; i++) {
      double dropX = x + 45 + (i % 3) * 4;
      double baseY = y - 10;
      double dropY = baseY + (i * 6) + (characterAnimation * 25);

      if (dropY < y + 35) { // Only show while falling
        canvas.drawOval(
          Rect.fromCenter(center: Offset(dropX, dropY), width: 3, height: 6),
          Paint()..color = const Color(0xFF64B5F6).withOpacity(0.8),
        );
      }
    }

    // Water splash at bottom
    canvas.drawCircle(
      Offset(x + 46, y + 34),
      6,
      Paint()
        ..color = const Color(0xFF64B5F6).withOpacity(0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // Arms holding can
    canvas.drawLine(
      Offset(x - 14, y - 4),
      Offset(x + 18, y - 6),
      Paint()
        ..color = const Color(0xFFFFD54F)
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      Offset(x + 14, y - 4),
      Offset(x + 24, y - 4),
      Paint()
        ..color = const Color(0xFFFFD54F)
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round,
    );

    _drawFace(canvas, x, y - 26, false);
  }

  void _drawWaitingPhase(Canvas canvas, double x, double y) {
    // Shadow
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x, y + 38), width: 42, height: 11),
      Paint()..color = Colors.black.withOpacity(0.25),
    );

    // Gentle bobbing motion
    double bobY = y + (sin(characterAnimation * 6.28) * 3);

    // Body
    canvas.drawCircle(Offset(x, bobY), 22, Paint()..color = const Color(0xFFFFD54F));

    // Head
    canvas.drawCircle(Offset(x, bobY - 26), 16, Paint()..color = const Color(0xFFFFE082));

    // Arms relaxed at sides
    canvas.drawLine(
      Offset(x - 16, bobY - 2),
      Offset(x - 28, bobY + 18),
      Paint()
        ..color = const Color(0xFFFFD54F)
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      Offset(x + 16, bobY - 2),
      Offset(x + 28, bobY + 18),
      Paint()
        ..color = const Color(0xFFFFD54F)
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round,
    );

    _drawFace(canvas, x, bobY - 26, false);
  }

  void _drawHarvestingPhase(Canvas canvas, double x, double y) {
    // Shadow
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x, y + 38), width: 42, height: 11),
      Paint()..color = Colors.black.withOpacity(0.25),
    );

    // Body (bending down)
    canvas.drawCircle(Offset(x, y + 8), 22, Paint()..color = const Color(0xFFFFD54F));

    // Head (lower)
    canvas.drawCircle(Offset(x, y - 16), 16, Paint()..color = const Color(0xFFFFE082));

    // Arms reaching down to pick
    double reachY = y + 28 + (sin(characterAnimation * 6.28) * 4);
    canvas.drawLine(
      Offset(x - 16, y + 8),
      Offset(x - 18, reachY),
      Paint()
        ..color = const Color(0xFFFFD54F)
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      Offset(x + 16, y + 8),
      Offset(x + 18, reachY),
      Paint()
        ..color = const Color(0xFFFFD54F)
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round,
    );

    // Harvest basket on ground
    final basketPath = Path()
      ..moveTo(x - 38, y + 32)
      ..lineTo(x - 42, y + 38)
      ..lineTo(x - 28, y + 38)
      ..lineTo(x - 32, y + 32)
      ..close();
    canvas.drawPath(basketPath, Paint()..color = const Color(0xFF8D6E63));

    // Basket weave texture
    for (int i = 0; i < 3; i++) {
      canvas.drawLine(
        Offset(x - 40, y + 33 + (i * 2)),
        Offset(x - 30, y + 33 + (i * 2)),
        Paint()
          ..color = const Color(0xFF6D4C41)
          ..strokeWidth = 1,
      );
    }

    _drawFace(canvas, x, y - 16, false);
  }

  void _drawSuccessPhase(Canvas canvas, double x, double y) {
    // Shadow
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x, y + 38), width: 42, height: 11),
      Paint()..color = Colors.black.withOpacity(0.25),
    );

    // Body
    canvas.drawCircle(Offset(x, y), 22, Paint()..color = const Color(0xFFFFD54F));

    // Head
    canvas.drawCircle(Offset(x, y - 26), 16, Paint()..color = const Color(0xFFFFE082));

    // Arms raised in VICTORY!
    canvas.drawLine(
      Offset(x - 16, y - 8),
      Offset(x - 32, y - 32),
      Paint()
        ..color = const Color(0xFFFFD54F)
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawLine(
      Offset(x + 16, y - 8),
      Offset(x + 32, y - 32),
      Paint()
        ..color = const Color(0xFFFFD54F)
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round,
    );

    // Large harvest basket with crops!
    final basketPath = Path()
      ..moveTo(x - 24, y + 22)
      ..lineTo(x - 28, y + 38)
      ..lineTo(x + 28, y + 38)
      ..lineTo(x + 24, y + 22)
      ..close();
    canvas.drawPath(basketPath, Paint()..color = const Color(0xFF8D6E63));

    // Basket rim
    canvas.drawLine(
      Offset(x - 24, y + 22),
      Offset(x + 24, y + 22),
      Paint()
        ..color = const Color(0xFF6D4C41)
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round,
    );

    // Overflowing vegetables (peas and carrots!)
    // Peas (green)
    for (int i = 0; i < 8; i++) {
      canvas.drawCircle(
        Offset(x - 18 + (i * 5), y + 18 + (i % 2) * 3),
        5,
        Paint()..color = const Color(0xFF7CB342),
      );
    }

    // Carrots (orange)
    for (int i = 0; i < 3; i++) {
      double cx = x - 12 + (i * 12);
      // Carrot body
      final carrotPath = Path()
        ..moveTo(cx, y + 26)
        ..lineTo(cx - 3, y + 34)
        ..lineTo(cx + 3, y + 34)
        ..close();
      canvas.drawPath(carrotPath, Paint()..color = const Color(0xFFFF9800));

      // Carrot top (green leaves)
      canvas.drawLine(
        Offset(cx, y + 26),
        Offset(cx - 2, y + 22),
        Paint()
          ..color = const Color(0xFF4CAF50)
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round,
      );
      canvas.drawLine(
        Offset(cx, y + 26),
        Offset(cx + 2, y + 22),
        Paint()
          ..color = const Color(0xFF4CAF50)
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round,
      );
    }

    // SPARKLES everywhere!
    _drawSparkle(canvas, x - 38, y - 35, 10);
    _drawSparkle(canvas, x + 38, y - 35, 10);
    _drawSparkle(canvas, x - 28, y - 42, 8);
    _drawSparkle(canvas, x + 28, y - 42, 8);
    _drawSparkle(canvas, x, y - 48, 12);

    // Happy face!
    _drawFace(canvas, x, y - 26, true);
  }

  void _drawFace(Canvas canvas, double x, double y, bool extraHappy) {
    // Eyes
    if (extraHappy) {
      // Happy eyes (closed)
      final leftEye = Path()
        ..moveTo(x - 8, y - 3)
        ..quadraticBezierTo(x - 6, y - 1, x - 4, y - 3);
      final rightEye = Path()
        ..moveTo(x + 4, y - 3)
        ..quadraticBezierTo(x + 6, y - 1, x + 8, y - 3);
      canvas.drawPath(leftEye, Paint()..color = Colors.black..strokeWidth = 2..style = PaintingStyle.stroke);
      canvas.drawPath(rightEye, Paint()..color = Colors.black..strokeWidth = 2..style = PaintingStyle.stroke);
    } else {
      // Normal eyes (open)
      canvas.drawCircle(Offset(x - 6, y - 2), 2.5, Paint()..color = Colors.black);
      canvas.drawCircle(Offset(x + 6, y - 2), 2.5, Paint()..color = Colors.black);
    }

    // Smile
    final smilePath = Path()
      ..moveTo(x - 7, y + 4)
      ..quadraticBezierTo(x, extraHappy ? y + 9 : y + 7, x + 7, y + 4);
    canvas.drawPath(
      smilePath,
      Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawSparkle(Canvas canvas, double x, double y, double size) {
    final sparklePaint = Paint()
      ..color = const Color(0xFFFFD700)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    // 4-point star
    canvas.drawLine(Offset(x, y - size), Offset(x, y + size), sparklePaint);
    canvas.drawLine(Offset(x - size, y), Offset(x + size, y), sparklePaint);
    canvas.drawLine(Offset(x - size * 0.7, y - size * 0.7), Offset(x + size * 0.7, y + size * 0.7), sparklePaint);
    canvas.drawLine(Offset(x - size * 0.7, y + size * 0.7), Offset(x + size * 0.7, y - size * 0.7), sparklePaint);

    // Center glow
    canvas.drawCircle(
      Offset(x, y),
      size * 0.3,
      Paint()
        ..color = const Color(0xFFFFD700)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, size * 0.5),
    );
  }

  void _drawFlowers(Canvas canvas, double w, double h) {
    // Colorful garden flowers
    _drawFlower(canvas, w * 0.20, h * 0.84, Colors.red[600]!);
    _drawFlower(canvas, w * 0.26, h * 0.87, Colors.yellow[600]!);
    _drawFlower(canvas, w * 0.23, h * 0.90, Colors.pink[400]!);
    _drawFlower(canvas, w * 0.75, h * 0.85, Colors.purple[400]!);
    _drawFlower(canvas, w * 0.81, h * 0.88, Colors.orange[600]!);
    _drawFlower(canvas, w * 0.78, h * 0.91, Colors.blue[400]!);
  }

  void _drawFlower(Canvas canvas, double x, double y, Color color) {
    // Stem
    canvas.drawLine(
      Offset(x, y),
      Offset(x, y - 20),
      Paint()
        ..color = const Color(0xFF4CAF50)
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round,
    );

    // Leaves
    final leftLeaf = Path()
      ..moveTo(x, y - 10)
      ..quadraticBezierTo(x - 6, y - 12, x - 8, y - 8);
    canvas.drawPath(leftLeaf, Paint()..color = const Color(0xFF66BB6A)..style = PaintingStyle.fill);

    final rightLeaf = Path()
      ..moveTo(x, y - 14)
      ..quadraticBezierTo(x + 6, y - 16, x + 8, y - 12);
    canvas.drawPath(rightLeaf, Paint()..color = const Color(0xFF66BB6A)..style = PaintingStyle.fill);

    // Petals (6 around center)
    for (int i = 0; i < 6; i++) {
      double angle = (i * 60) * (3.14159 / 180);
      double px = x + (cos(angle) * 8);
      double py = y - 20 + (sin(angle) * 8);

      canvas.drawCircle(Offset(px, py), 5.5, Paint()..color = color);

      // Petal highlight
      canvas.drawCircle(
        Offset(px - 1, py - 1),
        2,
        Paint()..color = Colors.white.withOpacity(0.4),
      );
    }

    // Center
    canvas.drawCircle(Offset(x, y - 20), 5, Paint()..color = Colors.amber[700]!);

    // Center detail
    canvas.drawCircle(
      Offset(x, y - 20),
      3,
      Paint()..color = Colors.amber[900]!,
    );
  }

  double cos(double radians) => math.cos(radians);
  double sin(double radians) => math.sin(radians);

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}