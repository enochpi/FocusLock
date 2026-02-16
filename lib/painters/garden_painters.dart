import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:ui' as ui;

// ========================================
// STAGE 0: PEA GARDEN
// ========================================
class PeaGardenPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // ── RAISED BED ──
    _drawRaisedBed(canvas, w, h, const Color(0xFF6D4C41), const Color(0xFF5D4037), const Color(0xFF4E342E));

    // ── TILLED ROWS ──
    for (int i = 0; i < 4; i++) {
      final y = h * 0.38 + i * h * 0.14;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.07, y, w * 0.86, h * 0.09),
          const Radius.circular(5),
        ),
        Paint()..shader = ui.Gradient.linear(
          Offset(0, y), Offset(0, y + h * 0.09),
          [const Color(0xFF795548), const Color(0xFF5D4037)],
        ),
      );
    }

    // ── PEA PLANTS ──
    for (int row = 0; row < 4; row++) {
      for (int col = 0; col < 6; col++) {
        final x = w * 0.12 + col * w * 0.145;
        final y = h * 0.38 + row * h * 0.14;
        _drawPeaPlant(canvas, x, y);
      }
    }

    // ── FENCE ──
    _drawWoodFence(canvas, w, h, h * 0.22, 8, const Color(0xFFA1887F), const Color(0xFF8D6E63));
  }

  void _drawPeaPlant(Canvas canvas, double x, double y) {
    // Main stem
    final stemPath = Path()
      ..moveTo(x, y + 8)
      ..cubicTo(x - 1, y, x + 1, y - 10, x, y - 20);
    canvas.drawPath(stemPath,
        Paint()..color = const Color(0xFF388E3C)..strokeWidth = 2.2
          ..style = PaintingStyle.stroke..strokeCap = StrokeCap.round);

    // Tendrils
    final tendrilPath = Path()
      ..moveTo(x, y - 15)
      ..quadraticBezierTo(x + 8, y - 20, x + 6, y - 25);
    canvas.drawPath(tendrilPath,
        Paint()..color = const Color(0xFF66BB6A).withOpacity(0.7)..strokeWidth = 0.8
          ..style = PaintingStyle.stroke);

    // Leaves
    _drawOvalLeaf(canvas, x - 6, y - 12, 7, 4.5, -0.4, const Color(0xFF4CAF50));
    _drawOvalLeaf(canvas, x + 6, y - 10, 7, 4.5, 0.4, const Color(0xFF66BB6A));
    _drawOvalLeaf(canvas, x - 4, y - 19, 6, 3.5, -0.2, const Color(0xFF43A047));

    // Pea pod
    final podPath = Path()
      ..moveTo(x + 3, y - 2)
      ..quadraticBezierTo(x + 13, y - 1, x + 11, y + 6)
      ..quadraticBezierTo(x + 6, y + 8, x + 3, y - 2);
    canvas.drawPath(podPath,
        Paint()..shader = ui.Gradient.linear(
          Offset(x + 3, y - 2), Offset(x + 11, y + 6),
          [const Color(0xFF81C784), const Color(0xFF4CAF50)],
        ));
    canvas.drawPath(podPath,
        Paint()..color = const Color(0xFF388E3C)..style = PaintingStyle.stroke..strokeWidth = 0.8);

    // Pea bumps
    for (int p = 0; p < 3; p++) {
      canvas.drawCircle(Offset(x + 5.5 + p * 2.5, y + 2), 1.8,
          Paint()..color = const Color(0xFFA5D6A7).withOpacity(0.6));
    }
  }

  void _drawOvalLeaf(Canvas canvas, double x, double y, double len, double width, double angle, Color color) {
    canvas.save();
    canvas.translate(x, y);
    canvas.rotate(angle);
    final path = Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(width, -len * 0.4, 0, -len)
      ..quadraticBezierTo(-width, -len * 0.4, 0, 0);
    canvas.drawPath(path, Paint()..color = color);
    canvas.drawLine(Offset.zero, Offset(0, -len * 0.75),
        Paint()..color = const Color(0xFF2E7D32).withOpacity(0.3)..strokeWidth = 0.5);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ========================================
// STAGE 1: CARROT GARDEN
// ========================================
class CarrotGardenPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // ── RAISED BED ──
    _drawRaisedBed(canvas, w, h, const Color(0xFF795548), const Color(0xFF6D4C41), const Color(0xFF5D4037));

    // ── TILLED ROWS ──
    for (int i = 0; i < 4; i++) {
      final y = h * 0.38 + i * h * 0.14;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.06, y, w * 0.88, h * 0.09),
          const Radius.circular(5),
        ),
        Paint()..shader = ui.Gradient.linear(
          Offset(0, y), Offset(0, y + h * 0.09),
          [const Color(0xFF8D6E63), const Color(0xFF6D4C41)],
        ),
      );
    }

    // ── CARROTS ──
    for (int row = 0; row < 4; row++) {
      for (int col = 0; col < 7; col++) {
        final x = w * 0.09 + col * w * 0.125;
        final y = h * 0.37 + row * h * 0.14;
        _drawCarrot(canvas, x, y);
      }
    }

    // ── FENCE ──
    _drawWoodFence(canvas, w, h, h * 0.2, 9, const Color(0xFFBCAAA4), const Color(0xFFA1887F));
  }

  void _drawCarrot(Canvas canvas, double x, double y) {
    // Leafy tops (feathery spray)
    for (int s = -3; s <= 3; s++) {
      final topPath = Path()
        ..moveTo(x, y + 2)
        ..quadraticBezierTo(x + s * 3.5, y - 12, x + s * 5, y - 22 - (s.abs() < 2 ? 5 : 0));
      canvas.drawPath(topPath,
          Paint()..color = Color.lerp(const Color(0xFF388E3C), const Color(0xFF66BB6A), (s + 3) / 6)!
            ..strokeWidth = 1.8..style = PaintingStyle.stroke..strokeCap = StrokeCap.round);
    }

    // Small leaf detail
    for (int s = -1; s <= 1; s += 2) {
      canvas.drawCircle(Offset(x + s * 3, y - 16), 3,
          Paint()..color = const Color(0xFF4CAF50).withOpacity(0.5));
    }

    // Carrot body
    final carrotPath = Path()
      ..moveTo(x - 5, y + 3)
      ..quadraticBezierTo(x - 4.5, y + 12, x, y + 20)
      ..quadraticBezierTo(x + 4.5, y + 12, x + 5, y + 3)
      ..close();
    canvas.drawPath(carrotPath,
        Paint()..shader = ui.Gradient.linear(
          Offset(x - 5, y), Offset(x + 5, y),
          [const Color(0xFFEF6C00), const Color(0xFFFF9800), const Color(0xFFEF6C00)],
          [0.0, 0.35, 1.0],
        ));

    // Horizontal lines
    for (int i = 1; i <= 3; i++) {
      final ly = y + 5 + i * 3.5;
      final halfW = 4.5 - i * 0.8;
      canvas.drawLine(Offset(x - halfW, ly), Offset(x + halfW, ly),
          Paint()..color = const Color(0xFFE65100).withOpacity(0.25)..strokeWidth = 0.6);
    }

    // Highlight
    canvas.drawLine(Offset(x - 1.5, y + 5), Offset(x - 1, y + 14),
        Paint()..color = const Color(0xFFFFCC80).withOpacity(0.5)..strokeWidth = 1.2
          ..strokeCap = StrokeCap.round);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ========================================
// STAGE 2: CORN FIELD
// ========================================
class CornGardenPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // ── SOIL BED ──
    _drawRaisedBed(canvas, w, h, const Color(0xFF6D4C41), const Color(0xFF5D4037), const Color(0xFF4E342E));

    // ── CORN STALKS ──
    for (int col = 0; col < 7; col++) {
      final x = w * 0.08 + col * w * 0.13;
      final baseY = h * 0.93;
      final topY = h * 0.04 + (col % 2) * h * 0.06;
      _drawCornStalk(canvas, x, topY, baseY, w);
    }

    // ── SCARECROW ──
    _drawScarecrow(canvas, w * 0.92, h * 0.12, h);
  }

  void _drawCornStalk(Canvas canvas, double x, double topY, double baseY, double w) {
    final stalkH = baseY - topY;

    // Stalk shadow
    canvas.drawLine(Offset(x + 3, baseY), Offset(x + 4, topY + 20),
        Paint()..color = Colors.black.withOpacity(0.05)..strokeWidth = 6);

    // Main stalk
    final stalkRect = Rect.fromLTWH(x - 2.5, topY, 5, stalkH);
    canvas.drawRRect(
      RRect.fromRectAndRadius(stalkRect, const Radius.circular(2)),
      Paint()..shader = ui.Gradient.linear(
        Offset(x - 2.5, 0), Offset(x + 2.5, 0),
        [const Color(0xFF558B2F), const Color(0xFF7CB342), const Color(0xFF558B2F)],
        [0.0, 0.35, 1.0],
      ),
    );

    // Nodes
    for (int n = 1; n < 5; n++) {
      final ny = topY + n * stalkH / 5;
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, ny), width: 8, height: 5),
        Paint()..color = const Color(0xFF689F38),
      );
    }

    // Leaves (alternating)
    for (int leaf = 0; leaf < 4; leaf++) {
      final ly = topY + stalkH * (leaf + 1) / 5.5;
      final dir = (leaf % 2 == 0) ? -1.0 : 1.0;

      final leafPath = Path()
        ..moveTo(x, ly)
        ..cubicTo(
          x + dir * w * 0.04, ly - 8,
          x + dir * w * 0.08, ly - 4,
          x + dir * w * 0.1, ly + 10,
        )
        ..cubicTo(
          x + dir * w * 0.06, ly + 6,
          x + dir * w * 0.02, ly + 2,
          x, ly,
        );

      canvas.drawPath(leafPath,
          Paint()..shader = ui.Gradient.linear(
            Offset(x, ly), Offset(x + dir * w * 0.1, ly),
            [const Color(0xFF7CB342), const Color(0xFF8BC34A), const Color(0xFF689F38)],
            [0.0, 0.4, 1.0],
          ));

      // Leaf center vein
      canvas.drawLine(Offset(x, ly), Offset(x + dir * w * 0.07, ly + 3),
          Paint()..color = const Color(0xFF558B2F).withOpacity(0.3)..strokeWidth = 0.5);
    }

    // Corn cob
    final cobY = topY + stalkH * 0.3;

    // Husk leaves
    final husk1 = Path()
      ..moveTo(x + 5, cobY - 12)
      ..quadraticBezierTo(x + 16, cobY - 6, x + 13, cobY + 6)
      ..quadraticBezierTo(x + 7, cobY + 4, x + 5, cobY - 12);
    canvas.drawPath(husk1, Paint()..color = const Color(0xFF8BC34A));
    final husk2 = Path()
      ..moveTo(x + 4, cobY - 10)
      ..quadraticBezierTo(x + 14, cobY - 2, x + 10, cobY + 8)
      ..quadraticBezierTo(x + 5, cobY + 6, x + 4, cobY - 10);
    canvas.drawPath(husk2, Paint()..color = const Color(0xFF9CCC65).withOpacity(0.7));

    // Cob
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(x + 7, cobY), width: 10, height: 18),
        const Radius.circular(5),
      ),
      Paint()..shader = ui.Gradient.linear(
        Offset(x + 2, cobY), Offset(x + 12, cobY),
        [const Color(0xFFFDD835), const Color(0xFFFFEE58), const Color(0xFFFDD835)],
        [0.0, 0.4, 1.0],
      ),
    );

    // Kernel grid
    for (int ky = -3; ky <= 3; ky++) {
      for (int kx = 0; kx < 2; kx++) {
        canvas.drawCircle(
          Offset(x + 5 + kx * 4, cobY + ky * 2.5),
          1.3,
          Paint()..color = const Color(0xFFF9A825).withOpacity(0.7),
        );
      }
    }

    // Silk
    for (int s = -1; s <= 1; s++) {
      final silkPath = Path()
        ..moveTo(x + 1, topY + 8)
        ..quadraticBezierTo(x + s * 4, topY - 4, x + s * 3, topY - 10);
      canvas.drawPath(silkPath,
          Paint()..color = const Color(0xFFFFE082).withOpacity(0.6)..strokeWidth = 0.8
            ..style = PaintingStyle.stroke);
    }
  }

  void _drawScarecrow(Canvas canvas, double x, double y, double h) {
    // Pole
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(x - 2, y + 10, 4, h * 0.72), const Radius.circular(2)),
      Paint()..shader = ui.Gradient.linear(
        Offset(x - 2, 0), Offset(x + 2, 0),
        [const Color(0xFF6D4C41), const Color(0xFF8D6E63), const Color(0xFF5D4037)],
        [0.0, 0.4, 1.0],
      ),
    );

    // Arms
    canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(x - 16, y + 22, 32, 3), const Radius.circular(1)),
        Paint()..color = const Color(0xFF6D4C41));

    // Head
    canvas.drawCircle(Offset(x, y + 4), 10,
        Paint()..shader = ui.Gradient.radial(
          Offset(x - 2, y + 2), 10,
          [const Color(0xFFFFCC80), const Color(0xFFFFB74D)],
        ));

    // Hat brim
    canvas.drawOval(
        Rect.fromCenter(center: Offset(x, y - 7), width: 28, height: 8),
        Paint()..color = const Color(0xFF5D4037));
    // Hat body
    canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(x - 8, y - 22, 16, 16), const Radius.circular(3)),
        Paint()..shader = ui.Gradient.linear(
          Offset(x - 8, 0), Offset(x + 8, 0),
          [const Color(0xFF5D4037), const Color(0xFF6D4C41), const Color(0xFF4E342E)],
          [0.0, 0.4, 1.0],
        ));

    // Eyes (X shapes)
    for (int side = -1; side <= 1; side += 2) {
      final ex = x + side * 4;
      final ey = y + 2;
      canvas.drawLine(Offset(ex - 2, ey - 2), Offset(ex + 2, ey + 2),
          Paint()..color = Colors.black..strokeWidth = 1.5);
      canvas.drawLine(Offset(ex + 2, ey - 2), Offset(ex - 2, ey + 2),
          Paint()..color = Colors.black..strokeWidth = 1.5);
    }

    // Smile
    canvas.drawArc(
      Rect.fromCenter(center: Offset(x, y + 7), width: 8, height: 5),
      0, pi, false,
      Paint()..color = Colors.black..strokeWidth = 1.2..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ========================================
// STAGE 3: STRAWBERRY + GOLDEN WHEAT
// ========================================
class StrawberryWheatGardenPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // ── RAISED BED ──
    _drawRaisedBed(canvas, w, h, const Color(0xFF5D4037), const Color(0xFF4E342E), const Color(0xFF3E2723));

    // ── ORNATE DIVIDER ──
    canvas.drawRect(
      Rect.fromLTWH(w * 0.495, h * 0.28, 3, h * 0.66),
      Paint()..color = const Color(0xFF8D6E63),
    );
    // Gold diamond accent
    final diamond = Path()
      ..moveTo(w * 0.5, h * 0.26)
      ..lineTo(w * 0.5 + 7, h * 0.3)
      ..lineTo(w * 0.5, h * 0.34)
      ..lineTo(w * 0.5 - 7, h * 0.3)
      ..close();
    canvas.drawPath(diamond, Paint()..color = const Color(0xFFD4A417));
    canvas.drawPath(diamond, Paint()..color = const Color(0xFFFFD54F).withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));

    // ── LEFT: STRAWBERRIES ──
    for (int row = 0; row < 3; row++) {
      for (int col = 0; col < 3; col++) {
        final x = w * 0.09 + col * w * 0.135;
        final y = h * 0.36 + row * h * 0.2;
        _drawStrawberryPlant(canvas, x, y);
      }
    }

    // ── RIGHT: GOLDEN WHEAT ──
    for (int col = 0; col < 5; col++) {
      for (int row = 0; row < 3; row++) {
        final x = w * 0.57 + col * w * 0.085;
        final baseY = h * 0.9 - row * h * 0.18;
        _drawWheatStalk(canvas, x, baseY);
      }
    }

    // ── STONE BORDER ──
    for (int i = 0; i < 16; i++) {
      final bx = w * 0.01 + i * w * 0.063;
      canvas.drawOval(
        Rect.fromCenter(center: Offset(bx, h * 0.27), width: w * 0.055, height: 8),
        Paint()..shader = ui.Gradient.linear(
          Offset(bx, h * 0.27 - 4), Offset(bx, h * 0.27 + 4),
          [const Color(0xFF9E9E9E), const Color(0xFF757575)],
        ),
      );
      if (i % 3 == 1) {
        canvas.drawCircle(Offset(bx, h * 0.27), 2.5, Paint()..color = const Color(0xFFD4A417));
      }
    }
  }

  void _drawStrawberryPlant(Canvas canvas, double x, double y) {
    // Bush (layered ovals)
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x, y + 2), width: 28, height: 22),
      Paint()..shader = ui.Gradient.radial(
        Offset(x - 3, y - 2), 14,
        [const Color(0xFF43A047), const Color(0xFF2E7D32)],
      ),
    );
    // Light patch
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x - 4, y - 2), width: 12, height: 10),
      Paint()..color = const Color(0xFF66BB6A).withOpacity(0.4),
    );

    // Strawberry
    final berryPath = Path()
      ..moveTo(x, y + 26)
      ..quadraticBezierTo(x - 9, y + 16, x - 7, y + 11)
      ..quadraticBezierTo(x - 3, y + 7, x, y + 12)
      ..quadraticBezierTo(x + 3, y + 7, x + 7, y + 11)
      ..quadraticBezierTo(x + 9, y + 16, x, y + 26);
    canvas.drawPath(berryPath,
        Paint()..shader = ui.Gradient.linear(
          Offset(x, y + 8), Offset(x, y + 26),
          [const Color(0xFFE53935), const Color(0xFFC62828), const Color(0xFFB71C1C)],
          [0.0, 0.6, 1.0],
        ));

    // Seeds
    for (int sy = 0; sy < 3; sy++) {
      for (int sx = -1; sx <= 1; sx++) {
        if (sy == 0 && sx.abs() > 0) continue; // fewer seeds at top
        final seedX = x + sx * 3.5;
        final seedY = y + 14 + sy * 3.5;
        canvas.drawOval(
          Rect.fromCenter(center: Offset(seedX, seedY), width: 1.5, height: 2.2),
          Paint()..color = const Color(0xFFFFEB3B).withOpacity(0.8),
        );
      }
    }

    // Berry shine
    canvas.drawOval(
      Rect.fromCenter(center: Offset(x - 2.5, y + 12), width: 3.5, height: 5),
      Paint()..color = Colors.white.withOpacity(0.25),
    );

    // Crown
    for (int c = -2; c <= 2; c++) {
      final crownPath = Path()
        ..moveTo(x + c * 1.5, y + 10)
        ..quadraticBezierTo(x + c * 4, y + 5, x + c * 3, y + 7);
      canvas.drawPath(crownPath,
          Paint()..color = const Color(0xFF4CAF50)..strokeWidth = 2
            ..style = PaintingStyle.stroke..strokeCap = StrokeCap.round);
    }
  }

  void _drawWheatStalk(Canvas canvas, double x, double baseY) {
    final topY = baseY - 55;

    // Stalk
    final stalkPath = Path()
      ..moveTo(x, baseY)
      ..quadraticBezierTo(x + 1.5, (baseY + topY) / 2, x + 2, topY);
    canvas.drawPath(stalkPath,
        Paint()..color = const Color(0xFFD4A417)..strokeWidth = 2
          ..style = PaintingStyle.stroke..strokeCap = StrokeCap.round);

    // Wheat head (overlapping ovals)
    for (int k = 0; k < 6; k++) {
      final ky = topY + k * 4;
      final kw = 6.0 - (k < 2 ? (2 - k) * 0.5 : 0) - (k > 4 ? 0.5 : 0);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x + 2, ky), width: kw, height: 7),
        Paint()..shader = ui.Gradient.linear(
          Offset(x - 1, ky), Offset(x + 5, ky),
          [const Color(0xFFFFD54F), const Color(0xFFFFE082), const Color(0xFFFFD54F)],
          [0.0, 0.35, 1.0],
        ),
      );
    }

    // Awns (whiskers)
    for (int a = 0; a < 4; a++) {
      final ay = topY + a * 5.5;
      canvas.drawLine(Offset(x + 2, ay), Offset(x - 5, ay - 7),
          Paint()..color = const Color(0xFFFFE082).withOpacity(0.5)..strokeWidth = 0.6);
      canvas.drawLine(Offset(x + 2, ay), Offset(x + 9, ay - 7),
          Paint()..color = const Color(0xFFFFE082).withOpacity(0.5)..strokeWidth = 0.6);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ========================================
// SHARED: Raised garden bed
// ========================================
void _drawRaisedBed(Canvas canvas, double w, double h, Color top, Color mid, Color bottom) {
  // Shadow
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.03, h * 0.32, w * 0.94, h * 0.64),
      const Radius.circular(12),
    ),
    Paint()..color = Colors.black.withOpacity(0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
  );

  // Border
  canvas.drawRRect(
    RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.02, h * 0.3, w * 0.96, h * 0.65),
      const Radius.circular(12),
    ),
    Paint()..color = const Color(0xFF3E2723),
  );

  // Fill gradient
  final soilRect = Rect.fromLTWH(w * 0.03, h * 0.31, w * 0.94, h * 0.62);
  canvas.drawRRect(
    RRect.fromRectAndRadius(soilRect, const Radius.circular(10)),
    Paint()..shader = ui.Gradient.linear(
      Offset(0, soilRect.top), Offset(0, soilRect.bottom),
      [top, mid, bottom],
      [0.0, 0.4, 1.0],
    ),
  );

  // Soil texture
  final rng = Random(42);
  for (int i = 0; i < 40; i++) {
    final sx = w * 0.06 + rng.nextDouble() * w * 0.88;
    final sy = h * 0.35 + rng.nextDouble() * h * 0.52;
    canvas.drawCircle(Offset(sx, sy), 1 + rng.nextDouble(),
        Paint()..color = top.withOpacity(0.2 + rng.nextDouble() * 0.15));
  }
}

// ========================================
// SHARED: Wooden fence
// ========================================
void _drawWoodFence(Canvas canvas, double w, double h, double fenceTop, int postCount, Color light, Color dark) {
  final fenceH = h * 0.12;

  for (int i = 0; i < postCount; i++) {
    final fx = w * 0.03 + i * (w * 0.94) / (postCount - 1);
    // Post
    final postRect = Rect.fromLTWH(fx - 2.5, fenceTop, 5, fenceH);
    canvas.drawRRect(
      RRect.fromRectAndRadius(postRect, const Radius.circular(2)),
      Paint()..shader = ui.Gradient.linear(
        Offset(fx - 2.5, 0), Offset(fx + 2.5, 0),
        [dark, light, dark],
        [0.0, 0.35, 1.0],
      ),
    );
    // Cap (ball top)
    canvas.drawCircle(Offset(fx, fenceTop - 1), 4,
        Paint()..shader = ui.Gradient.radial(
          Offset(fx - 1, fenceTop - 2), 4,
          [light, dark],
        ));
  }

  // Rails
  for (int r = 0; r < 2; r++) {
    final ry = fenceTop + fenceH * (r == 0 ? 0.3 : 0.7);
    // Shadow
    canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.03, ry + 1, w * 0.94, 3.5), const Radius.circular(1)),
        Paint()..color = Colors.black.withOpacity(0.06));
    // Rail
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
    case 0: return PeaGardenPainter();
    case 1: return CarrotGardenPainter();
    case 2: return CornGardenPainter();
    case 3: return StrawberryWheatGardenPainter();
    default: return PeaGardenPainter();
  }
}