import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:berry_focused/services/achievements_service.dart';
import 'package:berry_focused/services/streak_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:math' as math;
import '../models/character.dart';
import '../services/currency_service.dart';
import '../services/notification_service.dart';
import '../services/settings_service.dart';
import '../services/sound_service.dart';
import '../services/upgrade_service.dart';
import '../services/app_monitor_service.dart';
import '../services/focus_session_service.dart';
import '../services/storage_service.dart';
import '../services/focus_stats_service.dart';
import 'blocking_screen.dart';
import '../services/feedback_service.dart';
import '../utils/number_formatter.dart';

// ── Foreground task handler (separate isolate) ────────────────────────
const String _timerRemainingKey = 'bf_timer_remaining_seconds_v3';
const String _timerEndEpochKey = 'bf_timer_end_epoch_ms_v3';
const String _timerPausedKey = 'bf_timer_paused_v3';
const String _timerCompletedKey = 'bf_timer_completed_v3';

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(_FocusTaskHandler());
}

class _FocusTaskHandler extends TaskHandler {
  bool _tickInProgress = false;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    await _tick();
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    if (!_tickInProgress) {
      unawaited(_tick());
    }
  }

  // v8.13.0 defines this callback as void. Timer state is shared through
  // foreground-task storage, so no isolate messages are required.
  @override
  void onReceiveData(Object data) {}

  @override
  Future<void> onDestroy(DateTime timestamp) async {}

  Future<void> _tick() async {
    if (_tickInProgress) return;
    _tickInProgress = true;

    try {
      final paused =
          await FlutterForegroundTask.getData<bool>(key: _timerPausedKey) ??
              false;
      final savedRemaining =
          await FlutterForegroundTask.getData<int>(key: _timerRemainingKey) ??
              0;
      final endEpoch =
          await FlutterForegroundTask.getData<int>(key: _timerEndEpochKey);

      int remaining = savedRemaining.clamp(0, 24 * 60 * 60).toInt();

      if (!paused && endEpoch != null) {
        final millisecondsLeft =
            endEpoch - DateTime.now().millisecondsSinceEpoch;
        remaining = millisecondsLeft <= 0
            ? 0
            : (millisecondsLeft / 1000).ceil();
      }

      await FlutterForegroundTask.saveData(
        key: _timerRemainingKey,
        value: remaining,
      );
      await FlutterForegroundTask.saveData(
        key: _timerCompletedKey,
        value: remaining <= 0,
      );

      await FlutterForegroundTask.updateService(
        notificationTitle: remaining <= 0
            ? 'Berry Focused — Session complete! 🎉'
            : paused
                ? 'Berry Focused — Timer paused'
                : 'Berry Focused — Keep it up! 🌱',
        notificationText: remaining <= 0
            ? 'Open Berry Focused to collect your reward.'
            : _formatRemaining(remaining),
      );
    } catch (error) {
      // A notification update failure must never affect the on-screen timer.
      debugPrint('Foreground timer tick failed: $error');
    } finally {
      _tickInProgress = false;
    }
  }

  String _formatRemaining(int totalSeconds) {
    final safe = totalSeconds.clamp(0, 24 * 60 * 60).toInt();
    final hours = safe ~/ 3600;
    final minutes = (safe % 3600) ~/ 60;
    final seconds = safe % 60;

    if (hours > 0) {
      return '${hours}h '
          '${minutes.toString().padLeft(2, '0')}m '
          '${seconds.toString().padLeft(2, '0')}s remaining';
    }

    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')} remaining';
  }
}

void _initForegroundTask() {
  FlutterForegroundTask.init(
    androidNotificationOptions: AndroidNotificationOptions(
      channelId: 'berry_focused_timer_v3',
      channelName: 'Berry Focused Timer',
      channelDescription:
          'Keeps an active focus countdown visible in the background',
      channelImportance: NotificationChannelImportance.LOW,
      priority: NotificationPriority.LOW,
      onlyAlertOnce: true,
    ),
    iosNotificationOptions: const IOSNotificationOptions(
      showNotification: true,
      playSound: false,
    ),
    foregroundTaskOptions: ForegroundTaskOptions(
      eventAction: ForegroundTaskEventAction.repeat(1000),
      autoRunOnBoot: false,
      allowWakeLock: true,
    ),
  );
}

// ══════════════════════════════════════════════════════════════════════
// MAIN SCREEN
// ══════════════════════════════════════════════════════════════════════

class GardenFocusScreen extends StatefulWidget {
  final Character character;
  final int focusDurationMinutes;
  final int? initialRemainingSeconds;

  const GardenFocusScreen({
    super.key,
    required this.character,
    required this.focusDurationMinutes,
    this.initialRemainingSeconds,
  });

  @override
  State<GardenFocusScreen> createState() => _GardenFocusScreenState();
}

class _GardenFocusScreenState extends State<GardenFocusScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final CurrencyService currency = CurrencyService();
  final UpgradeService upgrades = UpgradeService();
  final AppMonitorService appMonitor = AppMonitorService();
  final FocusSessionService sessionService = FocusSessionService();

  late AnimationController _ambientController;
  int _remainingSeconds = 0;
  DateTime? _runningUntil;

  Timer? _breakReminderTimer;
  Timer? _distractionBreakTimer;
  DateTime? _distractionBreakEndsAt;
  Timer? _saveTimer;
  Timer? _uiTimer;

  bool _isWorking = false;
  bool _isPaused = false;
  bool _isFinished = false;
  bool _sessionStarting = false;
  bool _backgroundServiceReady = false;
  String? _backgroundWarning;

  bool _torchesOwned = false;
  bool _chimesOwned = false;
  bool _fountainOwned = false;

  int _characterTapCount = 0;
  bool _easterEggActive = false;

  final ValueNotifier<Offset> _parallaxOffset =
      ValueNotifier<Offset>(Offset.zero);
  Timer? _farmerMessageTimer;
  String? _temporaryFarmerMessage;

  double get _totalMultiplier =>
      upgrades.getTotalMultiplier() *
      (_torchesOwned ? 1.15 : 1.0) *
      (_chimesOwned ? 1.10 : 1.0) *
      (_fountainOwned ? 1.12 : 1.0);

  bool get _isPracticeMode => widget.focusDurationMinutes == 1;

  @override
  void initState() {
    super.initState();

    final totalSeconds =
        widget.focusDurationMinutes.clamp(1, 24 * 60).toInt() * 60;
    _remainingSeconds = (widget.initialRemainingSeconds ?? totalSeconds)
        .clamp(1, totalSeconds)
        .toInt();

    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();

    WidgetsBinding.instance.addObserver(this);
    _initForegroundTask();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_initSession());
    });
  }

  @override
  void dispose() {
    _ambientController.dispose();
    _uiTimer?.cancel();
    _saveTimer?.cancel();
    _breakReminderTimer?.cancel();
    _distractionBreakTimer?.cancel();
    _farmerMessageTimer?.cancel();
    _parallaxOffset.dispose();
    WidgetsBinding.instance.removeObserver(this);
    appMonitor.stopMonitoring();
    super.dispose();
  }

  Future<void> _loadDecorationBoosts() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;

    setState(() {
      _torchesOwned = prefs.getBool('torches_purchased') ?? false;
      _chimesOwned = prefs.getBool('wind_chimes_purchased') ?? false;
      _fountainOwned = prefs.getBool('fountain_purchased') ?? false;
    });
  }

  Future<void> _initSession() async {
    if (_sessionStarting || _isWorking || _isFinished) return;
    _sessionStarting = true;

    try {
      await _loadDecorationBoosts();
      if (!mounted) return;

      // Start the visible timer first. Storage, notification permission, and
      // native foreground-service startup can never freeze the countdown.
      _runningUntil = DateTime.now().add(
        Duration(seconds: _remainingSeconds),
      );
      setState(() {
        _isWorking = true;
        _isPaused = false;
      });
      _startUiTimer();

      try {
        if (widget.initialRemainingSeconds != null) {
          await sessionService.resumeSession(
            remainingSeconds: _remainingSeconds,
          );
        } else {
          await sessionService.startSession(
            durationMinutes: widget.focusDurationMinutes,
            initialRemainingSeconds: _remainingSeconds,
          );
        }
      } catch (error) {
        debugPrint('Session persistence failed: $error');
        if (mounted) {
          setState(() {
            _backgroundWarning =
                'Timer is running, but session recovery is unavailable.';
          });
        }
      }

      if (!_isWorking || _isFinished) return;

      appMonitor.startMonitoring(_onBlockedAppDetected);
      _startPeriodicSave();
      _startBreakReminderTimer();
      unawaited(SoundService().playFocusMusic());
      unawaited(_startBackgroundService());
    } catch (error, stackTrace) {
      debugPrint('Could not initialize focus timer: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;
      setState(() {
        _backgroundWarning = 'Could not fully initialize: $error';
      });
    } finally {
      _sessionStarting = false;
    }
  }

  int _remainingFromClock() {
    if (_isPaused || _runningUntil == null) {
      return _remainingSeconds.clamp(0, 24 * 60 * 60).toInt();
    }

    final millisecondsLeft =
        _runningUntil!.difference(DateTime.now()).inMilliseconds;
    if (millisecondsLeft <= 0) return 0;
    return (millisecondsLeft / 1000).ceil();
  }

  void _syncUiFromClock() {
    if (!mounted || !_isWorking || _isFinished || _isPaused) return;

    final next = _remainingFromClock();
    if (next != _remainingSeconds) {
      setState(() => _remainingSeconds = next);
    }

    if (next <= 0) {
      unawaited(_finishSession());
    }
  }

  void _startUiTimer() {
    _uiTimer?.cancel();
    _syncUiFromClock();

    _uiTimer = Timer.periodic(
      const Duration(milliseconds: 250),
      (_) => _syncUiFromClock(),
    );
  }

  Future<void> _requestNotificationPermission() async {
    final permission =
        await FlutterForegroundTask.checkNotificationPermission();
    if (permission != NotificationPermission.granted) {
      await FlutterForegroundTask.requestNotificationPermission();
    }
  }

  Future<void> _persistForegroundState() async {
    await FlutterForegroundTask.saveData(
      key: _timerRemainingKey,
      value: _remainingSeconds,
    );
    await FlutterForegroundTask.saveData(
      key: _timerPausedKey,
      value: _isPaused,
    );
    await FlutterForegroundTask.saveData(
      key: _timerCompletedKey,
      value: _remainingSeconds <= 0,
    );

    final runningUntil = _runningUntil;
    if (runningUntil == null) {
      await FlutterForegroundTask.removeData(key: _timerEndEpochKey);
    } else {
      await FlutterForegroundTask.saveData(
        key: _timerEndEpochKey,
        value: runningUntil.millisecondsSinceEpoch,
      );
    }
  }

  Future<void> _clearForegroundState() async {
    await FlutterForegroundTask.removeData(key: _timerRemainingKey);
    await FlutterForegroundTask.removeData(key: _timerEndEpochKey);
    await FlutterForegroundTask.removeData(key: _timerPausedKey);
    await FlutterForegroundTask.removeData(key: _timerCompletedKey);
  }

  Future<void> _startBackgroundService() async {
    try {
      await _requestNotificationPermission();
      await _persistForegroundState();

      // Always stop an old handler first. This prevents a stale timer isolate
      // from a previous/practice session from controlling the notification.
      if (await FlutterForegroundTask.isRunningService) {
        await FlutterForegroundTask.stopService();
      }

      await FlutterForegroundTask.startService(
        serviceId: 256,
        notificationTitle: 'Berry Focused — Keep it up! 🌱',
        notificationText: _formatTime(_remainingSeconds),
        callback: startCallback,
      );

      if (!mounted || _isFinished) return;
      setState(() {
        _backgroundServiceReady = true;
        _backgroundWarning = null;
      });
    } catch (error) {
      debugPrint('Background timer service failed: $error');
      if (!mounted || _isFinished) return;

      setState(() {
        _backgroundServiceReady = false;
        _backgroundWarning =
            'On-screen timer is running. Background notification is unavailable.';
      });
    }
  }

  Future<void> _stopBackgroundService() async {
    try {
      if (await FlutterForegroundTask.isRunningService) {
        await FlutterForegroundTask.stopService();
      }
    } catch (error) {
      debugPrint('Could not stop background timer: $error');
    }

    try {
      await _clearForegroundState();
    } catch (error) {
      debugPrint('Could not clear background timer data: $error');
    }
  }

  void _startPeriodicSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (!_isWorking || _isFinished) return;

      if (!_isPaused) _syncUiFromClock();
      unawaited(sessionService.updateRemainingTime(_remainingSeconds));
      unawaited(_persistForegroundState());
    });
  }

  void _pauseTimer() {
    if (_isPaused || !_isWorking || _isFinished) return;

    _syncUiFromClock();
    _runningUntil = null;
    setState(() => _isPaused = true);

    unawaited(
      sessionService.pauseSession(
        remainingSeconds: _remainingSeconds,
      ),
    );
    unawaited(_persistForegroundState());
  }

  void _resumeTimer() {
    if (!_isPaused || !_isWorking || _isFinished) return;
    if (_remainingSeconds <= 0) {
      unawaited(_finishSession());
      return;
    }

    _runningUntil = DateTime.now().add(
      Duration(seconds: _remainingSeconds),
    );
    setState(() => _isPaused = false);

    unawaited(
      sessionService.resumeSession(
        remainingSeconds: _remainingSeconds,
      ),
    );
    unawaited(_persistForegroundState());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      SoundService().onAppBackground();
      if (_isWorking && !_isFinished) {
        if (!_isPaused) _syncUiFromClock();
        unawaited(sessionService.updateRemainingTime(_remainingSeconds));
        unawaited(_persistForegroundState());
      }
      return;
    }

    if (state == AppLifecycleState.resumed) {
      SoundService().onAppForeground();

      if (_distractionBreakEndsAt != null &&
          !DateTime.now().isBefore(_distractionBreakEndsAt!)) {
        _finishDistractionBreak(showSnack: true);
      } else if (!_isPaused) {
        _syncUiFromClock();
      }
      return;
    }

    if (state == AppLifecycleState.detached &&
        _isWorking &&
        !_isFinished) {
      SoundService().stopMusic();
      if (!_isPaused) _syncUiFromClock();
      unawaited(sessionService.updateRemainingTime(_remainingSeconds));
      unawaited(_persistForegroundState());
    }
  }

  void _startBreakReminderTimer() {
    _breakReminderTimer?.cancel();
    if (!SettingsService().breakReminders) return;

    _breakReminderTimer = Timer.periodic(
      const Duration(minutes: 25),
      (_) {
        if (!mounted || !_isWorking || _isPaused || _isFinished) return;
        unawaited(FeedbackService().vibrateOnSuccess());
        _showBreakReminderOverlay();
      },
    );
  }

  void _showBreakReminderOverlay() {
    if (!mounted || !_isWorking || _isFinished) return;

    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Row(
          children: [
            Text('☕', style: TextStyle(fontSize: 28)),
            SizedBox(width: 12),
            Text(
              'Break reminder',
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
          ],
        ),
        content: const Text(
          'You have focused for 25 minutes. Stretch, drink water, or keep going.',
          style: TextStyle(color: Colors.white70, fontSize: 15),
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Keep going',
              style: TextStyle(
                color: Color(0xFF66E07A),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _cancelRuntimeTimers() {
    _uiTimer?.cancel();
    _saveTimer?.cancel();
    _breakReminderTimer?.cancel();
    _distractionBreakTimer?.cancel();
    _distractionBreakEndsAt = null;
    appMonitor.stopMonitoring();
  }

  void _resumeFromBlock(String packageName) {
    _distractionBreakTimer?.cancel();
    _distractionBreakEndsAt = null;
    appMonitor.onBlockDismissed(packageName);
    _resumeTimer();

    if (_isWorking && mounted && !_isFinished) {
      appMonitor.startMonitoring(_onBlockedAppDetected);
    }
  }

  void _finishDistractionBreak({bool showSnack = false}) {
    _distractionBreakTimer?.cancel();
    _distractionBreakEndsAt = null;

    if (!mounted || !_isWorking || _isFinished) return;

    _resumeTimer();
    appMonitor.startMonitoring(_onBlockedAppDetected);

    if (showSnack) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Break ended — focus timer resumed.'),
          backgroundColor: Color(0xFF4CAF50),
        ),
      );
    }
  }

  void _startFiveMinuteBreak(String packageName) {
    appMonitor.onBlockDismissed(packageName);

    // Stay paused during the break.
    _pauseTimer();
    appMonitor.stopMonitoring();

    _distractionBreakTimer?.cancel();
    _distractionBreakEndsAt = DateTime.now().add(const Duration(minutes: 5));

    _distractionBreakTimer = Timer(const Duration(minutes: 5), () {
      _finishDistractionBreak(showSnack: true);
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('5-minute break started. Your focus timer is paused.'),
        backgroundColor: Color(0xFF00BCD4),
        duration: Duration(seconds: 4),
      ),
    );
  }

  Future<void> _emergencyUnlockFromBlock(String packageName) async {
    if (_isFinished) return;

    if (!_isPaused) _syncUiFromClock();
    final elapsedSeconds =
        (widget.focusDurationMinutes * 60 - _remainingSeconds)
            .clamp(0, widget.focusDurationMinutes * 60)
            .toInt();
    final elapsedMinutes = elapsedSeconds ~/ 60;

    setState(() {
      _isFinished = true;
      _isWorking = false;
      _isPaused = false;
      _runningUntil = null;
    });

    _cancelRuntimeTimers();
    appMonitor.onBlockDismissed(packageName);

    await _stopBackgroundService();
    try {
      await sessionService.cancelSession();
    } catch (error) {
      debugPrint('Could not cancel emergency session: $error');
    }

    try {
      await FocusStatsService().recordSession(
        plannedMinutes: widget.focusDurationMinutes,
        focusedMinutes: elapsedMinutes,
        mode: _focusModeName,
        peasEarned: 0,
        completed: false,
      );
    } catch (error) {
      debugPrint('Could not record emergency stats: $error');
    }

    unawaited(SoundService().switchToBackgroundMusic());
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Focus session ended for emergency access.'),
        backgroundColor: Colors.red,
      ),
    );
    Navigator.pop(context);
  }

  void _onBlockedAppDetected(String appName, String packageName) async {
    debugPrint('🚫 Blocked app opened: $appName');

    _pauseTimer();
    await FeedbackService().vibrateOnBlock();

    // Current AppMonitorService keeps only the legacy total counter.
    await appMonitor.incrementBlockCount();
    // Keep the newer per-app statistics as well.
    await FocusStatsService().recordBlockedAttempt(
      appName: appName,
      packageName: packageName,
    );

    appMonitor.stopMonitoring();
    if (!mounted) return;

    // The current BlockingScreen uses an onReturn callback instead of
    // returning the newer BlockDecision enum. Once the route closes, resume
    // the paused focus session and restart app monitoring.
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => BlockingScreen(
          appName: appName,
          onReturn: () {},
        ),
      ),
    );

    if (!mounted || !_isWorking || _isFinished) return;
    _resumeFromBlock(packageName);
  }



  int _calculatePeasSoFar() {
    int elapsedMinutes = widget.focusDurationMinutes - (_remainingSeconds ~/ 60);
    return CurrencyService.calculatePeasFromFocus(
      elapsedMinutes,
      upgradeMultiplier:  upgrades.getTotalMultiplier(),
      torchMultiplier:    _torchesOwned  ? 1.15 : 1.0,
      chimesMultiplier:   _chimesOwned   ? 1.10 : 1.0,
      fountainMultiplier: _fountainOwned ? 1.12 : 1.0,
    );
  }

  Future<void> _finishSession() async {
    if (_isFinished || !_isWorking) return;

    setState(() {
      _isFinished = true;
      _isWorking = false;
      _isPaused = false;
      _remainingSeconds = 0;
      _runningUntil = null;
    });

    _cancelRuntimeTimers();

    try {
      await sessionService.completeSession();
    } catch (error) {
      debugPrint('Could not mark session complete: $error');
    }
    await _stopBackgroundService();

    try {
      await StreakService().recordFocusSession();
    } catch (error) {
      debugPrint('Could not update streak: $error');
    }

    try {
      await NotificationService().cancelStreakReminder();
      if (SettingsService().streakReminders) {
        await NotificationService().scheduleStreakReminder();
      }
    } catch (error) {
      debugPrint('Could not update streak reminder: $error');
    }

    final peasEarned = CurrencyService.calculatePeasFromFocus(
      widget.focusDurationMinutes,
      upgradeMultiplier: upgrades.getTotalMultiplier(),
      torchMultiplier: _torchesOwned ? 1.15 : 1.0,
      chimesMultiplier: _chimesOwned ? 1.10 : 1.0,
      fountainMultiplier: _fountainOwned ? 1.12 : 1.0,
    );

    try {
      await currency.addPeas(peasEarned);
    } catch (error) {
      debugPrint('Could not add crop reward: $error');
    }
    try {
      await AchievementService().onFocusSessionCompleted(
        widget.focusDurationMinutes,
      );
      await AchievementService().onSessionsInDay();
      await AchievementService().onPeasEarned(peasEarned);
    } catch (error) {
      debugPrint('Could not update achievements: $error');
    }

    final earnings = widget.focusDurationMinutes * 5;
    widget.character.earnMoney(earnings);
    widget.character.addFocusMinutes(widget.focusDurationMinutes);

    try {
      await StorageService().saveCharacter(widget.character);
      await FocusStatsService().recordSession(
        plannedMinutes: widget.focusDurationMinutes,
        focusedMinutes: widget.focusDurationMinutes,
        mode: _focusModeName,
        peasEarned: peasEarned,
        completed: true,
      );
    } catch (error) {
      debugPrint('Could not save completion data: $error');
    }

    // The session is removed only after reward/stat writes have been attempted.
    try {
      await sessionService.acknowledgeCompletion();
    } catch (error) {
      debugPrint('Could not clear completed session: $error');
    }

    try {
      await SoundService().playSessionComplete();
      SoundService().playBackgroundMusic();
    } catch (error) {
      debugPrint('Could not play completion sound: $error');
    }

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2d2d2d),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Focus Complete! 🎉',
            style: TextStyle(color: Colors.white), textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('You earned:',
                style: TextStyle(fontSize: 16, color: Colors.white70)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF4CAF50), width: 2),
              ),
              child: Column(
                children: [
                  Text('$peasEarned ${CurrencyService().cropEmoji}',
                      style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF4CAF50))),
                  const SizedBox(height: 8),
                  Text(CurrencyService().cropName,
                      style: const TextStyle(fontSize: 16, color: Colors.white70)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text('${widget.focusDurationMinutes} min focused!',
                style: const TextStyle(
                    fontSize: 14, color: Colors.white60, fontStyle: FontStyle.italic)),
            if (_torchesOwned || _chimesOwned || _fountainOwned) ...[
              const SizedBox(height: 8),
              if (_torchesOwned)
                const Text('🔥 Torch Boost: +15%',
                    style: TextStyle(color: Colors.orangeAccent, fontSize: 13)),
              if (_chimesOwned)
                const Text('🎐 Wind Chimes Boost: +10%',
                    style: TextStyle(color: Colors.tealAccent, fontSize: 13)),
              if (_fountainOwned)
                const Text('⛲ Fountain Boost: +12%',
                    style: TextStyle(color: Colors.blueAccent, fontSize: 13)),
            ],
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text('Also earned: \$$earnings',
                      style: const TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text('+${widget.focusDurationMinutes} focus minutes',
                      style: const TextStyle(color: Colors.white70, fontSize: 14)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Awesome!',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(int totalSeconds) {
    int hours   = totalSeconds ~/ 3600;
    int minutes = (totalSeconds % 3600) ~/ 60;
    int seconds = totalSeconds % 60;
    if (hours > 0) {
      return '${hours}h ${minutes.toString().padLeft(2, '0')}m ${seconds.toString().padLeft(2, '0')}s';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds.toString().padLeft(2, '0')}s';
    }
    return '${seconds}s';
  }


  double get _sessionProgress {
    final totalSeconds = widget.focusDurationMinutes * 60;
    if (totalSeconds <= 0) return 0.0;

    return (1.0 - (_remainingSeconds / totalSeconds))
        .clamp(0.0, 1.0)
        .toDouble();
  }

  String get _focusModeName {
    switch (widget.focusDurationMinutes) {
      case 1:
        return 'Practice';
      case 15:
        return 'Homework Panic';
      case 25:
        return 'Study';
      case 30:
        return 'No Phone';
      case 50:
        return 'Deep Work';
      default:
        return 'Custom Focus';
    }
  }

  String get _focusModeEmoji {
    switch (widget.focusDurationMinutes) {
      case 1:
        return '🧪';
      case 15:
        return '⚡';
      case 25:
        return '📚';
      case 30:
        return '📵';
      case 50:
        return '🧠';
      default:
        return '🌱';
    }
  }

  String get _progressStageLabel {
    final progress = _sessionProgress;

    if (progress < 0.12) return 'Preparing the soil';
    if (progress < 0.30) return 'Planting seeds';
    if (progress < 0.52) return 'Watering the garden';
    if (progress < 0.75) return 'Crops are growing';
    if (progress < 0.92) return 'Almost ready to harvest';
    return 'Harvest is ready!';
  }

  String get _farmerMessage {
    if (_temporaryFarmerMessage != null) {
      return _temporaryFarmerMessage!;
    }

    if (_isPaused) {
      return _distractionBreakEndsAt != null
          ? 'Enjoy your short break. I’ll wait here!'
          : 'Timer paused. Ready when you are.';
    }

    final progress = _sessionProgress;

    if (progress < 0.12) return 'Let’s grow something today!';
    if (progress < 0.30) return 'The seeds are going in!';
    if (progress < 0.52) return 'Nice work—keep watering!';
    if (progress < 0.75) return 'Look! The crops are growing.';
    if (progress < 0.92) return 'Almost there—stay with it!';
    return 'The harvest is ready! 🎉';
  }

  int get _expectedPeas {
    return CurrencyService.calculatePeasFromFocus(
      widget.focusDurationMinutes,
      upgradeMultiplier: upgrades.getTotalMultiplier(),
      torchMultiplier: _torchesOwned ? 1.15 : 1.0,
      chimesMultiplier: _chimesOwned ? 1.10 : 1.0,
      fountainMultiplier: _fountainOwned ? 1.12 : 1.0,
    );
  }

  void _handleFarmerTap() {
    final messages = <String>[
      'You’ve got this!',
      'One minute at a time.',
      'Your garden is counting on you!',
      'Stay focused—future you will be glad.',
    ];

    setState(() {
      _characterTapCount++;
      _temporaryFarmerMessage =
          messages[_characterTapCount % messages.length];

      if (_characterTapCount >= 50) {
        _easterEggActive = true;
      }
    });

    _farmerMessageTimer?.cancel();
    _farmerMessageTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() => _temporaryFarmerMessage = null);
    });

    if (_characterTapCount == 50) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🥚 Easter egg found!'),
          backgroundColor: Colors.purple,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void _updateParallax(Offset localPosition, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final normalizedX =
        ((localPosition.dx / size.width) - 0.5)
            .clamp(-0.5, 0.5)
            .toDouble();
    final normalizedY =
        ((localPosition.dy / size.height) - 0.5)
            .clamp(-0.5, 0.5)
            .toDouble();

    _parallaxOffset.value = Offset(
      normalizedX * 18,
      normalizedY * 10,
    );
  }

  void _resetParallax() {
    _parallaxOffset.value = Offset.zero;
  }

  Widget _buildMetricChip({
    required String icon,
    required String value,
    required String label,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withOpacity(0.10)),
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 7),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimerProtectionBadge() {
    final Color color;
    final IconData icon;
    final String label;

    if (_backgroundServiceReady) {
      color = const Color(0xFF66E07A);
      icon = Icons.shield_rounded;
      label = 'Background protected';
    } else if (_backgroundWarning != null) {
      color = Colors.orangeAccent;
      icon = Icons.phone_android_rounded;
      label = 'On-screen timer';
    } else {
      color = Colors.white54;
      icon = Icons.sync_rounded;
      label = 'Starting protection';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFocusHud() {
    final progress = _sessionProgress;
    final streak = StreakService().displayStreak;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E).withOpacity(0.88),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.14)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.24),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              SizedBox(
                width: 88,
                height: 88,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 82,
                      height: 82,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 7,
                        backgroundColor: Colors.white.withOpacity(0.10),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _isPaused
                              ? Colors.orangeAccent
                              : const Color(0xFF66E07A),
                        ),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${(progress * 100).round()}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          'grown',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          _focusModeEmoji,
                          style: const TextStyle(fontSize: 20),
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            _focusModeName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (_isPaused)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.22),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'PAUSED',
                              style: TextStyle(
                                color: Colors.orangeAccent,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _formatTime(_remainingSeconds),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'monospace',
                          letterSpacing: -1,
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _progressStageLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF9BE7A7),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildTimerProtectionBadge(),
              if (_isPracticeMode) ...[
                const SizedBox(width: 7),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF64B5F6).withOpacity(0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    '1-minute test',
                    style: TextStyle(
                      color: Color(0xFF90CAF9),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (_backgroundWarning != null) ...[
            const SizedBox(height: 7),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _backgroundWarning!,
                style: const TextStyle(
                  color: Colors.orangeAccent,
                  fontSize: 10,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white.withOpacity(0.08),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF66E07A),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildMetricChip(
                icon: CurrencyService().cropEmoji,
                value: NumberFormatter.format(_expectedPeas),
                label: 'expected reward',
              ),
              const SizedBox(width: 8),
              _buildMetricChip(
                icon: StreakService().streakEmoji,
                value: '$streak day${streak == 1 ? '' : 's'}',
                label: 'focus streak',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFarmerSpeechBubble() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: Container(
        key: ValueKey<String>(_farmerMessage),
        constraints: const BoxConstraints(maxWidth: 210),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8E8).withOpacity(0.96),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFD9C79A)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.18),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Text(
          _farmerMessage,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF4A3B23),
            fontSize: 12,
            height: 1.25,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomControl() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF16213E).withOpacity(0.86),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.22),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Stay with the task',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _isPaused
                      ? 'Your session is safely paused.'
                      : '${_formatTime((widget.focusDurationMinutes * 60 - _remainingSeconds).clamp(0, widget.focusDurationMinutes * 60).toInt())} invested',
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          OutlinedButton.icon(
            onPressed: _showStopDialog,
            icon: const Icon(Icons.stop_circle_outlined, size: 18),
            label: const Text('Stop'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.redAccent,
              side: BorderSide(color: Colors.redAccent.withOpacity(0.75)),
              padding: const EdgeInsets.symmetric(
                horizontal: 15,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WithForegroundTask(
      child: PopScope(
        canPop: !_isWorking || _isFinished,
        onPopInvoked: (didPop) {
          if (!didPop && _isWorking && !_isFinished) {
            _showStopDialog();
          }
        },
        child: Scaffold(
        backgroundColor: const Color(0xFF87CEEB),
        body: LayoutBuilder(
          builder: (context, constraints) {
            final size = Size(
              constraints.maxWidth,
              constraints.maxHeight,
            );

            return Listener(
              behavior: HitTestBehavior.translucent,
              onPointerMove: (event) =>
                  _updateParallax(event.localPosition, size),
              onPointerUp: (_) => _resetParallax(),
              onPointerCancel: (_) => _resetParallax(),
              child: Stack(
                children: [
                  // Static environment. It updates only when session progress changes,
                  // instead of repainting continuously.
                  ValueListenableBuilder<Offset>(
                    valueListenable: _parallaxOffset,
                    child: RepaintBoundary(
                      child: CustomPaint(
                        size: Size.infinite,
                        painter: GardenPainter(
                          characterAnimation: 0.0,
                          isWorking: _isWorking,
                          totalSeconds: widget.focusDurationMinutes * 60,
                          remainingSeconds: _remainingSeconds,
                        ),
                      ),
                    ),
                    builder: (context, offset, child) {
                      return Transform.translate(
                        offset: Offset(offset.dx * 0.22, offset.dy * 0.16),
                        child: child,
                      );
                    },
                  ),

                  // Lightweight animated effects only: drifting clouds, leaves,
                  // fireflies and late-session sparkles.
                  ValueListenableBuilder<Offset>(
                    valueListenable: _parallaxOffset,
                    child: IgnorePointer(
                      child: RepaintBoundary(
                        child: CustomPaint(
                          size: Size.infinite,
                          painter: GardenAmbientPainter(
                            animation: _ambientController,
                            progress: _sessionProgress,
                            isPaused: _isPaused,
                          ),
                        ),
                      ),
                    ),
                    builder: (context, offset, child) {
                      return Transform.translate(
                        offset: Offset(offset.dx * 0.45, offset.dy * 0.30),
                        child: child,
                      );
                    },
                  ),

                  // Soft edge shading adds depth and makes the HUD readable.
                  IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.10),
                            Colors.transparent,
                            Colors.transparent,
                            Colors.black.withOpacity(0.22),
                          ],
                          stops: const [0.0, 0.25, 0.68, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // Farmer remains a static PNG. No farmer animation is added.
                  AnimatedOpacity(
                    opacity: _easterEggActive ? 0.0 : 1.0,
                    duration: const Duration(milliseconds: 500),
                    child: LayoutBuilder(
                      builder: (context, farmerConstraints) {
                        final w = farmerConstraints.maxWidth;
                        final h = farmerConstraints.maxHeight;
                        final charX = w * 0.55;
                        final charY = h * 0.68;

                        return Stack(
                          children: [
                            Positioned(
                              left: charX - 105,
                              top: charY - 152,
                              width: 210,
                              child: _buildFarmerSpeechBubble(),
                            ),
                            Positioned(
                              left: charX - 70,
                              top: charY - 90,
                              width: 140,
                              height: 170,
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onTap: _handleFarmerTap,
                                child: Image.asset(
                                  'assets/images/farmer.png',
                                  fit: BoxFit.contain,
                                  filterQuality: FilterQuality.medium,
                                ),
                              ),
                            ),
                            if (_characterTapCount >= 25 &&
                                !_easterEggActive)
                              Positioned(
                                left: charX - 50,
                                top: charY + 90,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.purple.withOpacity(0.82),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${50 - _characterTapCount} more...',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),

                  Positioned(
                    top: MediaQuery.of(context).padding.top + 10,
                    left: 0,
                    right: 0,
                    child: _buildFocusHud(),
                  ),

                  Positioned(
                    bottom: MediaQuery.of(context).padding.bottom + 14,
                    left: 0,
                    right: 0,
                    child: _buildBottomControl(),
                  ),

                  if (_sessionStarting && !_isWorking)
                    const Positioned(
                      left: 0,
                      right: 0,
                      top: 0,
                      child: LinearProgressIndicator(
                        minHeight: 3,
                        color: Color(0xFF66E07A),
                        backgroundColor: Colors.transparent,
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
      ),
    );
  }

  Future<void> _endSessionEarly({
    required int elapsedMinutes,
    required int peasKept,
  }) async {
    if (_isFinished) return;

    setState(() {
      _isFinished = true;
      _isWorking = false;
      _isPaused = false;
      _runningUntil = null;
    });
    _cancelRuntimeTimers();

    await _stopBackgroundService();
    try {
      await sessionService.cancelSession();
    } catch (error) {
      debugPrint('Could not cancel focus session: $error');
    }

    if (peasKept > 0) {
      try {
        await currency.addPeas(peasKept);
      } catch (error) {
        debugPrint('Could not add partial reward: $error');
      }
    }

    if (elapsedMinutes > 0) {
      widget.character.addFocusMinutes(elapsedMinutes);
      try {
        await StorageService().saveCharacter(widget.character);
      } catch (error) {
        debugPrint('Could not save partial focus time: $error');
      }
    }

    try {
      await FocusStatsService().recordSession(
        plannedMinutes: widget.focusDurationMinutes,
        focusedMinutes: elapsedMinutes,
        mode: _focusModeName,
        peasEarned: peasKept,
        completed: false,
      );
    } catch (error) {
      debugPrint('Could not save stopped-session stats: $error');
    }

    unawaited(SoundService().switchToBackgroundMusic());
    if (!mounted) return;

    Navigator.pop(context); // close confirmation dialog
    Navigator.pop(context); // close focus screen
  }

  void _showStopDialog() {
    if (!_isPaused) _syncUiFromClock();
    int elapsedSeconds = (widget.focusDurationMinutes * 60) - _remainingSeconds;
    int elapsedMinutes = elapsedSeconds ~/ 60;

    if (elapsedMinutes < 5) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: const Color(0xFF16213e),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('⏱️', style: TextStyle(fontSize: 48)),
              SizedBox(height: 12),
              Text("Don't stop before 5 minutes!",
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center),
              SizedBox(height: 8),
              Text("You won't earn any peas.",
                  style: TextStyle(color: Colors.white54, fontSize: 14),
                  textAlign: TextAlign.center),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Keep Focusing',
                  style: TextStyle(color: Color(0xFF4CAF50), fontWeight: FontWeight.bold)),
            ),
            TextButton(
              onPressed: () => _endSessionEarly(
                elapsedMinutes: elapsedMinutes,
                peasKept: 0,
              ),
              child: const Text('Stop Anyway', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
      return;
    }

    int peasSoFar = _calculatePeasSoFar();
    int peasLost  = (peasSoFar * 0.20).floor();
    int peasKept  = peasSoFar - peasLost;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF16213e),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Text('⚠️', style: TextStyle(fontSize: 28)),
            SizedBox(width: 12),
            Expanded(child: Text('Stop Focus Session?',
                style: TextStyle(color: Colors.white, fontSize: 18))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Earned so far:', style: TextStyle(color: Colors.white70)),
                  Text('$peasSoFar 🌱',
                      style: const TextStyle(color: Color(0xFF4CAF50), fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text('$elapsedMinutes of ${widget.focusDurationMinutes} minutes completed',
                style: const TextStyle(color: Colors.white60, fontSize: 12)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('If you stop now:',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(children: [
                    const Text('❌', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Expanded(child: Text('Lose $peasLost peas (20% penalty)',
                        style: TextStyle(color: Colors.red[300]))),
                  ]),
                  const SizedBox(height: 4),
                  Row(children: [
                    const Text('✅', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 8),
                    Expanded(child: Text('Keep $peasKept peas',
                        style: const TextStyle(color: Color(0xFF4CAF50)))),
                  ]),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep Focusing',
                style: TextStyle(color: Color(0xFF00d4ff), fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () => _endSessionEarly(
              elapsedMinutes: elapsedMinutes,
              peasKept: peasKept,
            ),
            child: const Text('Stop', style: TextStyle(color: Colors.red, fontSize: 16)),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════
// GARDEN PAINTER
// ══════════════════════════════════════════════════════════════════════
class GardenPainter extends CustomPainter {
  final double characterAnimation;
  final bool isWorking;
  final int totalSeconds;
  final int remainingSeconds;

  GardenPainter({
    required this.characterAnimation,
    required this.isWorking,
    required this.totalSeconds,
    required this.remainingSeconds,
  });

  double get progress =>
      totalSeconds > 0 ? 1.0 - (remainingSeconds / totalSeconds) : 0.0;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    _drawSun(canvas, w, h);
    _drawGround(canvas, w, h);
    _drawCaveEntrance(canvas, w, h);
    _drawTrees(canvas, w, h);
    _drawRocks(canvas, w, h);
    _drawGarden(canvas, w, h);
    // Farmer image is drawn as a widget overlay, so don't repaint a second character here.
    _drawFlowers(canvas, w, h);
  }

  void _drawSun(Canvas canvas, double w, double h) {
    canvas.drawCircle(Offset(w * 0.85, h * 0.12), 38,
        Paint()..color = const Color(0xFFFDB813));
    canvas.drawCircle(
      Offset(w * 0.85, h * 0.12), 45,
      Paint()
        ..color = const Color(0xFFFFD700).withOpacity(0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
    );
    for (int i = 0; i < 12; i++) {
      double angle = (i * 30 + characterAnimation * 20) * (3.14159 / 180);
      canvas.drawLine(
        Offset(w * 0.85 + cos(angle) * 48, h * 0.12 + sin(angle) * 48),
        Offset(w * 0.85 + cos(angle) * 65, h * 0.12 + sin(angle) * 65),
        Paint()
          ..color = const Color(0xFFFFD700)
          ..strokeWidth = 5
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  void _drawClouds(Canvas canvas, double w, double h) {
    final p = Paint()..color = Colors.white.withOpacity(0.8);
    canvas.drawCircle(Offset(w * 0.18, h * 0.14), 38, p);
    canvas.drawCircle(Offset(w * 0.21, h * 0.13), 48, p);
    canvas.drawCircle(Offset(w * 0.24, h * 0.14), 42, p);
    canvas.drawCircle(Offset(w * 0.26, h * 0.15), 35, p);
    canvas.drawCircle(Offset(w * 0.63, h * 0.18), 32, p);
    canvas.drawCircle(Offset(w * 0.66, h * 0.17), 42, p);
    canvas.drawCircle(Offset(w * 0.69, h * 0.18), 38, p);
    canvas.drawCircle(Offset(w * 0.71, h * 0.19), 30, p);
  }

  void _drawGround(Canvas canvas, double w, double h) {
    final rect = Rect.fromLTWH(0, h * 0.6, w, h * 0.4);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF81C784), Color(0xFF66BB6A), Color(0xFF4CAF50)],
        ).createShader(rect),
    );
    final blade = Paint()
      ..color = const Color(0xFF66BB6A)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 80; i++) {
      double x  = i * w / 80;
      double y  = h * 0.6 + (i % 4) * 6;
      double ht = 10 + (i % 3) * 4;
      canvas.drawLine(Offset(x, y), Offset(x + 1, y + ht), blade);
    }
  }

  void _drawCaveEntrance(Canvas canvas, double w, double h) {
    final path = Path()
      ..moveTo(w * 0.06, h * 0.54)
      ..quadraticBezierTo(w * 0.12, h * 0.30, w * 0.24, h * 0.54)
      ..lineTo(w * 0.24, h * 0.6)
      ..lineTo(w * 0.06, h * 0.6)
      ..close();
    canvas.drawPath(path, Paint()..color = const Color(0xFF0D0C0A));
    canvas.drawPath(path,
        Paint()..color = const Color(0xFF4A4440)..style = PaintingStyle.stroke..strokeWidth = 6);
    canvas.drawPath(path,
        Paint()..color = const Color(0xFF2A2420)..style = PaintingStyle.stroke..strokeWidth = 3);
  }

  void _drawTrees(Canvas canvas, double w, double h) {
    _drawTree(canvas, w * 0.10, h * 0.6, 75);
    _drawTree(canvas, w * 0.90, h * 0.6, 68);
  }

  void _drawTree(Canvas canvas, double x, double y, double s) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(x - s * 0.12, y - s * 0.5, s * 0.24, s * 0.5),
          const Radius.circular(3)),
      Paint()..color = const Color(0xFF6D4C41),
    );
    for (int i = 0; i < 4; i++) {
      canvas.drawLine(
        Offset(x - s * 0.08, y - s * 0.4 + i * s * 0.1),
        Offset(x + s * 0.08, y - s * 0.38 + i * s * 0.1),
        Paint()..color = const Color(0xFF5D4037)..strokeWidth = 2,
      );
    }
    canvas.drawCircle(Offset(x, y - s * 0.7), s * 0.48,
        Paint()..color = const Color(0xFF1B5E20));
    canvas.drawCircle(Offset(x - s * 0.28, y - s * 0.45), s * 0.38,
        Paint()..color = const Color(0xFF2E7D32));
    canvas.drawCircle(Offset(x + s * 0.28, y - s * 0.45), s * 0.38,
        Paint()..color = const Color(0xFF388E3C));
    canvas.drawCircle(Offset(x - s * 0.15, y - s * 0.55), s * 0.32,
        Paint()..color = const Color(0xFF43A047));
    canvas.drawCircle(Offset(x + s * 0.15, y - s * 0.55), s * 0.32,
        Paint()..color = const Color(0xFF4CAF50));
  }

  void _drawRocks(Canvas canvas, double w, double h) {
    _drawRock(canvas, w * 0.25, h * 0.72, 28);
    _drawRock(canvas, w * 0.77, h * 0.75, 22);
    _drawRock(canvas, w * 0.30, h * 0.78, 18);
  }

  void _drawRock(Canvas canvas, double x, double y, double s) {
    final path = Path()
      ..moveTo(x - s * 0.4, y)
      ..lineTo(x, y - s * 0.7)
      ..lineTo(x + s * 0.6, y - s * 0.2)
      ..lineTo(x + s * 0.4, y)
      ..close();
    canvas.drawPath(path, Paint()..color = const Color(0xFF424242));
    canvas.drawPath(
      Path()
        ..moveTo(x - s * 0.2, y - s * 0.1)
        ..lineTo(x + s * 0.1, y - s * 0.5)
        ..lineTo(x + s * 0.3, y - s * 0.15),
      Paint()
        ..color = const Color(0xFF616161)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawPath(path,
        Paint()..color = const Color(0xFF212121)..style = PaintingStyle.stroke..strokeWidth = 3);
  }

  void _drawGarden(Canvas canvas, double w, double h) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(w * 0.55, h * 0.72), width: w * 0.45, height: h * 0.18),
      const Radius.circular(8),
    );
    canvas.drawRRect(
        rect,
        Paint()..color = progress < 0.17
            ? const Color(0xFF8D6E63)
            : const Color(0xFF6D4C41));
    canvas.drawRRect(rect,
        Paint()..color = const Color(0xFF5D4037)..style = PaintingStyle.stroke..strokeWidth = 3);
    if (progress > 0.17) {
      final row = Paint()..color = const Color(0xFF5D4037)..strokeWidth = 2;
      for (int i = 0; i < 3; i++) {
        canvas.drawLine(Offset(w * 0.325, h * 0.66 + i * 24),
            Offset(w * 0.775, h * 0.66 + i * 24), row);
      }
    }
    _drawPlants(canvas, w, h);
  }

  void _drawPlants(Canvas canvas, double w, double h) {
    int stage = 0;
    if (progress >= 0.12) stage = 1;
    if (progress >= 0.30) stage = 2;
    if (progress >= 0.52) stage = 3;
    if (progress >= 0.75) stage = 4;
    double sx = w * 0.365, sy = h * 0.66;
    double spx = (w * 0.37) / 4;
    for (int r = 0; r < 3; r++) {
      for (int c = 0; c < 4; c++) {
        _drawPlantStage(canvas, sx + c * spx, sy + r * 24.0, stage);
      }
    }
  }

  void _drawPlantStage(Canvas canvas, double x, double y, int stage) {
    if (stage == 0) return;
    final p  = Paint()..color = const Color(0xFF4CAF50);
    final sp = Paint()
      ..color = const Color(0xFF558B2F)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    if (stage == 1) {
      canvas.drawCircle(Offset(x, y - 2), 3.5, Paint()..color = const Color(0xFF81C784));
      canvas.drawLine(Offset(x, y), Offset(x, y - 4), sp..strokeWidth = 1.5);
    } else if (stage == 2) {
      canvas.drawCircle(Offset(x - 5, y - 4), 4.5, p);
      canvas.drawCircle(Offset(x + 5, y - 4), 4.5, p);
      canvas.drawLine(Offset(x, y), Offset(x, y - 8), sp);
    } else if (stage == 3) {
      canvas.drawCircle(Offset(x - 6, y - 6), 5.5, p);
      canvas.drawCircle(Offset(x + 6, y - 6), 5.5, p);
      canvas.drawCircle(Offset(x - 4, y - 11), 4.5, p);
      canvas.drawCircle(Offset(x + 4, y - 11), 4.5, p);
      canvas.drawLine(Offset(x, y), Offset(x, y - 14), sp);
    } else {
      canvas.drawCircle(Offset(x - 7, y - 8),  6.5, p);
      canvas.drawCircle(Offset(x + 7, y - 8),  6.5, p);
      canvas.drawCircle(Offset(x - 5, y - 14), 5.5, p);
      canvas.drawCircle(Offset(x + 5, y - 14), 5.5, p);
      canvas.drawCircle(Offset(x,     y - 18), 4.5, p);
      canvas.drawLine(Offset(x, y), Offset(x, y - 18), sp..strokeWidth = 3);
      final pp = Paint()..color = const Color(0xFF7CB342);
      canvas.drawCircle(Offset(x - 8, y - 12), 4.5, pp);
      canvas.drawCircle(Offset(x + 8, y - 12), 4.5, pp);
      canvas.drawCircle(Offset(x - 3, y - 16), 4.0, pp);
      canvas.drawCircle(Offset(x + 3, y - 16), 4.0, pp);
      canvas.drawCircle(Offset(x - 9, y - 13), 1.5, Paint()..color = const Color(0xFF9CCC65));
      canvas.drawCircle(Offset(x + 7, y - 13), 1.5, Paint()..color = const Color(0xFF9CCC65));
    }
  }

  void _drawCharacter(Canvas canvas, double w, double h) {
    double cx = w * 0.55, cy = h * 0.68;
    if (progress < 0.17)       _drawHoeingPhase(canvas, cx, cy);
    else if (progress < 0.33)  _drawSeedingPhase(canvas, cx, cy);
    else if (progress < 0.50)  _drawWateringPhase(canvas, cx, cy);
    else if (progress < 0.83)  _drawWaitingPhase(canvas, cx, cy);
    else if (progress < 0.95)  _drawHarvestingPhase(canvas, cx, cy);
    else                       _drawSuccessPhase(canvas, cx, cy);
  }

  void _drawHoeingPhase(Canvas canvas, double x, double y) {
    canvas.drawOval(Rect.fromCenter(center: Offset(x, y + 38), width: 42, height: 11),
        Paint()..color = Colors.black.withOpacity(0.25));
    canvas.drawCircle(Offset(x, y + 2),  22, Paint()..color = const Color(0xFFFFD54F));
    canvas.drawCircle(Offset(x, y - 23), 16, Paint()..color = const Color(0xFFFFE082));
    double hoeY = y + 10 + characterAnimation * 15;
    final arm = Paint()..color = const Color(0xFFFFD54F)..strokeWidth = 8..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(x + 14, y - 8),  Offset(x + 25, hoeY - 10), arm);
    canvas.drawLine(Offset(x - 14, y - 8),  Offset(x + 20, hoeY - 15), arm);
    canvas.drawLine(Offset(x + 22, hoeY - 12), Offset(x + 22, hoeY + 22),
        Paint()..color = const Color(0xFF8D6E63)..strokeWidth = 5);
    canvas.drawRect(Rect.fromCenter(center: Offset(x + 22, hoeY + 28), width: 25, height: 6),
        Paint()..color = const Color(0xFF757575));
    if (characterAnimation > 0.5) {
      for (int i = 0; i < 4; i++) {
        canvas.drawCircle(Offset(x + 30 + i * 6, hoeY + 20 - characterAnimation * 12),
            2.5, Paint()..color = const Color(0xFF8D6E63));
      }
    }
    _drawFace(canvas, x, y - 23, false);
  }

  void _drawSeedingPhase(Canvas canvas, double x, double y) {
    canvas.drawOval(Rect.fromCenter(center: Offset(x, y + 38), width: 42, height: 11),
        Paint()..color = Colors.black.withOpacity(0.25));
    canvas.drawCircle(Offset(x, y),      22, Paint()..color = const Color(0xFFFFD54F));
    canvas.drawCircle(Offset(x, y - 26), 16, Paint()..color = const Color(0xFFFFE082));
    canvas.drawPath(
      Path()..moveTo(x-28,y)..lineTo(x-22,y-8)..lineTo(x-18,y+2)..lineTo(x-24,y+8)..close(),
      Paint()..color = const Color(0xFF8D6E63),
    );
    double throwY = y - 8 - sin(characterAnimation * 3.14159) * 12;
    canvas.drawLine(Offset(x + 14, y - 6), Offset(x + 32, throwY),
        Paint()..color = const Color(0xFFFFD54F)..strokeWidth = 8..strokeCap = StrokeCap.round);
    for (int i = 0; i < 6; i++) {
      double sx = x + 35 + i * 8 + characterAnimation * 15;
      double sy = throwY + 5 + characterAnimation * characterAnimation * 40;
      if (sy < y + 35) {
        canvas.drawCircle(Offset(sx, sy), 2.5, Paint()..color = const Color(0xFF8D6E63));
      }
    }
    _drawFace(canvas, x, y - 26, false);
  }

  void _drawWateringPhase(Canvas canvas, double x, double y) {
    canvas.drawOval(Rect.fromCenter(center: Offset(x, y + 38), width: 42, height: 11),
        Paint()..color = Colors.black.withOpacity(0.25));
    canvas.drawCircle(Offset(x, y),      22, Paint()..color = const Color(0xFFFFD54F));
    canvas.drawCircle(Offset(x, y - 26), 16, Paint()..color = const Color(0xFFFFE082));
    canvas.save();
    canvas.translate(x + 28, y - 2);
    canvas.rotate(-0.3);
    canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-10,-12,20,24), const Radius.circular(4)),
        Paint()..color = const Color(0xFF78909C));
    canvas.drawPath(
      Path()..addOval(Rect.fromCenter(center: const Offset(-12, 0), width: 8, height: 16)),
      Paint()..color = const Color(0xFF546E7A)..style = PaintingStyle.stroke..strokeWidth = 3,
    );
    canvas.drawLine(const Offset(10,-8), const Offset(20,-12),
        Paint()..color = const Color(0xFF78909C)..strokeWidth = 5..strokeCap = StrokeCap.round);
    canvas.restore();
    for (int i = 0; i < 12; i++) {
      double dx = x + 45 + (i % 3) * 4;
      double dy = y - 10 + i * 6 + characterAnimation * 25;
      if (dy < y + 35) {
        canvas.drawOval(Rect.fromCenter(center: Offset(dx, dy), width: 3, height: 6),
            Paint()..color = const Color(0xFF64B5F6).withOpacity(0.8));
      }
    }
    canvas.drawCircle(Offset(x + 46, y + 34), 6,
        Paint()..color = const Color(0xFF64B5F6).withOpacity(0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));
    final arm = Paint()..color = const Color(0xFFFFD54F)..strokeWidth = 8..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(x - 14, y - 4), Offset(x + 18, y - 6), arm);
    canvas.drawLine(Offset(x + 14, y - 4), Offset(x + 24, y - 4), arm);
    _drawFace(canvas, x, y - 26, false);
  }

  void _drawWaitingPhase(Canvas canvas, double x, double y) {
    canvas.drawOval(Rect.fromCenter(center: Offset(x, y + 38), width: 42, height: 11),
        Paint()..color = Colors.black.withOpacity(0.25));
    double bobY = y + sin(characterAnimation * 6.28) * 3;
    canvas.drawCircle(Offset(x, bobY),      22, Paint()..color = const Color(0xFFFFD54F));
    canvas.drawCircle(Offset(x, bobY - 26), 16, Paint()..color = const Color(0xFFFFE082));
    final arm = Paint()..color = const Color(0xFFFFD54F)..strokeWidth = 8..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(x - 16, bobY - 2), Offset(x - 28, bobY + 18), arm);
    canvas.drawLine(Offset(x + 16, bobY - 2), Offset(x + 28, bobY + 18), arm);
    _drawFace(canvas, x, bobY - 26, false);
  }

  void _drawHarvestingPhase(Canvas canvas, double x, double y) {
    canvas.drawOval(Rect.fromCenter(center: Offset(x, y + 38), width: 42, height: 11),
        Paint()..color = Colors.black.withOpacity(0.25));
    canvas.drawCircle(Offset(x, y + 8),  22, Paint()..color = const Color(0xFFFFD54F));
    canvas.drawCircle(Offset(x, y - 16), 16, Paint()..color = const Color(0xFFFFE082));
    double ry = y + 28 + sin(characterAnimation * 6.28) * 4;
    final arm = Paint()..color = const Color(0xFFFFD54F)..strokeWidth = 8..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(x - 16, y + 8), Offset(x - 18, ry), arm);
    canvas.drawLine(Offset(x + 16, y + 8), Offset(x + 18, ry), arm);
    canvas.drawPath(
      Path()..moveTo(x-38,y+32)..lineTo(x-42,y+38)..lineTo(x-28,y+38)..lineTo(x-32,y+32)..close(),
      Paint()..color = const Color(0xFF8D6E63),
    );
    for (int i = 0; i < 3; i++) {
      canvas.drawLine(Offset(x-40, y+33+i*2), Offset(x-30, y+33+i*2),
          Paint()..color = const Color(0xFF6D4C41)..strokeWidth = 1);
    }
    _drawFace(canvas, x, y - 16, false);
  }

  void _drawSuccessPhase(Canvas canvas, double x, double y) {
    canvas.drawOval(Rect.fromCenter(center: Offset(x, y + 38), width: 42, height: 11),
        Paint()..color = Colors.black.withOpacity(0.25));
    canvas.drawCircle(Offset(x, y),      22, Paint()..color = const Color(0xFFFFD54F));
    canvas.drawCircle(Offset(x, y - 26), 16, Paint()..color = const Color(0xFFFFE082));
    final arm = Paint()..color = const Color(0xFFFFD54F)..strokeWidth = 8..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(x - 16, y - 8), Offset(x - 32, y - 32), arm);
    canvas.drawLine(Offset(x + 16, y - 8), Offset(x + 32, y - 32), arm);
    canvas.drawPath(
      Path()..moveTo(x-24,y+22)..lineTo(x-28,y+38)..lineTo(x+28,y+38)..lineTo(x+24,y+22)..close(),
      Paint()..color = const Color(0xFF8D6E63),
    );
    canvas.drawLine(Offset(x - 24, y + 22), Offset(x + 24, y + 22),
        Paint()..color = const Color(0xFF6D4C41)..strokeWidth = 4..strokeCap = StrokeCap.round);
    for (int i = 0; i < 8; i++) {
      canvas.drawCircle(Offset(x - 18 + i * 5, y + 18 + (i % 2) * 3), 5,
          Paint()..color = const Color(0xFF7CB342));
    }
    for (int i = 0; i < 3; i++) {
      double cx = x - 12 + i * 12;
      canvas.drawPath(
        Path()..moveTo(cx, y+26)..lineTo(cx-3, y+34)..lineTo(cx+3, y+34)..close(),
        Paint()..color = const Color(0xFFFF9800),
      );
      final lf = Paint()..color = const Color(0xFF4CAF50)..strokeWidth = 2..strokeCap = StrokeCap.round;
      canvas.drawLine(Offset(cx, y+26), Offset(cx-2, y+22), lf);
      canvas.drawLine(Offset(cx, y+26), Offset(cx+2, y+22), lf);
    }
    _drawSparkle(canvas, x - 38, y - 35, 10);
    _drawSparkle(canvas, x + 38, y - 35, 10);
    _drawSparkle(canvas, x - 28, y - 42, 8);
    _drawSparkle(canvas, x + 28, y - 42, 8);
    _drawSparkle(canvas, x, y - 48, 12);
    _drawFace(canvas, x, y - 26, true);
  }

  void _drawFace(Canvas canvas, double x, double y, bool happy) {
    if (happy) {
      final lp = Paint()..color = Colors.black..strokeWidth = 2..style = PaintingStyle.stroke;
      canvas.drawPath(Path()..moveTo(x-8,y-3)..quadraticBezierTo(x-6,y-1,x-4,y-3), lp);
      canvas.drawPath(Path()..moveTo(x+4,y-3)..quadraticBezierTo(x+6,y-1,x+8,y-3), lp);
    } else {
      canvas.drawCircle(Offset(x - 6, y - 2), 2.5, Paint()..color = Colors.black);
      canvas.drawCircle(Offset(x + 6, y - 2), 2.5, Paint()..color = Colors.black);
    }
    canvas.drawPath(
      Path()..moveTo(x-7,y+4)..quadraticBezierTo(x, happy ? y+9 : y+7, x+7, y+4),
      Paint()..color = Colors.black..style = PaintingStyle.stroke..strokeWidth = 2..strokeCap = StrokeCap.round,
    );
  }

  void _drawSparkle(Canvas canvas, double x, double y, double s) {
    final p = Paint()
      ..color = const Color(0xFFFFD700)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(x, y - s), Offset(x, y + s), p);
    canvas.drawLine(Offset(x - s, y), Offset(x + s, y), p);
    canvas.drawLine(Offset(x - s*0.7, y - s*0.7), Offset(x + s*0.7, y + s*0.7), p);
    canvas.drawLine(Offset(x - s*0.7, y + s*0.7), Offset(x + s*0.7, y - s*0.7), p);
    canvas.drawCircle(Offset(x, y), s * 0.3,
        Paint()..color = const Color(0xFFFFD700));
  }

  void _drawFlowers(Canvas canvas, double w, double h) {
    _drawFlower(canvas, w*0.20, h*0.84, Colors.red[600]!);
    _drawFlower(canvas, w*0.26, h*0.87, Colors.yellow[600]!);
    _drawFlower(canvas, w*0.23, h*0.90, Colors.pink[400]!);
    _drawFlower(canvas, w*0.75, h*0.85, Colors.purple[400]!);
    _drawFlower(canvas, w*0.81, h*0.88, Colors.orange[600]!);
    _drawFlower(canvas, w*0.78, h*0.91, Colors.blue[400]!);
  }

  void _drawFlower(Canvas canvas, double x, double y, Color color) {
    canvas.drawLine(Offset(x, y), Offset(x, y - 20),
        Paint()..color = const Color(0xFF4CAF50)..strokeWidth = 3.5..strokeCap = StrokeCap.round);
    final lf = Paint()..color = const Color(0xFF66BB6A)..style = PaintingStyle.fill;
    canvas.drawPath(Path()..moveTo(x,y-10)..quadraticBezierTo(x-6,y-12,x-8,y-8), lf);
    canvas.drawPath(Path()..moveTo(x,y-14)..quadraticBezierTo(x+6,y-16,x+8,y-12), lf);
    for (int i = 0; i < 6; i++) {
      double a  = (i * 60) * (3.14159 / 180);
      double px = x + cos(a) * 8;
      double py = y - 20 + sin(a) * 8;
      canvas.drawCircle(Offset(px, py), 5.5, Paint()..color = color);
      canvas.drawCircle(Offset(px - 1, py - 1), 2,
          Paint()..color = Colors.white.withOpacity(0.4));
    }
    canvas.drawCircle(Offset(x, y - 20), 5, Paint()..color = Colors.amber[700]!);
    canvas.drawCircle(Offset(x, y - 20), 3, Paint()..color = Colors.amber[900]!);
  }

  double cos(double r) => math.cos(r);
  double sin(double r) => math.sin(r);

  // ✅ FIX #2: shouldRepaint now correctly returns true when values change
  @override
  bool shouldRepaint(GardenPainter old) =>
      old.remainingSeconds != remainingSeconds ||
      old.totalSeconds != totalSeconds ||
      old.isWorking != isWorking;
}

class GardenAmbientPainter extends CustomPainter {
  final Animation<double> animation;
  final double progress;
  final bool isPaused;

  GardenAmbientPainter({
    required this.animation,
    required this.progress,
    required this.isPaused,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final t = animation.value;
    final w = size.width;
    final h = size.height;

    _drawMovingClouds(canvas, w, h, t);
    _drawFloatingLeaves(canvas, w, h, t);

    if (progress > 0.45) {
      _drawFireflies(canvas, w, h, t);
    }

    if (progress > 0.72) {
      _drawGardenSparkles(canvas, w, h, t);
    }

    _drawForegroundGrass(canvas, w, h, t);
  }

  void _drawMovingClouds(
    Canvas canvas,
    double w,
    double h,
    double t,
  ) {
    final cloudPaint = Paint()
      ..color = Colors.white.withOpacity(isPaused ? 0.58 : 0.78);

    final firstX = ((t * (w + 240)) - 120) % (w + 240) - 60;
    final secondX =
        (((t + 0.48) % 1.0) * (w + 280)) - 140;

    _drawCloud(canvas, Offset(firstX, h * 0.13), 0.85, cloudPaint);
    _drawCloud(canvas, Offset(secondX, h * 0.21), 0.62, cloudPaint);
  }

  void _drawCloud(
    Canvas canvas,
    Offset center,
    double scale,
    Paint paint,
  ) {
    canvas.drawCircle(
      center.translate(-38 * scale, 2),
      27 * scale,
      paint,
    );
    canvas.drawCircle(
      center.translate(-12 * scale, -8 * scale),
      36 * scale,
      paint,
    );
    canvas.drawCircle(
      center.translate(22 * scale, -2 * scale),
      31 * scale,
      paint,
    );
    canvas.drawCircle(
      center.translate(48 * scale, 5 * scale),
      23 * scale,
      paint,
    );
  }

  void _drawFloatingLeaves(
    Canvas canvas,
    double w,
    double h,
    double t,
  ) {
    for (int i = 0; i < 11; i++) {
      final phase = (t + i * 0.117) % 1.0;
      final x = (phase * (w + 90)) - 45;
      final baseY = h * (0.31 + (i % 5) * 0.075);
      final y = baseY + math.sin((phase * 6.28) + i) * 18;
      final angle = phase * 6.28 + i;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(angle);

      final rect = Rect.fromCenter(
        center: Offset.zero,
        width: 10 + (i % 3) * 2,
        height: 5 + (i % 2) * 2,
      );

      canvas.drawOval(
        rect,
        Paint()
          ..color = (i.isEven
                  ? const Color(0xFF7CB342)
                  : const Color(0xFF558B2F))
              .withOpacity(isPaused ? 0.38 : 0.68),
      );

      canvas.restore();
    }
  }

  void _drawFireflies(
    Canvas canvas,
    double w,
    double h,
    double t,
  ) {
    for (int i = 0; i < 9; i++) {
      final x =
          w * (0.16 + ((i * 0.097 + t * 0.08) % 0.72));
      final y =
          h * (0.58 + (i % 4) * 0.065) +
              math.sin(t * 12 + i) * 8;
      final glow =
          (0.35 + 0.35 * math.sin(t * 14 + i * 0.8))
              .clamp(0.10, 0.70)
              .toDouble();

      canvas.drawCircle(
        Offset(x, y),
        7,
        Paint()
          ..color = const Color(0xFFFFF59D).withOpacity(glow * 0.22)
          ..maskFilter =
              const MaskFilter.blur(BlurStyle.normal, 7),
      );
      canvas.drawCircle(
        Offset(x, y),
        2,
        Paint()
          ..color = const Color(0xFFFFF59D).withOpacity(glow),
      );
    }
  }

  void _drawGardenSparkles(
    Canvas canvas,
    double w,
    double h,
    double t,
  ) {
    final intensity =
        ((progress - 0.72) / 0.28)
            .clamp(0.0, 1.0)
            .toDouble();

    for (int i = 0; i < 10; i++) {
      final phase = (t * 1.4 + i * 0.13) % 1.0;
      final x = w * (0.34 + (i % 5) * 0.095);
      final y = h * (0.65 + (i ~/ 5) * 0.09) -
          phase * 28;
      final alpha =
          (math.sin(phase * math.pi) * intensity)
              .clamp(0.0, 1.0)
              .toDouble();

      final sparklePaint = Paint()
        ..color = const Color(0xFFFFD54F).withOpacity(alpha)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;

      final radius = 3.0 + (i % 3);
      canvas.drawLine(
        Offset(x - radius, y),
        Offset(x + radius, y),
        sparklePaint,
      );
      canvas.drawLine(
        Offset(x, y - radius),
        Offset(x, y + radius),
        sparklePaint,
      );
    }
  }

  void _drawForegroundGrass(
    Canvas canvas,
    double w,
    double h,
    double t,
  ) {
    final paint = Paint()
      ..color = const Color(0xFF2E7D32).withOpacity(0.72)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 34; i++) {
      final x = i * w / 33;
      final sway = math.sin(t * 6.28 + i * 0.55) * 3;
      final height = 13.0 + (i % 5) * 3;

      canvas.drawLine(
        Offset(x, h),
        Offset(x + sway, h - height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(GardenAmbientPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isPaused != isPaused;
  }
}

