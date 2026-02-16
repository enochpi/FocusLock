import 'package:flutter/material.dart';
import 'package:app_usage/app_usage.dart';
import '../services/app_monitor_service.dart';

class BlockedAppsScreen extends StatefulWidget {
  const BlockedAppsScreen({Key? key}) : super(key: key);

  @override
  State<BlockedAppsScreen> createState() => _BlockedAppsScreenState();
}

class _BlockedAppsScreenState extends State<BlockedAppsScreen> {
  final AppMonitorService appMonitor = AppMonitorService();
  Set<String> blockedApps = {};

  @override
  void initState() {
    super.initState();
    _loadBlockedApps();
  }

  Future<void> _loadBlockedApps() async {
    final blocked = await appMonitor.getBlockedApps();
    setState(() {
      blockedApps = blocked.toSet();
    });
  }

  Future<void> _resetToDefaults() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF16213e),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Reset to Defaults?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'This will restore the default list of blocked apps.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00d4ff),
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await appMonitor.resetToDefaults();
      await _loadBlockedApps();
    }
  }

  Widget _buildStatBox(String emoji, String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0f3460),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF00d4ff).withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Blocked Apps'),
        backgroundColor: const Color(0xFF16213e),
      ),
      backgroundColor: const Color(0xFF0f3460),
      body: FutureBuilder<List<AppUsageInfo>>(
        future: appMonitor.getAllInstalledApps(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.white),
              ),
            );
          }

          final allApps = snapshot.data ?? [];

          // Filter out system apps and our own app
          final userApps = allApps.where((app) {
            return !app.packageName.startsWith('com.android.') &&
                !app.packageName.startsWith('com.google.android.') &&
                app.packageName != 'com.example.focus_lock';  // ✅ Fixed!
          }).toList();

          // Sort by app name
          userApps.sort((a, b) => a.appName.compareTo(b.appName));

          return Column(
            children: [
              // Stats header
              Container(
                padding: const EdgeInsets.all(16),
                color: const Color(0xFF16213e),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatBox(
                      '🚫',
                      '${blockedApps.length}',
                      'Blocked',
                    ),
                    _buildStatBox(
                      '📱',
                      '${userApps.length}',
                      'Total Apps',
                    ),
                  ],
                ),
              ),

              // Reset button
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton.icon(
                  onPressed: _resetToDefaults,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reset to Defaults'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00d4ff),
                  ),
                ),
              ),

              // App list
              Expanded(
                child: ListView.builder(
                  itemCount: userApps.length,
                  itemBuilder: (context, index) {
                    final app = userApps[index];
                    final isBlocked = blockedApps.contains(app.packageName);

                    return Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF16213e),
                        borderRadius: BorderRadius.circular(12),
                        border: isBlocked
                            ? Border.all(color: Colors.red, width: 2)
                            : null,
                      ),
                      child: ListTile(
                        title: Text(
                          app.appName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          app.packageName,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                        trailing: Switch(
                          value: isBlocked,
                          onChanged: (value) async {
                            if (value) {
                              await appMonitor.addBlockedApp(app.packageName);
                            } else {
                              await appMonitor.removeBlockedApp(app.packageName);
                            }
                            await _loadBlockedApps();
                          },
                          activeColor: Colors.red,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}