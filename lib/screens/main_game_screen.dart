import 'package:flutter/material.dart';
import '../models/character.dart';
import '../models/farm.dart';
import '../models/cave_decorations.dart'; // ADD THIS LINE!
import '../services/storage_service.dart';
import 'cave_scene_screen.dart';
import 'shop_screen.dart';
import 'settings_screen.dart';

class MainGameScreen extends StatefulWidget {
  const MainGameScreen({super.key});

  @override
  _MainGameScreenState createState() => _MainGameScreenState();
}

class _MainGameScreenState extends State<MainGameScreen> {
  int _currentIndex = 1;
  Character character = Character();
  Farm farm = Farm();
  CaveDecorations decorations = CaveDecorations();
  StorageService storage = StorageService();
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    Character? loaded = await storage.loadCharacter();
    Farm loadedFarm = await storage.loadFarm();
    CaveDecorations loadedDeco = await storage.loadCaveDecorations();

    setState(() {
      character = loaded ?? Character(name: "Bob");
      farm = loadedFarm;
      decorations = loadedDeco;
      isLoading = false;
    });

    if (character.totalFocusMinutes == 0 && character.money == 0) {
      character.earnMoney(50);
      await storage.saveCharacter(character);
    }
  }

  List<Widget> get _screens => [
    const ShopScreen(),
    CaveSceneScreen(
      character: character,
      farm: farm,
      decorations: decorations, // PASS DECORATIONS HERE
      onUpdate: () => setState(() {}),
    ),
    SettingsScreen(character: character),
  ];

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1a1a2e),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: const Color(0xFF16213e),
        selectedItemColor: const Color(0xFF00d4ff),
        unselectedItemColor: Colors.white54,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.store, size: 30),
            label: 'Shop',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.play_circle_filled, size: 40),
            label: 'Focus',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings, size: 30),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}