import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:focus_life/services/furniture_service.dart';

// ════════════════════════════════════════════════════════════
//  CAVE INTERIOR — Dark underground room with rocky walls
//  Perspective room with torch-lit ambiance
// ════════════════════════════════════════════════════════════
class CaveInteriorPainter extends CustomPainter {
  final FurnitureService furniture;
  CaveInteriorPainter({required this.furniture});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final rng = Random(42);

    _drawRoom(canvas, w, h, rng);
    _drawFurniture(canvas, w, h);
  }

  void _drawRoom(Canvas canvas, double w, double h, Random rng) {
    // ── Full dark background ──
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h),
        Paint()..color = const Color(0xFF0a0806));

    // ── Back wall (perspective) ──
    final backLeft = w * 0.12;
    final backRight = w * 0.88;
    final backTop = h * 0.08;
    final backBottom = h * 0.62;

    final backWall = Path()
      ..moveTo(backLeft, backTop)
      ..lineTo(backRight, backTop)
      ..lineTo(backRight, backBottom)
      ..lineTo(backLeft, backBottom)
      ..close();
    canvas.drawPath(backWall, Paint()..shader = ui.Gradient.linear(
        Offset(w * 0.5, backTop), Offset(w * 0.5, backBottom),
        [const Color(0xFF2a1f15), const Color(0xFF1a1410), const Color(0xFF0f0c08)],
        [0.0, 0.6, 1.0]));

    // Rock texture on back wall
    for (int i = 0; i < 60; i++) {
      final rx = backLeft + rng.nextDouble() * (backRight - backLeft);
      final ry = backTop + rng.nextDouble() * (backBottom - backTop);
      final rw = 8 + rng.nextDouble() * 25;
      final rh = 5 + rng.nextDouble() * 15;
      canvas.drawOval(
          Rect.fromCenter(center: Offset(rx, ry), width: rw, height: rh),
          Paint()..color = Color.lerp(
              const Color(0xFF3E2723), const Color(0xFF1a1410), rng.nextDouble())!
              .withOpacity(0.2 + rng.nextDouble() * 0.15));
    }

    // ── Ceiling ──
    final ceiling = Path()
      ..moveTo(0, 0)
      ..lineTo(w, 0)
      ..lineTo(backRight, backTop)
      ..lineTo(backLeft, backTop)
      ..close();
    canvas.drawPath(ceiling, Paint()..shader = ui.Gradient.linear(
        Offset(w * 0.5, 0), Offset(w * 0.5, backTop),
        [const Color(0xFF1a1410), const Color(0xFF2a1f15)]));

    // Stalactites
    for (int i = 0; i < 18; i++) {
      final sx = w * 0.05 + rng.nextDouble() * w * 0.9;
      final sTop = rng.nextDouble() * backTop * 0.3;
      final sLen = 15 + rng.nextDouble() * 55;
      final sWidth = 3 + rng.nextDouble() * 7;
      final stalPath = Path()
        ..moveTo(sx - sWidth, sTop)
        ..quadraticBezierTo(sx - sWidth * 0.4, sTop + sLen * 0.6, sx, sTop + sLen)
        ..quadraticBezierTo(sx + sWidth * 0.4, sTop + sLen * 0.6, sx + sWidth, sTop)
        ..close();
      canvas.drawPath(stalPath, Paint()..shader = ui.Gradient.linear(
          Offset(sx, sTop), Offset(sx, sTop + sLen),
          [const Color(0xFF5D4037), const Color(0xFF3E2723), const Color(0xFF2a1c14)],
          [0.0, 0.5, 1.0]));
      // Drip highlight
      canvas.drawCircle(Offset(sx, sTop + sLen), 1.5,
          Paint()..color = const Color(0xFF8D6E63).withOpacity(0.5));
    }

    // ── Left wall ──
    final leftWall = Path()
      ..moveTo(0, 0)
      ..lineTo(backLeft, backTop)
      ..lineTo(backLeft, backBottom)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(leftWall, Paint()..shader = ui.Gradient.linear(
        Offset(0, h * 0.5), Offset(backLeft, h * 0.5),
        [const Color(0xFF1a1410), const Color(0xFF251c14)]));

    // Left wall rock texture
    for (int i = 0; i < 30; i++) {
      final t = rng.nextDouble();
      final rx = t * backLeft;
      final ryMin = t * backTop;
      final ryMax = h - t * (h - backBottom);
      final ry = ryMin + rng.nextDouble() * (ryMax - ryMin);
      canvas.drawOval(
          Rect.fromCenter(center: Offset(rx, ry), width: 10 + rng.nextDouble() * 20, height: 6 + rng.nextDouble() * 12),
          Paint()..color = const Color(0xFF3E2723).withOpacity(0.15 + rng.nextDouble() * 0.15));
    }

    // ── Right wall ──
    final rightWall = Path()
      ..moveTo(w, 0)
      ..lineTo(backRight, backTop)
      ..lineTo(backRight, backBottom)
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(rightWall, Paint()..shader = ui.Gradient.linear(
        Offset(w, h * 0.5), Offset(backRight, h * 0.5),
        [const Color(0xFF1a1410), const Color(0xFF211810)]));

    // Right wall rock texture
    for (int i = 0; i < 30; i++) {
      final t = rng.nextDouble();
      final rx = w - t * (w - backRight);
      final ryMin = t * backTop;
      final ryMax = h - t * (h - backBottom);
      final ry = ryMin + rng.nextDouble() * (ryMax - ryMin);
      canvas.drawOval(
          Rect.fromCenter(center: Offset(rx, ry), width: 10 + rng.nextDouble() * 20, height: 6 + rng.nextDouble() * 12),
          Paint()..color = const Color(0xFF3E2723).withOpacity(0.15 + rng.nextDouble() * 0.15));
    }

    // ── Floor ──
    final floor = Path()
      ..moveTo(0, h)
      ..lineTo(backLeft, backBottom)
      ..lineTo(backRight, backBottom)
      ..lineTo(w, h)
      ..close();
    canvas.drawPath(floor, Paint()..shader = ui.Gradient.linear(
        Offset(w * 0.5, backBottom), Offset(w * 0.5, h),
        [const Color(0xFF3E2723), const Color(0xFF2a1f15), const Color(0xFF1a1410)],
        [0.0, 0.5, 1.0]));

    // Floor stones
    for (int i = 0; i < 25; i++) {
      final t = rng.nextDouble();
      final fy = backBottom + t * (h - backBottom);
      final spread = backLeft + (0 - backLeft) * t / 1.0;
      final spreadR = backRight + (w - backRight) * t / 1.0;
      final fx = spread + rng.nextDouble() * (spreadR - spread);
      final sw = 15 + rng.nextDouble() * 30 + t * 20;
      final sh = 8 + rng.nextDouble() * 15 + t * 10;
      canvas.drawOval(
          Rect.fromCenter(center: Offset(fx, fy), width: sw, height: sh),
          Paint()..color = const Color(0xFF4E342E).withOpacity(0.12 + rng.nextDouble() * 0.1));
    }

    // ── Torches on walls ──
    _drawTorch(canvas, backLeft + 10, backTop + (backBottom - backTop) * 0.25, rng);
    _drawTorch(canvas, backRight - 10, backTop + (backBottom - backTop) * 0.25, rng);

    // ── Ambient glow from torches ──
    canvas.drawCircle(Offset(backLeft + 10, backTop + (backBottom - backTop) * 0.25), 100,
        Paint()..shader = ui.Gradient.radial(
            Offset(backLeft + 10, backTop + (backBottom - backTop) * 0.25), 100,
            [const Color(0xFFFF8F00).withOpacity(0.08), Colors.transparent]));

    canvas.drawCircle(Offset(backRight - 10, backTop + (backBottom - backTop) * 0.25), 100,
        Paint()..shader = ui.Gradient.radial(
            Offset(backRight - 10, backTop + (backBottom - backTop) * 0.25), 100,
            [const Color(0xFFFF8F00).withOpacity(0.08), Colors.transparent]));

    // Mushroom glow spots on floor
    for (int i = 0; i < 5; i++) {
      final mx = backLeft + rng.nextDouble() * (backRight - backLeft);
      final my = backBottom - 5 - rng.nextDouble() * 15;
      canvas.drawCircle(Offset(mx, my), 4 + rng.nextDouble() * 3,
          Paint()..color = const Color(0xFF76FF03).withOpacity(0.15));
      canvas.drawCircle(Offset(mx, my), 12,
          Paint()..color = const Color(0xFF76FF03).withOpacity(0.03)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
    }
  }

  void _drawTorch(Canvas canvas, double x, double y, Random rng) {
    // Handle
    canvas.drawRect(Rect.fromLTWH(x - 2, y, 4, 20), Paint()..color = const Color(0xFF5D4037));
    // Flame
    final flamePath = Path()
      ..moveTo(x - 5, y)
      ..quadraticBezierTo(x - 7, y - 12, x, y - 18)
      ..quadraticBezierTo(x + 7, y - 12, x + 5, y)
      ..close();
    canvas.drawPath(flamePath, Paint()..shader = ui.Gradient.linear(
        Offset(x, y), Offset(x, y - 18),
        [const Color(0xFFFF6D00), const Color(0xFFFFAB00), const Color(0xFFFFD740)],
        [0.0, 0.5, 1.0]));
    // Glow
    canvas.drawCircle(Offset(x, y - 8), 12,
        Paint()..color = const Color(0xFFFFAB00).withOpacity(0.15)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
  }

  void _drawFurniture(Canvas canvas, double w, double h) {
    final backLeft = w * 0.12;
    final backRight = w * 0.88;
    final backTop = h * 0.08;
    final backBottom = h * 0.62;

    // ── BED — left side on floor ──
    final bed = _eq('bed_spot');
    if (bed != null) {
      final bx = w * 0.04;
      final by = h * 0.7;
      final bw = w * 0.38;
      final bh = h * 0.11;

      // Shadow
      canvas.drawOval(Rect.fromCenter(center: Offset(bx + bw / 2, by + bh + 4), width: bw + 10, height: 12),
          Paint()..color = Colors.black.withOpacity(0.3)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));

      // Bed frame (rough wood/stone)
      final framePaint = Paint()..shader = ui.Gradient.linear(
          Offset(bx, by), Offset(bx, by + bh),
          [const Color(0xFF5D4037), const Color(0xFF4E342E), const Color(0xFF3E2723)],
          [0.0, 0.5, 1.0]);
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(bx, by, bw, bh), const Radius.circular(3)), framePaint);

      // Headboard
      canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(bx, by - h * 0.06, 8, h * 0.06 + bh), const Radius.circular(2)),
          Paint()..color = const Color(0xFF4E342E));

      // Straw/hay mattress
      canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(bx + 10, by + 3, bw - 14, bh - 7), const Radius.circular(4)),
          Paint()..shader = ui.Gradient.linear(
              Offset(bx + 10, by + 3), Offset(bx + 10, by + bh - 4),
              [const Color(0xFFC8A96E), const Color(0xFFB8944A)]));

      // Hay texture lines
      final hayPaint = Paint()..color = const Color(0xFFD4B96A).withOpacity(0.4)..strokeWidth = 0.5;
      for (int i = 0; i < 12; i++) {
        final hx = bx + 14 + i * (bw - 22) / 12;
        canvas.drawLine(Offset(hx, by + 5), Offset(hx + 3, by + bh - 8), hayPaint);
      }

      // Rough pillow
      canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(bx + 12, by + 5, bw * 0.22, bh * 0.55), const Radius.circular(8)),
          Paint()..color = const Color(0xFFBCAAA4));

      // Fur blanket
      canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(bx + bw * 0.35, by + 4, bw * 0.6, bh - 8), const Radius.circular(3)),
          Paint()..color = const Color(0xFF795548).withOpacity(0.7));

      _drawEmoji(canvas, bed.emoji, bx + bw / 2, by - h * 0.04, 20);
    }

    // ── DESK — right side ──
    final desk = _eq('desk_spot');
    if (desk != null) {
      final dx = w * 0.58;
      final dy = h * 0.6;
      final dw = w * 0.34;
      final dh = h * 0.04;

      // Shadow
      canvas.drawOval(Rect.fromCenter(center: Offset(dx + dw / 2, h * 0.82), width: dw + 8, height: 10),
          Paint()..color = Colors.black.withOpacity(0.25)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));

      // Table top (stone slab)
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(dx, dy, dw, dh), const Radius.circular(2)),
          Paint()..shader = ui.Gradient.linear(
              Offset(dx, dy), Offset(dx, dy + dh),
              [const Color(0xFF6D4C41), const Color(0xFF5D4037)]));

      // Top surface highlight
      canvas.drawRect(Rect.fromLTWH(dx + 2, dy + 1, dw - 4, 2),
          Paint()..color = const Color(0xFF8D6E63).withOpacity(0.3));

      // Stone legs
      canvas.drawRect(Rect.fromLTWH(dx + 6, dy + dh, 8, h * 0.16),
          Paint()..color = const Color(0xFF5D4037));
      canvas.drawRect(Rect.fromLTWH(dx + dw - 14, dy + dh, 8, h * 0.16),
          Paint()..color = const Color(0xFF4E342E));

      // Candle on desk
      canvas.drawRect(Rect.fromLTWH(dx + dw * 0.7, dy - 10, 4, 10),
          Paint()..color = const Color(0xFFECEFF1));
      // Flame
      canvas.drawOval(Rect.fromCenter(center: Offset(dx + dw * 0.7 + 2, dy - 13), width: 5, height: 8),
          Paint()..color = const Color(0xFFFFAB00));
      canvas.drawCircle(Offset(dx + dw * 0.7 + 2, dy - 13), 10,
          Paint()..color = const Color(0xFFFFAB00).withOpacity(0.06)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));

      _drawEmoji(canvas, desk.emoji, dx + dw / 2, dy - 10, 18);
    }

    // ── CHAIR — near desk ──
    final chair = _eq('chair_spot');
    if (chair != null) {
      final cx = w * 0.5;
      final cy = h * 0.66;

      // Shadow
      canvas.drawOval(Rect.fromCenter(center: Offset(cx + w * 0.04, h * 0.82), width: w * 0.1, height: 8),
          Paint()..color = Colors.black.withOpacity(0.2)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));

      // Seat (flat stone or log)
      canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromLTWH(cx, cy, w * 0.09, h * 0.035), const Radius.circular(3)),
          Paint()..color = const Color(0xFF6D4C41));

      // Back (stick/stone)
      canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromLTWH(cx, cy - h * 0.08, w * 0.025, h * 0.08), const Radius.circular(2)),
          Paint()..color = const Color(0xFF5D4037));
      canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromLTWH(cx + w * 0.065, cy - h * 0.08, w * 0.025, h * 0.08), const Radius.circular(2)),
          Paint()..color = const Color(0xFF5D4037));
      // Cross bar
      canvas.drawRect(Rect.fromLTWH(cx, cy - h * 0.05, w * 0.09, h * 0.012),
          Paint()..color = const Color(0xFF4E342E));

      // Legs
      canvas.drawRect(Rect.fromLTWH(cx + 2, cy + h * 0.035, 4, h * 0.1),
          Paint()..color = const Color(0xFF5D4037));
      canvas.drawRect(Rect.fromLTWH(cx + w * 0.07, cy + h * 0.035, 4, h * 0.1),
          Paint()..color = const Color(0xFF4E342E));

      _drawEmoji(canvas, chair.emoji, cx + w * 0.045, cy - h * 0.09, 16);
    }

    // ── KITCHEN — center-back area ──
    final kitchen = _eq('kitchen_spot');
    if (kitchen != null) {
      final kx = w * 0.32;
      final ky = h * 0.55;
      final kw = w * 0.28;
      final kh = h * 0.07;

      // Fire pit / cooking area
      // Stone base
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(kx, ky, kw, kh), const Radius.circular(4)),
          Paint()..color = const Color(0xFF4E342E));
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(kx + 2, ky + 2, kw - 4, kh - 4), const Radius.circular(3)),
          Paint()..color = const Color(0xFF3E2723));

      // Fire glow
      canvas.drawCircle(Offset(kx + kw / 2, ky + kh * 0.4), 20,
          Paint()..shader = ui.Gradient.radial(
              Offset(kx + kw / 2, ky + kh * 0.4), 20,
              [const Color(0xFFFF6D00).withOpacity(0.4), const Color(0xFFFF8F00).withOpacity(0.1), Colors.transparent],
              [0.0, 0.5, 1.0]));

      // Flames
      for (int i = 0; i < 3; i++) {
        final fx = kx + kw * 0.3 + i * kw * 0.2;
        final fPath = Path()
          ..moveTo(fx - 4, ky + kh * 0.3)
          ..quadraticBezierTo(fx - 5, ky - 8, fx, ky - 12 - i * 3)
          ..quadraticBezierTo(fx + 5, ky - 8, fx + 4, ky + kh * 0.3)
          ..close();
        canvas.drawPath(fPath, Paint()..color = Color.lerp(
            const Color(0xFFFF6D00), const Color(0xFFFFD740), i / 3.0)!.withOpacity(0.7));
      }

      // Ambient fire glow on surroundings
      canvas.drawCircle(Offset(kx + kw / 2, ky), 60,
          Paint()..color = const Color(0xFFFF6D00).withOpacity(0.04)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30));

      _drawEmoji(canvas, kitchen.emoji, kx + kw / 2, ky - 16, 18);
    }

    // ── DECORATIONS — on walls ──
    final decoPositions = [
      [backLeft + (backRight - backLeft) * 0.1, backTop + (backBottom - backTop) * 0.2],
      [backLeft + (backRight - backLeft) * 0.3, backTop + (backBottom - backTop) * 0.15],
      [backLeft + (backRight - backLeft) * 0.5, backTop + (backBottom - backTop) * 0.1],
      [backLeft + (backRight - backLeft) * 0.7, backTop + (backBottom - backTop) * 0.15],
      [backLeft + (backRight - backLeft) * 0.9, backTop + (backBottom - backTop) * 0.2],
      [w * 0.04, h * 0.35],
      [w * 0.96, h * 0.35],
      [backLeft + (backRight - backLeft) * 0.5, backTop + (backBottom - backTop) * 0.45],
    ];

    final backLeft2 = w * 0.12;
    final backRight2 = w * 0.88;
    final backTop2 = h * 0.08;
    final backBottom2 = h * 0.62;

    for (int i = 0; i < 8; i++) {
      final deco = _eq('decoration_spot_${i + 1}');
      if (deco != null) {
        final pos = decoPositions[i];
        // Warm glow behind
        canvas.drawCircle(Offset(pos[0], pos[1]), 22,
            Paint()..color = const Color(0xFFFFAB00).withOpacity(0.06)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12));
        // Small shelf/hook
        canvas.drawRect(Rect.fromLTWH(pos[0] - 10, pos[1] + 12, 20, 3),
            Paint()..color = const Color(0xFF5D4037).withOpacity(0.5));
        _drawEmoji(canvas, deco.emoji, pos[0], pos[1], 24);
      }
    }
  }

  Furniture? _eq(String spot) {
    final id = furniture.placedFurniture[spot];
    if (id == null) return null;
    try { return furniture.allFurniture.firstWhere((f) => f.id == id); }
    catch (_) { return null; }
  }

  void _drawEmoji(Canvas canvas, String emoji, double x, double y, double size) {
    final tp = TextPainter(
        text: TextSpan(text: emoji, style: TextStyle(fontSize: size)),
        textDirection: TextDirection.ltr)..layout();
    tp.paint(canvas, Offset(x - tp.width / 2, y - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant CaveInteriorPainter old) => true;
}