import 'package:flutter/material.dart';
import '../models/character.dart';
import '../models/farm.dart';
import '../models/focus_session.dart';
import '../services/storage_service.dart';
import 'dart:async';

class FocusActiveScreen extends StatefulWidget {
  final Character character;
  final Farm farm;
  final int durationMinutes;

  const FocusActiveScreen({super.key, 
    required this.character,
    required this.farm,
    required this.durationMinutes,
  });

  @override
  _FocusActiveScreenState createState() => _FocusActiveScreenState();
}

class _FocusActiveScreenState extends State<FocusActiveScreen> {
  late FocusSession session;
  Timer? timer;
  StorageService storage = StorageService();

  @override
  void initState() {
    super.initState();
    session = FocusSession(durationMinutes: widget.durationMinutes);
    session.start();

    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() {
        session.tick();

        if (session.isComplete) {
          t.cancel();
          onComplete();
        }
      });
    });
  }

  void onComplete() {
    int coinsEarned = widget.durationMinutes * 2;
    widget.character.earnMoney(coinsEarned);
    widget.character.addFocusMinutes(widget.durationMinutes);
    widget.farm.growAll(widget.durationMinutes);

    storage.saveCharacter(widget.character);
    storage.saveFarm(widget.farm);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF16213e),
        title: const Text("Complete! 🎉", style: TextStyle(color: Colors.white)),
        content: Text(
          "Earned $coinsEarned coins!\n${widget.durationMinutes} minutes focused",
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text("Done"),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Focus Time",
              style: TextStyle(color: Colors.white70, fontSize: 24),
            ),
            const SizedBox(height: 40),
            Text(
              session.formattedTime,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 72,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}