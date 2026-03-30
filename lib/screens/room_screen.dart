import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:focus_life/services/currency_service.dart';
import 'package:focus_life/services/furniture_service.dart';

enum RoomType {
  houseBedroom,
}

extension RoomTypeExtension on RoomType {
  String get title {
    switch (this) {
      case RoomType.houseBedroom: return 'Bedroom';
    }
  }

  String get imagePath {
    switch (this) {
      case RoomType.houseBedroom:
        return 'assets/images/house_bedroom_background.png';
    }
  }

  RoomType? get nextRoom {
    switch (this) {
      case RoomType.houseBedroom: return null;
    }
  }

  Color get fallbackColor {
    switch (this) {
      case RoomType.houseBedroom: return const Color(0xFF3a2a4a);
    }
  }
}

class RoomScreen extends StatefulWidget {
  final RoomType roomType;
  const RoomScreen({super.key, required this.roomType});

  @override
  State<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends State<RoomScreen> {
  ui.Image? _backgroundImage;
  bool _showFlash = false;
  double _flashOpacity = 0.0;

  @override
  void initState() {
    super.initState();
    _loadBackground();
  }

  Future<void> _loadBackground() async {
    try {
      final ByteData data = await rootBundle.load(widget.roomType.imagePath);
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      if (mounted) setState(() => _backgroundImage = frame.image);
    } catch (e) {
      debugPrint('Background not found: $e');
    }
  }

  void _onDoorTapped() async {
    final next = widget.roomType.nextRoom;
    if (next == null) return;

    setState(() => _showFlash = true);
    for (double i = 0; i <= 1.0; i += 0.1) {
      await Future.delayed(const Duration(milliseconds: 30));
      if (mounted) setState(() => _flashOpacity = i);
    }
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => RoomScreen(roomType: next)),
    );
    for (double i = 1.0; i >= 0; i -= 0.1) {
      await Future.delayed(const Duration(milliseconds: 30));
      if (mounted) setState(() => _flashOpacity = i);
    }
    if (mounted) setState(() => _showFlash = false);
  }

  bool _isOwned(String furnitureId) =>
      FurnitureService().isFurnitureOwned(furnitureId);

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
                    padding: const EdgeInsets.all(10),
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

  void _showBuyDialog(String furnitureId, int price, {double boost = 0.0}) {
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
    );
  }

  // ── BEDROOM furniture ─────────────────────────────────────────────────
  // Prices: 300c → 1000c (endgame bedroom)
  // Boosts: 8% → 15%
  List<Widget> _bedroomFurniture(
      double left, double top, double roomW, double roomH) {
    final s = roomW / 420.0;
    return [
      _buyableImage(left + roomW * 0.435, top + roomH * 0.20, 50 * s, 50 * s,
          'assets/images/house_clock.png', 'bedroom_clock', 15000, boost: 0.54),

      _buyableImage(left + roomW * 0.76, top + roomH * 0.20, 60 * s, 60 * s,
          'assets/images/house_picture.png', 'bedroom_picture', 25000, boost: 0.54),

      _buyableImage(left + roomW * 0.58, top + roomH * 0.37, 80 * s, 80 * s,
          'assets/images/house_desk.png', 'bedroom_desk', 45000, boost: 0.78),

      _buyableImage(left + roomW * 0.001, top + roomH * 0.22, 200 * s, 160 * s,
          'assets/images/house_bunkbed.png', 'bedroom_bunkbed', 80000, boost: 1.00),

      _buyableImage(left + roomW * 0.66, top + roomH * 0.42, 150 * s, 100 * s,
          'assets/images/house_bed.png', 'bedroom_bed', 150000, boost: 1.30),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final hasNextRoom = widget.roomType.nextRoom != null;

    return Scaffold(
      backgroundColor: const Color(0xFF0a0a0a),
      body: SafeArea(
        child: Stack(
          children: [
            // ── Background + furniture ────────────────────────────────────
            Positioned.fill(
              child: LayoutBuilder(builder: (context, constraints) {
                final w     = constraints.maxWidth;
                final h     = constraints.maxHeight;
                final roomW = w;
                final roomH = (w / (420.0 / 300.0)).clamp(0.0, h);
                final top   = (h - roomH) / 2;

                return Stack(
                  children: [
                    Positioned(
                      left: 0, top: top,
                      width: roomW, height: roomH,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: _backgroundImage != null
                            ? RawImage(
                          image: _backgroundImage,
                          fit: BoxFit.cover,
                          width: roomW,
                          height: roomH,
                        )
                            : Container(color: widget.roomType.fallbackColor),
                      ),
                    ),
                    if (widget.roomType == RoomType.houseBedroom)
                      ..._bedroomFurniture(0, top, roomW, roomH),
                  ],
                );
              }),
            ),

            // ── Door to next room ─────────────────────────────────────────
            if (hasNextRoom)
              Positioned(
                bottom: 370, left: 0, right: 0,
                child: Center(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _onDoorTapped,
                    child: Container(width: 50, height: 100, color: Colors.transparent),
                  ),
                ),
              ),

            // ── White flash overlay ───────────────────────────────────────
            if (_showFlash)
              Positioned.fill(
                child: IgnorePointer(
                  child: Container(color: Colors.white.withOpacity(_flashOpacity)),
                ),
              ),

            // ── Room title ────────────────────────────────────────────────
            Positioned(
              top: 16, left: 0, right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    widget.roomType.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),

            // ── Back button ───────────────────────────────────────────────
            Positioned(
              top: 8, left: 8,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}