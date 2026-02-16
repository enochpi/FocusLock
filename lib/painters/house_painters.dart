import 'package:flutter/material.dart';
import 'dart:math';

// ========================================
// STAGE 0: CAVE (just the cave structure)
// ========================================
class CavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Cave opening (arch)
    final cavePath = Path();
    cavePath.moveTo(w * 0.2, h * 0.95);
    cavePath.lineTo(w * 0.2, h * 0.4);
    cavePath.quadraticBezierTo(w * 0.5, h * 0.1, w * 0.8, h * 0.4);
    cavePath.lineTo(w * 0.8, h * 0.95);
    cavePath.close();
    canvas.drawPath(cavePath, Paint()..color = Color(0xFF0d0d0d));

    // Cave inner shadow
    final innerPath = Path();
    innerPath.moveTo(w * 0.25, h * 0.92);
    innerPath.lineTo(w * 0.25, h * 0.44);
    innerPath.quadraticBezierTo(w * 0.5, h * 0.18, w * 0.75, h * 0.44);
    innerPath.lineTo(w * 0.75, h * 0.92);
    innerPath.close();
    canvas.drawPath(innerPath, Paint()..color = Color(0xFF1a1a1a));

    // Rock texture around cave
    final rng = Random(55);
    for (int i = 0; i < 15; i++) {
      final rx = w * 0.1 + rng.nextDouble() * w * 0.8;
      final ry = h * 0.2 + rng.nextDouble() * h * 0.6;
      canvas.drawOval(
        Rect.fromCenter(center: Offset(rx, ry), width: 12 + rng.nextDouble() * 15, height: 8 + rng.nextDouble() * 8),
        Paint()..color = Color(0xFF3E2723).withOpacity(0.3),
      );
    }

    // Door
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.4, h * 0.55, w * 0.2, h * 0.35),
        Radius.circular(w * 0.1),
      ),
      Paint()..color = Color(0xFF5D4037),
    );
    canvas.drawCircle(Offset(w * 0.56, h * 0.73), 3, Paint()..color = Color(0xFFFFD700));

    // Glowing mushrooms
    _drawMushroom(canvas, w * 0.18, h * 0.82, 8, Color(0xFF76FF03));
    _drawMushroom(canvas, w * 0.82, h * 0.80, 6, Color(0xFF00E5FF));
  }

  void _drawMushroom(Canvas canvas, double x, double y, double size, Color glow) {
    canvas.drawRect(
      Rect.fromCenter(center: Offset(x, y + size * 0.3), width: size * 0.3, height: size * 0.6),
      Paint()..color = Color(0xFFE0E0E0),
    );
    canvas.drawArc(
      Rect.fromCenter(center: Offset(x, y - size * 0.1), width: size, height: size * 0.8),
      pi, pi, true,
      Paint()..color = glow,
    );
    canvas.drawCircle(
      Offset(x, y), size * 1.2,
      Paint()..color = glow.withOpacity(0.15)..maskFilter = MaskFilter.blur(BlurStyle.normal, size),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


// ========================================
// STAGE 1: SHACK (just the building)
// ========================================
class ShackPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Shack body
    canvas.drawRect(Rect.fromLTWH(w * 0.2, h * 0.35, w * 0.6, h * 0.6), Paint()..color = Color(0xFF8D6E63));

    // Wood plank lines
    for (int i = 1; i < 8; i++) {
      double y = h * 0.35 + i * (h * 0.6 / 8);
      canvas.drawLine(Offset(w * 0.2, y), Offset(w * 0.8, y), Paint()..color = Color(0xFF6D4C41)..strokeWidth = 1);
    }

    // Roof
    final roofPath = Path()
      ..moveTo(w * 0.12, h * 0.36)
      ..lineTo(w * 0.5, h * 0.08)
      ..lineTo(w * 0.88, h * 0.36)
      ..close();
    canvas.drawPath(roofPath, Paint()..color = Color(0xFF5D4037));
    canvas.drawLine(Offset(w * 0.5, h * 0.08), Offset(w * 0.5, h * 0.36),
        Paint()..color = Color(0xFF4E342E)..strokeWidth = 1);

    // Door
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.4, h * 0.55, w * 0.2, h * 0.4),
        Radius.circular(4),
      ),
      Paint()..color = Color(0xFF4E342E),
    );
    canvas.drawCircle(Offset(w * 0.56, h * 0.75), 3, Paint()..color = Color(0xFFFFD700));

    // Window
    canvas.drawRect(Rect.fromLTWH(w * 0.25, h * 0.45, w * 0.12, h * 0.14), Paint()..color = Color(0xFFFFE082));
    canvas.drawLine(Offset(w * 0.31, h * 0.45), Offset(w * 0.31, h * 0.59),
        Paint()..color = Color(0xFF5D4037)..strokeWidth = 2);
    canvas.drawLine(Offset(w * 0.25, h * 0.52), Offset(w * 0.37, h * 0.52),
        Paint()..color = Color(0xFF5D4037)..strokeWidth = 2);
    // Window glow
    canvas.drawRect(Rect.fromLTWH(w * 0.25, h * 0.45, w * 0.12, h * 0.14),
        Paint()..color = Color(0xFFFFE082).withOpacity(0.2)..maskFilter = MaskFilter.blur(BlurStyle.normal, 10));

    // Chimney
    canvas.drawRect(Rect.fromLTWH(w * 0.65, h * 0.1, w * 0.08, h * 0.2), Paint()..color = Color(0xFF795548));

    // Smoke
    final smokePaint = Paint()..color = Colors.white.withOpacity(0.2);
    canvas.drawCircle(Offset(w * 0.69, h * 0.06), 6, smokePaint);
    canvas.drawCircle(Offset(w * 0.71, h * 0.0), 8, smokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


// ========================================
// STAGE 2: HOUSE (just the building)
// ========================================
class HousePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // House body (stone)
    canvas.drawRect(Rect.fromLTWH(w * 0.15, h * 0.3, w * 0.7, h * 0.65), Paint()..color = Color(0xFFE0E0E0));

    // Stone texture
    final stoneLine = Paint()..color = Color(0xFFBDBDBD)..strokeWidth = 0.8;
    for (int row = 0; row < 10; row++) {
      double y = h * 0.3 + row * (h * 0.65 / 10);
      canvas.drawLine(Offset(w * 0.15, y), Offset(w * 0.85, y), stoneLine);
      double offset = (row % 2 == 0) ? 0 : w * 0.05;
      for (int col = 0; col < 7; col++) {
        double x = w * 0.15 + offset + col * (w * 0.7 / 7);
        canvas.drawLine(Offset(x, y), Offset(x, y + h * 0.65 / 10), stoneLine);
      }
    }

    // Roof
    final roofPath = Path()
      ..moveTo(w * 0.08, h * 0.31)
      ..lineTo(w * 0.5, h * 0.02)
      ..lineTo(w * 0.92, h * 0.31)
      ..close();
    canvas.drawPath(roofPath, Paint()..color = Color(0xFFC62828));

    // Roof shingles
    for (int i = 0; i < 6; i++) {
      double y = h * 0.07 + i * (h * 0.24 / 6);
      double leftX = w * 0.5 - (w * 0.42) * ((y - h * 0.02) / (h * 0.31 - h * 0.02));
      double rightX = w * 0.5 + (w * 0.42) * ((y - h * 0.02) / (h * 0.31 - h * 0.02));
      canvas.drawLine(Offset(leftX, y), Offset(rightX, y), Paint()..color = Color(0xFFB71C1C)..strokeWidth = 1);
    }

    // Door
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.4, h * 0.52, w * 0.2, h * 0.43),
        Radius.circular(w * 0.1),
      ),
      Paint()..color = Color(0xFF5D4037),
    );
    canvas.drawCircle(Offset(w * 0.56, h * 0.74), 3, Paint()..color = Color(0xFFFFD700));

    // Windows (two)
    _drawWindow(canvas, w * 0.22, h * 0.4, w * 0.13, h * 0.16);
    _drawWindow(canvas, w * 0.65, h * 0.4, w * 0.13, h * 0.16);
  }

  void _drawWindow(Canvas canvas, double x, double y, double ww, double hh) {
    canvas.drawRect(Rect.fromLTWH(x, y, ww, hh), Paint()..color = Color(0xFF81D4FA));
    final frame = Paint()..color = Color(0xFFFFFFFF)..strokeWidth = 2..style = PaintingStyle.stroke;
    canvas.drawRect(Rect.fromLTWH(x, y, ww, hh), frame);
    canvas.drawLine(Offset(x + ww / 2, y), Offset(x + ww / 2, y + hh), frame);
    canvas.drawLine(Offset(x, y + hh / 2), Offset(x + ww, y + hh / 2), frame);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


// ========================================
// STAGE 3: MANSION (just the building)
// ========================================
class MansionPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Mansion body
    canvas.drawRect(Rect.fromLTWH(w * 0.05, h * 0.3, w * 0.9, h * 0.65), Paint()..color = Color(0xFFF5F5F5));

    // Central tower
    canvas.drawRect(Rect.fromLTWH(w * 0.35, h * 0.15, w * 0.3, h * 0.15), Paint()..color = Color(0xFFF5F5F5));

    // Tower roof
    canvas.drawPath(
      Path()..moveTo(w * 0.32, h * 0.16)..lineTo(w * 0.5, h * 0.0)..lineTo(w * 0.68, h * 0.16)..close(),
      Paint()..color = Color(0xFF4A148C),
    );

    // Main roofs (left and right wings)
    canvas.drawPath(
      Path()..moveTo(w * 0.0, h * 0.31)..lineTo(w * 0.15, h * 0.16)..lineTo(w * 0.32, h * 0.31)..close(),
      Paint()..color = Color(0xFF4A148C),
    );
    canvas.drawPath(
      Path()..moveTo(w * 0.68, h * 0.31)..lineTo(w * 0.85, h * 0.16)..lineTo(w * 1.0, h * 0.31)..close(),
      Paint()..color = Color(0xFF4A148C),
    );

    // Gold trim
    canvas.drawLine(Offset(w * 0.05, h * 0.31), Offset(w * 0.95, h * 0.31),
        Paint()..color = Color(0xFFFFD700)..strokeWidth = 3);

    // Pillars
    for (int i = 0; i < 2; i++) {
      double x = i == 0 ? w * 0.33 : w * 0.62;
      canvas.drawRect(Rect.fromLTWH(x, h * 0.4, w * 0.05, h * 0.5), Paint()..color = Color(0xFFE0E0E0));
      canvas.drawRect(Rect.fromLTWH(x - 3, h * 0.38, w * 0.05 + 6, 6), Paint()..color = Color(0xFFBDBDBD));
    }

    // Grand door
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.4, h * 0.5, w * 0.2, h * 0.45),
        Radius.circular(w * 0.1),
      ),
      Paint()..color = Color(0xFF4A148C),
    );
    canvas.drawLine(Offset(w * 0.5, h * 0.5), Offset(w * 0.5, h * 0.95),
        Paint()..color = Color(0xFFFFD700)..strokeWidth = 1.5);
    canvas.drawCircle(Offset(w * 0.47, h * 0.73), 3, Paint()..color = Color(0xFFFFD700));
    canvas.drawCircle(Offset(w * 0.53, h * 0.73), 3, Paint()..color = Color(0xFFFFD700));

    // Windows (4)
    _drawMansionWindow(canvas, w * 0.09, h * 0.38, w * 0.1, h * 0.14);
    _drawMansionWindow(canvas, w * 0.22, h * 0.38, w * 0.1, h * 0.14);
    _drawMansionWindow(canvas, w * 0.68, h * 0.38, w * 0.1, h * 0.14);
    _drawMansionWindow(canvas, w * 0.81, h * 0.38, w * 0.1, h * 0.14);

    // Tower window (round)
    canvas.drawCircle(Offset(w * 0.5, h * 0.09), w * 0.035, Paint()..color = Color(0xFFFFE082));
    canvas.drawCircle(Offset(w * 0.5, h * 0.09), w * 0.035,
        Paint()..color = Color(0xFFFFD700)..style = PaintingStyle.stroke..strokeWidth = 2);
  }

  void _drawMansionWindow(Canvas canvas, double x, double y, double ww, double hh) {
    final windowPath = Path()..addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x, y, ww, hh), Radius.circular(ww / 2)));
    canvas.drawPath(windowPath, Paint()..color = Color(0xFFFFE082));
    canvas.drawPath(windowPath, Paint()..color = Color(0xFFFFD700)..style = PaintingStyle.stroke..strokeWidth = 2);
    canvas.drawLine(Offset(x + ww / 2, y), Offset(x + ww / 2, y + hh), Paint()..color = Color(0xFFFFD700)..strokeWidth = 1.5);
    canvas.drawLine(Offset(x, y + hh / 2), Offset(x + ww, y + hh / 2), Paint()..color = Color(0xFFFFD700)..strokeWidth = 1.5);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


// ========================================
// HELPER: Get painter by stage
// ========================================
CustomPainter getHousePainter(int stage) {
  switch (stage) {
    case 0: return CavePainter();
    case 1: return ShackPainter();
    case 2: return HousePainter();
    case 3: return MansionPainter();
    default: return CavePainter();
  }
}