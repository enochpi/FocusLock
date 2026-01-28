import 'package:flutter/material.dart';
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

  // Pan and Zoom controls
  double offsetX = 0.0;
  double offsetY = 0.0;
  double scale = 1.0;

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

  void openItemPicker(PlacementSpot spot) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0a0a0a),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text("My Cave"),
        actions: [
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
      body: GestureDetector(
        onScaleStart: (details) {
          // Starting point for pan/zoom
        },
        onScaleUpdate: (details) {
          setState(() {
            // Zoom
            scale = (scale * details.scale).clamp(0.5, 3.0);

            // Pan
            offsetX += details.focalPointDelta.dx;
            offsetY += details.focalPointDelta.dy;
          });
        },
        child: Container(
          width: double.infinity,
          height: double.infinity,
          color: Color(0xFF0a0a0a),
          child: Transform.translate(
            offset: Offset(offsetX, offsetY),
            child: Transform.scale(
              scale: scale,
              child: CustomPaint(
                size: Size(MediaQuery.of(context).size.width, MediaQuery.of(context).size.height),
                painter: TwoWallCornerPainter(
                  backgroundColor: backgroundColor,
                  lightLevel: widget.decorations.lightingLevel,
                  decorations: widget.decorations,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// TWO WALL CORNER PAINTER
class TwoWallCornerPainter extends CustomPainter {
  final Color backgroundColor;
  final int lightLevel;
  final CaveDecorations decorations;

  TwoWallCornerPainter({
    required this.backgroundColor,
    required this.lightLevel,
    required this.decorations,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // Room dimensions
    final wallWidth = 300.0;
    final wallHeight = 350.0;
    final cornerDepth = 180.0;

    // BACK WALL (main wall)
    _drawBackWall(canvas, centerX, centerY, wallWidth, wallHeight);

    // LEFT WALL (side wall creating corner)
    _drawLeftWall(canvas, centerX, centerY, wallWidth, wallHeight, cornerDepth);

    // FLOOR
    _drawFloor(canvas, centerX, centerY, wallWidth, wallHeight, cornerDepth);

    // Draw decorations
    _drawDecorations(canvas, centerX, centerY);
  }

  void _drawBackWall(Canvas canvas, double cx, double cy, double width, double height) {
    final paint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;

    final backWallRect = Rect.fromCenter(
      center: Offset(cx, cy - 50),
      width: width,
      height: height,
    );

    canvas.drawRect(backWallRect, paint);

    // Border
    canvas.drawRect(
      backWallRect,
      Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );

    // Stone texture
    _drawStoneTexture(
      canvas,
      cx - width / 2,
      cy - 50 - height / 2,
      width,
      height,
    );
  }

  void _drawLeftWall(Canvas canvas, double cx, double cy, double width, double height, double depth) {
    final paint = Paint()
      ..color = backgroundColor.withOpacity(0.7)
      ..style = PaintingStyle.fill;

    final leftWallPath = Path()
      ..moveTo(cx - width / 2, cy - 50 - height / 2) // Top back
      ..lineTo(cx - width / 2 - depth, cy - 50 - height / 2 + 50) // Top front
      ..lineTo(cx - width / 2 - depth, cy - 50 + height / 2 + 50) // Bottom front
      ..lineTo(cx - width / 2, cy - 50 + height / 2) // Bottom back
      ..close();

    canvas.drawPath(leftWallPath, paint);

    // Border
    canvas.drawPath(
      leftWallPath,
      Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );

    // Stone texture on left wall
    _drawStoneTexture(
      canvas,
      cx - width / 2 - depth,
      cy - 50 - height / 2 + 50,
      depth,
      height,
    );
  }

  void _drawFloor(Canvas canvas, double cx, double cy, double width, double height, double depth) {
    final paint = Paint()
      ..color = Color(0xFF4a3f2f)
      ..style = PaintingStyle.fill;

    final floorPath = Path()
      ..moveTo(cx - width / 2, cy - 50 + height / 2) // Back left corner
      ..lineTo(cx + width / 2, cy - 50 + height / 2) // Back right
      ..lineTo(cx + width / 2 + 100, cy - 50 + height / 2 + 150) // Front right
      ..lineTo(cx - width / 2 - depth + 100, cy - 50 + height / 2 + 150) // Front left
      ..close();

    canvas.drawPath(floorPath, paint);

    // Border
    canvas.drawPath(
      floorPath,
      Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );

    // Floor grid lines
    _drawFloorGrid(canvas, cx, cy, width, height, depth);
  }

  void _drawStoneTexture(Canvas canvas, double x, double y, double width, double height) {
    final texturePaint = Paint()
      ..color = Colors.black.withOpacity(0.15)
      ..style = PaintingStyle.fill;

    // Random stone spots
    final random = [
      (0.15, 0.2, 10.0),
      (0.4, 0.35, 12.0),
      (0.7, 0.25, 9.0),
      (0.25, 0.6, 11.0),
      (0.8, 0.65, 13.0),
      (0.5, 0.8, 8.0),
      (0.35, 0.45, 10.0),
      (0.65, 0.55, 9.0),
    ];

    for (var spot in random) {
      canvas.drawCircle(
        Offset(x + width * spot.$1, y + height * spot.$2),
        spot.$3,
        texturePaint,
      );
    }

    // Cracks
    final crackPaint = Paint()
      ..color = Colors.black.withOpacity(0.2)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(x + width * 0.3, y + height * 0.1),
      Offset(x + width * 0.4, y + height * 0.3),
      crackPaint,
    );

    canvas.drawLine(
      Offset(x + width * 0.6, y + height * 0.4),
      Offset(x + width * 0.7, y + height * 0.6),
      crackPaint,
    );
  }

  void _drawFloorGrid(Canvas canvas, double cx, double cy, double width, double height, double depth) {
    final linePaint = Paint()
      ..color = Colors.black.withOpacity(0.25)
      ..strokeWidth = 2;

    final startY = cy - 50 + height / 2;

    // Horizontal lines (going into distance)
    for (int i = 0; i <= 4; i++) {
      double progress = i / 4;
      double currentY = startY + (150 * progress);

      canvas.drawLine(
        Offset(cx - width / 2 - depth + 100 + (depth * progress * 0.3), currentY),
        Offset(cx + width / 2 + 100 - (100 * progress * 0.3), currentY),
        linePaint,
      );
    }

    // Vertical lines (perspective)
    for (int i = 0; i <= 3; i++) {
      double xProgress = i / 3;
      canvas.drawLine(
        Offset(cx - width / 2 + (width * xProgress), startY),
        Offset(cx - width / 2 - depth + 100 + ((width + depth) * xProgress), startY + 150),
        linePaint,
      );
    }
  }

  void _drawDecorations(Canvas canvas, double cx, double cy) {
    // Draw equipped items
    DecorationItem? bed = decorations.getEquippedItem('bed_main');
    if (bed != null) {
      _drawEmoji(canvas, bed.emoji, cx + 80, cy + 150, 50);
    }

    DecorationItem? light = decorations.getEquippedItem('light_main');
    if (light != null) {
      _drawEmoji(canvas, light.emoji, cx, cy - 200, 40);
    }

    DecorationItem? deco1 = decorations.getEquippedItem('decoration_1');
    if (deco1 != null) {
      _drawEmoji(canvas, deco1.emoji, cx - 100, cy - 50, 45);
    }

    DecorationItem? deco2 = decorations.getEquippedItem('decoration_2');
    if (deco2 != null) {
      _drawEmoji(canvas, deco2.emoji, cx + 100, cy - 50, 45);
    }

    DecorationItem? deco3 = decorations.getEquippedItem('decoration_3');
    if (deco3 != null) {
      _drawEmoji(canvas, deco3.emoji, cx - 50, cy + 150, 45);
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
    textPainter.paint(canvas, Offset(x - textPainter.width / 2, y - textPainter.height / 2));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Item Picker Sheet
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