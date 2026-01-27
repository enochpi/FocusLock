import 'dart:async';
import 'package:flutter/material.dart';
import '../models/focus_session.dart';

class FocusScreen extends StatefulWidget {
  @override
  _FocusScreenState createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> {
  FocusSession session = FocusSession(durationMinutes: 25);
  Timer? timer;

  @override
  void initState() {
    super.initState();
    startSession();
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

  void onSessionComplete() {
    print("🎉 Session complete!");

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Complete!"),
        content: Text("You focused for ${session.focusMinutes} minutes!"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
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
            Text(
              "Focus Time",
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
            SizedBox(height: 40),
            Text(
              session.formattedTime,
              style: TextStyle(color: Colors.white, fontSize: 72, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}