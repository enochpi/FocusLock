import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import 'dart:math' show Random;
import 'package:rive/rive.dart' hide LinearGradient, RadialGradient;
import '../models/character.dart';
import '../models/farm.dart';
import '../models/cave_decorations.dart';
import '../services/storage_service.dart';
import 'focus_active_screen.dart';
import 'garden_focus_screen.dart'; // ✅ ADD THIS LINE!
import 'cave_interior_screen.dart';
import '../services/currency_service.dart';
import '../widgets/converter_dialog.dart';

class CaveSceneScreen extends StatefulWidget {
  final Character character;
  final Farm farm;
  final CaveDecorations decorations;
  final VoidCallback onUpdate;

  CaveSceneScreen({
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

  void refreshCurrencyUI() {
    setState(() {});
  }

  Widget _buildCurrencyDisplay({
    required String icon,
    required int amount,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 2),
      ),
      child: Row(
        children: [
          Text(icon, style: TextStyle(fontSize: 20)),
          SizedBox(width: 6),
          Text(
            "$amount",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
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
      duration: Duration(milliseconds: 300),
    )..repeat(reverse: true);

    // Butterfly controller
    _butterflyController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 4), // 4 seconds to fly across
    );

    // Start butterfly animation periodically
    _startButterflyLoop();
  }

  void _startButterflyLoop() {
    Future.delayed(Duration(seconds: 5), () {
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

    Future.delayed(Duration(milliseconds: 500), () {
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
      builder: (context) => TimerPickerDialog(),
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
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Color(0xFF16213e),
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
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Color(0xFF4CAF50).withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Color(0xFF4CAF50), width: 2),
                  ),
                  child: Row(
                    children: [
                      Text("🌱", style: TextStyle(fontSize: 24)),
                      SizedBox(width: 8),
                      Text(
                        "${currency.peas}",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // Converter button (center)
                ElevatedButton(
                  onPressed: () async {
                    bool? converted = await showConverterDialog(context);
                    if (converted == true) refreshCurrencyUI();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF4CAF50),
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 4,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("🌱", style: TextStyle(fontSize: 18)),
                      SizedBox(width: 6),
                      Icon(Icons.arrow_forward, size: 18, color: Colors.white),
                      SizedBox(width: 6),
                      Text("🪙", style: TextStyle(fontSize: 18)),
                    ],
                  ),
                ),

                // Coins counter (right)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Color(0xFFFFD700).withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Color(0xFFFFD700), width: 2),
                  ),
                  child: Row(
                    children: [
                      Text("🪙", style: TextStyle(fontSize: 24)),
                      SizedBox(width: 8),
                      Text(
                        "${currency.coins}",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
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
              child: Container(
                width: double.infinity,
                child: Stack(
                  children: [
                    // SKY (top portion)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0xFF87CEEB), // Light blue sky
                              Color(0xFFB0E0E6), // Lighter blue
                            ],
                            stops: [0.0, 1.0],
                          ),
                        ),
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
                              Color(0xFF7CB342), // Lighter grass
                              Color(0xFF558B2F), // Darker grass
                            ],
                          ),
                        ),
                        child: CustomPaint(
                          painter: GrassTexturePainter(),
                        ),
                      ),
                    ),

                    // SUN (top right) - Placeholder for your PNG
                    Positioned(
                      top: 40,
                      right: 40,
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFFFD700), // Gold yellow
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFFFFD700).withOpacity(0.5),
                              blurRadius: 30,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                        // REPLACE THIS WITH YOUR PNG:
                        // child: Image.asset('assets/images/sun.png'),
                      ),
                    ),

                    // CAVE ENTRANCE (Rive animation! 🏔️)
                    Positioned(
                      top: MediaQuery.of(context).size.height * 0.2 - 140,
                      left: MediaQuery.of(context).size.width / 2 - 140,
                      child: SizedBox(
                        width: 300,
                        height: 350,
                        child: Stack(
                          clipBehavior: Clip.none, // 🔑 ALLOW OVERFLOW
                          children: [
                            // Cave animation
                            AnimatedScale(
                              scale: _caveScale,
                              duration: const Duration(milliseconds: 100),
                              curve: Curves.easeInOut,
                              child: RiveAnimation.asset(
                                'assets/animations/cave.riv',
                                fit: BoxFit.contain,
                                alignment: Alignment.bottomCenter,
                                stateMachines: const ['State Machine 1'],
                              ),
                            ),

                            // Tap hitbox (on top)
                            Positioned(
                              left: 50,
                              top: 150,
                              child: GestureDetector(
                                behavior: HitTestBehavior.translucent, // 🔑 IMPORTANT
                                onTapDown: (_) {
                                  setState(() => _caveScale = 0.95);
                                },
                                onTapUp: (_) {
                                  setState(() => _caveScale = 1.0);
                                  openCave();
                                },
                                onTapCancel: () {
                                  setState(() => _caveScale = 1.0);
                                },
                                child: Container(
                                  width: 200,
                                  height: 170,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.red.withOpacity(0.3), // debug
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),


                    // GARDEN (Rive animation only - NO tap! 🌱)
                    Positioned(
                      bottom: MediaQuery.of(context).size.height * 0.01,
                      left: MediaQuery.of(context).size.width / 2 - 210,
                      child: SizedBox(
                        width: 450,
                        height: 410,
                        child: RiveAnimation.asset(
                          'assets/animations/garden.riv',
                          fit: BoxFit.contain,
                          stateMachines: ['State Machine 1'],
                        ),
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
                            duration: Duration(milliseconds: 100),
                            curve: Curves.easeInOut,
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 35, vertical: 16),
                              decoration: BoxDecoration(
                                color: Color(0xFF4CAF50),
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 10,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Text(
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
                    AnimatedPositioned(
                      duration: Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      left: alexX,
                      top: alexY,
                      child: _buildAlex(),
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
                              child: Text(
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

  Widget _buildAlex() {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            widget.character.name,
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(height: 5),
        AnimatedBuilder(
          animation: _walkController ?? AnimationController(vsync: this, duration: Duration.zero),
          builder: (context, child) {
            double bounce = isWalking && _walkController != null ? _walkController!.value * 3 : 0;

            return Transform.translate(
              offset: Offset(0, -bounce),
              child: Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()..scale(facingRight ? 1.0 : -1.0, 1.0),
                child: Container(
                  width: 60,
                  height: 80,
                  child: Stack(
                    children: [
                      Positioned(
                        top: 0,
                        left: 15,
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            color: Color(0xFFffdbac),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.brown[800]!, width: 2),
                          ),
                          child: Center(
                            child: Text(
                              "👁️",
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 28,
                        left: 10,
                        child: Container(
                          width: 40,
                          height: 35,
                          decoration: BoxDecoration(
                            color: Color(0xFF5d4e37),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.brown[900]!, width: 2),
                          ),
                          child: CustomPaint(
                            painter: RaggedClothPainter(),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 60,
                        left: 15,
                        child: Container(
                          width: 10,
                          height: 20,
                          decoration: BoxDecoration(
                            color: Color(0xFF4a3f2f),
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 60,
                        left: 35,
                        child: Container(
                          width: 10,
                          height: 20,
                          decoration: BoxDecoration(
                            color: Color(0xFF4a3f2f),
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ],
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
            Text("🔥", style: TextStyle(fontSize: 30)),
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
      decoration: BoxDecoration(
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
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Color(0xFF0f3460),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Text(emoji, style: TextStyle(fontSize: 20)),
          SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(
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
      ..color = Color(0xFF3d3426)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawLine(Offset(5, 10), Offset(15, 15), paint);
    canvas.drawLine(Offset(20, 8), Offset(25, 18), paint);
    canvas.drawLine(Offset(10, 25), Offset(18, 30), paint);
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
        grassColor = Color(0xFF689F38);
      } else if (colorRand < 0.6) {
        grassColor = Color(0xFF7CB342);
      } else {
        grassColor = Color(0xFF8BC34A);
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
        Color(0xFFFFEB3B), // Yellow
        Color(0xFFFFFFFF), // White
        Color(0xFFFF69B4), // Pink
        Color(0xFFE1BEE7), // Light purple
      ];

      Color flowerColor = flowerColors[random.nextInt(flowerColors.length)];

      // Draw small flower
      final flowerPaint = Paint()..color = flowerColor;
      canvas.drawCircle(Offset(x, y), 2, flowerPaint);

      // Stem
      final stemPaint = Paint()
        ..color = Color(0xFF558B2F)
        ..strokeWidth = 1;
      canvas.drawLine(Offset(x, y), Offset(x, y + 5), stemPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ✅ UPDATED DIALOG - Shows garden earnings
class TimerPickerDialog extends StatefulWidget {
  @override
  _TimerPickerDialogState createState() => _TimerPickerDialogState();
}

class _TimerPickerDialogState extends State<TimerPickerDialog> {
  int selectedMinutes = 25;

  @override
  Widget build(BuildContext context) {
    int earnings = selectedMinutes * 5; // ✅ $5 per minute in garden

    return AlertDialog(
      backgroundColor: Color(0xFF16213e),
      title: Text(
        "Work in Garden 🌱", // ✅ Updated title
        style: TextStyle(color: Colors.white),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "$selectedMinutes minutes",
            style: TextStyle(
              color: Color(0xFF00d4ff),
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 20),
          Slider(
            value: selectedMinutes.toDouble(),
            min: 1,
            max: 120,
            divisions: 119,
            activeColor: Color(0xFF00d4ff),
            onChanged: (value) {
              setState(() {
                selectedMinutes = value.toInt();
              });
            },
          ),
          Text(
            "Earn \$$earnings 🌱", // ✅ Shows garden earnings
            style: TextStyle(
              color: Colors.greenAccent,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text("Cancel", style: TextStyle(color: Colors.white54)),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, selectedMinutes),
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF00d4ff),
          ),
          child: Text("Start Working", style: TextStyle(color: Colors.white)), // ✅ Updated text
        ),
      ],
    );
  }
}