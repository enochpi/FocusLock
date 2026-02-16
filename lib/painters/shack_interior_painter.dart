import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:focus_life/services/furniture_service.dart';

// ════════════════════════════════════════════════════════════
//  SHACK INTERIOR — Rustic wooden cabin
//  Warm wood tones, plank walls & floor, window light
// ════════════════════════════════════════════════════════════
class ShackInteriorPainter extends CustomPainter {
  final FurnitureService furniture;
  ShackInteriorPainter({required this.furniture});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final rng = Random(77);

    _drawRoom(canvas, w, h, rng);
    _drawFurniture(canvas, w, h);
  }

  void _drawRoom(Canvas canvas, double w, double h, Random rng) {
    // ── Full background ──
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h),
        Paint()..color = const Color(0xFF1a120a));

    // Perspective points
    final bL = w * 0.1;
    final bR = w * 0.9;
    final bT = h * 0.06;
    final bB = h * 0.6;

    // ── Back wall — warm wood ──
    final backWall = Path()..moveTo(bL, bT)..lineTo(bR, bT)..lineTo(bR, bB)..lineTo(bL, bB)..close();
    canvas.drawPath(backWall, Paint()..shader = ui.Gradient.linear(
        Offset(w * 0.5, bT), Offset(w * 0.5, bB),
        [const Color(0xFF5D4037), const Color(0xFF4E342E), const Color(0xFF3E2723)],
        [0.0, 0.5, 1.0]));

    // Horizontal plank lines on back wall
    for (int i = 0; i < 10; i++) {
      final y = bT + i * (bB - bT) / 10;
      canvas.drawLine(Offset(bL, y), Offset(bR, y),
          Paint()..color = const Color(0xFF3E2723).withOpacity(0.5)..strokeWidth = 1);
      // Plank grain
      for (int j = 0; j < 6; j++) {
        final gx = bL + rng.nextDouble() * (bR - bL);
        canvas.drawLine(Offset(gx, y + 2), Offset(gx + 20 + rng.nextDouble() * 30, y + 2),
            Paint()..color = const Color(0xFF6D4C41).withOpacity(0.12)..strokeWidth = 0.5);
      }
    }

    // Wood knots
    for (int i = 0; i < 8; i++) {
      final kx = bL + rng.nextDouble() * (bR - bL);
      final ky = bT + rng.nextDouble() * (bB - bT);
      canvas.drawOval(
          Rect.fromCenter(center: Offset(kx, ky), width: 6 + rng.nextDouble() * 8, height: 4 + rng.nextDouble() * 6),
          Paint()..color = const Color(0xFF3E2723).withOpacity(0.4));
    }

    // ── Window on back wall ──
    final winX = w * 0.38;
    final winY = bT + (bB - bT) * 0.1;
    final winW = w * 0.24;
    final winH = (bB - bT) * 0.45;

    // Window opening — sky view
    canvas.drawRect(Rect.fromLTWH(winX, winY, winW, winH),
        Paint()..shader = ui.Gradient.linear(
            Offset(winX, winY), Offset(winX, winY + winH),
            [const Color(0xFF81D4FA), const Color(0xFFB3E5FC), const Color(0xFF90CAF9)],
            [0.0, 0.5, 1.0]));

    // Sunbeam from window
    final sunbeam = Path()
      ..moveTo(winX, winY + winH)
      ..lineTo(winX + winW, winY + winH)
      ..lineTo(winX + winW + 40, h * 0.85)
      ..lineTo(winX - 40, h * 0.85)
      ..close();
    canvas.drawPath(sunbeam, Paint()..color = const Color(0xFFFFE082).withOpacity(0.04));

    // Window frame (wood)
    final framePaint = Paint()..color = const Color(0xFF6D4C41)..strokeWidth = 4..style = PaintingStyle.stroke;
    canvas.drawRect(Rect.fromLTWH(winX, winY, winW, winH), framePaint);
    // Cross bars
    canvas.drawLine(Offset(winX + winW / 2, winY), Offset(winX + winW / 2, winY + winH),
        Paint()..color = const Color(0xFF6D4C41)..strokeWidth = 3);
    canvas.drawLine(Offset(winX, winY + winH / 2), Offset(winX + winW, winY + winH / 2),
        Paint()..color = const Color(0xFF6D4C41)..strokeWidth = 3);

    // ── Ceiling ──
    final ceiling = Path()..moveTo(0, 0)..lineTo(w, 0)..lineTo(bR, bT)..lineTo(bL, bT)..close();
    canvas.drawPath(ceiling, Paint()..shader = ui.Gradient.linear(
        Offset(w * 0.5, 0), Offset(w * 0.5, bT),
        [const Color(0xFF3E2723), const Color(0xFF4E342E)]));

    // Ceiling beams
    for (int i = 0; i < 4; i++) {
      final t = (i + 1) / 5;
      final lx = t * bL;
      final rx = w - t * (w - bR);
      final y = t * bT;
      canvas.drawLine(Offset(lx, y), Offset(rx, y),
          Paint()..color = const Color(0xFF5D4037)..strokeWidth = 4);
    }

    // ── Left wall ──
    final leftWall = Path()..moveTo(0, 0)..lineTo(bL, bT)..lineTo(bL, bB)..lineTo(0, h)..close();
    canvas.drawPath(leftWall, Paint()..shader = ui.Gradient.linear(
        Offset(0, h * 0.5), Offset(bL, h * 0.5),
        [const Color(0xFF3E2723), const Color(0xFF4E342E)]));

    // Left wall planks
    for (int i = 0; i < 8; i++) {
      final t = i / 8;
      final x = t * bL;
      final yTop = t * bT;
      final yBot = h - t * (h - bB);
      canvas.drawLine(Offset(x, yTop), Offset(x, yBot),
          Paint()..color = const Color(0xFF5D4037).withOpacity(0.2)..strokeWidth = 0.5);
    }

    // ── Right wall ──
    final rightWall = Path()..moveTo(w, 0)..lineTo(bR, bT)..lineTo(bR, bB)..lineTo(w, h)..close();
    canvas.drawPath(rightWall, Paint()..shader = ui.Gradient.linear(
        Offset(w, h * 0.5), Offset(bR, h * 0.5),
        [const Color(0xFF3E2723), const Color(0xFF4E342E)]));

    // ── Floor — wood planks ──
    final floor = Path()..moveTo(0, h)..lineTo(bL, bB)..lineTo(bR, bB)..lineTo(w, h)..close();
    canvas.drawPath(floor, Paint()..shader = ui.Gradient.linear(
        Offset(w * 0.5, bB), Offset(w * 0.5, h),
        [const Color(0xFF5D4037), const Color(0xFF4E342E)]));

    // Floor board lines (perspective)
    for (int i = 0; i < 8; i++) {
      final t = i / 8;
      final topX = bL + t * (bR - bL);
      final botX = t * w;
      canvas.drawLine(Offset(topX, bB), Offset(botX, h),
          Paint()..color = const Color(0xFF6D4C41).withOpacity(0.25)..strokeWidth = 1);
    }

    // Cross planks on floor
    for (int i = 1; i < 5; i++) {
      final t = i / 5;
      final y = bB + t * (h - bB);
      final spread = t;
      final lx = bL * (1 - spread);
      final rx = bR + (w - bR) * spread;
      canvas.drawLine(Offset(lx, y), Offset(rx, y),
          Paint()..color = const Color(0xFF3E2723).withOpacity(0.3)..strokeWidth = 0.8);
    }

    // ── Small rug on floor ──
    canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.3, h * 0.73, w * 0.4, h * 0.12), const Radius.circular(3)),
        Paint()..color = const Color(0xFF8D6E63).withOpacity(0.25));
    canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.32, h * 0.74, w * 0.36, h * 0.1), const Radius.circular(2)),
        Paint()..color = const Color(0xFFA1887F).withOpacity(0.15));

    // ── Oil lamp on shelf (back wall) ──
    final shelfY = bT + (bB - bT) * 0.6;
    canvas.drawRect(Rect.fromLTWH(bL + 8, shelfY, (bR - bL) * 0.15, 4),
        Paint()..color = const Color(0xFF6D4C41));
    // Lamp
    canvas.drawOval(Rect.fromCenter(center: Offset(bL + 8 + (bR - bL) * 0.075, shelfY - 6), width: 10, height: 12),
        Paint()..color = const Color(0xFFFFE082).withOpacity(0.6));
    canvas.drawCircle(Offset(bL + 8 + (bR - bL) * 0.075, shelfY - 10), 15,
        Paint()..color = const Color(0xFFFFE082).withOpacity(0.05)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10));
  }

  void _drawFurniture(Canvas canvas, double w, double h) {
    final bL = w * 0.1;
    final bR = w * 0.9;
    final bT = h * 0.06;
    final bB = h * 0.6;

    // ── BED — left side ──
    final bed = _eq('bed_spot');
    if (bed != null) {
      final bx = w * 0.02;
      final by = h * 0.68;
      final bw = w * 0.4;
      final bh = h * 0.12;

      // Shadow
      _drawShadow(canvas, bx + bw / 2, by + bh + 3, bw + 6, 10);

      // Wood frame
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(bx, by, bw, bh), const Radius.circular(3)),
          Paint()..shader = ui.Gradient.linear(Offset(bx, by), Offset(bx, by + bh),
              [const Color(0xFF795548), const Color(0xFF6D4C41)]));

      // Headboard (taller)
      canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(bx, by - h * 0.08, 10, h * 0.08 + bh), const Radius.circular(3)),
          Paint()..color = const Color(0xFF6D4C41));
      // Headboard cross piece
      canvas.drawRect(Rect.fromLTWH(bx, by - h * 0.04, 10, 3),
          Paint()..color = const Color(0xFF5D4037));

      // Green wool blanket
      canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(bx + 12, by + 3, bw - 16, bh - 6), const Radius.circular(3)),
          Paint()..shader = ui.Gradient.linear(
              Offset(bx + 12, by + 3), Offset(bx + 12, by + bh - 3),
              [const Color(0xFF558B2F), const Color(0xFF33691E)]));

      // Blanket fold line
      canvas.drawLine(Offset(bx + bw * 0.4, by + 4), Offset(bx + bw * 0.4, by + bh - 5),
          Paint()..color = const Color(0xFF2E7D32).withOpacity(0.3)..strokeWidth = 1);

      // Pillow
      canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(bx + 13, by + 5, bw * 0.2, bh * 0.5), const Radius.circular(8)),
          Paint()..color = const Color(0xFFE8E8E8));
      // Pillow indent
      canvas.drawOval(
          Rect.fromCenter(center: Offset(bx + 13 + bw * 0.1, by + 5 + bh * 0.25), width: bw * 0.12, height: bh * 0.2),
          Paint()..color = const Color(0xFFBDBDBD).withOpacity(0.3));

      _drawEmoji(canvas, bed.emoji, bx + bw / 2, by - h * 0.04, 20);
    }

    // ── DESK — right side ──
    final desk = _eq('desk_spot');
    if (desk != null) {
      final dx = w * 0.55;
      final dy = h * 0.56;
      final dw = w * 0.38;
      final dh = h * 0.04;

      _drawShadow(canvas, dx + dw / 2, h * 0.82, dw + 6, 10);

      // Table top
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(dx, dy, dw, dh), const Radius.circular(2)),
          Paint()..shader = ui.Gradient.linear(Offset(dx, dy), Offset(dx, dy + dh),
              [const Color(0xFF8D6E63), const Color(0xFF795548)]));

      // Surface grain
      canvas.drawLine(Offset(dx + 5, dy + 2), Offset(dx + dw - 5, dy + 2),
          Paint()..color = const Color(0xFF6D4C41).withOpacity(0.3)..strokeWidth = 0.5);

      // Legs (tapered)
      canvas.drawRect(Rect.fromLTWH(dx + 6, dy + dh, 6, h * 0.18),
          Paint()..color = const Color(0xFF6D4C41));
      canvas.drawRect(Rect.fromLTWH(dx + dw - 12, dy + dh, 6, h * 0.18),
          Paint()..color = const Color(0xFF5D4037));
      // Cross brace
      canvas.drawLine(Offset(dx + 9, dy + dh + h * 0.12), Offset(dx + dw - 9, dy + dh + h * 0.12),
          Paint()..color = const Color(0xFF5D4037)..strokeWidth = 2);

      // Book on desk
      canvas.drawRect(Rect.fromLTWH(dx + dw * 0.3, dy - 5, 16, 5),
          Paint()..color = const Color(0xFF4E342E));
      canvas.drawRect(Rect.fromLTWH(dx + dw * 0.3 + 1, dy - 4, 14, 3),
          Paint()..color = const Color(0xFFC62828));

      // Quill in pot
      canvas.drawRect(Rect.fromLTWH(dx + dw * 0.6, dy - 8, 8, 8),
          Paint()..color = const Color(0xFF5D4037));
      canvas.drawLine(Offset(dx + dw * 0.6 + 4, dy - 8), Offset(dx + dw * 0.6 + 2, dy - 20),
          Paint()..color = const Color(0xFFECEFF1)..strokeWidth = 1);

      _drawEmoji(canvas, desk.emoji, dx + dw / 2, dy - 12, 18);
    }

    // ── CHAIR ──
    final chair = _eq('chair_spot');
    if (chair != null) {
      final cx = w * 0.48;
      final cy = h * 0.64;

      _drawShadow(canvas, cx + w * 0.04, h * 0.82, w * 0.1, 6);

      // Seat
      canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromLTWH(cx, cy, w * 0.1, h * 0.035), const Radius.circular(2)),
          Paint()..color = const Color(0xFF8D6E63));

      // Back
      canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromLTWH(cx + 2, cy - h * 0.1, w * 0.08, h * 0.1), const Radius.circular(3)),
          Paint()..color = const Color(0xFF6D4C41));

      // Back slats
      for (int i = 0; i < 3; i++) {
        final sx = cx + 6 + i * w * 0.025;
        canvas.drawRect(Rect.fromLTWH(sx, cy - h * 0.09, 3, h * 0.08),
            Paint()..color = const Color(0xFF795548));
      }

      // Legs
      canvas.drawRect(Rect.fromLTWH(cx + 2, cy + h * 0.035, 3, h * 0.1),
          Paint()..color = const Color(0xFF6D4C41));
      canvas.drawRect(Rect.fromLTWH(cx + w * 0.08, cy + h * 0.035, 3, h * 0.1),
          Paint()..color = const Color(0xFF5D4037));

      _drawEmoji(canvas, chair.emoji, cx + w * 0.05, cy - h * 0.11, 16);
    }

    // ── KITCHEN ──
    final kitchen = _eq('kitchen_spot');
    if (kitchen != null) {
      final kx = w * 0.28;
      final ky = h * 0.58;
      final kw = w * 0.3;
      final kh = h * 0.08;

      _drawShadow(canvas, kx + kw / 2, ky + kh + 8, kw + 4, 8);

      // Stove body
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(kx, ky, kw, kh), const Radius.circular(3)),
          Paint()..color = const Color(0xFF5D4037));

      // Stove top
      canvas.drawRect(Rect.fromLTWH(kx, ky, kw, h * 0.015),
          Paint()..color = const Color(0xFF795548));

      // Pot
      canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromLTWH(kx + kw * 0.15, ky - h * 0.03, kw * 0.25, h * 0.035), const Radius.circular(2)),
          Paint()..color = const Color(0xFF424242));
      // Pot handle
      canvas.drawArc(Rect.fromLTWH(kx + kw * 0.2, ky - h * 0.05, kw * 0.15, h * 0.03), 3.14, 3.14, false,
          Paint()..color = const Color(0xFF616161)..strokeWidth = 2..style = PaintingStyle.stroke);

      // Steam
      for (int i = 0; i < 3; i++) {
        canvas.drawCircle(Offset(kx + kw * 0.27 + i * 5, ky - h * 0.06 - i * 8), 3 + i * 1.5,
            Paint()..color = Colors.white.withOpacity(0.06 - i * 0.015));
      }

      // Firewood below
      canvas.drawRect(Rect.fromLTWH(kx + kw * 0.6, ky + kh * 0.3, kw * 0.3, kh * 0.5),
          Paint()..color = const Color(0xFF4E342E));
      // Fire glow in stove
      canvas.drawOval(
          Rect.fromCenter(center: Offset(kx + kw * 0.75, ky + kh * 0.4), width: kw * 0.2, height: kh * 0.35),
          Paint()..color = const Color(0xFFFF6D00).withOpacity(0.3));

      _drawEmoji(canvas, kitchen.emoji, kx + kw / 2, ky - h * 0.04, 18);
    }

    // ── DECORATIONS ──
    final decoPositions = [
      [bL + (bR - bL) * 0.08, bT + (bB - bT) * 0.2],
      [bL + (bR - bL) * 0.25, bT + (bB - bT) * 0.15],
      [bL + (bR - bL) * 0.75, bT + (bB - bT) * 0.15],
      [bL + (bR - bL) * 0.92, bT + (bB - bT) * 0.2],
      [w * 0.04, h * 0.3],
      [w * 0.96, h * 0.3],
      [bL + (bR - bL) * 0.5, bT + (bB - bT) * 0.55],
      [bL + (bR - bL) * 0.15, bT + (bB - bT) * 0.5],
    ];

    for (int i = 0; i < 8; i++) {
      final deco = _eq('decoration_spot_${i + 1}');
      if (deco != null) {
        final pos = decoPositions[i];
        // Wood shelf bracket
        canvas.drawRect(Rect.fromLTWH(pos[0] - 12, pos[1] + 14, 24, 3),
            Paint()..color = const Color(0xFF6D4C41));
        canvas.drawPath(
            Path()..moveTo(pos[0] - 8, pos[1] + 17)..lineTo(pos[0], pos[1] + 25)..lineTo(pos[0] + 8, pos[1] + 17)..close(),
            Paint()..color = const Color(0xFF5D4037));
        _drawEmoji(canvas, deco.emoji, pos[0], pos[1], 24);
      }
    }
  }

  void _drawShadow(Canvas canvas, double x, double y, double w, double h) {
    canvas.drawOval(Rect.fromCenter(center: Offset(x, y), width: w, height: h),
        Paint()..color = Colors.black.withOpacity(0.2)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
  }

  Furniture? _eq(String spot) {
    final id = furniture.placedFurniture[spot];
    if (id == null) return null;
    try { return furniture.allFurniture.firstWhere((f) => f.id == id); }
    catch (_) { return null; }
  }

  void _drawEmoji(Canvas canvas, String emoji, double x, double y, double size) {
    final tp = TextPainter(text: TextSpan(text: emoji, style: TextStyle(fontSize: size)), textDirection: TextDirection.ltr)..layout();
    tp.paint(canvas, Offset(x - tp.width / 2, y - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant ShackInteriorPainter old) => true;
}