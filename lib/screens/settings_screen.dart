import 'package:flutter/material.dart';
import '../models/character.dart';
import '../services/settings_service.dart';
import '../services/streak_service.dart';
import '../services/currency_service.dart';
import '../services/storage_service.dart';

class SettingsScreen extends StatefulWidget {
  final Character character;

  SettingsScreen({required this.character});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsService settings = SettingsService();
  final StreakService streak = StreakService();
  final CurrencyService currency = CurrencyService();
  final StorageService storage = StorageService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1a1a2e),
      appBar: AppBar(
        backgroundColor: Color(0xFF16213e),
        title: Text('⚙️ Settings'),
        centerTitle: true,
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          // Profile Section
          _buildSectionCard(
            title: '👤 Profile',
            children: [
              _buildProfileTile(),
              Divider(color: Colors.white24, height: 1),
              _buildStatsTile(),
            ],
          ),

          SizedBox(height: 16),

          // Focus Settings
          _buildSectionCard(
            title: '⏱️ Focus',
            children: [
              _buildSwitchTile(
                title: 'Sounds',
                subtitle: 'Enable sound effects',
                icon: Icons.volume_up,
                value: settings.soundsEnabled,
                onChanged: (value) async {
                  await settings.setSoundsEnabled(value);
                  setState(() {});
                },
              ),
              Divider(color: Colors.white24, height: 1),
              _buildSwitchTile(
                title: 'Break Reminders',
                subtitle: 'Get reminded to take breaks',
                icon: Icons.coffee,
                value: settings.breakReminders,
                onChanged: (value) async {
                  await settings.setBreakReminders(value);
                  setState(() {});
                },
              ),
              Divider(color: Colors.white24, height: 1),
              _buildNavTile(
                title: 'Blocked Apps',
                subtitle: 'Manage blocked apps',
                icon: Icons.block,
                onTap: () {
                  // TODO: Navigate to blocked apps screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Blocked apps manager coming soon!')),
                  );
                },
              ),
            ],
          ),

          SizedBox(height: 16),

          // Notifications
          _buildSectionCard(
            title: '🔔 Notifications',
            children: [
              _buildSwitchTile(
                title: 'Daily Reminder',
                subtitle: 'Remind me to focus',
                icon: Icons.notifications_active,
                value: settings.dailyReminder,
                onChanged: (value) async {
                  await settings.setDailyReminder(value);
                  setState(() {});
                },
              ),
              Divider(color: Colors.white24, height: 1),
              _buildSwitchTile(
                title: 'Streak Reminders',
                subtitle: 'Keep my streak alive!',
                icon: Icons.local_fire_department,
                value: settings.streakReminders,
                onChanged: (value) async {
                  await settings.setStreakReminders(value);
                  setState(() {});
                },
              ),
              Divider(color: Colors.white24, height: 1),
              _buildSwitchTile(
                title: 'Achievement Alerts',
                subtitle: 'Notify on new achievements',
                icon: Icons.emoji_events,
                value: settings.achievementAlerts,
                onChanged: (value) async {
                  await settings.setAchievementAlerts(value);
                  setState(() {});
                },
              ),
            ],
          ),

          SizedBox(height: 16),

          // Data & Privacy
          _buildSectionCard(
            title: '💾 Data & Privacy',
            children: [
              _buildNavTile(
                title: 'Export Save Data',
                subtitle: 'Backup your progress',
                icon: Icons.upload_file,
                onTap: () {
                  // TODO: Implement export
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Export feature coming soon!')),
                  );
                },
              ),
              Divider(color: Colors.white24, height: 1),
              _buildNavTile(
                title: 'Import Save Data',
                subtitle: 'Restore from backup',
                icon: Icons.download,
                onTap: () {
                  // TODO: Implement import
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Import feature coming soon!')),
                  );
                },
              ),
              Divider(color: Colors.white24, height: 1),
              _buildNavTile(
                title: 'Reset All Progress',
                subtitle: 'Delete everything',
                icon: Icons.delete_forever,
                iconColor: Colors.red,
                onTap: () => _showResetConfirmation(),
              ),
            ],
          ),

          SizedBox(height: 16),

          // About
          _buildSectionCard(
            title: 'ℹ️ About',
            children: [
              _buildNavTile(
                title: 'Version',
                subtitle: '1.0.0',
                icon: Icons.info,
                onTap: null,
              ),
              Divider(color: Colors.white24, height: 1),
              _buildNavTile(
                title: 'Credits',
                subtitle: 'Made with ❤️',
                icon: Icons.favorite,
                onTap: () {
                  showAboutDialog(
                    context: context,
                    applicationName: 'Focus Life',
                    applicationVersion: '1.0.0',
                    applicationLegalese: '© 2025 SpartaLabs',
                  );
                },
              ),
            ],
          ),

          SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required String title, required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF16213e),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              title,
              style: TextStyle(
                color: Color(0xFF00d4ff),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return ListTile(
      leading: Icon(icon, color: Color(0xFF00d4ff)),
      title: Text(
        title,
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: Colors.white54, fontSize: 12),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Color(0xFF00d4ff),
      ),
    );
  }

  Widget _buildNavTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback? onTap,
    Color? iconColor,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor ?? Color(0xFF00d4ff)),
      title: Text(
        title,
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: Colors.white54, fontSize: 12),
      ),
      trailing: onTap != null
          ? Icon(Icons.chevron_right, color: Colors.white54)
          : null,
      onTap: onTap,
    );
  }

  Widget _buildProfileTile() {
    return ListTile(
      leading: Icon(Icons.person, color: Color(0xFF00d4ff)),
      title: Text(
        'Character Name',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        widget.character.name,
        style: TextStyle(color: Colors.white54, fontSize: 12),
      ),
      trailing: Icon(Icons.edit, color: Color(0xFF00d4ff), size: 20),
      onTap: () => _showEditNameDialog(),
    );
  }

  Widget _buildStatsTile() {
    return ListTile(
      leading: Icon(Icons.bar_chart, color: Color(0xFF00d4ff)),
      title: Text(
        'Your Stats',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        'View detailed statistics',
        style: TextStyle(color: Colors.white54, fontSize: 12),
      ),
      trailing: Icon(Icons.chevron_right, color: Colors.white54),
      onTap: () => _showStatsDialog(),
    );
  }

  void _showEditNameDialog() {
    TextEditingController controller = TextEditingController(text: widget.character.name);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF16213e),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Edit Name', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Enter new name',
            hintStyle: TextStyle(color: Colors.white54),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF00d4ff)),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF00d4ff)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                widget.character.name = controller.text.trim();
                await storage.saveCharacter(widget.character);
                setState(() {});
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF00d4ff)),
            child: Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showStatsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF16213e),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.bar_chart, color: Color(0xFF00d4ff)),
            SizedBox(width: 8),
            Text('Your Stats', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatRow('Total Focus Time', '${widget.character.totalFocusMinutes} min'),
            Divider(color: Colors.white24),
            _buildStatRow('Peas Earned', '${currency.peas} 🌱'),
            Divider(color: Colors.white24),
            _buildStatRow('Coins', '${currency.coins} 🪙'),
            Divider(color: Colors.white24),
            _buildStatRow('Current Streak', '${streak.currentStreak} ${streak.streakEmoji}'),
            Divider(color: Colors.white24),
            _buildStatRow('Longest Streak', '${streak.longestStreak} days'),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF00d4ff)),
            child: Text('Close', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.white70)),
          Text(
            value,
            style: TextStyle(
              color: Color(0xFF00d4ff),
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  void _showResetConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF16213e),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Reset All Progress?', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Text(
          'This will delete ALL your progress, currency, furniture, and stats. This cannot be undone!',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () async {
              // Reset everything
              await storage.clearAll();
              await currency.reset();
              await streak.resetStreak();
              await settings.resetToDefaults();

              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('All progress has been reset'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Reset', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}