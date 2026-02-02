import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'dart:math' as math;
import '../models/character.dart';
import '../models/cave_decorations.dart';
import '../services/storage_service.dart';
import 'shop_screen.dart';
import '../services/furniture_service.dart';
import '../widgets/furniture_selection_dialog.dart';

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
  final FurnitureService furnitureService = FurnitureService(); // ← ADD THIS

  // Rotation control
  double rotationX = 0.25;
  double rotationY = 0.35;
  // ... rest of your variables

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
  // Method to open furniture dialog
  Future<void> _openFurnitureDialog(String spotId, FurnitureType type) async {
    Furniture? current = furnitureService.getPlacedFurniture(spotId);

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => FurnitureSelectionDialog(
        spotId: spotId,
        furnitureType: type,
        currentFurniture: current,
      ),
    );

    if (result == true) {
      setState(() {}); // Refresh UI
    }
  }

// Build furniture spot widget
  Widget _buildFurnitureSpot(String spotId, FurnitureType type) {
    Furniture? current = furnitureService.getPlacedFurniture(spotId); // ← current

    return GestureDetector(
      onTap: () => _openFurnitureDialog(spotId, type),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: current != null  // ← CHANGED
              ? Color(0xFF4CAF50).withOpacity(0.3)
              : Colors.black.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: current != null ? Color(0xFF4CAF50) : Colors.white30,  // ← CHANGED
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            current != null ? current.emoji : '+',  // ← CHANGED (both places)
            style: TextStyle(
              fontSize: current != null ? 32 : 24,  // ← CHANGED
              color: current != null ? Colors.white : Colors.white54,  // ← CHANGED
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0a0a0a),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text("My Cave"),
        actions: [
          // Reset view button
          IconButton(
            icon: Icon(Icons.center_focus_strong),
            onPressed: () {
              setState(() {
                rotationX = 0.25;
                rotationY = 0.35;
                offsetX = 0.0;
                offsetY = 0.0;
                _scale = 1.0;
              });
            },
            tooltip: "Reset View",
          ),
          Padding(
            padding: EdgeInsets.all(12),
            child: Center(
              child: Text(
                "💰 \$${widget.character.money}",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(  // ← WRAP IN STACK
        children: [
          // YOUR EXISTING CAVE (unchanged)
          Listener(
            // Mouse wheel for zoom
            onPointerSignal: (event) {
              if (event is PointerScrollEvent) {
                setState(() {
                  _scale = (_scale - event.scrollDelta.dy * 0.001).clamp(0.7, 2.0);
                });
              }
            },
            child: GestureDetector(
              // Rotate and pan with drag
              onScaleStart: (details) {
                _lastDragPosition = details.focalPoint;
              },
              onScaleUpdate: (details) {
                setState(() {
                  // Zoom (pinch)
                  if (details.scale != 1.0) {
                    _scale = (_scale * details.scale).clamp(0.7, 2.0);
                  }

                  // Pan and rotate
                  if (_lastDragPosition != null) {
                    double dx = details.focalPoint.dx - _lastDragPosition!.dx;
                    double dy = details.focalPoint.dy - _lastDragPosition!.dy;

                    // Right mouse button or two-finger: pan
                    // Left mouse button or one-finger: rotate
                    if (details.pointerCount == 2) {
                      // Pan
                      offsetX += dx;
                      offsetY += dy;
                    } else {
                      // Rotate (LIMITED range)
                      rotationY += dx * 0.005;
                      rotationX += dy * 0.005;

                      // TIGHT clamp - just subtle movement
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
              // Tap to open decoration menu
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
                      child: CustomPaint(
                        size: Size(400, 500),
                        painter: ThickWallCubePainter(
                          backgroundColor: backgroundColor,
                          lightLevel: widget.decorations.lightingLevel,
                          decorations: widget.decorations,
                          rotationX: rotationX,
                          rotationY: rotationY,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ), // ← End of Listener

          // NEW FURNITURE BUTTONS - ADD THESE:

          // Bed spot (top-left)
          Positioned(
            top: 80,
            left: 30,
            child: _buildFurnitureSpot('bed_spot', FurnitureType.bed),
          ),

          // Desk spot (top-right)
          Positioned(
            top: 80,
            right: 30,
            child: _buildFurnitureSpot('desk_spot', FurnitureType.desk),
          ),

          // Kitchen spot (bottom-left)
          Positioned(
            bottom: 120,
            left: 30,
            child: _buildFurnitureSpot('kitchen_spot', FurnitureType.kitchen),
          ),

          // Decoration spot (bottom-right)
          Positioned(
            bottom: 120,
            right: 30,
            child: _buildFurnitureSpot('decoration_spot', FurnitureType.decoration),
          ),
        ], // ← End of Stack children
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ShopScreen()), // ← No parameters!
          ).then((_) => setState(() {}));
        },
        backgroundColor: Color(0xFF4CAF50),
        icon: Icon(Icons.store, color: Colors.white),
        label: Text('Shop', style: TextStyle(color: Colors.white)),
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

  ThickWallCubePainter({
    required this.backgroundColor,
    required this.lightLevel,
    required this.decorations,
    required this.rotationX,
    required this.rotationY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final cubeSize = 150.0;

    // Define corners
    final corners = [
      [-1.0, -1.0, -1.0], // 0: Back bottom left
      [1.0, -1.0, -1.0],  // 1: Back bottom right
      [1.0, 1.0, -1.0],   // 2: Back top right
      [-1.0, 1.0, -1.0],  // 3: Back top left
      [-1.0, -1.0, 1.0],  // 4: Front bottom left
      [1.0, -1.0, 1.0],   // 5: Front bottom right
      [1.0, 1.0, 1.0],    // 6: Front top right
      [-1.0, 1.0, 1.0],   // 7: Front top left
    ];

    // Rotate and project
    List<Offset> p = corners.map((corner) {
      return _rotateAndProject(
        corner[0] * cubeSize,
        corner[1] * cubeSize,
        corner[2] * cubeSize,
        rotationX,
        rotationY,
        centerX,
        centerY,
      );
    }).toList();

    // Draw room with thickness!
    _drawEnhancedRoom(canvas, p, size);

    // Draw furniture
    _drawBaseFurniture(canvas, centerX, centerY);
    _drawDecorations(canvas, p, centerX, centerY);
  }

  void _drawEnhancedRoom(Canvas canvas, List<Offset> p, Size size) {
    // 1. FLOOR with visible edge
    _drawFloorWithThickness(canvas, p);

    // 2. WALLS with visible edges
    _drawWallsWithThickness(canvas, p);

    // 3. CORNER LINES (makes structure clear)
    _drawStructureLines(canvas, p);
  }

  void _drawFloorWithThickness(Canvas canvas, List<Offset> p) {
    // Main floor
    final floorPath = Path()
      ..moveTo(p[0].dx, p[0].dy)
      ..lineTo(p[1].dx, p[1].dy)
      ..lineTo(p[5].dx, p[5].dy)
      ..lineTo(p[4].dx, p[4].dy)
      ..close();

    canvas.drawPath(floorPath, Paint()..color = Color(0xFF5a4a3a));

    // Floor EDGE (thickness strip at front)
    final floorEdge = Path()
      ..moveTo(p[4].dx, p[4].dy)
      ..lineTo(p[5].dx, p[5].dy)
      ..lineTo(p[5].dx, p[5].dy + 16) // ← Thickness offset
      ..lineTo(p[4].dx, p[4].dy + 16)
      ..close();

    canvas.drawPath(floorEdge, Paint()..color = Color(0xFF4a3a2a)); // Darker edge

    // Grid on floor
    final gridPaint = Paint()
      ..color = Color(0xFF3d2f22)
      ..strokeWidth = 1.5;

    for (int i = 1; i < 6; i++) {
      double t = i / 6;
      Offset left = Offset.lerp(p[4], p[0], t)!;
      Offset right = Offset.lerp(p[5], p[1], t)!;
      canvas.drawLine(left, right, gridPaint);

      Offset front = Offset.lerp(p[4], p[5], t)!;
      Offset back = Offset.lerp(p[0], p[1], t)!;
      canvas.drawLine(front, back, gridPaint);
    }

    // Floor outline
    canvas.drawPath(
      floorPath,
      Paint()
        ..color = Color(0xFF2a2622)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  void _drawWallsWithThickness(Canvas canvas, List<Offset> p) {
    // BACK WALL - Main face
    final backWall = Path()
      ..moveTo(p[0].dx, p[0].dy)
      ..lineTo(p[1].dx, p[1].dy)
      ..lineTo(p[2].dx, p[2].dy)
      ..lineTo(p[3].dx, p[3].dy)
      ..close();

    canvas.drawPath(backWall, Paint()..color = Color(0xFF4a4440));

    // BACK WALL - Left edge (thickness)
    final backLeftEdge = Path()
      ..moveTo(p[0].dx, p[0].dy)
      ..lineTo(p[0].dx - 10, p[0].dy + 6) // ← Thickness offset
      ..lineTo(p[3].dx - 10, p[3].dy + 6)
      ..lineTo(p[3].dx, p[3].dy)
      ..close();

    canvas.drawPath(backLeftEdge, Paint()..color = Color(0xFF3a3430)); // Darker

    // BACK WALL - Top edge (thickness)
    final backTopEdge = Path()
      ..moveTo(p[3].dx, p[3].dy)
      ..lineTo(p[2].dx, p[2].dy)
      ..lineTo(p[2].dx, p[2].dy - 10) // ← Thickness offset
      ..lineTo(p[3].dx, p[3].dy - 10)
      ..close();

    canvas.drawPath(backTopEdge, Paint()..color = Color(0xFF3a3430));

    // RIGHT WALL - Main face
    final rightWall = Path()
      ..moveTo(p[1].dx, p[1].dy)
      ..lineTo(p[5].dx, p[5].dy)
      ..lineTo(p[6].dx, p[6].dy)
      ..lineTo(p[2].dx, p[2].dy)
      ..close();

    canvas.drawPath(rightWall, Paint()..color = Color(0xFF3d3935));

    // RIGHT WALL - Right edge (thickness)
    final rightEdge = Path()
      ..moveTo(p[5].dx, p[5].dy)
      ..lineTo(p[5].dx + 10, p[5].dy + 6) // ← Thickness offset
      ..lineTo(p[6].dx + 10, p[6].dy + 6)
      ..lineTo(p[6].dx, p[6].dy)
      ..close();

    canvas.drawPath(rightEdge, Paint()..color = Color(0xFF2d2925)); // Darker

    // RIGHT WALL - Top edge (thickness)
    final rightTopEdge = Path()
      ..moveTo(p[2].dx, p[2].dy)
      ..lineTo(p[6].dx, p[6].dy)
      ..lineTo(p[6].dx, p[6].dy - 10) // ← Thickness offset
      ..lineTo(p[2].dx, p[2].dy - 10)
      ..close();

    canvas.drawPath(rightTopEdge, Paint()..color = Color(0xFF2d2925));
  }

  void _drawStructureLines(Canvas canvas, List<Offset> p) {
    final linePaint = Paint()
      ..color = Color(0xFF2a2622)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    // Main corner edges (makes structure super clear)
    canvas.drawLine(p[0], p[3], linePaint); // Back left vertical
    canvas.drawLine(p[1], p[2], linePaint); // Back right vertical
    canvas.drawLine(p[5], p[6], linePaint); // Front right vertical
    canvas.drawLine(p[0], p[1], linePaint); // Back bottom horizontal
    canvas.drawLine(p[3], p[2], linePaint); // Back top horizontal
    canvas.drawLine(p[4], p[5], linePaint); // Front bottom horizontal
  }

  void _drawEdgeHighlights(Canvas canvas, List<Offset> p) {
    final highlightPaint = Paint()
      ..color = Color(0xFF8D7A6B).withOpacity(0.6)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    // Top edges (lighter = closer to "light source")
    canvas.drawLine(p[3], p[2], highlightPaint);
    canvas.drawLine(p[2], p[6], highlightPaint);

    // Vertical edges
    canvas.drawLine(p[3], p[0], highlightPaint..strokeWidth = 1.5);
    canvas.drawLine(p[2], p[1], highlightPaint..strokeWidth = 1.5);
  }

  void _drawCornerShadows(Canvas canvas, List<Offset> p) {
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.3)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8);

    // Back corners (darker = more depth)
    canvas.drawCircle(p[0], 15, shadowPaint);
    canvas.drawCircle(p[1], 15, shadowPaint);

    // Floor front corners (lighter)
    canvas.drawCircle(p[4], 10, shadowPaint..color = Colors.black.withOpacity(0.2));
    canvas.drawCircle(p[5], 10, shadowPaint);
  }

  Offset _rotateAndProject(
      double x,
      double y,
      double z,
      double rotX,
      double rotY,
      double cx,
      double cy,
      ) {
    // Rotate around X axis
    double cosX = cos(rotX);
    double sinX = sin(rotX);
    double y1 = y * cosX - z * sinX;
    double z1 = y * sinX + z * cosX;

    // Rotate around Y axis
    double cosY = cos(rotY);
    double sinY = sin(rotY);
    double x2 = x * cosY + z1 * sinY;
    double z2 = -x * sinY + z1 * cosY;

    return Offset(cx + x2, cy - y1);
  }
  void _drawBaseFurniture(Canvas canvas, double cx, double cy) {
    // 1. BED FRAME OUTLINE (front-right floor)
    _drawBedFrame(canvas, cx, cy);

    // 2. TABLE OUTLINE (center floor)
    _drawTableOutline(canvas, cx, cy);

    // 3. FIRE PIT (front-left floor)
    _drawFirePit(canvas, cx, cy);

    // 4. FLOOR RUG (center)
    _drawFloorRug(canvas, cx, cy);

    // 5. WALL TORCH HOLDERS (back wall)
    _drawTorchHolders(canvas, cx, cy);
  }

  void _drawBedFrame(Canvas canvas, double cx, double cy) {
    // Simple rectangular bed frame outline
    Offset corner1 = _rotateAndProject(40, -150, 60, rotationX, rotationY, cx, cy);
    Offset corner2 = _rotateAndProject(80, -150, 60, rotationX, rotationY, cx, cy);
    Offset corner3 = _rotateAndProject(80, -150, 100, rotationX, rotationY, cx, cy);
    Offset corner4 = _rotateAndProject(40, -150, 100, rotationX, rotationY, cx, cy);

    final bedPaint = Paint()
      ..color = Color(0xFF8D6E63).withOpacity(0.6)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    Path bedPath = Path()
      ..moveTo(corner1.dx, corner1.dy)
      ..lineTo(corner2.dx, corner2.dy)
      ..lineTo(corner3.dx, corner3.dy)
      ..lineTo(corner4.dx, corner4.dy)
      ..close();

    canvas.drawPath(bedPath, bedPaint);
  }

  void _drawTableOutline(Canvas canvas, double cx, double cy) {
    // Simple square table outline
    Offset corner1 = _rotateAndProject(-30, -150, 30, rotationX, rotationY, cx, cy);
    Offset corner2 = _rotateAndProject(-10, -150, 30, rotationX, rotationY, cx, cy);
    Offset corner3 = _rotateAndProject(-10, -150, 50, rotationX, rotationY, cx, cy);
    Offset corner4 = _rotateAndProject(-30, -150, 50, rotationX, rotationY, cx, cy);

    final tablePaint = Paint()
      ..color = Color(0xFF795548).withOpacity(0.5)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    Path tablePath = Path()
      ..moveTo(corner1.dx, corner1.dy)
      ..lineTo(corner2.dx, corner2.dy)
      ..lineTo(corner3.dx, corner3.dy)
      ..lineTo(corner4.dx, corner4.dy)
      ..close();

    canvas.drawPath(tablePath, tablePaint);
  }

  void _drawFirePit(Canvas canvas, double cx, double cy) {
    // Stone circle for fire
    Offset center = _rotateAndProject(-80, -150, 80, rotationX, rotationY, cx, cy);

    final stonePaint = Paint()
      ..color = Color(0xFF616161).withOpacity(0.7)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, 20, stonePaint);

    // Inner circle
    canvas.drawCircle(center, 15, Paint()..color = Color(0xFF424242).withOpacity(0.5));
  }

  void _drawFloorRug(Canvas canvas, double cx, double cy) {
    // Simple rectangular rug pattern
    Offset corner1 = _rotateAndProject(-40, -150, 20, rotationX, rotationY, cx, cy);
    Offset corner2 = _rotateAndProject(30, -150, 20, rotationX, rotationY, cx, cy);
    Offset corner3 = _rotateAndProject(30, -150, 80, rotationX, rotationY, cx, cy);
    Offset corner4 = _rotateAndProject(-40, -150, 80, rotationX, rotationY, cx, cy);

    final rugPaint = Paint()
      ..color = Color(0xFF6D4C41).withOpacity(0.4);

    Path rugPath = Path()
      ..moveTo(corner1.dx, corner1.dy)
      ..lineTo(corner2.dx, corner2.dy)
      ..lineTo(corner3.dx, corner3.dy)
      ..lineTo(corner4.dx, corner4.dy)
      ..close();

    canvas.drawPath(rugPath, rugPaint);

    // Border
    canvas.drawPath(
      rugPath,
      Paint()
        ..color = Color(0xFF5D4037)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );
  }

  void _drawTorchHolders(Canvas canvas, double cx, double cy) {
    // Left wall torch holder
    Offset holder1 = _rotateAndProject(-80, 0, -150, rotationX, rotationY, cx, cy);
    _drawTorchBracket(canvas, holder1);

    // Right wall torch holder
    Offset holder2 = _rotateAndProject(80, 0, -150, rotationX, rotationY, cx, cy);
    _drawTorchBracket(canvas, holder2);
  }

  void _drawTorchBracket(Canvas canvas, Offset pos) {
    final bracketPaint = Paint()
      ..color = Color(0xFF424242)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    // Simple L-shape bracket
    canvas.drawLine(
      Offset(pos.dx, pos.dy - 10),
      Offset(pos.dx, pos.dy + 10),
      bracketPaint,
    );
    canvas.drawLine(
      Offset(pos.dx, pos.dy + 10),
      Offset(pos.dx + 8, pos.dy + 10),
      bracketPaint,
    );
  }

  void _drawDecorations(Canvas canvas, List<Offset> projected, double cx, double cy) {
    // Draw placed decorations at 3D positions

    // Light - on back wall, top center
    DecorationItem? light = decorations.getEquippedItem('light_main');
    if (light != null) {
      Offset lightPos = _rotateAndProject(0, 80, -150, rotationX, rotationY, cx, cy);
      _drawEmoji(canvas, light.emoji, lightPos.dx, lightPos.dy, 40);
    }

    // Bed - on floor, front right
    DecorationItem? bed = decorations.getEquippedItem('bed_main');
    if (bed != null) {
      Offset bedPos = _rotateAndProject(60, -150, 80, rotationX, rotationY, cx, cy);
      _drawEmoji(canvas, bed.emoji, bedPos.dx, bedPos.dy, 50);
    }

    // Decoration 1 - on back wall, left
    DecorationItem? deco1 = decorations.getEquippedItem('decoration_1');
    if (deco1 != null) {
      Offset deco1Pos = _rotateAndProject(-80, 0, -150, rotationX, rotationY, cx, cy);
      _drawEmoji(canvas, deco1.emoji, deco1Pos.dx, deco1Pos.dy, 35);
    }

    // Decoration 2 - on right wall
    DecorationItem? deco2 = decorations.getEquippedItem('decoration_2');
    if (deco2 != null) {
      Offset deco2Pos = _rotateAndProject(150, 0, -50, rotationX, rotationY, cx, cy);
      _drawEmoji(canvas, deco2.emoji, deco2Pos.dx, deco2Pos.dy, 35);
    }

    // Decoration 3 - on floor, center
    DecorationItem? deco3 = decorations.getEquippedItem('decoration_3');
    if (deco3 != null) {
      Offset deco3Pos = _rotateAndProject(-20, -150, 40, rotationX, rotationY, cx, cy);
      _drawEmoji(canvas, deco3.emoji, deco3Pos.dx, deco3Pos.dy, 35);
    }
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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
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