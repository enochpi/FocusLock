import 'package:flutter/material.dart';
import 'dart:async';
import '../models/character.dart';
import '../models/farm.dart';
import '../models/cave_decorations.dart'; // ADD THIS
import '../services/storage_service.dart';
import 'focus_active_screen.dart';
import 'cave_interior_screen.dart'; // ADD THIS

class CaveSceneScreen extends StatefulWidget {
  final Character character;
  final Farm farm;
  final CaveDecorations decorations; // ADD THIS
  final VoidCallback onUpdate;

  CaveSceneScreen({
    required this.character,
    required this.farm,
    required this.decorations, // ADD THIS
    required this.onUpdate,
  });

  @override
  _CaveSceneScreenState createState() => _CaveSceneScreenState();
}

class _CaveSceneScreenState extends State<CaveSceneScreen> with TickerProviderStateMixin {
  StorageService storage = StorageService();

  double alexX = 150;
  double alexY = 300;
  bool facingRight = true;
  AnimationController? _walkController;
  bool isWalking = false;

  @override
  void initState() {
    super.initState();
    _walkController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _walkController?.dispose();
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

  void startFocus() async {
    int? minutes = await showDialog<int>(
      context: context,
      builder: (context) => TimerPickerDialog(),
    );

    if (minutes != null && minutes > 0) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FocusActiveScreen(
            character: widget.character,
            farm: widget.farm,
            durationMinutes: minutes,
          ),
        ),
      ).then((_) {
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
          Container(
            padding: EdgeInsets.all(15),
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
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatBox("💰", "${widget.character.money}"),
                _buildStatBox("⭐", "${widget.character.focusPoints}"),
                _buildStatBox("⏱️", "${widget.character.totalFocusMinutes}m"),
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
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(0.3, -0.5),
                    radius: 1.2,
                    colors: [
                      Color(0xFF4a4a4a),
                      Color(0xFF2d2d2d),
                      Color(0xFF1a1a1a),
                      Color(0xFF0a0a0a),
                    ],
                    stops: [0.0, 0.3, 0.6, 1.0],
                  ),
                ),
                child: Stack(
                  children: [
                    ..._buildCaveDecorations(),

                    // CAVE ENTRANCE
                    Positioned(
                      top: 50,
                      left: MediaQuery.of(context).size.width / 2 - 60,
                      child: GestureDetector(
                        onTap: openCave,
                        child: Container(
                          width: 120,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Color(0xFF1a1a1a),
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(60),
                            ),
                            border: Border.all(color: Colors.brown[800]!, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black87,
                                blurRadius: 15,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text("🏔️", style: TextStyle(fontSize: 40)),
                                SizedBox(height: 5),
                                Text(
                                  "Enter Cave",
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
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

                    // Instruction
                    Positioned(
                      bottom: 120,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            "Tap anywhere to move • Tap cave to enter",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Start Focus Button
                    Positioned(
                      bottom: 20,
                      left: 40,
                      right: 40,
                      child: ElevatedButton(
                        onPressed: startFocus,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF00d4ff),
                          padding: EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 10,
                          shadowColor: Color(0xFF00d4ff).withOpacity(0.5),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.play_arrow, size: 28, color: Colors.white),
                            SizedBox(width: 10),
                            Text(
                              "Start Focus",
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
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

  Widget _buildGardenPlot(int index) {
    bool hasCrop = index < widget.farm.crops.length;

    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: hasCrop ? Colors.brown[700] : Colors.brown[900],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.brown, width: 2),
      ),
      child: Center(
        child: Text(
          hasCrop ? "🌱" : "⬜",
          style: TextStyle(fontSize: 24),
        ),
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

class TimerPickerDialog extends StatefulWidget {
  @override
  _TimerPickerDialogState createState() => _TimerPickerDialogState();
}

class _TimerPickerDialogState extends State<TimerPickerDialog> {
  int selectedMinutes = 25;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Color(0xFF16213e),
      title: Text(
        "Set Focus Timer",
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
            "Earn ${selectedMinutes * 2} coins",
            style: TextStyle(color: Colors.white70),
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
          child: Text("Start", style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}