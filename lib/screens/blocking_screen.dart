import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BlockingScreen extends StatefulWidget {
  final VoidCallback onReturn;
  final String appName;

  BlockingScreen({
    required this.onReturn,
    this.appName = "blocked app",
  });

  @override
  _BlockingScreenState createState() => _BlockingScreenState();
}

class _BlockingScreenState extends State<BlockingScreen> {
  int countdown = 10;
  Timer? countdownTimer;

  @override
  void initState() {
    super.initState();

    // Lock orientation to portrait
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    startCountdown();
  }

  void startCountdown() {
    countdownTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        countdown--;
      });

      if (countdown <= 0) {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    countdownTimer?.cancel();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => countdown <= 0,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Big block icon
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.red.withOpacity(0.2),
                    ),
                    child: Icon(
                      Icons.block,
                      color: Colors.red,
                      size: 60,
                    ),
                  ),

                  SizedBox(height: 40),

                  Text(
                    "Focus Break",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: 20),

                  Text(
                    "You tried to open ${widget.appName}",
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 18,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  SizedBox(height: 60),

                  if (countdown > 0) ...[
                    Text(
                      "$countdown",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 64,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "seconds until you can return...",
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 30),
                    SizedBox(
                      width: 100,
                      height: 100,
                      child: CircularProgressIndicator(
                        value: (10 - countdown) / 10,
                        strokeWidth: 8,
                        color: Colors.red,
                        backgroundColor: Colors.white24,
                      ),
                    ),
                  ] else ...[
                    Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 80,
                    ),
                    SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        widget.onReturn();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 20,
                        ),
                      ),
                      child: Text(
                        "Return to Focus",
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}