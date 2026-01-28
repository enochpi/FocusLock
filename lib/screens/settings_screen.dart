import 'package:flutter/material.dart';
import '../models/character.dart';

class SettingsScreen extends StatelessWidget {
  final Character character;

  SettingsScreen({required this.character});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        "⚙️ Settings\nComing Soon!",
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white, fontSize: 24),
      ),
    );
  }
}