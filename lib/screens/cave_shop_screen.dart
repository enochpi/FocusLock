import 'package:flutter/material.dart';
import '../services/furniture_service.dart';
import '../services/currency_service.dart';

class CaveShopScreen extends StatefulWidget {
  @override
  _CaveShopScreenState createState() => _CaveShopScreenState();
}

class _CaveShopScreenState extends State<CaveShopScreen> {
  final FurnitureService furnitureService = FurnitureService();
  final CurrencyService currencyService = CurrencyService();

  FurnitureCategory selectedCategory = FurnitureCategory.bed;


    // ... rest of build method

  @override
  Widget build(BuildContext context) {
    print("=== FURNITURE STATUS ===");
    print("Desk spot: ${furnitureService.getPlacedFurniture('desk_spot')?.id ?? 'EMPTY'}");
    print("Owned desks: ${furnitureService.ownedFurniture.where((id) => id.contains('desk')).toList()}");
    print("=======================");
    return Scaffold(
      backgroundColor: Color(0xFF0a0a0a),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text('Cave Furniture Shop'),
        actions: [
          // Show current coins
          Padding(
            padding: EdgeInsets.all(12),
            child: Center(
              child: Text(
                '🪙 ${currencyService.coins}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Furniture boost display
          _buildBoostDisplay(),

          // Category tabs (ICONS ONLY - SMALLER)
          _buildCategoryTabs(),

          // Furniture grid
          Expanded(
            child: _buildFurnitureGrid(),
          ),
        ],
      ),
    );
  }

  // Boost display at top
  Widget _buildBoostDisplay() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(12),
      margin: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color(0xFF1a1a1a),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFF4CAF50), width: 2),
      ),
      child: Column(
        children: [
          Text(
            'Total Furniture Boost',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
          SizedBox(height: 4),
          Text(
            furnitureService.getBoostString(),
            style: TextStyle(
              color: Color(0xFF4CAF50),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Category tabs (ICONS ONLY - NO TEXT)
  Widget _buildCategoryTabs() {
    return Container(
      height: 60,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 12),
        children: [
          _buildCategoryTab(FurnitureCategory.bed, '🛏️'),
          _buildCategoryTab(FurnitureCategory.desk, '📚'),
          _buildCategoryTab(FurnitureCategory.chair, '🪑'),
          _buildCategoryTab(FurnitureCategory.kitchen, '🔥'),
          _buildCategoryTab(FurnitureCategory.decoration, '🖼️'),
        ],
      ),
    );
  }

  Widget _buildCategoryTab(FurnitureCategory category, String emoji) {
    bool isSelected = selectedCategory == category;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedCategory = category;
        });
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 4),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFF4CAF50) : Color(0xFF2d2d2d),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Color(0xFF4CAF50) : Color(0xFF444444),
            width: 2,
          ),
        ),
        child: Text(
          emoji,
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }

  // Furniture grid
  Widget _buildFurnitureGrid() {
    List<Furniture> items = furnitureService.getFurnitureByCategory(selectedCategory);

    if (items.isEmpty) {
      return Center(
        child: Text(
          'No items in this category',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    return GridView.builder(
      padding: EdgeInsets.all(12),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.7, // ADJUSTED FOR BETTER FIT
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return _buildFurnitureCard(items[index]);
      },
    );
  }


  // Individual furniture card (MORE COMPACT)
  Widget _buildFurnitureCard(Furniture furniture) {
    bool canAfford = currencyService.coins >= furniture.cost;
    bool isOwned = furnitureService.ownedFurniture.contains(furniture.id); // ← FIXED!
    bool isEquipped = _isFurnitureEquipped(furniture);

    // Determine button state
    String buttonText;
    Color buttonColor;
    VoidCallback? onPressed;

    if (!isOwned) {
      // Not owned - show Buy button
      buttonText = canAfford ? 'Buy' : 'Need 🪙';
      buttonColor = canAfford ? Color(0xFF4CAF50) : Colors.grey;
      onPressed = canAfford ? () => _buyFurniture(furniture) : null;
    } else if (isEquipped) {
      // Owned and equipped - show Remove button
      buttonText = 'Remove';
      buttonColor = Colors.red;
      onPressed = () => _removeFurniture(furniture);
    } else {
      // Owned but not equipped - show Equip button
      buttonText = 'Equip';
      buttonColor = Colors.blue;
      onPressed = () => _equipFurniture(furniture);
    }

    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF2d2d2d),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isEquipped
              ? Color(0xFF4CAF50)
              : (isOwned ? Colors.blue : (canAfford ? Color(0xFF666666) : Color(0xFF444444))),
          width: isEquipped ? 3 : 2,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top section - emoji and name
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Furniture emoji
                Text(
                  furniture.emoji,
                  style: TextStyle(fontSize: 45),
                ),
                SizedBox(height: 6),

                // Furniture name
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    furniture.name,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(height: 4),

                // Boost amount
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Color(0xFF4CAF50).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    furniture.description,
                    style: TextStyle(
                      color: Color(0xFF4CAF50),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom section - price and button
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Column(
              children: [
                // Price (only show if not owned)
                if (!isOwned) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '🪙 ',
                        style: TextStyle(fontSize: 16),
                      ),
                      Text(
                        '${furniture.cost}',
                        style: TextStyle(
                          color: canAfford ? Colors.amber : Colors.red,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6),
                ] else ...[
                  // Show "Owned" badge
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '✓ Owned',
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(height: 6),
                ],

                // Action button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: buttonColor,
                      padding: EdgeInsets.symmetric(vertical: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      buttonText,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  // Check if furniture is owned
  bool _isFurnitureOwned(Furniture furniture) {
    for (String? furnitureId in furnitureService.placedFurniture.values) {
      if (furnitureId == furniture.id) return true;
    }
    return false;
  }

  // Check if furniture is equipped
  bool _isFurnitureEquipped(Furniture furniture) {
    return _isFurnitureOwned(furniture);
  }

  // Buy furniture
  Future<void> _buyFurniture(Furniture furniture) async {
    if (currencyService.coins < furniture.cost) return;

    // Add to owned
    furnitureService.ownedFurniture.add(furniture.id);

    // Deduct coins
    await currencyService.addCoins(-furniture.cost);

    // Auto-equip for beds and kitchen (only 1 spot)
    // Auto-equip for beds, kitchen, AND DESKS (only 1 spot each)
    if (furniture.category == FurnitureCategory.bed) {
      await furnitureService.removeFurniture('bed_spot');
      await furnitureService.placeFurnitureInSpot('bed_spot', furniture.id, currencyService.coins);
    } else if (furniture.category == FurnitureCategory.kitchen) {
      await furnitureService.removeFurniture('kitchen_spot');
      await furnitureService.placeFurnitureInSpot('kitchen_spot', furniture.id, currencyService.coins);
    } else if (furniture.category == FurnitureCategory.desk) {  // ← ADD THIS!
      await furnitureService.removeFurniture('desk_spot');
      await furnitureService.placeFurnitureInSpot('desk_spot', furniture.id, currencyService.coins);
    }
// For decorations and chairs - don't auto-equip, let user click "Equip"

    await furnitureService.saveFurniture();
    setState(() {});
  }

// Equip furniture
  Future<void> _equipFurniture(Furniture furniture) async {
    String? emptySpot = furnitureService.findEmptySpot(furniture.category);

    if (emptySpot == null) return; // No spots available

    await furnitureService.placeFurnitureInSpot(
      emptySpot,
      furniture.id,
      currencyService.coins,
    );

    await furnitureService.saveFurniture();
    setState(() {});
  }

// Remove furniture
  Future<void> _removeFurniture(Furniture furniture) async {
    String? spotToRemove;

    furnitureService.placedFurniture.forEach((spotId, furnitureId) {
      if (furnitureId == furniture.id) {
        spotToRemove = spotId;
      }
    });

    if (spotToRemove != null) {
      await furnitureService.removeFurniture(spotToRemove!);
      setState(() {});
    }
  }

  String _getCategoryDisplayName(FurnitureCategory category) {
    switch (category) {
      case FurnitureCategory.bed:
        return 'bed';
      case FurnitureCategory.desk:
        return 'desk';
      case FurnitureCategory.chair:
        return 'chair';
      case FurnitureCategory.kitchen:
        return 'kitchen';
      case FurnitureCategory.decoration:
        return 'decoration';
    }
  }
  // Helper to find which spot this furniture is in
  String? _getSpotForFurniture(Furniture furniture) {
    switch (furniture.category) {
      case FurnitureCategory.bed:
        return 'bed_spot';
      case FurnitureCategory.desk:
        return 'desk_spot';
      case FurnitureCategory.chair:
        return 'chair_spot';
      case FurnitureCategory.kitchen:
        return 'kitchen_spot';
      case FurnitureCategory.decoration:
      // Check all decoration spots
        for (int i = 1; i <= 6; i++) {
          String spot = 'decoration_spot_$i';
          if (furnitureService.getPlacedFurniture(spot)?.id == furniture.id) {
            return spot;
          }
        }
        return null;
    }
  }

// Helper to get the spot name for a category
  String _getSpotForCategory(FurnitureCategory category) {
    switch (category) {
      case FurnitureCategory.bed:
        return 'bed_spot';
      case FurnitureCategory.desk:
        return 'desk_spot';
      case FurnitureCategory.chair:
        return 'chair_spot';
      case FurnitureCategory.kitchen:
        return 'kitchen_spot';
      case FurnitureCategory.decoration:
        return 'decoration_spot_1'; // Will be handled differently
    }
  }

  void _showMessage(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: Duration(seconds: 2),
      ),
    );
  }
}