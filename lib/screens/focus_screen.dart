import 'dart:async';
import 'package:flutter/material.dart';
import '../models/focus_session.dart';
import '../models/character.dart';
import '../models/farm.dart';
import '../services/storage_service.dart';
import '../services/app_monitor_service.dart';
import 'blocking_screen.dart';

class FocusScreen extends StatefulWidget {
  final Character character;
  final Farm farm;

  FocusScreen({
    required this.character,
    required this.farm,
  });

  @override
  _FocusScreenState createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> {
  FocusSession session = FocusSession(durationMinutes: 25);
  Timer? timer;
  Timer? progressTimer;
  AppMonitorService monitor = AppMonitorService();
  StorageService storage = StorageService();
  int breakCount = 0;

  @override
  void initState() {
    super.initState();
    startSession();
    startMonitoring();
    startProgressUpdates();
  }

  void startSession() {
    session.start();
    timer = Timer.periodic(Duration(seconds: 1), (t) {
      setState(() {
        session.tick();

        if (session.isComplete) {
          t.cancel();
          onSessionComplete();
        }
      });
    });
  }

  void startMonitoring() {
    monitor.onBlockedAppOpened = (appName) {
      breakCount++;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BlockingScreen(
            appName: appName,
            onReturn: () {
              // Just return to focus
            },
          ),
        ),
      );
    };
    monitor.startMonitoring();
  }

  void startProgressUpdates() {
    // Every 1 minute: grow crops and add focus minutes
    progressTimer = Timer.periodic(Duration(minutes: 1), (t) {
      setState(() {
        widget.farm.growAll(1);
        widget.character.addFocusMinutes(1);
      });
      saveData();
    });
  }

  Future<void> saveData() async {
    await storage.saveCharacter(widget.character);
    await storage.saveFarm(widget.farm);
  }

  void onSessionComplete() {
    monitor.stopMonitoring();
    progressTimer?.cancel();

    // Give completion bonus
    widget.character.earnMoney(10);

    // Auto-harvest ready crops
    int harvestMoney = widget.farm.harvestAll();
    widget.character.earnMoney(harvestMoney);

    saveData();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text("Session Complete! 🎉"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Great work focusing!"),
            SizedBox(height: 10),
            Text("⏱️ ${session.focusMinutes} minutes focused"),
            Text("💰 \$${10 + harvestMoney} earned"),
            if (harvestMoney > 0) Text("🌾 Crops auto-harvested!"),
            if (breakCount > 0) Text("⚠️ $breakCount distractions blocked"),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Return to home
            },
            child: Text("Done"),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    progressTimer?.cancel();
    monitor.stopMonitoring();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        bool shouldExit = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text("End Session?"),
            content: Text("You'll lose progress if you quit now."),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text("Stay"),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text("Quit", style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ) ?? false;

        if (shouldExit) {
          monitor.stopMonitoring();
          progressTimer?.cancel();
        }

        return shouldExit;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Stats Header
                Padding(
                  padding: EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Text(
                        "💰 \$${widget.character.money}",
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                      Text(
                        "🌾 ${widget.farm.readyCount}/${widget.farm.crops.length}",
                        style: TextStyle(color: Colors.white, fontSize: 18),
                      ),
                      if (breakCount > 0)
                        Text(
                          "⚠️ $breakCount",
                          style: TextStyle(color: Colors.orange, fontSize: 18),
                        ),
                    ],
                  ),
                ),

                Spacer(),

                // Main Timer
                Text(
                  "Focus Time",
                  style: TextStyle(color: Colors.white70, fontSize: 24),
                ),
                SizedBox(height: 20),
                Text(
                  session.formattedTime,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 72,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                SizedBox(height: 40),

                // Progress indicator
                Container(
                  width: 200,
                  height: 200,
                  child: CircularProgressIndicator(
                    value: session.elapsedSeconds / (session.durationMinutes * 60),
                    strokeWidth: 8,
                    color: Colors.green,
                    backgroundColor: Colors.white24,
                  ),
                ),

                Spacer(),

                // Bottom info
                Text(
                  "Stay focused!",
                  style: TextStyle(color: Colors.white54, fontSize: 16),
                ),
                SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}