import 'package:flutter/material.dart';
import '../models/character.dart';
import '../models/cave_decorations.dart';
import '../services/storage_service.dart';

class CaveInteriorScreen extends StatefulWidget {
  final Character character;
  final CaveDecorations decorations;

  CaveInteriorScreen({
    required this.character,
    required this.decorations,
  });

  @override
  _CaveInteriorScreenState createState() => _CaveInteriorScreenState();
}

class _CaveInteriorScreenState extends State<CaveInteriorScreen> {
  StorageService storage = StorageService();

  Color get backgroundColor {
    int level = widget.decorations.lightingLevel;
    switch (level) {
      case 0: return Color(0xFF0a0a0a);
      case 1: return Color(0xFF1a1a1a);
      case 2: return Color(0xFF2a2a2a);
      case 3: return Color(0xFF3a3a3a);
      case 4: return Color(0xFF4a4a4a);
      default: return Color(0xFF0a0a0a);
    }
  }

  void openItemPicker(PlacementSpot spot) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Color(0xFF16213e),
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => ItemPickerSheet(
        character: widget.character,
        decorations: widget.decorations,
        spot: spot,
        onItemSelected: (itemId) {
          setState(() {
            widget.decorations.equipItem(spot.id, itemId);
          });
          storage.saveCaveDecorations(widget.decorations);
          storage.saveCharacter(widget.character);
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get floor item for background
    PlacementSpot? floorSpot = widget.decorations.spots
        .firstWhere((s) => s.category == 'floor');

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text("My Cave"),
        actions: [
          Padding(
            padding: EdgeInsets.all(12),
            child: Center(
              child: Text(
                "💰 \$${widget.character.money}",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 0.8,
                colors: [
                  backgroundColor,
                  backgroundColor.withOpacity(0.7),
                  Colors.black,
                ],
              ),
            ),
          ),

          // All placement spots
          ...widget.decorations.spots.map((spot) {
            if (spot.category == 'floor') return SizedBox.shrink();
            return _buildPlacementSpot(spot);
          }).toList(),

          // Instructions
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.white24, width: 2),
              ),
              child: Text(
                "Tap [+] to add items • Tap items to change/remove",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlacementSpot(PlacementSpot spot) {
    DecorationItem? equippedItem = widget.decorations.getEquippedItem(spot.id);
    bool isEmpty = equippedItem == null;

    return Positioned(
      left: spot.x,
      top: spot.y,
      child: GestureDetector(
        onTap: () => openItemPicker(spot),
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: isEmpty ? Colors.white24 : Colors.transparent,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: isEmpty ? Colors.white54 : Colors.transparent,
              width: 2,
              style: BorderStyle.solid,
            ),
          ),
          child: isEmpty
              ? Icon(Icons.add_circle, size: 40, color: Colors.white54)
              : Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                equippedItem.emoji,
                style: TextStyle(fontSize: 50),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  equippedItem.name,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Item Picker Bottom Sheet
class ItemPickerSheet extends StatelessWidget {
  final Character character;
  final CaveDecorations decorations;
  final PlacementSpot spot;
  final Function(String) onItemSelected;

  ItemPickerSheet({
    required this.character,
    required this.decorations,
    required this.spot,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    List<DecorationItem> allItems = decorations.getItemsByCategory(spot.category);
    List<DecorationItem> ownedItems = decorations.getOwnedItemsByCategory(spot.category);

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Choose ${spot.category.toUpperCase()}",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),

          Divider(color: Colors.white24),

          SizedBox(height: 10),

          // Tabs
          DefaultTabController(
            length: 2,
            child: Expanded(
              child: Column(
                children: [
                  TabBar(
                    indicatorColor: Color(0xFF00d4ff),
                    labelColor: Color(0xFF00d4ff),
                    unselectedLabelColor: Colors.white54,
                    tabs: [
                      Tab(text: "Owned (${ownedItems.length})"),
                      Tab(text: "Shop (${allItems.length})"),
                    ],
                  ),

                  Expanded(
                    child: TabBarView(
                      children: [
                        // OWNED TAB
                        _buildItemGrid(ownedItems, true, context),

                        // SHOP TAB
                        _buildItemGrid(allItems, false, context),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemGrid(List<DecorationItem> items, bool isOwned, BuildContext context) {
    return GridView.builder(
      padding: EdgeInsets.only(top: 20),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 15,
        mainAxisSpacing: 15,
        childAspectRatio: 0.8,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        DecorationItem item = items[index];
        bool canAfford = character.money >= item.cost;
        bool alreadyOwned = item.isOwned;

        return GestureDetector(
          onTap: () {
            if (isOwned) {
              // Equip directly
              onItemSelected(item.id);
            } else {
              // Try to buy
              if (alreadyOwned) {
                onItemSelected(item.id);
              } else if (canAfford) {
                bool success = decorations.purchaseItem(item.id, character.money);
                if (success) {
                  character.spendMoney(item.cost);
                  onItemSelected(item.id);
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Not enough money! Need \$${item.cost}"),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: Color(0xFF0f3460),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: alreadyOwned
                    ? Colors.green
                    : (canAfford ? Color(0xFF00d4ff) : Colors.red),
                width: 2,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item.emoji,
                  style: TextStyle(fontSize: 40),
                ),
                SizedBox(height: 5),
                Text(
                  item.name,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 5),
                if (!isOwned)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: alreadyOwned
                          ? Colors.green
                          : (canAfford ? Color(0xFF00d4ff) : Colors.red),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      alreadyOwned ? "Owned" : "\$${item.cost}",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}