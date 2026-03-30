import 'package:flutter/material.dart';
import '../services/achievements_service.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({Key? key}) : super(key: key);

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> with TickerProviderStateMixin {
  final AchievementService _service = AchievementService();
  AchievementCategory selectedCategory = AchievementCategory.focus;
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0a0a0a),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1a1a1a),
        elevation: 0,
        title: const Text(
          '🏆 Achievements',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Overall Progress Header
          _buildProgressHeader(),

          // Category Tabs
          _buildCategoryTabs(),

          // Achievement List
          Expanded(
            child: _buildAchievementList(),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  PROGRESS HEADER
  // ═══════════════════════════════════════════════════════════

  Widget _buildProgressHeader() {
    final unlocked = _service.totalUnlocked;
    final total = _service.totalAchievements;
    final percent = _service.completionPercent;

    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFFD700).withOpacity(0.2),
            const Color(0xFFFF8C00).withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.5), width: 2),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total Progress',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$unlocked / $total',
                    style: const TextStyle(
                      color: Color(0xFFFFD700),
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              // Trophy icon with glow
              AnimatedBuilder(
                animation: _glowController,
                builder: (context, child) {
                  return Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFD700).withOpacity(_glowController.value * 0.5),
                          blurRadius: 20 + _glowController.value * 10,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        '🏆',
                        style: TextStyle(fontSize: 50),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: percent / 100,
              minHeight: 12,
              backgroundColor: const Color(0xFF2a2a2a),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFD700)),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${percent.toStringAsFixed(1)}% Complete',
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  CATEGORY TABS
  // ═══════════════════════════════════════════════════════════

  Widget _buildCategoryTabs() {
    final categories = [
      (AchievementCategory.focus, '🎯', 'Focus'),
      (AchievementCategory.furniture, '🛋️', 'Furniture'),
      (AchievementCategory.wealth, '💰', 'Wealth'),
      (AchievementCategory.property, '🏠', 'Property'),
      (AchievementCategory.power, '⚡', 'Power'),
      (AchievementCategory.secret, '🎭', 'Secret'),
    ];

    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = selectedCategory == cat.$1;
          final count = _service.getByCategory(cat.$1).where((a) => a.isUnlocked).length;
          final total = _service.getByCategory(cat.$1).length;

          return GestureDetector(
            onTap: () => setState(() => selectedCategory = cat.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFFFD700).withOpacity(0.2) : const Color(0xFF1a1a1a),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? const Color(0xFFFFD700) : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Text(cat.$2, style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 6),
                      Text(
                        cat.$3,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white60,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$count/$total',
                    style: TextStyle(
                      color: isSelected ? const Color(0xFFFFD700) : Colors.white38,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  ACHIEVEMENT LIST
  // ═══════════════════════════════════════════════════════════

  Widget _buildAchievementList() {
    final achievements = _service.getByCategory(selectedCategory);

    if (achievements.isEmpty) {
      return const Center(
        child: Text(
          'No achievements in this category',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: achievements.length,
      itemBuilder: (context, index) {
        return _buildAchievementCard(achievements[index]);
      },
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  ACHIEVEMENT CARD
  // ═══════════════════════════════════════════════════════════

  Widget _buildAchievementCard(Achievement achievement) {
    final isUnlocked = achievement.isUnlocked;
    final isSecret = achievement.isSecret && !isUnlocked;
    final progress = achievement.progressPercent;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isUnlocked
              ? [
            const Color(0xFFFFD700).withOpacity(0.15),
            const Color(0xFFFF8C00).withOpacity(0.15),
          ]
              : [
            const Color(0xFF1a1a1a),
            const Color(0xFF1a1a1a),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isUnlocked
              ? const Color(0xFFFFD700).withOpacity(0.6)
              : Colors.white.withOpacity(0.1),
          width: 2,
        ),
        boxShadow: isUnlocked
            ? [
          BoxShadow(
            color: const Color(0xFFFFD700).withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ]
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Icon
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: isUnlocked
                        ? const Color(0xFFFFD700).withOpacity(0.2)
                        : const Color(0xFF2a2a2a),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isUnlocked ? const Color(0xFFFFD700) : Colors.white24,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      isSecret ? '❓' : achievement.emoji,
                      style: TextStyle(
                        fontSize: 32,
                        color: isSecret ? Colors.white24 : null,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              isSecret ? '???' : achievement.name,
                              style: TextStyle(
                                color: isUnlocked ? const Color(0xFFFFD700) : Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (isUnlocked)
                            const Icon(
                              Icons.check_circle,
                              color: Color(0xFFFFD700),
                              size: 24,
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isSecret ? 'Secret Achievement' : achievement.description,
                        style: TextStyle(
                          color: isUnlocked ? Colors.white70 : Colors.white54,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            if (!isUnlocked && !isSecret) ...[
              const SizedBox(height: 12),
              // Progress bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Progress: ${achievement.currentProgress} / ${achievement.targetValue}',
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '${progress.toStringAsFixed(0)}%',
                        style: const TextStyle(
                          color: Color(0xFFFFD700),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress / 100,
                      minHeight: 8,
                      backgroundColor: const Color(0xFF2a2a2a),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFD700)),
                    ),
                  ),
                ],
              ),
            ],

            // Rewards
            if (!isSecret) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: achievement.rewards.map((reward) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getRewardColor(reward.type).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _getRewardColor(reward.type).withOpacity(0.5),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _getRewardIcon(reward.type),
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          reward.displayText,
                          style: TextStyle(
                            color: _getRewardColor(reward.type),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],

            // Unlocked date
            if (isUnlocked && achievement.unlockedAt != null) ...[
              const SizedBox(height: 8),
              Text(
                'Unlocked: ${_formatDate(achievement.unlockedAt!)}',
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  HELPERS
  // ═══════════════════════════════════════════════════════════

  Color _getRewardColor(RewardType type) {
    switch (type) {
      case RewardType.coins:
        return const Color(0xFFFFD700);
      case RewardType.peas:
        return const Color(0xFF4CAF50);
      case RewardType.furniture:
        return const Color(0xFF8B4513);
      case RewardType.cosmetic:
        return const Color(0xFFFF69B4);
      case RewardType.multiplier:
        return const Color(0xFF00D4FF);
    }
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

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}