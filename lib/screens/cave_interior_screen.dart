import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'dart:math' as math;
import '../models/character.dart';
import '../models/cave_decorations.dart';
import '../services/storage_service.dart';

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
      body: Listener(
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

    // Cube size
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
    ];

    // Rotate and project corners
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

    // Draw simple 2 walls + floor
    _drawSimpleRoom(canvas, p);
    _drawDecorations(canvas, p, centerX, centerY);
    _drawPlacementSpots(canvas, centerX, centerY);
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

  void _drawSimpleRoom(Canvas canvas, List<Offset> p) {
    // Floor - warmer brown
    _drawFace(
      canvas,
      [p[0], p[1], p[5], p[4]],
      Color(0xFF5a4a3a), // Warmer brown floor
      "Floor",
    );

    // Back wall - better cave stone color
    _drawFace(
      canvas,
      [p[0], p[1], p[2], p[3]],
      Color(0xFF4a4440), // Better gray-brown stone
      "Back",
    );

    // Right wall - slightly darker
    _drawFace(
      canvas,
      [p[1], p[5], p[6], p[2]],
      Color(0xFF3d3935), // Darker stone
      "Right",
    );
  }

  void _drawFace(Canvas canvas, List<Offset> points, Color color, String label) {
    final path = Path()
      ..moveTo(points[0].dx, points[0].dy)
      ..lineTo(points[1].dx, points[1].dy)
      ..lineTo(points[2].dx, points[2].dy)
      ..lineTo(points[3].dx, points[3].dy)
      ..close();

    // Fill
    canvas.drawPath(path, Paint()..color = color);

    // Border
    canvas.drawPath(
      path,
      Paint()
        ..color = Color(0xFF2a2622)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    // Add texture
    if (label == "Floor") {
      _drawFloorGrid(canvas, points);
    } else {
      _drawStoneTexture(canvas, points);
    }
  }

  void _drawStoneTexture(Canvas canvas, List<Offset> points) {
    final texturePaint = Paint()
      ..color = Colors.black.withOpacity(0.2);

    // Stone spots
    for (int i = 0; i < 8; i++) {
      double t1 = (i * 0.17 + 0.1);
      double t2 = ((i * 0.23 + 0.2) % 1.0);

      Offset spot = Offset(
        points[0].dx * (1 - t1) + points[2].dx * t1,
        points[0].dy * (1 - t2) + points[2].dy * t2,
      );

      canvas.drawCircle(spot, 6, texturePaint);
    }
  }

  void _drawFloorGrid(Canvas canvas, List<Offset> points) {
    final gridPaint = Paint()
      ..color = Color(0xFF3d2f22).withOpacity(0.5)
      ..strokeWidth = 1.5;

    // Grid lines
    for (int i = 1; i < 4; i++) {
      double t = i / 4;

      Offset start = Offset.lerp(points[0], points[1], t)!;
      Offset end = Offset.lerp(points[3], points[2], t)!;
      canvas.drawLine(start, end, gridPaint);

      start = Offset.lerp(points[0], points[3], t)!;
      end = Offset.lerp(points[1], points[2], t)!;
      canvas.drawLine(start, end, gridPaint);
    }
  }

  void _drawPlacementSpots(Canvas canvas, double cx, double cy) {
    // Define 3D positions for each placement spot
    // Then project them just like the walls/floor

    // Bed spot - on floor, front right
    if (decorations.getEquippedItem('bed_main') == null) {
      Offset bedPos = _rotateAndProject(60, -150, 80, rotationX, rotationY, cx, cy);
      _drawPlusSign(canvas, bedPos.dx, bedPos.dy, "Bed");
    }

    // Table spot - on floor, center
    if (decorations.getEquippedItem('decoration_3') == null) {
      Offset tablePos = _rotateAndProject(-20, -150, 40, rotationX, rotationY, cx, cy);
      _drawPlusSign(canvas, tablePos.dx, tablePos.dy, "Table");
    }

    // Light spot - on back wall, top center
    if (decorations.getEquippedItem('light_main') == null) {
      Offset lightPos = _rotateAndProject(0, 80, -150, rotationX, rotationY, cx, cy);
      _drawPlusSign(canvas, lightPos.dx, lightPos.dy, "Light");
    }

    // Wall decoration 1 - on back wall, left side
    if (decorations.getEquippedItem('decoration_1') == null) {
      Offset deco1Pos = _rotateAndProject(-80, 0, -150, rotationX, rotationY, cx, cy);
      _drawPlusSign(canvas, deco1Pos.dx, deco1Pos.dy, "Decor");
    }

    // Wall decoration 2 - on right wall
    if (decorations.getEquippedItem('decoration_2') == null) {
      Offset deco2Pos = _rotateAndProject(150, 0, -50, rotationX, rotationY, cx, cy);
      _drawPlusSign(canvas, deco2Pos.dx, deco2Pos.dy, "Decor");
    }
  }

  void _drawPlusSign(Canvas canvas, double x, double y, String label) {
    // Circle background
    canvas.drawCircle(
      Offset(x, y),
      25,
      Paint()
        ..color = Color(0xFF00d4ff).withOpacity(0.2)
        ..style = PaintingStyle.fill,
    );

    // Circle border
    canvas.drawCircle(
      Offset(x, y),
      25,
      Paint()
        ..color = Color(0xFF00d4ff)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Plus sign
    final plusPaint = Paint()
      ..color = Color(0xFF00d4ff)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    // Horizontal line
    canvas.drawLine(Offset(x - 10, y), Offset(x + 10, y), plusPaint);
    // Vertical line
    canvas.drawLine(Offset(x, y - 10), Offset(x, y + 10), plusPaint);

    // Label text
    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(x - textPainter.width / 2, y + 30),
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