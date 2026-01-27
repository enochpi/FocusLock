import 'package:flutter/material.dart';
import '../models/character.dart';
import '../models/farm.dart';
import '../services/storage_service.dart';
import 'focus_screen.dart';
import 'farm_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Character character = Character();
  Farm farm = Farm();
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

    setState(() {
      character = loaded ?? Character(name: "Alex");
      farm = loadedFarm;
      isLoading = false;
    });

    // Give starting money if new player
    if (character.totalFocusMinutes == 0 && character.money == 0) {
      character.earnMoney(50); // Starting money
      await storage.saveCharacter(character);
    }
  }

  void startFocusSession() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FocusScreen(
          character: character,
          farm: farm,
        ),
      ),
    ).then((_) {
      loadData();
    });
  }

  void openFarm() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FarmScreen(
          character: character,
          farm: farm,
        ),
      ),
    ).then((_) {
      loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey[900],
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: Text("Focus Life"),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: Icon(Icons.agriculture),
            onPressed: openFarm,
            tooltip: "Manage Farm",
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Character Card
            Card(
              color: Colors.grey[850],
              elevation: 4,
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.blue,
                          child: Text(
                            character.name[0],
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(width: 15),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              character.name,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "🏠 ${character.currentStage}",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatColumn("💰", "\$${character.money}"),
                        _buildStatColumn("⭐", "${character.focusPoints}"),
                        _buildStatColumn("⏱️", "${character.totalFocusMinutes} min"),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),

            // Farm Status
            Text(
              "Farm Status",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),
            Card(
              color: Colors.grey[850],
              child: Padding(
                padding: EdgeInsets.all(15),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "🌱 Crops: ${farm.crops.length}/${farm.maxPlots}",
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                        if (farm.readyCount > 0)
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              "${farm.readyCount} Ready!",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (farm.crops.isNotEmpty) ...[
                      SizedBox(height: 15),
                      ...farm.crops.take(3).map((crop) => Padding(
                        padding: EdgeInsets.symmetric(vertical: 5),
                        child: Row(
                          children: [
                            Text(
                              crop.type,
                              style: TextStyle(color: Colors.white),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: LinearProgressIndicator(
                                value: crop.growthPercentage,
                                backgroundColor: Colors.grey[700],
                                color: crop.isReady ? Colors.green : Colors.blue,
                              ),
                            ),
                            SizedBox(width: 10),
                            Text(
                              crop.isReady
                                  ? "✅"
                                  : "${(crop.growthPercentage * 100).toInt()}%",
                              style: TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      )).toList(),
                      if (farm.crops.length > 3) ...[
                        SizedBox(height: 10),
                        Text(
                          "...and ${farm.crops.length - 3} more",
                          style: TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                      ],
                    ] else ...[
                      SizedBox(height: 10),
                      Text(
                        "No crops planted",
                        style: TextStyle(color: Colors.white54),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            SizedBox(height: 30),

            // Start Focus Button
            Center(
              child: ElevatedButton(
                onPressed: startFocusSession,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: EdgeInsets.symmetric(horizontal: 60, vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.play_arrow, size: 28, color: Colors.white),
                    SizedBox(width: 10),
                    Text(
                      "Start Focus (25 min)",
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),

            // Milestone Progress
            if (character.totalFocusMinutes < 600) ...[
              Text(
                "Next Milestone",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              Card(
                color: Colors.grey[850],
                child: Padding(
                  padding: EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "🎓 College (600 min total)",
                        style: TextStyle(color: Colors.white),
                      ),
                      SizedBox(height: 10),
                      LinearProgressIndicator(
                        value: character.totalFocusMinutes / 600,
                        backgroundColor: Colors.grey[700],
                        color: Colors.amber,
                      ),
                      SizedBox(height: 5),
                      Text(
                        "${character.totalFocusMinutes}/600 minutes",
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String emoji, String value) {
    return Column(
      children: [
        Text(
          emoji,
          style: TextStyle(fontSize: 24),
        ),
        SizedBox(height: 5),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}