import 'package:flutter/material.dart';
import '../services/currency_service.dart';
import '../services/upgrade_service.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({Key? key}) : super(key: key);
  // ← No parameters needed!

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  final CurrencyService currency = CurrencyService();
  final UpgradeService upgrades = UpgradeService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1a1a1a),
      appBar: AppBar(
        backgroundColor: Color(0xFF2d2d2d),
        title: Text('🛒 Upgrade Shop'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Currency Display at top
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(0xFF2d2d2d),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Peas
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Color(0xFF4CAF50).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Color(0xFF4CAF50), width: 2),
                  ),
                  child: Row(
                    children: [
                      Text('🌱', style: TextStyle(fontSize: 24)),
                      SizedBox(width: 8),
                      Text(
                        '${currency.peas}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // Current Multiplier
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Color(0xFFFFD700).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Color(0xFFFFD700), width: 2),
                  ),
                  child: Row(
                    children: [
                      Text('⚡', style: TextStyle(fontSize: 24)),
                      SizedBox(width: 8),
                      Text(
                        upgrades.getMultiplierString(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Bonus info
          Container(
            padding: EdgeInsets.all(12),
            color: Color(0xFF4CAF50).withOpacity(0.1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info_outline, color: Color(0xFF4CAF50), size: 20),
                SizedBox(width: 8),
                Text(
                  'Current Bonus: ${upgrades.getBonusPercentageString()}',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // Upgrades List
          Expanded(
            child: upgrades.allUpgrades.isEmpty
                ? Center(
              child: Text(
                'No upgrades available',
                style: TextStyle(color: Colors.white54),
              ),
            )
                : ListView.builder(
              padding: EdgeInsets.all(16),
              itemCount: upgrades.allUpgrades.length,
              itemBuilder: (context, index) {
                Upgrade upgrade = upgrades.allUpgrades[index];
                return _buildUpgradeCard(upgrade);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpgradeCard(Upgrade upgrade) {
    bool canAfford = currency.peas >= upgrade.cost;
    bool isPurchased = upgrade.isPurchased;

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Color(0xFF2d2d2d),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPurchased
              ? Color(0xFF4CAF50)
              : canAfford
              ? Color(0xFF4CAF50).withOpacity(0.5)
              : Colors.white24,
          width: 2,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            // Emoji Icon
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: isPurchased
                    ? Color(0xFF4CAF50).withOpacity(0.2)
                    : Color(0xFF1a1a1a),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  upgrade.emoji,
                  style: TextStyle(fontSize: 32),
                ),
              ),
            ),

            SizedBox(width: 16),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    upgrade.name,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    upgrade.description,
                    style: TextStyle(
                      color: Color(0xFF4CAF50),
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Text('🌱', style: TextStyle(fontSize: 16)),
                      SizedBox(width: 4),
                      Text(
                        '${upgrade.cost}',
                        style: TextStyle(
                          color: canAfford ? Colors.white : Colors.white38,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Button
            SizedBox(width: 16),
            _buildPurchaseButton(upgrade, canAfford, isPurchased),
          ],
        ),
      ),
    );
  }

  Widget _buildPurchaseButton(Upgrade upgrade, bool canAfford, bool isPurchased) {
    if (isPurchased) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Color(0xFF4CAF50).withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Color(0xFF4CAF50), width: 2),
        ),
        child: Row(
          children: [
            Icon(Icons.check, color: Color(0xFF4CAF50), size: 20),
            SizedBox(width: 4),
            Text(
              'Owned',
              style: TextStyle(
                color: Color(0xFF4CAF50),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    return ElevatedButton(
      onPressed: canAfford
          ? () async {
        bool success = await _purchaseUpgrade(upgrade);
        if (success) {
          setState(() {}); // Refresh UI
        }
      }
          : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: canAfford ? Color(0xFF4CAF50) : Colors.grey[800],
        disabledBackgroundColor: Colors.grey[800],
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Text(
        'Buy',
        style: TextStyle(
          color: canAfford ? Colors.white : Colors.white38,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  Future<bool> _purchaseUpgrade(Upgrade upgrade) async {
    // Try to purchase
    bool success = await upgrades.purchaseUpgrade(upgrade.id, currency.peas);

    if (success) {
      // Deduct peas
      await currency.removePeas(upgrade.cost);

      // Show success dialog
      if (!mounted) return true;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Color(0xFF2d2d2d),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Text(upgrade.emoji, style: TextStyle(fontSize: 32)),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Purchased!',
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
                upgrade.name,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                upgrade.description,
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
                      'New Multiplier: ${upgrades.getMultiplierString()}',
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
              onPressed: () => Navigator.pop(context),
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

      return true;
    } else {
      // Show error (shouldn't happen with proper checks)
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not purchase upgrade'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
  }
}