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

  // Per-bulb flicker state: brightness 0.0–1.0
  final List<double> _brightness = List.filled(10, 1.0);
  // Per-bulb flicker speed (different for each bulb)
  final List<double> _flickerSpeed = [];
  // Per-bulb flicker phase
  final List<double> _flickerPhase = [];

  @override
  void initState() {
    super.initState();

    for (int i = 0; i < 10; i++) {
      _flickerSpeed.add(1.5 + _rng.nextDouble() * 4.0); // 1.5–5.5 Hz
      _flickerPhase.add(_rng.nextDouble() * pi * 2);    // random start phase
    }

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();

    _controller.addListener(() {
      final t = _controller.value * pi * 2;
      setState(() {
        for (int i = 0; i < 10; i++) {
          // Base sine wave flicker
          double base = (sin(t * _flickerSpeed[i] + _flickerPhase[i]) + 1) / 2;

          // Occasionally punch a bulb dim for a realistic flicker spike
          double spike = _rng.nextDouble() < 0.01 ? 0.1 : 1.0;

          _brightness[i] = (base * 0.35 + 0.65) * spike; // clamp between 0.65–1.0 normally
        }
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _StringLightsPainter(brightness: List.from(_brightness)),
      size: Size.infinite,
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

    // Very subtle sag — wire stays near the top
    final wirePath = Path();
    wirePath.moveTo(0, s.height * 0.15);
    for (int i = 1; i <= 100; i++) {
      final x = s.width * i / 100;
      final sag = sin(i / 100 * pi) * s.height * 0.25; // tiny sag
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

      // Very short cord
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