import 'package:flutter/material.dart';
import 'package:focus_life/services/achievements_service.dart';
import 'package:focus_life/services/streak_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:math' as math;
import '../models/character.dart';
import '../services/currency_service.dart';
import '../services/upgrade_service.dart';
import '../services/app_monitor_service.dart';
import '../services/focus_session_service.dart';
import 'blocking_screen.dart';
import '../services/feedback_service.dart';

class GardenFocusScreen extends StatefulWidget {
  final Character character;
  final int focusDurationMinutes;

  const GardenFocusScreen({
    super.key,
    required this.character,
    required this.focusDurationMinutes,
  });

  @override
  _GardenFocusScreenState createState() => _GardenFocusScreenState();
}

class _GardenFocusScreenState extends State<GardenFocusScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final CurrencyService currency = CurrencyService();
  final UpgradeService upgrades = UpgradeService();
  final AppMonitorService appMonitor = AppMonitorService();
  final FocusSessionService sessionService = FocusSessionService();

  late AnimationController _characterController;
  bool _isWorking = false;
  int _remainingSeconds = 0;

  Timer? _countdownTimer;
  Timer? _saveTimer;
  bool _isPaused   = false;
  bool _isFinished = false;

  // ── Decoration boosts (loaded once at start) ─────────────────────────
  bool _torchesOwned  = false;
  bool _chimesOwned   = false;
  bool _fountainOwned = false;

  // ── Total multiplier including decoration boosts ──────────────────────
  double get _totalMultiplier =>
      upgrades.getTotalMultiplier()
          * (_torchesOwned  ? 1.15 : 1.0)
          * (_chimesOwned   ? 1.10 : 1.0)
          * (_fountainOwned ? 1.12 : 1.0);

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.focusDurationMinutes * 60;

    _characterController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addObserver(this);

    _loadDecorationBoosts().then((_) => _startFocusSession());
  }

  @override
  void dispose() {
    _characterController.dispose();
    _countdownTimer?.cancel();
    _saveTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    appMonitor.stopMonitoring();
    super.dispose();
  }

  // ── Load decoration boost flags from SharedPreferences ────────────────
  Future<void> _loadDecorationBoosts() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _torchesOwned  = prefs.getBool('torches_purchased')     ?? false;
        _chimesOwned   = prefs.getBool('wind_chimes_purchased') ?? false;
        _fountainOwned = prefs.getBool('fountain_purchased')    ?? false;
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused) {
      debugPrint('⏸️ App went to background - pausing timer');
      _pauseTimer();
    } else if (state == AppLifecycleState.resumed) {
      debugPrint('▶️ App resumed - resuming timer');
      _resumeTimer();
    }
  }

  void _pauseTimer() {
    if (!_isPaused && _countdownTimer != null) {
      _isPaused = true;
      _countdownTimer?.cancel();
      debugPrint('Timer paused at $_remainingSeconds seconds');
    }
  }

  void _resumeTimer() {
    if (_isPaused && _isWorking && _remainingSeconds > 0) {
      _isPaused = false;
      _startCountdownTimer();
      debugPrint('Timer resumed at $_remainingSeconds seconds');
    }
  }

  void _startFocusSession() async {
    setState(() => _isWorking = true);
    await sessionService.startSession(durationMinutes: widget.focusDurationMinutes);
    appMonitor.startMonitoring(_onBlockedAppDetected);
    _startCountdownTimer();
    _startPeriodicSave();
  }

  void _startPeriodicSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_isWorking && !_isPaused) {
        sessionService.updateRemainingTime(_remainingSeconds);
      }
    });
  }

  void _startCountdownTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) { timer.cancel(); return; }
      if (_isPaused) return;
      if (_remainingSeconds > 0 && _isWorking) {
        setState(() => _remainingSeconds--);
        if (_remainingSeconds == 0) {
          timer.cancel();
          _finishSession();
        }
      } else {
        timer.cancel();
      }
    });
  }

  void _onBlockedAppDetected(String appName, String packageName) async {
    debugPrint('🚫 Blocked app opened: $appName');
    _pauseTimer();
    await FeedbackService().vibrateOnBlock();
    await appMonitor.incrementBlockCount();
    appMonitor.stopMonitoring();
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlockingScreen(
          appName: appName,
          onReturn: () {
            debugPrint('✅ User returned from blocking screen');
            _resumeTimer();
            if (_isWorking && mounted) {
              appMonitor.startMonitoring(_onBlockedAppDetected);
            }
          },
        ),
      ),
    );
  }

  int _calculatePeasSoFar() {
    int elapsedMinutes = widget.focusDurationMinutes - (_remainingSeconds ~/ 60);
    final double torchMultiplier = (_torchesOwned  ? 1.15 : 1.0)
        * (_chimesOwned   ? 1.10 : 1.0)
        * (_fountainOwned ? 1.12 : 1.0);
    return CurrencyService.calculatePeasFromFocus(
      elapsedMinutes,
      upgradeMultiplier: upgrades.getTotalMultiplier(),
      torchMultiplier: torchMultiplier,
    );
  }

  void _finishSession() async {
    // Race condition guard
    if (_isFinished || !_isWorking) return;

    setState(() {
      _isFinished = true;
      _isWorking  = false;
    });

    _countdownTimer?.cancel();
    _saveTimer?.cancel();
    appMonitor.stopMonitoring();

    await sessionService.completeSession();
    await StreakService().recordFocusSession();

    // Apply upgrade + decoration boosts
    final double torchMultiplier = (_torchesOwned  ? 1.15 : 1.0)
        * (_chimesOwned   ? 1.10 : 1.0)
        * (_fountainOwned ? 1.12 : 1.0);
    int peasEarned = CurrencyService.calculatePeasFromFocus(
      widget.focusDurationMinutes,
      upgradeMultiplier: upgrades.getTotalMultiplier(),
      torchMultiplier: torchMultiplier,
    );

    await currency.addPeas(peasEarned);
    await AchievementService().onFocusSessionCompleted(widget.focusDurationMinutes);

    int earnings = widget.focusDurationMinutes * 5;
    widget.character.earnMoney(earnings);
    widget.character.addFocusMinutes(widget.focusDurationMinutes);

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
            Text('${widget.focusDurationMinutes} min + 10% bonus!',
                style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white60,
                    fontStyle: FontStyle.italic)),
            // Show decoration boosts if active
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
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Awesome!',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF87CEEB),
      body: Stack(
        children: [
          CustomPaint(
            size: Size.infinite,
            painter: GardenPainter(
              characterAnimation: _characterController.value,
              isWorking: _isWorking,
              totalSeconds: widget.focusDurationMinutes * 60,
              remainingSeconds: _remainingSeconds,
            ),
          ),
          if (_isPaused)
            Positioned(
              top: 120, left: 0, right: 0,
              child: Center(
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.3), blurRadius: 10)
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.pause, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text('Timer Paused',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ),
          Positioned(
            top: 60, left: 0, right: 0,
            child: Center(
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(30)),
                child: Text(
                  _formatTime(_remainingSeconds),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace'),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 40, left: 0, right: 0,
            child: Center(
              child: ElevatedButton(
                onPressed: _showStopDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 50, vertical: 20),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                ),
                child: const Text('Stop Session',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showStopDialog() {
    int elapsedSeconds = (widget.focusDurationMinutes * 60) - _remainingSeconds;
    int elapsedMinutes = elapsedSeconds ~/ 60;

    if (elapsedMinutes < 5) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: const Color(0xFF16213e),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Text('⏱️', style: TextStyle(fontSize: 28)),
              SizedBox(width: 12),
              Expanded(
                child: Text('Stop Session?',
                    style: TextStyle(color: Colors.white, fontSize: 18)),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.withOpacity(0.5)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.block, color: Colors.red, size: 48),
                    const SizedBox(height: 12),
                    const Text("You won't earn any peas!",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 8),
                    const Text(
                        'You need at least 5 minutes of focus to earn peas.',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    Text(
                      'Current: $elapsedMinutes min\nRequired: 5 min',
                      style: TextStyle(color: Colors.red[300], fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Keep Focusing',
                  style: TextStyle(
                      color: Color(0xFF00d4ff),
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
            ),
            TextButton(
              onPressed: () async {
                _countdownTimer?.cancel();
                _saveTimer?.cancel();
                appMonitor.stopMonitoring();
                await sessionService.cancelSession();
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text('Stop Anyway',
                  style: TextStyle(color: Colors.red, fontSize: 16)),
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
            Expanded(
              child: Text('Stop Focus Session?',
                  style: TextStyle(color: Colors.white, fontSize: 18)),
            ),
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
                  const Text('Earned so far:',
                      style: TextStyle(color: Colors.white70)),
                  Text('$peasSoFar 🌱',
                      style: const TextStyle(
                          color: Color(0xFF4CAF50),
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
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
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('❌', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text('Lose $peasLost peas (20% penalty)',
                            style: TextStyle(color: Colors.red[300])),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Text('✅', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text('Keep $peasKept peas',
                            style: const TextStyle(
                                color: Color(0xFF4CAF50))),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep Focusing',
                style: TextStyle(
                    color: Color(0xFF00d4ff),
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () async {
              _countdownTimer?.cancel();
              _saveTimer?.cancel();
              appMonitor.stopMonitoring();
              await sessionService.cancelSession();
              if (peasKept > 0) await currency.addPeas(peasKept);
              widget.character.addFocusMinutes(elapsedMinutes);
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Stop',
                style: TextStyle(color: Colors.red, fontSize: 16)),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// GARDEN PAINTER — unchanged
// ═══════════════════════════════════════════════════════════════
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
    _drawClouds(canvas, w, h);
    _drawGround(canvas, w, h);
    _drawCaveEntrance(canvas, w, h);
    _drawTrees(canvas, w, h);
    _drawRocks(canvas, w, h);
    _drawGarden(canvas, w, h);
    _drawCharacter(canvas, w, h);
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
    if (progress >= 0.50) stage = 1;
    if (progress >= 0.60) stage = 2;
    if (progress >= 0.70) stage = 3;
    if (progress >= 0.80) stage = 4;
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
    final p = Paint()..color = const Color(0xFFFFD700)..strokeWidth = 3..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(x, y - s), Offset(x, y + s), p);
    canvas.drawLine(Offset(x - s, y), Offset(x + s, y), p);
    canvas.drawLine(Offset(x - s*0.7, y - s*0.7), Offset(x + s*0.7, y + s*0.7), p);
    canvas.drawLine(Offset(x - s*0.7, y + s*0.7), Offset(x + s*0.7, y - s*0.7), p);
    canvas.drawCircle(Offset(x, y), s * 0.3,
        Paint()..color = const Color(0xFFFFD700)..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.5));
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

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}