import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:focus_life/services/furniture_service.dart';

// ════════════════════════════════════════════════════════════
//  HOUSE INTERIOR — Modern comfortable home
//  Clean walls, hardwood floors, good lighting, curtains
// ════════════════════════════════════════════════════════════
class HouseInteriorPainter extends CustomPainter {
  final FurnitureService furniture;
  HouseInteriorPainter({required this.furniture});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    _drawRoom(canvas, w, h);
    _drawFurniture(canvas, w, h);
  }

  void _drawRoom(Canvas canvas, double w, double h) {
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h),
        Paint()..color = const Color(0xFF0a1520));

    // Perspective
    final bL = w * 0.1;
    final bR = w * 0.9;
    final bT = h * 0.05;
    final bB = h * 0.58;

    // ── Back wall — clean light blue-gray ──
    final backWall = Path()..moveTo(bL, bT)..lineTo(bR, bT)..lineTo(bR, bB)..lineTo(bL, bB)..close();
    canvas.drawPath(backWall, Paint()..shader = ui.Gradient.linear(
        Offset(w * 0.5, bT), Offset(w * 0.5, bB),
        [const Color(0xFF546E7A), const Color(0xFF455A64), const Color(0xFF37474F)],
        [0.0, 0.5, 1.0]));

    // Subtle wallpaper texture
    final texPaint = Paint()..color = const Color(0xFF607D8B).withOpacity(0.04);
    for (int row = 0; row < 20; row++) {
      for (int col = 0; col < 15; col++) {
        final tx = bL + col * (bR - bL) / 15 + (row % 2 == 0 ? 0 : (bR - bL) / 30);
        final ty = bT + row * (bB - bT) / 20;
        canvas.drawRect(Rect.fromLTWH(tx, ty, 3, 3), texPaint);
      }
    }

    // Crown molding
    canvas.drawRect(Rect.fromLTWH(bL, bT, bR - bL, 5),
        Paint()..color = Colors.white.withOpacity(0.12));
    canvas.drawRect(Rect.fromLTWH(bL, bT + 5, bR - bL, 2),
        Paint()..color = Colors.white.withOpacity(0.06));

    // Baseboard on back wall
    canvas.drawRect(Rect.fromLTWH(bL, bB - 6, bR - bL, 6),
        Paint()..color = Colors.white.withOpacity(0.08));

    // ── Large window — center back wall ──
    final winX = w * 0.32;
    final winY = bT + (bB - bT) * 0.08;
    final winW = w * 0.36;
    final winH = (bB - bT) * 0.55;

    // Window sky
    canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(winX, winY, winW, winH), const Radius.circular(2)),
        Paint()..shader = ui.Gradient.linear(
            Offset(winX, winY), Offset(winX, winY + winH),
            [const Color(0xFF64B5F6), const Color(0xFF90CAF9), const Color(0xFFBBDEFB)],
            [0.0, 0.4, 1.0]));

    // Cloud in window
    _drawCloud(canvas, winX + winW * 0.3, winY + winH * 0.2, 20);
    _drawCloud(canvas, winX + winW * 0.7, winY + winH * 0.35, 14);

    // Window frame (white/light)
    canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(winX, winY, winW, winH), const Radius.circular(2)),
        Paint()..color = Colors.white.withOpacity(0.4)..style = PaintingStyle.stroke..strokeWidth = 4);
    // Panes
    canvas.drawLine(Offset(winX + winW / 3, winY), Offset(winX + winW / 3, winY + winH),
        Paint()..color = Colors.white.withOpacity(0.3)..strokeWidth = 2);
    canvas.drawLine(Offset(winX + winW * 2 / 3, winY), Offset(winX + winW * 2 / 3, winY + winH),
        Paint()..color = Colors.white.withOpacity(0.3)..strokeWidth = 2);

    // Curtains
    // Left curtain
    final leftCurtain = Path()
      ..moveTo(winX - 8, winY - 4)
      ..lineTo(winX + winW * 0.1, winY - 4)
      ..quadraticBezierTo(winX + winW * 0.08, winY + winH * 0.5, winX + winW * 0.12, winY + winH + 4)
      ..lineTo(winX - 8, winY + winH + 4)
      ..close();
    canvas.drawPath(leftCurtain, Paint()..color = const Color(0xFF1565C0).withOpacity(0.2));

    // Right curtain
    final rightCurtain = Path()
      ..moveTo(winX + winW + 8, winY - 4)
      ..lineTo(winX + winW * 0.9, winY - 4)
      ..quadraticBezierTo(winX + winW * 0.92, winY + winH * 0.5, winX + winW * 0.88, winY + winH + 4)
      ..lineTo(winX + winW + 8, winY + winH + 4)
      ..close();
    canvas.drawPath(rightCurtain, Paint()..color = const Color(0xFF1565C0).withOpacity(0.2));

    // Curtain rod
    canvas.drawLine(Offset(winX - 15, winY - 6), Offset(winX + winW + 15, winY - 6),
        Paint()..color = const Color(0xFF78909C)..strokeWidth = 2);

    // Light rays from window
    canvas.drawRect(Rect.fromLTWH(winX - 20, winY, winW + 40, winH + 60),
        Paint()..color = const Color(0xFF64B5F6).withOpacity(0.02)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30));

    // ── Ceiling ──
    final ceiling = Path()..moveTo(0, 0)..lineTo(w, 0)..lineTo(bR, bT)..lineTo(bL, bT)..close();
    canvas.drawPath(ceiling, Paint()..shader = ui.Gradient.linear(
        Offset(w * 0.5, 0), Offset(w * 0.5, bT),
        [const Color(0xFF455A64), const Color(0xFF546E7A)]));

    // Ceiling light fixture
    canvas.drawRect(Rect.fromLTWH(w * 0.48, 0, w * 0.04, bT * 0.3),
        Paint()..color = const Color(0xFF78909C));
    canvas.drawOval(
        Rect.fromCenter(center: Offset(w * 0.5, bT * 0.4), width: w * 0.08, height: bT * 0.3),
        Paint()..color = const Color(0xFFFFE082).withOpacity(0.5));
    // Light glow
    canvas.drawCircle(Offset(w * 0.5, bT * 0.5), 80,
        Paint()..shader = ui.Gradient.radial(Offset(w * 0.5, bT * 0.5), 80,
            [const Color(0xFFFFE082).withOpacity(0.06), Colors.transparent]));

    // ── Left wall ──
    final leftWall = Path()..moveTo(0, 0)..lineTo(bL, bT)..lineTo(bL, bB)..lineTo(0, h)..close();
    canvas.drawPath(leftWall, Paint()..shader = ui.Gradient.linear(
        Offset(0, h * 0.5), Offset(bL, h * 0.5),
        [const Color(0xFF37474F), const Color(0xFF455A64)]));

    // ── Right wall ──
    final rightWall = Path()..moveTo(w, 0)..lineTo(bR, bT)..lineTo(bR, bB)..lineTo(w, h)..close();
    canvas.drawPath(rightWall, Paint()..shader = ui.Gradient.linear(
        Offset(w, h * 0.5), Offset(bR, h * 0.5),
        [const Color(0xFF37474F), const Color(0xFF455A64)]));

    // ── Floor — hardwood ──
    final floor = Path()..moveTo(0, h)..lineTo(bL, bB)..lineTo(bR, bB)..lineTo(w, h)..close();
    canvas.drawPath(floor, Paint()..shader = ui.Gradient.linear(
        Offset(w * 0.5, bB), Offset(w * 0.5, h),
        [const Color(0xFF6D4C41), const Color(0xFF5D4037)]));

    // Floor board lines (perspective from center)
    for (int i = 0; i < 10; i++) {
      final t = i / 10;
      final topX = bL + t * (bR - bL);
      final botX = t * w;
      canvas.drawLine(Offset(topX, bB), Offset(botX, h),
          Paint()..color = const Color(0xFF795548).withOpacity(0.2)..strokeWidth = 1);
    }

    // Floor shine
    canvas.drawOval(
        Rect.fromCenter(center: Offset(w * 0.5, h * 0.78), width: w * 0.4, height: h * 0.08),
        Paint()..color = Colors.white.withOpacity(0.02)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15));

    // Area rug
    canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.25, h * 0.7, w * 0.5, h * 0.15), const Radius.circular(3)),
        Paint()..color = const Color(0xFF1565C0).withOpacity(0.12));
    canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.27, h * 0.71, w * 0.46, h * 0.13), const Radius.circular(2)),
        Paint()..color = const Color(0xFF42A5F5).withOpacity(0.06));
    // Rug pattern border
    canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.27, h * 0.71, w * 0.46, h * 0.13), const Radius.circular(2)),
        Paint()..color = const Color(0xFF64B5F6).withOpacity(0.08)..style = PaintingStyle.stroke..strokeWidth = 1);
  }

  void _drawCloud(Canvas canvas, double x, double y, double r) {
    final p = Paint()..color = Colors.white.withOpacity(0.4);
    canvas.drawCircle(Offset(x, y), r, p);
    canvas.drawCircle(Offset(x - r * 0.7, y + r * 0.2), r * 0.7, p);
    canvas.drawCircle(Offset(x + r * 0.7, y + r * 0.15), r * 0.8, p);
  }

  void _drawFurniture(Canvas canvas, double w, double h) {
    final bL = w * 0.1;
    final bR = w * 0.9;
    final bT = h * 0.05;
    final bB = h * 0.58;

    // ── BED — left, proper bed frame ──
    final bed = _eq('bed_spot');
    if (bed != null) {
      final bx = w * 0.01;
      final by = h * 0.65;
      final bw = w * 0.42;
      final bh = h * 0.14;

      _drawShadow(canvas, bx + bw / 2, by + bh + 4, bw + 8, 12);

      // Metal/wood frame
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(bx, by, bw, bh), const Radius.circular(4)),
          Paint()..shader = ui.Gradient.linear(Offset(bx, by), Offset(bx, by + bh),
              [const Color(0xFF546E7A), const Color(0xFF455A64)]));

      // Headboard (tall, padded)
      canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(bx, by - h * 0.12, 12, h * 0.12 + bh), const Radius.circular(4)),
          Paint()..color = const Color(0xFF37474F));
      // Headboard padding
      canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(bx + 2, by - h * 0.1, 8, h * 0.1), const Radius.circular(3)),
          Paint()..color = const Color(0xFF546E7A));

      // Blue duvet
      canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(bx + 14, by + 3, bw - 18, bh - 6), const Radius.circular(4)),
          Paint()..shader = ui.Gradient.linear(
              Offset(bx + 14, by + 3), Offset(bx + 14, by + bh - 3),
              [const Color(0xFF42A5F5).withOpacity(0.4), const Color(0xFF1E88E5).withOpacity(0.3)]));

      // Folded top edge
      canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(bx + 14, by + 3, bw - 18, bh * 0.15), const Radius.circular(2)),
          Paint()..color = const Color(0xFF64B5F6).withOpacity(0.3));

      // Pillows (two)
      canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(bx + 15, by + 6, bw * 0.16, bh * 0.38), const Radius.circular(6)),
          Paint()..color = Colors.white.withOpacity(0.8));
      canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(bx + 15, by + bh * 0.5, bw * 0.16, bh * 0.38), const Radius.circular(6)),
          Paint()..color = Colors.white.withOpacity(0.7));

      // Nightstand
      canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromLTWH(bx + bw + 4, by + bh * 0.3, w * 0.06, bh * 0.7), const Radius.circular(2)),
          Paint()..color = const Color(0xFF455A64));
      // Lamp on nightstand
      canvas.drawRect(Rect.fromLTWH(bx + bw + 4 + w * 0.02, by + bh * 0.3 - 8, 3, 8),
          Paint()..color = const Color(0xFF78909C));
      canvas.drawOval(
          Rect.fromCenter(center: Offset(bx + bw + 4 + w * 0.03, by + bh * 0.3 - 10), width: 14, height: 8),
          Paint()..color = const Color(0xFFFFE082).withOpacity(0.4));

      _drawEmoji(canvas, bed.emoji, bx + bw / 2, by - h * 0.06, 22);
    }

    // ── DESK — right ──
    final desk = _eq('desk_spot');
    if (desk != null) {
      final dx = w * 0.56;
      final dy = h * 0.52;
      final dw = w * 0.38;
      final dh = h * 0.04;

      _drawShadow(canvas, dx + dw / 2, h * 0.81, dw + 6, 10);

      // Desktop (clean, modern)
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(dx, dy, dw, dh), const Radius.circular(2)),
          Paint()..shader = ui.Gradient.linear(Offset(dx, dy), Offset(dx, dy + dh),
              [const Color(0xFF607D8B), const Color(0xFF546E7A)]));

      // Drawer unit
      canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromLTWH(dx + 4, dy + dh, dw * 0.35, h * 0.08), const Radius.circular(2)),
          Paint()..color = const Color(0xFF455A64));
      // Drawer handles
      canvas.drawRect(Rect.fromLTWH(dx + dw * 0.12, dy + dh + h * 0.02, dw * 0.1, 2),
          Paint()..color = const Color(0xFF90CAF9).withOpacity(0.4));
      canvas.drawRect(Rect.fromLTWH(dx + dw * 0.12, dy + dh + h * 0.055, dw * 0.1, 2),
          Paint()..color = const Color(0xFF90CAF9).withOpacity(0.4));

      // Right legs
      canvas.drawRect(Rect.fromLTWH(dx + dw - 10, dy + dh, 6, h * 0.18),
          Paint()..color = const Color(0xFF455A64));

      // Monitor on desk
      canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromLTWH(dx + dw * 0.25, dy - h * 0.1, dw * 0.5, h * 0.1), const Radius.circular(3)),
          Paint()..color = const Color(0xFF263238));
      canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromLTWH(dx + dw * 0.27, dy - h * 0.098, dw * 0.46, h * 0.088), const Radius.circular(2)),
          Paint()..color = const Color(0xFF37474F));
      // Monitor stand
      canvas.drawRect(Rect.fromLTWH(dx + dw * 0.45, dy - 2, dw * 0.1, 4),
          Paint()..color = const Color(0xFF37474F));

      _drawEmoji(canvas, desk.emoji, dx + dw / 2, dy - h * 0.12, 18);
    }

    // ── CHAIR — office style ──
    final chair = _eq('chair_spot');
    if (chair != null) {
      final cx = w * 0.48;
      final cy = h * 0.6;

      _drawShadow(canvas, cx + w * 0.05, h * 0.82, w * 0.12, 8);

      // Cushion seat
      canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromLTWH(cx, cy, w * 0.1, h * 0.04), const Radius.circular(3)),
          Paint()..color = const Color(0xFF455A64));

      // Back (padded)
      canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromLTWH(cx + w * 0.01, cy - h * 0.1, w * 0.08, h * 0.1), const Radius.circular(4)),
          Paint()..shader = ui.Gradient.linear(
              Offset(cx, cy - h * 0.1), Offset(cx, cy),
              [const Color(0xFF546E7A), const Color(0xFF455A64)]));

      // Armrests
      canvas.drawRect(Rect.fromLTWH(cx - 2, cy - h * 0.02, w * 0.03, h * 0.015),
          Paint()..color = const Color(0xFF37474F));
      canvas.drawRect(Rect.fromLTWH(cx + w * 0.08, cy - h * 0.02, w * 0.03, h * 0.015),
          Paint()..color = const Color(0xFF37474F));

      // Center pole
      canvas.drawRect(Rect.fromLTWH(cx + w * 0.04, cy + h * 0.04, 4, h * 0.08),
          Paint()..color = const Color(0xFF37474F));
      // Wheels base
      canvas.drawLine(Offset(cx, cy + h * 0.12), Offset(cx + w * 0.1, cy + h * 0.12),
          Paint()..color = const Color(0xFF37474F)..strokeWidth = 2);

      _drawEmoji(canvas, chair.emoji, cx + w * 0.05, cy - h * 0.12, 16);
    }

    // ── KITCHEN — modern counter ──
    final kitchen = _eq('kitchen_spot');
    if (kitchen != null) {
      final kx = w * 0.26;
      final ky = h * 0.56;
      final kw = w * 0.3;
      final kh = h * 0.1;

      _drawShadow(canvas, kx + kw / 2, ky + kh + 6, kw + 4, 8);

      // Counter body
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(kx, ky, kw, kh), const Radius.circular(3)),
          Paint()..color = const Color(0xFF455A64));

      // Granite counter top
      canvas.drawRect(Rect.fromLTWH(kx, ky, kw, h * 0.02),
          Paint()..shader = ui.Gradient.linear(Offset(kx, ky), Offset(kx + kw, ky),
              [const Color(0xFF78909C), const Color(0xFF607D8B), const Color(0xFF78909C)],
              [0.0, 0.5, 1.0]));

      // Stove burners
      for (int i = 0; i < 2; i++) {
        final bx = kx + kw * 0.25 + i * kw * 0.35;
        canvas.drawCircle(Offset(bx, ky + h * 0.04), 8, Paint()..color = const Color(0xFF263238));
        canvas.drawCircle(Offset(bx, ky + h * 0.04), 5, Paint()..color = const Color(0xFF37474F));
      }

      // Sink
      canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromLTWH(kx + kw * 0.7, ky + h * 0.025, kw * 0.2, h * 0.04), const Radius.circular(2)),
          Paint()..color = const Color(0xFF37474F));

      // Cabinet doors below
      canvas.drawRect(Rect.fromLTWH(kx + 4, ky + h * 0.025, kw * 0.3, kh * 0.7),
          Paint()..color = const Color(0xFF37474F));
      canvas.drawRect(Rect.fromLTWH(kx + kw * 0.37, ky + h * 0.025, kw * 0.3, kh * 0.7),
          Paint()..color = const Color(0xFF37474F));

      _drawEmoji(canvas, kitchen.emoji, kx + kw / 2, ky - 10, 18);
    }

    // ── DECORATIONS — framed, on walls ──
    final decoPositions = [
      [bL + (bR - bL) * 0.06, bT + (bB - bT) * 0.3],
      [bL + (bR - bL) * 0.18, bT + (bB - bT) * 0.25],
      [bL + (bR - bL) * 0.82, bT + (bB - bT) * 0.25],
      [bL + (bR - bL) * 0.94, bT + (bB - bT) * 0.3],
      [w * 0.04, h * 0.28],
      [w * 0.96, h * 0.28],
      [bL + (bR - bL) * 0.5, bT + (bB - bT) * 0.5],
      [bL + (bR - bL) * 0.5, bT + (bB - bT) * 0.25],
    ];

    for (int i = 0; i < 8; i++) {
      final deco = _eq('decoration_spot_${i + 1}');
      if (deco != null) {
        final pos = decoPositions[i];
        // Picture frame
        canvas.drawRRect(RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(pos[0], pos[1]), width: 34, height: 34), const Radius.circular(3)),
            Paint()..color = Colors.white.withOpacity(0.08));
        canvas.drawRRect(RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(pos[0], pos[1]), width: 34, height: 34), const Radius.circular(3)),
            Paint()..color = Colors.white.withOpacity(0.1)..style = PaintingStyle.stroke..strokeWidth = 1.5);
        _drawEmoji(canvas, deco.emoji, pos[0], pos[1], 24);
      }
    }
  }

  void _drawShadow(Canvas canvas, double x, double y, double w, double h) {
    canvas.drawOval(Rect.fromCenter(center: Offset(x, y), width: w, height: h),
        Paint()..color = Colors.black.withOpacity(0.2)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));
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
  bool shouldRepaint(covariant HouseInteriorPainter old) => true;
}