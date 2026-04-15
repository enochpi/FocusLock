import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:ui' as ui;

// ========================================
// STAGE 0: CAVE — Small rough patch
// Rocky ground, 6 plants, stick fence
// ========================================
class StrawberryPatchSmallPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    _drawRockyBed(canvas, w, h);
    _drawStickFence(canvas, w, h);

    // 2 rows x 3 cols
    const rows = 2;
    const cols = 3;
    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        final x = w * 0.2 + col * (w * 0.6 / (cols - 1));
        final y = h * 0.52 + row * h * 0.26;
        _drawStrawberryClump(canvas, x, y, 0.7, 2, row * 31 + col * 17);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ========================================
// STAGE 1: SHACK — Medium organized patch
// Better soil, tilled rows, 12 plants, wood fence
// ========================================
class StrawberryPatchMediumPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    _drawRaisedBed(canvas, w, h, const Color(0xFF795548), const Color(0xFF6D4C41), const Color(0xFF5D4037));

    // Tilled rows
    for (int i = 0; i < 3; i++) {
      final y = h * 0.41 + i * h * 0.185;
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.07, y - h * 0.045, w * 0.86, h * 0.09), const Radius.circular(4)),
        Paint()..shader = ui.Gradient.linear(
          Offset(0, y - h * 0.045), Offset(0, y + h * 0.045),
          [const Color(0xFF8D6E63), const Color(0xFF6D4C41)],
        ),
      );
    }

    _drawWoodFence(canvas, w, h, h * 0.22, 8, const Color(0xFFBCAAA4), const Color(0xFF8D6E63));

    // 3 rows x 4 cols
    const rows = 3;
    const cols = 4;
    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        final x = w * 0.14 + col * (w * 0.72 / (cols - 1));
        final y = h * 0.435 + row * h * 0.185;
        _drawStrawberryClump(canvas, x, y, 0.9, 3, row * 31 + col * 17);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ========================================
// STAGE 2: HOUSE — Large lush patch
// Rich soil, 20 plants, white fence, decorations
// ========================================
class StrawberryPatchLargePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    _drawRaisedBed(canvas, w, h, const Color(0xFF5D4037), const Color(0xFF4E342E), const Color(0xFF3E2723));

    // Tilled rows
    for (int i = 0; i < 4; i++) {
      final y = h * 0.385 + i * h * 0.152;
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.05, y - h * 0.038, w * 0.9, h * 0.082), const Radius.circular(4)),
        Paint()..shader = ui.Gradient.linear(
          Offset(0, y - h * 0.038), Offset(0, y + h * 0.044),
          [const Color(0xFF795548), const Color(0xFF4E342E)],
        ),
      );
    }

    // Stone border
    for (int i = 0; i < 15; i++) {
      final bx = w * 0.015 + i * w * 0.067;
      final vary = (i % 3) * 1.5;
      canvas.drawOval(
        Rect.fromCenter(center: Offset(bx, h * 0.275 + vary), width: w * 0.055, height: 8),
        Paint()..shader = ui.Gradient.linear(
          Offset(bx, h * 0.27), Offset(bx, h * 0.284),
          [const Color(0xFFBDBDBD), const Color(0xFF757575)],
        ),
      );
    }

    _drawWoodFence(canvas, w, h, h * 0.2, 10, const Color(0xFFF5F5F5), const Color(0xFFBDBDBD));

    // Small flower decorations at corners
    _drawFlower(canvas, w * 0.05, h * 0.36);
    _drawFlower(canvas, w * 0.95, h * 0.36);

    // 4 rows x 5 cols
    const rows = 4;
    const cols = 5;
    for (int row = 0; row < rows; row++) {
      for (int col = 0; col < cols; col++) {
        final x = w * 0.12 + col * (w * 0.76 / (cols - 1));
        final y = h * 0.4 + row * h * 0.152;
        _drawStrawberryClump(canvas, x, y, 1.0, 4, row * 31 + col * 17);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ========================================
// Core: Strawberry clump (plant + berries)
// x, y = center base of plant
// scale = size multiplier
// berryCount = how many ripe berries
// seed = for pseudo-random variety
// ========================================
void _drawStrawberryClump(Canvas canvas, double x, double y, double s, int berryCount, int seed) {
  final rng = Random(seed);

  // Ground cover — low spreading leaves
  for (int i = 0; i < 5; i++) {
    final angle = -pi * 0.8 + i * (pi * 1.6 / 4);
    final lx = x + cos(angle) * 10 * s;
    final ly = y - 4 * s + sin(angle) * 4 * s;
    _drawGroundLeaf(canvas, lx, ly, angle, 9 * s, 6 * s,
        i % 2 == 0 ? const Color(0xFF388E3C) : const Color(0xFF2E7D32));
  }

  // Upright center leaves
  _drawUprightLeaf(canvas, x - 5 * s, y - 8 * s, -0.35, 13 * s, const Color(0xFF43A047));
  _drawUprightLeaf(canvas, x + 5 * s, y - 8 * s, 0.35, 12 * s, const Color(0xFF4CAF50));
  _drawUprightLeaf(canvas, x, y - 10 * s, 0.0, 14 * s, const Color(0xFF388E3C));

  // Berries — scattered naturally around plant
  final berryOffsets = [
    Offset(-8 * s, -2 * s),
    Offset(8 * s, -3 * s),
    Offset(-3 * s, 4 * s),
    Offset(6 * s, 3 * s),
    Offset(-6 * s, 5 * s),
  ];

  for (int i = 0; i < berryCount.clamp(0, berryOffsets.length); i++) {
    final off = berryOffsets[i];
    final bx = x + off.dx;
    final by = y + off.dy;
    final ripe = i < berryCount - (berryCount > 2 ? 1 : 0); // last one slightly less ripe
    _drawBerry(canvas, bx, by, s * (0.85 + rng.nextDouble() * 0.2), ripe);
  }

  // Unripe small berries (green) for realism
  if (berryCount >= 3) {
    _drawUnripeBerry(canvas, x + 2 * s, y - 5 * s, s * 0.55);
    _drawUnripeBerry(canvas, x - 4 * s, y - 3 * s, s * 0.5);
  }
}

void _drawBerry(Canvas canvas, double x, double y, double s, bool ripe) {
  // Stem
  canvas.drawLine(Offset(x, y - 6 * s), Offset(x, y - 2 * s),
      Paint()..color = const Color(0xFF388E3C)..strokeWidth = 1.2 * s..strokeCap = StrokeCap.round);

  // Tiny crown leaves
  for (int c = -1; c <= 1; c++) {
    final lp = Path()
      ..moveTo(x, y - 2 * s)
      ..quadraticBezierTo(x + c * 4 * s, y - 6 * s, x + c * 3 * s, y - 4 * s);
    canvas.drawPath(lp, Paint()
      ..color = const Color(0xFF4CAF50)
      ..strokeWidth = 1.4 * s
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round);
  }

  final color1 = ripe ? const Color(0xFFEF5350) : const Color(0xFFEF9A9A);
  final color2 = ripe ? const Color(0xFFB71C1C) : const Color(0xFFE57373);

  // Berry body
  final bp = Path()
    ..moveTo(x, y + 8 * s)
    ..quadraticBezierTo(x - 6 * s, y + 4 * s, x - 5 * s, y - 1 * s)
    ..quadraticBezierTo(x - 2 * s, y - 2 * s, x, y)
    ..quadraticBezierTo(x + 2 * s, y - 2 * s, x + 5 * s, y - 1 * s)
    ..quadraticBezierTo(x + 6 * s, y + 4 * s, x, y + 8 * s)
    ..close();

  canvas.drawPath(bp,
      Paint()..shader = ui.Gradient.linear(
        Offset(x - 5 * s, y), Offset(x + 5 * s, y + 8 * s),
        [color1, color2],
      ));

  canvas.drawPath(bp,
      Paint()..color = color2.withOpacity(0.4)..style = PaintingStyle.stroke..strokeWidth = 0.7 * s);

  // Seeds
  final seedPos = [
    Offset(-2.5 * s, 2 * s), Offset(2.5 * s, 2 * s),
    Offset(-3 * s, 5 * s), Offset(0, 4 * s), Offset(3 * s, 5 * s),
  ];
  for (final sp in seedPos) {
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x + sp.dx, y + sp.dy), width: 1.4 * s, height: 2 * s),
      Paint()..color = const Color(0xFFFFEE58).withOpacity(0.85),
    );
  }

  // Shine
  canvas.drawOval(
    Rect.fromCenter(center: Offset(x - 2 * s, y + 1 * s), width: 2.5 * s, height: 4 * s),
    Paint()..color = Colors.white.withOpacity(0.28),
  );
}

void _drawUnripeBerry(Canvas canvas, double x, double y, double s) {
  canvas.drawLine(Offset(x, y - 5 * s), Offset(x, y - 1 * s),
      Paint()..color = const Color(0xFF388E3C)..strokeWidth = s..strokeCap = StrokeCap.round);

  final bp = Path()
    ..moveTo(x, y + 6 * s)
    ..quadraticBezierTo(x - 4 * s, y + 3 * s, x - 3.5 * s, y - 0.5 * s)
    ..quadraticBezierTo(x, y - 1.5 * s, x + 3.5 * s, y - 0.5 * s)
    ..quadraticBezierTo(x + 4 * s, y + 3 * s, x, y + 6 * s)
    ..close();

  canvas.drawPath(bp, Paint()..color = const Color(0xFF81C784));
  canvas.drawPath(bp, Paint()..color = const Color(0xFF2E7D32).withOpacity(0.3)..style = PaintingStyle.stroke..strokeWidth = 0.6 * s);
}

void _drawGroundLeaf(Canvas canvas, double x, double y, double angle, double len, double width, Color color) {
  canvas.save();
  canvas.translate(x, y);
  canvas.rotate(angle);
  final path = Path()
    ..moveTo(0, 0)
    ..quadraticBezierTo(width * 0.6, -len * 0.35, 0, -len)
    ..quadraticBezierTo(-width * 0.6, -len * 0.35, 0, 0);
  canvas.drawPath(path, Paint()..color = color);
  canvas.drawLine(Offset.zero, Offset(0, -len * 0.75),
      Paint()..color = const Color(0xFF1B5E20).withOpacity(0.3)..strokeWidth = 0.6);
  canvas.restore();
}

void _drawUprightLeaf(Canvas canvas, double x, double y, double tilt, double len, Color color) {
  canvas.save();
  canvas.translate(x, y);
  canvas.rotate(tilt);
  final w = len * 0.45;
  final path = Path()
    ..moveTo(0, 0)
    ..quadraticBezierTo(w, -len * 0.4, 0, -len)
    ..quadraticBezierTo(-w, -len * 0.4, 0, 0);
  canvas.drawPath(path, Paint()..color = color);
  canvas.drawLine(Offset.zero, Offset(0, -len * 0.8),
      Paint()..color = const Color(0xFF1B5E20).withOpacity(0.35)..strokeWidth = 0.7);
  canvas.restore();
}

void _drawFlower(Canvas canvas, double x, double y) {
  final petalPaint = Paint()..color = const Color(0xFFFFF9C4);
  for (int i = 0; i < 5; i++) {
    final angle = i * pi * 2 / 5;
    canvas.drawCircle(Offset(x + cos(angle) * 4, y + sin(angle) * 4), 2.5, petalPaint);
  }
  canvas.drawCircle(Offset(x, y), 2.5, Paint()..color = const Color(0xFFFFD54F));
}

// ========================================
// STAGE 0: Rocky bed
// ========================================
void _drawRockyBed(Canvas canvas, double w, double h) {
  // Dark rough soil
  canvas.drawRRect(
    RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.02, h * 0.3, w * 0.96, h * 0.65), const Radius.circular(10)),
    Paint()..color = const Color(0xFF3E2723),
  );
  final soilRect = Rect.fromLTWH(w * 0.03, h * 0.31, w * 0.94, h * 0.62);
  canvas.drawRRect(
    RRect.fromRectAndRadius(soilRect, const Radius.circular(8)),
    Paint()..shader = ui.Gradient.linear(
      Offset(0, soilRect.top), Offset(0, soilRect.bottom),
      [const Color(0xFF5D4037), const Color(0xFF3E2723)],
    ),
  );

  // Rocks scattered
  final rng = Random(7);
  for (int i = 0; i < 10; i++) {
    final rx = w * 0.06 + rng.nextDouble() * w * 0.88;
    final ry = h * 0.35 + rng.nextDouble() * h * 0.52;
    final rs = 3.0 + rng.nextDouble() * 5;
    canvas.drawOval(
      Rect.fromCenter(center: Offset(rx, ry), width: rs * 2, height: rs),
      Paint()..color = const Color(0xFF757575).withOpacity(0.35 + rng.nextDouble() * 0.2),
    );
  }
}

// ========================================
// STAGE 0: Stick fence
// ========================================
void _drawStickFence(Canvas canvas, double w, double h) {
  final paint = Paint()..color = const Color(0xFF8D6E63)..strokeWidth = 2.5..strokeCap = StrokeCap.round;
  final count = 10;
  for (int i = 0; i < count; i++) {
    final fx = w * 0.03 + i * (w * 0.94 / (count - 1));
    canvas.drawLine(Offset(fx, h * 0.24), Offset(fx, h * 0.36), paint);
    // Pointed top
    canvas.drawLine(Offset(fx - 3, h * 0.255), Offset(fx, h * 0.24), paint);
    canvas.drawLine(Offset(fx + 3, h * 0.255), Offset(fx, h * 0.24), paint);
  }
  // Horizontal rail
  canvas.drawLine(Offset(w * 0.03, h * 0.31), Offset(w * 0.97, h * 0.31),
      Paint()..color = const Color(0xFF8D6E63)..strokeWidth = 2);
}

// ========================================
// SHARED: Raised garden bed
// ========================================
void _drawRaisedBed(Canvas canvas, double w, double h, Color top, Color mid, Color bottom) {
  canvas.drawRRect(
    RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.03, h * 0.32, w * 0.94, h * 0.64), const Radius.circular(12)),
    Paint()..color = Colors.black.withOpacity(0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
  );
  canvas.drawRRect(
    RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.02, h * 0.3, w * 0.96, h * 0.65), const Radius.circular(12)),
    Paint()..color = const Color(0xFF3E2723),
  );
  final soilRect = Rect.fromLTWH(w * 0.03, h * 0.31, w * 0.94, h * 0.62);
  canvas.drawRRect(
    RRect.fromRectAndRadius(soilRect, const Radius.circular(10)),
    Paint()..shader = ui.Gradient.linear(
      Offset(0, soilRect.top), Offset(0, soilRect.bottom),
      [top, mid, bottom], [0.0, 0.4, 1.0],
    ),
  );
  final rng = Random(42);
  for (int i = 0; i < 40; i++) {
    final sx = w * 0.06 + rng.nextDouble() * w * 0.88;
    final sy = h * 0.35 + rng.nextDouble() * h * 0.52;
    canvas.drawCircle(Offset(sx, sy), 1 + rng.nextDouble(),
        Paint()..color = top.withOpacity(0.15 + rng.nextDouble() * 0.12));
  }
}

// ========================================
// SHARED: Wooden fence
// ========================================
void _drawWoodFence(Canvas canvas, double w, double h, double fenceTop, int postCount, Color light, Color dark) {
  final fenceH = h * 0.12;
  for (int i = 0; i < postCount; i++) {
    final fx = w * 0.03 + i * (w * 0.94) / (postCount - 1);
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(fx - 2.5, fenceTop, 5, fenceH), const Radius.circular(2)),
      Paint()..shader = ui.Gradient.linear(
        Offset(fx - 2.5, 0), Offset(fx + 2.5, 0),
        [dark, light, dark], [0.0, 0.35, 1.0],
      ),
    );
    canvas.drawCircle(Offset(fx, fenceTop - 1), 4,
        Paint()..shader = ui.Gradient.radial(Offset(fx - 1, fenceTop - 2), 4, [light, dark]));
  }
  for (int r = 0; r < 2; r++) {
    final ry = fenceTop + fenceH * (r == 0 ? 0.3 : 0.7);
    canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.03, ry + 1, w * 0.94, 3.5), const Radius.circular(1)),
        Paint()..color = Colors.black.withOpacity(0.06));
    canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.03, ry, w * 0.94, 3.5), const Radius.circular(1)),
        Paint()..color = light);
  }
}

// ========================================
// HELPER
// ========================================
CustomPainter getGardenPainter(int stage) {
  switch (stage) {
    case 0: return StrawberryPatchSmallPainter();
    case 1: return StrawberryPatchMediumPainter();
    case 2: return StrawberryPatchLargePainter();
    default: return StrawberryPatchSmallPainter();
  }
}