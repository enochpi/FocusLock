import 'package:flutter/material.dart';
import 'achievement_model.dart';
import 'achievements_service.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({Key? key}) : super(key: key);

  @override
  _AchievementsScreenState createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  final AchievementsService _achievementsService = AchievementsService();
  String _filterType = 'all'; // all, unlocked, locked

  @override
  Widget build(BuildContext context) {
    List<Achievement> filteredAchievements = _getFilteredAchievements();

    return Scaffold(
      backgroundColor: Color(0xFF0a0e27),
      appBar: AppBar(
        backgroundColor: Color(0xFF16213e),
        elevation: 0,
        title: Text(
          'Achievements',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          // Total progress indicator
          Center(
            child: Padding(
              padding: EdgeInsets.only(right: 16),
              child: Text(
                '${_achievementsService.unlockedAchievements.length}/${_achievementsService.allAchievements.length}',
                style: TextStyle(
                  color: Color(0xFF00d4ff),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress bar
          _buildProgressBar(),

          // Filter tabs
          _buildFilterTabs(),

          // Achievements list
          Expanded(
            child: filteredAchievements.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: filteredAchievements.length,
              itemBuilder: (context, index) {
                return _buildAchievementCard(filteredAchievements[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  List<Achievement> _getFilteredAchievements() {
    switch (_filterType) {
      case 'unlocked':
        return _achievementsService.unlockedAchievements;
      case 'locked':
        return _achievementsService.lockedAchievements;
      default:
        return _achievementsService.allAchievements;
    }
  }

  Widget _buildProgressBar() {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFF16213e),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF00d4ff).withOpacity(0.2),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Overall Progress',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${(_achievementsService.completionPercentage * 100).toStringAsFixed(1)}%',
                style: TextStyle(
                  color: Color(0xFF00d4ff),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: _achievementsService.completionPercentage,
              backgroundColor: Color(0xFF0f3460),
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00d4ff)),
              minHeight: 12,
            ),
          ),
          SizedBox(height: 12),
          // Total rewards earned
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.eco, color: Colors.green, size: 20),
              SizedBox(width: 4),
              Text(
                '${_achievementsService.getTotalRewardsEarned().peas} peas',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              SizedBox(width: 16),
              Icon(Icons.monetization_on, color: Colors.amber, size: 20),
              SizedBox(width: 4),
              Text(
                '${_achievementsService.getTotalRewardsEarned().coins} coins',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(child: _buildFilterTab('All', 'all')),
          SizedBox(width: 8),
          Expanded(child: _buildFilterTab('Unlocked', 'unlocked')),
          SizedBox(width: 8),
          Expanded(child: _buildFilterTab('Locked', 'locked')),
        ],
      ),
    );
  }

  Widget _buildFilterTab(String label, String type) {
    bool isSelected = _filterType == type;
    return GestureDetector(
      onTap: () => setState(() => _filterType = type),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFF00d4ff) : Color(0xFF16213e),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.black : Colors.white70,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.emoji_events, size: 80, color: Colors.white24),
          SizedBox(height: 16),
          Text(
            _filterType == 'unlocked'
                ? 'No achievements unlocked yet!'
                : 'All achievements unlocked!',
            style: TextStyle(color: Colors.white54, fontSize: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementCard(Achievement achievement) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Color(0xFF16213e),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: achievement.isUnlocked
              ? achievement.rarity.color.withOpacity(0.5)
              : Colors.transparent,
          width: 2,
        ),
        boxShadow: achievement.isUnlocked
            ? [
          BoxShadow(
            color: achievement.rarity.color.withOpacity(0.2),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ]
            : null,
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            // Icon
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: achievement.isUnlocked
                    ? achievement.rarity.color.withOpacity(0.2)
                    : Colors.white12,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                achievement.icon,
                size: 32,
                color: achievement.isUnlocked
                    ? achievement.rarity.color
                    : Colors.white30,
              ),
            ),
            SizedBox(width: 16),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title + Rarity badge
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          achievement.title,
                          style: TextStyle(
                            color: achievement.isUnlocked
                                ? Colors.white
                                : Colors.white54,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: achievement.rarity.color.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: achievement.rarity.color.withOpacity(0.5),
                          ),
                        ),
                        child: Text(
                          achievement.rarity.displayName,
                          style: TextStyle(
                            color: achievement.rarity.color,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),

                  // Description
                  Text(
                    achievement.description,
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 12,
                    ),
                  ),
                  SizedBox(height: 8),

                  // Progress bar (if locked)
                  if (!achievement.isUnlocked) ...[
                    Row(
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: achievement.progressPercentage,
                              backgroundColor: Color(0xFF0f3460),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFF00d4ff)),
                              minHeight: 6,
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          '${achievement.currentProgress}/${achievement.targetValue}',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                  ],

                  // Rewards
                  Row(
                    children: [
                      if (achievement.reward.peas > 0) ...[
                        Icon(Icons.eco, color: Colors.green, size: 14),
                        SizedBox(width: 4),
                        Text(
                          '${achievement.reward.peas}',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 12),
                      ],
                      if (achievement.reward.coins > 0) ...[
                        Icon(Icons.monetization_on,
                            color: Colors.amber, size: 14),
                        SizedBox(width: 4),
                        Text(
                          '${achievement.reward.coins}',
                          style: TextStyle(
                            color: Colors.amber,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Unlocked checkmark
            if (achievement.isUnlocked)
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: achievement.rarity.color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check,
                  color: achievement.rarity.color,
                  size: 24,
                ),
              ),
          ],
        ),
      ),
    );
  }
}