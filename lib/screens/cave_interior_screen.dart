import 'dart:async';

import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:berry_focused/furniture/earthen_window_painter.dart';
import 'package:berry_focused/furniture/wooden_window_painter.dart';
import 'package:berry_focused/services/furniture_service.dart';
import '../furniture/shack_lights.dart';
import '../models/character.dart';
import '../services/currency_service.dart';
import 'package:berry_focused/services/day_night_cycle.dart';


class CaveInteriorScreen extends StatefulWidget {
  final Character character;
  final int stage;

  const CaveInteriorScreen({
    super.key,
    required this.character,
    required this.stage,
  });

  @override
  State<CaveInteriorScreen> createState() => _CaveInteriorScreenState();
}

class _CaveInteriorScreenState extends State<CaveInteriorScreen> {
  ui.Image? _backgroundImage;
  Timer? _skyTimer;
  bool _dialogShowing = false;

  @override
  void initState() {
    super.initState();
    _loadBackgroundImage();

    _skyTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _skyTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadBackgroundImage() async {
    final path = _bgPath(widget.stage);
    try {
      final data  = await rootBundle.load(path);
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      if (mounted) setState(() => _backgroundImage = frame.image);
    } catch (_) {}
  }

  String _bgPath(int stage) {
    switch (stage) {
      case 0:  return 'assets/images/cave_background.webp';
      case 1:  return 'assets/images/shack_background.webp';
      case 2:  return 'assets/images/house_background.webp';
      default: return 'assets/images/cave_background.webp';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0a0a0a),
      body: SafeArea(
        child: Stack(
          children: [
            // ── Room ────────────────────────────────────────────────────
            Positioned.fill(
              child: LayoutBuilder(builder: (context, constraints) {
                final w     = constraints.maxWidth;
                final h     = constraints.maxHeight;
                final roomW = w;
                final roomH = (w / (420.0 / 300.0)).clamp(0.0, h);
                final left  = 0.0;
                final top   = (h - roomH) / 2;

                return Stack(
                  children: [
                    Positioned(
                      left: left, top: top,
                      width: roomW, height: roomH,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: _backgroundImage != null
                            ? RawImage(
                            image: _backgroundImage,
                            fit: BoxFit.cover,
                            width: roomW, height: roomH)
                            : Container(color: const Color(0xFF1a1a1a)),
                      ),
                    ),
                    ..._buildFurniture(widget.stage, left, top, roomW, roomH),
                  ],
                );
              }),
            ),

            // Door tap zone (house stage 2+)
            if (widget.stage >= 2)
              Positioned(
                bottom: 369, left: 0, right: 0,
                child: Center(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    child: Container(width: 80, height: 120),
                  ),
                ),
              ),

            // Top bar
            Positioned(
              top: 16, left: 16, right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Text('🪙', style: TextStyle(fontSize: 20)),
                        const SizedBox(width: 8),
                        Text('${CurrencyService().coins}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── _buyableImage ─────────────────────────────────────────────────────
  Widget _buyableImage(double x, double y, double w, double h, String asset,
      String furnitureId, int price, {double boost = 0.0}) {
    final owned = _isOwned(furnitureId);
    return Positioned(
      left: x, top: y, width: w, height: h,
      child: Stack(
        children: [
          Opacity(
            opacity: owned ? 1.0 : 0.15,
            child: Image.asset(asset, fit: BoxFit.contain, width: w, height: h),
          ),
          if (!owned)
            Center(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _showBuyDialog(furnitureId, price, boost: boost),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF5A3A22).withOpacity(0.75),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF8C00).withOpacity(0.2),
                          blurRadius: 8, spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.add, color: Color(0xFFFFB347), size: 14),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── _buyablePainter ───────────────────────────────────────────────────
  Widget _buyablePainter(double x, double y, double w, double h,
      CustomPainter painter, String furnitureId, int price, {double boost = 0.0}) {
    final owned = _isOwned(furnitureId);
    return Positioned(
      left: x, top: y, width: w, height: h,
      child: Stack(
        children: [
          Opacity(
            opacity: owned ? 1.0 : 0.15,
            child: CustomPaint(painter: painter, size: Size(w, h)),
          ),
          if (!owned)
            Center(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _showBuyDialog(furnitureId, price, boost: boost),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF5A3A22).withOpacity(0.75),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF8C00).withOpacity(0.2),
                          blurRadius: 8, spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.add, color: Color(0xFFFFB347), size: 14),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── _showBuyDialog ────────────────────────────────────────────────────
  void _showBuyDialog(String furnitureId, int price, {double boost = 0.0}) {
    if (_dialogShowing) return;
    _dialogShowing = true;
    final canAfford = CurrencyService().coins >= price;
    final boostPercent = (boost * 100).toStringAsFixed(0);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF3D2B1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: const Color(0xFF7A5238).withOpacity(0.5), width: 1.5),
        ),
        title: Text(
          canAfford ? 'Build this?' : 'Not enough coins!',
          style: const TextStyle(color: Color(0xFFDDC4A0)),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (boost > 0)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green, width: 1.5),
                ),
                child: Text(
                  '+$boostPercent% production boost',
                  style: const TextStyle(
                    color: Colors.greenAccent,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🪙', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 8),
                Text(
                  '$price',
                  style: TextStyle(
                    color: canAfford ? const Color(0xFFFFB347) : Colors.red[300],
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'You have: ${CurrencyService().coins} 🪙',
              style: const TextStyle(color: Color(0xFF9B7A5C), fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF9B7A5C))),
          ),
          if (canAfford)
            ElevatedButton(
              onPressed: () async {
                await CurrencyService().removeCoins(price);
                FurnitureService().buyFurniture(furnitureId);
                Navigator.pop(context);
                setState(() {});
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5A3A22),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                side: const BorderSide(color: Color(0xFFFFB347), width: 1.5),
              ),
              child: const Text('Build!',
                  style: TextStyle(color: Color(0xFFFFB347), fontWeight: FontWeight.bold, fontSize: 16)),
            ),
        ],
      ),
    ).then((_) => _dialogShowing = false);
  }

  // ── Furniture layout ──────────────────────────────────────────────────
  List<Widget> _buildFurniture(
      int stage, double left, double top, double roomW, double roomH) {
    switch (stage) {
      case 0:  return _caveFurniture(left, top, roomW, roomH);
      case 1:  return _shackFurniture(left, top, roomW, roomH);
      case 2:  return _houseFurniture(left, top, roomW, roomH);
      default: return [];
    }
  }

  bool _isOwned(String furnitureId) =>
      FurnitureService().isFurnitureOwned(furnitureId);

  // ── CAVE ──────────────────────────────────────────────────────────────
  List<Widget> _caveFurniture(
      double left, double top, double roomW, double roomH) {
    final s = roomW / 420.0;
    return [
      _buyableImage(left + roomW * 0.01, top + roomH * 0.44, 250 * s, 250 * s,
          'assets/images/stone_rug.webp', 'stone_rug', 8, boost: 0.22),

      _buyableImage(left + roomW * 0.09, top + roomH * 0.42, 200 * s, 120 * s,
          'assets/images/stone_bed.webp', 'stone_bed', 80, boost: 0.55),

      _buyableImage(left + roomW * 0.57, top + roomH * 0.45, 150 * s, 150 * s,
          'assets/images/stone_table.webp', 'stone_table', 150, boost: 0.72),

      _buyablePainter(left + roomW * 0.40, top + roomH * 0.17, 80 * s, 70 * s,
          EarthenWindowPainter(cycle: DayNightCycle.current()),
          'stone_window', 3, boost: 0.10),

      _buyableImage(left + roomW * 0.42, top + roomH * 0.58, 90 * s, 90 * s,
          'assets/images/stone_fire.webp', 'stone_fire', 20, boost: 0.30),

      _buyableImage(left + roomW * 0.65, top + roomH * 0.70, 80 * s, 80 * s,
          'assets/images/stone_chair.webp', 'stone_chair', 40, boost: 0.38),
    ];
  }

  // ── SHACK ─────────────────────────────────────────────────────────────
  List<Widget> _shackFurniture(
      double left, double top, double roomW, double roomH) {
    final s = roomW / 420.0;
    final lightsOwned = _isOwned('shack_lights');

    return [
      Positioned(
        left: left + roomW * 0.05,
        top: top + roomH * 0.07,
        width: roomW * 0.9,
        height: 28 * s,
        child: Stack(
          children: [
            Opacity(
              opacity: lightsOwned ? 1.0 : 0.15,
              child: const ShackStringLights(),
            ),
            if (!lightsOwned)
              Center(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _showBuyDialog('shack_lights', 100, boost: 0.15),
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF5A3A22).withOpacity(0.75),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF8C00).withOpacity(0.2),
                          blurRadius: 8, spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.add, color: Color(0xFFFFB347), size: 14),
                  ),
                ),
              ),
          ],
        ),
      ),

      _buyablePainter(left + roomW * 0.414, top + roomH * 0.2, 70 * s, 60 * s,
          WoodenWindowPainter(cycle: DayNightCycle.current()),
          'shack_window', 400, boost: 0.22),

      _buyableImage(left + roomW * 0.08, top + roomH * 0.20, 80 * s, 60 * s,
          'assets/images/shack_picture.webp', 'shack_picture', 1000, boost: 0.22),

      _buyableImage(left + roomW * 0, top + roomH * 0.41, 170 * s, 150 * s,
          'assets/images/shack_bed.webp', 'shack_bed', 4000, boost: 0.42),

      _buyableImage(left + roomW * 0.31, top + roomH * 0.56, 180 * s, 140 * s,
          'assets/images/shack_table.webp', 'shack_table', 2000, boost: 0.28),

      _buyableImage(left + roomW * 0.73, top + roomH * 0.33, 90 * s, 130 * s,
          'assets/images/shack_stove.webp', 'shack_stove', 8000, boost: 0.55),
    ];
  }

  // ── HOUSE (kitchen) ───────────────────────────────────────────────────
  List<Widget> _houseFurniture(
      double left, double top, double roomW, double roomH) {
    final s = roomW / 420.0;
    return [
      _buyableImage(left + roomW * 0.41, top + roomH * 0.04, 70 * s, 44 * s,
          'assets/images/house_light.webp', 'house_light', 200, boost: 0.08),

      _buyableImage(left + roomW * 0.16, top + roomH * 0.06, 100 * s, 90 * s,
          'assets/images/house_cabinet.webp', 'house_cabinet', 300, boost: 0.08),

      _buyableImage(left + roomW * 0.59, top + roomH * 0.50, 150 * s, 75 * s,
          'assets/images/house_table.webp', 'house_table', 400, boost: 0.10),

      _buyableImage(left + roomW * 0.13, top + roomH * 0.37, 120 * s, 110 * s,
          'assets/images/house_stove.webp', 'house_stove', 600, boost: 0.12),

      _buyableImage(left - roomW * 0.04, top + roomH * 0.24, 100 * s, 150 * s,
          'assets/images/house_fridge.webp', 'house_fridge', 800, boost: 0.15),
    ];
  }

  Widget _placed(double x, double y, double w, double h, CustomPainter painter) {
    return Positioned(
      left: x, top: y, width: w, height: h,
      child: CustomPaint(painter: painter, size: Size(w, h)),
    );
  }

  Widget _placedImage(double x, double y, double w, double h, String asset,
      {double opacity = 1.0}) {
    return Positioned(
      left: x, top: y, width: w, height: h,
      child: Opacity(
        opacity: opacity,
        child: Image.asset(asset, fit: BoxFit.contain),
      ),
    );
  }
}