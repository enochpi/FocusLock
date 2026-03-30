import 'package:flutter/material.dart';
import '../services/daily_reward_service.dart';
import '../services/currency_service.dart';
import '../services/sound_service.dart';
import '../utils/number_formatter.dart';
import 'dart:math' as math;

/// Show the daily reward dialog
Future<void> showDailyRewardDialog(BuildContext context) async {
  final rewardService = DailyRewardService();

  if (!rewardService.canClaimReward()) {
    // Already claimed today - show "come back tomorrow" message
    return _showAlreadyClaimedDialog(context);
  }

  // Can claim! Show reward dialog
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => const DailyRewardDialog(),
  );
}

/// Dialog shown when reward can be claimed
class DailyRewardDialog extends StatefulWidget {
  const DailyRewardDialog({Key? key}) : super(key: key);

  @override
  State<DailyRewardDialog> createState() => _DailyRewardDialogState();
}

class _DailyRewardDialogState extends State<DailyRewardDialog>
    with TickerProviderStateMixin {
  final DailyRewardService _rewardService = DailyRewardService();
  late AnimationController _glowController;
  late AnimationController _bounceController;
  bool _claimed = false;

  @override
  void initState() {
    super.initState();

    // Glow animation
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    // Bounce animation
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  Future<void> _claimReward() async {
    setState(() => _claimed = true);

    // Bounce animation
    await _bounceController.forward();

    // Claim the reward
    final rewards = await _rewardService.claimReward();
    final coins = rewards['coins']!;
    final crops = rewards['crops']!;

    // Grant rewards (addPeas works for all crop types!)
    await CurrencyService().addCoins(coins);
    await CurrencyService().addPeas(crops);
    SoundService().playDailyReward();

    // Wait a moment to show the animation
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final streak = _rewardService.currentStreak;
    final nextStreak = streak + 1;
    final reward = _rewardService.getNextReward();
    final multiplier = _rewardService.getStreakMultiplier();
    final milestone = _rewardService.getNextMilestone();

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Main card
            Container(
              margin: const EdgeInsets.only(top: 40),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF1a1a2e),
                    Color(0xFF16213e),
                    Color(0xFF0f3460),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFFD700).withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 40),

                  // Title
                  const Text(
                    'Daily Reward!',
                    style: TextStyle(
                      color: Color(0xFFFFD700),
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Streak count
                  Text(
                    streak == 0
                        ? 'Start your streak!'
                        : 'Day $nextStreak Streak 🔥',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Reward display
                  AnimatedBuilder(
                    animation: _bounceController,
                    builder: (context, child) {
                      final scale = 1.0 + (_bounceController.value * 0.2);
                      return Transform.scale(
                        scale: _claimed ? scale : 1.0,
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0a0a0a).withOpacity(0.5),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFFFFD700),
                              width: 2,
                            ),
                          ),
                          child: Column(
                            children: [
                              const Text(
                                'Today\'s Reward:',
                                style: TextStyle(
                                  color: Colors.white60,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Coins
                                  Column(
                                    children: [
                                      const Text(
                                        '🪙',
                                        style: TextStyle(fontSize: 32),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        NumberFormatter.format(reward['coins']!),
                                        style: const TextStyle(
                                          color: Color(0xFFFFD700),
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const Text(
                                        'Coins',
                                        style: TextStyle(
                                          color: Colors.white60,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(width: 40),

                                  // Crops (dynamic: peas/carrots/corn/strawberries/wheat)
                                  Column(
                                    children: [
                                      Text(
                                        CurrencyService().cropEmoji,
                                        style: const TextStyle(fontSize: 32),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        NumberFormatter.format(reward['crops']!),
                                        style: const TextStyle(
                                          color: Color(0xFF4CAF50),
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        CurrencyService().cropName,
                                        style: const TextStyle(
                                          color: Colors.white60,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  // Streak multiplier bonus
                  if (multiplier > 1.0)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6B6B).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFFF6B6B),
                          width: 2,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            '🔥',
                            style: TextStyle(fontSize: 20),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Streak Bonus: ${_rewardService.getMultiplierString()}',
                            style: const TextStyle(
                              color: Color(0xFFFF6B6B),
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Next milestone
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Next Milestone: Day ${milestone['days']}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${milestone['daysLeft']} days away → ${((milestone['multiplier'] - 1.0) * 100).round()}% bonus',
                          style: const TextStyle(
                            color: Color(0xFF00D4FF),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Claim button
                  AnimatedBuilder(
                    animation: _glowController,
                    builder: (context, child) {
                      return Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFFD700)
                                  .withOpacity(0.3 + _glowController.value * 0.3),
                              blurRadius: 15 + _glowController.value * 10,
                              spreadRadius: 3,
                            ),
                          ],
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _claimed ? null : _claimReward,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFFD700),
                              disabledBackgroundColor: const Color(0xFF4CAF50),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Text(
                              _claimed ? 'Claimed! ✓' : 'Claim Reward 🎁',
                              style: TextStyle(
                                color: _claimed ? Colors.white : Colors.black,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Trophy icon at top
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Center(
                child: AnimatedBuilder(
                  animation: _glowController,
                  builder: (context, child) {
                    return Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const RadialGradient(
                          colors: [
                            Color(0xFFFFD700),
                            Color(0xFFFF8C00),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFD700)
                                .withOpacity(0.5 + _glowController.value * 0.3),
                            blurRadius: 20 + _glowController.value * 10,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          '🎁',
                          style: TextStyle(fontSize: 50),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dialog shown when already claimed today
Future<void> _showAlreadyClaimedDialog(BuildContext context) async {
  final rewardService = DailyRewardService();
  final streak = rewardService.currentStreak;
  final nextReward = rewardService.getNextReward();
  final multiplier = rewardService.getStreakMultiplier();

  return showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: const Color(0xFF16213e),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: const Row(
        children: [
          Text('✅', style: TextStyle(fontSize: 28)),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Already Claimed!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'You already claimed today\'s reward!',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          if (streak > 0) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0f3460),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    '🔥 $streak Day Streak',
                    style: const TextStyle(
                      color: Color(0xFFFF6B6B),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (multiplier > 1.0) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Bonus: ${rewardService.getMultiplierString()}',
                      style: const TextStyle(
                        color: Color(0xFF00D4FF),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          const Text(
            'Come back tomorrow for:',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '🪙 ${NumberFormatter.format(nextReward['coins']!)}',
                style: const TextStyle(
                  color: Color(0xFFFFD700),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 20),
              Text(
                '${CurrencyService().cropEmoji} ${NumberFormatter.format(nextReward['crops']!)}',
                style: const TextStyle(
                  color: Color(0xFF4CAF50),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00D4FF),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'Got it!',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    ),
  );
}