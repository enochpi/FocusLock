import 'package:flutter/material.dart';
import 'achievement_model.dart';

/// Show achievement unlock notification
void showAchievementUnlock(BuildContext context, Achievement achievement) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AchievementUnlockDialog(achievement: achievement),
  );
}

class AchievementUnlockDialog extends StatefulWidget {
  final Achievement achievement;

  const AchievementUnlockDialog({Key? key, required this.achievement})
      : super(key: key);

  @override
  _AchievementUnlockDialogState createState() =>
      _AchievementUnlockDialogState();
}

class _AchievementUnlockDialogState extends State<AchievementUnlockDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF16213e),
                  Color(0xFF0f3460),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: widget.achievement.rarity.color.withOpacity(0.5),
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.achievement.rarity.color.withOpacity(0.4),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // "ACHIEVEMENT UNLOCKED" header
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: widget.achievement.rarity.color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: widget.achievement.rarity.color.withOpacity(0.5),
                    ),
                  ),
                  child: Text(
                    '🎉 ACHIEVEMENT UNLOCKED!',
                    style: TextStyle(
                      color: widget.achievement.rarity.color,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                SizedBox(height: 20),

                // Icon
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: widget.achievement.rarity.color.withOpacity(0.2),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: widget.achievement.rarity.color.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Icon(
                    widget.achievement.icon,
                    size: 50,
                    color: widget.achievement.rarity.color,
                  ),
                ),
                SizedBox(height: 20),

                // Rarity badge
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: widget.achievement.rarity.color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: widget.achievement.rarity.color.withOpacity(0.5),
                    ),
                  ),
                  child: Text(
                    widget.achievement.rarity.displayName.toUpperCase(),
                    style: TextStyle(
                      color: widget.achievement.rarity.color,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                SizedBox(height: 12),

                // Title
                Text(
                  widget.achievement.title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),

                // Description
                Text(
                  widget.achievement.description,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 20),

                // Rewards
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Color(0xFF00d4ff).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Color(0xFF00d4ff).withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'REWARDS',
                        style: TextStyle(
                          color: Color(0xFF00d4ff),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (widget.achievement.reward.peas > 0) ...[
                            Icon(Icons.eco, color: Colors.green, size: 24),
                            SizedBox(width: 8),
                            Text(
                              '+${widget.achievement.reward.peas}',
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              'peas',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                            if (widget.achievement.reward.coins > 0)
                              SizedBox(width: 24),
                          ],
                          if (widget.achievement.reward.coins > 0) ...[
                            Icon(Icons.monetization_on,
                                color: Colors.amber, size: 24),
                            SizedBox(width: 8),
                            Text(
                              '+${widget.achievement.reward.coins}',
                              style: TextStyle(
                                color: Colors.amber,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              'coins',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24),

                // Claim button
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.achievement.rarity.color,
                    padding: EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 8,
                    shadowColor: widget.achievement.rarity.color.withOpacity(0.5),
                  ),
                  child: Text(
                    'AWESOME! 🎊',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Achievement notification badge (top of screen, less intrusive)
void showAchievementBadge(BuildContext context, Achievement achievement) {
  final overlay = Overlay.of(context);
  late OverlayEntry overlayEntry;

  overlayEntry = OverlayEntry(
    builder: (context) => Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 500),
          tween: Tween(begin: -100.0, end: 0.0),
          curve: Curves.elasticOut,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, value),
              child: child,
            );
          },
          child: Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF16213e),
                  Color(0xFF0f3460),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: achievement.rarity.color.withOpacity(0.5),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: achievement.rarity.color.withOpacity(0.3),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: achievement.rarity.color.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    achievement.icon,
                    color: achievement.rarity.color,
                    size: 28,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Achievement Unlocked!',
                        style: TextStyle(
                          color: achievement.rarity.color,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        achievement.title,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.celebration, color: Colors.amber, size: 24),
              ],
            ),
          ),
          onEnd: () {
            // Auto-dismiss after 3 seconds
            Future.delayed(Duration(seconds: 3), () {
              overlayEntry.remove();
            });
          },
        ),
      ),
    ),
  );

  overlay.insert(overlayEntry);
}