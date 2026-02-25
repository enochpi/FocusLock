import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import '../models/character.dart';
import '../models/cave_decorations.dart';
import '../services/furniture_service.dart';
import '../services/currency_service.dart';
import 'cave_shop_screen.dart';

class CaveInteriorScreen extends StatefulWidget {
  final Character character;
  final CaveDecorations decorations;
  final int stage;

  const CaveInteriorScreen({
    super.key,
    required this.character,
    required this.decorations,
    required this.stage,
  });

  @override
  State<CaveInteriorScreen> createState() => _CaveInteriorScreenState();
}

class _CaveInteriorScreenState extends State<CaveInteriorScreen> {
  ui.Image? _backgroundImage;

  // Furniture positions (spotId -> {x, y} percentages)
  Map<String, Offset> _furniturePositions = {};
  String? _draggingSpotId;
  Offset? _dragOffset;

  // Furniture upgrade levels (furnitureId -> level 1-10)
  Map<String, int> _furnitureLevels = {};

  @override
  void initState() {
    super.initState();
    _loadBackgroundImage();
    _initializeDefaultPositions();
  }

  void _initializeDefaultPositions() {
    // Default positions near the back wall (lower y values = closer to wall)
    _furniturePositions = {
      // Floor items - positioned near back wall
      'bed_spot': const Offset(0.15, 0.58),        // Far left, against wall
      'kitchen_spot': const Offset(0.40, 0.56),    // Center-left, near wall
      'desk_spot': const Offset(0.70, 0.58),       // Right side, against wall
      'chair_spot': const Offset(0.70, 0.68),      // In front of desk

      // Wall decorations - scattered on walls
      'decoration_spot_1': const Offset(0.12, 0.18),
      'decoration_spot_2': const Offset(0.28, 0.22),
      'decoration_spot_3': const Offset(0.72, 0.20),
      'decoration_spot_4': const Offset(0.88, 0.24),
      'decoration_spot_5': const Offset(0.20, 0.38),
      'decoration_spot_6': const Offset(0.50, 0.35),
      'decoration_spot_7': const Offset(0.82, 0.40),
      'decoration_spot_8': const Offset(0.35, 0.52),
    };
  }

  int _getFurnitureLevel(String furnitureId) {
    return _furnitureLevels[furnitureId] ?? 1;
  }

  int _getUpgradeCost(String furnitureId) {
    final currentLevel = _getFurnitureLevel(furnitureId);
    if (currentLevel >= 10) return 0;

    // Base cost of 50 coins, exponentially scaling
    // Level 1->2: 50, 2->3: 75, 3->4: 113, 5->6: 253, 9->10: 1925
    return (50 * math.pow(1.5, currentLevel)).round();
  }

  double _getFurnitureBoost(String furnitureId) {
    final level = _getFurnitureLevel(furnitureId);
    // Boost: Level 1 = 1x, Level 5 = 2x, Level 10 = 3.25x
    return 1.0 + (level - 1) * 0.25;
  }

  void _showUpgradeDialog(String spotId, String furnitureId) {
    final level = _getFurnitureLevel(furnitureId);
    final cost = _getUpgradeCost(furnitureId);
    final boost = _getFurnitureBoost(furnitureId);
    final nextBoost = level < 10 ? _getFurnitureBoost(furnitureId) + 0.25 : boost;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Text(_getFurnitureName(furnitureId)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _getLevelColor(level),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Lv $level',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current boost
            Text(
              'Current Boost: ${boost.toStringAsFixed(2)}x',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            // Progress bar
            LinearProgressIndicator(
              value: level / 10,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation(_getLevelColor(level)),
            ),
            const SizedBox(height: 16),

            if (level < 10) ...[
              // Next level info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Upgrade to Level ${level + 1}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text('New Boost: ${nextBoost.toStringAsFixed(2)}x'),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Text('Cost: ', style: TextStyle(fontWeight: FontWeight.bold)),
                        const Text('🪙', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 4),
                        Text(
                          '$cost',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: CurrencyService().coins >= cost
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Max level reached
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber[300]!),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.star, color: Colors.amber, size: 24),
                    SizedBox(width: 8),
                    Text(
                      'MAX LEVEL!',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.amber,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          if (level < 10)
            ElevatedButton.icon(
              onPressed: CurrencyService().coins >= cost
                  ? () {
                setState(() {
                  CurrencyService().addCoins(-cost);
                  _furnitureLevels[furnitureId] = level + 1;
                });
                Navigator.pop(context);

                // Show success message
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Upgraded to Level ${level + 1}! 🎉'),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
                  : null,
              icon: const Icon(Icons.arrow_upward),
              label: const Text('Upgrade'),
            ),
        ],
      ),
    );
  }

  String _getFurnitureName(String furnitureId) {
    return furnitureId.split('_').map((word) =>
    word[0].toUpperCase() + word.substring(1)
    ).join(' ');
  }

  Color _getLevelColor(int level) {
    if (level >= 10) return Colors.amber;
    if (level >= 7) return Colors.purple;
    if (level >= 4) return Colors.blue;
    return Colors.green;
  }

  void _handleLongPress(LongPressStartDetails details, Size size) {
    final tapPos = details.localPosition;
    final furnitureService = FurnitureService();

    // Check which furniture was long-pressed
    for (var entry in _furniturePositions.entries) {
      final spotId = entry.key;
      final position = entry.value;
      final furnitureId = furnitureService.placedFurniture[spotId];

      if (furnitureId == null) continue;

      final furnitureX = size.width * position.dx;
      final furnitureY = size.height * position.dy;

      final hitArea = Rect.fromCenter(
        center: Offset(furnitureX, furnitureY),
        width: 80,
        height: 80,
      );

      if (hitArea.contains(tapPos)) {
        _showUpgradeDialog(spotId, furnitureId);
        break;
      }
    }
  }

  void _handlePanStart(DragStartDetails details, Size size) {
    final tapPos = details.localPosition;
    final furnitureService = FurnitureService();

    // Check which furniture was tapped (in reverse order so top items are checked first)
    final spots = _furniturePositions.keys.toList().reversed;

    for (var spotId in spots) {
      final furnitureId = furnitureService.placedFurniture[spotId];
      if (furnitureId == null) continue;

      final pos = _furniturePositions[spotId]!;
      final furnitureX = size.width * pos.dx;
      final furnitureY = size.height * pos.dy;

      // Hit test (50x50 pixel hit area)
      final hitArea = Rect.fromCenter(
        center: Offset(furnitureX, furnitureY),
        width: 80,
        height: 80,
      );

      if (hitArea.contains(tapPos)) {
        setState(() {
          _draggingSpotId = spotId;
          _dragOffset = Offset(tapPos.dx - furnitureX, tapPos.dy - furnitureY);
        });
        break;
      }
    }
  }

  void _handlePanUpdate(DragUpdateDetails details, Size size) {
    if (_draggingSpotId == null) return;

    setState(() {
      final newX = (details.localPosition.dx - _dragOffset!.dx) / size.width;
      final newY = (details.localPosition.dy - _dragOffset!.dy) / size.height;

      // Clamp to screen bounds
      _furniturePositions[_draggingSpotId!] = Offset(
        newX.clamp(0.05, 0.95),
        newY.clamp(0.10, 0.90),
      );
    });
  }

  void _handlePanEnd(DragEndDetails details) {
    setState(() {
      _draggingSpotId = null;
      _dragOffset = null;
    });
  }

  Future<void> _loadBackgroundImage() async {
    final ByteData data = await rootBundle.load('assets/images/cave_background.png');
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    setState(() {
      _backgroundImage = frame.image;
    });
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      body: SafeArea(
        child: Stack(
          children: [
            // Main 2D room view with draggable furniture
            Positioned.fill(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final size = Size(constraints.maxWidth, constraints.maxHeight);

                  return GestureDetector(
                    onPanStart: (details) => _handlePanStart(details, size),
                    onPanUpdate: (details) => _handlePanUpdate(details, size),
                    onPanEnd: _handlePanEnd,
                    onLongPressStart: (details) => _handleLongPress(details, size),
                    child: CustomPaint(
                      painter: Simple2DRoomPainter(
                        stage: widget.stage,
                        backgroundImage: _backgroundImage,
                        furniturePositions: _furniturePositions,
                        draggingSpotId: _draggingSpotId,
                        furnitureLevels: _furnitureLevels,
                      ),
                      size: Size.infinite,
                    ),
                  );
                },
              ),
            ),

            // Top UI
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back button
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),

                  // Drag & upgrade instructions
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.touch_app, color: Colors.white70, size: 14),
                            SizedBox(width: 4),
                            Text(
                              'Drag to move',
                              style: TextStyle(color: Colors.white70, fontSize: 11),
                            ),
                          ],
                        ),
                        SizedBox(height: 2),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.upgrade, color: Colors.amber, size: 14),
                            SizedBox(width: 4),
                            Text(
                              'Hold to upgrade',
                              style: TextStyle(color: Colors.amber, fontSize: 11),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Coins display
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Text('🪙', style: TextStyle(fontSize: 20)),
                        const SizedBox(width: 8),
                        Text(
                          '${CurrencyService().coins}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Bottom shop button
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Reset positions button (small)
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _initializeDefaultPositions();
                      });
                    },
                    icon: const Icon(Icons.refresh, size: 16, color: Colors.white70),
                    label: const Text(
                      'Reset Positions',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.black38,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Shop button
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CaveShopScreen(),
                          ),
                        );
                        setState(() {}); // Refresh to show new furniture
                      },
                      icon: const Icon(Icons.shopping_bag),
                      label: const Text('Furniture Shop'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        textStyle: const TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  SIMPLE 2D ROOM PAINTER — Just Wall + Floor + Furniture
// ═══════════════════════════════════════════════════════════════════════════

class Simple2DRoomPainter extends CustomPainter {
  final int stage;
  final ui.Image? backgroundImage;
  final Map<String, Offset> furniturePositions;
  final String? draggingSpotId;
  final Map<String, int> furnitureLevels;

  Simple2DRoomPainter({
    required this.stage,
    this.backgroundImage,
    required this.furniturePositions,
    this.draggingSpotId,
    required this.furnitureLevels,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw background image if available, otherwise draw simple background
    if (backgroundImage != null) {
      // Draw the cave background image to fill the canvas
      paintImage(
        canvas: canvas,
        rect: Rect.fromLTWH(0, 0, size.width, size.height),
        image: backgroundImage!,
        fit: BoxFit.cover,
      );
    } else {
      // Fallback: simple gradient background
      final bgPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF1a1a1a),
            const Color(0xFF2d2d1f),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);
    }

    // Draw all placed furniture on top
    _drawPlacedFurniture(canvas, size);
  }

  void _drawPlacedFurniture(Canvas canvas, Size size) {
    final furnitureService = FurnitureService();

    // Draw all furniture at their stored positions
    for (var entry in furniturePositions.entries) {
      final spotId = entry.key;
      final position = entry.value;
      final furnitureId = furnitureService.placedFurniture[spotId];

      if (furnitureId == null) continue;

      // Determine scale based on furniture type
      double baseScale;
      if (spotId.startsWith('decoration_spot_')) {
        final decorNum = int.tryParse(spotId.replaceAll('decoration_spot_', '')) ?? 1;
        baseScale = 0.65 + (decorNum % 3) * 0.1;
      } else if (spotId == 'chair_spot') {
        baseScale = 1.0;
      } else if (spotId == 'kitchen_spot') {
        baseScale = 1.5;
      } else {
        baseScale = 1.2;
      }

      // Level increases size slightly (up to +20% at level 10)
      final level = furnitureLevels[furnitureId] ?? 1;
      final levelScaleBonus = (level - 1) * 0.022;
      final scale = baseScale + levelScaleBonus;

      final fx = size.width * position.dx;
      final fy = size.height * position.dy;

      // Highlight if being dragged
      final isDragging = spotId == draggingSpotId;

      if (isDragging) {
        final glowPaint = Paint()
          ..color = const Color(0xFF00FFFF).withOpacity(0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
        canvas.drawCircle(Offset(fx, fy), 40, glowPaint);
      }

      // Level aura (drawn BEHIND furniture)
      if (level >= 3) {
        _drawLevelAura(canvas, fx, fy, level, scale);
      }

      // Draw furniture
      _drawFurnitureItem(
        canvas,
        size,
        furnitureId,
        position.dx,
        position.dy,
        scale: scale,
      );

      // Level overlay effects (drawn ON TOP of furniture)
      if (level >= 5) {
        _drawLevelOverlay(canvas, fx, fy, level, scale);
      }

      // Draw level badge
      if (level > 1) {
        _drawLevelBadge(canvas, fx, fy, level, scale);
      }
    }
  }

  void _drawLevelBadge(Canvas canvas, double x, double y, int level, double furnitureScale) {
    // Position badge at top-right of furniture
    final badgeX = x + 35 * furnitureScale;
    final badgeY = y - 35 * furnitureScale;
    final badgeSize = 18.0;

    // Badge background (color based on level)
    Color badgeColor;
    if (level >= 10) {
      badgeColor = const Color(0xFFFFD700); // Gold
    } else if (level >= 7) {
      badgeColor = const Color(0xFF9C27B0); // Purple
    } else if (level >= 4) {
      badgeColor = const Color(0xFF2196F3); // Blue
    } else {
      badgeColor = const Color(0xFF4CAF50); // Green
    }

    // Badge glow
    final glowPaint = Paint()
      ..color = badgeColor.withOpacity(0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(Offset(badgeX, badgeY), badgeSize + 3, glowPaint);

    // Badge circle
    final badgePaint = Paint()
      ..color = badgeColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(badgeX, badgeY), badgeSize, badgePaint);

    // Badge border
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(Offset(badgeX, badgeY), badgeSize, borderPaint);

    // Level text
    final textPainter = TextPainter(
      text: TextSpan(
        text: '$level',
        style: TextStyle(
          color: level >= 10 ? Colors.black : Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        badgeX - textPainter.width / 2,
        badgeY - textPainter.height / 2,
      ),
    );

    // Star icon for max level
    if (level >= 10) {
      _drawStar(canvas, badgeX, badgeY - badgeSize - 8, 6, Colors.amber);
    }
  }

  void _drawStar(Canvas canvas, double x, double y, double size, Color color) {
    final path = Path();
    for (int i = 0; i < 5; i++) {
      final angle = (i * 4 * math.pi / 5) - math.pi / 2;
      final radius = i % 2 == 0 ? size : size / 2;
      final pointX = x + math.cos(angle) * radius;
      final pointY = y + math.sin(angle) * radius;

      if (i == 0) {
        path.moveTo(pointX, pointY);
      } else {
        path.lineTo(pointX, pointY);
      }
    }
    path.close();

    canvas.drawPath(path, Paint()..color = color);
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  LEVEL VISUAL SYSTEM — Tier-based auras, overlays, and effects
  // ═══════════════════════════════════════════════════════════════════════

  /// Drawn BEHIND furniture — ambient light and ground glow
  void _drawLevelAura(Canvas canvas, double x, double y, int level, double scale) {
    // Tier colors
    Color auraColor;
    double auraOpacity;
    double auraRadius;

    if (level >= 9) {
      // 👑 LEGENDARY (9-10) — Golden divine aura
      auraColor = const Color(0xFFFFD700);
      auraOpacity = 0.55;
      auraRadius = 65 * scale;
    } else if (level >= 7) {
      // ✨ ENCHANTED (7-8) — Purple magical aura
      auraColor = const Color(0xFFAA44FF);
      auraOpacity = 0.45;
      auraRadius = 55 * scale;
    } else if (level >= 5) {
      // ⚒️ CRAFTED (5-6) — Blue cool aura
      auraColor = const Color(0xFF44AAFF);
      auraOpacity = 0.35;
      auraRadius = 45 * scale;
    } else {
      // 🔨 REPAIRED (3-4) — Warm amber glow
      auraColor = const Color(0xFFFF9944);
      auraOpacity = 0.25;
      auraRadius = 38 * scale;
    }

    // Soft outer glow on ground
    canvas.drawCircle(
      Offset(x, y + 10),
      auraRadius,
      Paint()
        ..color = auraColor.withOpacity(auraOpacity * 0.4)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, auraRadius * 0.5),
    );

    // Ground circle light pool
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x, y + 20), width: auraRadius * 1.4, height: auraRadius * 0.4),
      Paint()
        ..color = auraColor.withOpacity(auraOpacity * 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );

    // Legendary: rotating ring effect (static ring since no animation)
    if (level >= 9) {
      final ringPaint = Paint()
        ..color = const Color(0xFFFFD700).withOpacity(0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, y + 15), width: 80 * scale, height: 22 * scale),
        ringPaint,
      );
      // Outer ring
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, y + 15), width: 96 * scale, height: 28 * scale),
        Paint()
          ..color = const Color(0xFFFFD700).withOpacity(0.15)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4,
      );
    }

    // Enchanted: swirling ring
    if (level >= 7 && level < 9) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, y + 15), width: 72 * scale, height: 18 * scale),
        Paint()
          ..color = const Color(0xFFAA44FF).withOpacity(0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  /// Drawn ON TOP of furniture — trim, runes, sparkles
  void _drawLevelOverlay(Canvas canvas, double x, double y, int level, double scale) {
    final random = math.Random(level * 7 + x.toInt());

    if (level >= 9) {
      // 👑 LEGENDARY — Gold trim shimmer + floating stars + rune circle

      // Gold shimmer overlay on furniture body
      canvas.drawCircle(
        Offset(x, y - 5),
        42 * scale,
        Paint()
          ..color = const Color(0xFFFFD700).withOpacity(0.08)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20),
      );

      // Floating gold sparkles above furniture
      for (int i = 0; i < 8; i++) {
        final sparkX = x + (random.nextDouble() - 0.5) * 70 * scale;
        final sparkY = y - 30 - random.nextDouble() * 45 * scale;
        final sparkSize = (1.5 + random.nextDouble() * 2.5) * scale;

        // Sparkle glow
        canvas.drawCircle(
          Offset(sparkX, sparkY),
          sparkSize + 3,
          Paint()
            ..color = const Color(0xFFFFD700).withOpacity(0.5)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
        );
        // Sparkle core
        canvas.drawCircle(
          Offset(sparkX, sparkY),
          sparkSize,
          Paint()..color = const Color(0xFFFFF9C4),
        );

        // Cross-sparkle lines
        final crossPaint = Paint()
          ..color = const Color(0xFFFFD700).withOpacity(0.8)
          ..strokeWidth = 1.5;
        canvas.drawLine(
          Offset(sparkX - sparkSize * 2.5, sparkY),
          Offset(sparkX + sparkSize * 2.5, sparkY),
          crossPaint,
        );
        canvas.drawLine(
          Offset(sparkX, sparkY - sparkSize * 2.5),
          Offset(sparkX, sparkY + sparkSize * 2.5),
          crossPaint,
        );
      }

      // Crown symbol above furniture
      _drawCrown(canvas, x, y - 55 * scale, scale);

    } else if (level >= 7) {
      // ✨ ENCHANTED — Purple runes + floating motes

      // Purple shimmer
      canvas.drawCircle(
        Offset(x, y - 5),
        38 * scale,
        Paint()
          ..color = const Color(0xFFAA44FF).withOpacity(0.07)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
      );

      // Floating purple motes
      for (int i = 0; i < 5; i++) {
        final moteX = x + (random.nextDouble() - 0.5) * 55 * scale;
        final moteY = y - 20 - random.nextDouble() * 40 * scale;
        final moteSize = (1.5 + random.nextDouble() * 2) * scale;

        canvas.drawCircle(
          Offset(moteX, moteY),
          moteSize + 3,
          Paint()
            ..color = const Color(0xFFAA44FF).withOpacity(0.5)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
        );
        canvas.drawCircle(
          Offset(moteX, moteY),
          moteSize,
          Paint()..color = const Color(0xFFDD88FF),
        );
      }

      // Rune symbols floating around furniture
      _drawRuneSymbols(canvas, x, y, scale, const Color(0xFFAA44FF));

    } else if (level >= 5) {
      // ⚒️ CRAFTED — Blue shimmer + light rays

      // Cool blue shimmer
      canvas.drawCircle(
        Offset(x, y - 5),
        34 * scale,
        Paint()
          ..color = const Color(0xFF44AAFF).withOpacity(0.06)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
      );

      // Floating blue motes (fewer)
      for (int i = 0; i < 3; i++) {
        final moteX = x + (random.nextDouble() - 0.5) * 45 * scale;
        final moteY = y - 15 - random.nextDouble() * 30 * scale;

        canvas.drawCircle(
          Offset(moteX, moteY),
          (1.5 + random.nextDouble() * 1.5) * scale + 2,
          Paint()
            ..color = const Color(0xFF44AAFF).withOpacity(0.5)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
        );
        canvas.drawCircle(
          Offset(moteX, moteY),
          (1.5 + random.nextDouble() * 1.5) * scale,
          Paint()..color = const Color(0xFFAACCFF),
        );
      }
    }
  }

  void _drawCrown(Canvas canvas, double x, double y, double scale) {
    final s = scale * 0.7;
    final crownColor = const Color(0xFFFFD700);

    final path = Path()
      ..moveTo(x - 14 * s, y + 8 * s)
      ..lineTo(x - 14 * s, y)
      ..lineTo(x - 8 * s, y + 4 * s)
      ..lineTo(x, y - 8 * s)
      ..lineTo(x + 8 * s, y + 4 * s)
      ..lineTo(x + 14 * s, y)
      ..lineTo(x + 14 * s, y + 8 * s)
      ..close();

    // Crown glow
    canvas.drawPath(
      path,
      Paint()
        ..color = crownColor.withOpacity(0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    // Crown body
    canvas.drawPath(path, Paint()..color = crownColor);
    // Crown gems
    for (int i = 0; i < 3; i++) {
      canvas.drawCircle(
        Offset(x + (i - 1) * 7 * s, y + 5 * s),
        2 * s,
        Paint()..color = [
          const Color(0xFFFF4444),
          const Color(0xFF44FF44),
          const Color(0xFF4444FF),
        ][i],
      );
    }
  }

  void _drawRuneSymbols(Canvas canvas, double x, double y, double scale, Color color) {
    final random = math.Random(x.toInt() + 99);
    final runePaint = Paint()
      ..color = color.withOpacity(0.55)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // 3 floating rune symbols around furniture
    final positions = [
      Offset(x - 40 * scale, y - 25 * scale),
      Offset(x + 38 * scale, y - 20 * scale),
      Offset(x - 5 * scale, y - 50 * scale),
    ];

    for (int i = 0; i < positions.length; i++) {
      final rx = positions[i].dx;
      final ry = positions[i].dy;
      final s = (0.7 + random.nextDouble() * 0.3) * scale;

      // Glow behind rune
      canvas.drawCircle(
        Offset(rx, ry), 7 * s,
        Paint()
          ..color = color.withOpacity(0.2)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );

      // Simple rune shapes (angular lines)
      switch (i % 3) {
        case 0: // X shape
          canvas.drawLine(Offset(rx - 5 * s, ry - 5 * s), Offset(rx + 5 * s, ry + 5 * s), runePaint);
          canvas.drawLine(Offset(rx + 5 * s, ry - 5 * s), Offset(rx - 5 * s, ry + 5 * s), runePaint);
          canvas.drawLine(Offset(rx - 5 * s, ry), Offset(rx + 5 * s, ry), runePaint);
          break;
        case 1: // Triangle
          canvas.drawLine(Offset(rx, ry - 6 * s), Offset(rx + 5 * s, ry + 5 * s), runePaint);
          canvas.drawLine(Offset(rx + 5 * s, ry + 5 * s), Offset(rx - 5 * s, ry + 5 * s), runePaint);
          canvas.drawLine(Offset(rx - 5 * s, ry + 5 * s), Offset(rx, ry - 6 * s), runePaint);
          canvas.drawLine(Offset(rx - 3 * s, ry + 2 * s), Offset(rx + 3 * s, ry + 2 * s), runePaint);
          break;
        case 2: // Angular character
          canvas.drawLine(Offset(rx - 4 * s, ry - 6 * s), Offset(rx - 4 * s, ry + 6 * s), runePaint);
          canvas.drawLine(Offset(rx - 4 * s, ry - 6 * s), Offset(rx + 4 * s, ry - 2 * s), runePaint);
          canvas.drawLine(Offset(rx - 4 * s, ry), Offset(rx + 4 * s, ry + 4 * s), runePaint);
          break;
      }
    }
  }

  void _drawFurnitureItem(
      Canvas canvas,
      Size size,
      String furnitureId,
      double xPercent,
      double yPercent,
      {double scale = 1.0}
      ) {
    final x = size.width * xPercent;
    final y = size.height * yPercent;

    // Save canvas state
    canvas.save();

    // Apply scaling from center of furniture
    canvas.translate(x, y);
    canvas.scale(scale);
    canvas.translate(-x, -y);

    // Draw based on furniture ID
    switch (furnitureId) {
    // ═══ BEDS ═══
      case 'hay_pile':
        _drawHayPile(canvas, x, y);
        break;
      case 'simple_cot':
        _drawSimpleCot(canvas, x, y);
        break;
      case 'wood_bed':
        _drawWoodBed(canvas, x, y);
        break;

    // ═══ DESKS ═══
      case 'rock_desk':
        _drawRockDesk(canvas, x, y);
        break;
      case 'wooden_desk':
        _drawWoodenDesk(canvas, x, y);
        break;
      case 'sturdy_desk':
        _drawSturdyDesk(canvas, x, y);
        break;

    // ═══ CHAIRS ═══
      case 'tree_stump':
        _drawTreeStump(canvas, x, y);
        break;
      case 'wooden_chair':
        _drawWoodenChair(canvas, x, y);
        break;
      case 'comfy_chair':
        _drawComfyChair(canvas, x, y);
        break;

    // ═══ KITCHEN ═══
      case 'small_fire':
        _drawSmallFire(canvas, x, y);
        break;
      case 'campfire':
        _drawCampfire(canvas, x, y);
        break;
      case 'stone_oven':
        _drawStoneOven(canvas, x, y);
        break;

    // ═══ DECORATIONS ═══
      case 'small_rock':
        _drawSmallRock(canvas, x, y);
        break;
      case 'moss_patch':
        _drawMossPatch(canvas, x, y);
        break;
      case 'wall_torch':
        _drawWallTorch(canvas, x, y);
        break;
      case 'cave_painting':
        _drawCavePainting(canvas, x, y);
        break;
      case 'glowing_mushroom':
        _drawGlowingMushroom(canvas, x, y);
        break;
      case 'crystal_cluster':
        _drawCrystalCluster(canvas, x, y);
        break;
      case 'ancient_artifact':
        _drawAncientArtifact(canvas, x, y);
        break;
      case 'enchanted_crystal':
        _drawEnchantedCrystal(canvas, x, y);
        break;
    }

    // Restore canvas state (undo scaling)
    canvas.restore();
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  FURNITURE DRAWING METHODS — Upgraded with shading, highlights, textures
  // ═══════════════════════════════════════════════════════════════════════

  // ─────────────── BEDS ───────────────

  void _drawHayPile(Canvas canvas, double x, double y) {
    // REALISTIC HAY PILE - Natural straw bedding with individual strands

    final hayGold = const Color(0xFFd4af37);
    final hayBrown = const Color(0xFFb8860b);
    final hayDark = const Color(0xFF8B6914);
    final strawYellow = const Color(0xFFEEDD82);

    // Shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x, y + 28), width: 95, height: 18),
      shadowPaint,
    );

    // BASE PILE SHAPE - Irregular natural mound
    final random = math.Random(42);

    // Main pile body (organic shape)
    final pilePath = Path()
      ..moveTo(x - 45, y + 20)
      ..quadraticBezierTo(x - 42, y + 10, x - 35, y + 5)
      ..quadraticBezierTo(x - 25, y - 8, x - 10, y - 15)
      ..quadraticBezierTo(x, y - 18, x + 10, y - 15)
      ..quadraticBezierTo(x + 25, y - 8, x + 35, y + 5)
      ..quadraticBezierTo(x + 42, y + 10, x + 45, y + 20)
      ..close();

    canvas.drawPath(
      pilePath,
      Paint()..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [strawYellow, hayGold, hayBrown, hayDark],
      ).createShader(Rect.fromCenter(center: Offset(x, y + 2), width: 90, height: 38)),
    );

    // INDIVIDUAL HAY STRANDS - Realistic scattered straw
    final strandPaint = Paint()
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    // Layer 1: Dark strands (bottom/shadow)
    for (int i = 0; i < 80; i++) {
      final strandX = x - 40 + random.nextDouble() * 80;
      final strandY = y - 12 + random.nextDouble() * 30;
      final length = 8 + random.nextDouble() * 18;
      final angle = random.nextDouble() * math.pi - math.pi / 2;

      strandPaint.color = hayDark.withOpacity(0.6 + random.nextDouble() * 0.3);

      canvas.drawLine(
        Offset(strandX, strandY),
        Offset(
          strandX + math.cos(angle) * length,
          strandY + math.sin(angle) * length,
        ),
        strandPaint,
      );
    }

    // Layer 2: Mid-tone strands
    for (int i = 0; i < 60; i++) {
      final strandX = x - 38 + random.nextDouble() * 76;
      final strandY = y - 15 + random.nextDouble() * 28;
      final length = 10 + random.nextDouble() * 16;
      final angle = random.nextDouble() * math.pi - math.pi / 2;

      strandPaint.color = hayBrown.withOpacity(0.7 + random.nextDouble() * 0.2);

      canvas.drawLine(
        Offset(strandX, strandY),
        Offset(
          strandX + math.cos(angle) * length,
          strandY + math.sin(angle) * length,
        ),
        strandPaint,
      );
    }

    // Layer 3: Light strands (top/highlights)
    for (int i = 0; i < 40; i++) {
      final strandX = x - 35 + random.nextDouble() * 70;
      final strandY = y - 18 + random.nextDouble() * 25;
      final length = 6 + random.nextDouble() * 14;
      final angle = random.nextDouble() * math.pi - math.pi / 2;

      strandPaint.color = random.nextBool() ? hayGold : strawYellow;

      canvas.drawLine(
        Offset(strandX, strandY),
        Offset(
          strandX + math.cos(angle) * length,
          strandY + math.sin(angle) * length,
        ),
        strandPaint,
      );
    }

    // TEXTURE CLUMPS - Natural bundles of straw
    final clumpPaint = Paint()..strokeWidth = 3..strokeCap = StrokeCap.round;

    for (int i = 0; i < 15; i++) {
      final clumpX = x - 30 + random.nextDouble() * 60;
      final clumpY = y - 10 + random.nextDouble() * 25;
      final clumpAngle = random.nextDouble() * math.pi - math.pi / 2;
      final clumpLength = 12 + random.nextDouble() * 8;

      clumpPaint.color = hayBrown.withOpacity(0.5);

      canvas.drawLine(
        Offset(clumpX, clumpY),
        Offset(
          clumpX + math.cos(clumpAngle) * clumpLength,
          clumpY + math.sin(clumpAngle) * clumpLength,
        ),
        clumpPaint,
      );
    }

    // DEPTH SHADOWS - Inside crevices
    final crevicePaint = Paint()
      ..color = hayDark.withOpacity(0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    canvas.drawOval(
      Rect.fromCenter(center: Offset(x - 15, y + 5), width: 25, height: 12),
      crevicePaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x + 20, y + 8), width: 20, height: 10),
      crevicePaint,
    );

    // LOOSE STRANDS - Scattered around pile
    final loosePaint = Paint()
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 20; i++) {
      final looseX = x - 50 + random.nextDouble() * 100;
      final looseY = y + 15 + random.nextDouble() * 12;
      final looseLength = 5 + random.nextDouble() * 10;
      final looseAngle = random.nextDouble() * math.pi / 2;

      loosePaint.color = hayGold.withOpacity(0.6);

      canvas.drawLine(
        Offset(looseX, looseY),
        Offset(
          looseX + math.cos(looseAngle) * looseLength,
          looseY + math.sin(looseAngle) * looseLength,
        ),
        loosePaint,
      );
    }

    // HIGHLIGHTS - Natural sheen on straw
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    canvas.drawOval(
      Rect.fromCenter(center: Offset(x - 10, y - 12), width: 35, height: 15),
      highlightPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x + 15, y - 8), width: 25, height: 12),
      highlightPaint,
    );
  }

  void _drawSimpleCot(Canvas canvas, double x, double y) {
    // REALISTIC COT - Simple camping bed with wooden frame and canvas

    final woodBrown = const Color(0xFF8B4513);
    final woodDark = const Color(0xFF654321);
    final woodLight = const Color(0xFFa06535);
    final canvasTan = const Color(0xFF9A8A7A);
    final canvasDark = const Color(0xFF7A6A5A);
    final ropeBrown = const Color(0xFF6B5A4A);

    // Shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x, y + 38), width: 88, height: 15),
      shadowPaint,
    );

    // WOODEN FRAME - Isometric construction

    // Back legs (visible in 3/4 view)
    void drawCotLeg(double legX, double legY, bool isBack) {
      final legPath = Path()
        ..moveTo(legX, legY)
        ..lineTo(legX - 2, legY - 4)
        ..lineTo(legX - 2, legY + 24)
        ..lineTo(legX, legY + 28)
        ..lineTo(legX + 4, legY + 26)
        ..lineTo(legX + 4, legY - 2)
        ..close();

      canvas.drawPath(
        legPath,
        Paint()..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [woodDark, woodBrown, woodLight],
        ).createShader(Rect.fromLTWH(legX - 2, legY - 4, 6, 32)),
      );

      // Wood grain on leg
      final grainPaint = Paint()
        ..color = woodDark.withOpacity(0.4)
        ..strokeWidth = 1;
      canvas.drawLine(
        Offset(legX + 1, legY + 5),
        Offset(legX + 1, legY + 23),
        grainPaint,
      );
    }

    // Draw all 4 legs
    drawCotLeg(x - 40, y + 8, true);   // Back left
    drawCotLeg(x + 32, y + 6, true);   // Back right
    drawCotLeg(x - 42, y + 14, false); // Front left
    drawCotLeg(x + 30, y + 12, false); // Front right

    // SIDE RAILS - Wooden frame bars

    // Left rail
    final leftRail = Path()
      ..moveTo(x - 40, y + 8)
      ..lineTo(x - 42, y + 14)
      ..lineTo(x - 39, y + 16)
      ..lineTo(x - 37, y + 10)
      ..close();

    canvas.drawPath(leftRail, Paint()..color = woodBrown);

    // Right rail
    final rightRail = Path()
      ..moveTo(x + 32, y + 6)
      ..lineTo(x + 30, y + 12)
      ..lineTo(x + 33, y + 14)
      ..lineTo(x + 35, y + 8)
      ..close();

    canvas.drawPath(rightRail, Paint()..color = woodLight);

    // CANVAS/FABRIC BED SURFACE - Stretched material

    // Canvas top surface (slightly sagging in middle)
    final canvasPath = Path()
      ..moveTo(x - 38, y + 2)
      ..lineTo(x - 40, y - 2)
      ..lineTo(x + 32, y - 4)
      ..lineTo(x + 34, y)
      ..close();

    canvas.drawPath(
      canvasPath,
      Paint()..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [canvasTan, canvasDark, canvasTan],
      ).createShader(Rect.fromLTWH(x - 40, y - 4, 74, 6)),
    );

    // Canvas front face (sagging)
    final canvasFront = Path()
      ..moveTo(x - 38, y + 2)
      ..quadraticBezierTo(x - 5, y + 8, x + 34, y)
      ..lineTo(x + 34, y + 28)
      ..quadraticBezierTo(x - 5, y + 32, x - 38, y + 28)
      ..close();

    canvas.drawPath(
      canvasFront,
      Paint()..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [canvasTan, canvasDark],
      ).createShader(Rect.fromLTWH(x - 38, y, 72, 32)),
    );

    // Canvas weave texture
    final weavePaint = Paint()
      ..color = canvasDark.withOpacity(0.3)
      ..strokeWidth = 1;

    // Horizontal weave lines
    for (int i = 0; i < 12; i++) {
      canvas.drawLine(
        Offset(x - 36, y + 4 + i * 2.5),
        Offset(x + 32, y + 3 + i * 2.5),
        weavePaint,
      );
    }

    // Vertical weave lines
    for (int i = 0; i < 15; i++) {
      canvas.drawLine(
        Offset(x - 35 + i * 5, y + 5),
        Offset(x - 35 + i * 5, y + 27),
        weavePaint,
      );
    }

    // ROPE BINDINGS - Securing canvas to frame
    final ropePaint = Paint()
      ..color = ropeBrown
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    // Rope wraps on sides
    for (int i = 0; i < 6; i++) {
      final ropeY = y + 6 + i * 4;

      // Left side ropes
      canvas.drawLine(
        Offset(x - 38, ropeY),
        Offset(x - 41, ropeY + 2),
        ropePaint,
      );

      // Right side ropes
      canvas.drawLine(
        Offset(x + 34, ropeY - 1),
        Offset(x + 31, ropeY + 1),
        ropePaint,
      );
    }

    // WEAR AND TEAR - Realistic used appearance

    // Wrinkles in canvas
    final wrinklePaint = Paint()
      ..color = canvasDark.withOpacity(0.4)
      ..strokeWidth = 1.5;

    canvas.drawLine(Offset(x - 20, y + 10), Offset(x - 10, y + 18), wrinklePaint);
    canvas.drawLine(Offset(x + 5, y + 12), Offset(x + 15, y + 20), wrinklePaint);

    // Stains/dirt patches
    final stainPaint = Paint()..color = const Color(0xFF5a4a3a).withOpacity(0.3);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x - 8, y + 15), width: 15, height: 10),
      stainPaint,
    );

    // Fabric highlights (worn shiny spots)
    final shinePaint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    canvas.drawOval(
      Rect.fromCenter(center: Offset(x - 10, y + 10), width: 25, height: 12),
      shinePaint,
    );
  }

  void _drawWoodBed(Canvas canvas, double x, double y) {
    // REALISTIC ISOMETRIC BED - 3/4 view perspective

    final woodBrown = const Color(0xFF6B4423);
    final woodDark = const Color(0xFF4a2f1a);
    final woodLight = const Color(0xFF8B5A3C);
    final fabricBeige = const Color(0xFF8B7B6B);
    final fabricDark = const Color(0xFF6B5B4B);
    final fabricLight = const Color(0xFFAB9B8B);

    // Realistic shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x + 5, y + 55), width: 95, height: 22),
      shadowPaint,
    );

    // BED FRAME - Isometric view from front-right angle

    // Back legs (visible in 3/4 view)
    void drawLeg(double legX, double legY, bool isBack) {
      final legPath = Path()
        ..moveTo(legX, legY)              // Top front
        ..lineTo(legX - 3, legY - 6)      // Top back (isometric)
        ..lineTo(legX - 3, legY + 22)     // Bottom back
        ..lineTo(legX, legY + 28)         // Bottom front
        ..lineTo(legX + 5, legY + 26)     // Bottom right
        ..lineTo(legX + 5, legY)          // Top right
        ..close();

      // Leg gradient for 3D depth
      canvas.drawPath(
        legPath,
        Paint()..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [woodDark, woodBrown, woodLight],
        ).createShader(Rect.fromLTWH(legX - 3, legY, 8, 28)),
      );

      // Wood grain on leg
      final grainPaint = Paint()
        ..color = woodDark.withOpacity(0.3)
        ..strokeWidth = 1;
      for (int i = 0; i < 3; i++) {
        canvas.drawLine(
          Offset(legX + 1, legY + 5 + i * 8),
          Offset(legX + 4, legY + 5 + i * 8),
          grainPaint,
        );
      }
    }

    // Draw all 4 legs in isometric view
    drawLeg(x - 35, y + 30, true);   // Back left
    drawLeg(x + 28, y + 28, true);   // Back right
    drawLeg(x - 38, y + 38, false);  // Front left
    drawLeg(x + 25, y + 36, false);  // Front right

    // HEADBOARD - Tall wooden panel with realistic thickness
    final headboardPath = Path()
      ..moveTo(x - 40, y - 20)          // Front top left
      ..lineTo(x - 43, y - 26)          // Back top left (isometric)
      ..lineTo(x + 35, y - 28)          // Back top right
      ..lineTo(x + 38, y - 22)          // Front top right
      ..lineTo(x + 38, y + 25)          // Front bottom right
      ..lineTo(x + 35, y + 23)          // Back bottom right
      ..lineTo(x - 43, y + 21)          // Back bottom left
      ..lineTo(x - 40, y + 23)          // Front bottom left
      ..close();

    // Headboard front face
    canvas.drawPath(
      headboardPath,
      Paint()..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [woodDark, woodBrown, woodLight, woodBrown],
      ).createShader(Rect.fromLTWH(x - 43, y - 26, 81, 51)),
    );

    // Headboard top edge (visible thickness)
    final headboardTop = Path()
      ..moveTo(x - 40, y - 20)
      ..lineTo(x - 43, y - 26)
      ..lineTo(x + 35, y - 28)
      ..lineTo(x + 38, y - 22)
      ..close();
    canvas.drawPath(headboardTop, Paint()..color = woodLight);

    // Headboard side edge
    final headboardSide = Path()
      ..moveTo(x + 38, y - 22)
      ..lineTo(x + 35, y - 28)
      ..lineTo(x + 35, y + 23)
      ..lineTo(x + 38, y + 25)
      ..close();
    canvas.drawPath(headboardSide, Paint()..color = woodBrown);

    // Wood grain on headboard
    final headboardGrain = Paint()
      ..color = woodDark.withOpacity(0.25)
      ..strokeWidth = 1.5;
    for (int i = 0; i < 8; i++) {
      canvas.drawLine(
        Offset(x - 38, y - 18 + i * 6),
        Offset(x + 32, y - 16 + i * 6),
        headboardGrain,
      );
    }

    // MATTRESS - Realistic fabric with folds and seams

    // Mattress top surface (isometric)
    final mattressTop = Path()
      ..moveTo(x - 35, y + 5)           // Front left
      ..lineTo(x - 38, y + 1)           // Back left
      ..lineTo(x + 30, y - 1)           // Back right
      ..lineTo(x + 33, y + 3)           // Front right
      ..close();

    canvas.drawPath(
      mattressTop,
      Paint()..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [fabricLight, fabricBeige, fabricBeige],
      ).createShader(Rect.fromLTWH(x - 38, y - 1, 71, 6)),
    );

    // Mattress front face
    final mattressFront = Path()
      ..moveTo(x - 35, y + 5)
      ..lineTo(x + 33, y + 3)
      ..lineTo(x + 33, y + 30)
      ..lineTo(x - 35, y + 32)
      ..close();

    canvas.drawPath(
      mattressFront,
      Paint()..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [fabricBeige, fabricDark],
      ).createShader(Rect.fromLTWH(x - 35, y + 3, 68, 29)),
    );

    // Mattress side face
    final mattressSide = Path()
      ..moveTo(x + 33, y + 3)
      ..lineTo(x + 30, y - 1)
      ..lineTo(x + 30, y + 26)
      ..lineTo(x + 33, y + 30)
      ..close();

    canvas.drawPath(
      mattressSide,
      Paint()..color = fabricDark,
    );

    // Realistic quilted stitching pattern
    final stitchPaint = Paint()
      ..color = fabricDark.withOpacity(0.5)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Horizontal stitching lines
    for (int i = 0; i < 4; i++) {
      final stitchY = y + 10 + i * 7;
      canvas.drawLine(
        Offset(x - 32, stitchY),
        Offset(x + 30, stitchY - 1),
        stitchPaint,
      );
    }

    // Vertical stitching lines
    for (int i = 0; i < 5; i++) {
      final stitchX = x - 28 + i * 14;
      canvas.drawLine(
        Offset(stitchX, y + 8),
        Offset(stitchX + 2, y + 28),
        stitchPaint,
      );
    }

    // Fabric seam along edge
    final seamPaint = Paint()
      ..color = fabricDark
      ..strokeWidth = 2;
    canvas.drawLine(Offset(x - 35, y + 5), Offset(x + 33, y + 3), seamPaint);

    // PILLOW - Realistic with fabric folds
    final pillowPath = Path()
      ..moveTo(x - 25, y + 8)
      ..quadraticBezierTo(x - 22, y + 2, x - 10, y + 3)
      ..quadraticBezierTo(x + 2, y + 2, x + 5, y + 8)
      ..quadraticBezierTo(x + 3, y + 15, x - 8, y + 16)
      ..quadraticBezierTo(x - 20, y + 15, x - 25, y + 8)
      ..close();

    canvas.drawPath(
      pillowPath,
      Paint()..shader = RadialGradient(
        center: Alignment.topCenter,
        radius: 0.9,
        colors: [const Color(0xFFCBBBAB), const Color(0xFFAB9B8B)],
      ).createShader(Rect.fromLTWH(x - 25, y + 2, 30, 14)),
    );

    // Pillow fold detail
    final foldPaint = Paint()
      ..color = const Color(0xFF8B7B6B).withOpacity(0.4)
      ..strokeWidth = 1.5;
    canvas.drawLine(Offset(x - 20, y + 10), Offset(x, y + 11), foldPaint);

    // Subtle fabric highlights
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.08)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x - 8, y + 12), width: 35, height: 12),
      highlightPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x - 12, y + 6), width: 18, height: 8),
      highlightPaint,
    );
  }

  // ─────────────── DESKS ───────────────

  void _drawRockDesk(Canvas canvas, double x, double y) {
    // REALISTIC STONE DESK - Primitive stone slab on rock pillars

    final rockLight = const Color(0xFF909090);
    final rockMid = const Color(0xFF707070);
    final rockDark = const Color(0xFF484848);
    final rockBlack = const Color(0xFF2a2a2a);

    // Shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x, y + 54), width: 105, height: 18),
      shadowPaint,
    );

    // STONE SUPPORT PILLARS - Irregular natural rocks

    void drawStonePillar(double pillarX, bool isLeft) {
      final random = math.Random(isLeft ? 100 : 200);

      // Pillar body (irregular shape)
      final pillarPath = Path()
        ..moveTo(pillarX - 8, y + 12)
        ..lineTo(pillarX - 10 + random.nextDouble() * 2, y + 8)
        ..lineTo(pillarX - 7 + random.nextDouble() * 2, y - 2)
        ..lineTo(pillarX + 8, y)
        ..lineTo(pillarX + 10 - random.nextDouble() * 2, y + 10)
        ..lineTo(pillarX + 7, y + 50)
        ..lineTo(pillarX - 6, y + 50)
        ..close();

      canvas.drawPath(
        pillarPath,
        Paint()..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [rockBlack, rockDark, rockMid, rockLight],
        ).createShader(Rect.fromLTWH(pillarX - 10, y, 20, 50)),
      );

      // Rock cracks and fissures
      final crackPaint = Paint()
        ..color = rockBlack
        ..strokeWidth = 1.5 + random.nextDouble()
        ..style = PaintingStyle.stroke;

      for (int i = 0; i < 5; i++) {
        final crackStart = Offset(
          pillarX - 6 + random.nextDouble() * 12,
          y + 5 + random.nextDouble() * 35,
        );
        final crackPath = Path()..moveTo(crackStart.dx, crackStart.dy);

        for (int j = 0; j < 3; j++) {
          crackPath.lineTo(
            crackStart.dx + (random.nextDouble() - 0.5) * 8,
            crackStart.dy + 5 + random.nextDouble() * 8,
          );
        }

        canvas.drawPath(crackPath, crackPaint);
      }

      // Stone texture (small dots and chips)
      final texturePaint = Paint()..color = rockDark;
      for (int i = 0; i < 15; i++) {
        canvas.drawCircle(
          Offset(
            pillarX - 6 + random.nextDouble() * 12,
            y + 5 + random.nextDouble() * 42,
          ),
          random.nextDouble() * 1.5,
          texturePaint,
        );
      }

      // Highlights on rock surface
      final highlightPaint = Paint()
        ..color = rockLight.withOpacity(0.4);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(pillarX + 4, y + 15 + random.nextDouble() * 10),
          width: 6,
          height: 10,
        ),
        highlightPaint,
      );
    }

    // Draw both support pillars
    drawStonePillar(x - 42, true);
    drawStonePillar(x + 38, false);

    // STONE DESKTOP SLAB - Heavy flat rock

    final random = math.Random(300);

    // Slab top surface (irregular shape)
    final slabTop = Path()
      ..moveTo(x - 52, y - 4)
      ..lineTo(x - 50 + random.nextDouble() * 2, y - 10)
      ..lineTo(x - 20 + random.nextDouble() * 3, y - 12)
      ..lineTo(x + 10, y - 13)
      ..lineTo(x + 40 - random.nextDouble() * 2, y - 11)
      ..lineTo(x + 50, y - 6)
      ..lineTo(x + 48, y - 2)
      ..lineTo(x - 50, y)
      ..close();

    canvas.drawPath(
      slabTop,
      Paint()..shader = RadialGradient(
        center: Alignment.topLeft,
        radius: 1.3,
        colors: [rockLight, rockMid, rockDark],
      ).createShader(Rect.fromLTWH(x - 52, y - 13, 102, 13)),
    );

    // Slab front edge (thick stone)
    final slabFront = Path()
      ..moveTo(x - 52, y - 4)
      ..lineTo(x + 50, y - 6)
      ..lineTo(x + 48, y + 8)
      ..lineTo(x - 50, y + 10)
      ..close();

    canvas.drawPath(
      slabFront,
      Paint()..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [rockMid, rockDark, rockBlack],
      ).createShader(Rect.fromLTWH(x - 52, y - 6, 102, 16)),
    );

    // Slab right edge
    final slabSide = Path()
      ..moveTo(x + 50, y - 6)
      ..lineTo(x + 48, y - 10)
      ..lineTo(x + 46, y + 4)
      ..lineTo(x + 48, y + 8)
      ..close();

    canvas.drawPath(slabSide, Paint()..color = rockDark);

    // NATURAL STONE DETAILS

    // Deep cracks in desktop slab
    final slabCrackPaint = Paint()
      ..color = rockBlack
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 8; i++) {
      final crackStart = Offset(
        x - 45 + random.nextDouble() * 90,
        y - 10 + random.nextDouble() * 5,
      );
      final crackPath = Path()..moveTo(crackStart.dx, crackStart.dy);

      for (int j = 0; j < 2; j++) {
        crackPath.lineTo(
          crackStart.dx + (random.nextDouble() - 0.5) * 15,
          crackStart.dy + random.nextDouble() * 8,
        );
      }

      canvas.drawPath(crackPath, slabCrackPaint);
    }

    // Chipped edges
    final chipPaint = Paint()..color = rockDark;
    for (int i = 0; i < 6; i++) {
      final chipX = x - 48 + random.nextDouble() * 96;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(chipX, y - 3),
          width: 3 + random.nextDouble() * 4,
          height: 2 + random.nextDouble() * 2,
        ),
        chipPaint,
      );
    }

    // Stone grain and sediment layers
    final layerPaint = Paint()
      ..color = rockMid.withOpacity(0.3)
      ..strokeWidth = 1;

    for (int i = 0; i < 5; i++) {
      canvas.drawLine(
        Offset(x - 48, y - 8 + i * 3),
        Offset(x + 46, y - 9 + i * 3),
        layerPaint,
      );
    }

    // Pitting and weathering on surface
    final pitPaint = Paint()..color = rockBlack.withOpacity(0.5);
    for (int i = 0; i < 20; i++) {
      canvas.drawCircle(
        Offset(
          x - 45 + random.nextDouble() * 90,
          y - 10 + random.nextDouble() * 8,
        ),
        random.nextDouble() * 2,
        pitPaint,
      );
    }

    // Moss/lichen growth in crevices
    final mossPaint = Paint()..color = const Color(0xFF2a3a2a).withOpacity(0.6);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x - 30, y - 2), width: 8, height: 5),
      mossPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x + 25, y), width: 6, height: 4),
      mossPaint,
    );

    // Natural highlights on stone
    final stoneShinePaint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    canvas.drawOval(
      Rect.fromCenter(center: Offset(x - 15, y - 9), width: 40, height: 12),
      stoneShinePaint,
    );
  }

  void _drawWoodenDesk(Canvas canvas, double x, double y) {
    // REALISTIC WOODEN DESK - Simple carpentry with visible construction

    final woodBrown = const Color(0xFF8B4513);
    final woodMid = const Color(0xFF6B4513);
    final woodDark = const Color(0xFF4a2f1a);
    final woodLight = const Color(0xFFa06535);

    // Shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x, y + 50), width: 100, height: 16),
      shadowPaint,
    );

    // DESK LEGS - Simple square legs with isometric view

    void drawSimpleLeg(double legX, double legY) {
      // Leg front face
      final legFront = Path()
        ..moveTo(legX, legY)
        ..lineTo(legX, legY + 40)
        ..lineTo(legX + 8, legY + 38)
        ..lineTo(legX + 8, legY - 2)
        ..close();

      canvas.drawPath(
        legFront,
        Paint()..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [woodDark, woodMid, woodBrown],
        ).createShader(Rect.fromLTWH(legX, legY, 8, 40)),
      );

      // Leg side face
      final legSide = Path()
        ..moveTo(legX + 8, legY - 2)
        ..lineTo(legX + 5, legY - 6)
        ..lineTo(legX + 5, legY + 34)
        ..lineTo(legX + 8, legY + 38)
        ..close();

      canvas.drawPath(legSide, Paint()..color = woodLight);

      // Wood grain on leg (vertical)
      final grainPaint = Paint()
        ..color = woodDark.withOpacity(0.35)
        ..strokeWidth = 1.2;

      for (int i = 0; i < 6; i++) {
        canvas.drawLine(
          Offset(legX + 2, legY + 2 + i * 6),
          Offset(legX + 2, legY + 8 + i * 6),
          grainPaint,
        );
      }

      // Wood knot on leg
      if (legX < x) {
        canvas.drawCircle(
          Offset(legX + 4, legY + 18),
          2,
          Paint()..color = woodDark.withOpacity(0.7),
        );
      }
    }

    // Draw all 4 legs
    drawSimpleLeg(x - 45, y + 8);  // Back left
    drawSimpleLeg(x + 35, y + 6);  // Back right
    drawSimpleLeg(x - 47, y + 14); // Front left
    drawSimpleLeg(x + 33, y + 12); // Front right

    // DESKTOP - Wooden planks joined together

    // Desktop top surface
    final desktopTop = Path()
      ..moveTo(x - 50, y - 6)
      ..lineTo(x + 48, y - 8)
      ..lineTo(x + 45, y - 13)
      ..lineTo(x - 53, y - 11)
      ..close();

    canvas.drawPath(
      desktopTop,
      Paint()..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [woodLight, woodBrown, woodMid],
      ).createShader(Rect.fromLTWH(x - 53, y - 13, 101, 7)),
    );

    // Desktop front edge
    final desktopFront = Path()
      ..moveTo(x - 50, y - 6)
      ..lineTo(x + 48, y - 8)
      ..lineTo(x + 48, y + 6)
      ..lineTo(x - 50, y + 8)
      ..close();

    canvas.drawPath(
      desktopFront,
      Paint()..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [woodBrown, woodDark],
      ).createShader(Rect.fromLTWH(x - 50, y - 8, 98, 16)),
    );

    // Desktop side edge
    final desktopSide = Path()
      ..moveTo(x + 48, y - 8)
      ..lineTo(x + 45, y - 13)
      ..lineTo(x + 45, y + 1)
      ..lineTo(x + 48, y + 6)
      ..close();

    canvas.drawPath(desktopSide, Paint()..color = woodLight);

    // WOOD GRAIN DETAILS - Natural wood texture

    final topGrainPaint = Paint()
      ..color = woodDark.withOpacity(0.25)
      ..strokeWidth = 1.5;

    final random = math.Random(400);

    // Long grain lines (direction of wood growth)
    for (int i = 0; i < 15; i++) {
      final startX = x - 48 + i * 7;
      final variation = random.nextDouble() * 3 - 1.5;

      canvas.drawLine(
        Offset(startX, y - 10 + variation),
        Offset(startX + 2, y - 4 + variation),
        topGrainPaint,
      );
    }

    // Plank seams (where boards join)
    final seamPaint = Paint()
      ..color = woodDark.withOpacity(0.4)
      ..strokeWidth = 1.5;

    canvas.drawLine(Offset(x - 15, y - 11), Offset(x - 15, y + 6), seamPaint);
    canvas.drawLine(Offset(x + 18, y - 12), Offset(x + 18, y + 5), seamPaint);

    // Wood knots and imperfections
    final knotPaint = Paint()..color = woodDark.withOpacity(0.7);

    // Large knot
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x - 28, y - 8), width: 6, height: 4),
      knotPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x - 28, y - 8), width: 3, height: 2),
      Paint()..color = woodDark,
    );

    // Small knots
    canvas.drawCircle(Offset(x + 25, y - 9), 2, knotPaint);
    canvas.drawCircle(Offset(x + 5, y - 7), 1.5, knotPaint);

    // Scratches and wear marks
    final scratchPaint = Paint()
      ..color = woodLight.withOpacity(0.4)
      ..strokeWidth = 1;

    canvas.drawLine(Offset(x - 20, y - 9), Offset(x - 8, y - 10), scratchPaint);
    canvas.drawLine(Offset(x + 10, y - 10), Offset(x + 25, y - 11), scratchPaint);

    // Edge beveling (rounded corner detail)
    final bevelPaint = Paint()
      ..color = woodLight
      ..strokeWidth = 1.5;

    canvas.drawLine(Offset(x - 50, y - 6), Offset(x + 48, y - 8), bevelPaint);

    // Natural wood highlights
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

    canvas.drawOval(
      Rect.fromCenter(center: Offset(x - 15, y - 10), width: 50, height: 10),
      highlightPaint,
    );

    // Dust/grime in corners
    final grimePaint = Paint()
      ..color = const Color(0xFF3a2a1a).withOpacity(0.3);

    canvas.drawOval(
      Rect.fromCenter(center: Offset(x - 46, y + 4), width: 8, height: 5),
      grimePaint,
    );
  }

  void _drawSturdyDesk(Canvas canvas, double x, double y) {
    // REALISTIC ISOMETRIC DESK - Professional construction

    final woodBrown = const Color(0xFF6B4423);
    final woodDark = const Color(0xFF4a2f1a);
    final woodLight = const Color(0xFF8B5A3C);
    final metalGray = const Color(0xFF5a5a5a);
    final metalDark = const Color(0xFF3a3a3a);

    // Realistic shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.45)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x + 3, y + 58), width: 110, height: 20),
      shadowPaint,
    );

    // DESK LEGS - Isometric view with realistic construction

    void drawRealisticLeg(double legX, double legY, bool isBack) {
      // Leg has 3 visible faces in isometric view

      // Front face
      final frontFace = Path()
        ..moveTo(legX, legY)
        ..lineTo(legX, legY + 42)
        ..lineTo(legX + 10, legY + 40)
        ..lineTo(legX + 10, legY - 2)
        ..close();

      canvas.drawPath(
        frontFace,
        Paint()..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [woodDark, woodBrown],
        ).createShader(Rect.fromLTWH(legX, legY, 10, 42)),
      );

      // Side face (isometric)
      final sideFace = Path()
        ..moveTo(legX + 10, legY - 2)
        ..lineTo(legX + 7, legY - 7)
        ..lineTo(legX + 7, legY + 35)
        ..lineTo(legX + 10, legY + 40)
        ..close();

      canvas.drawPath(sideFace, Paint()..color = woodLight);

      // Top face
      final topFace = Path()
        ..moveTo(legX, legY)
        ..lineTo(legX + 10, legY - 2)
        ..lineTo(legX + 7, legY - 7)
        ..lineTo(legX - 3, legY - 5)
        ..close();

      canvas.drawPath(topFace, Paint()..color = woodLight);

      // Wood grain detail
      final grainPaint = Paint()
        ..color = woodDark.withOpacity(0.3)
        ..strokeWidth = 1;

      for (int i = 0; i < 5; i++) {
        canvas.drawLine(
          Offset(legX + 2, legY + 5 + i * 8),
          Offset(legX + 8, legY + 4 + i * 8),
          grainPaint,
        );
      }
    }

    // Draw all 4 legs
    drawRealisticLeg(x - 48, y + 16, true);   // Back left
    drawRealisticLeg(x + 30, y + 14, true);   // Back right
    drawRealisticLeg(x - 50, y + 22, false);  // Front left
    drawRealisticLeg(x + 28, y + 20, false);  // Front right

    // DESK TOP - Thick wooden surface with beveled edges

    // Desktop top surface (isometric view)
    final desktopTop = Path()
      ..moveTo(x - 52, y - 6)           // Front left
      ..lineTo(x + 50, y - 8)           // Front right
      ..lineTo(x + 47, y - 14)          // Back right
      ..lineTo(x - 55, y - 12)          // Back left
      ..close();

    canvas.drawPath(
      desktopTop,
      Paint()..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [woodLight, woodBrown, woodBrown],
      ).createShader(Rect.fromLTWH(x - 55, y - 14, 105, 8)),
    );

    // Wood grain on desktop
    final topGrainPaint = Paint()
      ..color = woodDark.withOpacity(0.2)
      ..strokeWidth = 1.5;

    for (int i = 0; i < 12; i++) {
      canvas.drawLine(
        Offset(x - 50 + i * 9, y - 11),
        Offset(x - 48 + i * 9, y - 7),
        topGrainPaint,
      );
    }

    // Wood knots
    canvas.drawCircle(Offset(x - 20, y - 9), 2.5, Paint()..color = woodDark.withOpacity(0.6));
    canvas.drawCircle(Offset(x + 25, y - 10), 2, Paint()..color = woodDark.withOpacity(0.5));

    // Desktop front edge (thick panel)
    final desktopFront = Path()
      ..moveTo(x - 52, y - 6)
      ..lineTo(x + 50, y - 8)
      ..lineTo(x + 50, y + 10)
      ..lineTo(x - 52, y + 12)
      ..close();

    canvas.drawPath(
      desktopFront,
      Paint()..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [woodBrown, woodDark],
      ).createShader(Rect.fromLTWH(x - 52, y - 8, 102, 20)),
    );

    // Desktop right edge
    final desktopSide = Path()
      ..moveTo(x + 50, y - 8)
      ..lineTo(x + 47, y - 14)
      ..lineTo(x + 47, y + 4)
      ..lineTo(x + 50, y + 10)
      ..close();

    canvas.drawPath(desktopSide, Paint()..color = woodLight);

    // Beveled edge detail
    final bevelPaint = Paint()
      ..color = woodLight
      ..strokeWidth = 2;
    canvas.drawLine(Offset(x - 52, y - 6), Offset(x + 50, y - 8), bevelPaint);

    // DRAWER - Realistic drawer with handle
    final drawerFront = Path()
      ..moveTo(x - 15, y + 2)
      ..lineTo(x + 25, y + 1)
      ..lineTo(x + 25, y + 14)
      ..lineTo(x - 15, y + 15)
      ..close();

    // Drawer inset (recessed panel)
    canvas.drawPath(
      drawerFront,
      Paint()..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [woodBrown, woodDark, woodBrown],
      ).createShader(Rect.fromLTWH(x - 15, y + 1, 40, 14)),
    );

    // Drawer panel border
    final panelBorder = Paint()
      ..color = woodDark
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawRect(
      Rect.fromLTWH(x - 13, y + 3, 36, 10),
      panelBorder,
    );

    // Metal drawer handle
    final handlePath = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(x + 5, y + 8), width: 14, height: 4),
        const Radius.circular(2),
      ));

    canvas.drawPath(
      handlePath,
      Paint()..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [metalGray, metalDark],
      ).createShader(Rect.fromCenter(center: Offset(x + 5, y + 8), width: 14, height: 4)),
    );

    // Handle shine
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(x + 5, y + 7), width: 10, height: 1.5),
        const Radius.circular(0.5),
      ),
      Paint()..color = Colors.white.withOpacity(0.4),
    );

    // SUPPORT BEAM - Structural cross-brace
    final beamPath = Path()
      ..moveTo(x - 45, y + 32)
      ..lineTo(x + 43, y + 31)
      ..lineTo(x + 43, y + 38)
      ..lineTo(x - 45, y + 39)
      ..close();

    canvas.drawPath(
      beamPath,
      Paint()..color = woodDark,
    );

    // Beam top edge
    final beamTop = Path()
      ..moveTo(x - 45, y + 32)
      ..lineTo(x + 43, y + 31)
      ..lineTo(x + 40, y + 28)
      ..lineTo(x - 48, y + 29)
      ..close();

    canvas.drawPath(beamTop, Paint()..color = woodBrown);

    // Wood screws in beam (visible construction)
    final screwPaint = Paint()..color = metalDark;
    canvas.drawCircle(Offset(x - 35, y + 35), 1.5, screwPaint);
    canvas.drawCircle(Offset(x, y + 34), 1.5, screwPaint);
    canvas.drawCircle(Offset(x + 33, y + 34), 1.5, screwPaint);

    // Screw slots
    final slotPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 0.8;
    canvas.drawLine(Offset(x - 36, y + 35), Offset(x - 34, y + 35), slotPaint);
    canvas.drawLine(Offset(x - 1, y + 34), Offset(x + 1, y + 34), slotPaint);

    // Realistic wear marks on desktop
    final wearPaint = Paint()
      ..color = woodLight.withOpacity(0.3)
      ..strokeWidth = 1;

    canvas.drawLine(Offset(x - 20, y - 8), Offset(x - 5, y - 9), wearPaint);
    canvas.drawLine(Offset(x + 10, y - 9), Offset(x + 30, y - 10), wearPaint);

    // Subtle highlight on top edge
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x - 10, y - 11), width: 60, height: 8),
      highlightPaint,
    );
  }

  // ─────────────── CHAIRS ───────────────

  void _drawTreeStump(Canvas canvas, double x, double y) {
    // REALISTIC TREE STUMP - Natural wood with bark and growth rings

    final barkDark = const Color(0xFF3a2010);
    final barkMid = const Color(0xFF4a3020);
    final barkLight = const Color(0xFF5a4030);
    final woodBrown = const Color(0xFF8B6F47);
    final woodLight = const Color(0xFFA58A5C);
    final woodDark = const Color(0xFF6B4F27);
    final ringDark = const Color(0xFF4a3522);

    // Shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x, y + 35), width: 58, height: 14),
      shadowPaint,
    );

    // STUMP BODY - Isometric cylinder view

    // Bottom ellipse (ground level)
    final bottomEllipse = Path()
      ..addOval(Rect.fromCenter(center: Offset(x, y + 30), width: 54, height: 16));

    canvas.drawPath(
      bottomEllipse,
      Paint()..shader = RadialGradient(
        center: Alignment.center,
        radius: 0.9,
        colors: [barkMid, barkDark],
      ).createShader(Rect.fromCenter(center: Offset(x, y + 30), width: 54, height: 16)),
    );

    // Stump sides (curved surface with bark texture)
    final stumpSides = Path()
      ..moveTo(x - 27, y + 30)
      ..lineTo(x - 25, y - 15)
      ..quadraticBezierTo(x, y - 18, x + 25, y - 15)
      ..lineTo(x + 27, y + 30)
      ..close();

    canvas.drawPath(
      stumpSides,
      Paint()..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [barkDark, barkMid, barkLight, barkMid, barkDark],
      ).createShader(Rect.fromCenter(center: Offset(x, y + 8), width: 54, height: 48)),
    );

    // Realistic bark texture (vertical grooves and cracks)
    final barkPaint = Paint()
      ..color = barkDark
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final random = math.Random(42);

    // Deep vertical bark cracks
    for (int i = 0; i < 8; i++) {
      final crackX = x - 24 + i * 6;
      final crackDepth = random.nextDouble() * 5 + 2;

      final crackPath = Path()
        ..moveTo(crackX, y - 12 + random.nextDouble() * 5)
        ..lineTo(crackX + crackDepth * 0.5, y + random.nextDouble() * 10)
        ..lineTo(crackX - crackDepth * 0.3, y + 15 + random.nextDouble() * 8)
        ..lineTo(crackX + crackDepth * 0.2, y + 28);

      canvas.drawPath(crackPath, barkPaint);
    }

    // Bark ridges and bumps
    final ridgePaint = Paint()
      ..color = barkLight.withOpacity(0.6)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 6; i++) {
      final ridgeX = x - 20 + i * 7;
      canvas.drawLine(
        Offset(ridgeX, y - 8 + random.nextDouble() * 4),
        Offset(ridgeX + 2, y + 10 + random.nextDouble() * 15),
        ridgePaint,
      );
    }

    // Moss patches on bark
    final mossPaint = Paint()..color = const Color(0xFF2a4a2a).withOpacity(0.7);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x - 18, y + 10), width: 12, height: 8),
      mossPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x + 15, y + 5), width: 10, height: 7),
      mossPaint,
    );

    // TOP CUT SURFACE - Realistic wood grain and growth rings

    final topSurface = Path()
      ..addOval(Rect.fromCenter(center: Offset(x, y - 15), width: 50, height: 15));

    canvas.drawPath(
      topSurface,
      Paint()..shader = RadialGradient(
        center: Alignment.topLeft,
        radius: 1.2,
        colors: [woodLight, woodBrown, woodDark],
      ).createShader(Rect.fromCenter(center: Offset(x, y - 15), width: 50, height: 15)),
    );

    // Growth rings (concentric circles - tree's age)
    final ringCenter = Offset(x - 2, y - 16); // Slightly off-center (natural)

    final ringPaint = Paint()
      ..color = ringDark.withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Multiple growth rings
    final ringRadii = [22.0, 18.0, 14.0, 10.0, 6.0, 3.0];
    for (var radius in ringRadii) {
      canvas.drawOval(
        Rect.fromCenter(center: ringCenter, width: radius * 2, height: radius * 0.6),
        ringPaint,
      );
    }

    // Darker inner rings (denser wood)
    final darkRingPaint = Paint()
      ..color = ringDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawOval(
      Rect.fromCenter(center: ringCenter, width: 12, height: 7),
      darkRingPaint,
    );

    // Center heartwood
    canvas.drawOval(
      Rect.fromCenter(center: ringCenter, width: 4, height: 2.5),
      Paint()..color = barkDark,
    );

    // Radial wood grain lines (from center outward)
    final grainPaint = Paint()
      ..color = woodDark.withOpacity(0.4)
      ..strokeWidth = 1;

    for (int i = 0; i < 12; i++) {
      final angle = (i * math.pi * 2) / 12 + random.nextDouble() * 0.3;
      final startDist = 4 + random.nextDouble() * 3;
      final endDist = 20 + random.nextDouble() * 5;

      canvas.drawLine(
        Offset(
          ringCenter.dx + math.cos(angle) * startDist,
          ringCenter.dy + math.sin(angle) * startDist * 0.6,
        ),
        Offset(
          ringCenter.dx + math.cos(angle) * endDist,
          ringCenter.dy + math.sin(angle) * endDist * 0.6,
        ),
        grainPaint,
      );
    }

    // Wood knots and imperfections
    final knotPaint = Paint()..color = barkDark.withOpacity(0.8);

    // Large knot
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x + 12, y - 14), width: 6, height: 4),
      knotPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x + 12, y - 14), width: 3, height: 2),
      Paint()..color = barkDark,
    );

    // Small knot
    canvas.drawCircle(Offset(x - 10, y - 17), 2, knotPaint);

    // Saw cut marks (irregular surface)
    final sawPaint = Paint()
      ..color = woodDark.withOpacity(0.3)
      ..strokeWidth = 0.8;

    for (int i = 0; i < 8; i++) {
      final sawY = y - 18 + random.nextDouble() * 2;
      canvas.drawLine(
        Offset(x - 22, sawY),
        Offset(x + 20, sawY),
        sawPaint,
      );
    }

    // Highlight on top surface (natural wood sheen)
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x - 8, y - 18), width: 20, height: 8),
      highlightPaint,
    );

    // Woodchips at base
    final chipPaint = Paint()..color = woodLight.withOpacity(0.6);
    for (int i = 0; i < 5; i++) {
      final chipX = x - 15 + random.nextDouble() * 30;
      final chipY = y + 28 + random.nextDouble() * 4;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(chipX, chipY),
          width: 3 + random.nextDouble() * 2,
          height: 2,
        ),
        chipPaint,
      );
    }
  }

  void _drawWoodenChair(Canvas canvas, double x, double y) {
    // REALISTIC WOODEN CHAIR - Simple carpentry with backrest

    final woodBrown = const Color(0xFF8B4513);
    final woodDark = const Color(0xFF654321);
    final woodLight = const Color(0xFFa06535);

    // Shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.38)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x, y + 50), width: 52, height: 12),
      shadowPaint,
    );

    // BACKREST - Wooden frame with vertical slats

    // Back frame posts (isometric view)
    void drawBackPost(double postX) {
      final postPath = Path()
        ..moveTo(postX, y - 38)
        ..lineTo(postX - 2, y - 42)
        ..lineTo(postX - 2, y - 2)
        ..lineTo(postX, y)
        ..lineTo(postX + 3, y - 2)
        ..lineTo(postX + 3, y - 40)
        ..close();

      canvas.drawPath(
        postPath,
        Paint()..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [woodDark, woodBrown, woodLight],
        ).createShader(Rect.fromLTWH(postX - 2, y - 42, 5, 42)),
      );
    }

    drawBackPost(x - 20);
    drawBackPost(x + 17);

    // Top rail of backrest
    final topRail = Path()
      ..moveTo(x - 20, y - 38)
      ..lineTo(x - 22, y - 42)
      ..lineTo(x + 15, y - 44)
      ..lineTo(x + 17, y - 40)
      ..close();

    canvas.drawPath(topRail, Paint()..color = woodLight);

    // Vertical slats (3 slats in backrest)
    for (int i = 0; i < 3; i++) {
      final slatX = x - 14 + i * 14;

      final slatPath = Path()
        ..moveTo(slatX, y - 35)
        ..lineTo(slatX - 1, y - 38)
        ..lineTo(slatX - 1, y - 8)
        ..lineTo(slatX, y - 6)
        ..lineTo(slatX + 4, y - 7)
        ..lineTo(slatX + 4, y - 36)
        ..close();

      canvas.drawPath(
        slatPath,
        Paint()..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [woodDark, woodBrown],
        ).createShader(Rect.fromLTWH(slatX - 1, y - 38, 5, 32)),
      );

      // Wood grain on slat
      final slatGrain = Paint()
        ..color = woodDark.withOpacity(0.4)
        ..strokeWidth = 0.8;

      canvas.drawLine(
        Offset(slatX + 2, y - 33),
        Offset(slatX + 2, y - 10),
        slatGrain,
      );
    }

    // SEAT - Wooden plank seat

    // Seat top surface
    final seatTop = Path()
      ..moveTo(x - 24, y + 2)
      ..lineTo(x - 26, y - 2)
      ..lineTo(x + 20, y - 4)
      ..lineTo(x + 22, y)
      ..close();

    canvas.drawPath(
      seatTop,
      Paint()..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [woodLight, woodBrown],
      ).createShader(Rect.fromLTWH(x - 26, y - 4, 48, 6)),
    );

    // Seat front face
    final seatFront = Path()
      ..moveTo(x - 24, y + 2)
      ..lineTo(x + 22, y)
      ..lineTo(x + 22, y + 8)
      ..lineTo(x - 24, y + 10)
      ..close();

    canvas.drawPath(
      seatFront,
      Paint()..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [woodBrown, woodDark],
      ).createShader(Rect.fromLTWH(x - 24, y, 46, 10)),
    );

    // Seat side edge
    final seatSide = Path()
      ..moveTo(x + 22, y)
      ..lineTo(x + 20, y - 4)
      ..lineTo(x + 20, y + 4)
      ..lineTo(x + 22, y + 8)
      ..close();

    canvas.drawPath(seatSide, Paint()..color = woodDark);

    // Seat wood grain
    final seatGrainPaint = Paint()
      ..color = woodDark.withOpacity(0.3)
      ..strokeWidth = 1;

    for (int i = 0; i < 8; i++) {
      canvas.drawLine(
        Offset(x - 22 + i * 6, y - 2),
        Offset(x - 22 + i * 6, y + 6),
        seatGrainPaint,
      );
    }

    // LEGS - Four wooden legs in isometric view

    void drawChairLeg(double legX, double legY, bool isBack) {
      final legPath = Path()
        ..moveTo(legX, legY)
        ..lineTo(legX - 1.5, legY - 3)
        ..lineTo(legX - 1.5, legY + 35)
        ..lineTo(legX, legY + 38)
        ..lineTo(legX + 3.5, legY + 36)
        ..lineTo(legX + 3.5, legY - 1)
        ..close();

      canvas.drawPath(
        legPath,
        Paint()..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [woodDark, woodBrown, woodLight],
        ).createShader(Rect.fromLTWH(legX - 1.5, legY - 3, 5, 41)),
      );

      // Wood grain on leg
      final legGrain = Paint()
        ..color = woodDark.withOpacity(0.35)
        ..strokeWidth = 1;

      for (int i = 0; i < 5; i++) {
        canvas.drawLine(
          Offset(legX + 1, legY + 5 + i * 7),
          Offset(legX + 1, legY + 10 + i * 7),
          legGrain,
        );
      }
    }

    // Draw all 4 legs
    drawChairLeg(x - 22, y, true);      // Back left (connects to backrest)
    drawChairLeg(x + 18, y - 2, true);  // Back right
    drawChairLeg(x - 22, y + 8, false); // Front left
    drawChairLeg(x + 18, y + 6, false); // Front right

    // SUPPORT RUNGS - Cross braces between legs

    final rungPath = Path()
      ..moveTo(x - 20, y + 28)
      ..lineTo(x - 22, y + 26)
      ..lineTo(x + 16, y + 24)
      ..lineTo(x + 18, y + 26)
      ..close();

    canvas.drawPath(rungPath, Paint()..color = woodDark);

    // Wood wear on seat (shiny from use)
    final wearPaint = Paint()
      ..color = woodLight.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    canvas.drawOval(
      Rect.fromCenter(center: Offset(x - 2, y + 2), width: 30, height: 12),
      wearPaint,
    );
  }

  void _drawComfyChair(Canvas canvas, double x, double y) {
    // REALISTIC COMFY ARMCHAIR - Upholstered with wooden frame

    final fabricBrown = const Color(0xFF7B5A3C);
    final fabricDark = const Color(0xFF5B3A1C);
    final fabricLight = const Color(0xFF9B7A5C);
    final woodBrown = const Color(0xFF8B4513);
    final woodDark = const Color(0xFF654321);
    final woodLight = const Color(0xFFa06535);
    final buttonDark = const Color(0xFF3a2010);

    // Shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.45)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x, y + 54), width: 68, height: 16),
      shadowPaint,
    );

    // PADDED BACKREST - Upholstered with button tufting

    // Backrest body (curved for comfort)
    final backrestPath = Path()
      ..moveTo(x - 28, y - 45)
      ..quadraticBezierTo(x - 26, y - 50, x - 20, y - 52)
      ..quadraticBezierTo(x, y - 54, x + 20, y - 52)
      ..quadraticBezierTo(x + 26, y - 50, x + 28, y - 45)
      ..lineTo(x + 28, y - 5)
      ..quadraticBezierTo(x + 25, y, x + 20, y + 2)
      ..lineTo(x - 20, y + 2)
      ..quadraticBezierTo(x - 25, y, x - 28, y - 5)
      ..close();

    canvas.drawPath(
      backrestPath,
      Paint()..shader = RadialGradient(
        center: Alignment.centerLeft,
        radius: 1.2,
        colors: [fabricLight, fabricBrown, fabricDark],
      ).createShader(Rect.fromCenter(center: Offset(x, y - 25), width: 56, height: 56)),
    );

    // Button tufting pattern (diamond quilting)
    final tuftPaint = Paint()
      ..color = fabricDark.withOpacity(0.5)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Tufted diamond pattern
    for (int row = 0; row < 3; row++) {
      for (int col = 0; col < 2; col++) {
        final tuftX = x - 12 + col * 24;
        final tuftY = y - 42 + row * 14;

        // Diamond shape
        final diamond = Path()
          ..moveTo(tuftX, tuftY - 6)
          ..lineTo(tuftX + 8, tuftY)
          ..lineTo(tuftX, tuftY + 6)
          ..lineTo(tuftX - 8, tuftY)
          ..close();

        canvas.drawPath(diamond, tuftPaint);

        // Button in center
        canvas.drawCircle(Offset(tuftX, tuftY), 2.5, Paint()..color = buttonDark);
        canvas.drawCircle(Offset(tuftX, tuftY), 1.5, Paint()..color = fabricDark);
      }
    }

    // Fabric creases and folds
    final creasePaint = Paint()
      ..color = fabricDark.withOpacity(0.35)
      ..strokeWidth = 2;

    canvas.drawLine(Offset(x - 18, y - 30), Offset(x - 15, y - 15), creasePaint);
    canvas.drawLine(Offset(x + 18, y - 30), Offset(x + 15, y - 15), creasePaint);

    // PADDED SEAT CUSHION

    // Seat top surface (plush and rounded)
    final seatPath = Path()
      ..moveTo(x - 30, y + 4)
      ..quadraticBezierTo(x - 28, y, x - 22, y + 2)
      ..lineTo(x + 22, y)
      ..quadraticBezierTo(x + 28, y - 2, x + 30, y + 2)
      ..lineTo(x + 30, y + 8)
      ..lineTo(x - 30, y + 10)
      ..close();

    canvas.drawPath(
      seatPath,
      Paint()..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [fabricLight, fabricBrown, fabricDark],
      ).createShader(Rect.fromLTWH(x - 30, y, 60, 10)),
    );

    // Seat front face (cushioned)
    final seatFront = Path()
      ..moveTo(x - 30, y + 4)
      ..quadraticBezierTo(x, y + 10, x + 30, y + 2)
      ..lineTo(x + 30, y + 30)
      ..quadraticBezierTo(x, y + 34, x - 30, y + 32)
      ..close();

    canvas.drawPath(
      seatFront,
      Paint()..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [fabricBrown, fabricDark],
      ).createShader(Rect.fromLTWH(x - 30, y + 2, 60, 32)),
    );

    // Seat cushion seam
    final seamPaint = Paint()
      ..color = fabricDark
      ..strokeWidth = 2;

    canvas.drawLine(Offset(x - 28, y + 8), Offset(x + 28, y + 6), seamPaint);

    // Seat button tufts
    canvas.drawCircle(Offset(x - 10, y + 16), 2.5, Paint()..color = buttonDark);
    canvas.drawCircle(Offset(x + 10, y + 15), 2.5, Paint()..color = buttonDark);

    // WOODEN ARMRESTS - Polished wood

    void drawArmrest(double armX, bool isLeft) {
      final armPath = Path()
        ..moveTo(isLeft ? x - 34 : x + 26, y - 10)
        ..quadraticBezierTo(
          isLeft ? x - 36 : x + 28,
          y - 14,
          isLeft ? x - 32 : x + 30,
          y - 8,
        )
        ..lineTo(isLeft ? x - 32 : x + 30, y + 22)
        ..lineTo(isLeft ? x - 26 : x + 24, y + 24)
        ..lineTo(isLeft ? x - 26 : x + 24, y - 6)
        ..close();

      canvas.drawPath(
        armPath,
        Paint()..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: isLeft
              ? [woodDark, woodBrown, woodLight]
              : [woodLight, woodBrown, woodDark],
        ).createShader(Rect.fromLTWH(
          isLeft ? x - 36 : x + 24,
          y - 14,
          10,
          38,
        )),
      );

      // Armrest top surface (visible in isometric)
      final armTop = Path()
        ..moveTo(isLeft ? x - 34 : x + 26, y - 10)
        ..quadraticBezierTo(
          isLeft ? x - 36 : x + 28,
          y - 14,
          isLeft ? x - 32 : x + 30,
          y - 8,
        )
        ..lineTo(isLeft ? x - 29 : x + 27, y - 10)
        ..lineTo(isLeft ? x - 31 : x + 25, y - 12)
        ..close();

      canvas.drawPath(armTop, Paint()..color = woodLight);

      // Wood grain on armrest
      final armGrain = Paint()
        ..color = woodDark.withOpacity(0.35)
        ..strokeWidth = 1;

      for (int i = 0; i < 4; i++) {
        canvas.drawLine(
          Offset(isLeft ? x - 31 : x + 27, y - 4 + i * 7),
          Offset(isLeft ? x - 31 : x + 27, y + 1 + i * 7),
          armGrain,
        );
      }

      // Polished shine on armrest
      final shinePaint = Paint()
        ..color = Colors.white.withOpacity(0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(isLeft ? x - 30 : x + 28, y + 5),
          width: 8,
          height: 15,
        ),
        shinePaint,
      );
    }

    drawArmrest(x - 32, true);
    drawArmrest(x + 28, false);

    // WOODEN LEGS - Turned legs with isometric view

    void drawTurnedLeg(double legX, double legY) {
      // Leg shaft (tapered)
      final legPath = Path()
        ..moveTo(legX, legY)
        ..lineTo(legX - 2, legY - 4)
        ..lineTo(legX - 1, legY + 32)
        ..lineTo(legX, legY + 36)
        ..lineTo(legX + 5, legY + 34)
        ..lineTo(legX + 4, legY - 2)
        ..close();

      canvas.drawPath(
        legPath,
        Paint()..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [woodDark, woodBrown, woodLight],
        ).createShader(Rect.fromLTWH(legX - 2, legY - 4, 7, 40)),
      );

      // Decorative turning (bulge in middle)
      canvas.drawOval(
        Rect.fromCenter(center: Offset(legX + 2, legY + 18), width: 8, height: 6),
        Paint()..color = woodBrown,
      );

      // Leg foot
      canvas.drawOval(
        Rect.fromCenter(center: Offset(legX + 2, legY + 35), width: 9, height: 4),
        Paint()..color = woodDark,
      );
    }

    // Draw front legs
    drawTurnedLeg(x - 28, y + 14);
    drawTurnedLeg(x + 20, y + 12);

    // FABRIC WEAR AND HIGHLIGHTS

    // Worn shiny spots on seat (from use)
    final wearPaint = Paint()
      ..color = fabricLight.withOpacity(0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    canvas.drawOval(
      Rect.fromCenter(center: Offset(x - 8, y + 12), width: 28, height: 15),
      wearPaint,
    );

    // Backrest highlight
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x - 6, y - 32), width: 22, height: 18),
      Paint()
        ..color = Colors.white.withOpacity(0.08)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
  }

  // ─────────────── KITCHEN ───────────────

  void _drawSmallFire(Canvas canvas, double x, double y) {
    // REALISTIC SMALL FIRE PIT - Primitive cooking fire with rock ring

    final rockLight = const Color(0xFF808080);
    final rockMid = const Color(0xFF606060);
    final rockDark = const Color(0xFF404040);
    final ashGray = const Color(0xFF3a3a3a);

    // Shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x, y + 6), width: 55, height: 12),
      shadowPaint,
    );

    // Ash bed on ground
    final ashPaint = Paint()..color = ashGray.withOpacity(0.5);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x, y + 2), width: 38, height: 10),
      ashPaint,
    );

    // ROCK RING - Natural stones arranged in circle

    final random = math.Random(42);
    final rockPositions = [
      [x - 20, y - 3],
      [x - 10, y - 22],
      [x + 10, y - 22],
      [x + 20, y - 3],
      [x + 14, y + 14],
      [x - 14, y + 14],
    ];

    for (int i = 0; i < rockPositions.length; i++) {
      final pos = rockPositions[i];
      final rockSize = 9 + random.nextDouble() * 4;

      // Rock body (irregular shape)
      final rockPath = Path()
        ..addOval(Rect.fromCenter(
          center: Offset(pos[0], pos[1]),
          width: rockSize,
          height: rockSize - 2,
        ));

      canvas.drawPath(
        rockPath,
        Paint()..shader = RadialGradient(
          center: Alignment.topLeft,
          radius: 1.0,
          colors: [rockLight, rockMid, rockDark],
        ).createShader(Rect.fromCenter(
          center: Offset(pos[0], pos[1]),
          width: rockSize,
          height: rockSize,
        )),
      );

      // Rock texture (small cracks)
      if (random.nextBool()) {
        final crackPaint = Paint()
          ..color = rockDark
          ..strokeWidth = 1;
        canvas.drawLine(
          Offset(pos[0] - 2, pos[1] - 2),
          Offset(pos[0] + 2, pos[1] + 2),
          crackPaint,
        );
      }

      // Firelight reflection on rocks
      if (i < 4) { // Only top rocks get firelight
        canvas.drawCircle(
          Offset(pos[0] - 2, pos[1] - 2),
          2,
          Paint()..color = const Color(0xFFFF6600).withOpacity(0.25),
        );
      }

      // Rock highlight
      canvas.drawCircle(
        Offset(pos[0] - 2.5, pos[1] - 2.5),
        1.5,
        Paint()..color = Colors.white.withOpacity(0.15),
      );
    }

    // BURNING EMBERS IN CENTER - Glowing coals

    final emberGlow = const Color(0xFFFF4500);
    final emberYellow = const Color(0xFFFFAA00);

    for (int i = 0; i < 8; i++) {
      final emberX = x + (random.nextDouble() - 0.5) * 16;
      final emberY = y + (random.nextDouble() - 0.5) * 12;
      final emberSize = 1.5 + random.nextDouble() * 2;

      // Ember glow
      canvas.drawCircle(
        Offset(emberX, emberY),
        emberSize + 2,
        Paint()
          ..color = emberGlow.withOpacity(0.6)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );

      // Ember core
      canvas.drawCircle(
        Offset(emberX, emberY),
        emberSize,
        Paint()..color = random.nextBool() ? emberYellow : emberGlow,
      );
    }

    // FLAMES - Layered realistic fire

    final flameCenter = Offset(x, y - 8);

    // Red base flame layer
    final redFlame = Path()
      ..moveTo(flameCenter.dx - 16, flameCenter.dy + 2)
      ..quadraticBezierTo(
        flameCenter.dx - 12, flameCenter.dy - 12,
        flameCenter.dx - 6, flameCenter.dy - 22,
      )
      ..quadraticBezierTo(
        flameCenter.dx - 2, flameCenter.dy - 28,
        flameCenter.dx, flameCenter.dy - 32,
      )
      ..quadraticBezierTo(
        flameCenter.dx + 2, flameCenter.dy - 28,
        flameCenter.dx + 6, flameCenter.dy - 22,
      )
      ..quadraticBezierTo(
        flameCenter.dx + 12, flameCenter.dy - 12,
        flameCenter.dx + 16, flameCenter.dy + 2,
      )
      ..close();

    canvas.drawPath(
      redFlame,
      Paint()..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          const Color(0xFFAA0000),
          const Color(0xFFDD3300),
          const Color(0xFFFF4500),
        ],
      ).createShader(Rect.fromCenter(center: flameCenter, width: 32, height: 36)),
    );

    // Orange middle flame layer
    final orangeFlame = Path()
      ..moveTo(flameCenter.dx - 12, flameCenter.dy)
      ..quadraticBezierTo(
        flameCenter.dx - 8, flameCenter.dy - 16,
        flameCenter.dx - 3, flameCenter.dy - 26,
      )
      ..quadraticBezierTo(
        flameCenter.dx, flameCenter.dy - 35,
        flameCenter.dx + 3, flameCenter.dy - 26,
      )
      ..quadraticBezierTo(
        flameCenter.dx + 8, flameCenter.dy - 16,
        flameCenter.dx + 12, flameCenter.dy,
      )
      ..close();

    canvas.drawPath(
      orangeFlame,
      Paint()..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          const Color(0xFFFF5500),
          const Color(0xFFFF7700),
          const Color(0xFFFF9900),
        ],
      ).createShader(Rect.fromCenter(center: flameCenter, width: 24, height: 37)),
    );

    // Yellow-white core flame
    final yellowFlame = Path()
      ..moveTo(flameCenter.dx - 7, flameCenter.dy - 8)
      ..quadraticBezierTo(
        flameCenter.dx - 3, flameCenter.dy - 22,
        flameCenter.dx, flameCenter.dy - 38,
      )
      ..quadraticBezierTo(
        flameCenter.dx + 3, flameCenter.dy - 22,
        flameCenter.dx + 7, flameCenter.dy - 8,
      )
      ..close();

    canvas.drawPath(
      yellowFlame,
      Paint()..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          const Color(0xFFFFAA00),
          const Color(0xFFFFDD00),
          const Color(0xFFFFFF99),
        ],
      ).createShader(Rect.fromCenter(
        center: Offset(flameCenter.dx, flameCenter.dy - 18),
        width: 14,
        height: 32,
      )),
    );

    // Flame tips (dancing points)
    for (int i = 0; i < 2; i++) {
      final tipX = flameCenter.dx + (i - 0.5) * 6;
      final tipPath = Path()
        ..moveTo(tipX - 3, flameCenter.dy - 32 - i * 2)
        ..quadraticBezierTo(
          tipX, flameCenter.dy - 40 - i * 3,
          tipX + 3, flameCenter.dy - 32 - i * 2,
        )
        ..close();

      canvas.drawPath(
        tipPath,
        Paint()..color = const Color(0xFFFFFFCC).withOpacity(0.9),
      );
    }

    // FLOATING SPARKS - Rising embers

    final sparkPaint = Paint();
    for (int i = 0; i < 6; i++) {
      final sparkX = flameCenter.dx + (random.nextDouble() - 0.5) * 20;
      final sparkY = flameCenter.dy - 20 - random.nextDouble() * 25;
      final sparkSize = 0.8 + random.nextDouble() * 1.5;

      // Spark glow
      canvas.drawCircle(
        Offset(sparkX, sparkY),
        sparkSize + 1.5,
        Paint()
          ..color = const Color(0xFFFF8800).withOpacity(0.4)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );

      // Spark core
      canvas.drawCircle(
        Offset(sparkX, sparkY),
        sparkSize,
        Paint()..color = const Color(0xFFFFDD00),
      );
    }

    // HEAT GLOW - Multiple layers of warm light

    final glowLayers = [
      [30.0, 0.35, const Color(0xFFFF4500)],
      [22.0, 0.45, const Color(0xFFFF6600)],
      [15.0, 0.5, const Color(0xFFFF8800)],
    ];

    for (var layer in glowLayers) {
      canvas.drawCircle(
        flameCenter,
        layer[0] as double,
        Paint()
          ..color = (layer[2] as Color).withOpacity(layer[1] as double)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
      );
    }

    // Subtle smoke wisp
    final smokePaint = Paint()
      ..color = const Color(0xFF4a4a4a).withOpacity(0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(flameCenter.dx + 2, flameCenter.dy - 45),
        width: 15,
        height: 10,
      ),
      smokePaint,
    );
  }

  void _drawCampfire(Canvas canvas, double x, double y) {
    // Shadow (larger, softer)
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.45)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x, y + 18), width: 85, height: 18),
      shadowPaint,
    );

    // Ash/charcoal base on ground
    final ashPaint = Paint()..color = const Color(0xFF1a1a1a).withOpacity(0.6);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x, y + 8), width: 50, height: 15),
      ashPaint,
    );

    // Realistic rock ring with varied sizes and shading
    final rockLight = const Color(0xFF909090);
    final rockMid = const Color(0xFF707070);
    final rockDark = const Color(0xFF484848);

    final random = math.Random(200);
    for (int i = 0; i < 8; i++) {
      final angle = (i * math.pi * 2) / 8 + random.nextDouble() * 0.3;
      final distance = 30 + random.nextDouble() * 4;
      final rockX = x + math.cos(angle) * distance;
      final rockY = y + math.sin(angle) * distance;
      final rockSize = 12 + random.nextDouble() * 6;

      // Rock body (irregular shape)
      final rockPath = Path()
        ..addOval(Rect.fromCenter(
          center: Offset(rockX, rockY),
          width: rockSize + 2,
          height: rockSize - 1,
        ));

      canvas.drawPath(
        rockPath,
        Paint()..shader = RadialGradient(
          center: Alignment.topLeft,
          radius: 1.0,
          colors: [rockLight, rockMid, rockDark],
        ).createShader(Rect.fromCenter(
          center: Offset(rockX, rockY),
          width: rockSize,
          height: rockSize,
        )),
      );

      // Rock cracks
      if (random.nextBool()) {
        final crackPaint = Paint()
          ..color = rockDark
          ..strokeWidth = 1;
        canvas.drawLine(
          Offset(rockX - 3, rockY - 2),
          Offset(rockX + 2, rockY + 3),
          crackPaint,
        );
      }

      // Firelight reflection on rocks
      if (i % 2 == 0) {
        canvas.drawCircle(
          Offset(rockX - 2, rockY - 2),
          2.5,
          Paint()..color = const Color(0xFFFF8800).withOpacity(0.3),
        );
      }
    }

    // Charred burning logs with realistic detail
    final logBurnt = const Color(0xFF1a0a00);
    final logCharred = const Color(0xFF2d1510);
    final logWood = const Color(0xFF4a2f1a);
    final logLight = const Color(0xFF6b4423);
    final emberGlow = const Color(0xFFFF4500);

    void drawBurningLog(double startX, double startY, double endX, double endY, double width, bool isBurning) {
      // Log body (charred at center, wood at ends)
      final logPath = Path()
        ..moveTo(startX, startY - width/2)
        ..lineTo(endX, endY - width/2)
        ..lineTo(endX, endY + width/2)
        ..lineTo(startX, startY + width/2)
        ..close();

      canvas.drawPath(
        logPath,
        Paint()..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isBurning
              ? [logCharred, logBurnt, logCharred]
              : [logWood, logCharred, logLight],
        ).createShader(Rect.fromPoints(
          Offset(startX, startY - width/2),
          Offset(endX, endY + width/2),
        )),
      );

      // Bark texture with cracks
      final barkPaint = Paint()
        ..color = logBurnt
        ..strokeWidth = 1.5;

      for (int i = 0; i < 5; i++) {
        final t = i / 5;
        final midX = startX + (endX - startX) * t;
        final midY = startY + (endY - startY) * t;
        canvas.drawLine(
          Offset(midX, midY - width/2),
          Offset(midX, midY + width/2),
          barkPaint,
        );
      }

      // Glowing embers on log surface
      if (isBurning) {
        for (int i = 0; i < 8; i++) {
          final t = random.nextDouble();
          final emberX = startX + (endX - startX) * t + (random.nextDouble() - 0.5) * width;
          final emberY = startY + (endY - startY) * t + (random.nextDouble() - 0.5) * width/2;

          // Ember glow
          canvas.drawCircle(
            Offset(emberX, emberY),
            2 + random.nextDouble() * 1.5,
            Paint()
              ..color = emberGlow.withOpacity(0.8)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
          );

          // Ember core
          canvas.drawCircle(
            Offset(emberX, emberY),
            1 + random.nextDouble(),
            Paint()..color = const Color(0xFFFFFF00),
          );
        }
      }

      // Charred edge highlight
      final charredEdge = Paint()
        ..color = emberGlow.withOpacity(0.4)
        ..strokeWidth = 2;
      canvas.drawLine(
        Offset(startX, startY),
        Offset(endX, endY),
        charredEdge,
      );
    }

    // Draw 3 logs at different angles
    drawBurningLog(x - 30, y - 10, x + 30, y + 10, 13, true);  // Bottom log (burning)
    drawBurningLog(x - 10, y - 30, x + 10, y + 30, 13, true);  // Vertical log (burning)
    drawBurningLog(x - 24, y + 4, x + 22, y - 4, 11, false);   // Top log (less burnt)

    // ENHANCED REALISTIC FLAMES
    final flameCenter = Offset(x, y - 12);

    // Base flame layer (wide, red-orange)
    final baseFlame = Path()
      ..moveTo(flameCenter.dx - 24, flameCenter.dy + 5)
      ..quadraticBezierTo(
        flameCenter.dx - 18, flameCenter.dy - 15,
        flameCenter.dx - 10, flameCenter.dy - 28,
      )
      ..quadraticBezierTo(
        flameCenter.dx - 6, flameCenter.dy - 38,
        flameCenter.dx, flameCenter.dy - 48,
      )
      ..quadraticBezierTo(
        flameCenter.dx + 6, flameCenter.dy - 38,
        flameCenter.dx + 10, flameCenter.dy - 28,
      )
      ..quadraticBezierTo(
        flameCenter.dx + 18, flameCenter.dy - 15,
        flameCenter.dx + 24, flameCenter.dy + 5,
      )
      ..close();

    canvas.drawPath(
      baseFlame,
      Paint()..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          const Color(0xFFAA0000),
          const Color(0xFFDD3300),
          const Color(0xFFFF5500),
        ],
      ).createShader(Rect.fromCenter(center: flameCenter, width: 48, height: 55)),
    );

    // Middle flame (orange-yellow)
    final midFlame = Path()
      ..moveTo(flameCenter.dx - 18, flameCenter.dy + 2)
      ..quadraticBezierTo(
        flameCenter.dx - 12, flameCenter.dy - 20,
        flameCenter.dx - 4, flameCenter.dy - 38,
      )
      ..quadraticBezierTo(
        flameCenter.dx, flameCenter.dy - 52,
        flameCenter.dx + 4, flameCenter.dy - 38,
      )
      ..quadraticBezierTo(
        flameCenter.dx + 12, flameCenter.dy - 20,
        flameCenter.dx + 18, flameCenter.dy + 2,
      )
      ..close();

    canvas.drawPath(
      midFlame,
      Paint()..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          const Color(0xFFFF6600),
          const Color(0xFFFF8800),
          const Color(0xFFFFAA00),
        ],
      ).createShader(Rect.fromCenter(center: flameCenter, width: 36, height: 56)),
    );

    // Inner flame (bright yellow-white)
    final innerFlame = Path()
      ..moveTo(flameCenter.dx - 12, flameCenter.dy - 8)
      ..quadraticBezierTo(
        flameCenter.dx - 6, flameCenter.dy - 28,
        flameCenter.dx, flameCenter.dy - 56,
      )
      ..quadraticBezierTo(
        flameCenter.dx + 6, flameCenter.dy - 28,
        flameCenter.dx + 12, flameCenter.dy - 8,
      )
      ..close();

    canvas.drawPath(
      innerFlame,
      Paint()..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          const Color(0xFFFFCC00),
          const Color(0xFFFFFF66),
          const Color(0xFFFFFFCC),
        ],
      ).createShader(Rect.fromCenter(
        center: Offset(flameCenter.dx, flameCenter.dy - 25),
        width: 24,
        height: 50,
      )),
    );

    // Dancing flame tips (irregular points)
    for (int i = 0; i < 3; i++) {
      final tipX = flameCenter.dx + (i - 1) * 8;
      final tipPath = Path()
        ..moveTo(tipX - 4, flameCenter.dy - 45 - i * 3)
        ..quadraticBezierTo(
          tipX, flameCenter.dy - 58 - i * 4,
          tipX + 4, flameCenter.dy - 45 - i * 3,
        )
        ..close();

      canvas.drawPath(
        tipPath,
        Paint()..color = const Color(0xFFFFFF99).withOpacity(0.9),
      );
    }

    // Floating embers above fire
    for (int i = 0; i < 12; i++) {
      final emberX = flameCenter.dx + (random.nextDouble() - 0.5) * 40;
      final emberY = flameCenter.dy - 30 - random.nextDouble() * 50;
      final emberSize = 1 + random.nextDouble() * 2;

      // Ember glow
      canvas.drawCircle(
        Offset(emberX, emberY),
        emberSize + 2,
        Paint()
          ..color = const Color(0xFFFF6600).withOpacity(0.5)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );

      // Ember particle
      canvas.drawCircle(
        Offset(emberX, emberY),
        emberSize,
        Paint()..color = const Color(0xFFFFCC00),
      );
    }

    // Heat distortion shimmer effect (subtle)
    final shimmerPaint = Paint()
      ..color = const Color(0xFFFFAA00).withOpacity(0.08)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 25);
    canvas.drawOval(
      Rect.fromCenter(center: flameCenter, width: 70, height: 100),
      shimmerPaint,
    );

    // Multi-layered fire glow (warm light spreading)
    final glowLayers = [
      [45.0, 0.4, const Color(0xFFFF4500)],
      [35.0, 0.5, const Color(0xFFFF6600)],
      [25.0, 0.6, const Color(0xFFFF8800)],
    ];

    for (var layer in glowLayers) {
      canvas.drawCircle(
        flameCenter,
        layer[0] as double,
        Paint()
          ..color = (layer[2] as Color).withOpacity(layer[1] as double)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
      );
    }

    // Smoke wisps (very subtle, rising)
    final smokePaint = Paint()
      ..color = const Color(0xFF404040).withOpacity(0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    for (int i = 0; i < 3; i++) {
      final smokeX = flameCenter.dx + (random.nextDouble() - 0.5) * 20;
      final smokeY = flameCenter.dy - 60 - i * 15;
      canvas.drawOval(
        Rect.fromCenter(center: Offset(smokeX, smokeY), width: 20 + i * 5, height: 15 + i * 3),
        smokePaint,
      );
    }
  }

  void _drawStoneOven(Canvas canvas, double x, double y) {
    // REALISTIC STONE OVEN - Brick dome oven with fire

    final stoneLight = const Color(0xFF8a8a7a);
    final stoneMid = const Color(0xFF6a6a5a);
    final stoneDark = const Color(0xFF4a4a3a);
    final brickRed = const Color(0xFF9B5A3C);
    final brickOrange = const Color(0xFFa06535);
    final brickDark = const Color(0xFF6b3a1a);
    final mortarGray = const Color(0xFF7a7a6a);
    final sootBlack = const Color(0xFF2a1a0a);

    // Shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x, y + 60), width: 105, height: 20),
      shadowPaint,
    );

    // STONE BASE PLATFORM - Rough-hewn stone blocks

    final random = math.Random(500);

    // Base body with isometric perspective
    final basePath = Path()
      ..moveTo(x - 50, y + 28)
      ..lineTo(x - 52, y + 24)
      ..lineTo(x + 48, y + 22)
      ..lineTo(x + 50, y + 26)
      ..lineTo(x + 48, y + 58)
      ..lineTo(x - 48, y + 58)
      ..close();

    canvas.drawPath(
      basePath,
      Paint()..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [stoneMid, stoneDark],
      ).createShader(Rect.fromCenter(center: Offset(x, y + 42), width: 100, height: 36)),
    );

    // Stone block seams (irregular)
    final seamPaint = Paint()
      ..color = stoneDark
      ..strokeWidth = 2;

    for (int i = 0; i < 4; i++) {
      final seamX = x - 42 + i * 24 + random.nextDouble() * 4;
      canvas.drawLine(
        Offset(seamX, y + 30),
        Offset(seamX - 1, y + 54),
        seamPaint,
      );
    }

    // Horizontal stone courses
    for (int row = 0; row < 2; row++) {
      canvas.drawLine(
        Offset(x - 48, y + 38 + row * 12),
        Offset(x + 48, y + 37 + row * 12),
        seamPaint,
      );
    }

    // Stone texture (cracks and chips)
    final crackPaint = Paint()
      ..color = stoneDark.withOpacity(0.6)
      ..strokeWidth = 1;

    for (int i = 0; i < 8; i++) {
      final crackX = x - 40 + random.nextDouble() * 80;
      final crackY = y + 32 + random.nextDouble() * 22;
      canvas.drawLine(
        Offset(crackX, crackY),
        Offset(crackX + random.nextDouble() * 6 - 3, crackY + random.nextDouble() * 6),
        crackPaint,
      );
    }

    // BRICK OVEN DOME - Realistic brickwork with masonry

    // Dome body (rounded brick construction)
    final domePath = Path()
      ..moveTo(x - 44, y + 28)
      ..lineTo(x + 44, y + 26)
      ..quadraticBezierTo(x + 42, y + 12, x + 34, y - 2)
      ..quadraticBezierTo(x + 18, y - 14, x, y - 18)
      ..quadraticBezierTo(x - 18, y - 14, x - 34, y - 2)
      ..quadraticBezierTo(x - 42, y + 12, x - 44, y + 28)
      ..close();

    canvas.drawPath(
      domePath,
      Paint()..shader = RadialGradient(
        center: Alignment.topLeft,
        radius: 1.3,
        colors: [brickOrange, brickRed, brickDark],
      ).createShader(Rect.fromCenter(center: Offset(x, y + 10), width: 88, height: 48)),
    );

    // REALISTIC BRICK PATTERN - Individual bricks with mortar

    final mortarPaint = Paint()
      ..color = mortarGray
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // Brick courses (horizontal rows)
    for (int row = 0; row < 5; row++) {
      final rowY = y + 24 - row * 9;
      final rowRadius = 42 - row * 9;

      if (rowRadius > 0) {
        // Draw mortar line
        canvas.drawLine(
          Offset(x - rowRadius, rowY),
          Offset(x + rowRadius, rowY),
          mortarPaint,
        );

        // Individual bricks in this row
        final brickCount = 4 + (4 - row);
        final brickWidth = (rowRadius * 2) / brickCount;

        for (int b = 0; b < brickCount; b++) {
          final brickX = x - rowRadius + b * brickWidth;

          // Vertical mortar between bricks
          if (b > 0) {
            canvas.drawLine(
              Offset(brickX, rowY),
              Offset(brickX, rowY - 9),
              mortarPaint,
            );
          }

          // Individual brick color variation
          if (random.nextDouble() > 0.3) {
            final brickColor = random.nextBool() ? brickRed : brickOrange;
            canvas.drawRect(
              Rect.fromLTWH(brickX + 1, rowY - 8, brickWidth - 2, 7),
              Paint()..color = brickColor.withOpacity(0.3),
            );
          }
        }
      }
    }

    // OVEN OPENING - Arched entrance with depth

    final archPath = Path()
      ..moveTo(x - 26, y + 22)
      ..lineTo(x + 26, y + 21)
      ..quadraticBezierTo(x + 22, y + 12, x + 18, y + 4)
      ..quadraticBezierTo(x + 10, y - 4, x, y - 8)
      ..quadraticBezierTo(x - 10, y - 4, x - 18, y + 4)
      ..quadraticBezierTo(x - 22, y + 12, x - 26, y + 22)
      ..close();

    // Dark interior
    canvas.drawPath(
      archPath,
      Paint()..color = sootBlack,
    );

    // Arch inner lip (shows thickness)
    final archInner = Path()
      ..moveTo(x - 24, y + 21)
      ..lineTo(x + 24, y + 20)
      ..quadraticBezierTo(x + 20, y + 11, x + 16, y + 5)
      ..quadraticBezierTo(x + 9, y - 2, x, y - 6)
      ..quadraticBezierTo(x - 9, y - 2, x - 16, y + 5)
      ..quadraticBezierTo(x - 20, y + 11, x - 24, y + 21)
      ..close();

    canvas.drawPath(
      archInner,
      Paint()..color = const Color(0xFF1a0a00),
    );

    // FIRE INSIDE - Realistic flames and glow

    // Fire glow (radial gradient from inside)
    final glowPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 0.9,
        colors: [
          const Color(0xFFFFAA00).withOpacity(0.9),
          const Color(0xFFFF6600).withOpacity(0.6),
          const Color(0xFFCC3300).withOpacity(0.3),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCenter(center: Offset(x, y + 12), width: 52, height: 44));

    canvas.drawPath(archPath, glowPaint);

    // Dancing flames visible inside
    final flamePath = Path()
      ..moveTo(x - 14, y + 18)
      ..quadraticBezierTo(x - 8, y + 10, x - 4, y + 2)
      ..quadraticBezierTo(x, y - 4, x + 4, y + 2)
      ..quadraticBezierTo(x + 8, y + 10, x + 14, y + 18)
      ..close();

    canvas.drawPath(
      flamePath,
      Paint()..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          const Color(0xFFFF5500),
          const Color(0xFFFF8800),
          const Color(0xFFFFCC00),
        ],
      ).createShader(Rect.fromCenter(center: Offset(x, y + 8), width: 28, height: 22)),
    );

    // WEATHERING AND SOOT STAINS

    // Soot marks above opening (from smoke)
    final sootPaint = Paint()
      ..color = sootBlack.withOpacity(0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    canvas.drawOval(
      Rect.fromCenter(center: Offset(x, y - 10), width: 35, height: 20),
      sootPaint,
    );

    canvas.drawOval(
      Rect.fromCenter(center: Offset(x - 6, y), width: 25, height: 15),
      sootPaint,
    );

    // Cracks in brickwork
    final brickCrack = Paint()
      ..color = brickDark
      ..strokeWidth = 1.5;

    canvas.drawLine(Offset(x + 20, y + 8), Offset(x + 28, y + 18), brickCrack);
    canvas.drawLine(Offset(x - 25, y + 15), Offset(x - 18, y + 22), brickCrack);

    // SMOKE - Rising from chimney opening

    final smokePaint = Paint()
      ..color = const Color(0xFF5a5a5a).withOpacity(0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    // Multiple smoke wisps
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x - 3, y - 22), width: 20, height: 12),
      smokePaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x + 5, y - 32), width: 28, height: 16),
      smokePaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x - 8, y - 42), width: 35, height: 20),
      smokePaint,
    );

    // HEAT SHIMMER - From oven opening

    final shimmerPaint = Paint()
      ..color = const Color(0xFFFFAA00).withOpacity(0.08)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);

    canvas.drawOval(
      Rect.fromCenter(center: Offset(x, y + 8), width: 55, height: 40),
      shimmerPaint,
    );

    // Dome highlight (shows curve)
    final domeHighlight = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    canvas.drawOval(
      Rect.fromCenter(center: Offset(x - 18, y - 6), width: 32, height: 18),
      domeHighlight,
    );
  }

  // ─────────────── DECORATIONS ───────────────

  void _drawSmallRock(Canvas canvas, double x, double y) {
    final rockLight = const Color(0xFF909090);
    final rockMid = const Color(0xFF707070);
    final rockDark = const Color(0xFF505050);

    // Shadow
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x + 2, y + 6), width: 28, height: 8),
      Paint()..color = Colors.black.withOpacity(0.3)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // Rock body (irregular)
    final rockPath = Path()
      ..moveTo(x - 14, y + 2)
      ..quadraticBezierTo(x - 12, y - 8, x - 4, y - 10)
      ..quadraticBezierTo(x + 4, y - 12, x + 12, y - 8)
      ..quadraticBezierTo(x + 14, y, x + 10, y + 6)
      ..quadraticBezierTo(x, y + 8, x - 10, y + 6)
      ..close();

    canvas.drawPath(
      rockPath,
      Paint()..shader = RadialGradient(
        center: Alignment.topLeft,
        radius: 1.2,
        colors: [rockLight, rockMid, rockDark],
      ).createShader(Rect.fromCenter(center: Offset(x, y), width: 28, height: 20)),
    );

    // Rock texture (cracks)
    final crackPaint = Paint()
      ..color = rockDark.withOpacity(0.6)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(x - 6, y - 4), Offset(x + 2, y - 2), crackPaint);
    canvas.drawLine(Offset(x + 4, y + 1), Offset(x + 8, y + 4), crackPaint);

    // Highlight
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x - 6, y - 6), width: 10, height: 6),
      Paint()..color = Colors.white.withOpacity(0.25),
    );
  }

  void _drawMossPatch(Canvas canvas, double x, double y) {
    final mossLight = const Color(0xFF3a7a3a);
    final mossMid = const Color(0xFF2a5a2a);
    final mossDark = const Color(0xFF1a3a1a);

    // Irregular moss blob
    final mossPath = Path()
      ..moveTo(x - 24, y + 2)
      ..quadraticBezierTo(x - 20, y - 12, x - 8, y - 14)
      ..quadraticBezierTo(x + 4, y - 12, x + 18, y - 8)
      ..quadraticBezierTo(x + 24, y + 2, x + 20, y + 12)
      ..quadraticBezierTo(x + 8, y + 16, x - 6, y + 14)
      ..quadraticBezierTo(x - 18, y + 10, x - 24, y + 2)
      ..close();

    canvas.drawPath(
      mossPath,
      Paint()..shader = RadialGradient(
        center: Alignment.topLeft,
        radius: 1.0,
        colors: [mossLight, mossMid, mossDark],
      ).createShader(Rect.fromCenter(center: Offset(x, y), width: 48, height: 30)),
    );

    // Moss texture (tiny leaf clumps)
    final random = math.Random(300);
    final clumpPaint = Paint()..color = mossDark.withOpacity(0.6);

    for (int i = 0; i < 12; i++) {
      final clumpX = x + (random.nextDouble() - 0.5) * 35;
      final clumpY = y + (random.nextDouble() - 0.5) * 20;
      canvas.drawCircle(
        Offset(clumpX, clumpY),
        2 + random.nextDouble() * 2,
        clumpPaint,
      );
    }

    // Highlight
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x - 8, y - 6), width: 18, height: 10),
      Paint()..color = mossLight.withOpacity(0.4),
    );
  }

  void _drawWallTorch(Canvas canvas, double x, double y) {
    final woodDark = const Color(0xFF4a2f1a);
    final woodLight = const Color(0xFF8B4513);
    final metalDark = const Color(0xFF3a3a3a);

    // Wall mount (metal bracket)
    final bracketPath = Path()
      ..moveTo(x - 3, y)
      ..lineTo(x - 3, y + 18)
      ..lineTo(x + 3, y + 18)
      ..lineTo(x + 3, y)
      ..close();

    canvas.drawPath(
      bracketPath,
      Paint()..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [metalDark, const Color(0xFF5a5a5a)],
      ).createShader(Rect.fromLTWH(x - 3, y, 6, 18)),
    );

    // Torch stick
    final torchPath = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(x - 4, y + 12, 8, 35),
        const Radius.circular(3),
      ));

    canvas.drawPath(
      torchPath,
      Paint()..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [woodDark, woodLight],
      ).createShader(Rect.fromLTWH(x - 4, y + 12, 8, 35)),
    );

    // Wood texture
    final grainPaint = Paint()
      ..color = woodDark.withOpacity(0.4)
      ..strokeWidth = 1;
    for (int i = 0; i < 4; i++) {
      canvas.drawLine(
        Offset(x - 2, y + 15 + i * 8),
        Offset(x + 2, y + 15 + i * 8),
        grainPaint,
      );
    }

    // Wrapped cloth at top
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x, y + 45), width: 12, height: 8),
      Paint()..color = const Color(0xFF5a4a3a),
    );

    // Flame (detailed)
    final flameCenter = Offset(x, y + 42);

    // Red base
    final redFlame = Path()
      ..moveTo(flameCenter.dx - 10, flameCenter.dy)
      ..quadraticBezierTo(
        flameCenter.dx - 6, flameCenter.dy - 12,
        flameCenter.dx, flameCenter.dy - 24,
      )
      ..quadraticBezierTo(
        flameCenter.dx + 6, flameCenter.dy - 12,
        flameCenter.dx + 10, flameCenter.dy,
      )
      ..close();

    canvas.drawPath(
      redFlame,
      Paint()..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [const Color(0xFFCC0000), const Color(0xFFFF4500)],
      ).createShader(Rect.fromCenter(center: flameCenter, width: 20, height: 26)),
    );

    // Orange middle
    final orangeFlame = Path()
      ..moveTo(flameCenter.dx - 7, flameCenter.dy - 4)
      ..quadraticBezierTo(
        flameCenter.dx, flameCenter.dy - 28,
        flameCenter.dx + 7, flameCenter.dy - 4,
      )
      ..close();

    canvas.drawPath(
      orangeFlame,
      Paint()..shader = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [const Color(0xFFFF6600), const Color(0xFFFF8C00)],
      ).createShader(Rect.fromCenter(
        center: Offset(flameCenter.dx, flameCenter.dy - 12),
        width: 14,
        height: 26,
      )),
    );

    // Yellow tip
    final yellowFlame = Path()
      ..moveTo(flameCenter.dx - 4, flameCenter.dy - 10)
      ..quadraticBezierTo(
        flameCenter.dx, flameCenter.dy - 32,
        flameCenter.dx + 4, flameCenter.dy - 10,
      )
      ..close();

    canvas.drawPath(
      yellowFlame,
      Paint()..color = const Color(0xFFFFFF99),
    );

    // Glow
    final glowPaint = Paint()
      ..color = const Color(0xFFFF8800).withOpacity(0.5)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawCircle(flameCenter, 18, glowPaint);
  }

  void _drawCavePainting(Canvas canvas, double x, double y) {
    final rockBg = const Color(0xFF5a5a48);
    final paintBrown = const Color(0xFF6b4423);
    final paintRed = const Color(0xFF8B3a1a);

    // Background rock surface
    final bgPath = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(x, y), width: 56, height: 56),
        const Radius.circular(4),
      ));

    canvas.drawPath(
      bgPath,
      Paint()..shader = RadialGradient(
        center: Alignment.topLeft,
        radius: 1.0,
        colors: [rockBg, rockBg.withOpacity(0.7)],
      ).createShader(Rect.fromCenter(center: Offset(x, y), width: 56, height: 56)),
    );

    // Rock texture
    final crackPaint = Paint()
      ..color = const Color(0xFF3a3a28).withOpacity(0.5)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final random = math.Random(400);
    for (int i = 0; i < 4; i++) {
      canvas.drawLine(
        Offset(x - 20 + random.nextDouble() * 40, y - 20),
        Offset(x - 20 + random.nextDouble() * 40, y + 20),
        crackPaint,
      );
    }

    // Primitive painting style
    final artPaint = Paint()
      ..color = paintBrown
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    // Stick figure human
    final figureX = x - 12;

    // Head
    canvas.drawCircle(Offset(figureX, y - 12), 6, artPaint);

    // Body
    canvas.drawLine(
      Offset(figureX, y - 6),
      Offset(figureX, y + 10),
      artPaint,
    );

    // Arms raised
    canvas.drawLine(
      Offset(figureX - 10, y - 2),
      Offset(figureX, y + 2),
      artPaint,
    );
    canvas.drawLine(
      Offset(figureX, y + 2),
      Offset(figureX + 10, y - 2),
      artPaint,
    );

    // Legs
    canvas.drawLine(
      Offset(figureX, y + 10),
      Offset(figureX - 6, y + 20),
      artPaint,
    );
    canvas.drawLine(
      Offset(figureX, y + 10),
      Offset(figureX + 6, y + 20),
      artPaint,
    );

    // Animal (deer-like)
    final animalPaint = Paint()
      ..color = paintRed
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final animalX = x + 14;

    // Body
    canvas.drawOval(
      Rect.fromCenter(center: Offset(animalX, y + 8), width: 20, height: 12),
      animalPaint,
    );

    // Legs
    for (int i = 0; i < 4; i++) {
      final legX = animalX - 8 + i * 5;
      canvas.drawLine(
        Offset(legX, y + 14),
        Offset(legX, y + 22),
        animalPaint,
      );
    }

    // Head and neck
    canvas.drawLine(
      Offset(animalX + 10, y + 6),
      Offset(animalX + 14, y - 2),
      animalPaint,
    );
    canvas.drawCircle(Offset(animalX + 15, y - 4), 4, animalPaint);

    // Antlers
    canvas.drawLine(
      Offset(animalX + 15, y - 8),
      Offset(animalX + 18, y - 14),
      animalPaint,
    );
    canvas.drawLine(
      Offset(animalX + 15, y - 8),
      Offset(animalX + 12, y - 13),
      animalPaint,
    );

    // Handprints (red ochre)
    final handPaint = Paint()..color = paintRed.withOpacity(0.6);
    canvas.drawCircle(Offset(x - 18, y - 18), 4, handPaint);
    canvas.drawCircle(Offset(x + 20, y + 18), 3, handPaint);
  }

  void _drawGlowingMushroom(Canvas canvas, double x, double y) {
    final stemLight = const Color(0xFFE6E6FA);
    final stemDark = const Color(0xFFc6c6da);
    final capLight = const Color(0xFF40E0D0);
    final capDark = const Color(0xFF20a0a0);
    final glowColor = const Color(0xFF00FFFF);

    // Shadow
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x, y + 28), width: 20, height: 6),
      Paint()..color = Colors.black.withOpacity(0.3)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // Stem
    final stemPath = Path()
      ..moveTo(x - 5, y + 20)
      ..lineTo(x - 4, y - 5)
      ..lineTo(x + 4, y - 5)
      ..lineTo(x + 5, y + 20)
      ..close();

    canvas.drawPath(
      stemPath,
      Paint()..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [stemDark, stemLight],
      ).createShader(Rect.fromCenter(center: Offset(x, y + 8), width: 10, height: 25)),
    );

    // Stem texture
    final texturePaint = Paint()
      ..color = stemDark.withOpacity(0.4)
      ..strokeWidth = 1;
    for (int i = 0; i < 4; i++) {
      canvas.drawLine(
        Offset(x - 3, y + 2 + i * 5),
        Offset(x + 3, y + 2 + i * 5),
        texturePaint,
      );
    }

    // Mushroom cap
    final capPath = Path()
      ..moveTo(x - 18, y - 2)
      ..quadraticBezierTo(x - 14, y - 18, x, y - 22)
      ..quadraticBezierTo(x + 14, y - 18, x + 18, y - 2)
      ..lineTo(x + 16, y)
      ..quadraticBezierTo(x, y - 4, x - 16, y)
      ..close();

    canvas.drawPath(
      capPath,
      Paint()..shader = RadialGradient(
        center: Alignment.topCenter,
        radius: 0.9,
        colors: [capLight, capDark],
      ).createShader(Rect.fromCenter(center: Offset(x, y - 10), width: 36, height: 22)),
    );

    // Cap spots (bioluminescent)
    final spotPaint = Paint()..color = stemLight.withOpacity(0.7);
    canvas.drawCircle(Offset(x - 8, y - 12), 3, spotPaint);
    canvas.drawCircle(Offset(x + 6, y - 14), 2, spotPaint);
    canvas.drawCircle(Offset(x, y - 8), 2, spotPaint);
    canvas.drawCircle(Offset(x + 10, y - 8), 2, spotPaint);

    // Gills underneath
    final gillPaint = Paint()
      ..color = capDark.withOpacity(0.6)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 8; i++) {
      final gillX = x - 14 + i * 4;
      canvas.drawLine(
        Offset(gillX, y - 2),
        Offset(gillX, y + 1),
        gillPaint,
      );
    }

    // Bioluminescent glow
    final glowPaint = Paint()
      ..color = glowColor.withOpacity(0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
    canvas.drawCircle(Offset(x, y - 10), 25, glowPaint);

    // Bright glow center
    final brightGlow = Paint()
      ..color = glowColor.withOpacity(0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(Offset(x, y - 12), 12, brightGlow);
  }

  void _drawCrystalCluster(Canvas canvas, double x, double y) {
    final crystalLight = const Color(0xFFB8A0FF);
    final crystalMid = const Color(0xFF9370DB);
    final crystalDark = const Color(0xFF6A5ACD);
    final glowColor = const Color(0xFFDDA0DD);

    // Shadow
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x, y + 32), width: 45, height: 10),
      Paint()..color = Colors.black.withOpacity(0.35)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // Crystal shards (5 different sizes/angles)
    final shards = [
      [0.0, -30.0, 18.0],    // Center tallest
      [-10.0, -22.0, 14.0],  // Left
      [12.0, -24.0, 15.0],   // Right
      [-18.0, -16.0, 12.0],  // Far left
      [20.0, -18.0, 13.0],   // Far right
    ];

    for (var shard in shards) {
      final shardX = x + shard[0];
      final tipY = y + shard[1];
      final width = shard[2];

      // Crystal body
      final shardPath = Path()
        ..moveTo(shardX - width/2, y + 25)
        ..lineTo(shardX - width/3, tipY + 8)
        ..lineTo(shardX, tipY)
        ..lineTo(shardX + width/3, tipY + 8)
        ..lineTo(shardX + width/2, y + 25)
        ..close();

      canvas.drawPath(
        shardPath,
        Paint()..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [crystalLight, crystalMid, crystalDark],
        ).createShader(Rect.fromPoints(
          Offset(shardX, tipY),
          Offset(shardX, y + 25),
        )),
      );

      // Darker facet (right side)
      final facetPath = Path()
        ..moveTo(shardX, tipY)
        ..lineTo(shardX + width/3, tipY + 8)
        ..lineTo(shardX + width/2, y + 25)
        ..lineTo(shardX, y + 25)
        ..close();

      canvas.drawPath(
        facetPath,
        Paint()..color = crystalDark.withOpacity(0.6),
      );

      // Light reflection
      final reflectionPath = Path()
        ..moveTo(shardX - width/4, tipY + 5)
        ..lineTo(shardX - width/6, tipY + 2)
        ..lineTo(shardX - width/8, y + 15)
        ..lineTo(shardX - width/5, y + 18)
        ..close();

      canvas.drawPath(
        reflectionPath,
        Paint()..color = Colors.white.withOpacity(0.5),
      );
    }

    // Base cluster connection
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x, y + 25), width: 45, height: 12),
      Paint()..color = crystalDark,
    );

    // Magical glow
    final glowPaint = Paint()
      ..color = glowColor.withOpacity(0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
    canvas.drawCircle(Offset(x, y), 30, glowPaint);
  }

  void _drawAncientArtifact(Canvas canvas, double x, double y) {
    final stoneLight = const Color(0xFF808080);
    final stoneMid = const Color(0xFF606060);
    final stoneDark = const Color(0xFF404040);
    final goldColor = const Color(0xFFFFD700);
    final goldDark = const Color(0xFFb8860b);

    // Shadow
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x, y + 35), width: 40, height: 10),
      Paint()..color = Colors.black.withOpacity(0.4)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // Stone base platform
    final basePath = Path()
      ..addOval(Rect.fromCenter(center: Offset(x, y + 28), width: 38, height: 12));

    canvas.drawPath(
      basePath,
      Paint()..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [stoneMid, stoneDark],
      ).createShader(Rect.fromCenter(center: Offset(x, y + 28), width: 38, height: 12)),
    );

    // Totem body (tapered column)
    final totemPath = Path()
      ..moveTo(x - 16, y + 24)
      ..lineTo(x - 12, y - 25)
      ..lineTo(x + 12, y - 25)
      ..lineTo(x + 16, y + 24)
      ..close();

    canvas.drawPath(
      totemPath,
      Paint()..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [stoneDark, stoneMid, stoneLight, stoneMid],
      ).createShader(Rect.fromCenter(center: Offset(x, y), width: 28, height: 50)),
    );

    // Stone texture (vertical grooves)
    final groovePaint = Paint()
      ..color = stoneDark.withOpacity(0.5)
      ..strokeWidth = 2;

    for (int i = 0; i < 3; i++) {
      final grooveX = x - 8 + i * 8;
      canvas.drawLine(
        Offset(grooveX, y - 22),
        Offset(grooveX + 2, y + 20),
        groovePaint,
      );
    }

    // Ancient eye symbol (mystical)
    final eyePath = Path()
      ..addOval(Rect.fromCenter(center: Offset(x, y - 2), width: 22, height: 14));

    // Eye outline
    canvas.drawPath(
      eyePath,
      Paint()
        ..color = goldColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    // Pupil
    canvas.drawCircle(
      Offset(x, y - 2),
      5,
      Paint()..shader = RadialGradient(
        center: Alignment.center,
        radius: 0.8,
        colors: [goldColor, goldDark],
      ).createShader(Rect.fromCircle(center: Offset(x, y - 2), radius: 5)),
    );

    // Iris detail
    final irisPaint = Paint()
      ..color = goldDark
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 8; i++) {
      final angle = (i * math.pi * 2) / 8;
      canvas.drawLine(
        Offset(x + math.cos(angle) * 3, y - 2 + math.sin(angle) * 3),
        Offset(x + math.cos(angle) * 5, y - 2 + math.sin(angle) * 5),
        irisPaint,
      );
    }

    // Runic markings
    final runePaint = Paint()
      ..color = goldColor.withOpacity(0.8)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    // Top rune
    canvas.drawLine(Offset(x - 6, y - 18), Offset(x + 6, y - 18), runePaint);
    canvas.drawLine(Offset(x, y - 18), Offset(x, y - 14), runePaint);

    // Bottom rune
    canvas.drawLine(Offset(x - 8, y + 12), Offset(x + 8, y + 12), runePaint);
    canvas.drawLine(Offset(x - 8, y + 16), Offset(x + 8, y + 16), runePaint);

    // Mystical glow
    final glowPaint = Paint()
      ..color = goldColor.withOpacity(0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawCircle(Offset(x, y - 2), 20, glowPaint);
  }

  void _drawEnchantedCrystal(Canvas canvas, double x, double y) {
    final crystalLight = const Color(0xFF80FFFF);
    final crystalMid = const Color(0xFF00FFFF);
    final crystalDark = const Color(0xFF00CED1);
    final magicPink = const Color(0xFFFF00FF);
    final magicPurple = const Color(0xFF9370DB);

    // Shadow
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x, y + 52), width: 55, height: 12),
      Paint()..color = Colors.black.withOpacity(0.45)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // Base platform (dark stone)
    final basePath = Path()
      ..addOval(Rect.fromCenter(center: Offset(x, y + 45), width: 48, height: 14));

    canvas.drawPath(
      basePath,
      Paint()..color = const Color(0xFF2a2a2a),
    );

    // Large crystal structure
    final mainCrystal = Path()
      ..moveTo(x - 22, y + 40)
      ..lineTo(x - 16, y + 10)
      ..lineTo(x - 8, y - 10)
      ..lineTo(x, y - 38)
      ..lineTo(x + 8, y - 10)
      ..lineTo(x + 16, y + 10)
      ..lineTo(x + 22, y + 40)
      ..close();

    canvas.drawPath(
      mainCrystal,
      Paint()..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [crystalLight, crystalMid, crystalDark],
      ).createShader(Rect.fromCenter(center: Offset(x, y + 2), width: 44, height: 80)),
    );

    // Darker facets
    final leftFacet = Path()
      ..moveTo(x, y - 38)
      ..lineTo(x - 8, y - 10)
      ..lineTo(x - 16, y + 10)
      ..lineTo(x - 22, y + 40)
      ..lineTo(x, y + 40)
      ..close();

    canvas.drawPath(
      leftFacet,
      Paint()..color = crystalDark.withOpacity(0.5),
    );

    // Light reflections
    final reflection1 = Path()
      ..moveTo(x - 6, y - 20)
      ..lineTo(x - 4, y - 25)
      ..lineTo(x - 2, y + 5)
      ..lineTo(x - 4, y + 10)
      ..close();

    canvas.drawPath(
      reflection1,
      Paint()..color = Colors.white.withOpacity(0.6),
    );

    final reflection2 = Path()
      ..moveTo(x + 8, y - 5)
      ..lineTo(x + 10, y - 8)
      ..lineTo(x + 11, y + 15)
      ..lineTo(x + 9, y + 18)
      ..close();

    canvas.drawPath(
      reflection2,
      Paint()..color = crystalLight.withOpacity(0.5),
    );

    // Magical energy particles
    final particles = [
      [x - 28, y - 18, magicPink, 3.5],
      [x + 26, y - 22, magicPurple, 3.0],
      [x - 20, y - 35, crystalLight, 2.5],
      [x + 22, y - 30, magicPink, 4.0],
      [x - 15, y - 45, magicPurple, 2.0],
      [x + 18, y - 12, crystalMid, 3.0],
    ];

    for (var particle in particles) {
      // Particle glow
      canvas.drawCircle(
        Offset(particle[0] as double, particle[1] as double),
        (particle[3] as double) + 3,
        Paint()
          ..color = (particle[2] as Color).withOpacity(0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );

      // Particle core
      canvas.drawCircle(
        Offset(particle[0] as double, particle[1] as double),
        particle[3] as double,
        Paint()..color = particle[2] as Color,
      );
    }

    // Orbiting sparkles
    final random = math.Random(500);
    for (int i = 0; i < 8; i++) {
      final angle = (i * math.pi * 2) / 8;
      final radius = 32 + random.nextDouble() * 8;
      final sparkleX = x + math.cos(angle) * radius;
      final sparkleY = y - 5 + math.sin(angle) * radius;

      canvas.drawCircle(
        Offset(sparkleX, sparkleY),
        1.5,
        Paint()..color = Colors.white.withOpacity(0.8),
      );
    }

    // Multi-layered magical aura
    final aura1 = Paint()
      ..color = crystalMid.withOpacity(0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22);
    canvas.drawCircle(Offset(x, y), 42, aura1);

    final aura2 = Paint()
      ..color = magicPink.withOpacity(0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
    canvas.drawCircle(Offset(x, y - 5), 35, aura2);

    final aura3 = Paint()
      ..color = magicPurple.withOpacity(0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
    canvas.drawCircle(Offset(x, y - 10), 28, aura3);
  }

  @override
  bool shouldRepaint(covariant Simple2DRoomPainter oldDelegate) {
    return oldDelegate.stage != stage ||
        oldDelegate.backgroundImage != backgroundImage ||
        oldDelegate.furniturePositions != furniturePositions ||
        oldDelegate.draggingSpotId != draggingSpotId ||
        oldDelegate.furnitureLevels != furnitureLevels;
  }
}