import 'package:flutter/material.dart';
import 'dart:math';

class ShackStringLights extends StatefulWidget {
  const ShackStringLights({super.key});

  @override
  State<ShackStringLights> createState() => _ShackStringLightsState();
}

class _ShackStringLightsState extends State<ShackStringLights>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final Random _rng = Random();

  // Per-bulb flicker speed and phase — fixed at init, never change
  final List<double> _flickerSpeed = [];
  final List<double> _flickerPhase = [];

  @override
  void initState() {
    super.initState();

    for (int i = 0; i < 10; i++) {
      _flickerSpeed.add(1.5 + _rng.nextDouble() * 4.0);
      _flickerPhase.add(_rng.nextDouble() * pi * 2);
    }

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();

    // ✅ No addListener + setState here anymore
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ✅ Brightness is now calculated inside the painter on each frame
  // instead of being stored in state and triggering setState
  List<double> _computeBrightness(double t) {
    final brightness = <double>[];
    for (int i = 0; i < 10; i++) {
      double base = (sin(t * pi * 2 * _flickerSpeed[i] + _flickerPhase[i]) + 1) / 2;
      double spike = _rng.nextDouble() < 0.01 ? 0.1 : 1.0;
      brightness.add((base * 0.35 + 0.65) * spike);
    }
    return brightness;
  }

  @override
  Widget build(BuildContext context) {
    // ✅ AnimatedBuilder handles rebuilds efficiently —
    // no setState, no listener, no risk of calling setState after dispose
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return CustomPaint(
          painter: _StringLightsPainter(
            brightness: _computeBrightness(_controller.value),
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

class _StringLightsPainter extends CustomPainter {
  final List<double> brightness;

  const _StringLightsPainter({required this.brightness});

  @override
  void paint(Canvas canvas, Size s) {
    final wire = Paint()
      ..color = const Color(0xFF5C4A3A)
      ..strokeWidth = 1.5;

    // Wire sag
    final wirePath = Path();
    wirePath.moveTo(0, s.height * 0.15);
    for (int i = 1; i <= 100; i++) {
      final x = s.width * i / 100;
      final sag = sin(i / 100 * pi) * s.height * 0.25;
      final y = s.height * 0.15 + sag;
      wirePath.lineTo(x, y);
    }
    canvas.drawPath(wirePath, wire);

    final int count = brightness.length;
    final double spacing = s.width / count;

    for (int i = 0; i < count; i++) {
      final double frac = (i + 0.5) / count;
      final double x = spacing * i + spacing / 2;
      final double sag = sin(frac * pi) * s.height * 0.25;
      final double wireY = s.height * 0.15 + sag;

      final double b = brightness[i];

      final double bulbY = wireY + s.height * 0.30;
      canvas.drawLine(Offset(x, wireY), Offset(x, bulbY - 4), wire);

      // Outer glow
      final glow = Paint()
        ..color = Color.fromRGBO(255, 230, 100, b * 0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
      canvas.drawCircle(Offset(x, bulbY), 6, glow);

      // Bulb body
      final bulbPaint = Paint()
        ..color = Color.lerp(
          const Color(0xFF886600),
          const Color(0xFFfffaaa),
          b,
        )!;
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, bulbY), width: 6, height: 8),
        bulbPaint,
      );

      // Tiny metal cap
      canvas.drawRect(
        Rect.fromCenter(center: Offset(x, bulbY - 5), width: 3, height: 2),
        Paint()..color = const Color(0xFF6B5040),
      );
    }
  }

  @override
  bool shouldRepaint(_StringLightsPainter old) => true;
}