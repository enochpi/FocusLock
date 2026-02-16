import 'package:flutter/material.dart';
import '../services/currency_service.dart';
import '../services/upgrade_service.dart';
import '../utils/number_formatter.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({Key? key}) : super(key: key);

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  final CurrencyService currency = CurrencyService();
  final UpgradeService upgrades = UpgradeService();

  int selectedShopStage = 0; // Which shop tab is selected

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a1a),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2d2d2d),
        title: const Text('🛒 Upgrade Shop'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Currency Display at top
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
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
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF4CAF50), width: 2),
                  ),
                  child: Row(
                    children: [
                      Text(CurrencyService().cropEmoji, style: TextStyle(fontSize: 24)),
                      const SizedBox(width: 8),
                      Text(
                        NumberFormatter.format(currency.peas),
                        style: const TextStyle(
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
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD700).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFFFD700), width: 2),
                  ),
                  child: Row(
                    children: [
                      const Text('⚡', style: TextStyle(fontSize: 24)),
                      const SizedBox(width: 8),
                      Text(
                        upgrades.getMultiplierString(),
                        style: const TextStyle(
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
            padding: const EdgeInsets.all(12),
            color: const Color(0xFF4CAF50).withOpacity(0.1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.info_outline, color: Color(0xFF4CAF50), size: 20),
                const SizedBox(width: 8),
                Text(
                  'Current Bonus: ${upgrades.getBonusPercentageString()}',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // Shop tabs (Cave, Shack, House, Mansion)
          _buildShopTabs(),

          // Upgrades List
          Expanded(
            child: _buildUpgradesList(),
          ),
        ],
      ),
    );
  }

  Widget _buildShopTabs() {
    List<String> shopNames = ['Cave', 'Shack', 'House', 'Mansion'];
    List<String> shopEmojis = ['🏔️', '🏚️', '🏠', '🏰'];

    return SizedBox(
      height: 70,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: 4, // Always show all 4
        itemBuilder: (context, index) {
          bool isUnlocked = index <= upgrades.currentStage;
          bool isSelected = selectedShopStage == index;

          return GestureDetector(
            onTap: isUnlocked ? () => setState(() => selectedShopStage = index) : null,
            child: Container(
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: isUnlocked
                    ? (isSelected ? const Color(0xFF4CAF50) : const Color(0xFF2d2d2d))
                    : const Color(0xFF1a1a1a),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isUnlocked
                      ? (isSelected ? const Color(0xFF4CAF50) : Colors.grey)
                      : Colors.grey[800]!,
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  // Locked icon or emoji
                  Text(
                    isUnlocked ? shopEmojis[index] : '🔒',
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${shopNames[index]} Shop',
                    style: TextStyle(
                      color: isUnlocked ? Colors.white : Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildUpgradesList() {
    List<Upgrade> shopUpgrades = upgrades.getUpgradesForStage(selectedShopStage);
    HouseUnlock? nextUnlock = upgrades.getNextUnlock();

    // Show unlock card if this is the current stage and there's a next unlock
    bool showUnlock = nextUnlock != null && selectedShopStage == upgrades.currentStage;

    if (shopUpgrades.isEmpty && !showUnlock) {
      return const Center(
        child: Text(
          'No upgrades available',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: shopUpgrades.length + (showUnlock ? 1 : 0),
      itemBuilder: (context, index) {
        // Show unlock card first if available
        if (showUnlock && index == 0) {
          return _buildUnlockCard(nextUnlock);
        }

        // Adjust index if unlock card is shown
        int upgradeIndex = showUnlock ? index - 1 : index;
        return _buildUpgradeCard(shopUpgrades[upgradeIndex]);
      },
    );
  }

  Widget _buildUnlockCard(HouseUnlock unlock) {
    bool canAfford = currency.peas >= unlock.cost;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFFD700),
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Title
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(unlock.emoji, style: const TextStyle(fontSize: 48)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        unlock.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        unlock.description,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Cost and button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Cost
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Text(CurrencyService().cropEmoji, style: TextStyle(fontSize: 24)),
                      const SizedBox(width: 8),
                      Text(
                        NumberFormatter.format(unlock.cost),
                        style: TextStyle(
                          color: canAfford ? Colors.white : Colors.red,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // Buy button
                ElevatedButton(
                  onPressed: canAfford ? () => _purchaseUnlock(unlock) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canAfford ? Colors.white : Colors.grey[600],
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'UNLOCK',
                    style: TextStyle(
                      color: canAfford ? const Color(0xFFFFD700) : Colors.white38,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _purchaseUnlock(HouseUnlock unlock) async {
    bool success = await upgrades.purchaseHouseUnlock(unlock.id, currency.peas.toDouble());

    if (success) {
      await currency.removePeas(unlock.cost.round());
      await currency.upgradeStage();

      if (!mounted) return;

      // Show success dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF2d2d2d),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Text(unlock.emoji, style: const TextStyle(fontSize: 48)),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Unlocked!',
                  style: TextStyle(color: Color(0xFFFFD700)),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                unlock.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                unlock.description,
                style: const TextStyle(color: Color(0xFF4CAF50)),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  selectedShopStage = upgrades.currentStage; // Switch to new shop
                });
              },
              child: const Text(
                'Explore New Shop!',
                style: TextStyle(
                  color: Color(0xFFFFD700),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );

      setState(() {});
    }
  }

  Widget _buildUpgradeCard(Upgrade upgrade) {
    bool canAfford = currency.peas >= upgrade.cost;
    bool isPurchased = upgrade.isPurchased;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF2d2d2d),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPurchased
              ? const Color(0xFF4CAF50)
              : canAfford
              ? const Color(0xFF4CAF50).withOpacity(0.5)
              : Colors.white24,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Emoji Icon
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: isPurchased
                    ? const Color(0xFF4CAF50).withOpacity(0.2)
                    : const Color(0xFF1a1a1a),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  upgrade.emoji,
                  style: const TextStyle(fontSize: 32),
                ),
              ),
            ),

            const SizedBox(width: 16),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    upgrade.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    upgrade.description,
                    style: const TextStyle(
                      color: Color(0xFF4CAF50),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(CurrencyService().cropEmoji, style: TextStyle(fontSize: 24)),
                      const SizedBox(width: 4),
                      Text(
                        NumberFormatter.format(upgrade.cost),
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
            const SizedBox(width: 16),
            _buildPurchaseButton(upgrade, canAfford, isPurchased),
          ],
        ),
      ),
    );
  }

  Widget _buildPurchaseButton(Upgrade upgrade, bool canAfford, bool isPurchased) {
    if (isPurchased) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF4CAF50).withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF4CAF50), width: 2),
        ),
        child: const Row(
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
        backgroundColor: canAfford ? const Color(0xFF4CAF50) : Colors.grey[800],
        disabledBackgroundColor: Colors.grey[800],
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
    bool success = await upgrades.purchaseUpgrade(upgrade.id, currency.peas.toDouble());

    if (success) {
      // Deduct peas
      await currency.removePeas(upgrade.cost.round());

      // Show success dialog
      if (!mounted) return true;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF2d2d2d),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Text(upgrade.emoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 12),
              const Expanded(
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
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                upgrade.description,
                style: const TextStyle(color: Color(0xFF4CAF50)),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Text('⚡', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Text(
                      'New Multiplier: ${upgrades.getMultiplierString()}',
                      style: const TextStyle(
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
              child: const Text(
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

      return false;
    }
  }
}