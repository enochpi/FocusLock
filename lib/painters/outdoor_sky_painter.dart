import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:ui' as ui;
import '../services/day_night_cycle.dart';

/// Full outdoor sky background with day/night cycle.
/// Use on the main scene screen (behind house + garden).
class OutdoorSkyPainter extends CustomPainter {
  final DayNightCycle cycle;
  OutdoorSkyPainter({DayNightCycle? cycle}) : cycle = cycle ?? DayNightCycle.current();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final rng = Random(777);

    // ── Sky gradient (full background) ──
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()..shader = ui.Gradient.linear(
        Offset(0, 0), Offset(0, h * 0.65),
        cycle.skyGradient,
        [0.0, 0.5, 1.0],
      ),
    );

    // ── Stars (night only) ──
    if (cycle.showStars) {
      for (int i = 0; i < 60; i++) {
        final sx = rng.nextDouble() * w;
        final sy = rng.nextDouble() * h * 0.5;
        final brightness = cycle.starBrightness * (0.2 + rng.nextDouble() * 0.8);
        final starSize = 0.5 + rng.nextDouble() * 1.2;
        canvas.drawCircle(
          Offset(sx, sy), starSize,
          Paint()..color = Colors.white.withOpacity(brightness.clamp(0.0, 1.0)),
        );
      }
      // A few twinkling bigger stars
      for (int i = 0; i < 8; i++) {
        final sx = rng.nextDouble() * w;
        final sy = rng.nextDouble() * h * 0.35;
        final brightness = cycle.starBrightness * (0.5 + rng.nextDouble() * 0.5);
        // Cross sparkle
        final sparkleSize = 2 + rng.nextDouble() * 2;
        final sparkleP = Paint()..color = Colors.white.withOpacity(brightness.clamp(0.0, 0.8))..strokeWidth = 0.6;
        canvas.drawLine(Offset(sx - sparkleSize, sy), Offset(sx + sparkleSize, sy), sparkleP);
        canvas.drawLine(Offset(sx, sy - sparkleSize), Offset(sx, sy + sparkleSize), sparkleP);
      }
    }

    // ── Moon ──
    if (cycle.showMoon && cycle.moonPosition < 1.0) {
      final moonX = w * cycle.moonX.clamp(0.1, 0.9);
      final moonY = h * 0.5 * cycle.moonPosition.clamp(0.05, 0.95);
      // Outer glow
      canvas.drawCircle(
        Offset(moonX, moonY), 45,
        Paint()..shader = ui.Gradient.radial(
          Offset(moonX, moonY), 45,
          [const Color(0xFFE0E0E0).withOpacity(0.08), Colors.transparent],
        ),
      );
      // Moon body
      canvas.drawCircle(
        Offset(moonX, moonY), 18,
        Paint()..shader = ui.Gradient.radial(
          Offset(moonX - 3, moonY - 3), 18,
          [const Color(0xFFF5F5DC), const Color(0xFFE0D8B0)],
        ),
      );
      // Craters
      canvas.drawCircle(Offset(moonX + 5, moonY + 3), 3,
          Paint()..color = const Color(0xFFD0C8A0).withOpacity(0.3));
      canvas.drawCircle(Offset(moonX - 4, moonY - 5), 2,
          Paint()..color = const Color(0xFFD0C8A0).withOpacity(0.25));
      canvas.drawCircle(Offset(moonX + 2, moonY - 6), 1.5,
          Paint()..color = const Color(0xFFD0C8A0).withOpacity(0.2));
    }

    // ── Sun ──
    if (cycle.showSun && cycle.sunPosition < 1.0) {
      final sunX = w * cycle.sunX.clamp(0.1, 0.9);
      final sunY = h * 0.5 * cycle.sunPosition.clamp(0.05, 0.95);

      // Huge ambient glow
      canvas.drawCircle(
        Offset(sunX, sunY), 80 * cycle.sunGlowFactor,
        Paint()..shader = ui.Gradient.radial(
          Offset(sunX, sunY), 80 * cycle.sunGlowFactor,
          [cycle.sunColor.withOpacity(0.08), Colors.transparent],
        ),
      );
      // Medium glow
      canvas.drawCircle(
        Offset(sunX, sunY), 40 * cycle.sunGlowFactor,
        Paint()..shader = ui.Gradient.radial(
          Offset(sunX, sunY), 40 * cycle.sunGlowFactor,
          [cycle.sunColor.withOpacity(0.2), Colors.transparent],
        ),
      );
      // Sun disc
      canvas.drawCircle(
        Offset(sunX, sunY), 16,
        Paint()..shader = ui.Gradient.radial(
          Offset(sunX - 3, sunY - 3), 16,
          [Colors.white, cycle.sunColor],
        ),
      );
    }

    // ── Clouds ──
    // Clouds are visible during day, fade at night
    final cloudOpacity = cycle.ambientBrightness * 0.35;
    if (cloudOpacity > 0.02) {
      _drawCloud(canvas, w * 0.15, h * 0.08, 60, 22, cloudOpacity);
      _drawCloud(canvas, w * 0.55, h * 0.05, 80, 28, cloudOpacity * 0.8);
      _drawCloud(canvas, w * 0.82, h * 0.12, 50, 18, cloudOpacity * 0.6);
      _drawCloud(canvas, w * 0.35, h * 0.18, 45, 16, cloudOpacity * 0.5);
      _drawCloud(canvas, w * 0.7, h * 0.22, 55, 20, cloudOpacity * 0.4);
    }

    // ── Horizon glow (sunrise/sunset) ──
    if (cycle.isDawn || cycle.isDusk) {
      final horizonY = h * 0.55;
      canvas.drawRect(
        Rect.fromLTWH(0, horizonY - 40, w, 80),
        Paint()..shader = ui.Gradient.linear(
          Offset(0, horizonY - 40), Offset(0, horizonY + 40),
          [
            Colors.transparent,
            cycle.isDawn
                ? const Color(0xFFFF8A65).withOpacity(0.12)
                : const Color(0xFFE65100).withOpacity(0.1),
            Colors.transparent,
          ],
          [0.0, 0.5, 1.0],
        ),
      );
    }
  }

  void _drawCloud(Canvas canvas, double x, double y, double width, double height, double opacity) {
    final cloudColor = Colors.white.withOpacity(opacity);
    final paint = Paint()..color = cloudColor;
    // Build cloud from overlapping ellipses
    canvas.drawOval(Rect.fromCenter(center: Offset(x, y), width: width, height: height), paint);
    canvas.drawOval(Rect.fromCenter(center: Offset(x - width * 0.3, y + 2), width: width * 0.6, height: height * 0.8), paint);
    canvas.drawOval(Rect.fromCenter(center: Offset(x + width * 0.3, y + 1), width: width * 0.65, height: height * 0.85), paint);
    canvas.drawOval(Rect.fromCenter(center: Offset(x + width * 0.1, y - height * 0.2), width: width * 0.5, height: height * 0.7), paint);
  }

  @override
  bool shouldRepaint(covariant OutdoorSkyPainter oldDelegate) => true;
}