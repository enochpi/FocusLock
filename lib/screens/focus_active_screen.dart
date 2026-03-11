import 'package:flutter/material.dart';
import '../models/focus_session.dart';
import '../services/currency_service.dart';
import '../services/streak_service.dart';
import '../services/daily_reward_service.dart';
import '../services/furniture_service.dart';
import 'dart:async';

class FocusActiveScreen extends StatefulWidget {
  final int durationMinutes;

  const FocusActiveScreen({
    super.key,
    required this.durationMinutes,
  });

  @override
  _FocusActiveScreenState createState() => _FocusActiveScreenState();
}

class _FocusActiveScreenState extends State<FocusActiveScreen> {
  late FocusSession session;
  Timer? timer;

  final CurrencyService _currency = CurrencyService();
  final StreakService _streak = StreakService();
  final DailyRewardService _dailyReward = DailyRewardService();
  final FurnitureService _furniture = FurnitureService();

  @override
  void initState() {
    super.initState();
    session = FocusSession(durationMinutes: widget.durationMinutes);
    session.start();

    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() {
        session.tick();
        if (session.isComplete) {
          t.cancel();
          onComplete();
        }
      });
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void onComplete() async {
    // Record streak
    await _streak.recordFocusSession();

    // Snapshot multipliers BEFORE adding peas (for display)
    final double furnitureBoost = _furniture.getBoostMultiplier();
    final double streakBoost = _dailyReward.getStreakMultiplier();
    final String cropEmoji = _currency.cropEmoji;
    final String cropName = _currency.cropName;

    // calculatePeasFromFocus already applies furniture + streak multipliers internally
    final int peasEarned = CurrencyService.calculatePeasFromFocus(
      widget.durationMinutes,
    );
    await _currency.addPeas(peasEarned);

    // Build multiplier breakdown text
    final List<String> bonuses = [];
    if (furnitureBoost > 1.0) {
      bonuses.add('🛋️ +${((furnitureBoost - 1) * 100).round()}% furniture');
    }
    if (streakBoost > 1.0) {
      bonuses.add('🔥 +${((streakBoost - 1) * 100).round()}% streak (day ${_streak.currentStreak})');
    }

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF16213e),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Session Complete! 🎉",
          style: TextStyle(color: Colors.white),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Peas earned
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0f3460),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    '$cropEmoji +$peasEarned $cropName',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.durationMinutes} minutes focused',
                    style: const TextStyle(color: Colors.white54, fontSize: 14),
                  ),
                ],
              ),
            ),

            // Multiplier breakdown (only shown if bonuses apply)
            if (bonuses.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    const Text(
                      'Multipliers applied:',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                    ...bonuses.map((b) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Text(
                        b,
                        style: const TextStyle(
                          color: Colors.greenAccent,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )),
                    const SizedBox(height: 4),
                    Text(
                      'Total: ${(furnitureBoost * streakBoost).toStringAsFixed(2)}x',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // close dialog
                Navigator.pop(context); // return to main screen
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Collect',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Focus Time",
              style: TextStyle(color: Colors.white70, fontSize: 24),
            ),
            const SizedBox(height: 40),
            Text(
              session.formattedTime,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 72,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            // Live multiplier preview shown during session
            _MultiplierPreview(
              furnitureBoost: FurnitureService().getBoostMultiplier(),
              streakBoost: DailyRewardService().getStreakMultiplier(),
              cropEmoji: CurrencyService().cropEmoji,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Small widget showing active multipliers during the session ──
class _MultiplierPreview extends StatelessWidget {
  final double furnitureBoost;
  final double streakBoost;
  final String cropEmoji;

  const _MultiplierPreview({
    required this.furnitureBoost,
    required this.streakBoost,
    required this.cropEmoji,
  });

  @override
  Widget build(BuildContext context) {
    final double total = furnitureBoost * streakBoost;
    if (total <= 1.0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Text(
        '$cropEmoji ${total.toStringAsFixed(2)}x boost active',
        style: const TextStyle(
          color: Colors.greenAccent,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}