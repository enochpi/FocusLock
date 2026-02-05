import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static final SettingsService _instance = SettingsService._internal();
  factory SettingsService() => _instance;
  SettingsService._internal();

  // Settings values
  bool _soundsEnabled = true;
  bool _breakReminders = true;
  bool _dailyReminder = true;
  bool _streakReminders = true;
  bool _achievementAlerts = true;
  String _dailyReminderTime = "09:00"; // Default 9 AM

  // Getters
  bool get soundsEnabled => _soundsEnabled;
  bool get breakReminders => _breakReminders;
  bool get dailyReminder => _dailyReminder;
  bool get streakReminders => _streakReminders;
  bool get achievementAlerts => _achievementAlerts;
  String get dailyReminderTime => _dailyReminderTime;

  /// Initialize - Load saved settings
  Future<void> init() async {
    await loadSettings();
  }

  /// Toggle sounds
  Future<void> setSoundsEnabled(bool value) async {
    _soundsEnabled = value;
    await saveSettings();
  }

  /// Toggle break reminders
  Future<void> setBreakReminders(bool value) async {
    _breakReminders = value;
    await saveSettings();
  }

  /// Toggle daily reminder
  Future<void> setDailyReminder(bool value) async {
    _dailyReminder = value;
    await saveSettings();
  }

  /// Set daily reminder time
  Future<void> setDailyReminderTime(String time) async {
    _dailyReminderTime = time;
    await saveSettings();
  }

  /// Toggle streak reminders
  Future<void> setStreakReminders(bool value) async {
    _streakReminders = value;
    await saveSettings();
  }

  /// Toggle achievement alerts
  Future<void> setAchievementAlerts(bool value) async {
    _achievementAlerts = value;
    await saveSettings();
  }

  /// Save all settings
  Future<void> saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sounds_enabled', _soundsEnabled);
    await prefs.setBool('break_reminders', _breakReminders);
    await prefs.setBool('daily_reminder', _dailyReminder);
    await prefs.setString('daily_reminder_time', _dailyReminderTime);
    await prefs.setBool('streak_reminders', _streakReminders);
    await prefs.setBool('achievement_alerts', _achievementAlerts);
  }

  /// Load all settings
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _soundsEnabled = prefs.getBool('sounds_enabled') ?? true;
    _breakReminders = prefs.getBool('break_reminders') ?? true;
    _dailyReminder = prefs.getBool('daily_reminder') ?? true;
    _dailyReminderTime = prefs.getString('daily_reminder_time') ?? "09:00";
    _streakReminders = prefs.getBool('streak_reminders') ?? true;
    _achievementAlerts = prefs.getBool('achievement_alerts') ?? true;
  }

  /// Reset all settings to defaults
  Future<void> resetToDefaults() async {
    _soundsEnabled = true;
    _breakReminders = true;
    _dailyReminder = true;
    _dailyReminderTime = "09:00";
    _streakReminders = true;
    _achievementAlerts = true;
    await saveSettings();
  }
}