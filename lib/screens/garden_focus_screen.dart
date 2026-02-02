import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/character.dart';
import '../services/currency_service.dart';
import '../services/upgrade_service.dart';
import '../services/furniture_service.dart';

class GardenFocusScreen extends StatefulWidget {
  final Character character;
  final int focusDurationMinutes;

  GardenFocusScreen({
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
  final FurnitureService furniture = FurnitureService();
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
      duration: Duration(seconds: 2),
    )..repeat(reverse: true);

    _startFocusSession();
  }

  void _startFocusSession() {
    setState(() {
      _isWorking = true;
    });

    // Start countdown
    Future.delayed(Duration(seconds: 1), _countdown);
  }

  void _countdown() {
    if (_remainingSeconds > 0 && _isWorking) {
      setState(() {
        _remainingSeconds--;
      });
      Future.delayed(Duration(seconds: 1), _countdown);
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
    // Get ALL multipliers
    double upgradeMultiplier = upgrades.getTotalMultiplier();
    double furnitureBoost = furniture.getTotalBoost(); // ← ADD

    // Combine boosts
    double totalMultiplier = upgradeMultiplier + furnitureBoost;

    // Calculate peas with everything
    int peasEarned = CurrencyService.calculatePeasFromFocus(
      widget.focusDurationMinutes,
      upgradeMultiplier: totalMultiplier, // ← USE COMBINED
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
        backgroundColor: Color(0xFF2d2d2d),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          "Focus Complete! 🎉",
          style: TextStyle(color: Colors.white),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "You earned:",
              style: TextStyle(
                fontSize: 16,
                color: Colors.white70,
              ),
            ),
            SizedBox(height: 16),

            // Peas earned (main reward)
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color(0xFF4CAF50).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Color(0xFF4CAF50),
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    "$peasEarned 🌱",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4CAF50),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Peas",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 12),
            Text(
              "${widget.focusDurationMinutes} min + 10% bonus!",
              style: TextStyle(
                fontSize: 14,
                color: Colors.white60,
                fontStyle: FontStyle.italic,
              ),
            ),

            SizedBox(height: 16),

            // Additional info (money + focus minutes)
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    "Also earned: \$$earnings",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "+${widget.focusDurationMinutes} focus minutes",
                    style: TextStyle(
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
                backgroundColor: Color(0xFF4CAF50),
                padding: EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
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

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int secs = seconds % 60;
    return "${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}";
  }

  @override
  void dispose() {
    _characterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF87CEEB), // Sky blue
      body: Stack(
        children: [
          // Garden scene
          CustomPaint(
            size: Size.infinite,
            painter: GardenPainter(
              characterAnimation: _characterController.value,
              isWorking: _isWorking,
            ),
          ),

          // Timer display at top
          Positioned(
            top: 60,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  _formatTime(_remainingSeconds),
                  style: TextStyle(
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
                  int peasSoFar = _calculatePeasSoFar();
                  int elapsedMinutes = widget.focusDurationMinutes - (_remainingSeconds ~/ 60);
                  int peasLost = (peasSoFar * 0.20).floor(); // 20% penalty
                  int peasKept = peasSoFar - peasLost;

                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: Color(0xFF16213e),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      title: Row(
                        children: [
                          Text("⚠️", style: TextStyle(fontSize: 28)),
                          SizedBox(width: 12),
                          Text(
                            "Stop Focus Session?",
                            style: TextStyle(color: Colors.white, fontSize: 18),
                          ),
                        ],
                      ),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Progress so far
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Color(0xFF4CAF50).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Earned so far:",
                                  style: TextStyle(color: Colors.white70),
                                ),
                                Text(
                                  "$peasSoFar 🌱",
                                  style: TextStyle(
                                    color: Color(0xFF4CAF50),
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            "$elapsedMinutes of ${widget.focusDurationMinutes} minutes completed",
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: 12,
                            ),
                          ),
                          SizedBox(height: 16),

                          // Penalty warning
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.red.withOpacity(0.5)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "If you stop now:",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Row(
                                  children: [
                                    Text("❌", style: TextStyle(fontSize: 16)),
                                    SizedBox(width: 8),
                                    Text(
                                      "Lose $peasLost peas (20% penalty)",
                                      style: TextStyle(color: Colors.red[300]),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text("✅", style: TextStyle(fontSize: 16)),
                                    SizedBox(width: 8),
                                    Text(
                                      "Keep $peasKept peas",
                                      style: TextStyle(color: Color(0xFF4CAF50)),
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
                          child: Text(
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
                          child: Text(
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
                  padding: EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text(
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

// GARDEN PAINTER
class GardenPainter extends CustomPainter {
  final double characterAnimation;
  final bool isWorking;

  GardenPainter({
    required this.characterAnimation,
    required this.isWorking,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Sky (already background color, but add clouds)
    _drawClouds(canvas, w, h);

    // Ground (grass)
    _drawGround(canvas, w, h);

    // Cave entrance (background)
    _drawCaveEntrance(canvas, w, h);

    // Garden elements
    _drawGarden(canvas, w, h);

    // Character working
    _drawCharacter(canvas, w, h);

    // Trees/plants
    _drawPlants(canvas, w, h);
  }

  void _drawClouds(Canvas canvas, double w, double h) {
    final cloudPaint = Paint()
      ..color = Colors.white.withOpacity(0.7);

    // Cloud 1
    canvas.drawCircle(Offset(w * 0.2, h * 0.15), 40, cloudPaint);
    canvas.drawCircle(Offset(w * 0.22, h * 0.15), 50, cloudPaint);
    canvas.drawCircle(Offset(w * 0.24, h * 0.15), 40, cloudPaint);

    // Cloud 2
    canvas.drawCircle(Offset(w * 0.7, h * 0.2), 35, cloudPaint);
    canvas.drawCircle(Offset(w * 0.72, h * 0.2), 45, cloudPaint);
    canvas.drawCircle(Offset(w * 0.74, h * 0.2), 35, cloudPaint);
  }

  void _drawGround(Canvas canvas, double w, double h) {
    // Grass
    final grassRect = Rect.fromLTWH(0, h * 0.6, w, h * 0.4);
    final grassPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF7CB342), Color(0xFF558B2F)],
      ).createShader(grassRect);

    canvas.drawRect(grassRect, grassPaint);

    // Grass texture (simple lines)
    final grassTexture = Paint()
      ..color = Color(0xFF689F38)
      ..strokeWidth = 2;

    for (int i = 0; i < 50; i++) {
      double x = (i * w / 50);
      double y = h * 0.6 + (i % 3) * 10;
      canvas.drawLine(
        Offset(x, y),
        Offset(x, y + 15),
        grassTexture,
      );
    }
  }

  void _drawCaveEntrance(Canvas canvas, double w, double h) {
    // Cave opening in background
    final cavePath = Path()
      ..moveTo(w * 0.1, h * 0.5)
      ..quadraticBezierTo(w * 0.15, h * 0.3, w * 0.25, h * 0.5)
      ..lineTo(w * 0.25, h * 0.6)
      ..lineTo(w * 0.1, h * 0.6)
      ..close();

    canvas.drawPath(
      cavePath,
      Paint()..color = Color(0xFF2a2622),
    );

    // Cave border
    canvas.drawPath(
      cavePath,
      Paint()
        ..color = Color(0xFF4a4440)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );
  }

  void _drawGarden(Canvas canvas, double w, double h) {
    // Garden plot (dirt rectangle)
    final gardenRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(w * 0.5, h * 0.75),
        width: w * 0.6,
        height: h * 0.2,
      ),
      Radius.circular(10),
    );

    canvas.drawRRect(
      gardenRect,
      Paint()..color = Color(0xFF6D4C41),
    );

    // Garden rows
    final rowPaint = Paint()
      ..color = Color(0xFF5D4037)
      ..strokeWidth = 3;

    for (int i = 0; i < 3; i++) {
      double y = h * 0.7 + (i * 30);
      canvas.drawLine(
        Offset(w * 0.25, y),
        Offset(w * 0.75, y),
        rowPaint,
      );
    }

    // Plants growing
    _drawGardenPlants(canvas, w, h);
  }

  void _drawGardenPlants(Canvas canvas, double w, double h) {
    // Small plants in rows
    for (int row = 0; row < 3; row++) {
      for (int col = 0; col < 6; col++) {
        double x = w * 0.3 + (col * 60);
        double y = h * 0.68 + (row * 30);

        // Leaf
        canvas.drawCircle(
          Offset(x, y),
          6,
          Paint()..color = Color(0xFF4CAF50),
        );
      }
    }
  }

  void _drawCharacter(Canvas canvas, double w, double h) {
    // Character position (working in garden)
    double charX = w * 0.6;
    double charY = h * 0.65 + (characterAnimation * 5); // Bobbing motion

    // Shadow
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(charX, h * 0.7),
        width: 40,
        height: 10,
      ),
      Paint()..color = Colors.black.withOpacity(0.3),
    );

    // Body
    canvas.drawCircle(
      Offset(charX, charY),
      25,
      Paint()..color = Color(0xFFFFD54F),
    );

    // Head
    canvas.drawCircle(
      Offset(charX, charY - 30),
      18,
      Paint()..color = Color(0xFFFFE082),
    );

    // Arms (working motion)
    if (isWorking) {
      double armAngle = characterAnimation * 0.5;

      // Left arm
      canvas.drawLine(
        Offset(charX - 15, charY - 10),
        Offset(charX - 35 + armAngle * 10, charY + 10),
        Paint()
          ..color = Color(0xFFFFD54F)
          ..strokeWidth = 8
          ..strokeCap = StrokeCap.round,
      );

      // Right arm
      canvas.drawLine(
        Offset(charX + 15, charY - 10),
        Offset(charX + 35 - armAngle * 10, charY + 10),
        Paint()
          ..color = Color(0xFFFFD54F)
          ..strokeWidth = 8
          ..strokeCap = StrokeCap.round,
      );
    }

    // Facial features
    // Eyes
    canvas.drawCircle(
      Offset(charX - 8, charY - 32),
      3,
      Paint()..color = Colors.black,
    );
    canvas.drawCircle(
      Offset(charX + 8, charY - 32),
      3,
      Paint()..color = Colors.black,
    );

    // Smile
    final smilePath = Path()
      ..moveTo(charX - 8, charY - 25)
      ..quadraticBezierTo(charX, charY - 22, charX + 8, charY - 25);

    canvas.drawPath(
      smilePath,
      Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );

    // Tool (hoe)
    if (isWorking) {
      canvas.drawLine(
        Offset(charX + 30, charY + 10),
        Offset(charX + 30, charY + 40),
        Paint()
          ..color = Color(0xFF8D6E63)
          ..strokeWidth = 4,
      );

      canvas.drawLine(
        Offset(charX + 20, charY + 40),
        Offset(charX + 40, charY + 40),
        Paint()
          ..color = Color(0xFF757575)
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _drawPlants(Canvas canvas, double w, double h) {
    // Background trees
    _drawTree(canvas, w * 0.15, h * 0.55, 60);
    _drawTree(canvas, w * 0.85, h * 0.52, 70);

    // Flowers
    _drawFlower(canvas, w * 0.25, h * 0.85, Colors.red);
    _drawFlower(canvas, w * 0.3, h * 0.88, Colors.yellow);
    _drawFlower(canvas, w * 0.75, h * 0.86, Colors.pink);
    _drawFlower(canvas, w * 0.8, h * 0.89, Colors.purple);
  }

  void _drawTree(Canvas canvas, double x, double y, double size) {
    // Trunk
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(x, y + size * 0.3),
        width: size * 0.3,
        height: size * 0.6,
      ),
      Paint()..color = Color(0xFF6D4C41),
    );

    // Leaves (circles)
    canvas.drawCircle(
      Offset(x, y - size * 0.2),
      size * 0.5,
      Paint()..color = Color(0xFF43A047),
    );
    canvas.drawCircle(
      Offset(x - size * 0.3, y),
      size * 0.4,
      Paint()..color = Color(0xFF4CAF50),
    );
    canvas.drawCircle(
      Offset(x + size * 0.3, y),
      size * 0.4,
      Paint()..color = Color(0xFF66BB6A),
    );
  }

  void _drawFlower(Canvas canvas, double x, double y, Color color) {
    // Stem
    canvas.drawLine(
      Offset(x, y),
      Offset(x, y - 20),
      Paint()
        ..color = Color(0xFF4CAF50)
        ..strokeWidth = 3,
    );

    // Petals
    for (int i = 0; i < 5; i++) {
      double angle = (i * 72) * math.pi / 180;
      double px = x + math.cos(angle) * 8;
      double py = y - 20 + math.sin(angle) * 8;

      canvas.drawCircle(
        Offset(px, py),
        6,
        Paint()..color = color,
      );
    }

    // Center
    canvas.drawCircle(
      Offset(x, y - 20),
      4,
      Paint()..color = Colors.yellow,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}