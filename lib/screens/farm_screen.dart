import 'package:flutter/material.dart';
import '../models/character.dart';
import '../models/farm.dart';
import '../services/storage_service.dart';

class FarmScreen extends StatefulWidget {
  final Character character;
  final Farm farm;

  FarmScreen({
    required this.character,
    required this.farm,
  });

  @override
  _FarmScreenState createState() => _FarmScreenState();
}

class _FarmScreenState extends State<FarmScreen> {
  StorageService storage = StorageService();

  Future<void> saveData() async {
    await storage.saveCharacter(widget.character);
    await storage.saveFarm(widget.farm);
  }

  void plantCrop(CropType type) {
    if (widget.farm.canPlant(type, widget.character.money)) {
      setState(() {
        widget.farm.plant(type);
        widget.character.spendMoney(type.cost);
      });
      saveData();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("${type.emoji} Planted ${type.name}!"),
          backgroundColor: Colors.green,
        ),
      );
    } else if (widget.farm.crops.length >= widget.farm.maxPlots) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Farm is full! Harvest some crops first."),
          backgroundColor: Colors.orange,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Not enough money! Need \$${type.cost}"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void harvestCrop(int index) {
    int earned = widget.farm.harvest(index);
    if (earned > 0) {
      setState(() {
        widget.character.earnMoney(earned);
      });
      saveData();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Harvested! Earned \$$earned"),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void harvestAll() {
    int earned = widget.farm.harvestAll();
    if (earned > 0) {
      setState(() {
        widget.character.earnMoney(earned);
      });
      saveData();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Harvested all! Earned \$$earned"),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("No crops ready to harvest"),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: Text("Farm"),
        backgroundColor: Colors.black,
        actions: [
          if (widget.farm.readyCount > 0)
            TextButton.icon(
              onPressed: harvestAll,
              icon: Icon(Icons.yard, color: Colors.white),
              label: Text(
                "Harvest All (${widget.farm.readyCount})",
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Money Display
            Card(
              color: Colors.grey[850],
              child: Padding(
                padding: EdgeInsets.all(15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "💰 Money: \$${widget.character.money}",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "Plots: ${widget.farm.crops.length}/${widget.farm.maxPlots}",
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 20),

            // Current Crops
            Text(
              "Your Crops",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),

            if (widget.farm.crops.isEmpty) ...[
              Card(
                color: Colors.grey[850],
                child: Padding(
                  padding: EdgeInsets.all(30),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.agriculture, size: 48, color: Colors.white54),
                        SizedBox(height: 10),
                        Text(
                          "No crops planted",
                          style: TextStyle(color: Colors.white54, fontSize: 16),
                        ),
                        SizedBox(height: 5),
                        Text(
                          "Plant some below to get started!",
                          style: TextStyle(color: Colors.white38, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ] else ...[
              ...widget.farm.crops.asMap().entries.map((entry) {
                int index = entry.key;
                Crop crop = entry.value;

                return Card(
                  color: Colors.grey[850],
                  margin: EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: Text(
                      getCropEmoji(crop.type),
                      style: TextStyle(fontSize: 32),
                    ),
                    title: Text(
                      crop.type,
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: crop.growthPercentage,
                          backgroundColor: Colors.grey[700],
                          color: crop.isReady ? Colors.green : Colors.blue,
                        ),
                        SizedBox(height: 5),
                        Text(
                          crop.isReady
                              ? "Ready to harvest! \$${crop.sellPrice}"
                              : "${crop.minutesRemaining} min remaining",
                          style: TextStyle(
                            color: crop.isReady ? Colors.green : Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    trailing: crop.isReady
                        ? ElevatedButton(
                      onPressed: () => harvestCrop(index),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      child: Text("Harvest", style: TextStyle(color: Colors.white)),
                    )
                        : Text(
                      "${(crop.growthPercentage * 100).toInt()}%",
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                );
              }).toList(),
            ],

            SizedBox(height: 30),

            // Plant New Crops
            Text(
              "Plant New Crop",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 10),

            ...CropType.availableCrops.map((type) {
              bool canAfford = widget.character.canAfford(type.cost);
              bool hasSpace = widget.farm.crops.length < widget.farm.maxPlots;
              bool canPlant = canAfford && hasSpace;

              return Card(
                color: canPlant ? Colors.grey[850] : Colors.grey[800],
                margin: EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: Text(
                    type.emoji,
                    style: TextStyle(fontSize: 32),
                  ),
                  title: Text(
                    type.name,
                    style: TextStyle(
                      color: canPlant ? Colors.white : Colors.white38,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Cost: \$${type.cost} • Time: ${type.growthTime}min",
                        style: TextStyle(
                          color: canPlant ? Colors.white70 : Colors.white38,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        "Sell: \$${type.sellPrice} • Profit: \$${type.profit}",
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  trailing: ElevatedButton(
                    onPressed: canPlant ? () => plantCrop(type) : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: canPlant ? Colors.blue : Colors.grey,
                    ),
                    child: Text(
                      canPlant ? "Plant" : (hasSpace ? "No money" : "Full"),
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  String getCropEmoji(String cropName) {
    switch (cropName) {
      case "Wheat": return "🌾";
      case "Carrot": return "🥕";
      case "Tomato": return "🍅";
      case "Corn": return "🌽";
      default: return "🌱";
    }
  }
}