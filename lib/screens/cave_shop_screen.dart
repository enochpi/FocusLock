import 'package:flutter/material.dart';
import '../utils/number_formatter.dart';
import '../services/furniture_service.dart';
import '../services/currency_service.dart';
import '../services/upgrade_service.dart';

// ════════════════════════════════════════════════════════════
//  Stage-specific shop themes
// ════════════════════════════════════════════════════════════
class ShopTheme {
  final String name;
  final String emoji;
  final Color bgTop;
  final Color bgBottom;
  final Color cardColor;
  final Color cardBorder;
  final Color accentColor;
  final Color accentDark;
  final Color tabActive;
  final Color tabInactive;
  final Color textPrimary;
  final Color textSecondary;
  final Color priceColor;

  const ShopTheme({
    required this.name,
    required this.emoji,
    required this.bgTop,
    required this.bgBottom,
    required this.cardColor,
    required this.cardBorder,
    required this.accentColor,
    required this.accentDark,
    required this.tabActive,
    required this.tabInactive,
    required this.textPrimary,
    required this.textSecondary,
    required this.priceColor,
  });

  static ShopTheme getTheme(int stage) {
    switch (stage) {
      case 0:
        return const ShopTheme(
          name: 'Cave Furniture',
          emoji: '🏔️',
          bgTop: Color(0xFF1a1510),
          bgBottom: Color(0xFF0d0b08),
          cardColor: Color(0xFF2a2218),
          cardBorder: Color(0xFF4a3d2d),
          accentColor: Color(0xFF8D6E63),
          accentDark: Color(0xFF5D4037),
          tabActive: Color(0xFF6D4C41),
          tabInactive: Color(0xFF3E2723),
          textPrimary: Color(0xFFD7CCC8),
          textSecondary: Color(0xFF8D6E63),
          priceColor: Color(0xFFFFD54F),
        );
      case 1:
        return const ShopTheme(
          name: 'Shack Furniture',
          emoji: '🏚️',
          bgTop: Color(0xFF1b2218),
          bgBottom: Color(0xFF0e1410),
          cardColor: Color(0xFF1e2a1c),
          cardBorder: Color(0xFF4a6340),
          accentColor: Color(0xFF66BB6A),
          accentDark: Color(0xFF388E3C),
          tabActive: Color(0xFF43A047),
          tabInactive: Color(0xFF1B5E20),
          textPrimary: Color(0xFFC8E6C9),
          textSecondary: Color(0xFF81C784),
          priceColor: Color(0xFFFFB74D),
        );
      case 2:
        return const ShopTheme(
          name: 'House Furniture',
          emoji: '🏠',
          bgTop: Color(0xFF0d1b2a),
          bgBottom: Color(0xFF080f18),
          cardColor: Color(0xFF132238),
          cardBorder: Color(0xFF2962FF),
          accentColor: Color(0xFF42A5F5),
          accentDark: Color(0xFF1976D2),
          tabActive: Color(0xFF1E88E5),
          tabInactive: Color(0xFF0D47A1),
          textPrimary: Color(0xFFBBDEFB),
          textSecondary: Color(0xFF64B5F6),
          priceColor: Color(0xFF4FC3F7),
        );
      case 3:
        return const ShopTheme(
          name: 'Mansion Furniture',
          emoji: '🏰',
          bgTop: Color(0xFF1a0e2e),
          bgBottom: Color(0xFF0d0718),
          cardColor: Color(0xFF221440),
          cardBorder: Color(0xFFD4A417),
          accentColor: Color(0xFFCE93D8),
          accentDark: Color(0xFF9C27B0),
          tabActive: Color(0xFF7B1FA2),
          tabInactive: Color(0xFF4A148C),
          textPrimary: Color(0xFFE1BEE7),
          textSecondary: Color(0xFFCE93D8),
          priceColor: Color(0xFFFFD700),
        );
      default:
        return getTheme(0);
    }
  }
}

// ════════════════════════════════════════════════════════════
//  Shop Screen
// ════════════════════════════════════════════════════════════
class CaveShopScreen extends StatefulWidget {
  @override
  _CaveShopScreenState createState() => _CaveShopScreenState();
}

class _CaveShopScreenState extends State<CaveShopScreen> {
  final FurnitureService furnitureService = FurnitureService();
  final CurrencyService currencyService = CurrencyService();

  FurnitureCategory selectedCategory = FurnitureCategory.bed;
  int shopStage = 0; // Which stage's shop we're viewing

  @override
  void initState() {
    super.initState();
    shopStage = UpgradeService().currentStage;
  }

  ShopTheme get theme => ShopTheme.getTheme(shopStage);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: theme.bgBottom,
      appBar: AppBar(
        backgroundColor: theme.bgTop,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          '${theme.emoji} ${theme.name}',
          style: TextStyle(
            color: theme.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: theme.priceColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.priceColor.withOpacity(0.4)),
                ),
                child: Text(
                  '🪙 ${NumberFormatter.format(currencyService.coins)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: theme.priceColor,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [theme.bgTop, theme.bgBottom],
          ),
        ),
        child: Column(
          children: [
            // Stage shop tabs (if more than 1 stage unlocked)
            if (UpgradeService().currentStage > 0) _buildStageTabs(),
            _buildBoostDisplay(),
            _buildCategoryTabs(),
            Expanded(child: _buildFurnitureGrid()),
          ],
        ),
      ),
    );
  }

  // ── Stage selector tabs ──
  Widget _buildStageTabs() {
    final stageNames = ['🏔️ Cave', '🏚️ Shack', '🏠 House', '🏰 Mansion'];
    final maxStage = UpgradeService().currentStage;

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: maxStage + 1,
        itemBuilder: (context, index) {
          final isSelected = shopStage == index;
          final stageTheme = ShopTheme.getTheme(index);

          return GestureDetector(
            onTap: () => setState(() {
              shopStage = index;
              selectedCategory = FurnitureCategory.bed;
            }),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? stageTheme.tabActive : stageTheme.tabInactive.withOpacity(0.4),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? stageTheme.accentColor : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Text(
                  stageNames[index],
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white54,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Boost display ──
  Widget _buildBoostDisplay() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.accentColor.withOpacity(0.5), width: 1.5),
      ),
      child: Column(
        children: [
          Text(
            'Total Furniture Boost',
            style: TextStyle(color: theme.textSecondary, fontSize: 11),
          ),
          const SizedBox(height: 2),
          Text(
            furnitureService.getBoostString(),
            style: TextStyle(
              color: theme.accentColor,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ── Category tabs ──
  Widget _buildCategoryTabs() {
    final categories = [
      (FurnitureCategory.bed, '🛏️', 'Beds'),
      (FurnitureCategory.desk, '📚', 'Desks'),
      (FurnitureCategory.chair, '🪑', 'Chairs'),
      (FurnitureCategory.kitchen, '🍳', 'Kitchen'),
      (FurnitureCategory.decoration, '🖼️', 'Decor'),
    ];

    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: categories.map((cat) {
          final isSelected = selectedCategory == cat.$1;
          return GestureDetector(
            onTap: () => setState(() => selectedCategory = cat.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? theme.tabActive : theme.tabInactive.withOpacity(0.3),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? theme.accentColor : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(cat.$2, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 4),
                  Text(
                    cat.$3,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white60,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Furniture grid ──
  Widget _buildFurnitureGrid() {
    final items = furnitureService.getFurnitureForStageAndCategory(shopStage, selectedCategory);

    if (items.isEmpty) {
      return Center(
        child: Text(
          'No items available',
          style: TextStyle(color: theme.textSecondary, fontSize: 16),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: items.length,
      itemBuilder: (context, index) => _buildFurnitureCard(items[index]),
    );
  }

  // ── Individual furniture card ──
  Widget _buildFurnitureCard(Furniture furniture) {
    final isOwned = furnitureService.isFurnitureOwned(furniture.id);
    final isPlaced = furnitureService.isFurniturePlaced(furniture.id);
    final canAfford = currencyService.coins >= furniture.cost;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isPlaced
              ? theme.accentColor
              : isOwned
              ? theme.cardBorder.withOpacity(0.5)
              : theme.cardBorder.withOpacity(0.2),
          width: isPlaced ? 2 : 1,
        ),
        boxShadow: isPlaced
            ? [
          BoxShadow(
            color: theme.accentColor.withOpacity(0.15),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ]
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Emoji icon
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: theme.accentDark.withOpacity(0.25),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  furniture.emoji,
                  style: const TextStyle(fontSize: 26),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    furniture.name,
                    style: TextStyle(
                      color: theme.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    furniture.description,
                    style: TextStyle(
                      color: theme.accentColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (!isOwned)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        '🪙 ${NumberFormatter.format(furniture.cost.toDouble())}',
                        style: TextStyle(
                          color: canAfford ? theme.priceColor : Colors.red[300],
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            // Action button
            _buildActionButton(furniture, isOwned, isPlaced, canAfford),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(Furniture furniture, bool isOwned, bool isPlaced, bool canAfford) {
    if (isPlaced) {
      // Remove button
      return GestureDetector(
        onTap: () {
          furnitureService.removeFurniture(furniture.id);
          setState(() {});
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.red.withOpacity(0.4)),
          ),
          child: const Text(
            'Remove',
            style: TextStyle(
              color: Colors.redAccent,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      );
    }

    if (isOwned) {
      // Equip button
      return GestureDetector(
        onTap: () {
          furnitureService.placeFurniture(furniture.id);
          setState(() {});
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: theme.accentColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.accentColor.withOpacity(0.5)),
          ),
          child: Text(
            'Equip',
            style: TextStyle(
              color: theme.accentColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      );
    }

    // Buy button
    return GestureDetector(
      onTap: canAfford ? () => _buyFurniture(furniture) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: canAfford
              ? theme.accentDark.withOpacity(0.4)
              : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: canAfford
                ? theme.accentColor.withOpacity(0.6)
                : Colors.grey.withOpacity(0.2),
          ),
        ),
        child: Text(
          canAfford ? 'Buy' : 'Need 🪙',
          style: TextStyle(
            color: canAfford ? theme.priceColor : Colors.grey,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Future<void> _buyFurniture(Furniture furniture) async {
    // Deduct coins first
    await currencyService.removeCoins(furniture.cost);

    // Mark as owned
    furnitureService.buyFurniture(furniture.id);

    // Auto-equip
    furnitureService.placeFurniture(furniture.id);

    setState(() {});

    if (!mounted) return;

    // Success feedback
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          '${furniture.emoji} Purchased!',
          style: TextStyle(color: theme.textPrimary),
          textAlign: TextAlign.center,
        ),
        content: Text(
          '${furniture.name} has been equipped!\n${furniture.description}',
          style: TextStyle(color: theme.textSecondary),
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Nice!', style: TextStyle(color: theme.accentColor)),
          ),
        ],
      ),
    );
  }
}