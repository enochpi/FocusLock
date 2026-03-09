import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import '../models/character.dart';
import '../models/cave_decorations.dart';
import '../services/currency_service.dart';
import '../services/day_night_cycle.dart';
import 'cave_shop_screen.dart';
import 'room_screen.dart';
import 'package:rive/rive.dart';


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
  bool _showFlash    = false;
  double _flashOpacity = 0.0;

  @override
  void initState() {
    super.initState();
    _loadBackgroundImage();
  }

  Future<void> _loadBackgroundImage() async {
    final path = _bgPath(widget.stage);
    try {
      final data  = await rootBundle.load(path);
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      if (mounted) setState(() => _backgroundImage = frame.image);
    } catch (_) {}
  }

  String _bgPath(int stage) {
    switch (stage) {
      case 0:  return 'assets/images/cave_background.png';
      case 1:  return 'assets/images/shack_background.png';
      case 2:  return 'assets/images/house_background.png';
      default: return 'assets/images/cave_background.png';
    }
  }

  Future<void> _onDoorTapped() async {
    setState(() { _showFlash = true; _flashOpacity = 0; });
    for (double i = 0; i <= 1.0; i += 0.1) {
      await Future.delayed(const Duration(milliseconds: 30));
      if (mounted) setState(() => _flashOpacity = i);
    }
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RoomScreen(roomType: RoomType.houseBedroom),
      ),
    );
    for (double i = 1.0; i >= 0; i -= 0.1) {
      await Future.delayed(const Duration(milliseconds: 30));
      if (mounted) setState(() => _flashOpacity = i);
    }
    if (mounted) setState(() => _showFlash = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0a0a0a),
      body: SafeArea(
        child: Stack(
          children: [
            // ── Room ────────────────────────────────────────────────────
            Positioned.fill(
              child: LayoutBuilder(builder: (context, constraints) {
                final w     = constraints.maxWidth;
                final h     = constraints.maxHeight;
                final roomW = w;
                final roomH = (w / (420.0 / 300.0)).clamp(0.0, h);
                final left  = 0.0;
                final top   = (h - roomH) / 2;

                return Stack(
                  children: [
                    // Background image
                    Positioned(
                      left: left, top: top,
                      width: roomW, height: roomH,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: _backgroundImage != null
                            ? RawImage(
                            image: _backgroundImage,
                            fit: BoxFit.cover,
                            width: roomW, height: roomH)
                            : Container(color: const Color(0xFF1a1a1a)),
                      ),
                    ),

                    // Stage furniture
                    ..._buildFurniture(widget.stage, left, top, roomW, roomH),
                  ],
                );
              }),
            ),

            // Door tap zone (house stage 2+)
            if (widget.stage >= 2)
              Positioned(
                bottom: 369, left: 0, right: 0,
                child: Center(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _onDoorTapped,
                    child: Container(width: 80, height: 120),
                  ),
                ),
              ),

            // White flash
            if (_showFlash)
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(color: Colors.white.withOpacity(_flashOpacity)),
                ),
              ),

            // Top bar
            Positioned(
              top: 16, left: 16, right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
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
                        Text('${CurrencyService().coins}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Shop button
            Positioned(
              bottom: 16, left: 0, right: 0,
              child: Center(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await Navigator.push(context,
                        MaterialPageRoute(builder: (_) => CaveShopScreen()));
                    setState(() {});
                  },
                  icon: const Icon(Icons.shopping_bag),
                  label: const Text('Furniture Shop'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 16),
                    textStyle: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Furniture layout per stage ────────────────────────────────────────
  List<Widget> _buildFurniture(
      int stage, double left, double top, double roomW, double roomH) {
    switch (stage) {
      case 0:  return _caveFurniture(left, top, roomW, roomH);
      case 1:  return _shackFurniture(left, top, roomW, roomH);
      case 2:  return _houseFurniture(left, top, roomW, roomH);
      default: return [];
    }
  }

  // ── CAVE ──────────────────────────────────────────────────────────────
  List<Widget> _caveFurniture(
      double left, double top, double roomW, double roomH) {
    final s = roomW / 420.0;
    return [
      // Earthen window — Rive animation
      Positioned(
        left: left + roomW * 0.38,
        top: top + roomH * 0.10,
        width: 80 * s,
        height: 70 * s,
        child: CustomPaint(
          painter: _EarthenWindowPainter(cycle: DayNightCycle.current()),
          size: Size(80 * s, 70 * s),
        ),
      ),

      // Stone fire — centre floor
      _placed(left + roomW * 0.43, top + roomH * 0.52, 90 * s, 90 * s,
          const _StoneFirePainter()),

      // Stone bed — left floor
      _placed(left + roomW * 0.06, top + roomH * 0.52, 140 * s, 80 * s,
          const _StoneBedPainter()),
    ];
  }

  // ── SHACK ─────────────────────────────────────────────────────────────
  List<Widget> _shackFurniture(
      double left, double top, double roomW, double roomH) {
    final s = roomW / 420.0;
    return [
      // String lights across the top
      _placed(left + roomW * 0.05, top + roomH * 0.04, roomW * 0.90, 24 * s,
          const _StringLightsPainter()),

      // Wooden window — top centre
      _placed(left + roomW * 0.40, top + roomH * 0.08, 80 * s, 68 * s,
          const _WoodWindowPainter()),

      // Wooden bed — left floor
      _placed(left + roomW * 0.04, top + roomH * 0.52, 140 * s, 84 * s,
          const _WoodBedPainter()),

      // Wood stove — right floor
      _placed(left + roomW * 0.74, top + roomH * 0.44, 88 * s, 100 * s,
          const _WoodStovePainter()),
    ];
  }

  // ── HOUSE (room 1) ────────────────────────────────────────────────────
  List<Widget> _houseFurniture(
      double left, double top, double roomW, double roomH) {
    final s = roomW / 420.0;
    return [
      // Ceiling light — centre top
      _placed(left + roomW * 0.43, top + roomH * 0.02, 70 * s, 44 * s,
          const _CeilingLightPainter()),

      // Cabinet — far left wall
      _placed(left + roomW * 0.02, top + roomH * 0.18, 64 * s, 120 * s,
          const _CabinetPainter()),

      // Gas stove + hood — left-centre floor
      _placed(left + roomW * 0.20, top + roomH * 0.40, 100 * s, 110 * s,
          const _GasStovePainter()),

      // Table — right floor
      _placed(left + roomW * 0.62, top + roomH * 0.50, 120 * s, 75 * s,
          const _TablePainter()),
    ];
  }

  // Helper: place a CustomPaint widget at absolute position
  Widget _placed(double x, double y, double w, double h, CustomPainter painter) {
    return Positioned(
      left: x, top: y, width: w, height: h,
      child: CustomPaint(painter: painter, size: Size(w, h)),
    );
  }
}
// ════════════════════════════════════════════════════════════════
//  CAVE PAINTERS
// ════════════════════════════════════════════════════════════════

// Stone fire — simple arch hearth with flame
class _StoneFirePainter extends CustomPainter {
  const _StoneFirePainter();
  @override
  void paint(Canvas canvas, Size s) {
    final stone  = Paint()..color = const Color(0xFF6b5b4e);
    final dark   = Paint()..color = const Color(0xFF1a1008);
    final orange = Paint()..color = const Color(0xFFff6600);
    final yellow = Paint()..color = const Color(0xFFffd700);

    // Stone base
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(0, s.height * 0.45, s.width, s.height * 0.55),
            const Radius.circular(4)),
        stone);

    // Arch opening
    final arch = Path()
      ..moveTo(s.width * 0.15, s.height * 0.90)
      ..lineTo(s.width * 0.15, s.height * 0.52)
      ..quadraticBezierTo(s.width / 2, s.height * 0.28, s.width * 0.85, s.height * 0.52)
      ..lineTo(s.width * 0.85, s.height * 0.90)
      ..close();
    canvas.drawPath(arch, dark);

    // Flame outer
    final flamePath = Path()
      ..moveTo(s.width / 2, s.height * 0.35)
      ..cubicTo(s.width * 0.65, s.height * 0.45, s.width * 0.72, s.height * 0.62,
          s.width * 0.62, s.height * 0.82)
      ..lineTo(s.width * 0.38, s.height * 0.82)
      ..cubicTo(s.width * 0.28, s.height * 0.62, s.width * 0.35, s.height * 0.45,
          s.width / 2, s.height * 0.35);
    canvas.drawPath(flamePath, orange);

    // Flame inner
    final innerPath = Path()
      ..moveTo(s.width / 2, s.height * 0.42)
      ..cubicTo(s.width * 0.58, s.height * 0.52, s.width * 0.60, s.height * 0.66,
          s.width * 0.54, s.height * 0.80)
      ..lineTo(s.width * 0.46, s.height * 0.80)
      ..cubicTo(s.width * 0.40, s.height * 0.66, s.width * 0.42, s.height * 0.52,
          s.width / 2, s.height * 0.42);
    canvas.drawPath(innerPath, yellow);
  }
  @override bool shouldRepaint(_) => false;
}

// Stone bed — slab base, pillow, blanket
class _StoneBedPainter extends CustomPainter {
  const _StoneBedPainter();
  @override
  void paint(Canvas canvas, Size s) {
    final slab    = Paint()..color = const Color(0xFF7a6a5a);
    final blanket = Paint()..color = const Color(0xFF8b4513);
    final pillow  = Paint()..color = const Color(0xFFd2b48c);
    final line    = Paint()..color = const Color(0xFF6a5040)..strokeWidth = 1.5;

    // Base slab
    canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(0, s.height * 0.30, s.width, s.height * 0.70),
            const Radius.circular(4)),
        slab);

    // Blanket
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(s.width * 0.28, s.height * 0.22, s.width * 0.68, s.height * 0.60),
            const Radius.circular(4)),
        blanket);

    // Blanket fold lines
    canvas.drawLine(Offset(s.width * 0.28, s.height * 0.38),
        Offset(s.width * 0.96, s.height * 0.38), line);
    canvas.drawLine(Offset(s.width * 0.28, s.height * 0.52),
        Offset(s.width * 0.96, s.height * 0.52), line);

    // Pillow
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(s.width * 0.04, s.height * 0.18, s.width * 0.22, s.height * 0.50),
            const Radius.circular(6)),
        pillow);
  }
  @override bool shouldRepaint(_) => false;
}

// ════════════════════════════════════════════════════════════════
//  SHACK PAINTERS
// ════════════════════════════════════════════════════════════════

// String lights — line with little bulb dots
class _StringLightsPainter extends CustomPainter {
  const _StringLightsPainter();
  @override
  void paint(Canvas canvas, Size s) {
    final wire = Paint()..color = const Color(0xFF555555)..strokeWidth = 1.5;
    final bulb = Paint()..color = const Color(0xFFfffaaa);
    final glow = Paint()..color = const Color(0xFFffee88).withOpacity(0.35);

    canvas.drawLine(Offset(0, s.height / 2), Offset(s.width, s.height / 2), wire);

    double spacing = s.width / 10;
    for (int i = 0; i < 10; i++) {
      double x = spacing * i + spacing / 2;
      double y = s.height / 2 + 4;
      canvas.drawCircle(Offset(x, y), 5, glow);
      canvas.drawCircle(Offset(x, y), 3, bulb);
    }
  }
  @override bool shouldRepaint(_) => false;
}

// Wooden window — warm wood frame with cross
class _WoodWindowPainter extends CustomPainter {
  const _WoodWindowPainter();
  @override
  void paint(Canvas canvas, Size s) {
    final wood  = Paint()..color = const Color(0xFF8B5E3C);
    final light = Paint()..color = const Color(0xFFe8f4ff).withOpacity(0.65);
    final bar   = Paint()..color = const Color(0xFF6B4423)..strokeWidth = 3;

    canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, s.width, s.height),
            const Radius.circular(5)),
        wood);
    canvas.drawRect(Rect.fromLTWH(7, 7, s.width - 14, s.height - 14), light);
    canvas.drawLine(Offset(s.width / 2, 7), Offset(s.width / 2, s.height - 7), bar);
    canvas.drawLine(Offset(7, s.height / 2), Offset(s.width - 7, s.height / 2), bar);
  }
  @override bool shouldRepaint(_) => false;
}

// Wooden bed — warm brown frame, blanket, pillow
class _WoodBedPainter extends CustomPainter {
  const _WoodBedPainter();
  @override
  void paint(Canvas canvas, Size s) {
    final frame   = Paint()..color = const Color(0xFF6B4423);
    final blanket = Paint()..color = const Color(0xFF4a7c59);
    final pillow  = Paint()..color = const Color(0xFFf5deb3);
    final line    = Paint()..color = const Color(0xFF3a6049)..strokeWidth = 1.5;

    // Headboard
    canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, s.width * 0.18, s.height),
            const Radius.circular(5)),
        frame);

    // Base
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(s.width * 0.18, s.height * 0.35, s.width * 0.82, s.height * 0.65),
            const Radius.circular(4)),
        frame);

    // Blanket
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(s.width * 0.20, s.height * 0.26, s.width * 0.56, s.height * 0.58),
            const Radius.circular(4)),
        blanket);
    canvas.drawLine(Offset(s.width * 0.20, s.height * 0.42),
        Offset(s.width * 0.76, s.height * 0.42), line);

    // Pillow
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(s.width * 0.76, s.height * 0.22, s.width * 0.20, s.height * 0.46),
            const Radius.circular(5)),
        pillow);
  }
  @override bool shouldRepaint(_) => false;
}

// Wood stove — dark box, pipe going up, little door
class _WoodStovePainter extends CustomPainter {
  const _WoodStovePainter();
  @override
  void paint(Canvas canvas, Size s) {
    final body  = Paint()..color = const Color(0xFF3a3a3a);
    final pipe  = Paint()..color = const Color(0xFF555555)..strokeWidth = 8..strokeCap = StrokeCap.round;
    final door  = Paint()..color = const Color(0xFF222222);
    final hinge = Paint()..color = const Color(0xFF888888)..strokeWidth = 1.5;
    final leg   = Paint()..color = const Color(0xFF2a2a2a)..strokeWidth = 5..strokeCap = StrokeCap.round;

    // Pipe
    canvas.drawLine(Offset(s.width / 2, 0), Offset(s.width / 2, s.height * 0.22), pipe);

    // Body
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(s.width * 0.10, s.height * 0.20, s.width * 0.80, s.height * 0.65),
            const Radius.circular(4)),
        body);

    // Door
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(s.width * 0.25, s.height * 0.30, s.width * 0.50, s.height * 0.40),
            const Radius.circular(3)),
        door);
    canvas.drawLine(Offset(s.width * 0.25, s.height * 0.50),
        Offset(s.width * 0.75, s.height * 0.50), hinge);

    // Legs
    canvas.drawLine(Offset(s.width * 0.22, s.height * 0.85),
        Offset(s.width * 0.22, s.height), leg);
    canvas.drawLine(Offset(s.width * 0.78, s.height * 0.85),
        Offset(s.width * 0.78, s.height), leg);
  }
  @override bool shouldRepaint(_) => false;
}

// ════════════════════════════════════════════════════════════════
//  HOUSE PAINTERS
// ════════════════════════════════════════════════════════════════

// Ceiling light — round fixture with warm glow
class _CeilingLightPainter extends CustomPainter {
  const _CeilingLightPainter();
  @override
  void paint(Canvas canvas, Size s) {
    final wire   = Paint()..color = const Color(0xFF888888)..strokeWidth = 2;
    final shade  = Paint()..color = const Color(0xFFddccaa);
    final glow   = Paint()..color = const Color(0xFFffeeaa).withOpacity(0.4);
    final bulb   = Paint()..color = const Color(0xFFffee88);

    canvas.drawLine(Offset(s.width / 2, 0), Offset(s.width / 2, s.height * 0.30), wire);

    // Shade
    final shadePath = Path()
      ..moveTo(s.width * 0.15, s.height * 0.30)
      ..lineTo(s.width * 0.85, s.height * 0.30)
      ..lineTo(s.width * 0.72, s.height * 0.75)
      ..lineTo(s.width * 0.28, s.height * 0.75)
      ..close();
    canvas.drawPath(shadePath, shade);

    // Glow circle below
    canvas.drawCircle(Offset(s.width / 2, s.height * 0.85), s.width * 0.38, glow);
    canvas.drawCircle(Offset(s.width / 2, s.height * 0.72), 5, bulb);
  }
  @override bool shouldRepaint(_) => false;
}

// Cabinet — tall two-door with handles
class _CabinetPainter extends CustomPainter {
  const _CabinetPainter();
  @override
  void paint(Canvas canvas, Size s) {
    final body   = Paint()..color = const Color(0xFFd0b896);
    final border = Paint()..color = const Color(0xFFa08060)..style = PaintingStyle.stroke..strokeWidth = 1.5;
    final handle = Paint()..color = const Color(0xFF888888)..strokeWidth = 2..strokeCap = StrokeCap.round;

    canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, s.width, s.height),
            const Radius.circular(4)),
        body);
    canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, s.width, s.height),
            const Radius.circular(4)),
        border);

    // Divider line (two doors)
    final mid = s.height * 0.52;
    canvas.drawLine(Offset(0, mid), Offset(s.width, mid), border);

    // Door lines
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(4, 4, s.width - 8, mid - 6), const Radius.circular(2)),
        border);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(4, mid + 2, s.width - 8, s.height - mid - 6),
            const Radius.circular(2)),
        border);

    // Handles
    canvas.drawLine(Offset(s.width * 0.35, mid * 0.54),
        Offset(s.width * 0.65, mid * 0.54), handle);
    canvas.drawLine(Offset(s.width * 0.35, mid + (s.height - mid) * 0.48),
        Offset(s.width * 0.65, mid + (s.height - mid) * 0.48), handle);
  }
  @override bool shouldRepaint(_) => false;
}

// Gas stove — counter with burners + hood above
class _GasStovePainter extends CustomPainter {
  const _GasStovePainter();
  @override
  void paint(Canvas canvas, Size s) {
    final hood   = Paint()..color = const Color(0xFFaaaaaa);
    final body   = Paint()..color = const Color(0xFFe8e8e8);
    final burner = Paint()..color = const Color(0xFF555555);
    final ring   = Paint()..color = const Color(0xFF333333)..style = PaintingStyle.stroke..strokeWidth = 1.5;
    final pipe   = Paint()..color = const Color(0xFF999999)..strokeWidth = 4..strokeCap = StrokeCap.round;

    // Hood
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(s.width * 0.05, 0, s.width * 0.90, s.height * 0.28),
            const Radius.circular(3)),
        hood);

    // Pipe from hood to ceiling
    canvas.drawLine(Offset(s.width / 2, 0), Offset(s.width / 2, -16), pipe);

    // Stove body
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(0, s.height * 0.40, s.width, s.height * 0.60),
            const Radius.circular(4)),
        body);

    // 4 burners (2x2 grid)
    final burnerPositions = [
      Offset(s.width * 0.28, s.height * 0.56),
      Offset(s.width * 0.72, s.height * 0.56),
      Offset(s.width * 0.28, s.height * 0.78),
      Offset(s.width * 0.72, s.height * 0.78),
    ];
    for (final pos in burnerPositions) {
      canvas.drawCircle(pos, 9, burner);
      canvas.drawCircle(pos, 9, ring);
      canvas.drawCircle(pos, 4, ring);
    }
  }
  @override bool shouldRepaint(_) => false;
}

// Table — simple rectangle top with two legs
class _TablePainter extends CustomPainter {
  const _TablePainter();
  @override
  void paint(Canvas canvas, Size s) {
    final top = Paint()..color = const Color(0xFFc8a878);
    final leg = Paint()..color = const Color(0xFFa08060)..strokeWidth = 7..strokeCap = StrokeCap.round;
    final rim = Paint()..color = const Color(0xFFa08060)..style = PaintingStyle.stroke..strokeWidth = 1.5;

    // Table top
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(0, 0, s.width, s.height * 0.22), const Radius.circular(4)),
        top);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(0, 0, s.width, s.height * 0.22), const Radius.circular(4)),
        rim);

    // Legs
    canvas.drawLine(Offset(s.width * 0.15, s.height * 0.22),
        Offset(s.width * 0.15, s.height), leg);
    canvas.drawLine(Offset(s.width * 0.85, s.height * 0.22),
        Offset(s.width * 0.85, s.height), leg);

    // Cross support
    canvas.drawLine(Offset(s.width * 0.15, s.height * 0.70),
        Offset(s.width * 0.85, s.height * 0.70),
        Paint()..color = const Color(0xFFa08060)..strokeWidth = 3);
  }
  @override bool shouldRepaint(_) => false;
}