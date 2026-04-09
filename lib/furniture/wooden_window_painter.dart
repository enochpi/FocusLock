import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../services/day_night_cycle.dart';

class WoodenWindowPainter extends CustomPainter {
  final DayNightCycle cycle;

  WoodenWindowPainter({DayNightCycle? cycle})
      : cycle = cycle ?? DayNightCycle.current();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Warm orange-brown to match shack wall planks
    const Color frameColor  = Color(0xFFA0622A); // matches wall body
    const Color borderColor = Color(0xFF7A4A1E); // slightly darker for depth

    // ── Outer wood frame ──
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, w, h), const Radius.circular(3)),
      Paint()..color = frameColor,
    );

    // ── Sky gradient through glass ──
    final skyColors = cycle.skyGradient;
    final c1 = skyColors.isNotEmpty ? skyColors[0] : Colors.black;
    final c2 = skyColors.length > 1 ? skyColors[1] : c1;
    final c3 = skyColors.length > 2 ? skyColors[2] : c2;
    final skyPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, 0),
        Offset(0, h),
        [c1, c2, c3],
        [0.0, 0.5, 1.0],
      );

    // ── Pane layout: 2 columns × 2 rows ──
    final double inset   = w * 0.08;
    final double divider = w * 0.08;
    final double paneW   = (w - inset * 2 - divider) / 2;
    final double paneH   = (h - inset * 2 - divider) / 2;

    for (int row = 0; row < 2; row++) {
      for (int col = 0; col < 2; col++) {
        final double px = inset + col * (paneW + divider);
        final double py = inset + row * (paneH + divider);
        final paneRect  = Rect.fromLTWH(px, py, paneW, paneH);

        canvas.save();
        canvas.clipRect(paneRect);

        // Sky
        canvas.drawRect(paneRect, skyPaint);

        // Stars (night only)
        if (cycle.showStars) {
          final stars = [
            Offset(px + paneW * 0.2,  py + paneH * 0.2),
            Offset(px + paneW * 0.7,  py + paneH * 0.15),
            Offset(px + paneW * 0.45, py + paneH * 0.55),
            Offset(px + paneW * 0.85, py + paneH * 0.6),
            Offset(px + paneW * 0.1,  py + paneH * 0.75),
          ];
          for (final s in stars) {
            canvas.drawCircle(
              s, 0.7,
              Paint()..color = Colors.white
                  .withOpacity(cycle.starBrightness.clamp(0.0, 0.8)),
            );
          }
        }

        // Sun glow tint
        if (cycle.showSun && cycle.sunPosition < 1.0) {
          canvas.drawRect(
            paneRect,
            Paint()..color = cycle.sunColor
                .withOpacity(0.07 * cycle.sunGlowFactor),
          );
        }

        // Moon tint
        if (cycle.showMoon && cycle.moonPosition < 1.0) {
          canvas.drawRect(
            paneRect,
            Paint()..color = const Color(0xFFE0E0FF).withOpacity(0.05),
          );
        }

        // Glass glare (top-left of each pane)
        canvas.drawRect(
          Rect.fromLTWH(px + 2, py + 2, paneW * 0.28, paneH * 0.22),
          Paint()..color = Colors.white.withOpacity(0.12),
        );

        canvas.restore();

        // Pane border
        canvas.drawRect(
          paneRect,
          Paint()
            ..color = borderColor
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2,
        );
      }
    }

    // ── Centre dividers ──
    canvas.drawRect(
      Rect.fromLTWH(inset + paneW, inset, divider, paneH * 2 + divider),
      Paint()..color = frameColor,
    );
    canvas.drawRect(
      Rect.fromLTWH(inset, inset + paneH, paneW * 2 + divider, divider),
      Paint()..color = frameColor,
    );

    // ── Outer frame border ──
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, w, h), const Radius.circular(3)),
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
  }

  @override
  bool shouldRepaint(WoodenWindowPainter old) {
    // ✅ Same fix — fractional comparison
    return (old.cycle.hour - cycle.hour).abs() > 0.001;
  }
}