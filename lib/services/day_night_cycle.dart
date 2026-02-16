import 'package:flutter/material.dart';

/// Provides time-of-day visuals based on real local time.
class DayNightCycle {
  final double hour; // 0.0 – 24.0 (fractional)

  DayNightCycle({required this.hour});

  /// Get cycle based on device's current local time
  factory DayNightCycle.current() {
    final now = DateTime.now();
    final fractionalHour = now.hour + now.minute / 60.0;
    return DayNightCycle(hour: fractionalHour);
  }

  /// For testing: create with specific hour
  factory DayNightCycle.at(double hour) {
    return DayNightCycle(hour: hour % 24);
  }

  String get phaseName {
    if (hour >= 5 && hour < 7) return 'dawn';
    if (hour >= 7 && hour < 10) return 'morning';
    if (hour >= 10 && hour < 16) return 'day';
    if (hour >= 16 && hour < 18) return 'golden';
    if (hour >= 18 && hour < 20) return 'dusk';
    if (hour >= 20 && hour < 22) return 'evening';
    return 'night';
  }

  bool get isNight => hour >= 21 || hour < 5;
  bool get isDawn => hour >= 5 && hour < 7;
  bool get isDay => hour >= 7 && hour < 18;
  bool get isDusk => hour >= 18 && hour < 21;

  // ── SKY COLORS ──

  Color get skyTop => _lerpPhase([
    _Phase(0, const Color(0xFF070B1A)),
    _Phase(5, const Color(0xFF0D1B3E)),
    _Phase(6, const Color(0xFF2C3E6B)),
    _Phase(7, const Color(0xFF5B8CCC)),
    _Phase(10, const Color(0xFF4A90D9)),
    _Phase(16, const Color(0xFF4A85C8)),
    _Phase(18, const Color(0xFFD4724E)),
    _Phase(19.5, const Color(0xFF2D1B4E)),
    _Phase(21, const Color(0xFF0D1230)),
    _Phase(24, const Color(0xFF070B1A)),
  ]);

  Color get skyBottom => _lerpPhase([
    _Phase(0, const Color(0xFF0A0F22)),
    _Phase(5, const Color(0xFF1A2744)),
    _Phase(6, const Color(0xFFD4886B)),
    _Phase(7, const Color(0xFFADD8F0)),
    _Phase(10, const Color(0xFFB8DEF5)),
    _Phase(16, const Color(0xFFDDC9A0)),
    _Phase(18, const Color(0xFFE8A54D)),
    _Phase(19.5, const Color(0xFF4A2040)),
    _Phase(21, const Color(0xFF121830)),
    _Phase(24, const Color(0xFF0A0F22)),
  ]);

  Color get skyMid => Color.lerp(skyTop, skyBottom, 0.5)!;
  List<Color> get skyGradient => [skyTop, skyMid, skyBottom];

  // ── SUN / MOON ──

  double get sunPosition {
    if (hour < 6 || hour > 18) return 1.2;
    final t = (hour - 6) / 12.0;
    return 1.0 - _sin(t * 3.14159);
  }

  double get moonPosition {
    double h = hour;
    if (h < 6) h += 24;
    if (h < 19 || h > 31) return 1.2;
    final t = (h - 19) / 12.0;
    return 1.0 - _sin(t * 3.14159);
  }

  double get sunX {
    if (hour < 6 || hour > 18) return 0.5;
    return (hour - 6) / 12.0;
  }

  double get moonX {
    double h = hour;
    if (h < 6) h += 24;
    if (h < 19 || h > 31) return 0.5;
    return (h - 19) / 12.0;
  }

  bool get showSun => hour >= 5.5 && hour <= 18.5;
  bool get showMoon => hour >= 18.5 || hour <= 6;

  Color get sunColor {
    if (hour < 7 || hour > 17) return const Color(0xFFFFB74D);
    return const Color(0xFFFFF176);
  }

  double get sunGlowFactor {
    if (hour < 7 || hour > 17) return 1.5;
    return 1.0;
  }

  // ── AMBIENT LIGHTING ──

  double get ambientBrightness => _lerpValue([
    _VPhase(0, 0.05),
    _VPhase(5, 0.08),
    _VPhase(6, 0.25),
    _VPhase(8, 0.6),
    _VPhase(12, 0.7),
    _VPhase(16, 0.6),
    _VPhase(18, 0.35),
    _VPhase(20, 0.12),
    _VPhase(22, 0.06),
    _VPhase(24, 0.05),
  ]);

  Color get windowLightColor => _lerpPhase([
    _Phase(0, const Color(0xFF1A237E)),
    _Phase(6, const Color(0xFFFFCC80)),
    _Phase(10, const Color(0xFFFFFFFF)),
    _Phase(17, const Color(0xFFFFB74D)),
    _Phase(19, const Color(0xFFE65100)),
    _Phase(21, const Color(0xFF1A237E)),
    _Phase(24, const Color(0xFF1A237E)),
  ]);

  double get lightBeamOpacity => _lerpValue([
    _VPhase(0, 0.0),
    _VPhase(6, 0.02),
    _VPhase(8, 0.06),
    _VPhase(12, 0.08),
    _VPhase(16, 0.06),
    _VPhase(18, 0.03),
    _VPhase(20, 0.0),
    _VPhase(24, 0.0),
  ]);

  double get torchBrightness => _lerpValue([
    _VPhase(0, 1.0),
    _VPhase(6, 0.8),
    _VPhase(8, 0.3),
    _VPhase(10, 0.15),
    _VPhase(16, 0.15),
    _VPhase(18, 0.4),
    _VPhase(20, 0.9),
    _VPhase(22, 1.0),
    _VPhase(24, 1.0),
  ]);

  bool get showStars => hour >= 19.5 || hour < 5.5;

  double get starBrightness => _lerpValue([
    _VPhase(0, 0.8),
    _VPhase(4, 0.8),
    _VPhase(5.5, 0.0),
    _VPhase(19.5, 0.0),
    _VPhase(21, 0.6),
    _VPhase(24, 0.8),
  ]);

  // ── Helpers ──

  Color _lerpPhase(List<_Phase> phases) {
    for (int i = 0; i < phases.length - 1; i++) {
      if (hour >= phases[i].hour && hour < phases[i + 1].hour) {
        final t = (hour - phases[i].hour) / (phases[i + 1].hour - phases[i].hour);
        return Color.lerp(phases[i].color, phases[i + 1].color, t)!;
      }
    }
    return phases.last.color;
  }

  double _lerpValue(List<_VPhase> phases) {
    for (int i = 0; i < phases.length - 1; i++) {
      if (hour >= phases[i].hour && hour < phases[i + 1].hour) {
        final t = (hour - phases[i].hour) / (phases[i + 1].hour - phases[i].hour);
        return phases[i].value + (phases[i + 1].value - phases[i].value) * t;
      }
    }
    return phases.last.value;
  }

  static double _sin(double x) {
    x = x % (2 * 3.14159265);
    double result = x;
    double term = x;
    for (int i = 1; i < 8; i++) {
      term *= -x * x / ((2 * i) * (2 * i + 1));
      result += term;
    }
    return result;
  }
}

class _Phase {
  final double hour;
  final Color color;
  const _Phase(this.hour, this.color);
}

class _VPhase {
  final double hour;
  final double value;
  const _VPhase(this.hour, this.value);
}