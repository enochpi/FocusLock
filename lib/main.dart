import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Focus Life',
      theme: ThemeData.dark(),
      home: HomeScreen(), // Start with HomeScreen
      debugShowCheckedModeBanner: false,
    );
  }
}

class TestTimerScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Test Timer")),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => FocusScreen()),
            );
          },
          child: Text("Start 25-Minute Focus Session"),
        ),
      ),
    );
  }
}