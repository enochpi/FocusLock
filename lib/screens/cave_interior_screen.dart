import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:focus_life/services/currency_service.dart';
import 'dart:math' as math;
import '../models/character.dart';
import '../models/cave_decorations.dart';
import '../services/storage_service.dart';
import 'shop_screen.dart';
import '../services/furniture_service.dart';
import 'cave_shop_screen.dart';
import 'dart:async';
import 'dart:math';

class CaveInteriorScreen extends StatefulWidget {
  final Character character;
  final CaveDecorations decorations;

  CaveInteriorScreen({
    required this.character,
    required this.decorations,
  });

  @override
  _CaveInteriorScreenState createState() => _CaveInteriorScreenState();
}

class _CaveInteriorScreenState extends State<CaveInteriorScreen> {
  StorageService storage = StorageService();

  // Rotation control
  double rotationX = 0.25;
  double rotationY = 0.35;

  // Pan control
  double offsetX = 0.0;
  double offsetY = 0.0;

  // For tracking gestures
  Offset? _lastDragPosition;
  double _scale = 1.0;

  Color get backgroundColor {
    int level = widget.decorations.lightingLevel;
    switch (level) {
      case 0: return Color(0xFF2a2a2a);
      case 1: return Color(0xFF3a3a3a);
      case 2: return Color(0xFF4a4a4a);
      case 3: return Color(0xFF5a5a5a);
      case 4: return Color(0xFF6a6a6a);
      default: return Color(0xFF2a2a2a);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0a0a0a),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text("My Cave"),
        actions: [
          // Debug money button
          IconButton(
            icon: Icon(Icons.attach_money, color: Colors.green),
            onPressed: () async {
              await CurrencyService().addCoins(100);
              setState(() {});
            },
            tooltip: "Add Coins (Debug)",
          ),

          // Show coins
          Padding(
            padding: EdgeInsets.all(12),
            child: Center(
              child: Text(
                "🪙 ${CurrencyService().coins}",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Cave with animated pea
          Listener(
            onPointerSignal: (event) {
              if (event is PointerScrollEvent) {
                setState(() {
                  _scale = (_scale - event.scrollDelta.dy * 0.001).clamp(0.7, 2.0);
                });
              }
            },
            child: GestureDetector(
              onScaleStart: (details) {
                _lastDragPosition = details.focalPoint;
              },
              onScaleUpdate: (details) {
                setState(() {
                  if (details.scale != 1.0) {
                    _scale = (_scale * details.scale).clamp(0.7, 2.0);
                  }

                  if (_lastDragPosition != null) {
                    double dx = details.focalPoint.dx - _lastDragPosition!.dx;
                    double dy = details.focalPoint.dy - _lastDragPosition!.dy;

                    if (details.pointerCount == 2) {
                      offsetX += dx;
                      offsetY += dy;
                    } else {
                      rotationY += dx * 0.005;
                      rotationX += dy * 0.005;
                      rotationX = rotationX.clamp(0.0, 0.5);
                      rotationY = rotationY.clamp(0.1, 0.6);
                    }
                  }
                  _lastDragPosition = details.focalPoint;
                });
              },
              onScaleEnd: (details) {
                _lastDragPosition = null;
              },
              onTapUp: (details) {
                _handleTap(details.localPosition);
              },
              child: Center(
                child: Transform.translate(
                  offset: Offset(offsetX, offsetY),
                  child: Transform.scale(
                    scale: _scale,
                    child: Container(
                      width: 400,
                      height: 500,
                      child: Stack(
                        children: [
                          // Cave painting
                          CustomPaint(
                            size: Size(400, 500),
                            painter: ThickWallCubePainter(
                              backgroundColor: backgroundColor,
                              lightLevel: widget.decorations.lightingLevel,
                              decorations: widget.decorations,
                              rotationX: rotationX,
                              rotationY: rotationY,
                              furnitureService: FurnitureService(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Shop button
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton.icon(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => CaveShopScreen()),
                  );
                  setState(() {});
                },
                icon: Icon(Icons.shopping_bag, size: 22, color: Colors.white),
                label: Text(
                  "Shop",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF4CAF50),
                  padding: EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleTap(Offset position) {
    // Adjust for scale and offset
    double adjustedX = (position.dx - MediaQuery.of(context).size.width / 2 - offsetX) / _scale + 200;
    double adjustedY = (position.dy - MediaQuery.of(context).size.height / 2 - offsetY) / _scale + 250;

    // Screen center
    double cx = 200.0;
    double cy = 250.0;

    // Project 3D positions of placement spots to screen coordinates
    double tapRadius = 35.0;

    // Helper function to project and check
    bool checkSpot(double x3d, double y3d, double z3d) {
      Offset projected = _project3D(x3d, y3d, z3d, cx, cy);
      return _isNear(adjustedX, adjustedY, projected.dx, projected.dy, tapRadius);
    }

    // Bed spot
    if (checkSpot(60, -150, 80) &&
        widget.decorations.getEquippedItem('bed_main') == null) {
      _openItemPicker('bed_main');
      return;
    }

    // Table spot
    if (checkSpot(-20, -150, 40) &&
        widget.decorations.getEquippedItem('decoration_3') == null) {
      _openItemPicker('decoration_3');
      return;
    }

    // Light spot
    if (checkSpot(0, 80, -150) &&
        widget.decorations.getEquippedItem('light_main') == null) {
      _openItemPicker('light_main');
      return;
    }

    // Wall decoration 1
    if (checkSpot(-80, 0, -150) &&
        widget.decorations.getEquippedItem('decoration_1') == null) {
      _openItemPicker('decoration_1');
      return;
    }

    // Wall decoration 2
    if (checkSpot(150, 0, -50) &&
        widget.decorations.getEquippedItem('decoration_2') == null) {
      _openItemPicker('decoration_2');
      return;
    }
  }

  Offset _project3D(double x, double y, double z, double cx, double cy) {
    // Same rotation math as in painter
    double cosX = math.cos(rotationX);
    double sinX = math.sin(rotationX);
    double y1 = y * cosX - z * sinX;
    double z1 = y * sinX + z * cosX;

    double cosY = math.cos(rotationY);
    double sinY = math.sin(rotationY);
    double x2 = x * cosY + z1 * sinY;
    double y2 = y1;

    return Offset(cx + x2, cy - y2);
  }

  bool _isNear(double x, double y, double targetX, double targetY, double radius) {
    double dx = x - targetX;
    double dy = y - targetY;
    return (dx * dx + dy * dy) < (radius * radius);
  }

  void _openItemPicker(String spotId) {
    PlacementSpot spot = widget.decorations.spots.firstWhere((s) => s.id == spotId);

    showModalBottomSheet(
      context: context,
      backgroundColor: Color(0xFF16213e),
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => ItemPickerSheet(
        character: widget.character,
        decorations: widget.decorations,
        spot: spot,
        onItemSelected: (itemId) {
          setState(() {
            widget.decorations.equipItem(spot.id, itemId);
          });
          storage.saveCaveDecorations(widget.decorations);
          storage.saveCharacter(widget.character);
          Navigator.pop(context);
        },
      ),
    );
  }
}

// SIMPLE TWO-WALL PAINTER with placement spots
class ThickWallCubePainter extends CustomPainter {
  final Color backgroundColor;
  final int lightLevel;
  final CaveDecorations decorations;
  final double rotationX;
  final double rotationY;
  final FurnitureService? furnitureService;

  ThickWallCubePainter({
    required this.backgroundColor,
    required this.lightLevel,
    required this.decorations,
    required this.rotationX,
    required this.rotationY,
    this.furnitureService,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Background
    _drawSimpleBackground(canvas, size);

    // 2. Back wall
    _drawBackWall(canvas, size);

    // 3. Floor
    _drawFloor(canvas, size);

    // 4. PLACED FURNITURE (from shop!)
    _drawPlacedFurniture(canvas, size);
  }

  void _drawSimpleBackground(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Color(0xFF4a4440),
    );
  }

  void _drawBackWall(Canvas canvas, Size size) {
    final wallHeight = size.height * 0.6;

    final blockPaint = Paint()
      ..color = Colors.black.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (int i = 1; i < 5; i++) {
      double y = (wallHeight / 5) * i;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        blockPaint,
      );
    }

    for (int row = 0; row < 5; row++) {
      double y = (wallHeight / 5) * row;
      int blocks = 6 + (row % 2);

      for (int i = 1; i < blocks; i++) {
        double x = (size.width / blocks) * i;
        canvas.drawLine(
          Offset(x, y),
          Offset(x, y + wallHeight / 5),
          blockPaint,
        );
      }
    }

    canvas.drawLine(
      Offset(0, wallHeight),
      Offset(size.width, wallHeight),
      Paint()
        ..color = Color(0xFF2a2420)
        ..strokeWidth = 4,
    );
  }

  void _drawFloor(Canvas canvas, Size size) {
    final floorTop = size.height * 0.6;

    final plankPaint = Paint()
      ..color = Color(0xFF3d2f22)
      ..strokeWidth = 2;

    for (int i = 1; i < 8; i++) {
      double y = floorTop + (size.height * 0.4 / 8) * i;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        plankPaint,
      );
    }
  }

  void _drawPlacedFurniture(Canvas canvas, Size size) {
    if (furnitureService == null) return;

    final floorY = size.height * 0.6;

    Furniture? bed = furnitureService!.getPlacedFurniture('bed_spot');      // ← ADD THIS!
    Furniture? desk = furnitureService!.getPlacedFurniture('desk_spot');
    Furniture? chair = furnitureService!.getPlacedFurniture('chair_spot');
    Furniture? kitchen = furnitureService!.getPlacedFurniture('kitchen_spot');

    List<Furniture> allDecorations = [];
    for (int i = 1; i <= 6; i++) {
      Furniture? deco = furnitureService!.getPlacedFurniture('decoration_spot_$i');
      if (deco != null) {
        allDecorations.add(deco);
      }
    }

    bool hasHangingPlant = allDecorations.any((d) => d.id.contains('hanging_plant'));
    bool hasWallTorch = allDecorations.any((d) => d.id.contains('wall_torch'));
    bool hasPainting = allDecorations.any((d) => d.id.contains('painting'));
    bool hasCrystal = allDecorations.any((d) => d.id.contains('crystal'));

    if (hasHangingPlant) {
      _drawHangingPlant(canvas, size.width * 0.25, 6);
      _drawHangingPlant(canvas, size.width * 0.75, 6);
    }

    if (hasWallTorch) {
      _drawWallTorch(canvas, size.width * 0.1, size.height * 0.20);
      _drawWallTorch(canvas, size.width * 0.9, size.height * 0.20);
    }

    if (hasPainting) {
      _drawPictureFrame(canvas, size.width * 0.70, size.height * 0.25);
    }

    if (hasCrystal) {
      _drawCrystalCluster(canvas, size.width * 0.5, size.height * 0.12);
    }

    // Draw bed based on type (against right wall)
    if (bed != null) {
      if (bed.id == 'hay_bed') {
        _drawHayBed(canvas, size.width - 100, floorY - 40);
      } else if (bed.id == 'simple_cot') {
        _drawSimpleCot(canvas, size.width - 110, floorY - 45);
      } else if (bed.id == 'wood_bed') {
        _drawWoodFrameBed(canvas, size.width - 120, floorY - 55);
      }
    }

    // Draw desks based on type
    if (desk != null) {
      if (desk.id == 'simple_desk') {
        _drawSimpleDesk(canvas, size.width * 0.40, floorY - 20); // ← ADJUST THESE NUMBERS
      } else if (desk.id == 'oak_desk') {
        _drawOakDesk(canvas, size.width * 0.40, floorY - 20); // ← ADJUST THESE NUMBERS
      } else if (desk.id == 'executive_desk') {
        _drawExecutiveDesk(canvas, size.width * 0.40, floorY - 20); // ← ADJUST THESE NUMBERS
      }
    }

    // Draw chair in front of desk (position adjusts based on chair type)
    if (chair != null && desk != null) {
      double chairX = size.width * 0.42 + 35;
      double chairY = floorY + 25;

      if (chair.id == 'old_stool') {
        _drawOldStool(canvas, chairX, chairY);
      } else if (chair.id == 'wooden_chair') {
        _drawWoodenChair(canvas, chairX, chairY);
      } else if (chair.id == 'comfy_chair') {
        _drawComfyChair(canvas, chairX, chairY);
      }
    }

    if (kitchen != null) {
      if (kitchen.id == 'campfire') {
        _drawCampfire(canvas, 80, floorY);
      } else if (kitchen.id == 'simple_stove') {
        _drawSimpleStove(canvas, 60, floorY);
      } else if (kitchen.id == 'wood_stove') {
        _drawWoodStove(canvas, 60, floorY);
      }
    }
  }

// Draw decorations based on type
  void _drawDecoration(Canvas canvas, double x, double y, Furniture furniture) {
    if (furniture.id.contains('hanging_plant')) {
      _drawHangingPlant(canvas, x, y - 30);
    } else if (furniture.id.contains('wall_torch')) {
      _drawWallTorch(canvas, x, y);
    } else if (furniture.id.contains('painting')) {
      _drawPictureFrame(canvas, x, y);
    } else if (furniture.id.contains('crystal')) {
      _drawCrystalCluster(canvas, x, y - 20);
    }
  }

// Wall torch for decoration spot
  void _drawWallTorch(Canvas canvas, double x, double y) {
    // Brown wooden handle
    final handlePath = Path()
      ..moveTo(x - 3, y + 15)
      ..lineTo(x + 3, y + 15)
      ..lineTo(x + 2, y - 15)
      ..lineTo(x - 2, y - 15)
      ..close();

    canvas.drawPath(
      handlePath,
      Paint()..color = Color(0xFF6D4C41), // Brown wood
    );

    // Handle texture (wood grain lines)
    for (int i = 0; i < 3; i++) {
      canvas.drawLine(
        Offset(x - 2, y - 10 + (i * 8)),
        Offset(x + 2, y - 10 + (i * 8)),
        Paint()
          ..color = Color(0xFF5D4037)
          ..strokeWidth = 1,
      );
    }

    // Metal bracket (holds torch to wall)
    final bracketPaint = Paint()
      ..color = Color(0xFF424242)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    // Vertical bracket bar
    canvas.drawLine(
      Offset(x - 10, y - 5),
      Offset(x - 10, y + 10),
      bracketPaint,
    );

    // Horizontal bracket holder
    canvas.drawLine(
      Offset(x - 10, y),
      Offset(x - 3, y),
      bracketPaint,
    );

    // Torch top (fire holder - black iron)
    canvas.drawCircle(
      Offset(x, y - 18),
      5,
      Paint()..color = Color(0xFF2C2C2C),
    );

    // Fire glow effect
    canvas.drawCircle(
      Offset(x, y - 18),
      18,
      Paint()
        ..color = Color(0xFFFF8C42).withOpacity(0.3)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 15),
    );

    // Bright inner glow
    canvas.drawCircle(
      Offset(x, y - 18),
      10,
      Paint()
        ..color = Color(0xFFFFD54F).withOpacity(0.5)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8),
    );

    // Fire flame emoji
    _drawEmoji(canvas, '🔥', x, y - 18, 22);
  }
  // Picture frame with landscape
  void _drawPictureFrame(Canvas canvas, double x, double y) {
    // Outer wood frame
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(x, y), width: 50, height: 60),
        Radius.circular(3),
      ),
      Paint()..color = Color(0xFF8D6E63),
    );

    // Inner canvas (picture area)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(x, y), width: 40, height: 50),
        Radius.circular(2),
      ),
      Paint()..color = Color(0xFFE8D4B8),
    );

    // Sky
    canvas.drawRect(
      Rect.fromLTWH(x - 18, y - 23, 36, 20),
      Paint()..color = Color(0xFF87CEEB),
    );

    // Mountains
    final mountainPath = Path()
      ..moveTo(x - 18, y - 3)
      ..lineTo(x - 8, y - 15)
      ..lineTo(x + 2, y - 3)
      ..close();
    canvas.drawPath(
      mountainPath,
      Paint()..color = Color(0xFF8B7355),
    );

    final mountainPath2 = Path()
      ..moveTo(x - 5, y - 3)
      ..lineTo(x + 5, y - 12)
      ..lineTo(x + 15, y - 3)
      ..close();
    canvas.drawPath(
      mountainPath2,
      Paint()..color = Color(0xFF6B5B4D),
    );

    // Ground
    canvas.drawRect(
      Rect.fromLTWH(x - 18, y - 3, 36, 20),
      Paint()..color = Color(0xFF7CB342),
    );

    // Simple tree
    canvas.drawCircle(
      Offset(x - 10, y + 5),
      6,
      Paint()..color = Color(0xFF4CAF50),
    );
    canvas.drawRect(
      Rect.fromLTWH(x - 11, y + 10, 2, 7),
      Paint()..color = Color(0xFF5D4037),
    );

    // Frame border
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(x, y), width: 50, height: 60),
        Radius.circular(3),
      ),
      Paint()
        ..color = Color(0xFF5D4037)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

// Crystal cluster
  void _drawCrystalCluster(Canvas canvas, double x, double y) {
    // Glow effect
    canvas.drawCircle(
      Offset(x, y),
      30,
      Paint()
        ..color = Color(0xFF6EC6FF).withOpacity(0.3)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 20),
    );

    // Crystal shards
    for (int i = 0; i < 3; i++) {
      double offsetX = (i - 1) * 15;
      Color color = i == 0 ? Color(0xFF6EC6FF) :
      i == 1 ? Color(0xFF9D6EFF) : Color(0xFF6EFFB4);

      _drawCrystal(canvas, x + offsetX, y, color);
    }
  }

// Individual crystal
  void _drawCrystal(Canvas canvas, double x, double y, Color color) {
    final crystalPath = Path()
      ..moveTo(x, y - 15)
      ..lineTo(x - 6, y + 10)
      ..lineTo(x + 6, y + 10)
      ..close();

    // Fill
    canvas.drawPath(
      crystalPath,
      Paint()..color = color.withOpacity(0.8),
    );

    // Outline
    canvas.drawPath(
      crystalPath,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Highlight
    canvas.drawLine(
      Offset(x - 3, y),
      Offset(x, y - 15),
      Paint()
        ..color = Colors.white.withOpacity(0.7)
        ..strokeWidth = 1.5,
    );
  }

// Hanging plant for decoration spot
  void _drawHangingPlant(Canvas canvas, double x, double y) {
    // Rope/chain hanging down
    canvas.drawLine(
      Offset(x, 0),
      Offset(x, y + 25),
      Paint()
        ..color = Color(0xFF8D6E63)
        ..strokeWidth = 2,
    );

    // Rope knot at top of pot
    canvas.drawCircle(
      Offset(x, y + 23),
      3,
      Paint()..color = Color(0xFF6D4C41),
    );

    // Terracotta pot (wider trapezoid)
    final potPath = Path()
      ..moveTo(x - 14, y + 25)
      ..lineTo(x - 10, y + 42)
      ..lineTo(x + 10, y + 42)
      ..lineTo(x + 14, y + 25)
      ..close();

    // Pot fill (terracotta orange)
    canvas.drawPath(
      potPath,
      Paint()..color = Color(0xFFD4866A),
    );

    // Pot rim (darker band at top)
    canvas.drawRect(
      Rect.fromLTWH(x - 14, y + 25, 28, 3),
      Paint()..color = Color(0xFFB86F56),
    );

    // Decorative stripe on pot
    canvas.drawLine(
      Offset(x - 12, y + 33),
      Offset(x + 12, y + 33),
      Paint()
        ..color = Color(0xFFB86F56)
        ..strokeWidth = 2,
    );

    // Pot outline (clean edges)
    canvas.drawPath(
      potPath,
      Paint()
        ..color = Color(0xFFAA6652)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Soil surface (dark brown)
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x, y + 26), width: 24, height: 6),
      Paint()..color = Color(0xFF4A3C2E),
    );

    // Soil texture (little dots)
    for (int i = 0; i < 5; i++) {
      canvas.drawCircle(
        Offset(x - 8 + (i * 4), y + 26),
        1,
        Paint()..color = Color(0xFF3A2C1E),
      );
    }

    // SPROUT 1 (Left side - taller with 2 leaves)
    // Stem
    canvas.drawLine(
      Offset(x - 5, y + 26),
      Offset(x - 5, y + 14),
      Paint()
        ..color = Color(0xFF6B8E23)
        ..strokeWidth = 2,
    );

    // Left leaf
    final leaf1Path = Path()
      ..moveTo(x - 5, y + 18)
      ..quadraticBezierTo(x - 10, y + 16, x - 11, y + 19)
      ..quadraticBezierTo(x - 10, y + 20, x - 5, y + 19)
      ..close();
    canvas.drawPath(
      leaf1Path,
      Paint()..color = Color(0xFF7CB342),
    );

    // Right leaf
    final leaf2Path = Path()
      ..moveTo(x - 5, y + 16)
      ..quadraticBezierTo(x, y + 14, x + 1, y + 17)
      ..quadraticBezierTo(x, y + 18, x - 5, y + 17)
      ..close();
    canvas.drawPath(
      leaf2Path,
      Paint()..color = Color(0xFF7CB342),
    );

    // SPROUT 2 (Right side - shorter with rounded leaves)
    // Stem
    canvas.drawLine(
      Offset(x + 6, y + 26),
      Offset(x + 5, y + 16),
      Paint()
        ..color = Color(0xFF6B8E23)
        ..strokeWidth = 2,
    );

    // Left rounded leaf
    canvas.drawCircle(
      Offset(x + 2, y + 18),
      3.5,
      Paint()..color = Color(0xFF8BC34A),
    );

    // Right rounded leaf
    canvas.drawCircle(
      Offset(x + 8, y + 19),
      3,
      Paint()..color = Color(0xFF8BC34A),
    );

    // SPROUT 3 (Center back - tiny baby sprout)
    // Stem
    canvas.drawLine(
      Offset(x, y + 26),
      Offset(x, y + 21),
      Paint()
        ..color = Color(0xFF7CB342)
        ..strokeWidth = 1.5,
    );

    // Tiny leaves (just circles)
    canvas.drawCircle(
      Offset(x - 2, y + 22),
      2,
      Paint()..color = Color(0xFF9CCC65),
    );
    canvas.drawCircle(
      Offset(x + 2, y + 22),
      2,
      Paint()..color = Color(0xFF9CCC65),
    );
  }

// REALISTIC BED (against right wall)
  void _drawRealisticBed(Canvas canvas, double x, double y) {
    // Bed frame base
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, 90, 120),
        Radius.circular(5),
      ),
      Paint()..color = Color(0xFF8D6E63),
    );

    // Bed frame outline
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, 90, 120),
        Radius.circular(5),
      ),
      Paint()
        ..color = Color(0xFF6D4C41)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    // Mattress
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x + 5, y + 5, 80, 110),
        Radius.circular(4),
      ),
      Paint()..color = Color(0xFFE8E8E8),
    );

    // Pillow
    canvas.drawOval(
      Rect.fromLTWH(x + 15, y + 15, 60, 30),
      Paint()..color = Color(0xFFFFFFFF),
    );

    canvas.drawOval(
      Rect.fromLTWH(x + 15, y + 15, 60, 30),
      Paint()
        ..color = Color(0xFFCCCCCC)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Blanket
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x + 10, y + 50, 70, 60),
        Radius.circular(4),
      ),
      Paint()..color = Color(0xFF4CAF50),
    );

    // Blanket folds
    for (int i = 0; i < 3; i++) {
      canvas.drawLine(
        Offset(x + 15, y + 60 + (i * 15)),
        Offset(x + 75, y + 60 + (i * 15)),
        Paint()
          ..color = Color(0xFF388E3C)
          ..strokeWidth = 1.5,
      );
    }
  }

// REALISTIC DESK (against wall)
  void _drawRealisticDesk(Canvas canvas, double x, double y) {
    // Desk top
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, 100, 18),
        Radius.circular(3),
      ),
      Paint()..color = Color(0xFF795548),
    );

    // Desk top highlight
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, 100, 5),
        Radius.circular(3),
      ),
      Paint()..color = Color(0xFF8D6E63).withOpacity(0.5),
    );

    // Desk outline
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, 100, 18),
        Radius.circular(3),
      ),
      Paint()
        ..color = Color(0xFF5D4037)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Left leg
    canvas.drawRect(
      Rect.fromLTWH(x + 8, y + 18, 10, 75),
      Paint()..color = Color(0xFF6D4C41),
    );

    // Right leg
    canvas.drawRect(
      Rect.fromLTWH(x + 82, y + 18, 10, 75),
      Paint()..color = Color(0xFF6D4C41),
    );

    // Chair in front of desk
    _drawRealisticChair(canvas, x + 35, y + 100);

    // Lamp on desk
    _drawRealisticLamp(canvas, x + 75, y - 15);
  }

// REALISTIC CHAIR
  void _drawRealisticChair(Canvas canvas, double x, double y) {
    // Chair seat
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, 40, 40),
        Radius.circular(3),
      ),
      Paint()..color = Color(0xFF8D6E63),
    );

    // Seat outline
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, 40, 40),
        Radius.circular(3),
      ),
      Paint()
        ..color = Color(0xFF6D4C41)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Chair back
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x + 5, y - 50, 30, 55),
        Radius.circular(3),
      ),
      Paint()..color = Color(0xFF8D6E63),
    );

    // Back outline
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x + 5, y - 50, 30, 55),
        Radius.circular(3),
      ),
      Paint()
        ..color = Color(0xFF6D4C41)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Chair legs (4 legs)
    // Chair legs (4 legs)
    List<List<double>> legPositions = [
      [5, 5],
      [5, 30],
      [30, 5],
      [30, 30]
    ];

    for (var pos in legPositions) {
      canvas.drawRect(
        Rect.fromLTWH(x + pos[0], y + 40, 5, 35),
        Paint()..color = Color(0xFF6D4C41),
      );
    }
  }

// REALISTIC LAMP
  void _drawRealisticLamp(Canvas canvas, double x, double y) {
    // Lamp base
    canvas.drawCircle(
      Offset(x, y + 30),
      8,
      Paint()..color = Color(0xFF757575),
    );

    // Lamp stem
    canvas.drawRect(
      Rect.fromLTWH(x - 2, y + 5, 4, 25),
      Paint()..color = Color(0xFF9E9E9E),
    );

    // Lamp shade (cone)
    final lampPath = Path()
      ..moveTo(x - 15, y + 5)
      ..lineTo(x + 15, y + 5)
      ..lineTo(x + 10, y - 10)
      ..lineTo(x - 10, y - 10)
      ..close();

    canvas.drawPath(
      lampPath,
      Paint()..color = Color(0xFFFFE082),
    );

    canvas.drawPath(
      lampPath,
      Paint()
        ..color = Color(0xFFFFD54F)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Light glow
    canvas.drawCircle(
      Offset(x, y),
      20,
      Paint()
        ..color = Color(0xFFFFE082).withOpacity(0.3)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 15),
    );

    // Light bulb
    canvas.drawCircle(
      Offset(x, y - 5),
      4,
      Paint()..color = Color(0xFFFFFFFF),
    );
  }

// REALISTIC FIREPLACE
  void _drawCampfire(Canvas canvas, double x, double floorY) {
    // Stone circle on ground
    final stonePositions = [
      [-15, 0], [-10, -8], [0, -10], [10, -8], [15, 0],
      [12, 8], [0, 10], [-12, 8]
    ];

    for (var pos in stonePositions) {
      canvas.drawCircle(
        Offset(x + pos[0], floorY - 15 + pos[1]),
        6,
        Paint()..color = Color(0xFF7A7A7A),
      );
      // Stone shadow
      canvas.drawCircle(
        Offset(x + pos[0], floorY - 15 + pos[1]),
        6,
        Paint()
          ..color = Color(0xFF5A5A5A)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }

    // Wooden logs (brown rectangles crossed)
    // Log 1 (horizontal)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(x, floorY - 15), width: 30, height: 6),
        Radius.circular(3),
      ),
      Paint()..color = Color(0xFF6D4C41),
    );

    // Log 2 (diagonal left)
    canvas.save();
    canvas.translate(x - 8, floorY - 18);
    canvas.rotate(-0.5);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: 25, height: 5),
        Radius.circular(2.5),
      ),
      Paint()..color = Color(0xFF5D4037),
    );
    canvas.restore();

    // Log 3 (diagonal right)
    canvas.save();
    canvas.translate(x + 8, floorY - 18);
    canvas.rotate(0.5);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: 25, height: 5),
        Radius.circular(2.5),
      ),
      Paint()..color = Color(0xFF5D4037),
    );
    canvas.restore();

    // Fire glow (large, ground-level)
    canvas.drawCircle(
      Offset(x, floorY - 25),
      30,
      Paint()
        ..color = Color(0xFFFF6B35).withOpacity(0.4)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 25),
    );

    // Inner glow
    canvas.drawCircle(
      Offset(x, floorY - 25),
      18,
      Paint()
        ..color = Color(0xFFFFD54F).withOpacity(0.6)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 12),
    );

    // Fire flames (multiple sizes)
    _drawEmoji(canvas, '🔥', x, floorY - 30, 28);
    _drawEmoji(canvas, '🔥', x - 10, floorY - 25, 22);
    _drawEmoji(canvas, '🔥', x + 10, floorY - 25, 22);
  }
  void _drawSimpleStove(Canvas canvas, double x, double floorY) {
    // Wall recess (shadow behind stove)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x - 5, floorY - 90, 70, 90),
        Radius.circular(5),
      ),
      Paint()..color = Color(0xFF2a2420),
    );

    // Main stove body (brick red)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x, floorY - 85, 60, 85),
        Radius.circular(4),
      ),
      Paint()..color = Color(0xFFB85450),
    );

    // Stove outline
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x, floorY - 85, 60, 85),
        Radius.circular(4),
      ),
      Paint()
        ..color = Color(0xFF8B3A3A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    // Brick pattern (horizontal lines)
    for (int i = 1; i < 5; i++) {
      canvas.drawLine(
        Offset(x, floorY - 85 + (i * 17)),
        Offset(x + 60, floorY - 85 + (i * 17)),
        Paint()
          ..color = Color(0xFF8B3A3A)
          ..strokeWidth = 2,
      );
    }

    // Oven door (black metal)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x + 8, floorY - 60, 44, 35),
        Radius.circular(3),
      ),
      Paint()..color = Color(0xFF2C2C2C),
    );

    // Door window (orange glow inside)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x + 14, floorY - 52, 32, 20),
        Radius.circular(2),
      ),
      Paint()..color = Color(0xFFFF8C42),
    );

    // Fire glow through window
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x + 14, floorY - 52, 32, 20),
        Radius.circular(2),
      ),
      Paint()
        ..color = Color(0xFFFFD54F).withOpacity(0.7)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8),
    );

    // Door handle (silver)
    canvas.drawCircle(
      Offset(x + 45, floorY - 42),
      3,
      Paint()..color = Color(0xFFAAAAAA),
    );

    // Top cooking surface (black metal)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x, floorY - 90, 60, 8),
        Radius.circular(2),
      ),
      Paint()..color = Color(0xFF1C1C1C),
    );

    // Stovetop burner (circular)
    canvas.drawCircle(
      Offset(x + 30, floorY - 86),
      8,
      Paint()..color = Color(0xFF0C0C0C),
    );

    // Burner rings
    canvas.drawCircle(
      Offset(x + 30, floorY - 86),
      6,
      Paint()
        ..color = Color(0xFF666666)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // Small flame on top
    _drawEmoji(canvas, '🔥', x + 30, floorY - 86, 12);

    // Chimney smoke
    _drawEmoji(canvas, '💨', x + 50, floorY - 100, 14);
  }
void _drawWoodStove(Canvas canvas, double x, double floorY) {
  // Wall alcove (deep shadow)
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTWH(x - 10, floorY - 120, 90, 120),
      Radius.circular(8),
    ),
    Paint()..color = Color(0xFF1a1a1a),
  );

  // Main stove body (cast iron black)
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTWH(x, floorY - 110, 80, 110),
      Radius.circular(6),
    ),
    Paint()..color = Color(0xFF2C2C2C),
  );

  // Metallic sheen (top highlight)
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTWH(x + 5, floorY - 108, 70, 15),
      Radius.circular(4),
    ),
    Paint()..color = Color(0xFF444444).withOpacity(0.6),
  );

  // Stove legs (bottom supports)
  canvas.drawRect(
    Rect.fromLTWH(x + 10, floorY - 5, 8, 5),
    Paint()..color = Color(0xFF1C1C1C),
  );
  canvas.drawRect(
    Rect.fromLTWH(x + 62, floorY - 5, 8, 5),
    Paint()..color = Color(0xFF1C1C1C),
  );

  // Large oven door (ornate)
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTWH(x + 10, floorY - 85, 60, 50),
      Radius.circular(4),
    ),
    Paint()..color = Color(0xFF1C1C1C),
  );

  // Door decorative border (brass)
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTWH(x + 10, floorY - 85, 60, 50),
      Radius.circular(4),
    ),
    Paint()
      ..color = Color(0xFFD4AF37)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3,
  );

  // Large window (bright fire inside)
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTWH(x + 18, floorY - 75, 44, 32),
      Radius.circular(3),
    ),
    Paint()..color = Color(0xFFFF6B35),
  );

  // Bright inner fire glow
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTWH(x + 18, floorY - 75, 44, 32),
      Radius.circular(3),
    ),
    Paint()
      ..color = Color(0xFFFFD54F).withOpacity(0.9)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 12),
  );

  // NO FIRE EMOJIS IN WINDOW - just the glow!

  // Fancy brass handle
  canvas.drawCircle(
    Offset(x + 60, floorY - 59),
    5,
    Paint()..color = Color(0xFFD4AF37),
  );
  canvas.drawCircle(
    Offset(x + 60, floorY - 59),
    3,
    Paint()..color = Color(0xFFFFE55C),
  );

  // Top cooking surface (premium black)
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTWH(x, floorY - 115, 80, 10),
      Radius.circular(3),
    ),
    Paint()..color = Color(0xFF0C0C0C),
  );

  // Two burners on top
  canvas.drawCircle(
    Offset(x + 25, floorY - 110),
    10,
    Paint()..color = Color(0xFF1C1C1C),
  );
  canvas.drawCircle(
    Offset(x + 55, floorY - 110),
    10,
    Paint()..color = Color(0xFF1C1C1C),
  );

  // Burner coils (detailed)
  for (int i = 0; i < 3; i++) {
    canvas.drawCircle(
      Offset(x + 25, floorY - 110),
      8 - (i * 2.5),
      Paint()
        ..color = Color(0xFF666666)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    canvas.drawCircle(
      Offset(x + 55, floorY - 110),
      8 - (i * 2.5),
      Paint()
        ..color = Color(0xFF666666)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  // NO FIRE EMOJIS ON BURNERS - just the coils!

  // Stovepipe (chimney)
  canvas.drawRect(
    Rect.fromLTWH(x + 65, floorY - 140, 10, 30),
    Paint()..color = Color(0xFF3A3A3A),
  );

  // Pipe segments (bands)
  canvas.drawLine(
    Offset(x + 65, floorY - 125),
    Offset(x + 75, floorY - 125),
    Paint()
      ..color = Color(0xFF1C1C1C)
      ..strokeWidth = 2,
  );

  // NO SMOKE EMOJIS - just the pipe!
}


// REALISTIC RUG
  void _drawRealisticRug(Canvas canvas, double x, double y) {
    // Rug base
    final rugRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(x, y, 130, 90),
      Radius.circular(5),
    );

    canvas.drawRRect(
      rugRect,
      Paint()..color = Color(0xFFD32F2F),
    );

    // Inner pattern
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x + 15, y + 15, 100, 60),
        Radius.circular(3),
      ),
      Paint()..color = Color(0xFFFFEB3B).withOpacity(0.4),
    );

    // Diamond pattern
    canvas.drawLine(
      Offset(x + 65, y + 15),
      Offset(x + 115, y + 45),
      Paint()
        ..color = Color(0xFFFF9800)
        ..strokeWidth = 3,
    );
    canvas.drawLine(
      Offset(x + 115, y + 45),
      Offset(x + 65, y + 75),
      Paint()
        ..color = Color(0xFFFF9800)
        ..strokeWidth = 3,
    );
    canvas.drawLine(
      Offset(x + 65, y + 75),
      Offset(x + 15, y + 45),
      Paint()
        ..color = Color(0xFFFF9800)
        ..strokeWidth = 3,
    );
    canvas.drawLine(
      Offset(x + 15, y + 45),
      Offset(x + 65, y + 15),
      Paint()
        ..color = Color(0xFFFF9800)
        ..strokeWidth = 3,
    );

    // Rug border
    canvas.drawRRect(
      rugRect,
      Paint()
        ..color = Color(0xFF8D6E63)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );

    // Fringe tassels
    for (int i = 0; i < 13; i++) {
      double tassX = x + (i * 10);
      canvas.drawLine(
        Offset(tassX, y),
        Offset(tassX, y - 8),
        Paint()
          ..color = Color(0xFF8D6E63)
          ..strokeWidth = 2,
      );
      canvas.drawLine(
        Offset(tassX, y + 90),
        Offset(tassX, y + 98),
        Paint()
          ..color = Color(0xFF8D6E63)
          ..strokeWidth = 2,
      );
    }
  }
  void _drawHayBed(Canvas canvas, double x, double y) {
    // Simple wooden pallet base (VERY CLEAR)
    // Bottom planks
    for (int i = 0; i < 5; i++) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x + (i * 18), y + 95, 16, 8),
          Radius.circular(1),
        ),
        Paint()..color = Color(0xFF8D6E63),
      );
      // Wood grain
      canvas.drawLine(
        Offset(x + 2 + (i * 18), y + 97),
        Offset(x + 14 + (i * 18), y + 97),
        Paint()
          ..color = Color(0xFF6D4C41)
          ..strokeWidth = 1,
      );
    }

    // Support beams under planks
    canvas.drawRect(
      Rect.fromLTWH(x + 5, y + 103, 80, 4),
      Paint()..color = Color(0xFF5D4037),
    );

    // BIG GOLDEN HAY PILE (very obvious!)
    // Bottom layer - wide base
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y + 65, 90, 32),
        Radius.circular(6),
      ),
      Paint()..color = Color(0xFFEBB759), // Bright golden
    );

    // Middle layer - medium
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x + 8, y + 48, 74, 28),
        Radius.circular(8),
      ),
      Paint()..color = Color(0xFFE0AC4D),
    );

    // Top layer - small mound
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x + 22, y + 35, 46, 22),
        Radius.circular(10),
      ),
      Paint()..color = Color(0xFFD4A041),
    );

    // LOTS of hay strands (make it VERY obvious it's straw)
    final strandPaint = Paint()
      ..color = Color(0xFFC89235)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    // Left side strands
    canvas.drawLine(Offset(x + 5, y + 70), Offset(x - 2, y + 62), strandPaint);
    canvas.drawLine(Offset(x + 8, y + 75), Offset(x + 1, y + 68), strandPaint);
    canvas.drawLine(Offset(x + 3, y + 80), Offset(x - 4, y + 74), strandPaint);
    canvas.drawLine(Offset(x + 12, y + 58), Offset(x + 8, y + 50), strandPaint);
    canvas.drawLine(Offset(x + 15, y + 52), Offset(x + 10, y + 44), strandPaint);

    // Right side strands
    canvas.drawLine(Offset(x + 85, y + 72), Offset(x + 92, y + 64), strandPaint);
    canvas.drawLine(Offset(x + 82, y + 77), Offset(x + 89, y + 70), strandPaint);
    canvas.drawLine(Offset(x + 87, y + 82), Offset(x + 94, y + 76), strandPaint);
    canvas.drawLine(Offset(x + 78, y + 60), Offset(x + 84, y + 52), strandPaint);
    canvas.drawLine(Offset(x + 75, y + 54), Offset(x + 80, y + 46), strandPaint);

    // Top strands
    canvas.drawLine(Offset(x + 35, y + 38), Offset(x + 32, y + 30), strandPaint);
    canvas.drawLine(Offset(x + 45, y + 36), Offset(x + 47, y + 28), strandPaint);
    canvas.drawLine(Offset(x + 55, y + 40), Offset(x + 58, y + 32), strandPaint);
    canvas.drawLine(Offset(x + 40, y + 42), Offset(x + 38, y + 34), strandPaint);
    canvas.drawLine(Offset(x + 50, y + 44), Offset(x + 53, y + 36), strandPaint);

    // Hay texture lines (vertical straw pattern)
    final texturePaint = Paint()
      ..color = Color(0xFFB8852E)
      ..strokeWidth = 1.5;

    for (int i = 0; i < 20; i++) {
      double lineX = x + 10 + (i * 3.5);
      double lineStartY = y + 50 + ((i % 3) * 8);
      double lineEndY = lineStartY + 15 + ((i % 4) * 5);

      canvas.drawLine(
        Offset(lineX, lineStartY),
        Offset(lineX - 1, lineEndY),
        texturePaint,
      );
    }

    // Dark shadows for depth
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y + 65, 90, 32),
        Radius.circular(6),
      ),
      Paint()
        ..color = Color(0xFF9C7328)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Old sack cloth (roughly thrown over)
    final sackPath = Path()
      ..moveTo(x + 15, y + 55)
      ..lineTo(x + 70, y + 52)
      ..lineTo(x + 72, y + 85)
      ..lineTo(x + 18, y + 88)
      ..close();

    canvas.drawPath(
      sackPath,
      Paint()..color = Color(0xFF9E8B7E).withOpacity(0.75),
    );

    // Sack weave texture
    for (int i = 0; i < 6; i++) {
      canvas.drawLine(
        Offset(x + 20 + (i * 8), y + 56),
        Offset(x + 22 + (i * 8), y + 84),
        Paint()
          ..color = Color(0xFF7D6B5F)
          ..strokeWidth = 1,
      );
    }

    // Sack tears/holes (worn)
    canvas.drawCircle(Offset(x + 35, y + 68), 3, Paint()..color = Color(0xFF6B5A4E));
    canvas.drawCircle(Offset(x + 55, y + 75), 2.5, Paint()..color = Color(0xFF6B5A4E));

    // Sack edge fraying
    canvas.drawLine(
      Offset(x + 15, y + 55),
      Offset(x + 12, y + 52),
      Paint()
        ..color = Color(0xFF7D6B5F)
        ..strokeWidth = 2,
    );
    canvas.drawLine(
      Offset(x + 20, y + 56),
      Offset(x + 18, y + 52),
      Paint()
        ..color = Color(0xFF7D6B5F)
        ..strokeWidth = 2,
    );
  }
  void _drawSimpleCot(Canvas canvas, double x, double y) {
    // Back legs (darker, further away)
    canvas.drawRect(
      Rect.fromLTWH(x + 8, y + 8, 7, 22),
      Paint()..color = Color(0xFF5D4037),
    );
    canvas.drawRect(
      Rect.fromLTWH(x + 85, y + 8, 7, 22),
      Paint()..color = Color(0xFF5D4037),
    );

    // Side rails connecting back legs
    canvas.drawRect(
      Rect.fromLTWH(x + 8, y + 8, 7, 82),
      Paint()..color = Color(0xFF6D4C41),
    );
    canvas.drawRect(
      Rect.fromLTWH(x + 85, y + 8, 7, 82),
      Paint()..color = Color(0xFF6D4C41),
    );

    // Front legs (lighter, closer)
    canvas.drawRect(
      Rect.fromLTWH(x + 8, y + 82, 7, 38),
      Paint()..color = Color(0xFF8D6E63),
    );
    canvas.drawRect(
      Rect.fromLTWH(x + 85, y + 82, 7, 38),
      Paint()..color = Color(0xFF8D6E63),
    );

    // Canvas fabric stretched tight (beige/tan)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x + 12, y + 12, 78, 75),
        Radius.circular(2),
      ),
      Paint()..color = Color(0xFFD7CCC8),
    );

    // Canvas stretched effect (slightly sagging in middle)
    final sagPath = Path()
      ..moveTo(x + 12, y + 50)
      ..quadraticBezierTo(x + 50, y + 52, x + 90, y + 50);

    canvas.drawPath(
      sagPath,
      Paint()
        ..color = Color(0xFFBCAAA4)
        ..strokeWidth = 1.5,
    );

    // Woven texture (crosshatch)
    for (int i = 0; i < 8; i++) {
      canvas.drawLine(
        Offset(x + 12, y + 12 + (i * 9)),
        Offset(x + 90, y + 12 + (i * 9)),
        Paint()
          ..color = Color(0xFFBCAAA4).withOpacity(0.5)
          ..strokeWidth = 1,
      );
    }

    for (int i = 0; i < 8; i++) {
      canvas.drawLine(
        Offset(x + 12 + (i * 10), y + 12),
        Offset(x + 12 + (i * 10), y + 87),
        Paint()
          ..color = Color(0xFFBCAAA4).withOpacity(0.5)
          ..strokeWidth = 1,
      );
    }

    // Stitching around edges
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x + 12, y + 12, 78, 75),
        Radius.circular(2),
      ),
      Paint()
        ..color = Color(0xFF8D6E63)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Flat pillow (simple, worn)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x + 22, y + 18, 45, 18),
        Radius.circular(3),
      ),
      Paint()..color = Color(0xFFECEFF1),
    );

    // Pillow seam
    canvas.drawLine(
      Offset(x + 44, y + 20),
      Offset(x + 44, y + 34),
      Paint()
        ..color = Color(0xFFCFD8DC)
        ..strokeWidth = 1.5,
    );

    // Pillow outline
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x + 22, y + 18, 45, 18),
        Radius.circular(3),
      ),
      Paint()
        ..color = Color(0xFFB0BEC5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Simple wool blanket (folded at bottom)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x + 18, y + 55, 64, 28),
        Radius.circular(2),
      ),
      Paint()..color = Color(0xFF78909C),
    );

    // Blanket folds (3D effect)
    for (int i = 1; i < 4; i++) {
      canvas.drawLine(
        Offset(x + 18, y + 55 + (i * 7)),
        Offset(x + 82, y + 55 + (i * 7)),
        Paint()
          ..color = Color(0xFF607D8B)
          ..strokeWidth = 2,
      );
    }

    // Blanket edge stitching
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x + 18, y + 55, 64, 28),
        Radius.circular(2),
      ),
      Paint()
        ..color = Color(0xFF546E7A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }
  void _drawWoodFrameBed(Canvas canvas, double x, double y) {
    // BED LEGS (TALL - elevating the whole bed!)
    final legPaint = Paint()..color = Color(0xFF6D4C41);

    // Front left leg
    canvas.drawRect(Rect.fromLTWH(x + 12, y + 95, 8, 40), legPaint);
    // Front right leg
    canvas.drawRect(Rect.fromLTWH(x + 90, y + 95, 8, 40), legPaint);
    // Back left leg
    canvas.drawRect(Rect.fromLTWH(x + 12, y + 55, 8, 40), Paint()..color = Color(0xFF5D4037));
    // Back right leg
    canvas.drawRect(Rect.fromLTWH(x + 90, y + 55, 8, 40), Paint()..color = Color(0xFF5D4037));

    // TALL ORNATE HEADBOARD
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, 110, 60),
        Radius.circular(6),
      ),
      Paint()..color = Color(0xFF8D6E63),
    );

    // Headboard crown molding
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x - 2, y - 5, 114, 12),
        Radius.circular(3),
      ),
      Paint()..color = Color(0xFF6D4C41),
    );

    canvas.drawLine(
      Offset(x - 2, y + 3),
      Offset(x + 112, y + 3),
      Paint()
        ..color = Color(0xFF4E342E)
        ..strokeWidth = 2,
    );

    // Inner decorative panel
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x + 10, y + 12, 90, 40),
        Radius.circular(4),
      ),
      Paint()..color = Color(0xFF6D4C41),
    );

    // Carved vertical panels
    for (int i = 0; i < 4; i++) {
      double panelX = x + 18 + (i * 21);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(panelX, y + 16, 15, 32),
          Radius.circular(2),
        ),
        Paint()..color = Color(0xFF5D4037),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(panelX, y + 16, 15, 32),
          Radius.circular(2),
        ),
        Paint()
          ..color = Color(0xFF4E342E)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
    // ========== BACK FRAME STRUCTURE (connecting headboard to bed) ==========

// Back frame horizontal support (top)
    canvas.drawRect(
      Rect.fromLTWH(x + 8, y + 58, 94, 6),
      Paint()..color = Color(0xFF6D4C41),
    );

// Back frame decorative trim
    canvas.drawLine(
      Offset(x + 8, y + 61),
      Offset(x + 102, y + 61),
      Paint()
        ..color = Color(0xFF4E342E)
        ..strokeWidth = 2,
    );

// Vertical support posts (connecting headboard to frame)
// Left post
    canvas.drawRect(
      Rect.fromLTWH(x + 8, y + 40, 6, 24),
      Paint()..color = Color(0xFF7D5E52),
    );
// Right post
    canvas.drawRect(
      Rect.fromLTWH(x + 96, y + 40, 6, 24),
      Paint()..color = Color(0xFF7D5E52),
    );

// Decorative post caps (top of vertical posts)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x + 6, y + 36, 10, 8),
        Radius.circular(2),
      ),
      Paint()..color = Color(0xFF5D4037),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x + 94, y + 36, 10, 8),
        Radius.circular(2),
      ),
      Paint()..color = Color(0xFF5D4037),
    );

    // ELEVATED BED FRAME (sits on tall legs)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x + 5, y + 40, 100, 60), // ← LONGER! starts at y+40 instead of y+55, height 60 instead of 45
        Radius.circular(4),
      ),
      Paint()..color = Color(0xFF8D6E63),
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x + 5, y + 40, 100, 60),
        Radius.circular(4),
      ),
      Paint()
        ..color = Color(0xFF5D4037)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    // Side rails (connecting legs visibly)
    canvas.drawRect(
      Rect.fromLTWH(x + 10, y + 55, 6, 40),
      Paint()..color = Color(0xFF7D5E52),
    );
    canvas.drawRect(
      Rect.fromLTWH(x + 94, y + 55, 6, 40),
      Paint()..color = Color(0xFF7D5E52),
    );

    // Under-bed support beam (visible between legs)
    canvas.drawRect(
      Rect.fromLTWH(x + 15, y + 110, 80, 6),
      Paint()..color = Color(0xFF5D4037),
    );

    // THICK MATTRESS (on elevated frame)
    // THICK MATTRESS (on elevated frame - ADJUSTED!)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x + 10, y + 43, 90, 55), // ← MOVED UP and LENGTHENED
        Radius.circular(5),
      ),
      Paint()..color = Color(0xFFFAFAFA),
    );

// Mattress quilted tufting
    for (int row = 0; row < 3; row++) {
      for (int col = 0; col < 5; col++) {
        double tuftX = x + 20 + (col * 16);
        double tuftY = y + 55 + (row * 15); // ← ADJUSTED

        canvas.drawCircle(Offset(tuftX, tuftY), 2.5, Paint()..color = Color(0xFFD0D0D0));
        canvas.drawCircle(
            Offset(tuftX, tuftY),
            2.5,
            Paint()
              ..color = Color(0xFFE0E0E0)
              ..style = PaintingStyle.stroke
        );
      }
    }

// Mattress piping
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x + 10, y + 43, 90, 55), // ← MATCHES NEW MATTRESS
        Radius.circular(5),
      ),
      Paint()
        ..color = Color(0xFFBDBDBD)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // LUXURY PILLOWS (ADJUSTED TO NEW MATTRESS!)
// Left pillow
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x + 18, y + 48, 38, 20), // ← MOVED UP
        Radius.circular(6),
      ),
      Paint()..color = Color(0xFFFFFFFF),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x + 20, y + 50, 34, 8), // ← MOVED UP
        Radius.circular(4),
      ),
      Paint()..color = Color(0xFFFEFEFE).withOpacity(0.7),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x + 18, y + 48, 38, 20),
        Radius.circular(6),
      ),
      Paint()
        ..color = Color(0xFFE0E0E0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

// Right pillow
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x + 54, y + 50, 38, 18), // ← MOVED UP
        Radius.circular(6),
      ),
      Paint()..color = Color(0xFFFDFDFD),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x + 56, y + 52, 34, 7), // ← MOVED UP
        Radius.circular(4),
      ),
      Paint()..color = Color(0xFFFEFEFE).withOpacity(0.7),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x + 54, y + 50, 38, 18),
        Radius.circular(6),
      ),
      Paint()
        ..color = Color(0xFFE0E0E0)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // LUXURY DUVET (ADJUSTED!)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x + 15, y + 70, 80, 26), // ← MOVED UP and ADJUSTED SIZE
        Radius.circular(4),
      ),
      Paint()..color = Color(0xFF5C6BC0),
    );

// Quilted pattern
    for (int i = 0; i < 5; i++) {
      canvas.drawLine(
        Offset(x + 20 + (i * 15), y + 70), // ← ADJUSTED
        Offset(x + 20 + (i * 15), y + 96), // ← ADJUSTED
        Paint()
          ..color = Color(0xFF3F51B5)
          ..strokeWidth = 2,
      );
    }
    for (int i = 0; i < 4; i++) {
      canvas.drawLine(
        Offset(x + 15, y + 74 + (i * 6)), // ← ADJUSTED
        Offset(x + 95, y + 74 + (i * 6)), // ← ADJUSTED
        Paint()
          ..color = Color(0xFF3F51B5)
          ..strokeWidth = 2,
      );
    }

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x + 15, y + 70, 80, 26),
        Radius.circular(4),
      ),
      Paint()
        ..color = Color(0xFF3949AB)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x + 15, y + 82, 80, 18),
        Radius.circular(4),
      ),
      Paint()
        ..color = Color(0xFF3949AB)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // FOOTBOARD (at elevated height)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x + 8, y + 97, 94, 12),
        Radius.circular(3),
      ),
      Paint()..color = Color(0xFF8D6E63),
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x + 8, y + 97, 94, 12),
        Radius.circular(3),
      ),
      Paint()
        ..color = Color(0xFF5D4037)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }
  void _drawSimpleDesk(Canvas canvas, double x, double y) {
    // Simple wooden legs (4 legs)
    final legPaint = Paint()..color = Color(0xFF6D4C41);

    // Front left leg
    canvas.drawRect(Rect.fromLTWH(x + 10, y + 12, 6, 40), legPaint);
    // Front right leg
    canvas.drawRect(Rect.fromLTWH(x + 84, y + 12, 6, 40), legPaint);
    // Back left leg (darker for depth)
    canvas.drawRect(Rect.fromLTWH(x + 10, y, 6, 18), Paint()..color = Color(0xFF5D4037));
    // Back right leg
    canvas.drawRect(Rect.fromLTWH(x + 84, y, 6, 18), Paint()..color = Color(0xFF5D4037));

    // Simple plank desktop (rough wood)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y + 8, 100, 10),
        Radius.circular(2),
      ),
      Paint()..color = Color(0xFF8D6E63),
    );

    // Wood grain lines (rough texture)
    for (int i = 0; i < 8; i++) {
      canvas.drawLine(
        Offset(x + 5 + (i * 12), y + 9),
        Offset(x + 8 + (i * 12), y + 17),
        Paint()
          ..color = Color(0xFF6D4C41)
          ..strokeWidth = 1.5,
      );
    }

    // Desktop edge (darker)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y + 8, 100, 10),
        Radius.circular(2),
      ),
      Paint()
        ..color = Color(0xFF5D4037)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Visible nails/screws (rustic look)
    for (int i = 0; i < 4; i++) {
      double nailX = x + 15 + (i * 22);
      canvas.drawCircle(
        Offset(nailX, y + 12),
        2,
        Paint()..color = Color(0xFF424242),
      );
    }

    // Simple support beam under desktop
    canvas.drawRect(
      Rect.fromLTWH(x + 15, y + 18, 70, 4),
      Paint()..color = Color(0xFF5D4037),
    );
  }
  void _drawOakDesk(Canvas canvas, double x, double y) {
    // Sturdy wooden legs
    final legPaint = Paint()..color = Color(0xFF7D5E52);

    // Front legs (thicker)
    canvas.drawRect(Rect.fromLTWH(x + 8, y + 18, 8, 50), legPaint); // ← TALLER
    canvas.drawRect(Rect.fromLTWH(x + 84, y + 18, 8, 50), legPaint);
    // Back legs
    canvas.drawRect(Rect.fromLTWH(x + 8, y, 8, 22), Paint()..color = Color(0xFF6D4C41));
    canvas.drawRect(Rect.fromLTWH(x + 84, y, 8, 22), Paint()..color = Color(0xFF6D4C41));

    // Desktop (smooth oak finish)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y + 12, 100, 12),
        Radius.circular(3),
      ),
      Paint()..color = Color(0xFF9E8B7E),
    );

    // Desktop shine/polish effect
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x + 2, y + 13, 96, 4),
        Radius.circular(2),
      ),
      Paint()..color = Color(0xFFB8A89A).withOpacity(0.5),
    );

    // Desktop edge trim
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y + 12, 100, 12),
        Radius.circular(3),
      ),
      Paint()
        ..color = Color(0xFF6D4C41)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Drawer (center)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x + 25, y + 26, 50, 18),
        Radius.circular(2),
      ),
      Paint()..color = Color(0xFF8D7367),
    );

    // Drawer panel inset
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x + 28, y + 29, 44, 12),
        Radius.circular(1),
      ),
      Paint()..color = Color(0xFF7D6357),
    );

    // Drawer handle (brass)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x + 46, y + 33, 8, 4),
        Radius.circular(2),
      ),
      Paint()..color = Color(0xFFD4AF37),
    );

    // Handle highlight
    canvas.drawLine(
      Offset(x + 47, y + 34),
      Offset(x + 53, y + 34),
      Paint()
        ..color = Color(0xFFFFE55C)
        ..strokeWidth = 1,
    );

    // Drawer outline
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x + 25, y + 26, 50, 18),
        Radius.circular(2),
      ),
      Paint()
        ..color = Color(0xFF5D4037)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Side support panels
    canvas.drawRect(
      Rect.fromLTWH(x + 6, y + 24, 10, 44),
      Paint()..color = Color(0xFF8D7367),
    );
    canvas.drawRect(
      Rect.fromLTWH(x + 84, y + 24, 10, 44),
      Paint()..color = Color(0xFF8D7367),
    );

    // BASIC LAMP ON DESK (right side)
    _drawBasicLamp(canvas, x + 80, y + 2);
  }
  void _drawExecutiveDesk(Canvas canvas, double x, double y) {
    // Elegant carved legs
    final legPaint = Paint()..color = Color(0xFF5D4037);

    // Front legs (ornate, thicker)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x + 5, y + 22, 10, 55), // ← TALLER
        Radius.circular(2),
      ),
      legPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x + 85, y + 22, 10, 55),
        Radius.circular(2),
      ),
      legPaint,
    );

    // Back legs
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x + 5, y, 10, 26),
        Radius.circular(2),
      ),
      Paint()..color = Color(0xFF4E342E),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x + 85, y, 10, 26),
        Radius.circular(2),
      ),
      Paint()..color = Color(0xFF4E342E),
    );

    // Decorative leg carvings
    for (int i = 0; i < 3; i++) {
      canvas.drawCircle(
        Offset(x + 10, y + 30 + (i * 10)),
        2,
        Paint()..color = Color(0xFF3E2723),
      );
      canvas.drawCircle(
        Offset(x + 90, y + 30 + (i * 10)),
        2,
        Paint()..color = Color(0xFF3E2723),
      );
    }

    // Thick mahogany desktop (premium wood)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x - 5, y + 14, 110, 14),
        Radius.circular(4),
      ),
      Paint()..color = Color(0xFF6D4C41),
    );

    // Desktop leather inlay (green leather writing surface)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x + 5, y + 18, 90, 6),
        Radius.circular(2),
      ),
      Paint()..color = Color(0xFF2E5A3E),
    );

    // Leather texture (diamond pattern)
    for (int i = 0; i < 8; i++) {
      canvas.drawLine(
        Offset(x + 10 + (i * 11), y + 18),
        Offset(x + 10 + (i * 11), y + 24),
        Paint()
          ..color = Color(0xFF234A32)
          ..strokeWidth = 0.5,
      );
    }

    // Desktop gold trim
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x - 5, y + 14, 110, 14),
        Radius.circular(4),
      ),
      Paint()
        ..color = Color(0xFFD4AF37)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Desktop edge molding (3D effect)
    canvas.drawLine(
      Offset(x - 5, y + 16),
      Offset(x + 105, y + 16),
      Paint()
        ..color = Color(0xFF8D6E63)
        ..strokeWidth = 1.5,
    );

    // TWO drawers (stacked, left side)
    // Top drawer
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x + 8, y + 30, 35, 14),
        Radius.circular(2),
      ),
      Paint()..color = Color(0xFF5D4037),
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x + 11, y + 32, 29, 10),
        Radius.circular(1),
      ),
      Paint()..color = Color(0xFF4E342E),
    );

    // Top drawer brass handle
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x + 36, y + 37), width: 6, height: 4),
      Paint()..color = Color(0xFFD4AF37),
    );

    // Bottom drawer
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x + 8, y + 46, 35, 14),
        Radius.circular(2),
      ),
      Paint()..color = Color(0xFF5D4037),
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x + 11, y + 48, 29, 10),
        Radius.circular(1),
      ),
      Paint()..color = Color(0xFF4E342E),
    );

    // Bottom drawer brass handle
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x + 36, y + 53), width: 6, height: 4),
      Paint()..color = Color(0xFFD4AF37),
    );

    // Center panel (decorative wood panel)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x + 18, y + 28, 20, 32),
        Radius.circular(2),
      ),
      Paint()..color = Color(0xFF6D4C41),
    );

    // Panel carving detail
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x + 20, y + 32, 16, 24),
        Radius.circular(1),
      ),
      Paint()
        ..color = Color(0xFF5D4037)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // FANCY LAMP ON DESK (center-right)
    _drawFancyLamp(canvas, x + 60, y + 2);

    // BOOKSHELF ON DESK (right side)
    _drawMiniBookshelf(canvas, x + 80, y - 15);
  }
  void _drawOldStool(Canvas canvas, double x, double y) {
    // Simple wooden stool (no back, just a seat)

    // 3 legs (tripod style - cheaper construction)
    final legPaint = Paint()..color = Color(0xFF6D4C41);

    // Center leg (front)
    canvas.drawRect(
      Rect.fromLTWH(x + 17, y + 28, 6, 35),
      legPaint,
    );

    // Left leg (angled)
    canvas.save();
    canvas.translate(x + 8, y + 30);
    canvas.rotate(-0.2);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, 5, 32),
      Paint()..color = Color(0xFF5D4037),
    );
    canvas.restore();

    // Right leg (angled)
    canvas.save();
    canvas.translate(x + 30, y + 30);
    canvas.rotate(0.2);
    canvas.drawRect(
      Rect.fromLTWH(0, 0, 5, 32),
      Paint()..color = Color(0xFF5D4037),
    );
    canvas.restore();

    // Round wooden seat (worn and simple)
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x + 20, y + 30), width: 32, height: 28),
      Paint()..color = Color(0xFF8D6E63),
    );

    // Wood grain on seat
    for (int i = 0; i < 3; i++) {
      canvas.drawLine(
        Offset(x + 8 + (i * 6), y + 28),
        Offset(x + 10 + (i * 6), y + 32),
        Paint()
          ..color = Color(0xFF6D4C41)
          ..strokeWidth = 1.5,
      );
    }

    // Seat outline (rough edges)
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x + 20, y + 30), width: 32, height: 28),
      Paint()
        ..color = Color(0xFF5D4037)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Visible nail in center
    canvas.drawCircle(
      Offset(x + 20, y + 30),
      2,
      Paint()..color = Color(0xFF424242),
    );
  }
  void _drawWoodenChair(Canvas canvas, double x, double y) {
    // 4-legged wooden chair with backrest

    final legPaint = Paint()..color = Color(0xFF7D5E52);

    // Back legs (slightly darker)
    canvas.drawRect(
      Rect.fromLTWH(x + 6, y - 8, 6, 45),
      Paint()..color = Color(0xFF6D4C41),
    );
    canvas.drawRect(
      Rect.fromLTWH(x + 28, y - 8, 6, 45),
      Paint()..color = Color(0xFF6D4C41),
    );

    // Front legs
    canvas.drawRect(
      Rect.fromLTWH(x + 6, y + 28, 6, 35),
      legPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(x + 28, y + 28, 6, 35),
      legPaint,
    );

    // Seat (flat wooden plank)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x + 4, y + 24, 32, 30),
        Radius.circular(3),
      ),
      Paint()..color = Color(0xFF9E8B7E),
    );

    // Seat wood grain
    for (int i = 0; i < 4; i++) {
      canvas.drawLine(
        Offset(x + 8 + (i * 7), y + 26),
        Offset(x + 8 + (i * 7), y + 52),
        Paint()
          ..color = Color(0xFF8D7367)
          ..strokeWidth = 1,
      );
    }

    // Seat outline
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x + 4, y + 24, 32, 30),
        Radius.circular(3),
      ),
      Paint()
        ..color = Color(0xFF6D4C41)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Backrest (vertical slats)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x + 6, y - 10, 28, 38),
        Radius.circular(3),
      ),
      Paint()..color = Color(0xFF9E8B7E),
    );

    // Backrest slats (3 vertical bars)
    for (int i = 0; i < 3; i++) {
      canvas.drawRect(
        Rect.fromLTWH(x + 10 + (i * 8), y - 6, 4, 30),
        Paint()..color = Color(0xFF8D7367),
      );
    }

    // Backrest outline
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x + 6, y - 10, 28, 38),
        Radius.circular(3),
      ),
      Paint()
        ..color = Color(0xFF6D4C41)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Top rail (curved)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x + 4, y - 12, 32, 6),
        Radius.circular(3),
      ),
      Paint()..color = Color(0xFF8D6E63),
    );
  }
  void _drawComfyChair(Canvas canvas, double x, double y) {
    // Premium office chair with cushioning

    // 5-wheel base (star shape)
    canvas.drawCircle(
      Offset(x + 20, y + 60),
      15,
      Paint()..color = Color(0xFF424242),
    );

    // 5 wheel spokes
    for (int i = 0; i < 5; i++) {
      double angle = (i * 72) * (3.14159 / 180);
      double endX = x + 20 + (12 * cos(angle));
      double endY = y + 60 + (12 * sin(angle));

      canvas.drawLine(
        Offset(x + 20, y + 60),
        Offset(endX, endY),
        Paint()
          ..color = Color(0xFF333333)
          ..strokeWidth = 3,
      );

      // Wheel at end
      canvas.drawCircle(
        Offset(endX, endY),
        3,
        Paint()..color = Color(0xFF1C1C1C),
      );
    }

    // Pneumatic cylinder (adjustable height mechanism)
    canvas.drawRect(
      Rect.fromLTWH(x + 16, y + 42, 8, 20),
      Paint()..color = Color(0xFF666666),
    );

    // Cylinder segments (shows it's adjustable)
    for (int i = 0; i < 3; i++) {
      canvas.drawLine(
        Offset(x + 16, y + 47 + (i * 5)),
        Offset(x + 24, y + 47 + (i * 5)),
        Paint()
          ..color = Color(0xFF444444)
          ..strokeWidth = 1.5,
      );
    }

    // Padded seat (thick cushion)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x + 2, y + 22, 36, 28),
        Radius.circular(5),
      ),
      Paint()..color = Color(0xFF2E5A3E), // Dark green fabric
    );

    // Seat cushion tufting (buttons)
    for (int row = 0; row < 2; row++) {
      for (int col = 0; col < 3; col++) {
        canvas.drawCircle(
          Offset(x + 10 + (col * 9), y + 30 + (row * 10)),
          2,
          Paint()..color = Color(0xFF234A32),
        );
      }
    }

    // Seat outline
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x + 2, y + 22, 36, 28),
        Radius.circular(5),
      ),
      Paint()
        ..color = Color(0xFF1C3A2A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // High backrest (ergonomic curve)
    final backPath = Path()
      ..moveTo(x + 6, y + 24)
      ..lineTo(x + 6, y - 18)
      ..quadraticBezierTo(x + 20, y - 22, x + 34, y - 18)
      ..lineTo(x + 34, y + 24)
      ..close();

    canvas.drawPath(
      backPath,
      Paint()..color = Color(0xFF2E5A3E),
    );

    // Backrest padding pattern
    for (int i = 0; i < 3; i++) {
      canvas.drawLine(
        Offset(x + 10, y - 12 + (i * 10)),
        Offset(x + 30, y - 12 + (i * 10)),
        Paint()
          ..color = Color(0xFF234A32)
          ..strokeWidth = 1.5,
      );
    }

    // Lumbar support (extra padding in middle)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x + 12, y + 4, 16, 12),
        Radius.circular(3),
      ),
      Paint()..color = Color(0xFF3A6A4A).withOpacity(0.7),
    );

    // Backrest outline
    canvas.drawPath(
      backPath,
      Paint()
        ..color = Color(0xFF1C3A2A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Armrests (on both sides)
    // Left armrest
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x - 2, y + 28, 8, 18),
        Radius.circular(2),
      ),
      Paint()..color = Color(0xFF424242),
    );

    // Right armrest
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x + 34, y + 28, 8, 18),
        Radius.circular(2),
      ),
      Paint()..color = Color(0xFF424242),
    );
  }
  void _drawBasicLamp(Canvas canvas, double x, double y) {
    // Small circular base
    canvas.drawCircle(
      Offset(x, y + 8),
      6,
      Paint()..color = Color(0xFF757575),
    );

    // Thin stem
    canvas.drawRect(
      Rect.fromLTWH(x - 1.5, y - 8, 3, 16),
      Paint()..color = Color(0xFF9E9E9E),
    );

    // Simple conical shade
    final shadePath = Path()
      ..moveTo(x - 8, y - 8)
      ..lineTo(x + 8, y - 8)
      ..lineTo(x + 6, y - 16)
      ..lineTo(x - 6, y - 16)
      ..close();

    canvas.drawPath(
      shadePath,
      Paint()..color = Color(0xFFFFE082),
    );

    // Shade outline
    canvas.drawPath(
      shadePath,
      Paint()
        ..color = Color(0xFFFFD54F)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Small light glow
    canvas.drawCircle(
      Offset(x, y - 12),
      8,
      Paint()
        ..color = Color(0xFFFFE082).withOpacity(0.3)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8),
    );
  }
  void _drawFancyLamp(Canvas canvas, double x, double y) {
    // Ornate brass base (wider and decorative)
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x, y + 10), width: 14, height: 8),
      Paint()..color = Color(0xFFD4AF37),
    );

    // Base decorative rings
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x, y + 8), width: 10, height: 4),
      Paint()..color = Color(0xFFB8932E),
    );

    // Elegant curved stem
    final stemPath = Path()
      ..moveTo(x - 2, y + 6)
      ..quadraticBezierTo(x - 3, y - 4, x - 1, y - 10)
      ..lineTo(x + 1, y - 10)
      ..quadraticBezierTo(x + 3, y - 4, x + 2, y + 6)
      ..close();

    canvas.drawPath(
      stemPath,
      Paint()..color = Color(0xFFFFE55C),
    );

    // Premium glass shade (frosted)
    final glassPath = Path()
      ..moveTo(x - 12, y - 10)
      ..lineTo(x + 12, y - 10)
      ..lineTo(x + 10, y - 22)
      ..quadraticBezierTo(x, y - 24, x - 10, y - 22)
      ..close();

    canvas.drawPath(
      glassPath,
      Paint()..color = Color(0xFFFFF8DC).withOpacity(0.7),
    );

    // Glass rim (gold)
    canvas.drawLine(
      Offset(x - 12, y - 10),
      Offset(x + 12, y - 10),
      Paint()
        ..color = Color(0xFFD4AF37)
        ..strokeWidth = 2,
    );

    // Bright warm glow
    canvas.drawCircle(
      Offset(x, y - 16),
      15,
      Paint()
        ..color = Color(0xFFFFE082).withOpacity(0.5)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 15),
    );

    // Light bulb visible inside
    canvas.drawCircle(
      Offset(x, y - 14),
      4,
      Paint()..color = Color(0xFFFFFFFF),
    );
  }
  void _drawMiniBookshelf(Canvas canvas, double x, double y) {
    // Wooden bookshelf frame
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, 18, 28),
        Radius.circular(2),
      ),
      Paint()..color = Color(0xFF6D4C41),
    );

    // Shelf divider (middle)
    canvas.drawRect(
      Rect.fromLTWH(x + 1, y + 14, 16, 2),
      Paint()..color = Color(0xFF5D4037),
    );

    // Books on top shelf (colorful spines)
    List<Color> bookColors = [
      Color(0xFF8B0000), // Dark red
      Color(0xFF2E5A3E), // Dark green
      Color(0xFF1C3A5A), // Dark blue
      Color(0xFF5D4037), // Brown
    ];

    for (int i = 0; i < 4; i++) {
      canvas.drawRect(
        Rect.fromLTWH(x + 2 + (i * 3.5), y + 2, 3, 11),
        Paint()..color = bookColors[i],
      );

      // Book spine detail
      canvas.drawLine(
        Offset(x + 2.5 + (i * 3.5), y + 4),
        Offset(x + 2.5 + (i * 3.5), y + 11),
        Paint()
          ..color = Colors.white.withOpacity(0.3)
          ..strokeWidth = 0.5,
      );
    }

    // Books on bottom shelf (different heights)
    canvas.drawRect(
      Rect.fromLTWH(x + 2, y + 17, 3, 10),
      Paint()..color = Color(0xFF4A5A2A),
    );
    canvas.drawRect(
      Rect.fromLTWH(x + 6, y + 19, 3, 8),
      Paint()..color = Color(0xFF6A3A2A),
    );
    canvas.drawRect(
      Rect.fromLTWH(x + 10, y + 18, 3, 9),
      Paint()..color = Color(0xFF2A3A5A),
    );
    canvas.drawRect(
      Rect.fromLTWH(x + 14, y + 20, 3, 7),
      Paint()..color = Color(0xFF5A2A4A),
    );

    // Shelf outline
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, 18, 28),
        Radius.circular(2),
      ),
      Paint()
        ..color = Color(0xFF4E342E)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  void _drawEmoji(Canvas canvas, String emoji, double x, double y, double size) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: emoji,
        style: TextStyle(fontSize: size),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(x - textPainter.width / 2, y - textPainter.height / 2),
    );
  }


  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true; // ← ADD THIS HERE!

}

double cos(double radians) => math.cos(radians);
double sin(double radians) => math.sin(radians);

// ITEM PICKER SHEET
class ItemPickerSheet extends StatelessWidget {
  final Character character;
  final CaveDecorations decorations;
  final PlacementSpot spot;
  final Function(String) onItemSelected;

  ItemPickerSheet({
    required this.character,
    required this.decorations,
    required this.spot,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    List<DecorationItem> allItems = decorations.getItemsByCategory(spot.category);
    List<DecorationItem> ownedItems = decorations.getOwnedItemsByCategory(spot.category);

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Choose ${spot.category.toUpperCase()}",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          Divider(color: Colors.white24),
          SizedBox(height: 10),
          DefaultTabController(
            length: 2,
            child: Expanded(
              child: Column(
                children: [
                  TabBar(
                    indicatorColor: Color(0xFF00d4ff),
                    labelColor: Color(0xFF00d4ff),
                    unselectedLabelColor: Colors.white54,
                    tabs: [
                      Tab(text: "Owned (${ownedItems.length})"),
                      Tab(text: "Shop (${allItems.length})"),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildItemGrid(ownedItems, true, context),
                        _buildItemGrid(allItems, false, context),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Method to open furniture dialog


  Widget _buildItemGrid(List<DecorationItem> items, bool isOwned, BuildContext context) {
    return GridView.builder(
      padding: EdgeInsets.only(top: 20),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
        childAspectRatio: 0.8,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        DecorationItem item = items[index];
        bool canAfford = character.money >= item.cost;
        bool alreadyOwned = item.isOwned;

        return GestureDetector(
          onTap: () {
            if (isOwned) {
              onItemSelected(item.id);
            } else {
              if (alreadyOwned) {
                onItemSelected(item.id);
              } else if (canAfford) {
                bool success = decorations.purchaseItem(item.id, character.money);
                if (success) {
                  character.spendMoney(item.cost);
                  onItemSelected(item.id);
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Not enough money! Need \$${item.cost}"),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: Color(0xFF0f3460),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: alreadyOwned
                    ? Colors.green
                    : (canAfford ? Color(0xFF00d4ff) : Colors.red),
                width: 2,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item.emoji,
                  style: TextStyle(fontSize: 40),
                ),
                SizedBox(height: 5),
                Text(
                  item.name,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 5),
                if (!isOwned)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: alreadyOwned
                          ? Colors.green
                          : (canAfford ? Color(0xFF00d4ff) : Colors.red),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      alreadyOwned ? "Owned" : "\$${item.cost}",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}