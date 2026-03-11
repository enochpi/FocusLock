import 'package:flutter/material.dart';

/// Cave fire pit — rough stone ring with burning logs, layered flames,
/// glowing embers, floating sparks, and warm ambient light.
class StoneFirePainter extends CustomPainter {
  const StoneFirePainter();

  @override
  void paint(Canvas canvas, Size s) {
    final cx = s.width / 2;
    final baseY = s.height * 0.72;

    // ── Warm ground glow (light pool on floor) ──
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, baseY + 8), width: s.width * 0.9, height: s.height * 0.25),
      Paint()
        ..color = const Color(0xFFFF6600).withOpacity(0.08)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
    );

    // ── Ash/charcoal bed ──
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, baseY), width: s.width * 0.55, height: s.height * 0.12),
      Paint()..color = const Color(0xFF1A1008),
    );

    // ── Stone ring (individual rocks around the fire) ──
    final rockColors = [
      const Color(0xFF6B4A30),
      const Color(0xFF5C3A22),
      const Color(0xFF7A5838),
      const Color(0xFF4D3018),
      const Color(0xFF6B4A30),
      const Color(0xFF5C3A22),
      const Color(0xFF7A5838),
      const Color(0xFF4D3018),
    ];

    for (int i = 0; i < 8; i++) {
      final angle = (i / 8) * 6.283 - 0.4;
      final rx = s.width * 0.30;
      final ry = s.height * 0.09;
      final rockX = cx + _cos(angle) * rx;
      final rockY = baseY + _sin(angle) * ry;
      final rockW = s.width * 0.11 + (i % 3) * 2;
      final rockH = s.height * 0.07 + (i % 2) * 2;

      // Rock shadow
      canvas.drawOval(
        Rect.fromCenter(center: Offset(rockX + 1, rockY + 2), width: rockW, height: rockH),
        Paint()..color = const Color(0xFF2A1808).withOpacity(0.5),
      );

      // Rock body
      canvas.drawOval(
        Rect.fromCenter(center: Offset(rockX, rockY), width: rockW, height: rockH),
        Paint()..color = rockColors[i],
      );

      // Rock highlight (top-left)
      canvas.drawOval(
        Rect.fromCenter(center: Offset(rockX - 2, rockY - 1.5), width: rockW * 0.5, height: rockH * 0.4),
        Paint()..color = const Color(0xFF8B6848).withOpacity(0.35),
      );

      // Firelight reflection on front rocks
      if (i >= 2 && i <= 6) {
        canvas.drawOval(
          Rect.fromCenter(center: Offset(rockX, rockY - 1), width: rockW * 0.4, height: rockH * 0.3),
          Paint()..color = const Color(0xFFFF6600).withOpacity(0.12),
        );
      }
    }

    // ── Burning logs (crossed) ──
    final logDark = const Color(0xFF2A1505);
    final logMid = const Color(0xFF3D2010);
    final logEmber = const Color(0xFFCC3300);

    // Log 1 — diagonal left to right
    _drawLog(canvas, cx - s.width * 0.18, baseY - 2, cx + s.width * 0.15, baseY - 8, s.width * 0.04, logDark, logMid);

    // Log 2 — diagonal right to left
    _drawLog(canvas, cx + s.width * 0.18, baseY - 3, cx - s.width * 0.12, baseY - 10, s.width * 0.035, logDark, logMid);

    // Ember edges on logs (glowing cracks)
    canvas.drawLine(
      Offset(cx - s.width * 0.08, baseY - 5),
      Offset(cx + s.width * 0.06, baseY - 8),
      Paint()..color = logEmber.withOpacity(0.6)..strokeWidth = 1.5,
    );
    canvas.drawLine(
      Offset(cx + s.width * 0.04, baseY - 6),
      Offset(cx - s.width * 0.05, baseY - 9),
      Paint()..color = logEmber.withOpacity(0.5)..strokeWidth = 1.2,
    );

    // ── Glowing embers in the coals ──
    for (int i = 0; i < 10; i++) {
      final ex = cx + (i - 5) * s.width * 0.03 + (i % 3) * 2;
      final ey = baseY - 2 + (i % 2) * 3;
      final eSize = 1.0 + (i % 3) * 0.6;

      canvas.drawCircle(Offset(ex, ey), eSize + 2, Paint()
        ..color = const Color(0xFFFF4500).withOpacity(0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));
      canvas.drawCircle(Offset(ex, ey), eSize,
          Paint()..color = (i % 2 == 0) ? const Color(0xFFFFAA00) : const Color(0xFFFF4500));
    }

    // ── Flames — layered for realism ──
    final flameX = cx;
    final flameBase = baseY - 8;

    // Layer 1: Wide red base
    final redFlame = Path()
      ..moveTo(flameX - s.width * 0.16, flameBase)
      ..quadraticBezierTo(flameX - s.width * 0.12, flameBase - s.height * 0.15,
          flameX - s.width * 0.04, flameBase - s.height * 0.28)
      ..quadraticBezierTo(flameX, flameBase - s.height * 0.35,
          flameX + s.width * 0.04, flameBase - s.height * 0.28)
      ..quadraticBezierTo(flameX + s.width * 0.12, flameBase - s.height * 0.15,
          flameX + s.width * 0.16, flameBase)
      ..close();
    canvas.drawPath(redFlame, Paint()..color = const Color(0xFFCC2200).withOpacity(0.7));

    // Layer 2: Orange middle
    final orangeFlame = Path()
      ..moveTo(flameX - s.width * 0.12, flameBase)
      ..quadraticBezierTo(flameX - s.width * 0.08, flameBase - s.height * 0.18,
          flameX - s.width * 0.02, flameBase - s.height * 0.32)
      ..quadraticBezierTo(flameX, flameBase - s.height * 0.40,
          flameX + s.width * 0.02, flameBase - s.height * 0.32)
      ..quadraticBezierTo(flameX + s.width * 0.08, flameBase - s.height * 0.18,
          flameX + s.width * 0.12, flameBase)
      ..close();
    canvas.drawPath(orangeFlame, Paint()..color = const Color(0xFFFF6600).withOpacity(0.85));

    // Layer 3: Yellow core
    final yellowFlame = Path()
      ..moveTo(flameX - s.width * 0.07, flameBase - s.height * 0.02)
      ..quadraticBezierTo(flameX - s.width * 0.04, flameBase - s.height * 0.20,
          flameX, flameBase - s.height * 0.38)
      ..quadraticBezierTo(flameX + s.width * 0.04, flameBase - s.height * 0.20,
          flameX + s.width * 0.07, flameBase - s.height * 0.02)
      ..close();
    canvas.drawPath(yellowFlame, Paint()..color = const Color(0xFFFFAA00));

    // Layer 4: White-hot center
    final whiteFlame = Path()
      ..moveTo(flameX - s.width * 0.03, flameBase - s.height * 0.05)
      ..quadraticBezierTo(flameX, flameBase - s.height * 0.30,
          flameX + s.width * 0.03, flameBase - s.height * 0.05)
      ..close();
    canvas.drawPath(whiteFlame, Paint()..color = const Color(0xFFFFF3C0));

    // ── Flame tip (dancing point) ──
    final tipPath = Path()
      ..moveTo(flameX - s.width * 0.015, flameBase - s.height * 0.36)
      ..quadraticBezierTo(flameX, flameBase - s.height * 0.48,
          flameX + s.width * 0.015, flameBase - s.height * 0.36)
      ..close();
    canvas.drawPath(tipPath, Paint()..color = const Color(0xFFFFEEAA).withOpacity(0.8));

    // ── Side flickers (smaller dancing flames) ──
    // Left flicker
    final leftFlick = Path()
      ..moveTo(flameX - s.width * 0.10, flameBase - s.height * 0.02)
      ..quadraticBezierTo(flameX - s.width * 0.09, flameBase - s.height * 0.18,
          flameX - s.width * 0.06, flameBase - s.height * 0.02)
      ..close();
    canvas.drawPath(leftFlick, Paint()..color = const Color(0xFFFF8800).withOpacity(0.6));

    // Right flicker
    final rightFlick = Path()
      ..moveTo(flameX + s.width * 0.06, flameBase - s.height * 0.02)
      ..quadraticBezierTo(flameX + s.width * 0.09, flameBase - s.height * 0.20,
          flameX + s.width * 0.10, flameBase - s.height * 0.02)
      ..close();
    canvas.drawPath(rightFlick, Paint()..color = const Color(0xFFFF7700).withOpacity(0.6));

    // ── Floating sparks ──
    final sparkPositions = [
      [cx - s.width * 0.08, flameBase - s.height * 0.42],
      [cx + s.width * 0.10, flameBase - s.height * 0.38],
      [cx - s.width * 0.02, flameBase - s.height * 0.50],
      [cx + s.width * 0.05, flameBase - s.height * 0.46],
      [cx - s.width * 0.12, flameBase - s.height * 0.34],
    ];

    for (final pos in sparkPositions) {
      canvas.drawCircle(Offset(pos[0], pos[1]), 2.5, Paint()
        ..color = const Color(0xFFFF8800).withOpacity(0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2));
      canvas.drawCircle(Offset(pos[0], pos[1]), 1.0,
          Paint()..color = const Color(0xFFFFDD00));
    }

    // ── Central fire glow (ambient warm light) ──
    canvas.drawCircle(
      Offset(flameX, flameBase - s.height * 0.15),
      s.width * 0.20,
      Paint()
        ..color = const Color(0xFFFF6600).withOpacity(0.12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15),
    );

    // Wider ambient glow
    canvas.drawCircle(
      Offset(flameX, flameBase - s.height * 0.10),
      s.width * 0.35,
      Paint()
        ..color = const Color(0xFFFF4400).withOpacity(0.05)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20),
    );
  }

  void _drawLog(Canvas canvas, double x1, double y1, double x2, double y2, double width, Color dark, Color mid) {
    // Log shadow
    canvas.drawLine(Offset(x1, y1 + 2), Offset(x2, y2 + 2),
        Paint()..color = Colors.black.withOpacity(0.3)..strokeWidth = width + 2..strokeCap = StrokeCap.round);

    // Log body
    canvas.drawLine(Offset(x1, y1), Offset(x2, y2),
        Paint()..color = dark..strokeWidth = width..strokeCap = StrokeCap.round);

    // Log highlight (top edge)
    canvas.drawLine(Offset(x1, y1 - 1), Offset(x2, y2 - 1),
        Paint()..color = mid.withOpacity(0.5)..strokeWidth = width * 0.4..strokeCap = StrokeCap.round);
  }

  static double _cos(double x) => _sin(x + 1.5707963);

  static double _sin(double x) {
    x = x % 6.283185;
    double result = x;
    double term = x;
    for (int i = 1; i < 8; i++) {
      term *= -x * x / ((2 * i) * (2 * i + 1));
      result += term;
    }
    return result;
  }

  @override
  bool shouldRepaint(_) => false;
}