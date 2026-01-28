import 'package:flutter/material.dart';
import '../models/character.dart';
import '../models/farm.dart';

class ShopScreen extends StatelessWidget {
  final Character character;
  final Farm farm;

  ShopScreen({required this.character, required this.farm});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        "🏪 Shop\nComing Soon!",
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white, fontSize: 24),
      ),
    );
  }
}