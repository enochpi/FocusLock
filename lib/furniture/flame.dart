import 'dart:math';
import 'package:flutter/material.dart';

class FlameWidget extends StatefulWidget {
  final double width;
  final double height;
  final double opacity;

  const FlameWidget({
    super.key,
    this.width = 60,
    this.height = 130,
    this.opacity = 1.0,
  });

  @override
  State<FlameWidget> createState() => _FlameWidgetState();
}

class _FlameWidgetState extends State<FlameWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final Random _rng = Random();
  int _frameCount = 0;

  // ✅ Pre-allocated fixed pool — no garbage creation each frame
  static const int _maxSparks = 5;
  late final List<_Spark> _sparks;

  @override
  void initState() {
    super.initState();

    // ✅ Initialize pool with dead sparks
    _sparks = List.generate(_maxSparks, (_) => _Spark.dead());

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();

    _controller.addListener(_onTick);
  }

  void _onTick() {
    _frameCount++;
    if (_frameCount % 3 == 0) {
      // ✅ Recycle dead sparks instead of creating new ones
      for (final spark in _sparks) {
        if (spark.isDead) {
          spark.reset(_rng, widget.width, widget.height);
        } else {
          spark.update();
        }
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: widget.opacity,
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final t = _controller.value;
            final flameHeight    = 0.82 + 0.18 * _sine(t * 2 * pi);
            final flameSway      = 0.10 * _sine(t * 2 * pi);
            final flickerOpacity = 0.65 + 0.35 * _sine(t * 2 * pi * 8.9);
            final glowSize       = 0.85 + 0.30 * _sine(t * 2 * pi * 1.33);
            final turbulence     = _sine(t * 2 * pi * 4.0);

            return CustomPaint(
              size: Size(widget.width, widget.height),
              painter: _FlamePainter(
                flameHeight: flameHeight,
                flameSway: flameSway,
                flickerOpacity: flickerOpacity,
                glowSize: glowSize,
                turbulence: turbulence,
                sparks: _sparks,
              ),
            );
          },
        ),
      ),
    );
  }

  static double _sine(double x) => sin(x);
}

// ✅ Recyclable spark — no allocations after init
class _Spark {
  double x = 0, y = 0, vx = 0, vy = 0, life = 0, size = 0;
  double maxLife = 1;
  bool _dead = true;

  // ✅ Start as dead — will be reset on first use
  _Spark.dead();

  void reset(Random rng, double w, double h) {
    final cx = w / 2;
    x = cx + (rng.nextDouble() - 0.5) * w * 0.3;
    y = h * 0.45 - rng.nextDouble() * h * 0.25;
    vx = (rng.nextDouble() - 0.5) * 1.2;
    vy = -(0.8 + rng.nextDouble() * 1.5);
    maxLife = 0.6 + rng.nextDouble() * 0.4;
    life = maxLife;
    size = 0.8 + rng.nextDouble() * 1.8;
    _dead = false;
  }

  void update() {
    x += vx;
    y += vy;
    vx *= 0.97;
    vy -= 0.04;
    life -= 0.03;
    if (life <= 0) _dead = true;
  }

  bool get isDead => _dead;
  double get alpha => _dead ? 0.0 : (life / maxLife).clamp(0.0, 1.0);
}

class _FlamePainter extends CustomPainter {
  final double flameHeight, flameSway, flickerOpacity, glowSize, turbulence;
  final List<_Spark> sparks;

  // ✅ Reuse paints to avoid allocations every frame
  static final _glowPaint1  = Paint();
  static final _sparkPaint  = Paint();

  _FlamePainter({
    required this.flameHeight,
    required this.flameSway,
    required this.flickerOpacity,
    required this.glowSize,
    required this.turbulence,
    required this.sparks,
  });

  @override
  void paint(Canvas canvas, Size s) {
    final cx = s.width / 2;
    final baseY = s.height * 0.47;
    final swayX = flameSway * s.width * 0.55;
    final turbX = turbulence * s.width * 0.03;

    // ── Outer glow ────────────────────────────────────────
    _glowPaint1
      ..color = const Color(0xFFFF4400).withOpacity(0.12 * flickerOpacity)
      ..maskFilter = null;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx + swayX * 0.3, baseY - s.height * 0.10),
        width: s.width * 1.4 * glowSize,
        height: s.height * 0.45 * glowSize,
      ),
      _glowPaint1,
    );

    // ── Flame layers ──────────────────────────────────────
    _drawFlame(canvas, s, cx, baseY,
        swayX: swayX, turbX: turbX * 1.2,
        topOffset: s.height * 0.03, wf: 0.42, hf: flameHeight,
        c1: const Color(0xFFCC2200), c2: const Color(0xFFFF5500));

    _drawFlame(canvas, s, cx, baseY,
        swayX: swayX * 0.85, turbX: turbX * 0.9,
        topOffset: s.height * 0.06, wf: 0.32, hf: flameHeight,
        c1: const Color(0xFFFFAA00), c2: const Color(0xFFFF6600));

    _drawFlame(canvas, s, cx, baseY,
        swayX: swayX * 0.7, turbX: turbX * 0.6,
        topOffset: s.height * 0.10, wf: 0.22, hf: flameHeight,
        c1: const Color(0xFFFFDD00), c2: const Color(0xFFFFAA00));

    _drawFlame(canvas, s, cx, baseY,
        swayX: swayX * 0.45, turbX: turbX * 0.3,
        topOffset: s.height * 0.15, wf: 0.13, hf: flameHeight * 0.93,
        c1: const Color(0xFFFFF176), c2: const Color(0xFFFFDD00));

    _drawFlame(canvas, s, cx, baseY,
        swayX: swayX * 0.2, turbX: turbX * 0.1,
        topOffset: s.height * 0.21, wf: 0.07, hf: flameHeight * 0.86,
        c1: const Color(0xFFFFFFFF), c2: const Color(0xFFFFFDE0));

    // ── Sparks ────────────────────────────────────────────
    for (final spark in sparks) {
      if (spark.isDead) continue;
      _sparkPaint.color = Color.lerp(
        const Color(0xFFFFFFAA),
        const Color(0xFFFF8800),
        1.0 - spark.alpha,
      )!.withOpacity(spark.alpha * flickerOpacity);
      canvas.drawCircle(
          Offset(spark.x, spark.y), spark.size * spark.alpha, _sparkPaint);
    }

    // ── Handle ────────────────────────────────────────────
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - 4, s.height * 0.47, 8, s.height * 0.53),
        const Radius.circular(2.5),
      ),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: const [
            Color(0xFF3A1A05),
            Color(0xFF8B5E3C),
            Color(0xFF6B4020),
            Color(0xFF3A1A05)
          ],
          stops: const [0.0, 0.3, 0.7, 1.0],
        ).createShader(
            Rect.fromLTWH(cx - 4, s.height * 0.47, 8, s.height * 0.53)),
    );

    // ── Bowl ──────────────────────────────────────────────
    final bowl = Path()
      ..moveTo(cx - 10, s.height * 0.455)
      ..quadraticBezierTo(cx - 9, s.height * 0.44, cx - 8, s.height * 0.44)
      ..lineTo(cx + 8, s.height * 0.44)
      ..quadraticBezierTo(cx + 9, s.height * 0.44, cx + 10, s.height * 0.455)
      ..lineTo(cx + 7, s.height * 0.530)
      ..quadraticBezierTo(cx, s.height * 0.538, cx - 7, s.height * 0.530)
      ..close();

    canvas.drawPath(
        bowl,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: const [
              Color(0xFFAA7044),
              Color(0xFF7A4A20),
              Color(0xFF4A2A10)
            ],
          ).createShader(Rect.fromLTWH(
              cx - 10, s.height * 0.44, 20, s.height * 0.10)));
  }

  void _drawFlame(Canvas canvas, Size s, double cx, double baseY,
      {required double swayX,
        required double turbX,
        required double topOffset,
        required double wf,
        required double hf,
        required Color c1,
        required Color c2}) {
    final flameH = (baseY - topOffset) * hf;
    final topY   = baseY - flameH;
    final halfW  = s.width * wf;
    final tipX   = cx + swayX + turbX;

    final path = Path()
      ..moveTo(tipX, topY)
      ..cubicTo(tipX + halfW * 0.8, topY + flameH * 0.25,
          cx + swayX * 0.6 + halfW * 0.9, baseY - flameH * 0.15,
          cx + halfW, baseY)
      ..quadraticBezierTo(cx, baseY + 2, cx - halfW, baseY)
      ..cubicTo(cx + swayX * 0.6 - halfW * 0.9, baseY - flameH * 0.15,
          tipX - halfW * 0.8, topY + flameH * 0.25,
          tipX, topY)
      ..close();

    canvas.drawPath(
        path,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [c1, c2, c2.withOpacity(0.0)],
            stops: const [0.0, 0.55, 1.0],
          ).createShader(Rect.fromLTWH(cx - halfW, topY, halfW * 2, flameH)));
  }

  @override
  bool shouldRepaint(_FlamePainter old) => true;
}