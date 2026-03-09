import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';

enum RoomType {
  houseBedroom,
}

extension RoomTypeExtension on RoomType {
  String get title {
    switch (this) {
      case RoomType.houseBedroom: return 'Bedroom';
    }
  }

  String get imagePath {
    switch (this) {
      case RoomType.houseBedroom:
        return 'assets/images/house_bedroom_background.png';
    }
  }

  RoomType? get nextRoom {
    switch (this) {
      case RoomType.houseBedroom: return null;
    }
  }

  Color get fallbackColor {
    switch (this) {
      case RoomType.houseBedroom: return const Color(0xFF3a2a4a);
    }
  }
}

class RoomScreen extends StatefulWidget {
  final RoomType roomType;
  const RoomScreen({super.key, required this.roomType});

  @override
  State<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends State<RoomScreen> {
  ui.Image? _backgroundImage;
  bool _showFlash = false;
  double _flashOpacity = 0.0;

  @override
  void initState() {
    super.initState();
    _loadBackground();
  }

  Future<void> _loadBackground() async {
    try {
      final ByteData data = await rootBundle.load(widget.roomType.imagePath);
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      if (mounted) setState(() => _backgroundImage = frame.image);
    } catch (e) {
      debugPrint('Background not found: $e');
    }
  }

  void _onDoorTapped() async {
    final next = widget.roomType.nextRoom;
    if (next == null) return;

    setState(() => _showFlash = true);
    for (double i = 0; i <= 1.0; i += 0.1) {
      await Future.delayed(const Duration(milliseconds: 30));
      if (mounted) setState(() => _flashOpacity = i);
    }
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => RoomScreen(roomType: next)),
    );
    for (double i = 1.0; i >= 0; i -= 0.1) {
      await Future.delayed(const Duration(milliseconds: 30));
      if (mounted) setState(() => _flashOpacity = i);
    }
    if (mounted) setState(() => _showFlash = false);
  }

  @override
  Widget build(BuildContext context) {
    final hasNextRoom = widget.roomType.nextRoom != null;

    return Scaffold(
      backgroundColor: const Color(0xFF0d0d0d),
      body: SafeArea(
        child: Stack(
          children: [
            // ── Room drawn small + centered via CustomPainter ─────────────
            Positioned.fill(
              child: _backgroundImage != null
                  ? CustomPaint(
                painter: _RoomBackgroundPainter(_backgroundImage!),
              )
                  : Container(color: widget.roomType.fallbackColor),
            ),

            // ── Bedroom furniture ─────────────────────────────────────────
            if (widget.roomType == RoomType.houseBedroom)
              Positioned.fill(
                child: LayoutBuilder(builder: (context, constraints) {
                  final w     = constraints.maxWidth;
                  final h     = constraints.maxHeight;
                  const scale = 0.75;
                  final roomW = w * scale;
                  final roomH = h * scale;
                  final left  = (w - roomW) / 2;
                  final top   = (h - roomH) / 2;

                  Widget placed(double xP, double yP, double fw, double fh,
                      CustomPainter painter) {
                    return Positioned(
                      left: left + roomW * xP,
                      top:  top  + roomH * yP,
                      width: fw, height: fh,
                      child: CustomPaint(painter: painter, size: Size(fw, fh)),
                    );
                  }

                  return Stack(children: [
                    placed(0.04, 0.18, 115, 145, const _BunkBedPainter()),
                    placed(0.62, 0.52, 100, 60,  const _BedroomTablePainter()),
                    placed(0.80, 0.28, 40,  70,  const _LampPainter()),
                  ]);
                }),
              ),

            // ── Door to next room ─────────────────────────────────────────
            if (hasNextRoom)
              Positioned(
                bottom: 370,
                left: 0,
                right: 230,
                child: Center(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _onDoorTapped,
                    child: Container(
                      width: 50,
                      height: 100,
                      color: Colors.transparent,
                      // ↑ change to Colors.red.withOpacity(0.5) to debug
                    ),
                  ),
                ),
              ),

            // ── White flash overlay ───────────────────────────────────────
            if (_showFlash)
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(
                    color: Colors.white.withOpacity(_flashOpacity),
                  ),
                ),
              ),

            // ── Room title ────────────────────────────────────────────────
            Positioned(
              top: 16,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    widget.roomType.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),

            // ── Back button ───────────────────────────────────────────────
            Positioned(
              top: 8,
              left: 8,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoomBackgroundPainter extends CustomPainter {
  final ui.Image image;
  _RoomBackgroundPainter(this.image);

  @override
  void paint(Canvas canvas, Size size) {
    // How much of the screen the room should take up (0.0 – 1.0)
    const double scale = 0.75; // ← tweak this one number

    final roomW = size.width  * scale;
    final roomH = size.height * scale;

    // Center it on the canvas
    final left = (size.width  - roomW) / 2;
    final top  = (size.height - roomH) / 2;

    final dest = Rect.fromLTWH(left, top, roomW, roomH);

    paintImage(
      canvas: canvas,
      rect: dest,
      image: image,
      fit: BoxFit.cover,
    );
  }

  @override
  bool shouldRepaint(covariant _RoomBackgroundPainter old) =>
      old.image != image;
}

// ════════════════════════════════════════════════════════════════
//  BEDROOM PAINTERS
// ════════════════════════════════════════════════════════════════

// Bunk bed — two stacked beds with a ladder on the right
class _BunkBedPainter extends CustomPainter {
  const _BunkBedPainter();
  @override
  void paint(Canvas canvas, Size s) {
    final frame   = Paint()..color = const Color(0xFF6B4423);
    final mattress= Paint()..color = const Color(0xFFf0e6d0);
    final blanket1= Paint()..color = const Color(0xFF4a7c59); // lower
    final blanket2= Paint()..color = const Color(0xFF4a6a9c); // upper
    final pillow  = Paint()..color = const Color(0xFFf5deb3);
    final ladder  = Paint()..color = const Color(0xFF8B5E3C)
      ..strokeWidth = 4 ..strokeCap = StrokeCap.round;
    final rung    = Paint()..color = const Color(0xFF8B5E3C)
      ..strokeWidth = 3 ..strokeCap = StrokeCap.round;

    // Posts (4 corners)
    for (double x in [0.04, 0.76]) {
      canvas.drawRect(Rect.fromLTWH(s.width * x, 0, 8, s.height * 0.95), frame);
    }

    // Lower bed frame
    canvas.drawRect(
        Rect.fromLTWH(s.width * 0.04, s.height * 0.52, s.width * 0.80, 10), frame);
    // Lower mattress + blanket
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(s.width * 0.04, s.height * 0.58, s.width * 0.58, s.height * 0.30),
            const Radius.circular(3)),
        mattress);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(s.width * 0.04, s.height * 0.58, s.width * 0.58, s.height * 0.20),
            const Radius.circular(3)),
        blanket1);
    // Lower pillow
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(s.width * 0.62, s.height * 0.60, s.width * 0.16, s.height * 0.22),
            const Radius.circular(4)),
        pillow);

    // Upper bed frame
    canvas.drawRect(
        Rect.fromLTWH(s.width * 0.04, s.height * 0.12, s.width * 0.80, 8), frame);
    // Upper mattress + blanket
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(s.width * 0.04, s.height * 0.18, s.width * 0.58, s.height * 0.30),
            const Radius.circular(3)),
        mattress);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(s.width * 0.04, s.height * 0.18, s.width * 0.58, s.height * 0.18),
            const Radius.circular(3)),
        blanket2);
    // Upper pillow
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(s.width * 0.62, s.height * 0.20, s.width * 0.16, s.height * 0.22),
            const Radius.circular(4)),
        pillow);

    // Safety rail on upper bed
    canvas.drawLine(Offset(s.width * 0.04, s.height * 0.10),
        Offset(s.width * 0.38, s.height * 0.10), frame..strokeWidth = 5);

    // Ladder (right side)
    canvas.drawLine(Offset(s.width * 0.84, s.height * 0.12),
        Offset(s.width * 0.84, s.height * 0.95), ladder);
    canvas.drawLine(Offset(s.width * 0.94, s.height * 0.12),
        Offset(s.width * 0.94, s.height * 0.95), ladder);
    for (int i = 1; i <= 4; i++) {
      double y = s.height * (0.12 + i * 0.16);
      canvas.drawLine(Offset(s.width * 0.84, y), Offset(s.width * 0.94, y), rung);
    }
  }
  @override bool shouldRepaint(_) => false;
}

// Simple table matching the house room table
class _BedroomTablePainter extends CustomPainter {
  const _BedroomTablePainter();
  @override
  void paint(Canvas canvas, Size s) {
    final top = Paint()..color = const Color(0xFFc8a878);
    final leg = Paint()..color = const Color(0xFFa08060)
      ..strokeWidth = 7 ..strokeCap = StrokeCap.round;
    final rim = Paint()..color = const Color(0xFFa08060)
      ..style = PaintingStyle.stroke ..strokeWidth = 1.5;

    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(0, 0, s.width, s.height * 0.22), const Radius.circular(4)),
        top);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(0, 0, s.width, s.height * 0.22), const Radius.circular(4)),
        rim);
    canvas.drawLine(Offset(s.width * 0.15, s.height * 0.22),
        Offset(s.width * 0.15, s.height), leg);
    canvas.drawLine(Offset(s.width * 0.85, s.height * 0.22),
        Offset(s.width * 0.85, s.height), leg);
  }
  @override bool shouldRepaint(_) => false;
}

// Table lamp — base, stem, shade
class _LampPainter extends CustomPainter {
  const _LampPainter();
  @override
  void paint(Canvas canvas, Size s) {
    final base  = Paint()..color = const Color(0xFF888888);
    final stem  = Paint()..color = const Color(0xFFaaaaaa)..strokeWidth = 3;
    final shade = Paint()..color = const Color(0xFFf5e6a0);
    final glow  = Paint()..color = const Color(0xFFffee88).withOpacity(0.35);

    // Base
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(s.width * 0.20, s.height * 0.82, s.width * 0.60, s.height * 0.18),
            const Radius.circular(3)),
        base);

    // Stem
    canvas.drawLine(Offset(s.width / 2, s.height * 0.82),
        Offset(s.width / 2, s.height * 0.48), stem);

    // Shade
    final shadePath = Path()
      ..moveTo(s.width * 0.08, s.height * 0.48)
      ..lineTo(s.width * 0.92, s.height * 0.48)
      ..lineTo(s.width * 0.78, s.height * 0.18)
      ..lineTo(s.width * 0.22, s.height * 0.18)
      ..close();
    canvas.drawPath(shadePath, shade);

    // Glow below shade
    canvas.drawCircle(Offset(s.width / 2, s.height * 0.56), s.width * 0.40, glow);
  }
  @override bool shouldRepaint(_) => false;
}