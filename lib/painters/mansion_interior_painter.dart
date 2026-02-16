import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:focus_life/services/furniture_service.dart';

// ════════════════════════════════════════════════════════════
//  MANSION INTERIOR — Grand luxury estate
//  Marble floors, gold trim, chandelier, ornate everything
// ════════════════════════════════════════════════════════════
class MansionInteriorPainter extends CustomPainter {
  final FurnitureService furniture;
  MansionInteriorPainter({required this.furniture});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    _drawRoom(canvas, w, h);
    _drawFurniture(canvas, w, h);
  }

  void _drawRoom(Canvas canvas, double w, double h) {
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h),
        Paint()..color = const Color(0xFF0a0010));

    final bL = w * 0.1;
    final bR = w * 0.9;
    final bT = h * 0.04;
    final bB = h * 0.56;

    // ── Back wall — rich deep purple ──
    final backWall = Path()..moveTo(bL, bT)..lineTo(bR, bT)..lineTo(bR, bB)..lineTo(bL, bB)..close();
    canvas.drawPath(backWall, Paint()..shader = ui.Gradient.linear(
        Offset(w * 0.5, bT), Offset(w * 0.5, bB),
        [const Color(0xFF4A148C), const Color(0xFF38006b), const Color(0xFF2d0058)],
        [0.0, 0.4, 1.0]));

    // Gold damask wallpaper pattern
    final goldPat = Paint()..color = const Color(0xFFFFD700).withOpacity(0.03);
    final rng = Random(99);
    for (int row = 0; row < 14; row++) {
      for (int col = 0; col < 12; col++) {
        final tx = bL + col * (bR - bL) / 12 + (row % 2 == 0 ? 0 : (bR - bL) / 24);
        final ty = bT + row * (bB - bT) / 14;
        // Diamond shape
        final diamond = Path()
          ..moveTo(tx, ty - 4)..lineTo(tx + 3, ty)..lineTo(tx, ty + 4)..lineTo(tx - 3, ty)..close();
        canvas.drawPath(diamond, goldPat);
      }
    }

    // Gold crown molding (ornate)
    canvas.drawRect(Rect.fromLTWH(bL, bT, bR - bL, 8),
        Paint()..color = const Color(0xFFFFD700).withOpacity(0.2));
    canvas.drawRect(Rect.fromLTWH(bL, bT + 8, bR - bL, 3),
        Paint()..color = const Color(0xFFFFD700).withOpacity(0.1));
    // Decorative dots on molding
    for (int i = 0; i < 20; i++) {
      final dx = bL + 10 + i * (bR - bL - 20) / 20;
      canvas.drawCircle(Offset(dx, bT + 4), 1.5,
          Paint()..color = const Color(0xFFFFD700).withOpacity(0.15));
    }

    // Gold baseboard
    canvas.drawRect(Rect.fromLTWH(bL, bB - 8, bR - bL, 8),
        Paint()..color = const Color(0xFFFFD700).withOpacity(0.12));

    // Wall panels (wainscoting)
    final panelW = (bR - bL) / 5;
    for (int i = 0; i < 5; i++) {
      final px = bL + i * panelW + 6;
      final py = bB - (bB - bT) * 0.35;
      final pw = panelW - 12;
      final ph = (bB - bT) * 0.3;
      canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(px, py, pw, ph), const Radius.circular(2)),
          Paint()..color = const Color(0xFFFFD700).withOpacity(0.04)..style = PaintingStyle.stroke..strokeWidth = 1);
    }

    // ── Grand arched window ──
    final winCx = w * 0.5;
    final winW = w * 0.32;
    final winH = (bB - bT) * 0.6;
    final winY = bT + (bB - bT) * 0.06;

    // Window arch
    final windowPath = Path()
      ..moveTo(winCx - winW / 2, winY + winH)
      ..lineTo(winCx - winW / 2, winY + winH * 0.3)
      ..arcToPoint(Offset(winCx + winW / 2, winY + winH * 0.3),
          radius: Radius.circular(winW / 2), clockwise: true)
      ..lineTo(winCx + winW / 2, winY + winH)
      ..close();

    // Night sky through window
    canvas.drawPath(windowPath, Paint()..shader = ui.Gradient.linear(
        Offset(winCx, winY), Offset(winCx, winY + winH),
        [const Color(0xFF0d0033), const Color(0xFF1a0066), const Color(0xFF2d0099)],
        [0.0, 0.5, 1.0]));

    // Stars in window
    for (int i = 0; i < 15; i++) {
      final sx = winCx - winW * 0.4 + rng.nextDouble() * winW * 0.8;
      final sy = winY + winH * 0.1 + rng.nextDouble() * winH * 0.5;
      canvas.drawCircle(Offset(sx, sy), 0.8 + rng.nextDouble(),
          Paint()..color = Colors.white.withOpacity(0.4 + rng.nextDouble() * 0.4));
    }

    // Moon in window
    canvas.drawCircle(Offset(winCx + winW * 0.2, winY + winH * 0.2), 12,
        Paint()..color = const Color(0xFFFFE082).withOpacity(0.6));
    canvas.drawCircle(Offset(winCx + winW * 0.2, winY + winH * 0.2), 20,
        Paint()..color = const Color(0xFFFFE082).withOpacity(0.05)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12));

    // Gold window frame
    canvas.drawPath(windowPath, Paint()
      ..color = const Color(0xFFFFD700).withOpacity(0.35)
      ..style = PaintingStyle.stroke..strokeWidth = 4);

    // Window mullions
    canvas.drawLine(Offset(winCx, winY + winH * 0.15), Offset(winCx, winY + winH),
        Paint()..color = const Color(0xFFFFD700).withOpacity(0.25)..strokeWidth = 2);
    canvas.drawLine(Offset(winCx - winW / 2, winY + winH * 0.5), Offset(winCx + winW / 2, winY + winH * 0.5),
        Paint()..color = const Color(0xFFFFD700).withOpacity(0.25)..strokeWidth = 2);

    // Velvet drapes
    final drapePaint = Paint()..color = const Color(0xFF880E4F).withOpacity(0.25);
    // Left drape
    final leftDrape = Path()
      ..moveTo(winCx - winW / 2 - 12, winY)
      ..lineTo(winCx - winW / 2 + winW * 0.05, winY)
      ..quadraticBezierTo(winCx - winW / 2 + winW * 0.08, winY + winH * 0.5, winCx - winW / 2 + winW * 0.1, winY + winH + 5)
      ..lineTo(winCx - winW / 2 - 12, winY + winH + 5)
      ..close();
    canvas.drawPath(leftDrape, drapePaint);
    // Right drape
    final rightDrape = Path()
      ..moveTo(winCx + winW / 2 + 12, winY)
      ..lineTo(winCx + winW / 2 - winW * 0.05, winY)
      ..quadraticBezierTo(winCx + winW / 2 - winW * 0.08, winY + winH * 0.5, winCx + winW / 2 - winW * 0.1, winY + winH + 5)
      ..lineTo(winCx + winW / 2 + 12, winY + winH + 5)
      ..close();
    canvas.drawPath(rightDrape, drapePaint);

    // Gold drape rod
    canvas.drawLine(Offset(winCx - winW / 2 - 20, winY - 3), Offset(winCx + winW / 2 + 20, winY - 3),
        Paint()..color = const Color(0xFFFFD700).withOpacity(0.3)..strokeWidth = 3);
    // Rod finials
    canvas.drawCircle(Offset(winCx - winW / 2 - 20, winY - 3), 4,
        Paint()..color = const Color(0xFFFFD700).withOpacity(0.3));
    canvas.drawCircle(Offset(winCx + winW / 2 + 20, winY - 3), 4,
        Paint()..color = const Color(0xFFFFD700).withOpacity(0.3));

    // ── Ceiling ──
    final ceiling = Path()..moveTo(0, 0)..lineTo(w, 0)..lineTo(bR, bT)..lineTo(bL, bT)..close();
    canvas.drawPath(ceiling, Paint()..shader = ui.Gradient.linear(
        Offset(w * 0.5, 0), Offset(w * 0.5, bT),
        [const Color(0xFF2d0058), const Color(0xFF38006b)]));

    // ── CHANDELIER ──
    _drawChandelier(canvas, w * 0.5, bT * 0.3, w, h);

    // ── Left wall ──
    final leftWall = Path()..moveTo(0, 0)..lineTo(bL, bT)..lineTo(bL, bB)..lineTo(0, h)..close();
    canvas.drawPath(leftWall, Paint()..shader = ui.Gradient.linear(
        Offset(0, h * 0.5), Offset(bL, h * 0.5),
        [const Color(0xFF2d0058), const Color(0xFF38006b)]));

    // ── Right wall ──
    final rightWall = Path()..moveTo(w, 0)..lineTo(bR, bT)..lineTo(bR, bB)..lineTo(w, h)..close();
    canvas.drawPath(rightWall, Paint()..shader = ui.Gradient.linear(
        Offset(w, h * 0.5), Offset(bR, h * 0.5),
        [const Color(0xFF2d0058), const Color(0xFF38006b)]));

    // ── Floor — polished marble ──
    final floor = Path()..moveTo(0, h)..lineTo(bL, bB)..lineTo(bR, bB)..lineTo(w, h)..close();
    canvas.drawPath(floor, Paint()..shader = ui.Gradient.linear(
        Offset(w * 0.5, bB), Offset(w * 0.5, h),
        [const Color(0xFF424242), const Color(0xFF37474F), const Color(0xFF263238)],
        [0.0, 0.5, 1.0]));

    // Marble tile pattern
    for (int i = 0; i <= 8; i++) {
      final t = i / 8;
      final topX = bL + t * (bR - bL);
      final botX = t * w;
      canvas.drawLine(Offset(topX, bB), Offset(botX, h),
          Paint()..color = Colors.white.withOpacity(0.04)..strokeWidth = 0.5);
    }
    for (int i = 1; i < 5; i++) {
      final t = i / 5;
      final y = bB + t * (h - bB);
      final spread = t;
      final lx = bL * (1 - spread);
      final rx = bR + (w - bR) * spread;
      canvas.drawLine(Offset(lx, y), Offset(rx, y),
          Paint()..color = Colors.white.withOpacity(0.03)..strokeWidth = 0.5);
    }

    // Marble floor shine
    canvas.drawOval(
        Rect.fromCenter(center: Offset(w * 0.5, h * 0.76), width: w * 0.5, height: h * 0.1),
        Paint()..color = Colors.white.withOpacity(0.03)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20));

    // Grand rug
    canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.2, h * 0.68, w * 0.6, h * 0.18), const Radius.circular(4)),
        Paint()..color = const Color(0xFF880E4F).withOpacity(0.12));
    canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.22, h * 0.69, w * 0.56, h * 0.16), const Radius.circular(3)),
        Paint()..color = const Color(0xFFFFD700).withOpacity(0.03));
    // Rug gold border
    canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.22, h * 0.69, w * 0.56, h * 0.16), const Radius.circular(3)),
        Paint()..color = const Color(0xFFFFD700).withOpacity(0.08)..style = PaintingStyle.stroke..strokeWidth = 1.5);
    // Inner rug border
    canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.24, h * 0.7, w * 0.52, h * 0.14), const Radius.circular(2)),
        Paint()..color = const Color(0xFFFFD700).withOpacity(0.04)..style = PaintingStyle.stroke..strokeWidth = 0.5);
  }

  void _drawChandelier(Canvas canvas, double cx, double cy, double w, double h) {
    // Chain
    canvas.drawRect(Rect.fromLTWH(cx - 1, 0, 2, cy), Paint()..color = const Color(0xFFFFD700).withOpacity(0.3));

    // Main body circle
    canvas.drawCircle(Offset(cx, cy), 6, Paint()..color = const Color(0xFFFFD700).withOpacity(0.4));

    // Arms (6 arms radiating out)
    final armLen = w * 0.12;
    for (int i = 0; i < 6; i++) {
      final angle = i * 3.14159 / 3 + 0.5;
      final ax = cx + cos(angle) * armLen;
      final ay = cy + sin(angle).abs() * armLen * 0.3 + 5;

      // Arm
      canvas.drawLine(Offset(cx, cy), Offset(ax, ay),
          Paint()..color = const Color(0xFFFFD700).withOpacity(0.25)..strokeWidth = 1.5);

      // Candle
      canvas.drawRect(Rect.fromLTWH(ax - 2, ay - 8, 4, 8),
          Paint()..color = const Color(0xFFECEFF1).withOpacity(0.6));

      // Flame
      canvas.drawOval(
          Rect.fromCenter(center: Offset(ax, ay - 12), width: 4, height: 7),
          Paint()..color = const Color(0xFFFFD740).withOpacity(0.7));

      // Individual glow
      canvas.drawCircle(Offset(ax, ay - 10), 12,
          Paint()..color = const Color(0xFFFFD740).withOpacity(0.04)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
    }

    // Crystal drops
    for (int i = 0; i < 8; i++) {
      final angle = i * 3.14159 / 4;
      final dr = armLen * 0.5;
      final dx = cx + cos(angle) * dr;
      final dy = cy + sin(angle).abs() * dr * 0.3 + 12;
      canvas.drawLine(Offset(dx, dy), Offset(dx, dy + 8),
          Paint()..color = const Color(0xFFFFD700).withOpacity(0.1)..strokeWidth = 0.5);
      canvas.drawCircle(Offset(dx, dy + 9), 1.5,
          Paint()..color = const Color(0xFFFFD700).withOpacity(0.2));
    }

    // Central glow
    canvas.drawCircle(Offset(cx, cy), 80,
        Paint()..shader = ui.Gradient.radial(Offset(cx, cy), 80,
            [const Color(0xFFFFD700).withOpacity(0.08), Colors.transparent]));
  }

  void _drawFurniture(Canvas canvas, double w, double h) {
    final bL = w * 0.1;
    final bR = w * 0.9;
    final bT = h * 0.04;
    final bB = h * 0.56;

    // ── BED — grand four-poster ──
    final bed = _eq('bed_spot');
    if (bed != null) {
      final bx = w * 0.01;
      final by = h * 0.6;
      final bw = w * 0.44;
      final bh = h * 0.16;

      _drawShadow(canvas, bx + bw / 2, by + bh + 5, bw + 10, 14);

      // Base frame
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(bx, by, bw, bh), const Radius.circular(3)),
          Paint()..shader = ui.Gradient.linear(Offset(bx, by), Offset(bx, by + bh),
              [const Color(0xFF4A148C), const Color(0xFF38006b)]));

      // Gold frame trim
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(bx, by, bw, bh), const Radius.circular(3)),
          Paint()..color = const Color(0xFFFFD700).withOpacity(0.15)..style = PaintingStyle.stroke..strokeWidth = 2);

      // Tall ornate headboard
      canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(bx, by - h * 0.16, 14, h * 0.16 + bh), const Radius.circular(4)),
          Paint()..shader = ui.Gradient.linear(
              Offset(bx, by - h * 0.16), Offset(bx + 14, by - h * 0.16),
              [const Color(0xFF6A1B9A), const Color(0xFF4A148C)]));

      // Gold headboard decoration
      canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(bx + 2, by - h * 0.14, 10, h * 0.12), const Radius.circular(3)),
          Paint()..color = const Color(0xFFFFD700).withOpacity(0.08)..style = PaintingStyle.stroke..strokeWidth = 1);

      // Bedpost tops (gold caps)
      canvas.drawCircle(Offset(bx + 7, by - h * 0.16), 5,
          Paint()..color = const Color(0xFFFFD700).withOpacity(0.25));
      canvas.drawCircle(Offset(bx + bw - 3, by - h * 0.04), 4,
          Paint()..color = const Color(0xFFFFD700).withOpacity(0.2));

      // Rich purple silk sheets
      canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(bx + 16, by + 4, bw - 20, bh - 8), const Radius.circular(4)),
          Paint()..shader = ui.Gradient.linear(
              Offset(bx + 16, by + 4), Offset(bx + 16, by + bh - 4),
              [const Color(0xFFCE93D8).withOpacity(0.35), const Color(0xFF9C27B0).withOpacity(0.25)]));

      // Gold embroidered line
      canvas.drawLine(Offset(bx + bw * 0.35, by + 6), Offset(bx + bw * 0.35, by + bh - 6),
          Paint()..color = const Color(0xFFFFD700).withOpacity(0.15)..strokeWidth = 0.5);

      // Silk pillows (3)
      for (int i = 0; i < 3; i++) {
        canvas.drawRRect(
            RRect.fromRectAndRadius(
                Rect.fromLTWH(bx + 18, by + 6 + i * bh * 0.28, bw * 0.14, bh * 0.24), const Radius.circular(6)),
            Paint()..color = Color.lerp(Colors.white, const Color(0xFFCE93D8), i * 0.3)!.withOpacity(0.7 - i * 0.1));
      }

      _drawEmoji(canvas, bed.emoji, bx + bw / 2, by - h * 0.08, 24);
    }

    // ── DESK — grand writing desk ──
    final desk = _eq('desk_spot');
    if (desk != null) {
      final dx = w * 0.54;
      final dy = h * 0.48;
      final dw = w * 0.4;
      final dh = h * 0.04;

      _drawShadow(canvas, dx + dw / 2, h * 0.8, dw + 8, 12);

      // Desktop surface
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(dx, dy, dw, dh), const Radius.circular(2)),
          Paint()..shader = ui.Gradient.linear(Offset(dx, dy), Offset(dx, dy + dh),
              [const Color(0xFF4A148C), const Color(0xFF38006b)]));

      // Gold inlay on surface
      canvas.drawRect(Rect.fromLTWH(dx + 6, dy + 2, dw - 12, 1),
          Paint()..color = const Color(0xFFFFD700).withOpacity(0.2));

      // Ornate drawers (left and right)
      for (int side = 0; side < 2; side++) {
        final sdx = side == 0 ? dx + 4 : dx + dw * 0.6;
        canvas.drawRRect(RRect.fromRectAndRadius(
            Rect.fromLTWH(sdx, dy + dh, dw * 0.35, h * 0.1), const Radius.circular(2)),
            Paint()..color = const Color(0xFF38006b));

        // Drawer face detail
        canvas.drawRRect(RRect.fromRectAndRadius(
            Rect.fromLTWH(sdx + 3, dy + dh + 3, dw * 0.35 - 6, h * 0.04), const Radius.circular(1)),
            Paint()..color = const Color(0xFFFFD700).withOpacity(0.03)..style = PaintingStyle.stroke..strokeWidth = 0.5);
        canvas.drawRRect(RRect.fromRectAndRadius(
            Rect.fromLTWH(sdx + 3, dy + dh + h * 0.05, dw * 0.35 - 6, h * 0.04), const Radius.circular(1)),
            Paint()..color = const Color(0xFFFFD700).withOpacity(0.03)..style = PaintingStyle.stroke..strokeWidth = 0.5);

        // Gold handles
        canvas.drawCircle(Offset(sdx + dw * 0.175, dy + dh + h * 0.025), 2.5,
            Paint()..color = const Color(0xFFFFD700).withOpacity(0.4));
        canvas.drawCircle(Offset(sdx + dw * 0.175, dy + dh + h * 0.07), 2.5,
            Paint()..color = const Color(0xFFFFD700).withOpacity(0.4));
      }

      // Cabriole legs
      for (int i = 0; i < 2; i++) {
        final lx = i == 0 ? dx + 8 : dx + dw - 12;
        canvas.drawRect(Rect.fromLTWH(lx, dy + dh + h * 0.1, 5, h * 0.08),
            Paint()..color = const Color(0xFF4A148C));
        // Gold foot
        canvas.drawCircle(Offset(lx + 2.5, dy + dh + h * 0.18), 3,
            Paint()..color = const Color(0xFFFFD700).withOpacity(0.2));
      }

      // Quill and inkwell
      canvas.drawOval(Rect.fromCenter(center: Offset(dx + dw * 0.3, dy - 3), width: 10, height: 8),
          Paint()..color = const Color(0xFF1a1a1a));
      canvas.drawLine(Offset(dx + dw * 0.3, dy - 5), Offset(dx + dw * 0.25, dy - 22),
          Paint()..color = Colors.white.withOpacity(0.5)..strokeWidth = 1);

      // Candelabra
      canvas.drawRect(Rect.fromLTWH(dx + dw * 0.75, dy - 4, 3, 4),
          Paint()..color = const Color(0xFFFFD700).withOpacity(0.3));
      for (int i = -1; i <= 1; i++) {
        final cx = dx + dw * 0.76 + i * 6;
        canvas.drawRect(Rect.fromLTWH(cx, dy - 14, 2, 10),
            Paint()..color = const Color(0xFFECEFF1).withOpacity(0.5));
        canvas.drawOval(Rect.fromCenter(center: Offset(cx + 1, dy - 17), width: 3, height: 5),
            Paint()..color = const Color(0xFFFFD740).withOpacity(0.6));
      }

      _drawEmoji(canvas, desk.emoji, dx + dw / 2, dy - 14, 20);
    }

    // ── CHAIR — throne-like ──
    final chair = _eq('chair_spot');
    if (chair != null) {
      final cx = w * 0.46;
      final cy = h * 0.56;

      _drawShadow(canvas, cx + w * 0.05, h * 0.8, w * 0.14, 10);

      // Seat cushion
      canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromLTWH(cx, cy, w * 0.12, h * 0.04), const Radius.circular(3)),
          Paint()..color = const Color(0xFFCE93D8).withOpacity(0.3));

      // High ornate back
      canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromLTWH(cx + w * 0.01, cy - h * 0.14, w * 0.1, h * 0.14),
          Radius.circular(w * 0.05)),
          Paint()..shader = ui.Gradient.linear(
              Offset(cx, cy - h * 0.14), Offset(cx, cy),
              [const Color(0xFF6A1B9A), const Color(0xFF4A148C)]));

      // Gold trim on back
      canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromLTWH(cx + w * 0.01, cy - h * 0.14, w * 0.1, h * 0.14),
          Radius.circular(w * 0.05)),
          Paint()..color = const Color(0xFFFFD700).withOpacity(0.15)..style = PaintingStyle.stroke..strokeWidth = 1.5);

      // Crown detail at top
      canvas.drawCircle(Offset(cx + w * 0.06, cy - h * 0.14), 4,
          Paint()..color = const Color(0xFFFFD700).withOpacity(0.25));

      // Armrests
      canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromLTWH(cx - w * 0.01, cy - h * 0.03, w * 0.04, h * 0.02), const Radius.circular(3)),
          Paint()..color = const Color(0xFF4A148C));
      canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromLTWH(cx + w * 0.09, cy - h * 0.03, w * 0.04, h * 0.02), const Radius.circular(3)),
          Paint()..color = const Color(0xFF4A148C));

      // Legs (cabriole)
      canvas.drawRect(Rect.fromLTWH(cx + 3, cy + h * 0.04, 4, h * 0.1),
          Paint()..color = const Color(0xFF4A148C));
      canvas.drawRect(Rect.fromLTWH(cx + w * 0.09, cy + h * 0.04, 4, h * 0.1),
          Paint()..color = const Color(0xFF38006b));

      _drawEmoji(canvas, chair.emoji, cx + w * 0.06, cy - h * 0.16, 18);
    }

    // ── KITCHEN — grand cooking station ──
    final kitchen = _eq('kitchen_spot');
    if (kitchen != null) {
      final kx = w * 0.24;
      final ky = h * 0.54;
      final kw = w * 0.32;
      final kh = h * 0.1;

      _drawShadow(canvas, kx + kw / 2, ky + kh + 6, kw + 6, 10);

      // Counter body
      canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(kx, ky, kw, kh), const Radius.circular(3)),
          Paint()..color = const Color(0xFF38006b));

      // Marble counter top
      canvas.drawRect(Rect.fromLTWH(kx, ky, kw, h * 0.018),
          Paint()..shader = ui.Gradient.linear(Offset(kx, ky), Offset(kx + kw, ky),
              [const Color(0xFF78909C), const Color(0xFF90A4AE), const Color(0xFF78909C)],
              [0.0, 0.5, 1.0]));

      // Gold trim on counter edge
      canvas.drawRect(Rect.fromLTWH(kx, ky + h * 0.018, kw, 1.5),
          Paint()..color = const Color(0xFFFFD700).withOpacity(0.2));

      // Ornate stove
      canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromLTWH(kx + kw * 0.1, ky + h * 0.025, kw * 0.4, kh * 0.6), const Radius.circular(2)),
          Paint()..color = const Color(0xFF2d0058));
      // Stove burner grates
      for (int i = 0; i < 2; i++) {
        final bx = kx + kw * 0.18 + i * kw * 0.18;
        canvas.drawCircle(Offset(bx, ky + h * 0.045), 7,
            Paint()..color = const Color(0xFF424242).withOpacity(0.6));
        canvas.drawCircle(Offset(bx, ky + h * 0.045), 4,
            Paint()..color = const Color(0xFFFF6D00).withOpacity(0.2));
      }

      // Wine rack
      canvas.drawRRect(RRect.fromRectAndRadius(
          Rect.fromLTWH(kx + kw * 0.65, ky + h * 0.02, kw * 0.3, kh * 0.7), const Radius.circular(2)),
          Paint()..color = const Color(0xFF2d0058));
      // Wine bottles
      for (int i = 0; i < 3; i++) {
        canvas.drawRRect(RRect.fromRectAndRadius(
            Rect.fromLTWH(kx + kw * 0.7 + i * kw * 0.08, ky + h * 0.03, kw * 0.05, kh * 0.3), const Radius.circular(2)),
            Paint()..color = Color.lerp(const Color(0xFF880E4F), const Color(0xFF4A148C), i / 3)!.withOpacity(0.5));
      }

      _drawEmoji(canvas, kitchen.emoji, kx + kw / 2, ky - 12, 20);
    }

    // ── DECORATIONS — in gold frames ──
    final decoPositions = [
      [bL + (bR - bL) * 0.06, bT + (bB - bT) * 0.25],
      [bL + (bR - bL) * 0.16, bT + (bB - bT) * 0.2],
      [bL + (bR - bL) * 0.84, bT + (bB - bT) * 0.2],
      [bL + (bR - bL) * 0.94, bT + (bB - bT) * 0.25],
      [w * 0.04, h * 0.25],
      [w * 0.96, h * 0.25],
      [bL + (bR - bL) * 0.35, bT + (bB - bT) * 0.5],
      [bL + (bR - bL) * 0.65, bT + (bB - bT) * 0.5],
    ];

    for (int i = 0; i < 8; i++) {
      final deco = _eq('decoration_spot_${i + 1}');
      if (deco != null) {
        final pos = decoPositions[i];
        // Ornate gold frame
        canvas.drawRRect(RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(pos[0], pos[1]), width: 40, height: 40), const Radius.circular(3)),
            Paint()..color = const Color(0xFFFFD700).withOpacity(0.06));
        canvas.drawRRect(RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(pos[0], pos[1]), width: 40, height: 40), const Radius.circular(3)),
            Paint()..color = const Color(0xFFFFD700).withOpacity(0.15)..style = PaintingStyle.stroke..strokeWidth = 2);
        // Inner frame
        canvas.drawRRect(RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset(pos[0], pos[1]), width: 34, height: 34), const Radius.circular(2)),
            Paint()..color = const Color(0xFFFFD700).withOpacity(0.06)..style = PaintingStyle.stroke..strokeWidth = 0.5);
        // Warm glow
        canvas.drawCircle(Offset(pos[0], pos[1]), 24,
            Paint()..color = const Color(0xFFFFD700).withOpacity(0.03)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12));
        _drawEmoji(canvas, deco.emoji, pos[0], pos[1], 26);
      }
    }
  }

  void _drawShadow(Canvas canvas, double x, double y, double w, double h) {
    canvas.drawOval(Rect.fromCenter(center: Offset(x, y), width: w, height: h),
        Paint()..color = Colors.black.withOpacity(0.25)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7));
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
  bool shouldRepaint(covariant MansionInteriorPainter old) => true;
}