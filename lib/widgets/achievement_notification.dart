import 'package:flutter/material.dart';
import '../services/achievements_service.dart';  // ← Fixed: added 's'
import 'dart:math' as math;

// ═══════════════════════════════════════════════════════════
//  ACHIEVEMENT UNLOCK NOTIFICATION
// ═══════════════════════════════════════════════════════════

class AchievementUnlockNotification extends StatefulWidget {
  final Achievement achievement;
  final VoidCallback? onDismiss;

  const AchievementUnlockNotification({
    Key? key,
    required this.achievement,
    this.onDismiss,
  }) : super(key: key);

  @override
  State<AchievementUnlockNotification> createState() => _AchievementUnlockNotificationState();
}

class _AchievementUnlockNotificationState extends State<AchievementUnlockNotification>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _glowController;
  late AnimationController _confettiController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    // Slide in from top
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.elasticOut,
    ));

    // Glow effect
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    // Confetti
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // Start animations
    _slideController.forward();
    _confettiController.forward();

    // Auto dismiss after 4 seconds
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
    _glowController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  void _dismiss() {
    _slideController.reverse().then((_) {
      widget.onDismiss?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Confetti particles
        ...List.generate(20, (index) => _buildConfettiParticle(index)),

        // Achievement card
        SlideTransition(
          position: _slideAnimation,
          child: GestureDetector(
            onTap: _dismiss,
            child: Container(
              margin: const EdgeInsets.fromLTRB(16, 50, 16, 0),
              child: AnimatedBuilder(
                animation: _glowController,
                builder: (context, child) {
                  return Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFD700).withOpacity(0.3 + _glowController.value * 0.3),
                          blurRadius: 20 + _glowController.value * 10,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFFFFD700),
                            Color(0xFFFF8C00),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.5),
                          width: 2,
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // "Achievement Unlocked!" text
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                '🏆',
                                style: TextStyle(fontSize: 24),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Achievement Unlocked!',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Achievement icon
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                            ),
                            child: Center(
                              child: Text(
                                widget.achievement.emoji,
                                style: const TextStyle(fontSize: 50),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Achievement name
                          Text(
                            widget.achievement.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),

                          // Achievement description
                          Text(
                            widget.achievement.description,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),

                          // Rewards
                          if (widget.achievement.rewards.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                children: [
                                  const Text(
                                    'Rewards:',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 12,
                                    runSpacing: 8,
                                    alignment: WrapAlignment.center,
                                    children: widget.achievement.rewards.map((reward) {
                                      return Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            _getRewardIcon(reward.type),
                                            style: const TextStyle(fontSize: 20),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            reward.displayText,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            ),

                          const SizedBox(height: 12),

                          // Tap to dismiss hint
                          Text(
                            'Tap to dismiss',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConfettiParticle(int index) {
    final random = math.Random(index);
    final startX = random.nextDouble();
    final endX = startX + (random.nextDouble() - 0.5) * 0.3;
    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.yellow,
      Colors.purple,
      Colors.pink,
    ];

    return AnimatedBuilder(
      animation: _confettiController,
      builder: (context, child) {
        final progress = _confettiController.value;
        final screenHeight = MediaQuery.of(context).size.height;
        final screenWidth = MediaQuery.of(context).size.width;

        return Positioned(
          left: (startX + (endX - startX) * progress) * screenWidth,
          top: 100 + progress * screenHeight * 0.8,
          child: Opacity(
            opacity: 1 - progress,
            child: Transform.rotate(
              angle: progress * 4 * math.pi,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: colors[random.nextInt(colors.length)],
                  shape: random.nextBool() ? BoxShape.circle : BoxShape.rectangle,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _getRewardIcon(RewardType type) {
    switch (type) {
      case RewardType.coins:
        return '🪙';
      case RewardType.peas:
        return '🌾';
      case RewardType.furniture:
        return '🛋️';
      case RewardType.cosmetic:
        return '✨';
      case RewardType.multiplier:
        return '⚡';
    }
  }
}

// ═══════════════════════════════════════════════════════════
//  HELPER FUNCTION TO SHOW NOTIFICATION
// ═══════════════════════════════════════════════════════════

void showAchievementUnlocked(BuildContext context, Achievement achievement) {
  final overlay = OverlayEntry(
    builder: (context) => Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Material(
        color: Colors.transparent,
        child: AchievementUnlockNotification(
          achievement: achievement,
          onDismiss: () {
            // Remove overlay after animation completes
          },
        ),
      ),
    ),
  );

  Overlay.of(context).insert(overlay);

  // Auto remove after 5 seconds
  Future.delayed(const Duration(seconds: 5), () {
    overlay.remove();
  });
}