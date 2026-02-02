import 'package:flutter/material.dart';
import '../services/furniture_service.dart';
import '../services/currency_service.dart';

class FurnitureSelectionDialog extends StatefulWidget {
  final String spotId;
  final FurnitureType furnitureType;
  final Furniture? currentFurniture; // null if spot is empty

  const FurnitureSelectionDialog({
    Key? key,
    required this.spotId,
    required this.furnitureType,
    this.currentFurniture,
  }) : super(key: key);

  @override
  State<FurnitureSelectionDialog> createState() => _FurnitureSelectionDialogState();
}

class _FurnitureSelectionDialogState extends State<FurnitureSelectionDialog> {
  final FurnitureService furnitureService = FurnitureService();
  final CurrencyService currencyService = CurrencyService();

  String _getTypeTitle() {
    switch (widget.furnitureType) {
      case FurnitureType.bed:
        return '🛏️ Choose Bed';
      case FurnitureType.desk:
        return '🪑 Choose Desk';
      case FurnitureType.kitchen:
        return '🍳 Choose Kitchen';
      case FurnitureType.decoration:
        return '🖼️ Choose Decoration';
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Furniture> availableFurniture = furnitureService.getFurnitureByType(widget.furnitureType);

    return AlertDialog(
      backgroundColor: Color(0xFF2d2d2d),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: Text(
        _getTypeTitle(),
        style: TextStyle(color: Colors.white),
        textAlign: TextAlign.center,
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Current furniture info (if any)
            if (widget.currentFurniture != null) ...[
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Color(0xFF4CAF50).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Color(0xFF4CAF50), width: 2),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          widget.currentFurniture!.emoji,
                          style: TextStyle(fontSize: 24),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Currently: ${widget.currentFurniture!.name}',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () async {
                        await furnitureService.removeFurniture(widget.spotId);
                        Navigator.pop(context, true); // Return true to refresh
                      },
                      child: Text(
                        'Remove',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              Text(
                widget.currentFurniture != null ? 'Upgrade to:' : 'Available:',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),
              SizedBox(height: 12),
            ],

            // Furniture list
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: availableFurniture.length,
                itemBuilder: (context, index) {
                  return _buildFurnitureCard(availableFurniture[index]);
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            'Cancel',
            style: TextStyle(color: Colors.white54),
          ),
        ),
      ],
    );
  }

  Widget _buildFurnitureCard(Furniture furniture) {
    int currentCoins = currencyService.coins;
    bool canAfford = currentCoins >= furniture.cost;
    bool isCurrent = widget.currentFurniture?.id == furniture.id;

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Color(0xFF1a1a1a),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrent
              ? Color(0xFF4CAF50)
              : canAfford
              ? Color(0xFF4CAF50).withOpacity(0.3)
              : Colors.white24,
          width: 2,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Row(
          children: [
            // Emoji icon
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: canAfford
                    ? Color(0xFF4CAF50).withOpacity(0.2)
                    : Color(0xFF424242),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  furniture.emoji,
                  style: TextStyle(fontSize: 28),
                ),
              ),
            ),

            SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    furniture.name,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    furniture.description,
                    style: TextStyle(
                      color: Color(0xFF4CAF50),
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 6),
                  Row(
                    children: [
                      Text('🪙', style: TextStyle(fontSize: 14)),
                      SizedBox(width: 4),
                      Text(
                        '${furniture.cost}',
                        style: TextStyle(
                          color: canAfford ? Colors.white : Colors.white38,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Button
            SizedBox(width: 8),
            _buildActionButton(furniture, canAfford, isCurrent),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(Furniture furniture, bool canAfford, bool isCurrent) {
    if (isCurrent) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Color(0xFF4CAF50).withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Color(0xFF4CAF50), width: 2),
        ),
        child: Text(
          'Current',
          style: TextStyle(
            color: Color(0xFF4CAF50),
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return ElevatedButton(
      onPressed: canAfford
          ? () async {
        await _placeFurniture(furniture);
      }
          : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: canAfford ? Color(0xFF4CAF50) : Colors.grey[800],
        disabledBackgroundColor: Colors.grey[800],
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(
        widget.currentFurniture != null ? 'Upgrade' : 'Place',
        style: TextStyle(
          color: canAfford ? Colors.white : Colors.white38,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Future<void> _placeFurniture(Furniture furniture) async {
    // Try to place/upgrade
    bool success;
    if (widget.currentFurniture != null) {
      success = await furnitureService.upgradeFurniture(
        widget.spotId,
        furniture.id,
        currencyService.coins,
      );
    } else {
      success = await furnitureService.placeFurniture(
        widget.spotId,
        furniture.id,
        currencyService.coins,
      );
    }

    if (success) {
      // Deduct coins
      await currencyService.removeCoins(furniture.cost);

      // Show success dialog
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Color(0xFF2d2d2d),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Text(furniture.emoji, style: TextStyle(fontSize: 32)),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.currentFurniture != null ? 'Upgraded!' : 'Placed!',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                furniture.name,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                furniture.description,
                style: TextStyle(color: Color(0xFF4CAF50)),
              ),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Color(0xFF4CAF50).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Text('⚡', style: TextStyle(fontSize: 20)),
                    SizedBox(width: 8),
                    Text(
                      'Total Furniture Bonus: ${furnitureService.getBoostString()}',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close success dialog
                Navigator.pop(context, true); // Close selection dialog, return true
              },
              child: Text(
                'Awesome!',
                style: TextStyle(
                  color: Color(0xFF4CAF50),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      // Show error
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not place furniture'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}