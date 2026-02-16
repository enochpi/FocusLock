import 'package:flutter/material.dart';
import 'package:focus_life/screens/blocked_apps_screen.dart';
import 'package:focus_life/services/app_monitor_service.dart';
import 'package:focus_life/services/furniture_service.dart';
import 'package:focus_life/services/upgrade_service.dart';
import '../models/character.dart';
import '../services/settings_service.dart';
import '../services/streak_service.dart';
import '../services/currency_service.dart';
import '../services/storage_service.dart';

class SettingsScreen extends StatefulWidget {
  final Character character;

  const SettingsScreen({super.key, required this.character});

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
      backgroundColor: const Color(0xFF1a1a2e),
      appBar: AppBar(
        backgroundColor: const Color(0xFF16213e),
        title: const Text('⚙️ Settings'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile Section
          _buildSectionCard(
            title: '👤 Profile',
            children: [
              _buildProfileTile(),
              const Divider(color: Colors.white24, height: 1),
              _buildStatsTile(),
            ],
          ),

          const SizedBox(height: 16),

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
              const Divider(color: Colors.white24, height: 1),
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
              const Divider(color: Colors.white24, height: 1),
              _buildNavTile(
                title: 'Blocked Apps',
                subtitle: 'Manage blocked apps',
                icon: Icons.block,
                onTap: () {
                  // TODO: Navigate to blocked apps screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Blocked apps manager coming soon!')),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 16),

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
              const Divider(color: Colors.white24, height: 1),
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
              const Divider(color: Colors.white24, height: 1),
              _buildNavTile(
                title: 'Blocked Apps',
                subtitle: 'Manage blocked apps',
                icon: Icons.block,
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BlockedAppsScreen(),
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 16),

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
                    const SnackBar(content: Text('Export feature coming soon!')),
                  );
                },
              ),
              const Divider(color: Colors.white24, height: 1),
              _buildNavTile(
                title: 'Import Save Data',
                subtitle: 'Restore from backup',
                icon: Icons.download,
                onTap: () {
                  // TODO: Implement import
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Import feature coming soon!')),
                  );
                },
              ),
              const Divider(color: Colors.white24, height: 1),
              _buildNavTile(
                title: 'Reset All Progress',
                subtitle: 'Delete everything',
                icon: Icons.delete_forever,
                iconColor: Colors.red,
                onTap: () => _showResetConfirmation(),
              ),
            ],
          ),

          const SizedBox(height: 16),

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
              const Divider(color: Colors.white24, height: 1),
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

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required String title, required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF16213e),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: const TextStyle(
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
      leading: Icon(icon, color: const Color(0xFF00d4ff)),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: Colors.white54, fontSize: 12),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFF00d4ff),
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
      leading: Icon(icon, color: iconColor ?? const Color(0xFF00d4ff)),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: Colors.white54, fontSize: 12),
      ),
      trailing: onTap != null
          ? const Icon(Icons.chevron_right, color: Colors.white54)
          : null,
      onTap: onTap,
    );
  }

  Widget _buildProfileTile() {
    return ListTile(
      leading: const Icon(Icons.person, color: Color(0xFF00d4ff)),
      title: const Text(
        'Character Name',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        widget.character.name,
        style: const TextStyle(color: Colors.white54, fontSize: 12),
      ),
      trailing: const Icon(Icons.edit, color: Color(0xFF00d4ff), size: 20),
      onTap: () => _showEditNameDialog(),
    );
  }

  Widget _buildStatsTile() {
    return ListTile(
      leading: const Icon(Icons.bar_chart, color: Color(0xFF00d4ff)),
      title: const Text(
        'Your Stats',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
      ),
      subtitle: const Text(
        'View detailed statistics',
        style: TextStyle(color: Colors.white54, fontSize: 12),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.white54),
      onTap: () => _showStatsDialog(),
    );
  }

  void _showEditNameDialog() {
    final TextEditingController nameController = TextEditingController(
      text: widget.character.name,
    );
    String? errorText;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: const Color(0xFF16213e),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              'Edit Character Name',
              style: TextStyle(color: Colors.white),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Enter character name',
                    hintStyle: const TextStyle(color: Colors.white38),
                    errorText: errorText,
                    errorStyle: const TextStyle(color: Colors.red),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF00d4ff)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Color(0xFF00d4ff),
                        width: 2,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.red),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Colors.red,
                        width: 2,
                      ),
                    ),
                  ),
                  maxLength: 20,
                  onChanged: (value) {
                    // Clear error when user types
                    if (errorText != null) {
                      setDialogState(() {
                        errorText = null;
                      });
                    }
                  },
                ),
                const SizedBox(height: 8),
                const Text(
                  'Letters and numbers only (max 20 characters)',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.white54),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  String newName = nameController.text.trim();

                  // ✅ VALIDATION
                  if (newName.isEmpty) {
                    setDialogState(() {
                      errorText = 'Name cannot be empty';
                    });
                    return;
                  }

                  // Check if only whitespace (even after trim)
                  if (newName.replaceAll(RegExp(r'\s+'), '').isEmpty) {
                    setDialogState(() {
                      errorText = 'Name cannot be only spaces';
                    });
                    return;
                  }

                  // Check if only emojis/special characters
                  if (!RegExp(r'[a-zA-Z0-9]').hasMatch(newName)) {
                    setDialogState(() {
                      errorText = 'Name must contain letters or numbers';
                    });
                    return;
                  }

                  // Check length (should be redundant with maxLength but good to have)
                  if (newName.length > 20) {
                    setDialogState(() {
                      errorText = 'Name too long (max 20 characters)';
                    });
                    return;
                  }

                  // ✅ VALIDATION PASSED - Save the name
                  setState(() {
                    widget.character.name = newName;
                  });

                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Character name changed to "$newName"'),
                      backgroundColor: const Color(0xFF4CAF50),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00d4ff),
                ),
                child: const Text(
                  'Save',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showStatsDialog() async {
    // Get blocked app count
    int blockCount = await AppMonitorService().getTotalBlockCount();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF16213e),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.bar_chart, color: Color(0xFF00d4ff)),
            SizedBox(width: 8),
            Text('Your Stats', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: SingleChildScrollView(  // ← ADD this wrapper
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStatRow('Total Focus Time', '${widget.character.totalFocusMinutes} min'),
              const Divider(color: Colors.white24),
              _buildStatRow('Peas Earned', '${currency.peas} 🌱'),
              const Divider(color: Colors.white24),
              _buildStatRow('Coins', '${currency.coins} 🪙'),
              const Divider(color: Colors.white24),
              _buildStatRow('Current Streak', '${streak.currentStreak} ${streak.streakEmoji}'),
              const Divider(color: Colors.white24),
              _buildStatRow('Longest Streak', '${streak.longestStreak} days'),
              const Divider(color: Colors.white24),
              _buildStatRow('Apps Blocked', '$blockCount 🚫'),  // ← ADD THIS
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00d4ff)),
            child: const Text('Close', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF00d4ff),
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  void _showResetConfirmation() async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF2d2d2d),
        title: Text('Reset All Progress?', style: TextStyle(color: Colors.white)),
        content: Text(
          'This will delete ALL your progress:\n• Currency (peas & coins)\n• All upgrades\n• House unlocks\n• Furniture\n• Back to Cave stage',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('DELETE EVERYTHING', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await CurrencyService().reset();
      await UpgradeService().reset();
      await FurnitureService().reset();
      setState(() {});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('All progress has been reset!'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}