import 'package:flutter/material.dart';
import 'package:focus_life/services/day_night_cycle.dart';

/// Earthen cave window — carved into rock, matches cave wall tones.
/// Uses DayNightCycle for the sky visible through the opening.
class EarthenWindowPainter extends CustomPainter {
  final DayNightCycle cycle;
  const EarthenWindowPainter({required this.cycle});

  @override
  void paint(Canvas canvas, Size s) {
    final cx = s.width / 2;
    final cy = s.height / 2;
    final rng = _SimpleRng(42);

    final rockDark   = const Color(0xFF5C3A22);
    final rockMid    = const Color(0xFF7A5238);
    final rockEdge   = const Color(0xFF8B6848);
    final depthBlack = const Color(0xFF1A0E05);
    final barWood    = const Color(0xFF5C3820);
    final barLight   = const Color(0xFF7A5035);

    final skyColor = cycle.windowLightColor;

    // ── 1. Outer carved depression (shadow around the window) ──
    final outerShadow = _rockyOval(cx, cy, s.width * 0.50, s.height * 0.50, 12, 0.15);
    canvas.drawPath(outerShadow, Paint()
      ..color = rockDark.withOpacity(0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));

    // ── 2. Stone frame ring (thick carved rock border) ──
    final framePath = _rockyOval(cx, cy, s.width * 0.46, s.height * 0.46, 12, 0.14);
    canvas.drawPath(framePath, Paint()..color = rockDark);

    final frameInner = _rockyOval(cx - 1, cy - 1, s.width * 0.44, s.height * 0.44, 12, 0.12);
    canvas.drawPath(frameInner, Paint()..color = rockMid);

    // ── 3. Deep carved hole (the actual window opening) ──
    final holePath = _rockyOval(cx, cy, s.width * 0.33, s.height * 0.31, 10, 0.08);
    canvas.drawPath(holePath, Paint()..color = depthBlack);

    final skyPath = _rockyOval(cx, cy, s.width * 0.31, s.height * 0.29, 10, 0.06);
    canvas.drawPath(skyPath, Paint()..color = skyColor);

    if (cycle.isDay || cycle.isDawn) {
      canvas.drawPath(skyPath, Paint()
        ..color = skyColor.withOpacity(0.12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
    }

    if (cycle.isNight) {
      canvas.drawPath(skyPath, Paint()
        ..color = const Color(0xFF334466).withOpacity(0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
    }

    canvas.drawPath(skyPath, Paint()
      ..color = depthBlack.withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2));

    // ── 4. Wooden cross bars (rough hand-made look) ──
    final barW = s.width * 0.06;

    _drawWoodBar(canvas, cx - barW / 2, cy - s.height * 0.30,
        barW, s.height * 0.60, barWood, barLight, true);

    _drawWoodBar(canvas, cx - s.width * 0.30, cy - barW / 2,
        s.width * 0.60, barW, barWood, barLight, false);

    // ── 5. Rock texture on frame (cracks, pits, grain) ──
    final crackPaint = Paint()
      ..color = rockDark
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 6; i++) {
      final angle = rng.next() * 6.283;
      final dist = s.width * 0.36 + rng.next() * s.width * 0.08;
      final startX = cx + _cos(angle) * dist * 0.9;
      final startY = cy + _sin(angle) * dist * 0.9;
      final endX = startX + (rng.next() - 0.5) * 10;
      final endY = startY + (rng.next() - 0.5) * 8;
      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), crackPaint);
    }

    for (int i = 0; i < 25; i++) {
      final angle = rng.next() * 6.283;
      final dist = s.width * 0.34 + rng.next() * s.width * 0.12;
      final px = cx + _cos(angle) * dist * (s.width / s.height) * 0.7;
      final py = cy + _sin(angle) * dist * 0.7;

      if (px > 2 && px < s.width - 2 && py > 2 && py < s.height - 2) {
        if (rng.next() > 0.5) {
          canvas.drawCircle(Offset(px, py), 0.8 + rng.next() * 1.2,
              Paint()..color = rockDark.withOpacity(0.5));
        } else {
          canvas.drawCircle(Offset(px, py), 0.5 + rng.next() * 0.8,
              Paint()..color = rockEdge.withOpacity(0.3));
        }
      }
    }

  }

  void _drawWoodBar(Canvas canvas, double x, double y, double w, double h,
      Color dark, Color light, bool isVertical) {
    final barRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, w, h), const Radius.circular(1.5));
    canvas.drawRRect(barRect, Paint()..color = dark);

    if (isVertical) {
      canvas.drawLine(Offset(x + 1, y), Offset(x + 1, y + h),
          Paint()..color = light.withOpacity(0.4)..strokeWidth = 1);
    } else {
      canvas.drawLine(Offset(x, y + 1), Offset(x + w, y + 1),
          Paint()..color = light.withOpacity(0.4)..strokeWidth = 1);
    }

    final grainPaint = Paint()
      ..color = const Color(0xFF2A1A0E).withOpacity(0.4)
      ..strokeWidth = 0.8;
    final grainRng = _SimpleRng(isVertical ? 77 : 99);

    if (isVertical) {
      for (int i = 0; i < 4; i++) {
        final gx = x + 2 + grainRng.next() * (w - 4);
        canvas.drawLine(Offset(gx, y + 3), Offset(gx, y + h - 3), grainPaint);
      }
    } else {
      for (int i = 0; i < 4; i++) {
        final gy = y + 2 + grainRng.next() * (h - 4);
        canvas.drawLine(Offset(x + 3, gy), Offset(x + w - 3, gy), grainPaint);
      }
    }
  }

  Path _rockyOval(double cx, double cy, double rx, double ry, int segments, double roughness) {
    final path = Path();
    final rng = _SimpleRng(17);

    for (int i = 0; i <= segments; i++) {
      final angle = (i / segments) * 6.283185;
      final wobble = 1.0 + (rng.next() - 0.5) * roughness * 2;
      final x = cx + rx * wobble * _cos(angle);
      final y = cy + ry * wobble * _sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        final prevAngle = ((i - 0.5) / segments) * 6.283185;
        final cpWobble = 1.0 + (rng.next() - 0.5) * roughness;
        final cpx = cx + rx * cpWobble * _cos(prevAngle);
        final cpy = cy + ry * cpWobble * _sin(prevAngle);
        path.quadraticBezierTo(cpx, cpy, x, y);
      }
    }
    path.close();
    return path;
  }

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

  static double _cos(double x) => _sin(x + 1.5707963);

  @override
  bool shouldRepaint(EarthenWindowPainter old) {
    // ✅ Compare fractional hours so sky transitions every minute
    // instead of jumping once per hour
    return old.cycle.hour != cycle.hour;
  }
}

class _SimpleRng {
  double _state;
  _SimpleRng(int seed) : _state = seed.toDouble();

  double next() {
    _state = (_state * 1103515245 + 12345) % 2147483648;
    return _state / 2147483648;
  }
}