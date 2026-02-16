import 'package:flutter/material.dart';

class StageTheme {
  final String stageName;
  final Color primaryColor;
  final Color accentColor;
  final Color backgroundColor;
  final Color surfaceColor;
  final Color cardColor;
  final Color borderColor;
  final Color textColor;
  final Color subtextColor;
  final Color shopHeaderColor;
  final Color shopTabActiveColor;
  final Color shopTabInactiveColor;
  final Color buttonColor;
  final Color skyColorTop;
  final Color skyColorBottom;
  final Color groundColor;
  final Color groundAccent;
  final String houseEmoji;
  final String gardenEmoji;

  const StageTheme({
    required this.stageName,
    required this.primaryColor,
    required this.accentColor,
    required this.backgroundColor,
    required this.surfaceColor,
    required this.cardColor,
    required this.borderColor,
    required this.textColor,
    required this.subtextColor,
    required this.shopHeaderColor,
    required this.shopTabActiveColor,
    required this.shopTabInactiveColor,
    required this.buttonColor,
    required this.skyColorTop,
    required this.skyColorBottom,
    required this.groundColor,
    required this.groundAccent,
    required this.houseEmoji,
    required this.gardenEmoji,
  });

  // ========================================
  // STAGE 0: CAVE — Dark, earthy, underground
  // ========================================
  static const cave = StageTheme(
    stageName: 'Cave',
    primaryColor: Color(0xFF4CAF50),
    accentColor: Color(0xFF66BB6A),
    backgroundColor: Color(0xFF0a0a0a),
    surfaceColor: Color(0xFF1a1a1a),
    cardColor: Color(0xFF2d2d2d),
    borderColor: Color(0xFF444444),
    textColor: Color(0xFFFFFFFF),
    subtextColor: Color(0xFFB0B0B0),
    shopHeaderColor: Color(0xFF16213e),
    shopTabActiveColor: Color(0xFF4CAF50),
    shopTabInactiveColor: Color(0xFF2d2d2d),
    buttonColor: Color(0xFF4CAF50),
    skyColorTop: Color(0xFF1a1a2e),
    skyColorBottom: Color(0xFF16213e),
    groundColor: Color(0xFF3e2723),
    groundAccent: Color(0xFF4e342e),
    houseEmoji: '🏔️',
    gardenEmoji: '🌱',
  );

  // ========================================
  // STAGE 1: SHACK — Warm wood tones, rustic
  // ========================================
  static const shack = StageTheme(
    stageName: 'Shack',
    primaryColor: Color(0xFFFF8F00),
    accentColor: Color(0xFFFFA726),
    backgroundColor: Color(0xFF1a120a),
    surfaceColor: Color(0xFF2d1f10),
    cardColor: Color(0xFF3d2b18),
    borderColor: Color(0xFF5d4037),
    textColor: Color(0xFFFFFFFF),
    subtextColor: Color(0xFFBCAAA4),
    shopHeaderColor: Color(0xFF3e2723),
    shopTabActiveColor: Color(0xFFFF8F00),
    shopTabInactiveColor: Color(0xFF3d2b18),
    buttonColor: Color(0xFFFF8F00),
    skyColorTop: Color(0xFF1b2838),
    skyColorBottom: Color(0xFF2d4a5e),
    groundColor: Color(0xFF4e342e),
    groundAccent: Color(0xFF6d4c41),
    houseEmoji: '🏚️',
    gardenEmoji: '🥕',
  );

  // ========================================
  // STAGE 2: HOUSE — Cool stone, blue tones
  // ========================================
  static const house = StageTheme(
    stageName: 'House',
    primaryColor: Color(0xFF42A5F5),
    accentColor: Color(0xFF64B5F6),
    backgroundColor: Color(0xFF0a1520),
    surfaceColor: Color(0xFF152030),
    cardColor: Color(0xFF1e3045),
    borderColor: Color(0xFF37474F),
    textColor: Color(0xFFFFFFFF),
    subtextColor: Color(0xFF90CAF9),
    shopHeaderColor: Color(0xFF1a237e),
    shopTabActiveColor: Color(0xFF42A5F5),
    shopTabInactiveColor: Color(0xFF1e3045),
    buttonColor: Color(0xFF42A5F5),
    skyColorTop: Color(0xFF0d47a1),
    skyColorBottom: Color(0xFF42A5F5),
    groundColor: Color(0xFF2e7d32),
    groundAccent: Color(0xFF388E3C),
    houseEmoji: '🏠',
    gardenEmoji: '🌽',
  );

  // ========================================
  // STAGE 3: MANSION — Royal purple & gold
  // ========================================
  static const mansion = StageTheme(
    stageName: 'Mansion',
    primaryColor: Color(0xFFFFD700),
    accentColor: Color(0xFFFFE082),
    backgroundColor: Color(0xFF12001a),
    surfaceColor: Color(0xFF1f0a2e),
    cardColor: Color(0xFF2d1845),
    borderColor: Color(0xFF6A1B9A),
    textColor: Color(0xFFFFFFFF),
    subtextColor: Color(0xFFCE93D8),
    shopHeaderColor: Color(0xFF4A148C),
    shopTabActiveColor: Color(0xFFFFD700),
    shopTabInactiveColor: Color(0xFF2d1845),
    buttonColor: Color(0xFFFFD700),
    skyColorTop: Color(0xFF1a0033),
    skyColorBottom: Color(0xFF4A148C),
    groundColor: Color(0xFF1B5E20),
    groundAccent: Color(0xFF2E7D32),
    houseEmoji: '🏰',
    gardenEmoji: '🌾',
  );

  // Get theme by stage index
  static StageTheme getTheme(int stage) {
    switch (stage) {
      case 0: return cave;
      case 1: return shack;
      case 2: return house;
      case 3: return mansion;
      default: return cave;
    }
  }
}